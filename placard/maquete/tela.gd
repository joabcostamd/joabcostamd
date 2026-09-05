extends Control
class_name TelaMaquete
## A tela de partida do PLACARD, montada com um estado fixo e realista.
##
## Não é o jogo: é a maquete que existe para o tema ser escolhido olhando, e
## não lendo adjetivo. O estado desenhado é o momento canônico do design — uma
## carta fechando fileira e coluna ao mesmo tempo, que é a CRUZADA.
##
## LAYOUT — a regra que organiza tudo: **o centro só tem o que o jogador toca.**
## Esquerda é estado (consulta), centro é jogo (manipulação), direita é
## referência (consulta ocasional). Ver `HUD.md`.

const VAZIO := -1
const MARGEM := 24.0
const VAO := 20.0
const BARRA := 52.0

## [valor, naipe]; valor 1=Ás..13=K, naipe 0 copas, 1 ouros, 2 paus, 3 espadas.
##       A       B       C       D       E
## 0    K♠       ·      10♥      ·       ·
## 1     ·       ·       7♥      ·      3♦
## 2    Q♥      Q♠       9♥     Q♦      9♠   ← fileira cheia
## 3     ·       ·       6♥      ·       ·
## 4     ·       ·       8♥      ·      A♣
##                       ↑ coluna cheia
## A mesma carta (9♥ em C2) fechou a fileira e a coluna: Full House cruzando
## com Sequência de Cor.
const GRADE := [
    [[13, 3], VAZIO, [10, 0], VAZIO, VAZIO],
    [VAZIO, VAZIO, [7, 0], VAZIO, [3, 1]],
    [[12, 0], [12, 3], [9, 0], [12, 1], [9, 3]],
    [VAZIO, VAZIO, [6, 0], VAZIO, VAZIO],
    [VAZIO, VAZIO, [8, 0], VAZIO, [1, 2]],
]

const MAO := [[9, 1], [4, 2], [11, 0], [2, 3], [7, 3]]
const CARTA_AVESSO := 4  ## índice da mão que é o coringa de duas caras

const ROTULO_FILEIRA := ["2/5", "2/5", "FULL HOUSE", "1/5", "2/5"]
const ROTULO_COLUNA := ["2/5", "1/5", "SEQ. DE COR", "1/5", "3/5"]
const CHEIA_FILEIRA := 2
const CHEIA_COLUNA := 2

const PONTOS := 4144
const META := 2962
const MULT := 6
const JOGADAS := 4
const DESCARTES := 1

const MAOS := [
    ["Sequência de Cor", "100", "×8", true],
    ["Quadra", "60", "×7", false],
    ["Full House", "40", "×4", true],
    ["Flush", "35", "×4", false],
    ["Sequência", "30", "×4", false],
    ["Trinca", "30", "×3", false],
    ["Dois Pares", "20", "×2", false],
    ["Par", "10", "×2", false],
    ["Carta Alta", "5", "×1", false],
]

var _poeira: Array[Vector3] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Semente fixa (dentro de Pintura): a maquete precisa sair idêntica em toda
    # captura, senão duas rodadas do mesmo tema não são comparáveis.
    _poeira = Pintura.semear_poeira()
    _acompanhar()
    get_viewport().size_changed.connect(_acompanhar)

func _acompanhar() -> void:
    position = Vector2.ZERO
    size = get_viewport_rect().size
    queue_redraw()

func _draw() -> void:
    Pintura.fundo(self, size, _poeira)
    if size.y > size.x:
        _retrato()
    else:
        _paisagem()

func _paisagem() -> void:
    var util := size.x - MARGEM * 2.0
    # O centro leva a maior fatia; as laterais ficam iguais para a tela não
    # pender para um lado. 500 no centro cabe a mão de 5 cartas de 86 px.
    var centro_larg := clampf(util * 0.41, 420.0, 560.0)
    var lateral := (util - centro_larg - VAO * 2.0) * 0.5

    var topo := MARGEM * 0.5
    _barra(Rect2(MARGEM, topo, util, BARRA))

    var y := topo + BARRA + 8.0
    var alt := size.y - y - MARGEM * 0.5
    # Cada painel tem a altura do seu conteúdo, não a da coluna. Moldura com
    # buraco dentro lê como inacabado; espaço vazio FORA da moldura lê como
    # respiro. É a diferença mais barata entre interface cara e improvisada.
    _painel_estado(Rect2(MARGEM, y, lateral, 446.0))
    _centro(Rect2(MARGEM + lateral + VAO, y, centro_larg, alt))
    var dir := MARGEM + lateral + VAO + centro_larg + VAO
    _painel_referencia(Rect2(dir, y, lateral, 462.0))
    _rodape_mesa(Rect2(dir, y + 462.0 + 14.0, lateral, 54.0))

