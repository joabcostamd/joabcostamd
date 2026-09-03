extends "res://scripts/ui/panel_base.gd"

## Painel de CARTAS — os módulos que a torre carrega presos ao casco.
##
## Topo: os slots equipados, desenhados como cartas grandes.
## Baixo: o inventário em grade rolável, ordenável, com selo NOVO.
## Direita: o detalhe da carta selecionada e o quadro de conjuntos.
##
## Toda a arte é vetorial: a classe `ArteCarta`, no fim do arquivo, desenha
## moldura, brilho de raridade e uma silhueta própria para cada `forma`.

const LARG_ESQ := 806.0
const CARTA_W := 104.0
const CARTA_H := 140.0
const SLOT_H := 188.0
const COLUNAS := 7

var lbl_poeira: Label
var lbl_slots: Label
var lbl_inv: Label
var caixa_slots: HBoxContainer
var grade: GridContainer
var lbl_grade_vazia: Label
var detalhe: VBoxContainer
var acoes: VBoxContainer
var caixa_detalhe: PanelContainer
var caixa_conj_painel: PanelContainer
var aba_dir := "detalhe"
var botoes_aba: Array = []
var caixa_conjuntos: VBoxContainer

var ordem := "raridade"
var botoes_ordem: Array = []
var sel_uid := ""
var slots := 3
var assinatura := ""
var selos: Dictionary = {}        # uid -> Control (selo NOVO)
var artes: Dictionary = {}        # uid -> Array[ArteCarta]
var conjuntos_ui: Array = []      # [{def, caixa, nome, contagem, pecas, bonus}]
var botoes_detalhe: Array = []    # [{botao, tipo, custo}]
var overlay: Control

func configurar() -> void:
	titulo_texto = Txt.t("p_cartas")
	titulo_icone = "carta"
	largura = 1170.0
	altura = 690.0
	intervalo = 0.25

# ------------------------------------------------------------------ montagem

func montar(c: VBoxContainer) -> void:
	slots = _slots()

	# ---- barra superior ----
	var topo := UI.hbox(8)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	topo.add_child(ic)
	ic.configurar("poeira", UI.MOEDA_COR["poeira"], 20)
	lbl_poeira = UI.rotulo("0", 18, UI.MOEDA_COR["poeira"])
	lbl_poeira.tooltip_text = Txt.t("car_dica_poeira")
	topo.add_child(lbl_poeira)
	topo.add_child(UI.rotulo(Txt.t("m_poeira"), 13, UI.TEXTO3))
	topo.add_child(UI.espacador())
	lbl_slots = UI.rotulo("", 14, UI.TEXTO2)
	lbl_slots.tooltip_text = Txt.t("car_dica_slots")
	topo.add_child(lbl_slots)
	c.add_child(topo)

	# ---- corpo em duas colunas ----
	var principal := UI.hbox(14)
	principal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_child(principal)

	var esq := UI.vbox(8)
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esq.custom_minimum_size.x = LARG_ESQ
	principal.add_child(esq)

	var dir := UI.vbox(8)
	dir.custom_minimum_size.x = 306
	principal.add_child(dir)

	# --- equipadas ---
	esq.add_child(_secao(Txt.t("car_equipadas"), "escudo", Txt.t("car_dica_equipadas")))
	caixa_slots = UI.hbox(8)
	esq.add_child(caixa_slots)

	esq.add_child(UI.separador())

	# --- cabeçalho do inventário ---
	var linha_inv := UI.hbox(8)
	lbl_inv = UI.rotulo(Txt.t("car_inventario"), 15, UI.TEXTO2)
	linha_inv.add_child(lbl_inv)
	linha_inv.add_child(UI.espacador())
	linha_inv.add_child(UI.rotulo(Txt.t("car_ordenar_por"), 12, UI.TEXTO3))
	for par in [["raridade", Txt.t("car_ord_raridade")], ["nivel", Txt.t("nivel")], ["nome", Txt.t("car_ord_nome")]]:
		var chave := str(par[0])
		var b := UI.botao(str(par[1]), func(): _definir_ordem(chave))
		b.toggle_mode = true
		b.button_pressed = chave == ordem
		b.custom_minimum_size = Vector2(84, 30)
		b.add_theme_font_size_override("font_size", 13)
		linha_inv.add_child(b)
		botoes_ordem.append({"botao": b, "chave": chave})
	esq.add_child(linha_inv)

	# --- grade ---
	var rolagem := UI.scroll()
	esq.add_child(rolagem)
	var caixa_grade := UI.vbox(8)
	caixa_grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(caixa_grade)
	grade = GridContainer.new()
	grade.columns = COLUNAS
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	caixa_grade.add_child(grade)
	lbl_grade_vazia = UI.rotulo(Txt.t("car_grade_vazia"), 13, UI.TEXTO3)
	lbl_grade_vazia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_grade_vazia.custom_minimum_size.x = LARG_ESQ - 20.0
	caixa_grade.add_child(lbl_grade_vazia)

	# --- alternador: detalhe da carta ou quadro de conjuntos ---
	var abas := UI.hbox(6)
	dir.add_child(abas)
	for par2 in [["detalhe", Txt.t("car_aba_detalhe")], ["conjuntos", Txt.t("car_aba_conjuntos")]]:
		var chave2 := str(par2[0])
		var ba := UI.botao(str(par2[1]), func(): _definir_aba(chave2))
		ba.toggle_mode = true
		ba.button_pressed = chave2 == aba_dir
		ba.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ba.custom_minimum_size.y = 30
		abas.add_child(ba)
		botoes_aba.append({"botao": ba, "chave": chave2})

	# --- detalhe (rola) + ações (sempre à vista) ---
	var pd := UI.painel(UI.PAINEL2.darkened(0.18), 12)
	pd.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dir.add_child(pd)
	caixa_detalhe = pd
	var pv := UI.vbox(6)
	pd.add_child(pv)
	var sc := UI.scroll()
	pv.add_child(sc)
	detalhe = UI.vbox(5)
	detalhe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(detalhe)
	acoes = UI.vbox(4)
	acoes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_child(acoes)

	# --- conjuntos ---
	var pc := UI.painel(UI.PAINEL2.darkened(0.18), 12)
	pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pc.tooltip_text = Txt.t("car_dica_conjuntos")
	dir.add_child(pc)
	caixa_conj_painel = pc
	var sc2 := UI.scroll()
	pc.add_child(sc2)
	caixa_conjuntos = UI.vbox(6)
	caixa_conjuntos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.add_child(caixa_conjuntos)
	_montar_conjuntos()
	_definir_aba(aba_dir)

	_reconstruir()

func _definir_aba(chave: String) -> void:
	aba_dir = chave
	for b in botoes_aba:
		b["botao"].button_pressed = str(b["chave"]) == chave
	if caixa_detalhe != null:
		caixa_detalhe.visible = chave == "detalhe"
	if caixa_conj_painel != null:
		caixa_conj_painel.visible = chave == "conjuntos"

func _secao(texto: String, icone: String, dica: String) -> HBoxContainer:
	var h := UI.hbox(6)
	h.tooltip_text = dica
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(icone, UI.ACENTO, 16)
	h.add_child(UI.rotulo(texto, 15, UI.TEXTO2))
	return h

# --------------------------------------------------------------- estado curto

