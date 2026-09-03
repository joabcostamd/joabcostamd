extends SceneTree
func _initialize() -> void:
	var db = null
	print("antes: inimigos=", db.inimigos.size(), " faltando=", db.faltando, " carregado=", db.carregado)
	db.carregar()
	print("depois: inimigos=", db.inimigos.size(), " upgrades=", db.upgrades.size(), " cartas=", db.cartas.size(),
		" conquistas=", db.conquistas.size(), " eras=", db.eras.size(), " desafios=", db.desafios.size(),
		" eventos=", db.eventos.size(), " missoes=", db.missoes_diarias.size(), " reliquias=", db.reliquias.size())
	print("faltando: ", db.faltando)
	print("existe json: ", FileAccess.file_exists("res://data/enemies.json"))
	quit(0)
