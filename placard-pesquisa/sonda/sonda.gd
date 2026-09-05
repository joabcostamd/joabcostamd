extends SceneTree

const N_MESAS := 2000
const N_MESAS_PROF := 2000
const N_MESAS_M5 := 500
const DEEP_K := 8
const DEEP_S := 4

var out := {}

# --------------------------- utilidades estatisticas -----------------------
func media(a: Array) -> float:
	if a.is_empty(): return 0.0
	var s := 0.0
	for x in a: s += float(x)
	return s / a.size()

func pct(a: Array, p: float):
	if a.is_empty(): return null
	var b := a.duplicate()
	b.sort()
	var i := int(round((b.size() - 1) * p))
	return b[i]

func resumo(a: Array) -> Dictionary:
	if a.is_empty():
		return {"n": 0, "media": null, "mediana": null, "p90": null, "max": null, "min": null}
	return {
		"n": a.size(),
		"media": snappedf(media(a), 0.001),
		"mediana": pct(a, 0.5),
		"p90": pct(a, 0.9),
		"max": pct(a, 1.0),
		"min": pct(a, 0.0),
	}

# --------------------------- potencial de linha ----------------------------
const PESO_K := [0.0, 0.02, 0.08, 0.30, 0.75, 1.0]

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
	# valor projetado da linha SE completar, x peso convexo do progresso
	var fich_proj := float(fich) * 5.0 / float(k)
	var v: float = (float(m.base_de(cat)) + fich_proj) * float(m.mult_de(cat) + m.tear) * PESO_K[k]
	if Nucleo.DIAG[li]: v *= 0.6
	return v

# devolve dicionario com movimentos e estatisticas do turno
func movimentos(m: Mesa) -> Dictionary:
	var vazias := m.casas_vazias()
	var criticas := {}
	for c in m.casas_criticas(): criticas[c] = true
	# potencial atual por linha
	var pot_now := []
	pot_now.resize(12)
	for li in range(12): pot_now[li] = pot_linha(m, li, -1)
	# potencial por (carta, linha)
	var pot_add := []
	for i in range(m.mao.size()):
		var linha_pot := []
		linha_pot.resize(12)
		for li in range(12):
			linha_pot[li] = pot_linha(m, li, m.mao[i])
		pot_add.append(linha_pot)
	var lista := []
	var ganhos := {}
	var melhor_im := 0
	for i in range(m.mao.size()):
		for casa in vazias:
			var im := 0
			var nl := 0
			if criticas.has(casa):
				var g := m.ganho(casa, m.mao[i])
				im = g[0]; nl = g[1]
			var dp := 0.0
			for li in Nucleo.CELL_LINHAS[casa]:
				dp += float(pot_add[i][li]) - float(pot_now[li])
			lista.append([i, casa, im, dp, float(im) * 1000000.0 + dp, nl])
			ganhos[im] = true
			if im > melhor_im: melhor_im = im
	return {
		"lista": lista,
		"n_legais": lista.size(),
		"n_distintos": ganhos.size(),
		"melhor_imediato": melhor_im,
		"pot_now": pot_now,
		"pot_add": pot_add,
	}

func melhor_gulosa(lista: Array) -> Array:
	var b = lista[0]
	for mv in lista:
		if mv[4] > b[4]: b = mv
	return b

func segunda_gulosa(lista: Array, melhor: Array) -> float:
	var s := -1.0e30
	for mv in lista:
		if mv[0] == melhor[0] and mv[1] == melhor[1]: continue
		if mv[4] > s: s = mv[4]
	return s

