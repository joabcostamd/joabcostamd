extends Node
## Troca de telas com um escurecer curto no meio, para nada piscar.

const TELAS := {
    "abertura": "res://cenas/abertura.tscn",
    "menu": "res://cenas/menu.tscn",
    "capitulos": "res://cenas/capitulos.tscn",
    "fases": "res://cenas/fases.tscn",
    "jogo": "res://cenas/jogo.tscn",
    "revelacao": "res://cenas/revelacao.tscn",
    "galeria": "res://cenas/galeria.tscn",
    "opcoes": "res://cenas/opcoes.tscn",
    "creditos": "res://cenas/creditos.tscn",
    "conquistas": "res://cenas/conquistas.tscn",
    "estatisticas": "res://cenas/estatisticas.tscn",
}

var parametros := {}
var _cortina: ColorRect
var _trocando := false

func _ready() -> void:
    var camada := CanvasLayer.new()
    camada.layer = 100
    add_child(camada)
    _cortina = ColorRect.new()
    _cortina.color = Color(0.04, 0.05, 0.08, 0.0)
    _cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
    camada.add_child(_cortina)

    _talvez_capturar()
    if "--demonstracao" in OS.get_cmdline_user_args():
        add_child(load("res://testes/demonstracao.gd").new())

## Ferramenta de desenvolvimento: abre uma tela, salva um PNG e sai. Permite
## conferir o visual de todas as telas sem um monitor.
##   godot -- --capturar menu [--demo]
func _talvez_capturar() -> void:
    var args := OS.get_cmdline_user_args()
    var indice := args.find("--capturar")
    if indice < 0 or indice + 1 >= args.size():
        return
    var tela: String = args[indice + 1]
    if "--demo" in args:
        _preencher_progresso_demo()
    if "--claro" in args:
        Progresso.opcoes["tema_claro"] = true
        Progresso.aplicar_aparencia()
    await get_tree().process_frame
    var parametros_da_tela := {}
    match tela:
        "fases": parametros_da_tela = {"capitulo": 1}
        "jogo": parametros_da_tela = {"fase": 26}
        "revelacao": parametros_da_tela = {"fase": 26, "tempo": 214.0, "estrelas": 3}
    ir_para(tela, parametros_da_tela)
    var espera := 2.0
    var quando := args.find("--espera")
    if quando >= 0 and quando + 1 < args.size():
        espera = float(args[quando + 1])
    await get_tree().create_timer(espera).timeout
    await RenderingServer.frame_post_draw
    var destino: String = OS.get_environment("CAPTURA_DESTINO")
    if destino == "":
        destino = "user://%s.png" % tela
    get_viewport().get_texture().get_image().save_png(destino)
    print("captura: ", destino)
    get_tree().quit()

func _preencher_progresso_demo() -> void:
    var estrelas := [3, 2, 3, 1, 3, 3, 2, 3, 3, 2, 3, 1, 2, 3, 3, 2, 3, 3, 1, 2,
                     3, 2, 3, 3, 1, 2, 3]
    for i in estrelas.size():
        var fase := Catalogo.fase(i + 1)
        if fase == null:
            continue
        Progresso.fases[str(i + 1)] = {
            "estrelas": estrelas[i],
            "tempo": fase.tempo_alvo * (0.6 + 0.02 * i),
        }

func ir_para(tela: String, novos_parametros := {}) -> void:
    if _trocando or not TELAS.has(tela):
        return
    _trocando = true
    parametros = novos_parametros
    Audio.tocar("passar", 0.7)

    # A cortina não só escurece: ela desliza de um lado ao outro, o que dá
    # sentido de direção à troca em vez de um simples piscar.
    var largura := float(get_viewport().get_visible_rect().size.x)
    _cortina.position.x = -largura
    _cortina.color.a = 1.0
    var entrada := create_tween()
    entrada.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    entrada.tween_property(_cortina, "position:x", 0.0, 0.20)
    await entrada.finished

    get_tree().change_scene_to_file(TELAS[tela])
    await get_tree().process_frame

    var saida := create_tween()
    saida.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    saida.tween_property(_cortina, "position:x", largura, 0.24)
    await saida.finished
    _cortina.position.x = 0.0
    _cortina.color.a = 0.0
    _trocando = false

func parametro(chave: String, padrao = null):
    return parametros.get(chave, padrao)
