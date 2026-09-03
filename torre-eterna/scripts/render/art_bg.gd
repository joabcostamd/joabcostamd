class_name ArteFundo
extends RefCounted

## Fundo procedural que muda com a ERA. Céu, chão, névoa e vinheta —
## tudo desenhado, nada de imagem.

var estrelas: PackedVector2Array = PackedVector2Array()
var brilhos: PackedFloat32Array = PackedFloat32Array()
var flocos: Array = []
var rng := RngX.new(20260903)
var era_atual := -1
var paleta := {}
var ceu := {}
var chao := {}
var ambiente := {}
var t := 0.0
var tam := Vector2(1280, 720)
var _tex_vinheta: ImageTexture = null
var _tex_grad: ImageTexture = null
var _grad_c1 := Color.BLACK
var _grad_c2 := Color.BLACK

## Gradiente radial suave (claro no centro, some nas bordas).
func _gerar_gradiente(c1: Color, c2: Color) -> ImageTexture:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var meio := Vector2(float(n - 1) * 0.5, float(n - 1) * 0.5)
	var maxd := meio.length()
	for y in n:
		for x in n:
			var d := clampf(Vector2(float(x), float(y)).distance_to(meio) / maxd, 0.0, 1.0)
			var k := pow(1.0 - d, 2.1)
			img.set_pixel(x, y, Color(c2.r, c2.g, c2.b, k * 0.92))
	return ImageTexture.create_from_image(img)

## Vinheta radial pré-renderizada (64×64 esticada) — suave e barata.
func _gerar_vinheta() -> ImageTexture:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var meio := Vector2(float(n - 1) * 0.5, float(n - 1) * 0.5)
	var maxd := meio.length()
	for y in n:
		for x in n:
			var d := Vector2(float(x), float(y)).distance_to(meio) / maxd
			var a := clampf(pow(clampf((d - 0.42) / 0.58, 0.0, 1.0), 1.7), 0.0, 1.0) * 0.82
			img.set_pixel(x, y, Color(0, 0, 0, a))
	return ImageTexture.create_from_image(img)

func preparar(era_idx: int, tamanho: Vector2) -> void:
	tam = tamanho
	if era_idx == era_atual and not estrelas.is_empty():
		return
	era_atual = era_idx
	var era: Dictionary = Dados.eras[era_idx] if era_idx >= 0 and era_idx < Dados.eras.size() else {}
	paleta = era.get("paleta", {"fundo": "#080b14", "fundo2": "#0e1424", "nevoa": "#16203a", "grade": "#1b2740", "acento": "#38bdf8", "acento2": "#a78bfa"})
	ceu = era.get("ceu", {"tipo": "estrelas", "densidade": 90, "velocidade": 6, "cor": "#dbeafe"})
	chao = era.get("chao", {"tipo": "grade", "escala": 64, "opacidade": 0.16})
	ambiente = era.get("ambiente", {"vinheta": 0.55, "brilho": 0.1, "saturacao": 1.0, "tremorFundo": 0.0})

	estrelas.clear()
	brilhos.clear()
	flocos.clear()
	# `densidade` vem dos dados como fração 0..1
	var dens := float(ceu.get("densidade", 0.5))
	if dens <= 1.5:
		dens *= 240.0
	var n := int(clampf(dens, 0.0, 400.0))
	for i in n:
		estrelas.append(Vector2(rng.entre(0.0, tam.x), rng.entre(0.0, tam.y)))
		brilhos.append(rng.entre(0.25, 1.0))
	if str(ceu.get("tipo", "")) in ["chuva", "cinzas", "neve", "fogo", "codigo"]:
		for i in n:
			flocos.append({
				"p": Vector2(rng.entre(0.0, tam.x), rng.entre(0.0, tam.y)),
				"v": rng.entre(0.4, 1.6),
				"r": rng.entre(0.8, 2.4),
				"f": rng.entre(0.0, TAU),
			})

