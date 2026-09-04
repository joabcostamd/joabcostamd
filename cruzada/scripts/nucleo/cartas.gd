extends RefCounted
class_name Cartas
## A carta é um inteiro de 0 a 51. Nada de objeto, nada de dicionário.
##
##     naipe  = carta / 13     0 copas · 1 ouros · 2 paus · 3 espadas
##     indice = carta % 13     0 Ás · 1..8 = 2..9 · 9 = 10 · 10 J · 11 Q · 12 K
##
## O índice começa no Ás porque é assim que a sequência A-2-3-4-5 fica contígua
## na máscara de bits do avaliador. Para desenhar, `Carta` usa 1..13 — a
## conversão mora em `figura()` e em lugar nenhum mais.

const TAMANHO := 52
const VALORES := 13
const NAIPES := 4

const COPAS := 0
const OUROS := 1
const PAUS := 2
const ESPADAS := 3

## Ordem alta do pôquer, para leitura humana e desempate: o Ás é o maior.
const NOMES: PackedStringArray = ["A", "2", "3", "4", "5", "6", "7", "8", "9",
                                  "10", "J", "Q", "K"]
const NOMES_NAIPE: PackedStringArray = ["copas", "ouros", "paus", "espadas"]

static func naipe(carta: int) -> int:
    return carta / 13

static func indice(carta: int) -> int:
    return carta % 13

## O número que `Carta.desenhar` espera: 1 = Ás, 2..10, 11 = J, 12 = Q, 13 = K.
static func figura(carta: int) -> int:
    return carta % 13 + 1

## R05 — 2 a 10 valem a face, J/Q/K valem 10, Ás vale 11.
static func fichas(carta: int) -> int:
    var v := carta % 13
    if v == 0:
        return 11
    if v <= 9:
        return v + 1
    return 10

static func nome(carta: int) -> String:
    return NOMES[carta % 13] + " de " + NOMES_NAIPE[carta / 13]

## Um baralho de 52 na ordem canônica. Quem embaralha é a mesa, com semente.
static func baralho() -> Array[int]:
    var b: Array[int] = []
    b.resize(TAMANHO)
    for i in TAMANHO:
        b[i] = i
    return b
