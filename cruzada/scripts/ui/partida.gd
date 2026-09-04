extends Control
class_name Partida
## A tela da partida. Desenha uma `Mesa` e recebe o toque do jogador.
##
## Ela não sabe nenhuma regra: quem decide o que acontece é a `Mesa`, e esta
## classe só pergunta e desenha o que voltou. Se uma conta aparecer aqui, está no
## lugar errado.
##
## LAYOUT — a regra que organiza tudo: **o centro só tem o que o jogador toca.**
## Esquerda é estado (consulta), centro é jogo (manipulação), direita é
## referência (consulta ocasional). Ver `HUD.md`.

const MARGEM := 24.0
const VAO := 20.0
const BARRA := 52.0
const VIDAS_POR_RUN := 3

## Quanto tempo o realce de uma colheita fica na tela. Curto o bastante para não
## atrasar o próximo clique, longo o bastante para o olho pousar no número.
const TEMPO_DO_REALCE := 1.6

var mesa: Mesa
var run: Run          ## quando existe, é dela que saem rodada, vidas e progresso
var semente := 20260904

var _selecionada := -1        ## índice na mão, -1 = nenhuma
var _casa_sob_o_dedo := -1
var _carta_sob_o_dedo := -1
var _poeira: Array[Vector3] = []

## O último relato da mesa, guardado só para desenhar o que acabou de acontecer.
var _relato := {}
var _realce := 0.0
var _pontos_mostrados := 0.0  ## o número corre até o valor real, não salta

## Retângulos calculados no desenho e usados no toque. A tela é desenhada em modo
## imediato, então o mapa de toque é o próprio traçado do quadro anterior.
var _r_casas: Array[Rect2] = []
var _r_mao: Array[Rect2] = []
var _r_regras := Rect2()
var _regras_abertas := false
var _regras_de := 0      ## primeiro verbete da página aberta
var _regras_ate := 0     ## onde a próxima página começa

signal mesa_terminada(venceu: bool)

func _ready() -> void:
    _poeira = Pintura.semear_poeira()
    set_process(true)
    _acompanhar()
    get_viewport().size_changed.connect(_acompanhar)
    if mesa == null:
        comecar(Metas.PEQUENA, 1)

## Preencher pela âncora, não atribuindo `size`: atribuir tamanho a um Control
## ancorado é ignorado no quadro seguinte e o Godot avisa em log a cada troca de
## tela — barulho que esconde aviso de verdade.
func _acompanhar() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    queue_redraw()

## Abre uma mesa avulsa, sem Run. Serve às capturas e ao teste.
func comecar(tipo: int, p_rodada: int, tentativa := 1) -> void:
    mesa = Mesa.new(tipo, p_rodada, semente, tentativa)
    _selecionada = -1
    _relato = {}
    _realce = 0.0
    _pontos_mostrados = 0.0
    queue_redraw()

## Rodada, vidas e o nome da mesa saem da Run quando há uma. Sem Run — que é o
## caso das capturas e dos testes — a tela mostra a mesa avulsa como rodada 1.
func rodada() -> int:
    return run.rodada if run != null else 1

func vidas() -> int:
    return run.vidas if run != null else VIDAS_POR_RUN

func _process(delta: float) -> void:
    var mudou := false
    if _realce > 0.0:
        _realce = maxf(0.0, _realce - delta)
        mudou = true
    if mesa != null and absf(_pontos_mostrados - float(mesa.pontos)) > 0.5:
        ## Corre 12% da distância por quadro: rápido no começo, suave no fim, e
        ## sem depender da taxa de quadros para chegar ao mesmo lugar.
        _pontos_mostrados += (float(mesa.pontos) - _pontos_mostrados) \
                             * minf(1.0, delta * 7.0)
        mudou = true
    elif mesa != null:
        _pontos_mostrados = float(mesa.pontos)
    if mudou:
        queue_redraw()

# ─────────────────────────────── o toque ───────────────────────────────

func _gui_input(evento: InputEvent) -> void:
    if mesa == null:
        return
    if evento is InputEventMouseMotion:
        _mover(evento.position)
    elif evento is InputEventMouseButton and evento.pressed \
            and evento.button_index == MOUSE_BUTTON_LEFT:
        _tocar(evento.position)

func _mover(ponto: Vector2) -> void:
    var casa := _casa_em(ponto)
    var carta := _carta_em(ponto)
    if casa != _casa_sob_o_dedo or carta != _carta_sob_o_dedo:
        _casa_sob_o_dedo = casa
        _carta_sob_o_dedo = carta
        queue_redraw()

func _tocar(ponto: Vector2) -> void:
    if _regras_abertas:
        ## Tocar vira a página; na última, fecha. Rolagem seria pior: quem abriu
        ## REGRAS está travado no meio de um turno e quer terminar de ler.
        if _regras_ate < REGRAS.size():
            _regras_de = _regras_ate
        else:
            _regras_abertas = false
            _regras_de = 0
        queue_redraw()
        return
    if _r_regras.has_point(ponto):
        _regras_abertas = true
        _regras_de = 0
        queue_redraw()
        return
    if mesa.acabou:
        emit_signal("mesa_terminada", mesa.venceu)
        return
    var carta := _carta_em(ponto)
    if carta >= 0:
        ## Tocar de novo na carta já escolhida gira o Avesso. É o gesto mais
        ## curto possível para a única decisão que o item pede.
        if carta == _selecionada:
            mesa.girar_na_mao(carta)
        else:
            _selecionada = carta
        queue_redraw()
        return
    var casa := _casa_em(ponto)
    if casa >= 0 and _selecionada >= 0:
        jogar(_selecionada, casa)

