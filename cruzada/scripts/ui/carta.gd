extends RefCounted
class_name Carta
## Desenha uma carta de baralho inteiramente por código, em qualquer tamanho.
##
## É uma biblioteca de desenho, não um nó: a grade e a mão chamam
## `Carta.desenhar(alvo, retangulo, valor, naipe, estado)` e o mesmo código
## serve os dois. Nada aqui carrega imagem — a carta é geometria.
##
## `valor`: 1 = Ás, 2..10, 11 = J, 12 = Q, 13 = K.
## `naipe`: 0 copas, 1 ouros, 2 paus, 3 espadas.

enum { NORMAL, HOVER, NA_GRADE, MADURA, AVESSO, APAGADA }

## Carta de baralho francês é 63×88 mm — 5:7, altura = largura × 1,4. Vale para
## a mão E para a casa da grade: casa quadrada faz a grade parar de ler como
## baralho, que foi o defeito da primeira maquete. Toda medida de carta no jogo
## sai daqui, e ninguém escreve outro número.
const RAZAO := 1.4

## O retângulo da carta a partir da largura, ancorado no canto superior esquerdo.
static func retangulo(canto: Vector2, largura: float) -> Rect2:
    return Rect2(canto, Vector2(largura, largura * RAZAO))

## A maior carta 5:7 que cabe numa caixa, centralizada nela.
static func caber_em(caixa: Rect2) -> Rect2:
    var largura := minf(caixa.size.x, caixa.size.y / RAZAO)
    var tam := Vector2(largura, largura * RAZAO)
    return Rect2(caixa.position + (caixa.size - tam) * 0.5, tam)

const NOMES: PackedStringArray = ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

## Posições dos pips em coordenadas normalizadas dentro da área central.
## x: 0 coluna esquerda, 0.5 centro, 1 coluna direita. y: 0 topo, 1 base.
## É o arranjo clássico do baralho francês — quem cresceu vendo carta reconhece
## o desenho de 7 e de 10 sem contar os símbolos.
const PIPS := {
    1:  [[0.5, 0.5]],
    2:  [[0.5, 0.0], [0.5, 1.0]],
    3:  [[0.5, 0.0], [0.5, 0.5], [0.5, 1.0]],
    4:  [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [1.0, 1.0]],
    5:  [[0.0, 0.0], [1.0, 0.0], [0.5, 0.5], [0.0, 1.0], [1.0, 1.0]],
    6:  [[0.0, 0.0], [1.0, 0.0], [0.0, 0.5], [1.0, 0.5], [0.0, 1.0], [1.0, 1.0]],
    7:  [[0.0, 0.0], [1.0, 0.0], [0.5, 0.25], [0.0, 0.5], [1.0, 0.5], [0.0, 1.0], [1.0, 1.0]],
    8:  [[0.0, 0.0], [1.0, 0.0], [0.5, 0.25], [0.0, 0.5], [1.0, 0.5], [0.5, 0.75], [0.0, 1.0], [1.0, 1.0]],
    9:  [[0.0, 0.0], [1.0, 0.0], [0.0, 0.333], [1.0, 0.333], [0.5, 0.5],
         [0.0, 0.667], [1.0, 0.667], [0.0, 1.0], [1.0, 1.0]],
    10: [[0.0, 0.0], [1.0, 0.0], [0.5, 0.167], [0.0, 0.333], [1.0, 0.333],
         [0.0, 0.667], [1.0, 0.667], [0.5, 0.833], [0.0, 1.0], [1.0, 1.0]],
}

# ─────────────────────────────── a carta ───────────────────────────────

static func desenhar(alvo: CanvasItem, r: Rect2, valor: int, naipe: int,
                     estado := NORMAL) -> void:
    var raio := maxf(4.0, r.size.x * 0.09)
    _corpo(alvo, r, raio, estado)
    if estado == APAGADA:
        return
    var cor := Temas.cor_do_naipe(naipe)
    if estado == AVESSO:
        _avesso(alvo, r, valor, naipe)
        return
    _indice(alvo, r, valor, naipe, cor)
    # O miolo começa abaixo do índice e recuado dele. Sem essa folga o pip da
    # coluna esquerda encosta no número do canto e a carta fica ilegível — que
    # é exatamente o erro que a primeira captura mostrou.
    var miolo := Rect2(r.position + r.size * Vector2(0.26, 0.27),
                       r.size * Vector2(0.48, 0.58))
    if valor >= 11:
        _figura(alvo, miolo, valor, naipe, cor)
    else:
        _pips(alvo, miolo, valor, naipe, cor)