func _slots() -> int:
	return clampi(int(jogo.esp.get("slotsCartas", 3)), 1, 8)

func _inv() -> Array:
	return jogo.s["cartas"]["inventario"]

func _equipadas() -> Array:
	var e: Array = jogo.s["cartas"]["equipadas"]
	while e.size() < slots:
		e.append("")
	return e

func _novas() -> Array:
	return jogo.s["cartas"]["novas"]

func _achar(uid: String) -> Dictionary:
	if uid == "":
		return {}
	for item in _inv():
		var c: Dictionary = item
		if str(c["uid"]) == uid:
			return c
	return {}

func _slot_de(uid: String) -> int:
	var eq := _equipadas()
	for i in eq.size():
		if str(eq[i]) == uid:
			return i
	return -1

func _def_de(inst: Dictionary) -> Dictionary:
	return Dados.carta_por_id.get(str(inst.get("id", "")), {})

func _ordem_rar(r: String) -> int:
	for i in Dados.raridades.size():
		var d: Dictionary = Dados.raridades[i]
		if str(d.get("id", "")) == r:
			return i
	return 0

func _nome_carta(inst: Dictionary) -> String:
	return txt(_def_de(inst), "nome")

func _nome_rar(r: String) -> String:
	return txt(Dados.raridade(r), "nome")

func _cor_carta(def: Dictionary) -> Color:
	return Ux.hex(str(def.get("cor", "#93a3c4")))

func _assinatura() -> String:
	var p := PackedStringArray()
	p.append(ordem)
	p.append(str(slots))
	for item in _inv():
		var c: Dictionary = item
		p.append("%s.%s.%d" % [str(c["uid"]), str(c["raridade"]), int(c["nivel"])])
	p.append("=")
	for uid in _equipadas():
		p.append(str(uid))
	return "|".join(p)

# ------------------------------------------------------------ reconstrução

func _definir_ordem(chave: String) -> void:
	ordem = chave
	for b in botoes_ordem:
		b["botao"].button_pressed = str(b["chave"]) == chave
	_reconstruir()

func _comparar(a, b) -> bool:
	var ca: Dictionary = a
	var cb: Dictionary = b
	var ra := _ordem_rar(str(ca["raridade"]))
	var rb := _ordem_rar(str(cb["raridade"]))
	var na := int(ca["nivel"])
	var nb := int(cb["nivel"])
	var ta := _nome_carta(ca)
	var tb := _nome_carta(cb)
	match ordem:
		"nivel":
			if na != nb:
				return na > nb
			if ra != rb:
				return ra > rb
		"nome":
			if ta != tb:
				return ta.naturalnocasecmp_to(tb) < 0
		_:
			if ra != rb:
				return ra > rb
			if na != nb:
				return na > nb
	if ta != tb:
		return ta.naturalnocasecmp_to(tb) < 0
	return int(ca["uid"]) < int(cb["uid"])

func _reconstruir() -> void:
	slots = _slots()
	selos.clear()
	artes.clear()
	for n in caixa_slots.get_children():
		caixa_slots.remove_child(n)
		n.queue_free()
	for n in grade.get_children():
		grade.remove_child(n)
		n.queue_free()

	# ---- slots equipados ----
	var eq := _equipadas()
	var w := clampf((LARG_ESQ - 8.0 * float(slots - 1)) / float(slots), 76.0, 150.0)
	for i in slots:
		var uid := str(eq[i])
		var inst := _achar(uid)
		if inst.is_empty():
			caixa_slots.add_child(_widget_vazio(i, w, SLOT_H))
		else:
			caixa_slots.add_child(_widget_carta(inst, w, SLOT_H, true))

	# ---- inventário ----
	var lista: Array = _inv().duplicate()
	lista.sort_custom(_comparar)
	for item in lista:
		var inst2: Dictionary = item
		grade.add_child(_widget_carta(inst2, CARTA_W, CARTA_H, false))
	lbl_grade_vazia.visible = lista.is_empty()

	if sel_uid != "" and _achar(sel_uid).is_empty():
		sel_uid = ""
	assinatura = _assinatura()
	_atualizar_selos()
	_atualizar_selecao()
	_mostrar_detalhe()
	atualizar()

# ------------------------------------------------------------------ widgets

func _base_botao(w: float, h: float) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for est in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(est, UI.caixa_vazia())
	return b

func _widget_carta(inst: Dictionary, w: float, h: float, grande: bool) -> Control:
	var uid := str(inst["uid"])
	var def := _def_de(inst)
	var raridade := str(inst["raridade"])
	var nivel := int(inst["nivel"])
	var rar_def := Dados.raridade(raridade)
	var cor := _cor_carta(def)
	var cor_rar := UI.cor_raridade(raridade)
	var slot := _slot_de(uid)

	var b := _base_botao(w, h)
	b.tooltip_text = "%s\n%s · %s %d/%d\n%s%s" % [
		txt(def, "nome"), _nome_rar(raridade), Txt.t("nivel"), nivel, Dados.nivel_max_carta,
		txt(def, "desc"),
		"\n" + Txt.f("car_equipada_slot_par", {"n": slot + 1}) if slot >= 0 else ""]
	b.pressed.connect(func(): _selecionar(uid))

	var arte := ArteCarta.new()
	b.add_child(arte)
	arte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arte.configurar(str(def.get("forma", "lasca")), cor, cor_rar, float(rar_def.get("brilho", 0.0)))
	arte.equipada = slot >= 0
	arte.animar = grande or float(rar_def.get("brilho", 0.0)) >= 0.7
	if not artes.has(uid):
		artes[uid] = []
	artes[uid].append(arte)
	b.mouse_entered.connect(func():
		arte.hover = true
		arte.queue_redraw())
	b.mouse_exited.connect(func():
		arte.hover = false
		arte.queue_redraw())

	var v := UI.vbox(0)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6.0
	v.offset_right = -6.0
	v.offset_top = 5.0
	v.offset_bottom = -6.0
	v.add_child(UI.espacador(0, false))
	var ln := UI.rotulo(txt(def, "nome"), 12 if grande else 10, UI.ACENTO if slot >= 0 else UI.TEXTO)
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ln.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ln.custom_minimum_size.x = w - 14.0
	v.add_child(ln)
	var lr := UI.hbox(4)
	lr.add_child(UI.rotulo(_nome_rar(raridade), 10, cor_rar))
	lr.add_child(UI.espacador())
	lr.add_child(UI.rotulo("%s %d" % [Txt.t("car_nv_abrev"), nivel], 10, UI.TEXTO2))
	v.add_child(lr)
	_ignorar_mouse(v)

	if _novas().has(uid):
		var selo := UI.painel(UI.VERDE.darkened(0.62), 5)
		selo.add_theme_stylebox_override("panel", UI.caixa(UI.VERDE.darkened(0.6), 5, 1, UI.VERDE))
		var ls := UI.rotulo(Txt.t("novo"), 9, UI.VERDE)
		selo.add_child(ls)
		b.add_child(selo)
		selo.position = Vector2(5, 5)
		_ignorar_mouse(selo)
		selos[uid] = selo
	return b

