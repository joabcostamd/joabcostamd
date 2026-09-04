extends SceneTree

const N := 1200
const PESO_K := [0.0, 0.02, 0.08, 0.30, 0.75, 1.0]

func media(a: Array) -> float:
	if a.is_empty(): return 0.0
	var s := 0.0
	for x in a: s += float(x)
	return s / a.size()

func pct(a: Array, p: float):
	if a.is_empty(): return null
	var b := a.duplicate(); b.sort()
	return b[int(round((b.size() - 1) * p))]

func pot_linha(m: Mesa, li: int, extra: int) -> float:
	var cc := []
	for c in Nucleo.LINHAS[li]:
		if m.grade[c] >= 0: cc.append(m.grade[c])
	if extra >= 0: cc.append(extra)
	var k := cc.size()
	if k == 0 or k > 5: return 0.0
	var cat := Nucleo.melhor_alcancavel(cc)
	var fich := 0
	for c in cc: fich += Nucleo.fichas_carta(c)
	var fich_proj := float(fich) * 5.0 / float(k)
	var v: float = (float(m.base_de(cat)) + fich_proj) * float(m.mult_de(cat) + m.tear) * PESO_K[k]
	if Nucleo.DIAG[li]: v *= 0.6
	return v

func movimentos(m: Mesa) -> Dictionary:
	var vazias := m.casas_vazias()
	var criticas := {}
	for c in m.casas_criticas(): criticas[c] = true
	var pot_now := []; pot_now.resize(12)
	for li in range(12): pot_now[li] = pot_linha(m, li, -1)
	var pot_add := []
	for i in range(m.mao.size()):
		var lp := []; lp.resize(12)
		for li in range(12): lp[li] = pot_linha(m, li, m.mao[i])
		pot_add.append(lp)
	var lista := []
	var melhor_im := 0
	for i in range(m.mao.size()):
		for casa in vazias:
			var im := 0; var nl := 0
			if criticas.has(casa):
				var g := m.ganho(casa, m.mao[i]); im = g[0]; nl = g[1]
			var dp := 0.0
			for li in Nucleo.CELL_LINHAS[casa]:
				dp += float(pot_add[i][li]) - float(pot_now[li])
			lista.append([i, casa, im, dp, float(im) * 1000000.0 + dp, nl])
			if im > melhor_im: melhor_im = im
	return {"lista": lista, "melhor_imediato": melhor_im, "pot_now": pot_now, "pot_add": pot_add}

func melhor_gulosa(lista: Array) -> Array:
	var b = lista[0]
	for mv in lista:
		if mv[4] > b[4]: b = mv
	return b

func talvez_descartar(m: Mesa, mv: Dictionary) -> bool:
	if m.descartes_usados >= m.descartes_max: return false
	if mv["melhor_imediato"] > 0: return false
	if m.posic_max - m.posic_usados < 4: return false
	var util := []; var best := -1.0e30
	for i in range(m.mao.size()):
		var u := -1.0e30
		for casa in m.casas_vazias():
			var dp := 0.0
			for li in Nucleo.CELL_LINHAS[casa]:
				dp += float(mv["pot_add"][i][li]) - float(mv["pot_now"][li])
			if dp > u: u = dp
		util.append([i, u])
		if u > best: best = u
	var corte: float = (best * 0.35 if best > 0.0 else best)
	var fracas := []
	for x in util:
		if x[1] < corte: fracas.append(x[0])
	if fracas.size() < 2: return false
	if fracas.size() > 3:
		util.sort_custom(func(a, b): return a[1] < b[1])
		fracas = [util[0][0], util[1][0], util[2][0]]
	m.trocar(fracas)
	return true

# valor de pulso de uma linha li supondo carta extra ja colocada
func valor_pulso(m: Mesa, li: int, casa_nova: int, carta_nova: int, F: float) -> int:
	var cc := []
	for c in Nucleo.LINHAS[li]:
		if c == casa_nova: cc.append(carta_nova)
		elif m.grade[c] >= 0: cc.append(m.grade[c])
	var r := Nucleo.avaliar_parcial(cc)
	var cat: int = r[0]
	var fichas: int = m.base_de(cat) + int(r[1])
	var v := float(fichas) * float(m.mult_de(cat) + m.tear) * F
	if Nucleo.DIAG[li]: v *= 0.6
	return int(floor(v))