## Fundo, borda e sombra. A profundidade vem daqui — por camada e sombra
## projetada, nunca por perspectiva: a carta permanece plana e de frente,
## que é o que a mantém legível numa grade 5×5.
static func _corpo(alvo: CanvasItem, r: Rect2, raio: float, estado: int) -> void:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Temas.CARTA
    caixa.border_color = Temas.CARTA_BORDA
    caixa.set_border_width_all(maxf(1.0, r.size.x * 0.018))
    caixa.set_corner_radius_all(int(raio))

    match estado:
        APAGADA:
            caixa.bg_color = Color(Temas.CARTA, 0.14)
            caixa.border_color = Color(Temas.CARTA_BORDA, 0.25)
        HOVER:
            caixa.border_color = Temas.ACENTO
            caixa.set_border_width_all(maxf(2.0, r.size.x * 0.032))
        MADURA:
            # A linha cheia esperando a colheita é o estado mais importante da
            # tela: precisa gritar sem depender de cor, então engrossa a borda
            # além de trocá-la.
            caixa.border_color = Temas.DESTAQUE
            caixa.set_border_width_all(maxf(3.0, r.size.x * 0.05))
        AVESSO:
            caixa.border_color = Temas.ACENTO
            caixa.set_border_width_all(maxf(2.0, r.size.x * 0.03))

    if Temas.SOMBRA > 0.0:
        caixa.shadow_color = Color(0, 0, 0, Temas.SOMBRA)
        caixa.shadow_size = int(maxf(2.0, r.size.x * 0.06))
        caixa.shadow_offset = Vector2(0, maxf(1.0, r.size.x * 0.03))

    alvo.draw_style_box(caixa, r)

    if estado == MADURA:
        # A borda dourada sozinha some em escala de cinza — a captura provou.
        # A tarja sólida no pé da carta é a mesma informação em FORMA: um bloco
        # de valor tonal distinto, que sobrevive sem matiz nenhuma.
        var tarja := Rect2(r.position.x + r.size.x * 0.14,
                           r.end.y - r.size.y * 0.115,
                           r.size.x * 0.72, r.size.y * 0.065)
        var barra := StyleBoxFlat.new()
        barra.bg_color = Temas.DESTAQUE
        barra.set_corner_radius_all(int(maxf(2.0, tarja.size.y * 0.5)))
        alvo.draw_style_box(barra, tarja)

        # O halo só existe onde o fundo é escuro. Sobre creme ele vira borrão,
        # e o tema declara isso em GLOW = 0.
        if Temas.GLOW > 0.0:
            for i in 4:
                var t := float(i) / 3.0
                var fora := r.grow(r.size.x * (0.03 + t * 0.09))
                alvo.draw_rect(fora, Color(Temas.DESTAQUE, 0.10 * Temas.GLOW * (1.0 - t)),
                               false, maxf(1.0, r.size.x * 0.02))

## O índice do canto: valor e naipe pequenos, no alto à esquerda. Fica visível
## mesmo com as cartas sobrepostas em leque — por isso nunca no canto direito.
static func _indice(alvo: CanvasItem, r: Rect2, valor: int, naipe: int, cor: Color) -> void:
    var tam := maxf(8.0, r.size.x * 0.20)
    var fonte := Temas.fonte(true)
    var texto := NOMES[valor]
    var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, int(tam)).x
    var x := r.position.x + r.size.x * 0.09
    var y := r.position.y + r.size.y * 0.05 + tam
    alvo.draw_string(fonte, Vector2(x, y), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, int(tam), cor)
    # O naipe repetido logo abaixo do número é a redundância que serve o
    # daltônico: forma e posição fixas, independentes da cor.
    var s := r.size.x * 0.125
    _naipe(alvo, Vector2(x + largura * 0.5, y + s * 0.95), s, naipe, cor)

## Os pips no miolo. Os da metade de baixo saem invertidos, como no baralho de
## verdade — é o detalhe que faz a carta desenhada parecer carta.
static func _pips(alvo: CanvasItem, m: Rect2, valor: int, naipe: int, cor: Color) -> void:
    var lista: Array = PIPS.get(valor, [])
    var s := m.size.x * (0.40 if valor <= 3 else 0.27)
    if valor == 1:
        s = m.size.x * 0.58
    for p in lista:
        var px: float = m.position.x + m.size.x * (0.5 + (float(p[0]) - 0.5) * 0.82)
        var py: float = m.position.y + m.size.y * (0.06 + float(p[1]) * 0.88)
        _naipe(alvo, Vector2(px, py), s, naipe, cor, float(p[1]) > 0.55)

