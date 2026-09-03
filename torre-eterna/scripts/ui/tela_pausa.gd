extends Control

## Menu de pausa. O jogo para de verdade aqui — é a única pausa explícita.

signal retomar()
signal abrir_painel(nome: String)

var jogo: Node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	jogo = get_node_or_null("/root/Jogo")
	_montar()

func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.72)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fundo)

	var painel := UI.painel(UI.PAINEL, 16)
	painel.anchor_left = 0.5
	painel.anchor_right = 0.5
	painel.anchor_top = 0.5
	painel.anchor_bottom = 0.5
	painel.offset_left = -190
	painel.offset_right = 190
	painel.offset_top = -215
	painel.offset_bottom = 215
	add_child(painel)

	var v := UI.vbox(10)
	painel.add_child(v)
	v.add_child(UI.titulo(Txt.t("pau_titulo"), 26))
	v.add_child(UI.separador())

	var s: Dictionary = jogo.s
	v.add_child(UI.rotulo(Txt.f("pau_onda_recorde", {"a": int(s["onda"]), "b": int(s["onda_maxima_global"])}), 14, UI.TEXTO2))
	v.add_child(UI.rotulo(Txt.f("pau_tempo_total", {"t": Ux.tempo_curto(float(s["stats"]["tempo_total"]))}), 14, UI.TEXTO2))
	v.add_child(UI.separador())

	var b := UI.botao(Txt.t("pau_retomar"), func(): retomar.emit())
	b.custom_minimum_size.y = 46
	v.add_child(b)
	for par in [["config", Txt.t("p_config")], ["stats", Txt.t("p_stats")], ["codex", Txt.t("p_codex")], ["conquistas", Txt.t("p_conquistas")]]:
		var bb := UI.botao(str(par[1]), func(): abrir_painel.emit(str(par[0])))
		bb.custom_minimum_size.y = 38
		v.add_child(bb)
	v.add_child(UI.espacador(0, false))
	var bs := UI.botao(Txt.t("pau_salvar_sair"), func():
		jogo.salvar()
		get_tree().quit())
	bs.custom_minimum_size.y = 38
	bs.add_theme_color_override("font_color", UI.TEXTO2)
	v.add_child(bs)
	UI.saltar(painel, 1.05)
