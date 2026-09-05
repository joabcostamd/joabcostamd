extends SceneTree

const N := 1000
const N_M5 := 500
const N_PROF := 400
var res := {}
var b: Bancada4

func salvar() -> void:
	var f := FileAccess.open("res://resultado_raw.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "  ")); f.close()

func log_linha(s: String) -> void:
	var f := FileAccess.open("res://progresso.log", FileAccess.READ_WRITE if FileAccess.file_exists("res://progresso.log") else FileAccess.WRITE)
	f.seek_end(); f.store_line(s); f.close()

func celula(nome: String, cfg: Dictionary, pol: String, n: int, n_m5: int, ip: int) -> void:
	var t0 := Time.get_ticks_msec()
	var r := b.rodar(cfg, n, n_m5, ip)
	r["politica"] = pol
	r["meta_k"] = cfg["meta_k"]
	if not res.has(nome): res[nome] = {}
	res[nome][pol] = r
	salvar()
	log_linha(nome + "/" + pol + " dt=" + str(Time.get_ticks_msec() - t0) + "ms"
		+ " cruz=" + str(r["cruzes_por_mesa_media"]) + " zero=" + str(r["pct_mesas_com_zero_cruz"])
		+ " max=" + str(r["cruzes_por_mesa_max"]) + " cr/ev=" + str(r["cruzes_por_evento"])
		+ " rec=" + str(r["pct_turnos_com_recompensa"]) + " seca=" + str(r["seca_mediana"]) + "/" + str(r["seca_p90"])
		+ " razao=" + str(r["razao_pontos_meta_mediana"]) + " vit=" + str(r["vitoria_pct"])
		+ " m5=" + str(r["m5_pct"]) + " seg45=" + str(r["turnos_segurando_4_5"])
		+ " adiadas=" + str(r["pct_colheitas_adiadas"]) + " viol=" + str(r["violacoes_teto_duro"]))

func _init() -> void:
	Nucleo.init_estatico()
	b = Bancada4.new()
	var ks := {}
	if FileAccess.file_exists("res://calib.json"):
		var txt := FileAccess.open("res://calib.json", FileAccess.READ).get_as_text()
		var j = JSON.parse_string(txt)
		for k in j.keys(): ks[k] = float(j[k]["k_final"])
	log_linha("=== BANCADA c4 - JANELA DA COLHEITA ===")
	for e in Variantes.lista():
		var nome: String = e[0]
		var cfg := Variantes.cfg_de(e[1])
		cfg["meta_k"] = ks.get(nome, 2.25)
		celula(nome, cfg, "gulosa", N, N_M5, 0)
		celula(nome, cfg, "profunda", N_PROF, 0, 1)
		celula(nome, cfg, "planejadora", N, 0, 3)
		if nome == "BASE" or nome == "J1":
			celula(nome, cfg, "cacadora_b1", N, 0, 2)
	log_linha("=== FIM ===")
	quit()
