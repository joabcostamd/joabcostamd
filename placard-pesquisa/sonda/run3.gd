extends SceneTree
var res := {}
func _init() -> void:
	Nucleo.init_estatico()
	var b := Bancada.new()
	var especs := [
		["outs_base_gulosa", {}, 0], ["outs_agulha_gulosa", {"agulha": true}, 0],
		["outs_avesso_gulosa", {"avesso": true}, 0],
		["outs_base_cacadora", {}, 2], ["outs_agulha_cacadora", {"agulha": true}, 2],
		["outs_avesso_cacadora", {"avesso": true}, 2],
	]
	for e in especs:
		var cfg := Mesa2.cfg_padrao()
		for k in e[1].keys(): cfg[k] = e[1][k]
		var r := b.rodar(cfg, 2000, 0, e[2])
		res[e[0]] = {"outs_brutos": r["outs_brutos"], "cruzadas_por_mesa_media": r["cruzadas_por_mesa_media"],
			"pct_mesas_com_zero_cruzada": r["pct_mesas_com_zero_cruzada"],
			"quinas_por_mesa": r["quinas_por_mesa"], "reais_por_mesa": r["reais_por_mesa"],
			"n_linhas_por_evento": r["n_linhas_por_evento"], "mesas": r["mesas"]}
		var f := FileAccess.open("res://resultado_raw3.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(res, "  ")); f.close()
		var lf := FileAccess.open("res://progresso3.log", FileAccess.READ_WRITE if FileAccess.file_exists("res://progresso3.log") else FileAccess.WRITE)
		lf.seek_end(); lf.store_line(e[0] + " " + JSON.stringify(res[e[0]])); lf.close()
	var lf2 := FileAccess.open("res://progresso3.log", FileAccess.READ_WRITE)
	lf2.seek_end(); lf2.store_line("=== FIM 3 ==="); lf2.close()
	quit()
