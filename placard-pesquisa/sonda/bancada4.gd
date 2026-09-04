extends RefCounted
class_name Bancada4

# =============================================================================
# BANCADA c4 - JANELA DA COLHEITA. Deriva de bancada.gd (b1) e acrescenta:
#   - politica PLANEJADORA (alvo de cruz explicito)
#   - metricas de cruzada (perpendicularidade, intencao, teto do mult)
#   - suporte a janela (todas as casas viram criticas quando ha gatilho pendente)
# =============================================================================

const PESO_K := [0.0, 0.02, 0.08, 0.30, 0.75, 1.0]
const DEEP_K := 8
const DEEP_S := 4
const SEED0 := 31337

class Plano extends RefCounted:
	var L := -1
	var C := -1

func media(a: Array) -> float:
	if a.is_empty(): return 0.0
	var s := 0.0
	for x in a: s += float(x)
	return s / a.size()

func pct(a: Array, p: float):
	if a.is_empty(): return null
	var b := a.duplicate(); b.sort()
	return b[int(round((b.size() - 1) * p))]

# ------------------------------- potencial ---------------------------------
func pot_extra(m: Mesa2, li: int, extra: int) -> float:
	return _pot_cc(m, li, m.cartas_concretas_extra(li, extra))

func _pot_cc(m: Mesa2, li: int, cc: Array) -> float:
	var k := cc.size()
	if k == 0 or k > 5: return 0.0
	var cat := Nucleo.melhor_alcancavel(cc)
	var fich := 0
	for c in cc: fich += Nucleo.fichas_carta(c)
	var fich_proj := float(fich) * 5.0 / float(k)
	var v: float = (float(m.base_de(cat)) + fich_proj) * m.fator_linha(cat) * PESO_K[k]
	if Nucleo.DIAG[li]: v *= 0.6
	return v

# lista de movimentos: [idx_mao, casa, im, dp, score, nl, carta_efetiva]
func movimentos(m: Mesa2) -> Dictionary:
	var vazias := m.casas_vazias()
	var criticas := {}
	if m.gatilho_pendente():
		for c in vazias: criticas[c] = true
	else:
		for c in m.casas_criticas(): criticas[c] = true
	var pot_now := []
	pot_now.resize(12)
	for li in range(12): pot_now[li] = _pot_cc(m, li, m.cartas_concretas(li, -1, -1))
	var vars := []
	for i in range(m.mao.size()):
		var c: int = m.mao[i]
		vars.append([i, c])
		if Mesa2.eh_avesso(c):
			vars.append([i, Mesa2.girar(c)])
	var pot_add := []
	for v in vars:
		var lp := []
		lp.resize(12)
		for li in range(12): lp[li] = pot_extra(m, li, v[1])
		pot_add.append(lp)
	var lista := []
	var melhor_im := 0
	for vi in range(vars.size()):
		var i: int = vars[vi][0]
		var carta: int = vars[vi][1]
		for casa in vazias:
			if not m.pode_posicionar(carta, casa): continue
			var im := 0
			var nl := 0
			if criticas.has(casa):
				var g := m.ganho(casa, carta)
				im = g[0]; nl = g[1]
			var dp := 0.0
			for li in Nucleo.CELL_LINHAS[casa]:
				dp += float(pot_add[vi][li]) - float(pot_now[li])
			lista.append([i, casa, im, dp, float(im) * 1000000.0 + dp, nl, carta])
			if im > melhor_im: melhor_im = im
	return {"lista": lista, "melhor_imediato": melhor_im, "pot_now": pot_now, "pot_add": pot_add,
		"vars": vars}

func melhor_gulosa(lista: Array) -> Array:
	var b = lista[0]
	for mv in lista:
		if mv[4] > b[4]: b = mv
	return b

