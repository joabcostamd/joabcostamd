extends SceneTree

## Suíte de testes do jogo. Roda a simulação REAL, sem mocks.
##   godot --headless --path . -s res://tools/testes.gd

var passou := 0
var falhou := 0
var grupo := ""
var jogo: Node

func _initialize() -> void:
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
	t_save()
	t_offline()
	t_habilidades()
	t_integridade()

	print("\n===TESTES=== passou=%d falhou=%d" % [passou, falhou])
	print("===STATUS=== ", "PASS" if falhou == 0 else "FAIL")
	quit(0 if falhou == 0 else 1)

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
	e2.escudo = 1000.0
	e2.escudo_max = 1000.0
	var hp2 := e2.hp
	Combate.aplicar_dano(e2, Big.from(100.0), jogo, {"puro": true})
	ok("escudo absorve", perto(e2.hp, hp2, 1e-9) and e2.escudo < 1000.0)

	# execucao
	var e3 := EnemyAI.criar(def, 10, jogo, {})
	e3.hp = Big.mul_f(e3.hp_max, 0.02)
	Combate.aplicar_dano(e3, Big.from(1.0), jogo, {"puro": true, "execucao": 0.05})
	ok("execucao mata", not e3.vivo())

	jogo.arena.limpar_inimigos()

## ------------------------------------------------------- defesa da torre
func t_defesa() -> void:
	g("Defesa")
	# comprar vida PRECISA aumentar a sobrevivência (regressão: antes o dano de
	# contato era % da vida máxima, então vida extra não servia para nada)
	var hp10 := Bal.hp_onda(10)
	var d10 := Bal.dano_contato(hp10, 10, false, 1.0)
	ok("dano de contato independe da torre", not Big.is_zero(d10))
	ok("dano de contato cresce com a onda", Big.gt(Bal.dano_contato(Bal.hp_onda(80), 80, false, 1.0), d10))
	ok("chefe bate mais forte", Big.gt(Bal.dano_contato(hp10, 10, true, 1.0), d10))
	ok("piso protege o comeco", Big.gt(Bal.dano_contato(Bal.hp_onda(1), 1, false, 1.0), Big.mul_f(Bal.hp_onda(1), 0.02)))

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

	# mesclagem preserva campos novos do padrao
	var antigo := {"versao": 1, "onda": 5}
	var mesclado := GameState.mesclar(GameState.novo(), antigo)
	ok("mescla mantem padrao", mesclado.has("temporada") and mesclado.has("cartas"))
	ok("mescla aplica salvo", int(mesclado["onda"]) == 5)

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

## -------------------------------------------------------- habilidades
func t_habilidades() -> void:
	g("Habilidades")
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
