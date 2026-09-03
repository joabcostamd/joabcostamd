class_name RngX
extends RefCounted

## RngX — geração aleatória com utilidades de jogo (gaussiana, pity, pesos).

var rng := RandomNumberGenerator.new()

func _init(semente: int = 0) -> void:
	if semente == 0:
		rng.randomize()
	else:
		rng.seed = semente

func f() -> float:
	return rng.randf()

func entre(a: float, b: float) -> float:
	return rng.randf_range(a, b)

func inteiro(a: int, b: int) -> int:
	return rng.randi_range(a, b)

func chance(p: float) -> bool:
	return rng.randf() < p

func sinal() -> float:
	return 1.0 if rng.randf() < 0.5 else -1.0

func angulo() -> float:
	return rng.randf() * TAU

func escolher(arr: Array) -> Variant:
	if arr.is_empty():
		return null
	return arr[rng.randi() % arr.size()]

## Gaussiana (Box-Muller) — dispersão natural de partículas.
func gauss(media: float = 0.0, desvio: float = 1.0) -> float:
	var u := maxf(1e-7, rng.randf())
	var v := rng.randf()
	return media + desvio * sqrt(-2.0 * log(u)) * cos(TAU * v)

func direcao() -> Vector2:
	var a := angulo()
	return Vector2(cos(a), sin(a))

## Sorteio por peso: itens são Dictionaries com o campo informado.
func por_peso(itens: Array, campo: String = "peso") -> Variant:
	return Ux.peso_sorteio(itens, campo, rng.randf())

## Sorte com "pity": cada falha aumenta a chance. Devolve [acertou, novo_pity].
func pity(chance_base: float, acumulado: int, passo: float) -> Array:
	var c := minf(1.0, chance_base + float(acumulado) * passo)
	if rng.randf() < c:
		return [true, 0]
	return [false, acumulado + 1]
