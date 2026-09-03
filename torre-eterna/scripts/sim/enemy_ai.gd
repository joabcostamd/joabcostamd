class_name EnemyAI
extends RefCounted

## Nascimento, movimentação e habilidades dos inimigos.

## ------------------------------------------------------------- criação

static func criar(def: Dictionary, onda: int, j, opt: Dictionary = {}) -> Inimigo:
	var e: Inimigo = j.arena.novo_inimigo()
	if e == null:
		return null

	e.ativo = true
	e.tipo = str(def.get("id", "grunhido"))
	e.def = def
	e.chefe = bool(opt.get("chefe", false))
	e.super_chefe = bool(opt.get("super", false))
	e.elite = bool(opt.get("elite", false))
	e.dourado = bool(opt.get("dourado", false))
	e.elite_mod = str(opt.get("elite_mod", ""))
	e.dividido = bool(opt.get("dividido", false))
	e.segmento = bool(opt.get("segmento", false))

	var pos_padrao: Vector2 = j.arena.ponto_spawn(j.rng)
	e.pos = opt.get("pos", pos_padrao)
	e.dir_ang = (j.arena.centro - e.pos).angle()
	e.ang = e.dir_ang

	var m_hp := float(def.get("hp", 1.0))
	var m_ouro := float(def.get("ouro", 1.0))
	var m_vel := float(def.get("vel", 1.0))
	var m_esc := float(def.get("esc", 1.0))
	var m_xp := 1.0

	if e.chefe:
		var M: Dictionary = Bal.SUPER_CHEFE if e.super_chefe else Bal.CHEFE
		m_hp *= float(M["hp"]); m_ouro *= float(M["ouro"]); m_xp *= float(M["xp"])
		m_esc *= float(M["escala"]); m_vel *= float(M["vel"])
	if e.elite:
		var mod := _elite(e.elite_mod)
		m_hp *= float(mod.get("hp", 1.0)) * float(Bal.ELITE["hp"])
		m_ouro *= float(mod.get("ouro", 1.0)) * float(Bal.ELITE["ouro"])
		m_xp *= float(Bal.ELITE["xp"])
		m_esc *= float(mod.get("esc", 1.0)) * float(Bal.ELITE["escala"])
		m_vel *= float(mod.get("vel", 1.0))
	if e.dourado:
		m_hp *= float(Bal.DOURADO["hp"]); m_ouro *= float(Bal.DOURADO["ouro"])
		m_xp *= float(Bal.DOURADO["xp"]); m_esc *= float(Bal.DOURADO["escala"]); m_vel *= float(Bal.DOURADO["vel"])
	m_hp *= float(opt.get("hp_mult", 1.0))
	m_esc *= float(opt.get("esc_mult", 1.0))

	var hp: float = Big.mul_f(Bal.hp_onda(onda), m_hp * float(j.mods_dif.get("hpInimigo", 1.0)))
	e.hp_max = hp
	e.hp = hp
	e.ouro = Big.mul_f(Bal.ouro_onda(onda), m_ouro * float(j.mods_dif.get("ouro", 1.0)))
	e.xp = Big.mul_f(Bal.xp_onda(onda), m_xp)
	e.armadura = float(def.get("armadura", 0.0)) + (25.0 if e.chefe else 0.0) + float(onda) * 0.35
	e.escala = m_esc
	e.raio = 15.0 * m_esc
	e.vel_base = Bal.velocidade_inimigo(onda) * m_vel * float(j.mods_dif.get("velocidadeInimigo", 1.0))
	e.velocidade = e.vel_base
	e.entrada = 0.35
	e.cd = float(j.rng.entre(0.0, 1.0))
	e.fase_anim = float(j.rng.entre(0.0, TAU))
	e.forma = str(def.get("forma", "circulo"))
	e.mov = str(def.get("mov", "direto"))
	e.hab = str(def.get("hab", ""))
	e.cor = Color.html(str(def.get("cor", "#8b93a7")))
	e.cor2 = Color.html(str(def.get("cor2", "#3a4050")))
	if e.elite:
		var mod2 := _elite(e.elite_mod)
		if mod2.has("cor"):
			e.cor2 = Color.html(str(mod2["cor"]))
	if e.dourado:
		e.cor = Color.html("#fcd34d")
		e.cor2 = Color.html("#92400e")

	if def.has("escudoFrac"):
		e.escudo_max = Big.to_f(Big.mul_f(hp, float(def["escudoFrac"])))
		e.escudo = e.escudo_max
	if e.chefe:
		var fases := maxi(1, int(def.get("fases", 1)))
		e.fase_prox = 1.0 - 1.0 / float(fases)

	Bus.inimigo_surgiu.emit(e)
	if e.chefe:
		Bus.chefe_surgiu.emit(e)
	return e

