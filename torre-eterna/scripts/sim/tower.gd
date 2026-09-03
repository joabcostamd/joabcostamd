class_name TorreSim
extends RefCounted

## A torre: mira, disparo, projéteis, orbes e defesa.

var j                                 # autoload Jogo
var cd_tiro := 0.0
var angulo_canhao := -PI * 0.5
var recuo := 0.0
var pulso := 0.0
var iframes := 0.0
var tempo_sem_dano := 0.0
var orbes: Array = []                 # [{ang, raio, cd, pos}]
var orbes_extra := 0

const MODOS_MIRA := ["proximo", "avancado", "forte", "fraco", "chefe", "longe"]

func _init(jogo) -> void:
	j = jogo

## ------------------------------------------------------------- update

func atualizar(dt: float) -> void:
	var s: Dictionary = j.s
	var torre: Dictionary = s["torre"]
	if not bool(torre["viva"]):
		torre["tempo_morta"] = float(torre["tempo_morta"]) - dt
		if float(torre["tempo_morta"]) <= 0.0:
			j.reviver_torre()
		return

	if iframes > 0.0:
		iframes -= dt
	if recuo > 0.0:
		recuo = maxf(0.0, recuo - dt * 7.0)
	pulso += dt
	tempo_sem_dano += dt

	# regeneração (bloqueada por parasitas grudados)
	var regen: float = j.stats.n("regen")
	if regen > 0.0 and j.parasitas == 0 and float(torre["vida"]) < float(torre["vida_max"]):
		torre["vida"] = minf(float(torre["vida_max"]), float(torre["vida"]) + regen * dt)
	var esc_regen: float = j.stats.n("escudoRegen")
	if esc_regen > 0.0 and float(torre["escudo"]) < float(torre["escudo_max"]) and tempo_sem_dano > 2.0:
		torre["escudo"] = minf(float(torre["escudo_max"]), float(torre["escudo"]) + esc_regen * dt)

	# juros sobre o ouro guardado
	var juros: float = j.stats.n("jurosOuro")
	if juros > 0.0:
		j.ganhar_ouro(Big.mul_f(s["moedas"]["ouro"], juros * dt), "juros", true)

	# mira
	var alcance: float = j.stats.n("alcance")
	var centro_m: Vector2 = j.arena.centro
	var alvo: Inimigo = j.arena.alvo(centro_m, alcance, str(torre["mira"]))
	if alvo != null:
		var centro_a: Vector2 = j.arena.centro
		var ang := (alvo.pos - centro_a).angle()
		angulo_canhao = Ux.ang_lerp(angulo_canhao, ang, minf(1.0, dt * 16.0))

	# cadência
	var cadencia: float = maxf(0.05, j.stats.n("cadencia"))
	cd_tiro -= dt
	var tiros := 0
	while cd_tiro <= 0.0 and tiros < 12:
		cd_tiro += 1.0 / cadencia
		if alvo == null:
			break
		disparar(alvo)
		tiros += 1
	if cd_tiro < 0.0:
		cd_tiro = 0.0

	atualizar_orbes(dt)

## ------------------------------------------------------------ disparo

func disparar(alvo: Inimigo) -> void:
	var n: int = maxi(1, int(j.stats.n("projeteis")))
	var espalhamento: float = minf(0.6, 0.06 * float(n)) if n > 1 else 0.0
	var centro_b: Vector2 = j.arena.centro
	var base := (alvo.pos - centro_b).angle()
	var alcance: float = j.stats.n("alcance")

	for i in n:
		var t := 0.0 if n == 1 else (float(i) / float(n - 1) - 0.5) * 2.0
		var ang := base + t * espalhamento
		var alvo_p := alvo
		if i > 0:
			var outro: Inimigo = j.arena.alvo(centro_b, alcance, "proximo")
			if outro != null:
				alvo_p = outro
		_criar_projetil(ang, alvo_p)

	# passiva Eco Balístico: chance de repetir a salva
	if j.pas.has("eco"):
		var chance: float = float(j.pas.get("eco:valor", 0.12)) * float(j.pas["eco"])
		if j.rng.chance(minf(0.6, chance)):
			_criar_projetil(base, alvo)

	recuo = 1.0
	j.s["stats"]["tiros"] = int(j.s["stats"]["tiros"]) + 1
	Bus.torre_atirou.emit(angulo_canhao, n)

