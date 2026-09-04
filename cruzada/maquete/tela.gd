extends Control
class_name TelaMaquete
## A tela de partida do CRUZADA, montada com um estado fixo e realista.
##
## Não é o jogo: é a maquete que existe para o tema ser escolhido olhando, e
## não lendo adjetivo. O estado desenhado é o momento canônico do design — uma
## carta fechando fileira e coluna ao mesmo tempo, que é a CRUZADA.

const VAZIO := -1

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

const PONTOS := 4144
const META := 2962
const MULT := 6
const JOGADAS := 4
const DESCARTES := 1

var _poeira: Array[Vector3] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Semente fixa: a maquete precisa sair idêntica em toda captura, senão duas
    # rodadas do mesmo tema não são comparáveis.
    var rng := RandomNumberGenerator.new()
    rng.seed = 20260904
    for i in 40:
        _poeira.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(1.2, 3.0)))
    _acompanhar()
    get_viewport().size_changed.connect(_acompanhar)

func _acompanhar() -> void:
    position = Vector2.ZERO
    size = get_viewport_rect().size
    queue_redraw()

func _draw() -> void:
    var retrato := size.y > size.x
    _fundo()
    if retrato:
        _desenhar_retrato()
    else:
        _desenhar_paisagem()

# ─────────────────────────────── o fundo ───────────────────────────────

func _fundo() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Temas.FUNDO)

    # Brilho central em muitas camadas fracas: com poucas, as bordas dos
    # círculos aparecem como anéis em vez de um brilho contínuo.
    if Temas.BRILHO > 0.0:
        var centro := size * Vector2(0.5, 0.42)
        var raio := maxf(size.x, size.y) * 0.62
        for i in 18:
            var t := float(i) / 17.0
            var cor := Temas.ACENTO.lerp(Temas.DESTAQUE, t * 0.35)
            draw_circle(centro, raio * (1.0 - t * 0.85), Color(cor, 0.008 * Temas.BRILHO))

    # Poeira. Nos temas claros ela é escura sobre o papel, e o tema já declara
    # a opacidade certa — o código não sabe se o fundo é claro ou escuro.
    var cor_poeira := Temas.TEXTO
    for p in _poeira:
        draw_circle(Vector2(p.x * size.x, p.y * size.y), p.z * 0.7,
                    Color(cor_poeira, Temas.PARTICULA))

    # Vinheta: só faz sentido onde há o que escurecer.
    if not Temas.e_claro():
        var faixa := size.y * 0.20
        for i in 12:
            var t := float(i) / 11.0
            var a := 0.05 * (1.0 - t)
            var e := faixa * (1.0 - t) / 12.0 + 2.0
            draw_rect(Rect2(0, t * faixa / 2.0, size.x, e), Color(0, 0, 0, a))
            draw_rect(Rect2(0, size.y - t * faixa / 2.0 - e, size.x, e), Color(0, 0, 0, a))

# ────────────────────────────── paisagem ──────────────────────────────

func _desenhar_paisagem() -> void:
    _barra(Rect2(24, 16, size.x - 48, 46))
    _painel_status(Rect2(24, 84, 250, 448), false)
    var grade := Rect2(302, 80, 452, 452)
    _grade(grade)
    _rotulos(grade, 132.0)
    _painel_maos(Rect2(922, 84, 334, 448))
    _mao(Rect2(302, 578, 452, 128))

# ─────────────────────────────── retrato ───────────────────────────────

func _desenhar_retrato() -> void:
    var m := 14.0
    _barra(Rect2(m, 12, size.x - m * 2, 40))
    _painel_status(Rect2(m, 60, size.x - m * 2, 92), true)
    var lado := size.x - m * 2 - 44.0
    var grade := Rect2(m, 172, lado, lado)
    _grade(grade)
    _rotulos(grade, 42.0)
    # Em retrato a tabela de mãos não cabe na lateral, e sem ela sobra um terço
    # de tela vazia. Vai para o vão entre a grade e a mão, em duas colunas.
    _maos_compacto(Rect2(m, grade.end.y + 44, size.x - m * 2, size.y - grade.end.y - 210))
    _mao(Rect2(m, size.y - 152, size.x - m * 2, 122))

