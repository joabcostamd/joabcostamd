extends RefCounted
class_name Itens
## O catálogo. Selos de casa, selos de eixo e relíquias — tudo como DADO.
##
## A combinatória do jogo mora aqui, e ela é grande de propósito: um selo de casa
## pode ir em qualquer das 25 casas, um de eixo em qualquer das 12 linhas, e a
## run compra de 9 a 17 vezes. Não é "muitos itens": é que o mesmo item em duas
## casas diferentes é uma build diferente, porque a geometria é o jogo.
##
## Cada item é uma linha desta tabela. Um efeito novo é uma constante nova em
## `EFEITOS` e um `match` a mais em `Poderes` — nunca um `if` no meio do motor.

## Os efeitos. Cada um é um gancho implementado UMA vez em `Poderes`.
enum {
    FICHAS_NA_CASA,      ## +N fichas quando a carta desta casa entra numa mão
    MULT_NA_CASA,        ## +N mult para a linha que passa por esta casa
    DOBRA_A_CASA,        ## as fichas da carta desta casa contam em dobro
    TEAR_NA_CASA,        ## +N Tear quando esta casa participa de uma colheita
    DINHEIRO_NA_CASA,    ## $N quando esta casa é colhida
    FICHAS_NO_EIXO,      ## +N fichas quando esta linha é colhida
    MULT_NO_EIXO,        ## +N mult quando esta linha é colhida
    EIXO_PAGA_INTEIRO,   ## esta linha ignora o piso de 60% da diagonal
    TEAR_INICIAL,        ## o Tear começa em N
    TEAR_TETO,           ## o teto do Tear sobe N
    TEAR_POR_TIQUE,      ## o tique do Tear acontece a cada N posicionamentos
    MAO_MAIOR,           ## +N cartas na mão
    POSICIONAMENTOS,     ## +N posicionamentos por mesa
    DESCARTES,           ## +N descartes por mesa
    PARCELA_MAIOR,       ## a parcela paga +N% do que pagaria completa
    DIAGONAL_CHEIA,      ## todas as diagonais pagam 100%
    FICHAS_POR_NAIPE,    ## +N fichas por carta deste naipe na linha colhida
    MULT_POR_AVESSO,     ## +N mult por Avesso presente na linha colhida
    MULT_POR_FRACA,      ## +N mult por mão fraca colhida no mesmo evento
    JUROS,               ## +N no teto dos juros
    DESCONTO,            ## −N no preço de tudo na loja
    RENDA,               ## +$N por mesa vencida
}

const CASA := 0
const EIXO := 1
const RELIQUIA := 2

## Os preços vêm da economia da §6.3 e não são gosto: com renda mediana de ~$8
## por mesa e 17 lojas, um selo comum a $5 significa uma compra a cada mesa e
## meia — que é o ritmo que faz a build crescer junto com a curva de metas.
const PRECO_COMUM := 5
const PRECO_RARO := 7
const PRECO_EPICO := 9
const PRECO_EIXO := 6
const PRECO_RELIQUIA := 8
const PRECO_NIVEL := 4

## Um nível de mão soma `max(fichas_base × 0,35 ; 8)` às fichas e +1 ao mult.
## O passo usa SEMPRE as fichas do nível zero: não é composto, senão a Sequência
## Real dobraria sozinha em quatro compras e a tabela deixaria de ter hierarquia.
const NIVEL_PASSO_MULT := 1

static func passo_de_fichas(categoria: int) -> int:
    return maxi(8, int(round(float(Maos.FICHAS_BASE[categoria]) * 0.35)))

# ─────────────────────────── selos de casa ───────────────────────────
# Colam numa das 25 casas. O jogador escolhe onde, e é a escolha que importa:
# o mesmo selo em C3 toca quatro linhas, num canto toca três, no meio de uma
# borda toca duas. A grade é a build.

const SELOS_DE_CASA: Array[Dictionary] = [
    {"id": "brasa", "nome": "Brasa", "preco": PRECO_COMUM,
     "efeito": FICHAS_NA_CASA, "valor": 30, "frase": "+30 fichas nesta casa"},
    {"id": "lastro", "nome": "Lastro", "preco": PRECO_COMUM,
     "efeito": FICHAS_NA_CASA, "valor": 55, "frase": "+55 fichas nesta casa"},
    {"id": "cunha", "nome": "Cunha", "preco": PRECO_RARO,
     "efeito": MULT_NA_CASA, "valor": 2, "frase": "+2 mult nas linhas daqui"},
    {"id": "esquadro", "nome": "Esquadro", "preco": PRECO_EPICO,
     "efeito": MULT_NA_CASA, "valor": 4, "frase": "+4 mult nas linhas daqui"},
    {"id": "espelho", "nome": "Espelho", "preco": PRECO_EPICO,
     "efeito": DOBRA_A_CASA, "valor": 1, "frase": "esta carta vale em dobro"},
    {"id": "fuso", "nome": "Fuso", "preco": PRECO_RARO,
     "efeito": TEAR_NA_CASA, "valor": 1, "frase": "+1 Tear quando esta casa colhe"},
    {"id": "cofre", "nome": "Cofre", "preco": PRECO_COMUM,
     "efeito": DINHEIRO_NA_CASA, "valor": 2, "frase": "$2 quando esta casa colhe"},
]

# ─────────────────────────── selos de eixo ───────────────────────────
# Colam numa das 12 linhas. Mais caros e mais decisivos: uma linha colhe várias
# vezes por mesa, e escolher QUAL delas é escolher o formato da run.

