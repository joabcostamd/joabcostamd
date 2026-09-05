extends Node
## Caminho do editor: abra cenas/testes.tscn e aperte F6.


func _ready() -> void:
	var res := Suite.executar()
	Suite.relatar(res)
	if not Engine.is_editor_hint():
		get_tree().quit(0 if res["status"] == "PASS" else 1)
