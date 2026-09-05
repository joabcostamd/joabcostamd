class_name Mini
extends RefCounted
## Micro-suite de testes: sem addon, sem download, roda em headless e no editor.
## Um caso de teste é um .gd em testes/casos/ que estende Mini e define `rodar()`.

var passou := 0
var falhou: Array[String] = []


func rodar() -> void:
	push_error("caso de teste sem rodar()")


func certo(condicao: bool, o_que: String) -> void:
	if condicao:
		passou += 1
	else:
		falhou.append(o_que)


func igual(obtido: Variant, esperado: Variant, o_que: String) -> void:
	if obtido == esperado:
		passou += 1
	else:
		falhou.append("%s (obtido %s, esperado %s)" % [o_que, obtido, esperado])