static func _elite(id: String) -> Dictionary:
	for m in Dados.elites:
		if str(m.get("id", "")) == id:
			return m
	return {}

## Sorteia e cria um inimigo apropriado para a onda.
static func spawn_onda(onda: int, j) -> void:
	var pool := Dados.pool_da_onda(onda)
	if pool.is_empty():
		return
	var def_v = j.rng.por_peso(pool, "peso")
	if not (def_v is Dictionary):
		return
	var def: Dictionary = def_v

	var elite: bool = j.rng.chance(Bal.chance_elite(onda))
	var dourado: bool = (not elite) and bool(j.rng.chance(Bal.chance_dourado(onda) * maxf(1.0, float(j.stats.n("sorte")))))
	var opt := {"elite": elite, "dourado": dourado}
	if elite and not Dados.elites.is_empty():
		var em: Dictionary = j.rng.escolher(Dados.elites)
		opt["elite_mod"] = str(em.get("id", ""))

	if def.has("grupo"):
		var g: Array = def["grupo"]
		var n: int = j.rng.inteiro(int(g[0]), int(g[1]))
		var base: Vector2 = j.arena.ponto_spawn(j.rng)
		for i in n:
			var o := opt.duplicate()
			o["elite"] = elite and i == 0
			var off: Vector2 = j.rng.direcao()
			o["pos"] = base + off * float(j.rng.entre(0.0, 40.0))
			criar(def, onda, j, o)
		return
	criar(def, onda, j, opt)

## Cria o chefe da onda (e os segmentos, se houver).
static func spawn_chefe(onda: int, j) -> Inimigo:
	var def := Dados.chefe_da_onda(onda)
	if def.is_empty():
		return null
	# Chefe entra DENTRO da tela, com cerimônia — não caminhando meia arena.
	var centro_c: Vector2 = j.arena.centro
	var dir_c: Vector2 = j.rng.direcao()
	var dist: float = minf(j.arena.largura, j.arena.altura) * 0.33
	var e: Inimigo = criar(def, onda, j, {
		"chefe": true, "super": Bal.eh_super_chefe(onda),
		"pos": centro_c + dir_c * dist,
	})
	if e != null:
		e.entrada = 0.9
		e.atordoado = 0.9
		Bus.particulas.emit("pulso", e.pos, {"raio": 180.0, "cor": e.cor})
		Bus.particulas.emit("explosao", e.pos, {"raio": 90.0, "cor": e.cor})
		Bus.tremor_pedido.emit(16.0, 0.5)
		Bus.camera_lenta.emit(0.35, 700.0)
	if e != null and str(def.get("mecanica", "")) == "segmentos":
		var n := int(def.get("segmentos", 6))
		for i in n:
			var seg: Inimigo = criar(def, onda, j, {
				"segmento": true, "hp_mult": 0.16, "esc_mult": 0.55,
				"pos": e.pos - Vector2(cos(e.dir_ang), sin(e.dir_ang)) * float(i + 1) * 26.0,
			})
	return e

