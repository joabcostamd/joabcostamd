extends RefCounted
class_name Pintura
## A biblioteca de desenho compartilhada entre a maquete e o jogo.
##
## Existe para a tela de verdade ter exatamente os mesmos pixels da maquete que
## foi auditada, medida e escolhida. Se cada uma tivesse o seu próprio `_caixa`,
## a auditoria valeria para a maquete e não para o jogo.
##
## Tudo aqui é estático e recebe o `CanvasItem` como primeiro parâmetro: é
## desenho, não nó.

## A poeira flutuante do fundo. Cada partícula é (x, y, raio) em coordenadas
## normalizadas; a semente é fixa para toda captura sair idêntica.
static func semear_poeira(quantas := 90, semente := 20260904) -> Array[Vector3]:
    var rng := RandomNumberGenerator.new()
    rng.seed = semente
    var lista: Array[Vector3] = []
    for i in quantas:
        lista.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(1.0, 3.0)))
    return lista

# ─────────────────────────────── o fundo ───────────────────────────────
# Cada tema tem o SEU tratamento de fundo, não só a sua cor. Enquanto os oito
# compartilhavam um brilho radial, vários pareciam o mesmo tema repintado — foi
# o que a folha de contato mostrou. Fundo é identidade.

static func fundo(alvo: CanvasItem, tamanho: Vector2, poeira: Array[Vector3]) -> void:
    alvo.draw_rect(Rect2(Vector2.ZERO, tamanho), Temas.FUNDO)
    match Temas.FUNDO_ESTILO:
        "grade": _fundo_grade(alvo, tamanho, poeira)
        "tecido": _fundo_tecido(alvo, tamanho, poeira)
        "papel": _fundo_papel(alvo, tamanho, poeira)
        "vinheta": pass
        _: _fundo_brilho(alvo, tamanho, poeira)
    _poeira_flutuante(alvo, tamanho, poeira)
    _vinheta(alvo, tamanho, poeira)

## Brilho radial suave, em muitas camadas fracas: com poucas, as bordas dos
## círculos aparecem como anéis em vez de um brilho contínuo.
static func _fundo_brilho(alvo: CanvasItem, tamanho: Vector2, poeira: Array[Vector3]) -> void:
    if Temas.BRILHO <= 0.0:
        return
    var centro := tamanho * Vector2(0.5, 0.42)
    var raio := maxf(tamanho.x, tamanho.y) * 0.62
    for i in 18:
        var t := float(i) / 17.0
        var cor := Temas.ACENTO.lerp(Temas.DESTAQUE, t * 0.35)
        alvo.draw_circle(centro, raio * (1.0 - t * 0.85), Color(cor, 0.008 * Temas.BRILHO))

## Grade de linhas acesas: a assinatura do fliperama. Substitui o brilho radial,
## que misturava ciano com amarelo e lavava a tela de verde-piscina.
static func _fundo_grade(alvo: CanvasItem, tamanho: Vector2, poeira: Array[Vector3]) -> void:
    var passo := 48.0
    var cor := Color(Temas.ACENTO, 0.055)
    var x := passo
    while x < tamanho.x:
        alvo.draw_line(Vector2(x, 0), Vector2(x, tamanho.y), cor, 1.0)
        x += passo
    var y := passo
    while y < tamanho.y:
        alvo.draw_line(Vector2(0, y), Vector2(tamanho.x, y), Color(Temas.ACENTO, 0.035), 1.0)
        y += passo
    # Duas linhas mais fortes dão o "horizonte" sem custar nada.
    alvo.draw_line(Vector2(0, tamanho.y * 0.62), Vector2(tamanho.x, tamanho.y * 0.62),
              Color(Temas.ACENTO, 0.16), 1.0)
    alvo.draw_line(Vector2(tamanho.x * 0.5, 0), Vector2(tamanho.x * 0.5, tamanho.y),
              Color(Temas.ACENTO, 0.05), 1.0)

## Trama fina de feltro. Linhas cruzadas quase invisíveis: de perto some, de
## longe dá textura de pano.
static func _fundo_tecido(alvo: CanvasItem, tamanho: Vector2, poeira: Array[Vector3]) -> void:
    var passo := 4.0
    var cor := Color(Temas.TEXTO, 0.014)
    var y := 0.0
    while y < tamanho.y:
        alvo.draw_line(Vector2(0, y), Vector2(tamanho.x, y), cor, 1.0)
        y += passo
    var x := 0.0
    while x < tamanho.x:
        alvo.draw_line(Vector2(x, 0), Vector2(x, tamanho.y), Color(0, 0, 0, 0.012), 1.0)
        x += passo

## Grão de papel: manchas largas e fraquíssimas, para o creme não ficar chapado.
static func _fundo_papel(alvo: CanvasItem, tamanho: Vector2, poeira: Array[Vector3]) -> void:
    for p in poeira:
        alvo.draw_circle(Vector2(p.x * tamanho.x, p.y * tamanho.y), 40.0 + p.z * 30.0,
                    Color(Temas.TEXTO, 0.006))

static func _poeira_flutuante(alvo: CanvasItem, tamanho: Vector2, poeira: Array[Vector3]) -> void:
    if Temas.PARTICULA <= 0.0:
        return
    for i in mini(poeira.size(), 40):
        var p := poeira[i]
        alvo.draw_circle(Vector2(p.x * tamanho.x, p.y * tamanho.y), p.z * 0.7,
                    Color(Temas.TEXTO, Temas.PARTICULA))

