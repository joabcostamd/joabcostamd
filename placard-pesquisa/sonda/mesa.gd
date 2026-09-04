extends RefCounted
class_name Mesa

# RNG proprio: xorshift64* semeado (R34 - nada de randi global)
class Rng extends RefCounted:
	var s: int
	func _init(semente: int) -> void:
		s = semente if semente != 0 else 0x1E3779B97F4A7C15
		for i in range(4): _n()
	func _n() -> int:
		s ^= (s << 13) & 0x7FFFFFFFFFFFFFFF
		s ^= (s >> 7)
		s ^= (s << 17) & 0x7FFFFFFFFFFFFFFF
		s &= 0x7FFFFFFFFFFFFFFF
		return s
	func inteiro(n: int) -> int:
		if n <= 1: return 0
		return _n() % n
	func real() -> float:
		return float(_n() % 1000000) / 1000000.0

static func mix(a: int, b: int, c: int) -> int:
	var x := (a * 1000003 + b * 2654435761 + c * 40503) & 0x7FFFFFFFFFFFFFFF
	x ^= (x >> 31)
	x = (x * 0x27220A95) & 0x7FFFFFFFFFFFFFFF
	x ^= (x >> 29)
	return x

# ---------------------------- estado da mesa -------------------------------
var grade := PackedInt32Array()
var conta := PackedInt32Array()      # cartas por linha viva (12)
var mao := []
var baralho := []
var descarte := []
var colhida := []
var tear := 0
var pontos := 0
var meta := 0
var rodada := 1
var tipo := 0                         # 0 pequena, 1 grande, 2 chefe
var posic_max := 15
var posic_usados := 0
var descartes_max := 2
var descartes_usados := 0
var teto := 28
var tam_mao := 5
var niveis := []                      # niveis de mao por categoria (proxy opcional)
var rng: Rng
var rng_sem: Rng

const METAS := {
	0: [450, 639, 907, 1288, 1830, 2598],
	1: [675, 959, 1361, 1932, 2745, 3897],
	2: [1035, 1470, 2086, 2962, 4209, 5975],
}

func _init(p_rodada: int, p_tipo: int, semente: int, p_niveis: Array = []) -> void:
	Nucleo.init_estatico()
	rodada = p_rodada
	tipo = p_tipo
	meta = METAS[p_tipo][p_rodada - 1]
	posic_max = [15, 17, 19][p_tipo]
	descartes_max = [2, 3, 3][p_tipo]
	teto = 24 + 4 * p_rodada
	niveis = p_niveis if p_niveis.size() == 11 else [0,0,0,0,0,0,0,0,0,0,0]
	rng = Rng.new(mix(semente, p_rodada * 10 + p_tipo, 1))
	rng_sem = Rng.new(mix(semente, p_rodada * 10 + p_tipo, 77))
	grade.resize(25); grade.fill(-1)
	conta.resize(12); conta.fill(0)
	if semente == -1:
		return   # modo clone: sem baralho, sem semeadura
	# baralho 52 embaralhado (Fisher-Yates com rng proprio)
	baralho = []
	for i in range(52): baralho.append(i)
	for i in range(51, 0, -1):
		var j := rng.inteiro(i + 1)
		var t = baralho[i]; baralho[i] = baralho[j]; baralho[j] = t
	# R42: mesa Pequena nasce com 3 cartas semeadas
	if p_tipo == 0:
		for k in range(3):
			var vazias := []
			for c in range(25):
				if grade[c] == -1: vazias.append(c)
			var casa: int = vazias[rng_sem.inteiro(vazias.size())]
			var carta: int = baralho.pop_back()
			_por_carta(casa, carta)
	for k in range(tam_mao):
		var c := _comprar()
		if c >= 0: mao.append(c)

func _comprar() -> int:
	if baralho.is_empty():
		if descarte.is_empty():
			return -1
		baralho = descarte.duplicate()
		descarte = []
		for i in range(baralho.size() - 1, 0, -1):
			var j := rng.inteiro(i + 1)
			var t = baralho[i]; baralho[i] = baralho[j]; baralho[j] = t
	return baralho.pop_back()

func _por_carta(casa: int, carta: int) -> void:
	grade[casa] = carta
	for li in Nucleo.CELL_LINHAS[casa]:
		conta[li] += 1

func _tirar_carta(casa: int) -> void:
	if grade[casa] < 0: return
	colhida.append(grade[casa])
	grade[casa] = -1
	for li in Nucleo.CELL_LINHAS[casa]:
		conta[li] -= 1

func base_de(cat: int) -> int:
	var passo: int = int(max(Nucleo.CAT_BASE[cat] * 0.35, 8))
	return Nucleo.CAT_BASE[cat] + niveis[cat] * passo

