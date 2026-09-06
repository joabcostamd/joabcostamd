extends SceneTree
## godot --headless --path . -s res://simulador/rodar.gd -- [partidas] [fases...]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var partidas := int(args[0]) if args.size() > 0 else Simulador.PARTIDAS_PADRAO
	var fases: Array = []
	for i in range(1, args.size()):
		fases.append(int(args[i]))
	if fases.is_empty():
		fases = [1, 3, 5, 10]

	Simulador.relatar(Simulador.rodar(fases, partidas))
	quit(0)
