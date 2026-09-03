extends SceneTree

## Verificador rápido: carrega todo .gd do projeto e acusa quem não compila.
##   godot --headless --path . -s res://tools/verificar.gd
##   godot --headless --path . -s res://tools/verificar.gd -- scripts/ui/panel_x.gd

func _initialize() -> void:
	Dados.carregar(true)
	var alvos: Array = []
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		for a in args:
			alvos.append("res://" + str(a).replace("res://", ""))
	else:
		alvos = _todos("res://scripts")
		alvos.append_array(_todos("res://tools"))

	var falhas: Array = []
	for caminho in alvos:
		var r = load(caminho)
		if r == null:
			falhas.append(caminho)
			continue
		# `load()` de um .gd com erro de sintaxe devolve um recurso VAZIO em vez
		# de null — o portão passava enquanto o editor acusava "Parse Error".
		# Um script que não compila também não instancia: é essa a pergunta.
		if r is GDScript and not (r as GDScript).can_instantiate():
			falhas.append(caminho + " (nao compila)")
	# cenas e dados
	for cena in _todos("res://scenes", ".tscn"):
		if load(cena) == null:
			falhas.append(cena)
	var faltando := Dados.faltando
	print("===VERIFICAR=== scripts=%d falhas=%d dados_faltando=%s" % [alvos.size(), falhas.size(), str(faltando)])
	for f in falhas:
		print("  FALHA: ", f)
	print("===STATUS=== ", "PASS" if falhas.is_empty() and faltando.is_empty() else "FAIL")
	quit(0 if falhas.is_empty() else 1)

func _todos(pasta: String, ext: String = ".gd") -> Array:
	var out: Array = []
	var d := DirAccess.open(pasta)
	if d == null:
		return out
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if d.current_is_dir():
			if not nome.begins_with("."):
				out.append_array(_todos(pasta + "/" + nome, ext))
		elif nome.ends_with(ext):
			out.append(pasta + "/" + nome)
		nome = d.get_next()
	d.list_dir_end()
	return out
