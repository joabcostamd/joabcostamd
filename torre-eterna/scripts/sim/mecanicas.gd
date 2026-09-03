class_name Mecanicas
extends RefCounted

## As mecânicas-assinatura de Torre Eterna — o que este jogo tem e os outros não.
##
##  1. A PURGA          — a única ação que exige o jogador, e recompensa timing.
##  2. ÁLBUM DE ECOS    — ver uma carta já é progresso permanente. Descarte sem medo.
##  3. ADAPTAÇÃO        — o Enxame cria resistência ao elemento que você mais usa.
##  4. O PEREGRINO      — um inimigo que não ataca. Matar dá ouro; poupar conta.
##  5. AGLOMERAÇÃO      — quanto mais inimigos vivos na tela, mais ouro cada um vale.

# ============================================================== A PURGA ====
const PURGA_TEMPO_BASE := 26.0        ## segundos para encher sozinha
const PURGA_POR_ABATE := 0.006        ## cada abate adianta a carga
const PURGA_JANELA_PERFEITA := 0.92   ## a partir daqui é "perfeita"
const PURGA_JANELA_BOA := 0.70
const PURGA_DANO := 42.0              ## multiplicador do dano da torre
const PURGA_AUTO_QUALIDADE := 0.60    ## automação é DE PROPÓSITO pior
const PURGA_AUTO_GATILHO := 0.86

static func estado_purga(s: Dictionary) -> Dictionary:
	if not s.has("purga"):
		s["purga"] = {"carga": 0.0, "auto": false, "usos": 0, "perfeitas": 0, "estourou": 0, "brilho": 0.0}
	return s["purga"]

## Cada abate adianta a carga da Purga — a promessa que `PURGA_POR_ABATE` fazia
## e ninguem cumpria. Nao dispara nada por conta propria: so empurra a carga,
## e quem decide o estouro continua sendo `atualizar_purga` no quadro seguinte.
static func creditar_abate_purga(j) -> void:
	if not bool(j.s["torre"]["viva"]):
		return
	var p := estado_purga(j.s)
	p["carga"] = minf(1.0, float(p["carga"]) + PURGA_POR_ABATE)

static func atualizar_purga(dt: float, j) -> void:
	var p := estado_purga(j.s)
	if not bool(j.s["torre"]["viva"]):
		return
	var vel: float = 1.0 / PURGA_TEMPO_BASE * (1.0 + float(j.stats.n("cdr")))
	var carga_antes := float(p["carga"])
	p["carga"] = carga_antes + vel * dt
	# A JANELA DOURADA ABRIA EM SILÊNCIO. A Purga é a única coisa que o jogo pede
	# do jogador, a janela perfeita dura ~2 s de um ciclo de 26 s, e os dois
	# avisos existentes eram visuais e periféricos: um anel no botão, no canto.
	# Quem estivesse olhando para a arena — que é onde o jogo acontece — perdia a
	# janela sem nunca saber que ela abriu. Agora ela toca.
	if carga_antes < PURGA_JANELA_PERFEITA and float(p["carga"]) >= PURGA_JANELA_PERFEITA:
		Bus.habilidade_pronta.emit("purga")
	if float(p["brilho"]) > 0.0:
		p["brilho"] = maxf(0.0, float(p["brilho"]) - dt * 2.0)

	# automação: dispara cedo e rende menos — nunca substitui o jogador
	if bool(p["auto"]) and j.esp["desbloqueios"].has("autoPurga") and float(p["carga"]) >= PURGA_AUTO_GATILHO:
		disparar_purga(j, true)
		return

	# estouro: passou de 1.0 sem disparar → descarrega mal e atordoa a torre
	if float(p["carga"]) >= 1.0:
		p["estourou"] = int(p["estourou"]) + 1
		disparar_purga(j, false, 0.30)
		# A punição só começa depois que o jogo EXPLICOU. O balão da Purga é o
		# segundo passo do tutorial, mas quem ainda não chegou nele (ou abriu o
		# jogo e foi fazer outra coisa) levava um atordoamento aos 52 s por não
		# apertar um botão que nunca lhe foi apresentado. Enquanto o tutorial
		# não mostrou a Purga, o estouro só avisa.
		if int(p["estourou"]) > 1 and _purga_ja_explicada(j.s):
			j.torre.cd_tiro = maxf(j.torre.cd_tiro, 1.2)
			Bus.toast(Txt.t("sim_purga_estourou"), "ruim")
		else:
			Bus.toast(Txt.t("sim_purga_estourou_1a"), "info")

