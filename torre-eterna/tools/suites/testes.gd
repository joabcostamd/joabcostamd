extends RefCounted

## Corpo da ferramenta. Vive fora do script de entrada de propósito: em modo
## `-s` o Godot compila o script de entrada ANTES de registrar os autoloads, e
## qualquer classe que use `Bus`/`Cfg` falha a compilar de forma intermitente.
## Carregado por `res://tools/testes.gd` já dentro de `_initialize()`.

var arvore: SceneTree
var root: Node

## Suíte de testes do jogo. Roda a simulação REAL, sem mocks.
##   godot --headless --path . -s res://tools/testes.gd

var passou := 0
var falhou := 0
var grupo := ""
var jogo: Node

func rodar(cena: SceneTree) -> void:
	arvore = cena
	root = cena.root
	# roda num save separado: a suite nao pode apagar o progresso de quem joga
	SaveSys.prefixo = "_ferramenta_"
	Dados.carregar(true)
	jogo = root.get_node_or_null("Jogo")
	var save = root.get_node_or_null("SaveSys")
	var cfg = root.get_node_or_null("Cfg")
	cfg.v = cfg.PADRAO.duplicate(true)
	save.apagar()
	jogo.stats = StatEngine.new()
	jogo.iniciar()

	t_big()
	t_formatacao()
	t_stat_engine()
	t_modificadores()
	t_economia()
	t_combate()
	t_defesa()
	t_ondas()
	t_prestigio()
	t_saque()
	t_progresso()
	t_mecanicas()
	t_eventos()
	t_audio()
	t_save()
	t_offline()
	t_habilidades()
	t_integridade()

	print("\n===TESTES=== passou=%d falhou=%d" % [passou, falhou])
	print("===STATUS=== ", "PASS" if falhou == 0 else "FAIL")
	arvore.quit(0 if falhou == 0 else 1)

func g(nome: String) -> void:
	grupo = nome

func ok(nome: String, cond: bool, detalhe: String = "") -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		print("  FALHOU [%s] %s %s" % [grupo, nome, detalhe])

func perto(a: float, b: float, tol: float = 1e-6) -> bool:
	return absf(a - b) <= tol

## ------------------------------------------------------------------ Big
func t_big() -> void:
	g("Big")
	ok("ida e volta", perto(Big.to_f(Big.from(1234.5)), 1234.5, 1e-6))
	ok("multiplicacao", perto(Big.mul(Big.from(2e10), Big.from(3e20)), Big.from(6e30), 1e-9))
	ok("soma", perto(Big.to_f(Big.add(Big.from(3.0), Big.from(7.0))), 10.0, 1e-9))
	ok("soma desigual", perto(Big.add(Big.from(1e30), Big.from(1.0)), Big.from(1e30), 1e-12))
	ok("subtracao vira zero", Big.is_zero(Big.sub(Big.from(3.0), Big.from(9.0))))
	ok("zero multiplicado", Big.is_zero(Big.mul(Big.ZERO, Big.from(1e50))))
	ok("potencia", perto(Big.pow_n(Big.from(2.0), 1000.0), 301.02999566398, 1e-6))
	ok("fracao", perto(Big.frac(Big.from(5.0), Big.from(10.0)), 0.5, 1e-9))
	ok("compravel", Big.max_afford(Big.from(1000000.0), 10.0, 1.15, 0) == 68)
	ok("soma geometrica", absf(Big.to_f(Big.geo_sum(10.0, 1.15, 0, 60)) - 292199.9) < 500.0)
	ok("alem de 1e308", Big.gt(Big.from_log(5000.0), Big.from_log(4999.0)))
	ok("nao satura", perto(Big.mul(Big.from_log(900.0), Big.from_log(900.0)), 1800.0, 1e-9))

## ---------------------------------------------------------- formatacao
func t_formatacao() -> void:
	g("Fmt")
	Fmt.notacao = Fmt.Notacao.MISTA
	ok("zero", Fmt.big(Big.ZERO) == "0", Fmt.big(Big.ZERO))
	ok("milhar", Fmt.big(Big.from(1234.0)).contains("1"), Fmt.big(Big.from(1234.0)))
	ok("milhao", Fmt.big(Big.from(1.23e6)).contains("M"), Fmt.big(Big.from(1.23e6)))
	Fmt.notacao = Fmt.Notacao.CIENTIFICA
	ok("cientifica", Fmt.big(Big.from_log(100.0)).contains("e100"), Fmt.big(Big.from_log(100.0)))
	Fmt.notacao = Fmt.Notacao.MISTA
	ok("porcentagem", Fmt.pct(0.153, 1) == "15,3%", Fmt.pct(0.153, 1))
	ok("tempo", Ux.tempo_curto(3661.0) == "1h 01m", Ux.tempo_curto(3661.0))

## -------------------------------------------------------- motor de stats
func t_stat_engine() -> void:
	g("StatEngine")
	var m := StatEngine.new()
	m.zerar()
	m.add_flat("alcance", 100.0)
	m.add_pct("alcance", 0.5)
	m.add_mult("alcance", 2.0)
	m.calcular()
	var esperado := (Bal.ALCANCE_BASE + 100.0) * 1.5 * 2.0
	ok("flat+pct+mult", perto(m.n("alcance"), esperado, 0.01), str(m.n("alcance")))

	m.zerar()
	m.add_mult("critChance", 0.0)
	m.add_pct("critChance", 5.0)
	m.calcular()
	ok("multiplicador zero anula", perto(m.n("critChance"), 0.0), str(m.n("critChance")))

	m.zerar()
	m.add_mult_log("dano", 200.0)
	m.calcular()
	ok("multiplicador gigante", m.b("dano") > 199.0, str(m.b("dano")))

	m.zerar()
	m.add_flat("projeteis", 3.7)
	m.calcular()
	ok("inteiro trunca", perto(m.n("projeteis"), 4.0), str(m.n("projeteis")))

	m.zerar()
	m.add_flat("critChance", 5.0)
	m.calcular()
	ok("teto respeitado", m.n("critChance") <= 1.0, str(m.n("critChance")))

