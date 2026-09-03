extends "res://scripts/ui/panel_base.gd"

## Loja de RELÍQUIAS — bônus permanentes comprados com moedas de prestígio.
##
## Filtro por moeda no topo, com o saldo de cada uma. Cada relíquia mostra
## efeito atual e próximo, custo, nível/máx e um trecho de lore em cinza.
## Relíquias travadas aparecem esmaecidas com o motivo, não escondidas:
## o jogador precisa saber o que existe adiante.

const MOEDAS := ["fragmentos", "gemas", "nucleos"]

const ESPECIAIS := {
	"offlineHoras": "Horas de acúmulo offline",
	"offlineEficiencia": "Eficiência offline",
	"rerolls": "Rerrolagens diárias",
	"revivesExtra": "Renascimentos por onda",
	"slotsHabilidade": "Slots de habilidade",
	"slotsCartas": "Slots de carta",
	"pontosTalento": "Pontos de talento",
	"hpInimigo": "Vida dos inimigos",
	"ganhoNucleos": "Ganho de núcleos",
	"ondaInicial": "Onda inicial",
	"velocidadeMax": "Velocidade máxima",
	"comboTeto": "Teto de combo",
	"comboBonus": "Bônus por combo",
}

const DESBLOQUEIOS := {
	"autoReciclagem": "reciclagem automática de cartas",
	"autoCompra": "compra automática",
	"autoHabilidade": "uso automático de habilidades",
	"autoAscensao": "ascensão automática",
	"modoFarm": "modo farm",
	"desafios": "desafios",
}

const PASSIVAS := {
	"salva_coral": "Salva coral: de tempos em tempos a torre despeja projéteis em círculo.",
	"contrato_recompra": "Contrato de recompra: cancela uma morte por onda e devolve parte da vida.",
	"sino_de_recomeco": "Sino do recomeço: zera o tempo de recarga das habilidades a cada onda.",
	"combo_imortal": "Combo imortal: o combo só cai quando a torre toma dano.",
	"coleira_dourada": "Coleira dourada: mais inimigos dourados, e eles não fogem mais.",
	"heranca_dourada": "Herança dourada: guarda parte do ouro ao ascender.",
	"espelho_do_operador": "Espelho do operador: sua relíquia mais cara conta duas vezes.",
}

var abas: TabBar
var lista: VBoxContainer
var grade: GridContainer
var lbl_total: Label
var saldos: Dictionary = {}      # moeda -> Label
var cartoes: Dictionary = {}     # id -> Dictionary com os nós que mudam
var filtro := "todas"
var lbl_vazio: Label

func configurar() -> void:
	titulo_texto = "Relíquias"
	titulo_icone = "reliquia"
	largura = 1080.0
	altura = 690.0
	intervalo = 0.25

# ------------------------------------------------------------------ montagem

func montar(c: VBoxContainer) -> void:
	# ---- saldos ----
	var topo := UI.hbox(16)
	for moeda in MOEDAS:
		var h := UI.hbox(5)
		var ic := Control.new()
		ic.set_script(load("res://scripts/ui/icone_control.gd"))
		h.add_child(ic)
		ic.configurar(Icone.da_moeda(moeda), UI.MOEDA_COR.get(moeda, UI.OURO), 20)
		var l := UI.rotulo("0", 18, UI.MOEDA_COR.get(moeda, UI.OURO))
		h.add_child(l)
		h.add_child(UI.rotulo(_nome_moeda(moeda), 12, UI.TEXTO3))
		h.tooltip_text = _dica_moeda(moeda)
		topo.add_child(h)
		saldos[moeda] = l
	topo.add_child(UI.espacador())
	lbl_total = UI.rotulo("", 14, UI.TEXTO2)
	lbl_total.tooltip_text = "Relíquias com pelo menos um nível, de todas as que existem."
	topo.add_child(lbl_total)
	c.add_child(topo)

	var sub := UI.rotulo("Bônus permanentes: sobrevivem à Ascensão, à Singularidade e a você.", 12, UI.TEXTO3)
	c.add_child(sub)

	# ---- filtro por moeda ----
	abas = TabBar.new()
	abas.clip_tabs = false
	abas.add_tab("Todas")
	for moeda in MOEDAS:
		abas.add_tab(_nome_moeda(moeda).capitalize())
	abas.tab_changed.connect(func(i):
		filtro = "todas" if i <= 0 else str(MOEDAS[i - 1])
		_reconstruir())
	c.add_child(abas)

	# ---- grade de cartões ----
	var rolagem := UI.scroll()
	c.add_child(rolagem)
	lista = UI.vbox(10)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(lista)
	grade = GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 10)
	grade.add_theme_constant_override("v_separation", 10)
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_child(grade)
	lbl_vazio = UI.rotulo("Nenhuma relíquia nesta moeda ainda.", 13, UI.TEXTO3)
	lista.add_child(lbl_vazio)

	_reconstruir()