# --------------------------- politica profunda -----------------------------
func melhor_profunda(m: Mesa, lista: Array, rng: Mesa.Rng) -> Array:
	var ord := lista.duplicate()
	ord.sort_custom(func(a, b): return a[4] > b[4])
	var k: int = min(DEEP_K, ord.size())
	var pool: Array = m.baralho + m.descarte
	var melhor = ord[0]
	var melhor_v := -1.0e30
	for idx in range(k):
		var mv = ord[idx]
		var sim := m.clone_leve()
		sim.aplicar_seco(mv[1], m.mao[mv[0]])
		var mao2 := []
		for i in range(m.mao.size()):
			if i != mv[0]: mao2.append(m.mao[i])
		var soma := 0.0
		var crit := sim.casas_criticas()
		if pool.is_empty() or crit.is_empty():
			soma = 0.0
		else:
			for s in range(DEEP_S):
				var nova: int = pool[rng.inteiro(pool.size())]
				var mm: Array = mao2 + [nova]
				var best := 0
				for c in mm:
					for casa in crit:
						var g := sim.ganho(casa, c)
						if g[0] > best: best = g[0]
				soma += float(best)
		var v: float = float(mv[2]) + 0.9 * (soma / float(DEEP_S)) + 0.000001 * float(mv[3])
		if v > melhor_v:
			melhor_v = v
			melhor = mv
	return melhor

# ------------------- politica cacadora de cruz ---------------------------
# Igual a gulosa, mas DESCONTA o valor de fechar uma linha sozinha quando a
# perpendicular daquela casa esta a caminho de tambem fechar (arma a cruz).
func melhor_cacadora_de_cruz(m: Mesa, lista: Array) -> Array:
	var restam: int = m.posic_max - m.posic_usados
	# 1) se alguma jogada fecha 2+ linhas, e cruz: pega a melhor delas
	var melhor = null
	var melhor_v := -1.0e30
	for mv in lista:
		if mv[5] >= 2:
			var sc: float = float(mv[2]) * 1000000.0 + float(mv[3])
			if sc > melhor_v:
				melhor_v = sc; melhor = mv
	if melhor != null:
		return melhor
	# 2) proibe queimar uma casa de cruzamento que ainda da para armar
	var permitidos := []
	for mv in lista:
		var proibido := false
		if mv[5] == 1:
			var casa: int = mv[1]
			var melhor_outra := 0
			for li in Nucleo.CELL_LINHAS[casa]:
				if m.conta[li] < 4 and m.conta[li] > melhor_outra:
					melhor_outra = m.conta[li]
			var faltam: int = 4 - melhor_outra
			if melhor_outra >= 2 and restam >= faltam + 1:
				proibido = true
		if not proibido:
			permitidos.append(mv)
	if permitidos.is_empty():
		permitidos = lista
	return melhor_gulosa(permitidos)

# --------------------------- descarte heuristico ---------------------------
func talvez_descartar(m: Mesa, mv: Dictionary) -> bool:
	if m.descartes_usados >= m.descartes_max: return false
	if mv["melhor_imediato"] > 0: return false          # nao troca quando da para colher agora
	if m.posic_max - m.posic_usados < 4: return false   # tarde demais para investir
	# utilidade de cada carta = melhor delta de potencial que ela consegue em qualquer casa
	var util := []
	var best := -1.0e30
	for i in range(m.mao.size()):
		var u := -1.0e30
		for casa in m.casas_vazias():
			var dp := 0.0
			for li in Nucleo.CELL_LINHAS[casa]:
				dp += float(mv["pot_add"][i][li]) - float(mv["pot_now"][li])
			if dp > u: u = dp
		util.append([i, u])
		if u > best: best = u
	# cartas mortas: rendem menos de 35% do que a melhor carta da mao rende
	var corte: float = (best * 0.35 if best > 0.0 else best)
	var fracas := []
	for x in util:
		if x[1] < corte: fracas.append(x[0])
	if fracas.size() < 2:
		return false
	if fracas.size() > 3:
		util.sort_custom(func(a, b): return a[1] < b[1])
		fracas = [util[0][0], util[1][0], util[2][0]]
	m.trocar(fracas)
	return true

