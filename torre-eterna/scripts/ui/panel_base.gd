extends Control

## Base de todos os painéis. Cuida da janela, do título, do botão fechar,
## do ritmo de atualização e do acesso ao jogo.
##
## Um painel filho faz:  extends "res://scripts/ui/panel_base.gd"
## e implementa `montar(corpo: VBoxContainer)` e, se quiser, `atualizar()`.

var jogo: Node
var janela: PanelContainer
var corpo: VBoxContainer
var cabecalho: HBoxContainer
var _acc := 0.0
var intervalo := 0.2
var titulo_texto := "Painel"
var titulo_icone := "engrenagem"
var largura := 780.0
var altura := 560.0

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	configurar()
	_montar_janela()
	montar(corpo)
	atualizar()
	UI.saltar(janela, 1.04)

## Sobrescreva para definir título/tamanho.
func configurar() -> void:
	pass

## Sobrescreva: monta o conteúdo dentro de `corpo`.
func montar(_corpo: VBoxContainer) -> void:
	pass

## Sobrescreva: chamado a cada `intervalo` segundos.
func atualizar() -> void:
	pass

func _process(delta: float) -> void:
	_acc += delta
	if _acc >= intervalo:
		_acc = 0.0
		atualizar()

## Tamanho real da janela: o que o painel pediu, limitado pelo que cabe na
## tela. Com "fonte grande" ou escala da interface em 1,4 a tela LÓGICA encolhe
## (o `content_scale_factor` divide tudo), então um painel que pede 1170px de
## largura passava do limite e saía pela direita levando o botão de fechar
## junto — sem jeito de fechar a não ser pelo Esc. Todo mínimo interno grande
## tem que sair daqui, não de constante em pixel.
## Com `CONTENT_SCALE_MODE_CANVAS_ITEMS` (ver `Cfg._aplicar_escala`) o retângulo
## do viewport já vem em coordenadas LÓGICAS, que é onde os Controls vivem —
## então a conta é direta. O que não pode voltar é o mínimo em pixel fixo lá
## dentro: é ele que empurrava o painel para fora quando a tela lógica encolhia.
## O espaço disponível é o do PAI, não o do viewport. `get_viewport_rect()`
## devolve pixels físicos; com a escala da interface ligada a área lógica onde
## os Controls vivem é menor, e era por isso que um painel de 1170 "cabia" numa
## tela lógica de 816 e saía pela direita levando o botão de fechar junto.
func _area() -> Vector2:
	var a := get_parent_area_size()
	if a.x < 100.0 or a.y < 100.0:
		a = get_viewport_rect().size
	return a

func larg_janela() -> float:
	return minf(largura, _area().x - 40.0)

func alt_janela() -> float:
	return minf(altura, _area().y - 40.0)

## Largura útil de dentro da janela, já descontadas as margens do painel.
func larg_util() -> float:
	return maxf(280.0, larg_janela() - 44.0)

func _montar_janela() -> void:
	janela = UI.painel(UI.PAINEL, 16)
	janela.anchor_left = 0.5
	janela.anchor_right = 0.5
	janela.anchor_top = 0.5
	janela.anchor_bottom = 0.5
	var w := larg_janela()
	var h := alt_janela()
	janela.offset_left = -w * 0.5
	janela.offset_right = w * 0.5
	janela.offset_top = -h * 0.5
	janela.offset_bottom = h * 0.5
	add_child(janela)

	var v := UI.vbox(8)
	janela.add_child(v)

	cabecalho = UI.hbox(10)
	var ic := UI.icone(titulo_icone, UI.ACENTO, 24)
	cabecalho.add_child(ic)
	cabecalho.add_child(UI.titulo(titulo_texto, 22))
	cabecalho.add_child(UI.espacador())
	var fechar := Button.new()
	fechar.custom_minimum_size = Vector2(36, 32)
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.tooltip_text = Txt.t("fechar") + " (Esc)"
	fechar.pressed.connect(fechar_painel)
	var icf := Control.new()
	icf.set_script(load("res://scripts/ui/icone_control.gd"))
	icf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fechar.add_child(icf)
	icf.configurar("fechar", UI.TEXTO2, 16)
	cabecalho.add_child(fechar)
	v.add_child(cabecalho)
	v.add_child(UI.separador())

	corpo = UI.vbox(8)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(corpo)

func fechar_painel() -> void:
	var g = get_meta("gerente", null)
	if g != null and is_instance_valid(g):
		g.fechar()
	else:
		queue_free()

## ------------------------------------------------------------- utilidades

## Linha de item padrão: ícone + textos à esquerda, ação à direita.
func linha(icone: String, cor: Color) -> Dictionary:
	var cx := UI.painel(UI.PAINEL2.darkened(0.12), 10)
	cx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(10)
	cx.add_child(h)
	var ic := UI.icone(icone, cor, 26)
	h.add_child(ic)
	var textos := UI.vbox(1)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(textos)
	var direita := UI.hbox(6)
	direita.alignment = BoxContainer.ALIGNMENT_END
	h.add_child(direita)
	return {"caixa": cx, "icone": ic, "textos": textos, "direita": direita, "linha": h}

## Rótulo de custo colorido conforme a posse.
func custo_label(moeda: String, valor_log: float, tem: bool) -> HBoxContainer:
	var h := UI.hbox(4)
	var ic := UI.icone(Icone.da_moeda(moeda), UI.MOEDA_COR.get(moeda, UI.OURO) if tem else UI.TEXTO3, 15)
	h.add_child(ic)
	h.add_child(UI.rotulo(Fmt.big(valor_log), 14, UI.TEXTO if tem else UI.TEXTO3))
	return h

func txt(d: Dictionary, campo: String) -> String:
	return Ux.txt(d, campo, Cfg.ingles())