## O centro: só grade e mão. Nada de status, nada de tabela.
func _centro(r: Rect2) -> void:
    const ROT_FILEIRA := 108.0
    const ROT_COLUNA := 24.0
    const VAO_CELULA := 5.0
    const VAO_MAO := 12.0

    # A célula sai da restrição mais apertada entre largura e altura. Fixar um
    # número quebraria assim que a janela mudasse.
    var por_largura := (r.size.x - ROT_FILEIRA - 8.0 - VAO_CELULA * 4.0) / 5.0
    # A mão é limitada a 82 px de largura. Sem o teto ela cresce com a coluna,
    # come a altura da grade e a casa cai para 62 px — 2 abaixo do alvo de toque
    # de 64. A grade é a coisa mais importante da tela; quem cede é a mão.
    var carta_mao := minf((r.size.x - VAO_MAO * 4.0) / 5.0, 82.0)
    var alt_mao := carta_mao * Carta.RAZAO
    # 28 de folga entre os rótulos de coluna e a mão: a carta erguida do hover
    # sobe 5% da própria altura e encostava no rótulo com menos que isso.
    var sobra := r.size.y - ROT_COLUNA - 28.0 - alt_mao
    var por_altura := (sobra - VAO_CELULA * 4.0) / (5.0 * Carta.RAZAO)
    var celula := floorf(minf(por_largura, por_altura))

    var grade_larg := celula * 5.0 + VAO_CELULA * 4.0
    var grade_alt := celula * Carta.RAZAO * 5.0 + VAO_CELULA * 4.0
    var bloco := grade_larg + 8.0 + ROT_FILEIRA
    var gx := r.position.x + (r.size.x - bloco) * 0.5
    var grade := Rect2(gx, r.position.y, grade_larg, grade_alt)

    var mesa := Rect2(grade.position, Vector2(bloco, grade.size.y + ROT_COLUNA + 6.0))
    Pintura.mesa_embutida(self, mesa)
    _grade(grade, celula, VAO_CELULA)
    _rotulos(grade, celula, VAO_CELULA, ROT_FILEIRA, ROT_COLUNA)
    # A mão alinha pelo centro da MESA, não da grade nem da coluna. A massa
    # visual que o olho usa como eixo é a mesa inteira — grade mais rótulos —,
    # e centrar na grade sozinha joga a mão para a esquerda.
    var mao_larg := carta_mao * 5.0 + VAO_MAO * 4.0
    _mao(Rect2(mesa.get_center().x - mao_larg * 0.5, r.end.y - alt_mao, mao_larg, alt_mao),
         carta_mao, VAO_MAO)

# ─────────────────────────────── retrato ───────────────────────────────
# Três colunas não cabem em 360 de largura. A esquerda vira faixa no topo, a
# direita vira tabela no vão entre a grade e a mão, e os rótulos de fileira
# viram pontinhos de progresso na margem estreita.

