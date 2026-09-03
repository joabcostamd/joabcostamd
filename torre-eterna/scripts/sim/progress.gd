class_name Progresso
extends RefCounted

## Conquistas, missões diárias/semanais, temporada e codex.

## Lê o valor atual de uma condição rastreável.
static func valor_cond(s: Dictionary, tipo: String, chave: String = "") -> float:
	var st: Dictionary = s["stats"]
	match tipo:
		"onda": return float(s["onda"])
		"ondaMaxima": return float(s["onda_maxima"])
		"ondaMaximaGlobal": return float(s["onda_maxima_global"])
		"inimigosMortos": return float(st["mortos"])
		"chefesMortos": return float(st["chefes_mortos"])
		"ouroTotal": return Big.to_f(st["ouro_total"])
		"ouroGasto": return Big.to_f(st["ouro_gasto"])
		"nivel": return float(s["nivel"])
		"comboMaximo": return float(st["combo_maximo"])
		"criticos": return float(st["criticos"])
		"ascensoes": return float(s["prestigio"]["ascensoes"])
		"singularidades": return float(s["prestigio"]["singularidades"])
		"transcendencias": return float(s["prestigio"]["transcendencias"])
		"cartas": return float(s["cartas"]["inventario"].size())
		"lendarios": return float(st["lendarios"])
		"tempoTotal": return float(st["tempo_total"])
		"habilidadesUsadas": return float(st["habilidades_usadas"])
		"douradosAbatidos", "dourados": return float(st["dourados"])
		"danoMaximo": return Big.to_f(st["dano_maximo"])
		"ondasCompletas": return float(st["ondas_completas"])
		"mortes": return float(st["mortes"])
		"relicas": return float(s["relicas"].size())
		"conquistasTotal": return float(s["conquistas"].size())
		"missoesCompletas": return float(s.get("missoes_completas", 0))
		"desafiosCompletos": return float(s["desafios"]["completos"].size())
		"tiros": return float(st["tiros"])
		"gemas": return Big.to_f(s["moedas"]["gemas"])
		"fragmentos": return Big.to_f(s["moedas"]["fragmentos"])
		"nucleos": return Big.to_f(s["moedas"]["nucleos"])
		"eter": return Big.to_f(s["moedas"]["eter"])
		"upgradeNivel": return float(s["upgrades"].get(chave, 0))
		"talentoNivel": return float(s["talentos"].get(chave, 0))
		"inimigoTipo": return float(st["por_inimigo"].get(chave, 0))
		"eras": return float(s["eras_vistas"].size())
		_: return 0.0

static func cond_atendida(s: Dictionary, cond: Dictionary) -> bool:
	if cond.is_empty():
		return false
	var atual := valor_cond(s, str(cond.get("tipo", "")), str(cond.get("chave", "")))
	return atual >= float(cond.get("valor", 0))

## Verifica conquistas novas. Devolve a lista de ids desbloqueados agora.
static func checar_conquistas(j) -> Array:
	var s: Dictionary = j.s
	var novas: Array = []
	for def in Dados.conquistas:
		var id := str(def.get("id", ""))
		if s["conquistas"].has(id):
			continue
		if cond_atendida(s, def.get("cond", {})):
			s["conquistas"][id] = int(Time.get_unix_time_from_system())
			novas.append(id)
			_dar_recompensa(def.get("recompensa", {}), j, str(def.get("nome", id)))
			Bus.conquista_desbloqueada.emit(id)
	if not novas.is_empty():
		j.marcar_sujo()
	return novas

static func _dar_recompensa(r: Dictionary, j, fonte: String) -> void:
	if r.is_empty():
		return
	var v := float(r.get("valor", 0))
	match str(r.get("tipo", "")):
		"gemas": Economia.ganhar_moeda("gemas", Big.from(v), j, fonte)
		"fragmentos": Economia.ganhar_moeda("fragmentos", Big.from(v), j, fonte)
		"ouro": Economia.ganhar_ouro(Big.mul_f(Bal.ouro_onda(int(j.s["onda"])), v), j, fonte)
		"poeira": Economia.ganhar_moeda("poeira", Big.from(v), j, fonte)
		"pontosTalento": j.s["pontos_talento"] = int(j.s["pontos_talento"]) + int(v)
		"xp": Economia.ganhar_xp(Big.mul_f(Bal.xp_onda(int(j.s["onda"])), v), j)
		_: pass

## ------------------------------------------------------------- missões

const SEG_DIA := 86400
const SEG_SEMANA := 604800

static func agora() -> int:
	return int(Time.get_unix_time_from_system())

static func dia_atual() -> int:
	return agora() / SEG_DIA