func _unhandled_key_input(evento: InputEvent) -> void:
    if mesa == null or not (evento is InputEventKey) or not evento.pressed:
        return
    var tecla: int = evento.keycode
    if tecla >= KEY_1 and tecla <= KEY_9:
        var i := tecla - KEY_1
        if i < mesa.mao.size():
            _selecionada = i
            queue_redraw()
    elif tecla == KEY_SPACE and _selecionada >= 0:
        mesa.girar_na_mao(_selecionada)
        queue_redraw()
    elif tecla == KEY_D:
        descartar_selecionada()
    elif tecla == KEY_R or tecla == KEY_ESCAPE:
        _regras_abertas = not _regras_abertas and tecla == KEY_R
        queue_redraw()

func jogar(indice: int, casa: int) -> void:
    var r := mesa.posicionar(indice, casa)
    if not bool(r["valido"]):
        return
    _relato = r
    if run != null:
        run.anotar_colheita(r)
    if bool(r["colheita"]) or int(r["pontos_parcela"]) > 0:
        _realce = TEMPO_DO_REALCE
    _selecionada = mini(_selecionada, mesa.mao.size() - 1)
    queue_redraw()

func descartar_selecionada() -> void:
    if _selecionada < 0 or mesa.descartes_restantes <= 0:
        return
    if mesa.descartar([_selecionada]):
        _selecionada = -1
        queue_redraw()

func _casa_em(ponto: Vector2) -> int:
    for i in _r_casas.size():
        if _r_casas[i].has_point(ponto):
            return i
    return -1

func _carta_em(ponto: Vector2) -> int:
    for i in _r_mao.size():
        if _r_mao[i].has_point(ponto):
            return i
    return -1

# ─────────────────────────────── o desenho ───────────────────────────────

func _draw() -> void:
    Pintura.fundo(self, size, _poeira)
    if mesa == null:
        return
    _r_casas.clear()
    _r_casas.resize(Geometria.CASAS)
    _r_mao.clear()
    if size.y > size.x:
        _retrato()
    else:
        _paisagem()
    if mesa.acabou:
        _fim_de_mesa()
    if _regras_abertas:
        _regras()

func _paisagem() -> void:
    var util := size.x - MARGEM * 2.0
    ## O centro leva a maior fatia; as laterais ficam iguais para a tela não
    ## pender para um lado. 500 no centro cabe a mão de 5 cartas de 86 px.
    var centro_larg := clampf(util * 0.41, 420.0, 560.0)
    var lateral := (util - centro_larg - VAO * 2.0) * 0.5

    var topo := MARGEM * 0.5
    _barra(Rect2(MARGEM, topo, util, BARRA))

    var y := topo + BARRA + 8.0
    var alt := size.y - y - MARGEM * 0.5
    ## Cada painel tem a altura do seu conteúdo, não a da coluna. Moldura com
    ## buraco dentro lê como inacabado; espaço vazio FORA da moldura lê como
    ## respiro.
    _painel_estado(Rect2(MARGEM, y, lateral, minf(446.0, alt)))
    _centro(Rect2(MARGEM + lateral + VAO, y, centro_larg, alt))
    var dir := MARGEM + lateral + VAO + centro_larg + VAO
    _painel_referencia(Rect2(dir, y, lateral, minf(462.0, alt)))

## O centro: só grade e mão. Nada de status, nada de tabela.
func _centro(r: Rect2) -> void:
    const ROT_FILEIRA := 108.0
    const ROT_COLUNA := 24.0
    const VAO_CELULA := 5.0
    const VAO_MAO := 12.0

    var por_largura := (r.size.x - ROT_FILEIRA - 8.0 - VAO_CELULA * 4.0) / 5.0
    ## A mão é limitada a 82 px de largura. Sem o teto ela cresce com a coluna,
    ## come a altura da grade e a casa cai para 62 px — 2 abaixo do alvo de toque
    ## de 64. A grade é a coisa mais importante da tela; quem cede é a mão.
    var carta_mao := minf((r.size.x - VAO_MAO * 4.0) / 5.0, 82.0)
    var alt_mao := carta_mao * Carta.RAZAO
    var sobra := r.size.y - ROT_COLUNA - 28.0 - alt_mao
    var por_altura := (sobra - VAO_CELULA * 4.0) / (5.0 * Carta.RAZAO)
    var celula := floorf(minf(por_largura, por_altura))

    var grade_larg := celula * 5.0 + VAO_CELULA * 4.0
    var grade_alt := celula * Carta.RAZAO * 5.0 + VAO_CELULA * 4.0
    var bloco := grade_larg + 8.0 + ROT_FILEIRA
    var gx := r.position.x + (r.size.x - bloco) * 0.5
    var grade := Rect2(gx, r.position.y, grade_larg, grade_alt)

    var tabuleiro := Rect2(grade.position,
                           Vector2(bloco, grade.size.y + ROT_COLUNA + 6.0))
    Pintura.mesa_embutida(self, tabuleiro)
    _grade(grade, celula, VAO_CELULA)
    _rotulos(grade, celula, VAO_CELULA, ROT_FILEIRA, ROT_COLUNA)
    _diagonais(Rect2(grade.end.x + 8, grade.end.y + 8, ROT_FILEIRA, ROT_COLUNA))
    _faixa_do_evento(grade)
    ## A mão alinha pelo centro da MESA, não da grade nem da coluna. A massa
    ## visual que o olho usa como eixo é a mesa inteira.
    var mao_larg := carta_mao * 5.0 + VAO_MAO * 4.0
    _mao(Rect2(tabuleiro.get_center().x - mao_larg * 0.5, r.end.y - alt_mao,
               mao_larg, alt_mao), carta_mao, VAO_MAO)

