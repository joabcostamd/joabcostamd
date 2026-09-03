extends SceneTree

## preload garante que a classe esteja carregada em tempo de parse: em modo
## `-s` a resolução tardia de class_name já deixou esta checagem passar em
## silêncio uma vez, o que é pior do que falhar.
const Textos := preload("res://scripts/core/textos.gd")

## Validador do conteúdo em data/*.json — o JSON é a FONTE DA VERDADE do jogo.
##   godot --headless --path . -s res://tools/validar_dados.gd
## Falha se algum dado quebrar o contrato que o motor espera.

var erros: Array = []
var avisos: Array = []

const COND_VALIDAS := [
	"onda", "ondaMaxima", "ondaMaximaGlobal", "inimigosMortos", "chefesMortos", "ouroTotal",
	"ouroGasto", "nivel", "comboMaximo", "criticos", "ascensoes", "singularidades",
	"transcendencias", "cartas", "lendarios", "tempoTotal", "habilidadesUsadas",
	"douradosAbatidos", "dourados", "danoMaximo", "ondasCompletas", "mortes", "relicas",
	"conquistasTotal", "missoesCompletas", "desafiosCompletos", "tiros", "gemas",
	"fragmentos", "nucleos", "eter", "upgradeNivel", "talentoNivel", "inimigoTipo", "eras",
]
const TIPOS_EFEITO := ["flat", "pct", "mult", "passiva"]
## Teto plausível — só para os tipos que o jogo de fato limita. Onda, nível e
## combo têm um máximo que sai das constantes do balanceamento; ouro e XP não
## têm nenhum (num idle, 1e20 de ouro é começo de partida), então para eles a
## regra checa só sinal e finitude. Inventar um teto para moeda seria trocar um
## bug silencioso por um portão que reprova conteúdo legítimo.
const TETO_COND := {
	"onda": 100000.0, "ondaMaxima": 100000.0, "ondaMaximaGlobal": 100000.0,
	"nivel": 1000.0, "combo": 100000.0,
}

const MINIMOS := {
	"inimigos": 20, "chefes": 10, "upgrades": 35, "talentos": 30, "cartas": 30,
	"reliquias": 24, "conquistas": 80, "missoes_diarias": 20, "missoes_semanais": 10,
	"eventos": 18, "desafios": 12, "eras": 10, "entradas_lore": 35, "habilidades": 8,
}

func _initialize() -> void:
	Dados.carregar(true)
	if not Dados.faltando.is_empty():
		erros.append("arquivos de dados ausentes: %s" % str(Dados.faltando))

	_contagens()
	_bases_batem()
	_ids_unicos()
	_efeitos()
	_condicoes()
	_cores()
	_referencias()
	_bilingue()
	_curvas()
	_i18n()

	print("===VALIDAR-DADOS===")
	print("  erros: %d" % erros.size())
	for e in erros:
		print("    ERRO: ", e)
	print("  avisos: %d" % avisos.size())
	for a in avisos:
		print("    aviso: ", a)
	print("===STATUS=== ", "PASS" if erros.is_empty() else "FAIL")
	quit(0 if erros.is_empty() else 1)

## O seletor de idioma só é honesto se cada chave da interface tiver par em EN.
func _i18n() -> void:
	var faltando := Textos.chaves_sem_en()
	if not faltando.is_empty():
		erros.append("interface sem tradução em EN: %s" % str(faltando))
	for k in Textos.EN.keys():
		if not Textos.PT.has(k):
			avisos.append("chave de interface só em EN: %s" % str(k))
	_i18n_conteudo()

## O seletor de idioma promete o jogo inteiro em inglês, não só os botões. Todo
## texto de CONTEÚDO nos JSON (nome de inimigo, descrição de talento, lore de
## prestígio, dica de chefe) precisa do par `...En`. Faltavam 154 quando esta
## regra nasceu: o painel de Prestígio tinha os nomes traduzidos e as descrições
## em português no meio da tela.
const CAMPOS_TRADUZIVEIS := [
	"nome", "desc", "descricao", "titulo", "lore",
	"resetaTexto", "mantemTexto", "requisito", "dica",
	# `autor` é a assinatura da entrada de lore ("TORRE-0 — log de sistema"):
	# nome próprio mais TIPO DE DOCUMENTO, e o tipo precisa de tradução.
	"autor", "verdade", "verdadeNome",
]

