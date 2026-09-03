extends Control
## Números do jogador, e o progresso de cada capítulo num relance.

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 150
    coluna.offset_right = -150
    coluna.offset_top = 26
    coluna.offset_bottom = -20
    coluna.add_theme_constant_override("separation", 10)
    add_child(coluna)

    coluna.add_child(Estilo.titulo("Seus números", 38))

    var total_fases := Catalogo.fases.size()
    var resolvidas := Progresso.total_resolvidas()
    var estrelas := Progresso.total_estrelas()
    var tempo_total := 0.0
    var perfeitas := 0
    var celulas := 0
    for chave in Progresso.fases:
        tempo_total += float(Progresso.fases[chave]["tempo"])
        if int(Progresso.fases[chave]["estrelas"]) >= 3:
            perfeitas += 1
        var fase := Catalogo.fase(int(chave))
        if fase != null:
            celulas += fase.total_cheias

    var cartoes := GridContainer.new()
    cartoes.columns = 3
    cartoes.add_theme_constant_override("h_separation", 12)
    cartoes.add_theme_constant_override("v_separation", 12)
    coluna.add_child(cartoes)
    cartoes.add_child(_cartao("Imagens reveladas", "%d / %d" % [resolvidas, total_fases]))
    cartoes.add_child(_cartao("Estrelas", "%d / %d" % [estrelas, total_fases * 3]))
    cartoes.add_child(_cartao("Fases perfeitas", str(perfeitas)))
    cartoes.add_child(_cartao("Células pintadas", _milhares(celulas)))
    cartoes.add_child(_cartao("Tempo somado", _duracao(tempo_total)))
    cartoes.add_child(_cartao("Conquistas", "%d / %d" %
        [Conquistas.concluidas(), Conquistas.todas().size()]))

    coluna.add_child(Estilo.titulo("Por capítulo", 24, Estilo.ACENTO))
    for i in Catalogo.capitulos.size():
        coluna.add_child(_capitulo(i))

    var voltar := Estilo.botao("Voltar", 260)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("menu"))
    var rodape := HBoxContainer.new()
    rodape.alignment = BoxContainer.ALIGNMENT_CENTER
    rodape.add_child(voltar)
    coluna.add_child(rodape)
    Juice.entrada(coluna)

func _cartao(rotulo: String, valor: String) -> Control:
    var painel := PanelContainer.new()
    painel.custom_minimum_size = Vector2(0, 92)
    painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var caixa := VBoxContainer.new()
    caixa.alignment = BoxContainer.ALIGNMENT_CENTER
    caixa.add_child(Estilo.titulo(valor, 30, Estilo.DESTAQUE))
    caixa.add_child(Estilo.legenda(rotulo, 15))
    painel.add_child(caixa)
    return painel

func _capitulo(indice: int) -> Control:
    var capitulo: Dictionary = Catalogo.capitulos[indice]
    var total: int = capitulo["fases"].size()
    var feitas := Progresso.resolvidas_do_capitulo(indice)

    var linha := HBoxContainer.new()
    linha.add_theme_constant_override("separation", 14)
    linha.custom_minimum_size.y = 34

    var nome := Estilo.legenda("%d. %s" % [indice + 1, capitulo["nome"]], 17, Estilo.TEXTO)
    nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    nome.custom_minimum_size.x = 220
    linha.add_child(nome)

    var barra := ProgressBar.new()
    barra.show_percentage = false
    barra.max_value = maxf(float(total), 1.0)
    barra.value = float(feitas)
    barra.custom_minimum_size.y = 12
    barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var vazia := StyleBoxFlat.new()
    vazia.bg_color = Estilo.CELULA_VAZIA
    vazia.set_corner_radius_all(6)
    var cheia := StyleBoxFlat.new()
    cheia.bg_color = FundoAnimado.tom_do_capitulo(indice)
    cheia.set_corner_radius_all(6)
    barra.add_theme_stylebox_override("background", vazia)
    barra.add_theme_stylebox_override("fill", cheia)
    linha.add_child(barra)

    var contagem := Estilo.legenda("%d/%d" % [feitas, total], 16, Estilo.TEXTO)
    contagem.custom_minimum_size.x = 70
    linha.add_child(contagem)
    return linha

func _milhares(valor: int) -> String:
    var texto := str(valor)
    var saida := ""
    for i in texto.length():
        if i > 0 and (texto.length() - i) % 3 == 0:
            saida += "."
        saida += texto[i]
    return saida

func _duracao(segundos: float) -> String:
    var total := int(segundos)
    if total >= 3600:
        return "%dh %02dmin" % [total / 3600, (total % 3600) / 60]
    return "%dmin" % (total / 60)
