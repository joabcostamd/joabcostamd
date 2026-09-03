class_name Particulas
extends RefCounted

## Sistema de partículas próprio: pool fixo, desenho imediato, zero nós.
## Cada partícula é um Dicionário reciclado — nada é alocado no laço quente.

const MAX := 900

var pool: Array = []
var livres: Array = []
var rng := RngX.new()
var densidade := 1.0

func _init() -> void:
	for i in MAX:
		var p := {"ativo": false}
		pool.append(p)
		livres.append(p)

func _pegar() -> Dictionary:
	if livres.is_empty():
		# recicla a mais velha
		for p in pool:
			if bool(p["ativo"]):
				return p
		return pool[0]
	return livres.pop_back()

func limpar() -> void:
	for p in pool:
		p["ativo"] = false
	livres = pool.duplicate()

func vivas() -> int:
	var n := 0
	for p in pool:
		if bool(p["ativo"]):
			n += 1
	return n

## ---------------------------------------------------------------- emitir

func faisca(pos: Vector2, cor: Color, qtd: int = 6, forca: float = 110.0, ang_base: float = -1000.0, espalha: float = TAU) -> void:
	var n := maxi(1, int(float(qtd) * densidade))
	for i in n:
		var p := _pegar()
		var ang := rng.angulo() if ang_base < -100.0 else ang_base + rng.entre(-espalha * 0.5, espalha * 0.5)
		p["ativo"] = true
		p["tipo"] = "faisca"
		p["pos"] = pos
		p["vel"] = Vector2(cos(ang), sin(ang)) * rng.entre(forca * 0.4, forca)
		p["vida"] = rng.entre(0.18, 0.42)
		p["vida_max"] = p["vida"]
		p["cor"] = cor
		p["r"] = rng.entre(1.4, 3.2)
		p["grav"] = 0.0
		p["atrito"] = 3.0

func fumaca(pos: Vector2, cor: Color, qtd: int = 4, raio: float = 14.0) -> void:
	var n := maxi(1, int(float(qtd) * densidade))
	for i in n:
		var p := _pegar()
		p["ativo"] = true
		p["tipo"] = "fumaca"
		p["pos"] = pos + rng.direcao() * rng.entre(0.0, raio * 0.5)
		p["vel"] = rng.direcao() * rng.entre(8.0, 30.0)
		p["vida"] = rng.entre(0.5, 1.1)
		p["vida_max"] = p["vida"]
		p["cor"] = cor
		p["r"] = rng.entre(raio * 0.4, raio)
		p["grav"] = -8.0
		p["atrito"] = 1.2

func anel(pos: Vector2, cor: Color, raio_final: float, dur: float = 0.45, espessura: float = 3.0) -> void:
	var p := _pegar()
	p["ativo"] = true
	p["tipo"] = "anel"
	p["pos"] = pos
	p["vel"] = Vector2.ZERO
	p["vida"] = dur
	p["vida_max"] = dur
	p["cor"] = cor
	p["r"] = raio_final
	p["esp"] = espessura

func estilhaco(pos: Vector2, cor: Color, qtd: int = 5, forca: float = 150.0) -> void:
	var n := maxi(1, int(float(qtd) * densidade))
	for i in n:
		var p := _pegar()
		var ang := rng.angulo()
		p["ativo"] = true
		p["tipo"] = "estilhaco"
		p["pos"] = pos
		p["vel"] = Vector2(cos(ang), sin(ang)) * rng.entre(forca * 0.5, forca)
		p["vida"] = rng.entre(0.35, 0.75)
		p["vida_max"] = p["vida"]
		p["cor"] = cor
		p["r"] = rng.entre(2.5, 5.5)
		p["ang"] = ang
		p["giro"] = rng.entre(-12.0, 12.0)
		p["grav"] = 240.0
		p["atrito"] = 0.6

func raio_linha(pontos: Array, cor: Color, dur: float = 0.22) -> void:
	var p := _pegar()
	p["ativo"] = true
	p["tipo"] = "raio"
	p["pos"] = pontos[0]
	p["pontos"] = pontos.duplicate()
	p["vida"] = dur
	p["vida_max"] = dur
	p["cor"] = cor

func feixe(de: Vector2, para: Vector2, cor: Color, dur: float = 0.14) -> void:
	var p := _pegar()
	p["ativo"] = true
	p["tipo"] = "feixe"
	p["pos"] = de
	p["para"] = para
	p["vida"] = dur
	p["vida_max"] = dur
	p["cor"] = cor

func explosao(pos: Vector2, raio: float, cor: Color) -> void:
	anel(pos, cor, raio * 1.25, 0.4, 4.0)
	anel(pos, Color(1, 1, 1, 0.8), raio * 0.7, 0.22, 2.5)
	faisca(pos, cor, 14, raio * 5.0)
	fumaca(pos, Color(cor.r, cor.g, cor.b, 0.5), 6, raio * 0.5)

