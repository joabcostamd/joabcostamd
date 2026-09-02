extends Node

func _ready() -> void:
    _capturar.call_deferred()

func _capturar() -> void:
    for i in 5:
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var destino: String = OS.get_environment("CAPTURA_DESTINO")
    if destino == "":
        destino = "user://captura.png"
    get_viewport().get_texture().get_image().save_png(destino)
    print("captura salva em: ", destino)
    get_tree().quit()
