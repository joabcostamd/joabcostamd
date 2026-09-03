class_name Eventos
extends RefCounted

## EVENTOS ALEATÓRIOS — as batidas na porta entre uma onda e outra.
##
## Regras do sistema:
##  · só acontece no intervalo entre ondas (a onda acabou de ser limpa);
##  · um de cada vez — enquanto houver evento aberto, o relógio não anda;
##  · sorteio por peso, respeitando `requer.onda`, `unico` e o histórico recente;
##  · toda opção pode ter `risco` — `chance` é a chance de DAR ERRADO.
##
## A simulação só emite `Bus.evento_sorteado`; quem desenha a janela é
## `scripts/ui/dialogo_evento.gd`. O jogo continua rodando por trás.

const INTERVALO_MIN := 150.0      ## reagendamento mínimo, em segundos
const INTERVALO_MAX := 260.0
const RETENTAR := 5.0             ## deu vontade fora de hora: tenta de novo já já
const SEM_POOL := 60.0            ## nada elegível: espera mais um pouco
const MEMORIA := 5                ## quantos eventos recentes evitam repetir
const HISTORICO_MAX := 60
const ONDA_MINIMA := 3            ## antes disso o jogador ainda está se achando

const FATOR_OURO := 25.0          ## `valor` do JSON × ouro de uma onda
const FATOR_XP := 12.0

## Ícone VETORIAL de cada evento (a fonte não tem emoji — o do JSON é ignorado).
const ICONES := {
	"caravana_sucata": "engrenagem", "colheita_dourada": "ouro",
	"veterano_enferrujado": "escudo", "reator_instavel": "nova",
	"mercador_cego": "carta", "sinal_fantasma": "orbe",
	"tregua_improvavel": "estrela", "cofre_orbital": "cadeado",
	"praga_ferrugem": "veneno", "banco_ossario": "balanca",
	"apostador": "gema", "forja_esquecida": "fogo",
	"tempestade_ionica": "raio", "leilao_sussurrado": "trofeu",
	"torre_gemea": "torre", "nucleo_dormente": "nucleo",
	"biblioteca_submersa": "livro", "caderno_operador": "missao",
	"ruinas_da_primeira": "coracao", "trono_vazio": "vazio",
}

const ICONE_RESULTADO := {
	"ouro": "ouro", "gemas": "gema", "fragmentos": "fragmento", "xp": "estrela",
	"buff": "raio", "cura": "cura", "dano": "coracao", "carta": "carta",
	"onda": "ampulheta", "nada": "vazio",
}

const ORDEM_RARIDADE := ["comum", "incomum", "raro", "epico", "lendario", "mitico"]

## ============================================================== estado ====

## Sub-dicionário de estado, criado sob demanda (saves antigos entram aqui).
static func estado(s: Dictionary) -> Dictionary:
	if not (s.get("eventos", null) is Dictionary):
		s["eventos"] = {"ativo": "", "historico": [], "proximo_em": 180.0}
	var ev: Dictionary = s["eventos"]
	if not (ev.get("ativo", null) is String):
		ev["ativo"] = ""
	if not (ev.get("historico", null) is Array):
		ev["historico"] = []
	if not ev.has("proximo_em"):
		ev["proximo_em"] = 180.0
	return ev

## Evento pendente (save fechado com a janela aberta) — a UI reabre por aqui.
static func pendente(s: Dictionary) -> Dictionary:
	var id := str(estado(s)["ativo"])
	if id == "":
		return {}
	var def: Dictionary = Dados.evento_por_id.get(id, {})
	return def

## ============================================================== relógio ====

static func atualizar(dt: float, j) -> void:
	if j == null or not j.iniciado or Dados.eventos.is_empty():
		return
	var s: Dictionary = j.s
	var ev := estado(s)
	if str(ev["ativo"]) != "":
		return
	ev["proximo_em"] = float(ev["proximo_em"]) - dt
	if float(ev["proximo_em"]) > 0.0:
		return
	if not _momento_bom(j):
		ev["proximo_em"] = RETENTAR
		return
	var def := sortear(j)
	if def.is_empty():
		ev["proximo_em"] = SEM_POOL
		return
	ev["ativo"] = str(def.get("id", ""))
	Bus.evento_sorteado.emit(def)

## A porta só bate quando a onda acabou e a torre está de pé.
static func _momento_bom(j) -> bool:
	var s: Dictionary = j.s
	if not bool(s["torre"]["viva"]):
		return false
	if int(s["onda_maxima_global"]) < ONDA_MINIMA:
		return false
	if Mecanicas.em_retomada(s):
		return false
	if j.diretor == null:
		return false
	return str(j.diretor.estado) == "intervalo"

