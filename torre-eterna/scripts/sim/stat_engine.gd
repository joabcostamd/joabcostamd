class_name StatEngine
extends RefCounted

## Agrega modificadores:  valor = (base + Σflat) × (1 + Σpct) × Πmult
##
## Atributos "grandes" (dano, vida, escudo, regen) são calculados em log10
## para suportar multiplicadores absurdos do fim de jogo.

static var GRANDES := {"dano": true, "vidaMax": true, "escudoMax": true, "regen": true, "escudoRegen": true}

var flat := {}
var pct := {}
var mult := {}
var mult_log := {}        # multiplicadores gigantes (em log10)
var valor := {}
var fontes := {}
var recalculos := 0
var _chaves: Array = []

func _init() -> void:
	_chaves = Dados.stat_chaves.duplicate() if Dados.stat_chaves.size() > 0 else []
	zerar()

func zerar() -> void:
	if _chaves.is_empty():
		_chaves = Dados.stat_chaves.duplicate()
	for k in _chaves:
		flat[k] = 0.0
		pct[k] = 0.0
		mult[k] = 1.0
		mult_log[k] = 0.0
		fontes[k] = []

func add_flat(chave: String, v: float, fonte: String = "") -> void:
	if not flat.has(chave):
		return
	flat[chave] = float(flat[chave]) + v
	if fonte != "":
		fontes[chave].append({"fonte": fonte, "tipo": "flat", "valor": v})

func add_pct(chave: String, v: float, fonte: String = "") -> void:
	if not pct.has(chave):
		return
	pct[chave] = float(pct[chave]) + v
	if fonte != "":
		fontes[chave].append({"fonte": fonte, "tipo": "pct", "valor": v})

## v == 0.0 é válido e ANULA o atributo (cartas de trade-off dependem disso).
func add_mult(chave: String, v: float, fonte: String = "") -> void:
	if not mult.has(chave) or v < 0.0 or is_inf(v) or is_nan(v):
		return
	if v == 0.0:
		mult[chave] = 0.0
		mult_log[chave] = 0.0
		if fonte != "":
			fontes[chave].append({"fonte": fonte, "tipo": "mult", "valor": 0.0})
		return
	# multiplicadores enormes vão para o acumulador logarítmico
	if v > 1.0e30 or float(mult[chave]) > 1.0e250:
		mult_log[chave] = float(mult_log[chave]) + log(v) / 2.302585092994046
	else:
		mult[chave] = float(mult[chave]) * v
	if fonte != "":
		fontes[chave].append({"fonte": fonte, "tipo": "mult", "valor": v})

## Multiplicador já em log10 (ex.: prestígio ×10^40).
func add_mult_log(chave: String, log_v: float, fonte: String = "") -> void:
	if not mult_log.has(chave):
		return
	mult_log[chave] = float(mult_log[chave]) + log_v
	if fonte != "":
		fontes[chave].append({"fonte": fonte, "tipo": "mult", "valor": pow(10.0, minf(log_v, 300.0))})

func calcular() -> void:
	recalculos += 1
	for k in _chaves:
		var def: Dictionary = Dados.stat_defs.get(k, {})
		var base := float(def.get("base", 0.0))
		if float(mult[k]) == 0.0:
			valor[k] = Big.ZERO if GRANDES.has(k) else 0.0
			continue
		var fator: float = maxf(0.0, 1.0 + float(pct[k])) * float(mult[k])
		if GRANDES.has(k):
			var v: float = Big.mul_f(Big.from(base + float(flat[k])), fator)
			if float(mult_log[k]) != 0.0:
				v = Big.from_log(v + float(mult_log[k]))
			valor[k] = v
		else:
			var v: float = (base + float(flat[k])) * fator
			if float(mult_log[k]) != 0.0:
				v *= pow(10.0, minf(float(mult_log[k]), 30.0))
			if def.has("max"):
				v = minf(v, float(def["max"]))
			if bool(def.get("inteiro", false)):
				v = floor(maxf(0.0, v) + 1e-9)
			if is_inf(v) or is_nan(v):
				v = 1.0e30
			valor[k] = v

## Valor numérico comum (física, UI).
func n(chave: String) -> float:
	var v = valor.get(chave, 0.0)
	if GRANDES.has(chave):
		return Big.to_f(v)
	return float(v)

## Valor em log10 (dano, vida).
func b(chave: String) -> float:
	var v = valor.get(chave, 0.0)
	if GRANDES.has(chave):
		return float(v)
	return Big.from(float(v))