static func dividir(e: Inimigo, j) -> void:
	var cfg = e.def.get("divide", null)
	if not (cfg is Dictionary):
		return
	for i in int(cfg.get("qtd", 2)):
		var dir: Vector2 = j.rng.direcao()
		var filho: Inimigo = criar(e.def, int(j.s["onda"]), j, {
			"dividido": true,
			"hp_mult": float(cfg.get("hp", 0.35)),
			"esc_mult": float(cfg.get("esc", 0.6)),
			"pos": e.pos + dir * 18.0,
		})
		if filho != null:
			filho.vel_res = dir * 60.0

## ------------------------------------------------------- movimentação

static func mover(e: Inimigo, dt: float, j) -> void:
	var centro: Vector2 = j.arena.centro
	match e.mov:
		"zigue":
			var ang := (centro - e.pos).angle()
			e.dir_ang = ang
			var lateral := sin(e.t * 4.2 + e.fase_anim) * 52.0
			e.pos += (Vector2(cos(ang), sin(ang)) * e.velocidade + Vector2(cos(ang + PI * 0.5), sin(ang + PI * 0.5)) * lateral) * dt
		"salto":
			e.cd -= dt
			if e.estado == 0:
				if e.cd <= 0.0:
					e.estado = 1
					e.cd = 0.55
			else:
				var a := (centro - e.pos).angle()
				e.dir_ang = a
				e.pos += Vector2(cos(a), sin(a)) * e.velocidade * 3.2 * dt
				e.altura = sin((1.0 - e.cd / 0.55) * PI) * 22.0
				if e.cd <= 0.0:
					e.estado = 0
					e.cd = 0.9
					e.altura = 0.0
		"teleporte":
			e.cd -= dt
			_direto(e, dt * 0.45, centro)
			if e.cd <= 0.0:
				e.cd = 2.4
				var d := e.pos.distance_to(centro)
				var salto := minf(150.0, d - Bal.RAIO_TORRE - e.raio - 10.0)
				if salto > 20.0:
					e.piscou = 0.3
					e.pos += (centro - e.pos).normalized() * salto
		"fantasma":
			e.cd -= dt
			if e.cd <= 0.0:
				if e.intangivel > 0.0:
					e.intangivel = 0.0
					e.cd = 2.0
				else:
					e.intangivel = 1.1
					e.cd = 1.1
			if e.intangivel > 0.0:
				e.intangivel -= dt
			_direto(e, dt, centro)
		"parar_atirar":
			var dist := e.pos.distance_to(centro)
			var alcance := float(e.def.get("alcance", 250.0))
			if dist > alcance:
				_direto(e, dt, centro)
			else:
				e.dir_ang = (centro - e.pos).angle()
				e.cd -= dt
				if e.cd <= 0.0:
					e.cd = 2.2
					j.projetil_inimigo(e)
		"errante":
			e.vagueio += dt
			var ang2 := (centro - e.pos).angle() + sin(e.vagueio * 1.7 + e.fase_anim) * 0.9
			e.dir_ang = ang2
			e.pos += Vector2(cos(ang2), sin(ang2)) * e.velocidade * dt
		"perseguidor":
			var dd := e.pos.distance_to(centro)
			var acel := clampf(1.0 + (400.0 - dd) / 300.0, 1.0, 2.6)
			var a3 := (centro - e.pos).angle()
			e.dir_ang = a3
			e.pos += Vector2(cos(a3), sin(a3)) * e.velocidade * acel * dt
		"orbital":
			var ang4 := (e.pos - centro).angle()
			var d4 := e.pos.distance_to(centro)
			var novo_ang := ang4 + (e.velocidade / maxf(60.0, d4)) * dt * 1.4
			var novo_d := maxf(Bal.RAIO_TORRE, d4 - e.velocidade * dt * 0.45)
			e.pos = centro + Vector2(cos(novo_ang), sin(novo_ang)) * novo_d
			e.dir_ang = (centro - e.pos).angle()
		"passa":
			# O Peregrino não vai à torre: atravessa a arena em linha reta.
			if e.estado == 0:
				e.estado = 1
				var alvo_ang: float = (centro - e.pos).angle() + float(j.rng.entre(-0.55, 0.55))
				e.dir_ang = alvo_ang
			e.pos += Vector2(cos(e.dir_ang), sin(e.dir_ang)) * e.velocidade * dt
		"estatico":
			e.dir_ang = (centro - e.pos).angle()
		_:
			_direto(e, dt, centro)

