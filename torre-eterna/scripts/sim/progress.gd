class_name Progresso
extends RefCounted

## Conquistas, missões diárias/semanais, temporada e codex.

## Lê o valor atual de uma condição rastreável.
## Todo tipo de condição que `valor_cond` sabe ler. Existe para o portão
## conseguir perguntar "o conteúdo cita algum tipo sem leitor?" — sem isso, um
## tipo com erro de digitação cai no `_` da correspondência abaixo, devolve 0
## para sempre e a conquista fica presa sem ninguém reclamar. O linter compara
## esta lista com os casos reais da função e reprova se as duas divergirem.
const TIPOS_COND := [
	"onda",
	"ondaMaxima",
	"ondaMaximaGlobal",
	"inimigosMortos",
	"chefesMortos",
	"ouroTotal",
	"ouroGasto",
	"nivel",
	"comboMaximo",
	"criticos",
	"ascensoes",
	"singularidades",
	"transcendencias",
	"cartas",
	"lendarios",
	"tempoTotal",
	"habilidadesUsadas",
	"douradosAbatidos",
	"dourados",
	"danoMaximo",
	"ondasCompletas",
	"mortes",
	"relicas",
	"conquistasTotal",
	"missoesCompletas",
	"desafiosCompletos",
	"tiros",
	"gemas",
	"fragmentos",
	"nucleos",
	"eter",
	"upgradeNivel",
	"talentoNivel",
	"inimigoTipo",
	"eras",
]

static func tipo_cond_conhecido(tipo: String) -> bool:
	return TIPOS_COND.has(tipo)

## Tipos que ANDAM PARA TRÁS: zeram no prestígio ou na troca de run.
##
## `_sortear` escala a meta por `onda_maxima_global / 10`, e o progresso de
## missão é medido por DELTA (`atual - base`) justamente porque estes contadores
## caem. Escalar um deles pede um múltiplo do teto que o contador consegue
## andar: a semanal "Marca d'Água" (tipo `onda`, valor 120, escalaComOnda) pedia
## 12× o recorde, e o delta máximo que qualquer run produz é ~1× o recorde. A
## missão era matematicamente impossível a partir da onda ~130 e ninguém
## reclamava, porque uma missão travada parece só uma missão difícil.
const TIPOS_QUE_RESETAM := ["onda", "nivel", "upgradeNivel", "talentoNivel"]

static func escala_com_onda(tipo: String) -> bool:
	return not TIPOS_QUE_RESETAM.has(tipo)

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
			# Antes só tocava um som. Nas primeiras conquistas — que chegam nos
			# primeiros minutos, justo quando o jogador está entendendo o que o
			# jogo recompensa — nada aparecia na tela: nem o nome, nem o prêmio.
			Bus.toast(Txt.f("sim_conquista", {
				"n": Ux.txt(def, "nome", Cfg.ingles()),
				"r": _texto_recompensa(def.get("recompensa", {})),
			}), "epico", "trofeu")
	if not novas.is_empty():
		j.marcar_sujo()
	return novas

## "+25 gemas" — o prêmio em uma linha, para o aviso da conquista.
## A etapa da sequência para `dia` dias seguidos. A tabela é finita: passado o
## último dia, a recompensa fica na última etapa em vez de sumir — quem joga
## trinta dias seguidos não pode receber menos que quem jogou sete.
static func etapa_sequencia(dia: int) -> Dictionary:
	if Dados.sequencia_diaria.is_empty():
		return {}
	var melhor: Dictionary = {}
	for etapa in Dados.sequencia_diaria:
		if int(etapa.get("dia", 0)) <= dia:
			melhor = etapa
	return melhor if not melhor.is_empty() else Dados.sequencia_diaria[0]

## Multiplicador de XP que a sequência atual concede.
static func mult_xp_sequencia(s: Dictionary) -> float:
	var etapa := etapa_sequencia(int(s["missoes"].get("sequencia", 0)))
	return maxf(1.0, float(etapa.get("multXP", 1.0))) if not etapa.is_empty() else 1.0

static func _texto_recompensa(r: Dictionary) -> String:
	if r.is_empty():
		return ""
	var v := float(r.get("valor", 0))
	var tipo := str(r.get("tipo", ""))
	if v <= 0.0 or tipo == "":
		return ""
	return " · +%s %s" % [Fmt.num(v, 0), Txt.t("m_" + tipo)]

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
		"stat":
			# 61 recompensas do conteúdo são deste tipo e caíam no `_: pass`:
			# o jogador cumpria a missão, lia "Ganho de Ouro ×1,12" e não
			# ganhava nada. Agora vira bônus permanente no estado.
			var alvo := str(r.get("stat", ""))
			if alvo != "":
				j.s["bonus_permanentes"].append({
					"stat": alvo,
					"tipoEfeito": str(r.get("tipoEfeito", "flat")),
					"valor": v,
					"fonte": fonte,
				})
				j.marcar_sujo()
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
		var virou_o_dia := int(m.get("ultimo_dia", 0)) != dia
		if int(m.get("ultimo_dia", 0)) == dia - 1:
			m["sequencia"] = int(m["sequencia"]) + 1
		elif virou_o_dia:
			m["sequencia"] = 1
		m["ultimo_dia"] = dia
		# A tabela de sequência (data/missions.json) promete gemas e um
		# multiplicador de XP por dia seguido, e o painel mostra os dois. Só o
		# contador andava: ninguém lia `recompensa` nem `multXP`, então voltar
		# sete dias seguidos pagava exatamente nada. O prêmio é pago aqui, uma
		# vez por dia; o multiplicador entra no cálculo em `Mods.recalcular`.
		if virou_o_dia:
			var etapa := etapa_sequencia(int(m["sequencia"]))
			if not etapa.is_empty():
				_dar_recompensa(etapa.get("recompensa", {}), j,
					Ux.txt(etapa, "nome", Cfg.ingles()))
				Bus.sequencia_diaria.emit(int(m["sequencia"]), etapa)
		m["reset_diario"] = t
		m["diarias"] = _sortear(Dados.missoes_diarias, 3, progresso, j)
		m["rerrolagens_usadas"] = 0

	if forcar or t - int(m["reset_semanal"]) >= SEG_SEMANA or m["semanais"].is_empty():
		m["reset_semanal"] = t
		m["semanais"] = _sortear(Dados.missoes_semanais, 2, progresso, j)

