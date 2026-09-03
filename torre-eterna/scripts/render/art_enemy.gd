class_name ArteInimigo
extends RefCounted

## Arte procedural dos inimigos — nenhuma imagem, tudo desenhado por código.
## Cada `forma` tem silhueta própria para ser reconhecível em meio segundo.

static func desenhar(ci: CanvasItem, e: Inimigo, t: float, detalhe: float = 1.0) -> void:
	var p := e.pos - Vector2(0, e.altura)
	var r := e.raio
	var pulso := 1.0 + sin(t * 3.0 + e.fase_anim) * 0.05
	var entrada := 1.0
	if e.entrada > 0.0:
		var dur_ent: float = 0.9 if e.chefe else 0.35
		entrada = Ux.ease_out_back(clampf(1.0 - e.entrada / dur_ent, 0.0, 1.0))
	var morte := 1.0
	var alfa := 1.0
	if e.morrendo > 0.0:
		var k := clampf(e.morrendo / 0.28, 0.0, 1.0)
		morte = 0.3 + k * 1.1
		alfa = k
	if e.intangivel > 0.0:
		alfa *= 0.32
	if bool(e.def.get("invisivel", false)) and not e.revelado:
		alfa *= 0.18

	r *= pulso * entrada * morte
	if r <= 0.4 or alfa <= 0.02:
		return

	var cor := e.cor
	var cor2 := e.cor2
	if e.flash > 0.0:
		cor = cor.lerp(Color.WHITE, clampf(e.flash * 2.6, 0.0, 0.9))
	if e.gelo > 0.0:
		cor = cor.lerp(Color("#6bd6ff"), 0.45)
	if e.queimadura > 0:
		cor = cor.lerp(Color("#ff6b35"), minf(0.5, 0.12 * float(e.queimadura)))
	if e.veneno > 0:
		cor = cor.lerp(Color("#8cff6b"), minf(0.5, 0.06 * float(e.veneno)))
	cor.a = alfa
	cor2.a = alfa

	# sombra no chão (dá peso)
	if detalhe > 0.4 and e.altura > 0.5:
		ci.draw_circle(e.pos + Vector2(0, r * 0.35), r * 0.75, Color(0, 0, 0, 0.28 * alfa))

	# aura de elite / chefe
	if e.chefe:
		ci.draw_arc(p, r * 1.45, 0, TAU, 40, Color(cor.r, cor.g, cor.b, 0.28 * alfa), 3.0, true)
		ci.draw_arc(p, r * 1.7 + sin(t * 2.0) * 4.0, 0, TAU, 40, Color(1, 1, 1, 0.10 * alfa), 1.5, true)
	elif e.elite:
		ci.draw_arc(p, r * 1.3, 0, TAU, 24, Color(cor2.r, cor2.g, cor2.b, 0.55 * alfa), 2.0, true)
	if e.dourado:
		var g := 0.35 + sin(t * 8.0) * 0.2
		ci.draw_circle(p, r * 2.0, Color(0.98, 0.78, 0.2, g * 0.25 * alfa))

	match e.forma:
		"seta": _seta(ci, p, r, e.ang, cor, cor2, alfa)
		"hexagono": _poligono(ci, p, r, 6, e.ang, cor, cor2, alfa)
		"losango": _poligono(ci, p, r, 4, e.ang + t * 1.5, cor, cor2, alfa)
		"triangulo": _poligono(ci, p, r, 3, e.ang, cor, cor2, alfa)
		"escudo": _escudo(ci, p, r, e.ang, cor, cor2, alfa)
		"asa": _asa(ci, p, r, e.ang, t, cor, cor2, alfa)
		"fantasma": _fantasma(ci, p, r, t, e.fase_anim, cor, cor2, alfa)
		"celula": _celula(ci, p, r, t, cor, cor2, alfa)
		"cruz": _cruz(ci, p, r, e.ang, cor, cor2, alfa)
		"canhao": _canhao(ci, p, r, e.ang, cor, cor2, alfa)
		"estrela": _estrela(ci, p, r, e.ang + t, 5, cor, cor2, alfa)
		"bolha": _bolha(ci, p, r, t, e.fase_anim, cor, cor2, alfa)
		"verme": _verme(ci, p, r, e.ang, t, cor, cor2, alfa)
		"prisma": _prisma(ci, p, r, e.ang, cor, cor2, alfa)
		"monolito": _monolito(ci, p, r, e.ang, cor, cor2, alfa)
		"garra": _garra(ci, p, r, e.ang, cor, cor2, alfa)
		"ovo": _ovo(ci, p, r, t, cor, cor2, alfa)
		"fumaca": _fumaca(ci, p, r, t, e.fase_anim, cor, cor2, alfa)
		"boca": _boca(ci, p, r, e.ang, t, cor, cor2, alfa)
		"caos": _caos(ci, p, r, t, e.fase_anim, cor, cor2, alfa)
		"foice": _foice(ci, p, r, e.ang, cor, cor2, alfa)
		"peregrino": _peregrino(ci, p, r, t, cor, cor2, alfa)
		# --- chefes ---
		"tita": _tita(ci, p, r, e.ang, t, cor, cor2, alfa)
		"rainha": _rainha(ci, p, r, t, cor, cor2, alfa)
		"nucleo": _nucleo_chefe(ci, p, r, t, cor, cor2, alfa)
		"arauto": _arauto(ci, p, r, t, cor, cor2, alfa)
		"serpente": _serpente(ci, p, r, e.ang, t, cor, cor2, alfa)
		"espelho": _espelho(ci, p, r, e.ang, t, cor, cor2, alfa)
		"colmeia": _colmeia(ci, p, r, t, cor, cor2, alfa)
		"ceifador": _ceifador(ci, p, r, e.ang, t, cor, cor2, alfa)
		"silencio": _silencio(ci, p, r, t, cor, cor2, alfa)
		"devorador": _devorador(ci, p, r, e.ang, t, cor, cor2, alfa)
		"aniquilador": _aniquilador(ci, p, r, t, cor, cor2, alfa)
		"trono": _trono(ci, p, r, t, cor, cor2, alfa)
		_: _circulo(ci, p, r, cor, cor2, alfa)

	# escudo pessoal
	if e.escudo > Big.LIMIAR_ZERO and e.escudo_max > Big.LIMIAR_ZERO:
		var f := Big.frac(e.escudo, e.escudo_max)
		ci.draw_arc(p, r * 1.28, -PI * 0.5, -PI * 0.5 + TAU * f, 28, Color(0.45, 0.8, 1.0, 0.75 * alfa), 2.5, true)

	# status
	if detalhe > 0.5:
		if e.gelo > 0.0:
			ci.draw_arc(p, r * 1.12, 0, TAU, 16, Color(0.42, 0.84, 1.0, 0.5 * alfa), 2.0, true)
		if e.fissura > 0.0:
			ci.draw_arc(p, r * 1.36, t * 2.0, t * 2.0 + PI * 1.2, 16, Color(0.69, 0.42, 1.0, 0.65 * alfa), 2.0, true)
		if e.atordoado > 0.0:
			for i in 3:
				var a := t * 6.0 + float(i) * TAU / 3.0
				ci.draw_circle(p + Vector2(cos(a), sin(a) * 0.4) * r * 1.5 - Vector2(0, r * 1.2), 2.2, Color(1, 0.95, 0.4, 0.85 * alfa))

	# barra de vida (só quando ferido)
	var fv := e.frac_vida()
	if fv < 0.999 and e.morrendo <= 0.0:
		_barra_vida(ci, p, r, fv, e.chefe, alfa)

