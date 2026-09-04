class_name Marca
extends RefCounted

## A MARCA, LIDA DE UM LUGAR SÓ.
##
## O nome do produto aparecia escrito à mão em `project.godot`, no caminho do
## save, na tela de título, nos créditos e no README. Trocar o nome — coisa que
## acontece uma vez, mas acontece — significaria caçar a palavra em 93 scripts,
## em 20 arquivos de idioma e numa logo. Pior: um lugar esquecido não quebra
## nada, só mostra o nome antigo para quem comprou.
##
## Aqui o nome é dado, não código. `data/marca.json` é a fonte, e quem desenha
## pergunta. Trocar o nome do jogo ou da desenvolvedora passa a ser uma linha de
## JSON, e o portão de dados confere que ninguém escreveu por fora.
##
## O NOME DO JOGO É TRADUZÍVEL, e nem sempre deve ser traduzido. Um nome
## descritivo ("Torre Eterna") ganha versão em cada idioma; um nome próprio
## inventado não se traduz em língua nenhuma. `traduzir_nome` decide, e a
## interface obedece sem saber qual dos dois casos é.

static var _d: Dictionary = {}

static func carregar(forcar: bool = false) -> void:
	if not _d.is_empty() and not forcar:
		return
	var caminho := "res://data/marca.json"
	if not FileAccess.file_exists(caminho):
		_d = {}
		return
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		_d = {}
		return
	var texto := f.get_as_text()
	f.close()
	var r = JSON.parse_string(texto)
	_d = r if r is Dictionary else {}

static func _bloco(chave: String) -> Dictionary:
	carregar()
	var b = _d.get(chave, {})
	return b if b is Dictionary else {}

## O nome do jogo, na língua da pessoa.
##
## O padrão de emergência (JSON faltando ou corrompido) vem do `project.godot`,
## não de um literal aqui. Um literal seria a terceira verdade sobre o nome — e
## a que só aparece quando algo já deu errado, que é quando ninguém a confere.
static func nome(ingles: bool = false) -> String:
	var j := _bloco("jogo")
	if not bool(j.get("traduzir_nome", true)):
		return str(j.get("nome", _do_projeto()))
	return Ux.txt(j, "nome", ingles)

static func _do_projeto() -> String:
	var v = ProjectSettings.get_setting("application/config/name", "")
	return str(v)

static func subtitulo(ingles: bool = false) -> String:
	return Ux.txt(_bloco("jogo"), "subtitulo", ingles)

## Nome e subtítulo juntos, para tela de título e loja.
static func completo(ingles: bool = false) -> String:
	var sub := subtitulo(ingles)
	return nome(ingles) if sub == "" else "%s — %s" % [nome(ingles), sub]

## Identificador estável, em minúsculas e sem acento. É o que nomeia o arquivo
## de save e a pasta do usuário: se ele mudasse junto com o nome comercial, todo
## mundo que já joga perderia o progresso na atualização que renomeia o jogo.
static func id_curto() -> String:
	return str(_bloco("jogo").get("id_curto", "tower_zero"))

static func estudio() -> String:
	return str(_bloco("estudio").get("nome", ""))

static func titular() -> String:
	return str(_bloco("legal").get("titular", ""))

static func ano_inicial() -> int:
	return int(_bloco("legal").get("ano_inicial", 2026))

## "© 2026 Joab Costa" ou "© 2026-2029 Joab Costa" — a segunda data só aparece
## quando o ano corrente passou do inicial, que é como a linha de copyright é
## escrita de verdade.
static func copyright_linha() -> String:
	var ano := int(Time.get_date_dict_from_system().get("year", ano_inicial()))
	var faixa := str(ano_inicial()) if ano <= ano_inicial() else "%d-%d" % [ano_inicial(), ano]
	return "© %s %s" % [faixa, titular()]

static func app_id() -> int:
	return int(_bloco("steam").get("app_id", 0))
