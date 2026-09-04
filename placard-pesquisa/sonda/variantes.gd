extends RefCounted
class_name Variantes

# NUCLEO POLIDO (decisao fixada, ver topo do resultado.json):
#   PULSO 0,35 (3/5 e 4/5) + TIQUE DO TEAR a cada 4 + AVESSO + TEAR MULTIPLICA
#   fator do evento = f(mults das linhas colhidas) x Tear, SEM teto de evento
#   f = SOMA dos mults (leitura do candidato 4: "mults somados")
#   TEAR_INICIAL = 1, TEAR_TETO = 8, diagonais a 60% na parcela de fichas
static func base_polida() -> Dictionary:
	var c := Mesa2.cfg_padrao()
	c["produto"] = true
	c["tear_ini"] = 1
	c["teto_evento"] = false
	c["cruz_mult_soma"] = true
	c["avesso"] = true
	c["meta_k"] = 2.25
	return c

static func lista() -> Array:
	return [
		["BASE",        {}],
		["J1",          {"janela": 1}],
		["J2",          {"janela": 2}],
		["JFIM",        {"janela": 99}],
		["J1_PROD",     {"janela": 1, "cruz_mult_soma": false}],
		["J1_JUNTA",    {"janela": 1, "janela_junta": 1}],
		["J1_PRIMEIRA", {"janela": 1, "janela_max_por_mesa": 1}],
		["J1_CONDPERP", {"janela": 1, "janela_cond_perp": true}],
		["BASE_SEMAV",  {"avesso": false}],
		["J1_SEMAV",    {"janela": 1, "avesso": false}],
		["J1_CONDPERP_JUNTA", {"janela": 1, "janela_cond_perp": true, "janela_junta": 1}],
	]

static func cfg_de(over: Dictionary) -> Dictionary:
	var c := base_polida()
	for k in over.keys(): c[k] = over[k]
	return c
