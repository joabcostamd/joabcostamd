extends Control
class_name GradeJogo
## Desenha o tabuleiro e as pistas, e traduz mouse em jogadas.
##
## Tudo é desenhado num nó só, em vez de milhares de nós: uma grade 20x20 tem
## 400 células, e cada uma como nó seria desperdício.

signal jogada_feita(tipo: int, celula: Vector2i)
signal linha_fechada(indice: int, horizontal: bool)

const PROPORCAO_PISTA := 0.62   # tamanho da coluna de pistas em relação à célula

var partida: Partida
var mostrar_erros := true

var _lado_celula := 32.0
var _unidade_pista := 20.0
var _canto := Vector2.ZERO          # onde a grade começa
var _max_pistas_linha := 1
var _max_pistas_coluna := 1
var _celula_sob_mouse := Vector2i(-1, -1)
var _brilho := {}                    # Vector2i -> intensidade que decai
var _sequencia := 0                  # acertos seguidos, para a escada sonora
var _prontas := {}                   # linhas e colunas já comemoradas
var _arrastando := false
var _botao_arraste := 0
var _celula_inicial := Vector2i(-1, -1)
var _eixo_travado := -1              # 0 horizontal, 1 vertical

func definir_partida(nova: Partida) -> void:
    partida = nova
    _prontas.clear()
    _sequencia = 0
    _max_pistas_linha = 1
    _max_pistas_coluna = 1
    for pistas in partida.puzzle.pistas_linhas:
        _max_pistas_linha = maxi(_max_pistas_linha, pistas.size())
    for pistas in partida.puzzle.pistas_colunas:
        _max_pistas_coluna = maxi(_max_pistas_coluna, pistas.size())
    _recalcular()
    queue_redraw()

func _ready() -> void:
    resized.connect(_recalcular)
    mouse_exited.connect(func():
        _celula_sob_mouse = Vector2i(-1, -1)
        queue_redraw())
    set_process(true)

func _process(delta: float) -> void:
    if _brilho.is_empty():
        return
    for chave in _brilho.keys():
        _brilho[chave] -= delta * 3.2
        if _brilho[chave] <= 0.0:
            _brilho.erase(chave)
    queue_redraw()

func _recalcular() -> void:
    if partida == null:
        return
    var lado: int = partida.puzzle.lado
    # A largura tem de acomodar a grade mais a coluna de pistas.
    var por_largura := size.x / (lado + PROPORCAO_PISTA * _max_pistas_linha)
    var por_altura := size.y / (lado + PROPORCAO_PISTA * _max_pistas_coluna)
    _lado_celula = floorf(minf(por_largura, por_altura))
    _unidade_pista = _lado_celula * PROPORCAO_PISTA
    var largura_total := _lado_celula * lado + _unidade_pista * _max_pistas_linha
    var altura_total := _lado_celula * lado + _unidade_pista * _max_pistas_coluna
    _canto = Vector2(
        (size.x - largura_total) * 0.5 + _unidade_pista * _max_pistas_linha,
        (size.y - altura_total) * 0.5 + _unidade_pista * _max_pistas_coluna)
    queue_redraw()

func celula_em(posicao: Vector2) -> Vector2i:
    if partida == null or _lado_celula <= 0.0:
        return Vector2i(-1, -1)
    var relativa := (posicao - _canto) / _lado_celula
    var celula := Vector2i(floori(relativa.x), floori(relativa.y))
    if partida.puzzle.dentro(celula.x, celula.y):
        return celula
    return Vector2i(-1, -1)

func _gui_input(evento: InputEvent) -> void:
    if partida == null or partida.concluida or partida.perdeu:
        return

    if evento is InputEventMouseButton:
        var clique := evento as InputEventMouseButton
        if clique.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
            if clique.pressed:
                _celula_inicial = celula_em(clique.position)
                _eixo_travado = -1
                _arrastando = true
                _botao_arraste = clique.button_index
                _aplicar(_celula_inicial)
            else:
                _arrastando = false
                _eixo_travado = -1
            accept_event()

    elif evento is InputEventMouseMotion:
        var movimento := evento as InputEventMouseMotion
        var celula := celula_em(movimento.position)
        if celula != _celula_sob_mouse:
            _celula_sob_mouse = celula
            queue_redraw()
        if _arrastando and celula.x >= 0:
            # Arrastar preenche em linha reta: trava no eixo que o jogador puxou.
            if _eixo_travado < 0 and celula != _celula_inicial:
                var diferenca := celula - _celula_inicial
                _eixo_travado = 0 if absi(diferenca.x) >= absi(diferenca.y) else 1
            var destino := celula
            if _eixo_travado == 0:
                destino.y = _celula_inicial.y
            elif _eixo_travado == 1:
                destino.x = _celula_inicial.x
            _aplicar(destino)