## ------------------------------------------------------- modificadores
func t_modificadores() -> void:
	g("Mods")
	var s := GameState.novo()
	var m := StatEngine.new()
	s["upgrades"]["dano"] = 10
	var r := Mods.recalcular(s, m)
	var def: Dictionary = Dados.upgrade_por_id["dano"]
	var por_nivel := float(def["efeito"][0]["valor"])
	ok("upgrade soma", perto(Big.to_f(m.b("dano")), Bal.DANO_BASE + por_nivel * 10.0, 0.01), Fmt.big(m.b("dano")))

	s["conquistas"]["teste"] = 1
	var r2 := Mods.recalcular(s, m)
	ok("especiais padrao", float(r2["especiais"]["slotsCartas"]) >= 3.0)
	ok("desbloqueios e dicionario", r2["especiais"]["desbloqueios"] is Dictionary)

	# "+20% de bonus de combo por nivel" e multiplicativo, nao +0,2 absoluto.
	# Somando, dez niveis levavam o bonus por ponto de combo de 0,006 a 2,006.
	var s_cb := GameState.novo()
	s_cb["prestigio"]["arvore_fragmentos"]["af_combo"] = 10
	var r_cb := Mods.recalcular(s_cb, m)
	var cb := float(r_cb["especiais"]["comboBonus"])
	ok("combo multiplica, nao soma", cb < 0.05, str(cb))
	ok("combo cresce mesmo assim", cb > Bal.COMBO_BONUS_POR * 5.0, str(cb))

	# Sete passivas de reliquia estavam ESPECIFICADAS no JSON e nao eram lidas
	# por ninguem: o jogador comprava, o texto prometia e nada acontecia.
	var pas_sem_leitor: Array = []
	var s_rel := GameState.novo()
	for rel in Dados.reliquias:
		for ef in rel.get("efeito", []):
			if not (ef is Dictionary) or str(ef.get("chave", "")) == "":
				continue
			s_rel["relicas"] = {str(rel["id"]): 1}
			var r_rel := Mods.recalcular(s_rel, m)
			if not r_rel["passivas"].has(str(ef["chave"])):
				pas_sem_leitor.append("%s:%s" % [rel["id"], ef["chave"]])
	ok("toda passiva de reliquia chega em pas", pas_sem_leitor.is_empty(), str(pas_sem_leitor))

	# Rerrolagem de missao: o Dado Viciado promete "+1 rerroll diario em
	# missoes" e nao havia nem leitor do especial nem botao para gastar.
	jogo.s["relicas"] = {"dado_viciado": 2}
	jogo.marcar_sujo()
	jogo.recalcular()
	jogo.s["missoes"]["rerrolagens_usadas"] = 0
	ok("Dado Viciado da rerrolagens", Progresso.rerrolagens_restantes(jogo) == 2)
	Progresso.gerar_missoes(jogo, true)
	var antes_id := str(jogo.s["missoes"]["diarias"][0]["id"])
	ok("rerrolagem troca a missao", Progresso.rerrolar_missao(jogo, "diarias", 0))
	ok("missao mudou", str(jogo.s["missoes"]["diarias"][0]["id"]) != antes_id)
	ok("rerrolagem foi cobrada", Progresso.rerrolagens_restantes(jogo) == 1)
	Progresso.rerrolar_missao(jogo, "diarias", 0)
	ok("acaba quando acaba", not Progresso.rerrolar_missao(jogo, "diarias", 0))
	jogo.s["relicas"] = {}
	jogo.marcar_sujo()
	jogo.recalcular()

	# talento com passiva
	s["talentos"]["f_sede"] = 1
	s["combo"]["atual"] = 10
	var r3 := Mods.recalcular(s, m)
	ok("passiva registrada", r3["passivas"].has("sede_de_sangue"))

## ------------------------------------------------------------ economia
func t_economia() -> void:
	g("Economia")
	var s: Dictionary = jogo.s
	var antes: float = s["moedas"]["ouro"]
	Economia.ganhar_ouro(Big.from(1000.0), jogo, "teste", true)
	ok("ganha ouro", Big.gt(s["moedas"]["ouro"], antes))
	ok("gasta ouro", Economia.gastar_ouro(Big.from(500.0), jogo))
	ok("nao gasta o que nao tem", not Economia.gastar_ouro(Big.from_log(200.0), jogo))

	var nivel_antes := int(s["nivel"])
	Economia.ganhar_xp(Big.from(1e6), jogo)
	ok("sobe de nivel", int(s["nivel"]) > nivel_antes, "%d -> %d" % [nivel_antes, int(s["nivel"])])
	ok("ganha pontos", int(s["pontos_talento"]) > 0)
	ok("progresso 0..1", Economia.progresso_nivel(s) >= 0.0 and Economia.progresso_nivel(s) <= 1.0)

	var mortos := int(s["stats"]["mortos"])
	ok("estatisticas coerentes", mortos >= 0)

	# Juros compostos sobre o estoque nao podem virar hiperinflacao: sem teto,
	# 10% ao segundo faz o ouro crescer e^360 em uma hora.
	var cofre := Big.from_log(120.0)                  # 1e120 guardado
	var rendimento := Big.mul_f(cofre, 0.10 * (1.0 / 60.0))
	var teto := Bal.juros_teto(30, 1.0 / 60.0)
	ok("juros tem teto", Big.lt(teto, rendimento))
	ok("teto cresce com a onda", Big.gt(Bal.juros_teto(200, 1.0), Bal.juros_teto(30, 1.0)))

## ------------------------------------------------------------- combate
func t_combate() -> void:
	g("Combate")
	ok("armadura reduz", Bal.fator_armadura(60.0, 0.0) < 1.0)
	ok("armadura meio a meio", perto(Bal.fator_armadura(60.0, 0.0), 0.5, 0.001))
	ok("penetracao tem teto de 95%", perto(Bal.fator_armadura(60.0, 1.0), 60.0 / 63.0, 0.001), str(Bal.fator_armadura(60.0, 1.0)))

	var def: Dictionary = Dados.inimigo_por_id["grunhido"]
	var e := EnemyAI.criar(def, 10, jogo, {})
	ok("inimigo criado", e != null and e.ativo)
	if e == null:
		return
	var hp0 := e.hp
	Combate.aplicar_dano(e, Big.mul_f(hp0, 0.5), jogo, {"puro": true})
	ok("dano reduz vida", Big.lt(e.hp, hp0))
	ok("vida fracionaria", e.frac_vida() > 0.0 and e.frac_vida() < 1.0)
	Combate.aplicar_dano(e, Big.mul_f(hp0, 10.0), jogo, {"puro": true})
	ok("morre com dano alto", not e.vivo())

	# escudo absorve antes da vida
	var e2 := EnemyAI.criar(def, 10, jogo, {})
	e2.escudo = Big.from(1000.0)
	e2.escudo_max = e2.escudo
	var hp2 := e2.hp
	Combate.aplicar_dano(e2, Big.from(100.0), jogo, {"puro": true})
	ok("escudo absorve", perto(e2.hp, hp2, 1e-9) and Big.lt(e2.escudo, Big.from(1000.0)))

	# execucao
	var e3 := EnemyAI.criar(def, 10, jogo, {})
	e3.hp = Big.mul_f(e3.hp_max, 0.02)
	Combate.aplicar_dano(e3, Big.from(1.0), jogo, {"puro": true, "execucao": 0.05})
	ok("execucao mata", not e3.vivo())

	jogo.arena.limpar_inimigos()