## O jogador já viu o balão da Purga (ou dispensou o tutorial)?
static func _purga_ja_explicada(s: Dictionary) -> bool:
	var t = s.get("tutorial", null)
	if not (t is Dictionary):
		return true
	if bool(t.get("completo", false)):
		return true
	var vistas = t.get("vistas", null)
	return vistas is Array and vistas.has("purga")

## Qualidade da purga pela carga atual.
static func qualidade_purga(carga: float) -> float:
	if carga >= PURGA_JANELA_PERFEITA:
		return 1.0
	if carga >= PURGA_JANELA_BOA:
		return 0.55 + (carga - PURGA_JANELA_BOA) * 1.5
	return 0.18 + carga * 0.35

static func disparar_purga(j, automatica: bool = false, forcar_qualidade: float = -1.0) -> bool:
	var s: Dictionary = j.s
	var p := estado_purga(s)
	var carga := float(p["carga"])
	if carga < 0.12:
		# Clicar sem carga fazia SOM DE CLIQUE e nada mais: o jogador não sabia
		# se o botão estava quebrado, se a habilidade não existia, ou se ele
		# tinha feito algo errado. Silêncio depois de uma ação é a pior resposta
		# possível — pior que negar.
		if not automatica:
			Bus.toast(Txt.t("purga_sem_carga"), "bloqueado", "nova")
		return false

	var q := forcar_qualidade
	if q < 0.0:
		q = qualidade_purga(carga)
		if automatica:
			q *= PURGA_AUTO_QUALIDADE
	var perfeita := q >= 0.999

	p["carga"] = 0.0
	p["usos"] = int(p["usos"]) + 1
	p["brilho"] = 1.0
	if perfeita:
		p["perfeitas"] = int(p["perfeitas"]) + 1

	var dano: float = Big.mul_f(Big.mul_f(j.stats.b("dano"), float(j.stats.n("multiplicador"))), PURGA_DANO * q)
	var centro: Vector2 = j.arena.centro
	var todos: Array = j.arena.inimigos
	var lista: Array = todos.duplicate()
	var mortos := 0
	for item in lista:
		var e: Inimigo = item
		if not e.vivo():
			continue
		var r: Dictionary = Combate.aplicar_dano(e, dano, j, {"crit": perfeita, "penetracao": 1.0, "fonte": "purga"})
		if r["morreu"]:
			mortos += 1

	# purga perfeita também rende ouro e recarrega habilidades
	if perfeita:
		var bonus: float = Big.mul_f(Bal.ouro_onda(int(s["onda"])), 18.0 * float(mortos + 4))
		j.ganhar_ouro(Big.mul_f(bonus, float(j.stats.n("ganhoOuro"))), "purga")
		for id in s["habilidades"].keys():
			var h: Dictionary = s["habilidades"][id]
			h["cd"] = maxf(0.0, float(h["cd"]) - 6.0)

	Bus.particulas.emit("nova", centro, {"raio": maxf(j.arena.largura, j.arena.altura) * (0.55 + 0.5 * q), "cor": "#7dd3fc" if not perfeita else "#fde047"})
	Bus.tremor_pedido.emit(10.0 + 22.0 * q, 0.35 + 0.3 * q)
	Bus.hitstop_pedido.emit(40.0 + 90.0 * q)
	if perfeita:
		Bus.camera_lenta.emit(0.4, 320.0)
		Bus.celebracao.emit("purga_perfeita", {"mortos": mortos})
	Bus.purga_usada.emit(q, perfeita)
	return true

# ======================================================== ÁLBUM DE ECOS ====
## Ver uma carta basta: o Álbum guarda o registro para sempre, imune a
## TODOS os prestígios. Duplicata deixa de ser lixo e vira micro-progresso.
const ALBUM_DANO_POR_CARTA := 0.018
const ALBUM_OURO_POR_CARTA := 0.012

static func registrar_no_album(s: Dictionary, id_carta: String) -> bool:
	if not s.has("album"):
		s["album"] = {}
	if s["album"].has(id_carta):
		return false
	s["album"][id_carta] = int(Time.get_unix_time_from_system())
	return true