func _nome_moeda(moeda: String) -> String:
	match moeda:
		"fragmentos": return "fragmentos"
		"gemas": return "gemas"
		"nucleos": return "núcleos"
		"eter": return "éter"
	return moeda

func _dica_moeda(moeda: String) -> String:
	match moeda:
		"fragmentos": return "Fragmentos: vêm da Ascensão. O pó do que a torre já foi."
		"gemas": return "Gemas: caem de chefes e missões. Duras de conseguir, fáceis de gastar."
		"nucleos": return "Núcleos: vêm da Singularidade. Poucos, densos e caros."
	return moeda

# ------------------------------------------------------------ reconstrução

func _reconstruir() -> void:
	cartoes.clear()
	for n in grade.get_children():
		grade.remove_child(n)
		n.queue_free()
	var n_vis := 0
	for item in Dados.reliquias:
		var def: Dictionary = item
		if filtro != "todas" and str(def.get("moeda", "fragmentos")) != filtro:
			continue
		grade.add_child(_cartao(def))
		n_vis += 1
	lbl_vazio.visible = n_vis == 0
	atualizar()

func _cartao(def: Dictionary) -> Control:
	var id := str(def.get("id", ""))
	var moeda := str(def.get("moeda", "fragmentos"))
	var cor: Color = UI.MOEDA_COR.get(moeda, UI.OURO)

	var cx := UI.painel(UI.PAINEL2.darkened(0.16), 12)
	cx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cx.custom_minimum_size = Vector2(490, 0)

	var h := UI.hbox(10)
	cx.add_child(h)

	# --- ícone ---
	var col_ic := UI.vbox(4)
	h.add_child(col_ic)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	col_ic.add_child(ic)
	ic.configurar(_icone_de(id), cor, 34)
	col_ic.add_child(UI.espacador(0, false))

	# --- textos ---
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)

	var linha_nome := UI.hbox(6)
	var lnome := UI.rotulo(txt(def, "nome"), 15, UI.TEXTO)
	linha_nome.add_child(lnome)
	linha_nome.add_child(UI.espacador())
	var lnivel := UI.rotulo("", 13, UI.TEXTO2)
	linha_nome.add_child(lnivel)
	v.add_child(linha_nome)

	var ldesc := UI.rotulo(txt(def, "desc"), 12, UI.TEXTO2)
	ldesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ldesc.custom_minimum_size.x = 270
	v.add_child(ldesc)

	var latual := UI.rotulo("", 12, UI.VERDE)
	latual.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	latual.custom_minimum_size.x = 270
	v.add_child(latual)

	var lprox := UI.rotulo("", 11, UI.ACENTO)
	lprox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lprox.custom_minimum_size.x = 270
	v.add_child(lprox)

	var lbloq := UI.rotulo("", 12, UI.LARANJA)
	lbloq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbloq.custom_minimum_size.x = 270
	lbloq.visible = false
	v.add_child(lbloq)

	var llore := UI.rotulo("“" + txt(def, "lore") + "”", 11, UI.TEXTO3)
	llore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	llore.custom_minimum_size.x = 270
	v.add_child(llore)

	# --- compra ---
	var d := UI.vbox(4)
	d.custom_minimum_size.x = 156
	d.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(d)

	var linha_custo := UI.hbox(4)
	linha_custo.alignment = BoxContainer.ALIGNMENT_END
	var ic2 := Control.new()
	ic2.set_script(load("res://scripts/ui/icone_control.gd"))
	linha_custo.add_child(ic2)
	ic2.configurar(Icone.da_moeda(moeda), cor, 15)
	var lcusto := UI.rotulo("0", 14, UI.TEXTO)
	linha_custo.add_child(lcusto)
	d.add_child(linha_custo)

	var b1 := UI.botao("Comprar", func(): _comprar(id, 1), "Sobe um nível desta relíquia.")
	b1.custom_minimum_size = Vector2(150, 34)
	d.add_child(b1)
	var bm := UI.botao("Máx", func(): _comprar(id, -1), "Compra quantos níveis o saldo aguentar.")
	bm.custom_minimum_size = Vector2(150, 28)
	bm.add_theme_font_size_override("font_size", 13)
	d.add_child(bm)

	var barra := UI.barra(cor, 6)
	barra.visible = int(def.get("max", -1)) > 0
	v.add_child(barra)

	cartoes[id] = {
		"def": def, "caixa": cx, "icone": ic, "nome": lnome, "nivel": lnivel,
		"atual": latual, "prox": lprox, "custo": lcusto, "icone_custo": ic2,
		"b1": b1, "bm": bm, "bloqueio": lbloq, "barra": barra, "lore": llore,
		"desc": ldesc, "cor": cor, "moeda": moeda, "aceso": false,
	}
	return cx