static func reagendar(j) -> void:
	var ev := estado(j.s)
	ev["proximo_em"] = j.rng.entre(INTERVALO_MIN, INTERVALO_MAX)

## ============================================================== sorteio ====

static func sortear(j) -> Dictionary:
	var s: Dictionary = j.s
	var ev := estado(s)
	var hist: Array = ev["historico"]
	# Memória dos `unico`: lista própria, imune ao corte do histórico.
	var ja_vistos := {}
	for visto in ev.get("unicos_vistos", []):
		ja_vistos[str(visto)] = true
	# Retrocompatibilidade com save antigo, que só tinha o histórico: o que
	# estiver lá e for `unico` continua contando como visto.
	for item in hist:
		var h: Dictionary = item
		var hid := str(h.get("id", ""))
		var hdef: Dictionary = Dados.evento_por_id.get(hid, {})
		if bool(hdef.get("unico", false)):
			ja_vistos[hid] = true
	var recentes: Array = []
	for i in range(maxi(0, hist.size() - MEMORIA), hist.size()):
		var h2: Dictionary = hist[i]
		recentes.append(str(h2.get("id", "")))

	var onda := int(s["onda_maxima_global"])
	var pool: Array = []
	var reserva: Array = []
	for item in Dados.eventos:
		var def: Dictionary = item
		var id := str(def.get("id", ""))
		var req = def.get("requer", null)
		if req is Dictionary and onda < int(req.get("onda", 0)):
			continue
		if bool(def.get("unico", false)) and ja_vistos.has(id):
			continue
		if recentes.has(id):
			reserva.append(def)
		else:
			pool.append(def)
	if pool.is_empty():
		pool = reserva
	if pool.is_empty():
		return {}
	var escolhido = j.rng.por_peso(pool, "peso")
	return escolhido if escolhido is Dictionary else {}

## ============================================================ resolução ====

## Aplica a opção escolhida. Devolve o efeito para a UI comemorar:
## {tipo, texto, icone, cor, tom, sucesso, arriscou, chance}
static func resolver(j, evento_id: String, indice_opcao: int) -> Dictionary:
	var s: Dictionary = j.s
	var ev := estado(s)
	var def: Dictionary = Dados.evento_por_id.get(evento_id, {})
	var opcoes: Array = def.get("opcoes", []) if not def.is_empty() else []
	if opcoes.is_empty():
		ev["ativo"] = ""
		reagendar(j)
		return {}

	var idx := clampi(indice_opcao, 0, opcoes.size() - 1)
	var opcao: Dictionary = opcoes[idx]
	var alvo: Dictionary = opcao.get("resultado", {})
	var risco = opcao.get("risco", null)
	var chance_falha := 0.0
	var sucesso := true
	if risco is Dictionary:
		chance_falha = clampf(float(risco.get("chance", 0.0)), 0.0, 1.0)
		if j.rng.chance(chance_falha):
			sucesso = false
			var falha = risco.get("falha", {})
			alvo = falha if falha is Dictionary else {}

	var efeito := aplicar(j, def, alvo)
	efeito["sucesso"] = sucesso
	efeito["arriscou"] = risco is Dictionary
	efeito["chance"] = 1.0 - chance_falha
	if not sucesso:
		efeito["tom"] = "ruim"

	var hist: Array = ev["historico"]
	hist.append({
		"id": evento_id,
		"opcao": idx,
		"onda": int(s["onda"]),
		"sucesso": sucesso,
		"tipo": str(efeito.get("tipo", "nada")),
		"quando": int(Time.get_unix_time_from_system()),
	})
	while hist.size() > HISTORICO_MAX:
		hist.pop_front()

	# Um evento `unico` sai do pool para sempre — por isso a memória dele não
	# pode morar num array que é cortado.
	if bool(def.get("unico", false)):
		var vistos: Array = ev.get("unicos_vistos", [])
		if not vistos.has(evento_id):
			vistos.append(evento_id)
		ev["unicos_vistos"] = vistos

	ev["ativo"] = ""
	reagendar(j)
	Bus.ui_atualizar.emit(false)
	return efeito