static func bonus_album(s: Dictionary) -> Dictionary:
	var n := 0
	if s.has("album"):
		n = s["album"].size()
	return {"n": n, "dano": float(n) * ALBUM_DANO_POR_CARTA, "ouro": float(n) * ALBUM_OURO_POR_CARTA}

# ========================================================== ADAPTAÇÃO ======
## O Enxame aprende. Use fogo o tempo todo e o fogo passa a doer menos.
## Diversificar elementos é uma decisão real, não um detalhe.
## Ganho de resistencia por SEGUNDO de uso do elemento (nao por acerto).
const ADAPT_GANHO_SEG := 0.012
const ADAPT_DECAI := 0.0016
const ADAPT_TETO := 0.62

## A ADAPTACAO ESTAVA MORTA DESDE SEMPRE, e por uma unica palavra.
##
## `GameState.novo()` declara `"adaptacao": {}` — a chave EXISTE e esta vazia.
## Esta funcao semeava com `if not s.has("adaptacao")`, que e falso desde o
## primeiro quadro de toda partida. Consequencia em cadeia: `registrar_elemento`
## caia em `if not a.has(elemento): return` para os cinco elementos, nada nunca
## era registrado, e `fator_elemento` devolvia 1,0 para sempre. Uma das cinco
## mecanicas-assinatura do jogo — anunciada no README como "o mundo cria
## resistencia ao elemento que voce mais usa, ate 62%" — nunca aconteceu uma
## vez, em nenhuma partida.
##
## E passou por 348 assercoes verdes porque o teste escrevia o dicionario
## completo na mao antes de medir: media a funcao com o estado que o jogo nunca
## produz. Por isso a condicao agora e `is_empty()`, e o teste passou a partir
## do estado que `GameState.novo()` realmente devolve.
static func estado_adaptacao(s: Dictionary) -> Dictionary:
	if not s.has("adaptacao") or (s["adaptacao"] as Dictionary).is_empty():
		s["adaptacao"] = {"fogo": 0.0, "gelo": 0.0, "raio": 0.0, "veneno": 0.0, "vazio": 0.0}
	return s["adaptacao"]

## Marca que o elemento foi usado NESTE quadro. Nao sobe a adaptacao aqui.
##
## Subia: `+ADAPT_GANHO` por ACERTO. Com a torre no meio do jogo acertando
## centenas de vezes por segundo, isso levava a resistencia ao teto de 62% em
## menos de um segundo e a mantinha la para sempre — a Adaptacao nao era uma
## curva, era um interruptor. Enquanto a mecanica estava morta ninguem notou;
## consertada, ela derrubou a onda maxima do simulador de 261 para 97, e o
## motivo nao era o jogo ser difícil: era a resistencia estar sempre no maximo.
##
## Agora o ganho e por TEMPO de uso (ver `decair_adaptacao`), que e o que a
## mecanica sempre quis dizer: "o mundo cria resistencia ao elemento que voce
## MAIS USA" fala de habito, nao de cadencia de tiro.
static func registrar_elemento(s: Dictionary, elemento: String) -> void:
	if elemento == "":
		return
	var a := estado_adaptacao(s)
	if not a.has(elemento):
		return
	# CONTA, NAO MARCA.
	#
	# Isto era `usados[elemento] = true`, um booleano por quadro. Com a torre
	# acertando varios alvos por quadro, TODO elemento com qualquer peso ficava
	# marcado em quase todo quadro — e o `decair_adaptacao` dava o ganho cheio a
	# qualquer marcado. O resultado e que a adaptacao nao tinha meio-termo: cada
	# elemento acabava em 0% ou colado no teto de 62%, nunca entre os dois.
	#
	# E isso inverte a mecanica. O jogo diz, na dica do HUD e no README, que o
	# Enxame cria resistencia ao que voce MAIS usa e que diversificar resolve.
	# Com o booleano, diversificar so adicionava mais elementos a -62%: usar
	# dois era estritamente pior que usar um, e a "build otima que muda sozinha"
	# nao mudava nunca. A contagem e o que permite medir participacao.
	var usados: Dictionary = s.get("_adapt_uso", {})
	usados[elemento] = int(usados.get(elemento, 0)) + 1
	s["_adapt_uso"] = usados