static func gerar_missoes(j, forcar: bool = false) -> void:
	var s: Dictionary = j.s
	var m: Dictionary = s["missoes"]
	var t := agora()
	var progresso := maxi(1, int(s["onda_maxima_global"]))

	if forcar or t - int(m["reset_diario"]) >= SEG_DIA or m["diarias"].is_empty():
		var dia := dia_atual()
		if int(m.get("ultimo_dia", 0)) == dia - 1:
			m["sequencia"] = int(m["sequencia"]) + 1
		elif int(m.get("ultimo_dia", 0)) != dia:
			m["sequencia"] = 1
		m["ultimo_dia"] = dia
		m["reset_diario"] = t
		m["diarias"] = _sortear(Dados.missoes_diarias, 3, progresso, j)

	if forcar or t - int(m["reset_semanal"]) >= SEG_SEMANA or m["semanais"].is_empty():
		m["reset_semanal"] = t
		m["semanais"] = _sortear(Dados.missoes_semanais, 2, progresso, j)

static func _sortear(modelos: Array, qtd: int, progresso: int, j) -> Array:
	if modelos.is_empty():
		return []
	var pool := modelos.duplicate()
	pool.shuffle()
	var out: Array = []
	for i in mini(qtd, pool.size()):
		var def: Dictionary = pool[i]
		var meta: Dictionary = def.get("meta", {})
		var alvo := float(meta.get("valor", 1))
		if bool(def.get("escalaComOnda", false)):
			alvo = maxf(1.0, alvo * maxf(1.0, float(progresso) / 10.0))
		out.append({
			"id": str(def.get("id", "")),
			"alvo": alvo,
			"base": valor_cond(j.s, str(meta.get("tipo", "")), str(meta.get("chave", ""))),
			"pronta": false,
			"coletada": false,
		})
	return out

static func checar_missoes(j) -> void:
	var s: Dictionary = j.s
	for grupo in ["diarias", "semanais"]:
		for item in s["missoes"][grupo]:
			var mi: Dictionary = item
			if bool(mi["pronta"]):
				continue
			var def: Dictionary = Dados.missao_por_id.get(str(mi["id"]), {})
			if def.is_empty():
				continue
			var meta: Dictionary = def.get("meta", {})
			var atual := valor_cond(s, str(meta.get("tipo", "")), str(meta.get("chave", "")))
			if atual - float(mi["base"]) >= float(mi["alvo"]):
				mi["pronta"] = true
				Bus.missao_concluida.emit(str(mi["id"]))

static func progresso_missao(s: Dictionary, mi: Dictionary) -> float:
	var def: Dictionary = Dados.missao_por_id.get(str(mi["id"]), {})
	if def.is_empty():
		return 0.0
	var meta: Dictionary = def.get("meta", {})
	var atual := valor_cond(s, str(meta.get("tipo", "")), str(meta.get("chave", "")))
	var alvo := maxf(1.0, float(mi["alvo"]))
	return clampf((atual - float(mi["base"])) / alvo, 0.0, 1.0)

static func coletar_missao(j, grupo: String, indice: int) -> bool:
	var s: Dictionary = j.s
	var lista: Array = s["missoes"][grupo]
	if indice < 0 or indice >= lista.size():
		return false
	var mi: Dictionary = lista[indice]
	if not bool(mi["pronta"]) or bool(mi["coletada"]):
		return false
	mi["coletada"] = true
	var def: Dictionary = Dados.missao_por_id.get(str(mi["id"]), {})
	_dar_recompensa(def.get("recompensa", {}), j, str(def.get("nome", "")))
	s["missoes_completas"] = int(s.get("missoes_completas", 0)) + 1
	ganhar_xp_temporada(j, int(def.get("xpTemporada", 10)))
	return true

## ----------------------------------------------------------- temporada

static func xp_para_nivel(n: int) -> int:
	return int(round(100.0 + 40.0 * float(n) + 6.0 * pow(float(n), 1.35)))

static func ganhar_xp_temporada(j, xp: int) -> void:
	var t: Dictionary = j.s["temporada"]
	t["xp"] = int(t["xp"]) + xp
	var guarda := 0
	while guarda < 200:
		guarda += 1
		var custo := xp_para_nivel(int(t["nivel"]) + 1)
		if int(t["xp"]) < custo:
			break
		t["xp"] = int(t["xp"]) - custo
		t["nivel"] = int(t["nivel"]) + 1
		Bus.celebracao.emit("temporada", {"nivel": int(t["nivel"])})

static func coletar_temporada(j, nivel: int) -> bool:
	var t: Dictionary = j.s["temporada"]
	if nivel > int(t["nivel"]) or t["coletadas"].has(nivel):
		return false
	var recompensa := {}
	for r in Dados.temporada:
		if int(r.get("nivel", 0)) == nivel:
			recompensa = r.get("recompensa", {})
			break
	if recompensa.is_empty():
		return false
	t["coletadas"].append(nivel)
	_dar_recompensa(recompensa, j, "Temporada")
	return true

## --------------------------------------------------------------- codex

static func lore_desbloqueada(s: Dictionary) -> Array:
	var out: Array = []
	for e in Dados.entradas_lore:
		if cond_atendida(s, e.get("cond", {})):
			out.append(e)
	return out
