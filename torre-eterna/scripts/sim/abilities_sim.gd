class_name Habilidades
extends RefCounted

## Execução das habilidades ativas (os botões que dão vontade de apertar).

static func valor(def: Dictionary, chave: String, nivel: int) -> float:
	var esc = def.get("escala", {})
	if not (esc is Dictionary) or not esc.has(chave):
		return 0.0
	var par: Array = esc[chave]
	return float(par[0]) + float(par[1]) * float(nivel - 1)

static func cd_efetivo(def: Dictionary, nivel: int, cdr: float) -> float:
	var reducao := 1.0 - minf(0.4, float(nivel - 1) * 0.03)
	return float(def.get("cd", 60.0)) * reducao * (1.0 - minf(0.8, cdr))

static func duracao(def: Dictionary, nivel: int, mult: float) -> float:
	var esc = def.get("escala", {})
	var base := float(def.get("dur", 0.0))
	if esc is Dictionary and esc.has("dur"):
		base = valor(def, "dur", nivel)
	return base * mult

static func custo_melhoria(def: Dictionary, nivel: int) -> float:
	return ceil(float(def.get("custoBase", 20)) * pow(1.55, float(nivel - 1)))

static func disponivel(s: Dictionary, id: String) -> bool:
	var def: Dictionary = Dados.habilidade_por_id.get(id, {})
	if def.is_empty():
		return false
	var h := GameState.hab(s, id)
	return bool(h["desbloqueada"]) and float(h["cd"]) <= 0.0 and bool(s["torre"]["viva"])

static func desbloquear_por_progresso(s: Dictionary) -> Array:
	var novas: Array = []
	for def in Dados.habilidades:
		var id := str(def.get("id", ""))
		var h := GameState.hab(s, id)
		var req: Dictionary = def.get("requer", {})
		if not bool(h["desbloqueada"]) and int(s["onda_maxima_global"]) >= int(req.get("onda", 1)):
			h["desbloqueada"] = true
			novas.append(def)
	return novas

## Executa a habilidade. Devolve true se usou.
## O desafio ativo proíbe habilidades?
static func _sem_habilidades(s: Dictionary) -> bool:
	var id := str(s["desafios"]["ativo"])
	if id == "":
		return false
	return bool(Dados.desafio_por_id.get(id, {}).get("mods", {}).get("semHabilidades", false))

