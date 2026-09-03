class_name Economia
extends RefCounted

## Moedas, XP/níveis, coletáveis (ouro no chão) e ímã.

static func soltar_ouro(e: Inimigo, valor: float, j) -> void:
	var total := Big.mul_f(valor, j.stats.n("ganhoOuro"))
	if j.coleta_instantanea:
		ganhar_ouro(total, j, "abate")
		return

	var n := 12 if e.chefe else (8 if e.dourado else (4 if e.elite else 1))
	var parte := Big.div_f(total, float(n))
	for i in n:
		var c: Coletavel = j.arena.novo_coletavel()
		c.ativo = true
		c.pos = e.pos + Vector2(j.rng.gauss(0.0, 6.0), j.rng.gauss(0.0, 6.0))
		var dir: Vector2 = j.rng.direcao()
		c.vel = dir * float(j.rng.entre(40.0, 130.0))
		c.valor = parte
		c.tipo = "dourado" if e.dourado else "ouro"
		c.raio = 8.0 if e.chefe else 6.0
		c.escala = 0.0

static func atualizar_coletaveis(dt: float, j) -> void:
	var raio_ima := 70.0 * float(j.stats.n("coleta"))
	var lista: Array = j.arena.coletaveis
	var centro: Vector2 = j.arena.centro
	for i in range(lista.size() - 1, -1, -1):
		var c: Coletavel = lista[i]
		if not c.ativo:
			j.arena.soltar_coletavel(i)
			continue
		c.t += dt
		if c.escala < 1.0:
			c.escala = minf(1.0, c.escala + dt * 6.0)

		var delta := centro - c.pos
		var d := delta.length()
		if c.atraido or d < raio_ima or c.t > 3.5:
			c.atraido = true
			c.vel = delta.normalized() * (260.0 + c.t * 220.0)
		else:
			c.vel *= pow(0.05, dt)
		c.pos += c.vel * dt

		if d < Bal.RAIO_TORRE + 6.0:
			ganhar_ouro(c.valor, j, "coleta")
			Bus.particulas.emit("coleta", c.pos, {"tipo": c.tipo})
			j.arena.soltar_coletavel(i)

static func ganhar_ouro(valor: float, j, fonte: String = "", silencioso: bool = false) -> void:
	if Big.is_zero(valor):
		return
	var s: Dictionary = j.s
	s["moedas"]["ouro"] = Big.add(s["moedas"]["ouro"], valor)
	s["stats"]["ouro_total"] = Big.add(s["stats"]["ouro_total"], valor)
	if j.pas.has("avareza"):
		ganhar_xp(Big.mul_f(valor, 0.05), j)
	if not silencioso:
		Bus.ouro_ganho.emit(valor, fonte)

static func gastar_ouro(valor: float, j) -> bool:
	var s: Dictionary = j.s
	if Big.lt(s["moedas"]["ouro"], valor):
		return false
	s["moedas"]["ouro"] = Big.sub(s["moedas"]["ouro"], valor)
	s["stats"]["ouro_gasto"] = Big.add(s["stats"]["ouro_gasto"], valor)
	return true

static func ganhar_moeda(chave: String, valor: float, j, fonte: String = "") -> void:
	if Big.is_zero(valor):
		return
	var s: Dictionary = j.s
	s["moedas"][chave] = Big.add(s["moedas"].get(chave, Big.ZERO), valor)
	Bus.moeda_ganha.emit(chave, valor, fonte)

static func gastar_moeda(chave: String, valor: float, j) -> bool:
	var s: Dictionary = j.s
	var atual: float = s["moedas"].get(chave, Big.ZERO)
	if Big.lt(atual, valor):
		return false
	s["moedas"][chave] = Big.sub(atual, valor)
	return true

static func ganhar_xp(valor: float, j) -> void:
	var s: Dictionary = j.s
	# O modificador de XP dos desafios era escrito em `mods_dif["xp"]` e nunca
	# lido por ninguem. Tres desafios o declaram, e no Pobreza — que zera o ouro
	# — o XP em dobro e a UNICA compensacao oferecida: quem aceitava o desafio
	# perdia o ouro e nao recebia nada em troca.
	var v := Big.mul_f(valor, j.stats.n("ganhoXP") * float(j.mods_dif.get("xp", 1.0)))
	if Big.is_zero(v):
		return
	s["xp"] = Big.add(s["xp"], v)
	var subiu := 0
	var guarda := 0
	while int(s["nivel"]) < Bal.NIVEL_MAX and guarda < 500:
		guarda += 1
		var custo := Bal.custo_nivel(int(s["nivel"]))
		if Big.lt(s["xp"], custo):
			break
		s["xp"] = Big.sub(s["xp"], custo)
		s["nivel"] = int(s["nivel"]) + 1
		var pontos := Bal.pontos_por_nivel(int(s["nivel"]))
		s["pontos_talento"] = int(s["pontos_talento"]) + pontos
		subiu += 1
		Bus.nivel_subiu.emit(int(s["nivel"]), pontos)
	if subiu > 0:
		j.marcar_sujo()

static func progresso_nivel(s: Dictionary) -> float:
	var custo := Bal.custo_nivel(int(s["nivel"]))
	if Big.is_zero(custo):
		return 1.0
	return Big.frac(s["xp"], custo)

## Bônus por concluir uma onda.
static func recompensa_onda(onda: int, j) -> void:
	var chefe := Bal.eh_chefe(onda)
	var bonus := Big.mul_f(Bal.ouro_onda(onda), 26.0 if chefe else 4.5)
	ganhar_ouro(Big.mul_f(bonus, j.stats.n("ganhoOuro")), j, "onda")
	ganhar_xp(Big.mul_f(Bal.xp_onda(onda), 16.0 if chefe else 3.0), j)
	if chefe:
		var gemas := Bal.GEMAS_SUPER if Bal.eh_super_chefe(onda) else Bal.GEMAS_CHEFE
		ganhar_moeda("gemas", Big.from(float(gemas)), j, "chefe")
