class_name Arena
extends RefCounted

## O campo de batalha: pools de entidades, grade espacial e seleção de alvos.

const CELULA := 72.0

var largura := 1280.0
var altura := 720.0
var centro := Vector2(640, 360)

var inimigos: Array[Inimigo] = []
var projeteis: Array[Projetil] = []
var coletaveis: Array[Coletavel] = []

var _livres_i: Array[Inimigo] = []
var _livres_p: Array[Projetil] = []
var _livres_c: Array[Coletavel] = []

var max_inimigos := 500
var max_projeteis := 800
var max_coletaveis := 350

var _grade := {}
var _buffer: Array[Inimigo] = []
var _proximo_id := 1

func _init() -> void:
	for i in 96:
		_livres_i.append(Inimigo.new())
	for i in 128:
		_livres_p.append(Projetil.new())
	for i in 64:
		_livres_c.append(Coletavel.new())

func redimensionar(w: float, h: float) -> void:
	largura = w
	altura = h
	centro = Vector2(w * 0.5, h * 0.5)

## ------------------------------------------------------------------ pools

func novo_inimigo() -> Inimigo:
	var e: Inimigo
	if not _livres_i.is_empty():
		e = _livres_i.pop_back()
	elif inimigos.size() >= max_inimigos:
		# recicla o mais antigo que não seja chefe
		var idx := -1
		for i in inimigos.size():
			if not inimigos[i].chefe:
				idx = i
				break
		if idx < 0:
			return null
		e = inimigos[idx]
		inimigos.remove_at(idx)
		e.limpar()
	else:
		e = Inimigo.new()
	e.limpar()
	e.id = _proximo_id
	_proximo_id += 1
	inimigos.append(e)
	return e

func soltar_inimigo(i: int) -> void:
	var e := inimigos[i]
	inimigos.remove_at(i)
	e.limpar()
	if _livres_i.size() < 256:
		_livres_i.append(e)

func novo_projetil() -> Projetil:
	var p: Projetil
	if not _livres_p.is_empty():
		p = _livres_p.pop_back()
	elif projeteis.size() >= max_projeteis:
		p = projeteis[0]
		projeteis.remove_at(0)
		p.limpar()
	else:
		p = Projetil.new()
	p.limpar()
	projeteis.append(p)
	return p

func soltar_projetil(i: int) -> void:
	var p := projeteis[i]
	projeteis.remove_at(i)
	p.limpar()
	if _livres_p.size() < 320:
		_livres_p.append(p)

func novo_coletavel() -> Coletavel:
	var c: Coletavel
	if not _livres_c.is_empty():
		c = _livres_c.pop_back()
	elif coletaveis.size() >= max_coletaveis:
		c = coletaveis[0]
		coletaveis.remove_at(0)
		c.limpar()
	else:
		c = Coletavel.new()
	c.limpar()
	coletaveis.append(c)
	return c

func soltar_coletavel(i: int) -> void:
	var c := coletaveis[i]
	coletaveis.remove_at(i)
	c.limpar()
	if _livres_c.size() < 160:
		_livres_c.append(c)

func limpar_tudo() -> void:
	while not inimigos.is_empty():
		soltar_inimigo(inimigos.size() - 1)
	while not projeteis.is_empty():
		soltar_projetil(projeteis.size() - 1)
	while not coletaveis.is_empty():
		soltar_coletavel(coletaveis.size() - 1)
	_grade.clear()

func limpar_inimigos() -> void:
	for i in range(inimigos.size() - 1, -1, -1):
		soltar_inimigo(i)
	for i in range(projeteis.size() - 1, -1, -1):
		if projeteis[i].origem == "inimigo":
			soltar_projetil(i)

## -------------------------------------------------------------- grade

func reconstruir_grade() -> void:
	_grade.clear()
	for e in inimigos:
		if not e.vivo():
			continue
		var k := _chave(e.pos)
		if _grade.has(k):
			var celula: Array = _grade[k]
			celula.append(e)
		else:
			_grade[k] = [e]

func _chave(p: Vector2) -> int:
	return int(floor(p.x / CELULA)) * 4096 + int(floor(p.y / CELULA))

## Inimigos dentro de um raio (usa buffer interno — copie se for guardar).
func em_area(p: Vector2, raio: float) -> Array[Inimigo]:
	_buffer.clear()
	var c0 := Vector2i(int(floor((p.x - raio) / CELULA)), int(floor((p.y - raio) / CELULA)))
	var c1 := Vector2i(int(floor((p.x + raio) / CELULA)), int(floor((p.y + raio) / CELULA)))
	var r2 := raio * raio
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var k := cx * 4096 + cy
			if not _grade.has(k):
				continue
			var celula: Array = _grade[k]
			for item in celula:
				var e: Inimigo = item
				var d: float = (e.pos - p).length_squared()
				if d <= r2 + e.raio * e.raio:
					_buffer.append(e)
	return _buffer

## ------------------------------------------------------------ seleção

## modo: "proximo" | "longe" | "forte" | "fraco" | "chefe" | "avancado"
func alvo(origem: Vector2, alcance: float, modo: String = "proximo", excluir: Array = []) -> Inimigo:
	var melhor: Inimigo = null
	var melhor_score := -INF
	var a2 := alcance * alcance
	for e in inimigos:
		if not e.vivo() or e.intangivel > 0.0:
			continue
		if not excluir.is_empty() and excluir.has(e):
			continue
		var d2 := (e.pos - origem).length_squared()
		if d2 > a2:
			continue
		var score := 0.0
		match modo:
			"longe": score = d2
			"forte": score = e.hp
			"fraco": score = -e.hp
			"chefe": score = (1.0e6 if e.chefe else 0.0) + (1000.0 if e.elite else 0.0) - d2 * 1e-4
			_: score = -d2
		if score > melhor_score:
			melhor_score = score
			melhor = e
	return melhor

## Ponto de nascimento logo fora da borda visível — a ação acontece na tela,
## não a 800px de distância.
func ponto_spawn(r: RngX, margem: float = 46.0) -> Vector2:
	var w := largura + margem * 2.0
	var h := altura + margem * 2.0
	var perimetro := (w + h) * 2.0
	var d := r.f() * perimetro
	if d < w:
		return Vector2(-margem + d, -margem)
	d -= w
	if d < h:
		return Vector2(largura + margem, -margem + d)
	d -= h
	if d < w:
		return Vector2(largura + margem - d, altura + margem)
	d -= w
	return Vector2(-margem, altura + margem - d)

func fora_da_arena(p: Vector2, margem: float = 140.0) -> bool:
	return p.x < -margem or p.y < -margem or p.x > largura + margem or p.y > altura + margem

func contagem_viva() -> int:
	var n := 0
	for e in inimigos:
		if e.vivo():
			n += 1
	return n
