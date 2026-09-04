class_name ConteudoI18n
extends RefCounted

## AS TRADUÇÕES DO CONTEÚDO, FORA DOS ARQUIVOS DE CONTEÚDO.
##
## Nome de inimigo, descrição de melhoria, lore de prestígio: 1.147 textos que
## vivem dentro dos JSON de dados como par `nome`/`nomeEn`. O formato serve para
## dois idiomas e não serve para vinte — cada inimigo teria vinte campos, quem
## edita balanceamento passaria a rolar por dezenove traduções para achar um
## número, e tradutor e programador brigariam pela mesma linha do mesmo arquivo.
##
## Aqui cada idioma é um arquivo só, indexado por `arquivo:id.campo`. O ARQUIVO
## entra na chave porque existem 37 colisões de id entre conteúdos diferentes —
## a cepa `blindado` e o inimigo `blindado` são duas coisas distintas com o mesmo
## nome curto. Sem o arquivo na chave, uma tradução sobrescreveria a outra em
## silêncio, e o defeito só apareceria para quem jogasse naquele idioma.
##
## Carrega sob demanda: quem joga em português nunca lê nenhum destes arquivos.

const PASTA := "res://data/i18n/conteudo"

static var _cache: Dictionary = {}

static func _mapa(cod: String) -> Dictionary:
	if _cache.has(cod):
		return _cache[cod]
	var m: Dictionary = {}
	var caminho := "%s/%s.json" % [PASTA, cod]
	if FileAccess.file_exists(caminho):
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f != null:
			var r = JSON.parse_string(f.get_as_text())
			f.close()
			if r is Dictionary:
				m = r
			else:
				push_error("[i18n] %s não é um objeto JSON" % caminho)
	_cache[cod] = m
	return m

## O texto traduzido, ou "" se não houver. A cadeia de irmãos vale aqui também:
## uma descrição que falte em espanhol da América Latina usa a da Espanha antes
## de deixar a tela em inglês.
static func buscar(chave: String, cod: String) -> String:
	for passo in Idiomas.cadeia(cod):
		var c := str(passo)
		if c == Idiomas.FONTE or c == Idiomas.PONTE:
			return ""
		var v = _mapa(c).get(chave, null)
		if v != null and str(v) != "":
			return str(v)
	return ""

static func carregado(cod: String) -> int:
	return _mapa(cod).size()

static func recarregar() -> void:
	_cache = {}