# --------------------------- uma mesa --------------------------------------
# politica: 0 gulosa, 1 aleatoria, 2 profunda
func jogar(rodada: int, tipo: int, semente: int, politica: int, niveis: Array, coletar_m5: bool, col: Dictionary) -> Dictionary:
	var m := Mesa.new(rodada, tipo, semente, niveis)
	var rng := Mesa.Rng.new(Mesa.mix(semente, 999, politica))
	var eventos := []
	var turnos_com_ponto := []
	var cruzes := 0
	var turno := 0
	var marco := int(floor(m.posic_max * 2.0 / 3.0))
	var pontos_no_marco := -1
	var usou_descarte := 0
	while m.posic_usados < m.posic_max and m.pontos < m.meta:
		turno += 1
		if m.mao.is_empty(): break
		var mv := movimentos(m)
		if mv["lista"].is_empty(): break
		# estatisticas de ramificacao
		col["m1"].append(mv["n_legais"])
		while col["m1_por_turno"].size() < turno: col["m1_por_turno"].append([])
		col["m1_por_turno"][turno - 1].append(mv["n_legais"])
		col["m2"].append(mv["n_distintos"])
		col["turnos_total"] += 1
		if mv["melhor_imediato"] > 0: col["turnos_com_ganho_possivel"] += 1
		# descarte
		if politica != 1:
			if talvez_descartar(m, mv):
				usou_descarte += 1
				mv = movimentos(m)
				if mv["lista"].is_empty(): break
		var escolha
		if politica == 1:
			escolha = mv["lista"][rng.inteiro(mv["lista"].size())]
		elif politica == 0:
			escolha = melhor_gulosa(mv["lista"])
		elif politica == 3:
			escolha = melhor_cacadora_de_cruz(m, mv["lista"])
		else:
			escolha = melhor_profunda(m, mv["lista"], rng)
		# margem do topo (sempre pela ordenacao gulosa)
		if politica != 1:
			var b := melhor_gulosa(mv["lista"])
			var s := segunda_gulosa(mv["lista"], b)
			if b[2] > 0:
				var m2nd := 0.0
				for x in mv["lista"]:
					if (x[0] != b[0] or x[1] != b[1]) and float(x[2]) > m2nd: m2nd = float(x[2])
				col["m6_pontos"].append(snappedf(100.0 * (float(b[2]) - m2nd) / float(b[2]), 0.01))
			if abs(b[4]) > 0.0000001 and s > -1.0e29:
				col["m6_score"].append(snappedf(100.0 * (b[4] - s) / abs(b[4]), 0.01))
		# m5: concordancia gulosa x profunda
		if coletar_m5:
			var bg := melhor_gulosa(mv["lista"])
			var bp := melhor_profunda(m, mv["lista"], Mesa.Rng.new(Mesa.mix(semente, turno, 4242)))
			col["m5_total"] += 1
			if bg[0] == bp[0] and bg[1] == bp[1]:
				col["m5_iguais"] += 1
			# margem pela avaliacao profunda tambem
		var g := m.posicionar(escolha[0], escolha[1])
		if g[0] > 0:
			eventos.append(g[0])
			turnos_com_ponto.append(turno)
			col["m4"].append(g[0])
			if g[1] >= 2:
				cruzes += 1
				col["m4_cruz"].append(g[0])
			else:
				col["m4_simples"].append(g[0])
		if m.posic_usados == marco:
			pontos_no_marco = m.pontos
	var venceu := m.pontos >= m.meta
	var pontos_jogo := m.pontos
	var final_pts := 0
	if not venceu:
		final_pts = m.colheita_final()
	# intervalos entre eventos (m3) e seca (m9)
	var gaps := []
	var ant := 0
	for t in turnos_com_ponto:
		gaps.append(t - ant)
		ant = t
	var seca := 0
	var atual := 0
	var setp := {}
	for t in turnos_com_ponto: setp[t] = true
	for t in range(1, turno + 1):
		if setp.has(t):
			atual = 0
		else:
			atual += 1
			if atual > seca: seca = atual
	if turno > 0 and not setp.has(turno):
		pass
	for gp in gaps: col["m3"].append(gp)
	if not gaps.is_empty():
		col["m3_maior_por_mesa"].append(gaps.max())
	else:
		col["m3_maior_por_mesa"].append(turno)
	col["m8"].append(cruzes)
	col["m9"].append(seca)
	col["m10"].append(m.tear)
	col["m11"].append(turno)
	col["m7"][rodada - 1][tipo][0] += 1
	if venceu: col["m7"][rodada - 1][tipo][1] += 1
	col["razao_meta"].append(snappedf(float(m.pontos) / float(m.meta), 0.001))
	col["n_eventos"].append(eventos.size())
	col["pontos_finais"].append(m.pontos)
	col["colheita_final"].append(final_pts)
	col["descartes"].append(usou_descarte)
	return {
		"venceu": venceu,
		"rodada": rodada, "tipo": tipo,
		"meta": m.meta,
		"pontos_marco": pontos_no_marco,
		"pontos_final": m.pontos,
		"pontos_jogo": pontos_jogo,
		"turnos": turno,
	}

