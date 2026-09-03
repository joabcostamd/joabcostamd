extends RefCounted
class_name Juice
## As reações que fazem a interface parecer viva: botões que respondem ao
## toque, tremidas, pulsos e o atalho para pedir partículas.

const ESCALA_HOVER := 1.035
const ESCALA_CLIQUE := 0.965

## Passa a equipar todo botão desta tela — inclusive os criados depois, como
## os de uma sobreposição de pausa.
static func observar(raiz: Control) -> void:
    _equipar_arvore(raiz)
    # Carregado assim, e não pelo nome de classe, porque o equipador também
    # depende do Juice — o nome direto criaria um ciclo na compilação.
    var equipador: Node = load("res://scripts/ui/equipador.gd").new()
    equipador.raiz = raiz
    raiz.add_child(equipador)

static func _equipar_arvore(no: Node) -> void:
    if no is BaseButton:
        equipar(no as BaseButton)
    for filho in no.get_children():
        _equipar_arvore(filho)

## Cresce ao passar o mouse, afunda ao apertar, e avisa com um som curto.
static func equipar(botao: BaseButton) -> void:
    if botao.has_meta("com_juice"):
        return
    botao.set_meta("com_juice", true)
    botao.pivot_offset = botao.size * 0.5
    botao.resized.connect(func(): botao.pivot_offset = botao.size * 0.5)

    botao.mouse_entered.connect(func():
        if botao.disabled:
            return
        Audio.tocar("passar")
        _escalar(botao, ESCALA_HOVER, 0.12))
    botao.mouse_exited.connect(func(): _escalar(botao, 1.0, 0.16))
    botao.button_down.connect(func():
        if not botao.disabled:
            _escalar(botao, ESCALA_CLIQUE, 0.06))
    botao.button_up.connect(func(): _escalar(botao, 1.0, 0.14))

static func _escalar(no: Control, alvo: float, duracao: float) -> void:
    if not is_instance_valid(no):
        return
    var animacao := no.create_tween()
    animacao.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    animacao.tween_property(no, "scale", Vector2(alvo, alvo), duracao)

## Entrada de tela: o conteúdo ganha nitidez e cresce até o tamanho normal.
##
## De propósito não mexe em `position`: quase todo conteúdo aqui vive dentro
## de um container, que posiciona os filhos só no fim do quadro. Animar a
## posição a partir do valor lido agora joga o conteúdo para o canto da tela.
static func entrada(no: Control, atraso := 0.0, _deslocamento := 0.0) -> void:
    no.modulate.a = 0.0
    no.scale = Vector2(0.97, 0.97)
    no.pivot_offset = no.size * 0.5
    no.resized.connect(func():
        if is_instance_valid(no):
            no.pivot_offset = no.size * 0.5)
    var animacao := no.create_tween().set_parallel(true)
    animacao.tween_property(no, "modulate:a", 1.0, 0.34).set_delay(atraso)
    animacao.tween_property(no, "scale", Vector2.ONE, 0.42).set_delay(atraso) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Sacode um nó — usada quando o jogador erra.
static func tremer(no: Control, intensidade := 9.0, duracao := 0.3) -> void:
    if not is_instance_valid(no):
        return
    var origem := no.position
    var animacao := no.create_tween()
    var passos := 7
    for i in passos:
        var restante := 1.0 - float(i) / float(passos)
        var desvio := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * intensidade * restante
        animacao.tween_property(no, "position", origem + desvio, duracao / passos)
    animacao.tween_property(no, "position", origem, duracao / passos)

## Um pulso de escala, para chamar atenção sem gritar.
static func pulsar(no: Control, forca := 1.18, duracao := 0.26) -> void:
    if not is_instance_valid(no):
        return
    no.pivot_offset = no.size * 0.5
    var animacao := no.create_tween()
    animacao.tween_property(no, "scale", Vector2(forca, forca), duracao * 0.35) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    animacao.tween_property(no, "scale", Vector2.ONE, duracao * 0.65) \
        .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Clarão branco cobrindo a tela, que some sozinho.
static func clarao(raiz: Control, cor := Color.WHITE, forca := 0.5, duracao := 0.45) -> void:
    var brilho := ColorRect.new()
    brilho.color = Color(cor, forca)
    brilho.set_anchors_preset(Control.PRESET_FULL_RECT)
    brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
    brilho.z_index = 90
    raiz.add_child(brilho)
    var animacao := brilho.create_tween()
    animacao.tween_property(brilho, "color:a", 0.0, duracao)
    animacao.tween_callback(brilho.queue_free)

static func camada_particulas(no: Node) -> CamadaParticulas:
    var arvore := no.get_tree()
    if arvore == null:
        return null
    var achadas := arvore.get_nodes_in_group(CamadaParticulas.GRUPO)
    return achadas[0] if not achadas.is_empty() else null

static func faiscas(no: Node, posicao: Vector2, cor: Color, quantidade := 8,
                    forca := 130.0) -> void:
    var camada := camada_particulas(no)
    if camada != null:
        camada.jato(posicao, cor, quantidade, forca)