# ────────────────────────────── as peças ──────────────────────────────

func _barra(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var tam := 20 if r.size.y > 42 else 16
    draw_string(f, Vector2(r.position.x, r.position.y + r.size.y * 0.68),
                "CRUZADA", HORIZONTAL_ALIGNMENT_LEFT, -1, tam + 4, Temas.TEXTO)
    var sub := "rodada 4 · mesa 2 de 3"
    var largura_titulo := f.get_string_size("CRUZADA", HORIZONTAL_ALIGNMENT_LEFT, -1, tam + 4).x
    if r.size.x > 420:
        draw_string(Temas.fonte_do_tema(), Vector2(r.position.x + largura_titulo + 16,
                    r.position.y + r.size.y * 0.66), sub,
                    HORIZONTAL_ALIGNMENT_LEFT, -1, tam - 4, Temas.TEXTO_SUAVE)

    # O botão REGRAS: âncora fixa no alto à direita, alvo grande o bastante
    # para o dedo em qualquer tamanho de tela.
    var b := Rect2(r.end.x - 108, r.position.y, 108, maxf(r.size.y, 44))
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Temas.PAINEL
    caixa.border_color = Temas.BORDA
    caixa.set_border_width_all(2)
    caixa.set_corner_radius_all(8)
    draw_style_box(caixa, b)
    _centrado(Temas.fonte_do_tema(true), b, "REGRAS", 15, Temas.TEXTO)

func _painel_status(r: Rect2, deitado: bool) -> void:
    _caixa(r)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    if deitado:
        var col := r.size.x / 3.0
        _numero(Rect2(r.position.x, r.position.y + 8, col, 44), "PONTOS",
                _milhar(PONTOS), Temas.TEXTO, 26)
        _numero(Rect2(r.position.x + col, r.position.y + 8, col, 44), "META",
                _milhar(META), Temas.TEXTO_SUAVE, 26)
        _numero(Rect2(r.position.x + col * 2, r.position.y + 8, col, 44), "MULT",
                "×%d" % MULT, Temas.DESTAQUE, 26)
        _pilulas(Rect2(r.position.x + 10, r.end.y - 30, r.size.x - 20, 22))
        return

    var y := r.position.y + 26.0
    draw_string(ff, Vector2(r.position.x + 18, y), "PONTOS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Temas.TEXTO_SUAVE)
    y += 52
    # O número da pontuação é o maior da tela: é ele que precisa ser lido de
    # relance enquanto sobe.
    draw_string(ff, Vector2(r.position.x + 18, y), _milhar(PONTOS),
                HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Temas.TEXTO)
    y += 30
    draw_string(f, Vector2(r.position.x + 18, y), "de " + _milhar(META),
                HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Temas.TEXTO_SUAVE)

    # Barra da meta, já estourada: o verde diz "bateu" sem uma palavra.
    y += 22
    var trilho := Rect2(r.position.x + 18, y, r.size.x - 36, 10)
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Color(Temas.BORDA, 0.8)
    caixa.set_corner_radius_all(5)
    draw_style_box(caixa, trilho)
    caixa.bg_color = Temas.SUCESSO
    draw_style_box(caixa, trilho)

    y += 56
    draw_string(ff, Vector2(r.position.x + 18, y), "MULTIPLICADOR",
                HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Temas.TEXTO_SUAVE)
    y += 58
    draw_string(ff, Vector2(r.position.x + 18, y), "×%d" % MULT,
                HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Temas.DESTAQUE)
    draw_string(f, Vector2(r.position.x + 92, y - 6), "sobe e nunca desce",
                HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Temas.TEXTO_SUAVE)

    _pilulas(Rect2(r.position.x + 18, r.end.y - 46, r.size.x - 36, 30))

func _pilulas(r: Rect2) -> void:
    var f := Temas.fonte_do_tema(true)
    var larg := (r.size.x - 10.0) / 2.0
    var itens := [["JOGADAS", str(JOGADAS)], ["DESCARTES", str(DESCARTES)]]
    for i in itens.size():
        var b := Rect2(r.position.x + i * (larg + 10), r.position.y, larg, r.size.y)
        var caixa := StyleBoxFlat.new()
        caixa.bg_color = Color(Temas.BORDA, 0.35)
        caixa.set_corner_radius_all(int(r.size.y * 0.4))
        draw_style_box(caixa, b)
        var tam := 13 if r.size.y < 26 else 15
        _centrado(f, b, "%s  %s" % [itens[i][1], itens[i][0]], tam, Temas.TEXTO)

func _grade(r: Rect2) -> void:
    var gap := r.size.x * 0.018
    var lado := (r.size.x - gap * 4.0) / 5.0
    for linha in 5:
        for coluna in 5:
            var c := Rect2(r.position + Vector2(coluna * (lado + gap), linha * (lado + gap)),
                           Vector2(lado, lado))
            var conteudo: Variant = GRADE[linha][coluna]
            if typeof(conteudo) != TYPE_ARRAY:
                _casa_vazia(c, linha == 2 or coluna == 2)
                continue
            var estado := Carta.NA_GRADE
            if linha == 2 or coluna == 2:
                estado = Carta.MADURA
            Carta.desenhar(self, c, int(conteudo[0]), int(conteudo[1]), estado)

func _casa_vazia(c: Rect2, viva: bool) -> void:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Color(Temas.PAINEL, 0.55 if viva else 0.38)
    caixa.border_color = Color(Temas.DESTAQUE if viva else Temas.BORDA, 0.55 if viva else 0.7)
    caixa.set_border_width_all(2)
    caixa.set_corner_radius_all(int(maxf(4.0, c.size.x * 0.09)))
    draw_style_box(caixa, c)

## Os rótulos de linha: a fração e a categoria. É a informação que o jogador
## mais lê, então fica colada na linha e nunca num painel distante.
func _rotulos(g: Rect2, largura: float) -> void:
    var gap := g.size.x * 0.018
    var lado := (g.size.x - gap * 4.0) / 5.0
    var f := Temas.fonte_do_tema(true)
    var compacto := largura < 80.0
    for i in 5:
        var y := g.position.y + i * (lado + gap)
        var alvo := Rect2(g.end.x + 8, y, largura, lado)
        _rotulo(f, alvo, ROTULO_FILEIRA[i], i == 2, compacto)
    for i in 5:
        var x := g.position.x + i * (lado + gap)
        var alvo := Rect2(x, g.end.y + 8, lado, 26 if compacto else 30)
        _rotulo(f, alvo, ROTULO_COLUNA[i], i == 2, true)

func _rotulo(f: FontFile, r: Rect2, texto: String, cheia: bool, compacto: bool) -> void:
    var cor := Temas.TEXTO_SUAVE
    if cheia:
        # Preenchimento sólido com texto invertido. O chip translúcido de antes
        # sumia em escala de cinza: virava cinza sobre cinza. Sólido, o
        # contraste é de valor tonal e sobrevive sem cor.
        var caixa := StyleBoxFlat.new()
        caixa.bg_color = Temas.DESTAQUE
        caixa.set_corner_radius_all(6)
        draw_style_box(caixa, r)
        cor = Temas.FUNDO if not Temas.e_claro() else Temas.CARTA
    var t := texto
    if compacto and cheia:
        t = "CHEIA"
    _centrado(f, r, t, 12 if compacto else 15, cor)

func _painel_maos(r: Rect2) -> void:
    _caixa(r)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    draw_string(ff, Vector2(r.position.x + 18, r.position.y + 30), "MÃOS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Temas.TEXTO_SUAVE)
    var maos := [
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
    var y := r.position.y + 52.0
    for m in maos:
        var feita: bool = m[3]
        var cor: Color = Temas.DESTAQUE if feita else Temas.TEXTO
        if feita:
            var caixa := StyleBoxFlat.new()
            caixa.bg_color = Color(Temas.DESTAQUE, 0.13)
            caixa.set_corner_radius_all(6)
            draw_style_box(caixa, Rect2(r.position.x + 10, y - 15, r.size.x - 20, 28))
        draw_string(f, Vector2(r.position.x + 18, y + 5), str(m[0]),
                    HORIZONTAL_ALIGNMENT_LEFT, -1, 16, cor)
        # Números tabulares à direita: alinhados, o olho compara sem esforço.
        draw_string(ff, Vector2(r.end.x - 108, y + 5), str(m[1]),
                    HORIZONTAL_ALIGNMENT_RIGHT, 60, 16, Temas.TEXTO_SUAVE)
        draw_string(ff, Vector2(r.end.x - 60, y + 5), str(m[2]),
                    HORIZONTAL_ALIGNMENT_RIGHT, 44, 16, Temas.ACENTO)
        y += 43

## A tabela de mãos em duas colunas, para o retrato.
func _maos_compacto(r: Rect2) -> void:
    if r.size.y < 60.0:
        return
    _caixa(r)
    var f := Temas.fonte_do_tema()
    var ff := Temas.fonte_do_tema(true)
    draw_string(ff, Vector2(r.position.x + 14, r.position.y + 22), "MÃOS",
                HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Temas.TEXTO_SUAVE)
    var maos := [
        ["Seq. de Cor", "×8", true], ["Quadra", "×7", false],
        ["Full House", "×4", true], ["Flush", "×4", false],
        ["Sequência", "×4", false], ["Trinca", "×3", false],
        ["Dois Pares", "×2", false], ["Par", "×2", false],
    ]
    var col := (r.size.x - 28.0) / 2.0
    var y0 := r.position.y + 38.0
    for i in maos.size():
        var linha := i % 4
        var coluna := i / 4
        var b := Rect2(r.position.x + 14 + coluna * col, y0 + linha * 24.0, col - 6, 22)
        var feita: bool = maos[i][2]
        if feita:
            var caixa := StyleBoxFlat.new()
            caixa.bg_color = Color(Temas.DESTAQUE, 0.20)
            caixa.set_corner_radius_all(5)
            draw_style_box(caixa, b)
        var cor: Color = Temas.DESTAQUE if feita else Temas.TEXTO
        draw_string(f, Vector2(b.position.x + 6, b.position.y + 16), str(maos[i][0]),
                    HORIZONTAL_ALIGNMENT_LEFT, -1, 13, cor)
        draw_string(ff, Vector2(b.end.x - 34, b.position.y + 16), str(maos[i][1]),
                    HORIZONTAL_ALIGNMENT_RIGHT, 30, 13, Temas.ACENTO)

func _mao(r: Rect2) -> void:
    var n := MAO.size()
    var gap := r.size.x * 0.022
    var larg := minf((r.size.x - gap * (n - 1)) / n, r.size.y * 0.72)
    var alt := minf(larg * 1.42, r.size.y)
    var total := larg * n + gap * (n - 1)
    var x := r.position.x + (r.size.x - total) * 0.5
    var y := r.position.y + (r.size.y - alt) * 0.5
    for i in n:
        var c := Rect2(x + i * (larg + gap), y, larg, alt)
        var estado := Carta.NORMAL
        if i == CARTA_AVESSO:
            estado = Carta.AVESSO
        elif i == 0:
            # Uma carta erguida: é assim que o hover aparece, e sem isso a
            # maquete não mostra como o realce se comporta no tema.
            c.position.y -= alt * 0.10
            estado = Carta.HOVER
        Carta.desenhar(self, c, int(MAO[i][0]), int(MAO[i][1]), estado)

# ────────────────────────────── utilidades ──────────────────────────────

func _caixa(r: Rect2) -> void:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Color(Temas.PAINEL, 0.72)
    caixa.border_color = Temas.BORDA
    caixa.set_border_width_all(2)
    caixa.set_corner_radius_all(12)
    draw_style_box(caixa, r)

func _numero(r: Rect2, titulo: String, valor: String, cor: Color, tam: int) -> void:
    var f := Temas.fonte_do_tema(true)
    draw_string(f, Vector2(r.position.x, r.position.y + 14), titulo,
                HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Temas.TEXTO_SUAVE)
    draw_string(f, Vector2(r.position.x, r.position.y + 14 + tam),
                valor, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, tam, cor)

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
