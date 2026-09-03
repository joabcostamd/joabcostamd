class_name Saque
extends RefCounted

## Drops de cartas, raridade com pity e reciclagem em poeira.

static func rolar_raridade(j, bonus_sorte: float = 1.0) -> String:
	var s: Dictionary = j.s
	var pesos: Array = []
	var total := 0.0
	for r in Dados.raridades:
		var peso := float(r.get("peso", 1.0))
		var brilho := float(r.get("brilho", 0.0))
		# a sorte empurra o peso das raridades altas
		if brilho > 0.0:
			peso *= pow(maxf(1.0, float(j.stats.n("sorte")) * bonus_sorte), brilho * 1.5)
		pesos.append([str(r.get("id", "comum")), peso])
		total += peso
	# pity: garante lendário depois de muitas tentativas secas
	var pity := int(s["pity"]["lendaria"])
	if pity > 60 and j.rng.chance(minf(0.9, float(pity - 60) * 0.02)):
		s["pity"]["lendaria"] = 0
		return "lendario"
	var r2 := float(j.rng.f()) * total
	for par in pesos:
		r2 -= float(par[1])
		if r2 <= 0.0:
			var id := str(par[0])
			if id == "lendario" or id == "mitico":
				s["pity"]["lendaria"] = 0
			else:
				s["pity"]["lendaria"] = pity + 1
			return id
	return "comum"

## Tenta soltar uma carta ao matar um inimigo.
static func tentar_drop(e: Inimigo, j) -> void:
	if Dados.cartas.is_empty():
		return
	var chance := Bal.CHANCE_CARTA
	if e.chefe:
		chance = Bal.CHANCE_CARTA_CHEFE
	elif e.elite:
		chance = Bal.CHANCE_CARTA_ELITE
	chance *= float(j.stats.n("chanceDrop"))
	if not j.rng.chance(minf(1.0, chance)):
		return
	criar_carta(j, "", e.chefe)

static func criar_carta(j, id_forcado: String = "", garantir_boa: bool = false) -> Dictionary:
	var s: Dictionary = j.s
	var raridade := rolar_raridade(j, 1.5 if garantir_boa else 1.0)
	var def: Dictionary = {}
	if id_forcado != "":
		def = Dados.carta_por_id.get(id_forcado, {})
	if def.is_empty():
		# respeita a raridade mínima de cada carta
		var pool: Array = []
		for c in Dados.cartas:
			if _ordem(str(c.get("raridadeMin", "comum"))) <= _ordem(raridade):
				pool.append(c)
		if pool.is_empty():
			pool = Dados.cartas
		def = j.rng.escolher(pool)
	if def.is_empty():
		return {}

	var inst := {
		"uid": str(s["cartas"]["proximo_uid"]),
		"id": str(def.get("id", "")),
		"raridade": raridade,
		"nivel": 1,
	}
	s["cartas"]["proximo_uid"] = int(s["cartas"]["proximo_uid"]) + 1
	s["cartas"]["inventario"].append(inst)
	s["cartas"]["novas"].append(inst["uid"])
	s["stats"]["cartas_obtidas"] = int(s["stats"]["cartas_obtidas"]) + 1
	if raridade == "lendario" or raridade == "mitico":
		s["stats"]["lendarios"] = int(s["stats"]["lendarios"]) + 1
		Bus.celebracao.emit("lendario", {"carta": inst})
	Bus.carta_caiu.emit(inst)
	return inst

static func _ordem(r: String) -> int:
	match r:
		"comum": return 0
		"incomum": return 1
		"raro": return 2
		"epico": return 3
		"lendario": return 4
		"mitico": return 5
	return 0

static func poeira_de(raridade: String, nivel: int) -> float:
	var base := float(Bal.POEIRA.get(raridade, 5))
	return base * (1.0 + 0.6 * float(nivel - 1))

static func reciclar(j, uid: String) -> bool:
	var s: Dictionary = j.s
	var inv: Array = s["cartas"]["inventario"]
	for i in inv.size():
		var c: Dictionary = inv[i]
		if str(c["uid"]) != uid:
			continue
		if s["cartas"]["equipadas"].has(uid):
			return false
		Economia.ganhar_moeda("poeira", Big.from(poeira_de(str(c["raridade"]), int(c["nivel"]))), j, "reciclagem")
		inv.remove_at(i)
		j.marcar_sujo()
		return true
	return false

static func custo_fusao(nivel: int) -> float:
	return round(40.0 * pow(2.1, float(nivel - 1)))

static func fundir(j, uid: String) -> bool:
	var s: Dictionary = j.s
	for c in s["cartas"]["inventario"]:
		if str(c["uid"]) != uid:
			continue
		var nivel := int(c["nivel"])
		if nivel >= Dados.nivel_max_carta:
			return false
		var custo := Big.from(custo_fusao(nivel))
		if not Economia.gastar_moeda("poeira", custo, j):
			return false
		c["nivel"] = nivel + 1
		j.marcar_sujo()
		return true
	return false

static func equipar(j, uid: String, slot: int) -> bool:
	var s: Dictionary = j.s
	var slots := int(j.esp.get("slotsCartas", 3))
	if slot < 0 or slot >= slots:
		return false
	while s["cartas"]["equipadas"].size() < slots:
		s["cartas"]["equipadas"].append("")
	# desequipa de outro slot se já estiver equipada
	for i in s["cartas"]["equipadas"].size():
		if str(s["cartas"]["equipadas"][i]) == uid:
			s["cartas"]["equipadas"][i] = ""
	s["cartas"]["equipadas"][slot] = uid
	s["cartas"]["novas"].erase(uid)
	j.marcar_sujo()
	Bus.carta_equipada.emit(uid, slot)
	return true

static func desequipar(j, slot: int) -> void:
	var s: Dictionary = j.s
	if slot >= 0 and slot < s["cartas"]["equipadas"].size():
		s["cartas"]["equipadas"][slot] = ""
		j.marcar_sujo()