func novo_coletor() -> Dictionary:
	var m7 := []
	for r in range(6):
		var linha := []
		for t in range(3): linha.append([0, 0])
		m7.append(linha)
	return {
		"m1": [], "m1_por_turno": [], "m2": [], "m3": [], "m3_maior_por_mesa": [],
		"m4": [], "m4_cruz": [], "m4_simples": [],
		"m6_pontos": [], "m6_score": [],
		"m5_total": 0, "m5_iguais": 0, "turnos_total": 0, "turnos_com_ganho_possivel": 0,
		"m7": m7, "m8": [], "m9": [], "m10": [], "m11": [],
		"razao_meta": [], "n_eventos": [], "colheita_final": [], "descartes": [], "pontos_finais": [],
	}

func rodar_politica(politica: int, n: int, base_seed: int, niveis: Array, coletar_m5: bool) -> Dictionary:
	var col := novo_coletor()
	var mesas := []
	for t in range(n):
		var rodada := 1 + (t % 6)
		var tipo := int(t / 6) % 3
		var semente := base_seed + t * 7919
		mesas.append(jogar(rodada, tipo, semente, politica, niveis, coletar_m5, col))
	return {"col": col, "mesas": mesas}

func m12_calc(mesas: Array) -> Dictionary:
	# teto realista empirico: p95 do que foi pontuado depois do marco de 2/3,
	# por (rodada, tipo), medido no proprio corpus.
	var ganhos := {}
	for x in mesas:
		if x["pontos_marco"] < 0: continue
		var k = str(x["rodada"]) + "_" + str(x["tipo"])
		if not ganhos.has(k): ganhos[k] = []
		ganhos[k].append(x["pontos_final"] - x["pontos_marco"])
	var teto := {}
	for k in ganhos.keys():
		teto[k] = pct(ganhos[k], 0.95)
	var derrotas := 0
	var perdidas := 0
	for x in mesas:
		if x["venceu"]: continue
		derrotas += 1
		if x["pontos_marco"] < 0:
			continue
		var k = str(x["rodada"]) + "_" + str(x["tipo"])
		if not teto.has(k): continue
		if float(x["meta"] - x["pontos_marco"]) > float(teto[k]):
			perdidas += 1
	return {
		"derrotas": derrotas,
		"ja_perdidas_no_marco_2_3": perdidas,
		"pct": (snappedf(100.0 * float(perdidas) / float(derrotas), 0.01) if derrotas > 0 else null),
		"criterio": "teto realista = p95 empirico dos pontos feitos apos o marco de 2/3 dos posicionamentos, por (rodada,tipo), no mesmo corpus",
	}

