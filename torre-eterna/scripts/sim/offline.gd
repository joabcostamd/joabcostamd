class_name Offline
extends RefCounted

## Progresso enquanto o jogo esteve fechado.
##
## Não simulamos a batalha (caro e injusto): estimamos quantas ondas o jogador
## estava limpando por minuto e concedemos o rendimento equivalente,
## multiplicado pela eficiência offline.

static func calcular(j, segundos: float) -> Dictionary:
	var s: Dictionary = j.s
	var eficiencia := float(j.esp.get("offlineEficiencia", Bal.OFFLINE_EFICIENCIA))
	var teto := float(j.esp.get("offlineHoras", Bal.OFFLINE_HORAS_BASE)) * 3600.0
	var usado := minf(segundos, teto)
	var cortado := maxf(0.0, segundos - teto)

	if usado < Bal.OFFLINE_MIN_SEG:
		return {"segundos": segundos, "aplicado": false}

	# ritmo estimado: quanto o jogador rendia por segundo em jogo
	var onda := int(s["onda"])
	var por_onda := Big.mul_f(Bal.ouro_onda(onda), float(Bal.contagem_onda(onda)) + 4.5)
	var seg_por_onda := maxf(6.0, float(s.get("seg_por_onda_media", 18.0)))
	var ouro := Big.mul_f(Big.div_f(por_onda, seg_por_onda), usado * eficiencia * float(j.stats.n("ganhoOuro")))
	var xp := Big.mul_f(Big.div_f(Bal.xp_onda(onda), seg_por_onda), usado * eficiencia * 3.0 * float(j.stats.n("ganhoXP")))

	Economia.ganhar_ouro(ouro, j, "offline", true)
	Economia.ganhar_xp(xp, j)
	s["stats"]["tempo_offline"] = float(s["stats"]["tempo_offline"]) + usado

	return {
		"segundos": segundos,
		"usado": usado,
		"cortado": cortado,
		"eficiencia": eficiencia,
		"ouro": ouro,
		"xp": xp,
		"aplicado": true,
	}