## Troca UMA missão por outra do mesmo grupo, gastando uma rerrolagem.
##
## O Dado Viciado promete "+1 rerroll diário em lojas, cartas e missões por
## nível" e o especial `rerolls` não tinha um único leitor: a relíquia era
## compravel, aparecia no painel e não fazia nada. As rerrolagens gastas ficam
## no estado das missões e zeram junto com o dia.
static func rerrolar_missao(j, grupo: String, indice: int) -> bool:
	var s: Dictionary = j.s
	var m: Dictionary = s["missoes"]
	if not m.has(grupo) or indice < 0 or indice >= m[grupo].size():
		return false
	var mi: Dictionary = m[grupo][indice]
	if bool(mi["pronta"]) or bool(mi["coletada"]):
		return false
	if rerrolagens_restantes(j) <= 0:
		return false
	var modelos: Array = Dados.missoes_diarias if grupo == "diarias" else Dados.missoes_semanais
	var usados := {}
	for outra in m[grupo]:
		if outra != mi:
			usados[str(outra["id"])] = true
	usados[str(mi["id"])] = true
	var pool: Array = []
	for def in modelos:
		if not usados.has(str(def.get("id", ""))):
			pool.append(def)
	if pool.is_empty():
		return false
	var nova: Array = _sortear([j.rng.escolher(pool)], 1,
		maxi(1, int(s["onda_maxima_global"])), j)
	if nova.is_empty():
		return false
	m[grupo][indice] = nova[0]
	m["rerrolagens_usadas"] = int(m.get("rerrolagens_usadas", 0)) + 1
	j.marcar_sujo()
	return true

## Quantas rerrolagens ainda cabem hoje.
static func rerrolagens_restantes(j) -> int:
	var total := int(j.esp.get("rerolls", 0.0))
	return maxi(0, total - int(j.s["missoes"].get("rerrolagens_usadas", 0)))

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
		if bool(def.get("escalaComOnda", false)) and escala_com_onda(str(meta.get("tipo", ""))):
			alvo = maxf(1.0, alvo * maxf(1.0, float(progresso) / 10.0))
		out.append({
			"id": str(def.get("id", "")),
			"alvo": alvo,
			"base": valor_cond(j.s, str(meta.get("tipo", "")), str(meta.get("chave", ""))),
			"prog": 0.0,
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
			if _avancar(mi, atual) >= float(mi["alvo"]):
				mi["pronta"] = true
				Bus.missao_concluida.emit(str(mi["id"]))

## Avanço de uma missão, guardado no próprio item.
##
## Nem todo contador sobe sempre: `onda` e `nivel` voltam a 1 no prestígio,
## gemas e fragmentos são gastos, cartas somem do inventário quando são
## consumidas. Medir `atual - base` num contador desses deixava a missão do dia
## IMPOSSÍVEL depois de uma ascensão — o valor ficava permanentemente abaixo da
## base. Aqui a base acompanha a descida e o progresso já ganho nunca é perdido.
static func _avancar(mi: Dictionary, atual: float) -> float:
	# Cinto de segurança: nada não-finito pode entrar no estado, porque de lá
	# ele vai direto para o JSON do save e derruba a gravação para sempre.
	if not is_finite(atual):
		atual = Big.TETO_F
	var base := float(mi.get("base", 0.0))
	if not is_finite(base):
		base = 0.0
		mi["base"] = 0.0
	if atual < base:
		mi["base"] = atual
		base = atual
	var anterior := float(mi.get("prog", 0.0))
	if not is_finite(anterior):
		anterior = 0.0
	var prog := clampf(maxf(anterior, atual - base), 0.0, Big.TETO_F)
	mi["prog"] = prog
	return prog

static func progresso_missao(s: Dictionary, mi: Dictionary) -> float:
	var def: Dictionary = Dados.missao_por_id.get(str(mi["id"]), {})
	if def.is_empty():
		return 0.0
	var meta: Dictionary = def.get("meta", {})
	var atual := valor_cond(s, str(meta.get("tipo", "")), str(meta.get("chave", "")))
	var alvo := maxf(1.0, float(mi["alvo"]))
	return clampf(_avancar(mi, atual) / alvo, 0.0, 1.0)

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
