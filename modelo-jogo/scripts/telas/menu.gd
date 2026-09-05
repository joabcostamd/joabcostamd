extends Control
## Tela inicial.

@onready var _jogar: Button = %Jogar
@onready var _sair: Button = %Sair


func _ready() -> void:
	_jogar.pressed.connect(func() -> void: Navegacao.ir("jogo"))
	_sair.pressed.connect(func() -> void: get_tree().quit())
	_jogar.grab_focus()