static func _direto(e: Inimigo, dt: float, centro: Vector2) -> void:
	var ang := (centro - e.pos).angle()
	e.dir_ang = ang
	e.pos += Vector2(cos(ang), sin(ang)) * e.velocidade * dt

## -------------------------------------------------------- habilidades

static func habilidade(e: Inimigo, dt: float, j) -> void:
	if e.hab == "":
		return
	match e.hab:
		"curar":
			e.cd -= dt
			if e.cd > 0.0:
				return
			e.cd = 2.0
			var raio := float(e.def.get("raio", 130.0))
			var alvos_c: Array = j.arena.em_area(e.pos, raio)
			var alvos: Array = alvos_c.duplicate()
			var curou := 0
			for a in alvos:
				if a == e or not a.vivo():
					continue
				a.hp = Big.min_b(Big.add(a.hp, Big.mul_f(a.hp_max, 0.06)), a.hp_max)
				curou += 1
			if curou > 0:
				Bus.particulas.emit("pulso", e.pos, {"raio": raio, "cor": "#86efac"})
		"roubar_ouro":
			e.cd -= dt
			if e.cd > 0.0:
				return
			e.cd = 1.6
			var lista: Array = j.arena.coletaveis
			for i in range(lista.size() - 1, -1, -1):
				var c: Coletavel = lista[i]
				if c.ativo and c.pos.distance_to(e.pos) < 70.0:
					e.ouro = Big.add(e.ouro, c.valor)
					j.arena.soltar_coletavel(i)
					Bus.particulas.emit("faisca", c.pos, {"cor": "#f472b6"})
		"grudar":
			if e.grudado:
				e.cd -= dt
				if e.cd <= 0.0:
					e.cd = 1.0
					j.dano_na_torre(Bal.mul_contato(e, int(j.s["onda"]), 0.5), e, {"drenar": true})
		"chocar":
			e.cd -= dt
			if e.cd > 0.0:
				return
			e.cd = 4.5
			var def_enx: Dictionary = Dados.inimigo_por_id.get("enxame", {})
			if def_enx.is_empty():
				return
			for i in 3:
				var dd2: Vector2 = j.rng.direcao()
				criar(def_enx, int(j.s["onda"]), j, {"pos": e.pos + dd2 * 20.0})
			Bus.particulas.emit("pulso", e.pos, {"raio": 50.0, "cor": "#d9f99d"})
		"devorar":
			var lista2: Array = j.arena.coletaveis
			for i in range(lista2.size() - 1, -1, -1):
				var c2: Coletavel = lista2[i]
				if c2.ativo and c2.pos.distance_to(e.pos) < 55.0:
					e.hp = Big.min_b(Big.add(e.hp, Big.mul_f(e.hp_max, 0.05)), Big.mul_f(e.hp_max, 2.0))
					e.escala = minf(3.0, e.escala * 1.03)
					e.raio = 15.0 * e.escala
					j.arena.soltar_coletavel(i)
					Bus.particulas.emit("faisca", c2.pos, {"cor": "#dc2626"})
		"mutar":
			e.cd -= dt
			if e.cd > 0.0:
				return
			e.cd = 3.0
			e.mutacao += 1
			if e.mutacao % 2 == 0:
				e.armadura = float(e.def.get("armadura", 0.0)) + 60.0
				e.vel_base = float(e.def.get("vel", 1.0)) * 0.6 * Bal.velocidade_inimigo(int(j.s["onda"]))
			else:
				e.armadura = 0.0
				e.vel_base = float(e.def.get("vel", 1.0)) * 1.6 * Bal.velocidade_inimigo(int(j.s["onda"]))
			Bus.particulas.emit("pulso", e.pos, {"raio": 40.0, "cor": "#7c3aed"})
		"ceifar":
			e.cd -= dt
			if e.cd > 0.0:
				return
			e.cd = 5.0
			var centro_j: Vector2 = j.arena.centro
			var d5 := e.pos.distance_to(centro_j)
			if d5 < 300.0 and d5 > 80.0:
				e.pos += (j.arena.centro - e.pos).normalized() * 120.0
				e.piscou = 0.3
				Bus.particulas.emit("pulso", e.pos, {"raio": 60.0, "cor": "#f43f5e"})

