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

static func atualizar_purga(dt: float, j) -> void:
	var p := estado_purga(j.s)
	if not bool(j.s["torre"]["viva"]):
		return
	var vel: float = 1.0 / PURGA_TEMPO_BASE * (1.0 + float(j.stats.n("cdr")))
	p["carga"] = float(p["carga"]) + vel * dt
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
	Bus.habilidade_usada.emit("purga", 1)
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
const ADAPT_GANHO := 0.010
const ADAPT_DECAI := 0.0016
const ADAPT_TETO := 0.62

static func estado_adaptacao(s: Dictionary) -> Dictionary:
	if not s.has("adaptacao"):
		s["adaptacao"] = {"fogo": 0.0, "gelo": 0.0, "raio": 0.0, "veneno": 0.0, "vazio": 0.0}
	return s["adaptacao"]

static func registrar_elemento(s: Dictionary, elemento: String) -> void:
	if elemento == "":
		return
	var a := estado_adaptacao(s)
	if not a.has(elemento):
		return
	a[elemento] = minf(ADAPT_TETO, float(a[elemento]) + ADAPT_GANHO)

static func decair_adaptacao(dt: float, s: Dictionary) -> void:
	var a := estado_adaptacao(s)
	for k in a.keys():
		a[k] = maxf(0.0, float(a[k]) - ADAPT_DECAI * dt)

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
const RETOMADA_DURACAO := 10.0
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
	}
	j.s["auto"]["comprar"] = true
	Engine.time_scale = RETOMADA_VELOCIDADE
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

	r["restante"] = float(r["restante"]) - dt / maxf(0.001, RETOMADA_VELOCIDADE)
	if float(r["restante"]) <= 0.0 or bool(r["superou"]):
		encerrar_retomada(j)

static func encerrar_retomada(j) -> void:
	if not em_retomada(j.s):
		return
	var r: Dictionary = j.s["retomada"]
	j.s["auto"]["comprar"] = bool(r["auto_antes"])
	j.velocidade = float(r["velocidade_antes"])
	Engine.time_scale = j.velocidade
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
