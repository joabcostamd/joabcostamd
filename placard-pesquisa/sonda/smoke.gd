extends SceneTree

func p(nome, r) -> void:
	print(nome, " rec=", r["pct_turnos_com_recompensa"], " seca=", r["seca_mediana"], "/", r["seca_p90"],
		" ev=", r["eventos_por_mesa_media"], " razao=", r["razao_pontos_meta_mediana"],
		" vit=", r["vitoria_pct"], " tear=", r["tear_mediano"], "/", r["tear_max"],
		" maiorEv=", r["maior_evento_unico"], " pico/med=", r["razao_pico_sobre_mediana"],
		" cruz=", r["cruzes_por_mesa_media"], " zero=", r["pct_mesas_com_zero_cruz"],
		" max=", r["cruzes_por_mesa_max"], " m5=", r["m5_pct"], " seg45=", r["turnos_segurando_4_5"],
		" viol=", r["violacoes_teto_duro"])

func _init() -> void:
	Nucleo.init_estatico()
	var b := Bancada4.new()
	var t0 := Time.get_ticks_msec()
	# 1) base ADITIVA b1 (K=1): esperado rec 65,7 razao 0,990 vit 40,75 tear 6/7 maiorEv 2394
	var c1 := Mesa2.cfg_padrao()
	p("ADITIVA_b1  ", b.rodar(c1, 600, 200, 0))
	# 2) PRODUTO b3 K=2,25 sem avesso: esperado razao 0,770 vit 28,0 tear 7/8 maiorEv 10260 pico 15,8
	var c2 := Mesa2.cfg_padrao()
	c2["produto"] = true; c2["tear_ini"] = 1; c2["teto_evento"] = false; c2["meta_k"] = 2.25
	p("PRODUTO_b3  ", b.rodar(c2, 600, 200, 0))
	# 3) PRODUTO + AVESSO (nucleo polido, K a calibrar)
	var c3 := c2.duplicate(); c3["avesso"] = true
	p("POLIDO_K2.25", b.rodar(c3, 600, 200, 0))
	# 4) janela 1 smoke
	var c4 := c3.duplicate(); c4["janela"] = 1
	p("JANELA1_K2.25", b.rodar(c4, 600, 200, 0))
	# 5) planejadora na base
	p("POLIDO_PLANEJ", b.rodar(c3, 300, 0, 3))
	p("JANELA1_PLANEJ", b.rodar(c4, 300, 0, 3))
	print("dt=", Time.get_ticks_msec() - t0, "ms")
	quit()
