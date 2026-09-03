extends Control
## Seleção de fases. Com 200 fases, a tela precisa de abas por capítulo,
## filtros e rolagem — senão vira uma parede de botões.

enum Filtro { TODAS, PENDENTES, SEM_TRES_ESTRELAS }

const COLUNAS := 8

var _capitulo := 0
var _filtro := Filtro.TODAS
var _grade: GridContainer
var _resumo: Label
var _abas: HBoxContainer
var _botoes_filtro: Array[Button] = []
var _vazio: Label

func _ready() -> void:
    _capitulo = _capitulo_valido(int(Navegacao.parametro("capitulo", 0)))
    Estilo.aplicar(self, _capitulo)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 56
    coluna.offset_right = -56
    coluna.offset_top = 22
    coluna.offset_bottom = -18
    coluna.add_theme_constant_override("separation", 10)
    add_child(coluna)

    coluna.add_child(_montar_abas())
    _resumo = Estilo.legenda("", 17)
    coluna.add_child(_resumo)
    coluna.add_child(_montar_filtros())

    var rolagem := ScrollContainer.new()
    rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    coluna.add_child(rolagem)

    var centralizar := HBoxContainer.new()
    centralizar.alignment = BoxContainer.ALIGNMENT_CENTER
    centralizar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rolagem.add_child(centralizar)

    _grade = GridContainer.new()
    _grade.columns = COLUNAS
    _grade.add_theme_constant_override("h_separation", 10)
    _grade.add_theme_constant_override("v_separation", 10)
    centralizar.add_child(_grade)

    _vazio = Estilo.legenda("Nenhuma fase neste filtro.", 18)
    _vazio.visible = false
    coluna.add_child(_vazio)

    var voltar := Estilo.botao("Voltar ao menu", 220)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("menu"))
    var rodape := HBoxContainer.new()
    rodape.alignment = BoxContainer.ALIGNMENT_CENTER
    rodape.add_child(voltar)
    coluna.add_child(rodape)

    _preencher()
    Juice.entrada(coluna)

## Um capítulo ainda fechado não pode ser aberto nem por parâmetro: cai para
## o último aberto, senão a aba aparece com cadeado e o conteúdo aparece junto.
func _capitulo_valido(pedido: int) -> int:
    if Progresso.capitulo_aberto(pedido):
        return pedido
    for i in range(Catalogo.capitulos.size() - 1, -1, -1):
        if Progresso.capitulo_aberto(i):
            return i
    return 0

## Uma aba por capítulo: dá para pular entre eles sem voltar ao mapa.
func _montar_abas() -> Control:
    _abas = HBoxContainer.new()
    _abas.alignment = BoxContainer.ALIGNMENT_CENTER
    _abas.add_theme_constant_override("separation", 8)
    for i in Catalogo.capitulos.size():
        var capitulo: Dictionary = Catalogo.capitulos[i]
        var aberto := Progresso.capitulo_aberto(i)
        var aba := Button.new()
        aba.text = "%d. %s" % [i + 1, capitulo["nome"]] if aberto else "🔒 %d" % (i + 1)
        aba.custom_minimum_size = Vector2(0, 46)
        aba.disabled = not aberto
        aba.toggle_mode = true
        aba.button_pressed = i == _capitulo
        aba.pressed.connect(func():
            Audio.tocar("clique")
            _capitulo = i
            _atualizar_abas()
            _preencher())
        _abas.add_child(aba)
    return _abas

func _atualizar_abas() -> void:
    for i in _abas.get_child_count():
        var aba := _abas.get_child(i) as Button
        aba.button_pressed = i == _capitulo

func _montar_filtros() -> Control:
    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_theme_constant_override("separation", 8)
    _botoes_filtro.clear()
    for item in [["Todas", Filtro.TODAS], ["A resolver", Filtro.PENDENTES],
                 ["Sem 3 estrelas", Filtro.SEM_TRES_ESTRELAS]]:
        var botao := Button.new()
        botao.text = item[0]
        botao.custom_minimum_size = Vector2(0, 40)
        botao.toggle_mode = true
        botao.button_pressed = item[1] == _filtro
        botao.pressed.connect(func():
            Audio.tocar("cruz")
            _filtro = item[1]
            for outro in _botoes_filtro:
                outro.button_pressed = outro == botao
            _preencher())
        _botoes_filtro.append(botao)
        linha.add_child(botao)
    return linha

func _preencher() -> void:
    for filho in _grade.get_children():
        filho.queue_free()

    var capitulo: Dictionary = Catalogo.capitulos[_capitulo]
    var resolvidas := Progresso.resolvidas_do_capitulo(_capitulo)
    var total: int = capitulo["fases"].size()
    var estrelas := 0
    for numero in capitulo["fases"]:
        estrelas += Progresso.estrelas_de(int(numero))
    _resumo.text = "%s  ·  %d×%d  ·  %d de %d resolvidas  ·  %d de %d estrelas" % [
        capitulo["resumo"], capitulo["lado"], capitulo["lado"],
        resolvidas, total, estrelas, total * 3]

    var mostradas := 0
    for numero in capitulo["fases"]:
        var id := int(numero)
        if not _passa_no_filtro(id):
            continue
        _grade.add_child(_cartao(id))
        mostradas += 1
    _vazio.visible = mostradas == 0

func _passa_no_filtro(id: int) -> bool:
    match _filtro:
        Filtro.PENDENTES:
            return not Progresso.resolvida(id)
        Filtro.SEM_TRES_ESTRELAS:
            return Progresso.estrelas_de(id) < 3
        _:
            return true

func _cartao(id: int) -> Control:
    var puzzle := Catalogo.fase(id)
    var aberta := Progresso.desbloqueada(id)
    var resolvida := Progresso.resolvida(id)

    var botao := Button.new()
    botao.custom_minimum_size = Vector2(122, 138)
    botao.disabled = not aberta
    botao.tooltip_text = puzzle.nome if resolvida else "Ainda não revelada"
    botao.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("jogo", {"fase": id}))

    var conteudo := VBoxContainer.new()
    conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
    conteudo.offset_top = 6
    conteudo.offset_bottom = -6
    conteudo.alignment = BoxContainer.ALIGNMENT_CENTER
    conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    conteudo.add_theme_constant_override("separation", 2)
    botao.add_child(conteudo)

    conteudo.add_child(Estilo.legenda(str(id), 15,
        Estilo.TEXTO_SUAVE if aberta else Estilo.BORDA))

    var imagem := ImagemPuzzle.new()
    imagem.custom_minimum_size = Vector2(62, 62)
    imagem.mostrar_moldura = false
    imagem.bloqueada = not resolvida
    imagem.definir(puzzle)
    var centro := HBoxContainer.new()
    centro.alignment = BoxContainer.ALIGNMENT_CENTER
    centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
    centro.add_child(imagem)
    conteudo.add_child(centro)

    if resolvida:
        conteudo.add_child(Estilo.legenda(puzzle.nome, 14, Estilo.TEXTO))
        conteudo.add_child(Estilo.titulo(Estilo.estrelas_texto(Progresso.estrelas_de(id)),
            16, Estilo.DESTAQUE))
    elif aberta:
        conteudo.add_child(Estilo.legenda("a revelar", 14))
        conteudo.add_child(Estilo.titulo("☆☆☆", 16, Estilo.BORDA))
    else:
        conteudo.add_child(Estilo.legenda("bloqueada", 14, Estilo.BORDA))
    return botao
