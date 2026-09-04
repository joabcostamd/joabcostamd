extends Control

## A MESA DAS LEIS — a escolha que a Ascensão passou a ter.
##
## Aparece depois de uma Ascensão, com três leis na mesa. Cada uma é uma dádiva
## e um ônus, lado a lado, nas duas colunas: a pessoa não escolhe "qual é melhor",
## escolhe COM QUAL TROCA ela quer jogar as próximas ascensões.
##
## O botão de recusar existe e não é enfeite. Jogar sem lei nova é uma jogada
## legítima, e sem essa saída a mesa viraria imposto — três coisas ruins e a
## obrigação de levar uma para casa.
##
## Molde e comportamento vêm da janela de evento: o jogo NÃO pausa, a torre
## continua trabalhando atrás do vidro.

var jogo: Node
var scrim: ColorRect
var janela: PanelContainer
var corpo: VBoxContainer
var _fechando := false

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if jogo == null or not Editos.tem_oferta(jogo.s):
		queue_free()
		return
	_montar()

func _montar() -> void:
	modulate = Color(1, 1, 1, 0)
	scrim = ColorRect.new()
	scrim.color = Color(0.02, 0.03, 0.06, 0.72)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.22)

	var cor := UI.ACENTO2
	janela = UI.painel(UI.PAINEL, 16)
	janela.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL, 16, 2, cor.darkened(0.25)))
	janela.anchor_left = 0.5
	janela.anchor_right = 0.5
	janela.anchor_top = 0.5
	janela.anchor_bottom = 0.5
	janela.grow_horizontal = Control.GROW_DIRECTION_BOTH
	janela.grow_vertical = Control.GROW_DIRECTION_BOTH
	# A janela nunca pode passar da tela: numa vertical de celular a largura util
	# e bem menor que os 700 px do desktop, e sem o teto as tres fichas empurram
	# a janela para fora e a lei do meio fica cortada.
	var tela := get_viewport_rect().size
	janela.custom_minimum_size.x = minf(720.0, tela.x - 40.0)
	add_child(janela)

	corpo = UI.vbox(10)
	janela.add_child(corpo)

	var cab := UI.vbox(2)
	cab.add_child(UI.rotulo(Txt.t("edt_etiqueta"), 12, UI.TEXTO3))
	var t := UI.titulo(Txt.t("edt_titulo"), 24)
	t.add_theme_color_override("font_color", cor.lightened(0.35))
	cab.add_child(t)
	corpo.add_child(cab)
	var sub := UI.rotulo(Txt.t("edt_sub"), 13, UI.TEXTO2)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = minf(640.0, tela.x - 80.0)
	corpo.add_child(sub)
	corpo.add_child(UI.separador())

	# ROLAGEM VERTICAL SEMPRE. Tres fichas de lei com duas linhas de texto cada
	# passam de 500 px; numa tela de 720 de altura com a janela centrada, a
	# terceira lei ficava fora e o botao de recusar tambem.
	var sc := UI.scroll()
	sc.custom_minimum_size.y = minf(420.0, tela.y * 0.5)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_child(sc)
	var lista := UI.vbox(8)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(lista)
	for d in Editos.oferta(jogo.s):
		lista.add_child(_ficha(d, tela))

	corpo.add_child(UI.separador())
	var pe := UI.botao(Txt.t("edt_recusar"), func(): _recusar())
	pe.tooltip_text = Txt.t("edt_recusar_dica")
	corpo.add_child(pe)
	UI.saltar(janela, 1.07)

