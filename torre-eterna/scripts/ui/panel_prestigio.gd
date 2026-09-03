extends "res://scripts/ui/panel_base.gd"

## Painel de PRESTÍGIO — as três camadas do ciclo: Ascensão, Singularidade,
## Transcendência. Cada aba tem o mesmo ritual: o bloco de destaque diz quanto
## você ganha e o que perde, o botão grande executa, e a árvore permanente
## daquela camada guarda o que sobrou de todas as torres anteriores.
##
## Camadas ainda trancadas mostram o requisito com barra de progresso — o
## jogador precisa ver o que está perseguindo antes de conseguir perseguir.

const CHAVE_ARVORE := {"ascensao": "fragmentos", "singularidade": "nucleos", "transcendencia": "eter"}
const TABELA := {"fragmentos": "arvore_fragmentos", "nucleos": "arvore_nucleos", "eter": "arvore_eter"}
const CARD_W := 292.0

var abas: TabBar
var camadas: Array = []
var idx := 0
var conteudo: VBoxContainer

var chips := {}              # chave -> Label (moedas e contadores do topo)
var refs := {}               # rótulos do bloco de destaque
var barras := []             # [{barra, rotulo, atual: Callable, alvo}]
var cards := {}              # id do nó -> {def, ...}
var auras := []              # Controls com pulso

var dlg: Control
var dlg_titulo: Label
var dlg_lore: Label
var dlg_ganho: Label
var dlg_perde: Label
var dlg_mantem: Label
var dlg_sim: Button
var dlg_caixa: PanelContainer
var _pendente := ""

var check_auto: CheckButton
var giro_auto: SpinBox

func configurar() -> void:
	titulo_texto = Txt.t("p_prestigio")
	titulo_icone = "prestigio"
	largura = 1010.0
	altura = 690.0
	intervalo = 0.18

# ================================================================== montagem

func montar(c: VBoxContainer) -> void:
	camadas = Dados.camadas_prestigio
	if camadas.is_empty():
		c.add_child(UI.rotulo(Txt.t("prg_sem_camadas"), 14, UI.TEXTO3))
		return

	c.add_child(_barra_topo())

	abas = TabBar.new()
	abas.clip_tabs = false
	for item in camadas:
		var cam: Dictionary = item
		abas.add_tab(txt(cam, "nome"))
	abas.tab_changed.connect(func(i: int):
		idx = i
		_reconstruir())
	# abre já na camada mais alta que o jogador alcançou
	for i in camadas.size():
		if _liberada(camadas[i]):
			idx = i
	abas.current_tab = idx
	c.add_child(abas)

	conteudo = UI.vbox(8)
	conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_child(conteudo)

	_montar_dialogo()
	_reconstruir()

## Fita de moedas e contadores — sempre visível, seja qual for a aba.
func _barra_topo() -> HBoxContainer:
	var h := UI.hbox(6)
	for moeda in ["fragmentos", "nucleos", "eter"]:
		h.add_child(_chip(moeda, Icone.da_moeda(moeda), UI.MOEDA_COR.get(moeda, UI.TEXTO),
			_nome_moeda(moeda), Txt.t("prg_dica_moeda")))
	h.add_child(UI.espacador())
	h.add_child(_chip("ascensoes", "prestigio", UI.ACENTO, Txt.t("ascensoes"), Txt.t("prg_dica_ascensoes")))
	h.add_child(_chip("melhor", "trofeu", UI.OURO, Txt.t("melhor_onda"), Txt.t("prg_dica_melhor")))
	h.add_child(_chip("singularidades", "nucleo", UI.MOEDA_COR.get("nucleos", UI.ACENTO2), Txt.t("prg_singularidades"), Txt.t("prg_dica_singularidades")))
	h.add_child(_chip("transcendencias", "eter", UI.MOEDA_COR.get("eter", UI.ROSA), Txt.t("prg_transcendencias"), Txt.t("prg_dica_transcendencias")))
	return h

func _chip(chave: String, icone: String, cor: Color, legenda: String, dica: String) -> PanelContainer:
	var cx := UI.painel(UI.PAINEL2.darkened(0.18), 8)
	cx.tooltip_text = dica
	cx.mouse_filter = Control.MOUSE_FILTER_STOP
	var h := UI.hbox(6)
	cx.add_child(h)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(icone, cor, 17)
	var v := UI.vbox(0)
	h.add_child(v)
	var l := UI.rotulo("0", 15, cor)
	v.add_child(l)
	v.add_child(UI.rotulo(legenda, 10, UI.TEXTO3))
	chips[chave] = l
	return cx

# ------------------------------------------------------------ reconstrução

