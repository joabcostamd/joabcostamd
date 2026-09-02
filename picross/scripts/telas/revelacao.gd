extends Control
## A recompensa: a imagem aparece colorida, com o nome e o resultado.

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var id := int(Navegacao.parametro("fase", 1))
    var puzzle := Catalogo.fase(id)
    var tempo := float(Navegacao.parametro("tempo", 0.0))
    var estrelas := int(Navegacao.parametro("estrelas", 1))

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_top = 26
    coluna.offset_bottom = -26
    coluna.add_theme_constant_override("separation", 8)
    coluna.alignment = BoxContainer.ALIGNMENT_CENTER
    add_child(coluna)

    coluna.add_child(Estilo.legenda("imagem revelada", 18))
    var nome := Estilo.titulo(puzzle.nome, 46, puzzle.cor.lerp(Color.WHITE, 0.4))
    coluna.add_child(nome)

    var imagem := ImagemPuzzle.new()
    imagem.custom_minimum_size = Vector2(360, 360)
    imagem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    imagem.definir(puzzle)
    coluna.add_child(imagem)
    imagem.animar(1.2)

    coluna.add_child(Estilo.legenda(puzzle.legenda, 19))

    var placar := Estilo.titulo(Estilo.estrelas_texto(estrelas), 40, Estilo.DESTAQUE)
    coluna.add_child(placar)
    placar.modulate.a = 0.0
    var surgir := create_tween()
    surgir.tween_interval(1.2)
    surgir.tween_property(placar, "modulate:a", 1.0, 0.4)
    surgir.tween_callback(func(): Audio.tocar("estrela"))

    var detalhe := "tempo %s" % Estilo.tempo_texto(tempo)
    if estrelas < 3:
        detalhe += "   ·   3 estrelas: sem erros, sem dica e abaixo de %s" % \
            Estilo.tempo_texto(puzzle.tempo_alvo)
    coluna.add_child(Estilo.legenda(detalhe, 16))

    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_theme_constant_override("separation", 12)
    coluna.add_child(linha)

    var proxima_id := Catalogo.proxima_fase(id)
    if proxima_id > 0 and proxima_id <= Catalogo.fases.size():
        var proxima := Estilo.botao("Próxima fase", 220)
        proxima.pressed.connect(func():
            Audio.tocar("clique")
            Navegacao.ir_para("jogo", {"fase": proxima_id}))
        linha.add_child(proxima)
    else:
        linha.add_child(Estilo.titulo("Você revelou todas as imagens!", 22, Estilo.SUCESSO))

    var galeria := Estilo.botao("Galeria", 180)
    galeria.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("galeria"))
    linha.add_child(galeria)

    var mapa := Estilo.botao("Mapa", 160)
    mapa.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("fases", {"capitulo": Catalogo.capitulo_da_fase(id)}))
    linha.add_child(mapa)
