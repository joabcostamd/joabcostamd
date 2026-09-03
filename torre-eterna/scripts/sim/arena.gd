class_name Arena
extends RefCounted

## O campo de batalha: pools de entidades, grade espacial e seleção de alvos.

const CELULA := 72.0
## Maior raio de inimigo do conteúdo. Serve para o teste de colisão saber quantas
## células precisa olhar sem consultar cada inimigo antes.
const RAIO_INIMIGO_MAX := 34.0

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
var _celulas_usadas: Array[int] = []
var _buffer: Array[Inimigo] = []
var vivos := 0
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

## Remoção O(1): troca com o último. Seguro em laço reverso, e evita o
## remove_at() que era O(n) — com 500 inimigos isso virava O(n²) por frame.
func soltar_inimigo(i: int) -> void:
	var e := inimigos[i]
	var ultimo := inimigos.size() - 1
	if i != ultimo:
		inimigos[i] = inimigos[ultimo]
	inimigos.remove_at(ultimo)
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
	var ultimo := projeteis.size() - 1
	if i != ultimo:
		projeteis[i] = projeteis[ultimo]
	projeteis.remove_at(ultimo)
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
	var ultimo := coletaveis.size() - 1
	if i != ultimo:
		coletaveis[i] = coletaveis[ultimo]
	coletaveis.remove_at(ultimo)
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
	_celulas_usadas.clear()
	vivos = 0

func limpar_inimigos() -> void:
	for i in range(inimigos.size() - 1, -1, -1):
		soltar_inimigo(i)
	for i in range(projeteis.size() - 1, -1, -1):
		if projeteis[i].origem == "inimigo":
			soltar_projetil(i)

## -------------------------------------------------------------- grade

## Reconstrói a grade reaproveitando os arrays já alocados: limpar é barato,
## realocar 500 arrays por frame não é.
func reconstruir_grade() -> void:
	for k in _celulas_usadas:
		var c: Array = _grade[k]
		c.clear()
	_celulas_usadas.clear()
	vivos = 0
	for e in inimigos:
		if not e.vivo():
			continue
		vivos += 1
		var k := _chave(e.pos)
		if _grade.has(k):
			var celula: Array = _grade[k]
			if celula.is_empty():
				_celulas_usadas.append(k)
			celula.append(e)
		else:
			_grade[k] = [e]
			_celulas_usadas.append(k)

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

## O PRIMEIRO inimigo que colide com um círculo, sem montar lista nenhuma.
##
## `em_area` preenche um buffer com TODOS os vizinhos e quem chama percorre de
## novo para achar o primeiro que encosta — duas passadas e uma medida de
## distância repetida, por projétil, por quadro. Com 800 projéteis vivos (o teto
## do pool) isso era o maior custo do jogo: 39,8 ms só de projéteis no runner do
## CI, dez vezes o orçamento inteiro do quadro. Aqui a resposta sai na primeira
## colisão e o buffer não é tocado.
func primeiro_colidindo(pos: Vector2, raio: float, ignorar: Dictionary) -> Inimigo:
	var alcance := raio + RAIO_INIMIGO_MAX
	var cx0 := int(floor((pos.x - alcance) / CELULA))
	var cy0 := int(floor((pos.y - alcance) / CELULA))
	var cx1 := int(floor((pos.x + alcance) / CELULA))
	var cy1 := int(floor((pos.y + alcance) / CELULA))
	var px := pos.x
	var py := pos.y
	for cx in range(cx0, cx1 + 1):
		var base := cx * 4096
		for cy in range(cy0, cy1 + 1):
			var k := base + cy
			if not _grade.has(k):
				continue
			for item in _grade[k]:
				var e: Inimigo = item
				if e.intangivel > 0.0 or ignorar.has(e.id) or not e.vivo():
					continue
				var dx := e.pos.x - px
				var dy := e.pos.y - py
				var rr := e.raio + raio
				if dx * dx + dy * dy <= rr * rr:
					return e
	return null

## ------------------------------------------------------------ seleção

## modo: "proximo" | "longe" | "forte" | "fraco" | "chefe" | "avancado"
## Os modos como número. Comparar String dentro de um laço que roda uma vez por
## inimigo, várias vezes por quadro, é caro em GDScript — e o modo é o mesmo
## para a varredura inteira, então ele é resolvido UMA vez, aqui fora.
const M_PROXIMO := 0
const M_LONGE := 1
const M_FORTE := 2
const M_FRACO := 3
const M_CHEFE := 4

static func _modo_num(modo: String) -> int:
	match modo:
		"longe": return M_LONGE
		"forte": return M_FORTE
		"fraco": return M_FRACO
		"chefe": return M_CHEFE
	return M_PROXIMO

