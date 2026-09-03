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
const TEXTO3 := Color("#5f6f92")
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
	"nucleos": Color("#a855f7"), "eter": Color("#fb7185"), "poeira": Color("#94a3b8"),
}
const MOEDA_ICONE := {
	"ouro": "🪙", "gemas": "💎", "fragmentos": "💠", "nucleos": "🌌", "eter": "✴️", "poeira": "✨",
}

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

static func rotulo(texto: String, tamanho: int = 15, cor: Color = TEXTO, negrito: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if negrito:
		l.add_theme_color_override("font_outline_color", cor.darkened(0.6))
		l.add_theme_constant_override("outline_size", 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

static func titulo(texto: String, tamanho: int = 22) -> Label:
	var l := rotulo(texto, tamanho, Color.WHITE)
	l.add_theme_color_override("font_outline_color", ACENTO.darkened(0.7))
	l.add_theme_constant_override("outline_size", 0)
	return l

static func botao(texto: String, ao_clicar: Callable = Callable(), dica: String = "") -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
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

static func vbox(sep: int = 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

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
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.follow_focus = true
	return sc

## Texto de moeda com ícone e cor.
static func moeda(chave: String, valor_log: float, tamanho: int = 15) -> HBoxContainer:
	var h := hbox(4)
	h.add_child(rotulo(str(MOEDA_ICONE.get(chave, "•")), tamanho))
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
