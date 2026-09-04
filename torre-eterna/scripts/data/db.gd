class_name Dados
extends RefCounted

## Dados (estatico) — carrega e indexa todo o conteúdo em res://data/*.json.
##
## Os JSONs são gerados a partir dos módulos de design (tools/exportar_dados.mjs).
## Nada aqui muda em tempo de execução: é a fonte de verdade imutável.

const PASTA := "res://data/"

static var inimigos: Array = []
static var inimigo_por_id: Dictionary = {}
static var chefes: Array = []
static var super_chefes: Array = []

static var upgrades: Array = []
static var upgrade_por_id: Dictionary = {}
static var categorias_upgrade: Array = []

static var talentos: Array = []
static var talento_por_id: Dictionary = {}
static var ramos: Array = []

static var camadas_prestigio: Array = []
static var arvore := {"fragmentos": [], "nucleos": [], "eter": []}
static var no_por_id: Dictionary = {}
static var camada_do_no: Dictionary = {}

static var habilidades: Array = []
static var habilidade_por_id: Dictionary = {}
static var nivel_max_habilidade := 15

static var stat_defs: Dictionary = {}
static var stat_grupos: Array = []
static var stat_chaves: Array = []

static var raridades: Array = []
static var raridade_por_id: Dictionary = {}

static var cartas: Array = []
static var carta_por_id: Dictionary = {}
static var conjuntos: Array = []
static var nivel_max_carta := 10

static var reliquias: Array = []
static var reliquia_por_id: Dictionary = {}

static var conquistas: Array = []
static var conquista_por_id: Dictionary = {}
static var categorias_conquista: Array = []
static var pontos_totais := 0

static var missoes_diarias: Array = []
static var missoes_semanais: Array = []
static var missao_por_id: Dictionary = {}
static var temporada: Array = []
static var sequencia_diaria: Array = []

static var eventos: Array = []
static var evento_por_id: Dictionary = {}

static var desafios: Array = []
static var desafio_por_id: Dictionary = {}
static var mods_padrao: Dictionary = {}

static var eras: Array = []
static var capitulos_lore: Array = []
static var entradas_lore: Array = []
static var dicas: Array = []

## Ver `scripts/core/versao.gd`.
static var changelog: Array = []

## Ver `scripts/sim/editos.gd`.
static var editos: Array = []
static var edito_por_id: Dictionary = {}

## Ver `scripts/sim/cepas.gd`.
static var cepas: Array = []
static var cepas_por_eixo: Dictionary = {}
static var cepa_por_id: Dictionary = {}

static var carregado := false
static var faltando: Array = []

static func carregar(forcar: bool = false) -> void:
	if carregado and not forcar:
		return
	faltando.clear()
	var e := _json("enemies")
	inimigos = e.get("inimigos", [])
	chefes = e.get("chefes", [])
	super_chefes = e.get("superChefes", [])
	inimigo_por_id = _indexar(inimigos)

	# O lexico das Cepas, ja separado por eixo. O sorteio roda a cada inimigo
	# que nasce; agrupar aqui evita filtrar 38 entradas por spawn.
	var cp := _json("cepas")
	cepas = cp.get("cepas", [])
	cepa_por_id = _indexar(cepas)
	cepas_por_eixo = {}
	for c in cepas:
		if not (c is Dictionary):
			continue
		var eixo := str(c.get("eixo", ""))
		if not cepas_por_eixo.has(eixo):
			cepas_por_eixo[eixo] = []
		cepas_por_eixo[eixo].append(c)

	changelog = _json("changelog").get("changelog", [])

	var ed := _json("editos")
	editos = ed.get("editos", [])
	edito_por_id = _indexar(editos)

	var u := _json("upgrades")
	upgrades = u.get("upgrades", [])
	categorias_upgrade = u.get("categorias", [])
	upgrade_por_id = _indexar(upgrades)

	var t := _json("talents")
	talentos = t.get("talentos", [])
	ramos = t.get("ramos", [])
	talento_por_id = _indexar(talentos)

	var p := _json("prestige")
	camadas_prestigio = p.get("camadas", [])
	arvore.fragmentos = p.get("fragmentos", [])
	arvore.nucleos = p.get("nucleos", [])
	arvore.eter = p.get("eter", [])
	for chave in ["fragmentos", "nucleos", "eter"]:
		for no in arvore[chave]:
			no_por_id[no.get("id", "")] = no
			camada_do_no[no.get("id", "")] = chave

	var h := _json("abilities")
	habilidades = h.get("habilidades", [])
	nivel_max_habilidade = int(h.get("nivelMax", 15))
	habilidade_por_id = _indexar(habilidades)

	var s := _json("stats")
	stat_defs = s.get("defs", {})
	stat_grupos = s.get("grupos", [])
	stat_chaves = stat_defs.keys()

	var r := _json("rarities")
	raridades = r.get("raridades", [])
	raridade_por_id = _indexar(raridades)

	var c := _json("cards")
	cartas = c.get("cartas", [])
	conjuntos = c.get("conjuntos", [])
	nivel_max_carta = int(c.get("nivelMax", 10))
	carta_por_id = _indexar(cartas)

	var rl := _json("relics")
	reliquias = rl.get("reliquias", [])
	reliquia_por_id = _indexar(reliquias)

	var a := _json("achievements")
	conquistas = a.get("conquistas", [])
	categorias_conquista = a.get("categorias", [])
	pontos_totais = int(a.get("pontosTotais", 0))
	conquista_por_id = _indexar(conquistas)
	if pontos_totais == 0:
		for q in conquistas:
			pontos_totais += int(q.get("pontos", 5))

	var m := _json("missions")
	missoes_diarias = m.get("diarias", [])
	missoes_semanais = m.get("semanais", [])
	temporada = m.get("temporada", [])
	sequencia_diaria = m.get("sequencia", [])
	missao_por_id = _indexar(missoes_diarias)
	for x in missoes_semanais:
		missao_por_id[x.get("id", "")] = x

	var ev := _json("events")
	eventos = ev.get("eventos", [])
	evento_por_id = _indexar(eventos)

	var d := _json("challenges")
	desafios = d.get("desafios", [])
	mods_padrao = d.get("modsPadrao", {})
	desafio_por_id = _indexar(desafios)

	eras = _json("eras").get("eras", [])

	var l := _json("lore")
	capitulos_lore = l.get("capitulos", [])
	entradas_lore = l.get("entradas", [])
	dicas = l.get("dicas", [])

	carregado = true

