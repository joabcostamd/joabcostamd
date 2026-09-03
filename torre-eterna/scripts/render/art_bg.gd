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
			"neve":
				p.y += vel * 6.0 * float(f["v"]) * dt
				p.x += sin(t * 0.8 + float(f["f"])) * 9.0 * dt
			"cinzas":
				# Cinza desce mais devagar e vagueia mais que neve: ela e leve e
				# o ar do Campo de Vidro esta quente.
				p.y += vel * 3.5 * float(f["v"]) * dt
				p.x += sin(t * 0.45 + float(f["f"])) * 22.0 * dt
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

## Aplica o brilho e a saturacao que a era pede numa cor do fundo.
##
## Brilho anda numa faixa estreita de proposito (0,78 a 1,00): o jogo se le em
## cima do fundo, e clarear demais come o contraste dos inimigos e dos numeros
## de dano. O que importa e a era ter clima proprio, nao ser clara.
func _com_ambiente(c: Color) -> Color:
	var brilho := clampf(float(ambiente.get("brilho", 0.2)), 0.0, 1.0)
	var sat := clampf(float(ambiente.get("saturacao", 1.0)), 0.0, 2.0)
	var cinza := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var s := Color(
		lerpf(cinza, c.r, sat), lerpf(cinza, c.g, sat), lerpf(cinza, c.b, sat), c.a)
	var k := 0.78 + brilho * 0.22
	return Color(clampf(s.r * k, 0.0, 1.0), clampf(s.g * k, 0.0, 1.0),
		clampf(s.b * k, 0.0, 1.0), c.a)

func desenhar(ci: CanvasItem, centro: Vector2, detalhe: float = 1.0) -> void:
	# BRILHO E SATURACAO ERAM DADOS MORTOS.
	#
	# As dez eras declaram `ambiente.brilho` (0,18 a 0,90) e
	# `ambiente.saturacao` (0,55 a 1,35) em `data/eras.json`, e o desenho lia
	# so a vinheta. Medida a luminancia media do fundo nas dez capturas, todas
	# ficavam entre 4 e 22 de 255: as eras mudavam de MATIZ e nao de clima. A
	# Fundicao Perpetua pedia brilho 0,62 e era tao escura quanto a Necropole
	# (0,34); o Nada pedia saturacao 0,55 e nao dessaturava nada.
	#
	# As duas entram aqui, nas cores do gradiente, ANTES do cache — entao nao
	# custam um quadro a mais: a textura so e refeita quando a era muda.
	var c1 := _com_ambiente(Color.html(str(paleta.get("fundo", "#080b14"))))
	var c2 := _com_ambiente(Color.html(str(paleta.get("fundo2", "#0e1424"))))
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
				# `esc` no lugar de 90 fixo: a Aurora (150) e o Inverno (128)
				# desenhavam as MESMAS dez ondas, e o unico dado que tentava
				# separa-las nao mudava um pixel.
				var raio := fmod(t * 40.0 + float(i) * esc, 900.0)
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
				# Idem: a Necropole (160) caia nos mesmos 26 pontos do Cinturao
				# de Sucata (96). Duas das dez "terras novas" eram o mesmo
				# desenho repintado, e a virada de era lia como troca de filtro.
				var d := esc + float(i) * esc * 0.25
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
	# QUATRO TIPOS DE CEU DESENHAVAM O MESMO PONTINHO.
	#
	# "estrelas", "aurora", "vazio" e "nuvens" caiam todos no mesmo ramo: o
	# Cinturao de Sucata pedia NUVENS e recebia estrelas, o Jardim pedia VAZIO e
	# recebia estrelas. O dado estava no JSON desde sempre, escrito e revisado, e
	# quatro eras dividiam um ceu so. Cada uma tem o seu agora, reusando os
	# mesmos pontos ja sorteados — mesma quantidade de desenho por quadro.
	match str(ceu.get("tipo", "estrelas")):
		"estrelas", "aurora":
			for i in estrelas.size():
				var b := brilhos[i] * (0.55 + 0.45 * sin(t * 1.6 + float(i) * 0.7))
				ci.draw_circle(estrelas[i], 1.0 + b * 0.9, Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, b * 0.7))
		"nuvens":
			# Banco de poeira em suspensao: elipses largas e moles, andando de
			# lado. Nada pisca — poeira nao cintila.
			for i in estrelas.size():
				var b2 := brilhos[i]
				var pos_n := estrelas[i] + Vector2(fmod(t * 7.0 + float(i) * 37.0, tam.x + 220.0) - 110.0, 0.0)
				pos_n.x = fmod(pos_n.x + tam.x, tam.x)
				var rx := 26.0 + b2 * 40.0
				ci.draw_set_transform(pos_n, 0.0, Vector2(1.0, 0.34))
				ci.draw_circle(Vector2.ZERO, rx, Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, 0.045 + b2 * 0.05))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"vazio":
			# O Jardim pede VAZIO: aneis finos que abrem devagar e somem. E a
			# ausencia desenhada, nao mais um ceu estrelado.
			for i in mini(estrelas.size(), 18):
				var fase := fmod(t * 0.16 + float(i) * 0.37, 1.0)
				var raio_v := 4.0 + fase * 46.0
				ci.draw_arc(estrelas[i], raio_v, 0.0, TAU, 18,
					Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, (1.0 - fase) * 0.22), 1.0, true)
		"chuva":
			for f in flocos:
				var p: Vector2 = f["p"]
				ci.draw_line(p, p + Vector2(1.5, 9.0), Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, 0.35), 1.0)
		"neve", "fogo":
			for f in flocos:
				ci.draw_circle(f["p"], float(f["r"]), Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, 0.45))
		"cinzas":
			# Cinza nao e floco de neve: e lasca irregular que brilha e apaga
			# enquanto cai. Mesmo laco, primitiva e alfa diferentes.
			for f in flocos:
				var pc: Vector2 = f["p"]
				var rc := float(f["r"])
				var pisca := 0.28 + 0.34 * absf(sin(t * 1.7 + float(f["f"])))
				ci.draw_rect(Rect2(pc, Vector2(rc * 1.6, rc * 1.1)),
					Color(cor_ceu.r, cor_ceu.g, cor_ceu.b, pisca))
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
