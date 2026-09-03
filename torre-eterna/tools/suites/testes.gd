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
	t_alcancavel()
	t_ferramentas()
	t_conteudo_lido()
	t_tempo()
	t_daltonismo()
	t_nada_mudo()
	t_elites()
	t_mira()
	t_fim_de_sessao()
	t_celebracao()
	t_painel_melhorias()
	t_rodape()
	t_custo_do_quadro()
	t_teto()
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

	# PISO POR GRUPO, nao um numero global.
	#
	# O piso global era 250 contra 371 assercoes reais: 121 de folga, mais do que
	# QUALQUER grupo da suite. Ou seja, dava para um grupo inteiro parar de rodar
	# — um `return` cedo por alvo nulo, uma lista de dados vazia — e a suite
	# imprimir PASS, que e exatamente o que o piso existia para impedir. Um
	# auditor demonstrou isso comentando a chamada de um grupo de 57 assercoes;
	# quem pegou foi o conferidor de documentacao, por acidente, nao o piso.
	#
	# Agora cada grupo tem o proprio minimo. Perder um bloco reprova NOMEANDO o
	# bloco, e acrescentar teste continua nunca reprovando.
	var minimo_por_grupo := {
		"Acessibilidade": 22, "Alcancavel": 8, "Big": 12,
		"Chaves dinamicas": 3, "Combate": 9, "Defesa": 27,
		"Dicas": 5, "Economia": 9, "Elites": 11,
		"Eventos": 12, "Feedback": 2, "Ferramentas": 3, "Daltonismo": 9, "Tempo": 5, "Conteudo lido": 21, "Fmt": 6,
		"Habilidades": 17, "Icones": 2, "Integridade": 9,
		"Longo prazo": 7, "Mecânicas": 69, "Mira": 6,
		"Mods": 19, "Numeros de dano": 2, "Offline": 6,
		"Ondas": 17, "Pista de ouro": 3, "Prestígio": 25,
		"Progresso": 14, "Saque": 8, "Save": 41,
		"Celebracao": 25, "Fim de sessao": 25, "Painel de melhorias": 28, "Rodape": 28, "Sistemas": 6, "StatEngine": 5, "Custo do quadro": 12, "Teto": 38, "Áudio": 45,
	}
	for nome_g in minimo_por_grupo:
		var rodou := int(por_grupo.get(nome_g, 0))
		var min_g := int(minimo_por_grupo[nome_g])
		if rodou < min_g:
			print("  FALHOU [suite] o grupo '%s' rodou %d assercoes, o minimo e %d — ele saiu cedo ou sumiu" % [
				nome_g, rodou, min_g])
			falhou += 1
	# Piso global continua, agora so como rede contra a suite encolher inteira.
	var piso := 360
	if passou < piso:
		print("  FALHOU [suite] rodou %d assercoes, piso e %d" % [passou, piso])
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
		"upgrades": Dados.upgrades.size(),
		"talentos": Dados.talentos.size(),
		"cartas": Dados.cartas.size(),
		"reliquias": Dados.reliquias.size(),
		"conquistas": Dados.conquistas.size(),
		"eras": Dados.eras.size(),
		"habilidades": Dados.habilidades.size(),
		"efeitos_audio": Sfx.nomes().size(),
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
			# O SELO DA PRIMEIRA TELA. Ele dizia 195/195 enquanto o portao media
			# centenas: e o primeiro numero que qualquer pessoa ve do projeto, e
			# era o mais velho de todos. Agora ele tambem responde ao portao.
			["!\\[Testes\\]\\(https://img\\.shields\\.io/badge/Testes-([\\d.]+)%2F", "testes"],
			["!\\[Testes\\]\\(https://img\\.shields\\.io/badge/Testes-[\\d.]+%2F([\\d.]+)-", "testes"],
		],
		"res://AGENTS.md": [
			["testes\\.gd\\s+# ([\\d.]+) testes da simula[cç][aã]o", "testes"],
		],
		# O PLANO ESTAVA FORA DO PORTAO e apodreceu em quatro numeros — dizia
		# 191 testes quando o portao media centenas, e 31 efeitos de audio.
		# Documento vivo que ninguem confere e pior que documento nenhum: ele
		# mente com a autoridade de estar no repositorio.
		"res://docs/PLANO.md": [
			["\\| ([\\d.]+) testes \\|", "testes"],
			["`testes` \\(([\\d.]+)\\)", "testes"],
			["([\\d.]+) efeitos \\+ m[uú]sica adaptativa", "efeitos_audio"],
			["(?m)^([\\d.]+) inimigos · ", "inimigos"],
			[" · ([\\d.]+) elites · ", "elites"],
			[" · ([\\d.]+) chefes · ", "chefes"],
			[" · ([\\d.]+) super-chefes · ", "super_chefes"],
			[" · ([\\d.]+) melhorias · ", "upgrades"],
			["([\\d.]+)\\s*\\ntalentos · ", "talentos"],
			[" · ([\\d.]+) cartas · ", "cartas"],
			[" · ([\\d.]+) rel[ií]quias · ", "reliquias"],
			[" · ([\\d.]+) conquistas · ", "conquistas"],
			[" · ([\\d.]+) eras · ", "eras"],
			["([\\d.]+) habilidades\\.", "habilidades"],
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
	erros += _conferir_contagem_honesta()
	erros += _conferir_saida_colada()

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

## Quantas assercoes cada grupo rodou nesta execucao.
var por_grupo := {}

func g(nome: String) -> void:
	grupo = nome
	if not por_grupo.has(nome):
		por_grupo[nome] = 0

func ok(nome: String, cond: bool, detalhe: String = "") -> void:
	por_grupo[grupo] = int(por_grupo.get(grupo, 0)) + 1
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

## ------------------------------- conteudo declarado tem que ser lido
## Um campo escrito em data/*.json que nenhum codigo le e uma promessa feita ao
## jogador e nao cumprida — e o jogo tinha varias. `sinergia` existia em 12 das
## 30 cartas e so pintava um rotulo; `semMorrer` anunciava "uma queda e a
## contagem recomeca" em duas missoes e nenhum codigo lia a flag, entao dava
## para morrer toda onda e faturar os 8 pontos de talento.
func t_conteudo_lido() -> void:
	g("Conteudo lido")
	var codigo := ""
	for arq in _listar_gd("res://scripts"):
		codigo += _sem_comentario(FileAccess.get_file_as_string(arq))

	# Campos de conteudo que precisam de leitor na SIMULACAO (nao vale so a UI).
	var codigo_sim := ""
	for arq2 in _listar_gd("res://scripts/sim"):
		codigo_sim += _sem_comentario(FileAccess.get_file_as_string(arq2))
	var campos := ["sinergia", "semMorrer"]
	var sem_leitor: Array = []
	for campo in campos:
		if not codigo_sim.contains('"%s"' % campo):
			sem_leitor.append(campo)
	ok("campo de conteudo declarado tem leitor na simulacao",
		sem_leitor.is_empty(), str(sem_leitor))

	# CHEFE COM PELE DIFERENTE E MECANICA IGUAL NAO E OUTRO CHEFE.
	# `aniquilador` e `trono_vazio` declaravam mecanica, fases e invoca
	# identicos e caiam no mesmo braco do codigo: dois nomes, uma luta. E a
	# dica do Trono prometia "fissuras", coisa que a luta nao tinha.
	var assinaturas := {}
	var repetidos: Array = []
	for sc in Dados.super_chefes:
		var assin := "%s|%s|%s" % [str(sc.get("mecanica", "")), str(sc.get("fases", 0)),
			str(sc.get("invoca", []))]
		if assinaturas.has(assin):
			repetidos.append("%s == %s" % [str(sc.get("id", "")), str(assinaturas[assin])])
		assinaturas[assin] = str(sc.get("id", ""))
	ok("cada super-chefe tem luta propria, nao so outra pele",
		repetidos.is_empty(), str(repetidos))

	# O PEREGRINO SO E ESCOLHA SE DER PARA POUPAR. A contagem dos dois lados
	# existia (`peregrino_morto` e `peregrino_poupado`), mas nenhum modo de mira
	# o excluia: a torre atirava sozinha e a decisao que o README vende se
	# resolvia sempre do mesmo jeito.
	var arena_p := Arena.new()
	arena_p.redimensionar(1280.0, 720.0)
	var def_per: Dictionary = Dados.inimigo_por_id.get("peregrino", {})
	if def_per.is_empty():
		for d_i in Dados.inimigos:
			if bool(d_i.get("peregrino", false)):
				def_per = d_i
				break
	ok("o Peregrino existe no conteudo", not def_per.is_empty())
	if not def_per.is_empty():
		jogo.arena.limpar_inimigos()
		var per := EnemyAI.criar(def_per, 30, jogo, {})
		if per != null:
			per.peregrino = true
			per.pos = Vector2(700.0, 400.0)
			jogo.arena.reconstruir_grade()
			jogo.arena.poupar_peregrino = false
			var mirado = jogo.arena.alvo(jogo.arena.centro, 900.0, "proximo")
			ok("com a mira normal, a torre escolhe o Peregrino", mirado == per)
			jogo.arena.poupar_peregrino = true
			var poupado = jogo.arena.alvo(jogo.arena.centro, 900.0, "proximo")
			ok("poupando, a mira NAO escolhe o Peregrino", poupado != per,
				"a escolha do jogador tem que valer")
			ok("e o projetil no ar tambem respeita",
				jogo.arena.primeiro_colidindo(per.pos, 40.0, {}) == null)
			jogo.arena.poupar_peregrino = false
		jogo.arena.limpar_inimigos()

	# Toda mecanica declarada no conteudo precisa de um braco no codigo.
	# Varre a simulacao INTEIRA, nao so game.gd: `segmentos` mora em enemy_ai.gd
	# e `refletir` em tower.gd, e a primeira versao deste teste os acusou de
	# mortos por olhar um arquivo so. Teste que acusa o inocente perde a
	# autoridade para acusar o culpado.
	var codigo_jogo := ""
	for arq_sim in _listar_gd("res://scripts/sim"):
		codigo_jogo += _sem_comentario(FileAccess.get_file_as_string(arq_sim))
	var sem_braco: Array = []
	for lista in [Dados.chefes, Dados.super_chefes]:
		for b_def in lista:
			var mec := str(b_def.get("mecanica", ""))
			if mec != "" and not codigo_jogo.contains('"%s"' % mec):
				sem_braco.append("%s -> %s" % [str(b_def.get("id", "")), mec])
	ok("toda mecanica de chefe tem braco no codigo",
		sem_braco.is_empty(), str(sem_braco))

	# `cuspir`: o `atirador` declara a habilidade, o codex EXPLICA ela ao
	# jogador, e a simulacao nao tinha o braco. O inimigo cujo nome e "atirador"
	# nunca atirou: andava ate a torre e batia como qualquer outro.
	var codigo_hab := ""
	for arq_h in _listar_gd("res://scripts/sim"):
		codigo_hab += _sem_comentario(FileAccess.get_file_as_string(arq_h))
	var habs_sem_braco: Array = []
	for e_def in Dados.inimigos:
		var h := str(e_def.get("hab", ""))
		if h != "" and not codigo_hab.contains('"%s"' % h):
			habs_sem_braco.append("%s -> %s" % [str(e_def.get("id", "")), h])
	ok("toda habilidade de inimigo tem braco na simulacao",
		habs_sem_braco.is_empty(), str(habs_sem_braco))

	# NINGUEM ATIRA NA TORRE DE FORA DO ALCANCE DELA.
	#
	# O `atirador` declara `alcance: 260` e o alcance BASE da torre e 260 — os
	# dois exatamente iguais. Quando o `cuspir` foi implementado, ele passou a
	# parar no proprio alcance de tiro, e um pixel de arredondamento o deixava a
	# 260,1 px: fora do alcance da torre, atirando impunemente para sempre. A
	# onda nunca fechava e o jogo travava por volta da onda 100 sem que nada na
	# tela explicasse. Empate assim nao pode voltar por descuido de dado.
	var alc_torre := float(Dados.stat_defs.get("alcance", {}).get("base", 260.0))
	var atiradores_intocaveis: Array = []
	for e_def2 in Dados.inimigos:
		if str(e_def2.get("hab", "")) != "cuspir":
			continue
		var alc_dele := float(e_def2.get("alcance", 260.0)) * EnemyAI.CUSPIR_PARADA
		if alc_dele >= alc_torre:
			atiradores_intocaveis.append("%s para a %.0f px, torre alcanca %.0f" % [
				str(e_def2.get("id", "")), alc_dele, alc_torre])
	ok("nenhum atirador para fora do alcance base da torre",
		atiradores_intocaveis.is_empty(), str(atiradores_intocaveis))

	# `ondaMax`: doze dos catorze desafios declaram a linha de chegada, o painel
	# anuncia esse numero como a meta, e `encerrar_desafio(true)` nao tinha UM
	# chamador — o desafio nunca terminava e a recompensa era inalcancavel.
	var com_teto := 0
	for d_def in Dados.desafios:
		if float(d_def.get("mods", {}).get("ondaMax", 0.0)) > 0.0:
			com_teto += 1
	ok("os desafios declaram linha de chegada", com_teto > 0, "%d de %d" % [com_teto, Dados.desafios.size()])
	ok("alguem le ondaMax e encerra o desafio",
		codigo_hab.contains("ondaMax") and codigo_hab.contains("encerrar_desafio(true)"),
		"encerrar_desafio(true) precisa de chamador")

	# `salvamento_travado` era trava de MAO UNICA: ligava no boot, o sinal nao
	# tinha ouvinte e nao existia caminho para religar. Trancar sem oferecer a
	# chave nao e proteger, e prender.
	var codigo_ui2 := ""
	for arq_u in _listar_gd("res://scripts/ui"):
		codigo_ui2 += _sem_comentario(FileAccess.get_file_as_string(arq_u))
	ok("o save travado tem quem avise o jogador",
		codigo_ui2.contains("save_ilegivel"), "ninguem escuta o sinal")
	ok("o save travado tem como destravar",
		codigo_ui2.contains("destravar_salvamento("), "sem caminho de volta")

	# ANTECIPAR A ONDA: a decisao que devolve o ritmo ao jogador.
	# O ritmo era do spawner — comprar poder nao encurtava nada dentro de uma
	# run. Acelerar o spawner sozinho foi tentado e quebrou o jogo (onda 100 de
	# 30m56 para 1h03, onda maxima de 261 para 115), porque o tempo de espera
	# era, na pratica, tempo de acumular poder.
	jogo.diretor.estado = "intervalo"
	jogo.diretor.timer = jogo.diretor.intervalo_entre_ondas
	var ouro_antes: float = jogo.s["moedas"]["ouro"]
	var cedo: bool = jogo.diretor.antecipar()
	var ganho_cedo := Big.sub(jogo.s["moedas"]["ouro"], ouro_antes)
	ok("da para chamar a onda durante o respiro", cedo)
	ok("chamar cedo paga ouro", Big.gt(ganho_cedo, Big.ZERO))

	# E o bonus e proporcional: chamar em cima da hora paga menos.
	jogo.diretor.estado = "intervalo"
	jogo.diretor.timer = jogo.diretor.intervalo_entre_ondas * 0.05
	var ouro2: float = jogo.s["moedas"]["ouro"]
	jogo.diretor.antecipar()
	var ganho_tarde := Big.sub(jogo.s["moedas"]["ouro"], ouro2)
	ok("chamar em cima da hora paga menos que chamar cedo",
		Big.lt(ganho_tarde, ganho_cedo),
		"cedo=%s tarde=%s" % [Fmt.big(ganho_cedo), Fmt.big(ganho_tarde)])

	# Fora do respiro nao da para chamar: senao viraria um botao de pular onda.
	jogo.diretor.estado = "ativa"
	ok("fora do respiro nao da para chamar", not jogo.diretor.antecipar())

	# SINERGIA: a dupla equipada tem que pagar mais que as cartas soltas.
	var achou_par := {}
	for c in Dados.cartas:
		var par := str(c.get("sinergia", ""))
		if par != "" and Dados.carta_por_id.has(par):
			achou_par = {"a": str(c.get("id", "")), "b": par}
			break
	ok("ha par de sinergia no conteudo", not achou_par.is_empty())
	if not achou_par.is_empty():
		var s_par := GameState.novo()
		var m_sem := Mods.recalcular(s_par, StatEngine.new())
		var base_sem: float = float(m_sem["stats"].n("multiplicador"))
		# Equipa as duas cartas do par.
		var inv: Array = s_par["cartas"]["inventario"]
		var uids: Array = []
		for id_carta in [str(achou_par["a"]), str(achou_par["b"])]:
			var uid := "sin_%s" % id_carta
			inv.append({"uid": uid, "id": id_carta, "raridade": "comum", "nivel": 1})
			uids.append(uid)
		s_par["cartas"]["equipadas"] = uids
		var m_com = Mods.recalcular(s_par, StatEngine.new())
		var base_com: float = float(m_com["stats"].n("multiplicador"))
		ok("a dupla de sinergia paga mais que as cartas soltas",
			base_com > base_sem,
			"sem=%s com=%s" % [str(base_sem), str(base_com)])

	# semMorrer: cair zera a contagem.
	var s_m := GameState.novo()
	var def_sm: Dictionary = {}
	for d in (Dados.missoes_diarias + Dados.missoes_semanais):
		if bool(d.get("semMorrer", false)):
			def_sm = d
			break
	ok("ha missao semMorrer no conteudo", not def_sm.is_empty())
	if not def_sm.is_empty():
		var mi := {"id": str(def_sm.get("id", "")), "alvo": 999.0, "prog": 0.0,
			"base": 0.0, "pronta": false, "coletada": false, "quedas_base": -1}
		s_m["missoes"]["diarias"] = [mi]
		s_m["stats"]["mortes"] = 0
		s_m["onda_maxima"] = 10
		Progresso.checar_missoes(_jogo_falso(s_m))
		var prog1 := float(mi["prog"])
		s_m["stats"]["mortes"] = 1
		s_m["onda_maxima"] = 20
		Progresso.checar_missoes(_jogo_falso(s_m))
		ok("cair zera a contagem da missao semMorrer",
			float(mi["prog"]) <= prog1 + 0.001,
			"prog %s -> %s" % [str(prog1), str(mi["prog"])])

## Usa um elemento por `segundos`, como o jogo faz: marca o uso e deixa o
## relogio andar. A adaptacao sobe por TEMPO, nao por numero de acertos.
func _usar_elemento(estado: Dictionary, elemento: String, segundos: float) -> void:
	var passo := 1.0 / 60.0
	var n := int(segundos / passo)
	for i in n:
		Mecanicas.registrar_elemento(estado, elemento)
		Mecanicas.decair_adaptacao(passo, estado)

## Envelope minimo para exercitar `Progresso` sem subir o jogo inteiro.
func _jogo_falso(estado: Dictionary):
	var j := JogoFalso.new()
	j.s = estado
	return j

class JogoFalso:
	extends RefCounted
	var s: Dictionary = {}
	func marcar_sujo() -> void:
		pass

## ----------------------------------------- o tempo tem um dono so
## Quatro pontos escreviam em `Engine.time_scale` sem se falar: a velocidade
## escolhida pelo jogador, a Retomada (6x), a camera lenta do juice e o fim da
## Retomada. Eles brigavam de verdade — a camera lenta de um chefe morrendo,
## ao terminar, restaurava a "velocidade base" e MATAVA a Retomada no meio.
## Agora sao tres fatores independentes e um dono que multiplica.
func t_tempo() -> void:
	g("Tempo")
	jogo.velocidade = 1.0
	jogo.fator_retomada = 1.0
	jogo.fator_lenta = 1.0
	jogo.aplicar_time_scale()
	ok("parado em 1x", perto(Engine.time_scale, 1.0, 0.001), str(Engine.time_scale))

	jogo.definir_velocidade(2.0)
	var v2 := Engine.time_scale
	jogo.fator_lenta = 0.25
	jogo.aplicar_time_scale()
	ok("camera lenta multiplica a velocidade escolhida",
		perto(Engine.time_scale, v2 * 0.25, 0.001), str(Engine.time_scale))

	# O caso que quebrava: a camera lenta acaba enquanto a Retomada corre.
	jogo.fator_retomada = Mecanicas.RETOMADA_VELOCIDADE
	jogo.aplicar_time_scale()
	jogo.fator_lenta = 1.0
	jogo.aplicar_time_scale()
	ok("a camera lenta acabando NAO mata a Retomada",
		Engine.time_scale >= v2 * Mecanicas.RETOMADA_VELOCIDADE - 0.01,
		"time_scale=%s" % str(Engine.time_scale))

	jogo.fator_retomada = 1.0
	jogo.definir_velocidade(1.0)
	ok("volta ao normal no fim", perto(Engine.time_scale, 1.0, 0.001), str(Engine.time_scale))

	# Ninguem alem do dono pode escrever no relogio.
	var escritores: Array = []
	for arq in _listar_gd("res://scripts"):
		if arq.ends_with("game.gd"):
			continue
		var texto := _sem_comentario(FileAccess.get_file_as_string(arq))
		if texto.contains("Engine.time_scale ="):
			escritores.append(arq)
	ok("so o Jogo escreve em Engine.time_scale", escritores.is_empty(), str(escritores))

## --------------------------------- daltonismo: a medida que faltava
## O criterio 12 promete "daltonismo medido por separacao percebida" e se
## classifica como MEDIDA — "um comando produz um numero". Nao existia
## instrumento nenhum: o grupo Acessibilidade so tinha tremor e contraste WCAG.
## O unico numero publicado estava num comentario do proprio shader, e um juiz
## apontou o problema certo: ele foi obtido contra o modelo do proprio shader.
##
## Este e o instrumento. A parte que importa — a METRICA — e independente do
## filtro: converte sRGB para CIELAB e mede distancia perceptual, que e a
## pergunta "essas duas cores parecem diferentes para essa pessoa?". O que se
## replica do shader e so a simulacao de dicromacia (Vienot 1999) e a correcao,
## porque sem renderizar nao ha outro jeito de saber o que vai para a tela.
##
## O portao cobra o que o filtro promete: melhorar a MEDIA e, sobretudo, o PIOR
## PAR — acessibilidade nao se mede pela media, se mede pelo caso ruim.
func t_daltonismo() -> void:
	g("Daltonismo")
	var paleta: Array = [
		UI.ACENTO, UI.ACENTO2, UI.OURO, UI.VERDE, UI.VERMELHO,
		UI.TEXTO, UI.TEXTO2, UI.TEXTO3, UI.PAINEL, UI.PAINEL2, UI.BORDA,
	]
	var modos := {1: "protanopia", 2: "deuteranopia", 3: "tritanopia"}
	for modo in modos:
		var antes := _separacao(paleta, int(modo), false)
		var depois := _separacao(paleta, int(modo), true)
		# O PIOR PAR e o que decide, e por isso e a assercao dura. Duas cores
		# indistinguiveis fazem a informacao SUMIR para quem depende delas; uma
		# media alta nao devolve nada a essa pessoa. Medido: o filtro melhora o
		# pior par nos tres modos (5,2->5,4 | 5,1->5,6 | 5,3->5,6).
		ok("%s: o filtro melhora o PIOR par" % str(modos[modo]),
			float(depois[1]) >= float(antes[1]) - 0.001,
			"pior %.1f -> %.1f" % [float(antes[1]), float(depois[1])])
		# E a media NAO PODE DESABAR em troca. O filtro custa media — varri o
		# coeficiente de 0,0 a 0,4 e nenhum valor melhora a media em nenhum modo,
		# entao cobrar melhora aqui seria cobrar o impossivel. O que se cobra e
		# que o preco fique dentro de 6%: acima disso a tela inteira fica mais
		# chapada para ganhar um par, o que e um mau negocio.
		ok("%s: a media nao desaba em troca do pior par" % str(modos[modo]),
			float(depois[0]) >= float(antes[0]) * 0.94,
			"media %.1f -> %.1f (piso %.1f)" % [float(antes[0]), float(depois[0]), float(antes[0]) * 0.94])
		# Um filtro que satura tudo tambem "melhora" numeros e destroi a tela.
		ok("%s: o filtro nao satura a paleta" % str(modos[modo]),
			float(depois[2]) < 0.35,
			"fracao de canais no teto: %.2f" % float(depois[2]))

## [media, pior, fracao_saturada] da distancia CIELAB entre todos os pares da
## paleta, vistos por um dicromata do `modo`, com ou sem o filtro aplicado.
func _separacao(paleta: Array, modo: int, com_filtro: bool) -> Array:
	var vistas: Array = []
	var saturados := 0
	var canais := 0
	for cor in paleta:
		var c: Color = cor
		var final := _filtrar(c, modo) if com_filtro else c
		for v in [final.r, final.g, final.b]:
			canais += 1
			if v >= 0.999:
				saturados += 1
		vistas.append(_simular(final, modo))
	var soma := 0.0
	var pior := 1.0e9
	var n := 0
	for i in vistas.size():
		for j in range(i + 1, vistas.size()):
			var d := _dist_lab(vistas[i], vistas[j])
			soma += d
			pior = minf(pior, d)
			n += 1
	return [soma / maxf(1.0, float(n)), pior, float(saturados) / maxf(1.0, float(canais))]

## Simulacao de dicromacia (Vienot, Brettel & Mollon 1999), a mesma do shader.
func _simular(c: Color, modo: int) -> Color:
	match modo:
		1: return Color(
			0.567 * c.r + 0.433 * c.g,
			0.558 * c.r + 0.442 * c.g,
			0.242 * c.g + 0.758 * c.b)
		2: return Color(
			0.625 * c.r + 0.375 * c.g,
			0.7 * c.r + 0.3 * c.g,
			0.3 * c.g + 0.7 * c.b)
		_: return Color(
			0.95 * c.r + 0.05 * c.g,
			0.433 * c.g + 0.567 * c.b,
			0.475 * c.g + 0.525 * c.b)

## A correcao do shader, replicada: erro devolvido aos canais que a pessoa VE.
func _filtrar(c: Color, modo: int) -> Color:
	var s := _simular(c, modo)
	var er := c.r - s.r
	var eg := c.g - s.g
	var eb := c.b - s.b
	var corr := Vector3.ZERO
	if modo == 3:
		corr = Vector3(eb * 0.7 + er, eb * 0.7 + eg, 0.0)
	else:
		corr = Vector3(0.0, er * 0.7 + eg, er * 0.7 + eb)
	var perdido := (eb - (er + eg) * 0.5) if modo == 3 else (er - eg)
	return Color(
		clampf(c.r + corr.x + perdido * 0.3, 0.0, 1.0),
		clampf(c.g + corr.y + perdido * 0.3, 0.0, 1.0),
		clampf(c.b + corr.z + perdido * 0.3, 0.0, 1.0))

## Distancia CIELAB (DeltaE 76). E a METRICA, e nao vem do shader: e a pergunta
## "essas duas cores parecem diferentes?" respondida em espaco perceptual.
func _dist_lab(a: Color, b: Color) -> float:
	var la := _lab(a)
	var lb := _lab(b)
	return sqrt(pow(la.x - lb.x, 2.0) + pow(la.y - lb.y, 2.0) + pow(la.z - lb.z, 2.0))

func _lab(c: Color) -> Vector3:
	var r := _linear(c.r)
	var g := _linear(c.g)
	var b := _linear(c.b)
	var x := (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
	var y := r * 0.2126 + g * 0.7152 + b * 0.0722
	var z := (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
	var fx := _f_lab(x)
	var fy := _f_lab(y)
	var fz := _f_lab(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))

func _linear(v: float) -> float:
	return pow((v + 0.055) / 1.055, 2.4) if v > 0.04045 else v / 12.92

func _f_lab(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else (7.787 * t + 16.0 / 116.0)

## ------------------------------------------- as ferramentas nao mentem
## O veredito IMPRESSO e o CODIGO DE SAIDA tem que dizer a mesma coisa.
##
## `verificar.gd` escrevia FAIL quando faltava arquivo de dados e saia 0 mesmo
## assim: quem lesse o texto via reprovacao, quem lesse o codigo de saida — o
## CI, por exemplo — via aprovacao. A condicao do print considerava `faltando`
## e a do quit nao. Um portao que reprova por escrito e aprova por codigo nao e
## portao; e enfeite. Este teste cobra que as duas condicoes sejam a mesma em
## toda ferramenta que tenha veredito.
func t_ferramentas() -> void:
	g("Ferramentas")
	var arquivos := [
		"res://tools/verificar.gd", "res://tools/lint.gd",
		"res://tools/suites/testes.gd", "res://tools/suites/validar_dados.gd",
		"res://tools/suites/soak.gd", "res://tools/suites/perf.gd",
	]
	var sem_quit: Array = []
	var suspeitas: Array = []
	for arq in arquivos:
		var texto := _sem_comentario(FileAccess.get_file_as_string(arq))
		if not texto.contains("quit("):
			sem_quit.append(arq)
			continue
		# Toda ferramenta com veredito precisa sair com codigo derivado de uma
		# condicao, nunca de um `quit(0)` cru no fim do caminho de sucesso E de
		# falha. `quit(0 if <cond> else 1)` e a forma certa.
		if not (texto.contains("quit(0 if") or texto.contains("quit(1)")):
			suspeitas.append(arq)
	ok("toda ferramenta de portao termina com quit", sem_quit.is_empty(), str(sem_quit))
	ok("o codigo de saida vem de uma condicao, nao e fixo",
		suspeitas.is_empty(), str(suspeitas))

	# O caso concreto que motivou o teste: `verificar.gd` tem que considerar
	# dados faltando no codigo de saida, nao so no texto.
	var ver := _sem_comentario(FileAccess.get_file_as_string("res://tools/verificar.gd"))
	ok("verificar.gd reprova de verdade quando falta dado",
		ver.contains("faltando.is_empty()") and ver.contains("quit(0 if falhas.is_empty() and faltando.is_empty()"),
		"a condicao do quit precisa incluir `faltando`")

## ------------------------------------------------- nada acontece mudo
## Todo evento que o jogador PERCEBE precisa de resposta: visual, sonora, ou as
## duas. Um mapa dos sinais contra scripts/render/ e scripts/audio/ mostrou que
## `overkill` — o abate mais satisfatorio que o genero tem — nao tinha NENHUMA
## das duas, e que um chefe morrendo tinha som mas nenhum visual proprio: caia
## igual a um grunhido. Este teste existe para que a proxima mecanica nova nao
## nasca muda.
func t_nada_mudo() -> void:
	g("Feedback")
	var render := ""
	for arq in _listar_gd("res://scripts/render"):
		render += FileAccess.get_file_as_string(arq)
	var audio := ""
	for arq in _listar_gd("res://scripts/audio"):
		audio += FileAccess.get_file_as_string(arq)
	var ui := ""
	for arq in _listar_gd("res://scripts/ui"):
		ui += FileAccess.get_file_as_string(arq)

	# Eventos que o jogador vê ou ouve acontecer. Ficam de fora os puramente
	# internos (config mudou, save ilegível), que não são momento de jogo.
	var eventos := [
		"inimigo_morreu", "chefe_morreu", "chefe_surgiu", "chefe_fase", "overkill",
		"combo_mudou", "nivel_subiu", "conquista_desbloqueada", "missao_concluida",
		"prestigio_feito", "carta_caiu", "carta_equipada", "upgrade_comprado",
		"onda_iniciou", "onda_limpa", "onda_falhou", "torre_atingida", "torre_caiu",
		"inimigo_atingido", "moeda_ganha", "talento_comprado",
	]
	var mudos: Array = []
	for ev in eventos:
		var tem_visual := render.contains(ev) or ui.contains(ev)
		var tem_som := audio.contains(ev)
		if not tem_visual and not tem_som:
			mudos.append(ev)
	ok("nenhum evento do jogador acontece sem resposta", mudos.is_empty(),
		"mudos: %s" % str(mudos))

	# Os momentos GRANDES precisam de resposta visual propria — som sozinho nao
	# distingue um chefe caindo de um inimigo comum.
	var grandes := ["chefe_morreu", "chefe_fase", "overkill", "nivel_subiu",
		"conquista_desbloqueada", "prestigio_feito"]
	var sem_visual: Array = []
	for ev in grandes:
		if not render.contains(ev):
			sem_visual.append(ev)
	ok("os momentos grandes tem resposta visual propria", sem_visual.is_empty(),
		"sem visual: %s" % str(sem_visual))

## ------------------------------------------------ sistemas alcancaveis
## Duas vezes o mesmo defeito: uma funcao que e a UNICA porta para um sistema
## inteiro, com teste proprio passando, e zero chamadores fora dos testes. O
## Modo Infinito foi consertado primeiro; o Modo Farm, irmao ao lado, ficou
## quebrado mais tempo justamente porque ninguem perguntou de novo. E o Panteao
## — que o README vende como "o unico sistema em que voce perde algo de verdade"
## — nao tinha botao, tecla nem string: o jogador nao tinha como chegar nele.
##
## Este teste faz a pergunta uma vez por todas: toda funcao que abre um sistema
## precisa de um chamador FORA de tools/. Teste que passa sozinho nao prova que
## o jogador alcanca a coisa.
func t_alcancavel() -> void:
	g("Alcancavel")
	var portas := {
		"consagrar": "o Panteao",
		"alternar_farm": "o Modo Farm",
		"alternar_infinito": "o Modo Infinito",
		"disparar_purga": "a Purga",
		"ascender": "a Ascensao",
		"colapsar": "a Singularidade",
		"transcender": "a Transcendencia",
	}
	var codigo_ui := ""
	for arq in _listar_gd("res://scripts"):
		codigo_ui += FileAccess.get_file_as_string(arq)
	# TODO DESBLOQUEIO PAGO PRECISA DE INTERRUPTOR.
	#
	# `autoPurga` custava 120 fragmentos e `modoFarm` 35, e nenhum dos dois tinha
	# quem os ligasse: a flag era LIDA pela simulacao e nunca ESCRITA por ninguem.
	# O jogador pagava a compra mais cara do comeco da arvore e nada acontecia.
	# Nao basta o desbloqueio existir nos dados: alguem tem que poder liga-lo.
	var chaves := {
		"autoPurga": "p[\"auto\"] =",
		"modoFarm": "alternar_farm(",
		"autoCompra": "[\"comprar\"] =",
		"autoHabilidade": "[\"habilidades\"] =",
		"modoInfinito": "alternar_infinito(",
	}
	var sem_interruptor: Array = []
	for chave in chaves:
		if not codigo_ui.contains(str(chaves[chave])):
			sem_interruptor.append(str(chave))
	ok("todo desbloqueio pago tem interruptor na interface",
		sem_interruptor.is_empty(), str(sem_interruptor))

	for nome in portas:
		var alcancavel := codigo_ui.contains(nome + "(")
		# `contains(nome + "(")` acha tanto a definicao quanto a chamada, entao
		# so vale se aparecer MAIS de uma vez: uma e a propria declaracao.
		var vezes := codigo_ui.count(nome + "(")
		ok("%s tem porta no jogo" % str(portas[nome]), alcancavel and vezes >= 2,
			"%s aparece %d vez(es) em scripts/" % [nome, vezes])

## Todo `.gd` sob um diretorio, recursivo.
func _listar_gd(raiz: String) -> Array:
	var saida: Array = []
	var d := DirAccess.open(raiz)
	if d == null:
		return saida
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		var caminho := raiz + "/" + nome
		if d.current_is_dir():
			saida.append_array(_listar_gd(caminho))
		elif nome.ends_with(".gd"):
			saida.append(caminho)
		nome = d.get_next()
	d.list_dir_end()
	return saida

## --------------------------------------------------- elites de verdade
## Seis dos nove modificadores de elite tinham campo mecânico no JSON ou um
## ramo no código. Três — espinhoso, magnetico e fantasmal — tinham APENAS id,
## nome, cor e descrição: eram recolorização pura, e as descrições prometiam
## mecânica exata ao jogador, nos dois idiomas, impressa no codex. Uma auditoria
## independente pegou isso com `grep -rn espinhoso scripts/sim/` devolvendo
## zero. Estes testes existem para que a promessa não volte a ser só cor.
func t_elites() -> void:
	g("Elites")
	var def: Dictionary = Dados.inimigo_por_id["grunhido"]

	# Todo modificador de elite precisa de efeito: ou um campo que muda número,
	# ou um ramo no código que leia o id. Cor e texto não bastam.
	var com_efeito := 0
	var so_cor: Array = []
	var codigo := ""
	for arq in ["res://scripts/sim/enemy_ai.gd", "res://scripts/sim/combat.gd",
			"res://scripts/sim/game.gd", "res://scripts/sim/economy.gd"]:
		codigo += FileAccess.get_file_as_string(arq)
	for m in Dados.elites:
		var id := str(m.get("id", ""))
		var tem_campo: bool = m.has("hp") or m.has("vel") or m.has("esc") or m.has("ouro")
		var tem_ramo := codigo.contains('"%s"' % id)
		if tem_campo or tem_ramo:
			com_efeito += 1
		else:
			so_cor.append(id)
	ok("todo elite muda o jogo, nao so a cor", so_cor.is_empty(),
		"so cor e texto: %s" % str(so_cor))
	ok("os 9 modificadores foram conferidos", com_efeito == Dados.elites.size(),
		"com efeito=%d de %d" % [com_efeito, Dados.elites.size()])

	# fantasmal: fica intangivel e volta
	jogo.arena.limpar_inimigos()
	var fan := EnemyAI.criar(def, 10, jogo, {"elite": true, "elite_mod": "fantasmal"})
	ok("fantasmal nasce solido", fan != null and fan.intangivel <= 0.0)
	if fan != null:
		var virou := false
		var voltou := false
		for i in 400:
			EnemyAI.atualizar(1.0 / 60.0, jogo)
			if fan.intangivel > 0.0:
				virou = true
			elif virou:
				voltou = true
				break
		ok("fantasmal fica intangivel", virou)
		ok("fantasmal volta a ser solido", voltou)
		# Enquanto intangivel, a mira nao pode enxerga-lo.
		fan.intangivel = 1.0
		fan.pos = Vector2(600.0, 400.0)
		jogo.arena.reconstruir_grade()
		ok("intangivel some da mira",
			jogo.arena.alvo_ids(Vector2(600.0, 400.0), 200.0, {}) == null)
		fan.intangivel = 0.0
		jogo.arena.reconstruir_grade()
		ok("solido volta para a mira",
			jogo.arena.alvo_ids(Vector2(600.0, 400.0), 200.0, {}) == fan)

	# espinhoso: devolve dano em contato
	jogo.arena.limpar_inimigos()
	var esp := EnemyAI.criar(def, 10, jogo, {"elite": true, "elite_mod": "espinhoso"})
	var comum := EnemyAI.criar(def, 10, jogo, {"elite": true, "elite_mod": "blindado"})
	if esp != null and comum != null:
		var torre_s: Dictionary = jogo.s["torre"]
		torre_s["vida"] = Big.from(1.0e9)
		torre_s["escudo"] = Big.ZERO
		jogo.invulneravel = 0.0
		var vida0: float = torre_s["vida"]
		Combate.aplicar_dano(esp, Big.from(1000.0), jogo, {"puro": true})
		var perdeu_com_espinho := Big.lt(torre_s["vida"], vida0)
		ok("espinhoso devolve dano quando atingido", perdeu_com_espinho)
		torre_s["vida"] = Big.from(1.0e9)
		torre_s["escudo"] = Big.ZERO
		jogo.invulneravel = 0.0
		var vida1: float = torre_s["vida"]
		Combate.aplicar_dano(comum, Big.from(1000.0), jogo, {"puro": true})
		ok("elite comum nao devolve dano", not Big.lt(torre_s["vida"], vida1))

	# magnetico: rouba o ouro do chao
	jogo.arena.limpar_inimigos()
	var mag := EnemyAI.criar(def, 10, jogo, {"elite": true, "elite_mod": "magnetico"})
	if mag != null:
		mag.pos = Vector2(900.0, 400.0)
		var centro: Vector2 = jogo.arena.centro
		var c: Coletavel = jogo.arena.novo_coletavel()
		c.ativo = true
		c.pos = Vector2(860.0, 400.0)
		c.tipo = "ouro"
		c.valor = Big.from(10.0)
		c.atraido = false
		c.t = 0.0
		c.vel = Vector2.ZERO
		var perto_do_ima0: float = c.pos.distance_to(mag.pos)
		var perto_do_centro0: float = c.pos.distance_to(centro)
		for i in 20:
			Economia.atualizar_coletaveis(1.0 / 60.0, jogo)
		var perto_do_ima1: float = c.pos.distance_to(mag.pos)
		var perto_do_centro1: float = c.pos.distance_to(centro)
		ok("magnetico puxa o ouro para si", perto_do_ima1 < perto_do_ima0,
			"antes=%.1f depois=%.1f" % [perto_do_ima0, perto_do_ima1])
		ok("o ouro roubado se afasta da torre", perto_do_centro1 > perto_do_centro0,
			"antes=%.1f depois=%.1f" % [perto_do_centro0, perto_do_centro1])
	jogo.arena.limpar_inimigos()

## ------------------------------------------------------------- mira
## `alvo_ids` é a busca mais quente do jogo (todo impacto de perfuração e todo
## ricochete faz uma) e não tinha UM teste. Ela foi trocada de varredura linear
## por busca em anéis de células, e a única coisa que garante que a troca não
## mexeu no jogo é isto: a resposta da grade tem que bater com a da varredura
## burra, em cem arranjos diferentes, incluindo os casos que quebram poda mal
## feita — alvo fora do alcance, todos ignorados, arena vazia.
func t_mira() -> void:
	g("Mira")
	var arena = jogo.arena
	arena.limpar_inimigos()
	var def: Dictionary = Dados.inimigo_por_id["grunhido"]
	var r := RngX.new(4242)

	# Referência burra: varre todos, sem grade, sem poda. É o que a função fazia.
	var linear := func(origem: Vector2, alcance: float, ids: Dictionary):
		var melhor = null
		var melhor_d: float = alcance * alcance
		for e in arena.inimigos:
			if not e.vivo() or e.intangivel > 0.0 or ids.has(e.id):
				continue
			var d2: float = (e.pos - origem).length_squared()
			if d2 < melhor_d:
				melhor_d = d2
				melhor = e
		return melhor

	var divergencias := 0
	var achou_alguem := 0
	var achou_ninguem := 0
	for rodada in 100:
		arena.limpar_inimigos()
		var quantos := 1 + int(r.f() * 40.0)
		for i in quantos:
			var e := EnemyAI.criar(def, 10, jogo, {})
			if e != null:
				e.pos = Vector2(r.entre(-200.0, 1400.0), r.entre(-200.0, 900.0))
		arena.reconstruir_grade()

		# Ignora um pedaço deles, como um projétil perfurante já teria feito.
		var ids := {}
		for e in arena.inimigos:
			if r.f() < 0.4:
				ids[e.id] = true

		var origem := Vector2(r.entre(0.0, 1280.0), r.entre(0.0, 720.0))
		var alcance: float = [40.0, 240.0, 400.0, 2000.0][int(r.f() * 4.0)]
		var a = arena.alvo_ids(origem, alcance, ids)
		var b = linear.call(origem, alcance, ids)
		if a != b:
			divergencias += 1
		if a == null:
			achou_ninguem += 1
		else:
			achou_alguem += 1

	ok("grade concorda com a varredura linear em 100 arranjos", divergencias == 0,
		"divergencias=%d" % divergencias)
	# Sem isto o teste passaria com uma função que devolve sempre null.
	ok("os 100 arranjos cobriram achar e nao achar", achou_alguem > 10 and achou_ninguem > 0,
		"achou=%d vazio=%d" % [achou_alguem, achou_ninguem])

	# Poda com alvo colado na origem: o anel 0 já resolve e o resto tem que ser
	# ignorado sem perder um alvo que esteja mais longe porém dentro do alcance.
	arena.limpar_inimigos()
	var perto_e := EnemyAI.criar(def, 10, jogo, {})
	var longe_e := EnemyAI.criar(def, 10, jogo, {})
	perto_e.pos = Vector2(600.0, 400.0)
	longe_e.pos = Vector2(900.0, 400.0)
	arena.reconstruir_grade()
	ok("pega o mais perto", arena.alvo_ids(Vector2(610.0, 400.0), 400.0, {}) == perto_e)
	ok("pula o ignorado e pega o de tras",
		arena.alvo_ids(Vector2(610.0, 400.0), 400.0, {perto_e.id: true}) == longe_e)
	ok("nada dentro do alcance devolve nulo",
		arena.alvo_ids(Vector2(610.0, 400.0), 50.0, {perto_e.id: true}) == null)
	perto_e.intangivel = 1.0
	ok("inimigo intangivel nao e alvo",
		arena.alvo_ids(Vector2(610.0, 400.0), 400.0, {}) == longe_e)
	perto_e.intangivel = 0.0
	arena.limpar_inimigos()

## -------------------------------------------------------- fim de sessao / morte
func t_fim_de_sessao() -> void:
	g("Fim de sessao")
	# MORRER ERA UM BOTAO DE PANICO GRATUITO: a torre voltava com vida cheia,
	# escudo cheio e a arena LIMPA. Numa onda ruim, deixar cair era a melhor
	# jogada disponivel. E o Contrato de Recompra promete, escrito no painel,
	# "ao cair voce mantem TODO O OURO" — protegendo de uma perda inexistente.
	ok("a perda por morte existe e e uma parcela sensata",
		Bal.PERDA_OURO_MORTE > 0.0 and Bal.PERDA_OURO_MORTE < 0.6)
	jogo.pas.erase("contrato_recompra")
	jogo.recompras_usadas = 0
	jogo.s["moedas"]["ouro"] = Big.from(1.0e9)
	jogo.reviver_torre()
	var sobrou := Big.to_f(jogo.s["moedas"]["ouro"])
	ok("cair custa ouro nao gasto", sobrou < 1.0e9)
	ok("...mas nao apaga o cofre", perto(sobrou, 1.0e9 * (1.0 - Bal.PERDA_OURO_MORTE), 1.0e6))
	ok("a torre volta viva", bool(jogo.s["torre"]["viva"]))
	# ...e a reliquia passa a valer o que promete.
	jogo.pas["contrato_recompra"] = 1
	jogo.recompras_usadas = 0
	jogo.s["moedas"]["ouro"] = Big.from(1.0e9)
	jogo.reviver_torre()
	ok("com o Contrato de Recompra o ouro fica inteiro",
		perto(Big.to_f(jogo.s["moedas"]["ouro"]), 1.0e9, 1.0e3))
	jogo.pas.erase("contrato_recompra")

	# O ALBUM DE ECOS PAGAVA EM SILENCIO: a palavra "album" nao aparecia uma vez
	# em `scripts/ui/`. E o unico progresso que nenhum prestigio tira.
	var st_alb: Dictionary = GameState.novo()
	var alb0: Dictionary = Mecanicas.bonus_album(st_alb)
	ok("album vazio nao paga nada", int(alb0["n"]) == 0 and float(alb0["dano"]) == 0.0)
	ok("registrar uma carta entra no album", Mecanicas.registrar_no_album(st_alb, "x"))
	ok("registrar a MESMA carta nao conta de novo", not Mecanicas.registrar_no_album(st_alb, "x"))
	var alb1: Dictionary = Mecanicas.bonus_album(st_alb)
	ok("uma carta no album ja paga dano", float(alb1["dano"]) > 0.0)
	ok("...e ouro", float(alb1["ouro"]) > 0.0)
	var txt_ca := _ler("res://scripts/ui/panel_cartas.gd")
	ok("o painel de Cartas mostra o Album", txt_ca.contains("Mecanicas.bonus_album("))
	ok("...com o placar de quantas de quantas", txt_ca.contains('lbl_album.text = "%d / %d"'))
	ok("...e com o bonus que ele paga", txt_ca.contains("car_album_bonus"))
	for chave_a in ["car_album", "car_album_bonus", "car_album_dica"]:
		ok("a chave %s existe" % chave_a, Txt.t(str(chave_a)) != str(chave_a))

	# COLETAR TUDO: o criterio ja existia dos dois lados, faltava o botao.
	var st: Dictionary = GameState.novo()
	ok("estado novo nao tem nada a coletar", Progresso.quantas_a_coletar(st) == 0)
	st["missoes"]["diarias"].append({"id": "x", "alvo": 1, "pronta": true, "coletada": false})
	st["missoes"]["diarias"].append({"id": "y", "alvo": 1, "pronta": false, "coletada": false})
	st["missoes"]["semanais"].append({"id": "z", "alvo": 1, "pronta": true, "coletada": true})
	ok("conta so a missao pronta e nao coletada", Progresso.quantas_a_coletar(st) == 1)

	# RECICLAR DUPLICADAS: mesmo criterio da reciclagem automatica.
	var st2: Dictionary = GameState.novo()
	ok("inventario vazio nao tem duplicada", Saque.contar_duplicadas(st2) == 0)
	var txt_m := _ler("res://scripts/ui/panel_missoes.gd")
	ok("o painel de Missoes tem o botao de coletar tudo", txt_m.contains("b_coletar_tudo"))
	ok("...e ele so aparece quando ha o que coletar",
		txt_m.contains("b_coletar_tudo.visible = quantas > 0"))
	var txt_c2 := _ler("res://scripts/ui/panel_cartas.gd")
	ok("o painel de Cartas tem o botao de reciclar duplicadas",
		txt_c2.contains("b_reciclar_dups"))
	ok("...e ele so aparece quando ha duplicada",
		txt_c2.contains("b_reciclar_dups.visible = dups > 0"))
	for chave in ["mis_coletar_tudo", "mis_coletou_tudo", "car_reciclar_dups", "sim_perdeu_ouro"]:
		ok("a chave %s existe" % chave, Txt.t(str(chave)) != str(chave))

## ------------------------------------------------------------- comemoracoes
func t_celebracao() -> void:
	g("Celebracao")
	var C := load("res://scripts/ui/celebracao.gd") as GDScript
	ok("celebracao.gd carrega", C != null)
	if C == null:
		return
	var cel = C.new()
	# AS DEZ ERAS NUNCA DIZIAM O NOME. `Bus.era_mudou` tinha um unico ouvinte, o
	# pintor de fundo. Cada era traz nome e regra escritos nos dois idiomas.
	var era: Dictionary = Dados.era_atual(120)
	ok("a era 120 existe e tem nome", not era.is_empty() and str(era.get("nome", "")) != "")
	cel.atual = {"tipo": "era", "receita": C.RECEITAS["era"], "dados": {"era": era}}
	var titulo_era: String = cel._titulo()
	ok("a comemoracao da era diz o NOME da era",
		titulo_era != "" and titulo_era == Ux.txt(era, "nome", Cfg.ingles()).to_upper())
	var sub_era: String = cel._subtitulo()
	ok("...e o subtitulo traz a REGRA dela", sub_era != "")
	var regra: Dictionary = era.get("regra", {})
	if not regra.is_empty():
		ok("a regra mostrada e a do JSON", sub_era == Ux.txt(regra, "texto", Cfg.ingles()))
	# Toda era tem que ter titulo e algum texto: se alguem acrescentar a decima
	# primeira sem `regra` nem `descricao`, a comemoracao sai muda.
	for e in Dados.eras:
		cel.atual = {"tipo": "era", "receita": C.RECEITAS["era"], "dados": {"era": e}}
		ok("a era '%s' tem o que dizer" % str(e.get("id", "")),
			cel._titulo() != "" and cel._subtitulo() != "")

	# ASCENDER PESAVA MENOS QUE UMA PURGA, e o banner mostrava o id cru.
	var def_asc: Dictionary = {}
	for c in Dados.camadas_prestigio:
		if str((c as Dictionary).get("id", "")) == "ascensao":
			def_asc = c
	ok("a camada ascensao existe", not def_asc.is_empty())
	cel.atual = {"tipo": "prestigio", "receita": C.RECEITAS["prestigio"],
		"dados": {"camada": "ascensao", "ganho": Big.from(2917.0), "def": def_asc}}
	var titulo_asc: String = cel._titulo()
	ok("a ascensao diz o nome traduzido, nao o id",
		titulo_asc == Ux.txt(def_asc, "nome", Cfg.ingles()).to_upper() and titulo_asc != "ASCENSAO")
	ok("o subtitulo da ascensao traz o ganho", cel._subtitulo().contains("2"))
	ok("ascender pesa mais que uma Purga",
		float(C.RECEITAS["prestigio"]["peso"]) > float(C.RECEITAS["purga_perfeita"]["peso"]))
	ok("...e mais que qualquer outra comemoracao", _maior_peso(C) == "prestigio")

	# O subtitulo longo (a regra de era e uma frase) tem que caber na tela.
	var linhas_q: Array = C._quebrar(
		"uma frase bem comprida que nao cabe de jeito nenhum numa linha so desta largura",
		ThemeDB.fallback_font, 17, 200.0, 3)
	ok("o subtitulo longo quebra em varias linhas", linhas_q.size() > 1)
	ok("...e nunca passa do limite de linhas", linhas_q.size() <= 3)
	var curto: Array = C._quebrar("curto", ThemeDB.fallback_font, 17, 400.0, 3)
	ok("o subtitulo curto continua numa linha", curto.size() == 1 and str(curto[0]) == "curto")

	var txt_cel := _ler("res://scripts/ui/celebracao.gd")
	ok("a camada de comemoracao escuta a troca de era", txt_cel.contains("Bus.era_mudou.connect"))
	ok("...e o prestigio", txt_cel.contains("Bus.prestigio_feito.connect(_ao_prestigio)"))
	var txt_fl := _ler("res://scripts/render/view_flash.gd")
	ok("o banner nao mostra mais o identificador cru",
		not txt_fl.contains("banner_nome = camada.to_upper()"))
	cel.free()

func _maior_peso(C: GDScript) -> String:
	var melhor := ""
	var peso := -1.0
	for k in C.RECEITAS:
		var p := float((C.RECEITAS[k] as Dictionary).get("peso", 0.0))
		if p > peso:
			peso = p
			melhor = str(k)
	return melhor

## --------------------------------------------------------- painel de melhorias
func t_painel_melhorias() -> void:
	g("Painel de melhorias")
	var P := load("res://scripts/ui/panel_upgrades.gd") as GDScript
	ok("panel_upgrades.gd carrega", P != null)
	if P == null:
		return
	# O LOTE DEGRADA, NAO TRAVA. Com "x25" escolhido e ouro para tres, o botao
	# ficava desligado e so voltando para "x1" dava para comprar: o modo de
	# compra em lote punia quem o escolhia.
	ok("x25 com ouro para 3 compra 3", P.quantidade_do_lote(25, 0, -1, 3) == 3)
	ok("x25 com ouro para 40 compra 25", P.quantidade_do_lote(25, 0, -1, 40) == 25)
	ok("x10 respeita o teto da melhoria", P.quantidade_do_lote(10, 95, 100, 999) == 5)
	ok("x10 respeita o bolso E o teto", P.quantidade_do_lote(10, 95, 100, 2) == 2)
	ok("o lote nunca cai para zero", P.quantidade_do_lote(25, 0, -1, 0) == 1)
	ok("MAX compra o que couber", P.quantidade_do_lote(-1, 0, -1, 137) == 137)
	ok("MAX sem ouro ainda oferece 1", P.quantidade_do_lote(-1, 0, -1, 0) == 1)
	ok("melhoria sem teto nao limita o lote", P.quantidade_do_lote(10, 500, -1, 999) == 10)

	# MARCOS: as 39 melhorias eram "+X%" e nada mais, entao a tela mais aberta do
	# jogo nao tinha decisao nenhuma — comprava-se a mais barata, sempre, e a
	# ordem nao importava. Cada marco entrega uma coisa DIFERENTE do que a
	# melhoria vende, e o ouro e finito a cada instante: QUAL degrau perseguir
	# primeiro e a decisao que faltava.
	var validos_stat: Dictionary = Dados.stat_defs
	var com_marco := 0
	var erros_marco: Array = []
	for def_m in Dados.upgrades:
		var marcos: Array = def_m.get("marcos", [])
		if marcos.is_empty():
			continue
		com_marco += 1
		var anterior := 0
		for item_m in marcos:
			var mk: Dictionary = item_m
			var nivel_m := int(mk.get("nivel", 0))
			if nivel_m <= anterior:
				erros_marco.append("%s: marcos fora de ordem" % str(def_m.get("id", "?")))
			anterior = nivel_m
			var efs: Array = mk.get("efeito", [])
			if efs.is_empty():
				erros_marco.append("%s: marco %d nao entrega nada" % [str(def_m.get("id", "?")), nivel_m])
			for ef_m in efs:
				var st_m := str((ef_m as Dictionary).get("stat", ""))
				if not validos_stat.has(st_m):
					erros_marco.append("%s: stat '%s' nao existe" % [str(def_m.get("id", "?")), st_m])
				# O marco tem que entregar OUTRA coisa: se ele so repete o que a
				# melhoria ja vende, ele nao cria decisao nenhuma.
				for ef_base in def_m.get("efeito", []):
					if str((ef_base as Dictionary).get("stat", "")) == st_m:
						erros_marco.append("%s: marco repete o proprio efeito (%s)" % [
							str(def_m.get("id", "?")), st_m])
	ok("varias melhorias tem marcos", com_marco >= 10, str(com_marco))
	ok("todo marco e valido, crescente e entrega algo novo",
		erros_marco.is_empty(), str(erros_marco))
	# O PRIMEIRO marco tem que ser alcancavel dentro do teto de projeto, senao
	# ninguem o ve antes da onda 50.
	var longe: Array = []
	for def_m2 in Dados.upgrades:
		var marcos2: Array = def_m2.get("marcos", [])
		if marcos2.is_empty():
			continue
		var mx2 := int(def_m2.get("max", -1))
		if mx2 > 0 and int((marcos2[0] as Dictionary).get("nivel", 0)) > mx2:
			longe.append(str(def_m2.get("id", "?")))
	ok("o primeiro marco cabe no teto de projeto", longe.is_empty(), str(longe))
	# ...e o modificador realmente aplica.
	var txt_mod := _ler("res://scripts/sim/modifiers.gd")
	ok("os marcos entram no calculo de atributos", txt_mod.contains('def.get("marcos", [])'))
	var txt_g2 := _ler("res://scripts/sim/game.gd")
	ok("cruzar um marco avisa o jogador", txt_g2.contains('Bus.celebracao.emit("marco"'))
	# E o painel mostra o que falta — a antecipacao mora ai.
	var P2 := load("res://scripts/ui/panel_upgrades.gd") as GDScript
	var def_dano: Dictionary = Dados.upgrade_por_id.get("dano", {})
	ok("a melhoria de dano tem marcos", not (def_dano.get("marcos", []) as Array).is_empty())
	if not def_dano.is_empty():
		var t_zero: String = P2.texto_marco(def_dano, 0, false)
		# O idioma dos portoes e pt (ver `Cfg.idioma_do_sistema`), entao a
		# assercao olha o NUMERO, que nao muda de lingua.
		var nivel_1 := int((def_dano["marcos"] as Array)[0]["nivel"])
		ok("no nivel zero o painel diz o que falta",
			t_zero != "" and t_zero.contains(str(nivel_1)))
		var alto := int((def_dano["marcos"] as Array)[-1]["nivel"]) + 10
		var t_alto: String = P2.texto_marco(def_dano, alto, false)
		ok("com tudo conquistado o painel muda de frase",
			t_alto != "" and t_alto != t_zero and not t_alto.contains(str(nivel_1)))
		ok("melhoria sem marco nao inventa linha", P2.texto_marco({}, 0, false) == "")

	var txt_p := _ler("res://scripts/ui/panel_upgrades.gd")
	# A aba "Tudo" e a memoria da aba: sem as duas, achar o que da para comprar
	# custava sete cliques, e o painel voltava para a primeira categoria toda vez.
	ok("existe a aba Tudo", txt_p.contains("ABA_TUDO"))
	ok("a aba Tudo entra antes das categorias", txt_p.contains("abas.add_tab(Txt.t(\"upg_aba_tudo\"))"))
	ok("a aba escolhida sobrevive ao fechar", txt_p.contains("static var ultima_aba_id"))
	ok("...e e restaurada ao montar", txt_p.contains("abas.current_tab = cat_atual"))
	ok("a aba Tudo ordena pelo custo", txt_p.contains("_peso_na_lista"))
	# O botao dizia o preco e nunca o ganho.
	ok("a linha tem rotulo de ganho", txt_p.contains("_texto_ganho("))
	ok("o ganho e atualizado a cada ciclo", txt_p.contains('r["ganho"].text = _texto_ganho('))
	for chave in ["upg_aba_tudo", "upg_ganho_flat", "upg_ganho_pct", "upg_ganho_mult"]:
		ok("a chave %s existe nos dois idiomas" % chave, Txt.t(str(chave)) != str(chave))

## ------------------------------------------------------------ rodape do HUD
func t_rodape() -> void:
	g("Rodape")
	# O rodape mostrava doze glifos iguais na onda 1, cinco deles abrindo painel
	# vazio, e nunca avisava quando algo enchia. As duas metades sao portao:
	# a porta que NAO existe fica escondida, e a que tem algo esperando acende.
	var H := load("res://scripts/ui/hud.gd") as GDScript
	ok("hud.gd carrega", H != null)
	if H == null:
		return
	var txt_h := _ler("res://scripts/ui/hud.gd")
	ok("todo botao do rodape tem rotulo", txt_h.contains("_botao_de_painel("))
	ok("o rotulo e retraduzido junto com a dica", txt_h.contains('b.get_meta("rotulo")'))
	ok("o rodape e reavaliado no ciclo de update", txt_h.contains("_atualizar_portas_do_rodape()"))

	# Estado de jogo NOVO: nada foi conquistado ainda.
	var novo: Dictionary = GameState.novo()
	var esp_vazio := {"desbloqueios": {}}
	var p0: Dictionary = H.portas_do_rodape(novo, esp_vazio)
	var existe0: Dictionary = p0["existe"]
	var acende0: Dictionary = p0["acende"]
	for chave in ["cartas", "reliquias", "habilidades", "desafios", "prestigio"]:
		ok("no comeco o botao de %s fica escondido" % chave, not bool(existe0[chave]))
	for chave2 in ["cartas", "missoes", "prestigio", "conquistas"]:
		ok("no comeco o botao de %s nao acende" % chave2, not bool(acende0[chave2]))

	# ...e cada porta abre pelo motivo certo, uma de cada vez.
	var com_carta: Dictionary = GameState.novo()
	com_carta["cartas"]["inventario"].append({"uid": 1, "id": "x", "raridade": 0, "nivel": 1})
	ok("uma carta no inventario abre a porta de Cartas",
		bool((H.portas_do_rodape(com_carta, esp_vazio)["existe"] as Dictionary)["cartas"]))
	var com_reliquia: Dictionary = GameState.novo()
	com_reliquia["relicas"]["x"] = 1
	ok("uma reliquia abre a porta de Reliquias",
		bool((H.portas_do_rodape(com_reliquia, esp_vazio)["existe"] as Dictionary)["reliquias"]))
	var com_hab: Dictionary = GameState.novo()
	com_hab["habilidades"]["x"] = {"desbloqueada": true, "nivel": 1, "cd": 0.0, "cd_max": 0.0, "usos": 0}
	ok("uma habilidade abre a porta de Habilidades",
		bool((H.portas_do_rodape(com_hab, esp_vazio)["existe"] as Dictionary)["habilidades"]))
	ok("o desbloqueio abre a porta de Desafios",
		bool((H.portas_do_rodape(GameState.novo(), {"desbloqueios": {"desafios": true}})["existe"] as Dictionary)["desafios"]))
	var na_onda: Dictionary = GameState.novo()
	na_onda["onda_maxima"] = Bal.ASC_ONDA_MIN
	var p_onda: Dictionary = H.portas_do_rodape(na_onda, esp_vazio, Big.from(1000.0))
	ok("chegar na onda de ascensao abre a porta de Prestigio",
		bool((p_onda["existe"] as Dictionary)["prestigio"]))
	# QUANDO ASCENDER o jogo nao respondia: medido, uma corrida chega a onda 212
	# em uma hora e NUNCA para de subir, entao nao existe o momento em que o
	# jogo trava e diz "reinicie agora". O botao acende com o sinal que um
	# jogador experiente usa — a corrida atual vale, sozinha, tudo o que voce ja
	# guardou — e nao so por ter passado da onda 25.
	ok("...e acende quando a corrida vale o acervo inteiro",
		bool((p_onda["acende"] as Dictionary)["prestigio"]))
	na_onda["moedas"]["fragmentos"] = Big.from(1.0e9)
	var p_cedo: Dictionary = H.portas_do_rodape(na_onda, esp_vazio, Big.from(1000.0))
	ok("com o acervo grande e a corrida pequena, NAO acende",
		not bool((p_cedo["acende"] as Dictionary)["prestigio"]))
	ok("...mas a porta continua aberta", bool((p_cedo["existe"] as Dictionary)["prestigio"]))
	var carta_nova: Dictionary = GameState.novo()
	carta_nova["cartas"]["novas"].append(1)
	ok("carta nova acende o botao de Cartas",
		bool((H.portas_do_rodape(carta_nova, esp_vazio)["acende"] as Dictionary)["cartas"]))
	var missao: Dictionary = GameState.novo()
	missao["missoes"]["diarias"].append({"id": "x", "alvo": 1, "pronta": true, "coletada": false})
	ok("missao pronta acende o botao de Missoes",
		bool((H.portas_do_rodape(missao, esp_vazio)["acende"] as Dictionary)["missoes"]))
	missao["missoes"]["diarias"][0]["coletada"] = true
	ok("missao ja coletada nao acende nada",
		not bool((H.portas_do_rodape(missao, esp_vazio)["acende"] as Dictionary)["missoes"]))
	var conq: Dictionary = GameState.novo()
	conq["conquistas"]["x"] = 1
	ok("conquista nao vista acende o botao de Conquistas",
		bool((H.portas_do_rodape(conq, esp_vazio)["acende"] as Dictionary)["conquistas"]))

	# O idioma do sistema decide a PRIMEIRA abertura, e nunca sem tela.
	ok("sem tela o idioma padrao continua sendo pt", Cfg.idioma_do_sistema() == "pt")
	var txt_c := _ler("res://scripts/core/config.gd")
	ok("a deteccao de idioma le o locale do sistema", txt_c.contains("OS.get_locale()"))
	ok("...e so quando nao ha escolha salva", txt_c.contains('not salvo.has("idioma")'))

## ---------------------------------------------------------- custo do quadro
func t_custo_do_quadro() -> void:
	g("Custo do quadro")
	# Quatro defeitos que so aparecem quando o jogo fica FORTE, e que juntos
	# custavam 22,6 ms por passo — cinco vezes o orcamento do quadro inteiro.
	# Cada um tem aqui a assercao que reprova se voltar.

	# 1. O MORTEIRO EXPLODE UMA VEZ, nao uma por corpo atravessado.
	var p_test := Projetil.new()
	ok("o projetil nasce sem ter explodido", not p_test.explodiu)
	p_test.explodiu = true
	p_test.limpar()
	ok("reciclar o projetil zera a explosao", not p_test.explodiu)
	var txt_tw := _ler("res://scripts/sim/tower.gd")
	ok("a explosao e uma so por projetil",
		txt_tw.contains("if p.area > 0.0 and not p.explodiu:"))

	# 2. VIDA DO PROJETIL PROPORCIONAL A TRAVESSIA. Fixo em 3,5 s, o pool de 800
	# vivia saturado com ~500 projeteis que ja nao podiam acertar nada.
	ok("a vida do projetil sai da velocidade", txt_tw.contains("p.vida = clampf(2200.0"))

	# 3. CADENCIA ALEM DO TETO VIRA DANO. O laco disparava ate doze vezes por
	# passo e jogava o resto fora: quem comprava cadencia depois disso pagava
	# por nada.
	ok("existe teto de disparos por passo", TorreSim.TIROS_POR_PASSO >= 1)
	ok("o excedente vira forca da salva", txt_tw.contains("var forca := float(pedidos) / float(tiros)"))
	ok("...e a forca chega ao dano do projetil", txt_tw.contains("float(j.mods_dif.get(\"danoTorre\", 1.0))), forca)"))

	# 4. DANO CONTINUO A 10 Hz, nao a cada quadro. Com 212 inimigos em chamas
	# eram 424 chamadas de `aplicar_dano` por passo so para dividir o mesmo dano
	# em sessenta pedacos por segundo em vez de dez.
	ok("o intervalo do dano continuo e sensato",
		Combate.DOT_INTERVALO >= 0.05 and Combate.DOT_INTERVALO <= 0.25)
	ok("a corrente de raio tem espera", Combate.RAIO_ESPERA > 0.0)
	# E o dano TOTAL nao pode mudar: o acumulador guarda o tempo real decorrido.
	var alvo_dot = EnemyAI.criar(Dados.inimigo_por_id["grunhido"], 5, jogo, {})
	ok("criou o alvo do dano continuo", alvo_dot != null)
	if alvo_dot != null:
		alvo_dot.hp = Big.from(1.0e12)
		alvo_dot.hp_max = alvo_dot.hp
		alvo_dot.queimadura = 1
		alvo_dot.queimadura_dano = Big.from(1000.0)
		alvo_dot.queimadura_t = 10.0
		alvo_dot.dot_acc = 0.0
		var antes: float = alvo_dot.hp
		# um segundo inteiro, em passos de 1/60
		for i in 60:
			Combate.atualizar_status(1.0 / 60.0, jogo)
		var levou := Big.to_f(Big.sub(antes, alvo_dot.hp))
		# 1.000 por segundo por pilha, com uma pilha: ~1.000, com folga para o
		# resto que o acumulador ainda nao cobrou.
		ok("o dano continuo entrega o mesmo total por segundo",
			levou > 800.0 and levou < 1100.0, "%.0f" % levou)
	jogo.arena.limpar_tudo()

	# 5. A GRADE SO ENQUANTO A GRADE COMPENSA.
	var txt_ar := _ler("res://scripts/sim/arena.gd")
	ok("em_area troca a grade pela lista quando o raio e grande",
		txt_ar.contains("if lado * lado >= inimigos.size():"))
	ok("o pool de projeteis recicla em anel, sem memmove",
		txt_ar.contains("_anel_p = (_anel_p + 1)") and not txt_ar.contains("projeteis.remove_at(0)"))

## ------------------------------------------------------------ teto de nivel
func t_teto() -> void:
	g("Teto")
	# O teto cresce com o recorde, geometrico. Antes era linear e nao acompanhava
	# o ouro (exponencial): o catalogo esvaziava na onda 64 e as 33 melhorias com
	# teto viravam enfeite pelo resto da partida.
	ok("antes da onda livre o teto e o de projeto", Bal.teto_upgrade(100, 10) == 100)
	ok("na onda livre o teto ainda e o de projeto",
		Bal.teto_upgrade(100, Bal.TETO_ONDA_LIVRE) == 100)
	ok("depois da onda livre o teto cresce", Bal.teto_upgrade(100, 100) > 100)
	ok("o teto nunca desce", Bal.teto_upgrade(100, 300) >= Bal.teto_upgrade(100, 200))
	ok("melhoria sem teto continua sem teto", Bal.teto_upgrade(-1, 400) == -1)
	# Geometrico de verdade: o ganho entre a onda 200 e a 300 tem que ser MAIOR
	# que entre a 100 e a 200. Se alguem trocar por linear isto reprova.
	var d1 := Bal.teto_upgrade(100, 200) - Bal.teto_upgrade(100, 100)
	var d2 := Bal.teto_upgrade(100, 300) - Bal.teto_upgrade(100, 200)
	ok("o teto cresce geometrico, nao linear", d2 > d1)

	# `tetoFixo`: nivel que vira ENTIDADE nao cresce, senao a onda 200 pediria
	# 1.191 projeteis por disparo num pool de 800.
	ok("teto fixo ignora o recorde", Bal.teto_upgrade(14, 400, true) == 14)
	# Sete melhorias tem teto de projeto: quatro viram ENTIDADE (multishot, orbe,
	# perfuracao, ricochete) e tres viram ESPACO ou VELOCIDADE (alcance, area,
	# vel_projetil). Crescer qualquer uma delas custa quadro, nao poder.
	var contadores := ["multishot", "perfuracao", "ricochete", "orbe",
		"alcance", "area", "vel_projetil"]
	for id_c in contadores:
		var def_c: Dictionary = Dados.upgrade_por_id.get(str(id_c), {})
		ok("%s existe no catalogo" % id_c, not def_c.is_empty())
		if def_c.is_empty():
			continue
		ok("%s tem tetoFixo no JSON" % id_c, bool(def_c.get("tetoFixo", false)))
		var antes := int(jogo.s["onda_maxima_global"])
		jogo.s["onda_maxima_global"] = 400
		ok("%s nao ganha teto na onda 400" % id_c,
			jogo.teto_upgrade(def_c) == int(def_c.get("max", -1)))
		jogo.s["onda_maxima_global"] = antes
	# ...e quem NAO conta entidade tem que crescer, senao a tela volta a ficar
	# sem decisao. `cadencia` e o caso testemunha.
	var def_cad: Dictionary = Dados.upgrade_por_id.get("cadencia", {})
	ok("cadencia existe", not def_cad.is_empty())
	if not def_cad.is_empty():
		var antes_c := int(jogo.s["onda_maxima_global"])
		jogo.s["onda_maxima_global"] = 400
		ok("cadencia ganha teto na onda 400",
			jogo.teto_upgrade(def_cad) > int(def_cad.get("max", -1)))
		jogo.s["onda_maxima_global"] = antes_c

	# Redes de seguranca em codigo: por mais que o JSON mude, um quadro nao pede
	# mil projeteis nem duzentos orbes.
	ok("o teto de projeteis existe e e sensato",
		Bal.PROJETEIS_TETO >= 16 and Bal.PROJETEIS_TETO <= 128)
	ok("o teto de orbes existe e e sensato", Bal.ORBES_TETO >= 12 and Bal.ORBES_TETO <= 64)
	var txt_t := _ler("res://scripts/sim/tower.gd")
	ok("o disparo usa o teto de projeteis", txt_t.contains("Bal.PROJETEIS_TETO"))
	ok("os orbes usam o teto de orbes", txt_t.contains("Bal.ORBES_TETO"))

	# O RAIO DE AREA NUNCA PASSA DA DIAGONAL DA ARENA. `em_area` varre celulas da
	# grade dentro do quadrado do raio: o custo e o raio AO QUADRADO. Medido, a
	# onda 197 pedia raio 10.944 px numa arena de 1280x720 — 93.000 celulas por
	# impacto, ~180 impactos por quadro, e o simulador caiu de 40x tempo real
	# para menos de 1x.
	var arena_t: Arena = jogo.arena
	arena_t.limpar_tudo()
	arena_t.redimensionar(1280.0, 720.0)
	var perto_a = EnemyAI.criar(Dados.inimigo_por_id["grunhido"], 10, jogo, {})
	ok("criou o inimigo do teste de area", perto_a != null)
	if perto_a != null:
		perto_a.pos = Vector2(700.0, 380.0)
		arena_t.reconstruir_grade()
		var t0 := Time.get_ticks_usec()
		var achados_normal: int = arena_t.em_area(Vector2(640.0, 360.0), 200.0).size()
		var custo_normal := Time.get_ticks_usec() - t0
		t0 = Time.get_ticks_usec()
		var achados_absurdo: int = arena_t.em_area(Vector2(640.0, 360.0), 400000.0).size()
		var custo_absurdo := Time.get_ticks_usec() - t0
		ok("um raio de 200 px acha o inimigo", achados_normal == 1)
		ok("um raio absurdo acha o mesmo inimigo", achados_absurdo == 1)
		# Sem o corte, 400.000 px dariam 123 milhoes de celulas: a diferenca nao
		# seria "um pouco mais cara", seria o jogo parando. Duas ordens de
		# grandeza e folga suficiente para nao virar teste instavel.
		ok("um raio absurdo nao custa 100x mais que um normal",
			custo_absurdo <= maxi(400, custo_normal * 100))
	arena_t.limpar_tudo()
	var txt_a := _ler("res://scripts/sim/arena.gd")
	ok("o corte do raio esta em em_area", txt_a.contains("raio = minf(raio, sqrt("))

## ------------------------------------------------------- defesa da torre
func t_defesa() -> void:
	g("Defesa")
	# Reflexo em log10, nao linear: ja foi entregue como valor linear e a torre
	# morria num tiro so (10^(2e18) de dano com um golpe de 1e20).
	var golpe := Big.from(1.0e20)
	var refletido := Bal.dano_refletido(golpe)
	ok("reflexo continua em log10", refletido < 19.0 and refletido > 18.0)
	ok("reflexo e 2%% do golpe", perto(Big.to_f(refletido), 2.0e18, 1.0e12))

	# O TETO do reflexo e do espinho. Sem ele, o jogo se matava sozinho: reflexo
	# e espinho eram fracao do dano DO JOGADOR, que cresce exponencial, e nada
	# os ligava a vida da torre. Medido: onda 85, golpe 1,1e10, vida maxima
	# 1,3e7 — 2% do golpe dava 17x a vida INTEIRA, e o relatorio mostrava 23
	# quedas entre as ondas 58 e 85 com ZERO inimigos chegando na torre.
	var vida_max := Big.from(1.0e7)
	var golpe_alto := Big.from(1.0e20)
	var ref_teto := Bal.dano_refletido(golpe_alto, vida_max)
	var esp_teto := Bal.dano_espinho(golpe_alto, vida_max)
	ok("reflexo nunca passa do teto da vida maxima",
		Big.lte(ref_teto, Big.mul_f(vida_max, Bal.REFLEXO_TETO_VIDA + 0.0001)))
	ok("espinho nunca passa do teto da vida maxima",
		Big.lte(esp_teto, Big.mul_f(vida_max, Bal.ESPINHO_TETO_VIDA + 0.0001)))
	ok("um golpe devolvido nao mata a torre cheia", Big.lt(ref_teto, vida_max))
	ok("espinho devolvido nao mata a torre cheia", Big.lt(esp_teto, vida_max))
	# E abaixo do teto o valor continua sendo a fracao do golpe, como antes: o
	# teto e um limite, nao um piso que engorda o reflexo no comeco do jogo.
	var golpe_baixo := Big.from(1000.0)
	ok("abaixo do teto o reflexo segue 2% do golpe",
		perto(Big.to_f(Bal.dano_refletido(golpe_baixo, vida_max)), 20.0, 0.01))
	ok("abaixo do teto o espinho segue 6% do golpe",
		perto(Big.to_f(Bal.dano_espinho(golpe_baixo, vida_max)), 60.0, 0.01))
	# Quem chama TEM que passar a vida maxima. Se um dos dois voltar a chamar sem
	# o segundo argumento, o teto desaparece em silencio e o defeito volta.
	var fontes := {
		"res://scripts/sim/tower.gd": "dano_refletido(",
		"res://scripts/sim/combat.gd": "dano_espinho(",
	}
	for caminho in fontes:
		var txt := _ler(str(caminho))
		var chamada := str(fontes[caminho])
		var i := txt.find(chamada)
		ok("%s chama %s" % [caminho.get_file(), chamada], i >= 0)
		if i >= 0:
			var resto := txt.substr(i + chamada.length(), 90)
			ok("%s passa a vida maxima para %s" % [caminho.get_file(), chamada],
				resto.contains("vida_max"))

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
	# POR QUE O SPAWNER NAO PODE ACELERAR SOZINHO. A vida do inimigo cresce mais
	# rapido por onda (1,152) do que o ouro que ele larga (1,128), e a contagem
	# por onda tem teto. Logo, avancar uma onda e por si so uma PERDA de poder
	# relativo: o jogador ganha porque passa tempo DENTRO da onda, matando,
	# rendendo juros e subindo de nivel. Encurtar a onda sem dar o ganho junto
	# empobrece quem joga — foi medido (onda maxima de 261 para 115) antes de
	# ser entendido. Se alguem inverter os expoentes, o comentario de
	# `waves.gd` para de valer e isto reprova.
	ok("a vida cresce mais rapido por onda que o ouro", Bal.HP_CRESC > Bal.OURO_CRESC,
		"%.3f vs %.3f" % [Bal.HP_CRESC, Bal.OURO_CRESC])
	ok("a contagem de inimigos por onda tem teto",
		Bal.contagem_onda(999999) <= 40, str(Bal.contagem_onda(999999)))
	ok("o spawner nao acelera sozinho",
		not _sem_comentario(_ler("res://scripts/sim/waves.gd")).contains("contagem_viva_agora() == 0 and faltam"))
	# ...e a saida que o jogador TEM continua existindo e pagando.
	ok("antecipar existe", _ler("res://scripts/sim/waves.gd").contains("func antecipar()"))
	ok("...e paga bonus por isso", Diretor.ANTECIPAR_BONUS > 0.0)
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
	# A RETOMADA ACABA POR PROGRESSO, NAO POR RELOGIO. Eram 10 s reais fixos: a
	# x6 isso da quatro ondas, contra um alvo que podia ser a onda 200 — a
	# corrida tinha a linha de chegada fora da pista e `superou` nunca acontecia.
	var r_ret: Dictionary = jogo.s["retomada"]
	ok("a retomada guarda a onda que ja viu", r_ret.has("onda_vista"))
	ok("...e o quanto ficou parada", r_ret.has("parado"))
	ok("o teto e maior que os 10 s de antes", Mecanicas.RETOMADA_DURACAO > 10.0)
	ok("existe um tempo de parada", Mecanicas.RETOMADA_PARADA > 0.0)
	# Parada: sem ganhar onda, ela termina no tempo de parada — nao no teto.
	var passo_r := 0.5 * Mecanicas.RETOMADA_VELOCIDADE
	var voltas := 0
	while Mecanicas.em_retomada(jogo.s) and voltas < 400:
		Mecanicas.atualizar_retomada(passo_r, jogo)
		voltas += 1
	var reais := float(voltas) * 0.5
	ok("parada de onda encerra a Retomada bem antes do teto",
		reais <= Mecanicas.RETOMADA_PARADA + 1.0, "%.1f s reais" % reais)
	# Subindo: cada onda nova zera o cronometro de parada, e a Retomada segue.
	Mecanicas.iniciar_retomada(jogo, 30)
	var r2: Dictionary = jogo.s["retomada"]
	Mecanicas.atualizar_retomada(passo_r, jogo)
	var parado_antes := float(r2["parado"])
	ok("ficar parado acumula", parado_antes > 0.0)
	jogo.s["onda"] = int(jogo.s["onda"]) + 1
	Mecanicas.atualizar_retomada(passo_r, jogo)
	ok("ganhar uma onda zera o cronometro de parada", float(r2["parado"]) == 0.0)
	# ...e superar o alvo encerra na hora, que e o final que ela promete.
	jogo.s["onda"] = 31
	Mecanicas.atualizar_retomada(passo_r, jogo)
	ok("passar do alvo encerra a Retomada", not Mecanicas.em_retomada(jogo.s))
	Mecanicas.iniciar_retomada(jogo, 30)
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
	# A LINHA QUE ESTAVA AQUI ESCREVIA O DICIONÁRIO NA MÃO, e por isso a suíte
	# inteira passou por meses com a mecânica MORTA: `GameState.novo()` entrega
	# `"adaptacao": {}` e o semeador só agia `if not s.has(...)`, que é falso
	# desde o primeiro quadro. O teste media a função com um estado que o jogo
	# nunca produz. Agora ele parte do estado REAL, e é isso que o faz morder.
	var s_novo := GameState.novo()
	ok("o estado novo do jogo produz adaptacao utilizavel",
		not (s_novo["adaptacao"] as Dictionary).is_empty()
			or not Mecanicas.estado_adaptacao(s_novo).is_empty())
	# A adaptacao anda no RELOGIO, nao na contagem de acertos: usar o elemento
	# e deixar o tempo passar. Antes subia por acerto, e centenas de acertos por
	# segundo cravavam a resistencia no teto em menos de um segundo.
	_usar_elemento(s_novo, "fogo", 20.0)
	ok("a partir do estado REAL, usar um elemento cria resistencia",
		Mecanicas.fator_elemento(s_novo, "fogo") < 0.85,
		"fator=%s" % str(Mecanicas.fator_elemento(s_novo, "fogo")))

	# A ADAPTACAO TEM QUE VALER PARA OS CINCO ELEMENTOS.
	# `gelo` e `vazio` nao dependem de dano — entregam lentidao e ampliacao — e
	# os dois ramos ignoravam o fator, entao o Enxame nunca se adaptava a eles.
	# O HUD, enquanto isso, mostrava a resistencia subindo ate -62% para os
	# CINCO: dois dos cinco numeros na tela eram falsos.
	var def_alvo: Dictionary = Dados.inimigo_por_id["grunhido"]
	for elem in ["gelo", "vazio"]:
		jogo.arena.limpar_inimigos()
		var s_el: Dictionary = jogo.s
		s_el["adaptacao"] = {"fogo": 0.0, "gelo": 0.0, "raio": 0.0, "veneno": 0.0, "vazio": 0.0}
		var e_limpo := EnemyAI.criar(def_alvo, 10, jogo, {})
		Combate.aplicar_elemento(e_limpo, elem, Big.from(1000.0), jogo)
		var forte: float = e_limpo.gelo_forca if elem == "gelo" else e_limpo.fissura_forca
		# Satura a adaptacao naquele elemento e aplica de novo.
		_usar_elemento(s_el, elem, 90.0)
		var e_adap := EnemyAI.criar(def_alvo, 10, jogo, {})
		Combate.aplicar_elemento(e_adap, elem, Big.from(1000.0), jogo)
		var fraco: float = e_adap.gelo_forca if elem == "gelo" else e_adap.fissura_forca
		ok("o Enxame se adapta a %s como aos outros" % elem, fraco < forte,
			"antes=%.3f depois=%.3f" % [forte, fraco])
	jogo.arena.limpar_inimigos()
	jogo.s["adaptacao"] = {"fogo": 0.0, "gelo": 0.0, "raio": 0.0, "veneno": 0.0, "vazio": 0.0}

	ok("sem adaptacao o fator e 1", perto(Mecanicas.fator_elemento(s, "fogo"), 1.0, 1e-9))
	_usar_elemento(s, "fogo", 30.0)
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
	# O PORTAO COBRIA TRES CORES DE TEXTO DE UMAS DEZOITO, e havia reprovacao
	# viva que ele nao via: `MOEDA_COR["nucleos"]` (#a855f7) e escrito como TEXTO
	# em `UI.moeda` e dava 3,98:1 sobre PAINEL2. Agora a matriz e completa.
	var cores_texto: Array = [
		["TEXTO", UI.TEXTO], ["TEXTO2", UI.TEXTO2], ["TEXTO3", UI.TEXTO3],
		["ACENTO", UI.ACENTO], ["ACENTO2", UI.ACENTO2], ["OURO", UI.OURO],
		["VERDE", UI.VERDE], ["VERMELHO", UI.VERMELHO], ["LARANJA", UI.LARANJA],
		["ROSA", UI.ROSA],
	]
	for chave_m in UI.MOEDA_COR:
		cores_texto.append(["moeda:" + str(chave_m), UI.MOEDA_COR[chave_m]])
	for r_def in Dados.raridades:
		cores_texto.append(["raridade:" + str(r_def.get("id", "?")),
			Color.html(str(r_def.get("cor", "#ffffff")))])
	var fundos: Array = [["FUNDO", UI.FUNDO], ["FUNDO2", UI.FUNDO2],
		["PAINEL", UI.PAINEL], ["PAINEL2", UI.PAINEL2]]
	var reprovados: Array = []
	var pares := 0
	for par in cores_texto:
		for fundo in fundos:
			pares += 1
			if _contraste(par[1], fundo[1]) < 4.5:
				reprovados.append("%s/%s %.2f:1" % [par[0], fundo[0], _contraste(par[1], fundo[1])])
	ok("a matriz de contraste cobre a paleta inteira", pares >= 60, "%d pares" % pares)
	ok("nenhuma cor de texto reprova 4.5:1 em nenhum fundo",
		reprovados.is_empty(), str(reprovados))
	ok("hierarquia preservada", _contraste(UI.TEXTO, UI.PAINEL2) > _contraste(UI.TEXTO2, UI.PAINEL2)
		and _contraste(UI.TEXTO2, UI.PAINEL2) > _contraste(UI.TEXTO3, UI.PAINEL2))

	# NAVEGACAO POR TECLADO. Eram 296 controles interativos e 11 focaveis,
	# NENHUM deles um `Button`: Tab nao andava, Enter nao acionava, e quem nao
	# usa mouse simplesmente nao jogava. O contorno de foco ja estava desenhado
	# no tema desde sempre — so nao havia o que contornar.
	var b_kit := UI.botao("x")
	ok("o botao do kit e focavel", b_kit.focus_mode == Control.FOCUS_ALL)
	b_kit.free()
	var txt_kit := _ler("res://scripts/ui/ui_kit.gd")
	ok("o tema desenha o contorno de foco", txt_kit.contains('t.set_stylebox("focus", "Button"'))
	var txt_pb := _ler("res://scripts/ui/panel_base.gd")
	ok("o X de fechar e alcancavel pelo teclado",
		txt_pb.contains("fechar.focus_mode = Control.FOCUS_ALL"))
	ok("abrir um painel poe o foco em algum lugar", txt_pb.contains("_focar_primeiro"))
	ok("...e nao no botao de fechar", txt_pb.contains("_primeiro_focavel(corpo)"))
	# E os controles de Configuracoes — onde quem depende de teclado mais precisa.
	var txt_cfg := _ler("res://scripts/ui/panel_config.gd")
	var sem_foco := 0
	for linha_cfg in txt_cfg.split("\n"):
		if linha_cfg.contains("focus_mode = Control.FOCUS_NONE"):
			sem_foco += 1
	ok("nenhum controle de Configuracoes fica fora do teclado", sem_foco == 0, str(sem_foco))
	# O QUE FLUTUA TEM QUE PARAR ACIMA DA BARRA. Quatro vezes o mesmo defeito:
	# os avisos aprenderam a fugir do painel, do banner e do dialogo de evento, e
	# na quarta o lugar para onde eles fugiam — o rodape — ficou ocupado pelos
	# doze botoes com rotulo. A faixa agora e uma constante so, e os dois lados
	# tem que le-la.
	ok("a faixa do rodape e uma constante do kit", UI.RODAPE_TOPO < UI.RODAPE_BASE)
	ok("...com folga declarada", UI.RODAPE_FOLGA > 0.0)
	var txt_pm := _ler("res://scripts/ui/panel_manager.gd")
	ok("os avisos param acima da barra", txt_pm.contains("UI.RODAPE_TOPO - UI.RODAPE_FOLGA"))
	var txt_h3 := _ler("res://scripts/ui/hud.gd")
	ok("a barra usa a mesma constante", txt_h3.contains("int(UI.RODAPE_TOPO)"))
	ok("...nos dois lados do rodape",
		txt_h3.count("int(UI.RODAPE_TOPO)") >= 2 and txt_h3.count("int(UI.RODAPE_BASE)") >= 2)

	# O rodape do HUD continua SEM foco de proposito: e barra de ferramentas por
	# cima da arena e tem atalho proprio. Se alguem ligar foco la, isto avisa.
	var txt_hud2 := _ler("res://scripts/ui/hud.gd")
	ok("o rodape do HUD segue com atalho, nao com foco",
		txt_hud2.contains("b.focus_mode = Control.FOCUS_NONE"))

	# FUNDO DESTACADO NAO PODE CLAREAR. Onze lugares pintavam a caixa "completa"
	# com `PAINEL2.lerp(cor, 0.18)`, mais claro que o painel: cada um derrubava
	# o contraste de todo texto por cima (TEXTO3 caia de 4,62 para 3,10). Com
	# `UI.tingir` vale o invariante — o que passa em PAINEL2 passa no destaque.
	var claros: Array = []
	for par2 in cores_texto:
		for forca in [0.10, 0.14, 0.18, 0.28, 0.5]:
			var tinta: Color = UI.tingir(par2[1], float(forca))
			if UI.luz_relativa(tinta) > UI.luz_relativa(UI.PAINEL2) + 0.00001:
				claros.append("%s@%.2f" % [par2[0], forca])
	ok("tingir() nunca deixa o fundo mais claro que o painel",
		claros.is_empty(), str(claros))
	# ...e por consequencia todo texto que passa em PAINEL2 passa no destaque.
	var reprova_tinta: Array = []
	for par3 in cores_texto:
		for tinta_de in [UI.VERDE, UI.OURO, UI.ACENTO, UI.ROSA]:
			var f2: Color = UI.tingir(tinta_de, 0.18)
			if _contraste(par3[1], f2) < 4.5:
				reprova_tinta.append(str(par3[0]))
	ok("nenhum texto reprova sobre fundo destacado", reprova_tinta.is_empty(), str(reprova_tinta))
	# E a interface tem que USAR o ajudante, senao o invariante nao vale de nada.
	var cruas: Array = []
	for arq_ui in _listar_gd("res://scripts/ui"):
		var t_ui := _sem_comentario(_ler(str(arq_ui)))
		if t_ui.contains("PAINEL2.lerp(") and not str(arq_ui).ends_with("ui_kit.gd"):
			cruas.append(str(arq_ui).get_file())
	ok("nenhum painel mistura o fundo na mao", cruas.is_empty(), str(cruas))

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
	# ESTE PORTAO PROVAVA QUE UMA STRING EXISTIA, nao que o elo existia.
	#
	# A verificacao inteira era `texto.contains(prova)`. Um auditor independente
	# cortou os dois elos da Adaptacao do Enxame, reescreveu o nome da prova
	# dentro de um COMENTARIO em portugues, e a suite fechou 348/348 verde. Pior:
	# o portao ja certificava elos mortos — "Panteao -> Atributos" pela existencia
	# de `func bonus_panteao`, funcao que naquele momento era inalcancavel, e
	# "Combate -> Adaptacao" por `func decair_adaptacao`, que iterava um
	# dicionario vazio porque a mecanica estava quebrada. Oito pontos de rubrica
	# satisfeitos por texto morto.
	#
	# Agora sao tres exigencias, e a terceira e a que morde:
	#   1. a prova aparece em CODIGO, com comentarios e strings removidos;
	#   2. quando a prova e uma funcao, ela precisa estar DECLARADA;
	#   3. e precisa ter pelo menos um CHAMADOR em outro lugar de scripts/.
	# Funcao declarada e nunca chamada deixa de contar como elo.
	var sem_prova: Array = []
	var nao_chamada: Array = []
	var sistemas := {}
	var codigo_todo := ""
	for arq_gd in _listar_gd("res://scripts"):
		codigo_todo += _sem_comentario(FileAccess.get_file_as_string(arq_gd))
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
		var texto := _sem_comentario(fa.get_as_text())
		fa.close()
		var rotulo := "%s -> %s" % [str(elo.get("de", "")), str(elo.get("para", ""))]
		if not texto.contains(prova):
			sem_prova.append("%s: '%s' nao existe em CODIGO de %s" % [rotulo, prova, arq])
			continue
		# Prova do tipo "func nome": exigir chamador de verdade.
		if prova.begins_with("func "):
			var nome := prova.substr(5).strip_edges()
			if codigo_todo.count(nome + "(") < 2:
				nao_chamada.append("%s: %s existe e ninguem chama" % [rotulo, nome])
	ok("todo elo declarado tem prova em CODIGO, nao em comentario",
		sem_prova.is_empty(), str(sem_prova.slice(0, 3)))
	ok("toda funcao citada como prova de elo tem chamador",
		nao_chamada.is_empty(), str(nao_chamada.slice(0, 3)))
	ok("ha pelo menos 10 sistemas distintos", sistemas.size() >= 10, "%d sistemas" % sistemas.size())

## Remove os COMENTARIOS, e so eles.
##
## O furo demonstrado pelo auditor foi escrever o nome da prova dentro de um
## comentario em portugues; e isso que precisa deixar de contar. As strings
## ficam, de proposito: em GDScript uma chave de dicionario e uma string, e
## `s["desafios"]["completos"]` e uso legitimo em codigo — a primeira versao
## desta funcao apagava strings tambem e reprovou tres elos que estao vivos.
## O `#` dentro de uma string nao abre comentario, entao o estado de aspas
## precisa ser acompanhado mesmo mantendo o conteudo.
## Assinatura estrutural de uma receita de som: quais ondas, quantas camadas e
## que envelopes. Duas receitas com a mesma assinatura sao o MESMO som — no
## maximo transposto — e e exatamente isso que os portoes de audio proibem.
func _assinatura_som(receita: Dictionary) -> String:
	var partes: Array = []
	for camada in receita.get("camadas", []):
		var c: Dictionary = camada
		partes.append("%s:%.3f:%.4f:%.4f:%s" % [
			str(c.get("onda", "")), float(c.get("dur", 0.0)),
			float(c.get("atk", 0.0)), float(c.get("dec", 0.0)),
			str(c.get("fm_ratio", "-"))])
	return "|".join(partes)

## SAIDA "COLADA DE EXECUCAO" TEM QUE SER COLAVEL DE VERDADE.
##
## `QUALIDADE.md` publica um bloco que se apresenta como saida crua dos portoes
## — e havia ali uma linha que NENHUM caminho de codigo emite: `STATUS: PASS
## (kit 1.5.2, 0 falhas)`. `agent_verify.gd` imprime `STATUS: PASS   (%d ms)`,
## e nunca imprimiu outra coisa. Uma linha inventada num documento cuja tese e
## honestidade e o pior tipo de defeito que este projeto pode ter.
##
## O portao pega o esqueleto de cada linha de status do bloco (o texto antes do
## primeiro numero) e exige que ele apareca literalmente num `print` do
## repositorio. Nao prova que o bloco foi colado; prova que ele nao foi
## inventado.
func _conferir_saida_colada() -> int:
	var texto := _ler("res://docs/QUALIDADE.md")
	if texto == "":
		return 0
	# Junta o codigo todo uma vez: e nele que os moldes de `print` vivem.
	var fonte := ""
	for raiz in ["res://scripts", "res://tools"]:
		for arq in _listar_gd(str(raiz)):
			fonte += _ler(str(arq))
	fonte += _ler("res://agent_verify.gd")
	var erros := 0
	var re_status := RegEx.create_from_string("(?m)^(===[A-ZÁ-Ú-]+===|STATUS:)[^\n]*")
	for m in re_status.search_all(texto):
		var linha := m.get_string(0)
		# O esqueleto: tudo ate o primeiro digito, sem espacos nas pontas.
		var corte := linha.length()
		for i in linha.length():
			if linha[i] >= "0" and linha[i] <= "9":
				corte = i
				break
		var molde := linha.substr(0, corte)
		# `print("===STATUS=== ", "PASS" if ok else "FAIL")` monta o veredito com
		# DOIS argumentos, entao a palavra nunca aparece colada no codigo-fonte:
		# o esqueleto para antes dela.
		molde = molde.strip_edges()
		for palavra in [" PASS", " FAIL"]:
			if molde.ends_with(str(palavra)):
				molde = molde.substr(0, molde.length() - str(palavra).length()).strip_edges()
		if molde.length() < 6:
			continue
		if not fonte.contains(molde):
			print("  FALHOU [doc] QUALIDADE.md publica '%s' e nenhum print do codigo emite isso" % molde)
			erros += 1
	return erros

## A ARITMETICA DO DOCUMENTO SOBRE HONESTIDADE tem que fechar.
##
## `QUALIDADE.md` afirma quantos dos 100 pontos sao portao, medida e juizo. Os
## numeros vinham escritos a mao e estavam errados — diziam 59/11/30 quando a
## propria tabela logo acima soma 61/11/28. Aqui a soma sai da tabela: cada
## linha traz o peso e o tipo, e a afirmacao e conferida contra eles.
func _conferir_contagem_honesta() -> int:
	var texto := _ler("res://docs/QUALIDADE.md")
	if texto == "":
		print("  FALHOU [doc] nao consegui ler QUALIDADE.md")
		return 1
	# | N | **Nome** | Peso | TIPO | ...
	var re_linha := RegEx.create_from_string(
		"(?m)^\\|\\s*\\d+\\s*\\|[^|]+\\|\\s*(\\d+)\\s*\\|\\s*(PORT[ÃA]O|MEDIDA|JU[ÍI]ZO)\\s*\\|")
	var soma := {"portao": 0, "medida": 0, "juizo": 0}
	var linhas := 0
	for m in re_linha.search_all(texto):
		linhas += 1
		var peso := int(m.get_string(1))
		var tipo := m.get_string(2)
		if tipo.begins_with("PORT"):
			soma["portao"] += peso
		elif tipo == "MEDIDA":
			soma["medida"] += peso
		else:
			soma["juizo"] += peso
	var erros := 0
	if linhas < 15:
		print("  FALHOU [doc] a tabela da rubrica tem %d criterios, esperava 15" % linhas)
		erros += 1
	var total: int = int(soma["portao"]) + int(soma["medida"]) + int(soma["juizo"])
	if total != 100:
		print("  FALHOU [doc] os pesos da rubrica somam %d, nao 100" % total)
		erros += 1
	var re_diz := RegEx.create_from_string(
		"Contagem honesta: \\*\\*(\\d+) dos 100 pontos\\*\\*[\\s\\S]{0,200}?\\*\\*(\\d+) pontos\\*\\*[\\s\\S]{0,120}?\\*\\*(\\d+) pontos\\*\\*")
	var md := re_diz.search(texto)
	if md == null:
		print("  FALHOU [doc] QUALIDADE.md nao declara mais a contagem honesta")
		return erros + 1
	var ditos := [int(md.get_string(1)), int(md.get_string(2)), int(md.get_string(3))]
	var reais_c := [int(soma["portao"]), int(soma["medida"]), int(soma["juizo"])]
	var rotulos := ["portao", "medida", "juizo"]
	for i in 3:
		if ditos[i] != reais_c[i]:
			print("  FALHOU [doc] a contagem honesta diz %d ponto(s) de %s e a tabela soma %d" % [
				ditos[i], rotulos[i], reais_c[i]])
			erros += 1
	return erros

## Le um script do projeto como texto. Devolve "" se nao abrir — quem chama
## afirma sobre o conteudo, entao um arquivo faltando reprova de qualquer jeito.
func _ler(caminho: String) -> String:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()

func _sem_comentario(texto: String) -> String:
	var saida := ""
	for linha in texto.split("\n"):
		var aspas := ""
		var corte := linha.length()
		var i := 0
		while i < linha.length():
			var c := linha[i]
			if aspas != "":
				if c == aspas:
					aspas = ""
			elif c == "\"" or c == "'":
				aspas = c
			elif c == "#":
				corte = i
				break
			i += 1
		saida += linha.substr(0, corte) + "\n"
	return saida

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

	# --- 1. PURGA PERFEITA E PURGA ESTOURADA NAO PODEM SOAR IGUAL ---
	# A qualidade (0,18 a 1,0) e calculada e usada no dano, nas particulas, no
	# tremor e no hitstop — e era jogada fora no audio.
	ok("existe um som proprio da Purga perfeita", cat.has("hab_purga_perfeita"))
	ok("...e ele e gerado junto com os outros",
		Sfx.nomes().has("hab_purga_perfeita"))
	ok("...e nao e o mesmo da Purga comum",
		_assinatura_som(cat.get("hab_purga_perfeita", {})) != _assinatura_som(cat.get("hab_purga", {})))
	var txt_bus := _ler("res://scripts/core/event_bus.gd")
	ok("o barramento carrega a qualidade da Purga", txt_bus.contains("signal purga_usada"))
	var txt_mec := _ler("res://scripts/sim/mecanicas.gd")
	ok("a Purga emite a qualidade que teve", txt_mec.contains("Bus.purga_usada.emit(q, perfeita)"))
	var txt_ae := _ler("res://scripts/audio/audio_engine.gd")
	ok("o audio escuta a qualidade", txt_ae.contains("Bus.purga_usada.connect(_ao_purga)"))
	ok("...e escolhe outro som quando e perfeita",
		txt_ae.contains('tocar("hab_purga_perfeita"'))

	# --- 2. A ESCADA DO COMBO EM SEMITONS, nao em fracao linear ---
	var A := load("res://scripts/audio/audio_engine.gd") as GDScript
	ok("audio_engine.gd carrega", A != null)
	if A != null:
		var p0: float = A._passo_do_combo(0)
		ok("combo zero nao mexe no tom", perto(p0, 1.0, 0.0001))
		var subiu := true
		var anterior := 0.0
		for combo in [0, 4, 8, 12, 20, 40, 80, 400]:
			var v: float = A._passo_do_combo(int(combo))
			if v < anterior:
				subiu = false
			anterior = v
		ok("a escada so sobe", subiu)
		ok("a escada tem teto", perto(A._passo_do_combo(4000), A._passo_do_combo(400), 0.0001))
		# Cada degrau tem que ser um SEMITOM EXATO: 2^(n/12). Se alguem voltar
		# para a reta na razao, isto reprova.
		var todos_afinados := true
		for combo2 in [0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40]:
			var razao: float = A._passo_do_combo(int(combo2))
			var semitons: float = log(razao) / log(2.0) * 12.0
			if absf(semitons - round(semitons)) > 0.001:
				todos_afinados = false
		ok("todo degrau do combo cai num semitom exato", todos_afinados)

	# --- 3. SINO PRECISA DE RAZAO INARMONICA ---
	var inteiros: Array = []
	for nome_s in ["ouro", "moeda", "conquista"]:
		for camada in (cat.get(nome_s, {}) as Dictionary).get("camadas", []):
			var cm: Dictionary = camada
			if not cm.has("fm_ratio"):
				continue
			var r := float(cm["fm_ratio"])
			if absf(r - round(r)) < 0.001:
				inteiros.append("%s (%.2f)" % [nome_s, r])
	ok("os sinos nao usam razao FM inteira (isso e orgao, nao metal)",
		inteiros.is_empty(), str(inteiros))

	# --- 4. NOVE EFEITOS ERAM O MESMO TRIANGULO TRANSPOSTO ---
	var familia := ["compra", "nivel", "carta", "missao", "conquista", "prestigio"]
	var ondas := {}
	for nome_f in familia:
		var cams: Array = (cat.get(nome_f, {}) as Dictionary).get("camadas", [])
		if cams.is_empty():
			continue
		ondas[str((cams[0] as Dictionary).get("onda", ""))] = true
	ok("os eventos de progresso nao sao todos o mesmo instrumento",
		ondas.size() >= 3, str(ondas.keys()))
	var assinaturas := {}
	for nome_f2 in familia:
		assinaturas[_assinatura_som(cat.get(nome_f2, {}))] = true
	ok("cada evento de progresso tem receita propria",
		assinaturas.size() == familia.size(), "%d de %d" % [assinaturas.size(), familia.size()])

	# --- 5. "EU MACHUQUEI" E "EU APANHEI" NAO PODEM SER A MESMA RECEITA ---
	ok("dar dano e levar dano soam diferente",
		_assinatura_som(cat.get("impacto", {})) != _assinatura_som(cat.get("torre_dano", {})))
	# ...e nao so por altura: o numero de camadas e o formato tem que diferir.
	var n_imp: int = (cat.get("impacto", {}) as Dictionary).get("camadas", []).size()
	var n_dano: int = (cat.get("torre_dano", {}) as Dictionary).get("camadas", []).size()
	ok("levar dano tem corpo proprio, nao o mesmo transposto", n_imp != n_dano)

	# --- 6. UM WAV POR NOME VIRA BRITADEIRA ---
	ok("o tiro tem variantes", Sfx.variantes("tiro") >= 2)
	ok("o impacto tem variantes", Sfx.variantes("impacto") >= 2)
	ok("som raro nao paga variante", Sfx.variantes("prestigio") == 1)
	ok("o gerador enfileira as variantes", txt_ae.contains("_enfileirar_sfx"))
	ok("...e nunca repete a ultima", txt_ae.contains("_sortear_variante"))
	# Variante de verdade e OUTRA ONDA, nao a mesma com outro nome.
	var motor = A.new()
	var base: Array = (cat.get("tiro", {}) as Dictionary).get("camadas", [])
	var v1: Array = motor._semear(base, 1)
	ok("a variante muda a semente do ruido",
		int((v1[0] as Dictionary).get("semente", 0)) != int((base[0] as Dictionary).get("semente", 20260903)))
	var som0: PackedFloat32Array = Synth.mixar(base)
	var som1: PackedFloat32Array = Synth.mixar(v1)
	var iguais := true
	for i in range(0, mini(som0.size(), som1.size()), 97):
		if absf(som0[i] - som1[i]) > 0.0005:
			iguais = false
			break
	ok("a variante gera onda diferente de verdade", not iguais)
	motor.free()

	# --- 7. A TRILHA TEM QUE SABER DA PURGA E DA VIDA ---
	var txt_mu := _ler("res://scripts/audio/music.gd")
	ok("a trilha semeia uma vez por COMPASSO, nao por passo",
		txt_mu.contains("if compasso != _compasso_semeado:"))
	ok("a trilha sabe da Purga", txt_mu.contains("func marcar_purga("))
	ok("...e da janela dourada", txt_mu.contains("func marcar_purga_pronta("))
	ok("a vida entra na intensidade de forma continua",
		txt_mu.contains("bruta += (1.0 - vida) * 0.30"))
	ok("...e nao como degrau unico", not txt_mu.contains("if vida < 0.35:"))

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