## ------------------------------------------------------------- update

static func atualizar(dt: float, j) -> void:
	var lista: Array = j.arena.inimigos
	var centro: Vector2 = j.arena.centro
	for i in range(lista.size() - 1, -1, -1):
		var e: Inimigo = lista[i]
		if not e.ativo:
			j.arena.soltar_inimigo(i)
			continue
		if e.morrendo > 0.0:
			e.morrendo -= dt
			if e.morrendo <= 0.0:
				j.arena.soltar_inimigo(i)
			continue

		e.t += dt
		if e.cd_contato > 0.0:
			e.cd_contato -= dt
		if e.entrada > 0.0:
			e.entrada -= dt
		if e.piscou > 0.0:
			e.piscou -= dt

		var vel := e.vel_base
		if e.gelo > 0.0:
			vel *= (1.0 - e.gelo_forca)
		if e.atordoado > 0.0 or j.tempo_congelado > 0.0:
			vel = 0.0
		e.velocidade = vel

		if e.elite_mod == "regenerativo" and Big.lt(e.hp, e.hp_max):
			e.hp = Big.min_b(Big.add(e.hp, Big.mul_f(e.hp_max, 0.02 * dt)), e.hp_max)
		if e.escudo_max > 0.0 and e.escudo < e.escudo_max and e.sem_dano_t > 2.5:
			e.escudo = minf(e.escudo_max, e.escudo + e.escudo_max * 0.25 * dt)
		e.sem_dano_t += dt

		if not e.grudado and vel > 0.0:
			mover(e, dt, j)
			if e.vel_res.length_squared() > 1.0:
				e.pos += e.vel_res * dt
				e.vel_res *= pow(0.02, dt)
			else:
				e.vel_res = Vector2.ZERO

		if e.hab != "":
			habilidade(e, dt, j)
		if e.chefe:
			j.atualizar_chefe(e, dt)

		e.ang = e.dir_ang

		# O Peregrino nunca encosta na torre; ele só vai embora.
		if e.peregrino:
			if not e.saiu and j.arena.fora_da_arena(e.pos, 60.0) and e.t > 2.0:
				e.saiu = true
				Mecanicas.peregrino_poupado(j)
				e.morrendo = 0.2
				e.hp = Big.ZERO
			continue

		var d := e.pos.distance_to(centro)
		if d <= Bal.RAIO_TORRE + e.raio * 0.7:
			if e.hab == "grudar" and not e.grudado:
				e.grudado = true
				e.ang_grude = (e.pos - centro).angle()
				e.pos = centro + Vector2(cos(e.ang_grude), sin(e.ang_grude)) * (Bal.RAIO_TORRE + e.raio * 0.5)
			elif not e.grudado and e.cd_contato <= 0.0:
				# O inimigo comum morre no impacto, entao a recarga so pesa para
				# o chefe — que ficava encostado batendo a cada passo de fisica.
				e.cd_contato = Bal.CD_CONTATO
				j.impacto_na_torre(e)
