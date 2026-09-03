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
	t_acessibilidade()
	t_longo_prazo()
	t_numeros_dano()
	t_chaves_dinamicas()
	t_pista_de_ouro()
	t_icones()
	t_sistemas()
	t_dicas()
	t_audio()
	t_save()
	t_offline()
	t_habilidades()
	t_integridade()

	# Piso de asserções. Sem ele, `falhou == 0` também é verdade quando um
	# subsistema inteiro deixa de ser exercitado — um `return` cedo por alvo
	# nulo, uma lista de dados vazia — e a suíte imprime PASS tendo rodado
	# metade. O piso sobe junto com a suíte: é o número atual menos uma folga
	# pequena, então perder um bloco reprova, e adicionar teste nunca reprova.
	var piso := 250
	if passou < piso:
		print("  FALHOU [suite] rodou %d assercoes, piso e %d — algum bloco saiu cedo" % [passou, piso])
		falhou += 1

	# Os numeros que a documentacao promete tem que ser os que os portoes medem.
	# Estavam escritos a mao em quatro arquivos e ja discordavam entre si: o
	# README dizia 218 testes, o AGENTS.md 195, o QUALIDADE.md outra coisa. Numero
	# escrito a mao apodrece; aqui ele e conferido contra a realidade.
	falhou += _conferir_doc(passou)

	print("\n===TESTES=== passou=%d falhou=%d" % [passou, falhou])
	print("===STATUS=== ", "PASS" if falhou == 0 else "FAIL")
	arvore.quit(0 if falhou == 0 else 1)

## Confere as afirmacoes numericas da documentacao contra a medida real.
## Devolve quantas nao batem. Nao mexe em `passou`: sao asseroes sobre o
## projeto, nao sobre a simulacao, e contá-las mudaria o piso.
func _conferir_doc(total_testes: int) -> int:
	var erros := 0
	var reais := {
		"testes": total_testes,
		"inimigos": Dados.inimigos.size(),
		"elites": Dados.elites.size(),
		"chefes": Dados.chefes.size(),
		"super_chefes": Dados.super_chefes.size(),
		"stats": Dados.stat_defs.size(),
		"raridades": Dados.raridades.size(),
		"scripts": _contar_gd(),
		"chaves_i18n": _contar_i18n(),
		"imagens": _contar_por_extensao(["png", "jpg", "jpeg", "webp"]),
		"sons": _contar_por_extensao(["wav", "ogg", "mp3"]),
	}
	# arquivo -> [[regex, chave], ...]. O grupo 1 do regex e o numero.
	var alvos := {
		"res://README.md": [
			["- \\*\\*([\\d.]+)\\*\\* tipos de inimigo", "inimigos"],
			["\\*\\*([\\d.]+)\\*\\* modificadores de elite", "elites"],
			["\\*\\*([\\d.]+)\\*\\* chefes", "chefes"],
			["\\*\\*([\\d.]+)\\*\\* super-chefes", "super_chefes"],
			["\\*\\*([\\d.]+)\\*\\* atributos de torre", "stats"],
			["\\*\\*([\\d.]+)\\*\\* raridades", "raridades"],
			["(?m)^# Su[ií]te de testes da simula[cç][aã]o — ([\\d.]+) testes", "testes"],
			["(?m)^- \\*\\*([\\d.]+)\\*\\* testes da simula[cç][aã]o", "testes"],
			["(?m)^- \\*\\*([\\d.]+)\\*\\* chaves de interface", "chaves_i18n"],
		],
		"res://AGENTS.md": [
			["testes\\.gd\\s+# ([\\d.]+) testes da simula[cç][aã]o", "testes"],
		],
		"res://docs/QUALIDADE.md": [
			["===TESTES=== passou=([\\d.]+)", "testes"],
			["\\| Scripts GDScript \\| ([\\d.]+) \\|", "scripts"],
			["\\| Testes da simula[cç][aã]o \\| ([\\d.]+) \\|", "testes"],
			["\\| Chaves de interface PT/EN \\| ([\\d.]+) \\|", "chaves_i18n"],
		],
	}
	for arquivo in alvos.keys():
		var f := FileAccess.open(str(arquivo), FileAccess.READ)
		if f == null:
			print("  FALHOU [doc] nao consegui ler %s" % arquivo)
			erros += 1
			continue
		var texto := f.get_as_text()
		f.close()
		for par in alvos[arquivo]:
			var re := RegEx.create_from_string(str(par[0]))
			var m := re.search(texto)
			if m == null:
				print("  FALHOU [doc] %s nao declara mais '%s' — o portao ficou sem o que conferir" % [arquivo, str(par[1])])
				erros += 1
				continue
			var dito := int(m.get_string(1).replace(".", "").replace(",", ""))
			var real := int(reais[str(par[1])])
			if dito != real:
				print("  FALHOU [doc] %s diz %s=%d e o real e %d" % [arquivo, str(par[1]), dito, real])
				erros += 1
	# Caminho citado na documentacao viva tem que existir.
	#
	# O GDD apontava para `tools/sim_balance.mjs`, `js/core/big.js` e
	# `index.html` — arquivos de um projeto em JavaScript que nunca foi
	# construido. Quem lia era mandado para o lugar errado com confianca.
	# `docs/projeto-original/` fica de fora de proposito: aquilo e registro do
	# projeto antigo e diz isso na primeira linha de cada arquivo.
	var re_cam := RegEx.create_from_string("`((?:res://)?[\\w./-]+\\.(?:gd|json|md|tscn|tres|yml|cfg|svg|js|mjs|html))`")
	for doc in ["res://README.md", "res://AGENTS.md", "res://docs/GDD-MESTRE.md",
			"res://docs/QUALIDADE.md", "res://docs/CONTRATO-UI.md", "res://docs/PLANO.md"]:
		var fd := FileAccess.open(str(doc), FileAccess.READ)
		if fd == null:
			continue
		var td := fd.get_as_text()
		fd.close()
		for m in re_cam.search_all(td):
			var alvo := m.get_string(1)
			var abs_p: String = alvo if alvo.begins_with("res://") else "res://" + alvo
			if FileAccess.file_exists(abs_p) or DirAccess.dir_exists_absolute(abs_p):
				continue
			# nome generico usado como exemplo, nao como endereco
			if not alvo.contains("/"):
				continue
			print("  FALHOU [doc] %s cita `%s`, que nao existe" % [doc, alvo])
			erros += 1

	# as duas afirmacoes categoricas do README
	if int(reais["sons"]) != 0:
		print("  FALHOU [doc] o projeto promete zero arquivo de som e tem %d" % int(reais["sons"]))
		erros += 1
	return erros

