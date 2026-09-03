extends Node2D

signal moeda_coletada(total: int)

@onready var jogador: Jogador = $Jogador
@onready var placar: Label = $HUD/Placar

var moedas_restantes: Array[Vector2] = []
var pontos := 0

func _ready() -> void:
    _montar_plataformas()
    moedas_restantes = NivelDados.MOEDAS.duplicate()
    _atualizar_placar()
    var args := OS.get_cmdline_user_args()
    if "--testes" in args:
        add_child(preload("res://tests/roteiro_testes.gd").new())
    elif "--captura" in args:
        add_child(preload("res://tests/captura.gd").new())

func _montar_plataformas() -> void:
    for area in NivelDados.PLATAFORMAS:
        var corpo := StaticBody2D.new()
        corpo.position = area.position + area.size / 2.0
        var forma := RectangleShape2D.new()
        forma.size = area.size
        var colisor := CollisionShape2D.new()
        colisor.shape = forma
        corpo.add_child(colisor)
        add_child(corpo)

func _physics_process(_delta: float) -> void:
    for i in range(moedas_restantes.size() - 1, -1, -1):
        if jogador.global_position.distance_to(moedas_restantes[i]) <= NivelDados.RAIO_COLETA:
            moedas_restantes.remove_at(i)
            pontos += 1
            _atualizar_placar()
            moeda_coletada.emit(pontos)
            queue_redraw()

func _atualizar_placar() -> void:
    if placar:
        placar.text = "Moedas: %d / %d" % [pontos, NivelDados.MOEDAS.size()]

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 640, 360), Color("1c2333"))
    for area in NivelDados.PLATAFORMAS:
        draw_rect(area, Color("3c7a5a"))
        draw_rect(Rect2(area.position, Vector2(area.size.x, 4)), Color("5fbf8c"))
    for pos in moedas_restantes:
        draw_circle(pos, 7.0, Color("f0c040"))