func _criar_projetil(ang: float, alvo: Inimigo) -> void:
	var p: Projetil = j.arena.novo_projetil()
	var dano_base := Big.mul_f(j.stats.b("dano"), j.stats.n("multiplicador"))
	var golpe := Combate.rolar_golpe(dano_base, j, alvo)

	p.ativo = true
	var centro_p: Vector2 = j.arena.centro
	p.pos = centro_p + Vector2(cos(ang), sin(ang)) * (Bal.RAIO_TORRE - 4.0)
	p.velocidade = j.stats.n("velProjetil")
	p.vel = Vector2(cos(ang), sin(ang)) * p.velocidade
	p.ang = ang
	p.dano = golpe[0]
	p.critico = golpe[1]
	p.alvo = alvo
	p.perfuracao = int(j.stats.n("perfuracao"))
	p.ricochete = int(j.stats.n("ricochete"))
	p.area = j.stats.n("area")
	p.raio = 6.0 if p.critico else 4.0
	p.vida = 3.5
	p.origem = "torre"
	p.elemento = _sortear_elemento()
	if p.elemento != "":
		p.cor = Color.html(str(Bal.ELEMENTOS[p.elemento]["cor"]))
	else:
		p.cor = Color.html("#fde047") if p.critico else Color.html("#7dd3fc")
	p.tipo = "morteiro" if p.area > 0.0 else "bala"

func _sortear_elemento() -> String:
	var pesos: Array = []
	var total := 0.0
	for chave in ["fogo", "gelo", "raio", "veneno", "vazio"]:
		var v: float = j.stats.n("dano" + chave.capitalize())
		if v > 0.0:
			pesos.append([chave, v])
			total += v
	if pesos.is_empty():
		return ""
	if not j.rng.chance(minf(0.95, total)):
		return ""
	var r: float = float(j.rng.f()) * total
	for par in pesos:
		r -= float(par[1])
		if r <= 0.0:
			return str(par[0])
	return str(pesos[0][0])

## ---------------------------------------------------------- projéteis

func atualizar_projeteis(dt: float) -> void:
	var lista: Array = j.arena.projeteis
	var centro: Vector2 = j.arena.centro
	for i in range(lista.size() - 1, -1, -1):
		var p: Projetil = lista[i]
		if not p.ativo:
			j.arena.soltar_projetil(i)
			continue
		p.t += dt
		p.vida -= dt
		if p.vida <= 0.0:
			j.arena.soltar_projetil(i)
			continue

		if p.origem == "inimigo":
			p.pos += p.vel * dt
			if p.pos.distance_to(centro) < Bal.RAIO_TORRE:
				j.dano_na_torre(p.dano_torre, null, {"projetil": true})
				j.arena.soltar_projetil(i)
			elif j.arena.fora_da_arena(p.pos):
				j.arena.soltar_projetil(i)
			continue

		var alvo := p.alvo
		if alvo != null and alvo.vivo() and alvo.intangivel <= 0.0:
			var ang := (alvo.pos - p.pos).angle()
			p.ang = Ux.ang_lerp(p.ang, ang, minf(1.0, dt * 12.0))
			p.vel = Vector2(cos(p.ang), sin(p.ang)) * p.velocidade
		p.pos += p.vel * dt

		if j.arena.fora_da_arena(p.pos):
			j.arena.soltar_projetil(i)
			continue

		var atingido := _colisao(p)
		if atingido != null:
			if _impacto(p, atingido):
				j.arena.soltar_projetil(i)

func _colisao(p: Projetil) -> Inimigo:
	var perto: Array = j.arena.em_area(p.pos, p.raio + 34.0)
	for item in perto:
		var e: Inimigo = item
		if not e.vivo() or e.intangivel > 0.0:
			continue
		if p.atingidos.has(e):
			continue
		var rr := e.raio + p.raio
		if p.pos.distance_squared_to(e.pos) <= rr * rr:
			return e
	return null

func _impacto(p: Projetil, alvo: Inimigo) -> bool:
	var opt := {
		"crit": p.critico,
		"penetracao": j.stats.n("penetracao"),
		"execucao": j.stats.n("execucao"),
		"roubodeVida": j.stats.n("roubodeVida"),
		"elemento": p.elemento,
	}

	if str(alvo.def.get("hab", "")) == "refletir" and not p.critico:
		j.dano_na_torre(Big.to_f(p.dano) * 0.02, alvo, {"reflexo": true})
	if bool(alvo.def.get("invisivel", false)):
		alvo.revelado = true

	Combate.aplicar_dano(alvo, p.dano, j, opt)
	if p.elemento != "":
		Combate.aplicar_elemento(alvo, p.elemento, p.dano, j)

	if p.area > 0.0:
		Combate.dano_area(p.pos, p.area, Big.mul_f(p.dano, 0.6), j, {
			"crit": p.critico, "penetracao": opt["penetracao"], "queda": true, "ignorar": [alvo],
		})
		Bus.particulas.emit("explosao", p.pos, {"raio": p.area, "cor": p.cor})
	else:
		Bus.particulas.emit("impacto", p.pos, {"ang": p.ang, "cor": p.cor, "crit": p.critico})

	p.atingidos.append(alvo)

	if p.perfuracao > 0:
		p.perfuracao -= 1
		p.dano = Big.mul_f(p.dano, 0.82)
		p.alvo = j.arena.alvo(p.pos, 400.0, "proximo", p.atingidos)
		return false
	if p.ricochete > 0:
		var prox: Inimigo = j.arena.alvo(p.pos, 240.0, "proximo", p.atingidos)
		if prox != null:
			p.ricochete -= 1
			p.dano = Big.mul_f(p.dano, 0.75)
			p.alvo = prox
			p.ang = (prox.pos - p.pos).angle()
			p.vel = Vector2(cos(p.ang), sin(p.ang)) * p.velocidade
			p.vida = maxf(p.vida, 1.2)
			return false
	return true