func _reconstruir() -> void:
	if conteudo == null:
		return
	for n in conteudo.get_children():
		conteudo.remove_child(n)
		n.queue_free()
	refs.clear()
	barras.clear()
	cards.clear()
	auras.clear()
	check_auto = null
	giro_auto = null

	var cam: Dictionary = camadas[clampi(idx, 0, camadas.size() - 1)]
	conteudo.add_child(_destaque(cam))
	if str(cam.get("id", "")) == "ascensao":
		conteudo.add_child(_auto_ascensao())
	conteudo.add_child(_cabecalho_arvore(cam))

	var rol := UI.scroll()
	rol.add_child(_grade(cam))
	conteudo.add_child(rol)

	for a in auras:
		var aura: Control = a
		var tw := aura.create_tween().set_loops()
		tw.tween_property(aura, "modulate:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
		tw.tween_property(aura, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	atualizar()

# =================================================================== destaque

func _destaque(cam: Dictionary) -> PanelContainer:
	var cor := Color.html(str(cam.get("cor", "#38bdf8")))
	var moeda := str(cam.get("moeda", "fragmentos"))
	var liberada := _liberada(cam)

	var cx := PanelContainer.new()
	cx.add_theme_stylebox_override("panel", UI.caixa(
		UI.PAINEL2.darkened(0.28).lerp(cor.darkened(0.72), 0.5), 14, 2,
		cor.darkened(0.35) if liberada else UI.BORDA))
	var v := UI.vbox(6)
	cx.add_child(v)

	var h := UI.hbox(14)
	v.add_child(h)

	# --- selo da camada: aura pulsante + ícone da moeda ---
	var aura := Control.new()
	aura.custom_minimum_size = Vector2(96, 96)
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	aura.draw.connect(_desenhar_aura.bind(aura, cor, liberada))
	h.add_child(aura)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aura.add_child(ic)
	ic.configurar(Icone.da_moeda(moeda), cor if liberada else UI.TEXTO3, 44)
	if liberada:
		auras.append(aura)

	# --- textos ---
	var t := UI.vbox(3)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)

	if liberada:
		t.add_child(UI.rotulo(Txt.f("prg_ganho_ao", {"v": txt(cam, "verbo").to_upper()}), 11, UI.TEXTO3))
		var linha_ganho := UI.hbox(8)
		var lbl := UI.rotulo("0", 42, cor)
		linha_ganho.add_child(lbl)
		var uni := UI.rotulo(_nome_moeda(moeda), 15, UI.TEXTO2)
		uni.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		linha_ganho.add_child(uni)
		t.add_child(linha_ganho)
		refs["ganho"] = lbl
		var mult := UI.rotulo("", 13, UI.VERDE)
		t.add_child(mult)
		refs["mult"] = mult
	else:
		t.add_child(UI.rotulo(Txt.t("prg_fora_alcance"), 11, UI.TEXTO3))
		t.add_child(UI.rotulo(txt(cam, "requisito"), 19, UI.TEXTO2))
		for item in _requisitos(str(cam.get("id", ""))):
			var req: Dictionary = item
			t.add_child(_linha_requisito(req, cor))

	var lore := UI.rotulo(txt(cam, "lore"), 12, UI.TEXTO3)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size.x = 430
	t.add_child(lore)

	# --- botão do ritual ---
	var caixa_bt := UI.vbox(4)
	caixa_bt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(caixa_bt)
	var b := UI.botao(txt(cam, "verbo").to_upper(), func(): _pedir(str(cam.get("id", ""))))
	b.custom_minimum_size = Vector2(226, 68)
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_stylebox_override("normal", UI.caixa(cor.darkened(0.62), 10, 2, cor.darkened(0.15)))
	b.add_theme_stylebox_override("hover", UI.caixa(cor.darkened(0.40), 10, 2, Color.WHITE))
	b.add_theme_stylebox_override("pressed", UI.caixa(cor.darkened(0.22), 10, 2, Color.WHITE))
	b.add_theme_stylebox_override("disabled", UI.caixa(UI.PAINEL.darkened(0.3), 10, 1, UI.BORDA.darkened(0.2)))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.tooltip_text = Txt.f("prg_tip_ritual", {
		"req": txt(cam, "requisito"), "perde": txt(cam, "resetaTexto"), "mantem": txt(cam, "mantemTexto")})
	caixa_bt.add_child(b)
	refs["botao"] = b
	refs["cam"] = cam
	var sub := UI.rotulo("", 11, UI.TEXTO3)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa_bt.add_child(sub)
	refs["sub"] = sub

	# --- o que se desfaz / o que permanece ---
	v.add_child(UI.separador())
	var pes := UI.hbox(18)
	v.add_child(pes)
	pes.add_child(_coluna_texto(Txt.t("o_que_reseta").to_upper(), txt(cam, "resetaTexto"), UI.VERMELHO))
	pes.add_child(_coluna_texto(Txt.t("o_que_permanece").to_upper(), txt(cam, "mantemTexto"), UI.VERDE))
	return cx

func _coluna_texto(cabeca: String, corpo_txt: String, cor: Color) -> VBoxContainer:
	var v := UI.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.rotulo(cabeca, 10, UI.TEXTO3))
	var l := UI.rotulo(corpo_txt, 12, cor.lerp(UI.TEXTO, 0.35))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 380
	v.add_child(l)
	return v

