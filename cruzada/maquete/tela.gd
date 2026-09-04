extends Control
class_name TelaMaquete
## A tela de partida do CRUZADA, montada com um estado fixo e realista.
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
    # Semente fixa: a maquete precisa sair idêntica em toda captura, senão duas
    # rodadas do mesmo tema não são comparáveis.
    var rng := RandomNumberGenerator.new()
    rng.seed = 20260904
    for i in 90:
        _poeira.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(1.0, 3.0)))
    _acompanhar()
    get_viewport().size_changed.connect(_acompanhar)

func _acompanhar() -> void:
    position = Vector2.ZERO
    size = get_viewport_rect().size
    queue_redraw()

func _draw() -> void:
    _fundo()
    if size.y > size.x:
        _retrato()
    else:
        _paisagem()

# ─────────────────────────────── o fundo ───────────────────────────────
# Cada tema tem o SEU tratamento de fundo, não só a sua cor. Enquanto os oito
# compartilhavam um brilho radial, vários pareciam o mesmo tema repintado — foi
# o que a folha de contato mostrou. Fundo é identidade.

func _fundo() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Temas.FUNDO)
    match Temas.FUNDO_ESTILO:
        "grade": _fundo_grade()
        "tecido": _fundo_tecido()
        "papel": _fundo_papel()
        "vinheta": pass
        _: _fundo_brilho()
    _poeira_flutuante()
    _vinheta()

## Brilho radial suave, em muitas camadas fracas: com poucas, as bordas dos
## círculos aparecem como anéis em vez de um brilho contínuo.
func _fundo_brilho() -> void:
    if Temas.BRILHO <= 0.0:
        return
    var centro := size * Vector2(0.5, 0.42)
    var raio := maxf(size.x, size.y) * 0.62
    for i in 18:
        var t := float(i) / 17.0
        var cor := Temas.ACENTO.lerp(Temas.DESTAQUE, t * 0.35)
        draw_circle(centro, raio * (1.0 - t * 0.85), Color(cor, 0.008 * Temas.BRILHO))

## Grade de linhas acesas: a assinatura do fliperama. Substitui o brilho radial,
## que misturava ciano com amarelo e lavava a tela de verde-piscina.
func _fundo_grade() -> void:
    var passo := 48.0
    var cor := Color(Temas.ACENTO, 0.055)
    var x := passo
    while x < size.x:
        draw_line(Vector2(x, 0), Vector2(x, size.y), cor, 1.0)
        x += passo
    var y := passo
    while y < size.y:
        draw_line(Vector2(0, y), Vector2(size.x, y), Color(Temas.ACENTO, 0.035), 1.0)
        y += passo
    # Duas linhas mais fortes dão o "horizonte" sem custar nada.
    draw_line(Vector2(0, size.y * 0.62), Vector2(size.x, size.y * 0.62),
              Color(Temas.ACENTO, 0.16), 1.0)
    draw_line(Vector2(size.x * 0.5, 0), Vector2(size.x * 0.5, size.y),
              Color(Temas.ACENTO, 0.05), 1.0)

## Trama fina de feltro. Linhas cruzadas quase invisíveis: de perto some, de
## longe dá textura de pano.
func _fundo_tecido() -> void:
    var passo := 4.0
    var cor := Color(Temas.TEXTO, 0.014)
    var y := 0.0
    while y < size.y:
        draw_line(Vector2(0, y), Vector2(size.x, y), cor, 1.0)
        y += passo
    var x := 0.0
    while x < size.x:
        draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0, 0, 0, 0.012), 1.0)
        x += passo

## Grão de papel: manchas largas e fraquíssimas, para o creme não ficar chapado.
func _fundo_papel() -> void:
    for p in _poeira:
        draw_circle(Vector2(p.x * size.x, p.y * size.y), 40.0 + p.z * 30.0,
                    Color(Temas.TEXTO, 0.006))