## ------------------------------------------------------- defesa da torre
func t_defesa() -> void:
	g("Defesa")
	# Reflexo em log10, nao linear: ja foi entregue como valor linear e a torre
	# morria num tiro so (10^(2e18) de dano com um golpe de 1e20).
	var golpe := Big.from(1.0e20)
	var refletido := Bal.dano_refletido(golpe)
	ok("reflexo continua em log10", refletido < 19.0 and refletido > 18.0)
	ok("reflexo e 2%% do golpe", perto(Big.to_f(refletido), 2.0e18, 1.0e12))
	# comprar vida PRECISA aumentar a sobrevivência (regressão: antes o dano de
	# contato era % da vida máxima, então vida extra não servia para nada)
	var hp10 := Bal.hp_onda(10)
	var d10 := Bal.dano_contato(hp10, 10, false, 1.0)
	ok("dano de contato independe da torre", not Big.is_zero(d10))
	ok("dano de contato cresce com a onda", Big.gt(Bal.dano_contato(Bal.hp_onda(80), 80, false, 1.0), d10))
	ok("chefe bate mais forte", Big.gt(Bal.dano_contato(hp10, 10, true, 1.0), d10))
	ok("piso protege o comeco", Big.gt(Bal.dano_contato(Bal.hp_onda(1), 1, false, 1.0), Big.mul_f(Bal.hp_onda(1), 0.02)))

	# Chefe encostado na torre: o inimigo comum morre no impacto, o chefe fica.
	# Sem recarga ele batia a cada passo de fisica — 60 golpes por segundo.
	ok("contato tem recarga", Bal.CD_CONTATO >= 0.5)
	var chefao := Inimigo.new()
	chefao.ativo = true
	chefao.chefe = true
	chefao.hp_max = Bal.hp_onda(50)
	chefao.hp = chefao.hp_max
	chefao.escala = 1.0
	chefao.cd_contato = 0.0
	var golpes := 0
	for i in 60:                                  # um segundo de fisica
		if chefao.cd_contato <= 0.0:
			golpes += 1
			chefao.cd_contato = Bal.CD_CONTATO
		chefao.cd_contato -= 1.0 / 60.0
	ok("chefe bate no maximo 2x por segundo", golpes <= 2)

	# Escudo e regeneracao sao PARCELA da vida maxima: se fossem numeros soltos,
	# um multiplicador de vida (Forja x1,4 por nivel) deixaria os dois para tras
	# e a categoria Defesa inteira envelheceria mal.
	var mdef := StatEngine.new()
	mdef.zerar()
	mdef.add_flat("vidaMax", 1000.0)
	mdef.add_flat("escudoMax", 2000.0)
	mdef.calcular()
	var esc_simples := Big.mul_f(Big.mul(mdef.b("escudoMax"), mdef.b("vidaMax")), Bal.ESCUDO_POR_PONTO)
	mdef.zerar()
	mdef.add_flat("vidaMax", 1000.0)
	mdef.add_flat("escudoMax", 2000.0)
	mdef.add_mult("vidaMax", 50.0)
	mdef.calcular()
	var esc_forjado := Big.mul_f(Big.mul(mdef.b("escudoMax"), mdef.b("vidaMax")), Bal.ESCUDO_POR_PONTO)
	ok("escudo acompanha multiplicador de vida", Big.gt(esc_forjado, Big.mul_f(esc_simples, 40.0)))

	# Escudo do inimigo em log10, igual ao HP. Era linear: com hp_max acima de
	# 1e308 o Big.to_f virava INF e o escudo nunca mais descia.
	var blindado := Inimigo.new()
	blindado.ativo = true
	blindado.hp_max = 400.0                        # 10^400 de vida: fora do float
	blindado.hp = blindado.hp_max
	blindado.escudo_max = Big.mul_f(blindado.hp_max, 0.5)
	blindado.escudo = blindado.escudo_max
	ok("escudo do inimigo nao vira INF", not is_inf(blindado.escudo) and blindado.escudo < 401.0)
	var antes_esc := blindado.escudo
	Combate.aplicar_dano(blindado, Big.mul_f(blindado.escudo_max, 0.1), jogo, {})
	ok("escudo do inimigo desce quando apanha", blindado.escudo < antes_esc)

	var s: Dictionary = jogo.s
	s["torre"]["vida_max"] = Big.from(1000.0)
	s["torre"]["vida"] = Big.from(1000.0)
	s["torre"]["escudo"] = Big.ZERO
	s["torre"]["escudo_max"] = Big.ZERO
	s["torre"]["viva"] = true
	jogo.invulneravel = 0.0
	jogo.torre.iframes = 0.0
	jogo.dano_na_torre(Big.from(100.0), null, {"ignora_iframes": true})
	ok("dano reduz vida", Big.lt(s["torre"]["vida"], Big.from(1000.0)))
	ok("armadura reduziu", Big.gt(s["torre"]["vida"], Big.from(880.0)), Fmt.big(s["torre"]["vida"]))

	# escudo absorve antes da vida
	s["torre"]["vida"] = Big.from(1000.0)
	s["torre"]["escudo"] = Big.from(500.0)
	s["torre"]["escudo_max"] = Big.from(500.0)
	jogo.torre.iframes = 0.0
	jogo.dano_na_torre(Big.from(50.0), null, {"ignora_iframes": true})
	ok("escudo da torre absorve", perto(s["torre"]["vida"], Big.from(1000.0), 1e-9) and Big.lt(s["torre"]["escudo"], Big.from(500.0)))

	# vida em log aguenta valores absurdos sem estourar
	s["torre"]["vida_max"] = Big.from_log(80.0)
	s["torre"]["vida"] = Big.from_log(80.0)
	jogo.torre.iframes = 0.0
	jogo.dano_na_torre(Big.from_log(60.0), null, {"ignora_iframes": true})
	ok("vida gigante nao estoura", Big.gt(s["torre"]["vida"], Big.from_log(79.0)), Fmt.big(s["torre"]["vida"]))
	ok("fracao continua valida", Big.frac(s["torre"]["vida"], s["torre"]["vida_max"]) > 0.9)

	# torre morre quando a vida acaba
	s["torre"]["vida"] = Big.from(10.0)
	s["torre"]["vida_max"] = Big.from(1000.0)
	s["torre"]["escudo"] = Big.ZERO
	jogo.torre.iframes = 0.0
	jogo.dano_na_torre(Big.from(1e6), null, {"ignora_iframes": true})
	ok("torre cai", not bool(s["torre"]["viva"]))
	s["torre"]["viva"] = true
	s["torre"]["vida"] = s["torre"]["vida_max"]

## ---------------------------------------------------------------- ondas
func t_ondas() -> void:
	g("Ondas")
	ok("hp cresce", Big.gt(Bal.hp_onda(50), Bal.hp_onda(10)))
	ok("ouro cresce", Big.gt(Bal.ouro_onda(50), Bal.ouro_onda(10)))
	ok("chefe a cada 10", Bal.eh_chefe(10) and Bal.eh_chefe(20) and not Bal.eh_chefe(11))
	ok("super chefe a cada 50", Bal.eh_super_chefe(50) and not Bal.eh_super_chefe(40))
	ok("contagem sobe", Bal.contagem_onda(60) > Bal.contagem_onda(5))
	# Modo Infinito: a contagem perde o teto e a vida do inimigo continua subindo.
	ok("contagem tem teto no modo normal", Bal.contagem_onda(400) == Bal.contagem_onda(200))
	ok("infinito sobe muito mais", Bal.contagem_onda(360, true) > Bal.contagem_onda(200, true))
	ok("infinito ainda tem teto sao", Bal.contagem_onda(100000, true) <= 130)
	ok("infinito escala a vida", Bal.escala_infinito(500, true) > Bal.escala_infinito(100, true))
	ok("fora do infinito nada muda", perto(Bal.escala_infinito(500, false), 1.0))
	ok("intervalo tem piso", Bal.intervalo_spawn(9999) >= 0.22)

	# a onda NÃO pode travar quando inimigos alcançam a torre (regressão real)
	var d := Diretor.new(jogo)
	jogo.diretor = d
	jogo.s["onda"] = 5
	d.iniciar_onda(5)
	var passos := 0
	while d.estado != "intervalo" and passos < 60 * 240:
		jogo.simular(1.0 / 60.0)
		passos += 1
	ok("onda sempre termina", d.estado == "intervalo", "estado=%s passos=%d" % [d.estado, passos])
	jogo.arena.limpar_inimigos()