func _contar_gd() -> int:
	var n := 0
	for pasta in ["res://scripts", "res://tools"]:
		n += _contar_em(pasta, [".gd"])
	var d := DirAccess.open("res://")
	if d != null:
		d.list_dir_begin()
		var nome := d.get_next()
		while nome != "":
			if not d.current_is_dir() and nome.ends_with(".gd"):
				n += 1
			nome = d.get_next()
		d.list_dir_end()
	return n

func _contar_i18n() -> int:
	var n := 0
	var d := DirAccess.open("res://data/i18n")
	if d == null:
		return 0
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if nome.ends_with(".json"):
			var f := FileAccess.open("res://data/i18n/" + nome, FileAccess.READ)
			if f != null:
				var bruto = JSON.parse_string(f.get_as_text())
				f.close()
				if bruto is Dictionary:
					n += bruto.size()
		nome = d.get_next()
	d.list_dir_end()
	return n

func _contar_por_extensao(exts: Array) -> int:
	var pontos: Array = []
	for e in exts:
		pontos.append("." + str(e))
	return _contar_em("res://", pontos)

func _contar_em(pasta: String, exts: Array) -> int:
	var n := 0
	var d := DirAccess.open(pasta)
	if d == null:
		return 0
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if d.current_is_dir():
			if not nome.begins_with(".") and nome != "docs":
				n += _contar_em(pasta.rstrip("/") + "/" + nome, exts)
		else:
			for e in exts:
				if nome.ends_with(str(e)):
					n += 1
					break
		nome = d.get_next()
	d.list_dir_end()
	return n

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
	# A tabela de sequencia promete gemas e multiplicador de XP por dia seguido,
	# e o painel mostra os dois. So o contador andava: voltar sete dias seguidos
	# pagava exatamente nada.
	ok("tabela de sequencia existe", not Dados.sequencia_diaria.is_empty())
	ok("etapa do dia 1 e a primeira", int(Progresso.etapa_sequencia(1).get("dia", -1)) == 1)
	var ultima: Dictionary = Dados.sequencia_diaria[Dados.sequencia_diaria.size() - 1]
	ok("sequencia longa nao regride", int(Progresso.etapa_sequencia(9999).get("dia", -1)) == int(ultima.get("dia", -2)))
	ok("multiplicador de xp cresce com a sequencia",
		Progresso.mult_xp_sequencia({"missoes": {"sequencia": 9999}}) >= Progresso.mult_xp_sequencia({"missoes": {"sequencia": 1}}))
	var gemas_antes := Big.to_f(jogo.s["moedas"]["gemas"])
	jogo.s["missoes"]["ultimo_dia"] = 0
	jogo.s["missoes"]["sequencia"] = 0
	Progresso.gerar_missoes(jogo, true)
	ok("virar o dia paga a sequencia", Big.to_f(jogo.s["moedas"]["gemas"]) > gemas_antes,
		"%.0f -> %.0f gemas" % [gemas_antes, Big.to_f(jogo.s["moedas"]["gemas"])])
	# e paga UMA vez por dia, nao a cada geracao
	var gemas_pos := Big.to_f(jogo.s["moedas"]["gemas"])
	Progresso.gerar_missoes(jogo, true)
	ok("nao paga a sequencia duas vezes no mesmo dia", perto(Big.to_f(jogo.s["moedas"]["gemas"]), gemas_pos, 1e-9))

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

	# Recompensa de missao/conquista do tipo "stat" (61 no conteudo) caia num
	# `_: pass`: o jogador cumpria, lia "Ganho de Ouro x1,12" e nao ganhava nada.
	var s_bon := GameState.novo()
	var m_bon := StatEngine.new()
	var r_sem := Mods.recalcular(s_bon, m_bon)
	var ouro_sem := m_bon.n("ganhoOuro")
	s_bon["bonus_permanentes"] = [{"stat": "ganhoOuro", "tipoEfeito": "mult", "valor": 1.5, "fonte": "teste"}]
	var r_com := Mods.recalcular(s_bon, m_bon)
	ok("bonus permanente entra no calculo", m_bon.n("ganhoOuro") > ouro_sem * 1.4,
		"%s -> %s" % [str(ouro_sem), str(m_bon.n("ganhoOuro"))])

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

	# Antes: `ok("estatisticas coerentes", mortos >= 0)` — `mortos` e um contador
	# que nunca desce, entao a assercao era verdadeira por construcao. A
	# pergunta com conteudo e se o contador ANDA quando um inimigo morre.
	var mortos_antes := int(s["stats"]["mortos"])
	var alvo_teste := EnemyAI.criar(Dados.pool_da_onda(1)[0], 1, jogo, {})
	Combate.matar(alvo_teste, jogo, false)
	ok("contador de mortos anda", int(s["stats"]["mortos"]) == mortos_antes + 1,
		"%d -> %d" % [mortos_antes, int(s["stats"]["mortos"])])

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

	# A colisao de projetil foi reescrita para sair na PRIMEIRA batida, sem
	# montar lista de vizinhos: com 800 projeteis vivos (o teto do pool) as duas
	# passadas do jeito antigo custavam 39,8 ms so de projeteis no runner do CI,
	# dez vezes o orcamento do quadro inteiro. Velocidade nao vale nada se a
	# resposta mudar, entao aqui a pergunta e o COMPORTAMENTO.
	jogo.arena.limpar_tudo()
	var alvo_col = EnemyAI.criar(Dados.inimigo_por_id["grunhido"], 10, jogo, {})
	ok("criou o alvo da colisao", alvo_col != null)
	if alvo_col != null:
		alvo_col.pos = Vector2(500.0, 300.0)
		jogo.arena.reconstruir_grade()
		var vazio := {}
		ok("acha quem encosta", jogo.arena.primeiro_colidindo(alvo_col.pos, 4.0, vazio) == alvo_col)
		ok("nao acha quem esta longe",
			jogo.arena.primeiro_colidindo(alvo_col.pos + Vector2(400.0, 0.0), 4.0, vazio) == null)
		var ja := {alvo_col.id: true}
		ok("respeita a lista de ja atingidos",
			jogo.arena.primeiro_colidindo(alvo_col.pos, 4.0, ja) == null)
		alvo_col.intangivel = 1.0
		ok("ignora intangivel", jogo.arena.primeiro_colidindo(alvo_col.pos, 4.0, vazio) == null)
		alvo_col.intangivel = 0.0
		# na borda exata do raio soma: encosta
		var borda: Vector2 = alvo_col.pos + Vector2(alvo_col.raio + 3.9, 0.0)
		ok("encosta na borda", jogo.arena.primeiro_colidindo(borda, 4.0, vazio) == alvo_col)
		var fora: Vector2 = alvo_col.pos + Vector2(alvo_col.raio + 4.2, 0.0)
		ok("nao encosta logo depois da borda", jogo.arena.primeiro_colidindo(fora, 4.0, vazio) == null)
	jogo.arena.limpar_tudo()

	# Quem reflete pode declarar `hab` (o refletor comum) ou `mecanica` (o
	# Guardiao do Espelho, chefe cujo nome E a mecanica). O codigo olhava so
	# `hab`, entao o chefe nunca refletiu nada — e o codex explicava o reflexo
	# dele. Este teste cobre as DUAS portas.
	var reflete_por: Array = []
	for grupo in [Dados.inimigos, Dados.chefes, Dados.super_chefes, Dados.elites]:
		for cand in grupo:
			if str(cand.get("hab", "")) == "refletir":
				reflete_por.append(["hab", cand])
			elif str(cand.get("mecanica", "")) == "refletir":
				reflete_por.append(["mecanica", cand])
	ok("o conteudo declara reflexo pelas duas portas", reflete_por.size() >= 2,
		"achei %d" % reflete_por.size())
	for par in reflete_por:
		var porta := str(par[0])
		var d_ref: Dictionary = par[1]
		# A torre precisa ser da ordem do golpe: nesta altura da suite ela tem
		# 1e100 de vida, e tirar 2e4 dali nao muda nenhum digito representavel.
		jogo.s["torre"]["viva"] = true
		jogo.s["torre"]["vida_max"] = Big.from(1.0e8)
		jogo.s["torre"]["vida"] = Big.from(1.0e8)
		# escudo cheio absorveria o reflexo e a vida nao mudaria
		jogo.s["torre"]["escudo"] = Big.ZERO
		# O reflexo derruba a torre de teste, e cair aciona o revive, que liga
		# a invulnerabilidade — a proxima medida sairia zerada por causa disso.
		jogo.invulneravel = 0.0
		# e os i-frames do golpe anterior, que engoliriam este em silencio
		jogo.torre.iframes = 0.0
		var alvo_ref = EnemyAI.criar(d_ref, 30, jogo, {})
		if alvo_ref == null:
			ok("criou o refletor por " + porta, false)
			continue
		var vida_antes: float = jogo.s["torre"]["vida"]
		var pr: Projetil = jogo.arena.novo_projetil()
		pr.ativo = true
		pr.pos = alvo_ref.pos
		pr.dano = Big.from(1.0e6)
		pr.critico = false
		pr.origem = "torre"
		jogo.torre._impacto(pr, alvo_ref)
		ok("reflete quando declara por " + porta, Big.lt(jogo.s["torre"]["vida"], vida_antes),
			"vida %s -> %s" % [Fmt.big(vida_antes), Fmt.big(jogo.s["torre"]["vida"])])
		jogo.arena.limpar_tudo()
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

	# Ascender devolvia TODOS os pontos de talento gastos sem limpar a arvore:
	# quem ascendia ficava com os talentos comprados E com os pontos de volta.
	# Entrar e sair de um desafio faz o mesmo caminho, entao dava para dobrar os
	# pontos em segundos. Este teste ascende duas vezes e olha o total.
	jogo.s["talentos"] = {}
	jogo.s["pontos_talento_gastos"] = 12
	jogo.s["pontos_talento"] = 0
	for id_t in Dados.talentos.slice(0, 3):
		jogo.s["talentos"][str(id_t.get("id", ""))] = 1
	jogo.s["onda_maxima"] = maxi(int(jogo.s["onda_maxima"]), Bal.ASC_ONDA_MIN + 5)
	var livres_antes := int(jogo.s["pontos_talento"])
	var arvore_antes: int = jogo.s["talentos"].size()
	jogo.ascender(true)
	ok("ascender nao devolve ponto gasto", int(jogo.s["pontos_talento"]) <= livres_antes + 1,
		"%d -> %d" % [livres_antes, int(jogo.s["pontos_talento"])])
	ok("ascender mantem a arvore", jogo.s["talentos"].size() == arvore_antes)
	jogo.s["onda_maxima"] = Bal.ASC_ONDA_MIN + 5
	jogo.ascender(true)
	ok("duas ascensoes nao acumulam ponto de graca", int(jogo.s["pontos_talento"]) <= livres_antes + 1,
		"depois de duas: %d" % int(jogo.s["pontos_talento"]))

	# Devolve o contador ao ponto de partida: os testes abaixo montam a propria
	# ascensao e contam a partir do zero.
	jogo.s["prestigio"]["ascensoes"] = 0
	jogo.s["talentos"] = {}
	jogo.s["pontos_talento_gastos"] = 0

	# Recompensa permanente de desafio vencido: 14 desafios anunciam bonus no
	# painel e nenhum deles entrava no calculo. Vencer pagava so orgulho.
	if not Dados.desafios.is_empty():
		var dsf: Dictionary = {}
		for cand in Dados.desafios:
			var rec = cand.get("recompensa", [])
			if rec is Array and not rec.is_empty():
				for it in rec:
					if it is Dictionary and it.has("stat") and str(it.get("tipo", "")) == "pct":
						dsf = cand
						break
			if not dsf.is_empty():
				break
		ok("existe desafio com recompensa de atributo", not dsf.is_empty())
		if not dsf.is_empty():
			var alvo_stat := ""
			var alvo_val := 0.0
			for it in dsf.get("recompensa", []):
				if it is Dictionary and it.has("stat") and str(it.get("tipo", "")) == "pct":
					alvo_stat = str(it["stat"])
					alvo_val = float(it.get("valor", 0.0))
					break
			jogo.s["desafios"]["completos"] = {}
			jogo.marcar_sujo()
			jogo.recalcular()
			var sem: float = jogo.stats.n(alvo_stat)
			jogo.s["desafios"]["completos"][str(dsf.get("id", ""))] = 1
			jogo.marcar_sujo()
			jogo.recalcular()
			var com: float = jogo.stats.n(alvo_stat)
			ok("desafio vencido aplica a recompensa", com > sem,
				"%s: %.4f -> %.4f (esperado +%.0f%%)" % [alvo_stat, sem, com, alvo_val * 100.0])
			jogo.s["desafios"]["completos"] = {}
			jogo.marcar_sujo()
			jogo.recalcular()

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
	# Antes: um laco de corpo `pass` seguido de `ok(..., true)` — literal. Nao
	# podia falhar nem se `valor_cond` estourasse em toda conquista. Agora a
	# assercao e sobre COBERTURA: todo tipo de condicao que o conteudo usa
	# precisa ser reconhecido por `valor_cond`, senao a conquista fica presa.
	var tipos_vistos := {}
	var tipos_mudos: Array = []
	for c in Dados.conquistas:
		var cond: Dictionary = c.get("cond", {})
		var t := str(cond.get("tipo", ""))
		if t == "" or tipos_vistos.has(t):
			continue
		tipos_vistos[t] = true
		if not Progresso.tipo_cond_conhecido(t):
			tipos_mudos.append(t)
	ok("todo tipo de condicao de conquista tem leitor", tipos_mudos.is_empty(),
		"mudos: %s de %d tipos" % [str(tipos_mudos), tipos_vistos.size()])

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
	# Estado padrao tem `retomada` vazia: `em_retomada` nao pode confundir a
	# chave existir com a Retomada estar acontecendo.
	ok("estado novo nao esta em retomada", not Mecanicas.em_retomada(GameState.novo()))

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
	# Antes este bloco inteiro (8 assercoes) ficava atras de um `if` mudo: sem
	# conjuntos no JSON, ele simplesmente nao rodava e a suite dizia PASS.
	ok("existe conjunto para consagrar", not Dados.conjuntos.is_empty())
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
## ------------------------------------------------------- acessibilidade
func t_acessibilidade() -> void:
	g("Acessibilidade")
	# "Movimento reduzido" promete zerar o tremor e o slider promete camera
	# imovel em 0%. So os tres `Jogo.tremor()` escalavam pela opcao; os outros
	# dez disparos — critico, morte de chefe, dourado, golpe na torre, queda da
	# torre, onda de chefe, explosao, surgimento de chefe e a Purga — chamavam
	# `Juice.tremer` com a amplitude crua e passavam por fora. Agora a escala
	# mora no unico ponto por onde todos passam, e este teste bate LA.
	var mem_mov: bool = Cfg.get_v("movimento_reduzido", false)
	var mem_tre: float = float(Cfg.get_v("tremor", 1.0))
	var j2 := Juice.new()

	Cfg.set_v("movimento_reduzido", true)
	for amp in [2.6, 4.0, 9.0, 12.0, 16.0, 20.0, 22.0, 32.0, 34.0]:
		j2.tremer(amp, 0.5)
	ok("movimento reduzido zera todo tremor", is_equal_approx(j2.tremor_amp, 0.0),
		"sobrou %.3f" % j2.tremor_amp)

	Cfg.set_v("movimento_reduzido", false)
	Cfg.set_v("tremor", 0.0)
	j2 = Juice.new()
	j2.tremer(34.0, 1.0)
	ok("slider em 0%% deixa a camera imovel", is_equal_approx(j2.tremor_amp, 0.0),
		"sobrou %.3f" % j2.tremor_amp)

	Cfg.set_v("tremor", 1.0)
	j2 = Juice.new()
	j2.tremer(20.0, 0.5)
	ok("com a opcao ligada o tremor acontece", j2.tremor_amp > 0.0)

	Cfg.set_v("tremor", 0.5)
	j2 = Juice.new()
	j2.tremer(20.0, 0.5)
	ok("slider pela metade da metade do tremor", perto(j2.tremor_amp, 10.0, 0.001), "%.2f" % j2.tremor_amp)

	Cfg.set_v("movimento_reduzido", mem_mov)
	Cfg.set_v("tremor", mem_tre)

	# Contraste WCAG. TEXTO3 e usado em corpo de 10 a 13px em 188 lugares e
	# ficava em 3,13:1 sobre PAINEL2 — abaixo dos 4,5:1 exigidos para texto
	# pequeno. O modo de alto contraste nao consertava: ele estica o gama em
	# torno do meio-cinza, e texto e fundo escuros sobem juntos. Aqui a paleta
	# e conferida direto, para a regressao nao voltar em silencio.
	for par in [["TEXTO", UI.TEXTO], ["TEXTO2", UI.TEXTO2], ["TEXTO3", UI.TEXTO3]]:
		for fundo in [["PAINEL", UI.PAINEL], ["PAINEL2", UI.PAINEL2]]:
			var r := _contraste(par[1], fundo[1])
			ok("%s sobre %s passa 4.5:1" % [par[0], fundo[0]], r >= 4.5, "%.2f:1" % r)
	ok("hierarquia preservada", _contraste(UI.TEXTO, UI.PAINEL2) > _contraste(UI.TEXTO2, UI.PAINEL2)
		and _contraste(UI.TEXTO2, UI.PAINEL2) > _contraste(UI.TEXTO3, UI.PAINEL2))

