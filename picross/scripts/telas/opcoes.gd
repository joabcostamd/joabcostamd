extends Control

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.alignment = BoxContainer.ALIGNMENT_CENTER
    coluna.add_theme_constant_override("separation", 16)
    add_child(coluna)

    coluna.add_child(Estilo.titulo("Opções", 42))
    coluna.add_child(_espaco(10))

    coluna.add_child(_deslizante("Efeitos sonoros", "volume_efeitos"))
    coluna.add_child(_deslizante("Música", "volume_musica"))
    coluna.add_child(_marcador("Modo relaxado (erros não custam vidas)", "modo_relaxado"))
    coluna.add_child(_marcador("Destacar em vermelho a célula errada", "marcar_erro_automatico"))

    coluna.add_child(_espaco(16))

    var apagar := Estilo.botao("Apagar todo o progresso", 400)
    apagar.pressed.connect(_confirmar_apagar)
    coluna.add_child(apagar)

    var voltar := Estilo.botao("Voltar", 400)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        var destino: String = Navegacao.parametro("volta", "menu")
        if destino == "jogo":
            Navegacao.ir_para("jogo", {"fase": int(Navegacao.parametro("fase", 1))})
        else:
            Navegacao.ir_para("menu"))
    coluna.add_child(voltar)

    coluna.position = (size - coluna.get_combined_minimum_size()) * 0.5
    Juice.entrada(coluna)

func _espaco(altura: int) -> Control:
    var vazio := Control.new()
    vazio.custom_minimum_size.y = altura
    return vazio

func _deslizante(rotulo: String, chave: String) -> Control:
    var linha := HBoxContainer.new()
    linha.custom_minimum_size.x = 560
    linha.add_theme_constant_override("separation", 18)

    var texto := Estilo.legenda(rotulo, 19, Estilo.TEXTO)
    texto.custom_minimum_size.x = 330
    texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    linha.add_child(texto)

    var valor := Estilo.legenda("", 18, Estilo.ACENTO)
    valor.custom_minimum_size.x = 60

    var barra := HSlider.new()
    barra.min_value = 0.0
    barra.max_value = 1.0
    barra.step = 0.05
    barra.value = float(Progresso.opcoes[chave])
    barra.custom_minimum_size.x = 170
    barra.value_changed.connect(func(novo: float):
        Progresso.ajustar(chave, novo)
        valor.text = "%d%%" % int(novo * 100)
        Audio.tocar("cruz"))
    valor.text = "%d%%" % int(barra.value * 100)

    linha.add_child(barra)
    linha.add_child(valor)
    return linha

func _marcador(rotulo: String, chave: String) -> Control:
    var caixa := CheckBox.new()
    caixa.text = "  " + rotulo
    caixa.button_pressed = bool(Progresso.opcoes[chave])
    caixa.custom_minimum_size.x = 560
    caixa.add_theme_font_size_override("font_size", 19)
    caixa.toggled.connect(func(ligado: bool):
        Progresso.ajustar(chave, ligado)
        Audio.tocar("clique"))
    return caixa

func _confirmar_apagar() -> void:
    Audio.tocar("clique")
    var dialogo := ConfirmationDialog.new()
    dialogo.title = "Apagar progresso"
    dialogo.dialog_text = "Isto apaga as %d fases resolvidas e esvazia a galeria.\nNão dá para desfazer." % Progresso.total_resolvidas()
    dialogo.ok_button_text = "Apagar"
    dialogo.cancel_button_text = "Cancelar"
    dialogo.confirmed.connect(func():
        Progresso.apagar_tudo()
        Audio.tocar("derrota")
        Navegacao.ir_para("menu"))
    add_child(dialogo)
    dialogo.popup_centered()
