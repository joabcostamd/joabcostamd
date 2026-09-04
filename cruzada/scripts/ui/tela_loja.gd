extends Control
class_name TelaLoja
## A loja entre uma mesa e a seguinte, e o seletor de alvo do selo.
##
## Duas telas em uma, e de propósito: comprar um selo e escolher onde colá-lo é
## UMA decisão, não duas. Separá-las em telas diferentes faria o jogador comprar
## sem saber onde vai caber — e onde cabe é o jogo inteiro.

signal seguir

var run: Run
var _poeira: Array[Vector3] = []
var _r_vagas: Array[Rect2] = []
var _r_seguir := Rect2()
var _r_rerrolar := Rect2()
var _sob_o_dedo := -1

## Quando um selo foi comprado mas ainda não tem alvo: −1 nenhum, senão a vaga.
var _escolhendo := -1
var _r_alvos: Array[Rect2] = []
var _alvos: Array[int] = []
var _alvo_sob_o_dedo := -1

func _ready() -> void:
    _poeira = Pintura.semear_poeira()

func _gui_input(evento: InputEvent) -> void:
    if evento is InputEventMouseMotion:
        var antes := [_sob_o_dedo, _alvo_sob_o_dedo]
        _sob_o_dedo = -1
        _alvo_sob_o_dedo = -1
        for i in _r_vagas.size():
            if _r_vagas[i].has_point(evento.position):
                _sob_o_dedo = i
        for i in _r_alvos.size():
            if _r_alvos[i].has_point(evento.position):
                _alvo_sob_o_dedo = i
        if antes != [_sob_o_dedo, _alvo_sob_o_dedo]:
            queue_redraw()
        return
    if not (evento is InputEventMouseButton and evento.pressed
            and evento.button_index == MOUSE_BUTTON_LEFT):
        return
    var ponto: Vector2 = evento.position

    if _escolhendo >= 0:
        for i in _r_alvos.size():
            if _r_alvos[i].has_point(ponto):
                run.loja.comprar(_escolhendo, run.poderes, _alvos[i])
                _escolhendo = -1
                queue_redraw()
                return
        ## Clicar fora cancela a compra. O dinheiro nem saiu ainda.
        _escolhendo = -1
        queue_redraw()
        return

    if _r_seguir.has_point(ponto):
        emit_signal("seguir")
        return
    if _r_rerrolar.has_point(ponto):
        run.loja.rerrolar(run.poderes)
        queue_redraw()
        return
    for i in _r_vagas.size():
        if not _r_vagas[i].has_point(ponto):
            continue
        if not run.loja.pode_comprar(i, run.poderes):
            return
        if run.loja.precisa_de_alvo(i) >= 0:
            _escolhendo = i
        else:
            run.loja.comprar(i, run.poderes)
        queue_redraw()
        return

# ─────────────────────────────── desenho ───────────────────────────────

func _draw() -> void:
    Pintura.fundo(self, size, _poeira)
    if run == null or run.loja == null:
        return
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var margem := 24.0
    var util := size.x - margem * 2.0

    draw_string(ff, Vector2(margem, 52), "LOJA", HORIZONTAL_ALIGNMENT_LEFT, -1,
                Temas.T_TITULO, Temas.TEXTO)
    draw_string(f, Vector2(margem + 110, 50),
                "rodada %d · próxima mesa: %s" % [run.rodada,
                                                  Metas.NOMES[run.indice_da_mesa]],
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)
    ## O dinheiro grande, no alto à direita: é o número que decide toda a tela.
    ## `draw_string` alinhado à direita desenha DENTRO de [x, x+largura], não à
    ## esquerda de x — na primeira versão o saldo saiu da tela inteiro.
    draw_string(ff, Vector2(size.x - margem - 240, 60), "$%d" % run.poderes.dinheiro,
                HORIZONTAL_ALIGNMENT_RIGHT, 240, Temas.T_HEROI, Temas.DESTAQUE)

    _pagamento(Rect2(margem, 76, util, 40))
    _vitrine(Rect2(margem, 130, util, 190))
    ## O painel da build tem a altura do CONTEÚDO, não a da coluna: moldura com
    ## buraco dentro lê como inacabado, e espaço vazio fora dela lê como respiro.
    _o_que_eu_tenho(Rect2(margem, 336, util, minf(size.y - 336 - 96, _altura_da_build())))

    _r_rerrolar = Rect2(margem, size.y - 78, 200, 54)
    var pode := run.poderes.dinheiro >= run.loja.preco_da_rerrolagem()
    Pintura.caixa(self, _r_rerrolar, 10, 0.8 if pode else 0.4)
    Pintura.centrado(self, ff, _r_rerrolar,
                     "REROLAR  $%d" % run.loja.preco_da_rerrolagem(),
                     Temas.T_CORPO, Temas.TEXTO if pode else Temas.TEXTO_SUAVE)

    ## SEGUIR sempre visível e sempre habilitado: a loja nunca prende ninguém.
    _r_seguir = Rect2(size.x - margem - 220, size.y - 78, 220, 54)
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Temas.DESTAQUE
    caixa.set_corner_radius_all(10)
    draw_style_box(caixa, _r_seguir)
    Pintura.centrado(self, ff, _r_seguir, "SEGUIR", Temas.T_CORPO,
                     Temas.CARTA if Temas.e_claro() else Temas.FUNDO)

    if _escolhendo >= 0:
        _seletor()