func melhor_profunda(m: Mesa2, lista: Array, rng: Mesa2.Rng) -> Array:
	var ord := lista.duplicate()
	ord.sort_custom(func(a, b): return a[4] > b[4])
	var k: int = min(DEEP_K, ord.size())
	var pool: Array = m.baralho + m.descarte
	var melhor = ord[0]
	var melhor_v := -1.0e30
	for idx in range(k):
		var mv = ord[idx]
		var sim := m.clone_leve()
		sim.aplicar_seco(mv[1], mv[6])
		var mao2 := []
		for i in range(m.mao.size()):
			if i != mv[0]: mao2.append(m.mao[i])
		var soma := 0.0
		var crit: Array = (sim.casas_vazias() if sim.gatilho_pendente() else sim.casas_criticas())
		if not (pool.is_empty() or crit.is_empty()):
			for s in range(DEEP_S):
				var nova: int = pool[rng.inteiro(pool.size())]
				var mm: Array = mao2 + [nova]
				var best := 0
				for c in mm:
					for casa in crit:
						if not sim.pode_posicionar(c, casa): continue
						var g := sim.ganho(casa, c)
						if g[0] > best: best = g[0]
				soma += float(best)
		var v: float = float(mv[2]) + 0.9 * (soma / float(DEEP_S)) + 0.000001 * float(mv[3])
		if v > melhor_v:
			melhor_v = v; melhor = mv
	return melhor

# ------------------------- CACADORA da bancada 1 (referencia) --------------
func melhor_cacadora(m: Mesa2, lista: Array) -> Array:
	var restam: int = m.posic_max - m.posic_usados
	var melhor = null
	var melhor_v := -1.0e30
	for mv in lista:
		if mv[5] >= 2:
			var sc: float = float(mv[2]) * 1000000.0 + float(mv[3])
			if sc > melhor_v:
				melhor_v = sc; melhor = mv
	if melhor != null: return melhor
	var permitidos := []
	for mv in lista:
		var proibido := false
		if mv[5] == 1:
			var casa: int = mv[1]
			var melhor_outra := 0
			for li in Nucleo.CELL_LINHAS[casa]:
				if m.conta[li] < 4 and m.conta[li] > melhor_outra: melhor_outra = m.conta[li]
			var faltam: int = 4 - melhor_outra
			if melhor_outra >= 2 and restam >= faltam + 1: proibido = true
		if not proibido: permitidos.append(mv)
	if permitidos.is_empty(): permitidos = lista
	return melhor_gulosa(permitidos)

# =========================== POLITICA PLANEJADORA ==========================
static func bracos(L: int, C: int) -> Array:
	var b := []
	for c in range(5):
		if c != C: b.append(L * 5 + c)
	for r in range(5):
		if r != L: b.append(r * 5 + C)
	return b

func escolher_alvo(m: Mesa2) -> Array:
	var restam: int = m.posic_max - m.posic_usados
	var melhor := [-1, -1]
	var melhor_sc := -1.0e30
	for L in range(5):
		for C in range(5):
			var centro := L * 5 + C
			if m.grade[centro] != Mesa2.VAZIA: continue
			var br := bracos(L, C)
			var cheios := 0
			var perigo := 0
			for cc in br:
				if m.grade[cc] != Mesa2.VAZIA:
					cheios += 1
				else:
					for li in Nucleo.CELL_LINHAS[cc]:
						if li == L or li == 5 + C: continue
						if m.conta[li] >= 4: perigo += 1
			var faltam := (8 - cheios) + 1
			if faltam > restam: continue
			var q := _pot_cc(m, L, m.cartas_concretas(L, -1, -1)) + _pot_cc(m, 5 + C, m.cartas_concretas(5 + C, -1, -1))
			var sc := float(cheios) * 1000.0 - float(perigo) * 600.0 + q * 0.01
			if sc > melhor_sc:
				melhor_sc = sc; melhor = [L, C]
	return melhor

