extends RefCounted
class_name Bancada

# =============================================================================
# BANCADA 1 - linha de base (PULSO 0,35 + TIQUE 4) x variantes de CORINGA
# =============================================================================

const PESO_K := [0.0, 0.02, 0.08, 0.30, 0.75, 1.0]
const DEEP_K := 8
const DEEP_S := 4
const SEED0 := 31337

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
func pot_linha(m: Mesa2, li: int, casa_ov: int, carta_ov: int) -> float:
	return _pot_cc(m, li, m.cartas_concretas(li, casa_ov, carta_ov))

func pot_extra(m: Mesa2, li: int, extra: int) -> float:
	return _pot_cc(m, li, m.cartas_concretas_extra(li, extra))

func _pot_cc(m: Mesa2, li: int, cc: Array) -> float:
	var k := cc.size()
	if k == 0 or k > 5: return 0.0
	var cat := Nucleo.melhor_alcancavel(cc)
	var fich := 0
	for c in cc: fich += Nucleo.fichas_carta(c)
	var fich_proj := float(fich) * 5.0 / float(k)
	var v: float = (float(m.base_de(cat)) + fich_proj) * float(m.mult_de(cat) + m.tear) * PESO_K[k]
	if Nucleo.DIAG[li]: v *= 0.6
	return v

