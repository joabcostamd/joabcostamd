extends Control

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 140
    coluna.offset_right = -140
    coluna.offset_top = 24
    coluna.offset_bottom = -20
    coluna.add_theme_constant_override("separation", 8)
    add_child(coluna)

    var lista := Conquistas.todas()
    var feitas := 0
    for c in lista:
        if c.concluida():
            feitas += 1

    coluna.add_child(Estilo.titulo(tr("CONQ_TITULO"), 38))
    coluna.add_child(Estilo.legenda(tr("CONQ_CONTAGEM") % [feitas, lista.size()], 18))

    var rolagem := ScrollContainer.new()
    rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    coluna.add_child(rolagem)

    var caixa := VBoxContainer.new()
    caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    caixa.add_theme_constant_override("separation", 8)
    rolagem.add_child(caixa)

    for c in lista:
        caixa.add_child(_linha(c))

    var voltar := Estilo.botao(tr("COMUM_VOLTAR"), 260)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("menu"))
    var rodape := HBoxContainer.new()
    rodape.alignment = BoxContainer.ALIGNMENT_CENTER
    rodape.add_child(voltar)
    coluna.add_child(rodape)
    Juice.entrada(coluna)

func _linha(c) -> Control:
    var painel := PanelContainer.new()
    painel.custom_minimum_size.y = 68

    var linha := HBoxContainer.new()
    linha.add_theme_constant_override("separation", 18)
    painel.add_child(linha)

    var marca := Estilo.titulo("★" if c.concluida() else "☆", 30,
        Estilo.DESTAQUE if c.concluida() else Estilo.BORDA)
    marca.custom_minimum_size.x = 44
    marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    linha.add_child(marca)

    var texto := VBoxContainer.new()
    texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    texto.alignment = BoxContainer.ALIGNMENT_CENTER
    texto.add_theme_constant_override("separation", 2)
    var nome := Estilo.legenda(c.nome, 19,
        Estilo.TEXTO if c.concluida() else Estilo.TEXTO_SUAVE)
    nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var detalhe := Estilo.legenda(c.descricao, 15)
    detalhe.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    texto.add_child(nome)
    texto.add_child(detalhe)

    var barra := ProgressBar.new()
    barra.custom_minimum_size.y = 6
    barra.show_percentage = false
    barra.max_value = 1.0
    barra.value = c.fracao()
    var vazia := StyleBoxFlat.new()
    vazia.bg_color = Estilo.CELULA_VAZIA
    vazia.set_corner_radius_all(3)
    var cheia := StyleBoxFlat.new()
    cheia.bg_color = Estilo.SUCESSO if c.concluida() else Estilo.ACENTO
    cheia.set_corner_radius_all(3)
    barra.add_theme_stylebox_override("background", vazia)
    barra.add_theme_stylebox_override("fill", cheia)
    texto.add_child(barra)
    linha.add_child(texto)

    var contagem := Estilo.titulo("%d/%d" % [c.atual, c.meta], 20,
        Estilo.SUCESSO if c.concluida() else Estilo.TEXTO_SUAVE)
    contagem.custom_minimum_size.x = 90
    contagem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    linha.add_child(contagem)
    return painel