func _i18n_conteudo() -> void:
	var faltas: Array = []
	var d := DirAccess.open("res://data")
	if d == null:
		erros.append("pasta res://data não encontrada")
		return
	d.list_dir_begin()
	var arquivo := d.get_next()
	while arquivo != "":
		if arquivo.ends_with(".json"):
			var f := FileAccess.open("res://data/" + arquivo, FileAccess.READ)
			if f != null:
				var bruto = JSON.parse_string(f.get_as_text())
				f.close()
				_varrer_traducao(bruto, arquivo, faltas)
		arquivo = d.get_next()
	d.list_dir_end()
	if not faltas.is_empty():
		erros.append("conteúdo sem tradução em EN (%d): %s" % [
			faltas.size(), str(faltas.slice(0, 8))])

func _varrer_traducao(o, arquivo: String, faltas: Array) -> void:
	if o is Dictionary:
		for campo_v in CAMPOS_TRADUZIVEIS:
			var campo := str(campo_v)
			if not o.has(campo) or not (o[campo] is String):
				continue
			# a paleta das eras tem uma chave "texto" que é uma COR, não frase
			if str(o[campo]).begins_with("#"):
				continue
			var par: String = str(campo) + "En"
			if not o.has(par):
				faltas.append("%s:%s.%s" % [arquivo, str(o.get("id", "?")), campo])
		for v in o.values():
			_varrer_traducao(v, arquivo, faltas)
	elif o is Array:
		for v in o:
			_varrer_traducao(v, arquivo, faltas)

func _contagens() -> void:
	var reais := {
		"inimigos": Dados.inimigos.size(), "chefes": Dados.chefes.size(),
		"upgrades": Dados.upgrades.size(), "talentos": Dados.talentos.size(),
		"cartas": Dados.cartas.size(), "reliquias": Dados.reliquias.size(),
		"conquistas": Dados.conquistas.size(), "missoes_diarias": Dados.missoes_diarias.size(),
		"missoes_semanais": Dados.missoes_semanais.size(), "eventos": Dados.eventos.size(),
		"desafios": Dados.desafios.size(), "eras": Dados.eras.size(),
		"entradas_lore": Dados.entradas_lore.size(), "habilidades": Dados.habilidades.size(),
	}
	for k in MINIMOS.keys():
		if int(reais.get(k, 0)) < int(MINIMOS[k]):
			erros.append("conteúdo insuficiente em %s: %d (mínimo %d)" % [k, int(reais.get(k, 0)), int(MINIMOS[k])])

func _ids_unicos() -> void:
	var listas := {
		"inimigos": Dados.inimigos, "chefes": Dados.chefes, "elites": Dados.elites,
		"upgrades": Dados.upgrades, "talentos": Dados.talentos, "cartas": Dados.cartas,
		"reliquias": Dados.reliquias, "conquistas": Dados.conquistas, "eventos": Dados.eventos,
		"desafios": Dados.desafios, "eras": Dados.eras, "habilidades": Dados.habilidades,
		"entradas_lore": Dados.entradas_lore, "conjuntos": Dados.conjuntos,
	}
	for nome in listas.keys():
		var vistos := {}
		for it in listas[nome]:
			var id := str(it.get("id", ""))
			if id == "":
				erros.append("%s: item sem id" % nome)
			elif vistos.has(id):
				erros.append("%s: id duplicado '%s'" % [nome, id])
			vistos[id] = true

func _validar_efeito(origem: String, ef) -> void:
	if not (ef is Dictionary):
		erros.append("%s: efeito não é um objeto" % origem)
		return
	if ef.has("especial"):
		return
	if ef.has("chave") and not ef.has("stat"):
		return
	if not ef.has("stat"):
		erros.append("%s: efeito sem 'stat' nem 'especial'" % origem)
		return
	var stat := str(ef["stat"])
	if not Dados.stat_defs.has(stat):
		erros.append("%s: atributo desconhecido '%s'" % [origem, stat])
	var tipo := str(ef.get("tipo", "flat"))
	if not TIPOS_EFEITO.has(tipo):
		erros.append("%s: tipo de efeito inválido '%s'" % [origem, tipo])
	var v = ef.get("valor", 0)
	if not (v is float or v is int) or is_nan(float(v)) or is_inf(float(v)):
		erros.append("%s: valor não numérico/finito" % origem)
	elif tipo == "mult" and float(v) < 0.0:
		erros.append("%s: multiplicador negativo (é %s)" % [origem, str(v)])
	elif tipo == "mult" and float(v) == 0.0:
		avisos.append("%s: multiplicador ZERO anula o atributo (confirme que é intencional)" % origem)