func impacto(pos: Vector2, ang: float, cor: Color, critico: bool) -> void:
	faisca(pos, cor, 4 if not critico else 10, 130.0 if not critico else 240.0, ang + PI, 1.6)
	if critico:
		anel(pos, Color(1, 0.95, 0.5, 0.9), 26.0, 0.24, 2.5)

func morte(pos: Vector2, cor: Color, escala: float, chefe: bool) -> void:
	if chefe:
		anel(pos, cor, 220.0, 0.7, 6.0)
		anel(pos, Color(1, 1, 1), 130.0, 0.45, 3.0)
		estilhaco(pos, cor, 26, 340.0)
		fumaca(pos, Color(cor.r, cor.g, cor.b, 0.55), 16, 40.0)
	else:
		estilhaco(pos, cor, int(4.0 + escala * 3.0), 150.0 * escala)
		faisca(pos, cor, int(6.0 * escala), 140.0)
		anel(pos, Color(cor.r, cor.g, cor.b, 0.6), 22.0 * escala, 0.28, 2.0)

func nova(pos: Vector2, raio: float, cor: Color) -> void:
	for i in 4:
		anel(pos, Color(cor.r, cor.g, cor.b, 0.9 - float(i) * 0.18), raio * (0.35 + float(i) * 0.24), 0.5 + float(i) * 0.12, 6.0 - float(i))
	faisca(pos, cor, 40, 600.0)

func coleta(pos: Vector2, cor: Color) -> void:
	faisca(pos, cor, 3, 70.0)

## ---------------------------------------------------------------- update

func atualizar(dt: float) -> void:
	for p in pool:
		if not bool(p["ativo"]):
			continue
		p["vida"] = float(p["vida"]) - dt
		if float(p["vida"]) <= 0.0:
			p["ativo"] = false
			livres.append(p)
			continue
		var tipo := str(p["tipo"])
		if tipo == "anel" or tipo == "raio" or tipo == "feixe":
			continue
		var v: Vector2 = p["vel"]
		v.y += float(p.get("grav", 0.0)) * dt
		v *= pow(maxf(0.02, 1.0 - float(p.get("atrito", 1.0)) * 0.5), dt * 2.0)
		p["vel"] = v
		p["pos"] = (p["pos"] as Vector2) + v * dt
		if p.has("giro"):
			p["ang"] = float(p["ang"]) + float(p["giro"]) * dt

## --------------------------------------------------------------- desenho

func desenhar(ci: CanvasItem) -> void:
	for p in pool:
		if not bool(p["ativo"]):
			continue
		var k := clampf(float(p["vida"]) / maxf(0.001, float(p["vida_max"])), 0.0, 1.0)
		var cor: Color = p["cor"]
		match str(p["tipo"]):
			"faisca":
				ci.draw_circle(p["pos"], float(p["r"]) * k, Color(cor.r, cor.g, cor.b, cor.a * k))
			"fumaca":
				ci.draw_circle(p["pos"], float(p["r"]) * (1.4 - k * 0.4), Color(cor.r, cor.g, cor.b, cor.a * k * 0.35))
			"anel":
				var t := 1.0 - k
				var raio := float(p["r"]) * Ux.ease_out_cubic(t)
				ci.draw_arc(p["pos"], maxf(1.0, raio), 0, TAU, 40, Color(cor.r, cor.g, cor.b, cor.a * k), float(p.get("esp", 3.0)) * k, true)
			"estilhaco":
				var a := float(p.get("ang", 0.0))
				var r := float(p["r"]) * k
				var pos: Vector2 = p["pos"]
				ci.draw_colored_polygon(PackedVector2Array([
					pos + Vector2(cos(a), sin(a)) * r,
					pos + Vector2(cos(a + 2.2), sin(a + 2.2)) * r * 0.7,
					pos + Vector2(cos(a - 2.2), sin(a - 2.2)) * r * 0.7,
				]), Color(cor.r, cor.g, cor.b, cor.a * k))
			"raio":
				var pts: Array = p["pontos"]
				for i in range(pts.size() - 1):
					_zigzag(ci, pts[i], pts[i + 1], Color(cor.r, cor.g, cor.b, cor.a * k), 2.5 * k)
			"feixe":
				ci.draw_line(p["pos"], p["para"], Color(cor.r, cor.g, cor.b, cor.a * k), 2.2 * k, true)

func _zigzag(ci: CanvasItem, a: Vector2, b: Vector2, cor: Color, largura: float) -> void:
	var n := 5
	var pts := PackedVector2Array()
	var d := b - a
	var perp := Vector2(-d.y, d.x).normalized()
	for i in n + 1:
		var f := float(i) / float(n)
		var desvio := 0.0 if i == 0 or i == n else rng.entre(-9.0, 9.0)
		pts.append(a + d * f + perp * desvio)
	ci.draw_polyline(pts, cor, maxf(1.0, largura), true)
