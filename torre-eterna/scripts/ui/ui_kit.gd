class_name UI
extends RefCounted

## UI — tema e fábrica de widgets. Toda a interface é construída em código
## (nenhum .tscn escrito à mão), então este arquivo é a "linguagem visual".

# ------------------------------------------------------------------ paleta
const FUNDO := Color("#080b14")
const FUNDO2 := Color("#0e1424")
const PAINEL := Color("#121a2e")
const PAINEL2 := Color("#18223c")
const BORDA := Color("#243356")
const BORDA_FORTE := Color("#3b5a9e")
const TEXTO := Color("#e6ecf7")
const TEXTO2 := Color("#93a3c4")
## #5f6f92 dava 3,44:1 sobre PAINEL e 3,13:1 sobre PAINEL2 — abaixo dos 4,5:1
## que a WCAG exige para texto pequeno, e TEXTO3 é usado justamente em corpo de
## 10 a 13px: rodapé, explicação de opção, progresso de missão, custo
## indisponível. O modo de alto contraste não salvava: ele estica o gama em
## torno do meio-cinza, e como o texto e o fundo do painel são AMBOS escuros,
## os dois sobem juntos e a razão quase não muda (3,44 -> 3,48 medido). Este é
## o mesmo matiz, só claro o bastante para passar: 4,61:1 sobre PAINEL2, sem
## perder a hierarquia para o TEXTO2 (6,21:1). O portão de testes confere.
const TEXTO3 := Color("#778bb6")
const ACENTO := Color("#38bdf8")
const ACENTO2 := Color("#a78bfa")
const OURO := Color("#fbbf24")
const VERDE := Color("#4ade80")
const VERMELHO := Color("#f87171")
const LARANJA := Color("#fb923c")
const ROSA := Color("#f472b6")

const RARIDADE_COR := {
	"comum": Color("#9aa5b1"), "incomum": Color("#4ade80"), "raro": Color("#38bdf8"),
	"epico": Color("#c084fc"), "lendario": Color("#fbbf24"), "mitico": Color("#fb7185"),
}

const MOEDA_COR := {
	"ouro": Color("#fbbf24"), "gemas": Color("#f472b6"), "fragmentos": Color("#38bdf8"),
	# `#a855f7` reprovava a WCAG COMO TEXTO (3,98:1 sobre PAINEL2): o valor de
	# nucleos aparece escrito com esta cor em `UI.moeda`, nao so no icone.
	"nucleos": Color("#c084fc"), "eter": Color("#fb7185"), "poeira": Color("#94a3b8"),
}
## Nome do ícone VETORIAL de cada moeda (ver scripts/ui/icone.gd).
## Emoji não entra em texto de interface: a fonte padrão não tem glifo.
const MOEDA_ICONE := {
	"ouro": "ouro", "gemas": "gema", "fragmentos": "fragmento",
	"nucleos": "nucleo", "eter": "eter", "poeira": "poeira",
}

## A FAIXA DO RODAPE, num lugar so.
##
## O rodape de paineis e a barra de acoes vivem entre estas duas linhas, e os
## avisos (toasts) precisam parar ACIMA delas quando se mudam para baixo. Ja
## deu errado quatro vezes por serem numeros soltos em arquivos diferentes: na
## ultima, os avisos e os rotulos "Conquistas", "Codex" e "Habilidades" saiam
## impressos um por cima do outro. Quem mexer na altura da barra mexe aqui, e
## os avisos acompanham sozinhos.
const RODAPE_TOPO := -58.0
const RODAPE_BASE := -14.0
## Folga entre o que flutua e a barra.
const RODAPE_FOLGA := 12.0

# --------------------------------------------------------------- contraste