## De onde veio cada moeda. Sem esta linha o dinheiro aparece do nada, e o
## jogador não aprende que sobrar posicionamento paga.
func _pagamento(r: Rect2) -> void:
    var p := run.ultimo_pagamento
    if p.is_empty():
        return
    var f := Temas.fonte_do_tema()
    var partes := []
    if int(p.get("premio", 0)) > 0:
        partes.append("mesa $%d" % int(p["premio"]))
    if int(p.get("sobra", 0)) > 0:
        partes.append("%d jogadas de sobra $%d" % [int(p["sobra"]), int(p["sobra"])])
    if int(p.get("consolo", 0)) > 0:
        partes.append("chegou perto $%d" % int(p["consolo"]))
    if int(p.get("juros", 0)) > 0:
        partes.append("juros $%d" % int(p["juros"]))
    if int(p.get("selos", 0)) > 0:
        partes.append("selos $%d" % int(p["selos"]))
    if partes.is_empty():
        return
    draw_string(f, Vector2(r.position.x, r.position.y + 22),
                "recebeu:  " + "   ·   ".join(partes), HORIZONTAL_ALIGNMENT_LEFT,
                -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)

func _vitrine(r: Rect2) -> void:
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var n := run.loja.vagas.size()
    var vao := 16.0
    var larg := (r.size.x - vao * (n - 1)) / float(n)
    _r_vagas.clear()
    for i in n:
        var vaga: Dictionary = run.loja.vagas[i]
        var b := Rect2(r.position.x + i * (larg + vao), r.position.y, larg, r.size.y)
        _r_vagas.append(b)
        var vendida := bool(vaga["vendida"])
        var preco := run.loja.preco_da_vaga(i, run.poderes)
        var pode := run.loja.pode_comprar(i, run.poderes)

        var caixa := StyleBoxFlat.new()
        caixa.bg_color = Color(Temas.PAINEL, 0.35 if vendida else 0.86)
        caixa.border_color = Temas.DESTAQUE if (pode and i == _sob_o_dedo) else Temas.BORDA
        caixa.set_border_width_all(2)
        caixa.set_corner_radius_all(12)
        draw_style_box(caixa, b)

        var etiqueta := _etiqueta(vaga)
        draw_string(ff, Vector2(b.position.x + 16, b.position.y + 30), etiqueta,
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
        draw_string(ff, Vector2(b.position.x + 16, b.position.y + 66),
                    str(vaga["nome"]), HORIZONTAL_ALIGNMENT_LEFT, b.size.x - 32,
                    Temas.T_TITULO, Temas.TEXTO if not vendida else Temas.TEXTO_SUAVE)
        ## A frase do item, em até seis palavras, ancorada no próprio objeto.
        draw_multiline_string(f, Vector2(b.position.x + 16, b.position.y + 100),
                              str(vaga["frase"]), HORIZONTAL_ALIGNMENT_LEFT,
                              b.size.x - 32, Temas.T_CORPO, 2, Temas.TEXTO_SUAVE)

        var etiq := Rect2(b.position.x + 16, b.end.y - 46, b.size.x - 32, 34)
        if vendida:
            Pintura.centrado(self, ff, etiq, "COMPRADO", Temas.T_CORPO, Temas.SUCESSO)
        else:
            Pintura.pilula(self, etiq, Temas.DESTAQUE if pode else Color(Temas.BORDA, 0.5), 8)
            var cor := Temas.TEXTO_SUAVE
            if pode:
                cor = Temas.CARTA if Temas.e_claro() else Temas.FUNDO
            Pintura.centrado(self, ff, etiq, "$%d" % preco, Temas.T_CORPO, cor)

func _etiqueta(vaga: Dictionary) -> String:
    match int(vaga["tipo"]):
        Loja.NIVEL: return "NÍVEL DE MÃO"
        Itens.CASA + 1: return "SELO DE CASA"
        Itens.EIXO + 1: return "SELO DE EIXO"
        _: return "RELÍQUIA"

## O que a run já carrega. Sem isto o jogador compra às cegas a partir da
## terceira loja, porque ninguém lembra onde colou seis selos.
func _altura_da_build() -> float:
    var f := Temas.fonte_do_tema()
    var util := size.x - 48.0 - 36.0
    var alt := 66.0
    for linha in _linhas_da_build():
        alt += f.get_multiline_string_size(str(linha), HORIZONTAL_ALIGNMENT_LEFT,
                                           util, Temas.T_CORPO).y + 10.0
    return alt

func _linhas_da_build() -> Array:
    var p := run.poderes
    var linhas := []
    var niveis := []
    for cat in Maos.CATEGORIAS:
        if p.nivel(cat) > 0:
            niveis.append("%s +%d" % [Maos.CURTOS[cat], p.nivel(cat)])
    if not niveis.is_empty():
        linhas.append("níveis:  " + "   ".join(niveis))
    var selos := []
    for casa in p.selos_de_casa:
        for id in p.selos_de_casa[casa]:
            selos.append("%s em %s" % [str(Itens.achar(Itens.CASA, str(id))["nome"]),
                                       Geometria.nome_da_casa(int(casa))])
    for linha in p.selos_de_eixo:
        for id in p.selos_de_eixo[linha]:
            selos.append("%s na %s" % [str(Itens.achar(Itens.EIXO, str(id))["nome"]),
                                       Geometria.nome(int(linha))])
    if not selos.is_empty():
        linhas.append("selos:  " + "   ".join(selos))
    var reliq := []
    for id in p.reliquias:
        reliq.append(str(Itens.achar(Itens.RELIQUIA, id)["nome"]))
    if not reliq.is_empty():
        linhas.append("relíquias:  " + "   ".join(reliq))
    if linhas.is_empty():
        linhas.append("nada ainda — a primeira compra é a que ensina o resto")
    return linhas

func _o_que_eu_tenho(r: Rect2) -> void:
    if r.size.y < 80.0:
        return
    Pintura.caixa(self, r, 12, 0.55)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    draw_string(ff, Vector2(r.position.x + 18, r.position.y + 28), "A SUA BUILD",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    var y := r.position.y + 54.0
    for linha in _linhas_da_build():
        var alt := f.get_multiline_string_size(str(linha), HORIZONTAL_ALIGNMENT_LEFT,
                                               r.size.x - 36, Temas.T_CORPO).y
        draw_multiline_string(f, Vector2(r.position.x + 18, y), str(linha),
                              HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 36,
                              Temas.T_CORPO, -1, Temas.TEXTO)
        y += alt + 10.0

# ──────────────────────── onde colar o selo ────────────────────────

## O seletor de alvo. Um selo de casa mostra a grade 5×5 com as diagonais
## marcadas — a informação que torna a escolha uma decisão em vez de um clique.
func _seletor() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(Temas.FUNDO, 0.92))
    var ff := Temas.fonte_do_tema(true)
    var f := Temas.fonte_do_tema()
    var vaga: Dictionary = run.loja.vagas[_escolhendo]
    var por_casa := run.loja.precisa_de_alvo(_escolhendo) == 0

    Pintura.centrado(self, ff, Rect2(0, 40, size.x, 40),
                     "ONDE COLAR: " + str(vaga["nome"]).to_upper(), Temas.T_TITULO,
                     Temas.TEXTO)
    Pintura.centrado(self, f, Rect2(0, 82, size.x, 26), str(vaga["frase"]),
                     Temas.T_CORPO, Temas.DESTAQUE)

    _r_alvos.clear()
    _alvos.clear()
    if por_casa:
        _grade_de_casas()
    else:
        _lista_de_eixos()

    Pintura.centrado(self, f, Rect2(0, size.y - 46, size.x, 26),
                     "toque fora para desistir", Temas.T_ROTULO, Temas.TEXTO_SUAVE)

func _grade_de_casas() -> void:
    var f := Temas.fonte_do_tema(true)
    var celula := floorf(minf((size.y - 200.0) / (5.0 * Carta.RAZAO),
                              (size.x - 80.0) / 5.0))
    var alt := celula * Carta.RAZAO
    var vao := 6.0
    var larg := celula * 5.0 + vao * 4.0
    var g := Rect2((size.x - larg) * 0.5, 124, larg, alt * 5.0 + vao * 4.0)
    for casa in Geometria.CASAS:
        var c := Rect2(g.position + Vector2((casa % 5) * (celula + vao),
                                            (casa / 5) * (alt + vao)),
                       Vector2(celula, alt))
        _r_alvos.append(c)
        _alvos.append(casa)
        var quantas := Geometria.linhas_da_casa(casa).size()
        var quente := _alvo_sob_o_dedo == _alvos.size() - 1
        var caixa := StyleBoxFlat.new()
        caixa.bg_color = Temas.CASA
        caixa.border_color = Temas.DESTAQUE if quente else Temas.CASA_BORDA
        caixa.set_border_width_all(3 if quente else 2)
        caixa.set_corner_radius_all(int(maxf(4.0, celula * 0.09)))
        draw_style_box(caixa, c)
        ## O número de linhas que passam pela casa É a decisão: 4 no centro,
        ## 3 nos cantos, 2 no resto. Sem ele o jogador escolhe no chute.
        Pintura.centrado(self, f, Rect2(c.position.x, c.get_center().y - 22,
                                        c.size.x, 26),
                         "%d linhas" % quantas, Temas.T_ROTULO,
                         Temas.DESTAQUE if quantas >= 3 else Temas.TEXTO_SUAVE)
        Pintura.centrado(self, f, Rect2(c.position.x, c.get_center().y + 2,
                                        c.size.x, 24),
                         Geometria.nome_da_casa(casa), Temas.T_ROTULO,
                         Temas.TEXTO_SUAVE)
        var quantos_selos: int = run.poderes.selos_de_casa.get(casa, []).size()
        if quantos_selos > 0:
            var selo := Rect2(c.position.x + 6, c.position.y + 6, 22, 18)
            Pintura.pilula(self, selo, Temas.ACENTO, 6)
            Pintura.centrado(self, f, selo, str(quantos_selos), Temas.T_ROTULO,
                             Temas.FUNDO)

func _lista_de_eixos() -> void:
    var f := Temas.fonte_do_tema(true)
    var larg := minf(size.x - 80.0, 520.0)
    var alt := 44.0
    var vao := 6.0
    var y := 124.0
    for l in Geometria.LINHAS:
        var b := Rect2((size.x - larg) * 0.5, y + l * (alt + vao), larg, alt)
        _r_alvos.append(b)
        _alvos.append(l)
        var quente := _alvo_sob_o_dedo == l
        Pintura.caixa(self, b, 8, 0.9 if quente else 0.6)
        var nome := Geometria.nome(l)
        if Geometria.diagonal(l):
            nome += "  ·  paga 60%"
        var quantos: int = run.poderes.selos_de_eixo.get(l, []).size()
        if quantos > 0:
            nome += "  ·  %d selo%s" % [quantos, "" if quantos == 1 else "s"]
        Pintura.centrado(self, f, b, nome, Temas.T_CORPO,
                         Temas.DESTAQUE if quente else Temas.TEXTO)