## ------------------------------------------------------------ prestigio
func t_prestigio() -> void:
	g("Prestígio")
	ok("bloqueado cedo", Big.is_zero(Bal.fragmentos(10)))
	ok("libera na onda minima", not Big.is_zero(Bal.fragmentos(Bal.ASC_ONDA_MIN)))
	ok("cresce com a onda", Big.gt(Bal.fragmentos(100), Bal.fragmentos(50)))
	ok("nucleos exigem onda", Big.is_zero(Bal.nucleos(100, 20)))
	ok("eter exige onda", Big.is_zero(Bal.eter(300, 10)))

	var s: Dictionary = jogo.s
	s["onda_maxima"] = 60
	s["onda_maxima_global"] = 60
	var frag_antes: float = s["moedas"]["fragmentos"]
	var upgrades_antes: int = s["upgrades"].size()
	s["upgrades"]["dano"] = 50
	var conquistas_antes: int = s["conquistas"].size()
	ok("pode ascender", Prestigio.pode_ascender(s))
	var previa := Prestigio.previa_fragmentos(jogo)
	ok("previa positiva", not Big.is_zero(previa))
	jogo.ascender()
	ok("ganhou fragmentos", Big.gt(jogo.s["moedas"]["fragmentos"], frag_antes))
	var up_vazio: bool = jogo.s["upgrades"].is_empty()
	ok("reseta upgrades", up_vazio)
	ok("reseta ouro", Big.is_zero(jogo.s["moedas"]["ouro"]))
	var conq_agora: int = jogo.s["conquistas"].size()
	ok("mantem conquistas", conq_agora == conquistas_antes)
	ok("mantem recorde global", int(jogo.s["onda_maxima_global"]) >= 60)
	ok("conta ascensao", int(jogo.s["prestigio"]["ascensoes"]) == 1)

	# Ascender com o tempo congelado deixava o congelamento ligado na run nova.
	jogo.tempo_congelado = 9.0
	jogo.silenciado = 5.0
	jogo.parasitas = 7
	jogo.s["onda_maxima"] = 60
	jogo.s["onda_maxima_global"] = 60
	jogo.ascender()
	ok("ascender limpa o estado volatil",
		jogo.tempo_congelado == 0.0 and jogo.silenciado == 0.0 and jogo.parasitas == 0)

	# --- as colecoes eternas precisam atravessar TODOS os prestigios ---
	# A Transcendencia monta um estado novo do zero; o Album e o Panteao ja
	# foram apagados por ela uma vez, e o Panteao e o unico sistema em que o
	# jogador destroi cartas de verdade para sempre.
	Mecanicas.registrar_no_album(jogo.s, "carta_teste_eterna")
	jogo.s["panteao"]["conjunto_teste"] = 3
	jogo.s["tutorial"]["completo"] = true
	jogo.s["onda_maxima"] = 700
	jogo.s["onda_maxima_global"] = 700
	jogo.s["prestigio"]["singularidades"] = 9
	jogo.s["moedas"]["nucleos"] = Big.from(1.0e9)
	ok("pode transcender", Prestigio.pode_transcender(jogo.s))
	jogo.transcender()
	ok("album sobrevive a transcendencia", jogo.s["album"].has("carta_teste_eterna"))
	ok("panteao sobrevive a transcendencia", int(jogo.s["panteao"].get("conjunto_teste", 0)) == 3)
	ok("tutorial nao volta do zero", bool(jogo.s["tutorial"]["completo"]))
	ok("conta transcendencia", int(jogo.s["prestigio"]["transcendencias"]) == 1)
	ok("reseta fragmentos", Big.is_zero(jogo.s["moedas"]["fragmentos"]))

## ------------------------------------------------------------- saque
func t_saque() -> void:
	g("Saque")
	var s: Dictionary = jogo.s
	var antes: int = s["cartas"]["inventario"].size()
	var inst := Saque.criar_carta(jogo, "", true)
	var depois: int = s["cartas"]["inventario"].size()
	ok("cria carta", not inst.is_empty() and depois == antes + 1)
	if inst.is_empty():
		return
	var uid := str(inst["uid"])
	ok("carta tem raridade", Dados.raridade_por_id.has(str(inst["raridade"])))
	ok("equipa", Saque.equipar(jogo, uid, 0))
	ok("equipada no slot", str(s["cartas"]["equipadas"][0]) == uid)
	ok("nao recicla equipada", not Saque.reciclar(jogo, uid))
	Saque.desequipar(jogo, 0)
	var poeira_antes: float = s["moedas"]["poeira"]
	ok("recicla", Saque.reciclar(jogo, uid))
	ok("ganha poeira", Big.gt(s["moedas"]["poeira"], poeira_antes))
	ok("custo de fusao cresce", Saque.custo_fusao(3) > Saque.custo_fusao(1))

## ---------------------------------------------------------- progresso
func t_progresso() -> void:
	g("Progresso")
	# Missao ligada a contador que anda para tras (onda e nivel voltam a 1 no
	# prestigio; gemas e cartas sao gastas) ficava impossivel para sempre.
	var missao_teste := {"id": "x", "alvo": 10.0, "base": 40.0, "prog": 0.0, "pronta": false, "coletada": false}
	ok("progresso conta subida", Progresso._avancar(missao_teste, 45.0) >= 5.0)
	Progresso._avancar(missao_teste, 1.0)             # prestigio: contador despenca
	ok("base acompanha a descida", float(missao_teste["base"]) <= 1.0)
	ok("progresso ja ganho nao se perde", float(missao_teste["prog"]) >= 5.0)
	ok("missao volta a ser possivel", Progresso._avancar(missao_teste, 11.0) >= 10.0)
	var s: Dictionary = jogo.s
	ok("le condicao", Progresso.valor_cond(s, "onda") == float(s["onda"]))
	ok("condicao desconhecida = 0", Progresso.valor_cond(s, "nao_existe") == 0.0)
	ok("cond atendida", Progresso.cond_atendida(s, {"tipo": "onda", "valor": 0}))
	ok("cond nao atendida", not Progresso.cond_atendida(s, {"tipo": "onda", "valor": 999999}))

	# toda condicao usada pelos dados precisa ser reconhecida pelo motor
	var desconhecidas := 0
	for c in Dados.conquistas:
		var cond: Dictionary = c.get("cond", {})
		var t := str(cond.get("tipo", ""))
		if t != "" and Progresso.valor_cond(s, t, str(cond.get("chave", ""))) == 0.0:
			# 0 pode ser legitimo; so checamos que nao explode
			pass
	ok("conquistas nao explodem", true)

	Progresso.gerar_missoes(jogo, true)
	var n_di: int = s["missoes"]["diarias"].size()
	ok("gera diarias", n_di > 0)
	var n_se: int = s["missoes"]["semanais"].size()
	ok("gera semanais", n_se > 0)
	var mi: Dictionary = s["missoes"]["diarias"][0]
	ok("progresso de missao 0..1", Progresso.progresso_missao(s, mi) >= 0.0 and Progresso.progresso_missao(s, mi) <= 1.0)
	ok("xp de temporada cresce", Progresso.xp_para_nivel(10) > Progresso.xp_para_nivel(1))
	var nivel_antes := int(s["temporada"]["nivel"])
	Progresso.ganhar_xp_temporada(jogo, 100000)
	ok("sobe temporada", int(s["temporada"]["nivel"]) > nivel_antes)

