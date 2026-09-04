extends Control

## A JANELA DE TEXTO LONGO — licenças e novidades da versão.
##
## Duas telas que a loja exige e que o jogo não tinha. O texto MIT do Godot
## precisa acompanhar o produto: não é gentileza, é a condição da licença que
## permite usar a engine comercialmente. E a lista do que mudou é o que responde
## "a correção que eu esperava já chegou?" sem obrigar ninguém a caçar num fórum.
##
## As duas dividem a mesma janela porque são a mesma coisa do ponto de vista de
## quem monta a tela: um bloco de texto comprido que precisa rolar, caber em
## celular e fechar fácil. Duas janelas quase iguais seriam dois lugares para o
## mesmo defeito de layout aparecer.

## "licencas" ou "novidades".
var qual := "licencas"
var jogo: Node
var _fechando := false

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_montar()

func _montar() -> void:
	modulate = Color(1, 1, 1, 0)
	var scrim := ColorRect.new()
	scrim.color = Color(0.02, 0.03, 0.06, 0.78)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)

	var tela := get_viewport_rect().size
	var cor := UI.ACENTO2 if qual == "novidades" else UI.ACENTO
	var janela := UI.painel(UI.PAINEL, 16)
	janela.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL, 16, 2, cor.darkened(0.3)))
	janela.anchor_left = 0.5
	janela.anchor_right = 0.5
	janela.anchor_top = 0.5
	janela.anchor_bottom = 0.5
	janela.grow_horizontal = Control.GROW_DIRECTION_BOTH
	janela.grow_vertical = Control.GROW_DIRECTION_BOTH
	# Teto pelas DUAS dimensões. Só limitar a largura deixava a janela crescer
	# para baixo com o texto e sair pela borda de cima numa tela de celular.
	janela.custom_minimum_size = Vector2(minf(760.0, tela.x - 40.0), minf(560.0, tela.y - 60.0))
	add_child(janela)

	var corpo := UI.vbox(10)
	janela.add_child(corpo)

	var cab := UI.hbox(10)
	cab.add_child(UI.icone("livro" if qual == "licencas" else "estrela", cor, 20))
	var t := UI.titulo(Txt.t("cfg_licencas") if qual == "licencas" else Txt.t("cfg_novidades"), 21)
	t.add_theme_color_override("font_color", cor.lightened(0.3))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	cab.add_child(UI.botao_icone("fechar", Txt.t("fechar"), func(): _fechar()))
	corpo.add_child(cab)
	corpo.add_child(UI.separador())

	var sc := UI.scroll()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_child(sc)
	var dentro := UI.vbox(8)
	dentro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(dentro)
	if qual == "licencas":
		_montar_licencas(dentro, janela.custom_minimum_size.x - 60.0)
	else:
		_montar_novidades(dentro, janela.custom_minimum_size.x - 60.0)
	UI.saltar(janela, 1.05)

## O arquivo de licenças é lido do disco, e não colado numa constante. Colado,
## ele viraria uma segunda cópia do texto legal, e duas cópias divergem — a que
## o jogador lê passaria a não ser a que acompanha o produto.
func _montar_licencas(dentro: VBoxContainer, larg: float) -> void:
	var caminho := "res://licencas/TERCEIROS.txt"
	var texto := ""
	if FileAccess.file_exists(caminho):
		texto = FileAccess.get_file_as_string(caminho)
	if texto.strip_edges() == "":
		dentro.add_child(UI.rotulo(Txt.t("cfg_licencas_sem"), 13, UI.TEXTO3))
		return
	# `RichTextLabel` com rolagem própria DESLIGADA: quem rola é o
	# ScrollContainer de fora. Com as duas rolagens ligadas, a roda do mouse
	# move uma e o arrasto move a outra, e o texto parece preso.
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = false
	rt.text = texto
	rt.fit_content = true
	rt.scroll_active = false
	rt.selection_enabled = true
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.custom_minimum_size.x = larg
	rt.add_theme_font_size_override("normal_font_size", 12)
	rt.add_theme_color_override("default_color", UI.TEXTO2)
	dentro.add_child(rt)

func _montar_novidades(dentro: VBoxContainer, larg: float) -> void:
	var ingles := Cfg.ingles()
	var achou := false
	for item in Dados.changelog:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		achou = true
		var v := str(e.get("versao", ""))
		var h := UI.hbox(8)
		var lv := UI.rotulo(v, 16, UI.ACENTO2)
		h.add_child(lv)
		if v == Versao.numero():
			var atual := UI.painel(UI.PAINEL2.darkened(0.2), 6)
			atual.add_theme_stylebox_override("panel", UI.caixa(UI.FUNDO2, 6, 1, UI.VERDE.darkened(0.4)))
			atual.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			atual.add_child(UI.rotulo(Txt.t("cfg_versao_atual"), 11, UI.VERDE))
			h.add_child(atual)
		var data := UI.rotulo(str(e.get("data", "")), 12, UI.TEXTO3)
		data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		data.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(data)
		dentro.add_child(h)
		var tit := UI.rotulo(Ux.txt(e, "titulo", ingles), 14, UI.TEXTO)
		tit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tit.custom_minimum_size.x = larg
		dentro.add_child(tit)
		for m in Versao.mudancas(v, ingles):
			dentro.add_child(_linha_mudanca(m, larg))
		dentro.add_child(UI.separador())
	if not achou:
		dentro.add_child(UI.rotulo(Txt.t("cfg_novidades_sem"), 13, UI.TEXTO3))

## Cada mudança com a cor do que ela é: verde para o que chegou, azul para o que
## melhorou, laranja para o que estava quebrado. Uma lista monocromática obriga
## a ler tudo para achar a linha que interessa.
func _linha_mudanca(m: Dictionary, larg: float) -> Control:
	var tipo := str(m.get("tipo", "novo"))
	var cor := UI.VERDE
	var icone := "mais"
	if tipo == "correcao":
		cor = UI.LARANJA
		icone = "reparo"
	elif tipo == "melhoria":
		cor = UI.ACENTO
		icone = "velocidade"
	var h := UI.hbox(8)
	var ic := UI.icone(icone, cor, 13)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(ic)
	var l := UI.rotulo(str(m.get("texto", "")), 12, UI.TEXTO2)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = larg - 30.0
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h

func _fechar() -> void:
	if _fechando:
		return
	_fechando = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)