func _efeitos() -> void:
	for grupo in [["upgrades", Dados.upgrades], ["talentos", Dados.talentos],
			["cartas", Dados.cartas], ["reliquias", Dados.reliquias], ["conjuntos", Dados.conjuntos]]:
		for it in grupo[1]:
			var lista = it.get("efeito", it.get("bonus", []))
			if lista is Array:
				for ef in lista:
					_validar_efeito("%s/%s" % [grupo[0], str(it.get("id", "?"))], ef)
	for chave in ["fragmentos", "nucleos", "eter"]:
		for no in Dados.arvore[chave]:
			for ef in no.get("efeito", []):
				_validar_efeito("arvore.%s/%s" % [chave, str(no.get("id", "?"))], ef)

func _condicoes() -> void:
	for c in Dados.conquistas:
		_validar_cond("conquista/" + str(c.get("id", "?")), c.get("cond", {}))
	for m in Dados.missoes_diarias + Dados.missoes_semanais:
		_validar_cond("missao/" + str(m.get("id", "?")), m.get("meta", {}))
	for e in Dados.entradas_lore:
		_validar_cond("lore/" + str(e.get("id", "?")), e.get("cond", {}))

func _validar_cond(origem: String, cond) -> void:
	if not (cond is Dictionary) or cond.is_empty():
		erros.append("%s: condição ausente" % origem)
		return
	var tipo := str(cond.get("tipo", ""))
	if not COND_VALIDAS.has(tipo):
		erros.append("%s: condição desconhecida '%s'" % [origem, tipo])
		return
	if tipo in ["upgradeNivel", "talentoNivel", "inimigoTipo"]:
		var chave := str(cond.get("chave", ""))
		if chave == "":
			erros.append("%s: condição '%s' exige 'chave'" % [origem, tipo])
		else:
			var existe := false
			match tipo:
				"upgradeNivel": existe = Dados.upgrade_por_id.has(chave)
				"talentoNivel": existe = Dados.talento_por_id.has(chave)
				"inimigoTipo": existe = Dados.inimigo_por_id.has(chave) or _eh_chefe(chave)
			if not existe:
				erros.append("%s: chave '%s' não existe" % [origem, chave])
	var v = cond.get("valor", null)
	if not (v is float or v is int):
		erros.append("%s: condição sem valor numérico" % origem)
		return
	# Sem faixa, `{"tipo":"onda","valor":-5}` passava limpo (meta cumprida antes
	# de começar) e `valor: 1e9` também (meta que ninguém alcança). As duas
	# quebram a missão em silêncio, que é o pior jeito de quebrar.
	var n := float(v)
	if not is_finite(n):
		erros.append("%s: valor não-finito" % origem)
	elif n <= 0.0:
		erros.append("%s: valor %s não é positivo — meta já cumprida ao nascer" % [origem, str(v)])
	elif TETO_COND.has(tipo) and n > float(TETO_COND[tipo]):
		erros.append("%s: valor %s acima do teto de '%s' (%s)" % [
			origem, str(v), tipo, str(TETO_COND[tipo])])

## `Bal.DANO_BASE` e `Bal.ALCANCE_BASE` duplicam `data/stats.json`. Duplicata
## calada diverge: o JSON muda, a constante fica, e os testes passam a medir
## contra um valor que o jogo não usa mais. Aqui a duplicata vira invariante.
func _bases_batem() -> void:
	for par in [["dano", Bal.DANO_BASE], ["alcance", Bal.ALCANCE_BASE]]:
		var id := str(par[0])
		var def: Dictionary = Dados.stat_defs.get(id, {})
		if def.is_empty():
			erros.append("stat '%s' não existe em stats.json, mas Bal tem constante para ele" % id)
			continue
		var base := float(def.get("base", 0.0))
		if not is_equal_approx(base, float(par[1])):
			erros.append("stats.json diz %s.base=%s e Bal diz %s — os dois têm que dizer o mesmo" % [
				id, str(base), str(par[1])])

func _eh_chefe(id: String) -> bool:
	for c in Dados.chefes + Dados.super_chefes:
		if str(c.get("id", "")) == id:
			return true
	return false

func _hex_ok(s) -> bool:
	if not (s is String):
		return false
	var t: String = s
	if not t.begins_with("#") or not (t.length() == 7 or t.length() == 9 or t.length() == 4):
		return false
	return t.substr(1).is_valid_hex_number(false)