static func usar(id: String, j) -> bool:
	var s: Dictionary = j.s
	var def: Dictionary = Dados.habilidade_por_id.get(id, {})
	if def.is_empty() or not disponivel(s, id) or j.silenciado > 0.0:
		return false
	# `semHabilidades` (desafios Silêncio e Purgatório) era anunciado no painel
	# e nunca lido: os dois desafios prometiam "sem botões para apertar" e
	# entregavam todas as habilidades funcionando.
	if _sem_habilidades(s):
		return false
	var h := GameState.hab(s, id)
	var nivel := int(h["nivel"])
	var cd := cd_efetivo(def, nivel, j.stats.n("cdr"))
	var dur := duracao(def, nivel, j.stats.n("duracaoHab"))
	h["cd"] = cd
	h["cd_max"] = cd
	h["usos"] = int(h["usos"]) + 1
	s["stats"]["habilidades_usadas"] = int(s["stats"]["habilidades_usadas"]) + 1

	var dano_base := Big.mul_f(j.stats.b("dano"), j.stats.n("multiplicador"))
	var centro: Vector2 = j.arena.centro
	var cor := str(def.get("cor", "#ffffff"))

	match str(def.get("tipo", "")):
		"instantanea":
			var dano := Big.mul_f(dano_base, valor(def, "dano", nivel))
			var lista: Array = j.arena.inimigos.duplicate()
			for item in lista:
				var e: Inimigo = item
				if e.vivo():
					Combate.aplicar_dano(e, dano, j, {"crit": true, "penetracao": 1.0})
			Bus.particulas.emit("nova", centro, {"raio": maxf(j.arena.largura, j.arena.altura), "cor": cor})
			j.tremor(22.0, 0.55)
			j.hitstop_ms(90.0)
		"buff":
			for item in def.get("buffs", []):
				var b: Dictionary = item
				var chave := str(b.get("chave", ""))
				var v := valor(def, chave, nivel)
				var tipo_b := str(b.get("tipo", "pct"))
				var valor_final := v
				var tipo_real := "pct"
				if tipo_b == "multChave":
					tipo_real = "mult"
				elif tipo_b == "flatChave":
					tipo_real = "flat"
				else:
					tipo_real = tipo_b
					valor_final = v * float(b.get("escala", 1.0))
				j.adicionar_buff({
					"id": "hab_%s_%s" % [id, str(b.get("stat", ""))],
					"stat": str(b.get("stat", "")),
					"tipo": tipo_real,
					"valor": valor_final,
					"restante": dur,
					"fonte": str(def.get("nome", id)),
					"icone": Icone.da_habilidade(id),
					"cor": cor,
				})
			Bus.particulas.emit("aura", centro, {"cor": cor, "dur": dur})
		"congelar":
			j.tempo_congelado = dur
			for item in j.arena.inimigos:
				var e2: Inimigo = item
				if e2.ativo:
					e2.atordoado = maxf(e2.atordoado, dur)
			Bus.particulas.emit("congelar", centro, {"dur": dur, "cor": cor})
		"invulneravel":
			j.invulneravel = dur
			Bus.particulas.emit("aura", centro, {"cor": cor, "dur": dur})
		"misseis":
			j.fila_misseis = {
				"restantes": int(valor(def, "qtd", nivel)),
				"intervalo": 0.06, "cd": 0.0,
				"dano": Big.mul_f(dano_base, valor(def, "dano", nivel)),
				"cor": cor,
			}
		"buraco_negro":
			j.buraco_negro = {
				"pos": centro + Vector2(j.rng.entre(-60.0, 60.0), j.rng.entre(-60.0, 60.0)),
				"restante": dur, "acc": 0.0, "raio": 240.0,
				"dano": Big.mul_f(dano_base, valor(def, "dano", nivel)),
				"cor": cor,
			}
		"cura":
			var frac := valor(def, "cura", nivel) / 100.0
			var cura := Big.mul_f(s["torre"]["vida_max"], frac)
			j.curar_torre(cura)
			s["torre"]["escudo"] = Big.min_b(s["torre"]["vida_max"], Big.add(s["torre"]["escudo"], cura))
			Bus.particulas.emit("aura", centro, {"cor": cor, "dur": 1.2})
		"julgamento":
			var mult := valor(def, "dano", nivel)
			var lista2: Array = j.arena.inimigos.duplicate()
			for item in lista2:
				var e3: Inimigo = item
				if not e3.vivo():
					continue
				if e3.chefe:
					Combate.aplicar_dano(e3, Big.mul_f(dano_base, mult), j, {"crit": true, "penetracao": 1.0})
				else:
					# "converte cada abate em ouro dobrado" — a segunda metade do
					# texto não existia no código, e o inglês tinha apagado a
					# promessa em vez de cumpri-la.
					Combate.aplicar_dano(e3, Big.mul_f(e3.hp, 10.0), j, {"puro": true, "ouro_mult": 2.0})
			Bus.particulas.emit("julgamento", centro, {})
			j.tremor(34.0, 0.9)
			j.hitstop_ms(160.0)
			j.camera_lenta(0.25, 700.0)

	Bus.habilidade_usada.emit(id, nivel)
	return true