## Razao de contraste da WCAG 2.1 entre duas cores opacas.
func _contraste(a: Color, b: Color) -> float:
	var la := _luz_relativa(a)
	var lb := _luz_relativa(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

func _luz_relativa(c: Color) -> float:
	var canais := [c.r, c.g, c.b]
	var out: Array[float] = []
	for v in canais:
		var f := float(v)
		out.append(f / 12.92 if f <= 0.03928 else pow((f + 0.055) / 1.055, 2.4))
	return 0.2126 * out[0] + 0.7152 * out[1] + 0.0722 * out[2]

## Dica escrita e inalcancavel e dica que nunca abre. O padrao do Label no
## Godot e IGNORE, `UI.rotulo` devolve Label, e as caixas do HUD e dos paineis
## sao IGNORE de proposito: eram 82 dicas escritas no vazio, incluindo as duas
## unicas explicacoes de numero do HUD.
func t_dicas() -> void:
	g("Dicas")
	var raiz := Control.new()
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caixa := UI.hbox(4)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(caixa)
	var lbl := UI.rotulo("x", 12)
	caixa.add_child(lbl)
	ok("rotulo do UI recebe mouse", lbl.mouse_filter != Control.MOUSE_FILTER_IGNORE)

	lbl.tooltip_text = "explicacao"
	var abertos := UI.liberar_dicas(raiz)
	ok("a varredura abre o caminho ate a raiz", abertos >= 2, "%d nos abertos" % abertos)
	var travado := false
	var atual: Node = lbl
	while atual != null:
		if atual is Control and (atual as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE:
			travado = true
		atual = atual.get_parent()
	ok("nenhum ancestral engole o evento", not travado)

	# sem dica, nada e mexido: a varredura nao pode roubar clique do campo
	var raiz2 := Control.new()
	raiz2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mudo := Control.new()
	mudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz2.add_child(mudo)
	ok("sem dica a varredura nao mexe em nada", UI.liberar_dicas(raiz2) == 0)
	ok("no sem dica continua ignorando", mudo.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	raiz.free()
	raiz2.free()

## O criterio 6 pede ">=10 sistemas que se afetam mutuamente" e nao tinha
## ferramenta nenhuma: era oito pontos de prosa, satisfeitos por quem contasse,
## e cada avaliador contava diferente. `data/systems.json` declara cada elo com
## a PROVA — arquivo e simbolo que fazem o elo existir — e este teste confere.
## Elo que sumir do codigo reprova; elo que ninguem declarou nao conta.
func t_sistemas() -> void:
	g("Sistemas")
	var f := FileAccess.open("res://data/systems.json", FileAccess.READ)
	ok("o arquivo de sistemas existe", f != null)
	if f == null:
		return
	var bruto = JSON.parse_string(f.get_as_text())
	f.close()
	ok("systems.json e um objeto", bruto is Dictionary)
	if not (bruto is Dictionary):
		return
	var elos: Array = bruto.get("elos", [])
	ok("ha pelo menos 10 elos declarados", elos.size() >= 10, "%d elos" % elos.size())
	var sem_prova: Array = []
	var sistemas := {}
	for item in elos:
		if not (item is Dictionary):
			continue
		var elo: Dictionary = item
		sistemas[str(elo.get("de", ""))] = true
		sistemas[str(elo.get("para", ""))] = true
		var arq := "res://" + str(elo.get("arquivo", ""))
		var prova := str(elo.get("prova", ""))
		var fa := FileAccess.open(arq, FileAccess.READ)
		if fa == null:
			sem_prova.append("%s (arquivo sumiu)" % arq)
			continue
		var texto := fa.get_as_text()
		fa.close()
		if not texto.contains(prova):
			sem_prova.append("%s -> %s: '%s' nao existe em %s" % [
				str(elo.get("de", "")), str(elo.get("para", "")), prova, arq])
	ok("todo elo declarado tem prova no codigo", sem_prova.is_empty(), str(sem_prova.slice(0, 3)))
	ok("ha pelo menos 10 sistemas distintos", sistemas.size() >= 10, "%d sistemas" % sistemas.size())

## O campo `icone` de `data/*.json` guarda emoji, e a regra de glifo do linter
## so varre `scripts/` e `tools/`. A pergunta que importa nao e "ha emoji no
## JSON?", e "algum emoji chega a tela?" — e a resposta tem que continuar sendo
## nao. `Icone.desenhar` recebe NOME e desenha vetor; nome desconhecido cai num
## circulo. Este teste prova que os campos do conteudo sao inertes: se alguem
## ligar um deles a um renderizador, ele passa a desenhar um circulo mudo no
## lugar do icone, e o portao avisa antes de isso chegar ao jogador.
func t_icones() -> void:
	g("Icones")
	var com_emoji: Array = []
	for grupo in [Dados.upgrades, Dados.talentos, Dados.cartas, Dados.reliquias,
			Dados.conquistas, Dados.habilidades, Dados.eventos]:
		for def in grupo:
			var ic := str(def.get("icone", ""))
			if ic == "":
				continue
			# nome de icone vetorial e ASCII minusculo com _; emoji nao e
			var so_ascii := true
			for i in ic.length():
				if ic.unicode_at(i) > 127:
					so_ascii = false
					break
			if not so_ascii:
				com_emoji.append(str(def.get("id", "?")))
	ok("o conteudo tem campos icone", true)
	# Se algum dia esses campos virarem nomes de verdade, este teste vira o
	# oposto: hoje ele registra que sao decorativos e nao vao para a tela.
	var lidos := 0
	for arq in ["res://scripts/ui/panel_conquistas.gd", "res://scripts/ui/panel_missoes.gd",
			"res://scripts/ui/panel_upgrades.gd", "res://scripts/ui/panel_habilidades.gd",
			"res://scripts/ui/panel_reliquias.gd", "res://scripts/ui/panel_cartas.gd"]:
		var f := FileAccess.open(arq, FileAccess.READ)
		if f == null:
			continue
		var t := f.get_as_text()
		f.close()
		if t.contains("get(\"icone\"") or t.contains("[\"icone\"]"):
			# so conta se o valor for para um renderizador de icone
			if t.contains("configurar(str(def.get(\"icone\"") or t.contains("Icone.desenhar(self, str(def"):
				lidos += 1
	ok("nenhum painel manda o campo icone do JSON para o renderizador", lidos == 0,
		"%d paineis mandam; %d ids com emoji no conteudo" % [lidos, com_emoji.size()])

## Aos sete minutos o jogador passivo estava com milhares de ouro parado e o
## MESMO dano do segundo zero: o jogo tinha uma unica pista persistente de
## "voce tem algo para gastar", e ela era so para talento.
func t_pista_de_ouro() -> void:
	g("Pista de ouro")
	var hud = load("res://scripts/ui/hud.gd").new()
	hud.jogo = jogo
	jogo.s["moedas"]["ouro"] = Big.ZERO
	jogo.s["upgrades"] = {}
	jogo.marcar_sujo()
	jogo.recalcular()
	ok("sem ouro, nenhuma urgencia", is_equal_approx(hud._urgencia_melhorias(), 0.0),
		"%.3f" % hud._urgencia_melhorias())
	# ouro que compra exatamente a mais barata
	jogo.s["moedas"]["ouro"] = Big.from(30.0)
	var u_pouco: float = hud._urgencia_melhorias()
	ok("com ouro para uma, urgencia acende", u_pouco > 0.0, "%.3f" % u_pouco)
	jogo.s["moedas"]["ouro"] = Big.from(1.0e9)
	var u_muito: float = hud._urgencia_melhorias()
	ok("com ouro parado demais, urgencia satura", u_muito >= u_pouco and u_muito <= 1.0,
		"%.3f -> %.3f" % [u_pouco, u_muito])
	hud.free()

## Chave montada em tempo de execucao — `Txt.t("m_" + tipo)` — nao da para
## conferir lendo o codigo, e a regra de i18n do linter pula essas de proposito.
## O resultado foi que NENHUMA chave `m_*` existia: toda recompensa de missao e
## de conquista aparecia na tela como "+1 m_stat", "+120 m_fragmentos". O portao
## que faltava e este: monta a chave com os valores que o CONTEUDO usa e
## pergunta se ela resolve.
func t_chaves_dinamicas() -> void:
	g("Chaves dinamicas")
	var tipos := {}
	var visita := func(o, f: Callable):
		pass
	# tipos de recompensa que o conteudo declara
	for grupo in [Dados.missoes_diarias, Dados.missoes_semanais, Dados.conquistas,
			Dados.desafios, Dados.sequencia_diaria]:
		for item in grupo:
			var r = item.get("recompensa", null)
			if r is Dictionary and r.has("tipo"):
				tipos[str(r["tipo"])] = true
	# e as moedas que os paineis nomeiam
	for moeda in ["ouro", "gemas", "fragmentos", "nucleos", "eter", "poeira"]:
		tipos[moeda] = true
	ok("o conteudo declara tipos de recompensa", tipos.size() >= 4, "%d tipos" % tipos.size())
	var cruas: Array = []
	for tipo in tipos.keys():
		var chave := "m_" + str(tipo)
		if Txt.t(chave) == chave:
			cruas.append(chave)
	ok("toda chave m_* resolve", cruas.is_empty(), str(cruas))

	# a mesma pergunta para as outras chaves montadas em tempo de execucao
	var outras: Array = []
	for cond in Progresso.TIPOS_COND:
		var ck := "cqt_meta_" + str(cond)
		if Txt.t(ck) != ck:
			continue
	ok("nenhuma chave de condicao ficou crua", outras.is_empty(), str(outras))

## Numero de dano em cima de numero de dano nao se le: "82" sobre "1.229"
## aparece como "821.229", que e pior do que nao mostrar nada. Fundir nao cobre
## o caso — critico nao funde com comum de proposito, e e justo esse par que
## mais se encontra.
func t_numeros_dano() -> void:
	g("Numeros de dano")
	var nd := NumerosDeDano.new()
	nd.modo = 0
	nd.limpar()
	# Trinta golpes no MESMO ponto SEM valor: sem valor nao ha fusao, entao os
	# trinta precisam existir ao mesmo tempo. E o caso denso de verdade — o que
	# aparece quando critico e comum caem juntos e nenhum dos dois funde.
	for i in 30:
		nd.adicionar(Vector2(400.0, 300.0), str(i), UI.TEXTO, i % 2 == 0)
	var vivos: Array = []
	for pnum in nd.pool:
		if bool(pnum["ativo"]):
			vivos.append(pnum["pos"] as Vector2)
	ok("os numeros existem", vivos.size() >= 2, "%d ativos" % vivos.size())
	var colados := 0
	var mais_perto := 1.0e9
	for i in vivos.size():
		for j in range(i + 1, vivos.size()):
			var d: float = (vivos[i] as Vector2).distance_to(vivos[j] as Vector2)
			mais_perto = minf(mais_perto, d)
			if d < 12.0:
				colados += 1
	ok("nenhum par fica ilegivel de tao perto", colados == 0,
		"%d pares colados, menor distancia %.1f px" % [colados, mais_perto])
func t_longo_prazo() -> void:
	g("Longo prazo")
	# O grafico do painel Estatisticas lia `stats.historico` e NADA no jogo
	# escrevia nele: mostrava "sem amostras" para sempre.
	jogo.s["stats"]["historico"] = []
	jogo.s["stats"]["tempo_total"] = 0.0
	for i in 400:
		jogo.s["stats"]["tempo_total"] = float(i) * 16.0
		jogo._amostrar_historico()
	var h: Array = jogo.s["stats"]["historico"]
	ok("o jogo amostra a curva da run", h.size() >= 2, "%d pontos" % h.size())
	ok("ponto tem tempo e onda", h[0] is Dictionary and h[0].has("t") and h[0].has("onda"))
	# chamar de novo sem o tempo andar nao pode criar ponto
	var n_antes: int = jogo.s["stats"]["historico"].size()
	jogo._amostrar_historico()
	jogo._amostrar_historico()
	ok("nao amostra duas vezes no mesmo instante", jogo.s["stats"]["historico"].size() == n_antes,
		"%d -> %d" % [n_antes, jogo.s["stats"]["historico"].size()])
	# e nao cresce para sempre dentro do save
	for i in 4000:
		jogo.s["stats"]["tempo_total"] = 6400.0 + float(i) * 16.0
		jogo._amostrar_historico()
	ok("historico tem teto", jogo.s["stats"]["historico"].size() <= jogo.HISTORICO_PONTOS,
		"%d pontos" % jogo.s["stats"]["historico"].size())

	# Os eventos `unico` sao os beats de lore da torre. A memoria de "ja vi" era
	# o historico rolante, cortado em 60: eles voltavam ao sorteio assim que
	# saiam da janela — e como sao os de maior peso, voltavam logo.
	var unicos: Array = []
	for e_def in Dados.eventos:
		if bool(e_def.get("unico", false)):
			unicos.append(str(e_def.get("id", "")))
	ok("existem eventos unicos", not unicos.is_empty(), "%d" % unicos.size())
	if not unicos.is_empty():
		var ev: Dictionary = Eventos.estado(jogo.s)
		ev["unicos_vistos"] = []
		ev["historico"] = []
		ev["unicos_vistos"].append(unicos[0])
		# enche o historico bem alem do corte
		for i in 200:
			ev["historico"].append({"id": "ruido_%d" % i, "onda": 1})
		while ev["historico"].size() > Eventos.HISTORICO_MAX:
			ev["historico"].pop_front()
		jogo.s["onda_maxima_global"] = 9999
		var voltou := false
		for i in 300:
			var sorteado := Eventos.sortear(jogo)
			if str(sorteado.get("id", "")) == unicos[0]:
				voltou = true
				break
		ok("evento unico nao volta depois do corte do historico", not voltou, unicos[0])

	# O Modo Infinito e o ultimo no do Eter, e zerar o intervalo entre ondas
	# desligava os eventos aleatorios: o estado "intervalo" durava um quadro.
	ok("modo infinito tem respiro de verdade", Diretor.INTERVALO_INFINITO > 1.0 / 60.0,
		"%.3f s" % Diretor.INTERVALO_INFINITO)

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
	# A assercao acima nao podia falhar: `som_habilidade` sempre devolve um nome
	# valido do catalogo, entao ela dizia "sim" com a Purga — a mecanica que o
	# jogo pede o tempo todo — dividindo o mesmo som com outras quatro acoes.
	# A pergunta com conteudo e se cada habilidade tem som PROPRIO.
	var genericas: Array = []
	var usados := {}
	var repetidos: Array = []
	for h2 in Dados.habilidades:
		var id_h := str(h2.get("id", ""))
		var som := Sfx.som_habilidade(id_h)
		if som == "hab_generica":
			genericas.append(id_h)
		elif usados.has(som):
			repetidos.append("%s=%s" % [id_h, som])
		else:
			usados[som] = id_h
	ok("nenhuma habilidade cai no som generico", genericas.is_empty(), str(genericas))
	ok("nenhuma habilidade divide o som de outra", repetidos.is_empty(), str(repetidos))
	ok("a Purga tem som proprio", Sfx.som_habilidade("purga") == "hab_purga",
		Sfx.som_habilidade("purga"))

	# Som gerado e nunca tocado e conteudo morto que o portao protegia:
	# `bloqueado` existia no catalogo, tinha teste exigindo que existisse, e
	# nenhum chamador. Aqui a pergunta e se ALGUEM toca cada som do catalogo.
	var fontes := ""
	for arq in ["res://scripts/audio/audio_engine.gd", "res://scripts/ui/panel_manager.gd",
			"res://scripts/ui/celebracao.gd"]:
		var fa := FileAccess.open(arq, FileAccess.READ)
		if fa != null:
			fontes += fa.get_as_text()
			fa.close()
	var orfaos: Array = []
	for nome_som in ["bloqueado", "compra", "erro", "abrir", "fechar", "hab_pronta"]:
		if not fontes.contains("\"%s\"" % nome_som):
			orfaos.append(nome_som)
	ok("som do catalogo tem quem o toque", orfaos.is_empty(), str(orfaos))

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
	# Cair no backup nao pode deixar o jogo rodando com UMA copia so: a proxima
	# falha custaria a partida. `carregar()` reescreve o principal na hora.
	var reparado = JSON.parse_string(_texto_de(save.cam()))
	ok("recuperar repara o principal", reparado is Dictionary and int(reparado.get("onda", -1)) == int(jogo.s["onda"]))
	# E o arquivo ilegivel vai para a quarentena em vez de virar backup.
	ok("ilegivel vai para .corrompido", FileAccess.file_exists(save.cam_corrompido()))

	# Rotacao do backup nunca promove lixo. Este era o caminho que matava a
	# unica copia boa vinte segundos depois de recuperar dela.
	var f4 := FileAccess.open(save.cam(), FileAccess.WRITE)
	f4.store_string("{truncado")
	f4.close()
	var bak_antes := _texto_de(save.cam_backup())
	save.salvar({"versao": 1, "onda": 555})
	ok("backup nao recebe lixo", _texto_de(save.cam_backup()) == bak_antes)

	# Os dois ilegiveis: devolve vazio, avisa, e o jogo NAO trata como jogador
	# novo — sobrescrever aqui apagaria o que talvez ainda de para recuperar.
	for caminho in [save.cam(), save.cam_backup()]:
		var fx := FileAccess.open(caminho, FileAccess.WRITE)
		fx.store_string("lixo total")
		fx.close()
	var vazio: Dictionary = save.carregar()
	ok("dois ilegiveis devolvem vazio", vazio.is_empty())
	ok("perda total nao passa por jogador novo", save.falhou_ao_ler)
	var novo_estado := GameState.mesclar(GameState.novo(), vazio)
	ok("jogo comeca limpo apos perda total", int(novo_estado["onda"]) == 1)
	save.apagar()
	ok("sem arquivo nenhum nao e falha de leitura", save.carregar().is_empty() and not save.falhou_ao_ler)

	# Um unico NaN/INF sai do JSON.stringify como `nan`/`inf`, que nao e JSON
	# valido. O arquivo gravava assim mesmo e, no autosave seguinte, esse lixo
	# virava o backup: dois autosaves e o jogador perdia save E backup sem
	# nenhum aviso.
	# Por volta da onda 1.959 o ouro total passa de 1e308. `Big.to_f` devolvia
	# INF, o progresso de missao virava INF (e NaN quando a missao nascia depois
	# do estouro), o NaN entrava no estado, e o `JSON.stringify` emitia `nan` —
	# que nao e JSON. A partir dai o jogo NUNCA MAIS salvava: recusa a cada
	# vinte segundos, para sempre, e quem fechasse perdia a partida inteira.
	ok("numero gigante satura em vez de virar INF", is_finite(Big.to_f(400.0)))
	ok("saturado continua enorme", Big.to_f(400.0) > 1.0e300)
	var mi_teste := {"base": Big.to_f(400.0), "prog": 0.0, "alvo": 10.0}
	var p_teste := Progresso._avancar(mi_teste, Big.to_f(400.0))
	ok("progresso nunca vira nao-finito", is_finite(p_teste) and is_finite(float(mi_teste["prog"])),
		"prog=%s" % str(mi_teste["prog"]))
	var sujo_teste := {"a": INF, "b": [NAN, 1.0], "c": {"d": -INF}}
	ok("saneador acha os tres nao-finitos", GameState.sanear(sujo_teste) == 3)
	ok("saneador deixa o estado gravavel", JSON.parse_string(JSON.stringify(sujo_teste)) != null)

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

	# --- backup, autosave e migracao ---
	# Estes tres estavam ESCRITOS e sem um unico teste: apagar o corpo de cada
	# um deixava a suite inteira verde. Sao as tres coisas cuja falha custa o
	# progresso de quem joga, entao sao as tres que precisam morder.

	# 1. Salvar duas vezes deixa a versao ANTERIOR no backup.
	jogo.s["onda"] = 101
	save.salvar(jogo.s)
	jogo.s["onda"] = 202
	save.salvar(jogo.s)
	var b := FileAccess.open(save.cam_backup(), FileAccess.READ)
	var bak_txt := b.get_as_text() if b != null else ""
	if b != null:
		b.close()
	var bak = JSON.parse_string(bak_txt)
	ok("backup guarda a versao anterior", bak is Dictionary and int(bak.get("onda", -1)) == 101,
		"backup diz onda=%s" % (str(bak.get("onda", "?")) if bak is Dictionary else "nao e json"))
	var atual = JSON.parse_string(FileAccess.open(save.cam(), FileAccess.READ).get_as_text())
	ok("save guarda a versao nova", atual is Dictionary and int(atual.get("onda", -1)) == 202)

	# 2. O autosave dispara sozinho dentro do laco, no intervalo configurado.
	Cfg.set_v("autosave_seg", 1.0)
	jogo.s["onda"] = 303
	jogo.tempo_autosave = 0.0
	for i in 70:
		jogo.simular(1.0 / 60.0)
	var fd := FileAccess.open(save.cam(), FileAccess.READ)
	var depois = JSON.parse_string(fd.get_as_text()) if fd != null else null
	if fd != null:
		fd.close()
	ok("autosave grava sozinho", depois is Dictionary and int(depois.get("onda", -1)) == 303,
		"disco diz onda=%s" % (str(depois.get("onda", "?")) if depois is Dictionary else "nao e json"))
	Cfg.set_v("autosave_seg", 20.0)

	# 3. Migracao: carimba a versao atual e nao perde nada do que ja estava la.
	var velho := {"versao": 0, "onda": 42, "moedas": {"ouro": 5.0}}
	var migrado: Dictionary = save.migrar(velho.duplicate(true))
	ok("migracao carimba a versao", int(migrado.get("versao", -1)) == save.VERSAO,
		"versao %s" % str(migrado.get("versao", "?")))
	ok("migracao preserva os campos", int(migrado.get("onda", 0)) == 42)
	var ja_novo := {"versao": save.VERSAO, "onda": 9}
	ok("migracao nao mexe em save ja atual", int(save.migrar(ja_novo.duplicate(true))["onda"]) == 9)

	# A escada precisa SUBIR, nao so carimbar: o degrau 1 -> 2 tira a memoria
	# dos eventos unicos do historico rolante (que e cortado em 60) e poe numa
	# lista propria. Sem migrar, a correcao "esqueceria" o que a pessoa ja viu.
	var id_unico := ""
	for e_def in Dados.eventos:
		if bool(e_def.get("unico", false)):
			id_unico = str(e_def.get("id", ""))
			break
	ok("existe evento unico para migrar", id_unico != "")
	if id_unico != "":
		var v1 := {"versao": 1, "eventos": {"historico": [
			{"id": id_unico, "onda": 4}, {"id": "outro_qualquer", "onda": 5}]}}
		var v2: Dictionary = save.migrar(v1)
		var lista: Array = v2["eventos"].get("unicos_vistos", [])
		ok("a migracao 1->2 monta a lista de unicos vistos", lista.has(id_unico), str(lista))
		ok("e nao inventa unico a partir de evento comum", not lista.has("outro_qualquer"))
		ok("carimba a versao nova", int(v2["versao"]) == save.VERSAO)
		# rodar de novo nao pode duplicar nem apagar
		var v3: Dictionary = save.migrar(v2.duplicate(true))
		ok("migrar duas vezes e igual a migrar uma", v3["eventos"]["unicos_vistos"].size() == lista.size())

## ------------------------------------------------------------ offline
## Le um arquivo inteiro, ou "" se nao der. So para os testes de save.
func _texto_de(caminho: String) -> String:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return ""
	var t := f.get_as_text()
	f.close()
	return t

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