## ---------------------------------------------------------------- formas

static func _circulo(ci: CanvasItem, p: Vector2, r: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r, c2)
	ci.draw_circle(p, r * 0.78, c)
	ci.draw_circle(p - Vector2(r * 0.25, r * 0.28), r * 0.22, Color(1, 1, 1, 0.35 * a))

static func _poligono(ci: CanvasItem, p: Vector2, r: float, n: int, ang: float, c: Color, c2: Color, a: float) -> void:
	var pts := _pts(p, r, n, ang)
	ci.draw_colored_polygon(pts, c2)
	ci.draw_colored_polygon(_pts(p, r * 0.74, n, ang), c)
	ci.draw_polyline(_fechar(pts), Color(1, 1, 1, 0.22 * a), 1.5, true)

static func _pts(p: Vector2, r: float, n: int, ang: float) -> PackedVector2Array:
	var v := PackedVector2Array()
	for i in n:
		var t := ang + float(i) / float(n) * TAU
		v.append(p + Vector2(cos(t), sin(t)) * r)
	return v

static func _fechar(pts: PackedVector2Array) -> PackedVector2Array:
	var v := pts.duplicate()
	if v.size() > 0:
		v.append(v[0])
	return v

static func _seta(ci: CanvasItem, p: Vector2, r: float, ang: float, c: Color, c2: Color, a: float) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	var pts := PackedVector2Array([p + d * r * 1.35, p - d * r * 0.7 + n * r * 0.85, p - d * r * 0.25, p - d * r * 0.7 - n * r * 0.85])
	ci.draw_colored_polygon(pts, c)
	ci.draw_polyline(_fechar(pts), c2, 2.0, true)