func _linha_requisito(req: Dictionary, cor: Color) -> VBoxContainer:
	var v := UI.vbox(2)
	var h := UI.hbox(6)
	h.add_child(UI.rotulo(str(req.get("rotulo", "")), 12, UI.TEXTO2))
	h.add_child(UI.espacador())
	var val := UI.rotulo("", 12, UI.TEXTO3)
	h.add_child(val)
	v.add_child(h)
	var pb := UI.barra(cor, 8)
	pb.custom_minimum_size.x = 430
	v.add_child(pb)
	barras.append({"barra": pb, "rotulo": val, "chave": str(req.get("chave", "")), "alvo": float(req.get("alvo", 1.0))})
	return v

func _desenhar_aura(aura: Control, cor: Color, liberada: bool) -> void:
	var c := aura.size * 0.5
	var r := minf(aura.size.x, aura.size.y) * 0.5
	if not liberada:
		aura.draw_arc(c, r * 0.9, 0.0, TAU, 40, Ux.com_alfa(UI.BORDA, 0.7), 1.5, true)
		return
	aura.draw_circle(c, r * 0.86, Ux.com_alfa(cor, 0.08))
	aura.draw_circle(c, r * 0.60, Ux.com_alfa(cor, 0.12))
	aura.draw_arc(c, r * 0.92, 0.0, TAU, 48, Ux.com_alfa(cor, 0.45), 2.0, true)
	for i in 3:
		var a0 := float(i) * 2.09
		aura.draw_arc(c, r * (0.60 + float(i) * 0.11), a0, a0 + PI * 1.05, 24, Ux.com_alfa(cor, 0.30), 1.5, true)

# ============================================================ auto-ascensão

func _auto_ascensao() -> PanelContainer:
	var cx := UI.painel(UI.PAINEL2.darkened(0.2), 10)
	var h := UI.hbox(10)
	cx.add_child(h)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)

	if not jogo.esp["desbloqueios"].has("autoAscensao"):
		ic.configurar("cadeado", UI.TEXTO3, 17)
		h.add_child(UI.rotulo(Txt.t("prg_auto_bloqueada"), 12, UI.TEXTO3))
		cx.tooltip_text = Txt.t("prg_auto_bloqueada_dica")
		return cx

	ic.configurar("prestigio", UI.ACENTO, 17)
	check_auto = CheckButton.new()
	check_auto.text = Txt.t("prg_auto_ascensao")
	check_auto.tooltip_text = Txt.t("prg_auto_dica")
	check_auto.button_pressed = bool(jogo.s["prestigio"]["auto_ascender"])
	check_auto.toggled.connect(func(v: bool):
		jogo.s["prestigio"]["auto_ascender"] = v
		jogo.marcar_sujo()
		Bus.toast(Txt.t("prg_auto_ligada") if v else Txt.t("prg_auto_desligada"), "info"))
	h.add_child(check_auto)
	h.add_child(UI.espacador())
	h.add_child(UI.rotulo(Txt.t("prg_ao_chegar_onda"), 12, UI.TEXTO2))

	giro_auto = SpinBox.new()
	giro_auto.min_value = float(Bal.ASC_ONDA_MIN)
	giro_auto.max_value = 999999.0
	giro_auto.step = 5.0
	giro_auto.custom_minimum_size.x = 110
	giro_auto.value = maxf(float(Bal.ASC_ONDA_MIN), float(jogo.s["prestigio"]["auto_ascender_onda"]))
	giro_auto.tooltip_text = Txt.t("prg_onda_alvo_dica")
	giro_auto.value_changed.connect(func(v: float):
		jogo.s["prestigio"]["auto_ascender_onda"] = int(v)
		jogo.marcar_sujo())
	h.add_child(giro_auto)
	return cx

# ================================================================== árvore

func _cabecalho_arvore(cam: Dictionary) -> HBoxContainer:
	var chave := str(CHAVE_ARVORE.get(str(cam.get("id", "")), "fragmentos"))
	var cor := Color.html(str(cam.get("cor", "#38bdf8")))
	var h := UI.hbox(8)
	h.add_child(UI.rotulo(Txt.t("arvore_permanente").to_upper(), 12, UI.TEXTO3))
	h.add_child(UI.rotulo("·", 12, UI.TEXTO3))
	h.add_child(UI.rotulo(_nome_moeda(chave).to_upper(), 12, cor))
	h.add_child(UI.espacador())
	var l := UI.rotulo("", 12, UI.TEXTO3)
	h.add_child(l)
	refs["resumo_arvore"] = l
	return h