## Luminancia relativa da WCAG 2.1. Vive aqui, e nao so na suite, porque a
## interface PRECISA dela em tempo de montagem: `tingir` usa para garantir que
## fundo destacado nunca clareie.
static func luz_relativa(c: Color) -> float:
	var canais := [c.r, c.g, c.b]
	var lin: Array[float] = []
	for v in canais:
		var x := float(v)
		lin.append(x / 12.92 if x <= 0.03928 else pow((x + 0.055) / 1.055, 2.4))
	return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]

## Razao de contraste da WCAG 2.1 entre duas cores opacas.
static func contraste(a: Color, b: Color) -> float:
	var la := luz_relativa(a)
	var lb := luz_relativa(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

## FUNDO DESTACADO QUE NAO QUEBRA O CONTRASTE DE NINGUEM.
##
## Onze lugares da interface pintavam a caixa "completa"/"selecionada" com
## `PAINEL2.lerp(cor, 0.18)` — um fundo mais CLARO que o painel normal. Cada um
## desses fundos derrubava o contraste de todo texto por cima: TEXTO3 caia de
## 4,62:1 para 3,10:1, e com ele mais de trinta pares texto-fundo passavam a
## reprovar a WCAG. O portao de contraste nao via nada disso porque so conferia
## tres cores contra os dois painces lisos.
##
## `tingir` da a MESMA leitura visual (a caixa ganha o matiz do acento) sem
## nunca ficar mais clara que `PAINEL2`: se a mistura clareou, ela e escurecida
## de volta ate a luminancia do painel. Assim vale um invariante simples e
## testavel — cor de texto que passa em PAINEL2 passa em qualquer destaque.
static func tingir(cor: Color, forca: float = 0.28) -> Color:
	var alvo := PAINEL2.lerp(cor, clampf(forca, 0.0, 1.0))
	var teto := luz_relativa(PAINEL2)
	var passo := 0
	while luz_relativa(alvo) > teto and passo < 24:
		alvo = alvo.darkened(0.06)
		passo += 1
	return alvo

# ------------------------------------------------------------------ escala
static var escala := 1.0

static func px(v: float) -> int:
	return int(round(v * escala))

# ------------------------------------------------------------- stylebox

static func caixa(cor: Color, raio: int = 10, borda: int = 1, cor_borda: Color = BORDA) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.corner_radius_top_left = raio
	sb.corner_radius_top_right = raio
	sb.corner_radius_bottom_left = raio
	sb.corner_radius_bottom_right = raio
	if borda > 0:
		sb.border_width_left = borda
		sb.border_width_right = borda
		sb.border_width_top = borda
		sb.border_width_bottom = borda
		sb.border_color = cor_borda
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func caixa_vazia() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

## Tema global do jogo, gerado em código.
static func tema() -> Theme:
	var t := Theme.new()
	var fonte_base := 15
	t.default_font_size = fonte_base

	# --- Button ---
	var b_normal := caixa(PAINEL2, 8, 1, BORDA)
	var b_hover := caixa(PAINEL2.lerp(ACENTO, 0.18), 8, 1, BORDA_FORTE)
	var b_press := caixa(ACENTO.darkened(0.55), 8, 1, ACENTO)
	var b_disabled := caixa(PAINEL.darkened(0.2), 8, 1, BORDA.darkened(0.3))
	t.set_stylebox("normal", "Button", b_normal)
	t.set_stylebox("hover", "Button", b_hover)
	t.set_stylebox("pressed", "Button", b_press)
	t.set_stylebox("disabled", "Button", b_disabled)
	t.set_stylebox("focus", "Button", caixa(Color(0, 0, 0, 0), 8, 2, ACENTO))
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", TEXTO3)
	t.set_font_size("font_size", "Button", fonte_base)

	# --- Panel ---
	t.set_stylebox("panel", "Panel", caixa(PAINEL, 12, 1, BORDA))
	t.set_stylebox("panel", "PanelContainer", caixa(PAINEL, 12, 1, BORDA))

	# --- Label ---
	t.set_color("font_color", "Label", TEXTO)
	t.set_font_size("font_size", "Label", fonte_base)

	# --- ProgressBar ---
	var pb_bg := caixa(Color("#0b1120"), 6, 1, BORDA)
	pb_bg.content_margin_top = 0
	pb_bg.content_margin_bottom = 0
	var pb_fg := caixa(ACENTO, 6, 0)
	pb_fg.content_margin_top = 0
	pb_fg.content_margin_bottom = 0
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fg)
	t.set_color("font_color", "ProgressBar", TEXTO)
	t.set_font_size("font_size", "ProgressBar", 12)

	# --- ScrollContainer / abas ---
	t.set_stylebox("panel", "TabContainer", caixa(PAINEL, 12, 1, BORDA))
	t.set_stylebox("tab_selected", "TabContainer", caixa(PAINEL2, 8, 1, ACENTO))
	t.set_stylebox("tab_unselected", "TabContainer", caixa(FUNDO2, 8, 1, BORDA))
	t.set_color("font_selected_color", "TabContainer", Color.WHITE)
	t.set_color("font_unselected_color", "TabContainer", TEXTO2)

	# --- LineEdit / TextEdit ---
	t.set_stylebox("normal", "LineEdit", caixa(Color("#0b1120"), 8, 1, BORDA))
	t.set_stylebox("focus", "LineEdit", caixa(Color("#0b1120"), 8, 2, ACENTO))
	t.set_color("font_color", "LineEdit", TEXTO)
	t.set_stylebox("normal", "TextEdit", caixa(Color("#0b1120"), 8, 1, BORDA))
	t.set_color("font_color", "TextEdit", TEXTO)

	# --- CheckButton / CheckBox ---
	t.set_color("font_color", "CheckButton", TEXTO)
	t.set_color("font_color", "CheckBox", TEXTO)

	# --- HSlider ---
	t.set_stylebox("slider", "HSlider", caixa(Color("#0b1120"), 4, 1, BORDA))
	t.set_stylebox("grabber_area", "HSlider", caixa(ACENTO, 4, 0))

	# --- OptionButton ---
	t.set_stylebox("normal", "OptionButton", b_normal)
	t.set_stylebox("hover", "OptionButton", b_hover)
	t.set_stylebox("pressed", "OptionButton", b_press)
	t.set_color("font_color", "OptionButton", TEXTO)

	# --- PopupMenu ---
	t.set_stylebox("panel", "PopupMenu", caixa(PAINEL, 10, 1, BORDA_FORTE))
	t.set_color("font_color", "PopupMenu", TEXTO)
	return t