## Sobe o que foi usado neste quadro, desce o resto. Roda uma vez por quadro,
## com `dt` — e por isso a curva anda no relogio e nao na contagem de acertos.
##
## Com ADAPT_GANHO_SEG = 0.012, saturar leva ~52 s de uso continuo; com
## ADAPT_DECAI = 0.0016, esquecer leva ~6,5 min sem usar. Isso e uma curva que
## o jogador consegue ler e contornar, que e o ponto da mecanica.
static func decair_adaptacao(dt: float, s: Dictionary) -> void:
	var a := estado_adaptacao(s)
	# A MIRA E A PARTICIPACAO DO ELEMENTO, NAO O TETO.
	#
	# Cada elemento anda em direcao a `ADAPT_TETO x (acertos dele / acertos do
	# quadro)`. Quem carrega a build inteira mira nos 62%; quem divide meio a
	# meio com outro mira em 31% cada; quem quase nao aparece mira perto de zero
	# e desce. A velocidade continua sendo a mesma de antes (`ADAPT_GANHO_SEG`
	# para subir, `ADAPT_DECAI` para descer), entao a curva segue no relogio e o
	# ruido de um quadro nao decide nada — o valor integra a media ao longo de
	# muitos quadros.
	#
	# Agora diversificar FUNCIONA, que e o que o jogo promete em dois lugares.
	var usados: Dictionary = s.get("_adapt_uso", {})
	var total := 0
	for k2 in usados.keys():
		total += int(usados[k2])
	for k in a.keys():
		var atual := float(a[k])
		var alvo := 0.0
		if total > 0:
			alvo = ADAPT_TETO * (float(int(usados.get(k, 0))) / float(total))
		if atual < alvo:
			a[k] = minf(alvo, atual + ADAPT_GANHO_SEG * dt)
		elif atual > alvo:
			a[k] = maxf(alvo, atual - ADAPT_DECAI * dt)
	if not usados.is_empty():
		s["_adapt_uso"] = {}

## Multiplicador de dano do elemento depois da adaptação.
static func fator_elemento(s: Dictionary, elemento: String) -> float:
	if elemento == "":
		return 1.0
	var a := estado_adaptacao(s)
	return 1.0 - float(a.get(elemento, 0.0))

static func elemento_mais_adaptado(s: Dictionary) -> Array:
	var a := estado_adaptacao(s)
	var melhor := ""
	var v := 0.0
	for k in a.keys():
		if float(a[k]) > v:
			v = float(a[k])
			melhor = str(k)
	return [melhor, v]

# =========================================================== O PEREGRINO ===
## Um inimigo que não ataca ninguém. Atravessa a arena e vai embora.
## Matar dá muito ouro. Poupar não dá nada — só conta, para sempre.
const PEREGRINO_ONDA_MIN := 30
const PEREGRINO_CHANCE := 0.0055
const PEREGRINO_OURO := 40.0

static func talvez_peregrino(onda: int, j) -> void:
	if onda < PEREGRINO_ONDA_MIN:
		return
	var s: Dictionary = j.s
	if int(s.get("peregrino_onda", -1)) == onda:
		return
	var sorteou: bool = j.rng.chance(PEREGRINO_CHANCE * maxf(1.0, float(j.stats.n("sorte")) * 0.5))
	if not sorteou:
		return
	s["peregrino_onda"] = onda
	var def: Dictionary = Dados.inimigo_por_id.get("peregrino", {})
	if def.is_empty():
		return
	var e: Inimigo = EnemyAI.criar(def, onda, j, {})
	if e == null:
		return
	e.ouro = Big.mul_f(e.ouro, PEREGRINO_OURO)
	e.peregrino = true
	Bus.toast(Txt.t("sim_peregrino_chegou"), "info")

## Chamado quando o peregrino sai da tela sem ser morto.
static func peregrino_poupado(j) -> void:
	var s: Dictionary = j.s
	s["peregrinos_poupados"] = int(s.get("peregrinos_poupados", 0)) + 1
	Bus.toast(Txt.t("sim_peregrino_poupado"), "info")

static func peregrino_morto(j) -> void:
	var s: Dictionary = j.s
	s["peregrinos_mortos"] = int(s.get("peregrinos_mortos", 0)) + 1

# ============================================================ O PANTEÃO ====
## Consagrar um conjunto completo DESTRÓI aquelas cartas para sempre em troca
## de um multiplicador eterno, imune a todos os prestígios. É o único sistema
## do jogo em que você perde algo de verdade — e por isso o único em que a
## decisão pesa.
const PANTEAO_DANO := 1.18
const PANTEAO_OURO := 1.12