func _grade(cam: Dictionary) -> Control:
	var chave := str(CHAVE_ARVORE.get(str(cam.get("id", "")), "fragmentos"))
	var cor := Color.html(str(cam.get("cor", "#38bdf8")))
	var nos: Array = Dados.arvore.get(chave, [])
	if nos.is_empty():
		return UI.rotulo(Txt.t("prg_arvore_vazia"), 13, UI.TEXTO3)

	var colunas := 1
	var linhas_max := 0
	for item in nos:
		var def: Dictionary = item
		var p: Array = def.get("pos", [0, 0])
		colunas = maxi(colunas, int(p[0]) + 1 if p.size() > 0 else 1)
		linhas_max = maxi(linhas_max, int(p[1]) + 1 if p.size() > 1 else 1)

	var mapa := {}
	for item2 in nos:
		var def2: Dictionary = item2
		var p2: Array = def2.get("pos", [0, 0])
		var col := int(p2[0]) if p2.size() > 0 else 0
		var lin := int(p2[1]) if p2.size() > 1 else 0
		mapa[lin * 100 + col] = def2

	var g := GridContainer.new()
	g.columns = colunas
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lin2 in linhas_max:
		for col2 in colunas:
			var k := lin2 * 100 + col2
			if mapa.has(k):
				g.add_child(_card(mapa[k], chave, cor))
			else:
				var vazio := Control.new()
				vazio.custom_minimum_size = Vector2(CARD_W, 0)
				g.add_child(vazio)
	return g

func _card(def: Dictionary, chave: String, cor: Color) -> PanelContainer:
	var id := str(def.get("id", ""))
	var cx := PanelContainer.new()
	cx.custom_minimum_size = Vector2(CARD_W, 0)
	cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.2), 10, 1, UI.BORDA))
	var v := UI.vbox(3)
	cx.add_child(v)

	var cab := UI.hbox(8)
	v.add_child(cab)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	cab.add_child(ic)
	ic.configurar(_icone_no(id), cor, 24)
	var t := UI.vbox(0)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	t.add_child(UI.rotulo(txt(def, "nome"), 14, UI.TEXTO))
	var nivel := UI.rotulo("", 11, UI.TEXTO3)
	t.add_child(nivel)

	var agora := UI.rotulo("", 11, UI.VERDE)
	agora.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	agora.custom_minimum_size.x = CARD_W - 28.0
	v.add_child(agora)
	var prox := UI.rotulo("", 11, UI.TEXTO2)
	prox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prox.custom_minimum_size.x = CARD_W - 28.0
	v.add_child(prox)

	var rodape := UI.hbox(6)
	v.add_child(rodape)
	var ic_custo := Control.new()
	ic_custo.set_script(load("res://scripts/ui/icone_control.gd"))
	rodape.add_child(ic_custo)
	ic_custo.configurar(Icone.da_moeda(chave), UI.MOEDA_COR.get(chave, UI.TEXTO), 14)
	var lbl_custo := UI.rotulo("", 13, UI.TEXTO)
	rodape.add_child(lbl_custo)
	rodape.add_child(UI.espacador())
	var b1 := UI.botao("×1", func(): _comprar(id, 1), Txt.t("prg_dica_x1"))
	b1.custom_minimum_size = Vector2(46, 30)
	rodape.add_child(b1)
	var bm := UI.botao(Txt.t("prg_bt_max"), func(): _comprar(id, -1), Txt.t("prg_dica_max"))
	bm.custom_minimum_size = Vector2(62, 30)
	rodape.add_child(bm)

	cards[id] = {
		"def": def, "chave": chave, "cor": cor, "caixa": cx, "icone": ic,
		"nivel": nivel, "agora": agora, "prox": prox, "custo": lbl_custo,
		"ic_custo": ic_custo, "b1": b1, "bm": bm, "estado": "",
	}
	return cx

func _comprar(id: String, qtd: int) -> void:
	var arg = "max" if qtd < 0 else qtd
	var n: int = jogo.comprar_no(id, arg)
	if n <= 0:
		Bus.toast(Txt.f("prg_moeda_insuf", {"n": txt(Dados.no_por_id.get(id, {}), "nome")}), "ruim")
		return
	var r: Dictionary = cards[id]
	UI.pulsar(r["caixa"], r["cor"])
	UI.saltar(r["caixa"], 1.06)
	Bus.toast(Txt.f(("prg_toast_nivel" if n == 1 else "prg_toast_niveis"), {"nome": txt(r["def"], "nome"), "n": n}), "bom")
	atualizar()

# ================================================================== ritual