func _poeira_flutuante() -> void:
    if Temas.PARTICULA <= 0.0:
        return
    for i in mini(_poeira.size(), 40):
        var p := _poeira[i]
        draw_circle(Vector2(p.x * size.x, p.y * size.y), p.z * 0.7,
                    Color(Temas.TEXTO, Temas.PARTICULA))

## Bordas escuras para o olho ir ao centro. Só faz sentido onde há o que
## escurecer — sobre papel ela suja.
func _vinheta() -> void:
    if Temas.e_claro():
        return
    var forca := 0.05
    if Temas.FUNDO_ESTILO == "vinheta" or Temas.FUNDO_ESTILO == "grade":
        forca = 0.085
    var faixa := size.y * 0.22
    for i in 12:
        var t := float(i) / 11.0
        var a := forca * (1.0 - t)
        var e := faixa * (1.0 - t) / 12.0 + 2.0
        draw_rect(Rect2(0, t * faixa / 2.0, size.x, e), Color(0, 0, 0, a))
        draw_rect(Rect2(0, size.y - t * faixa / 2.0 - e, size.x, e), Color(0, 0, 0, a))
        draw_rect(Rect2(t * faixa / 3.0, 0, e, size.y), Color(0, 0, 0, a * 0.8))
        draw_rect(Rect2(size.x - t * faixa / 3.0 - e, 0, e, size.y), Color(0, 0, 0, a * 0.8))

# ─────────────────────── paisagem: três colunas ───────────────────────

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
    _painel_estado(Rect2(MARGEM, y, lateral, alt))
    _centro(Rect2(MARGEM + lateral + VAO, y, centro_larg, alt))
    _painel_referencia(Rect2(MARGEM + lateral + VAO + centro_larg + VAO, y, lateral, alt))

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

    _grade(grade, celula, VAO_CELULA)
    _rotulos(grade, celula, VAO_CELULA, ROT_FILEIRA, ROT_COLUNA)
    _mao(Rect2(r.position.x, r.end.y - alt_mao, r.size.x, alt_mao), carta_mao, VAO_MAO)

# ─────────────────────────────── retrato ───────────────────────────────
# Três colunas não cabem em 360 de largura. A esquerda vira faixa no topo, a
# direita vira tabela no vão entre a grade e a mão, e os rótulos de fileira
# viram pontinhos de progresso na margem estreita.

func _retrato() -> void:
    var m := 12.0
    var util := size.x - m * 2.0
    _barra(Rect2(m, 10, util, 40))

    var y := 58.0
    _faixa_estado(Rect2(m, y, util, 84.0))
    y += 84.0 + 12.0

    const ROT := 22.0
    const VAO_CELULA := 4.0
    var celula := floorf((util - ROT - 6.0 - VAO_CELULA * 4.0) / 5.0)
    var grade_larg := celula * 5.0 + VAO_CELULA * 4.0
    var grade_alt := celula * Carta.RAZAO * 5.0 + VAO_CELULA * 4.0
    var grade := Rect2(m, y, grade_larg, grade_alt)
    _grade(grade, celula, VAO_CELULA)
    _rotulos_retrato(grade, celula, VAO_CELULA, ROT)

    var carta_mao := (util - 10.0 * 4.0) / 5.0
    var alt_mao := carta_mao * Carta.RAZAO
    var mao_y := size.y - alt_mao - m
    _mao(Rect2(m, mao_y, util, alt_mao), carta_mao, 10.0)

    var vao_topo := grade.end.y + 26.0
    _maos_compacto(Rect2(m, vao_topo, util, mao_y - vao_topo - 12.0))

# ─────────────────────────────── as peças ───────────────────────────────

