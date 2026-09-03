extends SceneTree

func _initialize() -> void:
	Dados.carregar(true)
	DirAccess.make_dir_recursive_absolute("/tmp/te_audio")
	var cat := Sfx.catalogo()
	var alvos: Array = ["tiro", "tiro_critico", "impacto", "morte", "morte_chefe", "ouro",
		"compra", "bloqueado", "nivel", "onda", "alerta_chefe", "torre_dano",
		"torre_destruida", "prestigio", "lendario", "hab_nova", "hab_congelar",
		"hab_buraco_negro", "hab_julgamento", "clique", "erro"]
	for nome in alvos:
		var e: Dictionary = cat[str(nome)]
		var w: AudioStreamWAV = Synth.som(e.get("camadas", []), float(e.get("pico", 0.85)))
		_escrever("/tmp/te_audio/%s.pcm" % nome, w.data)
	var m := Musica.new(root)
	for nome in ["perc", "hat", "pad", "baixo_quadrada", "arpejo_dente"]:
		m.gerar_banco(str(nome))
		var w2: AudioStreamWAV = m.bancos[str(nome)]
		_escrever("/tmp/te_audio/mus_%s.pcm" % nome, w2.data)
	print("===DUMP=== ok")
	quit(0)

func _escrever(caminho: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
