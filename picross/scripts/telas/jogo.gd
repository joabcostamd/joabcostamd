extends Control
## A tela onde se joga. HUD em cima, tabuleiro no meio, ferramentas embaixo.

var partida: Partida
var grade: GradeJogo
var _rotulo_tempo: Label
var _rotulo_vidas: Label
var _rotulo_progresso: Label
var _pausa: Control
var _derrota: Control
var _barra: ProgressBar

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var id := int(Navegacao.parametro("fase", 1))
    var puzzle := Catalogo.fase(id)
    if puzzle == null:
        Navegacao.ir_para("menu")
        return
    partida = Partida.new(puzzle, bool(Progresso.opcoes["modo_relaxado"]))

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 40
    coluna.offset_right = -40
    coluna.offset_top = 20
    coluna.offset_bottom = -20
    coluna.add_theme_constant_override("separation", 10)
    add_child(coluna)

    coluna.add_child(_montar_hud(puzzle))

    grade = GradeJogo.new()
    grade.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grade.mostrar_erros = bool(Progresso.opcoes["marcar_erro_automatico"])
    grade.jogada_feita.connect(_ao_jogar)
    grade.linha_fechada.connect(_ao_fechar_linha)
    coluna.add_child(grade)
    grade.definir_partida(partida)

    coluna.add_child(_montar_ferramentas())

    _pausa = _montar_pausa()
    add_child(_pausa)
    _derrota = _montar_derrota()
    add_child(_derrota)

    if "--demo" in OS.get_cmdline_user_args():
        _preencher_demo()

    set_process(true)
    _atualizar_hud()

## Só para as capturas de desenvolvimento: deixa a partida pela metade.
func _preencher_demo() -> void:
    var contador := 0
    for y in partida.puzzle.lado:
        for x in partida.puzzle.lado:
            if partida.puzzle.e_cheia(x, y):
                contador += 1
                if contador % 3 != 0:
                    partida.pintar(x, y)
            elif (x * 7 + y * 3) % 11 == 0:
                partida.alternar_cruz(x, y)
    partida.tempo = 128.0
    grade.queue_redraw()

func _montar_hud(puzzle: Puzzle) -> Control:
    var barra := HBoxContainer.new()
    barra.add_theme_constant_override("separation", 24)
    barra.custom_minimum_size.y = 44

    var titulo := Estilo.titulo("Fase %d  ·  %d×%d" % [puzzle.id, puzzle.lado, puzzle.lado], 24)
    titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    barra.add_child(titulo)

    _rotulo_progresso = Estilo.legenda("", 20)
    barra.add_child(_rotulo_progresso)

    _barra = ProgressBar.new()
    _barra.custom_minimum_size = Vector2(180, 12)
    _barra.show_percentage = false
    _barra.max_value = 1.0
    _barra.value = 0.0
    var fundo_barra := StyleBoxFlat.new()
    fundo_barra.bg_color = Estilo.CELULA_VAZIA
    fundo_barra.set_corner_radius_all(6)
    var cheia_barra := StyleBoxFlat.new()
    cheia_barra.bg_color = Estilo.ACENTO
    cheia_barra.set_corner_radius_all(6)
    _barra.add_theme_stylebox_override("background", fundo_barra)
    _barra.add_theme_stylebox_override("fill", cheia_barra)
    var caixa_barra := VBoxContainer.new()
    caixa_barra.alignment = BoxContainer.ALIGNMENT_CENTER
    caixa_barra.add_child(_barra)
    barra.add_child(caixa_barra)

    _rotulo_vidas = Estilo.titulo("", 22, Estilo.ERRO)
    barra.add_child(_rotulo_vidas)

    _rotulo_tempo = Estilo.titulo("0:00", 22, Estilo.ACENTO)
    _rotulo_tempo.custom_minimum_size.x = 90
    barra.add_child(_rotulo_tempo)

    var pausar := Estilo.botao("Pausa", 120)
    pausar.pressed.connect(_abrir_pausa)
    barra.add_child(pausar)
    return barra

func _montar_ferramentas() -> Control:
    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_theme_constant_override("separation", 14)
    linha.custom_minimum_size.y = 56

    var desfazer := Estilo.botao("Desfazer  (Z)", 200)
    desfazer.pressed.connect(_desfazer)
    linha.add_child(desfazer)

    var dica := Estilo.botao("Dica  (H)", 170)
    dica.tooltip_text = "Revela uma célula. Abre mão das 3 estrelas."
    dica.pressed.connect(_dica)
    linha.add_child(dica)

    var ajuda := Estilo.legenda("botão esquerdo pinta  ·  botão direito marca X  ·  arraste preenche em linha", 15)
    linha.add_child(ajuda)
    return linha

func _process(delta: float) -> void:
    if partida == null or _pausa.visible:
        return
    partida.avancar_tempo(delta)
    _rotulo_tempo.text = Estilo.tempo_texto(partida.tempo)

func _unhandled_key_input(evento: InputEvent) -> void:
    if not (evento is InputEventKey) or not evento.pressed or evento.echo:
        return
    match (evento as InputEventKey).keycode:
        KEY_ESCAPE:
            if _pausa.visible:
                _fechar_pausa()
            else:
                _abrir_pausa()
        KEY_Z: _desfazer()
        KEY_H: _dica()