func _icone_de(id: String) -> String:
	match id:
		"coracao_primeira_torre": return "coracao"
		"dizimo_coveiro", "coleira_dourada", "testamento_dourado": return "ouro"
		"lente_vigia_cego": return "alvo"
		"costela_aco_morto": return "escudo"
		"gatilho_homem_morto": return "raio"
		"prisma_faminto": return "gema"
		"caderno_ultimo_engenheiro": return "livro"
		"coroa_rei_fundido": return "trofeu"
		"ovo_sentinela": return "orbe"
		"estilhaco_primeiro_colapso": return "fragmento"
		"cripta_estase", "relogio_turno_noite", "ampulheta_rachada": return "ampulheta"
		"dado_viciado": return "estrela"
		"vela_segundo_folego": return "fogo"
		"cinto_operador": return "engrenagem"
		"bocarra_recicladora": return "poeira"
		"mao_extra": return "carta"
		"manual_recruta": return "arvore"
		"coro_estilhacos", "sino_recomeco": return "nova"
		"contrato_recompra": return "missao"
		"regra_riscada": return "balanca"
		"espelho_operador": return "prestigio"
	return "reliquia"

# ---------------------------------------------------------------- requisitos

func _requisito(def: Dictionary) -> Dictionary:
	var r = def.get("requer", null)
	if not (r is Dictionary):
		return {"ok": true, "texto": ""}
	var req: Dictionary = r
	if req.has("onda"):
		var alvo := int(req["onda"])
		var atual := int(jogo.s["onda_maxima_global"])
		if atual < alvo:
			return {"ok": false, "texto": "Travada — alcance a onda %d (você chegou à %d)" % [alvo, atual]}
	if req.has("ascensoes"):
		var alvo2 := int(req["ascensoes"])
		var atual2 := int(jogo.s["prestigio"]["ascensoes"])
		if atual2 < alvo2:
			return {"ok": false, "texto": "Travada — %d ascensões (você tem %d)" % [alvo2, atual2]}
	if req.has("singularidades"):
		var alvo3 := int(req["singularidades"])
		var atual3 := int(jogo.s["prestigio"]["singularidades"])
		if atual3 < alvo3:
			return {"ok": false, "texto": "Travada — %d singularidades (você tem %d)" % [alvo3, atual3]}
	return {"ok": true, "texto": ""}

# ------------------------------------------------------------------- efeitos

func _n(v: float, casas: int = 2) -> String:
	if v < 0.0:
		return "-" + Fmt.num(-v, casas)
	return Fmt.num(v, casas)

