class_name Politica
extends RefCounted
## Três níveis de habilidade. O balanceamento tem que fechar para os três:
## se só o "bom" passa, a fase está dura; se até o "ruim" gabarita, está fácil.

var nome: String
var acerto_base: float

func _init(p_nome: String, p_acerto: float) -> void:
	nome = p_nome
	acerto_base = p_acerto

static func todas() -> Array[Politica]:
	return [
		Politica.new("ruim", 0.45),
		Politica.new("medio", 0.70),
		Politica.new("bom", 0.90),
	]

## Chance de acertar nesta fase, já com a penalidade de dificuldade.
func chance(fase: int) -> float:
	return clampf(acerto_base - Balanceamento.penalidade_da_fase(fase), 0.05, 0.99)
