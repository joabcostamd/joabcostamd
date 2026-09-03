extends Control
## Configurações, em seções. Inclui as opções de acessibilidade que a pesquisa
## sobre o gênero apontou como as mais pedidas: tema claro, alto contraste e
## poder desligar o fundo animado.

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 180
    coluna.offset_right = -180
    coluna.offset_top = 24
    coluna.offset_bottom = -20
    coluna.add_theme_constant_override("separation", 8)
    add_child(coluna)

    coluna.add_child(Estilo.titulo("Opções", 38))

    var rolagem := ScrollContainer.new()
    rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    coluna.add_child(rolagem)

    var lista := VBoxContainer.new()
    lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    lista.add_theme_constant_override("separation", 6)
    rolagem.add_child(lista)

    lista.add_child(_secao("Aparência"))
    lista.add_child(_marcador("Tema claro", "tema_claro",
        "Inverte a paleta inteira, inclusive as células."))
    lista.add_child(_marcador("Alto contraste", "alto_contraste",
        "Cores mais separadas, para leitura mais fácil."))
    lista.add_child(_marcador("Fundo animado", "fundo_animado",
        "Desligue se o movimento incomodar."))

    lista.add_child(_secao("Jogo"))
    lista.add_child(_marcador("Modo relaxado", "modo_relaxado",
        "Erros não custam vidas."))
    lista.add_child(_marcador("Destacar a célula errada", "marcar_erro_automatico",
        "Marca em vermelho onde você pintou errado."))
    lista.add_child(_marcador("Arraste em linha reta", "travar_arraste",
        "Ao arrastar, o preenchimento trava no eixo puxado."))
    lista.add_child(_marcador("Mostrar o tempo", "mostrar_tempo",
        "Esconda se preferir jogar sem relógio."))

    lista.add_child(_secao("Som"))
    lista.add_child(_deslizante("Efeitos sonoros", "volume_efeitos"))
    lista.add_child(_deslizante("Música", "volume_musica"))

    lista.add_child(_secao("Dados"))
    var apagar := Estilo.botao("Apagar todo o progresso", 420)
    apagar.pressed.connect(_confirmar_apagar)
    lista.add_child(apagar)

    var voltar := Estilo.botao("Voltar", 300)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        var destino: String = Navegacao.parametro("volta", "menu")
        if destino == "jogo":
            Navegacao.ir_para("jogo", {"fase": int(Navegacao.parametro("fase", 1))})
        else:
            Navegacao.ir_para("menu"))
    var rodape := HBoxContainer.new()
    rodape.alignment = BoxContainer.ALIGNMENT_CENTER
    rodape.add_child(voltar)
    coluna.add_child(rodape)

    Juice.entrada(coluna)

func _secao(titulo: String) -> Control:
    var caixa := VBoxContainer.new()
    var espaco := Control.new()
    espaco.custom_minimum_size.y = 12
    caixa.add_child(espaco)
    var rotulo := Estilo.titulo(titulo, 22, Estilo.ACENTO)
    rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    caixa.add_child(rotulo)
    var risco := ColorRect.new()
    risco.color = Estilo.BORDA
    risco.custom_minimum_size.y = 2
    caixa.add_child(risco)
    return caixa

func _deslizante(rotulo: String, chave: String) -> Control:
    var linha := HBoxContainer.new()
    linha.add_theme_constant_override("separation", 16)
    linha.custom_minimum_size.y = 44

    var texto := Estilo.legenda(rotulo, 19, Estilo.TEXTO)
    texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    linha.add_child(texto)

    var valor := Estilo.legenda("", 18, Estilo.ACENTO)
    valor.custom_minimum_size.x = 64

    var barra := HSlider.new()
    barra.min_value = 0.0
    barra.max_value = 1.0
    barra.step = 0.05
    barra.value = float(Progresso.opcoes[chave])
    barra.custom_minimum_size.x = 220
    barra.value_changed.connect(func(novo: float):
        Progresso.ajustar(chave, novo)
        valor.text = "%d%%" % int(novo * 100)
        Audio.tocar("cruz"))
    valor.text = "%d%%" % int(barra.value * 100)

    linha.add_child(barra)
    linha.add_child(valor)
    return linha

## Cada opção mostra também o que ela faz — sem isso o jogador tem de adivinhar.
func _marcador(rotulo: String, chave: String, explicacao: String) -> Control:
    var caixa := CheckBox.new()
    caixa.button_pressed = bool(Progresso.opcoes[chave])
    caixa.add_theme_font_size_override("font_size", 19)
    caixa.custom_minimum_size = Vector2(0, 58)
    caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var texto := VBoxContainer.new()
    texto.set_anchors_preset(Control.PRESET_FULL_RECT)
    texto.offset_left = 46
    texto.alignment = BoxContainer.ALIGNMENT_CENTER
    texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
    texto.add_theme_constant_override("separation", 0)
    var titulo := Estilo.legenda(rotulo, 19, Estilo.TEXTO)
    titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var detalhe := Estilo.legenda(explicacao, 15)
    detalhe.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    texto.add_child(titulo)
    texto.add_child(detalhe)
    caixa.add_child(texto)

    caixa.toggled.connect(func(ligado: bool):
        Progresso.ajustar(chave, ligado)
        Audio.tocar("clique")
        # Aparência muda a paleta inteira: a tela é remontada para aplicá-la.
        if chave in ["tema_claro", "alto_contraste", "fundo_animado"]:
            Navegacao.ir_para("opcoes", Navegacao.parametros))
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