static func _escudo(ci: CanvasItem, p: Vector2, r: float, ang: float, c: Color, c2: Color, a: float) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	ci.draw_colored_polygon(PackedVector2Array([
		p - d * r * 0.8 + n * r * 0.9, p - d * r * 0.8 - n * r * 0.9,
		p + d * r * 0.5 - n * r * 0.95, p + d * r * 1.1, p + d * r * 0.5 + n * r * 0.95]), c)
	# placa frontal
	ci.draw_line(p + d * r * 0.6 + n * r * 0.8, p + d * r * 0.6 - n * r * 0.8, c2, 3.5)

static func _asa(ci: CanvasItem, p: Vector2, r: float, ang: float, t: float, c: Color, c2: Color, a: float) -> void:
	var bat := sin(t * 14.0) * 0.45 + 0.6
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	for lado in [1.0, -1.0]:
		ci.draw_colored_polygon(PackedVector2Array([
			p, p + n * lado * r * 1.7 - d * r * 0.5 * bat, p + n * lado * r * 0.8 + d * r * 0.4]), Color(c2.r, c2.g, c2.b, 0.8 * a))
	ci.draw_circle(p, r * 0.6, c)

static func _fantasma(ci: CanvasItem, p: Vector2, r: float, t: float, fase: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p - Vector2(0, r * 0.25), r * 0.85, c)
	var pts := PackedVector2Array()
	pts.append(p + Vector2(-r * 0.85, -r * 0.2))
	for i in 9:
		var x := lerpf(-r * 0.85, r * 0.85, float(i) / 8.0)
		var y := r * 0.75 + sin(t * 6.0 + float(i) * 1.1 + fase) * r * 0.22
		pts.append(p + Vector2(x, y))
	pts.append(p + Vector2(r * 0.85, -r * 0.2))
	ci.draw_colored_polygon(pts, c)
	ci.draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.14, Color(0, 0, 0, 0.75 * a))
	ci.draw_circle(p + Vector2(r * 0.3, -r * 0.3), r * 0.14, Color(0, 0, 0, 0.75 * a))

static func _celula(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r, c2)
	ci.draw_circle(p, r * 0.82, c)
	for i in 3:
		var ang := t * 1.2 + float(i) * TAU / 3.0
		ci.draw_circle(p + Vector2(cos(ang), sin(ang)) * r * 0.38, r * 0.2, c2)

static func _cruz(ci: CanvasItem, p: Vector2, r: float, ang: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r * 0.95, c2)
	var w := r * 0.28
	ci.draw_rect(Rect2(p - Vector2(w, r * 0.72), Vector2(w * 2.0, r * 1.44)), c)
	ci.draw_rect(Rect2(p - Vector2(r * 0.72, w), Vector2(r * 1.44, w * 2.0)), c)

static func _canhao(ci: CanvasItem, p: Vector2, r: float, ang: float, c: Color, c2: Color, a: float) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	ci.draw_circle(p, r * 0.85, c)
	ci.draw_colored_polygon(PackedVector2Array([
		p + n * r * 0.35, p - n * r * 0.35, p + d * r * 1.5 - n * r * 0.22, p + d * r * 1.5 + n * r * 0.22]), c2)

static func _estrela(ci: CanvasItem, p: Vector2, r: float, ang: float, pontas: int, c: Color, c2: Color, a: float) -> void:
	var v := PackedVector2Array()
	for i in pontas * 2:
		var raio := r if i % 2 == 0 else r * 0.45
		var t := ang + float(i) / float(pontas * 2) * TAU
		v.append(p + Vector2(cos(t), sin(t)) * raio)
	ci.draw_colored_polygon(v, c)
	ci.draw_polyline(_fechar(v), c2, 1.5, true)

static func _bolha(ci: CanvasItem, p: Vector2, r: float, t: float, fase: float, c: Color, c2: Color, a: float) -> void:
	var v := PackedVector2Array()
	for i in 14:
		var ang := float(i) / 14.0 * TAU
		var raio := r * (1.0 + sin(t * 5.0 + ang * 3.0 + fase) * 0.13)
		v.append(p + Vector2(cos(ang), sin(ang)) * raio)
	ci.draw_colored_polygon(v, c)
	ci.draw_circle(p, r * 0.42, Color(c2.r, c2.g, c2.b, 0.85 * a))