## Uma lei: nome, o que dá, o que cobra.
func _ficha(d: Dictionary, tela: Vector2) -> Button:
	var cor := Color.html(str(d.get("cor", "#a78bfa")))
	var b := UI.botao("", func(): _aceitar(str(d.get("id", ""))))
	b.add_theme_stylebox_override("normal", UI.caixa(UI.PAINEL2.darkened(0.18), 10, 1, UI.BORDA))
	b.add_theme_stylebox_override("hover", UI.caixa(UI.tingir(cor, 0.14), 10, 1, cor.darkened(0.2)))

	var h := UI.hbox(12)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	h.offset_top = 10
	h.offset_bottom = -10
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)

	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ic)
	ic.configurar(_icone_do_eixo(str(d.get("eixo", ""))), cor, 26)

	var v := UI.vbox(3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(UI.rotulo(Ux.txt(d, "nome", Cfg.ingles()), 16, cor.lightened(0.3)))
	var desc := UI.rotulo(Ux.txt(d, "desc", Cfg.ingles()), 13, UI.TEXTO2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = minf(500.0, tela.x - 170.0)
	v.add_child(desc)
	var linha := _resumo(d)
	if linha != "":
		v.add_child(UI.rotulo(linha, 12, UI.TEXTO3))
	# A ficha inteira cresce com o texto: sem isto, a descricao em portugues
	# (mais longa que a inglesa) vazava por fora da moldura do botao.
	b.custom_minimum_size.y = maxf(74.0, v.get_combined_minimum_size().y + 20.0)
	return b

## "+3,1x dano · −65% cadência" — a troca em números, para quem quer o número.
func _resumo(d: Dictionary) -> String:
	var partes: Array[String] = []
	for chave in ["dadiva", "onus"]:
		var arr = d.get(chave, [])
		if not (arr is Array):
			continue
		for it in arr:
			if it is Dictionary:
				partes.append(_efeito_curto(it))
	var m = d.get("mods", {})
	if m is Dictionary:
		for k in (m as Dictionary).keys():
			partes.append("%s %s" % [Txt.t("edt_mod_" + str(k)), Fmt.mult(float((m as Dictionary)[k]))])
	return "  ·  ".join(partes)

## Mesmo formato dos marcos de melhoria (`panel_upgrades._resumo_efeito`): o
## jogador ja aprendeu a ler "x3,10 Dano" ali, e a lei nao inventa dialeto novo.
func _efeito_curto(ef: Dictionary) -> String:
	var sd: Dictionary = Dados.stat_defs.get(str(ef.get("stat", "")), {})
	var nome := Ux.txt(sd, "nome", Cfg.ingles())
	var v := float(ef.get("valor", 0.0))
	match str(ef.get("tipo", "flat")):
		"mult": return "%s %s" % [Fmt.mult(v), nome]
		"pct": return "%s%s %s" % ["+" if v >= 0.0 else "", Fmt.pct(v), nome]
		_: return "%s%s %s" % ["+" if v >= 0.0 else "", Fmt.num(v, 2), nome]

func _icone_do_eixo(eixo: String) -> String:
	match eixo:
		"cadencia": return "velocidade"
		"alcance": return "alvo"
		"critico": return "espada"
		"projeteis": return "misseis"
		"area": return "nova"
		"defesa": return "escudo"
		"economia": return "ouro"
		"enxame": return "sentinelas"
		"elemento": return "fogo"
		"orbes": return "orbe"
	return "prestigio"

## ------------------------------------------------------------- resolução

func _aceitar(id: String) -> void:
	if _fechando or jogo == null:
		return
	if Editos.aceitar(jogo.s, id):
		# A lei muda atributo: sem marcar sujo, ela so valeria no proximo
		# recalculo por outro motivo — que pode demorar minutos.
		jogo.marcar_sujo()
		jogo.recalcular()
		var d: Dictionary = Dados.edito_por_id.get(id, {})
		Bus.toast(Txt.f("edt_aceito", {"n": Ux.txt(d, "nome", Cfg.ingles())}), "bom", "prestigio")
	_fechar()

func _recusar() -> void:
	if _fechando or jogo == null:
		return
	Editos.recusar(jogo.s)
	_fechar()

func _fechar() -> void:
	if _fechando:
		return
	_fechando = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
