extends SceneTree

var ok := 0
var falhas := []

func check(nome: String, cond: bool, extra: String = "") -> void:
	if cond: ok += 1
	else: falhas.append(nome + " " + extra)

func _init() -> void:
	Nucleo.init_estatico()
	# --- codificacao do AVESSO ---
	var ida_volta := true
	for a in range(52):
		for b in range(52):
			var c := Mesa2.forjar(a, b)
			if Mesa2.face(c, true) != a or Mesa2.face(c, false) != b: ida_volta = false
			if Mesa2.girar(Mesa2.girar(c)) != c: ida_volta = false
	check("_codificacao_ida_e_volta + _giro_e_involucao", ida_volta)
	check("_avesso_nao_colide_com_carta_normal", not Mesa2.eh_avesso(51) and Mesa2.eh_avesso(1024))
	check("_agulha_nao_colide", Mesa2.eh_agulha(100) and not Mesa2.eh_agulha(51) and not Mesa2.eh_agulha(1024))

	# --- avesso le faces diferentes na linha e na coluna ---
	var cfg := Mesa2.cfg_padrao()
	cfg["avesso"] = true
	var m := Mesa2.new(1, 2, -1, cfg)   # tipo 2 = sem semeadura; semente -1 = clone vazio
	# linha 0 = casas 0..4 ; coluna 0 = casas 0,5,10,15,20
	# K de espadas = 12 ; 2 de copas = 14
	var av := Mesa2.forjar(12, 14)
	m._por_carta(0, av)
	var cs_lin := m._cartas_linha(0, -1, -1)
	var cs_col := m._cartas_linha(5, -1, -1)
	check("_avesso_faces_por_eixo", cs_lin[0] == 12 and cs_col[0] == 14, str(cs_lin) + str(cs_col))
	check("_avesso_fichas_seguem_a_face",
		Nucleo.fichas_carta(cs_lin[0]) == 10 and Nucleo.fichas_carta(cs_col[0]) == 2,
		str(Nucleo.fichas_carta(cs_lin[0])) + "/" + str(Nucleo.fichas_carta(cs_col[0])))
	var cs_diag := m._cartas_linha(10, -1, -1)   # diagonal principal passa por 0
	check("_avesso_diagonal_usa_face_avesso", cs_diag[0] == 14)

	# --- DOBRA: colheita de linha forja um avesso das pontas ---
	var m2 := Mesa2.new(1, 1, 777, cfg)
	m2.grade.fill(-1); m2.conta.fill(0)
	# monta linha 0 com 4 cartas, pontas conhecidas
	m2._por_carta(0, 12)   # K espadas (ponta inicial)
	m2._por_carta(1, 1)
	m2._por_carta(2, 2)
	m2._por_carta(3, 3)
	var n_bar := m2.baralho.size()
	m2.posicionar(4, 4, 1)   # 5 de espadas na ponta final
	check("_dobra_forja_um_avesso", m2.avessos_forjados == 1 and m2.baralho.size() == n_bar + 1,
		str(m2.avessos_forjados) + "/" + str(m2.baralho.size() - n_bar))
	var forjado: int = m2.baralho[m2.baralho.size() - 1]
	check("_dobra_usa_as_pontas", Mesa2.eh_avesso(forjado) and Mesa2.face(forjado, true) == 12 and Mesa2.face(forjado, false) == 4,
		str(Mesa2.face(forjado, true)) + "/" + str(Mesa2.face(forjado, false)))
	check("_dobra_esvazia_a_linha", m2.conta[0] == 0)

	# --- conservacao de FACES ---
	var cfg3 := Mesa2.cfg_padrao()
	cfg3["avesso"] = true
	var b := Bancada.new()
	var conserva := true
	for s in range(30):
		var mm := Mesa2.new(1 + s % 6, s % 3, 4242 + s * 31, cfg3)
		var alvo: int = mm.conservacao()[0]
		var turno := 0
		while mm.posic_usados < mm.posic_max and mm.pontos < mm.meta:
			turno += 1
			if mm.mao.is_empty(): break
			var mv := b.movimentos(mm)
			if mv["lista"].is_empty(): break
			var e = b.melhor_gulosa(mv["lista"])
			mm.posicionar(e[6], e[1], turno)
			mm.mao.remove_at(e[0])
			mm.comprar_mao()
			if mm.conservacao()[0] != alvo:
				conserva = false
				break
	check("_conservacao_das_pilhas_conta_faces", conserva)

	# --- conservacao com AGULHAS: faces == 52 + carimbos ; vivas + carimbos == criadas ---
	var cfg_ag := Mesa2.cfg_padrao()
	cfg_ag["agulha"] = true
	var cons_ag := true
	for s2 in range(30):
		var mm2 := Mesa2.new(1 + s2 % 6, s2 % 3, 8181 + s2 * 37, cfg_ag)
		var turno2 := 0
		while mm2.posic_usados < mm2.posic_max and mm2.pontos < mm2.meta:
			turno2 += 1
			if mm2.mao.is_empty(): break
			var mv2 := b.movimentos(mm2)
			if mv2["lista"].is_empty(): break
			var e2 = b.melhor_gulosa(mv2["lista"])
			mm2.posicionar(e2[6], e2[1], turno2)
			mm2.mao.remove_at(e2[0])
			mm2.comprar_mao()
			var cc := mm2.conservacao()
			if int(cc[0]) != 52 + int(mm2.stats["carimbos"]): cons_ag = false
			if int(cc[1]) + int(mm2.stats["carimbos"]) != mm2.agulhas_criadas: cons_ag = false
			if not cons_ag: break
	check("_conservacao_com_agulhas", cons_ag)

	# --- AGULHA: uma identidade em todas as linhas / fica carimbada ---
	var cfg4 := Mesa2.cfg_padrao()
	cfg4["agulha"] = true
	var m4 := Mesa2.new(1, 1, 999, cfg4)
	m4.grade.fill(-1); m4.conta.fill(0)
	# linha 0: tres reis + agulha  -> agulha deve virar rei (quadra)
	m4._por_carta(0, 12)
	m4._por_carta(1, 25)
	m4._por_carta(2, 38)
	m4._por_carta(3, Mesa2.AGULHA_BASE)
	var r4 := m4._av_linha(m4._cartas_linha(0, 4, 5))
	check("_agulha_escolhe_a_identidade_que_maximiza", int(r4[0]) == Nucleo.QUADRA, str(r4))
	var vazias_antes := m4.casas_vazias().size()
	m4.posicionar(5, 4, 1)
	var vazias_dep := m4.casas_vazias().size()
	check("_agulha_fica_e_carimba_colheita_esvazia_4", vazias_dep - vazias_antes == 3,
		"delta=" + str(vazias_dep - vazias_antes))
	check("_agulha_carimbada_e_carta_comum", m4.grade[3] >= 0 and m4.grade[3] < 52 and m4.costuradas.has(3),
		str(m4.grade[3]))

	# --- bloqueio: nao pode duas agulhas vivas na mesma linha ---
	var m5 := Mesa2.new(1, 1, 111, cfg4)
	m5.grade.fill(-1); m5.conta.fill(0)
	m5._por_carta(0, Mesa2.AGULHA_BASE)
	check("_pode_posicionar_recusa_segunda_agulha_viva_na_linha",
		not m5.pode_posicionar(Mesa2.AGULHA_BASE + 1, 3) and m5.pode_posicionar(7, 3),
		"")
	check("_agulha_livre_em_linha_sem_agulha", m5.pode_posicionar(Mesa2.AGULHA_BASE + 1, 19))

	# --- degradacao: cfg sem coringa == nucleo com pulso+tique ---
	var cfgn := Mesa2.cfg_padrao()
	var iguais := true
	for s in range(10):
		var a1 := Mesa2.new(2, 0, 555 + s, cfgn)
		var a2 := Mesa2.new(2, 0, 555 + s, cfgn)
		if a1.mao != a2.mao or a1.grade != a2.grade: iguais = false
	check("_determinismo_por_semente", iguais)

	print("ASSERCOES OK: ", ok, "  FALHAS: ", falhas.size())
	for f in falhas: print("  FALHOU: ", f)
	quit()
