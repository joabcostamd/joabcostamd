class_name Combate
extends RefCounted

## Aplicação de dano, status elementais e recompensas de abate.
## `j` é sempre o autoload Jogo (tipado como Node para evitar ciclo de tipos).

## Aplica dano a um inimigo. Devolve { morreu, dano, overkill, absorvido }.
static func aplicar_dano(e: Inimigo, dano: float, j, opt: Dictionary = {}) -> Dictionary:
	if not e.vivo():
		return {"morreu": false, "dano": Big.ZERO, "overkill": Big.ZERO, "absorvido": false}

	var dmg := dano

	if e.fissura > 0.0:
		dmg = Big.mul_f(dmg, 1.0 + e.fissura_forca)
	if e.marcado > 0.0:
		dmg = Big.mul_f(dmg, 1.5)
	if not bool(opt.get("puro", false)) and e.armadura > 0.0:
		dmg = Big.mul_f(dmg, Bal.fator_armadura(e.armadura, float(opt.get("penetracao", 0.0))))
	if e.elite_mod == "blindado":
		dmg = Big.mul_f(dmg, 0.55)

	var absorvido := false
	if e.escudo > 0.0:
		var esc := Big.from(e.escudo)
		if Big.gte(esc, dmg):
			e.escudo = Big.to_f(Big.sub(esc, dmg))
			e.flash = maxf(e.flash, 0.12)
			Bus.inimigo_atingido.emit(e, dmg, bool(opt.get("crit", false)), str(opt.get("elemento", "")))
			return {"morreu": false, "dano": dmg, "overkill": Big.ZERO, "absorvido": true}
		dmg = Big.sub(dmg, esc)
		e.escudo = 0.0
		absorvido = true

	# execução
	var limiar := float(opt.get("execucao", 0.0))
	if limiar > 0.0 and not e.chefe and e.frac_vida() <= limiar:
		dmg = e.hp

	var hp_antes := e.hp
	e.hp = Big.sub(e.hp, dmg)
	e.flash = maxf(e.flash, 0.2 if bool(opt.get("crit", false)) else 0.12)
	e.tremor = minf(1.0, e.tremor + 0.35)
	e.sem_dano_t = 0.0

	var st: Dictionary = j.s["stats"]
	st["dano_total"] = Big.add(st["dano_total"], dmg)
	if Big.gt(dmg, st["dano_maximo"]):
		st["dano_maximo"] = dmg
	if bool(opt.get("crit", false)):
		st["criticos"] = int(st["criticos"]) + 1

	var rv := float(opt.get("roubodeVida", 0.0))
	if rv > 0.0 and j.s["torre"]["viva"]:
		var cura: float = minf(Big.to_f(dmg) * rv, float(j.s["torre"]["vida_max"]) * 0.05)
		if cura > 0.0:
			j.curar_torre(cura)

	Bus.inimigo_atingido.emit(e, dmg, bool(opt.get("crit", false)), str(opt.get("elemento", "")))

	if Big.lte(e.hp, Big.ZERO) or Big.is_zero(e.hp):
		var overkill := Big.ZERO
		if Big.gt(dmg, hp_antes):
			overkill = Big.min_b(Big.sub(dmg, hp_antes), Big.mul_f(hp_antes, Bal.OVERKILL_TETO))
		matar(e, j, overkill, bool(opt.get("crit", false)))
		return {"morreu": true, "dano": dmg, "overkill": overkill, "absorvido": absorvido}
	return {"morreu": false, "dano": dmg, "overkill": Big.ZERO, "absorvido": absorvido}

## Dano em área.
static func dano_area(centro: Vector2, raio: float, dano: float, j, opt: Dictionary = {}) -> int:
	var alvos: Array = j.arena.em_area(centro, raio).duplicate()
	var mortos := 0
	var ignorar: Array = opt.get("ignorar", [])
	var queda := bool(opt.get("queda", false))
	for e in alvos:
		if ignorar.has(e):
			continue
		var q := 1.0
		if queda:
			q = maxf(0.35, 1.0 - e.pos.distance_to(centro) / maxf(1.0, raio))
		var r := aplicar_dano(e, Big.mul_f(dano, q), j, opt)
		if r["morreu"]:
			mortos += 1
	return mortos

## Corrente de raio entre alvos próximos.
static func corrente(origem: Inimigo, dano: float, saltos: int, j, opt: Dictionary = {}) -> Array:
	var visitados: Array = [origem]
	var atual := origem
	var dmg := dano
	var pontos: Array = [origem.pos]
	var fator := float(Bal.ELEMENTOS["raio"].get("fator", 0.45))
	for i in saltos:
		var prox = j.arena.alvo(atual.pos, 190.0, "proximo", visitados)
		if prox == null:
			break
		visitados.append(prox)
		dmg = Big.mul_f(dmg, fator)
		var o := opt.duplicate()
		o["elemento"] = "raio"
		aplicar_dano(prox, dmg, j, o)
		pontos.append(prox.pos)
		atual = prox
	if pontos.size() > 1:
		Bus.particulas.emit("raio", origem.pos, {"pontos": pontos, "cor": Bal.ELEMENTOS["raio"]["cor"]})
	return pontos

