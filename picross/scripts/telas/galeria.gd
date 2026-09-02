extends Control
## Mural das imagens conquistadas. Clicar numa amplia.

var _ampliada: Control

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 60
    coluna.offset_right = -60
    coluna.offset_top = 26
    coluna.offset_bottom = -20
    coluna.add_theme_constant_override("separation", 10)
    add_child(coluna)

    coluna.add_child(Estilo.titulo("Galeria", 40))
    coluna.add_child(Estilo.legenda("%d de %d imagens reveladas" %
        [Progresso.total_resolvidas(), Catalogo.fases.size()]))

    var rolagem := ScrollContainer.new()
    rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    coluna.add_child(rolagem)

    var grade := GridContainer.new()
    grade.columns = 8
    grade.add_theme_constant_override("h_separation", 12)
    grade.add_theme_constant_override("v_separation", 12)
    grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rolagem.add_child(grade)

    for puzzle in Catalogo.fases:
        grade.add_child(_moldura(puzzle))

    var voltar := Estilo.botao("Voltar", 200)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("menu"))
    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_child(voltar)
    coluna.add_child(linha)

func _moldura(puzzle: Puzzle) -> Control:
    var resolvida := Progresso.resolvida(puzzle.id)
    var botao := Button.new()
    botao.custom_minimum_size = Vector2(124, 140)
    botao.disabled = not resolvida
    botao.pressed.connect(func():
        Audio.tocar("clique")
        _ampliar(puzzle))

    var conteudo := VBoxContainer.new()
    conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
    conteudo.offset_top = 8
    conteudo.offset_bottom = -8
    conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    botao.add_child(conteudo)

    var imagem := ImagemPuzzle.new()
    imagem.custom_minimum_size = Vector2(96, 96)
    imagem.mostrar_moldura = false
    imagem.bloqueada = not resolvida
    imagem.definir(puzzle)
    conteudo.add_child(imagem)
    conteudo.add_child(Estilo.legenda(puzzle.nome if resolvida else "?", 14))
    return botao

func _ampliar(puzzle: Puzzle) -> void:
    if _ampliada != null:
        _ampliada.queue_free()

    _ampliada = Control.new()
    _ampliada.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_ampliada)

    var escuro := ColorRect.new()
    escuro.color = Color(0.02, 0.03, 0.05, 0.9)
    escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
    _ampliada.add_child(escuro)

    var coluna := VBoxContainer.new()
    coluna.alignment = BoxContainer.ALIGNMENT_CENTER
    coluna.add_theme_constant_override("separation", 10)
    _ampliada.add_child(coluna)

    coluna.add_child(Estilo.titulo(puzzle.nome, 40, puzzle.cor.lerp(Color.WHITE, 0.4)))
    var imagem := ImagemPuzzle.new()
    imagem.custom_minimum_size = Vector2(380, 380)
    imagem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    imagem.definir(puzzle)
    coluna.add_child(imagem)
    coluna.add_child(Estilo.legenda(puzzle.legenda, 19))
    coluna.add_child(Estilo.legenda("fase %d  ·  %d×%d  ·  %s  ·  melhor tempo %s" % [
        puzzle.id, puzzle.lado, puzzle.lado,
        Estilo.estrelas_texto(Progresso.estrelas_de(puzzle.id)),
        Estilo.tempo_texto(Progresso.tempo_de(puzzle.id))], 16))

    var fechar := Estilo.botao("Fechar", 180)
    fechar.pressed.connect(func():
        Audio.tocar("clique")
        _ampliada.queue_free()
        _ampliada = null)
    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_child(fechar)
    coluna.add_child(linha)

    coluna.position = (size - coluna.get_combined_minimum_size()) * 0.5