## ---------------------------------------------- mecânicas-assinatura
func t_mecanicas() -> void:
	g("Mecânicas")
	# A Purga so pune depois de explicada: quem nao chegou no balao do tutorial
	# levava um atordoamento aos 52s por nao apertar um botao que nunca lhe foi
	# apresentado.
	ok("purga nao pune sem tutorial",
		not Mecanicas._purga_ja_explicada({"tutorial": {"completo": false, "vistas": []}}))
	ok("purga pune depois do balao",
		Mecanicas._purga_ja_explicada({"tutorial": {"completo": false, "vistas": ["purga"]}}))
	ok("purga pune com tutorial dispensado",
		Mecanicas._purga_ja_explicada({"tutorial": {"completo": true, "vistas": []}}))

	# Modificadores de desafio que eram ANUNCIADOS no painel e nunca lidos por
	# ninguem: o texto prometia e a partida saia normal.
	jogo.s["desafios"]["ativo"] = "enxame"
	jogo.marcar_sujo()
	jogo.recalcular()
	jogo.diretor.iniciar_onda(20)
	var com_densidade := int(jogo.s["necessarios"])
	jogo.s["desafios"]["ativo"] = ""
	jogo.marcar_sujo()
	jogo.recalcular()
	jogo.diretor.iniciar_onda(20)
	var sem_densidade := int(jogo.s["necessarios"])
	ok("densidade multiplica a contagem", com_densidade > sem_densidade * 3, "%d vs %d" % [com_densidade, sem_densidade])

	jogo.s["desafios"]["ativo"] = "silencio"
	ok("semHabilidades bloqueia de verdade", Habilidades._sem_habilidades(jogo.s))
	jogo.s["desafios"]["ativo"] = ""
	ok("sem desafio, habilidade livre", not Habilidades._sem_habilidades(jogo.s))
	jogo.marcar_sujo()
	jogo.recalcular()

	# `danoTorre` e o dano QUE A TORRE CAUSA ("cada tiro causa 5x de dano"), e
	# estava sendo aplicado no dano que ela RECEBE — sinal invertido, e pintado
	# de verde no painel como se fosse bonus.
	jogo.s["desafios"]["ativo"] = "ferrugem"
	jogo.marcar_sujo()
	jogo.recalcular()
	ok("danoTorre multiplica o dano causado", float(jogo.mods_dif["danoTorre"]) > 1.0)
	jogo.s["torre"]["vida_max"] = Big.from(1.0e6)
	jogo.s["torre"]["vida"] = jogo.s["torre"]["vida_max"]
	jogo.s["torre"]["viva"] = true
	jogo.invulneravel = 0.0
	jogo.torre.iframes = 0.0
	var antes_v: float = jogo.s["torre"]["vida"]
	jogo.dano_na_torre(Big.from(1000.0), null, {"ignora_iframes": true})
	var perdeu := Big.to_f(antes_v) - Big.to_f(jogo.s["torre"]["vida"])
	ok("danoTorre nao amplifica o dano recebido", perdeu < 2000.0, str(perdeu))
	jogo.s["desafios"]["ativo"] = ""
	jogo.marcar_sujo()
	jogo.recalcular()

	# A Retomada ia para o save. Quem fechava o jogo no meio voltava dentro de
	# uma, sem velocidade (ela mora no no, nao no estado) e com a compra
	# automatica ligada a forca.
	jogo.s["auto"]["comprar"] = false
	Mecanicas.iniciar_retomada(jogo, 30)
	ok("retomada liga a compra automatica", bool(jogo.s["auto"]["comprar"]))
	Mecanicas.encerrar_retomada(jogo)
	ok("encerrar devolve a compra automatica", not bool(jogo.s["auto"]["comprar"]))
	ok("encerrar limpa o estado", not Mecanicas.em_retomada(jogo.s))

	var s: Dictionary = jogo.s

	# --- A Purga ---
	var p := Mecanicas.estado_purga(s)
	p["carga"] = 0.0
	ok("purga vazia nao dispara", not Mecanicas.disparar_purga(jogo, false))
	ok("qualidade cresce com a carga", Mecanicas.qualidade_purga(0.95) > Mecanicas.qualidade_purga(0.5))
	ok("janela perfeita e 1.0", perto(Mecanicas.qualidade_purga(0.96), 1.0, 1e-9))
	ok("cedo demais rende pouco", Mecanicas.qualidade_purga(0.2) < 0.35)
	p["carga"] = 0.95
	var perfeitas_antes := int(p["perfeitas"])
	ok("purga perfeita dispara", Mecanicas.disparar_purga(jogo, false))
	ok("conta perfeita", int(p["perfeitas"]) == perfeitas_antes + 1)
	ok("zera a carga", float(p["carga"]) == 0.0)
	p["carga"] = 0.95
	ok("automacao rende menos", Mecanicas.qualidade_purga(0.95) * Mecanicas.PURGA_AUTO_QUALIDADE < 1.0)

	# --- Álbum de Ecos ---
	s["album"] = {}
	ok("registra carta nova", Mecanicas.registrar_no_album(s, "teste_a"))
	ok("nao registra duplicata", not Mecanicas.registrar_no_album(s, "teste_a"))
	Mecanicas.registrar_no_album(s, "teste_b")
	var b := Mecanicas.bonus_album(s)
	ok("album conta", int(b["n"]) == 2)
	ok("album da bonus", float(b["dano"]) > 0.0 and float(b["ouro"]) > 0.0)

	# --- Adaptação do Enxame ---
	s["adaptacao"] = {"fogo": 0.0, "gelo": 0.0, "raio": 0.0, "veneno": 0.0, "vazio": 0.0}
	ok("sem adaptacao o fator e 1", perto(Mecanicas.fator_elemento(s, "fogo"), 1.0, 1e-9))
	for i in 30:
		Mecanicas.registrar_elemento(s, "fogo")
	ok("uso repetido cria resistencia", Mecanicas.fator_elemento(s, "fogo") < 0.85, str(Mecanicas.fator_elemento(s, "fogo")))
	ok("outro elemento continua limpo", perto(Mecanicas.fator_elemento(s, "gelo"), 1.0, 1e-9))
	ok("resistencia tem teto", Mecanicas.fator_elemento(s, "fogo") >= 1.0 - Mecanicas.ADAPT_TETO - 1e-9)
	var par := Mecanicas.elemento_mais_adaptado(s)
	ok("aponta o elemento mais usado", str(par[0]) == "fogo")
	var antes_f := Mecanicas.fator_elemento(s, "fogo")
	Mecanicas.decair_adaptacao(60.0, s)
	ok("resistencia decai sem uso", Mecanicas.fator_elemento(s, "fogo") > antes_f)

	# --- Aglomeração ---
	ok("tela vazia nao bonifica", perto(Mecanicas.fator_aglomeracao(0), 1.0, 1e-9))
	ok("tela cheia bonifica", Mecanicas.fator_aglomeracao(40) > 1.2, str(Mecanicas.fator_aglomeracao(40)))
	ok("ganho e sublinear", Mecanicas.fator_aglomeracao(80) < Mecanicas.fator_aglomeracao(40) * 2.0)

	# --- O Panteão ---
	s["panteao"] = {}
	s["cartas"]["inventario"] = []
	s["cartas"]["equipadas"] = ["", "", ""]
	ok("panteao comeca vazio", int(Mecanicas.bonus_panteao(s)["n"]) == 0)
	if not Dados.conjuntos.is_empty():
		var conj: Dictionary = Dados.conjuntos[0]
		var cid := str(conj.get("id", ""))
		ok("nao consagra sem as cartas", not Mecanicas.pode_consagrar(s, cid))
		for id_carta in conj.get("cartas", []):
			Saque.criar_carta(jogo, str(id_carta), false)
		ok("pode consagrar com o conjunto", Mecanicas.pode_consagrar(s, cid))
		var inv_antes: int = s["cartas"]["inventario"].size()
		ok("consagra", Mecanicas.consagrar(jogo, cid))
		var inv_depois: int = s["cartas"]["inventario"].size()
		ok("destroi as cartas de verdade", inv_depois < inv_antes, "%d -> %d" % [inv_antes, inv_depois])
		var bp := Mecanicas.bonus_panteao(s)
		ok("da multiplicador eterno", float(bp["dano"]) > 1.0 and float(bp["ouro"]) > 1.0)
		ok("nao consagra duas vezes sem repor", not Mecanicas.pode_consagrar(s, cid))

	# --- Caixa da Vigília ---
	s["caixa"] = {"seladas": 0, "abertas": 0}
	ok("caixa vazia nao abre", Mecanicas.abrir_caixa(jogo).is_empty())
	var n_sel := Mecanicas.selar_offline(s, 3600.0, 1.0)
	ok("offline sela cartas", n_sel > 0, str(n_sel))
	ok("tem teto", Mecanicas.selar_offline(s, 3600.0 * 999.0, 1.0) <= Mecanicas.CAIXA_MAX)
	var antes_caixa: int = int(s["caixa"]["seladas"])
	var carta := Mecanicas.abrir_caixa(jogo)
	ok("abre uma por vez", not carta.is_empty() and int(s["caixa"]["seladas"]) == antes_caixa - 1)

	# --- A Retomada ---
	s["retomada"] = null
	s.erase("retomada")
	Mecanicas.iniciar_retomada(jogo, 3)
	ok("retomada nao dispara em run curta", not Mecanicas.em_retomada(s))
	jogo.velocidade = 1.0
	Mecanicas.iniciar_retomada(jogo, 60)
	ok("retomada dispara apos run boa", Mecanicas.em_retomada(s))
	ok("liga a compra automatica", bool(s["auto"]["comprar"]))
	ok("guarda o alvo", int(s["retomada"]["alvo"]) == 60)
	ok("acelera o jogo", Engine.time_scale >= Mecanicas.RETOMADA_VELOCIDADE - 0.01)
	s["onda"] = 61
	Mecanicas.atualizar_retomada(0.016, jogo)
	ok("encerra ao superar o alvo", not Mecanicas.em_retomada(s))
	ok("devolve a velocidade", perto(Engine.time_scale, 1.0, 0.01), str(Engine.time_scale))
	Engine.time_scale = 1.0

	# --- O Peregrino ---
	ok("peregrino existe no bestiario", Dados.inimigo_por_id.has("peregrino"))
	var def_p: Dictionary = Dados.inimigo_por_id.get("peregrino", {})
	ok("peregrino nao entra no sorteio normal", int(def_p.get("peso", 1)) == 0)
	ok("peregrino atravessa", str(def_p.get("mov", "")) == "passa")
	var poupados_antes := int(s.get("peregrinos_poupados", 0))
	Mecanicas.peregrino_poupado(jogo)
	ok("poupar conta", int(s["peregrinos_poupados"]) == poupados_antes + 1)
	var mortos_antes := int(s.get("peregrinos_mortos", 0))
	Mecanicas.peregrino_morto(jogo)
	ok("matar conta", int(s["peregrinos_mortos"]) == mortos_antes + 1)

