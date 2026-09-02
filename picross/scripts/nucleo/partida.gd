extends RefCounted
class_name Partida
## Estado de uma partida em andamento. Sem nós e sem desenho: dá para simular
## uma partida inteira nos testes, sem abrir janela.

enum Marca { LIMPA, PINTADA, CRUZ }
enum Jogada { NADA, ACERTO, ERRO, ANOTACAO }

const VIDAS_INICIAIS := 3

var puzzle: Puzzle
var marcas: Array[PackedByteArray] = []
var vidas := VIDAS_INICIAIS
var erros := 0
var pintadas_corretas := 0
var tempo := 0.0
var concluida := false
var perdeu := false
var usou_dica := false
var modo_relaxado := false

## Células onde o jogador pintou errado. Só elas podem aparecer em vermelho:
## marcar X é anotação livre e não pode entregar a solução de graça.
var celulas_erradas := {}

var _historico: Array = []   # [x, y, marca_anterior]

func _init(novo_puzzle: Puzzle, relaxado := false) -> void:
    puzzle = novo_puzzle
    modo_relaxado = relaxado
    for y in puzzle.lado:
        var linha := PackedByteArray()
        linha.resize(puzzle.lado)
        marcas.append(linha)

func marca_em(x: int, y: int) -> int:
    return marcas[y][x]

## Clique de pintar. Devolve o que aconteceu, para a interface reagir.
func pintar(x: int, y: int) -> Jogada:
    if concluida or perdeu or not puzzle.dentro(x, y):
        return Jogada.NADA
    if marcas[y][x] == Marca.PINTADA:
        return Jogada.NADA
    _guardar(x, y)
    if puzzle.e_cheia(x, y):
        marcas[y][x] = Marca.PINTADA
        pintadas_corretas += 1
        _checar_vitoria()
        return Jogada.ACERTO
    # Errou: a célula vira anotação de vazia, como manda o gênero.
    marcas[y][x] = Marca.CRUZ
    celulas_erradas[Vector2i(x, y)] = true
    erros += 1
    if not modo_relaxado:
        vidas -= 1
        if vidas <= 0:
            perdeu = true
    return Jogada.ERRO

## Clique direito: anotação de "esta é vazia". Nunca erra, nunca pune.
func alternar_cruz(x: int, y: int) -> Jogada:
    if concluida or perdeu or not puzzle.dentro(x, y):
        return Jogada.NADA
    if marcas[y][x] == Marca.PINTADA:
        return Jogada.NADA
    _guardar(x, y)
    marcas[y][x] = Marca.LIMPA if marcas[y][x] == Marca.CRUZ else Marca.CRUZ
    return Jogada.ANOTACAO

func desfazer() -> bool:
    if _historico.is_empty() or concluida or perdeu:
        return false
    var passo: Array = _historico.pop_back()
    var x: int = passo[0]
    var y: int = passo[1]
    if marcas[y][x] == Marca.PINTADA and passo[2] != Marca.PINTADA:
        pintadas_corretas -= 1
    marcas[y][x] = passo[2]
    celulas_erradas.erase(Vector2i(x, y))
    return true

## Revela uma célula cheia ainda não pintada. Abre mão das 3 estrelas.
func pedir_dica() -> Vector2i:
    if concluida or perdeu:
        return Vector2i(-1, -1)
    for y in puzzle.lado:
        for x in puzzle.lado:
            if puzzle.e_cheia(x, y) and marcas[y][x] != Marca.PINTADA:
                usou_dica = true
                _guardar(x, y)
                marcas[y][x] = Marca.PINTADA
                pintadas_corretas += 1
                _checar_vitoria()
                return Vector2i(x, y)
    return Vector2i(-1, -1)

func avancar_tempo(delta: float) -> void:
    if not concluida and not perdeu:
        tempo += delta

func estrelas() -> int:
    if not concluida:
        return 0
    if erros > 0 or usou_dica:
        return 1
    return 3 if tempo <= puzzle.tempo_alvo else 2

func progresso() -> float:
    return float(pintadas_corretas) / float(puzzle.total_cheias)

func _guardar(x: int, y: int) -> void:
    _historico.append([x, y, marcas[y][x]])
    if _historico.size() > 500:
        _historico.pop_front()

func _checar_vitoria() -> void:
    if pintadas_corretas >= puzzle.total_cheias:
        concluida = true
