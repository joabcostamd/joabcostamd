extends Control
class_name FundoAnimado
## Fundo do jogo: um brilho suave no centro, poeira flutuando e uma vinheta.
## Sem shader — tudo desenhado, para funcionar em qualquer máquina.

const POEIRA := 34

## Cada capítulo tem seu tom no brilho de fundo: dá identidade sem atrapalhar
## a leitura, porque a cor entra em opacidade baixíssima.
const TONS_POR_CAPITULO := [
    Color("#6ab0d6"), Color("#7fc48c"), Color("#e0a45f"),
    Color("#c98fd6"), Color("#e0707f"),
]

var tom := Color("#6ab0d6")
var _animado := true
var _tempo := 0.0
var _poeira: Array[Vector3] = []   # x, y, velocidade
var _fases: Array[float] = []

func _ready() -> void:
    # Este nó vive dentro de um CanvasLayer, que não é um Control: sem um pai
    # Control os anchors não têm a que se ancorar e o tamanho fica zerado.
    # Por isso o tamanho é copiado do viewport, e recopiado quando ele muda.
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _acompanhar_tela()
    get_viewport().size_changed.connect(_acompanhar_tela)
    _animado = bool(Progresso.opcoes.get("fundo_animado", true))
    for i in POEIRA:
        _poeira.append(Vector3(randf(), randf(), randf_range(0.004, 0.017)))
        _fases.append(randf() * TAU)
    set_process(true)

## Define o tom do fundo pelo capítulo (0 a 4).
static func tom_do_capitulo(indice: int) -> Color:
    return TONS_POR_CAPITULO[clampi(indice, 0, TONS_POR_CAPITULO.size() - 1)]

func _acompanhar_tela() -> void:
    position = Vector2.ZERO
    size = get_viewport_rect().size

func _process(delta: float) -> void:
    if not _animado:
        set_process(false)
        queue_redraw()
        return
    _tempo += delta
    for i in _poeira.size():
        var p := _poeira[i]
        p.y -= p.z * delta * 5.0
        if p.y < -0.05:
            p.y = 1.05
            p.x = randf()
        _poeira[i] = p
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Estilo.FUNDO)

    # Brilho central: círculos concêntricos bem transparentes, do maior ao menor.
    var centro := size * Vector2(0.5, 0.42)
    var raio := maxf(size.x, size.y) * 0.62
    var pulso := 1.0 + 0.03 * sin(_tempo * 0.7)
    # Muitas camadas bem fracas: com poucas, as bordas dos círculos aparecem
    # como anéis em vez de um brilho contínuo.
    for i in 18:
        var t := float(i) / 17.0
        var cor := tom.lerp(Estilo.DESTAQUE, t * 0.35)
        draw_circle(centro, raio * (1.0 - t * 0.85) * pulso, Color(cor, 0.007))

    if not _animado:
        return
    for i in _poeira.size():
        var p := _poeira[i]
        var brilho := 0.16 + 0.12 * sin(_tempo * 1.4 + _fases[i])
        var posicao := Vector2(p.x * size.x, p.y * size.y)
        draw_circle(posicao, 1.6 + 1.2 * sin(_fases[i]), Color(Estilo.TEXTO, brilho))

    # Vinheta: bordas escuras para o olho ir ao centro.
    var faixa := size.y * 0.20
    for i in 12:
        var t := float(i) / 11.0
        var alfa := 0.055 * (1.0 - t)
        var espessura := faixa * (1.0 - t) / 12.0 + 2.0
        draw_rect(Rect2(0, t * faixa / 2.0, size.x, espessura), Color(0, 0, 0, alfa))
        draw_rect(Rect2(0, size.y - t * faixa / 2.0 - espessura, size.x, espessura), Color(0, 0, 0, alfa))
        draw_rect(Rect2(t * faixa / 3.0, 0, espessura, size.y), Color(0, 0, 0, alfa))
        draw_rect(Rect2(size.x - t * faixa / 3.0 - espessura, 0, espessura, size.y), Color(0, 0, 0, alfa))
