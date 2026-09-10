class_name Suite
extends RefCounted
## Roda todos os casos de testes/casos/. Usada pelo headless e pela cena de testes.

const PASTA := "res://testes/casos"


static func executar() -> Dictionary:
	var passou := 0
	var falhas: Array[String] = []
	var casos: Array[String] = []

	var dir := DirAccess.open(PASTA)
	if dir == null:
		return {"status": "FAIL", "passou": 0, "falhas": ["pasta %s nao existe" % PASTA], "casos": []}

	dir.list_dir_begin()
	var nome := dir.get_next()
	while nome != "":
		if not dir.current_is_dir() and nome.ends_with(".gd"):
			casos.append(nome)
		nome = dir.get_next()
	dir.list_dir_end()
	casos.sort()

	for arquivo in casos:
		var script = load(PASTA.path_join(arquivo))
		if script == null:
			falhas.append("%s: nao compila" % arquivo)
			continue
		var caso = script.new()
		caso.rodar()
		passou += caso.passou
		for f in caso.falhou:
			falhas.append("%s: %s" % [arquivo, f])

	return {
		"status": "PASS" if falhas.is_empty() else "FAIL",
		"passou": passou,
		"falhas": falhas,
		"casos": casos,
	}


static func relatar(res: Dictionary) -> void:
	print("\n===TESTES===")
	print(JSON.stringify(res, "  "))
	print("===FIM-TESTES===")
