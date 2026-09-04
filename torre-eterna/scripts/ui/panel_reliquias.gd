extends "res://scripts/ui/panel_base.gd"

## Loja de RELÍQUIAS — bônus permanentes comprados com moedas de prestígio.
##
## Filtro por moeda no topo, com o saldo de cada uma. Cada relíquia mostra
## efeito atual e próximo, custo, nível/máx e um trecho de lore em cinza.
## Relíquias travadas aparecem esmaecidas com o motivo, não escondidas:
## o jogador precisa saber o que existe adiante.

const MOEDAS := ["fragmentos", "gemas", "nucleos"]

## Chave interna do efeito -> chave de tradução (data/i18n/panel_reliquias.json).
const ESPECIAIS := {
	"offlineHoras": "rel_esp_offline_horas",
	"offlineEficiencia": "rel_esp_offline_eficiencia",
	"rerolls": "rel_esp_rerolls",
	"revivesExtra": "rel_esp_revives",
	"slotsHabilidade": "rel_esp_slots_habilidade",
	"slotsCartas": "rel_esp_slots_cartas",
	"pontosTalento": "rel_esp_pontos_talento",
	"hpInimigo": "rel_esp_hp_inimigo",
	"ganhoNucleos": "rel_esp_ganho_nucleos",
	"ondaInicial": "rel_esp_onda_inicial",
	"velocidadeMax": "rel_esp_velocidade_max",
	"comboTeto": "rel_esp_combo_teto",
	"comboBonus": "rel_esp_combo_bonus",
}

const DESBLOQUEIOS := {
	"autoReciclagem": "rel_desb_auto_reciclagem",
	"autoCompra": "rel_desb_auto_compra",
	"autoHabilidade": "rel_desb_auto_habilidade",
	"autoAscensao": "rel_desb_auto_ascensao",
	"modoFarm": "rel_desb_modo_farm",
	"desafios": "rel_desb_desafios",
}