const SELOS_DE_EIXO: Array[Dictionary] = [
    {"id": "bordado", "nome": "Bordado", "preco": PRECO_EIXO,
     "efeito": MULT_NO_EIXO, "valor": 3, "frase": "+3 mult nesta linha"},
    {"id": "trama", "nome": "Trama", "preco": PRECO_EIXO,
     "efeito": FICHAS_NO_EIXO, "valor": 70, "frase": "+70 fichas nesta linha"},
    {"id": "bussola", "nome": "Bússola", "preco": PRECO_EIXO,
     "efeito": EIXO_PAGA_INTEIRO, "valor": 1, "frase": "esta diagonal paga inteiro"},
    {"id": "veia", "nome": "Veia", "preco": PRECO_EIXO,
     "efeito": FICHAS_NO_EIXO, "valor": 120, "frase": "+120 fichas nesta linha"},
]

# ──────────────────────────── relíquias ────────────────────────────
# Globais. Mudam a run inteira, e são o lugar onde as builds ficam diferentes
# umas das outras em vez de só maiores.

const RELIQUIAS: Array[Dictionary] = [
    {"id": "novelo", "nome": "Novelo", "preco": PRECO_RELIQUIA,
     "efeito": TEAR_INICIAL, "valor": 3, "frase": "o Tear começa em 4"},
    {"id": "roca", "nome": "Roca", "preco": PRECO_RELIQUIA,
     "efeito": TEAR_TETO, "valor": 4, "frase": "o Tear vai até 12"},
    {"id": "lancadeira", "nome": "Lançadeira", "preco": PRECO_RELIQUIA,
     "efeito": TEAR_POR_TIQUE, "valor": 3, "frase": "Tear sobe a cada 3 cartas"},
    {"id": "manga", "nome": "Manga larga", "preco": PRECO_RELIQUIA,
     "efeito": MAO_MAIOR, "valor": 2, "frase": "+2 cartas na mão"},
    {"id": "sirga", "nome": "Sirga", "preco": PRECO_RELIQUIA,
     "efeito": POSICIONAMENTOS, "valor": 3, "frase": "+3 posicionamentos por mesa"},
    {"id": "gaveta", "nome": "Gaveta", "preco": PRECO_RELIQUIA,
     "efeito": DESCARTES, "valor": 3, "frase": "+3 descartes por mesa"},
    {"id": "pulso", "nome": "Pulso firme", "preco": PRECO_RELIQUIA,
     "efeito": PARCELA_MAIOR, "valor": 25, "frase": "a parcela paga 60%"},
    {"id": "prumo", "nome": "Prumo", "preco": PRECO_RELIQUIA,
     "efeito": DIAGONAL_CHEIA, "valor": 1, "frase": "as diagonais pagam inteiro"},
    {"id": "carmim", "nome": "Carmim", "preco": PRECO_RELIQUIA,
     "efeito": FICHAS_POR_NAIPE, "valor": 25, "naipe": Cartas.COPAS,
     "frase": "+25 fichas por copas colhida"},
    {"id": "ocre", "nome": "Ocre", "preco": PRECO_RELIQUIA,
     "efeito": FICHAS_POR_NAIPE, "valor": 25, "naipe": Cartas.OUROS,
     "frase": "+25 fichas por ouros colhida"},
    {"id": "seiva", "nome": "Seiva", "preco": PRECO_RELIQUIA,
     "efeito": FICHAS_POR_NAIPE, "valor": 25, "naipe": Cartas.PAUS,
     "frase": "+25 fichas por paus colhida"},
    {"id": "carvao", "nome": "Carvão", "preco": PRECO_RELIQUIA,
     "efeito": FICHAS_POR_NAIPE, "valor": 25, "naipe": Cartas.ESPADAS,
     "frase": "+25 fichas por espadas colhida"},
    {"id": "duas_caras", "nome": "Duas caras", "preco": PRECO_RELIQUIA,
     "efeito": MULT_POR_AVESSO, "valor": 3, "frase": "+3 mult por Avesso colhido"},
    {"id": "remendo", "nome": "Remendo", "preco": PRECO_RELIQUIA,
     "efeito": MULT_POR_FRACA, "valor": 3, "frase": "+3 mult por mão fraca colhida"},
    {"id": "juro", "nome": "Juro composto", "preco": PRECO_RELIQUIA,
     "efeito": JUROS, "valor": 4, "frase": "os juros vão até $8"},
    {"id": "pechincha", "nome": "Pechincha", "preco": PRECO_RELIQUIA,
     "efeito": DESCONTO, "valor": 2, "frase": "tudo custa $2 a menos"},
    {"id": "quinhao", "nome": "Quinhão", "preco": PRECO_RELIQUIA,
     "efeito": RENDA, "valor": 3, "frase": "+$3 por mesa vencida"},
]

static func todos_de(tipo: int) -> Array[Dictionary]:
    match tipo:
        CASA: return SELOS_DE_CASA
        EIXO: return SELOS_DE_EIXO
        _: return RELIQUIAS

static func achar(tipo: int, id: String) -> Dictionary:
    for item in todos_de(tipo):
        if str(item["id"]) == id:
            return item
    return {}

## O total de itens distintos. Não é o tamanho do espaço de builds — esse é muito
## maior, porque cada selo escolhe uma das 25 casas ou uma das 12 linhas.
static func quantos() -> int:
    return SELOS_DE_CASA.size() + SELOS_DE_EIXO.size() + RELIQUIAS.size()
