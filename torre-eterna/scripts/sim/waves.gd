class_name Diretor
extends RefCounted

## Diretor de ondas: ritmo de spawn, chefes, limpeza e avanço.

var j
var cd_spawn := 0.0
var spawnados := 0
var estado := "preparando"        # preparando | ativa | chefe | intervalo
var timer := 0.0
var chefe_atual: Inimigo = null
var intervalo_entre_ondas := 0.9

func _init(jogo) -> void:
	j = jogo

func iniciar_onda(n: int) -> void:
	var s: Dictionary = j.s
	s["onda"] = n
	s["mortos_na_onda"] = 0
	s["tempo_na_onda"] = 0.0
	s["em_chefe"] = Bal.eh_chefe(n)
	s["necessarios"] = 1 if bool(s["em_chefe"]) else Bal.contagem_onda(n)
	spawnados = 0
	cd_spawn = 0.25
	chefe_atual = null
	estado = "chefe" if bool(s["em_chefe"]) else "ativa"
	if n > int(s["onda_maxima"]):
		s["onda_maxima"] = n
	if n > int(s["onda_maxima_global"]):
		s["onda_maxima_global"] = n
	var era_antes := int(s["era"])
	var era_agora := Dados.era_da_onda(n)
	if era_agora != era_antes:
		s["era"] = era_agora
		if not s["eras_vistas"].has(era_agora):
			s["eras_vistas"].append(era_agora)
		Bus.era_mudou.emit(era_agora, Dados.era_atual(n))
	Bus.onda_iniciou.emit(n, bool(s["em_chefe"]))

func atualizar(dt: float) -> void:
	var s: Dictionary = j.s
	s["tempo_na_onda"] = float(s["tempo_na_onda"]) + dt

	match estado:
		"preparando":
			timer -= dt
			if timer <= 0.0:
				iniciar_onda(int(s["onda"]))
		"ativa":
			cd_spawn -= dt
			var faltam := int(s["necessarios"]) - spawnados
			if cd_spawn <= 0.0 and faltam > 0:
				cd_spawn = Bal.intervalo_spawn(int(s["onda"]))
				EnemyAI.spawn_onda(int(s["onda"]), j)
				spawnados += 1
			# a onda fecha quando TUDO que nasceu foi resolvido (morto ou chegou na torre)
			if spawnados >= int(s["necessarios"]) and j.arena.contagem_viva() == 0:
				concluir()
		"chefe":
			if chefe_atual == null:
				chefe_atual = EnemyAI.spawn_chefe(int(s["onda"]), j)
				cd_spawn = 3.5
				if chefe_atual == null:
					concluir()
					return
			cd_spawn -= dt
			if cd_spawn <= 0.0:
				cd_spawn = 4.5
				var invoca = chefe_atual.def.get("invoca", null)
				if invoca is Array and j.arena.inimigos.size() < 90:
					EnemyAI.spawn_onda(int(s["onda"]), j)
			if not chefe_atual.vivo():
				concluir()
		"intervalo":
			timer -= dt
			if timer <= 0.0:
				var proxima := int(s["onda_farm"]) if bool(s["modo_farm"]) else int(s["onda"]) + 1
				iniciar_onda(proxima)

func concluir() -> void:
	var s: Dictionary = j.s
	s["stats"]["ondas_completas"] = int(s["stats"]["ondas_completas"]) + 1
	j.recompensa_de_onda(int(s["onda"]))
	Bus.onda_limpa.emit(int(s["onda"]), float(s["tempo_na_onda"]))
	estado = "intervalo"
	timer = 1.6 if bool(s["em_chefe"]) else intervalo_entre_ondas
	chefe_atual = null

func reiniciar_onda(penalidade: int = 1) -> void:
	var s: Dictionary = j.s
	var nova := maxi(1, int(s["onda"]) - penalidade)
	s["onda"] = int(s["onda_farm"]) if bool(s["modo_farm"]) else nova
	estado = "preparando"
	timer = 1.2
	chefe_atual = null
	Bus.onda_falhou.emit(int(s["onda"]))

func ir_para(n: int) -> void:
	var s: Dictionary = j.s
	j.arena.limpar_inimigos()
	s["onda"] = clampi(n, 1, int(s["onda_maxima"]))
	estado = "preparando"
	timer = 0.4
	chefe_atual = null