func mult_de(cat: int) -> int:
	return Nucleo.CAT_MULT[cat] + niveis[cat]

# ------------------ ganho imediato de um posicionamento --------------------
# Devolve [pontos, n_linhas_fechadas]. Nao muta nada.
func ganho(casa: int, carta: int) -> Array:
	var fecha := []
	for li in Nucleo.CELL_LINHAS[casa]:
		if conta[li] == 4:
			fecha.append(li)
	if fecha.is_empty():
		return [0, 0]
	var soma_mult := 0
	var parcelas := []
	for li in fecha:
		var L = Nucleo.LINHAS[li]
		var cc := []
		for c in L:
			cc.append(carta if c == casa else grade[c])
		var r := Nucleo.avaliar5(cc[0], cc[1], cc[2], cc[3], cc[4])
		var cat: int = r[0]
		var fichas: int = base_de(cat) + int(r[1])
		soma_mult += mult_de(cat)
		parcelas.append([fichas, Nucleo.DIAG[li]])
	var mult_ef: int = min(teto, soma_mult + tear)
	var total := 0
	for p in parcelas:
		if p[1]:
			total += int(floor(float(p[0]) * float(mult_ef) * 0.6))
		else:
			total += p[0] * mult_ef
	return [total, fecha.size()]

# ------------------------ posicionamento efetivo ---------------------------
# Devolve [pontos, n_linhas_fechadas]
func posicionar(indice_mao: int, casa: int) -> Array:
	var carta: int = mao[indice_mao]
	var g := ganho(casa, carta)
	_por_carta(casa, carta)
	mao.remove_at(indice_mao)
	posic_usados += 1
	if g[1] > 0:
		pontos += g[0]
		# remocao (R11/R17)
		var fechadas := []
		for li in Nucleo.CELL_LINHAS[casa]:
			if conta[li] == 5:
				fechadas.append(li)
		var remover := {}
		for li in fechadas:
			for c in Nucleo.LINHAS[li]:
				remover[c] = true
		for c in remover.keys():
			_tirar_carta(c)
		tear = min(8, tear + g[1])   # R39: +1 por linha colhida, teto 8
	var nova := _comprar()
	if nova >= 0: mao.append(nova)
	return g

func trocar(indices: Array) -> void:
	indices.sort()
	indices.reverse()
	for i in indices:
		descarte.append(mao[i])
		mao.remove_at(i)
	descartes_usados += 1
	while mao.size() < tam_mao:
		var c := _comprar()
		if c < 0: break
		mao.append(c)

# ------------------------ colheita final (R14b) ----------------------------
func colheita_final() -> int:
	var total := 0
	for li in range(12):
		if conta[li] < 3:
			continue
		var cc := []
		for c in Nucleo.LINHAS[li]:
			if grade[c] >= 0: cc.append(grade[c])
		var r := Nucleo.avaliar_parcial(cc)
		var cat: int = r[0]
		var fichas: int = base_de(cat) + int(r[1])
		var v := float(fichas) * float(mult_de(cat) + tear) * 0.5
		if Nucleo.DIAG[li]:
			v *= 0.6
		total += int(floor(v))
	pontos += total
	return total

func casas_vazias() -> Array:
	var v := []
	for c in range(25):
		if grade[c] == -1: v.append(c)
	return v

# casas que podem fechar alguma linha agora (unica fonte de ganho > 0)
func casas_criticas() -> Array:
	var s := {}
	for li in range(12):
		if conta[li] == 4:
			for c in Nucleo.LINHAS[li]:
				if grade[c] == -1: s[c] = true
	return s.keys()

func restantes() -> int:
	return baralho.size() + descarte.size()

# ------------------ clone leve para a busca profunda -----------------------
func clone_leve() -> Mesa:
	var c := Mesa.new(rodada, tipo, -1, niveis)
	c.grade = grade.duplicate()
	c.conta = conta.duplicate()
	c.tear = tear
	c.teto = teto
	c.pontos = pontos
	c.mao = []
	c.baralho = []
	c.descarte = []
	c.colhida = []
	return c

# aplica um posicionamento sem mexer em mao/baralho (para simulacao)
func aplicar_seco(casa: int, carta: int) -> Array:
	var g := ganho(casa, carta)
	_por_carta(casa, carta)
	posic_usados += 1
	if g[1] > 0:
		pontos += g[0]
		var fechadas := []
		for li in Nucleo.CELL_LINHAS[casa]:
			if conta[li] == 5:
				fechadas.append(li)
		var remover := {}
		for li in fechadas:
			for c in Nucleo.LINHAS[li]:
				remover[c] = true
		for c in remover.keys():
			_tirar_carta(c)
		tear = min(8, tear + g[1])
	return g
