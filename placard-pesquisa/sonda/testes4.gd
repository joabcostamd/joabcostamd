extends SceneTree
var ok := 0
var falhas := []
func check(nome: String, cond: bool, extra: String = "") -> void:
	if cond: ok += 1
	else: falhas.append(nome + " " + extra)

func cfgj(J: int) -> Dictionary:
	var c := Mesa2.cfg_padrao()
	c["produto"] = true; c["tear_ini"] = 1; c["teto_evento"] = false
	c["meta_k"] = 2.25; c["avesso"] = true; c["janela"] = J
	return c

func _init() -> void:
	Nucleo.init_estatico()
	var b := Bancada4.new()

	# ---- A) a linha cheia NAO sai da grade no turno em que enche ----
	var m := Mesa2.new(1, 1, 500, cfgj(1))
	m.grade.fill(-1); m.conta.fill(0); m.pontos = 0
	m._por_carta(1, 1); m._por_carta(2, 2); m._por_carta(3, 3); m._por_carta(4, 4)
	var r := m.posicionar(0, 0, 1)
	check("_A_linha_cheia_fica_na_grade", m.conta[0] == 5 and m.grade[0] != -1 and m.madura[0] == 1
		and int(r[1]) == 0, "conta=" + str(m.conta[0]) + " nlin=" + str(r[1]))
	check("_A_nao_pontuou_ainda", int(r[0]) == 0, str(r[0]))
	# posicionamento seguinte em casa neutra -> colhe
	var r2 := m.posicionar(20, 22, 2)
	check("_A_colhe_no_posicionamento_seguinte", int(r1_n(r2)) == 1 and m.conta[0] == 0 and m.grade[0] == -1,
		"nlin=" + str(r2[1]) + " conta=" + str(m.conta[0]))
	check("_A_pontuou_agora", int(r2[0]) > 0, str(r2[0]))
	check("_A_madura_limpa", m.madura[0] == 0)

	# ---- B) CRUZADA pela janela: linha fecha, coluna vai a 4/5, proxima carta fecha as duas ----
	var m2 := Mesa2.new(1, 1, 501, cfgj(1))
	m2.grade.fill(-1); m2.conta.fill(0); m2.pontos = 0
	for x in [[1,1],[2,2],[3,3],[4,4],[5,5],[10,6],[15,7]]:
		m2._por_carta(x[0], x[1])
	var rb := m2.posicionar(0, 0, 1)       # fecha a linha 0; coluna 0 vai a 4/5
	check("_B_linha_madura_coluna_em_4", m2.madura[0] == 1 and m2.conta[5] == 4 and int(rb[1]) == 0,
		"col=" + str(m2.conta[5]))
	var rb2 := m2.posicionar(8, 20, 2)     # fecha a coluna 0 -> as duas colhem juntas
	check("_B_CRUZADA_em_um_evento", int(rb2[1]) == 2, "nlin=" + str(rb2[1]))
	check("_B_grade_esvaziou_as_9_casas", m2.conta[0] == 0 and m2.conta[5] == 0)

	# ---- C) ultimo posicionamento colhe na hora (regra 5) ----
	var m3 := Mesa2.new(1, 1, 502, cfgj(1))
	m3.grade.fill(-1); m3.conta.fill(0); m3.pontos = 0
	m3.posic_usados = m3.posic_max - 1
	m3._por_carta(1, 1); m3._por_carta(2, 2); m3._por_carta(3, 3); m3._por_carta(4, 4)
	var rc := m3.posicionar(0, 0, 1)
	check("_C_ultimo_posicionamento_colhe_na_hora", int(rc[1]) == 1 and int(rc[0]) > 0 and m3.conta[0] == 0,
		"nlin=" + str(rc[1]))

	# ---- D) antidoto: janela so para a primeira linha madura da mesa ----
	var cd := cfgj(1); cd["janela_max_por_mesa"] = 1
	var m4 := Mesa2.new(1, 1, 503, cd)
	m4.grade.fill(-1); m4.conta.fill(0); m4.pontos = 0
	m4._por_carta(1, 1); m4._por_carta(2, 2); m4._por_carta(3, 3); m4._por_carta(4, 4)
	m4.posicionar(0, 0, 1)                      # 1a linha: espera
	check("_D_primeira_espera", m4.madura[0] == 1)
	m4.posicionar(20, 22, 2)                    # colhe a 1a
	m4._por_carta(6, 10); m4._por_carta(7, 11); m4._por_carta(8, 12); m4._por_carta(9, 13)
	var rd := m4.posicionar(14, 5, 3)           # 2a linha (linha 1 = casas 5..9)
	check("_D_segunda_colhe_na_hora", int(rd[1]) == 1 and m4.conta[1] == 0, "nlin=" + str(rd[1]))

	# ---- E) conservacao de FACES com a janela ligada ----
	var conserva := true
	var alvo_faces := 0
	for J in [1, 2, 99]:
		var cj := cfgj(J)
		for s in range(12):
			var mm := Mesa2.new(1 + s % 6, s % 3, 4242 + s * 31, cj)
			alvo_faces = int(mm.conservacao()[0])
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
				if int(mm.conservacao()[0]) != alvo_faces: conserva = false
			mm.finalizar_janela(turno)
			if int(mm.conservacao()[0]) != alvo_faces: conserva = false
			if not conserva: break
	check("_E_conservacao_de_faces_com_janela", conserva, "alvo=" + str(alvo_faces))

	# ---- F) nenhuma linha fica madura depois de finalizar_janela ----
	var sobrou := false
	for J in [1, 2, 99]:
		var cj := cfgj(J)
		for s in range(10):
			var mm := Mesa2.new(1 + s % 6, s % 3, 777 + s * 13, cj)
			var turno := 0
			while mm.posic_usados < mm.posic_max and mm.pontos < mm.meta:
				turno += 1
				if mm.mao.is_empty(): break
				var mv := b.movimentos(mm)
				if mv["lista"].is_empty(): break
				var e = b.melhor_gulosa(mv["lista"])
				mm.posicionar(e[6], e[1], turno)
				mm.mao.remove_at(e[0]); mm.comprar_mao()
			mm.finalizar_janela(turno)
			for li in range(12):
				if mm.madura[li] == 1: sobrou = true
	check("_F_nada_maduro_sobrevive_ao_fim_da_mesa", not sobrou)

	# ---- G) TETO DURO: cruzadas por mesa <= 2 / 1 / 2 ----
	var viol := 0
	for J in [0, 1, 2, 99]:
		var cj := cfgj(J)
		for pol in [0, 3]:
			var res := b.rodar(cj, 120, 0, pol)
			viol += int(res["violacoes_teto_duro"])
	check("_G_teto_duro_2_1_2_nunca_estourado", viol == 0, "violacoes=" + str(viol))

	# ---- H) sem janela o motor e identico ao de antes (cfg base) ----
	var c0 := Mesa2.cfg_padrao()
	var det := true
	for s in range(8):
		var a1 := Mesa2.new(2, 0, 555 + s, c0)
		var a2 := Mesa2.new(2, 0, 555 + s, c0)
		if a1.mao != a2.mao or a1.grade != a2.grade or a1.meta != a2.meta: det = false
	check("_H_determinismo_por_semente", det)

	print("ASSERCOES OK: ", ok, "  FALHAS: ", falhas.size())
	for f in falhas: print("  FALHOU: ", f)
	quit()

func r1_n(a: Array) -> int:
	return int(a[1])