static func _verme(ci: CanvasItem, p: Vector2, r: float, ang: float, t: float, c: Color, c2: Color, a: float) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	for i in 5:
		var off := d * (-float(i) * r * 0.55) + n * sin(t * 8.0 - float(i) * 0.9) * r * 0.4
		ci.draw_circle(p + off, r * (0.85 - float(i) * 0.12), c if i % 2 == 0 else c2)

static func _prisma(ci: CanvasItem, p: Vector2, r: float, ang: float, c: Color, c2: Color, a: float) -> void:
	var pts := _pts(p, r, 3, ang - PI * 0.5)
	ci.draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.7 * a))
	ci.draw_polyline(_fechar(pts), Color(1, 1, 1, 0.65 * a), 2.0, true)
	ci.draw_line(pts[0], p, c2, 1.5)
	ci.draw_line(pts[1], p, c2, 1.5)

static func _monolito(ci: CanvasItem, p: Vector2, r: float, ang: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_rect(Rect2(p - Vector2(r * 0.62, r * 1.05), Vector2(r * 1.24, r * 2.1)), c2)
	ci.draw_rect(Rect2(p - Vector2(r * 0.44, r * 0.9), Vector2(r * 0.88, r * 1.8)), c)
	ci.draw_line(p - Vector2(0, r * 0.7), p + Vector2(0, r * 0.7), Color(1, 1, 1, 0.2 * a), 2.0)

static func _garra(ci: CanvasItem, p: Vector2, r: float, ang: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r * 0.7, c)
	var d := Vector2(cos(ang), sin(ang))
	for k in [-0.5, 0.0, 0.5]:
		var dd := d.rotated(k)
		ci.draw_line(p, p + dd * r * 1.5, c2, 3.0, true)

static func _ovo(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	var v := PackedVector2Array()
	for i in 16:
		var ang := float(i) / 16.0 * TAU
		var rr := r * (1.15 if sin(ang) < 0.0 else 0.95)
		v.append(p + Vector2(cos(ang) * rr * 0.82, sin(ang) * rr))
	ci.draw_colored_polygon(v, c)
	var pulso := 0.5 + sin(t * 3.5) * 0.25
	ci.draw_circle(p, r * 0.35, Color(c2.r, c2.g, c2.b, pulso * a))

static func _fumaca(ci: CanvasItem, p: Vector2, r: float, t: float, fase: float, c: Color, c2: Color, a: float) -> void:
	for i in 4:
		var ang := t * 1.5 + float(i) * TAU / 4.0 + fase
		var off := Vector2(cos(ang), sin(ang)) * r * 0.4
		ci.draw_circle(p + off, r * 0.62, Color(c.r, c.g, c.b, 0.45 * a))
	ci.draw_circle(p, r * 0.4, Color(c2.r, c2.g, c2.b, 0.9 * a))

static func _boca(ci: CanvasItem, p: Vector2, r: float, ang: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r, c2)
	var abre := 0.35 + absf(sin(t * 3.0)) * 0.5
	var d := Vector2(cos(ang), sin(ang))
	ci.draw_colored_polygon(PackedVector2Array([
		p, p + d.rotated(abre) * r * 1.15, p + d * r * 0.9, p + d.rotated(-abre) * r * 1.15]), c)
	for i in 5:
		var k := lerpf(-abre, abre, float(i) / 4.0)
		ci.draw_line(p + d.rotated(k) * r * 0.55, p + d.rotated(k) * r * 1.05, Color(1, 1, 1, 0.75 * a), 1.5)

static func _caos(ci: CanvasItem, p: Vector2, r: float, t: float, fase: float, c: Color, c2: Color, a: float) -> void:
	var v := PackedVector2Array()
	for i in 11:
		var ang := float(i) / 11.0 * TAU
		var rr := r * (0.6 + absf(sin(t * 4.0 + ang * 5.0 + fase)) * 0.7)
		v.append(p + Vector2(cos(ang), sin(ang)) * rr)
	ci.draw_colored_polygon(v, c)
	ci.draw_polyline(_fechar(v), c2, 2.0, true)

static func _foice(ci: CanvasItem, p: Vector2, r: float, ang: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r * 0.55, c2)
	var pts := PackedVector2Array()
	for i in 12:
		var k := lerpf(-1.2, 1.2, float(i) / 11.0)
		pts.append(p + Vector2(cos(ang + k), sin(ang + k)) * r * (1.5 - absf(k) * 0.35))
	ci.draw_polyline(pts, c, 3.5, true)

## Uma silhueta encapuzada com um halo lento. Não parece uma ameaça — não é.
static func _peregrino(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r * 2.1, Color(c.r, c.g, c.b, 0.10 * a))
	ci.draw_arc(p, r * 1.55, t * 0.5, t * 0.5 + PI * 1.7, 32, Color(c.r, c.g, c.b, 0.45 * a), 1.6, true)
	# manto
	ci.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -r * 1.0), p + Vector2(r * 0.62, r * 0.9),
		p + Vector2(0, r * 1.15), p + Vector2(-r * 0.62, r * 0.9)]), c2)
	# capuz
	ci.draw_circle(p + Vector2(0, -r * 0.55), r * 0.46, c)
	ci.draw_circle(p + Vector2(0, -r * 0.5), r * 0.3, Color(0.04, 0.03, 0.02, 0.9 * a))
	# cajado
	ci.draw_line(p + Vector2(r * 0.7, -r * 1.1), p + Vector2(r * 0.55, r * 1.1), Color(c.r, c.g, c.b, 0.85 * a), 2.0, true)
	ci.draw_circle(p + Vector2(r * 0.7, -r * 1.15), r * 0.17 * (1.0 + sin(t * 2.0) * 0.15), Color(1, 0.95, 0.7, a))

