extends SceneTree
func _init() -> void:
	Nucleo.init_estatico()
	var b := Bancada4.new()
	var txt := FileAccess.open("res://calib.json", FileAccess.READ).get_as_text()
	var out = JSON.parse_string(txt)
	for e in Variantes.lista():
		var nome: String = e[0]
		if out.has(nome): continue
		var k := 2.25
		var hist := []
		for it in range(3):
			var cfg := Variantes.cfg_de(e[1])
			cfg["meta_k"] = k
			var r := b.rodar(cfg, 600, 0, 0)
			var razao := float(r["razao_pontos_meta_mediana"])
			hist.append([snappedf(k, 0.0001), razao, r["vitoria_pct"]])
			if abs(razao - 0.79) < 0.006: break
			k = k * razao / 0.79
		out[nome] = {"k_final": hist[hist.size() - 1][0], "trajetoria": hist}
		print(nome, " -> ", hist)
	var f := FileAccess.open("res://calib.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  ")); f.close()
	quit()
