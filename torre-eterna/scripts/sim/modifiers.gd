class_name Mods
extends RefCounted

## Junta TODAS as fontes de bônus num StatEngine.
## Fontes: upgrades · talentos · árvores de prestígio · relíquias · cartas
## (+ conjuntos) · buffs · conquistas · era · desafio · passivas.

## Valores que não são atributos (onda inicial, slots, desbloqueios...).
static func especiais_padrao() -> Dictionary:
	return {
		"ondaInicial": 0.0,
		"slotsCartas": float(GameState.SLOTS_CARTAS_BASE),
		"pontosTalento": 0.0,
		"offlineHoras": Bal.OFFLINE_HORAS_BASE,
		"offlineEficiencia": Bal.OFFLINE_EFICIENCIA,
		"comboTeto": float(Bal.COMBO_TETO),
		"comboBonus": Bal.COMBO_BONUS_POR,
		"velocidadeMax": 1.0,
		"ganhoNucleos": 1.0,
		"hpInimigo": 1.0,
		"ouroDourado": 1.0,
		"revives": 0.0,
		"slotsHabilidade": 0.0,
		"rerolls": 0.0,
		"desbloqueios": {},
	}

static func aplicar_efeitos(m: StatEngine, efeitos, n: int, fonte: String, esp: Dictionary, pas: Dictionary) -> void:
	if efeitos == null or n <= 0 or not (efeitos is Array):
		return
	for item in efeitos:
		if not (item is Dictionary):
			continue
		var ef: Dictionary = item
		if ef.has("especial"):
			var chave := str(ef["especial"])
			var v = ef.get("valor", 0)
			match chave:
				"desbloqueio":
					esp["desbloqueios"][str(v)] = true
				"hpInimigo", "ganhoNucleos":
					esp[chave] = float(esp.get(chave, 1.0)) * pow(float(v), float(n))
				"revivesExtra":
					# o painel chama de `revivesExtra`; o estado acumulado é
					# `revives`, que é o nome que a simulação lê
					esp["revives"] = float(esp.get("revives", 0.0)) + float(v) * float(n)
				"comboBonus":
					# "+20% de bônus de combo por nível" é MULTIPLICATIVO. Somando
					# 0,2 por nível o bônus por ponto de combo saía 0,006 -> 2,006
					# (334x o descrito): com o teto de combo em 650, o dano do
					# combo passava de 1300x. Aqui 10 níveis dão 1,2^10 = 6,2x.
					esp[chave] = float(esp.get(chave, Bal.COMBO_BONUS_POR)) * pow(1.0 + float(v), float(n))
				_:
					if v is float or v is int:
						esp[chave] = float(esp.get(chave, 0.0)) + float(v) * float(n)
					else:
						esp["desbloqueios"][str(v)] = true
			continue
		if ef.get("tipo", "") == "passiva" or (not ef.has("stat") and ef.has("chave")):
			var ch := str(ef.get("chave", ""))
			if ch != "":
				pas[ch] = int(pas.get(ch, 0)) + n
				if ef.has("valor"):
					pas[ch + ":valor"] = float(ef["valor"])
			continue
		if not ef.has("stat"):
			continue
		var stat := str(ef["stat"])
		var valor := float(ef.get("valor", 0.0))
		match str(ef.get("tipo", "flat")):
			"flat":
				m.add_flat(stat, valor * float(n), fonte)
			"pct":
				m.add_pct(stat, valor * float(n), fonte)
			"mult":
				if valor <= 0.0:
					m.add_mult(stat, 0.0, fonte)          # anulador
				else:
					m.add_mult_log(stat, (log(valor) / 2.302585092994046) * float(n), fonte)