# ─────────────────────────────── retrato ───────────────────────────────

func _retrato() -> void:
    ## Em 360 px não cabem a casa de 64, a faixa de rótulos em texto e a margem
    ## de 12. A regra decide quem cede: o elemento onde o dedo trabalha é o único
    ## que não cede tamanho. Então a margem encolhe, o rótulo de fileira vira uma
    ## barra de 8 px, e a tabela de mãos sai da tela para trás do botão REGRAS.
    const MARGEM_R := 8.0
    const BARRA_FILEIRA := 8.0
    const VAO_CELULA := 4.0
    const VAO_MAO := 4.0

    var util := size.x - MARGEM_R * 2.0
    _barra(Rect2(MARGEM_R, 10, util, 40))
    _faixa_estado(Rect2(MARGEM_R, 58, util, 84.0))

    var celula := floorf((util - BARRA_FILEIRA - VAO_CELULA * 4.0) / 5.0)
    var grade_larg := celula * 5.0 + VAO_CELULA * 4.0
    var grade_alt := celula * Carta.RAZAO * 5.0 + VAO_CELULA * 4.0
    var grade := Rect2(MARGEM_R, 154, grade_larg, grade_alt)
    Pintura.mesa_embutida(self, grade)
    _grade(grade, celula, VAO_CELULA)
    _barras_de_fileira(grade, celula, VAO_CELULA, BARRA_FILEIRA)
    _rotulos_coluna(grade, celula, VAO_CELULA, 20.0)

    var carta_mao := floorf((util - VAO_MAO * 4.0) / 5.0)
    var alt_mao := carta_mao * Carta.RAZAO
    var mao_y := size.y - alt_mao - MARGEM_R
    _mao(Rect2(MARGEM_R, mao_y, util, alt_mao), carta_mao, VAO_MAO)

    var vao_topo := grade.end.y + 28.0
    var vao_alt := mao_y - vao_topo - 10.0
    if vao_alt >= 34.0:
        var faixa := Rect2(MARGEM_R, vao_topo + (vao_alt - 40.0) * 0.5, util,
                           minf(40.0, vao_alt))
        Pintura.caixa(self, faixa, 10, 0.72)
        _diagonais(Rect2(faixa.position.x + 10, faixa.position.y + 8, 116, 24))
        _linha_do_evento(Rect2(faixa.position.x + 134, faixa.position.y,
                               faixa.size.x - 144, faixa.size.y))

# ─────────────────────────────── as peças ───────────────────────────────