func melhor_planejadora(m: Mesa2, lista: Array, plano: Plano) -> Array:
	var restam: int = m.posic_max - m.posic_usados
	if plano.L < 0 or m.grade[plano.L * 5 + plano.C] != Mesa2.VAZIA:
		var a := escolher_alvo(m)
		plano.L = a[0]; plano.C = a[1]
	if plano.L >= 0:
		var brx := bracos(plano.L, plano.C)
		var vaz := 0
		for cc in brx:
			if m.grade[cc] == Mesa2.VAZIA: vaz += 1
		if vaz + 1 > restam:
			var a2 := escolher_alvo(m)
			plano.L = a2[0]; plano.C = a2[1]
	if plano.L < 0:
		return melhor_gulosa(lista)
	var Lli: int = plano.L
	var Cli: int = 5 + plano.C
	var centro: int = plano.L * 5 + plano.C
	var vazios := []
	for cc in bracos(plano.L, plano.C):
		if m.grade[cc] == Mesa2.VAZIA: vazios.append(cc)
	var destinos: Array = (vazios if not vazios.is_empty() else [centro])
	var alvo_set := {}
	for d in destinos: alvo_set[d] = true
	var melhor = null
	var melhor_v := -1.0e30
	for mv in lista:
		if not alvo_set.has(mv[1]): continue
		var casa: int = mv[1]
		var carta: int = mv[6]
		var lateral := 0
		for li in Nucleo.CELL_LINHAS[casa]:
			if m.conta[li] == 4 and li != Lli and li != Cli: lateral += 1
		var alvo_li: int = (Lli if int(casa / 5) == plano.L else Cli)
		var antes := _pot_cc(m, alvo_li, m.cartas_concretas(alvo_li, -1, -1))
		var depois := _pot_cc(m, alvo_li, m.cartas_concretas_extra(alvo_li, carta))
		var v := (depois - antes) - float(lateral) * 1.0e7
		if casa == centro: v += float(mv[2])
		if v > melhor_v:
			melhor_v = v; melhor = mv
	if melhor == null: return melhor_gulosa(lista)
	return melhor

func planejador_descarta(m: Mesa2, plano: Plano) -> bool:
	if m.descartes_usados >= m.descartes_max: return false
	if plano.L < 0: return false
	if m.posic_max - m.posic_usados < 4: return false
	var Lli: int = plano.L
	var Cli: int = 5 + plano.C
	var aL := _pot_cc(m, Lli, m.cartas_concretas(Lli, -1, -1))
	var aC := _pot_cc(m, Cli, m.cartas_concretas(Cli, -1, -1))
	var util := []
	var best := -1.0e30
	for i in range(m.mao.size()):
		var c: int = m.mao[i]
		var u: float = max(pot_extra(m, Lli, c) - aL, pot_extra(m, Cli, c) - aC)
		if Mesa2.eh_avesso(c):
			var g := Mesa2.girar(c)
			u = max(u, max(pot_extra(m, Lli, g) - aL, pot_extra(m, Cli, g) - aC))
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

# ------------------------ descarte generico (gulosa/profunda) --------------
func talvez_descartar(m: Mesa2, mv: Dictionary) -> bool:
	if m.descartes_usados >= m.descartes_max: return false
	if mv["melhor_imediato"] > 0: return false
	if m.posic_max - m.posic_usados < 4: return false
	var util := []
	var best := -1.0e30
	var vazias := m.casas_vazias()
	var melhor_por_mao := {}
	for vi in range(mv["vars"].size()):
		var idx: int = mv["vars"][vi][0]
		for casa in vazias:
			var dp := 0.0
			for li in Nucleo.CELL_LINHAS[casa]:
				dp += float(mv["pot_add"][vi][li]) - float(mv["pot_now"][li])
			if not melhor_por_mao.has(idx) or dp > float(melhor_por_mao[idx]):
				melhor_por_mao[idx] = dp
	for i in range(m.mao.size()):
		var u: float = float(melhor_por_mao[i]) if melhor_por_mao.has(i) else -1.0e30
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

