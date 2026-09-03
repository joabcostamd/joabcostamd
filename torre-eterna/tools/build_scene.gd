extends SceneTree

## Gera scenes/main.tscn PELA ENGINE (nunca escrevemos .tscn como texto).
##   godot --headless --path . -s res://tools/build_scene.gd

func _initialize() -> void:
	var raiz := Node2D.new()
	raiz.name = "Main"
	raiz.set_script(load("res://scripts/main.gd"))

	var cena := PackedScene.new()
	var err := cena.pack(raiz)
	if err != OK:
		print("ERRO ao empacotar: ", err)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes"))
	err = ResourceSaver.save(cena, "res://scenes/main.tscn")
	print("===BUILD-SCENE=== main.tscn: ", "ok" if err == OK else str(err))
	quit(0 if err == OK else 1)
