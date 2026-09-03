extends RefCounted

## Corpo da ferramenta. Vive fora do script de entrada de propósito: em modo
## `-s` o Godot compila o script de entrada ANTES de registrar os autoloads, e
## qualquer classe que use `Bus`/`Cfg` falha a compilar de forma intermitente.
## Carregado por `res://tools/sim_balance.gd` já dentro de `_initialize()`.

var arvore: SceneTree
var root: Node

## Simulador headless de balanceamento.
## Roda o jogo REAL (mesmo código do jogo) por N horas simuladas e reporta o ritmo.
##   godot --headless --path . -s res://tools/sim_balance.gd -- 2   (2 horas)

const DT := 1.0 / 60.0

func rodar(cena: SceneTree) -> void:
	arvore = cena
	root = cena.root
	# roda num save separado: a suite nao pode apagar o progresso de quem joga
	SaveSys.prefixo = "_ferramenta_"
	var args := OS.get_cmdline_user_args()
	var horas := 1.0
	if args.size() > 0:
		horas = maxf(0.05, float(args[0]))
	var auto_tudo := args.size() > 1 and str(args[1]) == "auto"

	var cfg = root.get_node_or_null("Cfg")
	var save = root.get_node_or_null("SaveSys")
	var j = root.get_node_or_null("Jogo")
	if j == null:
		print("ERRO: autoloads ausentes")
		arvore.quit(1)
		return
	Dados.carregar(true)
	cfg.v = cfg.PADRAO.duplicate(true)

	# ambiente limpo
	save.apagar()
	j.stats = StatEngine.new()
	j.iniciar()
	# Um jogador de verdade usa as habilidades: a IA de uso automático é o
	# comportamento base do simulador; "auto" liga também a compra automática.
	# Os desbloqueios moram em `s["desbloqueios"]`; `esp` é recalculado a partir
	# dele e escrever direto em `esp` era apagado no primeiro recalcular() — o
	# simulador media 3h de jogo com a automação DESLIGADA sem avisar.
	j.s["auto"]["habilidades"] = true
	j.s["desbloqueios"]["autoHabilidade"] = true
	if auto_tudo:
		j.s["auto"]["comprar"] = true
		j.s["desbloqueios"]["autoCompra"] = true
	j.recalcular()

	var passos := int(horas * 3600.0 / DT)
	var marcos := {}
	var proximo_relatorio := 0.0
	var t0 := Time.get_ticks_msec()
	var erros := 0
	var pico_inimigos := 0
	var pico_projeteis := 0

	print("=== SIMULACAO: %.2f h de jogo (%d passos) ===" % [horas, passos])
	print("tempo | onda | ouro | dano | vida | inimigos | nivel | frag")

	var onda_no_terco := 0
	var passo_do_terco := int(float(passos) * 0.66)
	for i in passos:
		if i == passo_do_terco:
			onda_no_terco = int(j.s["onda_maxima"])
		j.simular(DT)
		# compra automática básica para simular um jogador ativo
		if not auto_tudo and i % 20 == 0:
			_comprar_como_jogador(j)
		pico_inimigos = maxi(pico_inimigos, j.arena.inimigos.size())
		pico_projeteis = maxi(pico_projeteis, j.arena.projeteis.size())

		var t: float = j.s["stats"]["tempo_total"]
		if t >= proximo_relatorio:
			proximo_relatorio += maxf(60.0, horas * 3600.0 / 24.0)
			print("%6s | %4d | %9s | %8s | %10s | %3d | %3d | %s" % [
				Ux.tempo_curto(t), int(j.s["onda"]),
				Fmt.big(j.s["moedas"]["ouro"]), Fmt.big(j.stats.b("dano")),
				Fmt.big(j.s["torre"]["vida"]), j.arena.inimigos.size(),
				int(j.s["nivel"]), Fmt.big(j.s["moedas"]["fragmentos"]),
			])
		for marco in [10, 25, 50, 75, 100, 150, 200, 300, 500]:
			if int(j.s["onda_maxima"]) >= marco and not marcos.has(marco):
				marcos[marco] = t

	var ms := Time.get_ticks_msec() - t0
	print("\n=== MARCOS (tempo para chegar) ===")
	for k in marcos.keys():
		print("  onda %4d -> %s" % [k, Ux.tempo_curto(marcos[k])])
	print("\n=== RESUMO ===")
	print("onda maxima: %d" % int(j.s["onda_maxima"]))
	print("mortes: %d | inimigos mortos: %d | chefes: %d" % [
		int(j.s["stats"]["mortes"]), int(j.s["stats"]["mortos"]), int(j.s["stats"]["chefes_mortos"])])
	print("ouro total: %s | dano max: %s" % [Fmt.big(j.s["stats"]["ouro_total"]), Fmt.big(j.s["stats"]["dano_maximo"])])
	print("cartas: %d | conquistas: %d" % [j.s["cartas"]["inventario"].size(), j.s["conquistas"].size()])
	print("fragmentos se ascender agora: %s" % Fmt.big(Prestigio.previa_fragmentos(j)))
	print("pico de entidades: %d inimigos, %d projeteis" % [pico_inimigos, pico_projeteis])
	print("desempenho: %d ms para %d passos (%.2f us/passo, %.0fx tempo real)" % [
		ms, passos, float(ms) * 1000.0 / float(passos), (horas * 3600.0) / maxf(0.001, float(ms) / 1000.0)])
	print("recalculos de atributos: %d" % j.stats.recalculos)

	# ------------------------------------------------------------ VEREDITO
	#
	# Esta ferramenta nao tinha nenhum. Numa corrida bem-sucedida ela terminava
	# em `quit(0)` sem imprimir uma linha de status, e o passo do CI que a roda
	# so procurava por `SCRIPT ERROR`. Ou seja: chegar a onda 25 em trinta
	# segundos ou em tres horas passava no CI exatamente igual, e a faixa do
	# criterio 5 era "cobrada" por uma pessoa lendo uma tabela. Um criterio cuja
	# coluna "como se verifica" aponta para um programa sem PASS/FAIL nao
	# verifica coisa alguma.
	#
	# Agora ele cobra. As faixas so valem quando a corrida e longa o bastante
	# para conte-las — numa corrida de 1 h nao da para cobrar a onda 100 em ate
	# 60 min sem transformar o portao em loteria.
	var falhas: Array = []
	var minutos := horas * 60.0
	for regra in [[25, 5.0, 12.0], [50, 15.0, 30.0], [100, 30.0, 60.0]]:
		var alvo := int(regra[0])
		var lo := float(regra[1])
		var hi := float(regra[2])
		if minutos < hi:
			continue                       # corrida curta demais para julgar
		if not marcos.has(alvo):
			falhas.append("onda %d nao foi alcancada em %.0f min (faixa %.0f-%.0f)" % [alvo, minutos, lo, hi])
			continue
		var t_min := float(marcos[alvo]) / 60.0
		if t_min < lo or t_min > hi:
			falhas.append("onda %d em %.1f min, fora da faixa %.0f-%.0f" % [alvo, t_min, lo, hi])

	# "sem travar": a onda tem que continuar subindo no ultimo terco da corrida.
	if minutos >= 30.0 and onda_no_terco > 0 and int(j.s["onda_maxima"]) <= onda_no_terco:
		falhas.append("a onda parou de subir: %d no ultimo terco, %d no fim" % [
			onda_no_terco, int(j.s["onda_maxima"])])

	# O catalogo nao pode esvaziar: se TODAS as melhorias com teto estiverem no
	# maximo, a tela de melhorias ficou sem decisao pelo resto da partida.
	var com_teto := 0
	var no_teto := 0
	for def in Dados.upgrades:
		var teto: int = j.teto_upgrade(def)
		if teto < 0:
			continue
		com_teto += 1
		if int(j.s["upgrades"].get(str(def.get("id", "")), 0)) >= teto:
			no_teto += 1
	print("melhorias no teto: %d de %d com teto" % [no_teto, com_teto])
	if com_teto > 0 and no_teto >= com_teto:
		falhas.append("todas as %d melhorias com teto estao no maximo — a tela ficou sem decisao" % com_teto)

	for f in falhas:
		print("  FALHOU: ", f)
	print("===STATUS=== ", "PASS" if falhas.is_empty() else "FAIL")
	arvore.quit(0 if falhas.is_empty() else 1)

## Heurística simples de "jogador": compra o upgrade mais barato disponível.
func _comprar_como_jogador(j) -> void:
	for k in 6:
		var melhor := ""
		var melhor_custo := INF
		for def in Dados.upgrades:
			if not j.upgrade_disponivel(def):
				continue
			var id := str(def["id"])
			var nivel: int = int(j.s["upgrades"].get(id, 0))
			var maxn := int(def.get("max", -1))
			if maxn >= 0 and nivel >= maxn:
				continue
			var c: float = j.custo_upgrade(def, nivel)
			if Big.lte(c, j.s["moedas"]["ouro"]) and c < melhor_custo:
				melhor_custo = c
				melhor = id
		if melhor == "":
			return
		j.comprar_upgrade(melhor, 1)