## J, Q e K resolvidos por monograma geométrico em vez de ilustração: uma
## moldura, a letra grande e dois naipes. Sem artista, e legível a 24 px.
static func _figura(alvo: CanvasItem, m: Rect2, valor: int, naipe: int, cor: Color) -> void:
    var moldura := m.grow(-m.size.x * 0.04)
    alvo.draw_rect(moldura, Color(cor, 0.10))
    alvo.draw_rect(moldura, Color(cor, 0.55), false, maxf(1.0, m.size.x * 0.035))

    var tam := int(maxf(12.0, m.size.y * 0.52))
    var fonte := Temas.fonte(true)
    var texto := NOMES[valor]
    var med := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
    alvo.draw_string(fonte, m.get_center() + Vector2(-med.x * 0.5, med.y * 0.34),
                     texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
    var s := m.size.x * 0.20
    _naipe(alvo, moldura.position + Vector2(s * 0.75, s * 0.75), s, naipe, cor)
    _naipe(alvo, moldura.end - Vector2(s * 0.75, s * 0.75), s, naipe, cor, true)

## O Avesso: a carta de duas caras. A diagonal é a leitura — metade de cima
## vale na fileira, metade de baixo vale na coluna. Duas cartas num objeto só,
## e o jogador entende olhando.
static func _avesso(alvo: CanvasItem, r: Rect2, valor: int, naipe: int) -> void:
    ## Sem a segunda cara declarada, inventa uma. Só a maquete cai aqui — no
    ## jogo o Avesso tem duas caras de verdade e entra por `desenhar_avesso`.
    _avesso_faces(alvo, r, valor, naipe, 11 if valor <= 10 else 7, (naipe + 2) % 4)

## O AVESSO com as duas caras que a colheita prensou. A de cima vale na fileira,
## a de baixo vale na coluna e nas diagonais — a diagonal do desenho é a mesma
## divisão que a regra faz, e é por isso que ela pode ser lida sem legenda.
static func desenhar_avesso(alvo: CanvasItem, r: Rect2, valor_a: int, naipe_a: int,
                            valor_b: int, naipe_b: int, estado := AVESSO) -> void:
    _corpo(alvo, r, maxf(4.0, r.size.x * 0.09), estado)
    _avesso_faces(alvo, r, valor_a, naipe_a, valor_b, naipe_b)

static func _avesso_faces(alvo: CanvasItem, r: Rect2, valor: int, naipe: int,
                          outro_valor: int, outro_naipe: int) -> void:
    var cor_a := Temas.cor_do_naipe(naipe)
    var cor_b := Temas.cor_do_naipe(outro_naipe)

    # As duas metades ganham fundo próprio: é a diagonal que diz "são duas
    # cartas num objeto só", e ela precisa ser vista antes de qualquer símbolo.
    var alto := PackedVector2Array([
        r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y)])
    var baixo := PackedVector2Array([
        r.end, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y)])
    alvo.draw_colored_polygon(alto, Color(cor_a, 0.16))
    alvo.draw_colored_polygon(baixo, Color(cor_b, 0.16))
    alvo.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y),
                   Color(Temas.CARTA_TEXTO, 0.45), maxf(1.5, r.size.x * 0.022))

    # Cada face no centro de gravidade do seu triângulo: valor à esquerda,
    # naipe à direita, na mesma ordem de leitura do índice do canto.
    var s := r.size.x * 0.26
    var tam := r.size.x * 0.30
    _texto_pequeno(alvo, r.position + r.size * Vector2(0.26, 0.30), NOMES[valor], cor_a, tam)
    _naipe(alvo, r.position + r.size * Vector2(0.48, 0.30), s, naipe, cor_a)
    _texto_pequeno(alvo, r.position + r.size * Vector2(0.52, 0.72), NOMES[outro_valor], cor_b, tam)
    _naipe(alvo, r.position + r.size * Vector2(0.74, 0.72), s, outro_naipe, cor_b)

static func _texto_pequeno(alvo: CanvasItem, centro: Vector2, texto: String,
                           cor: Color, tam: float) -> void:
    var fonte := Temas.fonte(true)
    var med := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, int(tam))
    alvo.draw_string(fonte, centro - Vector2(med.x * 0.5, -med.y * 0.34),
                     texto, HORIZONTAL_ALIGNMENT_LEFT, -1, int(tam), cor)

