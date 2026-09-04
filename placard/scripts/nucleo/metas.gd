extends RefCounted
class_name Metas
## A curva de metas, o orçamento de posicionamentos e o de descartes.
##
## DESIGN R18. A curva é calculada pela fórmula, não digitada: uma tabela
## materializada é uma tabela que sai de sincronia com a fórmula um dia.

const PEQUENA := 0
const GRANDE := 1
const CHEFE := 2
const TIPOS := 3
const RODADAS := 6

const NOMES: PackedStringArray = ["Pequena", "Grande", "Chefe"]

## O 2.178 é `450 × 4,84`, e o 4,84 é a constante calibrada até a razão
## pontos/meta voltar a 0,79 com a Janela da Colheita e a BC_rec ligadas.
## Ela NÃO é um dial de dificuldade — é o resultado de uma calibragem, e mexer
## nela sem remedir invalida todas as bandas do DESIGN §9.
const BASE := 2178
const RAZAO := 1.42
const FATOR_GRANDE := 1.50
const FATOR_CHEFE := 2.30

## DESIGN R06.
const POSICIONAMENTOS: PackedInt32Array = [15, 17, 19]
const DESCARTES: PackedInt32Array = [2, 3, 3]

## DESIGN R13, R19 e R14.
const PARCELA := 0.35
const FECHO := 0.50
const TEAR_INICIAL := 1
const TEAR_TETO := 8
const TEAR_POR_TIQUE := 4

const MAO_INICIAL := 5

## A meta de uma mesa. `rodada` é 1..6.
static func meta(tipo: int, rodada: int) -> int:
    var pequena := _arredondar(float(BASE) * pow(RAZAO, rodada - 1))
    match tipo:
        GRANDE:
            return _arredondar(float(pequena) * FATOR_GRANDE)
        CHEFE:
            return _arredondar(float(pequena) * FATOR_CHEFE)
        _:
            return pequena

## Meio-para-cima, explícito. `round()` do GDScript já faz isso, mas deixar a
## regra escrita evita que alguém troque por `int()` e mude a curva inteira.
static func _arredondar(x: float) -> int:
    return int(floor(x + 0.5))

static func posicionamentos(tipo: int) -> int:
    return POSICIONAMENTOS[tipo]

static func descartes(tipo: int) -> int:
    return DESCARTES[tipo]