func m7_dict(col: Dictionary) -> Dictionary:
	var d := {}
	var nomes := ["pequena", "grande", "chefe"]
	var tot := 0
	var tot_v := 0
	for r in range(6):
		for t in range(3):
			var n: int = col["m7"][r][t][0]
			var v: int = col["m7"][r][t][1]
			tot += n; tot_v += v
			d["r" + str(r + 1) + "_" + nomes[t]] = {
				"n": n, "vitorias": v,
				"taxa": (snappedf(100.0 * float(v) / float(n), 0.01) if n > 0 else null)
			}
	d["global"] = {"n": tot, "vitorias": tot_v, "taxa": (snappedf(100.0 * float(tot_v) / float(tot), 0.01) if tot > 0 else null)}
	return d

func empacotar(nome: String, r: Dictionary) -> Dictionary:
	var col: Dictionary = r["col"]
	var mesas: Array = r["mesas"]
	var m1t := {}
	for i in range(col["m1_por_turno"].size()):
		m1t["turno_" + str(i + 1)] = snappedf(media(col["m1_por_turno"][i]), 0.01)
	var m3r := resumo(col["m3"])
	var med4 = pct(col["m4"], 0.5)
	var mx4 = pct(col["m4"], 1.0)
	var zero_cruz := 0
	for x in col["m8"]:
		if x == 0: zero_cruz += 1
	return {
		"politica": nome,
		"mesas_simuladas": mesas.size(),
		"m1_ramificacao": {
			"pares_legais_por_turno": resumo(col["m1"]),
			"media_por_indice_de_turno": m1t,
		},
		"m2_jogadas_distintas": {
			"resultados_imediatos_distintos_por_turno": resumo(col["m2"]),
			"pct_turnos_em_que_alguma_jogada_pontua": snappedf(100.0 * float(col["turnos_com_ganho_possivel"]) / float(col["turnos_total"]), 0.01),
			"pct_turnos_em_que_NENHUMA_jogada_pontua": snappedf(100.0 - 100.0 * float(col["turnos_com_ganho_possivel"]) / float(col["turnos_total"]), 0.01),
			"nota": "conta valores distintos de ganho imediato de pontos entre TODOS os pares legais do turno; 1 = todas as jogadas do turno pontuam igual (quase sempre zero)",
		},
		"m3_intervalo_recompensa": {
			"turnos_entre_colheitas": m3r,
			"segundos_entre_colheitas_a_4s": {
				"media": (snappedf(float(m3r["media"]) * 4.0, 0.01) if m3r["media"] != null else null),
				"mediana": (float(m3r["mediana"]) * 4.0 if m3r["mediana"] != null else null),
				"p90": (float(m3r["p90"]) * 4.0 if m3r["p90"] != null else null),
				"max": (float(m3r["max"]) * 4.0 if m3r["max"] != null else null),
			},
			"maior_intervalo_por_mesa": resumo(col["m3_maior_por_mesa"]),
		},
		"m4_magnitude": {
			"pontos_por_evento": resumo(col["m4"]),
			"fator_explosao_max_sobre_mediana": (snappedf(float(mx4) / float(med4), 0.01) if (med4 != null and float(med4) > 0) else null),
			"eventos_simples": resumo(col["m4_simples"]),
			"eventos_cruz": resumo(col["m4_cruz"]),
			"razao_mediana_cruz_sobre_simples": (snappedf(float(pct(col["m4_cruz"], 0.5)) / float(pct(col["m4_simples"], 0.5)), 0.01) if (not col["m4_cruz"].is_empty() and not col["m4_simples"].is_empty() and float(pct(col["m4_simples"], 0.5)) > 0) else null),
			"colheita_final_r14b": resumo(col["colheita_final"]),
		},
		"m6_margem_do_topo": {
			"pct_pontos_quando_ha_colheita_disponivel": resumo(col["m6_pontos"]),
			"pct_score_gulosa_todos_os_turnos": resumo(col["m6_score"]),
			"nota": "pct_pontos so existe nos turnos em que a melhor jogada pontua > 0; nos demais a diferenca e so de potencial posicional",
		},
		"m7_taxa_vitoria": m7_dict(col),
		"m8_cruz": {
			"por_mesa": resumo(col["m8"]),
			"pct_mesas_com_zero_cruz": snappedf(100.0 * float(zero_cruz) / float(col["m8"].size()), 0.01),
		},
		"m9_seca": {"maior_sequencia_sem_pontuar_por_mesa": resumo(col["m9"])},
		"m10_tear": {"tear_ao_fim_da_mesa": resumo(col["m10"]), "distribuicao": _hist(col["m10"])},
		"m11_turnos_por_mesa": resumo(col["m11"]),
		"m12_derrota_previsivel": m12_calc(mesas),
		"extra_eventos_por_mesa": resumo(col["n_eventos"]),
		"extra_razao_pontos_meta": resumo(col["razao_meta"]),
		"extra_descartes_usados_por_mesa": resumo(col["descartes"]),
	}

