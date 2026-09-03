extends Control

## JANELA DE EVENTO — a batida na porta entre duas ondas.
##
## Criada pelo `panel_manager` quando `Bus.evento_sorteado` dispara.
## O jogo NÃO pausa: a torre continua atirando atrás do vidro. O jogador
## escolhe uma opção, vê o que aconteceu, e a janela some.
##
## A regra do risco: `risco.chance` no JSON é a chance de DAR ERRADO —
## aqui mostramos sempre a chance de SUCESSO, que é o que a cabeça entende.

var evento: Dictionary = {}
var jogo: Node

var scrim: ColorRect
var janela: PanelContainer
var corpo: VBoxContainer
var cor := UI.ACENTO
var resolvido := false
var _fechando := false

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if evento.is_empty():
		queue_free()
		return
	cor = Eventos.cor_de(evento)
	_montar()

func configurar(def: Dictionary) -> void:
	evento = def

## ------------------------------------------------------------- montagem

func _montar() -> void:
	modulate = Color(1, 1, 1, 0)
	scrim = ColorRect.new()
	scrim.color = Color(0.02, 0.03, 0.06, 0.72)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.22)

	janela = UI.painel(UI.PAINEL, 16)
	janela.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL, 16, 2, cor.darkened(0.25)))
	janela.anchor_left = 0.5
	janela.anchor_right = 0.5
	janela.anchor_top = 0.5
	janela.anchor_bottom = 0.5
	janela.grow_horizontal = Control.GROW_DIRECTION_BOTH
	janela.grow_vertical = Control.GROW_DIRECTION_BOTH
	janela.custom_minimum_size.x = minf(700.0, get_viewport_rect().size.x - 60.0)
	add_child(janela)

	corpo = UI.vbox(12)
	janela.add_child(corpo)
	_montar_pergunta()
	UI.saltar(janela, 1.07)

func _montar_pergunta() -> void:
	_limpar()
	corpo.add_child(_cabecalho())
	corpo.add_child(UI.separador())

	var texto := UI.rotulo(_txt(evento, "texto"), 15, UI.TEXTO2)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size.x = 620
	texto.add_theme_constant_override("line_spacing", 7)
	corpo.add_child(texto)
	corpo.add_child(UI.separador())

	var opcoes: Array = evento.get("opcoes", [])
	for i in opcoes.size():
		var op: Dictionary = opcoes[i]
		corpo.add_child(_botao_opcao(op, i))

	var rodape := UI.rotulo(Txt.t("evt_rodape"), 12, UI.TEXTO3)
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corpo.add_child(rodape)

func _cabecalho() -> HBoxContainer:
	var h := UI.hbox(14)

	var medalha := UI.painel(UI.PAINEL2.darkened(0.15), 14)
	medalha.add_theme_stylebox_override("panel", UI.caixa(cor.darkened(0.75), 14, 1, cor.darkened(0.35)))
	medalha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	medalha.add_child(ic)
	h.add_child(medalha)
	ic.configurar(Eventos.icone_de(evento), cor, 42)

	var v := UI.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var etiqueta := UI.rotulo("%s  ·  %s %d" % [Txt.t("evt_evento"), Txt.t("onda"), int(jogo.s["onda"])], 12, UI.TEXTO3)
	v.add_child(etiqueta)
	var titulo := UI.titulo(_txt(evento, "nome"), 25)
	titulo.add_theme_color_override("font_color", cor.lightened(0.35))
	v.add_child(titulo)
	h.add_child(v)
	return h

