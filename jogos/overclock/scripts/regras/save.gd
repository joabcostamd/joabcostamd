class_name Save
extends RefCounted
## Formato do save, com schema_version desde o primeiro dia.
## Migrar depois é barato; adivinhar o formato antigo não é.

const VERSAO_ATUAL := 1

static func vazio() -> Dictionary:
	return {
		"schema_version": VERSAO_ATUAL,
		"fase_atual": 1,
		"melhores": {},      # {"1": 1200, "2": 900}
		"opcoes": {"volume_master": 1.0, "volume_sfx": 1.0, "idioma": ""},
	}

## Sobe um save antigo para o formato atual. Nunca joga dado fora.
static func migrar(dados: Dictionary) -> Dictionary:
	var d := dados.duplicate(true)
	var v := int(d.get("schema_version", 0))
	if v < 1:
		d = vazio().merged(d, true)
		d["schema_version"] = 1
	d["schema_version"] = VERSAO_ATUAL
	return d

## Funde dois saves (duas máquinas, mesma conta): vence o melhor de cada fase.
static func mesclar(a: Dictionary, b: Dictionary) -> Dictionary:
	var r := migrar(a)
	var o := migrar(b)
	r["fase_atual"] = maxi(int(r.get("fase_atual", 1)), int(o.get("fase_atual", 1)))
	var melhores: Dictionary = r.get("melhores", {}).duplicate()
	for k in o.get("melhores", {}):
		melhores[k] = maxi(int(melhores.get(k, 0)), int(o["melhores"][k]))
	r["melhores"] = melhores
	return r