static func estado_panteao(s: Dictionary) -> Dictionary:
	if not s.has("panteao"):
		s["panteao"] = {}
	return s["panteao"]

## O jogador tem todas as cartas do conjunto no inventário?
static func pode_consagrar(s: Dictionary, conjunto_id: String) -> bool:
	var conj := _conjunto(conjunto_id)
	if conj.is_empty():
		return false
	for id in conj.get("cartas", []):
		if _achar_carta_por_id(s, str(id)).is_empty():
			return false
	return true

static func consagrar(j, conjunto_id: String) -> bool:
	var s: Dictionary = j.s
	if not pode_consagrar(s, conjunto_id):
		return false
	var conj := _conjunto(conjunto_id)
	# destrói uma cópia de cada carta do conjunto — de verdade, sem volta
	for id in conj.get("cartas", []):
		var inst := _achar_carta_por_id(s, str(id))
		if inst.is_empty():
			continue
		var uid := str(inst["uid"])
		for i in s["cartas"]["equipadas"].size():
			if str(s["cartas"]["equipadas"][i]) == uid:
				s["cartas"]["equipadas"][i] = ""
		var inv: Array = s["cartas"]["inventario"]
		for i in inv.size():
			if str(inv[i]["uid"]) == uid:
				inv.remove_at(i)
				break
	var p := estado_panteao(s)
	p[conjunto_id] = int(p.get(conjunto_id, 0)) + 1
	j.marcar_sujo()
	Bus.celebracao.emit("panteao", {"conjunto": conjunto_id, "nivel": int(p[conjunto_id])})
	Bus.toast(Txt.f("sim_consagrado", {"n": Ux.txt(conj, "nome", Cfg.ingles())}), "epico")
	return true

static func bonus_panteao(s: Dictionary) -> Dictionary:
	var total := 0
	for k in estado_panteao(s).keys():
		total += int(s["panteao"][k])
	return {"n": total, "dano": pow(PANTEAO_DANO, float(total)), "ouro": pow(PANTEAO_OURO, float(total))}

static func _conjunto(id: String) -> Dictionary:
	for c in Dados.conjuntos:
		if str(c.get("id", "")) == id:
			return c
	return {}

static func _achar_carta_por_id(s: Dictionary, id_carta: String) -> Dictionary:
	for c in s["cartas"]["inventario"]:
		if str(c.get("id", "")) == id_carta:
			return c
	return {}

# ==================================================== CAIXA DA VIGÍLIA =====
## O saque offline chega LACRADO. Você abre uma carta por vez, com o momento
## que o progresso offline normalmente assassina.
const CAIXA_SEG_POR_CARTA := 900.0
const CAIXA_MAX := 12

static func estado_caixa(s: Dictionary) -> Dictionary:
	if not s.has("caixa"):
		s["caixa"] = {"seladas": 0, "abertas": 0}
	return s["caixa"]

static func selar_offline(s: Dictionary, segundos: float, sorte: float) -> int:
	var n := int(floor(segundos / CAIXA_SEG_POR_CARTA * maxf(0.5, sorte)))
	n = clampi(n, 0, CAIXA_MAX)
	if n <= 0:
		return 0
	var c := estado_caixa(s)
	c["seladas"] = mini(CAIXA_MAX * 3, int(c["seladas"]) + n)
	return n

static func abrir_caixa(j) -> Dictionary:
	var c := estado_caixa(j.s)
	if int(c["seladas"]) <= 0:
		return {}
	c["seladas"] = int(c["seladas"]) - 1
	c["abertas"] = int(c["abertas"]) + 1
	return Saque.criar_carta(j, "", true)

# =========================================================== A RETOMADA ====
## Depois de um prestígio, o jogo acelera sozinho e reconstrói o império
## enquanto você assiste — com a marca da run anterior na tela para ser
## ultrapassada ao vivo. O reset deixa de ser o anticlímax e vira o clímax.
## A RETOMADA ACABA POR PROGRESSO, NAO POR RELOGIO.
##
## Eram 10 segundos reais fixos. A ×6, isso da 60 segundos de jogo, e uma onda
## leva de 16 a 18 s: quatro ondas. Como o ALVO e o recorde da corrida anterior
## — que podia ser a onda 200 — `superou` nunca acontecia, e a mecanica que
## existe para transformar o reset em climax terminava sempre do mesmo jeito:
## o cronometro zerava no meio da subida e o jogo voltava ao normal sem dizer
## nada. Era uma corrida com a linha de chegada fora da pista.
##
## Agora ela dura ENQUANTO ESTIVER SUBINDO: acaba quando o alvo e superado
## (o final que ela sempre prometeu), quando passam `RETOMADA_PARADA` segundos
## reais sem ganhar uma onda, ou no teto duro — que existe so para o caso
## degenerado de uma build que sobe para sempre.
const RETOMADA_DURACAO := 45.0
const RETOMADA_PARADA := 6.0
const RETOMADA_VELOCIDADE := 6.0

