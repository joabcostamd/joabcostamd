extends RefCounted

const DT := 1.0 / 60.0
const SEMENTE := 20260903

var arvore: SceneTree
var root: Node

func executar() -> void:
	var args := OS.get_cmdline_user_args()
	var horas := 6.0
	if args.size() > 0:
		horas = maxf(0.5, float(args[0]))
	var passos := int(horas * 3600.0 / DT)

	# Sem isto, `Dados` fica vazio: nao ha inimigos, as ondas fecham vazias, o
	# nivel nunca sobe e o relatorio mede um jogo que nao existe. A primeira
	# versao desta ferramenta media onda 378 em 10 minutos por causa disso.
	Dados.carregar(true)
	var save = root.get_node_or_null("SaveSys")
	var cfg = root.get_node_or_null("Cfg")
	cfg.v = cfg.PADRAO.duplicate(true)
	save.apagar()
	var j = root.get_node_or_null("Jogo")
	j.stats = StatEngine.new()
	j.iniciar()
	j.rng = RngX.new(SEMENTE)

	# O jogador que esta ferramenta simula USA o jogo: ascende assim que pode,
	# colapsa assim que pode, transcende assim que pode. E o unico jeito de a
	# duracao medida ter alguma relacao com a duracao vivida.
	# Os desbloqueios moram em `s["desbloqueios"]`; `esp` e RECALCULADO a partir
	# dele, entao escrever direto em `esp` e apagado no primeiro recalcular().
	# O comentario que diz isso esta no sim_balance porque eu ja tinha caido
	# nessa uma vez — e cai de novo aqui, medindo uma hora de jogo com a
	# automacao desligada e concluindo "onda 10 em 1 hora".
	j.s["auto"]["habilidades"] = true
	j.s["desbloqueios"]["autoHabilidade"] = true
	j.s["auto"]["comprar"] = true
	j.s["desbloqueios"]["autoCompra"] = true
	j.recalcular()

	var marcos := {}
	var t := 0.0
	print("=== DURACAO: %.1f h de jogo, com prestigio ligado ===" % horas)
	# O prestígio é acionado AQUI, chamando `j.ascender()` direto, e não pelo
	# desbloqueio de automação: `recalcular()` reconstrói `esp` a cada quadro
	# sujo, então ligar `esp["desbloqueios"]` na mão dura até o primeiro
	# recálculo. Foi assim que a primeira versão desta ferramenta mediu UMA
	# ascensão em 12 horas e quase me fez acusar o jogo de um defeito que era
	# meu. A regra de quando ascender é a de um jogador que sabe o que faz:
	# assim que a run bate o dobro da onda em que ascendeu da última vez.
	# O AGENTE E O MESMO do portao de balanceamento, instanciado aqui em vez de
	# reescrito: um jogador simulado que compra melhoria mas nao gasta talento,
	# carta, no de prestigio nem reliquia progride ate a onda 10 em uma hora
	# (medido). Duas ferramentas com dois agentes diferentes dariam duas
	# duracoes diferentes para o mesmo jogo, e uma delas estaria mentindo.
	var agente = load("res://tools/suites/sim_balance.gd").new()

	var alvo_asc := Bal.ASC_ONDA_MIN
	for i in passos:
		j.simular(DT)
		if i % 20 == 0:
			agente._jogar_o_resto(j)
		t += DT
		var s: Dictionary = j.s
		if int(s["onda_maxima"]) >= alvo_asc and Prestigio.pode_ascender(s):
			if Prestigio.pode_transcender(s):
				j.transcender()
				alvo_asc = Bal.ASC_ONDA_MIN
			elif Prestigio.pode_colapsar(s):
				j.colapsar()
				alvo_asc = Bal.ASC_ONDA_MIN
			else:
				j.ascender()
				alvo_asc = maxi(Bal.ASC_ONDA_MIN, int(s["prestigio"]["ultima_onda_asc"]) * 2)
		var pr: Dictionary = s["prestigio"]
		_marcar(marcos, "1a ascensao", t, int(pr["ascensoes"]) >= 1)
		_marcar(marcos, "8 ascensoes (porta da Singularidade)", t, int(pr["ascensoes"]) >= Bal.SING_ASC_MIN)
		_marcar(marcos, "onda 150 (porta da Singularidade)", t, int(s["onda_maxima_global"]) >= Bal.SING_ONDA_MIN)
		_marcar(marcos, "1a singularidade", t, int(pr["singularidades"]) >= 1)
		_marcar(marcos, "5 singularidades (porta da Transcendencia)", t, int(pr["singularidades"]) >= Bal.TRANS_SING_MIN)
		_marcar(marcos, "onda 500 (porta da Transcendencia)", t, int(s["onda_maxima_global"]) >= Bal.TRANS_ONDA_MIN)
		_marcar(marcos, "1a transcendencia", t, int(pr.get("transcendencias", 0)) >= 1)
		_marcar(marcos, "metade das conquistas", t, s["conquistas"].size() * 2 >= Dados.conquistas.size())
		_marcar(marcos, "todas as conquistas", t, s["conquistas"].size() >= Dados.conquistas.size())
		_marcar(marcos, "nivel 500 da torre", t, int(s["nivel"]) >= Bal.NIVEL_MAX)
		if i % 216000 == 0 and i > 0:
			print("  %s | onda %d (recorde global %d) | asc %d | sing %d | trans %d | conq %d/%d | nivel %d" % [
				_hm(t), int(s["onda"]), int(s["onda_maxima_global"]), int(pr["ascensoes"]),
				int(pr["singularidades"]), int(pr.get("transcendencias", 0)),
				s["conquistas"].size(), Dados.conquistas.size(), int(s["nivel"])])

	print("")
	print("=== QUANDO CADA COISA ACONTECEU PELA PRIMEIRA VEZ ===")
	for k in marcos:
		print("  %-42s %s" % [k, _hm(float(marcos[k]))])
	var s2: Dictionary = j.s
	var pr2: Dictionary = s2["prestigio"]
	print("")
	print("=== AO FIM DE %.1f h ===" % horas)
	print("onda recorde: %d | ascensoes: %d | singularidades: %d | transcendencias: %d" % [
		int(s2["onda_maxima_global"]), int(pr2["ascensoes"]), int(pr2["singularidades"]),
		int(pr2.get("transcendencias", 0))])
	print("conquistas: %d de %d | nivel da torre: %d de %d | cartas vistas: %d de %d" % [
		s2["conquistas"].size(), Dados.conquistas.size(), int(s2["nivel"]), Bal.NIVEL_MAX,
		s2["album"].size() if s2.has("album") else 0, Dados.cartas.size()])
	var faltam: Array = []
	for nome in ["1a ascensao", "1a singularidade", "1a transcendencia", "todas as conquistas", "nivel 500 da torre"]:
		if not marcos.has(nome):
			faltam.append(nome)
	print("nao alcancado em %.1f h: %s" % [horas, str(faltam) if not faltam.is_empty() else "nada"])

func _marcar(m: Dictionary, chave: String, t: float, cond: bool) -> void:
	if cond and not m.has(chave):
		m[chave] = t

func _hm(t: float) -> String:
	var h := int(t) / 3600
	var mi := (int(t) % 3600) / 60
	if h > 0:
		return "%dh %02dm" % [h, mi]
	return "%dm %02ds" % [mi, int(t) % 60]