const PASSIVAS := {
	"salva_coral": "rel_pas_salva_coral",
	"contrato_recompra": "rel_pas_contrato_recompra",
	"sino_de_recomeco": "rel_pas_sino_de_recomeco",
	"combo_imortal": "rel_pas_combo_imortal",
	"coleira_dourada": "rel_pas_coleira_dourada",
	"heranca_dourada": "rel_pas_heranca_dourada",
	"espelho_do_operador": "rel_pas_espelho_do_operador",
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
	titulo_texto = Txt.t("p_reliquias")
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
		var ic := UI.icone(Icone.da_moeda(moeda), UI.MOEDA_COR.get(moeda, UI.OURO), 20)
		h.add_child(ic)
		var l := UI.rotulo("0", 18, UI.MOEDA_COR.get(moeda, UI.OURO))
		h.add_child(l)
		h.add_child(UI.rotulo(_nome_moeda(moeda), 12, UI.TEXTO3))
		h.tooltip_text = _dica_moeda(moeda)
		topo.add_child(h)
		saldos[moeda] = l
	topo.add_child(UI.espacador())
	lbl_total = UI.rotulo("", 14, UI.TEXTO2)
	lbl_total.tooltip_text = Txt.t("rel_total_dica")
	topo.add_child(lbl_total)
	c.add_child(topo)

	var sub := UI.rotulo(Txt.t("rel_sub"), 12, UI.TEXTO3)
	c.add_child(sub)

	# ---- filtro por moeda ----
	abas = TabBar.new()
	abas.clip_tabs = false
	abas.add_tab(Txt.t("tudo"))
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
	# COLUNAS PELA LARGURA, NAO PELO PALPITE.
	#
	# Duas colunas cabiam a 1,0 e nao cabiam a 1,25, onde a janela logica cai de
	# 1280 para 1024: sobravam 173 px de conteudo escondido atras de rolagem
	# horizontal. Uma ficha de reliquia precisa de uns 470 px para o texto e os
	# dois botoes; quando nao cabem duas, cabe uma — e uma ficha larga le melhor
	# que duas cortadas.
	grade.columns = UI.colunas(UI.larg_util_painel(self), 470.0, 10.0, 2)
	grade.add_theme_constant_override("h_separation", 10)
	grade.add_theme_constant_override("v_separation", 10)
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_child(grade)
	lbl_vazio = UI.rotulo(Txt.t("rel_vazio_moeda"), 13, UI.TEXTO3)
	lista.add_child(lbl_vazio)

	_reconstruir()

func _nome_moeda(moeda: String) -> String:
	match moeda:
		"fragmentos": return Txt.t("m_fragmentos")
		"gemas": return Txt.t("m_gemas")
		"nucleos": return Txt.t("m_nucleos")
		"eter": return Txt.t("m_eter")
	return moeda

func _dica_moeda(moeda: String) -> String:
	match moeda:
		"fragmentos": return Txt.t("rel_dica_fragmentos")
		"gemas": return Txt.t("rel_dica_gemas")
		"nucleos": return Txt.t("rel_dica_nucleos")
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
	# A FICHA NAO PEDE LARGURA: ELA ACEITA A QUE SOBRAR.
	#
	# Ela pedia 490 px de minimo, e os minimos dos filhos (texto a 270, coluna
	# de compra a 156) somavam mais que isso. Duas fichas assim nao cabiam nos
	# ~1.190 px do painel: em portugues o botao "Comprar" virava "Com", o "Max"
	# virava "Ma" e sobrava barra de rolagem horizontal. Baixar os numeros um
	# pouco so diminuiu o corte — a conta continuava estourando, porque a soma
	# de minimos e que mandava.
	#
	# Sem minimo proprio, a grade divide a largura do painel em duas colunas
	# iguais (~590 cada) e a ficha se ajusta: sobra folga para o texto nos dois
	# idiomas e os botoes ficam inteiros. Os minimos dos filhos continuam la
	# como piso.
	cx.custom_minimum_size = Vector2(0, 0)

	var h := UI.hbox(10)
	cx.add_child(h)

	# --- ícone ---
	var col_ic := UI.vbox(4)
	h.add_child(col_ic)
	var ic := UI.icone(_icone_de(id), cor, 34)
	col_ic.add_child(ic)
	col_ic.add_child(UI.espacador(0, false))

	# --- textos ---
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)

	var linha_nome := UI.hbox(6)
	# O NOME TAMBEM QUEBRA LINHA, e essa e a linha que faltava.
	#
	# Todos os textos da ficha tinham `autowrap` e teto de 235 px; o NOME nao
	# tinha nenhum dos dois, entao ele crescia livre. Em portugues e em ingles os
	# nomes sao curtos e ninguem percebia. Em alemao, "Krone des geschmolzenen
	# Königs" mede 241 px e em russo "Корона расплавленного короля" mede 242: um
	# unico rotulo empurrava a ficha, a ficha empurrava a coluna, e o painel
	# inteiro ganhava barra de rolagem horizontal — com o conteudo em 1.121 px
	# num espaco de 1.048. Achado pela varredura de layout depois que os vinte
	# idiomas entraram, e nao a olho.
	var lnome := UI.rotulo(txt(def, "nome"), 15, UI.TEXTO)
	lnome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lnome.custom_minimum_size.x = 150
	lnome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha_nome.add_child(lnome)
	linha_nome.add_child(UI.espacador())
	var lnivel := UI.rotulo("", 13, UI.TEXTO2)
	linha_nome.add_child(lnivel)
	v.add_child(linha_nome)

	var ldesc := UI.rotulo(txt(def, "desc"), 12, UI.TEXTO2)
	ldesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ldesc.custom_minimum_size.x = 235
	v.add_child(ldesc)

	var latual := UI.rotulo("", 12, UI.VERDE)
	latual.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	latual.custom_minimum_size.x = 235
	v.add_child(latual)

	var lprox := UI.rotulo("", 11, UI.ACENTO)
	lprox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lprox.custom_minimum_size.x = 235
	v.add_child(lprox)

	var lbloq := UI.rotulo("", 12, UI.LARANJA)
	lbloq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbloq.custom_minimum_size.x = 235
	lbloq.visible = false
	v.add_child(lbloq)

	var llore := UI.rotulo("“" + txt(def, "lore") + "”", 11, UI.TEXTO3)
	llore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	llore.custom_minimum_size.x = 235
	v.add_child(llore)

	# --- compra ---
	var d := UI.vbox(4)
	d.custom_minimum_size.x = 140
	d.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(d)

	var linha_custo := UI.hbox(4)
	linha_custo.alignment = BoxContainer.ALIGNMENT_END
	var ic2 := UI.icone(Icone.da_moeda(moeda), cor, 15)
	linha_custo.add_child(ic2)
	var lcusto := UI.rotulo("0", 14, UI.TEXTO)
	linha_custo.add_child(lcusto)
	d.add_child(linha_custo)

	var b1 := UI.botao(Txt.t("comprar"), func(): _comprar(id, 1), Txt.t("rel_dica_comprar_1"))
	b1.custom_minimum_size = Vector2(132, 34)
	d.add_child(b1)
	var bm := UI.botao(Txt.t("rel_btn_max"), func(): _comprar(id, -1), Txt.t("rel_dica_comprar_max"))
	bm.custom_minimum_size = Vector2(132, 28)
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
			return {"ok": false, "texto": Txt.f("rel_travada_onda", {"a": alvo, "b": atual})}
	if req.has("ascensoes"):
		var alvo2 := int(req["ascensoes"])
		var atual2 := int(jogo.s["prestigio"]["ascensoes"])
		if atual2 < alvo2:
			return {"ok": false, "texto": Txt.f("rel_travada_ascensoes", {"a": alvo2, "b": atual2})}
	if req.has("singularidades"):
		var alvo3 := int(req["singularidades"])
		var atual3 := int(jogo.s["prestigio"]["singularidades"])
		if atual3 < alvo3:
			return {"ok": false, "texto": Txt.f("rel_travada_singularidades", {"a": alvo3, "b": atual3})}
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
				partes.append(Txt.f("rel_desbloqueia", {"o": Txt.t(str(DESBLOQUEIOS.get(str(val), str(val))))}))
				continue
			var fv := float(val)
			var rotulo := Txt.t(str(ESPECIAIS.get(chave, chave)))
			if chave == "hpInimigo" or chave == "ganhoNucleos":
				partes.append("%s ×%s" % [rotulo, _n(pow(fv, float(n)), 3)])
			elif chave == "offlineEficiencia" or chave == "comboBonus":
				partes.append("%s +%s" % [rotulo, Fmt.pct(fv * float(n))])
			else:
				partes.append("%s +%s" % [rotulo, _n(fv * float(n), 2)])
			continue
		if ef.has("chave"):
			partes.append(Txt.t(str(PASSIVAS.get(str(ef["chave"]), str(ef["chave"])))))
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
			Bus.toast(Txt.t("recurso_insuficiente"), "ruim")
			return
	var comprados: int = jogo.comprar_reliquia(id, n)
	if comprados > 0:
		UI.pulsar(reg["caixa"], UI.VERDE)
		Bus.toast(Txt.f("rel_comprou", {"nome": txt(def, "nome"), "n": int(jogo.s["relicas"].get(id, 0))}), "bom")
		atualizar()
	else:
		Bus.toast(Txt.f("rel_faltam", {"m": _nome_moeda(str(reg["moeda"]))}), "ruim")

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
	lbl_total.text = "%s  %d/%d" % [Txt.t("p_reliquias"), possuidas, Dados.reliquias.size()]

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
	lnivel.text = Txt.t("maximo") if no_teto else ("%s %d%s" % [Txt.t("nivel"), nivel, "/%d" % maxn if maxn >= 0 else ""])
	lnivel.add_theme_color_override("font_color", UI.OURO if no_teto else UI.TEXTO2)

	var latual: Label = reg["atual"]
	latual.text = _valores(def, nivel) if nivel > 0 else Txt.t("rel_sem_nivel")
	latual.add_theme_color_override("font_color", UI.VERDE if nivel > 0 else UI.TEXTO3)

	var lprox: Label = reg["prox"]
	lprox.visible = not travada
	if no_teto:
		lprox.text = Txt.t("rel_no_teto")
		lprox.add_theme_color_override("font_color", UI.TEXTO3)
	else:
		lprox.text = Txt.t("proximo") + ": " + _valores(def, nivel + 1)
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
		b1.text = Txt.t("bloqueado")
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
		b1.text = Txt.t("maximo")
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
	b1.text = Txt.t("comprar")
	var n_max := _max_compravel(def)
	bm.disabled = n_max <= 0
	bm.text = "%s  ×%d" % [Txt.t("rel_btn_max"), n_max] if n_max > 0 else Txt.t("rel_btn_max")
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