static func iniciar_retomada(j, onda_anterior: int) -> void:
	if onda_anterior < 8:
		return
	j.s["retomada"] = {
		"restante": RETOMADA_DURACAO,
		"alvo": onda_anterior,
		"velocidade_antes": float(j.velocidade),
		"auto_antes": bool(j.s["auto"]["comprar"]),
		"superou": false,
		"onda_vista": int(j.s["onda"]),
		"parado": 0.0,
	}
	j.s["auto"]["comprar"] = true
	j.fator_retomada = RETOMADA_VELOCIDADE
	j.aplicar_time_scale()
	Bus.celebracao.emit("retomada", {"alvo": onda_anterior})

static func atualizar_retomada(dt: float, j) -> void:
	if not em_retomada(j.s):
		return
	var r: Dictionary = j.s["retomada"]
	# a compra automática da Retomada não depende de desbloqueio: é cortesia da casa
	j.auto_comprar()
	j.auto_comprar()
	j.auto_comprar()

	if int(j.s["onda"]) > int(r["alvo"]) and not bool(r["superou"]):
		r["superou"] = true
		Bus.celebracao.emit("retomada_superada", {"onda": int(j.s["onda"])})
		Bus.toast(Txt.t("sim_retomada_superada"), "epico")

	# `dt` chega ja acelerado pelo `time_scale`; dividir pela velocidade devolve
	# o tempo REAL, que e o que o jogador sente.
	var real := dt / maxf(0.001, RETOMADA_VELOCIDADE)
	r["restante"] = float(r["restante"]) - real
	# Enquanto a onda sobe, o cronometro de parada volta para o comeco: a
	# Retomada acompanha a subida em vez de cortar no meio dela.
	var agora := int(j.s["onda"])
	if agora > int(r.get("onda_vista", 0)):
		r["onda_vista"] = agora
		r["parado"] = 0.0
	else:
		r["parado"] = float(r.get("parado", 0.0)) + real
	if bool(r["superou"]) or float(r["restante"]) <= 0.0 or float(r["parado"]) >= RETOMADA_PARADA:
		encerrar_retomada(j)

static func encerrar_retomada(j) -> void:
	if not em_retomada(j.s):
		return
	var r: Dictionary = j.s["retomada"]
	j.s["auto"]["comprar"] = bool(r["auto_antes"])
	j.velocidade = float(r["velocidade_antes"])
	j.fator_retomada = 1.0
	j.aplicar_time_scale()
	j.s["retomada"] = {}

## Estar em Retomada é ter um ALVO, não ter a chave. Enquanto `retomada` só
## nascia quando começava, `has` bastava; agora que ela é campo de primeira
## classe do estado (e portanto existe vazia desde o início), a pergunta certa é
## se ela tem conteúdo.
static func em_retomada(s: Dictionary) -> bool:
	var r = s.get("retomada", null)
	return r is Dictionary and r.has("alvo")

# ============================================================== DICAS ======
## As dicas vêm dos dados como objetos {id, icone, tag, texto}. Esta função
## existe para que ninguém precise lembrar disso na hora de mostrar uma.
static func dica_aleatoria(semente: int = 0) -> String:
	if Dados.dicas.is_empty():
		return ""
	var i := absi(semente) % Dados.dicas.size()
	var d = Dados.dicas[i]
	if d is Dictionary:
		return Ux.txt(d, "texto", Cfg.ingles())
	return str(d)

# ========================================================= AGLOMERAÇÃO =====
## O teto de entidades vira economia: quanto mais inimigos vivos, mais cada
## abate vale. O jogador PERSEGUE a lotação da tela — e 60 fps saem por design.
const AGLOM_EXPO := 0.80
const AGLOM_DIV := 100.0

static func fator_aglomeracao(vivos: int) -> float:
	return pow(1.0 + float(vivos) / AGLOM_DIV, AGLOM_EXPO)
