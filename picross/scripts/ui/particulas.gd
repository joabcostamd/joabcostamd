extends Control
class_name CamadaParticulas
## Partículas desenhadas num nó só. Cada tela ganha uma camada dessas, e
## qualquer parte do jogo pode pedir um jato de faíscas por cima de tudo.

const GRUPO := "camada_particulas"

class Faisca:
    var posicao: Vector2
    var velocidade: Vector2
    var cor: Color
    var vida: float
    var vida_total: float
    var tamanho: float
    var gravidade: float
    var giro: float

var _faiscas: Array[Faisca] = []

func _ready() -> void:
    add_to_group(GRUPO)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Mesmo motivo do fundo: dentro de um CanvasLayer não há pai Control para
    # os anchors, então o tamanho vem do viewport.
    _acompanhar_tela()
    get_viewport().size_changed.connect(_acompanhar_tela)
    set_process(true)

func _acompanhar_tela() -> void:
    position = Vector2.ZERO
    size = get_viewport_rect().size

## Jato curto de faíscas — o feedback de "algo aconteceu aqui".
func jato(posicao: Vector2, cor: Color, quantidade := 8, forca := 130.0,
          gravidade := 420.0, tamanho := 4.0) -> void:
    for i in quantidade:
        var f := Faisca.new()
        var angulo := randf() * TAU
        f.posicao = posicao
        f.velocidade = Vector2(cos(angulo), sin(angulo)) * forca * randf_range(0.35, 1.0)
        f.cor = cor
        f.vida_total = randf_range(0.32, 0.62)
        f.vida = f.vida_total
        f.tamanho = tamanho * randf_range(0.6, 1.3)
        f.gravidade = gravidade
        f.giro = randf_range(-6.0, 6.0)
        _faiscas.append(f)

## Chuva de confete vinda de cima — usada quando a imagem é revelada.
func confete(largura: float, cores: Array, quantidade := 90) -> void:
    for i in quantidade:
        var f := Faisca.new()
        f.posicao = Vector2(randf() * largura, randf_range(-260.0, -20.0))
        f.velocidade = Vector2(randf_range(-45.0, 45.0), randf_range(90.0, 220.0))
        f.cor = cores[randi() % cores.size()]
        f.vida_total = randf_range(2.0, 3.4)
        f.vida = f.vida_total
        f.tamanho = randf_range(4.0, 8.0)
        f.gravidade = 90.0
        f.giro = randf_range(-4.0, 4.0)
        _faiscas.append(f)

## Onda de faíscas ao longo de um segmento: a linha que acabou de fechar.
func varrer(inicio: Vector2, fim: Vector2, cor: Color, pontos := 14) -> void:
    for i in pontos:
        var t := float(i) / maxf(float(pontos - 1), 1.0)
        var f := Faisca.new()
        f.posicao = inicio.lerp(fim, t)
        f.velocidade = Vector2(randf_range(-30.0, 30.0), randf_range(-90.0, -30.0))
        f.cor = cor
        f.vida_total = randf_range(0.4, 0.75)
        f.vida = f.vida_total
        f.tamanho = randf_range(3.0, 6.0)
        f.gravidade = 180.0
        f.giro = randf_range(-3.0, 3.0)
        _faiscas.append(f)

func _process(delta: float) -> void:
    if _faiscas.is_empty():
        return
    for i in range(_faiscas.size() - 1, -1, -1):
        var f := _faiscas[i]
        f.vida -= delta
        if f.vida <= 0.0:
            _faiscas.remove_at(i)
            continue
        f.velocidade.y += f.gravidade * delta
        f.velocidade.x *= 1.0 - 1.2 * delta
        f.posicao += f.velocidade * delta
    queue_redraw()

func _draw() -> void:
    for f in _faiscas:
        var restante := f.vida / f.vida_total
        var cor := Color(f.cor, clampf(restante * 1.4, 0.0, 1.0))
        var lado := f.tamanho * (0.4 + 0.6 * restante)
        draw_rect(Rect2(f.posicao - Vector2(lado, lado) * 0.5, Vector2(lado, lado)), cor)
