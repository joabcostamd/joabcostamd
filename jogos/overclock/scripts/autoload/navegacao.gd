extends Node
## Troca de tela num lugar só, com transição e pilha de volta.

const TELAS := {
	"menu": "res://cenas/menu.tscn",
	"jogo": "res://cenas/jogo.tscn",
}

var _pilha: Array[String] = []


func ir(tela: String) -> void:
	if not TELAS.has(tela):
		push_error("tela desconhecida: %s" % tela)
		return
	_pilha.append(tela)
	get_tree().change_scene_to_file(TELAS[tela])


func voltar() -> void:
	if _pilha.size() > 1:
		_pilha.pop_back()
		get_tree().change_scene_to_file(TELAS[_pilha.back()])
	else:
		ir("menu")
