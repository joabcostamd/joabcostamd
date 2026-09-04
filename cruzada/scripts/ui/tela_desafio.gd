extends Control
class_name TelaDesafio
## A escolha da dificuldade. Três réguas e um dial, na mesma tela.
##
## O dial é para quem quer um degrau; as réguas são para quem quer exatamente o
## que quer. Esconder as réguas atrás de um "avançado" seria fingir que o jogo
## tem modos, e ele não tem: tem três números, e o dial só escreve neles.
##
## O texto embaixo de cada régua diz o que ela FAZ, não o que ela vale. "17
## posicionamentos" decide; "orçamento +2" não decide nada.

signal fechou

var desafio: Desafio
var _poeira: Array[Vector3] = []
var _r_voltar := Rect2()
var _r_graus: Array[Rect2] = []
var _r_menos: Array[Rect2] = []
var _r_mais: Array[Rect2] = []
var _r_estufa := Rect2()
var _sob_o_dedo := -1

func _ready() -> void:
    _poeira = Pintura.semear_poeira()
    if desafio == null:
        desafio = Desafio.new()

func _gui_input(evento: InputEvent) -> void:
    if evento is InputEventMouseMotion:
        var antes := _sob_o_dedo
        _sob_o_dedo = -1
        for i in _r_graus.size():
            if _r_graus[i].has_point(evento.position):
                _sob_o_dedo = i
        if antes != _sob_o_dedo:
            queue_redraw()
        return
    if not (evento is InputEventMouseButton and evento.pressed
            and evento.button_index == MOUSE_BUTTON_LEFT):
        return
    var ponto: Vector2 = evento.position
    if _r_voltar.has_point(ponto):
        emit_signal("fechou")
        return
    if _r_estufa.has_point(ponto):
        ## A Estufa é um lugar, não um degrau: sair dela volta ao Tabuleiro 0.
        desafio = Desafio.new() if desafio.sem_derrota else Desafio.estufa()
        queue_redraw()
        return
    for i in _r_graus.size():
        if _r_graus[i].has_point(ponto):
            desafio = Desafio.tabuleiro(i)
            queue_redraw()
            return
    for i in _r_menos.size():
        if _r_menos[i].has_point(ponto):
            _mexer(i, -1)
            return
        if _r_mais[i].has_point(ponto):
            _mexer(i, 1)
            return

func _mexer(regua: int, passo: int) -> void:
    match regua:
        0: desafio.orcamento = clampi(desafio.orcamento + passo,
                                      Desafio.ORCAMENTO_MIN, Desafio.ORCAMENTO_MAX)
        1: desafio.geometria = clampi(desafio.geometria + passo, 0,
                                      Desafio.GEOMETRIA_MAX)
        2: desafio.metas = clampf(snappedf(desafio.metas + passo * 0.05, 0.05),
                                  Desafio.METAS_MIN, Desafio.METAS_MAX)
    ## Mexer na régua sai da Estufa: lá a derrota não existe, e isso não é um
    ## valor de régua nenhuma.
    desafio.sem_derrota = false
    desafio.descartes = 0
    queue_redraw()