func _widget_vazio(slot: int, w: float, h: float) -> Control:
	var b := _base_botao(w, h)
	b.tooltip_text = Txt.f("car_dica_slot_vazio", {"n": slot + 1})
	b.pressed.connect(func(): _clicar_vazio(slot))
	var arte := ArteCarta.new()
	b.add_child(arte)
	arte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arte.configurar("vazio", UI.TEXTO3, UI.BORDA_FORTE, 0.0)
	arte.vazia = true
	var v := UI.vbox(2)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 6.0
	v.offset_bottom = -8.0
	v.alignment = BoxContainer.ALIGNMENT_END
	var l := UI.rotulo(Txt.t("vazio"), 12, UI.TEXTO3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var l2 := UI.rotulo(Txt.f("car_slot_n", {"n": slot + 1}), 10, UI.TEXTO3.darkened(0.15))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l2)
	_ignorar_mouse(v)
	return b

func _ignorar_mouse(no: Node) -> void:
	if no is Control:
		(no as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for f in no.get_children():
		_ignorar_mouse(f)

# ------------------------------------------------------------------ detalhe

func _selecionar(uid: String) -> void:
	sel_uid = uid
	var novas := _novas()
	if novas.has(uid):
		novas.erase(uid)
		jogo.marcar_sujo()
	_atualizar_selos()
	_atualizar_selecao()
	_mostrar_detalhe()
	_definir_aba("detalhe")

func _clicar_vazio(slot: int) -> void:
	var inst := _achar(sel_uid)
	if inst.is_empty():
		Bus.toast(Txt.t("car_toast_escolha"), "info")
		return
	_equipar(sel_uid, slot)

func _atualizar_selecao() -> void:
	for uid in artes.keys():
		for a in artes[uid]:
			var arte: ArteCarta = a
			var sel := str(uid) == sel_uid
			if arte.selecionada != sel:
				arte.selecionada = sel
				arte.queue_redraw()

func _atualizar_selos() -> void:
	var novas := _novas()
	for uid in selos.keys():
		var s: Control = selos[uid]
		if is_instance_valid(s):
			s.visible = novas.has(uid)

func _mostrar_detalhe() -> void:
	botoes_detalhe.clear()
	for n in detalhe.get_children():
		detalhe.remove_child(n)
		n.queue_free()
	for n in acoes.get_children():
		acoes.remove_child(n)
		n.queue_free()

	var inst := _achar(sel_uid)
	if inst.is_empty():
		var l := UI.rotulo(Txt.t("car_sel_vazia"), 13, UI.TEXTO2)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 244
		detalhe.add_child(l)
		var l2 := UI.rotulo(Txt.t("car_sel_vazia_lore"), 12, UI.TEXTO3)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l2.custom_minimum_size.x = 244
		detalhe.add_child(l2)
		return

	var def := _def_de(inst)
	var raridade := str(inst["raridade"])
	var nivel := int(inst["nivel"])
	var cor_rar := UI.cor_raridade(raridade)
	var rar_def := Dados.raridade(raridade)
	var slot := _slot_de(sel_uid)

	# --- retrato ---
	var cab := UI.hbox(10)
	var moldura := ArteCarta.new()
	moldura.custom_minimum_size = Vector2(96, 128)
	cab.add_child(moldura)
	moldura.configurar(str(def.get("forma", "lasca")), _cor_carta(def), cor_rar, float(rar_def.get("brilho", 0.0)))
	moldura.animar = true
	moldura.equipada = slot >= 0
	var vt := UI.vbox(3)
	vt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(vt)
	var ln := UI.rotulo(txt(def, "nome"), 15, cor_rar)
	ln.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ln.custom_minimum_size.x = 148
	vt.add_child(ln)
	vt.add_child(UI.rotulo("%s · %s %d/%d" % [_nome_rar(raridade), Txt.t("car_nv_abrev"), nivel, Dados.nivel_max_carta], 12, UI.TEXTO2))
	if slot >= 0:
		vt.add_child(UI.rotulo(Txt.f("car_equipada_slot", {"n": slot + 1}), 11, UI.ACENTO))
	detalhe.add_child(cab)

	var ld := UI.rotulo(txt(def, "desc"), 11, UI.TEXTO3)
	ld.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ld.custom_minimum_size.x = 244
	detalhe.add_child(ld)
	detalhe.add_child(UI.separador())

	# --- efeitos ---
	detalhe.add_child(UI.rotulo(Txt.t("car_efeitos_titulo"), 12, UI.TEXTO2))
	var efeitos := _efeitos_carta(def, raridade, nivel)
	if efeitos.is_empty():
		detalhe.add_child(UI.rotulo(Txt.t("car_sem_efeitos"), 12, UI.TEXTO3))
	for e in efeitos:
		var ef: Dictionary = e
		var l3 := UI.rotulo("· " + str(ef["texto"]), 12, ef["cor"])
		l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l3.custom_minimum_size.x = 244
		detalhe.add_child(l3)
	if nivel < Dados.nivel_max_carta:
		var prev := _efeitos_carta(def, raridade, nivel + 1)
		if not prev.is_empty():
			var lp := UI.rotulo(Txt.f("car_no_nivel", {"n": nivel + 1, "t": str(prev[0]["texto"])}), 11, UI.TEXTO3)
			lp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lp.custom_minimum_size.x = 244
			detalhe.add_child(lp)

	# --- conjunto ---
	var conj := _conjunto_de(str(def.get("id", "")))
	if not conj.is_empty():
		detalhe.add_child(UI.separador())
		var cor_c := Ux.hex(str(conj.get("cor", "#38bdf8")))
		var pecas: Array = conj.get("cartas", [])
		var equipadas_ids := _ids_equipados()
		var faltam := 0
		for cid in pecas:
			if not equipadas_ids.has(str(cid)):
				faltam += 1
		detalhe.add_child(UI.rotulo(Txt.t("car_conjunto") + ": " + txt(conj, "nome"), 12, cor_c))
		var lc := UI.rotulo(
			Txt.t("car_conj_completo") if faltam == 0 else Txt.f("car_conj_faltam", {"n": faltam}),
			11, UI.VERDE if faltam == 0 else UI.TEXTO3)
		lc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lc.custom_minimum_size.x = 244
		detalhe.add_child(lc)

	# --- sinergia ---
	var sin := str(def.get("sinergia", ""))
	if sin != "":
		var alvo: Dictionary = Dados.carta_por_id.get(sin, {})
		if not alvo.is_empty():
			var junto := _ids_equipados().has(sin)
			var marca_eq := " " + Txt.t("car_equipada_par") if junto else ""
			var lsin := UI.rotulo(Txt.f("car_sinergia", {"nome": txt(alvo, "nome")}) + marca_eq,
				11, UI.ACENTO2 if junto else UI.TEXTO3)
			lsin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lsin.custom_minimum_size.x = 244
			lsin.tooltip_text = Txt.t("car_dica_sinergia")
			detalhe.add_child(lsin)

	# --- ações ---
	if slot >= 0:
		var bd := UI.botao(Txt.t("car_desequipar"), func(): _desequipar(slot), Txt.f("car_dica_desequipar", {"n": slot + 1}))
		bd.custom_minimum_size.y = 34
		acoes.add_child(bd)
	else:
		acoes.add_child(UI.rotulo(Txt.t("car_equipar_no_slot"), 12, UI.TEXTO2))
		var hs := UI.hbox(4)
		for i in slots:
			var idx := i
			var ocupante := _achar(str(_equipadas()[i]))
			var bs := UI.botao(str(i + 1), func(): _equipar(sel_uid, idx))
			bs.custom_minimum_size = Vector2(38, 32)
			bs.tooltip_text = Txt.f("car_slot_livre", {"n": i + 1}) if ocupante.is_empty() else Txt.f("car_slot_troca", {"n": i + 1, "nome": _nome_carta(ocupante)})
			hs.add_child(bs)
		hs.add_child(UI.espacador())
		acoes.add_child(hs)

	var no_teto := nivel >= Dados.nivel_max_carta
	var custo := Saque.custo_fusao(nivel)
	var bf := UI.botao("", func(): _fundir(sel_uid))
	bf.custom_minimum_size.y = 34
	bf.disabled = no_teto
	bf.text = Txt.t("car_nivel_maximo") if no_teto else Txt.f("car_fundir_custo", {"n": Fmt.num(custo, 0)})
	bf.tooltip_text = Txt.t("car_dica_fundir")
	acoes.add_child(bf)
	botoes_detalhe.append({"botao": bf, "tipo": "fundir", "custo": custo, "teto": no_teto})

	var ganho := Saque.poeira_de(raridade, nivel)
	var br := UI.botao(Txt.f("car_reciclar_ganho", {"n": Fmt.num(ganho, 0)}), func(): _reciclar(sel_uid))
	br.custom_minimum_size.y = 32
	br.disabled = slot >= 0
	br.tooltip_text = Txt.t("car_dica_reciclar") if slot < 0 else Txt.t("car_dica_reciclar_equipada")
	br.add_theme_color_override("font_color", UI.VERMELHO.lerp(UI.TEXTO, 0.35))
	acoes.add_child(br)
	botoes_detalhe.append({"botao": br, "tipo": "reciclar", "custo": 0.0, "teto": false})

func _ids_equipados() -> Array:
	var ids: Array = []
	for uid in _equipadas():
		var inst := _achar(str(uid))
		if not inst.is_empty():
			ids.append(str(inst["id"]))
	return ids

func _conjunto_de(id_carta: String) -> Dictionary:
	for item in Dados.conjuntos:
		var conj: Dictionary = item
		if conj.get("cartas", []).has(id_carta):
			return conj
	return {}

# ------------------------------------------------------------------ efeitos

func _nome_stat(chave: String) -> String:
	var sd: Dictionary = Dados.stat_defs.get(chave, {})
	if sd.is_empty():
		return chave
	return txt(sd, "nome")

func _n(v: float, casas: int = 2) -> String:
	if v < 0.0:
		return "-" + Fmt.num(-v, casas)
	return Fmt.num(v, casas)

## Lista de {texto, cor} com o efeito já escalado por raridade e nível.
func _efeitos_carta(def: Dictionary, raridade: String, nivel: int) -> Array:
	var out: Array = []
	var rar: Dictionary = Dados.raridade(raridade)
	var mult := float(rar.get("mult", 1.0))
	var escala := 1.0 + 0.25 * float(nivel - 1)
	for item in def.get("efeito", []):
		if not (item is Dictionary):
			continue
		var ef: Dictionary = item
		if not ef.has("stat"):
			continue
		var v := float(ef.get("valor", 0.0)) * mult * escala
		var nome := _nome_stat(str(ef["stat"]))
		var cor := UI.VERDE if v >= 0.0 else UI.VERMELHO
		var texto := ""
		match str(ef.get("tipo", "flat")):
			"pct":
				texto = "%s %s%s" % [nome, "+" if v >= 0.0 else "", Fmt.pct(v)]
			"mult":
				if v <= 0.0:
					texto = Txt.f("car_ef_anulado", {"nome": nome})
					cor = UI.VERMELHO
				else:
					texto = "%s ×%s" % [nome, _n(v, 2)]
					cor = UI.VERDE if v >= 1.0 else UI.VERMELHO
			_:
				texto = "%s %s%s" % [nome, "+" if v >= 0.0 else "", _n(v, 3)]
		out.append({"texto": texto, "cor": cor})
	return out

func _texto_efeitos(efeitos: Array, n: int) -> String:
	var partes: Array = []
	for item in efeitos:
		if not (item is Dictionary):
			continue
		var ef: Dictionary = item
		if not ef.has("stat"):
			continue
		var nome := _nome_stat(str(ef["stat"]))
		var v := float(ef.get("valor", 0.0))
		match str(ef.get("tipo", "flat")):
			"pct":
				partes.append("%s +%s" % [nome, Fmt.pct(v * float(n))])
			"mult":
				partes.append("%s ×%s" % [nome, _n(pow(v, float(n)), 2)])
			_:
				partes.append("%s +%s" % [nome, _n(v * float(n), 3)])
	return " · ".join(partes)

# ------------------------------------------------------------------- ações

func _equipar(uid: String, slot: int) -> void:
	if Saque.equipar(jogo, uid, slot):
		jogo.recalcular()
		Bus.toast(Txt.f("car_toast_equipou", {"n": slot + 1}), "bom")
		_reconstruir()
		UI.saltar(caixa_slots, 1.03)
	else:
		Bus.toast(Txt.t("car_toast_falha_equipar"), "ruim")

func _desequipar(slot: int) -> void:
	Saque.desequipar(jogo, slot)
	jogo.recalcular()
	Bus.toast(Txt.f("car_toast_slot_livre", {"n": slot + 1}), "info")
	_reconstruir()

func _fundir(uid: String) -> void:
	var inst := _achar(uid)
	if inst.is_empty():
		return
	if int(inst["nivel"]) >= Dados.nivel_max_carta:
		Bus.toast(Txt.t("car_toast_no_teto"), "info")
		return
	if Saque.fundir(jogo, uid):
		jogo.recalcular()
		Bus.toast(Txt.f("car_toast_fusao", {"n": int(inst["nivel"])}), "epico")
		_reconstruir()
		UI.pulsar(detalhe, UI.ACENTO2)
	else:
		Bus.toast(Txt.t("car_poeira_insuficiente"), "ruim")

func _reciclar(uid: String) -> void:
	var inst := _achar(uid)
	if inst.is_empty():
		return
	var raridade := str(inst["raridade"])
	var ganho := Saque.poeira_de(raridade, int(inst["nivel"]))
	if _ordem_rar(raridade) >= 3:
		_confirmar(Txt.f("car_conf_titulo", {"nome": _nome_carta(inst)}),
			Txt.f("car_conf_texto", {
				"rar": _nome_rar(raridade), "n": int(inst["nivel"]), "p": Fmt.num(ganho, 0)}),
			func(): _fazer_reciclar(uid, ganho))
		return
	_fazer_reciclar(uid, ganho)

func _fazer_reciclar(uid: String, ganho: float) -> void:
	if Saque.reciclar(jogo, uid):
		if sel_uid == uid:
			sel_uid = ""
		Bus.toast(Txt.f("car_toast_poeira", {"n": Fmt.num(ganho, 0)}), "bom")
		_reconstruir()
		UI.pulsar(lbl_poeira, UI.MOEDA_COR["poeira"])
	else:
		Bus.toast(Txt.t("car_toast_esta_equipada"), "ruim")

func _confirmar(titulo: String, texto: String, ao_confirmar: Callable) -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.55)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(fundo)

	var cx := UI.painel(UI.PAINEL, 14)
	cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL, 14, 2, UI.VERMELHO.darkened(0.3)))
	cx.anchor_left = 0.5
	cx.anchor_right = 0.5
	cx.anchor_top = 0.5
	cx.anchor_bottom = 0.5
	cx.offset_left = -190
	cx.offset_right = 190
	cx.offset_top = -84
	cx.offset_bottom = 84
	overlay.add_child(cx)
	var v := UI.vbox(8)
	cx.add_child(v)
	v.add_child(UI.titulo(titulo, 17))
	var lt := UI.rotulo(texto, 12, UI.TEXTO2)
	lt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lt.custom_minimum_size.x = 340
	v.add_child(lt)
	v.add_child(UI.espacador(0, false))
	var h := UI.hbox(8)
	var bn := UI.botao(Txt.t("cancelar"), func(): _fechar_overlay())
	bn.custom_minimum_size = Vector2(120, 34)
	h.add_child(bn)
	h.add_child(UI.espacador())
	var bs := UI.botao(Txt.t("car_desmanchar"), func():
		_fechar_overlay()
		ao_confirmar.call())
	bs.custom_minimum_size = Vector2(140, 34)
	bs.add_theme_color_override("font_color", UI.VERMELHO)
	h.add_child(bs)
	v.add_child(h)
	UI.saltar(cx, 1.05)

