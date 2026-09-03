extends Node
## Roda o jogo numa tela virtual e salva um PNG — assim dá para conferir
## o visual mesmo sem monitor. Liga em: xvfb-run godot -- --captura

func _ready() -> void:
    _capturar.call_deferred()

func _capturar() -> void:
    var jogo: Node2D = get_parent()
    var jogador: Jogador = jogo.jogador
    jogador.ler_teclado = false
    jogador.global_position = Vector2(175, 200)
    for i in 40:
        await get_tree().physics_frame
    await RenderingServer.frame_post_draw
    var imagem := get_viewport().get_texture().get_image()
    var destino: String = OS.get_environment("CAPTURA_DESTINO")
    if destino == "":
        destino = "user://captura.png"
    imagem.save_png(destino)
    print("captura salva em: ", destino)
    get_tree().quit()