func _nome_stat(chave: String) -> String:
	var sd: Dictionary = Dados.stat_defs.get(chave, {})
	if sd.is_empty():
		return chave
	return txt(sd, "nome")

## Resumo dos efeitos da relíquia acumulados até o nível `n`.
func _valores(def: Dictionary, n: int) -> String:
	if n <= 0:
		return ""
	var partes: Array = []
	for item in def.get("efeito", []):
		if not (item is Dictionary):
			continue
		var ef: Dictionary = item
		if ef.has("stat"):
			var nome := _nome_stat(str(ef["stat"]))
			var v := float(ef.get("valor", 0.0))
			match str(ef.get("tipo", "flat")):
				"pct":
					partes.append("%s +%s" % [nome, Fmt.pct(v * float(n))])
				"mult":
					partes.append("%s ×%s" % [nome, Fmt.big(Big.pow_n(Big.from(v), float(n)))])
				_:
					partes.append("%s +%s" % [nome, _n(v * float(n), 3)])
			continue
		if ef.has("especial"):
			var chave := str(ef["especial"])
			var val = ef.get("valor", 0)
			if chave == "desbloqueio" or not (val is float or val is int):
				partes.append("Desbloqueia " + str(DESBLOQUEIOS.get(str(val), str(val))))
				continue
			var fv := float(val)
			var rotulo := str(ESPECIAIS.get(chave, chave))
			if chave == "hpInimigo" or chave == "ganhoNucleos":
				partes.append("%s ×%s" % [rotulo, _n(pow(fv, float(n)), 3)])
			elif chave == "offlineEficiencia" or chave == "comboBonus":
				partes.append("%s +%s" % [rotulo, Fmt.pct(fv * float(n))])
			else:
				partes.append("%s +%s" % [rotulo, _n(fv * float(n), 2)])
			continue
		if ef.has("chave"):
			partes.append(str(PASSIVAS.get(str(ef["chave"]), str(ef["chave"]))))
	return " · ".join(partes)

# -------------------------------------------------------------------- compra

func _comprar(id: String, qtd: int) -> void:
	if not cartoes.has(id):
		return
	var reg: Dictionary = cartoes[id]
	var def: Dictionary = reg["def"]
	var req := _requisito(def)
	if not bool(req["ok"]):
		Bus.toast(str(req["texto"]), "info")
		return
	var n := qtd
	if n < 0:
		n = _max_compravel(def)
		if n <= 0:
			Bus.toast("Saldo insuficiente", "ruim")
			return
	var comprados: int = jogo.comprar_reliquia(id, n)
	if comprados > 0:
		UI.pulsar(reg["caixa"], UI.VERDE)
		Bus.toast("%s — nível %d" % [txt(def, "nome"), int(jogo.s["relicas"].get(id, 0))], "bom")
		atualizar()
	else:
		Bus.toast("Faltam %s" % _nome_moeda(str(reg["moeda"])), "ruim")

func _max_compravel(def: Dictionary) -> int:
	var id := str(def.get("id", ""))
	var moeda := str(def.get("moeda", "fragmentos"))
	var nivel := int(jogo.s["relicas"].get(id, 0))
	var maxn := int(def.get("max", -1))
	var teto := 1000 if maxn < 0 else maxn - nivel
	if teto <= 0:
		return 0
	var saldo: float = jogo.s["moedas"].get(moeda, Big.ZERO)
	return Big.max_afford(saldo, float(def.get("base", 1)), float(def.get("cresc", 1.6)), nivel, teto)

# ---------------------------------------------------------------- atualizar

func atualizar() -> void:
	if jogo == null or lbl_total == null:
		return
	for moeda in MOEDAS:
		var l: Label = saldos[moeda]
		l.text = Fmt.big(jogo.s["moedas"].get(moeda, Big.ZERO))

	var possuidas := 0
	for id in jogo.s["relicas"].keys():
		if int(jogo.s["relicas"][id]) > 0:
			possuidas += 1
	lbl_total.text = "Relíquias  %d/%d" % [possuidas, Dados.reliquias.size()]

	for id in cartoes.keys():
		_atualizar_cartao(str(id))