## ----------------------------------------------------------- chefes

static func _tita(ci: CanvasItem, p: Vector2, r: float, ang: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_colored_polygon(_pts(p, r, 6, ang), c2)
	ci.draw_colored_polygon(_pts(p, r * 0.72, 6, ang + 0.4), c)
	for i in 6:
		var an := ang + float(i) / 6.0 * TAU
		ci.draw_line(p + Vector2(cos(an), sin(an)) * r * 0.7, p + Vector2(cos(an), sin(an)) * r * 1.25, Color(1, 0.8, 0.3, 0.8 * a), 3.0)
	ci.draw_circle(p, r * 0.28 * (1.0 + sin(t * 4.0) * 0.15), Color(1, 0.75, 0.25, a))

static func _rainha(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	for i in 6:
		var an := t * 0.8 + float(i) / 6.0 * TAU
		ci.draw_circle(p + Vector2(cos(an), sin(an)) * r * 1.15, r * 0.28, Color(c2.r, c2.g, c2.b, 0.85 * a))
	ci.draw_circle(p, r * 0.95, c)
	_estrela(ci, p, r * 0.6, t * 1.5, 6, Color(1, 1, 1, 0.55 * a), c2, a)

static func _nucleo_chefe(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	for i in 3:
		var raio := r * (0.6 + float(i) * 0.35) + sin(t * 3.0 - float(i)) * 4.0
		ci.draw_arc(p, raio, t * (1.0 + float(i) * 0.4), t * (1.0 + float(i) * 0.4) + PI * 1.4, 28, Color(c.r, c.g, c.b, (0.8 - float(i) * 0.2) * a), 3.5, true)
	ci.draw_circle(p, r * 0.45 * (1.0 + sin(t * 7.0) * 0.14), Color(1, 0.9, 0.55, a))

static func _arauto(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r, Color(0, 0, 0, 0.85 * a))
	ci.draw_arc(p, r * 1.05, 0, TAU, 40, c, 3.0, true)
	for i in 8:
		var an := t * 1.2 + float(i) / 8.0 * TAU
		var l := r * (0.6 + absf(sin(t * 2.0 + float(i))) * 0.8)
		ci.draw_line(p + Vector2(cos(an), sin(an)) * r * 0.4, p + Vector2(cos(an), sin(an)) * (r * 0.4 + l), Color(c.r, c.g, c.b, 0.7 * a), 2.0, true)

static func _serpente(ci: CanvasItem, p: Vector2, r: float, ang: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r, c2)
	ci.draw_circle(p, r * 0.75, c)
	var d := Vector2(cos(ang), sin(ang))
	ci.draw_circle(p + d.rotated(0.5) * r * 0.5, r * 0.16, Color(1, 0.3, 0.3, a))
	ci.draw_circle(p + d.rotated(-0.5) * r * 0.5, r * 0.16, Color(1, 0.3, 0.3, a))

static func _espelho(ci: CanvasItem, p: Vector2, r: float, ang: float, t: float, c: Color, c2: Color, a: float) -> void:
	var pts := _pts(p, r, 8, ang + t * 0.5)
	ci.draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.55 * a))
	ci.draw_polyline(_fechar(pts), Color(1, 1, 1, 0.85 * a), 2.5, true)
	for i in 4:
		ci.draw_line(pts[i], pts[i + 4], Color(1, 1, 1, 0.3 * a), 1.2)

static func _colmeia(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	for anel in 2:
		var n := 6 + anel * 6
		for i in n:
			var an := float(i) / float(n) * TAU + t * (0.3 if anel == 0 else -0.2)
			var off := Vector2(cos(an), sin(an)) * r * (0.45 + float(anel) * 0.45)
			ci.draw_colored_polygon(_pts(p + off, r * 0.24, 6, 0.0), c if (i + anel) % 2 == 0 else c2)
	ci.draw_circle(p, r * 0.3, Color(1, 0.85, 0.3, a))

static func _ceifador(ci: CanvasItem, p: Vector2, r: float, ang: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r * 0.9, Color(0.05, 0.02, 0.05, 0.9 * a))
	_foice(ci, p, r * 1.4, ang + sin(t * 2.0) * 0.4, c, c2, a)
	ci.draw_circle(p + Vector2(-r * 0.22, -r * 0.15), r * 0.12, Color(1, 0.2, 0.35, a))
	ci.draw_circle(p + Vector2(r * 0.22, -r * 0.15), r * 0.12, Color(1, 0.2, 0.35, a))

static func _silencio(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r, Color(0.01, 0.01, 0.03, 0.96 * a))
	var n := 30
	var v := PackedVector2Array()
	for i in n + 1:
		var an := float(i) / float(n) * TAU
		v.append(p + Vector2(cos(an), sin(an)) * (r * 1.1 + sin(an * 7.0 + t * 3.0) * r * 0.1))
	ci.draw_polyline(v, Color(c.r, c.g, c.b, 0.55 * a), 2.0, true)

static func _devorador(ci: CanvasItem, p: Vector2, r: float, ang: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r, c2)
	_boca(ci, p, r * 0.95, ang, t * 1.6, c, c2, a)
	ci.draw_arc(p, r * 1.2, 0, TAU, 32, Color(1, 0.25, 0.2, 0.5 * a), 2.5, true)

static func _aniquilador(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	for i in 3:
		ci.draw_arc(p, r * (1.0 + float(i) * 0.28), t * (1.5 - float(i) * 0.4), t * (1.5 - float(i) * 0.4) + PI * 1.5, 32,
			Color(c.r, c.g, c.b, (0.75 - float(i) * 0.18) * a), 3.0, true)
	_estrela(ci, p, r * 0.9, -t * 0.8, 8, c, c2, a)
	ci.draw_circle(p, r * 0.3 * (1.0 + sin(t * 9.0) * 0.2), Color(1, 1, 1, a))

static func _trono(ci: CanvasItem, p: Vector2, r: float, t: float, c: Color, c2: Color, a: float) -> void:
	ci.draw_circle(p, r * 1.05, Color(0.02, 0.01, 0.06, 0.92 * a))
	for i in 12:
		var an := float(i) / 12.0 * TAU + t * 0.25
		var h := r * (1.1 + sin(t * 1.5 + float(i)) * 0.35)
		ci.draw_line(p + Vector2(cos(an), sin(an)) * r * 0.5, p + Vector2(cos(an), sin(an)) * h, Color(c.r, c.g, c.b, 0.65 * a), 2.5, true)
	ci.draw_arc(p, r * 0.55, 0, TAU, 24, Color(1, 1, 1, 0.5 * a), 2.0, true)

## ------------------------------------------------------------ barra

static func _barra_vida(ci: CanvasItem, p: Vector2, r: float, frac: float, chefe: bool, a: float) -> void:
	var w := r * (2.6 if chefe else 2.0)
	var h := 3.5 if chefe else 2.5
	var y := p.y - r * 1.55 - h
	ci.draw_rect(Rect2(p.x - w * 0.5, y, w, h), Color(0, 0, 0, 0.55 * a))
	var cor := Color(0.31, 0.85, 0.42) if frac > 0.5 else (Color(0.98, 0.75, 0.2) if frac > 0.22 else Color(0.95, 0.35, 0.35))
	cor.a = a
	ci.draw_rect(Rect2(p.x - w * 0.5, y, w * frac, h), cor)