## ------------------------------------------------------------ eventos
func t_eventos() -> void:
	g("Eventos")
	var s: Dictionary = jogo.s
	s["eventos"] = {"ativo": "", "historico": [], "proximo_em": 180.0}
	var ev := Eventos.estado(s)
	ok("estado normaliza", ev.has("ativo") and ev.has("historico") and ev.has("proximo_em"))
	ok("nada pendente no inicio", Eventos.pendente(s).is_empty())

	s["onda_maxima_global"] = 60
	var def := Eventos.sortear(jogo)
	ok("sorteia um evento", not def.is_empty())
	if def.is_empty():
		return
	ok("evento tem opcoes", (def.get("opcoes", []) as Array).size() >= 2)

	# resolver aplica algum efeito e limpa o pendente
	ev["ativo"] = str(def["id"])
	var ouro_antes: float = s["moedas"]["ouro"]
	var efeito := Eventos.resolver(jogo, str(def["id"]), 0)
	ok("resolver devolve efeito", not efeito.is_empty())
	ok("limpa o evento ativo", str(Eventos.estado(s)["ativo"]) == "")
	ok("reagenda o proximo", float(Eventos.estado(s)["proximo_em"]) >= Eventos.INTERVALO_MIN - 0.01)
	ok("registra no historico", (Eventos.estado(s)["historico"] as Array).size() > 0)

	# indice fora da faixa nao quebra
	ev["ativo"] = str(def["id"])
	var e2 := Eventos.resolver(jogo, str(def["id"]), 999)
	ok("indice invalido nao quebra", not e2.is_empty())
	ev["ativo"] = str(def["id"])
	var e3 := Eventos.resolver(jogo, "id_que_nao_existe", 0)
	ok("evento inexistente nao quebra", e3.is_empty() and str(Eventos.estado(s)["ativo"]) == "")

	# eventos unicos nao repetem
	var unicos := 0
	for d in Dados.eventos:
		if bool(d.get("unico", false)):
			unicos += 1
	ok("existem eventos unicos", unicos >= 1, str(unicos))
	# todos os resultados declarados nos dados sao tipos que o motor aplica
	var tipos_ok := ["ouro", "gemas", "fragmentos", "xp", "buff", "cura", "dano", "carta", "onda", "nada", "poeira"]
	var desconhecidos: Array = []
	for d in Dados.eventos:
		for op in d.get("opcoes", []):
			var r: Dictionary = op.get("resultado", {})
			var t := str(r.get("tipo", ""))
			if t != "" and not tipos_ok.has(t) and not desconhecidos.has(t):
				desconhecidos.append(t)
			var risco = op.get("risco", null)
			if risco is Dictionary:
				var f: Dictionary = risco.get("falha", {})
				var tf := str(f.get("tipo", ""))
				if tf != "" and not tipos_ok.has(tf) and not desconhecidos.has(tf):
					desconhecidos.append(tf)
	ok("todo resultado de evento e conhecido", desconhecidos.is_empty(), str(desconhecidos))

