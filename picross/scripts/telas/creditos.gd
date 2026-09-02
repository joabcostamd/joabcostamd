extends Control

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.alignment = BoxContainer.ALIGNMENT_CENTER
    coluna.add_theme_constant_override("separation", 10)
    add_child(coluna)

    coluna.add_child(Estilo.titulo("REVELAR", 48, Estilo.DESTAQUE))
    coluna.add_child(Estilo.legenda("um jogo de picross", 20))
    coluna.add_child(_linha(24))

    for texto in [
        "50 fases desenhadas à mão, em quatro capítulos",
        "todas com solução única, garantida por um solucionador",
        "a dificuldade de cada fase foi medida, não estimada",
        "efeitos e trilha sintetizados por código, sem arquivos de áudio",
        "feito em Godot 4.6",
    ]:
        coluna.add_child(Estilo.legenda(texto, 18))

    coluna.add_child(_linha(28))
    coluna.add_child(Estilo.legenda("Joab Costa   ·   desenvolvido com Claude Code", 18, Estilo.TEXTO))
    coluna.add_child(_linha(28))

    var voltar := Estilo.botao("Voltar", 240)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("menu"))
    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_child(voltar)
    coluna.add_child(linha)

    coluna.position = (size - coluna.get_combined_minimum_size()) * 0.5
    Juice.entrada(coluna)

func _linha(altura: int) -> Control:
    var vazio := Control.new()
    vazio.custom_minimum_size.y = altura
    return vazio
