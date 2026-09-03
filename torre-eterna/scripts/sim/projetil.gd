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
## De quem é o projétil. Era a String "torre" ou "inimigo", e a pergunta
## `origem == "inimigo"` era feita uma vez por projétil por quadro — com 234
## projéteis vivos, catorze mil comparações de texto por segundo para responder
## sim ou não. Um booleano responde a mesma coisa sem comparar caractere nenhum.
var do_inimigo := false

## Ângulo com que `vel` foi calculada pela última vez. Enquanto o ângulo de mira
## não se afastar disso, a velocidade guardada já está certa e o seno/cosseno
## não precisam ser refeitos (ver `TorreSim.atualizar_projeteis`).
var ang_vel := 0.0
var dano_torre := 0.0
var atingidos: Dictionary = {}

func limpar() -> void:
	explodiu = false
	ativo = false
	alvo = null
	atingidos.clear()
	perfuracao = 0
	ricochete = 0
	area = 0.0
	elemento = ""
	critico = false
	tipo = "bala"
	do_inimigo = false
	ang_vel = 0.0
	t = 0.0
