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

	for i in passos:
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
	arvore.quit(0)

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
