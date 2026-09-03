class_name Projetil
extends RefCounted

## Projétil da torre (ou do inimigo). Reciclado por pool.

var ativo := false
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var ang := 0.0
var velocidade := 400.0
var raio := 4.0
var vida := 3.0
var t := 0.0

var dano := 0.0            # log10
var critico := false
var alvo: Inimigo = null
var perfuracao := 0
var ricochete := 0
var area := 0.0
## O morteiro explode UMA vez. Ver `TorreSim._impacto`.
var explodiu := false
var elemento := ""
var cor: Color = Color(0.49, 0.83, 0.99)
var tipo := "bala"
var origem := "torre"
var dano_torre := 0.0
var atingidos: Dictionary = {}
var trilha: PackedVector2Array = PackedVector2Array()

func limpar() -> void:
	explodiu = false
	ativo = false
	alvo = null
	atingidos.clear()
	trilha.clear()
	perfuracao = 0
	ricochete = 0
	area = 0.0
	elemento = ""
	critico = false
	tipo = "bala"
	origem = "torre"
	t = 0.0