# ────────────────────────────── os naipes ──────────────────────────────
# Cor E forma, sempre: 4,5% dos jogadores não separam os naipes por cor, e a
# grade precisa continuar legível em escala de cinza. Nos temas de fundo claro
# o tema pede contorno, que separa o naipe do papel sem depender de matiz.

static func _naipe(alvo: CanvasItem, centro: Vector2, tamanho: float, naipe: int,
                   cor: Color, invertido := false) -> void:
    var s := tamanho * 0.5
    var d := -1.0 if invertido else 1.0
    match naipe:
        0: _copas(alvo, centro, s, d, cor)
        1: _ouros(alvo, centro, s, d, cor)
        2: _paus(alvo, centro, s, d, cor)
        _: _espadas(alvo, centro, s, d, cor)

static func _contornar(alvo: CanvasItem, pontos: PackedVector2Array) -> void:
    if Temas.CONTORNO <= 0.0:
        return
    var fechado := pontos.duplicate()
    fechado.append(pontos[0])
    alvo.draw_polyline(fechado, Color(Temas.CARTA_TEXTO, 0.55 * Temas.CONTORNO), 1.0)

## Coração: dois círculos no alto e um triângulo apontando para baixo.
static func _copas(alvo: CanvasItem, c: Vector2, s: float, d: float, cor: Color) -> void:
    var rc := s * 0.52
    alvo.draw_circle(c + Vector2(-rc * 0.92, -rc * 0.42 * d), rc, cor)
    alvo.draw_circle(c + Vector2(rc * 0.92, -rc * 0.42 * d), rc, cor)
    var p := PackedVector2Array([
        c + Vector2(-s * 1.0, -s * 0.16 * d),
        c + Vector2(s * 1.0, -s * 0.16 * d),
        c + Vector2(0, s * 1.02 * d)])
    alvo.draw_colored_polygon(p, cor)
    _contornar(alvo, p)

## Ouro: um losango. É o mais simples e o mais distinto em escala de cinza.
static func _ouros(alvo: CanvasItem, c: Vector2, s: float, _d: float, cor: Color) -> void:
    var p := PackedVector2Array([
        c + Vector2(0, -s * 1.05), c + Vector2(s * 0.74, 0),
        c + Vector2(0, s * 1.05), c + Vector2(-s * 0.74, 0)])
    alvo.draw_colored_polygon(p, cor)
    _contornar(alvo, p)

## Paus: três círculos e um pé.
static func _paus(alvo: CanvasItem, c: Vector2, s: float, d: float, cor: Color) -> void:
    var rc := s * 0.46
    alvo.draw_circle(c + Vector2(0, -s * 0.52 * d), rc, cor)
    alvo.draw_circle(c + Vector2(-s * 0.62, s * 0.20 * d), rc, cor)
    alvo.draw_circle(c + Vector2(s * 0.62, s * 0.20 * d), rc, cor)
    var p := PackedVector2Array([
        c + Vector2(-s * 0.16, s * 0.10 * d), c + Vector2(s * 0.16, s * 0.10 * d),
        c + Vector2(s * 0.40, s * 1.05 * d), c + Vector2(-s * 0.40, s * 1.05 * d)])
    alvo.draw_colored_polygon(p, cor)
    _contornar(alvo, p)

## Espadas: o coração de cabeça para baixo, com pé.
static func _espadas(alvo: CanvasItem, c: Vector2, s: float, d: float, cor: Color) -> void:
    var rc := s * 0.52
    alvo.draw_circle(c + Vector2(-rc * 0.92, rc * 0.50 * d), rc, cor)
    alvo.draw_circle(c + Vector2(rc * 0.92, rc * 0.50 * d), rc, cor)
    var p := PackedVector2Array([
        c + Vector2(-s * 1.0, s * 0.24 * d),
        c + Vector2(s * 1.0, s * 0.24 * d),
        c + Vector2(0, -s * 1.02 * d)])
    alvo.draw_colored_polygon(p, cor)
    _contornar(alvo, p)
    var pe := PackedVector2Array([
        c + Vector2(-s * 0.14, s * 0.55 * d), c + Vector2(s * 0.14, s * 0.55 * d),
        c + Vector2(s * 0.42, s * 1.10 * d), c + Vector2(-s * 0.42, s * 1.10 * d)])
    alvo.draw_colored_polygon(pe, cor)

## Desenha só o símbolo do naipe, para rótulos e legendas fora da carta.
static func simbolo(alvo: CanvasItem, centro: Vector2, tamanho: float, naipe: int) -> void:
    _naipe(alvo, centro, tamanho, naipe, Temas.cor_do_naipe(naipe))