func _barra(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var tam := Temas.T_TITULO if r.size.y > 46 else Temas.T_NUMERO
    draw_string(f, Vector2(r.position.x, r.position.y + r.size.y * 0.70),
                "CRUZADA", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Temas.TEXTO)
    var largura := f.get_string_size("CRUZADA", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
    if r.size.x > 420:
        draw_string(Temas.fonte_do_tema(),
                    Vector2(r.position.x + largura + 16, r.position.y + r.size.y * 0.68),
                    "rodada %d de %d · mesa %s" % [rodada(), Metas.RODADAS,
                                                   Metas.NOMES[mesa.tipo]],
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)

    ## REGRAS: âncora fixa no alto à direita, 44 px de altura mínima para o dedo.
    _r_regras = Rect2(r.end.x - 112, r.position.y, 112, maxf(r.size.y, 44.0))
    Pintura.caixa(self, _r_regras, 8, 0.9)
    Pintura.centrado(self, Temas.fonte_do_tema(true), _r_regras, "REGRAS",
                     Temas.T_CORPO, Temas.TEXTO)

## Coluna esquerda: o ESTADO. O jogador consulta, não toca.
func _painel_estado(r: Rect2) -> void:
    Pintura.caixa(self, r, 12, 0.72)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var x := r.position.x + 20.0
    var larg := r.size.x - 40.0

    draw_string(ff, Vector2(x, r.position.y + 30), "PONTOS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    draw_string(ff, Vector2(x, r.position.y + 84), Pintura.milhar(int(_pontos_mostrados)),
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_HEROI, Temas.TEXTO)
    draw_string(f, Vector2(x, r.position.y + 112), "de " + Pintura.milhar(mesa.meta),
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)

    var trilho := Rect2(x, r.position.y + 128, larg, 10)
    Pintura.pilula(self, trilho, Color(Temas.BORDA, 0.8))
    var fracao := clampf(_pontos_mostrados / float(maxi(1, mesa.meta)), 0.0, 1.0)
    if fracao > 0.0:
        var cheio := Rect2(trilho.position, Vector2(trilho.size.x * fracao, trilho.size.y))
        ## Verde só quando bateu: a cor de sucesso gasta antes da hora deixa de
        ## significar sucesso.
        Pintura.pilula(self, cheio,
                       Temas.SUCESSO if mesa.pontos >= mesa.meta else Temas.DESTAQUE)

    draw_rect(Rect2(x, r.position.y + 164, larg, 1), Color(Temas.FILETE, 0.18))

    draw_string(ff, Vector2(x, r.position.y + 196), "TEAR",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    draw_string(ff, Vector2(x, r.position.y + 252), "×%d" % mesa.tear,
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_HEROI, Temas.DESTAQUE)
    var frase := "sobe e nunca desce"
    if mesa.tear >= Metas.TEAR_TETO:
        frase = "no teto"
    draw_string(f, Vector2(x + 88, r.position.y + 248), frase,
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)

    draw_rect(Rect2(x, r.position.y + 286, larg, 1), Color(Temas.FILETE, 0.18))

    ## Rodada e vidas como contas, não como texto: o jogador vê onde está e
    ## quanto lhe resta sem ler nada.
    draw_string(ff, Vector2(x, r.position.y + 322), "RODADA",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    for i in Metas.RODADAS:
        var c := Vector2(x + 92 + i * 19, r.position.y + 317)
        if i < rodada():
            draw_circle(c, 5.5, Temas.DESTAQUE if i == rodada() - 1 else Temas.TEXTO_SUAVE)
        else:
            draw_circle(c, 5.5, Color(Temas.BORDA, 0.9))

    draw_string(ff, Vector2(x, r.position.y + 356), "VIDAS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    for i in VIDAS_POR_RUN:
        var c := Vector2(x + 92 + i * 26, r.position.y + 351)
        ## Vida gasta vira contorno, não some: quem olha precisa ver que tinha três.
        if i < vidas():
            Carta.simbolo(self, c, 17.0, 0)
        else:
            draw_arc(c, 7.0, 0.0, TAU, 20, Color(Temas.TEXTO_SUAVE, 0.5), 1.5)

    _contadores(Rect2(x, r.end.y - 58, larg, 38))

func _contadores(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var larg := (r.size.x - 10.0) / 2.0
    var restam := mesa.posicionamentos_max - mesa.posicionamentos_usados
    var itens := [[str(restam), "JOGADAS"], [str(mesa.descartes_restantes), "DESCARTES"]]
    for i in itens.size():
        var b := Rect2(r.position.x + i * (larg + 10), r.position.y, larg, r.size.y)
        ## O último punhado de jogadas muda de cor: é o único aviso que o jogo
        ## dá de que a mesa está acabando, e ele precisa chegar antes do fim.
        var pouco := i == 0 and restam <= 3
        Pintura.pilula(self, b, Color(Temas.ALERTA if pouco else Temas.BORDA,
                                      0.35 if not pouco else 0.30))
        Pintura.centrado(self, f, b, "%s  %s" % [itens[i][0], itens[i][1]],
                         Temas.T_CORPO, Temas.ALERTA if pouco else Temas.TEXTO)

## Faixa de estado do retrato: os mesmos três números, deitados.
func _faixa_estado(r: Rect2) -> void:
    Pintura.caixa(self, r, 12, 0.72)
    var col := r.size.x / 3.0
    Pintura.numero(self, Rect2(r.position.x, r.position.y + 8, col, 44), "PONTOS",
                   Pintura.milhar(int(_pontos_mostrados)), Temas.TEXTO, 26)
    Pintura.numero(self, Rect2(r.position.x + col, r.position.y + 8, col, 44), "META",
                   Pintura.milhar(mesa.meta), Temas.TEXTO_SUAVE, 26)
    Pintura.numero(self, Rect2(r.position.x + col * 2, r.position.y + 8, col, 44), "TEAR",
                   "×%d" % mesa.tear, Temas.DESTAQUE, 26)
    _contadores(Rect2(r.position.x + 12, r.end.y - 32, r.size.x - 24, 24))

## Coluna direita: a REFERÊNCIA. Consulta ocasional, nunca no caminho do dedo.
func _painel_referencia(r: Rect2) -> void:
    Pintura.caixa(self, r, 12, 0.72)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    draw_string(ff, Vector2(r.position.x + 20, r.position.y + 30), "MÃOS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)

    ## Só as linhas CHEIAS acendem. Acender a categoria parcial de toda linha com
    ## três cartas deixava metade da tabela iluminada o tempo todo — realce que
    ## está sempre ligado deixa de ser realce.
    var na_mesa := {}
    for l in Geometria.LINHAS:
        if mesa.contagem[l] == Geometria.LADO:
            var cs := mesa.cartas_da_linha(l)
            na_mesa[Maos.categoria(cs[0], cs[1], cs[2], cs[3], cs[4])] = true

    var passo := minf(40.0, (r.size.y - 72.0) / float(Maos.CATEGORIAS))
    var y := r.position.y + 52.0
    for cat in range(Maos.CATEGORIAS - 1, -1, -1):
        var feita: bool = na_mesa.has(cat)
        var cor: Color = Temas.DESTAQUE if feita else Temas.TEXTO
        if feita:
            Pintura.pilula(self, Rect2(r.position.x + 12, y - 15, r.size.x - 24, 26),
                           Color(Temas.DESTAQUE, 0.16), 6)
        draw_string(f, Vector2(r.position.x + 20, y + 5), Maos.NOMES[cat],
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, cor)
        ## Números tabulares alinhados à direita: o olho compara sem esforço.
        draw_string(ff, Vector2(r.end.x - 112, y + 5), str(Maos.FICHAS_BASE[cat]),
                    HORIZONTAL_ALIGNMENT_RIGHT, 60, Temas.T_CORPO, Temas.TEXTO_SUAVE)
        draw_string(ff, Vector2(r.end.x - 62, y + 5), "×%d" % Maos.MULTIPLICADOR[cat],
                    HORIZONTAL_ALIGNMENT_RIGHT, 44, Temas.T_CORPO, Temas.ACENTO)
        y += passo

# ─────────────────────────────── a grade ───────────────────────────────

func _grade(r: Rect2, celula: float, vao: float) -> void:
    var alt := celula * Carta.RAZAO
    for casa in Geometria.CASAS:
        var fileira := Geometria.fileira_da(casa)
        var coluna := Geometria.coluna_da(casa)
        var c := Rect2(r.position + Vector2(coluna * (celula + vao),
                                            fileira * (alt + vao)),
                       Vector2(celula, alt))
        _r_casas[casa] = c
        var carta: int = mesa.grade[casa]
        if carta == Mesa.VAZIA:
            _casa_livre(c, casa)
            continue
        var madura := _casa_madura(casa)
        var estado := Carta.MADURA if madura else Carta.NA_GRADE
        if Mesa.eh_avesso(carta):
            Carta.desenhar_avesso(self, c,
                Cartas.figura(Mesa.face(carta, true)), Cartas.naipe(Mesa.face(carta, true)),
                Cartas.figura(Mesa.face(carta, false)), Cartas.naipe(Mesa.face(carta, false)),
                estado)
        else:
            Carta.desenhar(self, c, Cartas.figura(carta), Cartas.naipe(carta), estado)

## A casa pertence a alguma linha madura, esperando a colheita?
func _casa_madura(casa: int) -> bool:
    for l in Geometria.linhas_da_casa(casa):
        if mesa.madura[l] == 1:
            return true
    return false

func _casa_livre(c: Rect2, casa: int) -> void:
    ## "Viva" é a casa que fecha alguma linha: é a única informação que muda a
    ## decisão e ela precisa estar na casa, não num painel.
    var viva := false
    for l in Geometria.linhas_da_casa(casa):
        if mesa.contagem[l] == Geometria.LADO - 1:
            viva = true
    Pintura.casa_vazia(self, c, viva)
    if _selecionada < 0 or _casa_sob_o_dedo != casa or mesa.acabou:
        return
    ## O fantasma da carta escolhida, e o que ela paga. A dica mais barata que
    ## existe: mostrar a consequência antes do clique, sem opinar sobre ela.
    var carta: int = mesa.mao[_selecionada]
    if Mesa.eh_avesso(carta):
        Carta.desenhar_avesso(self, c,
            Cartas.figura(Mesa.face(carta, true)), Cartas.naipe(Mesa.face(carta, true)),
            Cartas.figura(Mesa.face(carta, false)), Cartas.naipe(Mesa.face(carta, false)),
            Carta.NA_GRADE)
    else:
        Carta.desenhar(self, c, Cartas.figura(carta), Cartas.naipe(carta), Carta.NA_GRADE)
    ## Sem véu por cima: a primeira versão escurecia o fantasma e ele virava um
    ## retângulo cinza que parecia defeito. A moldura sozinha já diz "isto ainda
    ## não aconteceu", e a carta continua legível — que é o ponto de mostrá-la.
    draw_rect(c.grow(-1.5), Temas.DESTAQUE, false, 3.0)
    var g := mesa.ganho(_selecionada, casa)
    if g > 0:
        var etiqueta := Rect2(c.position.x, c.get_center().y - 13, c.size.x, 26)
        Pintura.pilula(self, etiqueta, Temas.DESTAQUE, 6)
        Pintura.centrado(self, Temas.fonte_do_tema(true), etiqueta,
                         "+" + Pintura.milhar(g), Temas.T_ROTULO,
                         Temas.CARTA if Temas.e_claro() else Temas.FUNDO)

## Os rótulos de linha: a fração e a categoria, colados na linha. É a informação
## que o jogador mais lê — painel distante obrigaria o olho a viajar.
func _rotulos(g: Rect2, celula: float, vao: float, larg: float, alt_col: float) -> void:
    var f := Temas.fonte_do_tema(true)
    var alt := celula * Carta.RAZAO
    for i in 5:
        var y := g.position.y + i * (alt + vao)
        _rotulo(f, Rect2(g.end.x + 8, y + alt * 0.5 - 15, larg, 30),
                Geometria.FILEIRA_0 + i, false)
    for i in 5:
        var x := g.position.x + i * (celula + vao)
        _rotulo(f, Rect2(x, g.end.y + 8, celula, alt_col),
                Geometria.COLUNA_0 + i, true)

## Em retrato não há largura para texto ao lado da grade. O estado da fileira
## vira uma barra de progresso de 8 px na borda externa: a mesma informação em
## FORMA, que é o que sobrevive sem cor e sem espaço.
func _barras_de_fileira(g: Rect2, celula: float, vao: float, larg: float) -> void:
    var alt := celula * Carta.RAZAO
    for i in 5:
        var l := Geometria.FILEIRA_0 + i
        var y := g.position.y + i * (alt + vao)
        ## Cinco marcas, não uma barra contínua: "3 de 5" se lê contando, e a
        ## barra contínua de 6 px de largura obrigava a estimar uma fração. A
        ## primeira versão era invisível na captura, que é como se descobre.
        var trilho := Rect2(g.end.x + 2, y + alt * 0.10, larg - 2, alt * 0.80)
        var vao_marca := 2.0
        var marca := (trilho.size.y - vao_marca * 4.0) / 5.0
        var madura := mesa.madura[l] == 1
        for k in Geometria.LADO:
            ## De baixo para cima: a linha enche como um copo.
            var cheio := k < mesa.contagem[l]
            var caixa := Rect2(trilho.position.x,
                               trilho.end.y - (k + 1) * marca - k * vao_marca,
                               trilho.size.x, marca)
            var cor := Color(Temas.CASA_BORDA, 0.55)
            if cheio:
                cor = Temas.DESTAQUE if madura else Temas.TEXTO_SUAVE
            Pintura.pilula(self, caixa, cor, int(trilho.size.x * 0.5))

func _rotulos_coluna(g: Rect2, celula: float, vao: float, alt_rot: float) -> void:
    var f := Temas.fonte_do_tema(true)
    for i in 5:
        var x := g.position.x + i * (celula + vao)
        _rotulo(f, Rect2(x, g.end.y + 6, celula, alt_rot), Geometria.COLUNA_0 + i, true)

## AS DIAGONAIS. Elas são duas das doze linhas vivas e pagam 60%, mas não têm
## fileira nem coluna onde pendurar um rótulo — na primeira versão desta tela o
## jogador só descobria que uma diagonal estava cheia quando ela colhia. Duas
## fichas no canto livre resolvem: a informação existe e ocupa 108 px.
func _diagonais(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var larg := (r.size.x - 4.0) * 0.5
    var setas := ["↘", "↗"]
    for i in 2:
        var l := Geometria.DIAGONAL_0 + i
        var caixa := Rect2(r.position.x + i * (larg + 4.0), r.position.y, larg, r.size.y)
        var madura := mesa.madura[l] == 1
        var cor := Temas.TEXTO_SUAVE
        if madura:
            Pintura.pilula(self, caixa, Temas.DESTAQUE, 6)
            cor = Temas.CARTA if Temas.e_claro() else Temas.FUNDO
        elif mesa.contagem[l] > 0:
            Pintura.pilula(self, caixa, Color(Temas.BORDA, 0.40), 6)
        ## Só a fração, nunca a palavra: em 52 px "CHEIA" estourava a ficha. O
        ## preenchimento dourado já diz que ela está esperando a colheita, e uma
        ## linha em 5/5 não pode estar em outro estado.
        var texto := "%s %d/5" % [setas[i], mesa.contagem[l]]
        Pintura.centrado(self, f, caixa, texto, Temas.T_ROTULO, cor)

## O que acabou de acontecer, grande, no meio da mesa, sumindo sozinho. Sem isto
## a colheita é só um número correndo num painel lateral: o jogador vê a
## pontuação mudar e não sabe por quê.
func _faixa_do_evento(grade: Rect2) -> void:
    if _realce <= 0.0 or _relato.is_empty():
        return
    if not bool(_relato["colheita"]):
        return
    ## Opaco durante a maior parte do tempo, e some nos últimos 45%: aparecer
    ## devagar atrasaria a leitura, sumir devagar não atrapalha nada.
    var t := clampf(_realce / (TEMPO_DO_REALCE * 0.45), 0.0, 1.0)
    var ff := Temas.fonte_do_tema(true)
    var grau := str(_relato["grau"])
    var pontos := "+" + Pintura.milhar(int(_relato["pontos_evento"]))
    var caixa := Rect2(grade.position.x, grade.get_center().y - 66, grade.size.x, 132)
    var fundo := StyleBoxFlat.new()
    fundo.bg_color = Color(Temas.FUNDO, 0.86 * t)
    fundo.border_color = Color(Temas.DESTAQUE, 0.8 * t)
    fundo.set_border_width_all(2)
    fundo.set_corner_radius_all(14)
    draw_style_box(fundo, caixa)
    Pintura.centrado(self, ff, Rect2(caixa.position.x, caixa.position.y + 6,
                                     caixa.size.x, 34), grau, Temas.T_TITULO,
                     Color(Temas.DESTAQUE, t))
    Pintura.centrado(self, ff, Rect2(caixa.position.x, caixa.position.y + 42,
                                     caixa.size.x, 54), pontos, Temas.T_HEROI,
                     Color(Temas.TEXTO, t))
    ## A conta da R12 aparecendo no instante em que ela paga. Ver
    ## "mults 5 × Tear 2 = fator 10" uma vez ensina a regra melhor que o
    ## compêndio inteiro — e é a única explicação que o jogo dá dela.
    Pintura.centrado(self, Temas.fonte_do_tema(),
                     Rect2(caixa.position.x, caixa.end.y - 30, caixa.size.x, 24),
                     "mults %d × Tear %d = fator %d" % [int(_relato["soma_dos_mults"]),
                                                        int(_relato["tear_do_evento"]),
                                                        int(_relato["fator"])],
                     Temas.T_ROTULO, Color(Temas.TEXTO_SUAVE, t))

func _rotulo(f: FontFile, r: Rect2, linha: int, compacto: bool) -> void:
    var cheias: int = mesa.contagem[linha]
    var madura := mesa.madura[linha] == 1
    var cor := Temas.TEXTO_SUAVE
    if madura:
        ## Preenchimento sólido com texto invertido. O chip translúcido sumia em
        ## escala de cinza: virava cinza sobre cinza. Sólido, o contraste é de
        ## valor tonal e sobrevive sem cor.
        Pintura.pilula(self, r, Temas.DESTAQUE, 6)
        cor = Temas.CARTA if Temas.e_claro() else Temas.FUNDO
    var texto := "%d/5" % cheias
    if madura:
        texto = "CHEIA" if compacto else "MADURA"
    elif cheias == Geometria.LADO - 1 and not compacto:
        ## A categoria alcançável só entra em 4/5. Com três cartas ela ainda diz
        ## "QUADRA" para qualquer trio solto — promessa que não restringe nada é
        ## ruído com ar de informação. Faltando uma carta, ela vira conselho: a
        ## linha diz exatamente no que ainda pode virar.
        texto = Maos.CURTOS[Maos.melhor_alcancavel(mesa.cartas_da_linha(linha))]
    Pintura.centrado(self, f, r, texto, Temas.T_ROTULO, cor)

# ─────────────────────────────── a mão ───────────────────────────────

func _mao(r: Rect2, largura: float, vao: float) -> void:
    var n := mesa.mao.size()
    if n == 0:
        return
    var alt := largura * Carta.RAZAO
    var total := largura * n + vao * (n - 1)
    var x := r.position.x + (r.size.x - total) * 0.5
    _r_mao.resize(n)
    for i in n:
        var c := Rect2(x + i * (largura + vao), r.position.y, largura, alt)
        _r_mao[i] = c
        var carta: int = mesa.mao[i]
        var estado := Carta.NORMAL
        if i == _selecionada:
            ## A carta escolhida sobe. Erguer é a única forma de realce que
            ## funciona nos oito temas: não depende de cor nenhuma.
            c.position.y -= alt * 0.10
            estado = Carta.HOVER
        elif i == _carta_sob_o_dedo:
            c.position.y -= alt * 0.05
            estado = Carta.HOVER
        if Mesa.eh_avesso(carta):
            Carta.desenhar_avesso(self, c,
                Cartas.figura(Mesa.face(carta, true)), Cartas.naipe(Mesa.face(carta, true)),
                Cartas.figura(Mesa.face(carta, false)), Cartas.naipe(Mesa.face(carta, false)),
                Carta.AVESSO)
        else:
            Carta.desenhar(self, c, Cartas.figura(carta), Cartas.naipe(carta), estado)

# ────────────────────── o que acabou de acontecer ──────────────────────

func _linha_do_evento(r: Rect2) -> void:
    if _relato.is_empty():
        return
    var ff := Temas.fonte_do_tema(true)
    var texto := ""
    var cor := Temas.TEXTO_SUAVE
    if bool(_relato["colheita"]):
        texto = "%s  ·  +%s" % [_relato["grau"], Pintura.milhar(int(_relato["pontos_evento"]))]
        cor = Temas.DESTAQUE
    elif int(_relato["pontos_parcela"]) > 0:
        texto = "PARCELA  ·  +%s" % Pintura.milhar(int(_relato["pontos_parcela"]))
        cor = Temas.ACENTO
    else:
        texto = "sem pontos neste turno"
    Pintura.centrado(self, ff, r, texto, Temas.T_CORPO, cor)

## AS REGRAS, atrás de um botão fixo no alto à direita.
##
## O jogo inteiro cabe em dez frases, e é assim que ele precisa ser explicado —
## quem abre REGRAS está travado no meio de um turno e quer a resposta, não um
## manual. Cada linha começa pelo nome que aparece na tela: o jogador chegou aqui
## depois de ver a palavra, e é por ela que ele procura.
##
## Os nomes foram testados com dois leitores cegos, e 10 de 33 reprovaram. Estes
## são os que passaram; nenhum deles se troca sem repetir o teste.
const REGRAS: Array[Array] = [
    ["", "Cada carta pontua em duas mãos de pôquer: a fileira e a coluna onde você a colocar."],
    ["O TURNO", "Coloque uma carta numa casa vazia e compre de volta. A carta fica ali."],
    ["PARCELA", "Ao chegar a 3 e a 4 cartas, a linha já paga um troco. Sem gastar turno."],
    ["MADURA", "Linha com 5 cartas não colhe na hora: fica madura e colhe no próximo posicionamento."],
    ["CRUZADA", "Colher duas ou mais de uma vez soma os multiplicadores de TODAS elas — e o Tear multiplica a soma. É por isso que vale esperar."],
    ["DUPLA · TRIPLA · CRUZ TOTAL", "Duas, três e quatro linhas no mesmo evento. A Cruz Total cabe exata numa mesa Grande."],
    ["TEAR", "Sobe +1 a cada colheita e +1 a cada 4 cartas, até 8. Multiplica o evento inteiro."],
    ["AVESSO", "Toda colheita prensa as duas maiores cartas da linha numa carta de duas caras. Uma vale na fileira, a outra na coluna. Toque de novo para girar."],
    ["DIAGONAIS", "As duas diagonais também são mãos, e pagam 60%."],
    ["LINHA FRACA", "Carta Alta e Par devolvem +1 Tear, +2 descartes e +1 na mão. E ganham fichas por quase-flush e quase-escada."],
    ["O FIM", "Bateu a meta, venceu na hora. Acabaram as jogadas, cada linha com 3 ou 4 cartas ainda paga metade."],
]

func _regras() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(Temas.FUNDO, 0.90))
    var larg := minf(size.x - 48.0, 980.0)
    var caixa := Rect2((size.x - larg) * 0.5, 24.0, larg, size.y - 48.0)
    Pintura.caixa(self, caixa, 14, 0.97)

    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var margem := 26.0
    var y0 := caixa.position.y + 40.0

    draw_string(ff, Vector2(caixa.position.x + margem, y0), "REGRAS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_TITULO, Temas.TEXTO)
    y0 += 26.0
    draw_rect(Rect2(caixa.position.x + margem, y0, caixa.size.x - margem * 2, 1),
              Color(Temas.FILETE, 0.25))
    y0 += 22.0

    ## Duas colunas quando há largura; uma quando não há. E o que não couber vai
    ## para a página seguinte — texto cortado no rodapé é o defeito clássico de
    ## painel de regra, e ele só aparece quando alguém olha.
    var colunas := 2 if caixa.size.x >= 700.0 else 1
    var vao := 28.0
    var col_larg := (caixa.size.x - margem * 2 - vao * (colunas - 1)) / float(colunas)
    var fundo_util := caixa.end.y - 52.0

    var i := _regras_de
    for col in colunas:
        var x := caixa.position.x + margem + col * (col_larg + vao)
        var y := y0
        while i < REGRAS.size():
            var titulo := str(REGRAS[i][0])
            var corpo := str(REGRAS[i][1])
            var alt_corpo := f.get_multiline_string_size(
                corpo, HORIZONTAL_ALIGNMENT_LEFT, col_larg, Temas.T_CORPO).y
            var altura := alt_corpo + 16.0 + (22.0 if titulo != "" else 0.0)
            if y + altura > fundo_util:
                break
            if titulo != "":
                draw_string(ff, Vector2(x, y + 14), titulo, HORIZONTAL_ALIGNMENT_LEFT,
                            -1, Temas.T_ROTULO, Temas.DESTAQUE)
                y += 22.0
            draw_multiline_string(f, Vector2(x, y + 14), corpo,
                                  HORIZONTAL_ALIGNMENT_LEFT, col_larg, Temas.T_CORPO,
                                  -1, Temas.TEXTO if titulo == "" else Temas.TEXTO_SUAVE)
            y += alt_corpo + 16.0
            i += 1
    _regras_ate = i

    var rodape := "toque em qualquer lugar para voltar"
    if _regras_ate < REGRAS.size():
        rodape = "toque para ver o resto"
    Pintura.centrado(self, f, Rect2(caixa.position.x, caixa.end.y - 40,
                                    caixa.size.x, 26), rodape, Temas.T_ROTULO,
                     Temas.TEXTO_SUAVE)

func _fim_de_mesa() -> void:
    ## O véu escurece a mesa sem escondê-la: o jogador precisa ver o tabuleiro
    ## que produziu aquele resultado enquanto lê o resultado.
    draw_rect(Rect2(Vector2.ZERO, size), Color(Temas.FUNDO, 0.82))
    var caixa := Rect2(size.x * 0.5 - 210, size.y * 0.5 - 90, 420, 180)
    Pintura.caixa(self, caixa, 14, 0.96)
    var ff := Temas.fonte_do_tema(true)
    var titulo := "META BATIDA" if mesa.venceu else "MESA PERDIDA"
    Pintura.centrado(self, ff, Rect2(caixa.position.x, caixa.position.y + 20,
                                     caixa.size.x, 52), titulo, Temas.T_TITULO,
                     Temas.SUCESSO if mesa.venceu else Temas.ALERTA)
    Pintura.centrado(self, ff, Rect2(caixa.position.x, caixa.position.y + 74,
                                     caixa.size.x, 52),
                     "%s de %s" % [Pintura.milhar(mesa.pontos), Pintura.milhar(mesa.meta)],
                     Temas.T_HEROI, Temas.TEXTO)
    Pintura.centrado(self, Temas.fonte_do_tema(),
                     Rect2(caixa.position.x, caixa.end.y - 44, caixa.size.x, 30),
                     _o_que_vem(), Temas.T_CORPO, Temas.TEXTO_SUAVE)

## O jogador precisa saber o que custou a derrota antes de tocar. "Toque para
## seguir" esconde a informação mais importante da tela.
func _o_que_vem() -> String:
    if run == null:
        return "toque para seguir"
    if mesa.venceu:
        if run.rodada >= Metas.RODADAS and run.indice_da_mesa >= Run.MESAS_POR_RODADA - 1:
            return "toque para fechar a run"
        return "toque para a próxima mesa"
    if run.vidas <= 1:
        return "era a última vida — toque para encerrar a run"
    return "custa uma vida: sobram %d — toque para repetir a mesa" % (run.vidas - 1)