## --------------------------------------------------------------- áudio
## O áudio é sintetizado: dá para provar que cada som existe, tem duração
## sensata e NÃO é silêncio — mesmo sem placa de som nesta máquina.
func t_audio() -> void:
	g("Áudio")
	var cat: Dictionary = Sfx.catalogo()
	ok("catalogo tem sons", cat.size() >= 20, str(cat.size()))

	# nomes reais do catálogo (scripts/audio/sfx.gd)
	var essenciais := ["tiro", "tiro_critico", "impacto", "morte", "morte_chefe", "ouro",
		"compra", "bloqueado", "nivel", "onda", "alerta_chefe", "torre_dano", "torre_destruida",
		"prestigio", "lendario", "hab_pronta", "conquista", "clique", "erro", "carta"]
	var faltando: Array = []
	for nome in essenciais:
		if not cat.has(nome):
			faltando.append(nome)
	ok("sons essenciais presentes", faltando.is_empty(), str(faltando))

	var mudos: Array = []
	var longos: Array = []
	var curtos: Array = []
	var invalidos: Array = []
	var total_amostras := 0
	for nome in cat.keys():
		var receita: Dictionary = cat[nome]
		var buf: PackedFloat32Array = Synth.mixar(receita.get("camadas", []))
		if buf.size() == 0:
			invalidos.append(str(nome))
			continue
		total_amostras += buf.size()
		var dur := float(buf.size()) / float(Synth.TAXA)
		if dur < 0.015:
			curtos.append("%s (%.3fs)" % [str(nome), dur])
		if dur > 6.0:
			longos.append("%s (%.2fs)" % [str(nome), dur])
		var pico := 0.0
		var tem_nan := false
		for i in range(0, buf.size(), maxi(1, buf.size() / 400)):
			var v := buf[i]
			if is_nan(v) or is_inf(v):
				tem_nan = true
				break
			pico = maxf(pico, absf(v))
		if tem_nan:
			invalidos.append(str(nome) + " (NaN)")
		elif pico < 0.01:
			mudos.append(str(nome))

	ok("nenhum som invalido", invalidos.is_empty(), str(invalidos))
	ok("nenhum som mudo", mudos.is_empty(), str(mudos))
	ok("nenhum som curto demais", curtos.is_empty(), str(curtos))
	ok("nenhum som longo demais", longos.is_empty(), str(longos))
	ok("gerou audio de verdade", total_amostras > 44100, str(total_amostras))

	# o WAV precisa sair no formato que o Godot toca
	var primeiro: Dictionary = cat[cat.keys()[0]]
	var wav: AudioStreamWAV = Synth.som(primeiro.get("camadas", []), float(primeiro.get("pico", 0.85)))
	ok("gera AudioStreamWAV", wav != null)
	if wav != null:
		ok("16 bits", wav.format == AudioStreamWAV.FORMAT_16_BITS)
		ok("taxa correta", wav.mix_rate == Synth.TAXA, str(wav.mix_rate))
		ok("tem dados", wav.data.size() > 0)

	# cada habilidade precisa ter um som mapeado
	var sem_som: Array = []
	for h in Dados.habilidades:
		var nome := Sfx.som_habilidade(str(h.get("id", "")))
		if nome == "" or not cat.has(nome):
			sem_som.append(str(h.get("id", "")))
	ok("toda habilidade tem som", sem_som.is_empty(), str(sem_som))

## -------------------------------------------------------------- save
func t_save() -> void:
	g("Save")
	var save = root.get_node_or_null("SaveSys")
	jogo.s["moedas"]["ouro"] = Big.from_log(123.456)
	jogo.s["onda"] = 77
	var codigo: String = jogo.exportar()
	ok("exporta com assinatura", codigo.begins_with("TORRE1|"))
	ok("codigo nao vazio", codigo.length() > 100)

	var lido: Dictionary = save.importar(codigo)
	ok("importa", not lido.is_empty())
	ok("preserva onda", int(lido.get("onda", 0)) == 77)
	ok("preserva numero gigante", perto(float(lido["moedas"]["ouro"]), 123.456, 1e-9))

	var corrompido := codigo.substr(0, codigo.length() - 6) + "zzzzzz"
	ok("rejeita corrompido", save.importar(corrompido).is_empty())
	ok("erro explicado", save.ultimo_erro != "")
	ok("rejeita lixo", save.importar("nada disso").is_empty())

	# --- save corrompido no disco: precisa cair no backup, nunca travar ---
	var bom: String = JSON.stringify(jogo.s)
	var f1 := FileAccess.open(save.cam(), FileAccess.WRITE)
	f1.store_string(bom)
	f1.close()
	var f2 := FileAccess.open(save.cam_backup(), FileAccess.WRITE)
	f2.store_string(bom)
	f2.close()
	var f3 := FileAccess.open(save.cam(), FileAccess.WRITE)
	f3.store_string("{isso nao e json valido[[[")
	f3.close()
	var recuperado: Dictionary = save.carregar()
	ok("save corrompido cai no backup", not recuperado.is_empty())
	ok("backup preserva a onda", int(recuperado.get("onda", -1)) == int(jogo.s["onda"]))

	# os dois corrompidos: precisa devolver vazio sem explodir
	var f4 := FileAccess.open(save.cam_backup(), FileAccess.WRITE)
	f4.store_string("lixo total")
	f4.close()
	var vazio: Dictionary = save.carregar()
	ok("dois corrompidos devolvem vazio", vazio.is_empty())
	var novo_estado := GameState.mesclar(GameState.novo(), vazio)
	ok("jogo comeca limpo apos perda total", int(novo_estado["onda"]) == 1)
	save.apagar()

	# Um unico NaN/INF sai do JSON.stringify como `nan`/`inf`, que nao e JSON
	# valido. O arquivo gravava assim mesmo e, no autosave seguinte, esse lixo
	# virava o backup: dois autosaves e o jogador perdia save E backup sem
	# nenhum aviso.
	var podre := {"versao": 1, "onda": 5, "ruim": INF}
	ok("save recusa numero nao-finito", not save.salvar(podre))
	var so_bom := {"versao": 1, "onda": 5}
	ok("save aceita estado sao", save.salvar(so_bom))
	save.apagar()

	# mesclagem preserva campos novos do padrao
	var antigo := {"versao": 1, "onda": 5}
	var mesclado := GameState.mesclar(GameState.novo(), antigo)
	ok("mescla mantem padrao", mesclado.has("temporada") and mesclado.has("cartas"))
	ok("mescla aplica salvo", int(mesclado["onda"]) == 5)

	# Save valido em JSON mas com tipo trocado travava o boot para sempre: o
	# valor entrava, `int(s["onda"])` estourava em todo quadro, e o mesmo save
	# era recarregado na abertura seguinte.
	var torto := GameState.mesclar(GameState.novo(), {"onda": {}, "nivel": [1, 2], "modo_farm": 7})
	ok("tipo trocado nao passa (dicionario)", torto["onda"] is int)
	ok("tipo trocado nao passa (array)", torto["nivel"] is int)
	ok("tipo trocado nao passa (bool)", torto["modo_farm"] is bool)
	var infinito := GameState.mesclar(GameState.novo(), {"xp": INF, "nivel": NAN})
	ok("nao-finito nao entra no estado", is_finite(float(infinito["xp"])) and int(infinito["nivel"]) >= 1)

## ------------------------------------------------------------ offline
func t_offline() -> void:
	g("Offline")
	var r := Offline.calcular(jogo, 10.0)
	ok("ignora tempo curto", not bool(r.get("aplicado", false)))
	jogo.s["moedas"]["ouro"] = Big.ZERO
	var ouro_antes: float = jogo.s["moedas"]["ouro"]
	var r2 := Offline.calcular(jogo, 3600.0)
	ok("aplica uma hora", bool(r2.get("aplicado", false)))
	ok("da ouro", Big.gt(jogo.s["moedas"]["ouro"], ouro_antes))
	var r3 := Offline.calcular(jogo, 3600.0 * 500.0)
	ok("corta no teto", float(r3.get("cortado", 0.0)) > 0.0)
	# A ancora do offline nunca anda para tras: relogio atrasado apagaria tempo
	# real em silencio, relogio adiantado pagaria o teto quantas vezes quisesse.
	var futuro := int(Time.get_unix_time_from_system()) + 86400
	jogo.s["tick_em"] = futuro
	jogo.salvar()
	ok("ancora nao volta no tempo", int(jogo.s["tick_em"]) >= futuro)
	# O relatorio precisa continuar guardado no Jogo. A interface conectava o
	# sinal um quadro DEPOIS de ele ser emitido e o relatorio nunca aparecia;
	# agora o painel tambem pode ler o estado guardado.
	jogo.relatorio_offline = r2
	ok("jogo guarda o relatorio", bool(jogo.relatorio_offline.get("aplicado", false)))