func _cores() -> void:
	for era in Dados.eras:
		var pal = era.get("paleta", {})
		if not (pal is Dictionary):
			erros.append("era %s: paleta ausente" % str(era.get("id", "?")))
			continue
		for k in pal.keys():
			if not _hex_ok(pal[k]):
				erros.append("era %s: cor inválida em paleta.%s = %s" % [str(era.get("id", "?")), k, str(pal[k])])
	for grupo in [["cartas", Dados.cartas], ["desafios", Dados.desafios], ["eventos", Dados.eventos],
			["inimigos", Dados.inimigos], ["chefes", Dados.chefes], ["habilidades", Dados.habilidades]]:
		for it in grupo[1]:
			for campo in ["cor", "cor2"]:
				if it.has(campo) and not _hex_ok(it[campo]):
					erros.append("%s/%s: %s inválida (%s)" % [grupo[0], str(it.get("id", "?")), campo, str(it[campo])])

func _referencias() -> void:
	for t in Dados.talentos:
		var req = t.get("requer", null)
		if req is Array:
			for id in req:
				if not Dados.talento_por_id.has(str(id)):
					erros.append("talento %s: pré-requisito inexistente '%s'" % [str(t.get("id", "?")), str(id)])
	for u in Dados.upgrades:
		var r = u.get("requer", null)
		if r is Dictionary and r.has("upgrade") and not Dados.upgrade_por_id.has(str(r["upgrade"])):
			erros.append("upgrade %s: requisito inexistente '%s'" % [str(u.get("id", "?")), str(r["upgrade"])])
	for c in Dados.conjuntos:
		for id in c.get("cartas", []):
			if not Dados.carta_por_id.has(str(id)):
				erros.append("conjunto %s: carta inexistente '%s'" % [str(c.get("id", "?")), str(id)])
	for ca in Dados.cartas:
		if ca.has("sinergia") and str(ca["sinergia"]) != "" and not Dados.carta_por_id.has(str(ca["sinergia"])):
			avisos.append("carta %s: sinergia aponta para carta inexistente '%s'" % [str(ca.get("id", "?")), str(ca["sinergia"])])
	for e in Dados.inimigos:
		var mov := str(e.get("mov", "direto"))
		if not mov in ["direto", "zigue", "salto", "teleporte", "fantasma", "parar_atirar", "errante", "perseguidor", "orbital", "estatico", "passa"]:
			erros.append("inimigo %s: movimento desconhecido '%s'" % [str(e.get("id", "?")), mov])
		if e.has("hab"):
			var hab := str(e["hab"])
			if not hab in ["curar", "cuspir", "explodir", "roubar_ouro", "refletir", "grudar", "chocar", "devorar", "mutar", "ceifar"]:
				erros.append("inimigo %s: habilidade desconhecida '%s'" % [str(e.get("id", "?")), hab])

func _bilingue() -> void:
	var faltando := 0
	for grupo in [Dados.upgrades, Dados.talentos, Dados.cartas, Dados.reliquias,
			Dados.conquistas, Dados.desafios, Dados.habilidades, Dados.inimigos, Dados.chefes]:
		for it in grupo:
			if it.has("nome") and not it.has("nomeEn"):
				faltando += 1
	# Isto era AVISO enquanto `_i18n_conteudo` trata exatamente a mesma omissão
	# como ERRO. A mesma falta não pode ser bloqueante num caminho e ignorável
	# no outro — quem lê o portão não tem como saber qual das duas vale.
	if faltando > 0:
		erros.append("%d itens sem tradução em inglês (nomeEn)" % faltando)

func _curvas() -> void:
	# eras precisam começar em ondas crescentes
	var anterior := -1
	for era in Dados.eras:
		var oi := int(era.get("ondaInicio", 0))
		if oi <= anterior:
			erros.append("era %s: ondaInicio %d não é crescente" % [str(era.get("id", "?")), oi])
		anterior = oi
	# custos precisam crescer
	for u in Dados.upgrades:
		if float(u.get("cresc", 1.0)) <= 1.0 and int(u.get("max", -1)) < 0:
			erros.append("upgrade %s: crescimento <= 1 num upgrade infinito (custo nunca sobe)" % str(u.get("id", "?")))
		if float(u.get("base", 0.0)) <= 0.0:
			erros.append("upgrade %s: custo base inválido" % str(u.get("id", "?")))
	for chave in ["fragmentos", "nucleos", "eter"]:
		for no in Dados.arvore[chave]:
			if float(no.get("base", 0.0)) <= 0.0:
				erros.append("arvore.%s/%s: custo base inválido" % [chave, str(no.get("id", "?"))])