func alvo(origem: Vector2, alcance: float, modo: String = "proximo", excluir: Array = []) -> Inimigo:
	var melhor: Inimigo = null
	var melhor_score := -INF
	var a2 := alcance * alcance
	var m := _modo_num(modo)
	var tem_excluir := not excluir.is_empty()
	var ox := origem.x
	var oy := origem.y
	for e in inimigos:
		if not e.vivo() or e.intangivel > 0.0:
			continue
		if tem_excluir and excluir.has(e):
			continue
		var dx := e.pos.x - ox
		var dy := e.pos.y - oy
		var d2 := dx * dx + dy * dy
		if d2 > a2:
			continue
		var score := -d2
		if m != M_PROXIMO:
			match m:
				M_LONGE: score = d2
				M_FORTE: score = e.hp
				M_FRACO: score = -e.hp
				M_CHEFE: score = (1.0e6 if e.chefe else 0.0) + (1000.0 if e.elite else 0.0) - d2 * 1e-4
		if score > melhor_score:
			melhor_score = score
			melhor = e
	return melhor

## O inimigo vivo mais próximo DENTRO de um raio, usando a grade.
##
## `alvo()` varre a lista inteira, o que é o certo para a torre (o alcance dela
## cobre boa parte da arena). Para quem tem alcance curto — os orbes, com 150px
## — varrer 160 inimigos para achar um que está a dois passos é desperdício, e
## era feito por CADA orbe, TODO quadro: quando não havia ninguém perto, o orbe
## nem reiniciava o relógio, então repetia a varredura no quadro seguinte. Com
## 19 orbes eram 19 varreduras completas por quadro sem nenhum efeito.
func alvo_no_raio(origem: Vector2, raio: float, excluir: Array = []) -> Inimigo:
	var melhor: Inimigo = null
	var melhor_d := raio * raio
	var tem_ex := not excluir.is_empty()
	for e in em_area(origem, raio):
		if not e.vivo() or e.intangivel > 0.0:
			continue
		if tem_ex and excluir.has(e):
			continue
		var dx := e.pos.x - origem.x
		var dy := e.pos.y - origem.y
		var d2 := dx * dx + dy * dy
		if d2 < melhor_d:
			melhor_d = d2
			melhor = e
	return melhor

## O inimigo vivo mais próximo de `origem` dentro de `alcance`, ignorando os
## ids que já foram atingidos por este projétil.
##
## Esta é a busca mais quente do jogo: cada impacto de perfuração e cada
## ricochete faz uma. A versão anterior varria a lista `inimigos` INTEIRA e não
## encostava na grade — o comentário dela dizia "O(1)" falando do filtro de ids
## e escondia que a varredura era O(n) sobre todos os vivos. Com 193 inimigos e
## centenas de impactos por passo isso custava 24 ms de simulação por quadro e
## reprovou o portão de desempenho.
##
## Agora a busca anda em anéis de células a partir da origem e PARA no primeiro
## anel que já não pode conter ninguém mais perto que o melhor achado: qualquer
## ponto de uma célula a `k` células de distância está a pelo menos
## `(k-1) * CELULA` da origem, então quando o melhor já é mais perto que isso,
## não há o que procurar adiante. O inimigo devolvido é o mesmo de antes; só o
## caminho até ele encurtou.
func alvo_ids(origem: Vector2, alcance: float, ids: Dictionary) -> Inimigo:
	var melhor: Inimigo = null
	var melhor_d := alcance * alcance
	var ox2 := origem.x
	var oy2 := origem.y
	var c0x := int(floor(ox2 / CELULA))
	var c0y := int(floor(oy2 / CELULA))
	var max_anel := int(ceil(alcance / CELULA))
	for anel in range(max_anel + 1):
		if melhor != null:
			var piso := float(anel - 1) * CELULA
			if piso > 0.0 and melhor_d <= piso * piso:
				break
		for cx in range(c0x - anel, c0x + anel + 1):
			var borda_x := absi(cx - c0x) == anel
			var base := cx * 4096
			for cy in range(c0y - anel, c0y + anel + 1):
				# Só a casca do anel: o miolo já foi varrido nos anéis de dentro.
				if not borda_x and absi(cy - c0y) != anel:
					continue
				var k := base + cy
				if not _grade.has(k):
					continue
				for item in _grade[k]:
					var e: Inimigo = item
					if not e.vivo() or e.intangivel > 0.0 or ids.has(e.id):
						continue
					var ddx := e.pos.x - ox2
					var ddy := e.pos.y - oy2
					var d2 := ddx * ddx + ddy * ddy
					if d2 < melhor_d:
						melhor_d = d2
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

## Contagem viva do frame atual (atualizada em reconstruir_grade).
## Antes isso varria a lista inteira a cada abate — O(n²) numa onda cheia.
func contagem_viva() -> int:
	return vivos

## Contagem viva AGORA, varrendo de verdade. Só para quem não pode conviver
## com um quadro de atraso: o diretor fecha a onda com base nisto e, com o
## número em cache, um inimigo que nasceu neste mesmo quadro ficava de fora da
## conta — a onda fechava com ele vivo e ele vazava para a onda seguinte.
func contagem_viva_agora() -> int:
	var n := 0
	for e in inimigos:
		if e.vivo():
			n += 1
	return n
