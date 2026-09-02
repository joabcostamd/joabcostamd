extends RefCounted
class_name Puzzle
## Um puzzle carregado dos dados. Só leitura — quem muda é a Partida.

var id := 0
var nome := ""
var legenda := ""
var cor := Color.WHITE
var lado := 5
var solucao: Array[PackedByteArray] = []   # 1 = célula cheia
var pistas_linhas: Array = []
var pistas_colunas: Array = []
var dificuldade := 0.0
var tempo_alvo := 60
var total_cheias := 0

static func do_dicionario(d: Dictionary) -> Puzzle:
    var p := Puzzle.new()
    p.id = int(d["id"])
    p.nome = d["nome"]
    p.legenda = d["legenda"]
    p.cor = Color(d["cor"])
    p.lado = int(d["lado"])
    p.dificuldade = float(d["dificuldade"])
    p.tempo_alvo = int(d["tempo_alvo"])
    for linha in d["solucao"]:
        var bytes := PackedByteArray()
        for caractere in (linha as String):
            var cheia := 1 if caractere == "#" else 0
            bytes.append(cheia)
            p.total_cheias += cheia
        p.solucao.append(bytes)
    p.pistas_linhas = d["pistas_linhas"]
    p.pistas_colunas = d["pistas_colunas"]
    return p

func e_cheia(x: int, y: int) -> bool:
    return solucao[y][x] == 1

func dentro(x: int, y: int) -> bool:
    return x >= 0 and y >= 0 and x < lado and y < lado