func _pedir(cam_id: String) -> void:
	var cam: Dictionary = _camada(cam_id)
	if not _liberada(cam):
		Bus.toast(Txt.f("prg_requisito_falta", {"r": txt(cam, "requisito")}), "info")
		return
	if not bool(Cfg.get_v("confirmar_prestigio", true)):
		_executar(cam_id)
		return
	var cor := Color.html(str(cam.get("cor", "#38bdf8")))
	_pendente = cam_id
	dlg_caixa.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL.lerp(cor.darkened(0.8), 0.35), 14, 2, cor.darkened(0.3)))
	dlg_titulo.text = "%s?" % txt(cam, "verbo")
	dlg_titulo.add_theme_color_override("font_color", cor)
	dlg_lore.text = txt(cam, "lore")
	dlg_ganho.text = Txt.f("prg_dlg_recebe", {"v": Fmt.big(_previa(cam_id)), "m": _nome_moeda(str(cam.get("moeda", "")))})
	dlg_ganho.add_theme_color_override("font_color", cor)
	dlg_perde.text = txt(cam, "resetaTexto")
	dlg_mantem.text = txt(cam, "mantemTexto")
	dlg_sim.text = txt(cam, "verbo").to_upper()
	dlg_sim.add_theme_stylebox_override("normal", UI.caixa(cor.darkened(0.6), 8, 2, cor.darkened(0.15)))
	dlg_sim.add_theme_stylebox_override("hover", UI.caixa(cor.darkened(0.38), 8, 2, Color.WHITE))
	dlg.visible = true
	UI.saltar(dlg, 1.05)

func _executar(cam_id: String) -> void:
	var cam: Dictionary = _camada(cam_id)
	var cor := Color.html(str(cam.get("cor", "#38bdf8")))
	var ganho := _previa(cam_id)
	var ok := false
	match cam_id:
		"ascensao": ok = bool(jogo.ascender())
		"singularidade": ok = bool(jogo.colapsar())
		"transcendencia": ok = bool(jogo.transcender())
	if not ok:
		Bus.toast(Txt.t("prg_ritual_falhou"), "ruim")
		return
	UI.pulsar(janela, cor)
	UI.saltar(janela, 1.05)
	Bus.toast("%s: +%s %s" % [txt(cam, "nome"), Fmt.big(ganho), _nome_moeda(str(cam.get("moeda", "")))], "epico")
	_reconstruir()

func _montar_dialogo() -> void:
	dlg = Control.new()
	dlg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dlg.visible = false
	add_child(dlg)

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.6)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	dlg.add_child(fundo)

	var cx := UI.painel(UI.PAINEL, 14)
	dlg_caixa = cx
	cx.anchor_left = 0.5
	cx.anchor_right = 0.5
	cx.anchor_top = 0.5
	cx.anchor_bottom = 0.5
	cx.offset_left = -260
	cx.offset_right = 260
	cx.offset_top = -168
	cx.offset_bottom = 168
	dlg.add_child(cx)

	var v := UI.vbox(8)
	cx.add_child(v)
	dlg_titulo = UI.rotulo("", 24, UI.ACENTO)
	v.add_child(dlg_titulo)
	dlg_lore = UI.rotulo("", 12, UI.TEXTO3)
	dlg_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_lore.custom_minimum_size.x = 470
	v.add_child(dlg_lore)
	v.add_child(UI.separador())
	dlg_ganho = UI.rotulo("", 18, UI.ACENTO)
	v.add_child(dlg_ganho)
	v.add_child(UI.rotulo(Txt.t("prg_dlg_desfaz"), 11, UI.TEXTO3))
	dlg_perde = UI.rotulo("", 13, UI.VERMELHO)
	dlg_perde.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_perde.custom_minimum_size.x = 470
	v.add_child(dlg_perde)
	v.add_child(UI.rotulo(Txt.t("prg_dlg_permanece"), 11, UI.TEXTO3))
	dlg_mantem = UI.rotulo("", 13, UI.VERDE)
	dlg_mantem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_mantem.custom_minimum_size.x = 470
	v.add_child(dlg_mantem)
	v.add_child(UI.espacador(0, false))

	var h := UI.hbox(8)
	v.add_child(h)
	var nao := UI.botao(Txt.t("prg_ainda_nao"), func(): dlg.visible = false)
	nao.custom_minimum_size = Vector2(150, 42)
	h.add_child(nao)
	h.add_child(UI.espacador())
	dlg_sim = UI.botao("", func():
		dlg.visible = false
		var alvo := _pendente
		_pendente = ""
		if alvo != "":
			_executar(alvo))
	dlg_sim.custom_minimum_size = Vector2(200, 42)
	dlg_sim.add_theme_font_size_override("font_size", 17)
	dlg_sim.add_theme_color_override("font_color", Color.WHITE)
	h.add_child(dlg_sim)

# ================================================================ atualizar