## Bordas escuras para o olho ir ao centro. Só faz sentido onde há o que
## escurecer — sobre papel ela suja.
static func _vinheta(alvo: CanvasItem, tamanho: Vector2, poeira: Array[Vector3]) -> void:
    if Temas.e_claro():
        return
    var forca := 0.05
    if Temas.FUNDO_ESTILO == "vinheta" or Temas.FUNDO_ESTILO == "grade":
        forca = 0.085
    var faixa := tamanho.y * 0.22
    for i in 12:
        var t := float(i) / 11.0
        var opacidade := forca * (1.0 - t)
        var e := faixa * (1.0 - t) / 12.0 + 2.0
        alvo.draw_rect(Rect2(0, t * faixa / 2.0, tamanho.x, e), Color(0, 0, 0, opacidade))
        alvo.draw_rect(Rect2(0, tamanho.y - t * faixa / 2.0 - e, tamanho.x, e),
                    Color(0, 0, 0, opacidade))
        alvo.draw_rect(Rect2(t * faixa / 3.0, 0, e, tamanho.y), Color(0, 0, 0, opacidade * 0.8))
        alvo.draw_rect(Rect2(tamanho.x - t * faixa / 3.0 - e, 0, e, tamanho.y),
                    Color(0, 0, 0, opacidade * 0.8))

# ─────────────────────── paisagem: três colunas ───────────────────────

static func mesa_embutida(alvo: CanvasItem, g: Rect2) -> void:
    var mesa := g.grow(14.0)
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Color(Temas.FUNDO, 0.55) if Temas.e_claro() else Color(0, 0, 0, 0.22)
    caixa.set_corner_radius_all(16)
    caixa.border_color = Color(Temas.FILETE, 0.16)
    caixa.set_border_width_all(1)
    alvo.draw_style_box(caixa, mesa)
    # Sombra interna só no topo: a luz vem de cima, então o degrau só escurece
    # a aba superior. Sombra nos quatro lados lê como buraco, não como encaixe.
    for i in 6:
        var t := float(i) / 5.0
        alvo.draw_rect(Rect2(mesa.position.x + 2, mesa.position.y + 1 + i, mesa.size.x - 4, 1),
                  Color(0, 0, 0, 0.10 * (1.0 - t)))

static func casa_vazia(alvo: CanvasItem, c: Rect2, viva: bool) -> void:
    var caixa := StyleBoxFlat.new()
    # Token próprio, nunca PAINEL com alfa: derivar a cor da casa de outra cor
    # funciona no tema escuro e faz o tabuleiro sumir no claro.
    caixa.bg_color = Temas.CASA
    caixa.border_color = Temas.DESTAQUE if viva else Temas.CASA_BORDA
    caixa.set_border_width_all(3 if viva else 2)
    caixa.set_corner_radius_all(int(maxf(4.0, c.size.x * 0.09)))
    alvo.draw_style_box(caixa, c)
    # Um fio de luz na aresta de cima. A luz da cena vem de cima, então só a
    # aba superior a recebe — é o que faz a casa ler como marcação rebaixada no
    # feltro em vez de buraco recortado nele. Um draw_rect.
    if not viva:
        alvo.draw_rect(Rect2(c.position.x + c.size.x * 0.12, c.position.y + 1.5,
                        c.size.x * 0.76, 1.0), Color(Temas.TEXTO, 0.07))

## Os rótulos de linha: a fração e a categoria, colados na linha. É a informação
## que o jogador mais lê — painel distante obrigaria o olho a viajar.

static func caixa(alvo: CanvasItem, r: Rect2, raio := 12, alfa := 0.72) -> void:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = Color(Temas.PAINEL, alfa)
    caixa.border_color = Temas.BORDA
    caixa.set_border_width_all(1)
    caixa.set_corner_radius_all(raio)
    alvo.draw_style_box(caixa, r)
    # O filete: 1 px do acento por dentro da borda. Borda grossa é a assinatura
    # da interface improvisada; a linha fina é a da interface cara. Custa um
    # draw_rect e muda a leitura da tela inteira.
    var dentro := StyleBoxFlat.new()
    dentro.bg_color = Color(0, 0, 0, 0)
    dentro.border_color = Color(Temas.FILETE, 0.22)
    dentro.set_border_width_all(1)
    dentro.set_corner_radius_all(maxi(raio - 2, 2))
    alvo.draw_style_box(dentro, r.grow(-3.0))

static func pilula(alvo: CanvasItem, r: Rect2, cor: Color, raio := -1) -> void:
    var caixa := StyleBoxFlat.new()
    caixa.bg_color = cor
    caixa.set_corner_radius_all(int(r.size.y * 0.5) if raio < 0 else raio)
    alvo.draw_style_box(caixa, r)

static func numero(alvo: CanvasItem, r: Rect2, titulo: String, valor: String, cor: Color, tam: int) -> void:
    var f := Temas.fonte_do_tema(true)
    alvo.draw_string(f, Vector2(r.position.x, r.position.y + 14), titulo,
                HORIZONTAL_ALIGNMENT_CENTER, r.size.x, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
    alvo.draw_string(f, Vector2(r.position.x, r.position.y + 14 + tam), valor,
                HORIZONTAL_ALIGNMENT_CENTER, r.size.x, tam, cor)

static func centrado(alvo: CanvasItem, f: FontFile, r: Rect2, texto: String, tam: int, cor: Color) -> void:
    var med := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
    alvo.draw_string(f, Vector2(r.position.x + (r.size.x - med.x) * 0.5,
                r.position.y + (r.size.y + med.y * 0.62) * 0.5),
                texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)

## Milhar com ponto, como se escreve em português.

static func milhar(n: int) -> String:
    var s := str(n)
    var saida := ""
    var conta := 0
    for i in range(s.length() - 1, -1, -1):
        saida = s[i] + saida
        conta += 1
        if conta % 3 == 0 and i > 0:
            saida = "." + saida
    return saida
