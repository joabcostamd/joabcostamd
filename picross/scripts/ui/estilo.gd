extends RefCounted
class_name Estilo
## Paleta e tema únicos do jogo. Toda tela chama Estilo.aplicar(raiz).

## As cores são variáveis, não constantes: o jogo troca entre tema escuro e
## claro em tempo de execução, e tudo que desenha lê daqui.
static var FUNDO := Color("#12151f")
static var FUNDO_ALTO := Color("#1a1f2e")
static var PAINEL := Color("#1c2130")
static var BORDA := Color("#2f3750")
static var TEXTO := Color("#e8ecf5")
static var TEXTO_SUAVE := Color("#98a2bd")
static var DESTAQUE := Color("#f0c05a")
static var ACENTO := Color("#6ab0d6")
static var ERRO := Color("#e0655f")
static var SUCESSO := Color("#6fc48c")
static var CELULA_VAZIA := Color("#232a3d")
static var CELULA_CHEIA := Color("#e8ecf5")
static var GRADE := Color("#39415c")
static var GRADE_FORTE := Color("#5a6a91")

const ESCURO := {
    "FUNDO": "#12151f", "FUNDO_ALTO": "#1a1f2e", "PAINEL": "#1c2130",
    "BORDA": "#2f3750", "TEXTO": "#e8ecf5", "TEXTO_SUAVE": "#98a2bd",
    "DESTAQUE": "#f0c05a", "ACENTO": "#6ab0d6", "ERRO": "#e0655f",
    "SUCESSO": "#6fc48c", "CELULA_VAZIA": "#232a3d", "CELULA_CHEIA": "#e8ecf5",
    "GRADE": "#39415c", "GRADE_FORTE": "#5a6a91",
}

## No tema claro a célula pintada vira escura: o que importa é o contraste
## com o fundo, não a cor em si.
const CLARO := {
    "FUNDO": "#eef1f7", "FUNDO_ALTO": "#e3e8f2", "PAINEL": "#ffffff",
    "BORDA": "#c2cadb", "TEXTO": "#1b2030", "TEXTO_SUAVE": "#5d6884",
    "DESTAQUE": "#c98a1e", "ACENTO": "#2f7fb5", "ERRO": "#cc4a44",
    "SUCESSO": "#2f8f5c", "CELULA_VAZIA": "#dbe2ef", "CELULA_CHEIA": "#232a3d",
    "GRADE": "#b3bcd0", "GRADE_FORTE": "#7c869d",
}

## Paleta de alto contraste, para quem precisa de mais separação entre estados.
const ALTO_CONTRASTE_ESCURO := {
    "FUNDO": "#000000", "FUNDO_ALTO": "#111111", "PAINEL": "#141414",
    "BORDA": "#7a7a7a", "TEXTO": "#ffffff", "TEXTO_SUAVE": "#c8c8c8",
    "DESTAQUE": "#ffd400", "ACENTO": "#4fc3ff", "ERRO": "#ff6b5e",
    "SUCESSO": "#5ee08a", "CELULA_VAZIA": "#1a1a1a", "CELULA_CHEIA": "#ffffff",
    "GRADE": "#5a5a5a", "GRADE_FORTE": "#9a9a9a",
}

const ALTO_CONTRASTE_CLARO := {
    "FUNDO": "#ffffff", "FUNDO_ALTO": "#f0f0f0", "PAINEL": "#ffffff",
    "BORDA": "#404040", "TEXTO": "#000000", "TEXTO_SUAVE": "#3a3a3a",
    "DESTAQUE": "#a86400", "ACENTO": "#0b5f8f", "ERRO": "#b32018",
    "SUCESSO": "#0f6b3c", "CELULA_VAZIA": "#e6e6e6", "CELULA_CHEIA": "#000000",
    "GRADE": "#8a8a8a", "GRADE_FORTE": "#404040",
}

static var tema_claro := false
static var alto_contraste := false

