extends RefCounted
class_name Mesa2

# =============================================================================
# BANCADA 1 - motor estendido: nucleo + PULSO + TIQUE DO TEAR + AGULHA + AVESSO
# Reaproveita Nucleo (avaliador de 5 cartas 0..51) sem alterar uma linha dele.
# =============================================================================

const AGULHA_BASE := 100      # 100+k = agulha viva
const AVESSO_BASE := 1024     # 1024 + (direito<<6) + avesso
const VAZIA := -1

# ordem das 12 linhas do Nucleo: 5 horizontais, 5 verticais, 2 diagonais
const HORIZ := [true,true,true,true,true, false,false,false,false,false, false,false]

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

static func mix(a: int, b: int, c: int) -> int:
	var x := (a * 1000003 + b * 2654435761 + c * 40503) & 0x7FFFFFFFFFFFFFFF
	x ^= (x >> 31)
	x = (x * 0x27220A95) & 0x7FFFFFFFFFFFFFFF
	x ^= (x >> 29)
	return x

# --------------------------- codificacao de carta --------------------------
static func eh_agulha(c: int) -> bool:
	return c >= AGULHA_BASE and c < AVESSO_BASE
static func eh_avesso(c: int) -> bool:
	return c >= AVESSO_BASE
static func forjar(d: int, a: int) -> int:
	return AVESSO_BASE + (d << 6) + a
static func girar(c: int) -> int:
	var d := c - AVESSO_BASE
	return AVESSO_BASE + ((d & 63) << 6) + (d >> 6)
static func face(c: int, horizontal: bool) -> int:
	if c < AVESSO_BASE: return c
	var d := c - AVESSO_BASE
	return (d >> 6) if horizontal else (d & 63)
static func n_faces(c: int) -> int:
	return 2 if c >= AVESSO_BASE else 1

# --------------------------------- estado ----------------------------------
var cfg := {}
var grade := PackedInt32Array()
var conta := PackedInt32Array()
var mao := []
var baralho := []
var descarte := []
var colhida := []
var tear := 0
var pontos := 0
var meta := 0
var rodada := 1
var tipo := 0
var posic_max := 15
var posic_usados := 0
var descartes_max := 2
var descartes_usados := 0
var teto := 28
var tam_mao := 5
var rng: Rng
var rng_sem: Rng
var pulsos_por_linha := []
# contadores de instrumentacao
var agulhas_criadas := 0
var agulhas_na_mesa := 0
var avessos_forjados := 0
var costuradas := {}          # casa -> true (agulha carimbada)
var carimbo_de := {}          # casa -> turno do carimbo
var stats := {}

const METAS := {
	0: [450, 639, 907, 1288, 1830, 2598],
	1: [675, 959, 1361, 1932, 2745, 3897],
	2: [1035, 1470, 2086, 2962, 4209, 5975],
}

static func cfg_padrao() -> Dictionary:
	return {
		"pulso_F": 0.35, "pulso_max_linha": 2, "tick_tear": 4, "tear_teto": 8,
		# AGULHA
		"agulha": false, "ag_iniciais": 1, "ag_por_colheita": 1.0, "ag_teto": 4,
		"ag_janela": 12, "ag_destino": 0,      # 0 fica carimbada, 1 evapora junto
		"ag_desempate": 0,                     # 0 maior_fichas, 1 menor_ficha_preserva_categoria
		"ag_bloqueio_diag": true, "ag_pulso_fichas": true, "ag_so_naipe": false,
		# AVESSO
		"avesso": false, "av_gatilho": 0,      # 0 toda colheita, 3 TRINCA+, 5 FLUSH+
		"av_pontas": 0,                        # 0 extremos, 1 duas maiores fichas
		"av_teto": 4,                          # 99 = sem teto
		"av_diag_face_direito": false,
	}