func atualizar() -> void:
	if jogo == null or chips.is_empty():
		return
	var moedas: Dictionary = jogo.s["moedas"]
	var pres: Dictionary = jogo.s["prestigio"]
	for chave in ["fragmentos", "nucleos", "eter"]:
		if chips.has(chave):
			chips[chave].text = Fmt.big(float(moedas[chave]))
	if chips.has("ascensoes"):
		chips["ascensoes"].text = Fmt.inteiro(int(pres["ascensoes"]))
	if chips.has("melhor"):
		chips["melhor"].text = Fmt.inteiro(int(jogo.s["onda_maxima_global"]))
	if chips.has("singularidades"):
		chips["singularidades"].text = Fmt.inteiro(int(pres["singularidades"]))
	if chips.has("transcendencias"):
		chips["transcendencias"].text = Fmt.inteiro(int(pres["transcendencias"]))

	_atualizar_destaque()
	_atualizar_arvore()

func _atualizar_destaque() -> void:
	if not refs.has("cam"):
		return
	var cam: Dictionary = refs["cam"]
	var cam_id := str(cam.get("id", ""))
	var moeda := str(cam.get("moeda", "fragmentos"))
	var liberada := _liberada(cam)

	for item in barras:
		var b: Dictionary = item
		var atual := _valor_requisito(str(b["chave"]))
		var alvo := float(b["alvo"])
		var pb: ProgressBar = b["barra"]
		pb.value = clampf(atual / maxf(1.0, alvo), 0.0, 1.0)
		var rot: Label = b["rotulo"]
		rot.text = "%s / %s" % [Fmt.inteiro(int(atual)), Fmt.inteiro(int(alvo))]

	if liberada and refs.has("ganho"):
		var ganho := _previa(cam_id)
		var lbl: Label = refs["ganho"]
		lbl.text = "+" + Fmt.big(ganho)
		var atual_moeda := float(jogo.s["moedas"][moeda])
		var mult: Label = refs["mult"]
		if Big.is_zero(atual_moeda):
			mult.text = Txt.f("prg_primeiro_punhado", {"m": _nome_moeda(moeda)})
		elif Big.is_zero(ganho):
			mult.text = Txt.t("prg_ganho_nulo")
		else:
			var razao := Big.div(Big.add(atual_moeda, ganho), atual_moeda)
			mult.text = Txt.f("prg_multiplica", {
				"x": Fmt.big(razao), "a": Fmt.big(atual_moeda), "b": Fmt.big(Big.add(atual_moeda, ganho))})

	var b_ritual: Button = refs["botao"]
	var sub: Label = refs["sub"]
	b_ritual.disabled = not liberada
	if liberada:
		b_ritual.text = txt(cam, "verbo").to_upper()
		sub.text = Txt.t("prg_recomeca")
	else:
		b_ritual.text = Txt.t("bloqueado").to_upper()
		sub.text = txt(cam, "requisito")

func _atualizar_arvore() -> void:
	if cards.is_empty():
		return
	var comprados := 0
	var total := 0
	for chave in cards.keys():
		var id := str(chave)
		var r: Dictionary = cards[id]
		var def: Dictionary = r["def"]
		var camada := str(r["chave"])
		var tabela: Dictionary = jogo.s["prestigio"][str(TABELA.get(camada, "arvore_fragmentos"))]
		var moeda := float(jogo.s["moedas"][camada])
		var nivel := int(tabela.get(id, 0))
		var maxn := int(def.get("max", -1))
		var no_teto := maxn >= 0 and nivel >= maxn
		total += 1
		if nivel > 0:
			comprados += 1

		var custo := Prestigio.custo_no(def, nivel)
		var pode := (not no_teto) and Big.gte(moeda, custo)
		var n_max := 0 if no_teto else Prestigio.max_compravel_no(def, nivel, moeda)

		var estado := "%d|%d|%d|%d" % [nivel, int(no_teto), int(pode), n_max]
		if str(r["estado"]) == estado:
			continue
		r["estado"] = estado

		var lbl_nivel: Label = r["nivel"]
		lbl_nivel.text = Txt.t("maximo") if no_teto else (Txt.f("prg_nv", {"n": nivel}) if maxn < 0 else Txt.f("prg_nv_de", {"n": nivel, "m": maxn}))
		lbl_nivel.add_theme_color_override("font_color", UI.OURO if no_teto else UI.TEXTO3)

		var agora: Label = r["agora"]
		agora.text = (Txt.t("atual") + ": " + _efeito(def, nivel)) if nivel > 0 else _desc(def)
		agora.add_theme_color_override("font_color", UI.VERDE if nivel > 0 else UI.TEXTO2)
		var prox: Label = r["prox"]
		prox.visible = not no_teto and not _so_desbloqueio(def)
		prox.text = Txt.t("proximo") + ": " + _efeito(def, nivel + 1)

		var lbl_custo: Label = r["custo"]
		var ic_custo: Control = r["ic_custo"]
		var cor_moeda: Color = UI.MOEDA_COR.get(camada, UI.TEXTO)
		lbl_custo.text = "—" if no_teto else Fmt.big(custo)
		lbl_custo.add_theme_color_override("font_color", UI.TEXTO if pode else UI.TEXTO3)
		ic_custo.configurar(Icone.da_moeda(camada), cor_moeda if pode else UI.TEXTO3, 14)

		var b1: Button = r["b1"]
		var bm: Button = r["bm"]
		b1.disabled = not pode
		bm.disabled = n_max <= 0
		bm.text = Txt.t("prg_bt_max") if n_max <= 1 else Txt.f("prg_bt_max_n", {"n": n_max})
		b1.visible = not no_teto
		bm.visible = not no_teto

		var cor: Color = r["cor"]
		var cx: PanelContainer = r["caixa"]
		var cor_borda := UI.BORDA
		if no_teto:
			cor_borda = UI.OURO.darkened(0.25)
		elif pode:
			cor_borda = cor.darkened(0.1)
		elif nivel > 0:
			cor_borda = cor.darkened(0.55)
		var fundo := UI.PAINEL2.darkened(0.2)
		if nivel > 0:
			fundo = UI.PAINEL2.darkened(0.2).lerp(cor.darkened(0.72), 0.55)
		cx.add_theme_stylebox_override("panel", UI.caixa(fundo, 10, 1 if not pode else 2, cor_borda))
		var ic: Control = r["icone"]
		ic.configurar(_icone_no(id), UI.OURO if no_teto else (cor if nivel > 0 else cor.darkened(0.25)), 24)
		cx.tooltip_text = "%s\n%s\n\n%s" % [txt(def, "nome"), _desc(def),
			(Txt.t("prg_ja_maximo") if no_teto else Txt.f("prg_custo_proximo", {"c": Fmt.big(custo), "m": _nome_moeda(camada)}))]

	if refs.has("resumo_arvore"):
		refs["resumo_arvore"].text = Txt.f("prg_resumo_arvore", {"a": comprados, "b": total})

