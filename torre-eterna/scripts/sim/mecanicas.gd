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
		j.torre.cd_tiro = maxf(j.torre.cd_tiro, 1.2)
		Bus.toast("O núcleo estourou sozinho — você perdeu a janela.", "ruim")

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
	Bus.toast("Algo atravessa a arena sem olhar para você.", "info")

## Chamado quando o peregrino sai da tela sem ser morto.
static func peregrino_poupado(j) -> void:
	var s: Dictionary = j.s
	s["peregrinos_poupados"] = int(s.get("peregrinos_poupados", 0)) + 1
	Bus.toast("O Peregrino seguiu em frente. A torre registrou.", "info")

static func peregrino_morto(j) -> void:
	var s: Dictionary = j.s
	s["peregrinos_mortos"] = int(s.get("peregrinos_mortos", 0)) + 1

# ========================================================= AGLOMERAÇÃO =====
## O teto de entidades vira economia: quanto mais inimigos vivos, mais cada
## abate vale. O jogador PERSEGUE a lotação da tela — e 60 fps saem por design.
const AGLOM_EXPO := 0.80
const AGLOM_DIV := 100.0

static func fator_aglomeracao(vivos: int) -> float:
	return pow(1.0 + float(vivos) / AGLOM_DIV, AGLOM_EXPO)