func _fechar_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null

# ---------------------------------------------------------------- conjuntos

func _montar_conjuntos() -> void:
	conjuntos_ui.clear()
	for item in Dados.conjuntos:
		var conj: Dictionary = item
		var cor := Ux.hex(str(conj.get("cor", "#38bdf8")))
		var cx := UI.painel(UI.PAINEL.darkened(0.15), 10)
		cx.tooltip_text = txt(conj, "desc")
		var v := UI.vbox(2)
		cx.add_child(v)
		var h := UI.hbox(6)
		var ln := UI.rotulo(txt(conj, "nome"), 13, cor)
		h.add_child(ln)
		h.add_child(UI.espacador())
		var lc := UI.rotulo("0/3", 12, UI.TEXTO3)
		h.add_child(lc)
		v.add_child(h)
		var pecas: Array = []
		for cid in conj.get("cartas", []):
			var cdef: Dictionary = Dados.carta_por_id.get(str(cid), {})
			var lp := UI.rotulo("· " + txt(cdef, "nome"), 11, UI.TEXTO3)
			v.add_child(lp)
			pecas.append({"id": str(cid), "rotulo": lp})
		var lb := UI.rotulo(_texto_efeitos(conj.get("bonus", []), 1), 11, UI.TEXTO3)
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.custom_minimum_size.x = 244
		v.add_child(lb)
		caixa_conjuntos.add_child(cx)
		conjuntos_ui.append({"def": conj, "caixa": cx, "nome": ln, "contagem": lc, "pecas": pecas, "bonus": lb, "cor": cor, "completo": false})