## CARIMBA A PROCEDÊNCIA EM CADA DICIONÁRIO DE CONTEÚDO.
##
## `Ux.txt` recebe um Dicionário solto e precisa saber de onde ele veio para
## achar a tradução: a chave é `arquivo:id`, e o arquivo é obrigatório porque há
## 37 colisões de id entre conteúdos diferentes. O carimbo é feito UMA vez, aqui,
## e não a cada leitura — `Ux.txt` roda a cada rótulo desenhado.
##
## `_k` começa com sublinhado por convenção: é campo do motor, não do conteúdo, e
## nenhum validador de dados deve cobrar tradução dele.
static func _carimbar(o, arquivo: String) -> void:
	if o is Dictionary:
		var d: Dictionary = o
		if d.has("id") and d["id"] is String:
			d["_k"] = "%s:%s" % [arquivo, str(d["id"])]
		for v in d.values():
			_carimbar(v, arquivo)
	elif o is Array:
		for v2 in o:
			_carimbar(v2, arquivo)

static func _json(nome: String) -> Dictionary:
	var caminho := PASTA + nome + ".json"
	if not ResourceLoader.exists(caminho) and not FileAccess.file_exists(caminho):
		faltando.append(nome)
		return {}
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		faltando.append(nome)
		return {}
	var texto := f.get_as_text()
	f.close()
	var r = JSON.parse_string(texto)
	if r is Dictionary:
		_carimbar(r, nome + ".json")
		return r
	faltando.append(nome + " (json inválido)")
	return {}

static func _indexar(arr: Array) -> Dictionary:
	var d := {}
	for it in arr:
		if it is Dictionary and it.has("id"):
			d[it["id"]] = it
	return d

## Índice da era pela onda.
static func era_da_onda(onda: int) -> int:
	var idx := 0
	for i in eras.size():
		if onda >= int(eras[i].get("ondaInicio", 1)):
			idx = i
	return idx

static func era_atual(onda: int) -> Dictionary:
	if eras.is_empty():
		return {}
	return eras[era_da_onda(onda)]

## Chefe da onda (rotativo e determinístico).
static func chefe_da_onda(onda: int) -> Dictionary:
	if onda % 50 == 0 and not super_chefes.is_empty():
		return super_chefes[(onda / 50 - 1) % super_chefes.size()]
	if chefes.is_empty():
		return {}
	return chefes[(onda / 10 - 1) % chefes.size()]

## Inimigos disponíveis numa onda.
static func pool_da_onda(onda: int) -> Array:
	var out: Array = []
	for e in inimigos:
		if int(e.get("onda", 1)) <= onda:
			out.append(e)
	return out

static func raridade(id: String) -> Dictionary:
	return raridade_por_id.get(id, raridade_por_id.get("comum", {}))