func _draw() -> void:
    Pintura.fundo(self, size, _poeira)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var margem := 24.0
    var util := size.x - margem * 2.0

    draw_string(ff, Vector2(margem, 52), "DESAFIO", HORIZONTAL_ALIGNMENT_LEFT, -1,
                Temas.T_TITULO, Temas.TEXTO)
    _r_voltar = Rect2(size.x - margem - 112, 24, 112, 44)
    Pintura.caixa(self, _r_voltar, 8, 0.9)
    Pintura.centrado(self, ff, _r_voltar, "VOLTAR", Temas.T_CORPO, Temas.TEXTO)

    ## O dial. Nove fichas numeradas, a atual acesa.
    var y := 96.0
    draw_string(ff, Vector2(margem, y), "TABULEIRO", HORIZONTAL_ALIGNMENT_LEFT, -1,
                Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    y += 16.0
    var n := Desafio.TABULEIROS.size()
    var passo := minf(64.0, (util - 8.0 * (n - 1)) / float(n))
    var grau := desafio.grau_do_dial()
    _r_graus.clear()
    for i in n:
        var b := Rect2(margem + i * (passo + 8.0), y, passo, 52.0)
        _r_graus.append(b)
        var aceso := i == grau
        var caixa := StyleBoxFlat.new()
        caixa.bg_color = Temas.DESTAQUE if aceso else Color(Temas.PAINEL, 0.9)
        caixa.border_color = Temas.DESTAQUE if (aceso or i == _sob_o_dedo) else Temas.BORDA
        caixa.set_border_width_all(2)
        caixa.set_corner_radius_all(10)
        draw_style_box(caixa, b)
        var cor := Temas.TEXTO
        if aceso:
            cor = Temas.CARTA if Temas.e_claro() else Temas.FUNDO
        Pintura.centrado(self, ff, b, str(i), Temas.T_NUMERO, cor)
    y += 62.0

    ## O que este grau muda, listado. O dial sem a lista é um número sem sentido.
    var atual := maxi(grau, desafio.geometria)
    var descricao := "a linha de base — é contra ela que todo número foi medido"
    if desafio.sem_derrota:
        descricao = "a derrota não existe: a mesa perdida repete de graça"
    elif desafio.geometria > 0:
        descricao = ""
        for g in range(1, desafio.geometria + 1):
            descricao += "· " + Desafio.GEO_NOMES[g] + "\n"
    var altura := f.get_multiline_string_size(descricao, HORIZONTAL_ALIGNMENT_LEFT,
                                              util - 28, Temas.T_CORPO).y
    var painel := Rect2(margem, y, util, altura + 28.0)
    Pintura.caixa(self, painel, 10, 0.6)
    draw_multiline_string(f, Vector2(margem + 14, y + 22), descricao,
                          HORIZONTAL_ALIGNMENT_LEFT, util - 28, Temas.T_CORPO,
                          -1, Temas.TEXTO_SUAVE)
    y += painel.size.y + 22.0

    ## As três réguas, com o efeito escrito em número de jogo, não em jargão.
    var reguas := [
        ["ORÇAMENTO", "%d posicionamentos na Pequena" % desafio.posicionamentos(Metas.PEQUENA),
         "%+d" % desafio.orcamento],
        ["GEOMETRIA", "grau %d de %d" % [desafio.geometria, Desafio.GEOMETRIA_MAX],
         str(desafio.geometria)],
        ["METAS", "primeira meta: %s" % Pintura.milhar(desafio.meta(Metas.PEQUENA, 1)),
         "×%.2f" % desafio.metas],
    ]
    _r_menos.clear()
    _r_mais.clear()
    for i in reguas.size():
        var r := Rect2(margem, y + i * 74.0, util, 62.0)
        Pintura.caixa(self, r, 10, 0.72)
        draw_string(ff, Vector2(r.position.x + 16, r.position.y + 26),
                    str(reguas[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1,
                    Temas.T_ROTULO, Temas.TEXTO_SUAVE)
        draw_string(f, Vector2(r.position.x + 16, r.position.y + 48),
                    str(reguas[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1,
                    Temas.T_CORPO, Temas.TEXTO)
        ## Botões de 48 px: é onde o dedo trabalha, e não cedem tamanho.
        var menos := Rect2(r.end.x - 168, r.position.y + 7, 48, 48)
        var mais := Rect2(r.end.x - 60, r.position.y + 7, 48, 48)
        _r_menos.append(menos)
        _r_mais.append(mais)
        Pintura.pilula(self, menos, Color(Temas.BORDA, 0.6), 10)
        Pintura.pilula(self, mais, Color(Temas.BORDA, 0.6), 10)
        Pintura.centrado(self, ff, menos, "−", Temas.T_NUMERO, Temas.TEXTO)
        Pintura.centrado(self, ff, mais, "+", Temas.T_NUMERO, Temas.TEXTO)
        Pintura.centrado(self, ff, Rect2(menos.end.x, r.position.y, 60, r.size.y),
                         str(reguas[i][2]), Temas.T_CORPO, Temas.DESTAQUE)
    y += reguas.size() * 74.0 + 6.0

    ## A ESTUFA. Fica destacada e por último porque é a escolha que muda o
    ## contrato do jogo, não o volume dele.
    _r_estufa = Rect2(margem, y, util, 62.0)
    var caixa_e := StyleBoxFlat.new()
    caixa_e.bg_color = Temas.DESTAQUE if desafio.sem_derrota else Color(Temas.PAINEL, 0.72)
    caixa_e.border_color = Temas.DESTAQUE
    caixa_e.set_border_width_all(2)
    caixa_e.set_corner_radius_all(10)
    draw_style_box(caixa_e, _r_estufa)
    var cor_e := Temas.TEXTO
    if desafio.sem_derrota:
        cor_e = Temas.CARTA if Temas.e_claro() else Temas.FUNDO
    draw_string(ff, Vector2(_r_estufa.position.x + 16, _r_estufa.position.y + 26),
                "ESTUFA", HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, cor_e)
    draw_string(f, Vector2(_r_estufa.position.x + 16, _r_estufa.position.y + 48),
                "sem derrota, mais tempo, metas menores — e a coleção abre igual",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, cor_e)

    Pintura.centrado(self, f, Rect2(0, size.y - 40, size.x, 26),
                     "jogando em: " + desafio.nome(), Temas.T_ROTULO, Temas.TEXTO_SUAVE)
