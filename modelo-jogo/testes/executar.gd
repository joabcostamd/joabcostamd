extends SceneTree
## Caminho headless:  godot --headless --path . -s res://testes/executar.gd


func _initialize() -> void:
	var res := Suite.executar()
	Suite.relatar(res)
	quit(0 if res["status"] == "PASS" else 1)