func _retrato() -> void:
    # Em 360 px não cabem a casa de 64, a faixa de rótulos em texto e a margem
    # de 12. A regra decide quem cede: o elemento onde o dedo trabalha é o único
    # que não cede tamanho. Então a margem encolhe, o rótulo de fileira vira uma
    # barra de 8 px, e a tabela de mãos sai da tela para trás do botão REGRAS.
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

    # No vão que sobra entre a grade e a mão vai a informação mais quente que
    # ainda não está na tela: qual é o modificador desta mesa.
    var vao_topo := grade.end.y + 28.0
    var vao_alt := mao_y - vao_topo - 10.0
    if vao_alt >= 34.0:
        var faixa := Rect2(MARGEM_R, vao_topo + (vao_alt - 40.0) * 0.5, util, minf(40.0, vao_alt))
        Pintura.caixa(self, faixa, 10, 0.72)
        var ff := Temas.fonte_do_tema(true)
        draw_string(ff, Vector2(faixa.position.x + 14, faixa.position.y + faixa.size.y * 0.66),
                    "MESA", HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
        # Em retrato só o nome. A explicação do modificador é trabalho do
        # compêndio: tela estreita não é lugar de frase longa, e texto que
        # encosta na borda lê como descuido mesmo quando cabe por um pixel.
        draw_string(Temas.fonte_do_tema(), Vector2(faixa.position.x + 66,
                    faixa.position.y + faixa.size.y * 0.66), "Rachada",
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.ALERTA)

# ─────────────────────────────── as peças ───────────────────────────────

func _barra(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var tam := Temas.T_TITULO if r.size.y > 46 else Temas.T_NUMERO
    draw_string(f, Vector2(r.position.x, r.position.y + r.size.y * 0.70),
                "CRUZADA", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Temas.TEXTO)
    var largura := f.get_string_size("CRUZADA", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
    if r.size.x > 420:
        draw_string(Temas.fonte_do_tema(), Vector2(r.position.x + largura + 16,
                    r.position.y + r.size.y * 0.68), "rodada 4 · mesa 2 de 3",
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)

    # REGRAS: âncora fixa no alto à direita, 44 px de altura mínima para o dedo.
    var b := Rect2(r.end.x - 112, r.position.y, 112, maxf(r.size.y, 44.0))
    Pintura.caixa(self, b, 8, 0.9)
    Pintura.centrado(self, Temas.fonte_do_tema(true), b, "REGRAS", Temas.T_CORPO, Temas.TEXTO)

## Coluna esquerda: o ESTADO. O jogador consulta, não toca.
func _painel_estado(r: Rect2) -> void:
    Pintura.caixa(self, r, 12, 0.72)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var x := r.position.x + 20.0
    var larg := r.size.x - 40.0

    draw_string(ff, Vector2(x, r.position.y + 30), "PONTOS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    draw_string(ff, Vector2(x, r.position.y + 84), Pintura.milhar(PONTOS),
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_HEROI, Temas.TEXTO)
    draw_string(f, Vector2(x, r.position.y + 112), "de " + Pintura.milhar(META),
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)

    var trilho := Rect2(x, r.position.y + 128, larg, 10)
    Pintura.pilula(self, trilho, Color(Temas.BORDA, 0.8))
    Pintura.pilula(self, trilho, Temas.SUCESSO)   # meta estourada: o verde diz "bateu" sem palavra

    # Um filete separando os dois blocos de informação. Régua, não decoração:
    # é ele que dá ritmo à coluna sem precisar de mais moldura.
    draw_rect(Rect2(x, r.position.y + 164, larg, 1), Color(Temas.FILETE, 0.18))

    draw_string(ff, Vector2(x, r.position.y + 196), "MULTIPLICADOR",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    draw_string(ff, Vector2(x, r.position.y + 252), "×%d" % MULT,
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_HEROI, Temas.DESTAQUE)
    draw_string(f, Vector2(x + 88, r.position.y + 248), "sobe e nunca desce",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)

    draw_rect(Rect2(x, r.position.y + 286, larg, 1), Color(Temas.FILETE, 0.18))

    # Rodada e vidas como contas, não como texto: o jogador vê onde está e
    # quanto lhe resta sem ler nada.
    draw_string(ff, Vector2(x, r.position.y + 322), "RODADA",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    for i in 6:
        var c := Vector2(x + 92 + i * 19, r.position.y + 317)
        if i < 4:
            draw_circle(c, 5.5, Temas.DESTAQUE if i == 3 else Temas.TEXTO_SUAVE)
        else:
            draw_circle(c, 5.5, Color(Temas.BORDA, 0.9))

    draw_string(ff, Vector2(x, r.position.y + 356), "VIDAS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    for i in 3:
        var c := Vector2(x + 92 + i * 26, r.position.y + 351)
        # Vida gasta vira contorno, não some: quem olha precisa ver que tinha três.
        if i < 2:
            Carta.simbolo(self, c, 17.0, 0)
        else:
            draw_arc(c, 7.0, 0.0, TAU, 20, Color(Temas.TEXTO_SUAVE, 0.5), 1.5)

    _contadores(Rect2(x, r.size.y + r.position.y - 58, larg, 38))

func _contadores(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var larg := (r.size.x - 10.0) / 2.0
    var itens := [[str(JOGADAS), "JOGADAS"], [str(DESCARTES), "DESCARTES"]]
    for i in itens.size():
        var b := Rect2(r.position.x + i * (larg + 10), r.position.y, larg, r.size.y)
        Pintura.pilula(self, b, Color(Temas.BORDA, 0.35))
        Pintura.centrado(self, f, b, "%s  %s" % [itens[i][0], itens[i][1]], Temas.T_CORPO, Temas.TEXTO)

## Faixa de estado do retrato: os mesmos três números, deitados.
func _faixa_estado(r: Rect2) -> void:
    Pintura.caixa(self, r, 12, 0.72)
    var col := r.size.x / 3.0
    Pintura.numero(self, Rect2(r.position.x, r.position.y + 8, col, 44), "PONTOS", Pintura.milhar(PONTOS),
            Temas.TEXTO, 26)
    Pintura.numero(self, Rect2(r.position.x + col, r.position.y + 8, col, 44), "META", Pintura.milhar(META),
            Temas.TEXTO_SUAVE, 26)
    Pintura.numero(self, Rect2(r.position.x + col * 2, r.position.y + 8, col, 44), "MULT", "×%d" % MULT,
            Temas.DESTAQUE, 26)
    _contadores(Rect2(r.position.x + 12, r.end.y - 32, r.size.x - 24, 24))

## Coluna direita: a REFERÊNCIA. Consulta ocasional, nunca no caminho do dedo.
func _painel_referencia(r: Rect2) -> void:
    Pintura.caixa(self, r, 12, 0.72)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    draw_string(ff, Vector2(r.position.x + 20, r.position.y + 30), "MÃOS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)

    var passo := minf(44.0, (r.size.y - 72.0) / MAOS.size())
    var y := r.position.y + 52.0
    for m in MAOS:
        var feita: bool = m[3]
        var cor: Color = Temas.DESTAQUE if feita else Temas.TEXTO
        if feita:
            Pintura.pilula(self, Rect2(r.position.x + 12, y - 15, r.size.x - 24, 28),
                    Color(Temas.DESTAQUE, 0.16), 6)
        draw_string(f, Vector2(r.position.x + 20, y + 5), str(m[0]),
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, cor)
        # Números tabulares alinhados à direita: o olho compara sem esforço.
        draw_string(ff, Vector2(r.end.x - 112, y + 5), str(m[1]),
                    HORIZONTAL_ALIGNMENT_RIGHT, 60, Temas.T_CORPO, Temas.TEXTO_SUAVE)
        draw_string(ff, Vector2(r.end.x - 62, y + 5), str(m[2]),
                    HORIZONTAL_ALIGNMENT_RIGHT, 44, Temas.T_CORPO, Temas.ACENTO)
        y += passo



## O tabuleiro afundado na mesa. Numa mesa de carteado de verdade o feltro é
## rebaixado na madeira, e é esse degrau que faz o objeto parecer caro. Aqui
## são três desenhos: um retângulo mais escuro, uma sombra interna no topo e um
## filete dourado na borda.
func _rodape_mesa(r: Rect2) -> void:
    Pintura.caixa(self, r, 10, 0.72)
    var ff := Temas.fonte_do_tema(true)
    draw_string(ff, Vector2(r.position.x + 18, r.position.y + 22), "MESA",
                HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    draw_string(Temas.fonte_do_tema(), Vector2(r.position.x + 18, r.position.y + 44),
                "Rachada · as quinas nascem lacradas", HORIZONTAL_ALIGNMENT_LEFT, -1,
                Temas.T_CORPO, Temas.ALERTA)

func _grade(r: Rect2, celula: float, vao: float) -> void:
    var alt := celula * Carta.RAZAO
    for linha in 5:
        for coluna in 5:
            var c := Rect2(r.position + Vector2(coluna * (celula + vao), linha * (alt + vao)),
                           Vector2(celula, alt))
            var conteudo: Variant = GRADE[linha][coluna]
            var viva := linha == CHEIA_FILEIRA or coluna == CHEIA_COLUNA
            if typeof(conteudo) != TYPE_ARRAY:
                Pintura.casa_vazia(self, c, viva)
                continue
            Carta.desenhar(self, c, int(conteudo[0]), int(conteudo[1]),
                           Carta.MADURA if viva else Carta.NA_GRADE)

## Os rótulos de linha: a fração e a categoria, colados na linha. É a informação
## que o jogador mais lê — painel distante obrigaria o olho a viajar.
func _rotulos(g: Rect2, celula: float, vao: float, larg: float, alt_col: float) -> void:
    var f := Temas.fonte_do_tema(true)
    var alt := celula * Carta.RAZAO
    for i in 5:
        var y := g.position.y + i * (alt + vao)
        _rotulo(f, Rect2(g.end.x + 8, y + alt * 0.5 - 15, larg, 30),
                ROTULO_FILEIRA[i], i == CHEIA_FILEIRA, false)
    for i in 5:
        var x := g.position.x + i * (celula + vao)
        _rotulo(f, Rect2(x, g.end.y + 8, celula, alt_col), ROTULO_COLUNA[i],
                i == CHEIA_COLUNA, true)

## Em retrato não há largura para texto ao lado da grade. O estado da fileira
## vira uma barra de progresso de 8 px na borda externa: a mesma informação em
## FORMA, que é o que sobrevive sem cor e sem espaço.
func _barras_de_fileira(g: Rect2, celula: float, vao: float, larg: float) -> void:
    var alt := celula * Carta.RAZAO
    for i in 5:
        var y := g.position.y + i * (alt + vao)
        var trilho := Rect2(g.end.x + 2, y + alt * 0.12, larg - 2, alt * 0.76)
        Pintura.pilula(self, trilho, Color(Temas.BORDA, 0.45), int(larg * 0.5))
        var texto: String = ROTULO_FILEIRA[i]
        var cheios := 5.0 if i == CHEIA_FILEIRA else float(texto.split("/")[0].to_int())
        var fracao := cheios / 5.0
        var cheio := Rect2(trilho.position.x, trilho.end.y - trilho.size.y * fracao,
                           trilho.size.x, trilho.size.y * fracao)
        Pintura.pilula(self, cheio, Temas.DESTAQUE if i == CHEIA_FILEIRA else Temas.TEXTO_SUAVE,
                int(larg * 0.5))

func _rotulos_coluna(g: Rect2, celula: float, vao: float, alt_rot: float) -> void:
    var f := Temas.fonte_do_tema(true)
    for i in 5:
        var x := g.position.x + i * (celula + vao)
        _rotulo(f, Rect2(x, g.end.y + 6, celula, alt_rot), ROTULO_COLUNA[i],
                i == CHEIA_COLUNA, true)

func _rotulo(f: FontFile, r: Rect2, texto: String, cheia: bool, compacto: bool) -> void:
    var cor := Temas.TEXTO_SUAVE
    if cheia:
        # Preenchimento sólido com texto invertido. O chip translúcido de antes
        # sumia em escala de cinza: virava cinza sobre cinza. Sólido, o contraste
        # é de valor tonal e sobrevive sem cor.
        Pintura.pilula(self, r, Temas.DESTAQUE, 6)
        cor = Temas.CARTA if Temas.e_claro() else Temas.FUNDO
    var t := texto
    if compacto and cheia:
        t = "CHEIA"
    Pintura.centrado(self, f, r, t, Temas.T_ROTULO, cor)

func _mao(r: Rect2, largura: float, vao: float) -> void:
    var n := MAO.size()
    var alt := largura * Carta.RAZAO
    var total := largura * n + vao * (n - 1)
    var x := r.position.x + (r.size.x - total) * 0.5
    for i in n:
        var c := Rect2(x + i * (largura + vao), r.position.y, largura, alt)
        var estado := Carta.NORMAL
        if i == CARTA_AVESSO:
            estado = Carta.AVESSO
        elif i == 0:
            # Uma carta erguida: é assim que o hover aparece, e sem isso a
            # maquete não mostra como o realce se comporta no tema.
            c.position.y -= alt * 0.05
            estado = Carta.HOVER
        Carta.desenhar(self, c, int(MAO[i][0]), int(MAO[i][1]), estado)
