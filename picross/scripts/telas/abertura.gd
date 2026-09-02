extends Control
## Abertura: o nome do jogo aparece como um puzzle sendo preenchido.

## Alfabeto próprio, 5 linhas de altura. Só as letras do título.
const GLIFOS := {
    "R": ["###.", "#..#", "###.", "#.#.", "#..#"],
    "E": ["####", "#...", "###.", "#...", "####"],
    "V": ["#..#", "#..#", "#..#", "#..#", ".##."],
    "L": ["#...", "#...", "#...", "#...", "####"],
    "A": [".##.", "#..#", "####", "#..#", "#..#"],
}
const TITULO := "REVELAR"
const CELULA := 20.0

var _logo: Array[String] = []
var _total_cheias := 0
var _preenchidas := 0.0
var _pode_seguir := false
var _tempo := 0.0

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _montar_logo()

    var animacao := create_tween()
    animacao.tween_property(self, "_preenchidas", float(_total_cheias), 1.4)
    animacao.tween_callback(func(): _pode_seguir = true)
    set_process(true)

## Junta os glifos numa grade só, com uma coluna de respiro entre as letras.
func _montar_logo() -> void:
    var linhas: Array[String] = ["", "", "", "", ""]
    for i in TITULO.length():
        var glifo: Array = GLIFOS[TITULO[i]]
        for y in 5:
            linhas[y] += glifo[y]
            if i < TITULO.length() - 1:
                linhas[y] += "."
    _logo = linhas
    _total_cheias = 0
    for linha in _logo:
        _total_cheias += linha.count("#")

func _process(delta: float) -> void:
    _tempo += delta
    queue_redraw()

func _unhandled_input(evento: InputEvent) -> void:
    var apertou: bool = (evento is InputEventKey and (evento as InputEventKey).pressed) \
        or (evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed)
    if not apertou:
        return
    if not _pode_seguir:
        _preenchidas = float(_total_cheias)   # pula a animação
        _pode_seguir = true
        return
    Audio.tocar("clique")
    Navegacao.ir_para("menu")

func _draw() -> void:
    var largura := _logo[0].length() * CELULA
    var canto := Vector2((size.x - largura) * 0.5, size.y * 0.34)
    var contador := 0
    for y in _logo.size():
        for x in _logo[y].length():
            var area := Rect2(canto + Vector2(x, y) * CELULA, Vector2(CELULA - 3, CELULA - 3))
            if _logo[y][x] == "#":
                contador += 1
                draw_rect(area, Estilo.DESTAQUE if contador <= _preenchidas else Estilo.CELULA_VAZIA)

    var fonte := get_theme_default_font()
    var base := canto.y + _logo.size() * CELULA
    draw_string(fonte, Vector2(0, base + 60), "resolva o enigma, revele a imagem",
                HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Estilo.TEXTO_SUAVE)
    if _pode_seguir:
        var pulso := 0.55 + 0.35 * sin(_tempo * 2.6)
        draw_string(fonte, Vector2(0, size.y - 80), "clique ou aperte qualquer tecla",
                    HORIZONTAL_ALIGNMENT_CENTER, size.x, 18,
                    Color(Estilo.TEXTO_SUAVE, pulso))