func _atualizar_cartao(id: String) -> void:
	var reg: Dictionary = cartoes[id]
	var def: Dictionary = reg["def"]
	var moeda := str(reg["moeda"])
	var cor: Color = reg["cor"]
	var nivel := int(jogo.s["relicas"].get(id, 0))
	var maxn := int(def.get("max", -1))
	var no_teto := maxn >= 0 and nivel >= maxn
	var req := _requisito(def)
	var travada := not bool(req["ok"])

	var lnivel: Label = reg["nivel"]
	lnivel.text = "MÁX" if no_teto else ("Nv %d%s" % [nivel, "/%d" % maxn if maxn >= 0 else ""])
	lnivel.add_theme_color_override("font_color", UI.OURO if no_teto else UI.TEXTO2)

	var latual: Label = reg["atual"]
	latual.text = _valores(def, nivel) if nivel > 0 else "Ainda sem nível — nenhum efeito."
	latual.add_theme_color_override("font_color", UI.VERDE if nivel > 0 else UI.TEXTO3)

	var lprox: Label = reg["prox"]
	lprox.visible = not travada
	if no_teto:
		lprox.text = "Nada além disso. Já foi longe."
		lprox.add_theme_color_override("font_color", UI.TEXTO3)
	else:
		lprox.text = "Próximo: " + _valores(def, nivel + 1)
		lprox.add_theme_color_override("font_color", UI.ACENTO)

	var barra: ProgressBar = reg["barra"]
	if maxn > 0:
		barra.value = float(nivel) / float(maxn)

	var lbloq: Label = reg["bloqueio"]
	lbloq.visible = travada
	if travada:
		lbloq.text = str(req["texto"])

	var b1: Button = reg["b1"]
	var bm: Button = reg["bm"]
	var lcusto: Label = reg["custo"]
	var cx: PanelContainer = reg["caixa"]
	var ic: Control = reg["icone"]

	if travada:
		cx.modulate = Color(1, 1, 1, 0.55)
		b1.disabled = true
		bm.disabled = true
		b1.text = "Travada"
		bm.visible = false
		lcusto.text = "—"
		lcusto.add_theme_color_override("font_color", UI.TEXTO3)
		ic.set("cor", UI.TEXTO3)
		ic.queue_redraw()
		_acender(reg, false, cor)
		return

	cx.modulate = Color(1, 1, 1, 1)
	ic.set("cor", cor)
	ic.queue_redraw()
	bm.visible = not no_teto

	if no_teto:
		b1.disabled = true
		b1.text = "MÁXIMO"
		lcusto.text = "—"
		lcusto.add_theme_color_override("font_color", UI.TEXTO3)
		_acender(reg, true, UI.OURO)
		return

	var custo := Big.geo_sum(float(def.get("base", 1)), float(def.get("cresc", 1.6)), nivel, 1)
	var saldo: float = jogo.s["moedas"].get(moeda, Big.ZERO)
	var pode := Big.gte(saldo, custo)
	lcusto.text = Fmt.big(custo)
	lcusto.add_theme_color_override("font_color", UI.TEXTO if pode else UI.TEXTO3)
	b1.disabled = not pode
	b1.text = "Comprar"
	var n_max := _max_compravel(def)
	bm.disabled = n_max <= 0
	bm.text = "Máx  ×%d" % n_max if n_max > 0 else "Máx"
	_acender(reg, pode, cor)

## Acende a moldura do cartão quando dá para comprar (ou quando está no máximo).
func _acender(reg: Dictionary, aceso: bool, cor: Color) -> void:
	if bool(reg["aceso"]) == aceso:
		return
	reg["aceso"] = aceso
	var cx: PanelContainer = reg["caixa"]
	cx.add_theme_stylebox_override("panel", UI.caixa(
		UI.PAINEL2.darkened(0.06) if aceso else UI.PAINEL2.darkened(0.16), 12, 1,
		cor.darkened(0.25) if aceso else UI.BORDA))