## Recargas, mísseis em voo e buraco negro.
static func atualizar(dt: float, j) -> void:
	var s: Dictionary = j.s
	for id in s["habilidades"].keys():
		var h: Dictionary = s["habilidades"][id]
		if float(h["cd"]) > 0.0:
			h["cd"] = float(h["cd"]) - dt
			if float(h["cd"]) <= 0.0:
				h["cd"] = 0.0
				Bus.habilidade_pronta.emit(id)

	if j.tempo_congelado > 0.0:
		j.tempo_congelado -= dt
	if j.invulneravel > 0.0:
		j.invulneravel -= dt
	if j.silenciado > 0.0:
		j.silenciado -= dt

	var f = j.fila_misseis
	if f is Dictionary and int(f["restantes"]) > 0:
		f["cd"] = float(f["cd"]) - dt
		while float(f["cd"]) <= 0.0 and int(f["restantes"]) > 0:
			f["cd"] = float(f["cd"]) + float(f["intervalo"])
			f["restantes"] = int(f["restantes"]) - 1
			var centro2: Vector2 = j.arena.centro
			var alvo: Inimigo = j.arena.alvo(centro2, 3000.0, "forte")
			if alvo == null:
				break
			var p: Projetil = j.arena.novo_projetil()
			var ang: float = float(j.rng.angulo())
			p.ativo = true
			p.pos = centro2 + Vector2(cos(ang), sin(ang)) * 20.0
			p.velocidade = 520.0
			p.ang = ang
			p.vel = Vector2(cos(ang), sin(ang)) * p.velocidade
			p.dano = f["dano"]
			p.critico = true
			p.alvo = alvo
			p.area = 60.0
			p.raio = 6.0
			p.vida = 4.0
			p.cor = Color.html(str(f["cor"]))
			p.tipo = "missil"
		if int(f["restantes"]) <= 0:
			j.fila_misseis = null

	var bn = j.buraco_negro
	if bn is Dictionary:
		bn["restante"] = float(bn["restante"]) - dt
		var bpos: Vector2 = bn["pos"]
		var braio := float(bn["raio"])
		for item in j.arena.inimigos:
			var e: Inimigo = item
			if not e.vivo():
				continue
			var delta := bpos - e.pos
			var d := delta.length()
			if d < braio:
				e.pos += delta.normalized() * ((1.0 - d / braio) * 260.0) * dt
		bn["acc"] = float(bn["acc"]) + dt
		if float(bn["acc"]) >= 0.25:
			bn["acc"] = float(bn["acc"]) - 0.25
			Combate.dano_area(bpos, braio, Big.mul_f(bn["dano"], 0.25), j, {"penetracao": 0.5})
		if float(bn["restante"]) <= 0.0:
			Combate.dano_area(bpos, braio * 1.3, Big.mul_f(bn["dano"], 3.0), j, {"crit": true})
			Bus.particulas.emit("explosao", bpos, {"raio": braio * 1.3, "cor": str(bn["cor"])})
			j.tremor(18.0, 0.4)
			j.buraco_negro = null

## Uso automático (IA de prioridade).
static func auto_usar(j) -> bool:
	var s: Dictionary = j.s
	var perigo := Big.frac(s["torre"]["vida"], s["torre"]["vida_max"])
	var vivos: int = j.arena.contagem_viva()
	var em_chefe := bool(s["em_chefe"])

	for id in ORDEM_AUTO:
		if _vale_a_pena(str(id), perigo, vivos, em_chefe) and disponivel(s, str(id)):
			return usar(str(id), j)
	return false

## Ordem de prioridade do uso automático — a primeira que servir é a que sai.
## Era um Array de Arrays montado a cada chamada, ou seja, onze alocações por
## quadro; a lista agora é constante e a condição virou função.
const ORDEM_AUTO := [
	"reparo", "escudo_absoluto", "julgamento", "nova", "buraco_negro",
	"misseis", "tempo", "sobrecarga", "sentinelas", "chuva_ouro",
]

## Quando cada habilidade vale a pena. `perigo` é a fração de vida que sobrou:
## quanto menor, pior a situação.
static func _vale_a_pena(id: String, perigo: float, vivos: int, em_chefe: bool) -> bool:
	match id:
		"reparo": return perigo < 0.4
		"escudo_absoluto": return perigo < 0.25
		"julgamento": return vivos > 18 or (em_chefe and perigo < 0.5)
		"nova": return vivos >= 8
		"buraco_negro": return vivos >= 10
		"misseis": return em_chefe or vivos >= 6
		"tempo": return vivos >= 12 or perigo < 0.5
		"sobrecarga": return vivos >= 4 or em_chefe
		"sentinelas": return vivos >= 4
		"chuva_ouro": return vivos >= 6
	return false
