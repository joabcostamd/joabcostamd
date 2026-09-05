extends RefCounted
class_name Maos
## O avaliador de mãos de pôquer e a conta de pontos de uma linha.
##
## Este arquivo é o coração aritmético do jogo e foi portado da sonda, onde
## rodou dezenas de milhares de mesas com 43 asserções passando. A tabela de
## fichas e multiplicadores não é sugestão de balanceamento: ela é a hierarquia
## medida, e mexer nela sem remedir quebra as bandas do DESIGN §9.

## As 11 categorias, em ordem crescente de força.
const ALTA := 0
const PAR := 1
const DOIS_PARES := 2
const TRINCA := 3
const SEQUENCIA := 4
const FLUSH := 5
const FULL := 6
const QUADRA := 7
const SEQ_COR := 8
const REAL := 9
const QUINA := 10
const CATEGORIAS := 11

const NOMES: PackedStringArray = [
    "Carta Alta", "Par", "Dois Pares", "Trinca", "Sequência", "Flush",
    "Full House", "Quadra", "Sequência de Cor", "Sequência Real", "Quina",
]

## Os mesmos nomes para o rótulo colado na linha, onde só cabem 108 px em caixa
## alta. "SEQUÊNCIA DE COR" mede 138 e invadia o painel da direita. Abreviar é
## melhor que reduzir o corpo da fonte: 14 px é o piso da escala.
const CURTOS: PackedStringArray = [
    "ALTA", "PAR", "2 PARES", "TRINCA", "SEQUÊNCIA", "FLUSH",
    "FULL", "QUADRA", "SEQ. DE COR", "SEQ. REAL", "QUINA",
]

## DESIGN R10. Fichas base e multiplicador de cada categoria.
const FICHAS_BASE: PackedInt32Array = [5, 10, 20, 30, 30, 35, 40, 60, 100, 120, 140]
const MULTIPLICADOR: PackedInt32Array = [1, 2, 2, 3, 4, 4, 4, 7, 8, 10, 12]

## DESIGN R15 — o piso do padrão parcial. Só entra em mão fraca, e `+15` é
## fronteira medida, não sugestão: em `+20` o Par empata com Dois Pares e em
## `+25` inverte.
const PISO_POR_PADRAO := 15
const PISO_TETO_PADROES := 3

## DESIGN R16 — o troco da linha fraca. Devolve recurso, não pontos.
const TROCO_TEAR := 1
const TROCO_DESCARTES := 2
const TROCO_MAO := 1

## DESIGN R07 — a diagonal paga 60%.
const PISO_DIAGONAL := 0.60

## É mão fraca — a que ganha piso (R15) e troco (R16)?
static func fraca(categoria: int) -> bool:
    return categoria <= DOIS_PARES

## Só Carta Alta e Par devolvem troco; Dois Pares recebe piso mas não troco.
static func devolve_troco(categoria: int) -> bool:
    return categoria <= PAR

# ───────────────────────────── o avaliador ─────────────────────────────

## Buffers de contagem reaproveitados. Avaliar cinco cartas acontece milhares de
## vezes por turno na assistência de posicionamento; alocar treze inteiros a cada
## chamada aparece no perfil.
static var _cv := PackedInt32Array()
static var _cn := PackedInt32Array()

static func _preparar() -> void:
    if _cv.size() != Cartas.VALORES:
        _cv.resize(Cartas.VALORES)
        _cn.resize(Cartas.NAIPES)