# =================================================================== textos

func _camada(id: String) -> Dictionary:
	for item in camadas:
		var cam: Dictionary = item
		if str(cam.get("id", "")) == id:
			return cam
	return {}

func _liberada(cam: Dictionary) -> bool:
	match str(cam.get("id", "")):
		"ascensao": return Prestigio.pode_ascender(jogo.s)
		"singularidade": return Prestigio.pode_colapsar(jogo.s)
		"transcendencia": return Prestigio.pode_transcender(jogo.s)
	return false

func _previa(cam_id: String) -> float:
	match cam_id:
		"ascensao": return Prestigio.previa_fragmentos(jogo)
		"singularidade": return Prestigio.previa_nucleos(jogo)
		"transcendencia": return Prestigio.previa_eter(jogo)
	return Big.ZERO

func _requisitos(cam_id: String) -> Array:
	match cam_id:
		"ascensao":
			return [{"rotulo": Txt.t("prg_req_onda_run"), "chave": "onda_run", "alvo": float(Bal.ASC_ONDA_MIN)}]
		"singularidade":
			return [
				{"rotulo": Txt.t("prg_req_onda_global"), "chave": "onda_global", "alvo": float(Bal.SING_ONDA_MIN)},
				{"rotulo": Txt.t("prg_req_ascensoes"), "chave": "ascensoes", "alvo": float(Bal.SING_ASC_MIN)},
			]
		"transcendencia":
			return [
				{"rotulo": Txt.t("prg_req_onda_global"), "chave": "onda_global", "alvo": float(Bal.TRANS_ONDA_MIN)},
				{"rotulo": Txt.t("prg_req_singularidades"), "chave": "singularidades", "alvo": float(Bal.TRANS_SING_MIN)},
			]
	return []

func _valor_requisito(chave: String) -> float:
	match chave:
		"onda_run": return float(jogo.s["onda_maxima"])
		"onda_global": return float(jogo.s["onda_maxima_global"])
		"ascensoes": return float(jogo.s["prestigio"]["ascensoes"])
		"singularidades": return float(jogo.s["prestigio"]["singularidades"])
	return 0.0

func _nome_moeda(chave: String) -> String:
	match chave:
		"fragmentos", "nucleos", "eter", "ouro", "gemas", "poeira":
			return Txt.t("m_" + chave)
	return chave

## Descrição do nó, com {v} trocado pelo valor real.
func _desc(def: Dictionary) -> String:
	var d := txt(def, "desc")
	if not d.contains("{v}"):
		return d
	var v := 0.0
	for item in def.get("efeito", []):
		var ef: Dictionary = item
		var valor = ef.get("valor", 0)
		if valor is float or valor is int:
			v = float(valor)
			break
	return d.replace("{v}", "+" + Fmt.num(v, 2))

## Nó que só abre uma porta: a descrição já diz tudo, o "próximo" seria eco.
func _so_desbloqueio(def: Dictionary) -> bool:
	var efeitos: Array = def.get("efeito", [])
	if efeitos.is_empty():
		return false
	for item in efeitos:
		var ef: Dictionary = item
		if str(ef.get("especial", "")) != "desbloqueio" and not (ef.get("valor", 0) is String):
			return false
	return true

