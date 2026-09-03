class_name Coletavel
extends RefCounted

## Moeda/orbe de XP caída no chão. Reciclada por pool.

var ativo := false
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var valor := 0.0          # log10
var tipo := "ouro"        # "ouro" | "dourado" | "gema"
var t := 0.0
var raio := 6.0
var atraido := false
var escala := 0.0

func limpar() -> void:
	ativo = false
	atraido = false
	t = 0.0
	escala = 0.0
	tipo = "ouro"