# lista de movimentos: [idx_mao, casa, im, dp, score, nl, carta_efetiva]
func movimentos(m: Mesa2) -> Dictionary:
	var vazias := m.casas_vazias()
	var criticas := {}
	for c in m.casas_criticas(): criticas[c] = true
	var pot_now := []
	pot_now.resize(12)
	for li in range(12): pot_now[li] = _pot_cc(m, li, m.cartas_concretas(li, -1, -1))
	# variantes de carta na mao (avesso: 2 orientacoes)
	var vars := []   # [idx_mao, carta_efetiva]
	for i in range(m.mao.size()):
		var c: int = m.mao[i]
		vars.append([i, c])
		if Mesa2.eh_avesso(c):
			vars.append([i, Mesa2.girar(c)])
	# potencial por (variante, linha) - independente da casa, como na sonda
	var pot_add := []
	for v in vars:
		var lp := []
		lp.resize(12)
		for li in range(12): lp[li] = pot_extra(m, li, v[1])
		pot_add.append(lp)
	var lista := []
	var melhor_im := 0
	var n_dist := {}
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
			n_dist[im] = true
			if im > melhor_im: melhor_im = im
	return {"lista": lista, "melhor_imediato": melhor_im, "pot_now": pot_now, "pot_add": pot_add,
		"vars": vars, "n_legais": lista.size(), "n_distintos": n_dist.size()}

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
		var crit := sim.casas_criticas()
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
# politica: 0 gulosa, 1 profunda, 2 cacadora
func jogar(rodada: int, tipo: int, semente: int, cfg: Dictionary, politica: int,
		coletar_m5: bool, col: Dictionary) -> void:
	var m := Mesa2.new(rodada, tipo, semente, cfg)
	var rng := Mesa2.Rng.new(Mesa2.mix(semente, 999, politica))
	var turno := 0
	var turnos_rec := []
	var cruzes := 0
	var eventos := []
	var marco := int(floor(m.posic_max * 2.0 / 3.0))
	var pontos_marco := -1
	var maior_evento := 0
	var pos_coringa := 0
	var pos_total := 0
	while m.posic_usados < m.posic_max and m.pontos < m.meta:
		turno += 1
		if m.mao.is_empty(): break
		var mv := movimentos(m)
		if mv["lista"].is_empty(): break
		if talvez_descartar(m, mv):
			mv = movimentos(m)
			if mv["lista"].is_empty(): break
		# outs de cruz: existe jogada que fecha 2+ linhas?
		var tem_out := false
		for x in mv["lista"]:
			if x[5] >= 2: tem_out = true; break
		var tem_coringa_mao := false
		for c in m.mao:
			if Mesa2.eh_agulha(c) or Mesa2.eh_avesso(c): tem_coringa_mao = true
		if tem_coringa_mao:
			col["outs_com_n"] += 1
			if tem_out: col["outs_com_sim"] += 1
			if not m.stats["viu_coringa"]:
				m.stats["viu_coringa"] = true
				m.stats["turno_1o_achado"] = turno
		else:
			col["outs_sem_n"] += 1
			if tem_out: col["outs_sem_sim"] += 1
		if coletar_m5:
			var bg := melhor_gulosa(mv["lista"])
			var bp := melhor_profunda(m, mv["lista"], Mesa2.Rng.new(Mesa2.mix(semente, turno, 4242)))
			col["m5_total"] += 1
			if bg[0] == bp[0] and bg[1] == bp[1] and bg[6] == bp[6]:
				col["m5_iguais"] += 1
		var esc
		if politica == 0: esc = melhor_gulosa(mv["lista"])
		elif politica == 1: esc = melhor_profunda(m, mv["lista"], rng)
		else: esc = melhor_cacadora(m, mv["lista"])
		var carta_ef: int = esc[6]
		if Mesa2.eh_agulha(carta_ef) or Mesa2.eh_avesso(carta_ef): pos_coringa += 1
		pos_total += 1
		var r := m.posicionar(carta_ef, esc[1], turno)
		m.mao.remove_at(esc[0])
		m.comprar_mao()
		if int(r[0]) > 0:
			eventos.append(int(r[0]))
			if int(r[0]) > maior_evento: maior_evento = int(r[0])
			if int(r[1]) >= 2: cruzes += 1
			col["eventos_pontos"].append(int(r[0]))
			col["n_por_evento"].append(int(r[1]))
		if int(r[0]) > 0 or int(r[2]) > 0:
			turnos_rec.append(turno)
		if m.posic_usados == marco: pontos_marco = m.pontos
	var venceu := m.pontos >= m.meta
	if not venceu: m.colheita_final()
	# residuo morto: carimbos que nunca participaram de linha pontuada depois
	var res_morto := 0
	for casa in m.costuradas.keys():
		if m.grade[casa] != Mesa2.VAZIA: res_morto += 1
	# gaps e seca
	var gaps := []
	var ant := 0
	for t in turnos_rec:
		gaps.append(t - ant); ant = t
	var setp := {}
	for t in turnos_rec: setp[t] = true
	var seca := 0
	var atual := 0
	for t in range(1, turno + 1):
		if setp.has(t): atual = 0
		else:
			atual += 1
			if atual > seca: seca = atual
	for gp in gaps: col["gaps"].append(gp)
	col["seca"].append(seca)
	col["tear"].append(m.tear)
	col["turnos"].append(turno)
	col["pct_turno_rec"].append(float(turnos_rec.size()) / float(max(turno, 1)))
	col["razao"].append(float(m.pontos) / float(m.meta))
	col["pontos"].append(m.pontos)
	col["n_eventos"].append(eventos.size())
	col["cruzes"].append(cruzes)
	col["maior_evento"].append(maior_evento)
	col["maior_evento_meta"].append(float(maior_evento) / float(m.meta))
	if venceu: col["maior_evento_venc_meta"].append(float(maior_evento) / float(m.meta))
	col["vitorias"] += 1 if venceu else 0
	col["mesas"] += 1
	col["coringas_postos"].append(int(m.stats["coringas_postos"]))
	col["pos_total"] += pos_total
	col["pos_coringa"] += pos_coringa
	col["colheitas"] += int(m.stats["colheitas"])
	col["colheitas_com_coringa"] += int(m.stats["colheitas_com_coringa"])
	col["pontos_ev_total"] += int(m.stats["pontos_total_eventos"])
	col["pontos_ev_coringa"] += int(m.stats["pontos_com_coringa"])
	col["quinas"] += int(m.stats["quinas"])
	col["reais"] += int(m.stats["reais"])
	col["carimbos"] += int(m.stats["carimbos"])
	col["residuo_morto"] += res_morto
	col["duplo_pulso"] += int(m.stats["duplo_pulso"])
	col["pulsos"] += int(m.stats["pulsos"])
	col["c3_coringa"] += int(m.stats["c3_coringa"])
	col["agulhas_criadas"].append(m.agulhas_criadas)
	col["avessos_forjados"].append(m.avessos_forjados)
	col["pontos_pulso"].append(int(m.stats["pontos_pulso"]))
	for e in m.stats["espera_forja_uso"]: col["espera"].append(e)
	if m.stats["viu_coringa"]:
		col["mesas_com_coringa"] += 1
		col["turno_1o"].append(int(m.stats["turno_1o_achado"]))
	for i in range(25): col["heat"][i] += int(m.stats["heat"][i])
	if not col["por_rodada"].has(rodada): col["por_rodada"][rodada] = [0, 0]
	col["por_rodada"][rodada][0] += 1
	if venceu: col["por_rodada"][rodada][1] += 1
	# derrota decidida aos 2/3
	if not venceu and pontos_marco >= 0:
		col["derrotas"] += 1
		if float(pontos_marco) < 0.45 * float(m.meta): col["derrotas_decididas"] += 1

