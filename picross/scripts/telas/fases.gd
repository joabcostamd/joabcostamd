extends Control

var _capitulo := 0

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _capitulo = int(Navegacao.parametro("capitulo", 0))
    var capitulo: Dictionary = Catalogo.capitulos[_capitulo]

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 90
    coluna.offset_right = -90
    coluna.offset_top = 40
    coluna.offset_bottom = -30
    coluna.add_theme_constant_override("separation", 14)
    add_child(coluna)

    coluna.add_child(Estilo.titulo(capitulo["nome"], 40))
    coluna.add_child(Estilo.legenda("%d de %d resolvidas neste capítulo" %
        [Progresso.resolvidas_do_capitulo(_capitulo), capitulo["fases"].size()]))

    var grade := GridContainer.new()
    grade.columns = 5
    grade.add_theme_constant_override("h_separation", 14)
    grade.add_theme_constant_override("v_separation", 14)
    grade.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var centralizar := HBoxContainer.new()
    centralizar.alignment = BoxContainer.ALIGNMENT_CENTER
    centralizar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    centralizar.add_child(grade)
    coluna.add_child(centralizar)

    for id in capitulo["fases"]:
        grade.add_child(_cartao(int(id)))

    var voltar := Estilo.botao("Voltar", 200)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("capitulos"))
    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_child(voltar)
    coluna.add_child(linha)
    Juice.entrada(coluna)

func _cartao(id: int) -> Control:
    var puzzle := Catalogo.fase(id)
    var aberta := Progresso.desbloqueada(id)
    var resolvida := Progresso.resolvida(id)

    var botao := Button.new()
    botao.custom_minimum_size = Vector2(158, 146)
    botao.disabled = not aberta
    botao.tooltip_text = puzzle.nome if resolvida else "Ainda não revelada"
    botao.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("jogo", {"fase": id}))

    var conteudo := VBoxContainer.new()
    conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
    conteudo.alignment = BoxContainer.ALIGNMENT_CENTER
    conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    botao.add_child(conteudo)

    conteudo.add_child(Estilo.titulo(str(id), 26,
        Estilo.TEXTO if aberta else Estilo.TEXTO_SUAVE))

    if resolvida:
        # Mostra a imagem conquistada: o cartão vira lembrança, não só um número.
        var miniatura := ImagemPuzzle.new()
        miniatura.custom_minimum_size = Vector2(46, 46)
        miniatura.mostrar_moldura = false
        miniatura.definir(puzzle)
        var centralizar := HBoxContainer.new()
        centralizar.alignment = BoxContainer.ALIGNMENT_CENTER
        centralizar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        centralizar.add_child(miniatura)
        conteudo.add_child(centralizar)
        conteudo.add_child(Estilo.legenda(puzzle.nome, 15, Estilo.TEXTO))
        conteudo.add_child(Estilo.titulo(Estilo.estrelas_texto(Progresso.estrelas_de(id)),
            18, Estilo.DESTAQUE))
    elif aberta:
        conteudo.add_child(Estilo.legenda("%d×%d" % [puzzle.lado, puzzle.lado], 16))
        conteudo.add_child(Estilo.titulo("☆☆☆", 20, Estilo.TEXTO_SUAVE))
    else:
        conteudo.add_child(Estilo.titulo("🔒", 22, Estilo.TEXTO_SUAVE))
    return botao
