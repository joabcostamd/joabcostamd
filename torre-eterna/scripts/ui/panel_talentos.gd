extends "res://scripts/ui/panel_base.gd"

## Painel de TALENTOS — três ramos, uma escolha por nível.
## Os nós são desenhados numa malha própria: as ligações saem de um _draw()
## customizado (acesas quando o pré-requisito está pago, apagadas quando não).
## Clique compra 1 nível · Shift+clique enche até onde os pontos derem.

const CUSTO_REDIST := 50.0
const NO := 42.0            # diâmetro de um nó comum
const NO_CHAVE := 54.0      # diâmetro de um nó "chave" (muda a build)
const COL := 132.0          # distância entre colunas da malha
const LIN := 69.0           # distância entre linhas da malha
const MARGEM_X := 50.0
const MARGEM_Y := 28.0
const MALHA_W := 244.0

var lbl_pontos: Label
var lbl_gastos: Label
var bt_redist: Button
var caixa_confirma: PanelContainer
var lbl_confirma: Label
var nos := {}               # id -> {def, botao, icone, rotulo, cor, estado}
var malhas := {}            # ramo -> Control
var lbl_ramos := {}         # ramo -> Label
var _t := 0.0

func configurar() -> void:
	titulo_texto = Txt.t("p_talentos")
	titulo_icone = "arvore"
	largura = 920.0
	altura = 680.0
	intervalo = 0.12

func montar(c: VBoxContainer) -> void:
	c.add_child(_topo())
	c.add_child(_confirmacao())

	var rolagem := UI.scroll()
	var colunas := UI.hbox(10)
	colunas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colunas.alignment = BoxContainer.ALIGNMENT_CENTER
	rolagem.add_child(colunas)
	c.add_child(rolagem)

	if Dados.ramos.is_empty() or Dados.talentos.is_empty():
		colunas.add_child(UI.rotulo(Txt.t("tal_arvore_vazia"), 14, UI.TEXTO3))
		return
	for item in Dados.ramos:
		var ramo: Dictionary = item
		colunas.add_child(_coluna(ramo))

## ------------------------------------------------------------- cabeçalho

func _topo() -> HBoxContainer:
	var topo := UI.hbox(8)
	var ic := UI.icone("estrela", UI.ACENTO2, 22)
	topo.add_child(ic)

	lbl_pontos = UI.rotulo("0", 22, UI.ACENTO2)
	topo.add_child(lbl_pontos)
	topo.add_child(UI.rotulo(Txt.t("pontos_talento"), 13, UI.TEXTO2))
	lbl_gastos = UI.rotulo("", 12, UI.TEXTO3)
	topo.add_child(lbl_gastos)
	topo.add_child(UI.espacador())

	var dica := UI.rotulo(Txt.t("tal_dica_clique"), 12, UI.TEXTO3)
	topo.add_child(dica)

	bt_redist = UI.botao(Txt.t("tal_redistribuir"), _pedir_redist,
		Txt.f("tal_redist_dica", {"n": int(CUSTO_REDIST)}))
	bt_redist.custom_minimum_size = Vector2(140, 34)
	topo.add_child(bt_redist)
	return topo

func _confirmacao() -> PanelContainer:
	caixa_confirma = UI.painel(UI.PAINEL2.darkened(0.1), 10)
	caixa_confirma.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.1), 10, 1, UI.VERMELHO.darkened(0.35)))
	caixa_confirma.visible = false
	var h := UI.hbox(10)
	var ic := UI.icone("cadeado", UI.VERMELHO, 18)
	h.add_child(ic)
	lbl_confirma = UI.rotulo("", 13, UI.TEXTO)
	h.add_child(lbl_confirma)
	h.add_child(UI.espacador())
	var sim := UI.botao(Txt.t("confirmar"), _confirmar_redist)
	sim.custom_minimum_size = Vector2(110, 30)
	sim.add_theme_color_override("font_color", UI.VERMELHO)
	h.add_child(sim)
	var nao := UI.botao(Txt.t("cancelar"), func(): caixa_confirma.visible = false)
	nao.custom_minimum_size = Vector2(100, 30)
	h.add_child(nao)
	caixa_confirma.add_child(h)
	return caixa_confirma

