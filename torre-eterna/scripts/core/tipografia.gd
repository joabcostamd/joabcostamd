class_name Tipografia
extends RefCounted

## A TIPOGRAFIA DO JOGO, E O QUE ACONTECE QUANDO ELA NÃO ESTÁ LÁ.
##
## O jogo desenhava tudo com `ThemeDB.fallback_font` — a fonte embutida do Godot.
## Ela é honesta e legível, e não tem identidade nenhuma: qualquer projeto em
## Godot sem tema tem exatamente a mesma cara. Para uma loja isso custa caro, e a
## primeira coisa que alguém julga numa captura de tela é a letra.
##
## Também não tem chinês, japonês, coreano nem tailandês. Com vinte idiomas, isso
## deixa de ser questão de estilo e vira quadradinho na tela de quatro públicos.
##
## POR QUE ISTO NÃO EXPLODE SEM AS FONTES. Elas não são versionadas (ver
## `fontes/FONTES.md`): quem clona o repositório não as tem, o CI não as tem, e
## quem só quer rodar o jogo não deveria precisar delas. Então tudo aqui é
## condicional — carrega o que existe, encadeia o que carregou, e se não houver
## nada devolve `null`, que é a instrução para a interface continuar usando a
## fonte do motor. Um jogo que não abre porque falta um arquivo de fonte é um
## jogo pior do que um jogo com a letra genérica.
##
## A CADEIA DE RESERVA IMPORTA MAIS QUE A FONTE PRINCIPAL. Uma tela em russo com
## metade em Exo 2 e metade em Noto lê como erro de montagem. A ordem aqui é:
## a fonte da interface primeiro, e as reservas só para o que ela não tem — e a
## reserva de CJK entra apenas quando o idioma escolhido precisa dela, porque
## são vinte megabytes que não fazem falta para quem joga em português.

const PASTA := "res://fontes/"

## Qual reserva cada idioma precisa. Idioma que não aparece aqui é atendido pela
## fonte de interface sozinha.
const RESERVA_POR_IDIOMA := {
	"zh-Hans": "NotoSansSC.otf",
	"zh-Hant": "NotoSansTC.otf",
	"ja": "NotoSansJP.otf",
	"ko": "NotoSansKR.otf",
	"th": "NotoSansThai.ttf",
}

static var _cache: Dictionary = {}
static var _ui: FontVariation = null
static var _titulo: FontVariation = null
static var _idioma_montado := ""

## Existe alguma fonte instalada? Quem desenha usa isto para decidir se aplica um
## tema próprio ou deixa o motor cuidar.
static func instalada() -> bool:
	return _arquivo("Exo2.ttf") != null or _arquivo("Orbitron.ttf") != null

static func _arquivo(nome: String) -> FontFile:
	if _cache.has(nome):
		return _cache[nome]
	var caminho := PASTA + nome
	var f: FontFile = null
	if FileAccess.file_exists(caminho):
		f = FontFile.new()
		var dados := FileAccess.get_file_as_bytes(caminho)
		# `load()` só funciona com o arquivo já importado pelo editor, e as
		# fontes chegam DEPOIS do import (são baixadas na hora de exportar). Por
		# isso os bytes são lidos na mão e entregues ao FontFile direto.
		var erro: int = ERR_UNAVAILABLE
		if dados.size() > 4:
			erro = f.load_dynamic_font_from_byte_array(dados)
		if erro != OK:
			f = null
	_cache[nome] = f
	return f

## A fonte da interface, já com a reserva do idioma pedido. Devolve `null` quando
## não há fonte instalada — e `null` aqui quer dizer "use a do motor".
static func ui(idioma: String) -> FontVariation:
	_montar(idioma)
	return _ui

## A fonte de título. Em alfabeto latino é a de display; nos alfabetos que ela
## não tem, cai para a de interface — um título em Orbitron seguido de um
## subtítulo em Noto, em coreano, leria como duas telas coladas.
static func titulo(idioma: String) -> FontVariation:
	_montar(idioma)
	return _titulo

static func _montar(idioma: String) -> void:
	if _idioma_montado == idioma and _ui != null:
		return
	_idioma_montado = idioma

	var base := _arquivo("Exo2.ttf")
	var display := _arquivo("Orbitron.ttf")
	if base == null and display == null:
		_ui = null
		_titulo = null
		return
	if base == null:
		base = display

	var reservas: Array[Font] = []
	var nome_reserva := str(RESERVA_POR_IDIOMA.get(idioma, ""))
	if nome_reserva != "":
		var r := _arquivo(nome_reserva)
		if r != null:
			reservas.append(r)
	# O tailandês entra sempre que existir: ele é leve e cobre um alfabeto que
	# nenhuma das outras tem.
	if nome_reserva != "NotoSansThai.ttf":
		var t := _arquivo("NotoSansThai.ttf")
		if t != null:
			reservas.append(t)
	base.fallbacks = reservas

	_ui = _com_numeros_alinhados(base)
	var d := display if display != null else base
	# Orbitron não tem cirílico nem CJK. Em russo, ucraniano, chinês, japonês,
	# coreano e tailandês o título usa a fonte de interface — uma letra que
	# EXISTE em peso forte lê melhor do que uma letra bonita que vira caixa.
	if _precisa_de_reserva(idioma) and display != null:
		d = base
	d.fallbacks = reservas
	_titulo = _com_numeros_alinhados(d)

static func _precisa_de_reserva(idioma: String) -> bool:
	return RESERVA_POR_IDIOMA.has(idioma) or idioma == "ru" or idioma == "uk"

## ALGARISMOS DE LARGURA FIXA.
##
## Este jogo mostra número em coluna o tempo todo — ouro, dano, custo, contagem
## de onda —, e com algarismo proporcional a coluna DANÇA a cada quadro, porque
## o `1` é mais estreito que o `8`. `tnum` trava a largura. É a diferença entre
## um painel que parece um instrumento e um painel que parece um rascunho.
static func _com_numeros_alinhados(f: Font) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = f
	fv.opentype_features = {
		# tags OpenType como inteiro de 4 bytes, que é o formato que o Godot usa
		_tag("tnum"): 1,
		_tag("lnum"): 1,
	}
	return fv

static func _tag(s: String) -> int:
	var v := 0
	for i in 4:
		v = (v << 8) | s.unicode_at(i)
	return v
