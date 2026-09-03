class_name Prestigio
extends RefCounted

## As três camadas de prestígio e as compras nas árvores permanentes.

static func pode_ascender(s: Dictionary) -> bool:
	return int(s["onda_maxima"]) >= Bal.ASC_ONDA_MIN

static func pode_colapsar(s: Dictionary) -> bool:
	return int(s["onda_maxima_global"]) >= Bal.SING_ONDA_MIN and int(s["prestigio"]["ascensoes"]) >= Bal.SING_ASC_MIN

static func pode_transcender(s: Dictionary) -> bool:
	return int(s["onda_maxima_global"]) >= Bal.TRANS_ONDA_MIN and int(s["prestigio"]["singularidades"]) >= Bal.TRANS_SING_MIN

static func previa_fragmentos(j) -> float:
	return Bal.fragmentos(int(j.s["onda_maxima"]), j.stats.n("ganhoFrag"))

static func previa_nucleos(j) -> float:
	return Bal.nucleos(int(j.s["onda_maxima_global"]), int(j.s["prestigio"]["ascensoes"]), float(j.esp.get("ganhoNucleos", 1.0)))

static func previa_eter(j) -> float:
	return Bal.eter(int(j.s["onda_maxima_global"]), int(j.s["prestigio"]["singularidades"]))

## Custo do próximo nível de um nó de árvore.
static func custo_no(def: Dictionary, nivel: int) -> float:
	return Big.custo(float(def.get("base", 1)), float(def.get("cresc", 1.5)), nivel)

static func max_compravel_no(def: Dictionary, nivel: int, moeda: float) -> int:
	var maxn := int(def.get("max", -1))
	var teto := 1000000 if maxn < 0 else maxn - nivel
	if teto <= 0:
		return 0
	return mini(teto, Big.max_afford(moeda, float(def.get("base", 1)), float(def.get("cresc", 1.5)), nivel))