## Reconstrói o motor de atributos a partir do estado.
## Devolve { stats, especiais, passivas, pontos_conquista }
static func recalcular(s: Dictionary, m: StatEngine) -> Dictionary:
	m.zerar()
	var esp := especiais_padrao()
	var pas := {}

	# ---------------------------------------------------------- upgrades
	for id in s["upgrades"].keys():
		var n := int(s["upgrades"][id])
		var def: Dictionary = Dados.upgrade_por_id.get(id, {})
		if not def.is_empty() and n > 0:
			aplicar_efeitos(m, def.get("efeito", []), n, str(def.get("nome", id)), esp, pas)

	# ---------------------------------------------------------- talentos
	for id in s["talentos"].keys():
		var n := int(s["talentos"][id])
		var def: Dictionary = Dados.talento_por_id.get(id, {})
		if not def.is_empty() and n > 0:
			aplicar_efeitos(m, def.get("efeito", []), n, str(def.get("nome", id)), esp, pas)

	# ------------------------------------------------- árvores de prestígio
	for par in [["arvore_fragmentos", "fragmentos"], ["arvore_nucleos", "nucleos"], ["arvore_eter", "eter"]]:
		var tabela: Dictionary = s["prestigio"][par[0]]
		for id in tabela.keys():
			var n := int(tabela[id])
			var def: Dictionary = Dados.no_por_id.get(id, {})
			if not def.is_empty() and n > 0:
				aplicar_efeitos(m, def.get("efeito", []), n, str(def.get("nome", id)), esp, pas)

	# ------------------------------------------- bônus permanentes ganhos
	# Recompensas do tipo "stat" de missões, conquistas e desafios. Ficam no
	# estado (ver GameState) e entram aqui como qualquer outro modificador.
	for item in s.get("bonus_permanentes", []):
		if not (item is Dictionary):
			continue
		var b: Dictionary = item
		var alvo := str(b.get("stat", ""))
		if alvo == "":
			continue
		var val := float(b.get("valor", 0.0))
		var fonte := str(b.get("fonte", ""))
		match str(b.get("tipoEfeito", "flat")):
			"mult": m.add_mult(alvo, val, fonte)
			"pct": m.add_pct(alvo, val, fonte)
			_: m.add_flat(alvo, val, fonte)

	# --------------------------------------------------------- relíquias
	var espelho := false
	for id in s["relicas"].keys():
		var n := int(s["relicas"][id])
		var def: Dictionary = Dados.reliquia_por_id.get(id, {})
		if not def.is_empty() and n > 0:
			aplicar_efeitos(m, def.get("efeito", []), n, str(def.get("nome", id)), esp, pas)
			if _tem_passiva(def, "espelho_do_operador"):
				espelho = true

	# Espelho do Operador: "a sua relíquia mais cara (excluindo esta) tem todos
	# os efeitos aplicados uma segunda vez". A relíquia existia no JSON, o texto
	# prometia, e o código nunca duplicava nada.
	if espelho:
		var alvo := _reliquia_mais_cara(s)
		if not alvo.is_empty():
			var def_alvo: Dictionary = Dados.reliquia_por_id.get(str(alvo["id"]), {})
			aplicar_efeitos(m, def_alvo.get("efeito", []), int(alvo["nivel"]),
				str(def_alvo.get("nome", alvo["id"])), esp, pas)

	# ------------------------------------------------------------ cartas
	var equipadas_ids: Array = []
	for uid in s["cartas"]["equipadas"]:
		if str(uid) == "":
			continue
		var inst := _achar_carta(s, str(uid))
		if inst.is_empty():
			continue
		var def: Dictionary = Dados.carta_por_id.get(inst.get("id", ""), {})
		if def.is_empty():
			continue
		equipadas_ids.append(def.get("id", ""))
		var rar: Dictionary = Dados.raridade(str(inst.get("raridade", "comum")))
		var mult_rar := float(rar.get("mult", 1.0))
		var escala_nivel := 1.0 + 0.25 * float(int(inst.get("nivel", 1)) - 1)
		for item in def.get("efeito", []):
			if not (item is Dictionary):
				continue
			var ef: Dictionary = item
			if ef.has("especial"):
				aplicar_efeitos(m, [ef], 1, str(def.get("nome", "")), esp, pas)
				continue
			if not ef.has("stat"):
				continue
			var bruto := float(ef.get("valor", 0.0))
			var tipo_ef := str(ef.get("tipo", "flat"))
			# Em multiplicadores a raridade escala o BÔNUS (o que passa de 1), não o valor
			# inteiro; e penalidades (valor < 1) nunca são amplificadas pela raridade.
			var v := bruto * mult_rar * escala_nivel
			if tipo_ef == "mult":
				v = (1.0 + (bruto - 1.0) * mult_rar * escala_nivel) if bruto >= 1.0 else bruto
			var stat := str(ef["stat"])
			match tipo_ef:
				"mult":
					if v <= 0.0:
						m.add_mult(stat, 0.0, str(def.get("nome", "")))
					else:
						m.add_mult(stat, v, str(def.get("nome", "")))
				"pct":
					m.add_pct(stat, v, str(def.get("nome", "")))
				_:
					m.add_flat(stat, v, str(def.get("nome", "")))

	# bônus de conjunto completo
	for conj in Dados.conjuntos:
		var ids: Array = conj.get("cartas", [])
		if ids.is_empty():
			continue
		var completo := true
		for cid in ids:
			if not equipadas_ids.has(cid):
				completo = false
				break
		if completo:
			aplicar_efeitos(m, conj.get("bonus", []), 1, "Conjunto " + str(conj.get("nome", "")), esp, pas)

	# -------------------------------------------------------- conquistas
	var pontos := 0
	for id in s["conquistas"].keys():
		var def: Dictionary = Dados.conquista_por_id.get(id, {})
		if def.is_empty():
			continue
		pontos += int(def.get("pontos", 5))
		var r: Dictionary = def.get("recompensa", {})
		if str(r.get("tipo", "")) == "stat" and r.has("stat"):
			if str(r.get("tipoEfeito", "pct")) == "mult":
				m.add_mult(str(r["stat"]), float(r.get("valor", 1.0)), str(def.get("nome", "")))
			else:
				m.add_pct(str(r["stat"]), float(r.get("valor", 0.0)), str(def.get("nome", "")))
	if pontos > 0:
		var b := (float(pontos) / 10.0) * 0.005
		m.add_pct("multiplicador", b, "Conquistas")
		m.add_pct("ganhoOuro", b, "Conquistas")

	# ------------------------------------------------- Álbum de Ecos
	var album := Mecanicas.bonus_album(s)
	if int(album["n"]) > 0:
		m.add_pct("multiplicador", float(album["dano"]), "Álbum de Ecos")
		m.add_pct("ganhoOuro", float(album["ouro"]), "Álbum de Ecos")

	# ---------------------------------------------------- O Panteão
	var pant := Mecanicas.bonus_panteao(s)
	if int(pant["n"]) > 0:
		m.add_mult("multiplicador", float(pant["dano"]), "Panteão")
		m.add_mult("ganhoOuro", float(pant["ouro"]), "Panteão")

	# desbloqueios permanentes guardados no estado
	for k in s["desbloqueios"].keys():
		esp["desbloqueios"][str(k)] = true

	# ------------------------------------------------------------- era
	var era: Dictionary = Dados.era_atual(int(s["onda"]))
	if era.has("regra") and (era["regra"] is Dictionary):
		var regra: Dictionary = era["regra"]
		var mod_era = regra.get("mod", {})
		if mod_era is Dictionary:
			for k in mod_era.keys():
				if esp.has(k) and (mod_era[k] is float or mod_era[k] is int):
					esp[k] = float(esp[k]) * float(mod_era[k])

	# ----------------------------------------------------------- buffs
	for item in s["buffs"]:
		var b2: Dictionary = item
		if float(b2.get("restante", 0.0)) <= 0.0:
			continue
		var stat := str(b2.get("stat", ""))
		var v := float(b2.get("valor", 0.0))
		match str(b2.get("tipo", "pct")):
			"mult":
				m.add_mult(stat, v, str(b2.get("fonte", "")))
			"flat":
				m.add_flat(stat, v, str(b2.get("fonte", "")))
			_:
				m.add_pct(stat, v, str(b2.get("fonte", "")))

	# -------------------------------------------------------- passivas
	if pas.has("sede_de_sangue") and int(s["combo"]["atual"]) > 0:
		var pilhas := mini(25, int(s["combo"]["atual"]))
		m.add_pct("dano", 0.02 * float(pilhas), "Sede de Sangue")
	if pas.has("ultima_chama"):
		var frac := Big.frac(s["torre"]["vida"], s["torre"]["vida_max"])
		if frac < 0.3:
			m.add_mult("multiplicador", 2.0, "Última Chama")
	if pas.has("combo_estendido"):
		esp["comboBonus"] = float(esp["comboBonus"]) * (1.0 + 0.5 * float(pas["combo_estendido"]))
	if pas.has("midas"):
		# "Dobra a chance de inimigos dourados E O OURO QUE ELES SOLTAM". A
		# segunda metade da promessa não existia: só a sorte era dobrada.
		m.add_mult("sorte", 2.0, "Toque de Midas")
		esp["ouroDourado"] = float(esp.get("ouroDourado", 1.0)) * 2.0
	if pas.has("juros_dobrados"):
		m.add_mult("jurosOuro", 2.0, "Juros Compostos")

	# ------------------------------------------ desafios ja vencidos
	# Os 14 desafios anunciam uma "Recompensa permanente" no painel (dano +15%,
	# perfuracao +1, e por ai). A vitoria era gravada em `completos` e o array
	# `recompensa` nao era lido por ninguem: o selo de vencido aparecia e os
	# atributos ficavam identicos. Vencer um desafio pagava so orgulho.
	for vencido in s["desafios"]["completos"].keys():
		var dv: Dictionary = Dados.desafio_por_id.get(str(vencido), {})
		if dv.is_empty():
			continue
		aplicar_efeitos(m, dv.get("recompensa", []), 1,
			Ux.txt(dv, "nome", Cfg.ingles()), esp, pas)

	# --------------------------------------------------------- desafio
	var desafio_id := str(s["desafios"]["ativo"])
	if desafio_id != "":
		var d: Dictionary = Dados.desafio_por_id.get(desafio_id, {})
		var dm: Dictionary = d.get("mods", {})
		if float(dm.get("cadencia", 1.0)) != 1.0:
			m.add_mult("cadencia", float(dm["cadencia"]), "Desafio")
		if bool(dm.get("semCritico", false)):
			m.add_mult("critChance", 0.0001, "Desafio")
		if bool(dm.get("semRegen", false)):
			m.add_mult("regen", 0.0001, "Desafio")
		if bool(dm.get("semOrbes", false)):
			m.add_mult("orbes", 0.0001, "Desafio")

	m.calcular()

	# limites derivados
	esp["slotsCartas"] = minf(8.0, float(esp["slotsCartas"]))
	esp["offlineHoras"] = minf(Bal.OFFLINE_HORAS_TETO, float(esp["offlineHoras"]))
	esp["offlineEficiencia"] = minf(1.0, float(esp["offlineEficiencia"]))
	if esp["desbloqueios"].has("offlinePerfeito"):
		esp["offlineEficiencia"] = 1.0
		esp["offlineHoras"] = 9999.0

	return {"stats": m, "especiais": esp, "passivas": pas, "pontos_conquista": pontos}

static func _achar_carta(s: Dictionary, uid: String) -> Dictionary:
	for item in s["cartas"]["inventario"]:
		if str(item.get("uid", "")) == uid:
			return item
	return {}

## A relíquia possuída de maior custo base, ignorando o próprio Espelho. Custo
## é o critério porque é o que o texto da relíquia diz: "a sua relíquia mais
## cara".
static func _reliquia_mais_cara(s: Dictionary) -> Dictionary:
	var melhor: Dictionary = {}
	var melhor_custo := -1.0
	for id in s["relicas"].keys():
		var n := int(s["relicas"][id])
		if n <= 0:
			continue
		var def: Dictionary = Dados.reliquia_por_id.get(str(id), {})
		if def.is_empty() or _tem_passiva(def, "espelho_do_operador"):
			continue
		var custo := float(def.get("base", 0)) * float(n)
		if custo > melhor_custo:
			melhor_custo = custo
			melhor = {"id": str(id), "nivel": n}
	return melhor

static func _tem_passiva(def: Dictionary, chave: String) -> bool:
	for ef in def.get("efeito", []):
		if ef is Dictionary and str(ef.get("chave", "")) == chave:
			return true
	return false