## Aplica um status elemental.
static func aplicar_elemento(e: Inimigo, elemento: String, dano_base: float, j) -> void:
	if not Bal.ELEMENTOS.has(elemento) or not e.vivo():
		return
	var d: Dictionary = Bal.ELEMENTOS[elemento]
	match elemento:
		"fogo":
			e.queimadura = mini(int(d["pilhas"]), e.queimadura + 1)
			e.queimadura_dano = Big.mul_f(dano_base, float(d["dot"]))
			e.queimadura_t = float(d["duracao"])
		"veneno":
			e.veneno = mini(int(d["pilhas"]), e.veneno + 1)
			e.veneno_dano = Big.mul_f(dano_base, float(d["dot"]))
			e.veneno_t = float(d["duracao"])
		"gelo":
			e.gelo = float(d["duracao"])
			e.gelo_forca = minf(0.75, float(d["lentidao"]) * (1.0 + float(j.stats.n("danoGelo"))))
		"vazio":
			e.fissura = float(d["duracao"])
			e.fissura_forca = minf(1.2, float(d["ampliacao"]) * (1.0 + float(j.stats.n("danoVazio"))))
		"raio":
			corrente(e, dano_base, int(d["corrente"]), j, {})

## Tique de status (dano contínuo, lentidão, marcações).
static func atualizar_status(dt: float, j) -> void:
	var lista: Array = j.arena.inimigos
	for e in lista:
		if not e.vivo():
			continue
		if e.queimadura > 0:
			e.queimadura_t -= dt
			if e.queimadura_t <= 0.0:
				e.queimadura = 0
			else:
				aplicar_dano(e, Big.mul_f(e.queimadura_dano, float(e.queimadura) * dt), j, {"puro": true, "elemento": "fogo", "dot": true})
		if e.veneno > 0 and e.vivo():
			e.veneno_t -= dt
			if e.veneno_t <= 0.0:
				e.veneno = 0
			else:
				aplicar_dano(e, Big.mul_f(e.veneno_dano, float(e.veneno) * dt), j, {"puro": true, "elemento": "veneno", "dot": true})
		if e.gelo > 0.0:
			e.gelo -= dt
		if e.fissura > 0.0:
			e.fissura -= dt
		if e.atordoado > 0.0:
			e.atordoado -= dt
		if e.marcado > 0.0:
			e.marcado -= dt
		if e.flash > 0.0:
			e.flash -= dt * 4.0
		if e.tremor > 0.0:
			e.tremor -= dt * 2.5

## Mata o inimigo e distribui recompensas.
static func matar(e: Inimigo, j, overkill: float = Big.ZERO, critico: bool = false) -> void:
	if e.morrendo > 0.0:
		return
	e.morrendo = 0.28
	e.hp = Big.ZERO

	var s: Dictionary = j.s
	var st: Dictionary = s["stats"]
	st["mortos"] = int(st["mortos"]) + 1
	st["por_inimigo"][e.tipo] = int(st["por_inimigo"].get(e.tipo, 0)) + 1
	s["codex"]["inimigos"][e.tipo] = int(s["codex"]["inimigos"].get(e.tipo, 0)) + 1
	if e.chefe:
		st["chefes_mortos"] = int(st["chefes_mortos"]) + 1
		s["codex"]["chefes"][e.tipo] = int(s["codex"]["chefes"].get(e.tipo, 0)) + 1
	if e.dourado:
		st["dourados"] = int(st["dourados"]) + 1

	# combo
	var teto := int(j.esp.get("comboTeto", Bal.COMBO_TETO))
	s["combo"]["atual"] = mini(teto, int(s["combo"]["atual"]) + 1)
	s["combo"]["timer"] = Bal.COMBO_JANELA + (1.0 if j.pas.has("combo_estendido") else 0.0)
	if int(s["combo"]["atual"]) > int(st["combo_maximo"]):
		st["combo_maximo"] = int(s["combo"]["atual"])
	Bus.combo_mudou.emit(int(s["combo"]["atual"]))

	# ouro com bônus de combo e overkill
	var bonus_combo := 1.0 + float(s["combo"]["atual"]) * float(j.esp.get("comboBonus", Bal.COMBO_BONUS_POR))
	var ouro := Big.mul_f(e.ouro, bonus_combo)
	if not Big.is_zero(overkill):
		var frac := minf(Bal.OVERKILL_TETO, Big.to_f(Big.div(overkill, e.hp_max)))
		ouro = Big.mul_f(ouro, 1.0 + frac)
		if frac > 0.25:
			Bus.overkill.emit(e, frac)

	j.soltar_ouro(e, ouro)
	j.ganhar_xp(e.xp)

	s["mortos_na_onda"] = int(s["mortos_na_onda"]) + 1
	Bus.inimigo_morreu.emit(e, ouro)
	if e.chefe:
		Bus.chefe_morreu.emit(e)

	j.ao_morrer_inimigo(e, critico)

## Rola crítico e devolve [dano_final, foi_critico].
static func rolar_golpe(dano_base: float, j, alvo: Inimigo) -> Array:
	var crit: bool = j.rng.chance(j.stats.n("critChance"))
	var dmg := dano_base
	if crit:
		dmg = Big.mul_f(dmg, float(j.stats.n("critDano")))
	if alvo != null and alvo.chefe:
		dmg = Big.mul_f(dmg, float(j.stats.n("danoChefe")))
	return [dmg, crit]
