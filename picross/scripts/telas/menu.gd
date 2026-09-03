extends Control

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_CENTER)
    coluna.alignment = BoxContainer.ALIGNMENT_CENTER
    coluna.add_theme_constant_override("separation", 14)
    add_child(coluna)

    coluna.add_child(Estilo.titulo("REVELAR", 64, Estilo.DESTAQUE))
    coluna.add_child(Estilo.legenda("resolva o enigma, revele a imagem", 19))
    coluna.add_child(_espaco(28))

    var pendente := _primeira_pendente()
    if Progresso.total_resolvidas() > 0 and pendente > 0:
        var continuar := Estilo.botao("Continuar  ·  fase %d" % pendente)
        continuar.pressed.connect(func():
            Audio.tocar("clique")
            Navegacao.ir_para("jogo", {"fase": pendente}))
        coluna.add_child(continuar)

    for item in [["Jogar", "capitulos"], ["Galeria", "galeria"],
                 ["Conquistas", "conquistas"], ["Seus números", "estatisticas"],
                 ["Opções", "opcoes"], ["Créditos", "creditos"]]:
        var botao := Estilo.botao(item[0])
        botao.pressed.connect(func():
            Audio.tocar("clique")
            Navegacao.ir_para(item[1]))
        coluna.add_child(botao)

    var sair := Estilo.botao("Sair")
    sair.pressed.connect(func():
        Audio.tocar("clique")
        get_tree().quit())
    coluna.add_child(sair)

    coluna.add_child(_espaco(22))
    var total := Catalogo.fases.size()
    coluna.add_child(Estilo.legenda(
        "%d de %d imagens reveladas   ·   %d estrelas" %
        [Progresso.total_resolvidas(), total, Progresso.total_estrelas()], 17))

    # Centraliza a coluna inteira sem depender de âncoras frágeis.
    coluna.position = (size - coluna.get_combined_minimum_size()) * 0.5
    Juice.entrada(coluna)

## Primeira fase aberta que ainda não foi resolvida.
func _primeira_pendente() -> int:
    for p in Catalogo.fases:
        if Progresso.desbloqueada(p.id) and not Progresso.resolvida(p.id):
            return p.id
    return -1

func _espaco(altura: int) -> Control:
    var vazio := Control.new()
    vazio.custom_minimum_size.y = altura
    return vazio