## Aplica um bloco {tipo, valor, stat, duracao, modo} e descreve o que fez.
static func aplicar(j, def: Dictionary, res: Dictionary) -> Dictionary:
	var s: Dictionary = j.s
	var tipo := str(res.get("tipo", "nada"))
	var v := float(res.get("valor", 0.0))
	var out := {
		"tipo": tipo,
		"texto": "Nada aconteceu. Às vezes é o melhor resultado possível.",
		"icone": str(ICONE_RESULTADO.get(tipo, "estrela")),
		"cor": UI.TEXTO2,
		"tom": "info",
	}
	match tipo:
		"ouro":
			var quantia := ouro_de(j, absf(v))
			if v >= 0.0:
				j.ganhar_ouro(quantia, "evento")
				out["texto"] = "+%s de ouro" % Fmt.big(quantia)
				out["cor"] = UI.OURO
				out["tom"] = "bom"
			else:
				var tinha := float(s["moedas"]["ouro"])
				var perda := Big.min_b(tinha, quantia)
				s["moedas"]["ouro"] = Big.sub(tinha, perda)
				out["texto"] = "-%s de ouro" % Fmt.big(perda)
				out["cor"] = UI.VERMELHO
				out["tom"] = "ruim"
		"gemas", "fragmentos", "nucleos", "eter", "poeira":
			Economia.ganhar_moeda(tipo, Big.from(absf(v)), j, "evento")
			out["texto"] = "+%s %s" % [Fmt.inteiro(int(absf(v))), _nome_moeda(tipo)]
			out["cor"] = UI.MOEDA_COR.get(tipo, UI.ACENTO)
			out["icone"] = Icone.da_moeda(tipo)
			out["tom"] = "bom"
		"xp":
			var xp := xp_de(j, absf(v))
			j.ganhar_xp(xp)
			out["texto"] = "+%s de experiência" % Fmt.big(xp)
			out["cor"] = UI.ACENTO2
			out["tom"] = "bom"
		"buff":
			var stat := str(res.get("stat", ""))
			var dur := float(res.get("duracao", 60.0))
			j.adicionar_buff({
				"id": "evento_%s_%s" % [str(def.get("id", "")), stat],
				"stat": stat,
				"tipo": str(res.get("modo", "pct")),
				"valor": v,
				"restante": dur,
				"fonte": Ux.txt(def, "nome", Cfg.ingles()),
				"icone": "estrela",
				"cor": str(def.get("cor", "#38bdf8")),
			})
			out["texto"] = "%s por %s" % [_desc_buff(res), Ux.tempo_curto(dur)]
			out["cor"] = UI.VERDE
			out["tom"] = "bom"
		"cura":
			var t: Dictionary = s["torre"]
			var antes := float(t["vida"])
			j.curar_torre(Big.mul_f(float(t["vida_max"]), absf(v)))
			var curou := Big.sub(float(t["vida"]), antes)
			if Big.is_zero(curou):
				out["texto"] = "O casco já estava inteiro."
				out["cor"] = UI.TEXTO2
			else:
				out["texto"] = "Casco reparado: +%s" % Fmt.big(curou)
				out["cor"] = UI.VERDE
				out["tom"] = "bom"
		"dano":
			var t2: Dictionary = s["torre"]
			j.dano_na_torre(Big.mul_f(float(t2["vida_max"]), absf(v)), null, {"ignora_iframes": true})
			out["texto"] = "A torre levou %s do casco" % Fmt.pct(absf(v), 0)
			out["cor"] = UI.VERMELHO
			out["tom"] = "ruim"
			j.tremor(12.0, 0.35)
		"carta":
			var inst := _carta(j, str(res.get("raridadeMin", "")))
			if inst.is_empty():
				out["texto"] = "Nenhuma carta sobreviveu à viagem."
			else:
				var cdef: Dictionary = Dados.carta_por_id.get(str(inst["id"]), {})
				var rar := str(inst["raridade"])
				out["texto"] = "%s  ·  %s" % [Ux.txt(cdef, "nome", Cfg.ingles()), _nome_raridade(rar)]
				out["cor"] = UI.RARIDADE_COR.get(rar, UI.ACENTO)
				out["tom"] = "epico"
		"onda":
			var destino := maxi(1, int(s["onda"]) + 1 + int(v))
			_ir_para_onda(j, destino)
			if v >= 0.0:
				out["texto"] = "O tempo pulou: onda %d" % destino
				out["cor"] = UI.ACENTO
				out["tom"] = "bom"
			else:
				out["texto"] = "O tempo voltou: onda %d" % destino
				out["cor"] = UI.VERMELHO
				out["tom"] = "ruim"
		_:
			out["cor"] = UI.TEXTO2
	return out

## ============================================================ prévias ====