# ------------------------------- uma mesa ----------------------------------
# politica: 0 gulosa, 1 profunda, 2 cacadora(b1), 3 PLANEJADORA
func jogar(rodada: int, tipo: int, semente: int, cfg: Dictionary, politica: int,
		coletar_m5: bool, col: Dictionary) -> void:
	var m := Mesa2.new(rodada, tipo, semente, cfg)
	var rng := Mesa2.Rng.new(Mesa2.mix(semente, 999, politica))
	var plano := Plano.new()
	var turno := 0
	var turnos_rec := []
	var cruzadas := 0
	var eventos := []
	var marco := int(floor(m.posic_max * 2.0 / 3.0))
	var pontos_marco := -1
	var maior_evento := 0
	var seg4 := 0
	var ent4 := 0
	var fechar_possivel := 0
	var recusou := 0
	var cruz_intencionais := 0
	var cruz_acidentais := 0
	var e4 := []
	e4.resize(12)
	while m.posic_usados < m.posic_max and m.pontos < m.meta:
		turno += 1
		if m.mao.is_empty(): break
		var mv := movimentos(m)
		if mv["lista"].is_empty(): break
		var descartou := false
		if politica == 3: descartou = planejador_descarta(m, plano)
		else: descartou = talvez_descartar(m, mv)
		if descartou:
			mv = movimentos(m)
			if mv["lista"].is_empty(): break
		var bg := melhor_gulosa(mv["lista"])
		if coletar_m5:
			var bp := melhor_profunda(m, mv["lista"], Mesa2.Rng.new(Mesa2.mix(semente, turno, 4242)))
			col["m5_total"] += 1
			if bg[0] == bp[0] and bg[1] == bp[1] and bg[6] == bp[6]:
				col["m5_iguais"] += 1
		var esc
		if politica == 0: esc = bg
		elif politica == 1: esc = melhor_profunda(m, mv["lista"], rng)
		elif politica == 2: esc = melhor_cacadora(m, mv["lista"])
		else: esc = melhor_planejadora(m, mv["lista"], plano)
		# fechar era possivel? a politica recusou?
		var crit := m.casas_criticas()
		if not crit.is_empty():
			fechar_possivel += 1
			if not crit.has(esc[1]): recusou += 1
		for li in range(12): e4[li] = (m.conta[li] == 4)
		var era_gulosa: bool = (esc[0] == bg[0] and esc[1] == bg[1] and esc[6] == bg[6])
		var centro_alvo: int = (plano.L * 5 + plano.C if plano.L >= 0 else -1)
		var r := m.posicionar(esc[6], esc[1], turno)
		m.mao.remove_at(esc[0])
		m.comprar_mao()
		if esc[1] == centro_alvo: plano.L = -1
		for li in range(12):
			if m.conta[li] == 4:
				if e4[li]: seg4 += 1
				else: ent4 += 1
		if int(r[0]) > 0:
			eventos.append(int(r[0]))
			if int(r[0]) > maior_evento: maior_evento = int(r[0])
			if int(r[1]) >= 2:
				cruzadas += 1
				if era_gulosa: cruz_acidentais += 1
				else: cruz_intencionais += 1
			col["eventos_pontos"].append(int(r[0]))
			col["n_por_evento"].append(int(r[1]))
		if int(r[0]) > 0 or int(r[2]) > 0:
			turnos_rec.append(turno)
		if m.posic_usados == marco: pontos_marco = m.pontos
	# regra 5: nada sobrevive ao fim da mesa
	var fj := m.finalizar_janela(turno)
	if int(fj[0]) > 0:
		eventos.append(int(fj[0]))
		if int(fj[0]) > maior_evento: maior_evento = int(fj[0])
		if int(fj[1]) >= 2:
			cruzadas += 1
			cruz_acidentais += 1
		col["eventos_pontos"].append(int(fj[0]))
		col["n_por_evento"].append(int(fj[1]))
	var venceu := m.pontos >= m.meta
	if not venceu: m.colheita_final()
	# teto duro do enunciado: 2 (Pequena) / 1 (Grande) / 2 (Chefe)
	var teto_cruz: int = [2, 1, 2][tipo]
	if cruzadas > teto_cruz: col["violacoes_teto"] += 1
	var setp := {}
	for t in turnos_rec: setp[t] = true
	var seca := 0
	var atual := 0
	for t in range(1, turno + 1):
		if setp.has(t): atual = 0
		else:
			atual += 1
			if atual > seca: seca = atual
	var ant := 0
	for t in turnos_rec:
		col["gaps"].append(t - ant); ant = t
	col["seca"].append(seca)
	col["tear"].append(m.tear)
	col["turnos"].append(turno)
	col["pct_turno_rec"].append(float(turnos_rec.size()) / float(max(turno, 1)))
	col["razao"].append(float(m.pontos) / float(m.meta))
	col["pontos"].append(m.pontos)
	col["n_eventos"].append(eventos.size())
	col["cruzadas"].append(cruzadas)
	col["maior_evento"].append(maior_evento)
	col["vitorias"] += 1 if venceu else 0
	col["mesas"] += 1
	col["vazias_min"].append(m.vazias_min)
	col["seg4"] += seg4
	col["ent4"] += ent4
	col["fechar_possivel"] += fechar_possivel
	col["recusou"] += recusou
	col["cruz_intencionais"] += cruz_intencionais
	col["cruz_acidentais"] += cruz_acidentais
	col["cruz_perp"] += int(m.stats["cruz_perp"])
	col["cruz_n"] += int(m.stats["cruz_n"])
	col["cruz_teto_mordeu"] += int(m.stats["cruz_teto_mordeu"])
	col["teto_mordeu"] += int(m.stats["teto_mordeu"])
	col["maduras_criadas"] += m.maduras_criadas
	col["colheitas"] += int(m.stats["colheitas"])
	col["pulsos"] += int(m.stats["pulsos"])
	for x in m.stats["cruz_nlinhas"]: col["cruz_nlinhas"].append(x)
	if not col["por_rodada"].has(rodada): col["por_rodada"][rodada] = [0, 0, 0]
	col["por_rodada"][rodada][0] += 1
	if venceu: col["por_rodada"][rodada][1] += 1
	col["por_rodada"][rodada][2] += cruzadas
	if not col["por_tipo"].has(tipo): col["por_tipo"][tipo] = [0, 0, 0, 0]
	col["por_tipo"][tipo][0] += 1
	if venceu: col["por_tipo"][tipo][1] += 1
	col["por_tipo"][tipo][2] += cruzadas
	if cruzadas > 0: col["por_tipo"][tipo][3] += 1
	if not venceu and pontos_marco >= 0:
		col["derrotas"] += 1
		if float(pontos_marco) < 0.45 * float(m.meta): col["derrotas_decididas"] += 1

