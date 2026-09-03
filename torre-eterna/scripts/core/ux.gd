class_name Ux
extends RefCounted

## Ux — utilidades de matemática, cor e tempo usadas em todo o jogo.

const TAU_ := 6.283185307179586

## ------------------------------------------------------------- suavização

static func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

static func ease_in_cubic(t: float) -> float:
	return t * t * t

static func ease_out_quart(t: float) -> float:
	return 1.0 - pow(1.0 - t, 4.0)

static func ease_out_expo(t: float) -> float:
	return 1.0 if t >= 1.0 else 1.0 - pow(2.0, -10.0 * t)

static func ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)

static func ease_out_elastic(t: float) -> float:
	if t <= 0.0:
		return 0.0
	if t >= 1.0:
		return 1.0
	var c4 := TAU_ / 3.0
	return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0

static func ease_out_bounce(t: float) -> float:
	var n1 := 7.5625
	var d1 := 2.75
	if t < 1.0 / d1:
		return n1 * t * t
	elif t < 2.0 / d1:
		t -= 1.5 / d1
		return n1 * t * t + 0.75
	elif t < 2.5 / d1:
		t -= 2.25 / d1
		return n1 * t * t + 0.9375
	t -= 2.625 / d1
	return n1 * t * t + 0.984375

static func ease_in_out_sine(t: float) -> float:
	return -(cos(PI * t) - 1.0) / 2.0

## Aproximação suave independente de framerate.
static func approach(atual: float, alvo: float, dt: float, taxa: float) -> float:
	return atual + (alvo - atual) * (1.0 - exp(-taxa * dt))

static func ang_lerp(a: float, b: float, t: float) -> float:
	var d := fposmod(b - a + PI, TAU_) - PI
	return a + d * t

## ------------------------------------------------------------------ cores

static func hex(s: String) -> Color:
	return Color.html(s)

static func mix(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, t)

static func com_alfa(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)

static func clarear(c: Color, t: float) -> Color:
	return c.lerp(Color.WHITE, t)

static func escurecer(c: Color, t: float) -> Color:
	return c.lerp(Color.BLACK, t)

## Cor por raridade (usa a paleta oficial do jogo).
static func brilho_pulsante(c: Color, t: float, forca: float = 0.25) -> Color:
	var p := 1.0 + sin(t * 4.0) * forca
	return Color(minf(1.0, c.r * p), minf(1.0, c.g * p), minf(1.0, c.b * p), c.a)

## ------------------------------------------------------------------ tempo

static func tempo_curto(segundos: float) -> String:
	if segundos < 0.0 or is_inf(segundos) or is_nan(segundos):
		return "—"
	var s := int(segundos) % 60
	var m := (int(segundos) / 60) % 60
	var h := (int(segundos) / 3600) % 24
	var d := int(segundos) / 86400
	if d > 0:
		return "%dd %02dh" % [d, h]
	if h > 0:
		return "%dh %02dm" % [h, m]
	if m > 0:
		return "%dm %02ds" % [m, s]
	return "%ds" % s

static func tempo_relogio(segundos: float) -> String:
	var s := int(maxf(0.0, segundos))
	return "%02d:%02d" % [s / 60, s % 60]

## -------------------------------------------------------------- coleções

static func peso_sorteio(itens: Array, campo: String, r: float) -> Variant:
	var total := 0.0
	for it in itens:
		total += float(it.get(campo, 1.0))
	if total <= 0.0:
		return null
	var alvo := r * total
	for it in itens:
		alvo -= float(it.get(campo, 1.0))
		if alvo <= 0.0:
			return it
	return itens[itens.size() - 1]

## Texto bilíngue vindo dos JSONs: {"nome": "...", "nomeEn": "..."}
static func txt(d: Dictionary, campo: String, ingles: bool) -> String:
	if ingles:
		var en = d.get(campo + "En", "")
		if en is String and not en.is_empty():
			return en
	var pt = d.get(campo, "")
	return pt if pt is String else ""
