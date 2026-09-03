extends CharacterBody2D
class_name Jogador

const VELOCIDADE := 200.0
const FORCA_PULO := -380.0
const GRAVIDADE := 1100.0
const TEMPO_COYOTE := 0.10   # pulo ainda vale por um instante depois de sair da borda
const BUFFER_PULO := 0.10    # pulo apertado um pouco antes de pousar ainda vale

## Intenção de movimento. O teclado escreve aqui, e os testes também —
## é isso que deixa o jogo testável sem tela e sem simular teclas.
var intencao_x := 0.0
var intencao_pulo := false
var ler_teclado := true

var _coyote := 0.0
var _buffer := 0.0

func _physics_process(delta: float) -> void:
    if ler_teclado:
        intencao_x = Input.get_axis("mover_esquerda", "mover_direita")
        if Input.is_action_just_pressed("pular"):
            intencao_pulo = true

    if is_on_floor():
        _coyote = TEMPO_COYOTE
    else:
        _coyote = maxf(_coyote - delta, 0.0)

    if intencao_pulo:
        _buffer = BUFFER_PULO
        intencao_pulo = false
    else:
        _buffer = maxf(_buffer - delta, 0.0)

    velocity.x = intencao_x * VELOCIDADE
    velocity.y += GRAVIDADE * delta

    if _buffer > 0.0 and _coyote > 0.0:
        velocity.y = FORCA_PULO
        _buffer = 0.0
        _coyote = 0.0

    move_and_slide()

func _draw() -> void:
    draw_rect(Rect2(-10, -14, 20, 28), Color("e05a47"))
    draw_rect(Rect2(-6, -9, 4, 4), Color.WHITE)
    draw_rect(Rect2(2, -9, 4, 4), Color.WHITE)