func _atualizar_conjuntos() -> void:
	var equipados := _ids_equipados()
	var possuidos: Array = []
	for item in _inv():
		var c: Dictionary = item
		possuidos.append(str(c["id"]))
	for reg in conjuntos_ui:
		var r: Dictionary = reg
		var cor: Color = r["cor"]
		var n := 0
		for p in r["pecas"]:
			var peca: Dictionary = p
			var lp: Label = peca["rotulo"]
			var pid := str(peca["id"])
			if equipados.has(pid):
				n += 1
				lp.add_theme_color_override("font_color", cor)
			elif possuidos.has(pid):
				lp.add_theme_color_override("font_color", UI.TEXTO2)
			else:
				lp.add_theme_color_override("font_color", UI.TEXTO3.darkened(0.2))
		var total: int = r["pecas"].size()
		var completo := n >= total and total > 0
		var lc: Label = r["contagem"]
		lc.text = "%d/%d" % [n, total]
		lc.add_theme_color_override("font_color", UI.VERDE if completo else UI.TEXTO3)
		var lb: Label = r["bonus"]
		lb.add_theme_color_override("font_color", UI.VERDE if completo else UI.TEXTO3)
		if bool(r["completo"]) != completo:
			r["completo"] = completo
			var cx: PanelContainer = r["caixa"]
			cx.add_theme_stylebox_override("panel", UI.caixa(
				UI.PAINEL2.lerp(cor, 0.18) if completo else UI.PAINEL.darkened(0.15), 10, 1,
				cor if completo else UI.BORDA))
			if completo:
				UI.pulsar(cx, cor)

# ---------------------------------------------------------------- atualizar

func atualizar() -> void:
	if jogo == null or lbl_poeira == null:
		return
	if _slots() != slots or _assinatura() != assinatura:
		_reconstruir()
		return
	lbl_poeira.text = Fmt.big(jogo.s["moedas"]["poeira"])
	var usados := 0
	for uid in _equipadas():
		if str(uid) != "" and not _achar(str(uid)).is_empty():
			usados += 1
	lbl_slots.text = Txt.f("car_slots_n", {"a": usados, "b": slots})
	var n_inv: int = _inv().size()
	var n_novas: int = _novas().size()
	var marca_novas := Txt.f("car_novas_n", {"n": n_novas}) if n_novas > 0 else ""
	lbl_inv.text = "%s  %d %s" % [Txt.t("car_inventario"), n_inv, marca_novas]
	_atualizar_selos()
	_atualizar_conjuntos()

	var poeira: float = jogo.s["moedas"]["poeira"]
	for item in botoes_detalhe:
		var reg: Dictionary = item
		var b: Button = reg["botao"]
		if not is_instance_valid(b):
			continue
		if str(reg["tipo"]) == "fundir":
			var pode := not bool(reg["teto"]) and Big.gte(poeira, Big.from(float(reg["custo"])))
			b.disabled = not pode
			b.add_theme_color_override("font_color", UI.ACENTO2 if pode else UI.TEXTO3)

# =============================================================================
# ARTE — a carta desenhada à mão, sem imagem nenhuma.
# =============================================================================