func novo() -> Dictionary:
	var h := []
	h.resize(25)
	for i in range(25): h[i] = 0
	return {"gaps": [], "seca": [], "tear": [], "turnos": [], "pct_turno_rec": [],
		"razao": [], "pontos": [], "n_eventos": [], "cruzes": [], "maior_evento": [],
		"maior_evento_meta": [], "maior_evento_venc_meta": [], "eventos_pontos": [],
		"n_por_evento": [], "coringas_postos": [], "agulhas_criadas": [],
		"avessos_forjados": [], "espera": [], "turno_1o": [], "pontos_pulso": [],
		"vitorias": 0, "mesas": 0, "por_rodada": {}, "heat": h,
		"pos_total": 0, "pos_coringa": 0, "colheitas": 0, "colheitas_com_coringa": 0,
		"pontos_ev_total": 0, "pontos_ev_coringa": 0, "quinas": 0, "reais": 0,
		"carimbos": 0, "residuo_morto": 0, "duplo_pulso": 0, "pulsos": 0,
		"c3_coringa": 0, "mesas_com_coringa": 0, "derrotas": 0, "derrotas_decididas": 0,
		"m5_total": 0, "m5_iguais": 0,
		"outs_com_n": 0, "outs_com_sim": 0, "outs_sem_n": 0, "outs_sem_sim": 0}