## Um botão por opção: o que você faz, o que ganha e a chance de sair certo.
func _botao_opcao(op: Dictionary, indice: int) -> Button:
	var res: Dictionary = op.get("resultado", {})
	var risco = op.get("risco", null)
	var cor_res := Eventos.cor_resultado(res)

	var b := UI.botao("", func(): _escolher(indice))
	b.custom_minimum_size.y = 68
	b.add_theme_stylebox_override("normal", UI.caixa(UI.PAINEL2.darkened(0.18), 10, 1, UI.BORDA))
	b.add_theme_stylebox_override("hover", UI.caixa(UI.tingir(cor, 0.14), 10, 1, cor.darkened(0.2)))

	var h := UI.hbox(12)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -14
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)

	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	ic.configurar(Eventos.icone_resultado(res), cor_res, 24)

	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.rotulo(_txt(op, "texto"), 15, UI.TEXTO)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 420
	v.add_child(l)
	v.add_child(UI.rotulo(Eventos.resumo(jogo, res), 13, cor_res))
	h.add_child(v)

	if risco is Dictionary:
		var chance := 1.0 - clampf(float(risco.get("chance", 0.0)), 0.0, 1.0)
		var cor_risco := UI.VERDE if chance >= 0.7 else (UI.OURO if chance >= 0.5 else UI.VERMELHO)
		var cx := UI.painel(UI.PAINEL.darkened(0.25), 8)
		cx.add_theme_stylebox_override("panel", UI.caixa(UI.FUNDO2, 8, 1, cor_risco.darkened(0.45)))
		cx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vr := UI.vbox(0)
		vr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pc := UI.rotulo(Fmt.pct(chance, 0), 17, cor_risco)
		pc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vr.add_child(pc)
		var sub := UI.rotulo(Txt.t("evt_de_sair_certo"), 11, UI.TEXTO3)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vr.add_child(sub)
		cx.add_child(vr)
		h.add_child(cx)
		var falha = risco.get("falha", {})
		var texto_falha := Eventos.resumo(jogo, falha) if falha is Dictionary else Txt.t("evt_nada")
		b.tooltip_text = Txt.f("evt_se_der_errado", {"s": texto_falha})
	else:
		var certo := UI.rotulo(Txt.t("evt_garantido"), 12, UI.TEXTO3)
		certo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		certo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(certo)
		b.tooltip_text = Txt.t("evt_sem_risco")
	return b

## ------------------------------------------------------------- resolução

func _escolher(indice: int) -> void:
	if resolvido or jogo == null:
		return
	resolvido = true
	var efeito := Eventos.resolver(jogo, str(evento.get("id", "")), indice)
	_montar_resultado(efeito)

func _montar_resultado(efeito: Dictionary) -> void:
	_limpar()
	var sucesso := bool(efeito.get("sucesso", true))
	var arriscou := bool(efeito.get("arriscou", false))
	var cor_res: Color = efeito.get("cor", UI.TEXTO2)
	var tom := str(efeito.get("tom", "info"))

	var h := UI.hbox(14)
	var medalha := UI.painel(UI.PAINEL2, 14)
	medalha.add_theme_stylebox_override("panel", UI.caixa(cor_res.darkened(0.75), 14, 1, cor_res.darkened(0.3)))
	medalha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	medalha.add_child(ic)
	h.add_child(medalha)
	ic.configurar(str(efeito.get("icone", "estrela")), cor_res, 44)

	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var manchete := Txt.t("evt_correu_bem") if sucesso else Txt.t("evt_correu_mal")
	if not arriscou:
		manchete = Txt.t("evt_feito")
	v.add_child(UI.rotulo("%s  ·  %s" % [_txt(evento, "nome").to_upper(), manchete], 12, UI.TEXTO3))
	var l := UI.titulo(str(efeito.get("texto", "")), 23)
	l.add_theme_color_override("font_color", cor_res)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 520
	v.add_child(l)
	h.add_child(v)
	corpo.add_child(h)

	if arriscou:
		corpo.add_child(UI.separador())
		var chance := float(efeito.get("chance", 1.0))
		var frase := Txt.f("evt_chance_sucesso", {"p": Fmt.pct(chance, 0)})
		if not sucesso:
			frase = Txt.f("evt_chance_falha", {"p": Fmt.pct(chance, 0)})
		corpo.add_child(UI.rotulo(frase, 13, UI.TEXTO3))

	var b := UI.botao(Txt.t("evt_voltar_trabalho"), _fechar)
	b.custom_minimum_size.y = 44
	corpo.add_child(b)

	UI.saltar(janela, 1.06)
	UI.pulsar(janela, cor_res)
	if str(efeito.get("texto", "")) != "":
		Bus.toast(str(efeito.get("texto", "")), tom)
	if tom == "epico":
		Bus.flash_pedido.emit(cor_res, 0.28)
	_fechar_em(5.0)

func _fechar_em(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout
	if is_instance_valid(self):
		_fechar()

func _fechar() -> void:
	if _fechando:
		return
	_fechando = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)

## ------------------------------------------------------------ utilidades

func _limpar() -> void:
	for n in corpo.get_children():
		corpo.remove_child(n)
		n.queue_free()

func _txt(d: Dictionary, campo: String) -> String:
	return Ux.txt(d, campo, Cfg.ingles())