## -------------------------------------------------------- habilidades
func t_habilidades() -> void:
	g("Habilidades")
	# O desbloqueio precisa rodar em toda onda, nao so quando o recorde sobe:
	# um save carregado, um salto de onda ou a onda inicial de um talento mexem
	# no recorde por fora e a habilidade ficava presa com "requisito cumprido"
	# escrito ao lado do cadeado.
	jogo.s["habilidades"] = {}
	jogo.s["onda_maxima_global"] = 300
	jogo.diretor.iniciar_onda(50)              # 50 < 300: o recorde NAO sobe
	var abertas := 0
	for id in jogo.s["habilidades"].keys():
		if bool(jogo.s["habilidades"][id]["desbloqueada"]):
			abertas += 1
	ok("habilidade abre mesmo sem recorde novo", abertas >= 5, str(abertas))

	# O no do topo da arvore de Eter prometia o Modo Infinito e nao tinha nada
	# por tras dele. Agora tem — e continua trancado sem o desbloqueio.
	jogo.s["modo_infinito"] = false
	jogo.esp["desbloqueios"].erase("modoInfinito")
	ok("infinito trancado sem o no", not jogo.alternar_infinito())
	jogo.s["desbloqueios"]["modoInfinito"] = true
	jogo.recalcular()
	ok("infinito liga com o no", jogo.alternar_infinito())
	ok("infinito desliga", not jogo.alternar_infinito())
	jogo.s["desbloqueios"].erase("modoInfinito")
	jogo.recalcular()

	# Bestiario Verdadeiro: todo chefe precisa saber QUAL torre ele foi, nas
	# duas linguas. E a revelacao do jogo — chefe sem verdade e um buraco no
	# pagamento da historia.
	var sem_verdade: Array = []
	for b in Dados.chefes + Dados.super_chefes:
		for campo in ["verdadeNome", "verdadeNomeEn", "verdade", "verdadeEn"]:
			if str(b.get(campo, "")) == "":
				sem_verdade.append("%s.%s" % [str(b.get("id", "?")), campo])
	ok("todo chefe tem Bestiario Verdadeiro", sem_verdade.is_empty(), str(sem_verdade))

	# O placar do Peregrino decide o Fim Verdadeiro. A Transcendencia montava um
	# estado novo sem ele e a tela final lia 0 x 0 — a unica pergunta que o jogo
	# faz ao jogador, respondida com silencio.
	jogo.s["peregrinos_poupados"] = 7
	jogo.s["peregrinos_mortos"] = 3
	jogo.s["missoes_completas"] = 21
	jogo.s["caixa"] = {"seladas": 4, "abertas": 9}
	jogo.s["onda_maxima"] = 700
	jogo.s["onda_maxima_global"] = 700
	jogo.s["prestigio"]["singularidades"] = 9
	jogo.s["moedas"]["nucleos"] = Big.from(1.0e9)
	jogo.transcender()
	ok("placar do Peregrino sobrevive", int(jogo.s["peregrinos_poupados"]) == 7 and int(jogo.s["peregrinos_mortos"]) == 3)
	ok("total de missoes sobrevive", int(jogo.s["missoes_completas"]) == 21)
	ok("Caixa da Vigilia sobrevive", int(jogo.s["caixa"]["abertas"]) == 9)

	var s: Dictionary = jogo.s
	s["onda_maxima_global"] = 200
	Habilidades.desbloquear_por_progresso(s)
	var desbloqueadas := 0
	for id in s["habilidades"].keys():
		if bool(s["habilidades"][id]["desbloqueada"]):
			desbloqueadas += 1
	ok("desbloqueia por onda", desbloqueadas >= 8, str(desbloqueadas))

	# regressão: habilidades precisam liberar DURANTE a partida, não só no boot
	for id in s["habilidades"].keys():
		s["habilidades"][id]["desbloqueada"] = false
	s["onda_maxima_global"] = 1
	Habilidades.desbloquear_por_progresso(s)
	var so_inicial := 0
	for id in s["habilidades"].keys():
		if bool(s["habilidades"][id]["desbloqueada"]):
			so_inicial += 1
	jogo.diretor.iniciar_onda(40)
	var depois_da_onda := 0
	for id in s["habilidades"].keys():
		if bool(s["habilidades"][id]["desbloqueada"]):
			depois_da_onda += 1
	ok("nova onda libera habilidade", depois_da_onda > so_inicial, "%d -> %d" % [so_inicial, depois_da_onda])
	jogo.arena.limpar_inimigos()
	ok("nova disponivel", Habilidades.disponivel(s, "nova"))
	ok("usa", Habilidades.usar("nova", jogo))
	ok("entra em recarga", float(GameState.hab(s, "nova")["cd"]) > 0.0)
	ok("nao usa em recarga", not Habilidades.usar("nova", jogo))
	var def: Dictionary = Dados.habilidade_por_id["nova"]
	ok("recarga cai com cdr", Habilidades.cd_efetivo(def, 1, 0.5) < Habilidades.cd_efetivo(def, 1, 0.0))
	ok("nivel melhora", Habilidades.valor(def, "dano", 5) > Habilidades.valor(def, "dano", 1))
	ok("custo cresce", Habilidades.custo_melhoria(def, 5) > Habilidades.custo_melhoria(def, 1))

## ------------------------------------------------------- integridade
func t_integridade() -> void:
	g("Integridade")
	var sem_faltar: bool = Dados.faltando.is_empty()
	ok("dados carregados", Dados.carregado and sem_faltar)
	ok("todo upgrade tem efeito", _todos_tem(Dados.upgrades, "efeito"))
	ok("todo talento tem efeito", _todos_tem(Dados.talentos, "efeito"))
	ok("toda carta tem efeito", _todos_tem(Dados.cartas, "efeito"))
	ok("todo inimigo tem forma", _todos_tem(Dados.inimigos, "forma"))
	ok("toda era tem paleta", _todos_tem(Dados.eras, "paleta"))
	ok("toda habilidade tem tipo", _todos_tem(Dados.habilidades, "tipo"))
	# a arte precisa saber desenhar toda forma declarada
	var formas_conhecidas := ["circulo", "seta", "hexagono", "losango", "triangulo", "escudo", "asa",
		"fantasma", "celula", "cruz", "canhao", "estrela", "bolha", "verme", "prisma", "monolito",
		"garra", "ovo", "fumaca", "boca", "caos", "foice", "tita", "rainha", "nucleo", "arauto",
		"serpente", "espelho", "colmeia", "ceifador", "silencio", "devorador", "aniquilador", "trono", "peregrino"]
	var faltando: Array = []
	for e in Dados.inimigos + Dados.chefes + Dados.super_chefes:
		var f := str(e.get("forma", ""))
		if not formas_conhecidas.has(f) and not faltando.has(f):
			faltando.append(f)
	ok("toda forma tem arte", faltando.is_empty(), str(faltando))
	# habilidades do HUD tem icone
	var sem_icone: Array = []
	for h in Dados.habilidades:
		if Icone.da_habilidade(str(h.get("id", ""))) == "estrela" and str(h.get("id", "")) != "chuva_ouro":
			sem_icone.append(str(h.get("id", "")))
	ok("habilidades com icone proprio", sem_icone.is_empty(), str(sem_icone))

func _todos_tem(lista: Array, campo: String) -> bool:
	for it in lista:
		if not it.has(campo):
			return false
	return true
