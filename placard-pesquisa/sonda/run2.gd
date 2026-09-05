extends SceneTree

const N := 1200
const N_M5 := 500
const N_PROF := 400
var res := {}
var b: Bancada

func salvar() -> void:
	var f := FileAccess.open("res://resultado_raw2.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "  "))
	f.close()

func log_linha(s: String) -> void:
	var f := FileAccess.open("res://progresso2.log", FileAccess.READ_WRITE if FileAccess.file_exists("res://progresso2.log") else FileAccess.WRITE)
	f.seek_end(); f.store_line(s); f.close()

func celula(grupo: String, nome: String, over: Dictionary, n: int, n_m5: int, politica: int) -> void:
	var cfg := Mesa2.cfg_padrao()
	for k in over.keys(): cfg[k] = over[k]
	var t0 := Time.get_ticks_msec()
	var r := b.rodar(cfg, n, n_m5, politica)
	r["cfg"] = over
	r["politica"] = ["gulosa", "profunda", "cacadora"][politica]
	if not res.has(grupo): res[grupo] = {}
	res[grupo][nome] = r
	salvar()
	log_linha(grupo + "/" + nome + " dt=" + str(Time.get_ticks_msec() - t0) + "ms m5=" + str(r["m5_pct"])
		+ " rec=" + str(r["pct_turnos_com_recompensa"]) + " razao=" + str(r["razao_pontos_meta_mediana"])
		+ " vit=" + str(r["vitoria_pct"]) + " cruz=" + str(r["cruzes_por_mesa_media"])
		+ " cor/mesa=" + str(r["coringas_criados_por_mesa"]) + " postos=" + str(r["coringas_por_mesa_media"]))

func _init() -> void:
	Nucleo.init_estatico()
	b = Bancada.new()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://progresso2.log"))
	log_linha("=== BANCADA 1 - fase 2 (base recalibrada F=0,15 + escassez) ===")
	# base recalibrada: razao/meta 0,84 - o unico ponto de operacao em que a
	# comparacao de PODER nao esta saturada pelo teto de vitoria
	celula("recal", "R_BASE_F015", {"pulso_F": 0.15}, N, N_M5, 0)
	celula("recal", "R_AGULHA_F015", {"pulso_F": 0.15, "agulha": true}, N, N_M5, 0)
	celula("recal", "R_AVESSO_F015", {"pulso_F": 0.15, "avesso": true}, N, N_M5, 0)
	celula("recal", "R_AGULHA_F015_profunda", {"pulso_F": 0.15, "agulha": true}, N_PROF, 0, 1)
	celula("recal", "R_AGULHA_F015_cacadora", {"pulso_F": 0.15, "agulha": true}, N, 0, 2)
	celula("recal", "R_AVESSO_F015_cacadora", {"pulso_F": 0.15, "avesso": true}, N, 0, 2)
	# escassez: 1 coringa por mesa
	celula("escassez", "E_AGULHA_teto1_colheita0", {"agulha": true, "ag_teto": 1, "ag_por_colheita": 0.0}, N, N_M5, 0)
	celula("escassez", "E_AVESSO_teto1", {"avesso": true, "av_teto": 1}, N, N_M5, 0)
	celula("escassez", "E_AGULHA_teto1_F015", {"pulso_F": 0.15, "agulha": true, "ag_teto": 1, "ag_por_colheita": 0.0}, N, N_M5, 0)
	celula("escassez", "E_AVESSO_teto1_F015", {"pulso_F": 0.15, "avesso": true, "av_teto": 1}, N, N_M5, 0)
	# agulha + avesso juntos (registro, nao recomendacao)
	celula("combo", "C_AGULHA_E_AVESSO_F015", {"pulso_F": 0.15, "agulha": true, "avesso": true}, N, N_M5, 0)
	log_linha("=== FIM 2 ===")
	quit()
