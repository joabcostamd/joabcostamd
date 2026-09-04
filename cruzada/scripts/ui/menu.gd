extends Control
class_name Menu
## O menu. Três botões e o nome do jogo.
##
## A frase única fica embaixo do título porque ela É o tutorial: quem lê "cada
## carta pontua em duas mãos de pôquer" já sabe o suficiente para o turno 1, e
## quem não lê descobre na primeira colheita. Nenhuma tela de tutorial.

signal jogar
signal temas
signal desafio

const FRASE := "Cada carta pontua em duas mãos de pôquer:\na fileira e a coluna onde você a colocar."

var perfil: Perfil
var _poeira: Array[Vector3] = []
var _botoes: Array[Rect2] = []
var _sob_o_dedo := -1

func _ready() -> void:
    _poeira = Pintura.semear_poeira()
    set_process_input(false)

func _itens() -> Array[String]:
    ## O DESAFIO fica ao lado de JOGAR, não escondido em configurações: escolher
    ## quanto se quer apanhar é parte de começar a partida.
    var lista: Array[String] = ["JOGAR", "DESAFIO", "TEMAS"]
    return lista

func _gui_input(evento: InputEvent) -> void:
    if evento is InputEventMouseMotion:
        var antes := _sob_o_dedo
        _sob_o_dedo = _em(evento.position)
        if antes != _sob_o_dedo:
            queue_redraw()
    elif evento is InputEventMouseButton and evento.pressed \
            and evento.button_index == MOUSE_BUTTON_LEFT:
        match _em(evento.position):
            0: emit_signal("jogar")
            1: emit_signal("desafio")
            2: emit_signal("temas")

func _em(ponto: Vector2) -> int:
    for i in _botoes.size():
        if _botoes[i].has_point(ponto):
            return i
    return -1

## Cinco cartas em leque, entre a frase e os botões. Um menu de jogo de cartas
## sem carta nenhuma desperdiça o argumento mais forte do tema escolhido: quem
## nunca ouviu falar do CRUZADA sabe que é um jogo de cartas antes de ler
## qualquer palavra. É o mesmo meio segundo que decidiu o tema padrão.
## Uma Sequência com os quatro naipes: mostra a paleta inteira do tema e,
## de quebra, uma das mãos que o jogo paga.
const LEQUE := [[10, 2], [11, 1], [12, 3], [13, 0], [1, 0]]

func _leque(r: Rect2) -> void:
    var largura := clampf(r.size.y * 0.62, 48.0, 104.0)
    var passo := largura * 0.72
    var centro := Vector2(r.get_center().x, r.position.y + r.size.y * 0.5)
    for i in LEQUE.size():
        var t := float(i) - (LEQUE.size() - 1) * 0.5
        ## O arco: as cartas das pontas descem e giram, como um leque na mão.
        var pos := centro + Vector2(t * passo, absf(t) * largura * 0.10)
        var giro := t * 0.13
        draw_set_transform(pos, giro, Vector2.ONE)
        Carta.desenhar(self, Rect2(-largura * 0.5, -largura * Carta.RAZAO * 0.5,
                                   largura, largura * Carta.RAZAO),
                       int(LEQUE[i][0]), int(LEQUE[i][1]), Carta.NORMAL)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw() -> void:
    Pintura.fundo(self, size, _poeira)
    var ff := Temas.fonte_do_tema(true)
    var f := Temas.fonte_do_tema()
    var centro := size * 0.5

    ## O título grande e a frase logo abaixo, no terço superior: é a proporção
    ## que deixa o olho pousar no nome antes de procurar o botão.
    var tam := int(clampf(size.x * 0.09, 40.0, 96.0))
    Pintura.centrado(self, ff, Rect2(0, size.y * 0.13, size.x, tam + 10),
                     "CRUZADA", tam, Temas.TEXTO)
    draw_multiline_string(f, Vector2(size.x * 0.5 - 260, size.y * 0.13 + tam + 34),
                          FRASE, HORIZONTAL_ALIGNMENT_CENTER, 520, Temas.T_CORPO,
                          -1, Temas.TEXTO_SUAVE)

    _leque(Rect2(0, size.y * 0.38, size.x, size.y * 0.20))

    var larg := minf(size.x - 64.0, 320.0)
    var alt := 64.0            ## nunca abaixo de 64: é onde o dedo trabalha
    var vao := 16.0
    var itens := _itens()
    _botoes.clear()
    var y := size.y * 0.60
    for i in itens.size():
        var b := Rect2(centro.x - larg * 0.5, y + i * (alt + vao), larg, alt)
        _botoes.append(b)
        var quente := i == _sob_o_dedo
        var caixa := StyleBoxFlat.new()
        caixa.bg_color = Temas.DESTAQUE if quente else Color(Temas.PAINEL, 0.9)
        caixa.border_color = Temas.DESTAQUE if quente else Temas.BORDA
        caixa.set_border_width_all(2)
        caixa.set_corner_radius_all(12)
        draw_style_box(caixa, b)
        var cor := Temas.TEXTO
        if quente:
            cor = Temas.CARTA if Temas.e_claro() else Temas.FUNDO
        Pintura.centrado(self, ff, b, itens[i], Temas.T_CORPO, cor)

    if perfil != null:
        ## A dificuldade em uso fica visível no menu. Escondê-la é como se
        ## descobre, três mesas depois, que se está no grau errado.
        Pintura.centrado(self, f, Rect2(0, y + itens.size() * (alt + vao) + 6,
                                        size.x, 24),
                         "desafio: " + perfil.desafio.nome(), Temas.T_ROTULO,
                         Temas.DESTAQUE)
    if perfil != null and perfil.mesas_jogadas > 0:
        var placar := "%d mesas jogadas" % perfil.mesas_jogadas
        if perfil.runs_vencidas > 0:
            placar += "  ·  %d run%s vencida%s" % [perfil.runs_vencidas,
                       "" if perfil.runs_vencidas == 1 else "s",
                       "" if perfil.runs_vencidas == 1 else "s"]
        if perfil.maior_evento > 0:
            placar += "  ·  maior colheita %s" % Pintura.milhar(perfil.maior_evento)
        Pintura.centrado(self, f, Rect2(0, size.y - 56, size.x, 26), placar,
                         Temas.T_ROTULO, Temas.TEXTO_SUAVE)
