extends RefCounted
class_name Nucleo

# ---------------------------------------------------------------------------
# SONDA CRUZADA - nucleo descartavel. Secoes 4, 5 e 6 do PROMPT-JOGO-DE-CARTAS.md
# ---------------------------------------------------------------------------

# Categorias (5.1) - ordem normativa
const ALTA := 0
const PAR := 1
const DOIS_PARES := 2
const TRINCA := 3
const SEQUENCIA := 4
const FLUSH := 5
const FULL := 6
const QUADRA := 7
const SEQ_COR := 8
const REAL := 9
const QUINA := 10

const CAT_BASE := [5, 10, 20, 30, 30, 35, 40, 60, 100, 120, 140]
const CAT_MULT := [1, 2, 2, 3, 4, 4, 4, 7, 8, 10, 12]

# 12 linhas vivas: 5 horizontais, 5 verticais, 2 diagonais (R03/R03b)
const LINHAS := [
	[0,1,2,3,4],[5,6,7,8,9],[10,11,12,13,14],[15,16,17,18,19],[20,21,22,23,24],
	[0,5,10,15,20],[1,6,11,16,21],[2,7,12,17,22],[3,8,13,18,23],[4,9,14,19,24],
	[0,6,12,18,24],[4,8,12,16,20]
]
const DIAG := [false,false,false,false,false,false,false,false,false,false,true,true]

static var CELL_LINHAS := []

static func init_estatico() -> void:
	if CELL_LINHAS.size() == 25:
		return
	CELL_LINHAS = []
	for c in range(25):
		var l := []
		for li in range(12):
			if LINHAS[li].has(c):
				l.append(li)
		CELL_LINHAS.append(l)

# --------------------------- fichas da carta (R05) -------------------------
static func fichas_carta(carta: int) -> int:
	var v := carta % 13   # 0 = As, 1..8 = 2..9, 9 = 10, 10..12 = J,Q,K
	if v == 0:
		return 11
	if v <= 9:
		return v + 1
	return 10

static func valor(carta: int) -> int:
	return carta % 13

static func naipe(carta: int) -> int:
	return carta / 13

# --------------------------- avaliador de 5 cartas -------------------------
# devolve [categoria, fichas_das_cartas]
static var _vc := PackedInt32Array()
static var _sc := PackedInt32Array()

static func avaliar5(c0: int, c1: int, c2: int, c3: int, c4: int) -> Array:
	if _vc.size() != 13:
		_vc.resize(13); _sc.resize(4)
	for i in range(13): _vc[i] = 0
	for i in range(4): _sc[i] = 0
	var fichas := 0
	var cs := [c0, c1, c2, c3, c4]
	var mask := 0
	for c in cs:
		var v: int = c % 13
		_vc[v] += 1
		_sc[c / 13] += 1
		mask |= 1 << v
		fichas += fichas_carta(c)
	var flush := false
	for s in range(4):
		if _sc[s] == 5:
			flush = true
			break
	# contagens
	var c_max := 0
	var pares := 0
	var trinca := false
	for v in range(13):
		var n: int = _vc[v]
		if n > c_max: c_max = n
		if n == 2: pares += 1
		if n == 3: trinca = true
	# sequencia (R18)
	var seq := false
	var royal := false
	if _popcount(mask) == 5:
		# 10-J-Q-K-A : valores 9,10,11,12,0
		if mask == ((1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | 1):
			seq = true
			royal = true
		else:
			for st in range(0, 9):
				var w := 0
				for k in range(5):
					w |= 1 << (st + k)
				if mask == w:
					seq = true
					break
	var cat := ALTA
	if c_max == 5:
		cat = QUINA
	elif flush and seq and royal:
		cat = REAL
	elif flush and seq:
		cat = SEQ_COR
	elif c_max == 4:
		cat = QUADRA
	elif trinca and pares == 1:
		cat = FULL
	elif flush:
		cat = FLUSH
	elif seq:
		cat = SEQUENCIA
	elif trinca:
		cat = TRINCA
	elif pares == 2:
		cat = DOIS_PARES
	elif pares == 1:
		cat = PAR
	return [cat, fichas]

static func _popcount(x: int) -> int:
	var n := 0
	while x != 0:
		n += x & 1
		x >>= 1
	return n

# Melhor categoria GARANTIDA com k<5 cartas presentes (R14b / 5.2)
# Escolha da sonda: com menos de 5 cartas so categorias por valor sao garantidas.
static func avaliar_parcial(cartas: Array) -> Array:
	var k := cartas.size()
	if k == 5:
		return avaliar5(cartas[0], cartas[1], cartas[2], cartas[3], cartas[4])
	if _vc.size() != 13:
		_vc.resize(13); _sc.resize(4)
	for i in range(13): _vc[i] = 0
	var fichas := 0
	for c in cartas:
		_vc[c % 13] += 1
		fichas += fichas_carta(c)
	var c_max := 0
	var pares := 0
	var trinca := false
	for v in range(13):
		var n: int = _vc[v]
		if n > c_max: c_max = n
		if n == 2: pares += 1
		if n >= 3: trinca = true
	var cat := ALTA
	if c_max >= 4:
		cat = QUADRA
	elif trinca:
		cat = TRINCA
	elif pares >= 2:
		cat = DOIS_PARES
	elif pares == 1:
		cat = PAR
	return [cat, fichas]

# Melhor categoria ALCANCAVEL (heuristica p/ potencial da linha)
static func melhor_alcancavel(cartas: Array) -> int:
	var k := cartas.size()
	var livres := 5 - k
	if k == 0:
		return SEQ_COR
	if _vc.size() != 13:
		_vc.resize(13); _sc.resize(4)
	for i in range(13): _vc[i] = 0
	for i in range(4): _sc[i] = 0
	var mask := 0
	for c in cartas:
		_vc[c % 13] += 1
		_sc[c / 13] += 1
		mask |= 1 << (c % 13)
	var mesmo_naipe := false
	for s in range(4):
		if _sc[s] == k:
			mesmo_naipe = true
			break
	var distintos := _popcount(mask)
	var sem_dup := (distintos == k)
	# sequencia possivel: todos distintos e cabem numa janela de 5
	var seq_ok := false
	var royal_ok := false
	if sem_dup:
		var royal_mask := (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | 1
		if (mask & ~royal_mask) == 0:
			seq_ok = true
			royal_ok = true
		if not seq_ok:
			for st in range(0, 9):
				var w := 0
				for j in range(5):
					w |= 1 << (st + j)
				if (mask & ~w) == 0:
					seq_ok = true
					break
	var c1 := 0
	var c2 := 0
	for v in range(13):
		var n: int = _vc[v]
		if n > c1:
			c2 = c1; c1 = n
		elif n > c2:
			c2 = n
	if mesmo_naipe and royal_ok:
		return REAL
	if mesmo_naipe and seq_ok:
		return SEQ_COR
	if c1 + livres >= 4:
		return QUADRA
	if distintos <= 2 and c1 <= 3 and c2 <= 2:
		return FULL
	if mesmo_naipe:
		return FLUSH
	if seq_ok:
		return SEQUENCIA
	if c1 + livres >= 3:
		return TRINCA
	# dois pares
	var deficit: int = (2 - c1) + (2 - int(min(c2, 2)))
	if c1 >= 2 and c2 >= 2:
		return DOIS_PARES
	if deficit <= livres and distintos >= 1:
		return DOIS_PARES
	if c1 >= 2 or livres >= 1:
		return PAR
	return ALTA
