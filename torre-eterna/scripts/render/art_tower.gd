class_name ArteTorre
extends RefCounted

## A torre central — desenhada em camadas que EVOLUEM com os upgrados do jogador.
## Quanto mais forte a torre, mais anéis, mais luz e mais peso ela ganha.

static func desenhar(ci: CanvasItem, j, t: float, detalhe: float = 1.0) -> void:
	var c: Vector2 = j.arena.centro
	var s: Dictionary = j.s
	var torre: Dictionary = s["torre"]
	var viva := bool(torre["viva"])
	var r := Bal.RAIO_TORRE

	# Nível visual: cresce com o RECORDE, em escala logarítmica, e não satura.
	#
	# Antes vinha de `dano / 12` com teto em 6. Como `dano` é log10 e passa de
	# 72 por volta da onda 30, o valor grudava no teto para sempre: a torre
	# ficava pixel por pixel idêntica da onda 30 à 520. A estrela do jogo não
	# mudava com quinhentas ondas de progressão. Agora cada vez que o recorde
	# TRIPLICA a torre ganha um degrau — onda 3 dá 1, onda 27 dá 3, onda 240 dá
	# 5, onda 2.200 dá 7 —, então ela nunca para de mudar e nunca muda rápido
	# demais para ser notada.
	var recorde := maxf(1.0, float(s["onda_maxima_global"]))
	var poder := clampf(log(recorde) / log(3.0), 0.0, 9.0)
	var anéis := 1 + int(poder * 0.75)
	var vida_frac := Big.frac(torre["vida"], torre["vida_max"])
	var cor_nucleo := Color("#7dd3fc").lerp(Color("#f472b6"), clampf(poder / 9.0, 0.0, 1.0))
	# o elemento em que o jogador mais investiu tinge o núcleo
	var dom := ""
	var dom_v := 0.0
	for par in [["fogo", "danoFogo"], ["gelo", "danoGelo"], ["raio", "danoRaio"], ["veneno", "danoVeneno"], ["vazio", "danoVazio"]]:
		var v: float = j.stats.n(str(par[1]))
		if v > dom_v:
			dom_v = v
			dom = str(par[0])
	if dom != "" and dom_v > 0.05:
		cor_nucleo = cor_nucleo.lerp(Color.html(str(Bal.ELEMENTOS[dom]["cor"])), clampf(dom_v * 1.6, 0.0, 0.7))
	if not viva:
		cor_nucleo = Color("#64748b")

	# --- alcance (halo sutil) ---
	var alcance: float = j.stats.n("alcance")
	ci.draw_arc(c, alcance, 0, TAU, 72, Color(0.35, 0.65, 1.0, 0.055), 1.5, true)

	# --- sombra / base ---
	ci.draw_circle(c + Vector2(0, 6), r * 1.5, Color(0, 0, 0, 0.35))
	ci.draw_circle(c, r * 1.32, Color("#111a2e"))
	ci.draw_arc(c, r * 1.32, 0, TAU, 48, Color("#243356"), 2.0, true)

	# --- anéis orbitais (giram em direções alternadas) ---
	for i in anéis:
		var raio := r * (1.05 + float(i) * 0.22)
		var vel := (0.35 + float(i) * 0.22) * (1.0 if i % 2 == 0 else -1.0)
		var abertura := PI * (1.25 - float(i) * 0.08)
		var alfa := 0.55 - float(i) * 0.06
		ci.draw_arc(c, raio, t * vel, t * vel + abertura, 32,
			Color(cor_nucleo.r, cor_nucleo.g, cor_nucleo.b, alfa), 2.5 - float(i) * 0.15, true)
		if detalhe > 0.5:
			var an := t * vel + abertura
			ci.draw_circle(c + Vector2(cos(an), sin(an)) * raio, 2.6, Color(1, 1, 1, alfa))

	# --- corpo ---
	var pts := PackedVector2Array()
	var lados := 5 + mini(9, int(poder))
	for i in lados:
		var an := float(i) / float(lados) * TAU + t * 0.12
		pts.append(c + Vector2(cos(an), sin(an)) * r)
	ci.draw_colored_polygon(pts, Color("#1b2742"))
	var pts2 := PackedVector2Array()
	for i in lados:
		var an := float(i) / float(lados) * TAU + t * 0.12
		pts2.append(c + Vector2(cos(an), sin(an)) * r * 0.8)
	ci.draw_colored_polygon(pts2, Color("#243660"))

	# --- núcleo pulsante ---
	var pulso := 1.0 + sin(t * 2.2) * 0.09 + (0.16 if j.torre != null and j.torre.recuo > 0.4 else 0.0)
	var rn := r * 0.42 * pulso
	ci.draw_circle(c, rn * 1.9, Color(cor_nucleo.r, cor_nucleo.g, cor_nucleo.b, 0.16))
	ci.draw_circle(c, rn, cor_nucleo)
	ci.draw_circle(c, rn * 0.55, Color(1, 1, 1, 0.9))

	# --- canhão ---
	if j.torre != null:
		var ang: float = j.torre.angulo_canhao
		var recuo: float = j.torre.recuo
		var d := Vector2(cos(ang), sin(ang))
		var n := Vector2(-d.y, d.x)
		var base_off := d * (r * 0.25 - recuo * 5.0)
		var comp := r * 1.15
		var larg := r * 0.19
		ci.draw_colored_polygon(PackedVector2Array([
			c + base_off + n * larg, c + base_off - n * larg,
			c + base_off + d * comp - n * larg * 0.7, c + base_off + d * comp + n * larg * 0.7,
		]), Color("#33436e"))
		ci.draw_line(c + base_off + d * comp * 0.55, c + base_off + d * comp, cor_nucleo, 3.0, true)
		# clarão do disparo
		if recuo > 0.55:
			var f := (recuo - 0.55) / 0.45
			ci.draw_circle(c + base_off + d * comp, r * 0.28 * f, Color(1, 0.96, 0.8, 0.75 * f))

	# --- escudo ---
	if not Big.is_zero(torre["escudo_max"]):
		var ef := Big.frac(torre["escudo"], torre["escudo_max"])
		if ef > 0.001:
			ci.draw_arc(c, r * 1.62, 0, TAU, 56, Color(0.35, 0.7, 1.0, 0.16 + ef * 0.22), 4.0, true)
			ci.draw_arc(c, r * 1.62, -PI * 0.5, -PI * 0.5 + TAU * ef, 56, Color(0.55, 0.85, 1.0, 0.75), 2.5, true)

	# --- anel de vida ---
	var cor_vida := Color("#4ade80") if vida_frac > 0.5 else (Color("#fbbf24") if vida_frac > 0.25 else Color("#f87171"))
	ci.draw_arc(c, r * 1.44, 0, TAU, 56, Color(0, 0, 0, 0.45), 5.0, true)
	ci.draw_arc(c, r * 1.44, -PI * 0.5, -PI * 0.5 + TAU * vida_frac, 56, cor_vida, 4.0, true)

	# --- invulnerabilidade ---
	if j.invulneravel > 0.0:
		var k := 0.4 + sin(t * 12.0) * 0.25
		ci.draw_arc(c, r * 1.85, 0, TAU, 64, Color(1, 1, 1, k), 3.0, true)

	# --- marcas de prestígio ---
	#
	# O que a torre carrega de permanente também tem que aparecer nela. Ascensão
	# põe uma lasca girando; Singularidade acende um halo externo; Transcendência
	# grava pontas de coroa. São as três camadas do prestígio, na ordem em que o
	# jogo as apresenta, e é o que faz duas torres de recorde igual parecerem
	# diferentes se uma delas já foi mais longe.
	var asc := int(s["prestigio"].get("ascensoes", 0))
	if asc > 0:
		var lascas := mini(12, asc)
		for i in lascas:
			var an := float(i) / float(lascas) * TAU - t * 0.22
			var pp := c + Vector2(cos(an), sin(an)) * (r * 1.72)
			ci.draw_circle(pp, 2.2, Color(0.55, 0.85, 1.0, 0.55))
	var sing := int(s["prestigio"].get("singularidades", 0))
	if sing > 0:
		var k := clampf(float(sing) / 8.0, 0.15, 0.6)
		ci.draw_arc(c, r * 2.05, 0, TAU, 64, Color(0.66, 0.33, 0.97, k * 0.5), 2.0, true)
	var trans := int(s["prestigio"].get("transcendencias", 0))
	if trans > 0:
		var pontas := mini(9, trans)
		for i in pontas:
			var an2 := float(i) / float(pontas) * TAU + t * 0.05
			var d2 := Vector2(cos(an2), sin(an2))
			var n2 := Vector2(-d2.y, d2.x)
			ci.draw_colored_polygon(PackedVector2Array([
				c + d2 * (r * 1.5) + n2 * 3.0,
				c + d2 * (r * 1.5) - n2 * 3.0,
				c + d2 * (r * 1.98),
			]), Color(0.98, 0.85, 0.35, 0.75))

	# --- torre caída ---
	if not viva:
		ci.draw_arc(c, r * 1.2, 0, TAU, 32, Color(0.6, 0.2, 0.2, 0.6 + sin(t * 6.0) * 0.2), 3.0, true)

