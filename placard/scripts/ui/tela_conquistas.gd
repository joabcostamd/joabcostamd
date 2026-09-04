extends Control
class_name TelaConquistas
## As conquistas, todas visíveis desde o começo.
##
## Nenhuma fica escondida: a conquista que ninguém sabe que existe não puxa
## ninguém, e metade delas ENSINA uma regra — quem lê "colha as quatro linhas que
## passam por C3" descobre um jogo que estava lá o tempo todo.

signal fechou

var perfil: Perfil
var _poeira: Array[Vector3] = []
var _r_voltar := Rect2()
var _rolagem := 0.0

func _ready() -> void:
    _poeira = Pintura.semear_poeira()

func _gui_input(evento: InputEvent) -> void:
    if evento is InputEventMouseButton and evento.pressed:
        if evento.button_index == MOUSE_BUTTON_LEFT and _r_voltar.has_point(evento.position):
            emit_signal("fechou")
        elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _rolagem = minf(_rolagem + 60.0, maxf(0.0, _altura() - size.y + 120.0))
            queue_redraw()
        elif evento.button_index == MOUSE_BUTTON_WHEEL_UP:
            _rolagem = maxf(0.0, _rolagem - 60.0)
            queue_redraw()

func _colunas() -> int:
    return 3 if size.x >= 1000.0 else (2 if size.x >= 640.0 else 1)

func _altura() -> float:
    var linhas := ceilf(float(Conquistas.total()) / float(_colunas()))
    return 120.0 + linhas * 78.0

func _draw() -> void:
    Pintura.fundo(self, size, _poeira)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var margem := 24.0
    var util := size.x - margem * 2.0

    var feitas := perfil.quantas_conquistas() if perfil != null else 0
    draw_string(ff, Vector2(margem, 52), "CONQUISTAS", HORIZONTAL_ALIGNMENT_LEFT,
                -1, Temas.T_TITULO, Temas.TEXTO)
    draw_string(f, Vector2(margem + 200, 50), "%d de %d" % [feitas, Conquistas.total()],
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.DESTAQUE)
    _r_voltar = Rect2(size.x - margem - 112, 24, 112, 44)
    Pintura.caixa(self, _r_voltar, 8, 0.9)
    Pintura.centrado(self, ff, _r_voltar, "VOLTAR", Temas.T_CORPO, Temas.TEXTO)

    var colunas := _colunas()
    var vao := 12.0
    var larg := (util - vao * (colunas - 1)) / float(colunas)
    var y0 := 88.0 - _rolagem
    for i in Conquistas.total():
        var c := Conquistas.LISTA[i]
        var col := i % colunas
        var lin := i / colunas
        var r := Rect2(margem + col * (larg + vao), y0 + lin * 78.0, larg, 66.0)
        ## Recorta contra o rodapé, não contra a borda da tela: cartão passando
        ## por baixo do aviso de rolagem lê como texto quebrado.
        if r.end.y < 84.0 or r.end.y > size.y - 38.0:
            continue
        var feita := perfil != null and perfil.conquistas.has(str(c["id"]))
        var caixa := StyleBoxFlat.new()
        caixa.bg_color = Color(Temas.PAINEL, 0.86 if feita else 0.45)
        caixa.border_color = Temas.DESTAQUE if feita else Temas.BORDA
        caixa.set_border_width_all(2 if feita else 1)
        caixa.set_corner_radius_all(10)
        draw_style_box(caixa, r)

        ## A marca é forma, não cor: um disco cheio contra um anel vazio
        ## sobrevive à escala de cinza e a quem não separa matiz.
        var centro := Vector2(r.position.x + 26, r.get_center().y)
        if feita:
            draw_circle(centro, 10.0, Temas.DESTAQUE)
            draw_circle(centro, 4.0, Temas.FUNDO)
        else:
            draw_arc(centro, 10.0, 0.0, TAU, 24, Color(Temas.TEXTO_SUAVE, 0.6), 2.0)

        draw_string(ff, Vector2(r.position.x + 48, r.position.y + 28),
                    str(c["nome"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 60,
                    Temas.T_CORPO, Temas.TEXTO if feita else Temas.TEXTO_SUAVE)
        draw_string(f, Vector2(r.position.x + 48, r.position.y + 50),
                    str(c["como"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 60,
                    Temas.T_ROTULO, Temas.TEXTO_SUAVE)

    if _altura() > size.y:
        Pintura.centrado(self, f, Rect2(0, size.y - 30, size.x, 24),
                         "role para ver o resto", Temas.T_ROTULO, Temas.TEXTO_SUAVE)
