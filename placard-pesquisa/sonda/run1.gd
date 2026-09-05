extends SceneTree

const N := 1200
const N_M5 := 500
const N_PROF := 400

var res := {}
var b: Bancada

func salvar() -> void:
	var f := FileAccess.open("res://resultado_raw.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "  "))
	f.close()

func log_linha(s: String) -> void:
	var f := FileAccess.open("res://progresso.log", FileAccess.READ_WRITE if FileAccess.file_exists("res://progresso.log") else FileAccess.WRITE)
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
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://progresso.log"))
	log_linha("=== BANCADA 1 ===")

	# ---------- VALIDACAO contra os numeros conhecidos da sonda ----------
	celula("validacao", "nucleo_puro_sem_pulso_sem_tique", {"pulso_F": 0.0, "tick_tear": 0}, N, 0, 0)
	celula("validacao", "pulso035_sem_tique", {"tick_tear": 0}, N, 0, 0)
	celula("validacao", "tique4_sem_pulso", {"pulso_F": 0.0}, N, 0, 0)
	celula("validacao", "pulso035_tique3", {"tick_tear": 3}, N, 0, 0)

	# ---------- LINHA DE BASE ----------
	celula("base", "BASE_pulso035_tique4_gulosa", {}, N, N_M5, 0)
	celula("base", "BASE_pulso035_tique4_profunda", {}, N_PROF, 0, 1)
	celula("base", "BASE_pulso035_tique4_cacadora", {}, N, 0, 2)
	celula("base", "BASE_B_pulso015_tique4_gulosa", {"pulso_F": 0.15}, N, N_M5, 0)

	# ---------- AGULHA ----------
	var ag := {"agulha": true}
	celula("agulha", "A0_fica_maiorfichas", {"agulha": true, "ag_destino": 0, "ag_desempate": 0}, N, N_M5, 0)
	celula("agulha", "A1_fica_menorficha", {"agulha": true, "ag_destino": 0, "ag_desempate": 1}, N, N_M5, 0)
	celula("agulha", "A2_evapora_maiorfichas", {"agulha": true, "ag_destino": 1, "ag_desempate": 0}, N, N_M5, 0)
	celula("agulha", "A3_evapora_menorficha", {"agulha": true, "ag_destino": 1, "ag_desempate": 1}, N, N_M5, 0)
	celula("agulha", "A4_ini1_colheita0", {"agulha": true, "ag_por_colheita": 0.0}, N, N_M5, 0)
	celula("agulha", "A5_ini1_colheita05", {"agulha": true, "ag_por_colheita": 0.5}, N, N_M5, 0)
	celula("agulha", "A6_ini0_colheita1", {"agulha": true, "ag_iniciais": 0}, N, N_M5, 0)
	celula("agulha", "A7_teto2", {"agulha": true, "ag_teto": 2}, N, N_M5, 0)
	celula("agulha", "A8_teto3", {"agulha": true, "ag_teto": 3}, N, N_M5, 0)
	celula("agulha", "A9_sem_bloqueio_diagonais", {"agulha": true, "ag_bloqueio_diag": false}, N, N_M5, 0)
	celula("agulha", "A10_janela8", {"agulha": true, "ag_janela": 8}, N, N_M5, 0)
	celula("agulha", "A11_janela_uniforme", {"agulha": true, "ag_janela": 0}, N, N_M5, 0)
	celula("agulha", "A0_profunda", {"agulha": true}, N_PROF, 0, 1)
	celula("agulha", "A0_cacadora", {"agulha": true}, N, 0, 2)

	# ---------- AVESSO ----------
	celula("avesso", "B0_gat_toda_pontas_extremos", {"avesso": true}, N, N_M5, 0)
	celula("avesso", "B1_gat_trinca_pontas_extremos", {"avesso": true, "av_gatilho": 3}, N, N_M5, 0)
	celula("avesso", "B2_gat_flush_pontas_extremos", {"avesso": true, "av_gatilho": 5}, N, N_M5, 0)
	celula("avesso", "B3_gat_toda_pontas_maiores", {"avesso": true, "av_pontas": 1}, N, N_M5, 0)
	celula("avesso", "B4_gat_trinca_pontas_maiores", {"avesso": true, "av_gatilho": 3, "av_pontas": 1}, N, N_M5, 0)
	celula("avesso", "B5_gat_flush_pontas_maiores", {"avesso": true, "av_gatilho": 5, "av_pontas": 1}, N, N_M5, 0)
	celula("avesso", "B6_teto2", {"avesso": true, "av_teto": 2}, N, N_M5, 0)
	celula("avesso", "B7_teto3", {"avesso": true, "av_teto": 3}, N, N_M5, 0)
	celula("avesso", "B8_sem_teto", {"avesso": true, "av_teto": 99}, N, N_M5, 0)
	celula("avesso", "B9_diagonais_leem_direito", {"avesso": true, "av_diag_face_direito": true}, N, N_M5, 0)
	celula("avesso", "B0_profunda", {"avesso": true}, N_PROF, 0, 1)
	celula("avesso", "B0_cacadora", {"avesso": true}, N, 0, 2)

	log_linha("=== FIM ===")
	quit()
