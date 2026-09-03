extends SceneTree

func _initialize() -> void:
	Dados.carregar(true)
	var cat := Sfx.catalogo()
	var total := 0
	var pior := 0.0
	var pior_nome := ""
	var t0 := Time.get_ticks_usec()
	for nome in Sfx.nomes():
		var e: Dictionary = cat[str(nome)]
		var t1 := Time.get_ticks_usec()
		var w: AudioStreamWAV = Synth.som(e.get("camadas", []), float(e.get("pico", 0.85)))
		var ms := float(Time.get_ticks_usec() - t1) / 1000.0
		total += w.data.size() / 2
		if ms > pior:
			pior = ms
			pior_nome = str(nome)
		print("%-18s %6.1f ms  %5d ms de som  rms=%.3f" % [nome, ms, int(float(w.data.size() / 2) / 44.1), _rms(w)])
	var t_sfx := float(Time.get_ticks_usec() - t0) / 1000.0

	var m := Musica.new(root)
	var t2 := Time.get_ticks_usec()
	for nome in m.nomes_banco():
		m.gerar_banco(str(nome))
	var t_mus := float(Time.get_ticks_usec() - t2) / 1000.0
	print("---")
	print("SFX: %d sons em %.0f ms (pior: %s %.0f ms) · %d amostras" % [Sfx.nomes().size(), t_sfx, pior_nome, pior, total])
	print("Musica: %d bancos em %.0f ms" % [m.nomes_banco().size(), t_mus])
	quit(0)

func _rms(w: AudioStreamWAV) -> float:
	var d: PackedByteArray = w.data
	var n := d.size() / 2
	if n == 0:
		return 0.0
	var soma := 0.0
	for i in n:
		var v := float(d.decode_s16(i * 2)) / 32768.0
		soma += v * v
	return sqrt(soma / float(n))
