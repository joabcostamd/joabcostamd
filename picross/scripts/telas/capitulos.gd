extends Control

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.add_theme_constant_override("separation", 16)
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 120
    coluna.offset_right = -120
    coluna.offset_top = 48
    coluna.offset_bottom = -40
    add_child(coluna)

    coluna.add_child(Estilo.titulo("Capítulos", 42))
    coluna.add_child(Estilo.legenda(
        "%d de %d imagens reveladas" % [Progresso.total_resolvidas(), Catalogo.fases.size()]))

    for i in Catalogo.capitulos.size():
        coluna.add_child(_cartao(i))

    var voltar := Estilo.botao("Voltar", 200)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("menu"))
    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_child(voltar)
    coluna.add_child(linha)

func _cartao(indice: int) -> Control:
    var capitulo: Dictionary = Catalogo.capitulos[indice]
    var resolvidas := Progresso.resolvidas_do_capitulo(indice)
    var total: int = capitulo["fases"].size()
    var aberto := Progresso.capitulo_aberto(indice)

    var botao := Button.new()
    botao.custom_minimum_size.y = 96
    botao.disabled = not aberto
    botao.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("fases", {"capitulo": indice}))

    var conteudo := HBoxContainer.new()
    conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
    conteudo.offset_left = 26
    conteudo.offset_right = -26
    conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    conteudo.add_theme_constant_override("separation", 20)
    botao.add_child(conteudo)

    var texto := VBoxContainer.new()
    texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    texto.alignment = BoxContainer.ALIGNMENT_CENTER
    var nome := Estilo.titulo("%d. %s" % [indice + 1, capitulo["nome"]], 26)
    nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var resumo := Estilo.legenda(capitulo["resumo"] if aberto else "Termine o capítulo anterior para abrir", 16)
    resumo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    texto.add_child(nome)
    texto.add_child(resumo)
    conteudo.add_child(texto)

    var direita := VBoxContainer.new()
    direita.alignment = BoxContainer.ALIGNMENT_CENTER
    var contagem := Estilo.titulo("%d/%d" % [resolvidas, total], 30,
        Estilo.SUCESSO if resolvidas == total else Estilo.TEXTO)
    var grade := Estilo.legenda("%d×%d" % [capitulo["lado"], capitulo["lado"]], 16)
    direita.add_child(contagem)
    direita.add_child(grade)
    conteudo.add_child(direita)
    return botao
