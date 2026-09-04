extends Control
class_name TelaTemas
## O seletor de temas: os oito lado a lado, com o que falta para abrir os
## travados.
##
## A escolha de tema é relativa — o olho compara, não avalia isolado —, então os
## oito aparecem juntos, cada um com uma amostra da própria paleta. É a mesma
## razão da folha de contato que serviu para escolher o padrão.

signal fechou

var perfil: Perfil
var _poeira: Array[Vector3] = []
var _cartoes: Array[Rect2] = []
var _sob_o_dedo := -1
var _r_voltar := Rect2()
var _r_cinza := Rect2()
var _r_cores := Rect2()

func _ready() -> void:
    _poeira = Pintura.semear_poeira()

func _gui_input(evento: InputEvent) -> void:
    if evento is InputEventMouseMotion:
        var antes := _sob_o_dedo
        _sob_o_dedo = _em(evento.position)
        if antes != _sob_o_dedo:
            queue_redraw()
        return
    if not (evento is InputEventMouseButton and evento.pressed
            and evento.button_index == MOUSE_BUTTON_LEFT):
        return
    if _r_voltar.has_point(evento.position):
        emit_signal("fechou")
        return
    if _r_cinza.has_point(evento.position):
        Temas.usar(Temas.atual, not Temas.escala_de_cinza)
        queue_redraw()
        return
    if _r_cores.has_point(evento.position):
        Temas.quatro_cores = not Temas.quatro_cores
        Temas.usar(Temas.atual, Temas.escala_de_cinza)
        queue_redraw()
        return
    var i := _em(evento.position)
    ## Tema travado não é clicável, e o cartão diz o porquê em vez de só recusar.
    if i >= 0 and perfil != null and perfil.destravado(i):
        Temas.usar(i, Temas.escala_de_cinza)
        queue_redraw()

func _em(ponto: Vector2) -> int:
    for i in _cartoes.size():
        if _cartoes[i].has_point(ponto):
            return i
    return -1

func _draw() -> void:
    Pintura.fundo(self, size, _poeira)
    var ff := Temas.fonte_do_tema(true)
    var f := Temas.fonte_do_tema()
    var margem := 24.0

    draw_string(ff, Vector2(margem, 52), "TEMAS", HORIZONTAL_ALIGNMENT_LEFT, -1,
                Temas.T_TITULO, Temas.TEXTO)
    _r_voltar = Rect2(size.x - margem - 112, 24, 112, 44)
    Pintura.caixa(self, _r_voltar, 8, 0.9)
    Pintura.centrado(self, ff, _r_voltar, "VOLTAR", Temas.T_CORPO, Temas.TEXTO)

    ## Grade que se acomoda: 4 colunas na largura cheia, 2 no retrato.
    var colunas := 4 if size.x >= 900.0 else 2
    var vao := 14.0
    var util := size.x - margem * 2.0
    var larg := (util - vao * (colunas - 1)) / float(colunas)
    var alt := minf(larg * 0.72, (size.y - 210.0) / ceilf(float(Temas.total()) / colunas) - vao)
    var y0 := 86.0

    _cartoes.clear()
    for i in Temas.total():
        var col := i % colunas
        var lin := i / colunas
        var c := Rect2(margem + col * (larg + vao), y0 + lin * (alt + vao), larg, alt)
        _cartoes.append(c)
        _cartao(i, c, ff, f)

    ## As duas chaves de acessibilidade ficam com os temas, não num submenu:
    ## quem precisa delas está exatamente aqui, escolhendo como enxergar o jogo.
    var y := y0 + ceilf(float(Temas.total()) / colunas) * (alt + vao) + 8.0
    _r_cores = Rect2(margem, y, minf(util * 0.5 - 8.0, 320.0), 44)
    _r_cinza = Rect2(_r_cores.end.x + 16, y, minf(util * 0.5 - 8.0, 320.0), 44)
    _chave(_r_cores, "QUATRO CORES DE NAIPE", Temas.quatro_cores, ff)
    _chave(_r_cinza, "ESCALA DE CINZA", Temas.escala_de_cinza, ff)