## --------------------------------------------------------------- orbes

func atualizar_orbes(dt: float) -> void:
	var n: int = int(j.stats.n("orbes")) + orbes_extra
	var centro_o: Vector2 = j.arena.centro
	if orbes.size() != n:
		orbes.clear()
		for i in n:
			orbes.append({
				"ang": (float(i) / maxf(1.0, float(n))) * TAU,
				"raio": 78.0 + float(i % 3) * 22.0,
				"cd": float(j.rng.entre(0.0, 0.6)),
				"pos": centro_o,
			})
	if n == 0:
		return
	var vel_orb := 1.6 * float(j.stats.n("velOrbe"))
	var dano_orb := Big.mul_f(j.stats.b("dano"), 0.45 * float(j.stats.n("danoOrbe")) * float(j.stats.n("multiplicador")))

	for o in orbes:
		o["ang"] = float(o["ang"]) + vel_orb * dt
		o["pos"] = centro_o + Vector2(cos(float(o["ang"])), sin(float(o["ang"]))) * float(o["raio"])
		o["cd"] = float(o["cd"]) - dt
		if float(o["cd"]) <= 0.0:
			var op: Vector2 = o["pos"]
			var alvo: Inimigo = j.arena.alvo(op, 150.0, "proximo")
			if alvo != null:
				o["cd"] = 0.75
				var golpe := Combate.rolar_golpe(dano_orb, j, alvo)
				Combate.aplicar_dano(alvo, golpe[0], j, {"crit": golpe[1], "penetracao": j.stats.n("penetracao")})
				Bus.particulas.emit("feixe", op, {"para": alvo.pos, "cor": "#a78bfa"})

## -------------------------------------------------------------- defesa

func levar_dano(quantidade: float, fonte, opt: Dictionary = {}) -> float:
	var s: Dictionary = j.s
	var torre: Dictionary = s["torre"]
	if not bool(torre["viva"]):
		return 0.0
	if iframes > 0.0 and not bool(opt.get("ignora_iframes", false)):
		return 0.0

	var armadura: float = j.stats.n("armadura")
	var dano := quantidade * (Bal.ARMADURA_K / (Bal.ARMADURA_K + armadura))
	dano *= float(j.mods_dif.get("danoTorre", 1.0))

	if float(torre["escudo"]) > 0.0:
		var absorvido := minf(float(torre["escudo"]), dano)
		torre["escudo"] = float(torre["escudo"]) - absorvido
		dano -= absorvido
		if float(torre["escudo"]) <= 0.0 and j.pas.has("escudo_explosivo"):
			var centro_x: Vector2 = j.arena.centro
			Combate.dano_area(centro_x, 200.0, Big.mul_f(j.stats.b("dano"), 20.0 * float(j.pas["escudo_explosivo"])), j, {"crit": true})
			Bus.particulas.emit("explosao", centro_x, {"raio": 200.0, "cor": "#60a5fa"})

	if dano > 0.0:
		torre["vida"] = float(torre["vida"]) - dano
		iframes = 0.0 if bool(opt.get("drenar", false)) else Bal.IFRAMES
		tempo_sem_dano = 0.0

	Bus.torre_atingida.emit(dano, float(torre["vida"]), float(torre["vida_max"]))

	if float(torre["vida"]) <= 0.0:
		if j.pas.has("fenix") and not j.fenix_usada:
			j.fenix_usada = true
			torre["vida"] = float(torre["vida_max"]) * 0.4
			iframes = 2.0
			Bus.celebracao.emit("fenix", {})
			Bus.toast("A torre renasce das cinzas!", "epico", "🔥")
			return dano
		torre["vida"] = 0.0
		torre["viva"] = false
		torre["tempo_morta"] = Bal.RESPAWN
		s["stats"]["mortes"] = int(s["stats"]["mortes"]) + 1
		Bus.torre_caiu.emit()
	return dano
