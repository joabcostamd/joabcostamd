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
}

var parametros := {}
var _cortina: ColorRect
var _trocando := false

func _ready() -> void:
    var camada := CanvasLayer.new()
    camada.layer = 100
    add_child(camada)
    _cortina = ColorRect.new()
    _cortina.color = Color(0.05, 0.06, 0.09, 0.0)
    _cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
    camada.add_child(_cortina)

func ir_para(tela: String, novos_parametros := {}) -> void:
    if _trocando or not TELAS.has(tela):
        return
    _trocando = true
    parametros = novos_parametros
    var animacao := create_tween()
    animacao.tween_property(_cortina, "color:a", 1.0, 0.16)
    await animacao.finished
    get_tree().change_scene_to_file(TELAS[tela])
    await get_tree().process_frame
    var volta := create_tween()
    volta.tween_property(_cortina, "color:a", 0.0, 0.16)
    await volta.finished
    _trocando = false

func parametro(chave: String, padrao = null):
    return parametros.get(chave, padrao)
