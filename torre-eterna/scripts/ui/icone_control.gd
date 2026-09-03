extends Control

## Control que desenha um Icone vetorial. Usado em botões, listas e no HUD.

@export var nome := "ouro"
@export var cor := Color.WHITE
@export var cor2 := Color.TRANSPARENT
@export var tamanho := 20.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(tamanho, tamanho)

func configurar(n: String, c: Color, t: float = 20.0, c2: Color = Color.TRANSPARENT) -> void:
	nome = n
	cor = c
	cor2 = c2
	tamanho = t
	custom_minimum_size = Vector2(t, t)
	queue_redraw()

func _draw() -> void:
	Icone.desenhar(self, nome, size * 0.5, tamanho, cor, cor2)
