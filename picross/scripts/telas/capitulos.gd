extends Control

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.add_theme_constant_override("separation", 10)
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 120
    coluna.offset_right = -120
    coluna.offset_top = 26
    coluna.offset_bottom = -40
    add_child(coluna)

    coluna.add_child(Estilo.titulo(tr("CAPITULOS_TITULO"), 42))
    coluna.add_child(Estilo.legenda(
        tr("GALERIA_CONTAGEM") % [Progresso.total_resolvidas(), Catalogo.fases.size()]))

    for i in Catalogo.capitulos.size():
        coluna.add_child(_cartao(i))

    var voltar := Estilo.botao(tr("COMUM_VOLTAR"), 200)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("menu"))
    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_child(voltar)
    coluna.add_child(linha)
    Juice.entrada(coluna)

func _cartao(indice: int) -> Control:
    var capitulo: Dictionary = Catalogo.capitulos[indice]
    var resolvidas := Progresso.resolvidas_do_capitulo(indice)
    var total: int = capitulo["fases"].size()
    var aberto := Progresso.capitulo_aberto(indice)

    var botao := Button.new()
    botao.custom_minimum_size.y = 80
    botao.disabled = not aberto
    botao.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("fases", {"capitulo": indice}))

    var conteudo := HBoxContainer.new()
    conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
    conteudo.offset_left = 26
    conteudo.offset_right = -26
    conteudo.offset_bottom = -16   # espaço reservado para a barra de progresso
    conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    conteudo.add_theme_constant_override("separation", 20)
    botao.add_child(conteudo)

    var texto := VBoxContainer.new()
    texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    texto.alignment = BoxContainer.ALIGNMENT_CENTER
    var nome := Estilo.titulo("%d. %s" % [indice + 1, capitulo["nome"]], 23)
    nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var resumo := Estilo.legenda(capitulo["resumo"] if aberto else tr("CAPITULO_TRANCADO"), 16)
    resumo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    texto.add_child(nome)
    texto.add_child(resumo)
    conteudo.add_child(texto)

    var direita := VBoxContainer.new()
    direita.alignment = BoxContainer.ALIGNMENT_CENTER
    var contagem := Estilo.titulo("%d/%d" % [resolvidas, total], 26,
        Estilo.SUCESSO if resolvidas == total else Estilo.TEXTO)
    var grade := Estilo.legenda("%d×%d" % [capitulo["lado"], capitulo["lado"]], 16)
    direita.add_child(contagem)
    direita.add_child(grade)
    conteudo.add_child(direita)

    # Barra de progresso do capítulo: dá a medida do avanço num relance.
    var barra := ProgressBar.new()
    barra.custom_minimum_size = Vector2(0, 6)
    barra.show_percentage = false
    barra.max_value = maxf(float(total), 1.0)
    barra.value = float(resolvidas)
    var vazia := StyleBoxFlat.new()
    vazia.bg_color = Estilo.CELULA_VAZIA
    vazia.set_corner_radius_all(3)
    var cheia := StyleBoxFlat.new()
    cheia.bg_color = Estilo.SUCESSO if resolvidas == total else FundoAnimado.tom_do_capitulo(indice)
    cheia.set_corner_radius_all(3)
    barra.add_theme_stylebox_override("background", vazia)
    barra.add_theme_stylebox_override("fill", cheia)
    barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    barra.offset_left = 26
    barra.offset_right = -26
    barra.offset_top = -12
    barra.offset_bottom = -7
    barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
    botao.add_child(barra)
    return botao