## ---------------------------------------------------------------- colunas

func _coluna(ramo: Dictionary) -> PanelContainer:
	var id := str(ramo.get("id", ""))
	var cor := Color.html(str(ramo.get("cor", "#38bdf8")))
	var cx := PanelContainer.new()
	cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL.darkened(0.25), 12, 1, cor.darkened(0.6)))
	cx.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var v := UI.vbox(4)
	cx.add_child(v)

	var cab := UI.hbox(8)
	var ic := UI.icone(_icone_ramo(id), cor, 22)
	cab.add_child(ic)
	var textos := UI.vbox(0)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(textos)
	textos.add_child(UI.rotulo(txt(ramo, "nome"), 17, cor))
	var l_pts := UI.rotulo("", 11, UI.TEXTO3)
	textos.add_child(l_pts)
	lbl_ramos[id] = l_pts
	v.add_child(cab)

	var desc := UI.rotulo(txt(ramo, "desc"), 12, UI.TEXTO2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = MALHA_W - 12.0
	v.add_child(desc)
	v.add_child(UI.separador())

	var malha := Control.new()
	malha.custom_minimum_size = Vector2(MALHA_W, _altura_malha(id))
	malha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	malha.draw.connect(_desenhar_malha.bind(malha, id))
	malhas[id] = malha
	v.add_child(malha)

	for item in Dados.talentos:
		var def: Dictionary = item
		if str(def.get("ramo", "")) == id:
			_criar_no(def, malha, cor)
	return cx

func _altura_malha(ramo_id: String) -> float:
	var maior := 0.0
	for item in Dados.talentos:
		var def: Dictionary = item
		if str(def.get("ramo", "")) != ramo_id:
			continue
		maior = maxf(maior, _centro(def).y + (NO_CHAVE if bool(def.get("chave", false)) else NO) * 0.5)
	return maior + 8.0

func _centro(def: Dictionary) -> Vector2:
	var p: Array = def.get("pos", [0, 0])
	var col := float(p[0]) if p.size() > 0 else 0.0
	var lin := float(p[1]) if p.size() > 1 else 0.0
	return Vector2(MARGEM_X + col * COL, MARGEM_Y + lin * LIN)

func _criar_no(def: Dictionary, malha: Control, cor: Color) -> void:
	var id := str(def.get("id", ""))
	var chave := bool(def.get("chave", false))
	var tam: float = NO_CHAVE if chave else NO
	var centro := _centro(def)

	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(tam, tam)
	b.size = Vector2(tam, tam)
	b.position = centro - Vector2(tam, tam) * 0.5
	b.pressed.connect(func(): _clicar(id))
	malha.add_child(b)

	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(ic)
	ic.configurar(_icone_ramo(str(def.get("ramo", ""))), cor, tam * 0.46)

	var rot := UI.rotulo("", 11, UI.TEXTO2)
	rot.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rot.size = Vector2(44, 14)
	rot.position = Vector2(centro.x + tam * (0.80 if chave else 0.5) + 6.0, centro.y - 7.0)
	malha.add_child(rot)

	nos[id] = {"def": def, "botao": b, "icone": ic, "rotulo": rot, "cor": cor, "tam": tam, "estado": ""}

## ------------------------------------------------------------- ligações

func _desenhar_malha(malha: Control, ramo_id: String) -> void:
	if jogo == null:
		return
	var cor := UI.ACENTO
	for item in Dados.ramos:
		var ramo: Dictionary = item
		if str(ramo.get("id", "")) == ramo_id:
			cor = Color.html(str(ramo.get("cor", "#38bdf8")))

	for item2 in Dados.talentos:
		var def: Dictionary = item2
		if str(def.get("ramo", "")) != ramo_id:
			continue
		var req = def.get("requer", null)
		if not (req is Array):
			continue
		var destino := _centro(def)
		var r_dest: float = (NO_CHAVE if bool(def.get("chave", false)) else NO) * 0.5 + 4.0
		for rid in req:
			var pai: Dictionary = Dados.talento_por_id.get(str(rid), {})
			if pai.is_empty():
				continue
			var origem := _centro(pai)
			var r_orig: float = (NO_CHAVE if bool(pai.get("chave", false)) else NO) * 0.5 + 4.0
			var dir := (destino - origem).normalized()
			var a := origem + dir * r_orig
			var b := destino - dir * r_dest
			if int(jogo.s["talentos"].get(str(rid), 0)) > 0:
				malha.draw_line(a, b, Ux.com_alfa(cor, 0.22), 8.0, true)
				malha.draw_line(a, b, Ux.clarear(cor, 0.25), 2.5, true)
			else:
				malha.draw_line(a, b, Ux.com_alfa(UI.BORDA_FORTE, 0.5), 2.0, true)

	# nós-chave: hexágono de destaque com brilho pulsante
	for item3 in Dados.talentos:
		var def2: Dictionary = item3
		if str(def2.get("ramo", "")) != ramo_id or not bool(def2.get("chave", false)):
			continue
		var id := str(def2.get("id", ""))
		var nivel := int(jogo.s["talentos"].get(id, 0))
		var maxn := int(def2.get("max", 1))
		var liberado := bool(jogo.talento_liberado(def2))
		var c := _centro(def2)
		var cor_anel := UI.TEXTO3
		if nivel >= maxn:
			cor_anel = UI.OURO
		elif liberado:
			cor_anel = Ux.clarear(cor, 0.2)
		var pulso := 0.5 + 0.5 * sin(_t * 2.6)
		if liberado:
			malha.draw_circle(c, NO_CHAVE * 0.62, Ux.com_alfa(cor_anel, 0.06 + 0.10 * pulso))
		malha.draw_polyline(_hexagono(c, NO_CHAVE * 0.66), Ux.com_alfa(cor_anel, 0.55 if liberado else 0.3), 2.0, true)
		if liberado:
			malha.draw_polyline(_hexagono(c, NO_CHAVE * 0.78), Ux.com_alfa(cor_anel, 0.10 + 0.22 * pulso), 1.5, true)

func _hexagono(c: Vector2, raio: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 7:
		var a := -PI * 0.5 + float(i) * PI / 3.0
		pts.append(c + Vector2(cos(a), sin(a)) * raio)
	return pts

## ---------------------------------------------------------------- compra

func _clicar(id: String) -> void:
	var def: Dictionary = Dados.talento_por_id.get(id, {})
	if def.is_empty():
		return
	var nivel := int(jogo.s["talentos"].get(id, 0))
	var maxn := int(def.get("max", 1))
	if not jogo.talento_liberado(def):
		Bus.toast(Txt.f("tal_bloqueado_falta", {"req": _nomes_requisitos(def)}), "info")
		return
	if nivel >= maxn:
		Bus.toast(Txt.f("tal_ja_no_maximo", {"n": txt(def, "nome")}), "info")
		return
	var comprou := 0
	if Input.is_key_pressed(KEY_SHIFT):
		while comprou < 999 and jogo.comprar_talento(id):
			comprou += 1
	elif jogo.comprar_talento(id):
		comprou = 1
	if comprou <= 0:
		Bus.toast(Txt.t("tal_pontos_insuficientes"), "ruim")
		return
	var r: Dictionary = nos[id]
	UI.pulsar(r["botao"], r["cor"])
	UI.saltar(r["botao"], 1.22)
	Bus.toast(Txt.f("tal_toast_nivel", {"n": txt(def, "nome"), "v": nivel + comprou}), "bom")
	atualizar()

func _pedir_redist() -> void:
	var gastos := int(jogo.s["pontos_talento_gastos"])
	if gastos <= 0:
		Bus.toast(Txt.t("tal_nada_desfazer"), "info")
		return
	var quantos := 0
	for id in jogo.s["talentos"].keys():
		if int(jogo.s["talentos"][id]) > 0:
			quantos += 1
	lbl_confirma.text = Txt.f("tal_confirma_redist", {
		"a": _plural(quantos, Txt.t("tal_talento_um"), Txt.t("tal_talento_muitos")),
		"b": _plural(gastos, Txt.t("tal_ponto_um"), Txt.t("tal_ponto_muitos")),
		"n": int(CUSTO_REDIST)})
	caixa_confirma.visible = true

func _confirmar_redist() -> void:
	caixa_confirma.visible = false
	if jogo.redistribuir_talentos(CUSTO_REDIST):
		Bus.toast(Txt.t("tal_redistribuidos"), "bom")
		UI.pulsar(janela, UI.ACENTO2)
		atualizar()
	else:
		Bus.toast(Txt.f("tal_gemas_insuficientes", {"n": int(CUSTO_REDIST)}), "ruim")

## ------------------------------------------------------------ atualização

func atualizar() -> void:
	if jogo == null or lbl_pontos == null:
		return
	_t = float(Time.get_ticks_msec()) * 0.001
	var pontos := int(jogo.s["pontos_talento"])
	var gastos := int(jogo.s["pontos_talento_gastos"])
	lbl_pontos.text = Fmt.inteiro(pontos)
	lbl_gastos.text = Txt.f("tal_ja_investidos", {"n": gastos})
	lbl_pontos.add_theme_color_override("font_color", UI.ACENTO2 if pontos > 0 else UI.TEXTO3)

	var gemas := float(jogo.s["moedas"]["gemas"])
	var pode_redist := gastos > 0 and Big.gte(gemas, Big.from(CUSTO_REDIST))
	bt_redist.disabled = not pode_redist
	bt_redist.text = Txt.f("tal_redist_botao", {"n": int(CUSTO_REDIST)})
	bt_redist.add_theme_color_override("font_color", UI.ROSA if pode_redist else UI.TEXTO3)

	for chave in lbl_ramos.keys():
		var ramo_id := str(chave)
		var niveis := 0
		var pts := 0
		for item in Dados.talentos:
			var def: Dictionary = item
			if str(def.get("ramo", "")) != ramo_id:
				continue
			var n := int(jogo.s["talentos"].get(str(def.get("id", "")), 0))
			niveis += n
			for k in n:
				pts += int(jogo.custo_talento(def, k))
		var l: Label = lbl_ramos[ramo_id]
		l.text = "%s · %s" % [_plural(niveis, Txt.t("tal_nivel_um"), Txt.t("tal_nivel_muitos")), _plural(pts, Txt.t("tal_ponto_um"), Txt.t("tal_ponto_muitos"))] if niveis > 0 else Txt.t("tal_nada_investido")

	for chave2 in nos.keys():
		var r: Dictionary = nos[str(chave2)]
		_pintar(r)
	for m in malhas.values():
		var malha: Control = m
		malha.queue_redraw()

func _pintar(r: Dictionary) -> void:
	var def: Dictionary = r["def"]
	var id := str(def.get("id", ""))
	var cor: Color = r["cor"]
	var tam: float = r["tam"]
	var nivel := int(jogo.s["talentos"].get(id, 0))
	var maxn := int(def.get("max", 1))
	var liberado := bool(jogo.talento_liberado(def))
	var no_teto := nivel >= maxn
	var custo := int(jogo.custo_talento(def, nivel))
	var pode := liberado and not no_teto and int(jogo.s["pontos_talento"]) >= custo

	var estado := "%d|%d|%d|%d" % [nivel, int(liberado), int(pode), custo]
	if str(r["estado"]) == estado:
		return
	r["estado"] = estado

	var cor_borda := UI.BORDA
	if no_teto:
		cor_borda = UI.OURO
	elif nivel > 0:
		cor_borda = Ux.clarear(cor, 0.15)
	elif liberado:
		cor_borda = Color.WHITE if pode else UI.TEXTO2

	var fundo := UI.PAINEL.darkened(0.35)
	if nivel > 0:
		fundo = cor.darkened(0.74).lerp(cor.darkened(0.42), float(nivel) / float(maxi(1, maxn)))
	elif liberado:
		fundo = UI.PAINEL2

	var b: Button = r["botao"]
	var raio := int(tam * 0.5)
	b.add_theme_stylebox_override("normal", _redondo(fundo, raio, 2, cor_borda))
	b.add_theme_stylebox_override("hover", _redondo(Ux.clarear(fundo, 0.12), raio, 2, Ux.clarear(cor_borda, 0.3)))
	b.add_theme_stylebox_override("pressed", _redondo(Ux.clarear(fundo, 0.25), raio, 2, Color.WHITE))
	b.add_theme_stylebox_override("disabled", _redondo(fundo, raio, 2, cor_borda))
	b.modulate = Color(1, 1, 1, 1.0 if liberado else 0.72)

	var ic: Control = r["icone"]
	var cor_ic := cor
	if not liberado:
		cor_ic = UI.TEXTO3
	elif no_teto:
		cor_ic = Ux.clarear(UI.OURO, 0.15)
	ic.configurar(_icone_ramo(str(def.get("ramo", ""))), cor_ic, tam * 0.46)

	var rot: Label = r["rotulo"]
	rot.text = Txt.t("tal_max_curto") if no_teto else "%d/%d" % [nivel, maxn]
	rot.add_theme_color_override("font_color", UI.OURO if no_teto else (UI.TEXTO if nivel > 0 else UI.TEXTO3))
	b.tooltip_text = _dica(def, nivel, maxn, liberado, no_teto, custo)

func _redondo(cor_fundo: Color, raio: int, borda: int, cor_borda: Color) -> StyleBoxFlat:
	var sb := UI.caixa(cor_fundo, raio, borda, cor_borda)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb

## ---------------------------------------------------------------- textos

func _dica(def: Dictionary, nivel: int, maxn: int, liberado: bool, no_teto: bool, custo: int) -> String:
	var partes: Array = []
	var cabeca := txt(def, "nome")
	if bool(def.get("chave", false)):
		cabeca += "   " + Txt.t("tal_talento_chave")
	partes.append(cabeca)
	partes.append(txt(def, "desc"))
	partes.append("")
	partes.append(Txt.f("tal_nivel_de", {"a": nivel, "b": maxn}))
	if nivel > 0:
		partes.append(Txt.t("atual") + ":  " + _efeito(def, nivel))
	if nivel < maxn:
		partes.append(Txt.t("proximo") + ":  " + _efeito(def, nivel + 1))
	partes.append("")
	if not liberado:
		partes.append(Txt.f("tal_bloqueado_falta", {"req": _nomes_requisitos(def)}))
	elif no_teto:
		partes.append(Txt.t("tal_maximizado"))
	else:
		partes.append(Txt.f("tal_custo_dica", {"c": _plural(custo, Txt.t("tal_ponto_um"), Txt.t("tal_ponto_muitos"))}))
	return "\n".join(partes)

func _efeito(def: Dictionary, nivel: int) -> String:
	var partes: Array = []
	for item in def.get("efeito", []):
		var ef: Dictionary = item
		if str(ef.get("tipo", "")) == "passiva":
			var maxn := int(def.get("max", 1))
			partes.append(Txt.t("tal_passiva_ativa") if maxn <= 1 else Txt.f("tal_passiva_acumulada", {"n": nivel}))
			continue
		if not ef.has("stat"):
			continue
		var sd: Dictionary = Dados.stat_defs.get(str(ef["stat"]), {})
		var nome := txt(sd, "nome")
		var v := float(ef.get("valor", 0.0))
		match str(ef.get("tipo", "flat")):
			"flat":
				partes.append("%s +%s" % [nome, Fmt.num(v * float(nivel), 2)])
			"pct":
				partes.append("%s +%s" % [nome, Fmt.pct(v * float(nivel))])
			"mult":
				partes.append("%s ×%s" % [nome, Fmt.big(Big.pow_n(Big.from(v), float(nivel)))])
	return "  ·  ".join(partes) if not partes.is_empty() else "—"

func _nomes_requisitos(def: Dictionary) -> String:
	var req = def.get("requer", null)
	if not (req is Array):
		return "—"
	var faltando: Array = []
	for rid in req:
		if int(jogo.s["talentos"].get(str(rid), 0)) > 0:
			continue
		var pai: Dictionary = Dados.talento_por_id.get(str(rid), {})
		faltando.append(txt(pai, "nome") if not pai.is_empty() else str(rid))
	return (" %s " % Txt.t("tal_e")).join(faltando) if not faltando.is_empty() else "—"

func _plural(n: int, um: String, muitos: String) -> String:
	return "%s %s" % [Fmt.inteiro(n), um if n == 1 else muitos]

func _icone_ramo(id: String) -> String:
	match id:
		"furia": return "espada"
		"bastiao": return "escudo"
		"fortuna": return "ouro"
	return "estrela"