## Orbes que giram em volta da torre.
static func desenhar_orbes(ci: CanvasItem, j, t: float) -> void:
	if j.torre == null:
		return
	for o in j.torre.orbes:
		var p: Vector2 = o["pos"]
		var pr := 6.0 + sin(t * 5.0 + float(o["ang"])) * 1.2
		ci.draw_circle(p, pr * 2.2, Color(0.65, 0.55, 1.0, 0.16))
		ci.draw_circle(p, pr, Color("#a78bfa"))
		ci.draw_circle(p, pr * 0.45, Color(1, 1, 1, 0.85))

## Projéteis.
static func desenhar_projeteis(ci: CanvasItem, j, t: float, detalhe: float = 1.0) -> void:
	for item in j.arena.projeteis:
		var p: Projetil = item
		if not p.ativo:
			continue
		var c := p.cor
		match p.tipo:
			"missil":
				var d := Vector2(cos(p.ang), sin(p.ang))
				ci.draw_line(p.pos - d * 12.0, p.pos, Color(c.r, c.g, c.b, 0.55), 3.0, true)
				ci.draw_circle(p.pos, p.raio, c)
				ci.draw_circle(p.pos, p.raio * 0.5, Color(1, 1, 1, 0.9))
			"acido":
				ci.draw_circle(p.pos, p.raio, c)
				ci.draw_circle(p.pos, p.raio * 0.5, Color(1, 0.85, 0.9, 0.8))
			"morteiro":
				ci.draw_circle(p.pos, p.raio * 1.6, Color(c.r, c.g, c.b, 0.25))
				ci.draw_circle(p.pos, p.raio, c)
			_:
				var d2 := Vector2(cos(p.ang), sin(p.ang))
				if detalhe > 0.4:
					ci.draw_line(p.pos - d2 * (7.0 + p.raio), p.pos, Color(c.r, c.g, c.b, 0.4), p.raio * 0.9, true)
				ci.draw_circle(p.pos, p.raio, c)
				if p.critico:
					ci.draw_circle(p.pos, p.raio * 1.9, Color(c.r, c.g, c.b, 0.28))

## Ouro/gemas no chão.
static func desenhar_coletaveis(ci: CanvasItem, j, t: float) -> void:
	for item in j.arena.coletaveis:
		var c: Coletavel = item
		if not c.ativo:
			continue
		var r := c.raio * c.escala * (1.0 + sin(t * 6.0 + c.pos.x * 0.05) * 0.12)
		var cor := Color("#fbbf24") if c.tipo == "ouro" else Color("#fde68a")
		ci.draw_circle(c.pos, r * 1.8, Color(cor.r, cor.g, cor.b, 0.18))
		ci.draw_circle(c.pos, r, cor)
		ci.draw_circle(c.pos - Vector2(r * 0.28, r * 0.3), r * 0.3, Color(1, 1, 1, 0.75))
