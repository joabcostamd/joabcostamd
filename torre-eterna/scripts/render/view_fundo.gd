extends Node2D

## Camada de fundo: céu, chão e névoa da era atual. Parallax suave.

var arte := ArteFundo.new()
var jogo: Node
var parallax := Vector2.ZERO

func _ready() -> void:
	z_index = -100
	jogo = get_node_or_null("/root/Jogo")
	Bus.era_mudou.connect(_ao_mudar_era)

func _ao_mudar_era(_i: int, _e: Dictionary) -> void:
	arte.era_atual = -1

func preparar(tam: Vector2) -> void:
	var onda := int(jogo.s.get("onda", 1)) if jogo else 1
	arte.preparar(Dados.era_da_onda(onda), tam)

func _process(delta: float) -> void:
	preparar(get_viewport_rect().size)
	arte.atualizar(delta)
	queue_redraw()

func _draw() -> void:
	var tam := get_viewport_rect().size
	arte.desenhar(self, tam * 0.5 + parallax, _detalhe())

func _detalhe() -> float:
	return [0.3, 0.6, 1.0, 1.0][clampi(int(Cfg.get_v("qualidade", 2)), 0, 3)]