## Avalia cinco cartas. Devolve a categoria; as fichas saem por `fichas_de()`.
static func categoria(c0: int, c1: int, c2: int, c3: int, c4: int) -> int:
    _preparar()
    for i in Cartas.VALORES:
        _cv[i] = 0
    for i in Cartas.NAIPES:
        _cn[i] = 0
    var mascara := 0
    for c in [c0, c1, c2, c3, c4]:
        var v: int = c % 13
        _cv[v] += 1
        _cn[c / 13] += 1
        mascara |= 1 << v

    var flush := false
    for n in Cartas.NAIPES:
        if _cn[n] == 5:
            flush = true
            break

    var repeticao_maxima := 0
    var pares := 0
    var trinca := false
    for v in Cartas.VALORES:
        var n: int = _cv[v]
        if n > repeticao_maxima:
            repeticao_maxima = n
        if n == 2:
            pares += 1
        if n == 3:
            trinca = true

    var sequencia := false
    var real := false
    if _bits(mascara) == 5:
        ## 10-J-Q-K-A é a única sequência que não é uma janela contígua: o Ás
        ## mora no bit 0 e volta ao topo.
        if mascara == ((1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | 1):
            sequencia = true
            real = true
        else:
            for inicio in 9:
                var janela := 0
                for k in 5:
                    janela |= 1 << (inicio + k)
                if mascara == janela:
                    sequencia = true
                    break

    if repeticao_maxima == 5:
        return QUINA
    if flush and sequencia and real:
        return REAL
    if flush and sequencia:
        return SEQ_COR
    if repeticao_maxima == 4:
        return QUADRA
    if trinca and pares == 1:
        return FULL
    if flush:
        return FLUSH
    if sequencia:
        return SEQUENCIA
    if trinca:
        return TRINCA
    if pares == 2:
        return DOIS_PARES
    if pares == 1:
        return PAR
    return ALTA

static func _bits(x: int) -> int:
    var n := 0
    while x != 0:
        n += x & 1
        x >>= 1
    return n

static func fichas_de(cartas: Array) -> int:
    var soma := 0
    for c in cartas:
        soma += Cartas.fichas(c)
    return soma

# ─────────────────────── DESIGN R15 — padrão parcial ───────────────────────

## Quantos padrões parciais as cinco cartas contêm — "quase-flush" e
## "quase-escada" na tela. 3 cartas do mesmo naipe valem 1 padrão, 4 valem 2; o
## mesmo para 3 e 4 em sequência. Teto de 3 padrões no total.
##
## Só é chamado em mão fraca. Num Flush a conta daria 2 padrões de naipe, e
## somar piso a uma mão que já é forte é exatamente o que a bancada reprovou.
static func padroes_parciais(cartas: Array) -> int:
    _preparar()
    for i in Cartas.VALORES:
        _cv[i] = 0
    for i in Cartas.NAIPES:
        _cn[i] = 0
    for c in cartas:
        _cv[c % 13] += 1
        _cn[c / 13] += 1

    var naipe_maximo := 0
    for n in Cartas.NAIPES:
        if _cn[n] > naipe_maximo:
            naipe_maximo = _cn[n]
    var padroes := 0
    if naipe_maximo >= 4:
        padroes += 2
    elif naipe_maximo == 3:
        padroes += 1

    ## O Ás conta dos dois lados: A-2-3 é quase-escada e Q-K-A também. Por isso
    ## a régua tem 14 posições, com o Ás repetido na ponta de cima.
    var corrida := 0
    var melhor := 0
    for p in 14:
        var v := 0 if p == 13 else p
        if _cv[v] > 0:
            corrida += 1
            if corrida > melhor:
                melhor = corrida
        else:
            corrida = 0
    if melhor >= 4:
        padroes += 2
    elif melhor == 3:
        padroes += 1

    return mini(padroes, PISO_TETO_PADROES)

# ────────────────── DESIGN R11/R12 — a conta do evento ──────────────────

## As fichas de uma linha completa. É a parte que NÃO depende do evento: só o
## que as cinco cartas valem, mais a base da categoria, mais o piso se for fraca.
static func fichas_da_linha(cartas: Array) -> int:
    var cat := categoria(cartas[0], cartas[1], cartas[2], cartas[3], cartas[4])
    var fichas := FICHAS_BASE[cat] + fichas_de(cartas)
    if fraca(cat):
        fichas += padroes_parciais(cartas) * PISO_POR_PADRAO
    return fichas

## R12 — o fator do evento: a SOMA dos multiplicadores de todas as mãos colhidas
## juntas, vezes o Tear. Um fator só, comum a todas as linhas do evento.
##
## É aqui que a cruz existe. Uma Trinca sozinha paga `fichas × 3 × Tear`;
## a mesma Trinca colhida junto com um Flush paga `fichas × 7 × Tear` — para as
## duas. Se cada linha usasse o multiplicador dela, colher junto seria idêntico a
## colher separado e a Janela da Colheita (R08) não teria razão de existir.
static func fator_do_evento(categorias: Array, tear: int) -> int:
    var soma := 0
    for cat in categorias:
        soma += MULTIPLICADOR[cat]
    return soma * tear

## Os pontos de uma linha dentro de um evento, já com o piso da diagonal.
## Arredonda para baixo: o jogador nunca ganha ponto que a conta não tem.
static func pontos_da_linha(fichas: int, fator: int, diagonal: bool) -> int:
    var v := float(fichas) * float(fator)
    if diagonal:
        v *= PISO_DIAGONAL
    return int(floor(maxf(0.0, v)))

# ─────────────── DESIGN R13/R19 — a parcela e o fecho ───────────────

## Uma linha incompleta vale o que ela já tem: só as categorias por valor são
## garantidas com menos de 5 cartas, porque a 5ª carta pode desmanchar qualquer
## promessa de naipe ou de sequência.
static func categoria_parcial(cartas: Array) -> int:
    if cartas.size() == 5:
        return categoria(cartas[0], cartas[1], cartas[2], cartas[3], cartas[4])
    _preparar()
    for i in Cartas.VALORES:
        _cv[i] = 0
    for c in cartas:
        _cv[c % 13] += 1
    var repeticao_maxima := 0
    var pares := 0
    var trinca := false
    for v in Cartas.VALORES:
        var n: int = _cv[v]
        if n > repeticao_maxima:
            repeticao_maxima = n
        if n == 2:
            pares += 1
        if n >= 3:
            trinca = true
    if repeticao_maxima >= 4:
        return QUADRA
    if trinca:
        return TRINCA
    if pares >= 2:
        return DOIS_PARES
    if pares == 1:
        return PAR
    return ALTA

## O que uma linha incompleta paga. `fracao` é 0,35 na PARCELA e 0,50 no FECHO.
##
## A linha sozinha usa o multiplicador dela — não há evento partilhado aqui — e o
## piso do padrão parcial NÃO entra: ele é recompensa de colheita, não de
## promessa. Foi assim que a bancada mediu, e mudar isso muda a economia inteira.
static func pontos_parciais(cartas: Array, diagonal: bool, tear: int,
                            fracao: float) -> int:
    if cartas.is_empty():
        return 0
    var cat := categoria_parcial(cartas)
    var fichas := FICHAS_BASE[cat] + fichas_de(cartas)
    var v := float(fichas) * float(MULTIPLICADOR[cat] * tear) * fracao
    if diagonal:
        v *= PISO_DIAGONAL
    return int(floor(maxf(0.0, v)))

# ──────────────── o que esta linha AINDA pode ser (§6, "COMO FECHAR") ────────────────

## A melhor categoria que uma linha incompleta ainda consegue alcançar, se as
## cartas que faltam vierem certas. É uma promessa, não uma garantia — e é a
## régua que separa "esta linha ainda vale a pena" de "esta linha morreu".
##
## Serve ao painel COMO FECHAR e ao nível 2 das DICAS. É também o que um jogador
## competente calcula de cabeça sem saber que está calculando.
static func melhor_alcancavel(cartas: Array) -> int:
    var k := cartas.size()
    if k == 0:
        return SEQ_COR
    if k > 5:
        return ALTA
    var livres := 5 - k
    _preparar()
    for i in Cartas.VALORES:
        _cv[i] = 0
    for i in Cartas.NAIPES:
        _cn[i] = 0
    var mascara := 0
    for c in cartas:
        _cv[c % 13] += 1
        _cn[c / 13] += 1
        mascara |= 1 << (c % 13)

    var mesmo_naipe := false
    for n in Cartas.NAIPES:
        if _cn[n] == k:
            mesmo_naipe = true
            break

    var distintos := _bits(mascara)
    var sem_repeticao := distintos == k

    ## Sequência ainda possível: nenhum valor repetido e tudo cabendo numa
    ## janela de cinco. A janela do Ás alto entra à parte, como no avaliador.
    var seq := false
    var real := false
    if sem_repeticao:
        var janela_real := (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | 1
        if (mascara & ~janela_real) == 0:
            seq = true
            real = true
        if not seq:
            for inicio in 9:
                var janela := 0
                for j in 5:
                    janela |= 1 << (inicio + j)
                if (mascara & ~janela) == 0:
                    seq = true
                    break

    var maior := 0
    var segunda := 0
    for v in Cartas.VALORES:
        var n: int = _cv[v]
        if n > maior:
            segunda = maior
            maior = n
        elif n > segunda:
            segunda = n

    if mesmo_naipe and real:
        return REAL
    if mesmo_naipe and seq:
        return SEQ_COR
    if maior + livres >= 4:
        return QUADRA
    if distintos <= 2 and maior <= 3 and segunda <= 2:
        return FULL
    if mesmo_naipe:
        return FLUSH
    if seq:
        return SEQUENCIA
    if maior + livres >= 3:
        return TRINCA
    if maior >= 2 and segunda >= 2:
        return DOIS_PARES
    if (2 - maior) + (2 - mini(segunda, 2)) <= livres and distintos >= 1:
        return DOIS_PARES
    if maior >= 2 or livres >= 1:
        return PAR
    return ALTA