func _aplicar(celula: Vector2i) -> void:
    if celula.x < 0 or partida == null:
        return
    var anterior := partida.marca_em(celula.x, celula.y)
    var resultado: int
    if _botao_arraste == MOUSE_BUTTON_LEFT:
        resultado = partida.pintar(celula.x, celula.y)
    else:
        # No arraste com o botão direito só marcamos, nunca desmarcamos:
        # arrastar por cima de uma cruz já feita não deve apagá-la.
        if _arrastando and _eixo_travado >= 0 and anterior == Partida.Marca.CRUZ:
            return
        resultado = partida.alternar_cruz(celula.x, celula.y)
    if resultado == Partida.Jogada.NADA:
        return
    _brilho[celula] = 1.0
    var centro := _canto + (Vector2(celula) + Vector2(0.5, 0.5)) * _lado_celula
    match resultado:
        Partida.Jogada.ACERTO:
            _sequencia += 1
            Juice.faiscas(self, centro + global_position, Estilo.DESTAQUE, 6, 90.0)
        Partida.Jogada.ERRO:
            _sequencia = 0
            Juice.faiscas(self, centro + global_position, Estilo.ERRO, 14, 190.0)
        _:
            _sequencia = 0
    jogada_feita.emit(resultado, celula)
    if resultado == Partida.Jogada.ACERTO:
        _conferir_fechamento(celula)
    queue_redraw()

## Avisa quando a linha ou a coluna da jogada acabou de fechar — é o momento
## que mais dá satisfação num picross, e antes passava em branco.
func _conferir_fechamento(celula: Vector2i) -> void:
    var camada := Juice.camada_particulas(self)
    for par in [[celula.y, true], [celula.x, false]]:
        var indice: int = par[0]
        var horizontal: bool = par[1]
        var chave := "%s%d" % ["l" if horizontal else "c", indice]
        if _prontas.has(chave) or not _linha_pronta(indice, horizontal):
            continue
        _prontas[chave] = true
        if camada != null:
            var lado: int = partida.puzzle.lado
            var inicio := _canto + global_position
            var fim := inicio
            if horizontal:
                inicio.y += (indice + 0.5) * _lado_celula
                fim = inicio + Vector2(lado * _lado_celula, 0)
            else:
                inicio.x += (indice + 0.5) * _lado_celula
                fim = inicio + Vector2(0, lado * _lado_celula)
            camada.varrer(inicio, fim, Estilo.SUCESSO, 16)
        linha_fechada.emit(indice, horizontal)

## Quantos acertos seguidos, para quem quiser reagir à sequência.
func sequencia() -> int:
    return _sequencia

# ─────────────────────────────── desenho ───────────────────────────────

func _draw() -> void:
    if partida == null:
        return
    var lado: int = partida.puzzle.lado
    var fonte := get_theme_default_font()
    var corpo := Rect2(_canto, Vector2(_lado_celula * lado, _lado_celula * lado))

    # Moldura própria: separa o tabuleiro do fundo animado e dá foco.
    # As pistas ficam só à esquerda e acima, então a folga não é igual nos
    # quatro lados — daí o retângulo ser montado à mão.
    var folga := 10.0
    var recuo_esquerda := _unidade_pista * _max_pistas_linha + folga
    var recuo_topo := _unidade_pista * _max_pistas_coluna + folga
    var moldura := Rect2(
        corpo.position - Vector2(recuo_esquerda, recuo_topo),
        corpo.size + Vector2(recuo_esquerda + folga, recuo_topo + folga))
    draw_rect(moldura, Color(Estilo.PAINEL, 0.55))
    draw_rect(moldura, Color(Estilo.BORDA, 0.8), false, 2.0)

    draw_rect(corpo, Estilo.CELULA_VAZIA)
    _desenhar_destaque(lado)
    _desenhar_celulas(lado)
    _desenhar_linhas(lado)
    _desenhar_pistas(lado, fonte)

func _desenhar_destaque(lado: int) -> void:
    if _celula_sob_mouse.x < 0:
        return
    var cor := Color(Estilo.ACENTO, 0.13)
    draw_rect(Rect2(_canto + Vector2(0, _celula_sob_mouse.y * _lado_celula),
                    Vector2(_lado_celula * lado, _lado_celula)), cor)
    draw_rect(Rect2(_canto + Vector2(_celula_sob_mouse.x * _lado_celula, 0),
                    Vector2(_lado_celula, _lado_celula * lado)), cor)
    # a célula sob o cursor ganha um contorno, para o alvo ficar claro
    draw_rect(Rect2(_canto + Vector2(_celula_sob_mouse) * _lado_celula,
                    Vector2(_lado_celula, _lado_celula)),
              Color(Estilo.DESTAQUE, 0.55), false, 2.0)