## Troca a paleta inteira e joga fora o Theme, para ele ser remontado com as
## cores novas na próxima tela.
static func usar_tema(claro: bool, contraste_alto := false) -> void:
    tema_claro = claro
    alto_contraste = contraste_alto
    var paleta: Dictionary
    if contraste_alto:
        paleta = ALTO_CONTRASTE_CLARO if claro else ALTO_CONTRASTE_ESCURO
    else:
        paleta = CLARO if claro else ESCURO
    FUNDO = Color(paleta["FUNDO"])
    FUNDO_ALTO = Color(paleta["FUNDO_ALTO"])
    PAINEL = Color(paleta["PAINEL"])
    BORDA = Color(paleta["BORDA"])
    TEXTO = Color(paleta["TEXTO"])
    TEXTO_SUAVE = Color(paleta["TEXTO_SUAVE"])
    DESTAQUE = Color(paleta["DESTAQUE"])
    ACENTO = Color(paleta["ACENTO"])
    ERRO = Color(paleta["ERRO"])
    SUCESSO = Color(paleta["SUCESSO"])
    CELULA_VAZIA = Color(paleta["CELULA_VAZIA"])
    CELULA_CHEIA = Color(paleta["CELULA_CHEIA"])
    GRADE = Color(paleta["GRADE"])
    GRADE_FORTE = Color(paleta["GRADE_FORTE"])
    _tema = null

static var _tema: Theme = null

const FONTE_BASE := "res://recursos/fontes/Nunito-Regular.ttf"
const FONTE_FORTE := "res://recursos/fontes/Nunito-Bold.ttf"
const FONTES_CJK := ["res://recursos/fontes/cjk-ja.ttf",
                     "res://recursos/fontes/cjk-ko.ttf",
                     "res://recursos/fontes/cjk-zh.ttf"]

static var _fonte: FontFile = null
static var _fonte_forte: FontFile = null

## Nunito para as línguas de alfabeto latino, cirílico e grego, com as fontes
## japonesa, coreana e chinesa como reserva. O Godot troca de fonte por glifo,
## então uma frase mista sai correta sem nenhum código extra.
static func fonte(forte := false) -> FontFile:
    if forte and _fonte_forte != null:
        return _fonte_forte
    if not forte and _fonte != null:
        return _fonte
    var arquivo: FontFile = load(FONTE_FORTE if forte else FONTE_BASE)
    if arquivo == null:
        return null
    var copia: FontFile = arquivo.duplicate()
    var reservas: Array[Font] = []
    for caminho in FONTES_CJK:
        var reserva := load(caminho)
        if reserva != null:
            reservas.append(reserva)
    copia.fallbacks = reservas
    if forte:
        _fonte_forte = copia
    else:
        _fonte = copia
    return copia

static func tema() -> Theme:
    if _tema != null:
        return _tema
    var t := Theme.new()
    t.default_font_size = 18
    var base := fonte()
    if base != null:
        t.default_font = base
    var forte := fonte(true)
    if forte != null:
        t.set_font("font", "Button", forte)

    t.set_stylebox("normal", "Button", _caixa(PAINEL, BORDA))
    t.set_stylebox("hover", "Button", _caixa(FUNDO_ALTO, ACENTO))
    t.set_stylebox("pressed", "Button", _caixa(BORDA, ACENTO))
    # As cores do estado desabilitado precisam sair da paleta: fixas no código,
    # elas continuavam escuras no tema claro.
    t.set_stylebox("disabled", "Button", _caixa(FUNDO_ALTO, Color(BORDA, 0.45)))
    t.set_stylebox("focus", "Button", _caixa(Color(0, 0, 0, 0), ACENTO))
    t.set_color("font_color", "Button", TEXTO)
    t.set_color("font_hover_color", "Button", DESTAQUE)
    t.set_color("font_pressed_color", "Button", DESTAQUE)
    t.set_color("font_disabled_color", "Button", Color(TEXTO_SUAVE, 0.55))
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

## `capitulo` tinge o brilho do fundo com a cor daquele capítulo.
static func aplicar(raiz: Control, capitulo := -1) -> void:
    raiz.theme = tema()

    # O fundo vai numa camada própria atrás de tudo. Como filho comum ele
    # cobriria o _draw() da própria tela, que o Godot pinta antes dos filhos.
    var atras := CanvasLayer.new()
    atras.layer = -10
    var fundo := FundoAnimado.new()
    if capitulo >= 0:
        fundo.tom = FundoAnimado.tom_do_capitulo(capitulo)
    atras.add_child(fundo)
    raiz.add_child(atras)

    # E as partículas vão numa camada na frente de tudo.
    var frente := CanvasLayer.new()
    frente.layer = 50
    frente.add_child(CamadaParticulas.new())
    raiz.add_child(frente)

    Juice.observar(raiz)

static func titulo(texto: String, tamanho := 44, cor := TEXTO) -> Label:
    var rotulo := Label.new()
    rotulo.text = texto
    var forte := fonte(true)
    if forte != null:
        rotulo.add_theme_font_override("font", forte)
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