func rodar(cfg: Dictionary, n: int, n_m5: int, politica: int) -> Dictionary:
	var col := novo()
	for t in range(n):
		var rodada := (t % 6) + 1
		var tipo := int(t / 6) % 3
		jogar(rodada, tipo, SEED0 + t * 7919, cfg, politica, t < n_m5, col)
	var vr := {}
	for k in col["por_rodada"].keys():
		vr[str(k)] = snappedf(100.0 * float(col["por_rodada"][k][1]) / float(col["por_rodada"][k][0]), 0.1)
	var mediana_ev = pct(col["eventos_pontos"], 0.5)
	var pico = pct(col["maior_evento"], 1.0)
	var n1 := 0; var n2 := 0; var n3 := 0; var n4 := 0
	for x in col["n_por_evento"]:
		if x == 1: n1 += 1
		elif x == 2: n2 += 1
		elif x == 3: n3 += 1
		else: n4 += 1
	var tot_ev: int = max(1, col["n_por_evento"].size())
	var zc := 0
	for x in col["cruzes"]:
		if x == 0: zc += 1
	return {
		"mesas": col["mesas"],
		"m5_pct": (snappedf(100.0 * float(col["m5_iguais"]) / float(col["m5_total"]), 0.1) if col["m5_total"] > 0 else null),
		"m5_n": col["m5_total"],
		"pct_turnos_com_recompensa": snappedf(100.0 * media(col["pct_turno_rec"]), 0.1),
		"turnos_entre_recompensas_mediana": pct(col["gaps"], 0.5),
		"turnos_entre_recompensas_p90": pct(col["gaps"], 0.9),
		"seca_mediana": pct(col["seca"], 0.5),
		"seca_p90": pct(col["seca"], 0.9),
		"eventos_por_mesa_media": snappedf(media(col["n_eventos"]), 0.01),
		"cruzes_por_mesa_media": snappedf(media(col["cruzes"]), 0.001),
		"pct_mesas_com_zero_cruz": snappedf(100.0 * float(zc) / float(max(1, col["mesas"])), 0.1),
		"cascatas_por_mesa_media": 0.0,
		"maior_cadeia_observada": 0,
		"pontos_por_mesa_mediana": pct(col["pontos"], 0.5),
		"razao_pontos_meta_mediana": snappedf(float(pct(col["razao"], 0.5)), 0.001),
		"maior_evento_unico": pico,
		"evento_mediano": mediana_ev,
		"razao_pico_sobre_mediana": (snappedf(float(pico) / float(mediana_ev), 0.01) if mediana_ev != null and int(mediana_ev) > 0 else null),
		"maior_evento_sobre_meta_p50": snappedf(float(pct(col["maior_evento_meta"], 0.5)), 0.001),
		"maior_evento_sobre_meta_p90": snappedf(float(pct(col["maior_evento_meta"], 0.9)), 0.001),
		"tear_mediano": pct(col["tear"], 0.5),
		"tear_max": pct(col["tear"], 1.0),
		"vitoria_pct": snappedf(100.0 * float(col["vitorias"]) / float(max(1, col["mesas"])), 0.01),
		"vitoria_por_rodada": vr,
		"turnos_por_mesa_mediana": pct(col["turnos"], 0.5),
		"pontos_pulso_mediana": pct(col["pontos_pulso"], 0.5),
		"derrota_decidida_2_3_pct": (snappedf(100.0 * float(col["derrotas_decididas"]) / float(col["derrotas"]), 0.1) if col["derrotas"] > 0 else null),
		"n_linhas_por_evento": {"n1": snappedf(100.0*float(n1)/float(tot_ev),0.01), "n2": snappedf(100.0*float(n2)/float(tot_ev),0.01),
			"n3": snappedf(100.0*float(n3)/float(tot_ev),0.01), "n4": snappedf(100.0*float(n4)/float(tot_ev),0.01)},
		# --- coringa ---
		"coringas_por_mesa_media": snappedf(media(col["coringas_postos"]), 0.01),
		"coringas_criados_por_mesa": snappedf(media(col["agulhas_criadas"]) + media(col["avessos_forjados"]), 0.01),
		"pct_posicionamentos_coringa": snappedf(100.0 * float(col["pos_coringa"]) / float(max(1, col["pos_total"])), 0.1),
		"pct_pontos_via_coringa": (snappedf(100.0 * float(col["pontos_ev_coringa"]) / float(col["pontos_ev_total"]), 0.1) if col["pontos_ev_total"] > 0 else null),
		"pct_colheitas_com_coringa": (snappedf(100.0 * float(col["colheitas_com_coringa"]) / float(col["colheitas"]), 0.1) if col["colheitas"] > 0 else null),
		"pct_mesas_que_veem_coringa": snappedf(100.0 * float(col["mesas_com_coringa"]) / float(max(1, col["mesas"])), 0.1),
		"turno_mediano_1o_achado": pct(col["turno_1o"], 0.5),
		"espera_forja_uso_mediana": pct(col["espera"], 0.5),
		"taxa_residuo_morto_pct": (snappedf(100.0 * float(col["residuo_morto"]) / float(col["carimbos"]), 0.1) if col["carimbos"] > 0 else null),
		"carimbos_por_mesa": snappedf(float(col["carimbos"]) / float(max(1, col["mesas"])), 0.01),
		"pct_coringa_em_C3": (snappedf(100.0 * float(col["c3_coringa"]) / float(col["pos_coringa"]), 0.1) if col["pos_coringa"] > 0 else null),
		"pct_coringa_duplo_pulso": (snappedf(100.0 * float(col["duplo_pulso"]) / float(col["pos_coringa"]), 0.1) if col["pos_coringa"] > 0 else null),
		"quinas_por_mesa": snappedf(float(col["quinas"]) / float(max(1, col["mesas"])), 0.001),
		"reais_por_mesa": snappedf(float(col["reais"]) / float(max(1, col["mesas"])), 0.001),
		"p_out_cruz_com_coringa": (snappedf(100.0*float(col["outs_com_sim"])/float(col["outs_com_n"]),0.1) if col["outs_com_n"]>0 else null),
		"p_out_cruz_sem_coringa": (snappedf(100.0*float(col["outs_sem_sim"])/float(col["outs_sem_n"]),0.1) if col["outs_sem_n"]>0 else null),
		"outs_brutos": {"turnos_com_coringa_na_mao": col["outs_com_n"], "desses_com_jogada_de_cruz": col["outs_com_sim"],
			"turnos_sem_coringa_na_mao": col["outs_sem_n"], "desses_sem_com_jogada_de_cruz": col["outs_sem_sim"]},
		"heat": col["heat"],
	}