func _ao_jogar(tipo: int, _celula: Vector2i) -> void:
    match tipo:
        Partida.Jogada.ACERTO:
            # Cada acerto seguido sobe meio tom: a sequência vira uma escada.
            var passo: int = mini(grade.sequencia(), 12)
            Audio.tocar("pintar", 1.0 + passo * 0.045)
        Partida.Jogada.ERRO:
            Audio.tocar("erro")
            Juice.tremer(grade, 11.0, 0.32)
            Juice.clarao(self, Estilo.ERRO, 0.16, 0.35)
            Juice.pulsar(_rotulo_vidas, 1.45, 0.35)
        Partida.Jogada.ANOTACAO:
            Audio.tocar("cruz")
    _atualizar_hud()
    if partida.concluida:
        _vencer()
    elif partida.perdeu:
        _perder()

## Chamada quando uma linha ou coluna fecha por inteiro.
func _ao_fechar_linha(_indice: int, _horizontal: bool) -> void:
    Audio.tocar("linha", randf_range(0.97, 1.06))

func _atualizar_hud() -> void:
    _rotulo_progresso.text = "%d%%" % int(partida.progresso() * 100.0)
    if _barra != null:
        var animacao := create_tween()
        animacao.tween_property(_barra, "value", partida.progresso(), 0.22) \
            .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    if partida.modo_relaxado:
        _rotulo_vidas.text = "modo relaxado"
        _rotulo_vidas.add_theme_color_override("font_color", Estilo.SUCESSO)
    else:
        _rotulo_vidas.text = "♥".repeat(maxi(partida.vidas, 0)) + "·".repeat(maxi(3 - partida.vidas, 0))

func _desfazer() -> void:
    if partida.desfazer():
        Audio.tocar("cruz")
        grade.queue_redraw()
        _atualizar_hud()

func _dica() -> void:
    var celula := partida.pedir_dica()
    if celula.x >= 0:
        Audio.tocar("estrela")
        grade.queue_redraw()
        _atualizar_hud()
        if partida.concluida:
            _vencer()

func _vencer() -> void:
    Audio.tocar("vitoria")
    Juice.clarao(self, Estilo.DESTAQUE, 0.42, 0.6)
    var camada := Juice.camada_particulas(self)
    if camada != null:
        camada.confete(size.x, [Estilo.DESTAQUE, Estilo.ACENTO, Estilo.SUCESSO,
                                partida.puzzle.cor], 70)
    Progresso.registrar(partida.puzzle.id, partida.estrelas(), partida.tempo)
    await get_tree().create_timer(0.45).timeout
    Navegacao.ir_para("revelacao", {
        "fase": partida.puzzle.id,
        "tempo": partida.tempo,
        "estrelas": partida.estrelas(),
        "erros": partida.erros,
    })

func _perder() -> void:
    Audio.tocar("derrota")
    _derrota.visible = true

func _abrir_pausa() -> void:
    Audio.tocar("clique")
    _pausa.visible = true
    Juice.entrada(_pausa, 0.0, 14.0)

func _fechar_pausa() -> void:
    Audio.tocar("clique")
    _pausa.visible = false

func _montar_pausa() -> Control:
    return _montar_sobreposicao("Pausa", "", [
        ["Continuar", func(): _fechar_pausa()],
        ["Reiniciar fase", func(): Navegacao.ir_para("jogo", {"fase": partida.puzzle.id})],
        ["Opções", func(): Navegacao.ir_para("opcoes", {"volta": "jogo", "fase": partida.puzzle.id})],
        ["Sair para o mapa", func(): Navegacao.ir_para("fases",
            {"capitulo": Catalogo.capitulo_da_fase(partida.puzzle.id)})],
    ])

func _montar_derrota() -> Control:
    return _montar_sobreposicao("Acabaram as vidas",
        "Três erros encerram a partida. O modo relaxado, nas opções, tira esse limite.", [
        ["Tentar de novo", func(): Navegacao.ir_para("jogo", {"fase": partida.puzzle.id})],
        ["Sair para o mapa", func(): Navegacao.ir_para("fases",
            {"capitulo": Catalogo.capitulo_da_fase(partida.puzzle.id)})],
    ])

func _montar_sobreposicao(titulo: String, texto: String, acoes: Array) -> Control:
    var camada := Control.new()
    camada.set_anchors_preset(Control.PRESET_FULL_RECT)
    camada.visible = false

    var escuro := ColorRect.new()
    escuro.color = Color(0.02, 0.03, 0.05, 0.86)
    escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
    camada.add_child(escuro)

    var coluna := VBoxContainer.new()
    coluna.alignment = BoxContainer.ALIGNMENT_CENTER
    coluna.add_theme_constant_override("separation", 14)
    coluna.set_anchors_preset(Control.PRESET_CENTER)
    camada.add_child(coluna)

    coluna.add_child(Estilo.titulo(titulo, 40))
    if texto != "":
        var explicacao := Estilo.legenda(texto, 17)
        explicacao.custom_minimum_size.x = 520
        explicacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        coluna.add_child(explicacao)
    for acao in acoes:
        var botao := Estilo.botao(acao[0])
        botao.pressed.connect(func():
            Audio.tocar("clique")
            (acao[1] as Callable).call())
        coluna.add_child(botao)

    coluna.position = (size - coluna.get_combined_minimum_size()) * 0.5
    return camada
