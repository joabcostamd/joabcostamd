extends SceneTree

## Entrada do portão. Este arquivo não cita NENHUMA classe do jogo de propósito:
## em modo `-s` o Godot compila o script de entrada antes de registrar os
## autoloads, então qualquer classe que use `Bus`/`Cfg` falharia a compilar —
## de forma intermitente, o que é pior ainda. O corpo mora em tools/suites/ e é
## carregado aqui dentro, quando os autoloads já existem.

func _initialize() -> void:
	var suite = load("res://tools/suites/soak.gd").new()
	suite.rodar(self)