func _cartao(i: int, c: Rect2, ff: FontFile, f: FontFile) -> void:
    var t := Temas.dados(i)
    var aberto := perfil == null or perfil.destravado(i)
    var atual := i == Temas.atual

    ## A amostra é pintada com as cores DAQUELE tema, não com as do vigente:
    ## um cartão que não mostra a própria paleta não serve para escolher.
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Temas.cor_de(t["fundo"])
    caixa.border_color = Temas.DESTAQUE if atual else Temas.BORDA
    caixa.set_border_width_all(3 if atual else 1)
    caixa.set_corner_radius_all(12)
    draw_style_box(caixa, c)

    ## Três faixas: o painel, o filete e uma carta. É o suficiente para o olho
    ## reconhecer o tema, e é o que a folha de contato provou ao escolher o padrão.
    var amostra := Rect2(c.position.x + 12, c.position.y + 12, c.size.x - 24,
                         c.size.y * 0.44)
    var painel := StyleBoxFlat.new()
    painel.bg_color = Temas.cor_de(t["painel"])
    painel.set_corner_radius_all(8)
    draw_style_box(painel, amostra)
    draw_rect(Rect2(amostra.position.x + 10, amostra.end.y - 10,
                    amostra.size.x - 20, 2), Temas.cor_de(t["filete"]))
    var carta := Rect2(amostra.end.x - amostra.size.y * 0.52,
                       amostra.position.y + amostra.size.y * 0.16,
                       amostra.size.y * 0.42, amostra.size.y * 0.42 * Carta.RAZAO)
    var papel := StyleBoxFlat.new()
    papel.bg_color = Temas.cor_de(t["carta"])
    papel.set_corner_radius_all(4)
    draw_style_box(papel, carta)
    for k in 4:
        draw_circle(Vector2(amostra.position.x + 22 + k * 20,
                            amostra.get_center().y),
                    7.0, Temas.cor_de(t[["copas", "ouros", "paus", "espadas"][k]]))

    var y := amostra.end.y + 24.0
    draw_string(ff, Vector2(c.position.x + 14, y), str(t["nome"]),
                HORIZONTAL_ALIGNMENT_LEFT, c.size.x - 28, Temas.T_CORPO,
                Temas.cor_de(t["texto"]))
    var recado := str(t["sensacao"]) if aberto else str(t["como"])
    draw_multiline_string(f, Vector2(c.position.x + 14, y + 20), recado,
                          HORIZONTAL_ALIGNMENT_LEFT, c.size.x - 28, Temas.T_ROTULO,
                          2, Temas.cor_de(t["texto_suave"]))

    if not aberto:
        ## O véu não esconde a paleta — ele diz "ainda não", e o jogador continua
        ## vendo o que vai ganhar. Prêmio invisível não puxa ninguém.
        draw_rect(c, Color(Temas.FUNDO, 0.62))
        var selo := Rect2(c.position.x + 12, c.position.y + 12, 78, 24)
        Pintura.pilula(self, selo, Color(Temas.BORDA, 0.9), 6)
        Pintura.centrado(self, ff, selo, "TRAVADO", Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    elif atual:
        var selo2 := Rect2(c.end.x - 90, c.position.y + 12, 78, 24)
        Pintura.pilula(self, selo2, Temas.DESTAQUE, 6)
        Pintura.centrado(self, ff, selo2, "EM USO", Temas.T_ROTULO,
                         Temas.CARTA if Temas.e_claro() else Temas.FUNDO)

func _chave(r: Rect2, texto: String, ligada: bool, ff: FontFile) -> void:
    Pintura.caixa(self, r, 10, 0.8)
    Pintura.centrado(self, ff, Rect2(r.position.x + 44, r.position.y,
                                     r.size.x - 56, r.size.y),
                     texto, Temas.T_ROTULO, Temas.TEXTO)
    var pino := Rect2(r.position.x + 12, r.get_center().y - 9, 22, 18)
    Pintura.pilula(self, pino, Temas.DESTAQUE if ligada else Color(Temas.BORDA, 0.9))
    draw_circle(Vector2(pino.position.x + (16.0 if ligada else 6.0), pino.get_center().y),
                6.0, Temas.CARTA if ligada else Temas.TEXTO_SUAVE)