func atualizar(dt: float) -> void:
	t += dt
	var vel := float(ceu.get("velocidade", 6.0))
	for f in flocos:
		var p: Vector2 = f["p"]
		match str(ceu.get("tipo", "")):
			"chuva":
				p.y += vel * 26.0 * float(f["v"]) * dt
				p.x += vel * 3.0 * dt
			"neve", "cinzas":
				p.y += vel * 6.0 * float(f["v"]) * dt
				p.x += sin(t * 0.8 + float(f["f"])) * 9.0 * dt
			"fogo":
				p.y -= vel * 10.0 * float(f["v"]) * dt
				p.x += sin(t * 2.0 + float(f["f"])) * 12.0 * dt
			"codigo":
				p.y += vel * 18.0 * float(f["v"]) * dt
			_:
				p.y += vel * 4.0 * dt
		if p.y > tam.y + 8.0:
			p.y = -8.0
			p.x = rng.entre(0.0, tam.x)
		elif p.y < -8.0:
			p.y = tam.y + 8.0
			p.x = rng.entre(0.0, tam.x)
		if p.x > tam.x + 8.0:
			p.x = -8.0
		f["p"] = p

func desenhar(ci: CanvasItem, centro: Vector2, detalhe: float = 1.0) -> void:
	var c1 := Color.html(str(paleta.get("fundo", "#080b14")))
	var c2 := Color.html(str(paleta.get("fundo2", "#0e1424")))
	var acento := Color.html(str(paleta.get("acento", "#38bdf8")))
	var grade := Color.html(str(paleta.get("grade", "#1b2740")))

	# --- gradiente radial (textura pré-renderizada: sem banding, uma chamada) ---
	ci.draw_rect(Rect2(Vector2.ZERO, tam), c1)
	if _tex_grad == null or _grad_c1 != c1 or _grad_c2 != c2:
		_grad_c1 = c1
		_grad_c2 = c2
		_tex_grad = _gerar_gradiente(c1, c2)
	var lado := maxf(tam.x, tam.y) * 1.45
	ci.draw_texture_rect(_tex_grad, Rect2(centro - Vector2(lado, lado) * 0.5, Vector2(lado, lado)), false)
	var rmax := tam.length() * 0.62

	# --- chão ---
	var op := float(chao.get("opacidade", 0.16))
	var esc := maxf(16.0, float(chao.get("escala", 64.0)))
	match str(chao.get("tipo", "grade")):
		"grade":
			var cor := Color(grade.r, grade.g, grade.b, op)
			var x := fmod(t * 4.0, esc)
			while x < tam.x:
				ci.draw_line(Vector2(x, 0), Vector2(x, tam.y), cor, 1.0)
				x += esc
			var y := fmod(t * 2.0, esc)
			while y < tam.y:
				ci.draw_line(Vector2(0, y), Vector2(tam.x, y), cor, 1.0)
				y += esc
		"hexagonos":
			if detalhe > 0.4:
				var cor := Color(grade.r, grade.g, grade.b, op)
				var passo := esc
				var linha := 0
				var y := 0.0
				while y < tam.y + passo:
					var offx := 0.0 if linha % 2 == 0 else passo * 0.5
					var x := offx
					while x < tam.x + passo:
						_hex(ci, Vector2(x, y), passo * 0.42, cor)
						x += passo
					y += passo * 0.75
					linha += 1
		"ondas":
			var cor := Color(grade.r, grade.g, grade.b, op)
			for i in 10:
				var raio := fmod(t * 40.0 + float(i) * 90.0, 900.0)
				ci.draw_arc(centro, raio, 0, TAU, 48, Color(cor.r, cor.g, cor.b, cor.a * (1.0 - raio / 900.0)), 1.5, true)
		"circuito":
			var cor := Color(grade.r, grade.g, grade.b, op)
			var passo := esc
			var x := 0.0
			while x < tam.x:
				ci.draw_line(Vector2(x, 0), Vector2(x, tam.y), Color(cor.r, cor.g, cor.b, cor.a * 0.5), 1.0)
				var yy := fmod(t * 22.0 + x * 3.0, tam.y)
				ci.draw_circle(Vector2(x, yy), 2.0, Color(acento.r, acento.g, acento.b, 0.35))
				x += passo
		"ruinas":
			var cor_r := Color(grade.r, grade.g, grade.b, op)
			for i in 26:
				var an := float(i) * 2.399963 + 0.7
				var d := 150.0 + float(i) * 24.0
				var p := centro + Vector2(cos(an), sin(an) * 0.72) * d
				var w := 12.0 + float(i % 4) * 7.0
				var h := 16.0 + float((i * 7) % 5) * 9.0
				ci.draw_rect(Rect2(p - Vector2(w, h) * 0.5, Vector2(w, h)), cor_r)
				ci.draw_line(p + Vector2(-w * 0.5, -h * 0.5), p + Vector2(w * 0.5, -h * 0.5), Color(cor_r.r, cor_r.g, cor_r.b, op * 1.8), 1.0)
		"organico":
			var cor_o := Color(grade.r, grade.g, grade.b, op)
			for i in 16:
				var an2 := float(i) * 0.7853 + t * 0.05
				var d2 := 120.0 + float(i) * 34.0
				var p2 := centro + Vector2(cos(an2), sin(an2)) * d2
				var v := PackedVector2Array()
				for k in 9:
					var a7 := float(k) / 8.0 * TAU
					v.append(p2 + Vector2(cos(a7), sin(a7)) * (18.0 + sin(a7 * 3.0 + float(i)) * 7.0))
				ci.draw_polyline(v, cor_o, 1.5)
		"cristais":
			if detalhe > 0.4:
				for i in 22:
					var an := float(i) * 2.399963
					var d := 120.0 + float(i) * 26.0
					var p := centro + Vector2(cos(an), sin(an)) * d
					ci.draw_colored_polygon(PackedVector2Array([
						p + Vector2(0, -14), p + Vector2(7, 4), p + Vector2(-7, 4)]),
						Color(grade.r, grade.g, grade.b, op * 1.6))
		_:
			pass

	# --- céu / partículas ambientais ---
	var cor_ceu := Color.html(str(ceu.get("cor", "#dbeafe")))
	match str(ceu.get("tipo", "estrelas")):
		"estrelas", "aurora", "vazio", "nuvens":
			for i in estrelas.size():
				var b := brilhos[i] * (0.55 + 0.45 * sin(t * 1.6 + float(i) * 0.7))
				ci.draw_circle(estrelas[i], 1.0 + b * 0.9, Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, b * 0.7))
		"chuva":
			for f in flocos:
				var p: Vector2 = f["p"]
				ci.draw_line(p, p + Vector2(1.5, 9.0), Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, 0.35), 1.0)
		"neve", "cinzas", "fogo":
			for f in flocos:
				ci.draw_circle(f["p"], float(f["r"]), Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, 0.45))
		"codigo":
			for f in flocos:
				var p2: Vector2 = f["p"]
				ci.draw_rect(Rect2(p2, Vector2(1.6, 7.0)), Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, 0.4))
		_:
			pass

	# --- aurora / névoa em volta da torre ---
	if str(ceu.get("tipo", "")) == "aurora" and detalhe > 0.5:
		for i in 4:
			var raio := 180.0 + float(i) * 70.0 + sin(t * 0.6 + float(i)) * 22.0
			ci.draw_arc(centro, raio, t * 0.15 + float(i), t * 0.15 + float(i) + PI * 0.8, 40,
				Color(acento.r, acento.g, acento.b, 0.06), 26.0, true)

	# --- vinheta (textura radial gerada uma vez) ---
	var vin := float(ambiente.get("vinheta", 0.5))
	if vin > 0.01:
		if _tex_vinheta == null:
			_tex_vinheta = _gerar_vinheta()
		ci.draw_texture_rect(_tex_vinheta, Rect2(Vector2.ZERO, tam), false, Color(1, 1, 1, clampf(vin, 0.0, 1.0)))

func _hex(ci: CanvasItem, p: Vector2, r: float, cor: Color) -> void:
	var v := PackedVector2Array()
	for i in 7:
		var a := float(i) / 6.0 * TAU
		v.append(p + Vector2(cos(a), sin(a)) * r)
	ci.draw_polyline(v, cor, 1.0)