## Resumo de UMA opção, para o botão da janela (antes de escolher).
static func resumo(j, res: Dictionary) -> String:
	var tipo := str(res.get("tipo", "nada"))
	var v := float(res.get("valor", 0.0))
	match tipo:
		"ouro":
			var q := Fmt.big(ouro_de(j, absf(v)))
			return ("+%s de ouro" % q) if v >= 0.0 else ("-%s de ouro" % q)
		"gemas", "fragmentos", "nucleos", "eter", "poeira":
			return "+%s %s" % [Fmt.inteiro(int(absf(v))), _nome_moeda(tipo)]
		"xp":
			return "+%s de experiência" % Fmt.big(xp_de(j, absf(v)))
		"buff":
			return "%s por %s" % [_desc_buff(res), Ux.tempo_curto(float(res.get("duracao", 60.0)))]
		"cura":
			return "Repara %s do casco" % Fmt.pct(absf(v), 0)
		"dano":
			return "A torre perde %s do casco" % Fmt.pct(absf(v), 0)
		"carta":
			var rar := str(res.get("raridadeMin", ""))
			return "Uma carta nova" + ("" if rar == "" else " (%s ou melhor)" % _nome_raridade(rar))
		"onda":
			return ("Avança %d onda(s)" % int(absf(v))) if v >= 0.0 else ("Recua %d onda(s)" % int(absf(v)))
	return "Nada"

static func icone_resultado(res: Dictionary) -> String:
	var tipo := str(res.get("tipo", "nada"))
	if tipo in ["gemas", "fragmentos", "nucleos", "eter", "poeira"]:
		return Icone.da_moeda(tipo)
	return str(ICONE_RESULTADO.get(tipo, "estrela"))

static func cor_resultado(res: Dictionary) -> Color:
	var tipo := str(res.get("tipo", "nada"))
	var v := float(res.get("valor", 0.0))
	var cor := UI.TEXTO2
	match tipo:
		"ouro": cor = UI.OURO if v >= 0.0 else UI.VERMELHO
		"gemas", "fragmentos", "nucleos", "eter", "poeira": cor = UI.MOEDA_COR.get(tipo, UI.ACENTO)
		"xp": cor = UI.ACENTO2
		"buff", "cura": cor = UI.VERDE
		"dano": cor = UI.VERMELHO
		"carta": cor = UI.RARIDADE_COR.get(str(res.get("raridadeMin", "raro")), UI.ACENTO)
		"onda": cor = UI.ACENTO if v >= 0.0 else UI.VERMELHO
	return cor

## Ícone vetorial do evento.
static func icone_de(def: Dictionary) -> String:
	return str(ICONES.get(str(def.get("id", "")), "estrela"))

static func cor_de(def: Dictionary) -> Color:
	return Color.html(str(def.get("cor", "#38bdf8")))

## ============================================================ auxiliares ====

## Ouro em log10 a partir do `valor` do JSON (escala com a onda atual).
static func ouro_de(j, v: float) -> float:
	var onda := maxi(1, int(j.s["onda"]))
	return Big.mul_f(Bal.ouro_onda(onda), v * FATOR_OURO * j.stats.n("ganhoOuro"))

static func xp_de(j, v: float) -> float:
	var onda := maxi(1, int(j.s["onda"]))
	return Big.mul_f(Bal.xp_onda(onda), v * FATOR_XP)

static func _desc_buff(res: Dictionary) -> String:
	var sd: Dictionary = Dados.stat_defs.get(str(res.get("stat", "")), {})
	var nome := Ux.txt(sd, "nome", Cfg.ingles())
	if nome == "":
		nome = str(res.get("stat", "atributo"))
	var v := float(res.get("valor", 0.0))
	match str(res.get("modo", "pct")):
		"mult": return "%s ×%s" % [nome, Fmt.num(v, 2)]
		"flat": return "%s +%s" % [nome, Fmt.num(v, 2)]
	return "%s +%s" % [nome, Fmt.pct(v, 0)]

## Nome bonito da raridade ("epico" -> "Épico"), vindo dos dados.
static func _nome_raridade(id: String) -> String:
	var nome := Ux.txt(Dados.raridade(id), "nome", Cfg.ingles())
	return nome if nome != "" else id.capitalize()

static func _nome_moeda(chave: String) -> String:
	match chave:
		"gemas": return "gemas"
		"fragmentos": return "fragmentos"
		"nucleos": return "núcleos"
		"eter": return "éter"
		"poeira": return "poeira"
	return chave

## Carta de evento, respeitando a raridade mínima da opção.
static func _carta(j, raridade_min: String) -> Dictionary:
	var inst := Saque.criar_carta(j, "", raridade_min != "")
	if inst.is_empty() or raridade_min == "":
		return inst
	var piso := ORDEM_RARIDADE.find(raridade_min)
	var atual := ORDEM_RARIDADE.find(str(inst.get("raridade", "comum")))
	if piso >= 0 and atual < piso:
		inst["raridade"] = raridade_min
		j.marcar_sujo()
	return inst

## Salta (ou recua) no tempo. O diretor está no intervalo — assume o comando.
static func _ir_para_onda(j, destino: int) -> void:
	var alvo := maxi(1, destino)
	j.arena.limpar_inimigos()
	j.diretor.chefe_atual = null
	j.diretor.iniciar_onda(alvo)