# Limites duros derivados so da aritmetica das regras (R09, R11, R15, R42).
# Cada carta colhida sai da mesa para sempre (R04b), entao o numero de cartas
# que a mesa pode ter na vida inteira e fixo: posicionamentos + semeadura.
func _limites() -> Dictionary:
	var d := {}
	var nomes := ["pequena", "grande", "chefe"]
	var cartas := [15 + 3, 17, 19]
	for t in range(3):
		var n: int = cartas[t]
		# linha simples custa 5 cartas; cruz de 2 linhas custa 9 (a casa e compartilhada)
		var max_simples: int = int(floor(float(n) / 5.0))
		var max_cruzes: int = int(floor(float(n) / 9.0))
		# maximo de EVENTOS de pontuacao: cada evento consome >= 5 cartas
		var max_eventos: int = int(floor(float(n) / 5.0))
		d[nomes[t]] = {
			"posicionamentos": [15,17,19][t],
			"cartas_semeadas": (3 if t == 0 else 0),
			"cartas_que_a_mesa_ve_na_vida_inteira": n,
			"max_linhas_colhidas": int(floor(2.0 * float(n) / 9.0)) if n >= 9 else max_simples,
			"max_eventos_de_pontuacao": max_eventos,
			"max_cruzes_teorico": max_cruzes,
			"intervalo_minimo_entre_eventos_turnos": 5,
			"intervalo_minimo_entre_eventos_segundos_a_4s": 20,
			"tear_maximo_alcancavel": min(8, int(floor(2.0 * float(n) / 9.0)) if n >= 9 else max_simples),
		}
	d["nota"] = "Derivado da aritmetica das regras, nao da simulacao. Uma colheita manda 5 cartas para a pilha `colhida`, que nunca volta (R04b), e o orcamento de posicionamentos (R09) e fixo. Logo o numero de eventos de pontuacao por mesa tem teto duro de 3, e a banda da secao 7.4 (mediana de 1,5 a 2,5 cruzes por mesa) exige jogo perfeito em toda mesa - na Grande ela e impossivel (17 cartas < 18 necessarias para 2 cruzes)."
	return d

func _hist(a: Array) -> Dictionary:
	var d := {}
	for x in a:
		var k := str(x)
		d[k] = int(d.get(k, 0)) + 1
	return d