func _efeito(def: Dictionary, nivel: int) -> String:
	if nivel <= 0:
		return "—"
	var partes: Array = []
	for item in def.get("efeito", []):
		var ef: Dictionary = item
		if ef.has("especial"):
			partes.append(_efeito_especial(ef, nivel))
			continue
		if not ef.has("stat"):
			continue
		var sd: Dictionary = Dados.stat_defs.get(str(ef["stat"]), {})
		var nome := txt(sd, "nome")
		if nome == "":
			nome = str(ef["stat"])
		var v := float(ef.get("valor", 0.0))
		var pct_stat := str(sd.get("tipo", "")) == "pct"
		match str(ef.get("tipo", "flat")):
			"flat":
				var tot := v * float(nivel)
				partes.append("%s +%s" % [nome, Fmt.pct(tot) if pct_stat else Fmt.num(tot, 2)])
			"pct": partes.append("%s +%s" % [nome, Fmt.pct(v * float(nivel))])
			"mult": partes.append("%s ×%s" % [nome, Fmt.big(Big.pow_n(Big.from(v), float(nivel)))])
	return "  ·  ".join(partes) if not partes.is_empty() else "—"

func _efeito_especial(ef: Dictionary, nivel: int) -> String:
	var chave := str(ef.get("especial", ""))
	var v = ef.get("valor", 0)
	if chave == "desbloqueio" or v is String:
		return Txt.f("prg_desbloqueia", {"v": _nome_desbloqueio(str(v))})
	var f := float(v)
	match chave:
		"hpInimigo":
			return Txt.f("prg_esp_hp_inimigo", {"v": Fmt.num(pow(f, float(nivel)), 3)})
		"ganhoNucleos":
			return Txt.f("prg_esp_ganho_nucleos", {"v": Fmt.num(pow(f, float(nivel)), 2)})
		"offlineEficiencia", "comboBonus":
			return "%s +%s" % [_nome_especial(chave), Fmt.pct(f * float(nivel))]
	return "%s +%s" % [_nome_especial(chave), Fmt.num(f * float(nivel), 2)]

func _nome_especial(chave: String) -> String:
	match chave:
		"ondaInicial": return Txt.t("prg_esp_onda_inicial")
		"slotsCartas": return Txt.t("prg_esp_slots_cartas")
		"pontosTalento": return Txt.t("pontos_talento")
		"offlineHoras": return Txt.t("prg_esp_offline_horas")
		"offlineEficiencia": return Txt.t("prg_esp_offline_eficiencia")
		"comboTeto": return Txt.t("prg_esp_combo_teto")
		"comboBonus": return Txt.t("prg_esp_combo_bonus")
		"velocidadeMax": return Txt.t("prg_esp_velocidade_max")
		"slotsHabilidade": return Txt.t("prg_esp_slots_habilidade")
		"revives": return Txt.t("prg_esp_revives")
		"rerolls": return Txt.t("prg_esp_rerolls")
	return chave

func _nome_desbloqueio(chave: String) -> String:
	match chave:
		"autoCompra": return Txt.t("prg_desb_auto_compra")
		"autoHabilidade": return Txt.t("prg_desb_auto_habilidade")
		"modoFarm": return Txt.t("prg_desb_modo_farm")
		"autoAscensao": return Txt.t("prg_desb_auto_ascensao")
		"desafios": return Txt.t("prg_desb_desafios")
		"offlinePerfeito": return Txt.t("prg_desb_offline_perfeito")
		"modoInfinito": return Txt.t("prg_desb_modo_infinito")
	return chave

## A fonte não tem emoji: cada nó vira um ícone vetorial.
func _icone_no(id: String) -> String:
	match id:
		"af_dano", "an_dano": return "espada"
		"af_ouro": return "ouro"
		"an_ouro": return "gema"
		"af_vida": return "coracao"
		"af_regen": return "cura"
		"af_inicio", "an_onda": return "foguete"
		"af_xp": return "livro"
		"af_crit": return "raio"
		"af_frag", "an_frag": return "fragmento"
		"af_drop", "an_lendario": return "estrela"
		"af_slots", "an_slot": return "carta"
		"af_offline", "an_offline", "ae_eternidade": return "ampulheta"
		"af_orbe": return "orbe"
		"af_auto_compra": return "engrenagem"
		"af_auto_hab", "ae_onipresenca": return "nova"
		"af_farm": return "alvo"
		"af_velocidade", "an_turbo": return "velocidade"
		"af_combo": return "balanca"
		"af_talento", "an_talento": return "arvore"
		"an_auto_asc": return "prestigio"
		"an_desafios": return "desafio"
		"an_nucleo": return "nucleo"
		"ae_dano": return "eter"
		"ae_tudo": return "ouro"
		"ae_realidade": return "livro"
		"ae_infinito": return "vazio"
	return "reliquia"
