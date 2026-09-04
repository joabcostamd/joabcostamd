extends Control
## Desenha a folha de contato: os oito temas lado a lado, cada um com o nome e
## a sensação que ele carrega. Existe para a escolha ser feita olhando os oito
## de uma vez, que é como o olho compara.

var colunas := 2
var celula := Vector2(620, 349)
var rotulo := 30.0
var pad := 14.0

## As texturas precisam viver fora do `_draw()`. Os comandos de desenho são
## gravados e só executam depois que a função retorna: uma ImageTexture criada
## na hora é liberada antes disso, e o que sobra na tela é um retângulo branco.
var _texturas: Array[ImageTexture] = []

func _ready() -> void:
    for i in Temas.total():
        var caminho := ProjectSettings.globalize_path(
            "res://maquete/capturas/%s-paisagem.png" % Temas.dados(i)["id"])
        var imagem := Image.load_from_file(caminho)
        if imagem == null:
            push_error("folha: não carreguei " + caminho)
            continue
        _texturas.append(ImageTexture.create_from_image(imagem))
    queue_redraw()

func _draw() -> void:
    # Exceção deliberada à regra "nenhuma cor literal fora dos tokens": a folha
    # de contato é FERRAMENTA, não tela de jogo. Ela precisa de fundo neutro
    # fixo — se usasse o tema vigente, contaminaria a comparação entre os oito.
    draw_rect(Rect2(Vector2.ZERO, size), Color("#15171c"))
    var fonte: FontFile = Temas.fonte(true)
    var fonte_fina: FontFile = Temas.fonte()

    for i in mini(_texturas.size(), Temas.total()):
        var t := Temas.dados(i)
        var col := i % colunas
        var lin := i / colunas
        var origem := Vector2(pad + col * (celula.x + pad),
                              pad + lin * (celula.y + rotulo + pad))

        draw_texture_rect(_texturas[i], Rect2(origem, celula), false)
        draw_rect(Rect2(origem, celula), Color(1, 1, 1, 0.10), false, 1.0)

        var y := origem.y + celula.y + 20.0
        draw_string(fonte, Vector2(origem.x, y), "%d." % (i + 1),
                    HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#7f879a"))
        draw_string(fonte, Vector2(origem.x + 24, y), str(t["nome"]),
                    HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#eef1f7"))
        var largura := fonte.get_string_size(str(t["nome"]), HORIZONTAL_ALIGNMENT_LEFT,
                                             -1, 15).x
        draw_string(fonte_fina, Vector2(origem.x + 34 + largura, y),
                    "· " + str(t["sensacao"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
                    Color("#7f879a"))