func novo() -> Dictionary:
	return {"gaps": [], "seca": [], "tear": [], "turnos": [], "pct_turno_rec": [],
		"razao": [], "pontos": [], "n_eventos": [], "cruzadas": [], "maior_evento": [],
		"eventos_pontos": [], "n_por_evento": [], "vazias_min": [], "cruz_nlinhas": [],
		"vitorias": 0, "mesas": 0, "por_rodada": {}, "por_tipo": {},
		"seg4": 0, "ent4": 0, "fechar_possivel": 0, "recusou": 0,
		"cruz_intencionais": 0, "cruz_acidentais": 0, "cruz_perp": 0, "cruz_n": 0,
		"cruz_teto_mordeu": 0, "teto_mordeu": 0, "maduras_criadas": 0,
		"colheitas": 0, "pulsos": 0, "violacoes_teto": 0,
		"derrotas": 0, "derrotas_decididas": 0, "m5_total": 0, "m5_iguais": 0}

func rodar(cfg: Dictionary, n: int, n_m5: int, politica: int) -> Dictionary:
	var col := novo()
	for t in range(n):
		var rodada := (t % 6) + 1
		var tipo := int(t / 6) % 3
		jogar(rodada, tipo, SEED0 + t * 7919, cfg, politica, t < n_m5, col)
	var vr := {}
	for k in col["por_rodada"].keys():
		vr[str(k)] = [snappedf(100.0 * float(col["por_rodada"][k][1]) / float(col["por_rodada"][k][0]), 0.1),
			snappedf(float(col["por_rodada"][k][2]) / float(col["por_rodada"][k][0]), 0.001)]
	var vt := {}
	for k in col["por_tipo"].keys():
		vt[["pequena", "grande", "chefe"][int(k)]] = {
			"mesas": col["por_tipo"][k][0],
			"vitoria_pct": snappedf(100.0 * float(col["por_tipo"][k][1]) / float(col["por_tipo"][k][0]), 0.1),
			"cruzadas_por_mesa": snappedf(float(col["por_tipo"][k][2]) / float(col["por_tipo"][k][0]), 0.001),
			"pct_mesas_com_cruzada": snappedf(100.0 * float(col["por_tipo"][k][3]) / float(col["por_tipo"][k][0]), 0.1)}
	var mediana_ev = pct(col["eventos_pontos"], 0.5)
	var pico = pct(col["maior_evento"], 1.0)
	var nn := [0, 0, 0, 0, 0, 0]
	for x in col["n_por_evento"]:
		if x < 6: nn[x] += 1
	var tot_ev: int = max(1, col["n_por_evento"].size())
	var zc := 0
	var maxc := 0
	for x in col["cruzadas"]:
		if x == 0: zc += 1
		if x > maxc: maxc = x
	var ev_cruz := 0
	for x in col["n_por_evento"]:
		if x >= 2: ev_cruz += 1
	return {
		"mesas": col["mesas"],
		"m5_pct": (snappedf(100.0 * float(col["m5_iguais"]) / float(col["m5_total"]), 0.1) if col["m5_total"] > 0 else null),
		"m5_n": col["m5_total"],
		"pct_turnos_com_recompensa": snappedf(100.0 * media(col["pct_turno_rec"]), 0.1),
		"seca_mediana": pct(col["seca"], 0.5),
		"seca_p90": pct(col["seca"], 0.9),
		"turnos_entre_recompensas_mediana": pct(col["gaps"], 0.5),
		"eventos_por_mesa_media": snappedf(media(col["n_eventos"]), 0.01),
		"cruzadas_por_mesa_media": snappedf(media(col["cruzadas"]), 0.001),
		"cruzadas_por_mesa_max": maxc,
		"pct_mesas_com_zero_cruzada": snappedf(100.0 * float(zc) / float(max(1, col["mesas"])), 0.1),
		"cruzadas_por_evento": snappedf(float(ev_cruz) / float(tot_ev), 0.001),
		"violacoes_teto_duro": col["violacoes_teto"],
		"pct_cruzadas_perpendiculares": (snappedf(100.0 * float(col["cruz_perp"]) / float(col["cruz_n"]), 0.1) if col["cruz_n"] > 0 else null),
		"pct_cruzadas_acidentais": (snappedf(100.0 * float(col["cruz_acidentais"]) / float(max(1, col["cruz_acidentais"] + col["cruz_intencionais"])), 0.1) if (col["cruz_acidentais"] + col["cruz_intencionais"]) > 0 else null),
		"pct_cruzadas_com_teto_do_mult_mordendo": (snappedf(100.0 * float(col["cruz_teto_mordeu"]) / float(col["cruz_n"]), 0.1) if col["cruz_n"] > 0 else null),
		"pct_eventos_com_teto_do_mult_mordendo": (snappedf(100.0 * float(col["teto_mordeu"]) / float(tot_ev), 0.1) if tot_ev > 0 else null),
		"n_linhas_por_evento_pct": {"n1": snappedf(100.0*float(nn[1])/float(tot_ev),0.01), "n2": snappedf(100.0*float(nn[2])/float(tot_ev),0.01),
			"n3": snappedf(100.0*float(nn[3])/float(tot_ev),0.01), "n4": snappedf(100.0*float(nn[4])/float(tot_ev),0.01),
			"n5": snappedf(100.0*float(nn[5])/float(tot_ev),0.01)},
		"turnos_segurando_4_5": (snappedf(float(col["seg4"]) / float(col["ent4"]), 0.001) if col["ent4"] > 0 else null),
		"pct_colheitas_adiadas": (snappedf(100.0 * float(col["recusou"]) / float(col["fechar_possivel"]), 0.1) if col["fechar_possivel"] > 0 else null),
		"casas_vazias_min_mediana": pct(col["vazias_min"], 0.5),
		"casas_vazias_min_p10": pct(col["vazias_min"], 0.1),
		"casas_vazias_min_minimo": pct(col["vazias_min"], 0.0),
		"maduras_por_mesa": snappedf(float(col["maduras_criadas"]) / float(max(1, col["mesas"])), 0.01),
		"pontos_por_mesa_mediana": pct(col["pontos"], 0.5),
		"razao_pontos_meta_mediana": snappedf(float(pct(col["razao"], 0.5)), 0.001),
		"maior_evento_unico": pico,
		"evento_mediano": mediana_ev,
		"razao_pico_sobre_mediana": (snappedf(float(pico) / float(mediana_ev), 0.01) if mediana_ev != null and int(mediana_ev) > 0 else null),
		"tear_mediano": pct(col["tear"], 0.5),
		"tear_max": pct(col["tear"], 1.0),
		"vitoria_pct": snappedf(100.0 * float(col["vitorias"]) / float(max(1, col["mesas"])), 0.01),
		"por_rodada_vitoria_e_cruzadas": vr,
		"por_tipo": vt,
		"derrota_decidida_2_3_pct": (snappedf(100.0 * float(col["derrotas_decididas"]) / float(col["derrotas"]), 0.1) if col["derrotas"] > 0 else null),
	}