func _initialize() -> void:
	Nucleo.init_estatico()
	var t0 := Time.get_ticks_msec()
	var sem_niveis := [0,0,0,0,0,0,0,0,0,0,0]
	print("=== gulosa ===")
	var rg := rodar_politica(0, N_MESAS, 100000, sem_niveis, false)
	out["gulosa"] = empacotar("gulosa", rg)
	print("  ", Time.get_ticks_msec() - t0, " ms")
	print("=== aleatoria ===")
	var ra := rodar_politica(1, N_MESAS, 200000, sem_niveis, false)
	out["aleatoria"] = empacotar("aleatoria", ra)
	print("  ", Time.get_ticks_msec() - t0, " ms")
	print("=== profunda ===")
	var rp := rodar_politica(2, N_MESAS_PROF, 300000, sem_niveis, false)
	out["profunda"] = empacotar("profunda", rp)
	print("  ", Time.get_ticks_msec() - t0, " ms")
	# m5: concordancia gulosa x profunda ao longo da trajetoria GULOSA
	print("=== m5 (trajetoria gulosa) ===")
	var rm5 := rodar_politica(0, N_MESAS_M5, 400000, sem_niveis, true)
	var c5: Dictionary = rm5["col"]
	out["m5_topo_obvio"] = {
		"trajetoria": "gulosa",
		"turnos_avaliados": c5["m5_total"],
		"turnos_em_que_gulosa_igual_profunda": c5["m5_iguais"],
		"pct_concordancia": (snappedf(100.0 * float(c5["m5_iguais"]) / float(c5["m5_total"]), 0.01) if c5["m5_total"] > 0 else null),
		"mesas": N_MESAS_M5,
	}
	print("  ", Time.get_ticks_msec() - t0, " ms")
	# m5b: mesma medida ao longo da trajetoria PROFUNDA
	print("=== m5b (trajetoria profunda) ===")
	var rm5b := rodar_politica(2, N_MESAS_M5, 500000, sem_niveis, true)
	var c5b: Dictionary = rm5b["col"]
	out["m5b_topo_obvio_trajetoria_profunda"] = {
		"trajetoria": "profunda",
		"turnos_avaliados": c5b["m5_total"],
		"turnos_em_que_gulosa_igual_profunda": c5b["m5_iguais"],
		"pct_concordancia": (snappedf(100.0 * float(c5b["m5_iguais"]) / float(c5b["m5_total"]), 0.01) if c5b["m5_total"] > 0 else null),
		"mesas": N_MESAS_M5,
	}
	print("  ", Time.get_ticks_msec() - t0, " ms")
	print("=== cacadora de cruz ===")
	var rc := rodar_politica(3, N_MESAS, 600000, sem_niveis, false)
	out["cacadora_de_cruz"] = empacotar("cacadora_de_cruz", rc)
	print("  ", Time.get_ticks_msec() - t0, " ms")
	# limites estruturais (aritmetica pura, nao simulacao)
	out["limites_estruturais"] = _limites()
	# cenario secundario: proxy grosseiro de poder de build (niveis de mao)
	print("=== gulosa + proxy de poder ===")
	var por_rodada := {}
	for r in range(1, 7):
		var niv := []
		for i in range(11): niv.append(min(3, r - 1))
		var col := novo_coletor()
		var mesas := []
		for t in range(360):
			var tipo := t % 3
			mesas.append(jogar(r, tipo, 700000 + r * 100003 + t * 7919, 0, niv, false, col))
		por_rodada["r" + str(r)] = m7_dict(col)["global"]
	out["cenario_proxy_de_poder"] = {
		"descricao": "APROXIMACAO fora do nucleo: todas as categorias com nivel de mao = min(3, rodada-1). Nao e o jogo do documento (nao ha selos, reliquias, motores); serve so para mostrar quanto do gap de meta vem da ausencia de progressao.",
		"taxa_vitoria_por_rodada": por_rodada,
	}
	print("  total ", Time.get_ticks_msec() - t0, " ms")
	out["_meta_da_sonda"] = {
		"godot": "4.7.2",
		"mesas_por_politica": N_MESAS,
		"mesas_m5": N_MESAS_M5,
		"profundidade_busca": {"K_candidatos": DEEP_K, "S_amostras_de_compra": DEEP_S, "niveis": 2},
		"segundos_por_turno_assumidos": 4,
		"escopo": "somente nucleo: baralho, mao, grade 5x5, posicionamento, colheita, cruz, tear, meta, orcamento, R14b, R42. SEM loja, selos, reliquias, modificadores, niveis de mao, chefes, vidas, Fianca.",
		"ms_total": Time.get_ticks_msec() - t0,
	}
	var f := FileAccess.open("res://metricas.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print("escrito metricas.json")
	quit()
