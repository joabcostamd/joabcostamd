extends RefCounted
class_name Run
## Uma partida inteira: 6 rodadas de 3 mesas, 3 vidas, uma semente.
##
## A `Mesa` sabe jogar uma mesa; a `Run` sabe encadeá-las. Nenhuma das duas
## desenha nada — quem desenha é a tela, e ela lê estes dois objetos.

const MESAS_POR_RODADA := 3   ## Pequena, Grande e Chefe, nesta ordem
const VIDAS := 3

## SEGUNDA MÃO. Repetir a mesma mesa dá uma carta a mais na manga, cumulativa,
## até três. Nunca reduz a meta: o jogador recebe ferramenta, não desconto —
## desconto ensina que perder é o caminho, ferramenta ensina que dá para virar.
const CATRACA_MAX := 3

## QUASE LÁ. Derrota com 80% ou mais da meta devolve a vida. A mesa em que se
## chegou perto é justamente a que dói perder, e é aí que se abandona o jogo.
const QUASE_LA := 0.80

var semente := 0
var desafio: Desafio
var rodada := 1               ## 1 a 6
var indice_da_mesa := 0       ## 0 Pequena · 1 Grande · 2 Chefe
var tentativa := 1            ## sobe a cada derrota; muda a semente da mesa
var vidas := VIDAS
var mesa: Mesa

var acabou := false
var venceu := false

## Números da run inteira, para desbloqueio e para a autópsia.
var mesas_jogadas := 0
var mesas_vencidas := 0
var maior_evento := 0
var categorias_feitas := {}   ## categoria -> quantas vezes
var maior_cruzada := 0        ## quantas linhas no maior evento de linhas

## Cartas que a run já colheu e não devolve (geometria 4).
var fora_do_baralho: Array[int] = []
## Linhas que morreram de vez (geometria 7): uma por rodada.
var linhas_mortas: Array[int] = []
## As luzes da Fiança atravessam as mesas e zeram entre runs.
var fianca := 0
## Quantas vezes o Quase lá segurou a run. Vira conquista.
var quase_la := 0

func _init(p_semente: int, p_desafio: Desafio = null) -> void:
    semente = p_semente
    desafio = p_desafio if p_desafio != null else Desafio.new()
    _matar_linha_da_rodada()
    _abrir_mesa()

func _abrir_mesa() -> void:
    var catraca := mini(tentativa - 1, CATRACA_MAX)
    mesa = Mesa.new(indice_da_mesa, rodada, semente, tentativa, desafio, catraca,
                    fianca, fora_do_baralho, linhas_mortas)

## Geometria 7 — uma linha morre a cada rodada. Sorteada por fluxo próprio, e
## nunca as duas diagonais juntas: elas são as únicas que cruzam tudo, e matar as
## duas na mesma run tira a geometria do jogo em vez de apertá-la.
func _matar_linha_da_rodada() -> void:
    if not desafio.tem(Desafio.GEO_LINHA_MORTA_POR_RODADA):
        return
    var rng := Aleatorio.new(Aleatorio.misturar(semente, 555, rodada))
    var candidatas: Array[int] = []
    var diagonais_mortas := 0
    for l in linhas_mortas:
        if Geometria.diagonal(l):
            diagonais_mortas += 1
    for l in Geometria.LINHAS:
        if linhas_mortas.has(l):
            continue
        if Geometria.diagonal(l) and diagonais_mortas >= 1:
            continue
        candidatas.append(l)
    if not candidatas.is_empty():
        linhas_mortas.append(candidatas[rng.inteiro(candidatas.size())])

func total_de_mesas() -> int:
    return Metas.RODADAS * MESAS_POR_RODADA

func mesas_concluidas() -> int:
    return (rodada - 1) * MESAS_POR_RODADA + indice_da_mesa

## Chamado quando a mesa termina. Devolve o que aconteceu, para a tela contar.
func concluir_mesa() -> Dictionary:
    if not mesa.acabou or acabou:
        return {"pronto": false}
    mesas_jogadas += 1
    maior_evento = maxi(maior_evento, mesa.maior_evento)

    fianca = mesa.fianca
    if not mesa.venceu:
        ## A FIANÇA acende também na mesa perdida: é a perda que menos se escolhe.
        if fianca < Mesa.FIANCA_LUZES:
            fianca += 1
        var fracao := float(mesa.pontos) / float(maxi(1, mesa.meta))
        var perto := fracao >= QUASE_LA
        ## R20 — a derrota gasta uma vida e repete a MESMA mesa com semente
        ## derivada. Não é sorteio novo: a run continua sendo a mesma run.
        if not perto and not desafio.sem_derrota:
            vidas -= 1
        if perto:
            quase_la += 1
        tentativa += 1
        if vidas <= 0:
            acabou = true
            return {"pronto": true, "venceu_mesa": false, "fim_da_run": true,
                    "venceu_run": false, "fracao": fracao}
        _abrir_mesa()
        return {"pronto": true, "venceu_mesa": false, "fim_da_run": false,
                "repetindo": true, "quase_la": perto, "fracao": fracao,
                "catraca": mini(tentativa - 1, CATRACA_MAX)}

    mesas_vencidas += 1
    tentativa = 1
    ## Geometria 4 — o que foi colhido sai da run.
    if desafio.tem(Desafio.GEO_COLHIDA_NAO_VOLTA):
        for carta: int in mesa.colhida:
            if not fora_do_baralho.has(carta):
                fora_do_baralho.append(carta)
    indice_da_mesa += 1
    if indice_da_mesa >= MESAS_POR_RODADA:
        indice_da_mesa = 0
        rodada += 1
        _matar_linha_da_rodada()
    if rodada > Metas.RODADAS:
        acabou = true
        venceu = true
        return {"pronto": true, "venceu_mesa": true, "fim_da_run": true,
                "venceu_run": true}
    _abrir_mesa()
    return {"pronto": true, "venceu_mesa": true, "fim_da_run": false}

## Registra o que uma colheita produziu. É daqui que saem os desbloqueios de
## tema: a condição "faça uma Sequência de Cor" precisa de alguém contando.
func anotar_colheita(relato: Dictionary) -> void:
    if not bool(relato.get("colheita", false)):
        return
    var linhas: Array = relato["linhas"]
    maior_cruzada = maxi(maior_cruzada, linhas.size())
    for linha in linhas:
        var cat := int(linha["categoria"])
        categorias_feitas[cat] = int(categorias_feitas.get(cat, 0)) + 1

## A CRUZADA DO CENTRO: um evento que colhe as quatro linhas que passam pela
## casa central. É o melhor jogo do CRUZADA e o desbloqueio mais difícil.
static func e_cruzada_do_centro(relato: Dictionary) -> bool:
    if not bool(relato.get("colheita", false)):
        return false
    var linhas: Array = relato["linhas"]
    if linhas.size() < 4:
        return false
    var pelo_centro := 0
    var centro := Geometria.CASAS / 2
    for linha in linhas:
        if Geometria.CELULAS[int(linha["linha"])].has(centro):
            pelo_centro += 1
    return pelo_centro >= 4
