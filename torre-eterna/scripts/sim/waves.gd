class_name Diretor
extends RefCounted

## Diretor de ondas: ritmo de spawn, chefes, limpeza e avanço.

var j
## Ouro extra por antecipar a onda inteira, em cima da recompensa de onda.
const ANTECIPAR_BONUS := 0.6

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
	var quantos := 1 if bool(s["em_chefe"]) else Bal.contagem_onda(n, bool(s.get("modo_infinito", false)))
	# densidade: o desafio Enxame multiplica a contagem (5× mais inimigos)
	s["necessarios"] = maxi(1, int(round(float(quantos) * float(j.mods_dif.get("densidade", 1.0)))))
	spawnados = 0
	cd_spawn = 0.25
	chefe_atual = null
	estado = "chefe" if bool(s["em_chefe"]) else "ativa"
	if n > int(s["onda_maxima"]):
		s["onda_maxima"] = n
	# A linha de chegada do desafio, FORA do `if` do recorde — o comentario logo
	# abaixo ja explica por que: basta um caminho que mexa no recorde por fora
	# (carregar save, salto de onda) para a checagem nunca rodar. `ondaMax` era
	# lido por ninguem e `encerrar_desafio(true)` nao tinha chamador: o desafio
	# nunca terminava, e quem entrava ficava preso nos modificadores duros para
	# sempre, sem vitoria possivel.
	j.checar_fim_do_desafio()
	if n > int(s["onda_maxima_global"]):
		s["onda_maxima_global"] = n
	# A checagem roda em TODA onda, não só quando o recorde sobe. Antes ficava
	# atrás do `if` do recorde e bastava um caminho que mexesse no recorde por
	# fora (carregar um save, um salto de onda, um talento que empurra a onda
	# inicial) para a habilidade ficar presa: o painel dizia "requisito
	# cumprido" e mostrava cadeado ao mesmo tempo. São dez habilidades — custa
	# nada conferir sempre.
	# Sino do Recomeço: "toda onda nova começa com TODAS as habilidades sem
	# recarga". Estava escrito no JSON e não existia no código.
	if j.pas.has("sino_de_recomeco"):
		for id in s["habilidades"].keys():
			var h: Dictionary = s["habilidades"][id]
			if bool(h.get("desbloqueada", false)):
				h["cd"] = 0.0
	# as recompras do Contrato são por onda
	j.recompras_usadas = 0
	j.revives_usados = 0

	var novas: Array = Habilidades.desbloquear_por_progresso(s)
	if not novas.is_empty():
		for def in novas:
			Bus.toast(Txt.f("sim_nova_habilidade", {"n": Ux.txt(def, "nome", Cfg.ingles())}), "epico")
		Bus.ui_atualizar.emit(false)
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
			# `ondaAuto` (desafio Esteira): a onda avança sozinha a cada N
			# segundos, tendo o jogador limpado ou não. Os atrasados ficam no
			# mapa e se acumulam — que é exatamente o que o texto promete.
			var auto_seg := float(j.mods_dif.get("ondaAuto", 0.0))
			if auto_seg > 0.0 and float(s["tempo_na_onda"]) >= auto_seg:
				concluir()
				return
			cd_spawn -= dt
			var faltam := int(s["necessarios"]) - spawnados
			# NAO ACELERE O SPAWN SOZINHO. Tentei: quando a arena esvaziava e
			# ainda faltavam inimigos, o proximo vinha quase na hora. As ondas
			# iniciais aceleraram (onda 25 de 7m27 para 6m59), e o jogo QUEBROU
			# do meio para a frente: onda 100 saiu de 30m56 para 1h03 e a onda
			# maxima despencou de 261 para 115. O tempo de espera do spawn era,
			# na pratica, tempo de acumular poder — encurtar a onda sem dar o
			# ganho junto so faz o jogador chegar despreparado na parede.
			#
			# A saida certa nao e o jogo decidir o ritmo, e o JOGADOR: quem esta
			# forte antecipa a onda e leva bonus por isso (ver `antecipar()`).
			if cd_spawn <= 0.0 and faltam > 0:
				cd_spawn = Bal.intervalo_spawn(int(s["onda"]))
				EnemyAI.spawn_onda(int(s["onda"]), j)
				spawnados += 1
			# A onda fecha quando TUDO que nasceu foi resolvido (morto ou chegou na
			# torre). A contagem tem que ser a de AGORA: com o número em cache,
			# o inimigo que nasceu três linhas acima não entrava na conta e a
			# onda fechava com ele vivo, vazando para a onda seguinte.
			if spawnados >= int(s["necessarios"]) and j.arena.contagem_viva_agora() == 0:
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

## ANTECIPAR A ONDA: a decisao que faltava.
##
## O ritmo do jogo era ditado pelo spawner, nao pelo poder do jogador: a onda so
## fecha quando todos nasceram, um a cada `intervalo_spawn`, entao o piso de
## tempo era o mesmo para quem matava em um tiro e para quem apanhava. Medido:
## da onda ~50 em diante, 21 ordens de grandeza de dano sobrando compravam 0,2
## minuto. Comprar poder nao encurtava nada, e o jogo virava espera.
##
## Acelerar o spawn sozinho foi tentado e QUEBROU o jogo (onda 100 de 30m56 para
## 1h03, onda maxima de 261 para 115): o tempo de espera era, na pratica, tempo
## de acumular poder. A saida e nao decidir pelo jogador — quem esta forte
## antecipa e leva bonus por isso; quem nao esta simplesmente nao aperta.
##
## Devolve `false` quando nao da para antecipar (nao esta no intervalo).
func antecipar() -> bool:
	if estado != "intervalo" or timer <= 0.0:
		return false
	var s: Dictionary = j.s
	# O bonus e proporcional ao que sobrou do respiro: quem chama na hora exata
	# em que a onda ia comecar nao ganha nada, e quem chama de cara ganha tudo.
	var fracao := clampf(timer / maxf(0.01, intervalo_entre_ondas), 0.0, 1.0)
	var bonus := 1.0 + ANTECIPAR_BONUS * fracao
	j.ganhar_ouro(Big.mul_f(Bal.ouro_onda(int(s["onda"])), bonus), "antecipar", false)
	timer = 0.0
	Bus.onda_antecipada.emit(int(s["onda"]) + 1, bonus)
	return true

func concluir() -> void:
	var s: Dictionary = j.s
	s["stats"]["ondas_completas"] = int(s["stats"]["ondas_completas"]) + 1
	j.recompensa_de_onda(int(s["onda"]))
	Bus.onda_limpa.emit(int(s["onda"]), float(s["tempo_na_onda"]))
	estado = "intervalo"
	# No Modo Infinito o respiro é curto, não inexistente.
	#
	# Era `timer = 0.0`, e o estado "intervalo" durava exatamente UM tique de
	# física. `Eventos._momento_bom` exige esse estado, e o relógio de eventos
	# só o consulta no quadro em que zera — a chance de coincidir com aquele
	# único quadro é perto de nada. Ligar o Modo Infinito, que é o último nó do
	# Éter, desligava os eventos aleatórios do jogo inteiro sem dizer nada.
	if bool(s.get("modo_infinito", false)):
		timer = INTERVALO_INFINITO
	else:
		timer = 1.6 if bool(s["em_chefe"]) else intervalo_entre_ondas
	chefe_atual = null

## Respiro entre ondas no Modo Infinito: curto o bastante para o combate
## parecer contínuo, longo o bastante para o sorteio de eventos enxergar.
const INTERVALO_INFINITO := 0.35

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