class ArteCarta extends Control:
	var forma := "lasca"
	var cor := Color.WHITE
	var cor_rar := Color.WHITE
	var brilho := 0.0
	var vazia := false
	var selecionada := false
	var equipada := false
	var hover := false
	var animar := false
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(animar)
		_t = randf() * 6.0

	func configurar(f: String, c: Color, cr: Color, b: float) -> void:
		forma = f
		cor = c
		cor_rar = cr
		brilho = b
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var rc := Rect2(Vector2.ZERO, size)
		if rc.size.x < 8.0 or rc.size.y < 8.0:
			return
		if vazia:
			_desenhar_vazia(rc)
			return
		var pulso := 0.5 + 0.5 * sin(_t * 2.0)
		var raio := 10.0

		# halo de raridade
		if brilho > 0.01:
			var g := clampf(brilho, 0.0, 1.4)
			for i in 3:
				var e := 1.5 + float(i) * 2.5
				_contorno(self, _rrect(rc.grow(e), raio + e),
					Color(cor_rar.r, cor_rar.g, cor_rar.b, (0.20 - float(i) * 0.055) * g * (0.65 + 0.35 * pulso)), 2.0)

		var pts := _rrect(rc, raio)
		var topo := UI.PAINEL2.lerp(cor_rar, 0.20 + 0.12 * clampf(brilho, 0.0, 1.4))
		if hover:
			topo = topo.lightened(0.10)
		_gradiente(self, pts, rc, topo, UI.FUNDO2.darkened(0.15))

		# vinheta do nicho onde mora a silhueta
		var cen := Vector2(rc.size.x * 0.5, rc.size.y * 0.40)
		var r_art := minf(rc.size.x, rc.size.y) * 0.30
		draw_circle(cen, r_art * 1.55, Color(cor.r, cor.g, cor.b, 0.10 + 0.06 * brilho))
		silhueta(self, forma, cen, r_art, cor, _t, UI.FUNDO2.darkened(0.15))

		# régua entre a arte e o texto
		draw_rect(Rect2(6.0, rc.size.y * 0.63, rc.size.x - 12.0, 1.0), Color(cor_rar.r, cor_rar.g, cor_rar.b, 0.35))

		# reflexo diagonal para lendário e acima
		if brilho >= 0.9:
			var f := fmod(_t * 0.35, 2.4) - 0.7
			var x := rc.size.x * f
			draw_line(Vector2(x, 0), Vector2(x + rc.size.y * 0.5, rc.size.y),
				Color(1, 1, 1, 0.07 * clampf(brilho, 0.0, 1.4)), 10.0)

		_contorno(self, pts, cor_rar.lightened(0.35) if hover else cor_rar, 2.0)
		if equipada:
			_pol(self, PackedVector2Array([
				Vector2(rc.size.x - 26.0, 2.0), Vector2(rc.size.x - 3.0, 2.0), Vector2(rc.size.x - 3.0, 25.0)]),
				UI.ACENTO)
		if selecionada:
			_contorno(self, _rrect(rc.grow(3.0), 13.0), UI.ACENTO, 2.0)

	func _desenhar_vazia(rc: Rect2) -> void:
		var pts := _rrect(rc.grow(-2.0), 10.0)
		var cor_l := UI.BORDA_FORTE.lerp(UI.TEXTO3, 0.3)
		_gradiente(self, _rrect(rc, 10.0), rc, UI.PAINEL.darkened(0.25), UI.FUNDO2.darkened(0.25))
		_tracejado(self, pts, cor_l, 7.0, 6.0, 2.0)
		var c := Vector2(rc.size.x * 0.5, rc.size.y * 0.40)
		var r := minf(rc.size.x, rc.size.y) * 0.16
		draw_arc(c, r, 0, TAU, 26, Color(cor_l.r, cor_l.g, cor_l.b, 0.5), 1.5, true)
		draw_line(c - Vector2(r * 0.5, 0), c + Vector2(r * 0.5, 0), cor_l, 2.0, true)
		draw_line(c - Vector2(0, r * 0.5), c + Vector2(0, r * 0.5), cor_l, 2.0, true)

	# ------------------------------------------------------------ primitivas

	static func _p(c: Vector2, r: float, x: float, y: float) -> Vector2:
		return c + Vector2(x, y) * r

	static func _pts(c: Vector2, r: float, lista: Array) -> PackedVector2Array:
		var v := PackedVector2Array()
		for item in lista:
			var p: Vector2 = item
			v.append(c + p * r)
		return v

	static func _pol(ci: CanvasItem, pts: PackedVector2Array, cor: Color) -> void:
		if pts.size() >= 3:
			ci.draw_colored_polygon(pts, cor)

	static func _contorno(ci: CanvasItem, pts: PackedVector2Array, cor: Color, largura: float) -> void:
		if pts.size() < 2:
			return
		var f := pts.duplicate()
		f.append(pts[0])
		ci.draw_polyline(f, cor, largura, true)

	static func _elipse(c: Vector2, rx: float, ry: float, n: int = 26) -> PackedVector2Array:
		var v := PackedVector2Array()
		for i in n:
			var a := float(i) / float(n) * TAU
			v.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return v

	static func _rrect(rc: Rect2, raio: float) -> PackedVector2Array:
		var r := minf(raio, minf(rc.size.x, rc.size.y) * 0.5)
		var v := PackedVector2Array()
		var cantos := [
			[Vector2(rc.position.x + r, rc.position.y + r), PI, PI * 1.5],
			[Vector2(rc.end.x - r, rc.position.y + r), PI * 1.5, TAU],
			[Vector2(rc.end.x - r, rc.end.y - r), 0.0, PI * 0.5],
			[Vector2(rc.position.x + r, rc.end.y - r), PI * 0.5, PI],
		]
		for item in cantos:
			var c: Vector2 = item[0]
			var a0: float = item[1]
			var a1: float = item[2]
			for i in 5:
				var a := lerpf(a0, a1, float(i) / 4.0)
				v.append(c + Vector2(cos(a), sin(a)) * r)
		return v

	static func _gradiente(ci: CanvasItem, pts: PackedVector2Array, rc: Rect2, topo: Color, base: Color) -> void:
		var cores := PackedColorArray()
		var h := maxf(1.0, rc.size.y)
		for p in pts:
			cores.append(topo.lerp(base, clampf((p.y - rc.position.y) / h, 0.0, 1.0)))
		ci.draw_polygon(pts, cores)

	static func _tracejado(ci: CanvasItem, pts: PackedVector2Array, cor: Color, traco: float, vao: float, largura: float) -> void:
		var n := pts.size()
		var resto := 0.0
		var aceso := true
		for i in n:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % n]
			var d := a.distance_to(b)
			var t := 0.0
			while t < d:
				var passo := maxf(0.5, (traco if aceso else vao) - resto)
				var fim := minf(d, t + passo)
				if aceso:
					ci.draw_line(a.lerp(b, t / d), a.lerp(b, fim / d), cor, largura, true)
				if fim - t >= passo:
					aceso = not aceso
					resto = 0.0
				else:
					resto += fim - t
				t = fim

	# -------------------------------------------------------------- silhuetas

	## Desenha a silhueta de uma `forma` num círculo de raio `r` centrado em `c`.
	static func silhueta(ci: CanvasItem, forma: String, c: Vector2, r: float, cor: Color, t: float, fundo: Color = Color(0, 0, 0, 1)) -> void:
		var clara := cor.lightened(0.45)
		var escura := cor.darkened(0.45)
		var brilho_b := Color(1, 1, 1, 0.55)
		match forma:
			"lasca":
				_pol(ci, _pts(c, r, [Vector2(-0.12, -1.0), Vector2(0.34, -0.42), Vector2(0.16, 0.02),
					Vector2(0.5, 0.38), Vector2(0.02, 1.0), Vector2(-0.3, 0.2), Vector2(-0.52, -0.3)]), cor)
				_pol(ci, _pts(c, r, [Vector2(-0.08, -0.76), Vector2(0.2, -0.3), Vector2(0.04, 0.04),
					Vector2(-0.2, -0.16)]), clara)
				ci.draw_line(_p(c, r, -0.52, -0.3), _p(c, r, -0.12, -1.0), brilho_b, 1.5, true)
			"runa":
				_pol(ci, _pts(c, r, [Vector2(-0.56, -0.86), Vector2(0.56, -0.86), Vector2(0.72, -0.36),
					Vector2(0.56, 0.94), Vector2(-0.56, 0.94), Vector2(-0.72, -0.36)]), escura)
				_contorno(ci, _pts(c, r, [Vector2(-0.56, -0.86), Vector2(0.56, -0.86), Vector2(0.72, -0.36),
					Vector2(0.56, 0.94), Vector2(-0.56, 0.94), Vector2(-0.72, -0.36)]), cor, 2.0)
				ci.draw_line(_p(c, r, 0.0, -0.6), _p(c, r, 0.0, 0.66), clara, 2.4, true)
				ci.draw_line(_p(c, r, 0.0, -0.2), _p(c, r, -0.34, -0.5), clara, 2.2, true)
				ci.draw_line(_p(c, r, 0.0, 0.16), _p(c, r, 0.34, -0.14), clara, 2.2, true)
				ci.draw_line(_p(c, r, -0.26, 0.66), _p(c, r, 0.26, 0.66), clara, 2.0, true)
			"circuito":
				for i in 3:
					var o := -0.34 + float(i) * 0.34
					ci.draw_line(_p(c, r, o, -0.6), _p(c, r, o, -0.98), cor, 2.0, true)
					ci.draw_line(_p(c, r, o, 0.6), _p(c, r, o, 0.98), cor, 2.0, true)
					ci.draw_line(_p(c, r, -0.6, o), _p(c, r, -0.98, o), cor, 2.0, true)
					ci.draw_line(_p(c, r, 0.6, o), _p(c, r, 0.98, o), cor, 2.0, true)
				var corpo := _pts(c, r, [Vector2(-0.62, -0.62), Vector2(0.62, -0.62), Vector2(0.62, 0.62), Vector2(-0.62, 0.62)])
				_pol(ci, corpo, escura)
				_contorno(ci, corpo, cor, 2.0)
				ci.draw_line(_p(c, r, -0.36, -0.3), _p(c, r, 0.06, -0.3), clara, 1.6, true)
				ci.draw_line(_p(c, r, 0.06, -0.3), _p(c, r, 0.06, 0.16), clara, 1.6, true)
				ci.draw_line(_p(c, r, 0.06, 0.16), _p(c, r, 0.4, 0.16), clara, 1.6, true)
				ci.draw_line(_p(c, r, -0.36, 0.36), _p(c, r, 0.26, 0.36), clara, 1.6, true)
				ci.draw_circle(_p(c, r, -0.36, -0.3), r * 0.08, clara)
				ci.draw_circle(_p(c, r, 0.4, 0.16), r * 0.08, clara)
				ci.draw_rect(Rect2(_p(c, r, -0.18, -0.12), Vector2(r * 0.36, r * 0.32)), cor)
			"cristal":
				var gema := _pts(c, r, [Vector2(0.0, -1.0), Vector2(0.62, -0.34), Vector2(0.44, 0.62),
					Vector2(0.0, 1.0), Vector2(-0.44, 0.62), Vector2(-0.62, -0.34)])
				_pol(ci, gema, cor)
				_pol(ci, _pts(c, r, [Vector2(0.0, -1.0), Vector2(-0.62, -0.34), Vector2(0.0, 0.1)]), Color(1, 1, 1, 0.22))
				_pol(ci, _pts(c, r, [Vector2(0.0, -1.0), Vector2(0.62, -0.34), Vector2(0.0, 0.1)]), clara)
				ci.draw_line(_p(c, r, 0.0, 0.1), _p(c, r, 0.0, 1.0), Color(1, 1, 1, 0.35), 1.5, true)
				_contorno(ci, gema, escura, 1.6)
			"olho":
				var lente := PackedVector2Array()
				for i in 21:
					var x := -1.0 + 2.0 * float(i) / 20.0
					lente.append(_p(c, r, x, -0.62 * (1.0 - x * x)))
				for i in range(1, 20):
					var x2 := 1.0 - 2.0 * float(i) / 20.0
					lente.append(_p(c, r, x2, 0.62 * (1.0 - x2 * x2)))
				_pol(ci, lente, escura)
				ci.draw_circle(c, r * 0.36, cor)
				ci.draw_circle(c, r * 0.16, Color(0.03, 0.04, 0.08, 1.0))
				ci.draw_circle(c + Vector2(-r * 0.13, -r * 0.13), r * 0.07, Color(1, 1, 1, 0.8))
				_contorno(ci, lente, clara, 2.0)
				for i in 3:
					var a := -0.7 + float(i) * 0.7
					ci.draw_line(_p(c, r, a * 0.5, -0.5), _p(c, r, a * 0.62, -0.92), clara, 1.6, true)
			"engrenagem":
				var n := 9
				for i in n:
					var a2 := float(i) / float(n) * TAU + t * 0.25
					var d := Vector2(cos(a2), sin(a2))
					var e := Vector2(-d.y, d.x)
					_pol(ci, PackedVector2Array([
						c + d * r * 0.6 + e * r * 0.17, c + d * r * 1.0 + e * r * 0.11,
						c + d * r * 1.0 - e * r * 0.11, c + d * r * 0.6 - e * r * 0.17]), cor)
				ci.draw_circle(c, r * 0.68, cor)
				ci.draw_circle(c, r * 0.5, escura)
				ci.draw_circle(c, r * 0.2, fundo)
				for i in 4:
					var a3 := float(i) / 4.0 * TAU + t * 0.25
					ci.draw_line(c + Vector2(cos(a3), sin(a3)) * r * 0.22, c + Vector2(cos(a3), sin(a3)) * r * 0.48, cor, 2.0, true)
			"chama":
				var osc := sin(t * 3.0) * 0.05
				_pol(ci, _pts(c, r, [Vector2(0.0 + osc, -1.05), Vector2(0.36, -0.45), Vector2(0.56, 0.0),
					Vector2(0.58, 0.45), Vector2(0.28, 0.86), Vector2(-0.06, 0.98), Vector2(-0.42, 0.78),
					Vector2(-0.58, 0.3), Vector2(-0.4, -0.24), Vector2(-0.12 + osc, -0.58)]), cor)
				_pol(ci, _pts(c, r, [Vector2(0.02 - osc, -0.5), Vector2(0.3, 0.06), Vector2(0.26, 0.5),
					Vector2(-0.02, 0.74), Vector2(-0.3, 0.46), Vector2(-0.26, 0.02)]), clara)
				ci.draw_circle(_p(c, r, 0.0, 0.45), r * 0.16, Color(1, 1, 1, 0.55))
			"floco":
				for i in 6:
					var a4 := float(i) / 6.0 * TAU + t * 0.18
					var d2 := Vector2(cos(a4), sin(a4))
					var e2 := Vector2(-d2.y, d2.x)
					ci.draw_line(c, c + d2 * r, cor, 2.4, true)
					for k in 2:
						var b2 := 0.4 + float(k) * 0.3
						ci.draw_line(c + d2 * r * b2, c + d2 * r * (b2 + 0.22) + e2 * r * 0.2, cor, 1.7, true)
						ci.draw_line(c + d2 * r * b2, c + d2 * r * (b2 + 0.22) - e2 * r * 0.2, cor, 1.7, true)
				ci.draw_circle(c, r * 0.15, clara)
			"raio":
				_pol(ci, _pts(c, r, [Vector2(0.16, -1.0), Vector2(-0.58, 0.08), Vector2(-0.08, 0.08),
					Vector2(-0.32, 1.0), Vector2(0.6, -0.16), Vector2(0.08, -0.16)]), cor)
				_pol(ci, _pts(c, r, [Vector2(0.1, -0.7), Vector2(-0.3, 0.0), Vector2(-0.02, 0.0),
					Vector2(-0.16, 0.62), Vector2(0.34, -0.1), Vector2(0.04, -0.1)]), clara)
			"caveira":
				_pol(ci, _elipse(_p(c, r, 0.0, -0.16), r * 0.76, r * 0.74), cor)
				_pol(ci, _pts(c, r, [Vector2(-0.44, 0.3), Vector2(0.44, 0.3), Vector2(0.36, 0.9),
					Vector2(-0.36, 0.9)]), cor.darkened(0.12))
				ci.draw_circle(_p(c, r, -0.3, -0.2), r * 0.25, fundo.darkened(0.4))
				ci.draw_circle(_p(c, r, 0.3, -0.2), r * 0.25, fundo.darkened(0.4))
				ci.draw_circle(_p(c, r, -0.3, -0.2), r * 0.09, clara)
				ci.draw_circle(_p(c, r, 0.3, -0.2), r * 0.09, clara)
				_pol(ci, _pts(c, r, [Vector2(0.0, 0.06), Vector2(0.13, 0.3), Vector2(-0.13, 0.3)]), fundo.darkened(0.4))
				for i in 3:
					var x3 := -0.2 + float(i) * 0.2
					ci.draw_line(_p(c, r, x3, 0.42), _p(c, r, x3, 0.86), escura, 1.6, true)
			"coroa":
				_pol(ci, _pts(c, r, [Vector2(-0.86, 0.5), Vector2(0.86, 0.5), Vector2(0.82, -0.3),
					Vector2(0.44, 0.12), Vector2(0.24, -0.72), Vector2(0.0, 0.04), Vector2(-0.24, -0.72),
					Vector2(-0.44, 0.12), Vector2(-0.82, -0.3)]), cor)
				ci.draw_rect(Rect2(_p(c, r, -0.86, 0.5), Vector2(r * 1.72, r * 0.32)), escura)
				for i in 3:
					ci.draw_circle(_p(c, r, -0.44 + float(i) * 0.44, 0.66), r * 0.1, clara)
				ci.draw_circle(_p(c, r, 0.0, -0.66), r * 0.11, clara)
			"ampulheta":
				ci.draw_rect(Rect2(_p(c, r, -0.72, -0.96), Vector2(r * 1.44, r * 0.18)), escura)
				ci.draw_rect(Rect2(_p(c, r, -0.72, 0.78), Vector2(r * 1.44, r * 0.18)), escura)
				ci.draw_line(_p(c, r, -0.62, -0.8), _p(c, r, -0.62, 0.8), escura, 2.2, true)
				ci.draw_line(_p(c, r, 0.62, -0.8), _p(c, r, 0.62, 0.8), escura, 2.2, true)
				_pol(ci, _pts(c, r, [Vector2(-0.52, -0.78), Vector2(0.52, -0.78), Vector2(0.0, 0.0)]), cor)
				_pol(ci, _pts(c, r, [Vector2(-0.52, 0.78), Vector2(0.52, 0.78), Vector2(0.0, 0.0)]), cor.darkened(0.18))
				var q := clampf(0.5 + 0.5 * sin(t * 1.2), 0.15, 0.9)
				_pol(ci, _pts(c, r, [Vector2(-0.34 * q, -0.72), Vector2(0.34 * q, -0.72), Vector2(0.0, -0.72 + 0.7 * q)]), clara)
				_pol(ci, _pts(c, r, [Vector2(-0.42, 0.76), Vector2(0.42, 0.76), Vector2(0.0, 0.76 - 0.46 * (1.02 - q))]), clara)
				ci.draw_line(_p(c, r, 0.0, 0.02), _p(c, r, 0.0, 0.6), clara, 1.4, true)
			"moeda":
				# a mordida é um entalhe no próprio polígono — nada de apagar por cima
				var disco := PackedVector2Array()
				var dentes := PackedVector2Array()
				for i in 34:
					var a5 := float(i) / 34.0 * TAU
					var mordida := absf(wrapf(a5 - PI * 0.28, -PI, PI)) < 0.62
					var rr := 0.58 + 0.06 * sin(float(i) * 3.0) if mordida else 0.9
					disco.append(c + Vector2(cos(a5), sin(a5)) * r * rr)
					dentes.append(c + Vector2(cos(a5), sin(a5)) * r * (rr - 0.08))
				_pol(ci, disco, escura)
				_pol(ci, dentes, cor)
				ci.draw_arc(c, r * 0.5, 0, TAU, 26, clara, 1.8, true)
				for i in 8:
					var a6 := float(i) / 8.0 * TAU
					ci.draw_line(c + Vector2(cos(a6), sin(a6)) * r * 0.18, c + Vector2(cos(a6), sin(a6)) * r * 0.4, escura, 2.0, true)
				ci.draw_circle(c, r * 0.14, clara)
			"escudo":
				var esc := _pts(c, r, [Vector2(-0.76, -0.82), Vector2(0.76, -0.82), Vector2(0.64, 0.3),
					Vector2(0.0, 0.98), Vector2(-0.64, 0.3)])
				_pol(ci, esc, cor)
				_pol(ci, _pts(c, r, [Vector2(-0.46, -0.52), Vector2(0.0, -0.52), Vector2(0.0, 0.6),
					Vector2(-0.4, 0.2)]), Color(1, 1, 1, 0.18))
				_pol(ci, _pts(c, r, [Vector2(-0.34, -0.2), Vector2(0.0, -0.44), Vector2(0.34, -0.2),
					Vector2(0.0, 0.06)]), clara)
				_contorno(ci, esc, escura, 2.0)
			"orbe":
				ci.draw_circle(c, r * 0.62, escura)
				ci.draw_circle(c, r * 0.54, cor)
				ci.draw_circle(_p(c, r, -0.2, -0.22), r * 0.16, Color(1, 1, 1, 0.5))
				for i in 2:
					var ang := t * 0.7 + float(i) * PI * 0.55
					var anel := PackedVector2Array()
					for k in 30:
						var th := float(k) / 30.0 * TAU
						var p := Vector2(cos(th) * r * 0.98, sin(th) * r * 0.34).rotated(ang)
						anel.append(c + p)
					_contorno(ci, anel, clara, 1.6)
					var sat := Vector2(cos(t * 1.6 + float(i) * 2.0) * r * 0.98, sin(t * 1.6 + float(i) * 2.0) * r * 0.34).rotated(ang)
					ci.draw_circle(c + sat, r * 0.1, clara)
			"espiral":
				var passos := 60
				for i in passos:
					var f0 := float(i) / float(passos)
					var f1 := float(i + 1) / float(passos)
					var a6 := f0 * 9.4 + t * 0.5
					var a7 := f1 * 9.4 + t * 0.5
					var r0 := (0.05 + f0 * 0.97) * r
					var r1 := (0.05 + f1 * 0.97) * r
					ci.draw_line(c + Vector2(cos(a6), sin(a6)) * r0, c + Vector2(cos(a7), sin(a7)) * r1,
						cor.lerp(clara, f0), 1.0 + 2.6 * f0, true)
				ci.draw_circle(c, r * 0.1, clara)
			_:
				ci.draw_arc(c, r * 0.8, 0, TAU, 22, cor, 2.5, true)
				ci.draw_circle(c, r * 0.2, clara)
