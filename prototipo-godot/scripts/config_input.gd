extends Node
## Registra as ações de input por código, para o projeto não depender
## de um InputMap salvo no project.godot (mais fácil de versionar e revisar).

func _ready() -> void:
    _acao("mover_esquerda", [KEY_LEFT, KEY_A])
    _acao("mover_direita", [KEY_RIGHT, KEY_D])
    _acao("pular", [KEY_SPACE, KEY_W, KEY_UP])

func _acao(nome: String, teclas: Array) -> void:
    if InputMap.has_action(nome):
        return
    InputMap.add_action(nome)
    for tecla in teclas:
        var evento := InputEventKey.new()
        evento.physical_keycode = tecla
        InputMap.action_add_event(nome, evento)
