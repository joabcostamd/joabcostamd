extends RefCounted
class_name Estilo
## Paleta e tema únicos do jogo. Toda tela chama Estilo.aplicar(raiz).

const FUNDO := Color("#12151f")
const FUNDO_ALTO := Color("#1a1f2e")
const PAINEL := Color("#1c2130")
const BORDA := Color("#2f3750")
const TEXTO := Color("#e8ecf5")
const TEXTO_SUAVE := Color("#98a2bd")
const DESTAQUE := Color("#f0c05a")
const ACENTO := Color("#6ab0d6")
const ERRO := Color("#e0655f")
const SUCESSO := Color("#6fc48c")
const CELULA_VAZIA := Color("#232a3d")
const CELULA_CHEIA := Color("#e8ecf5")
const GRADE := Color("#39415c")
const GRADE_FORTE := Color("#5a6a91")

static var _tema: Theme = null

static func tema() -> Theme:
    if _tema != null:
        return _tema
    var t := Theme.new()
    t.default_font_size = 18

    t.set_stylebox("normal", "Button", _caixa(PAINEL, BORDA))
    t.set_stylebox("hover", "Button", _caixa(FUNDO_ALTO, ACENTO))
    t.set_stylebox("pressed", "Button", _caixa(BORDA, ACENTO))
    t.set_stylebox("disabled", "Button", _caixa(Color("#171b26"), Color("#242a3a")))
    t.set_stylebox("focus", "Button", _caixa(Color(0, 0, 0, 0), ACENTO))
    t.set_color("font_color", "Button", TEXTO)
    t.set_color("font_hover_color", "Button", DESTAQUE)
    t.set_color("font_pressed_color", "Button", DESTAQUE)
    t.set_color("font_disabled_color", "Button", Color("#4a5268"))
    t.set_font_size("font_size", "Button", 20)

    t.set_color("font_color", "Label", TEXTO)
    t.set_stylebox("panel", "PanelContainer", _caixa(PAINEL, BORDA))

    var deslizante := StyleBoxFlat.new()
    deslizante.bg_color = BORDA
    deslizante.set_corner_radius_all(4)
    deslizante.content_margin_top = 4
    deslizante.content_margin_bottom = 4
    t.set_stylebox("slider", "HSlider", deslizante)
    var preenchido := StyleBoxFlat.new()
    preenchido.bg_color = ACENTO
    preenchido.set_corner_radius_all(4)
    t.set_stylebox("grabber_area", "HSlider", preenchido)
    t.set_stylebox("grabber_area_highlight", "HSlider", preenchido)

    _tema = t
    return t

static func _caixa(fundo: Color, borda: Color) -> StyleBoxFlat:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = fundo
    caixa.border_color = borda
    caixa.set_border_width_all(2)
    caixa.set_corner_radius_all(8)
    caixa.content_margin_left = 22
    caixa.content_margin_right = 22
    caixa.content_margin_top = 11
    caixa.content_margin_bottom = 11
    return caixa

static func aplicar(raiz: Control) -> void:
    raiz.theme = tema()
    # O fundo vai numa camada própria atrás de tudo. Como filho comum ele
    # cobriria o _draw() da própria tela, que o Godot pinta antes dos filhos.
    var camada := CanvasLayer.new()
    camada.layer = -10
    var fundo := ColorRect.new()
    fundo.color = FUNDO
    fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
    fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    camada.add_child(fundo)
    raiz.add_child(camada)

static func titulo(texto: String, tamanho := 44, cor := TEXTO) -> Label:
    var rotulo := Label.new()
    rotulo.text = texto
    rotulo.add_theme_font_size_override("font_size", tamanho)
    rotulo.add_theme_color_override("font_color", cor)
    rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return rotulo

static func legenda(texto: String, tamanho := 17, cor := TEXTO_SUAVE) -> Label:
    return titulo(texto, tamanho, cor)

static func botao(texto: String, largura := 320.0) -> Button:
    var b := Button.new()
    b.text = texto
    b.custom_minimum_size = Vector2(largura, 54)
    return b

## Estrelas em texto, do jeito que aparecem em toda tela do jogo.
static func estrelas_texto(quantas: int) -> String:
    return "★".repeat(quantas) + "☆".repeat(3 - quantas)

static func tempo_texto(segundos: float) -> String:
    var total := int(segundos)
    return "%d:%02d" % [total / 60, total % 60]