func _init(p_rodada: int, p_tipo: int, semente: int, p_cfg: Dictionary) -> void:
	Nucleo.init_estatico()
	cfg = p_cfg
	rodada = p_rodada
	tipo = p_tipo
	meta = METAS[p_tipo][p_rodada - 1]
	posic_max = [15, 17, 19][p_tipo]
	descartes_max = [2, 3, 3][p_tipo]
	teto = 24 + 4 * p_rodada
	pulsos_por_linha = [0,0,0,0,0,0,0,0,0,0,0,0]
	stats = {"pontos_com_coringa": 0, "pontos_total_eventos": 0,
		"heat": [], "coringas_postos": 0, "colheitas": 0, "colheitas_com_coringa": 0,
		"quinas": 0, "reais": 0, "n_eventos": 0,
		"turno_1o_achado": -1, "viu_coringa": false, "residuo_morto": 0, "carimbos": 0,
		"giros": 0, "duplo_pulso": 0, "pulsos": 0, "espera_forja_uso": [],
		"forjado_no_turno": {}, "cruz_outs_com": 0, "cruz_outs_sem": 0,
		"turnos_amostra_outs": 0, "c3_coringa": 0, "pontos_pulso": 0}
	stats["heat"].resize(25)
	for i in range(25): stats["heat"][i] = 0
	grade.resize(25); grade.fill(VAZIA)
	conta.resize(12); conta.fill(0)
	if semente == -1:
		return
	rng = Rng.new(mix(semente, p_rodada * 10 + p_tipo, 1))
	rng_sem = Rng.new(mix(semente, p_rodada * 10 + p_tipo, 77))
	baralho = []
	for i in range(52): baralho.append(i)
	for i in range(51, 0, -1):
		var j := rng.inteiro(i + 1)
		var t = baralho[i]; baralho[i] = baralho[j]; baralho[j] = t
	if p_tipo == 0:
		for k in range(3):
			var vazias := []
			for c in range(25):
				if grade[c] == VAZIA: vazias.append(c)
			var casa: int = vazias[rng_sem.inteiro(vazias.size())]
			var carta: int = baralho.pop_back()
			_por_carta(casa, carta)
	for k in range(tam_mao):
		var c := _comprar()
		if c != VAZIA: mao.append(c)
	# R44a: agulha inicial semeada na janela do topo, DEPOIS da mao inicial
	if cfg["agulha"] and cfg["ag_iniciais"] > 0:
		for k in range(int(cfg["ag_iniciais"])):
			_semear_agulha(int(cfg["ag_janela"]))

func _semear_agulha(janela: int) -> void:
	if rng_sem == null: return
	if agulhas_criadas >= int(cfg["ag_teto"]): return
	var n: int = baralho.size()
	if n == 0: return
	# topo do baralho = fim do array (pop_back)
	var j: int = janela if janela > 0 and janela < n else n
	var pos: int = n - 1 - rng_sem.inteiro(j)
	baralho.insert(pos, AGULHA_BASE + agulhas_criadas)
	agulhas_criadas += 1

func _comprar() -> int:
	if baralho.is_empty():
		if descarte.is_empty():
			return VAZIA
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

func base_de(cat: int) -> int:
	return Nucleo.CAT_BASE[cat]
func mult_de(cat: int) -> int:
	return Nucleo.CAT_MULT[cat]

# ------------------------- resolucao de faces / coringas -------------------
# devolve as cartas presentes numa linha (ja com face do Avesso resolvida).
# agulhas ficam como 100+k na lista.
func _cartas_linha(li: int, casa_ov: int, carta_ov: int) -> Array:
	var h: bool = HORIZ[li]
	if Nucleo.DIAG[li] and cfg["av_diag_face_direito"]: h = true
	var out := []
	for c in Nucleo.LINHAS[li]:
		var raw: int = carta_ov if c == casa_ov else grade[c]
		if raw == VAZIA: continue
		if raw >= AVESSO_BASE: out.append(face(raw, h))
		else: out.append(raw)
	return out

