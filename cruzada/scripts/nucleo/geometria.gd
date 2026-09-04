extends RefCounted
class_name Geometria
## A grade 5×5 e as doze linhas vivas.
##
## A casa é um inteiro de 0 a 24: `casa = fileira * 5 + coluna`, fileira 0 no
## topo, coluna 0 à esquerda. Na tela a fileira é 1..5 e a coluna A..E, então a
## casa central (12) é a **C3** que a pesquisa cita — aquela que recebe 28,6%
## dos posicionamentos quando há um Avesso na mão, contra 4,0% do uniforme.

const LADO := 5
const CASAS := 25
const LINHAS := 12

## 5 fileiras, 5 colunas, 2 diagonais — nesta ordem, que o resto do código usa.
const CELULAS := [
    [0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14],
    [15, 16, 17, 18, 19], [20, 21, 22, 23, 24],
    [0, 5, 10, 15, 20], [1, 6, 11, 16, 21], [2, 7, 12, 17, 22],
    [3, 8, 13, 18, 23], [4, 9, 14, 19, 24],
    [0, 6, 12, 18, 24], [4, 8, 12, 16, 20],
]

const FILEIRA_0 := 0
const COLUNA_0 := 5
const DIAGONAL_0 := 10

const COLUNAS_NA_TELA: PackedStringArray = ["A", "B", "C", "D", "E"]

static func diagonal(linha: int) -> bool:
    return linha >= DIAGONAL_0

## Nome que vai para a tela. Nunca "linha": 12 unidades numa grade 5×5 travou os
## dois leitores cegos do teste de nomes, e a correção foi dizer sempre qual é.
static func nome(linha: int) -> String:
    if linha < COLUNA_0:
        return "fileira %d" % (linha + 1)
    if linha < DIAGONAL_0:
        return "coluna %s" % COLUNAS_NA_TELA[linha - COLUNA_0]
    return "diagonal ↘" if linha == DIAGONAL_0 else "diagonal ↗"

## Nome curto da casa, como o jogador a chama: C3 é o centro.
static func nome_da_casa(casa: int) -> String:
    return "%s%d" % [COLUNAS_NA_TELA[casa % LADO], casa / LADO + 1]

## As linhas que passam por cada casa. Tabela fixa, calculada uma vez: quatro
## casas pertencem a 3 linhas (as pontas), o centro a 4, e o resto a 2.
static var _por_casa: Array = []

static func linhas_da_casa(casa: int) -> Array:
    if _por_casa.is_empty():
        _construir()
    return _por_casa[casa]

static func _construir() -> void:
    _por_casa = []
    for casa in CASAS:
        var lista: Array[int] = []
        for l in LINHAS:
            if CELULAS[l].has(casa):
                lista.append(l)
        _por_casa.append(lista)

static func fileira_da(casa: int) -> int:
    return casa / LADO

static func coluna_da(casa: int) -> int:
    return casa % LADO
