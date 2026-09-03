class_name Fmt
extends RefCounted

## Fmt — formatação de números gigantes (entrada em log10) em várias notações.

enum Notacao { MISTA, LETRAS, CIENTIFICA, ENGENHARIA, EXTENSO, LOGARITMICA }

const SUFIXOS := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
	"UDc", "DDc", "TDc", "QaDc", "QiDc", "SxDc", "SpDc", "ODc", "NDc", "Vg"]

const EXTENSO_PT := ["", "mil", "milhão", "bilhão", "trilhão", "quatrilhão", "quintilhão",
	"sextilhão", "septilhão", "octilhão", "nonilhão", "decilhão", "undecilhão", "duodecilhão"]
const EXTENSO_PT_PL := ["", "mil", "milhões", "bilhões", "trilhões", "quatrilhões", "quintilhões",
	"sextilhões", "septilhões", "octilhões", "nonilhões", "decilhões", "undecilhões", "duodecilhões"]
const EXTENSO_EN := ["", "thousand", "million", "billion", "trillion", "quadrillion", "quintillion",
	"sextillion", "septillion", "octillion", "nonillion", "decillion", "undecillion", "duodecillion"]

static var notacao: Notacao = Notacao.MISTA
static var casas: int = 2
static var ingles: bool = false

static func sufixo(tier: int) -> String:
	if tier < SUFIXOS.size():
		return SUFIXOS[tier]
	var n := tier - SUFIXOS.size()
	var s := ""
	while true:
		s = char(97 + (n % 26)) + s
		n = n / 26 - 1
		if n < 0:
			break
	return s

static func _dec(v: float, casas_n: int) -> String:
	var s := String.num(v, casas_n)
	if casas_n > 0 and s.contains("."):
		s = s.rstrip("0").rstrip(".")
	if not ingles:
		s = s.replace(".", ",")
	return s

static func _milhar(n: int) -> String:
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = ("," if ingles else ".") + out
	return ("-" if neg else "") + out

## Formata um valor em log10.
static func big(a: float, casas_n: int = -1) -> String:
	if casas_n < 0:
		casas_n = casas
	if a <= Big.LIMIAR_ZERO:
		return "0"
	if is_nan(a):
		return "?"

	# menores que 1 milhão: por extenso
	if a < 6.0:
		var v := pow(10.0, a)
		if v < 1.0:
			return _dec(v, maxi(casas_n, 2))
		if v < 1000.0:
			var cn := 2 if v < 10.0 else (1 if v < 100.0 else 0)
			return _dec(v, mini(casas_n, cn))
		return _milhar(int(v))

	match notacao:
		Notacao.CIENTIFICA:
			return _cientifica(a, casas_n)
		Notacao.ENGENHARIA:
			return _engenharia(a, casas_n)
		Notacao.LOGARITMICA:
			return "e" + _dec(a, 3)
		Notacao.LETRAS:
			return _letras(a, casas_n)
		Notacao.EXTENSO:
			return _extenso(a, casas_n)
		_:
			return _letras(a, casas_n) if a < 36.0 else _cientifica(a, casas_n)

static func _cientifica(a: float, casas_n: int) -> String:
	var e := int(floor(a))
	var m := pow(10.0, a - float(e))
	return "%se%d" % [_dec(m, casas_n), e]

static func _engenharia(a: float, casas_n: int) -> String:
	var e := int(floor(a))
	var e3 := int(floor(float(e) / 3.0)) * 3
	var m := pow(10.0, a - float(e3))
	return "%se%d" % [_dec(m, casas_n), e3]

static func _letras(a: float, casas_n: int) -> String:
	var tier := int(floor(a / 3.0))
	var suf := sufixo(tier)
	var m := pow(10.0, a - float(tier * 3))
	if suf.is_empty():
		return _dec(m, casas_n)
	return "%s %s" % [_dec(m, casas_n), suf]

static func _extenso(a: float, casas_n: int) -> String:
	var tier := int(floor(a / 3.0))
	var tabela := EXTENSO_EN if ingles else EXTENSO_PT
	if tier >= tabela.size():
		return _cientifica(a, casas_n)
	var m := pow(10.0, a - float(tier * 3))
	var nome := ""
	if ingles:
		nome = EXTENSO_EN[tier]
	else:
		nome = EXTENSO_PT_PL[tier] if m >= 2.0 or (m > 1.0 and casas_n > 0) else EXTENSO_PT[tier]
	return _dec(m, casas_n) if nome.is_empty() else "%s %s" % [_dec(m, casas_n), nome]

## Número comum (não-log).
static func num(v: float, casas_n: int = 2) -> String:
	return big(Big.from(v), casas_n) if v > 0.0 else "0"

static func inteiro(v: int) -> String:
	return _milhar(v)

static func pct(frac: float, casas_n: int = 1) -> String:
	return _dec(frac * 100.0, casas_n) + "%"

static func mult(v: float, casas_n: int = 2) -> String:
	return "×" + _dec(v, casas_n)

## "1,23 K / 4,56 M"
static func par(a: float, b: float) -> String:
	return big(a) + " / " + big(b)