static func _pc(x: int) -> int:
	var n := 0
	while x != 0:
		n += x & 1
		x >>= 1
	return n

# candidatos de identidade para uma agulha, dadas as cartas reais da linha
func _candidatos(reais: Array) -> Array:
	if reais.is_empty():
		return [0]  # A de espadas
	var mask := 0
	var vals := {}
	for c in reais:
		vals[c % 13] = true
		mask |= 1 << (c % 13)
	var lista := []
	for v in vals.keys(): lista.append(v)
	# valores que fecham janela de sequencia faltando exatamente 1
	var janelas := []
	for st in range(0, 9):
		var w := 0
		for k in range(5): w |= 1 << (st + k)
		janelas.append(w)
	janelas.append((1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | 1)
	for w in janelas:
		if (mask & ~w) == 0 and _pc(w & ~mask) == 1:
			var falta: int = w & ~mask
			var v := 0
			while (falta >> v) & 1 == 0: v += 1
			if not lista.has(v): lista.append(v)
	if not lista.has(0): lista.append(0)
	if lista.size() > 8: lista.resize(8)
	# naipes: mais frequente + naipe da carta de maior ficha
	var cn := [0,0,0,0]
	var melhor_f := -1
	var naipe_mf := 0
	for c in reais:
		cn[c / 13] += 1
		var f := Nucleo.fichas_carta(c)
		if f > melhor_f:
			melhor_f = f; naipe_mf = c / 13
	var nmax := 0
	var naipe_top := 0
	for s in range(4):
		if cn[s] > nmax:
			nmax = cn[s]; naipe_top = s
	var naipes := [naipe_top]
	if naipe_mf != naipe_top: naipes.append(naipe_mf)
	var res := []
	for v in lista:
		for s in naipes:
			if cfg["ag_so_naipe"]:
				pass
			res.append(s * 13 + v)
	return res

# Avalia uma lista de cartas (com possiveis agulhas) resolvendo a identidade
# que MAXIMIZA o valor daquela linha isolada. Devolve [cat, fichas, id_escolhida]
func _av_linha(cs: Array) -> Array:
	var idx := -1
	for i in range(cs.size()):
		if eh_agulha(cs[i]): idx = i; break
	if idx < 0:
		var r := (Nucleo.avaliar5(cs[0], cs[1], cs[2], cs[3], cs[4]) if cs.size() == 5 else Nucleo.avaliar_parcial(cs))
		return [r[0], r[1], -1]
	var reais := []
	for i in range(cs.size()):
		if i != idx and not eh_agulha(cs[i]): reais.append(cs[i])
	var cands := _candidatos(reais)
	var bc := -1; var bf := -1; var bid := -1; var bv := -1
	var tmp := cs.duplicate()
	for cd in cands:
		tmp[idx] = cd
		var t2 := tmp.duplicate()
		for i in range(t2.size()):
			if eh_agulha(t2[i]): t2[i] = cd
		var r := (Nucleo.avaliar5(t2[0], t2[1], t2[2], t2[3], t2[4]) if t2.size() == 5 else Nucleo.avaliar_parcial(t2))
		var cat: int = r[0]
		var fic: int = r[1]
		var val: int = (base_de(cat) + fic) * mult_de(cat)
		var melhor := false
		if cfg["ag_desempate"] == 1:
			# maior categoria, depois MENOR fichas
			if cat > bc or (cat == bc and fic < bf): melhor = true
		else:
			if cat > bc or (cat == bc and val > bv): melhor = true
		if bc < 0: melhor = true
		if melhor:
			bc = cat; bf = fic; bid = cd; bv = val
	return [bc, bf, bid]

# ---------------------------- pontuacao de evento --------------------------
# fechadas: linhas que chegam a 5 com a jogada hipotetica.
# devolve {"pontos", "ids": {casa: carta}, "cats": [..], "com_coringa": bool}
func _resolver_evento(fechadas: Array, casa_ov: int, carta_ov: int) -> Dictionary:
	# casas com agulha viva participando
	var ag_casas := []
	for li in fechadas:
		for c in Nucleo.LINHAS[li]:
			var raw: int = carta_ov if c == casa_ov else grade[c]
			if eh_agulha(raw) and not ag_casas.has(c): ag_casas.append(c)
	ag_casas.sort()
	var fix := {}
	for casa_a in ag_casas:
		var reais := []
		for li in fechadas:
			if not Nucleo.LINHAS[li].has(casa_a): continue
			for c in _cartas_linha(li, casa_ov, carta_ov):
				if not eh_agulha(c): reais.append(c)
		var cands := _candidatos(reais)
		var melhor_id: int = cands[0]
		var melhor_p := -1
		var melhor_cat := -1
		var melhor_fic := 999
		for cd in cands:
			fix[casa_a] = cd
			var r := _pontos_evento(fechadas, casa_ov, carta_ov, fix)
			var p: int = r[0]
			var cat: int = r[2]
			var fic: int = r[3]
			var melhor := false
			if cfg["ag_desempate"] == 1:
				if cat > melhor_cat or (cat == melhor_cat and fic < melhor_fic): melhor = true
			else:
				if p > melhor_p: melhor = true
			if melhor_p < 0: melhor = true
			if melhor:
				melhor_p = p; melhor_id = cd; melhor_cat = cat; melhor_fic = fic
		fix[casa_a] = melhor_id
	var rr := _pontos_evento(fechadas, casa_ov, carta_ov, fix)
	return {"pontos": rr[0], "ids": fix, "cats": rr[1], "com_coringa": _evento_tem_coringa(fechadas, casa_ov, carta_ov)}

func _evento_tem_coringa(fechadas: Array, casa_ov: int, carta_ov: int) -> bool:
	for li in fechadas:
		for c in Nucleo.LINHAS[li]:
			var raw: int = carta_ov if c == casa_ov else grade[c]
			if eh_agulha(raw) or eh_avesso(raw): return true
	return false

# devolve [pontos, cats, cat_max, fichas_da_cat_max]
func _pontos_evento(fechadas: Array, casa_ov: int, carta_ov: int, fix: Dictionary) -> Array:
	var soma_mult := 0
	var parcelas := []
	var cats := []
	var cat_max := -1
	var fic_max := 0
	for li in fechadas:
		var h: bool = HORIZ[li]
		if Nucleo.DIAG[li] and cfg["av_diag_face_direito"]: h = true
		var cs := []
		for c in Nucleo.LINHAS[li]:
			var raw: int = carta_ov if c == casa_ov else grade[c]
			if raw == VAZIA: continue
			if eh_agulha(raw):
				cs.append(fix[c] if fix.has(c) else 0)
			elif raw >= AVESSO_BASE:
				cs.append(face(raw, h))
			else:
				cs.append(raw)
		if cs.size() != 5: continue
		var r := Nucleo.avaliar5(cs[0], cs[1], cs[2], cs[3], cs[4])
		var cat: int = r[0]
		cats.append(cat)
		if cat > cat_max:
			cat_max = cat; fic_max = r[1]
		var fichas: int = base_de(cat) + int(r[1])
		soma_mult += mult_de(cat)
		parcelas.append([fichas, Nucleo.DIAG[li]])
	var mult_ef: int = min(teto, soma_mult + tear)
	var total := 0
	for p in parcelas:
		if p[1]: total += int(floor(float(p[0]) * float(mult_ef) * 0.6))
		else: total += p[0] * mult_ef
	return [total, cats, cat_max, fic_max]

# ganho imediato de um posicionamento hipotetico: [pontos, n_linhas]
func ganho(casa: int, carta: int) -> Array:
	var fecha := []
	for li in Nucleo.CELL_LINHAS[casa]:
		if conta[li] == 4: fecha.append(li)
	if fecha.is_empty(): return [0, 0]
	var r := _resolver_evento(fecha, casa, carta)
	return [r["pontos"], fecha.size()]

# valor do PULSO de uma linha li supondo a carta ja colocada
func valor_pulso(li: int, casa_nova: int, carta_nova: int, F: float) -> int:
	var cs := _cartas_linha(li, casa_nova, carta_nova)
	if cs.is_empty(): return 0
	var r := _av_linha(cs)
	var cat: int = r[0]
	var fic: int = r[1]
	if cfg["agulha"] and not cfg["ag_pulso_fichas"]:
		# a agulha viva nao contribui fichas para o pulso
		for c in cs:
			if eh_agulha(c): fic -= Nucleo.fichas_carta(r[2]) if r[2] >= 0 else 0
	var v := float(base_de(cat) + fic) * float(mult_de(cat) + tear) * F
	if Nucleo.DIAG[li]: v *= 0.6
	return int(max(0.0, floor(v)))

# ------------------------------ posicionar ---------------------------------
func pode_posicionar(carta: int, casa: int) -> bool:
	if grade[casa] != VAZIA: return false
	if not eh_agulha(carta): return true
	if not cfg["agulha"]: return true
	for li in Nucleo.CELL_LINHAS[casa]:
		if Nucleo.DIAG[li] and not cfg["ag_bloqueio_diag"]: continue
		for c in Nucleo.LINHAS[li]:
			if c != casa and eh_agulha(grade[c]): return false
	return true

# devolve [pontos_evento, n_linhas, pontos_pulso]
func posicionar(carta: int, casa: int, turno: int) -> Array:
	var fecha := []
	for li in Nucleo.CELL_LINHAS[casa]:
		if conta[li] == 4: fecha.append(li)
	# pulsos candidatos (linhas que passam para 3/5 ou 4/5)
	var cand_pulso := []
	if cfg["pulso_F"] > 0.0:
		for li in Nucleo.CELL_LINHAS[casa]:
			var novo: int = conta[li] + 1
			if (novo == 3 or novo == 4) and pulsos_por_linha[li] < int(cfg["pulso_max_linha"]):
				cand_pulso.append([li, novo, valor_pulso(li, casa, carta, float(cfg["pulso_F"]))])
	var pev := 0
	var nlin := 0
	var com_cor := false
	var ids := {}
	if not fecha.is_empty():
		var r := _resolver_evento(fecha, casa, carta)
		pev = r["pontos"]; nlin = fecha.size(); com_cor = r["com_coringa"]; ids = r["ids"]
		var cats: Array = r["cats"]
		for ct in cats:
			if ct == Nucleo.QUINA: stats["quinas"] += 1
			if ct == Nucleo.REAL: stats["reais"] += 1
	# aplica
	if eh_agulha(carta) or eh_avesso(carta):
		stats["coringas_postos"] += 1
		stats["heat"][casa] += 1
		if casa == 12: stats["c3_coringa"] += 1
		if stats["forjado_no_turno"].has(carta):
			stats["espera_forja_uso"].append(turno - int(stats["forjado_no_turno"][carta]))
	_por_carta(casa, carta)
	posic_usados += 1
	if nlin > 0:
		pontos += pev
		stats["n_eventos"] += 1
		stats["pontos_total_eventos"] += pev
		if com_cor: stats["pontos_com_coringa"] += pev
		stats["colheitas"] += 1
		if com_cor: stats["colheitas_com_coringa"] += 1
		_colher(fecha, ids, turno)
		tear = min(int(cfg["tear_teto"]), tear + nlin)
	# pulsos
	var pp := 0
	var n_pulsos_agora := 0
	var cats_pulso := {}
	for x in cand_pulso:
		if conta[x[0]] == x[1]:
			pp += int(x[2]); pulsos_por_linha[x[0]] += 1; n_pulsos_agora += 1
			stats["pulsos"] += 1
			cats_pulso[x[0]] = true
	if pp > 0:
		pontos += pp
		stats["pontos_pulso"] += pp
	if n_pulsos_agora >= 2 and (eh_avesso(carta) or eh_agulha(carta)):
		stats["duplo_pulso"] += 1
	# tique do Tear
	if int(cfg["tick_tear"]) > 0 and posic_usados % int(cfg["tick_tear"]) == 0:
		tear = min(int(cfg["tear_teto"]), tear + 1)
	return [pev, nlin, pp]

func _colher(fechadas: Array, ids: Dictionary, turno: int) -> void:
	var remover := {}
	for li in fechadas:
		for c in Nucleo.LINHAS[li]:
			remover[c] = true
	# DOBRA (avesso) - antes da remocao efetiva, precisa das pontas
	var dobras := []
	var consumidas := {}
	if cfg["avesso"]:
		for li in fechadas:
			var gat: int = int(cfg["av_gatilho"])
			var cs := _cartas_linha(li, -1, -1)
			var cat := 0
			if cs.size() == 5:
				cat = int(Nucleo.avaliar5(cs[0],cs[1],cs[2],cs[3],cs[4])[0])
			if cat < gat: continue
			if int(cfg["av_teto"]) <= avessos_forjados: continue
			var h: bool = HORIZ[li]
			if Nucleo.DIAG[li] and cfg["av_diag_face_direito"]: h = true
			var i0: int = Nucleo.LINHAS[li][0]
			var i4: int = Nucleo.LINHAS[li][4]
			if int(cfg["av_pontas"]) == 1:
				# duas maiores fichas da linha
				var ord := []
				for c in Nucleo.LINHAS[li]:
					if grade[c] == VAZIA: continue
					ord.append([Nucleo.fichas_carta(face(grade[c], h)), c])
				ord.sort_custom(func(a, b): return a[0] > b[0])
				if ord.size() >= 2:
					i0 = ord[0][1]; i4 = ord[1][1]
			if grade[i0] == VAZIA or grade[i4] == VAZIA: continue
			if consumidas.has(i0) or consumidas.has(i4): continue
			if eh_agulha(grade[i0]) or eh_agulha(grade[i4]): continue
			var d: int = face(grade[i0], h)
			var a: int = face(grade[i4], h)
			# se a ponta ja era Avesso, a face NAO lida vai para colhida (conservacao)
			if eh_avesso(grade[i0]): colhida.append(face(grade[i0], not h))
			if eh_avesso(grade[i4]): colhida.append(face(grade[i4], not h))
			consumidas[i0] = true
			consumidas[i4] = true
			dobras.append([i0, i4, forjar(d, a)])
			avessos_forjados += 1
	var pontas_usadas := {}
	for d in dobras:
		pontas_usadas[d[0]] = true
		pontas_usadas[d[1]] = true
	for c in remover.keys():
		var raw: int = grade[c]
		if raw == VAZIA: continue
		if eh_agulha(raw) and cfg["agulha"] and int(cfg["ag_destino"]) == 0:
			# R44e: a agulha FICA, carimbada com a identidade escolhida
			var novo: int = ids[c] if ids.has(c) else 0
			grade[c] = novo
			costuradas[c] = true
			carimbo_de[c] = turno
			stats["carimbos"] += 1
			continue
		if not pontas_usadas.has(c):
			colhida.append(raw)
		grade[c] = VAZIA
		for li in Nucleo.CELL_LINHAS[c]:
			conta[li] -= 1
	# as pontas dobradas sairam da grade sem ir para colhida; o avesso vai ao topo
	for d in dobras:
		baralho.push_back(d[2])
		stats["forjado_no_turno"][d[2]] = turno
	# R44a: nova agulha por colheita
	if cfg["agulha"] and float(cfg["ag_por_colheita"]) > 0.0:
		var p: float = float(cfg["ag_por_colheita"])
		if p >= 1.0:
			_semear_agulha(0)
		else:
			# uma a cada 2 colheitas
			if stats["colheitas"] % 2 == 0:
				_semear_agulha(0)

func trocar(indices: Array) -> void:
	indices.sort()
	indices.reverse()
	for i in indices:
		descarte.append(mao[i])
		mao.remove_at(i)
	descartes_usados += 1
	while mao.size() < tam_mao:
		var c := _comprar()
		if c == VAZIA: break
		mao.append(c)

func comprar_mao() -> void:
	while mao.size() < tam_mao:
		var c := _comprar()
		if c == VAZIA: break
		mao.append(c)

# --------------------------- colheita final (R14b) -------------------------
func colheita_final() -> int:
	var total := 0
	for li in range(12):
		if conta[li] < 3: continue
		var cs := _cartas_linha(li, -1, -1)
		var r := _av_linha(cs)
		var cat: int = r[0]
		var fichas: int = base_de(cat) + int(r[1])
		var v := float(fichas) * float(mult_de(cat) + tear) * 0.5
		if Nucleo.DIAG[li]: v *= 0.6
		total += int(floor(v))
	pontos += total
	return total

# cartas da linha ja concretas (agulha resolvida pela identidade da linha)
func cartas_concretas(li: int, casa_ov: int, carta_ov: int) -> Array:
	var cs := _cartas_linha(li, casa_ov, carta_ov)
	var tem := false
	for c in cs:
		if eh_agulha(c): tem = true
	if not tem: return cs
	var r := _av_linha(cs)
	var out := []
	for c in cs:
		out.append(int(r[2]) if eh_agulha(c) else c)
	return out

# cartas da linha + uma carta extra (para potencial), agulhas resolvidas
func cartas_concretas_extra(li: int, extra: int) -> Array:
	var h: bool = HORIZ[li]
	if Nucleo.DIAG[li] and cfg["av_diag_face_direito"]: h = true
	var cs := []
	for c in Nucleo.LINHAS[li]:
		var raw: int = grade[c]
		if raw == VAZIA: continue
		if raw >= AVESSO_BASE: cs.append(face(raw, h))
		else: cs.append(raw)
	if extra != VAZIA:
		cs.append(face(extra, h) if extra >= AVESSO_BASE else extra)
	if cs.size() > 5: return []
	var tem := false
	for c in cs:
		if eh_agulha(c): tem = true
	if not tem: return cs
	var r := _av_linha(cs)
	var out := []
	for c in cs:
		out.append(int(r[2]) if eh_agulha(c) else c)
	return out

func casas_vazias() -> Array:
	var v := []
	for c in range(25):
		if grade[c] == VAZIA: v.append(c)
	return v

func casas_criticas() -> Array:
	var s := {}
	for li in range(12):
		if conta[li] == 4:
			for c in Nucleo.LINHAS[li]:
				if grade[c] == VAZIA: s[c] = true
	return s.keys()

# conservacao: conta FACES (um avesso vale 2); agulha nao pertence ao baralho
func conservacao() -> Array:
	var faces := 0
	var ag := 0
	for a in [mao, baralho, descarte, colhida]:
		for c in a:
			if eh_agulha(c): ag += 1
			else: faces += n_faces(c)
	for i in range(25):
		var c: int = grade[i]
		if c == VAZIA: continue
		if eh_agulha(c): ag += 1
		else: faces += n_faces(c)
	return [faces, ag]

func clone_leve() -> Mesa2:
	var c := Mesa2.new(rodada, tipo, -1, cfg)
	c.grade = grade.duplicate()
	c.conta = conta.duplicate()
	c.tear = tear
	c.teto = teto
	c.pontos = pontos
	c.posic_usados = posic_usados
	c.posic_max = posic_max
	c.pulsos_por_linha = pulsos_por_linha.duplicate()
	return c

func aplicar_seco(casa: int, carta: int) -> Array:
	return posicionar(carta, casa, 0)