func _desenhar_celulas(lado: int) -> void:
    var margem := maxf(_lado_celula * 0.06, 1.0)
    for y in lado:
        for x in lado:
            var marca := partida.marca_em(x, y)
            var canto := _canto + Vector2(x, y) * _lado_celula
            var area := Rect2(canto + Vector2(margem, margem),
                              Vector2(_lado_celula - margem * 2, _lado_celula - margem * 2))
            var chave := Vector2i(x, y)
            if marca == Partida.Marca.PINTADA:
                var cor := Estilo.CELULA_CHEIA
                if _brilho.has(chave):
                    var forca: float = _brilho[chave]
                    cor = cor.lerp(Estilo.DESTAQUE, forca)
                    # a célula nasce um pouco maior e assenta: dá o "pop"
                    var crescer := forca * _lado_celula * 0.16
                    area = area.grow(crescer)
                    draw_rect(area.grow(crescer * 1.6), Color(Estilo.DESTAQUE, forca * 0.35))
                draw_rect(area, cor)
                # faixa clara no topo: dá volume, em vez de um branco chapado
                draw_rect(Rect2(area.position, Vector2(area.size.x, area.size.y * 0.28)),
                          Color(Color.WHITE, 0.35))
            elif marca == Partida.Marca.CRUZ:
                var errada: bool = mostrar_erros and partida.celulas_erradas.has(chave)
                var cor_x := Estilo.ERRO if errada else Estilo.TEXTO_SUAVE
                if _brilho.has(chave):
                    cor_x = cor_x.lerp(Estilo.ERRO, _brilho[chave])
                var recuo := _lado_celula * 0.30
                var largura := maxf(_lado_celula * 0.09, 1.5)
                draw_line(canto + Vector2(recuo, recuo),
                          canto + Vector2(_lado_celula - recuo, _lado_celula - recuo), cor_x, largura)
                draw_line(canto + Vector2(_lado_celula - recuo, recuo),
                          canto + Vector2(recuo, _lado_celula - recuo), cor_x, largura)

func _desenhar_linhas(lado: int) -> void:
    for i in range(lado + 1):
        var forte := i % 5 == 0 or i == lado
        var cor := Estilo.GRADE_FORTE if forte else Estilo.GRADE
        var grossura := 2.0 if forte else 1.0
        var deslocamento := i * _lado_celula
        draw_line(_canto + Vector2(deslocamento, 0),
                  _canto + Vector2(deslocamento, _lado_celula * lado), cor, grossura)
        draw_line(_canto + Vector2(0, deslocamento),
                  _canto + Vector2(_lado_celula * lado, deslocamento), cor, grossura)

func _desenhar_pistas(lado: int, fonte: Font) -> void:
    var tamanho := int(maxf(_unidade_pista * 0.78, 8.0))
    for y in lado:
        var pistas: Array = partida.puzzle.pistas_linhas[y]
        var pronta := _linha_pronta(y, true)
        var cor := Estilo.TEXTO_SUAVE if pronta else Estilo.TEXTO
        if _celula_sob_mouse.y == y and not pronta:
            cor = Estilo.DESTAQUE
        for i in pistas.size():
            var valor := int(pistas[i])
            if valor == 0:
                continue
            var deslocamento := (pistas.size() - i) * _unidade_pista
            var posicao := _canto + Vector2(-deslocamento, y * _lado_celula + _lado_celula * 0.72)
            draw_string(fonte, posicao, str(valor), HORIZONTAL_ALIGNMENT_CENTER,
                        _unidade_pista, tamanho, cor)

    for x in lado:
        var pistas: Array = partida.puzzle.pistas_colunas[x]
        var pronta := _linha_pronta(x, false)
        var cor := Estilo.TEXTO_SUAVE if pronta else Estilo.TEXTO
        if _celula_sob_mouse.x == x and not pronta:
            cor = Estilo.DESTAQUE
        for i in pistas.size():
            var valor := int(pistas[i])
            if valor == 0:
                continue
            var deslocamento := (pistas.size() - i) * _unidade_pista
            var posicao := _canto + Vector2(x * _lado_celula, -deslocamento + _unidade_pista * 0.78)
            draw_string(fonte, posicao, str(valor), HORIZONTAL_ALIGNMENT_CENTER,
                        _lado_celula, tamanho, cor)

## Uma linha (ou coluna) está pronta quando todas as suas células cheias
## já foram pintadas — aí as pistas dela esmaecem e saem do caminho.
func _linha_pronta(indice: int, horizontal: bool) -> bool:
    for i in partida.puzzle.lado:
        var x := i if horizontal else indice
        var y := indice if horizontal else i
        if partida.puzzle.e_cheia(x, y) and partida.marca_em(x, y) != Partida.Marca.PINTADA:
            return false
    return true