func _barra(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var tam := 24 if r.size.y > 46 else 19
    draw_string(f, Vector2(r.position.x, r.position.y + r.size.y * 0.70),
                "CRUZADA", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Temas.TEXTO)
    var largura := f.get_string_size("CRUZADA", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
    if r.size.x > 420:
        draw_string(Temas.fonte_do_tema(), Vector2(r.position.x + largura + 16,
                    r.position.y + r.size.y * 0.68), "rodada 4 · mesa 2 de 3",
                    HORIZONTAL_ALIGNMENT_LEFT, -1, tam - 8, Temas.TEXTO_SUAVE)

    # REGRAS: âncora fixa no alto à direita, 44 px de altura mínima para o dedo.
    var b := Rect2(r.end.x - 112, r.position.y, 112, maxf(r.size.y, 44.0))
    _caixa(b, 8, 0.9)
    _centrado(Temas.fonte_do_tema(true), b, "REGRAS", 15, Temas.TEXTO)

## Coluna esquerda: o ESTADO. O jogador consulta, não toca.
func _painel_estado(r: Rect2) -> void:
    _caixa(r, 12, 0.72)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var x := r.position.x + 20.0
    var larg := r.size.x - 40.0
    var y := r.position.y + 30.0

    draw_string(ff, Vector2(x, y), "PONTOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
                Temas.TEXTO_SUAVE)
    y += 54
    # O maior número da tela: é ele que precisa ser lido de relance enquanto sobe.
    draw_string(ff, Vector2(x, y), _milhar(PONTOS), HORIZONTAL_ALIGNMENT_LEFT, -1, 50,
                Temas.TEXTO)
    y += 28
    draw_string(f, Vector2(x, y), "de " + _milhar(META), HORIZONTAL_ALIGNMENT_LEFT, -1,
                18, Temas.TEXTO_SUAVE)
    y += 20
    var trilho := Rect2(x, y, larg, 10)
    _pilula(trilho, Color(Temas.BORDA, 0.8))
    _pilula(trilho, Temas.SUCESSO)   # meta estourada: o verde diz "bateu" sem palavra

    y += 60
    draw_string(ff, Vector2(x, y), "MULTIPLICADOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
                Temas.TEXTO_SUAVE)
    y += 56
    draw_string(ff, Vector2(x, y), "×%d" % MULT, HORIZONTAL_ALIGNMENT_LEFT, -1, 50,
                Temas.DESTAQUE)
    draw_string(f, Vector2(x + 86, y - 4), "sobe e", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
                Temas.TEXTO_SUAVE)
    draw_string(f, Vector2(x + 86, y + 14), "nunca desce", HORIZONTAL_ALIGNMENT_LEFT, -1,
                14, Temas.TEXTO_SUAVE)

    _contadores(Rect2(x, r.end.y - 58, larg, 38))

func _contadores(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var larg := (r.size.x - 10.0) / 2.0
    var itens := [[str(JOGADAS), "JOGADAS"], [str(DESCARTES), "DESCARTES"]]
    for i in itens.size():
        var b := Rect2(r.position.x + i * (larg + 10), r.position.y, larg, r.size.y)
        _pilula(b, Color(Temas.BORDA, 0.35))
        _centrado(f, b, "%s  %s" % [itens[i][0], itens[i][1]], 14, Temas.TEXTO)

## Faixa de estado do retrato: os mesmos três números, deitados.
func _faixa_estado(r: Rect2) -> void:
    _caixa(r, 12, 0.72)
    var col := r.size.x / 3.0
    _numero(Rect2(r.position.x, r.position.y + 8, col, 44), "PONTOS", _milhar(PONTOS),
            Temas.TEXTO, 26)
    _numero(Rect2(r.position.x + col, r.position.y + 8, col, 44), "META", _milhar(META),
            Temas.TEXTO_SUAVE, 26)
    _numero(Rect2(r.position.x + col * 2, r.position.y + 8, col, 44), "MULT", "×%d" % MULT,
            Temas.DESTAQUE, 26)
    _contadores(Rect2(r.position.x + 12, r.end.y - 32, r.size.x - 24, 24))

## Coluna direita: a REFERÊNCIA. Consulta ocasional, nunca no caminho do dedo.
func _painel_referencia(r: Rect2) -> void:
    _caixa(r, 12, 0.72)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    draw_string(ff, Vector2(r.position.x + 20, r.position.y + 30), "MÃOS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Temas.TEXTO_SUAVE)

    var passo := minf(44.0, (r.size.y - 130.0) / MAOS.size())
    var y := r.position.y + 52.0
    for m in MAOS:
        var feita: bool = m[3]
        var cor: Color = Temas.DESTAQUE if feita else Temas.TEXTO
        if feita:
            _pilula(Rect2(r.position.x + 12, y - 15, r.size.x - 24, 28),
                    Color(Temas.DESTAQUE, 0.16), 6)
        draw_string(f, Vector2(r.position.x + 20, y + 5), str(m[0]),
                    HORIZONTAL_ALIGNMENT_LEFT, -1, 16, cor)
        # Números tabulares alinhados à direita: o olho compara sem esforço.
        draw_string(ff, Vector2(r.end.x - 112, y + 5), str(m[1]),
                    HORIZONTAL_ALIGNMENT_RIGHT, 60, 16, Temas.TEXTO_SUAVE)
        draw_string(ff, Vector2(r.end.x - 62, y + 5), str(m[2]),
                    HORIZONTAL_ALIGNMENT_RIGHT, 44, 16, Temas.ACENTO)
        y += passo

    var rodape := Rect2(r.position.x + 16, r.end.y - 62, r.size.x - 32, 46)
    _caixa(rodape, 8, 0.5)
    draw_string(ff, Vector2(rodape.position.x + 12, rodape.position.y + 19), "MESA",
                HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Temas.TEXTO_SUAVE)
    draw_string(f, Vector2(rodape.position.x + 12, rodape.position.y + 37), "Rachada",
                HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Temas.ALERTA)

## A tabela de mãos em duas colunas, para o retrato.
func _maos_compacto(r: Rect2) -> void:
    if r.size.y < 56.0:
        return
    _caixa(r, 12, 0.72)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    var col := (r.size.x - 24.0) / 2.0
    var linhas := 4
    var passo := minf(24.0, (r.size.y - 34.0) / linhas)
    var y0 := r.position.y + 30.0
    for i in mini(8, MAOS.size()):
        var b := Rect2(r.position.x + 12 + (i / linhas) * col, y0 + (i % linhas) * passo,
                       col - 6, passo - 2)
        var feita: bool = MAOS[i][3]
        if feita:
            _pilula(b, Color(Temas.DESTAQUE, 0.20), 5)
        var cor: Color = Temas.DESTAQUE if feita else Temas.TEXTO
        draw_string(f, Vector2(b.position.x + 6, b.position.y + b.size.y * 0.75),
                    str(MAOS[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cor)
        draw_string(ff, Vector2(b.end.x - 32, b.position.y + b.size.y * 0.75),
                    str(MAOS[i][2]), HORIZONTAL_ALIGNMENT_RIGHT, 28, 12, Temas.ACENTO)

func _grade(r: Rect2, celula: float, vao: float) -> void:
    var alt := celula * Carta.RAZAO
    for linha in 5:
        for coluna in 5:
            var c := Rect2(r.position + Vector2(coluna * (celula + vao), linha * (alt + vao)),
                           Vector2(celula, alt))
            var conteudo: Variant = GRADE[linha][coluna]
            var viva := linha == CHEIA_FILEIRA or coluna == CHEIA_COLUNA
            if typeof(conteudo) != TYPE_ARRAY:
                _casa_vazia(c, viva)
                continue
            Carta.desenhar(self, c, int(conteudo[0]), int(conteudo[1]),
                           Carta.MADURA if viva else Carta.NA_GRADE)

func _casa_vazia(c: Rect2, viva: bool) -> void:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Color(Temas.PAINEL, 0.55 if viva else 0.38)
    caixa.border_color = Color(Temas.DESTAQUE if viva else Temas.BORDA,
                               0.55 if viva else 0.7)
    caixa.set_border_width_all(2)
    caixa.set_corner_radius_all(int(maxf(4.0, c.size.x * 0.09)))
    draw_style_box(caixa, c)

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

## Em retrato não há margem para texto ao lado da grade: a fileira vira cinco
## pontinhos de progresso, e só a cheia ganha um chip.
func _rotulos_retrato(g: Rect2, celula: float, vao: float, larg: float) -> void:
    var f := Temas.fonte_do_tema(true)
    var alt := celula * Carta.RAZAO
    for i in 5:
        var y := g.position.y + i * (alt + vao) + alt * 0.5
        var cheios := int(ROTULO_FILEIRA[i].split("/")[0]) if "/" in ROTULO_FILEIRA[i] else 5
        for p in 5:
            var cx := g.end.x + 8.0 + (p % 3) * 7.0
            var cy := y - 7.0 + (p / 3) * 8.0
            var cheio := p < cheios
            draw_circle(Vector2(cx, cy), 2.5,
                        Temas.DESTAQUE if (cheio and cheios == 5) else
                        (Temas.TEXTO_SUAVE if cheio else Color(Temas.BORDA, 0.7)))
    for i in 5:
        var x := g.position.x + i * (celula + vao)
        _rotulo(f, Rect2(x, g.end.y + 6, celula, 20), ROTULO_COLUNA[i],
                i == CHEIA_COLUNA, true)

func _rotulo(f: FontFile, r: Rect2, texto: String, cheia: bool, compacto: bool) -> void:
    var cor := Temas.TEXTO_SUAVE
    if cheia:
        # Preenchimento sólido com texto invertido. O chip translúcido de antes
        # sumia em escala de cinza: virava cinza sobre cinza. Sólido, o contraste
        # é de valor tonal e sobrevive sem cor.
        _pilula(r, Temas.DESTAQUE, 6)
        cor = Temas.CARTA if Temas.e_claro() else Temas.FUNDO
    var t := texto
    if compacto and cheia:
        t = "CHEIA"
    _centrado(f, r, t, 11 if compacto else 14, cor)

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

# ────────────────────────────── utilidades ──────────────────────────────

func _caixa(r: Rect2, raio := 12, alfa := 0.72) -> void:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Color(Temas.PAINEL, alfa)
    caixa.border_color = Temas.BORDA
    caixa.set_border_width_all(2)
    caixa.set_corner_radius_all(raio)
    draw_style_box(caixa, r)

func _pilula(r: Rect2, cor: Color, raio := -1) -> void:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = cor
    caixa.set_corner_radius_all(int(r.size.y * 0.5) if raio < 0 else raio)
    draw_style_box(caixa, r)

func _numero(r: Rect2, titulo: String, valor: String, cor: Color, tam: int) -> void:
    var f := Temas.fonte_do_tema(true)
    draw_string(f, Vector2(r.position.x, r.position.y + 14), titulo,
                HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Temas.TEXTO_SUAVE)
    draw_string(f, Vector2(r.position.x, r.position.y + 14 + tam), valor,
                HORIZONTAL_ALIGNMENT_CENTER, r.size.x, tam, cor)

func _centrado(f: FontFile, r: Rect2, texto: String, tam: int, cor: Color) -> void:
    var med := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
    draw_string(f, Vector2(r.position.x + (r.size.x - med.x) * 0.5,
                r.position.y + (r.size.y + med.y * 0.62) * 0.5),
                texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)

## Milhar com ponto, como se escreve em português.
func _milhar(n: int) -> String:
    var s := str(n)
    var saida := ""
    var conta := 0
    for i in range(s.length() - 1, -1, -1):
        saida = s[i] + saida
        conta += 1
        if conta % 3 == 0 and i > 0:
            saida = "." + saida
    return saida