# variante: bit0 = pulso, bit1 = tear tick
var TICK := 3
func jogar(rodada: int, tipo: int, semente: int, variante: int, F: float, col: Dictionary) -> void:
	var m := Mesa.new(rodada, tipo, semente, [])
	var usa_pulso := (variante & 1) != 0
	var usa_tick := (variante & 2) != 0
	var pulsos_por_linha := []; pulsos_por_linha.resize(12); pulsos_por_linha.fill(0)
	var turno := 0
	var turnos_com_recompensa := []
	var pontos_pulso := 0
	var n_pulsos := 0
	while m.posic_usados < m.posic_max and m.pontos < m.meta:
		turno += 1
		if m.mao.is_empty(): break
		var mv := movimentos(m)
		if mv["lista"].is_empty(): break
		if talvez_descartar(m, mv):
			mv = movimentos(m)
			if mv["lista"].is_empty(): break
		var esc = melhor_gulosa(mv["lista"])
		var casa: int = esc[1]
		var carta: int = m.mao[esc[0]]
		# pulsos candidatos: linhas que passam para 3 ou 4
		var cand := []
		if usa_pulso:
			for li in Nucleo.CELL_LINHAS[casa]:
				var novo: int = m.conta[li] + 1
				if (novo == 3 or novo == 4) and pulsos_por_linha[li] < 2:
					cand.append([li, novo, valor_pulso(m, li, casa, carta, F)])
		
		var g := m.posicionar(esc[0], casa)
		var ganhou: bool = int(g[0]) > 0
		var pp := 0
		for x in cand:
			if m.conta[x[0]] == x[1]:
				pp += int(x[2]); pulsos_por_linha[x[0]] += 1; n_pulsos += 1
		if pp > 0:
			m.pontos += pp; pontos_pulso += pp
		if usa_tick and m.posic_usados % TICK == 0:
			m.tear = min(8, m.tear + 1)
		if ganhou or pp > 0:
			turnos_com_recompensa.append(turno)
	var venceu := m.pontos >= m.meta
	if not venceu: m.colheita_final()
	var gaps := []; var ant := 0
	for t in turnos_com_recompensa:
		gaps.append(t - ant); ant = t
	var setp := {}
	for t in turnos_com_recompensa: setp[t] = true
	var seca := 0; var atual := 0
	for t in range(1, turno + 1):
		if setp.has(t): atual = 0
		else:
			atual += 1
			if atual > seca: seca = atual
	for gp in gaps: col["gaps"].append(gp)
	col["seca"].append(seca)
	col["tear"].append(m.tear)
	col["turnos"].append(turno)
	col["pct_turno_rec"].append(float(turnos_com_recompensa.size()) / float(max(turno, 1)))
	col["razao"].append(float(m.pontos) / float(m.meta))
	col["n_pulsos"].append(n_pulsos)
	col["pontos_pulso"].append(pontos_pulso)
	col["pontos"].append(m.pontos)
	col["vitorias"] += 1 if venceu else 0
	col["mesas"] += 1
	if not col["por_rodada"].has(rodada): col["por_rodada"][rodada] = [0, 0]
	col["por_rodada"][rodada][0] += 1
	if venceu: col["por_rodada"][rodada][1] += 1

func novo() -> Dictionary:
	return {"gaps": [], "seca": [], "tear": [], "turnos": [], "pct_turno_rec": [],
		"razao": [], "n_pulsos": [], "pontos_pulso": [], "pontos": [],
		"vitorias": 0, "mesas": 0, "por_rodada": {}}

func rodar(variante: int, F: float) -> Dictionary:
	var col := novo()
	for t in range(N):
		var rodada := (t % 6) + 1
		var tipo := int(t / 6) % 3
		jogar(rodada, tipo, 31337 + t * 7919 + variante * 104729, variante, F, col)
	return {
		"mesas": col["mesas"],
		"vitoria_pct": snappedf(100.0 * float(col["vitorias"]) / float(col["mesas"]), 0.01),
		"vit_por_rodada": col["por_rodada"],
		"turnos_entre_recompensas_mediana": pct(col["gaps"], 0.5),
		"turnos_entre_recompensas_p90": pct(col["gaps"], 0.9),
		"seca_mediana": pct(col["seca"], 0.5),
		"seca_p90": pct(col["seca"], 0.9),
		"pct_turnos_com_recompensa": snappedf(100.0 * media(col["pct_turno_rec"]), 0.1),
		"tear_mediana": pct(col["tear"], 0.5),
		"tear_media": snappedf(media(col["tear"]), 0.01),
		"tear_max": pct(col["tear"], 1.0),
		"pulsos_por_mesa_mediana": pct(col["n_pulsos"], 0.5),
		"pulsos_por_mesa_media": snappedf(media(col["n_pulsos"]), 0.01),
		"pontos_pulso_por_mesa_mediana": pct(col["pontos_pulso"], 0.5),
		"pontos_por_mesa_mediana": pct(col["pontos"], 0.5),
		"razao_pontos_meta_mediana": snappedf(float(pct(col["razao"], 0.5)), 0.001),
	}

func _init() -> void:
	Nucleo.init_estatico()
	var res := {}
	res["v0_base"] = rodar(0, 0.0)
	print("v0 ok")
	res["v1_pulso_F035"] = rodar(1, 0.35)
	print("v1 ok")
	res["v1_pulso_F015"] = rodar(1, 0.15)
	print("v1b ok")
	res["v2_tear_tick"] = rodar(2, 0.0)
	print("v2 ok")
	res["v3_pulso035_e_tick3"] = rodar(3, 0.35)
	print("v3 ok")
	TICK = 4
	res["v4_tick4_so"] = rodar(2, 0.0)
	res["v5_pulso025_tick4"] = rodar(3, 0.25)
	res["v6_pulso015_tick4"] = rodar(3, 0.15)
	print("v6 ok")
	var f := FileAccess.open("res://experimento.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "  "))
	f.close()
	print("escrito")
	quit()