# ------------------------------------------------------------- widgets

## A LETRA DO JOGO PASSA POR AQUI, e é por isso que uma linha resolve a tela
## inteira. Todo texto do jogo nasce de `rotulo` ou de `titulo`: aplicar a fonte
## nesses dois pontos veste as 52 telas de uma vez, sem tocar em nenhuma delas.
##
## `Tipografia.ui()` devolve `null` quando as fontes não estão instaladas (elas
## não são versionadas — ver `fontes/FONTES.md`), e `null` aqui quer dizer "não
## sobrescreva nada", ou seja, continua a fonte do motor. O jogo abre igual.
static func _vestir(l: Label, de_titulo: bool) -> void:
	var f := Tipografia.titulo(Cfg.v.get("idioma", "pt")) if de_titulo else Tipografia.ui(Cfg.v.get("idioma", "pt"))
	if f != null:
		l.add_theme_font_override("font", f)

static func rotulo(texto: String, tamanho: int = 15, cor: Color = TEXTO, negrito: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	_vestir(l, false)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if negrito:
		l.add_theme_color_override("font_outline_color", cor.darkened(0.6))
		l.add_theme_constant_override("outline_size", 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# O padrão do Label no Godot é `MOUSE_FILTER_IGNORE`, e é por aqui que sai
	# quase todo texto do jogo. Com IGNORE o nó nunca recebe o mouse, e
	# `tooltip_text` posto nele vira decoração: a dica não abre nunca. PASS (e
	# não STOP) porque o rótulo passa a receber o evento sem tirá-lo de quem
	# está atrás — nada que já funcionava para de funcionar.
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	return l

## Faz toda dica da subárvore ser alcançável pelo mouse.
##
## `tooltip_text` num nó que não recebe mouse é decoração: a dica nunca abre. E
## não basta o nó — um ancestral `MOUSE_FILTER_IGNORE` engole o evento antes de
## ele descer. As caixas do HUD e dos painéis são IGNORE de propósito (para não
## roubar clique do campo), então quem escrevia uma dica ali escrevia no vazio.
## Esta varredura sobe de cada nó com dica até a raiz e troca IGNORE por PASS —
## PASS recebe o evento e continua passando adiante, então nada que já
## funcionava para de funcionar. Roda uma vez, quando a tela termina de montar.
static func liberar_dicas(raiz: Node) -> int:
	var abertos := 0
	for no in _com_dica(raiz):
		var atual: Node = no
		while atual != null and atual != raiz.get_parent():
			if atual is Control and (atual as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE:
				(atual as Control).mouse_filter = Control.MOUSE_FILTER_PASS
				abertos += 1
			atual = atual.get_parent()
	return abertos

static func _com_dica(no: Node) -> Array:
	var out: Array = []
	if no is Control and str((no as Control).tooltip_text) != "":
		out.append(no)
	for filho in no.get_children():
		out.append_array(_com_dica(filho))
	return out

static func titulo(texto: String, tamanho: int = 22) -> Label:
	var l := rotulo(texto, tamanho, Color.WHITE)
	_vestir(l, true)
	l.add_theme_color_override("font_outline_color", ACENTO.darkened(0.7))
	l.add_theme_constant_override("outline_size", 0)
	return l

## NAVEGACAO POR TECLADO. Eram 296 controles interativos e 11 focaveis, NENHUM
## deles um `Button`: todo botao nascia `FOCUS_NONE`, entao Tab nao andava, Enter
## nao acionava e quem nao usa mouse simplesmente nao jogava. O tema ja tinha o
## contorno de foco desenhado desde sempre — so nao havia o que contornar.
##
## O botao do rodape do HUD continua sem foco de proposito: aquilo e barra de
## ferramentas por cima da arena, tem atalho proprio (Q/W/E/R/T/O) e um anel de
## foco piscando sobre o campo atrapalharia mais do que ajuda.
static func botao(texto: String, ao_clicar: Callable = Callable(), dica: String = "") -> Button:
	var b := Button.new()
	b.text = texto
	var fb := Tipografia.ui(Cfg.v.get("idioma", "pt"))
	if fb != null:
		b.add_theme_font_override("font", fb)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if dica != "":
		b.tooltip_text = dica
	if ao_clicar.is_valid():
		b.pressed.connect(ao_clicar)
	return b

static func botao_icone(icone: String, dica: String, ao_clicar: Callable) -> Button:
	var b := botao(icone, ao_clicar, dica)
	b.custom_minimum_size = Vector2(40, 40)
	b.add_theme_font_size_override("font_size", 19)
	return b

## Um ícone vetorial pronto para entrar num container.
##
## O mesmo trio `Control.new()` + `set_script(load(...))` + `configurar(...)`
## estava repetido 60 vezes espalhado por 18 arquivos. Aqui ele tem um nome, e
## o caminho do script aparece UMA vez — mover ou renomear o desenhador de
## ícones deixa de ser uma caçada.
const SCRIPT_ICONE := preload("res://scripts/ui/icone_control.gd")

static func icone(nome: String, cor: Color = TEXTO, tamanho: int = 18) -> Control:
	var ic := Control.new()
	ic.set_script(SCRIPT_ICONE)
	ic.configurar(nome, cor, tamanho)
	return ic

static func vbox(sep: int = 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

## Quantas colunas de `larg_ficha` cabem em `larg_util`, no maximo `teto`.
##
## Grade com numero fixo de colunas cabe na escala em que foi escrita e em mais
## nenhuma. Com a interface a 1,25 a janela logica encolhe de 1280 para 1024, e
## quatro paineis (Reliquias, Missoes, Codex, Prestigio) passavam a ter rolagem
## horizontal — conteudo escondido atras de um gesto que ninguem faz numa grade.
## A varredura de layout (`--auditar-ui`) acha isso em segundos; esta funcao e
## o conserto, num lugar so, para as quatro.
static func colunas(larg_util: float, larg_ficha: float, sep: float, teto: int) -> int:
	if larg_ficha <= 0.0:
		return 1
	var n := int(floor((larg_util + sep) / (larg_ficha + sep)))
	return clampi(n, 1, teto)

## Largura util de um painel: a janela logica menos a moldura dele.
##
## A janela logica ja vem dividida pela escala da interface (`content_scale`),
## entao 1280 vira 1024 a 1,25 sem ninguem precisar dividir nada na mao.
static func larg_util_painel(no: Control, moldura: float = 190.0) -> float:
	return maxf(240.0, no.get_viewport_rect().size.x - moldura)

static func hbox(sep: int = 6) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func espacador(min_size: float = 0.0, horizontal: bool = true) -> Control:
	var c := Control.new()
	if horizontal:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.custom_minimum_size.x = min_size
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c.custom_minimum_size.y = min_size
	return c

static func separador() -> HSeparator:
	var s := HSeparator.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = BORDA
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	s.add_theme_stylebox_override("separator", sb)
	return s

static func painel(cor: Color = PAINEL, raio: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", caixa(cor, raio, 1, BORDA))
	return p

static func barra(cor: Color = ACENTO, altura: int = 10) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size.y = altura
	pb.max_value = 1.0
	pb.step = 0.0001
	var fg := caixa(cor, altura / 2, 0)
	fg.content_margin_top = 0
	fg.content_margin_bottom = 0
	pb.add_theme_stylebox_override("fill", fg)
	return pb

static func scroll() -> ScrollContainer:
	var sc := ScrollContainer.new()
	# AUTO, não DISABLED. Com a escala da interface acima de 1,05 a tela lógica
	# encolhe e há conteúdo que não consegue mais estreitar — coluna de pontos,
	# data, botões de filtro. Com a rolagem horizontal desligada esse conteúdo
	# simplesmente ficava fora da tela, sem nenhum jeito de alcançá-lo. A barra
	# só aparece quando de fato não coube, então em 1,0 nada muda.
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.follow_focus = true
	return sc

## Texto de moeda com ícone e cor.
static func moeda(chave: String, valor_log: float, tamanho: int = 15) -> HBoxContainer:
	var h := hbox(4)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(str(MOEDA_ICONE.get(chave, "ouro")), MOEDA_COR.get(chave, TEXTO), float(tamanho))
	h.add_child(rotulo(Fmt.big(valor_log), tamanho, MOEDA_COR.get(chave, TEXTO)))
	return h

static func cor_raridade(r: String) -> Color:
	return RARIDADE_COR.get(r, TEXTO2)

## Pisca um Control (feedback de compra).
static func pulsar(no: Control, cor: Color = VERDE) -> void:
	if not is_instance_valid(no):
		return
	var t := no.create_tween()
	no.modulate = cor.lerp(Color.WHITE, 0.3)
	t.tween_property(no, "modulate", Color.WHITE, 0.35)

## Anima a escala de um Control a partir do centro.
static func saltar(no: Control, forca: float = 1.15) -> void:
	if not is_instance_valid(no):
		return
	no.pivot_offset = no.size * 0.5
	no.scale = Vector2.ONE * forca
	var t := no.create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(no, "scale", Vector2.ONE, 0.3)
