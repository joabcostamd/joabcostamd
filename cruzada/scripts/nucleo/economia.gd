extends RefCounted
class_name Economia
## O dinheiro. Uma tabela e três contas.
##
## A renda existe para a build crescer junto com a curva de metas, e o número que
## importa é a RAZÃO entre as duas: sem loja o jogo é impossível a partir da
## rodada 4; a loja é o que transforma "difícil" em "difícil e possível".

const PREMIO_POR_MESA: PackedInt32Array = [3, 4, 5]  ## Pequena, Grande, Chefe
const SOBRA_TETO := 4          ## $1 por posicionamento não usado, teto $4
const JUROS_A_CADA := 5        ## $1 a cada $5 guardados
const JUROS_TETO := 4
const DERROTA_TETO := 4        ## $1 a cada 20% da meta atingida

## O que uma mesa paga. `poderes` pode ser nulo — a renda extra é relíquia.
static func pagamento(mesa: Mesa, poderes: Poderes = null) -> Dictionary:
    var premio := 0
    var sobra := 0
    var consolo := 0
    if mesa.venceu:
        premio = PREMIO_POR_MESA[mesa.tipo]
        if poderes != null:
            premio += poderes.renda_extra()
        ## Posicionamento não usado vira moeda: é o prêmio por terminar cedo, e é
        ## o que impede "bater a meta rápido" de ser pior que raspar no limite.
        sobra = mini(SOBRA_TETO, mesa.posicionamentos_max - mesa.posicionamentos_usados)
    else:
        ## Derrota paga. Sair de uma mesa perdida com zero é o que faz a run
        ## perdida virar duas mesas perdidas.
        consolo = mini(DERROTA_TETO,
                       int(5.0 * float(mesa.pontos) / float(maxi(1, mesa.meta))))
    var guardado := poderes.dinheiro if poderes != null else 0
    var teto := poderes.juros_teto() if poderes != null else JUROS_TETO
    var juros := mini(teto, guardado / JUROS_A_CADA)
    return {"premio": premio, "sobra": sobra, "consolo": consolo, "juros": juros,
            "total": premio + sobra + consolo + juros}

## O preço de um item, já com o desconto das relíquias. Piso $1: item de graça
## tira a decisão de comprar, que é a decisão que a loja existe para criar.
static func preco(item: Dictionary, poderes: Poderes) -> int:
    var p := int(item.get("preco", Itens.PRECO_COMUM))
    if poderes != null:
        p -= poderes.desconto()
    return maxi(1, p)
