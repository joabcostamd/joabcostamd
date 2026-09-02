extends Node
## Carrega as fases de dados/puzzles.json na inicialização.

const CAMINHO := "res://dados/puzzles.json"

var capitulos: Array = []
var fases: Array[Puzzle] = []

func _ready() -> void:
    carregar()

func carregar() -> void:
    var arquivo := FileAccess.open(CAMINHO, FileAccess.READ)
    if arquivo == null:
        push_error("Não foi possível abrir %s" % CAMINHO)
        return
    var dados: Dictionary = JSON.parse_string(arquivo.get_as_text())
    arquivo.close()
    capitulos = dados["capitulos"]
    fases.clear()
    for d in dados["fases"]:
        fases.append(Puzzle.do_dicionario(d))

func fase(id: int) -> Puzzle:
    for p in fases:
        if p.id == id:
            return p
    return null

func capitulo_da_fase(id: int) -> int:
    for i in capitulos.size():
        if id in capitulos[i]["fases"]:
            return i
    return 0

func proxima_fase(id: int) -> int:
    return id + 1 if id < fases.size() else -1
