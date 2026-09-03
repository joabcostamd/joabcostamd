extends SceneTree

## Entrada do portão. Este arquivo não cita NENHUMA classe do jogo de propósito:
## em modo `-s` o Godot compila o script de entrada antes de registrar os
## autoloads, e qualquer classe que dependa de `Bus`/`Cfg` falha a compilar.

func _initialize() -> void:
	# Se o corpo não compila, `load()` devolve um GDScript vazio e o `.new()`
	# estoura sem que ninguém imprima nada: a ferramenta fica pendurada para
	# sempre em vez de reprovar. O portão precisa falhar alto.
	var corpo = load("res://tools/suites/validar_dados.gd")
	if corpo == null or not (corpo as GDScript).can_instantiate():
		print("res://tools/suites/validar_dados.gd nao compila")
		print("===STATUS=== FAIL")
		quit(1)
		return
	var suite = corpo.new()
	suite.rodar(self)
