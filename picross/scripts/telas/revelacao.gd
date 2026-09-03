extends Control
## A recompensa: a imagem aparece colorida, com o nome e o resultado.

## Ordem da comemoração: a imagem se forma, o clarão e o confete marcam o
## fim, e só então as estrelas caem uma a uma.
func _coreografar(imagem: ImagemPuzzle, simbolos: Array[Label], estrelas: int,
                  puzzle: Puzzle) -> void:
    var roteiro := create_tween()
    roteiro.tween_interval(1.25)
    roteiro.tween_callback(func():
        Audio.tocar("revelar")
        Juice.clarao(self, Color.WHITE, 0.34, 0.55)
        Juice.pulsar(imagem, 1.06, 0.4)
        var camada := Juice.camada_particulas(self)
        if camada != null:
            camada.confete(size.x, [Estilo.DESTAQUE, Estilo.ACENTO,
                                    Estilo.SUCESSO, puzzle.cor], 110))
    for i in simbolos.size():
        roteiro.tween_interval(0.22)
        roteiro.tween_callback(func():
            var estrela: Label = simbolos[i]
            estrela.modulate.a = 1.0
            Juice.pulsar(estrela, 1.7, 0.45)
            if i < estrelas:
                Audio.tocar("estrela", 1.0 + i * 0.14)
                Juice.faiscas(self, estrela.global_position + estrela.size * 0.5,
                              Estilo.DESTAQUE, 12, 140.0))

func _ready() -> void:
    var id := int(Navegacao.parametro("fase", 1))
    Estilo.aplicar(self, Catalogo.capitulo_da_fase(id))
    set_anchors_preset(Control.PRESET_FULL_RECT)
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

    coluna.add_child(Estilo.legenda(tr("REVELACAO_ROTULO"), 18))
    var nome := Estilo.titulo(puzzle.nome, 46, puzzle.cor.lerp(Color.WHITE, 0.4))
    coluna.add_child(nome)

    var imagem := ImagemPuzzle.new()
    imagem.custom_minimum_size = Vector2(360, 360)
    imagem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    imagem.definir(puzzle)
    coluna.add_child(imagem)
    imagem.animar(1.2)

    coluna.add_child(Estilo.legenda(puzzle.legenda, 19))

    # As estrelas entram uma de cada vez, cada uma com seu som e seu pulso.
    var fileira := HBoxContainer.new()
    fileira.alignment = BoxContainer.ALIGNMENT_CENTER
    fileira.add_theme_constant_override("separation", 10)
    coluna.add_child(fileira)
    var simbolos: Array[Label] = []
    for i in 3:
        var estrela := Estilo.titulo("★" if i < estrelas else "☆", 44,
            Estilo.DESTAQUE if i < estrelas else Estilo.BORDA)
        # Tamanho reservado: sem isso o pulso de cada estrela empurra as
        # vizinhas e a linha inteira dança.
        estrela.custom_minimum_size = Vector2(58, 58)
        estrela.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        estrela.modulate.a = 0.0
        fileira.add_child(estrela)
        simbolos.append(estrela)

    _coreografar(imagem, simbolos, estrelas, puzzle)

    var detalhe := tr("REVELACAO_TEMPO") % Estilo.tempo_texto(tempo)
    if estrelas < 3:
        detalhe += "   ·   " + (tr("REVELACAO_TRES_ESTRELAS") % Estilo.tempo_texto(puzzle.tempo_alvo))
    coluna.add_child(Estilo.legenda(detalhe, 16))

    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_theme_constant_override("separation", 12)
    coluna.add_child(linha)

    var proxima_id := Catalogo.proxima_fase(id)
    if proxima_id > 0 and proxima_id <= Catalogo.fases.size():
        var proxima := Estilo.botao(tr("REVELACAO_PROXIMA"), 220)
        proxima.pressed.connect(func():
            Audio.tocar("clique")
            Navegacao.ir_para("jogo", {"fase": proxima_id}))
        linha.add_child(proxima)
    else:
        linha.add_child(Estilo.titulo(tr("REVELACAO_TUDO"), 22, Estilo.SUCESSO))

    var galeria := Estilo.botao(tr("MENU_GALERIA"), 180)
    galeria.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("galeria"))
    linha.add_child(galeria)

    Juice.entrada(linha, 1.55, 18.0)

    var mapa := Estilo.botao(tr("REVELACAO_MAPA"), 160)
    mapa.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("fases", {"capitulo": Catalogo.capitulo_da_fase(id)}))
    linha.add_child(mapa)
