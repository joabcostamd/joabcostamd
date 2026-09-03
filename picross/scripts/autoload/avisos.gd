extends Node
## Cartões que entram por cima do jogo — hoje, as conquistas desbloqueadas.
##
## Vive num autoload com camada própria para sobreviver à troca de tela: a
## conquista costuma cair no momento em que o jogo vai da partida para a
## revelação, e um aviso preso à tela antiga morreria no meio.

const DURACAO := 3.4

var _camada: CanvasLayer
var _fila: Array[Dictionary] = []
var _mostrando := false

func _ready() -> void:
    _camada = CanvasLayer.new()
    _camada.layer = 80
    add_child(_camada)
    Progresso.conquista_desbloqueada.connect(_enfileirar)

func _enfileirar(nome: String, descricao: String) -> void:
    _fila.append({"nome": nome, "descricao": descricao})
    if not _mostrando:
        _mostrar_proximo()

func _mostrar_proximo() -> void:
    if _fila.is_empty():
        _mostrando = false
        return
    _mostrando = true
    var dados: Dictionary = _fila.pop_front()

    var cartao := PanelContainer.new()
    cartao.theme = Estilo.tema()
    cartao.custom_minimum_size = Vector2(400, 84)
    var tela := Vector2(1280, 720)
    if _camada.get_viewport() != null:
        tela = _camada.get_viewport().get_visible_rect().size
    cartao.position = Vector2(tela.x - 430, -100)
    _camada.add_child(cartao)

    var linha := HBoxContainer.new()
    linha.add_theme_constant_override("separation", 14)
    cartao.add_child(linha)

    var marca := Estilo.titulo("★", 34, Estilo.DESTAQUE)
    marca.custom_minimum_size.x = 46
    marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    linha.add_child(marca)

    var texto := VBoxContainer.new()
    texto.alignment = BoxContainer.ALIGNMENT_CENTER
    texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var titulo := Estilo.legenda(tr("CONQ_DESBLOQUEADA"), 14, Estilo.ACENTO)
    titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var nome := Estilo.legenda(dados["nome"], 19, Estilo.TEXTO)
    nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    texto.add_child(titulo)
    texto.add_child(nome)
    linha.add_child(texto)

    Audio.tocar("estrela", 1.25)
    var animacao := cartao.create_tween()
    animacao.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    animacao.tween_property(cartao, "position:y", 22.0, 0.45)
    animacao.tween_interval(DURACAO)
    animacao.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    animacao.tween_property(cartao, "position:y", -120.0, 0.35)
    animacao.tween_callback(cartao.queue_free)
    animacao.tween_callback(_mostrar_proximo)
