extends RefCounted
class_name Run
## Uma partida inteira: 6 rodadas de 3 mesas, 3 vidas, uma semente.
##
## A `Mesa` sabe jogar uma mesa; a `Run` sabe encadeá-las. Nenhuma das duas
## desenha nada — quem desenha é a tela, e ela lê estes dois objetos.

const MESAS_POR_RODADA := 3   ## Pequena, Grande e Chefe, nesta ordem
const VIDAS := 3

var semente := 0
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

func _init(p_semente: int) -> void:
    semente = p_semente
    _abrir_mesa()

func _abrir_mesa() -> void:
    mesa = Mesa.new(indice_da_mesa, rodada, semente, tentativa)

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

    if not mesa.venceu:
        ## R20 — a derrota gasta uma vida e repete a MESMA mesa com semente
        ## derivada. Não é sorteio novo: a run continua sendo a mesma run.
        vidas -= 1
        tentativa += 1
        if vidas <= 0:
            acabou = true
            return {"pronto": true, "venceu_mesa": false, "fim_da_run": true,
                    "venceu_run": false}
        _abrir_mesa()
        return {"pronto": true, "venceu_mesa": false, "fim_da_run": false,
                "repetindo": true}

    mesas_vencidas += 1
    tentativa = 1
    indice_da_mesa += 1
    if indice_da_mesa >= MESAS_POR_RODADA:
        indice_da_mesa = 0
        rodada += 1
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
