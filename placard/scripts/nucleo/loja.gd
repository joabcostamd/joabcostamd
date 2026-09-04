extends RefCounted
class_name Loja
## As três vagas entre uma mesa e a seguinte.
##
## A loja é o que faz a build crescer junto com a curva de metas. Sem ela o jogo
## é matematicamente impossível a partir da rodada 4 — está medido — e com ela
## "difícil" volta a ser diferente de "fechado".
##
## **Divulgação progressiva:** a rodada 1 só vende nível de mão; selo de casa
## entra na 2, selo de eixo na 3, relíquia na 4. Não é para racionar poder: é
## para o jogador aprender um conceito por vez, e a rodada 1 é onde ele ainda
## está aprendendo o que é uma linha.

const NIVEL := 0
const VAGAS := 3

var vagas: Array[Dictionary] = []
var rerrolagens := 0
var rodada := 1
var _rng: Aleatorio

## O que esta rodada pode vender. É a divulgação progressiva, e ela é regra.
static func tipos_da_rodada(rodada: int) -> Array[int]:
    var tipos: Array[int] = [NIVEL]
    if rodada >= 2:
        tipos.append(Itens.CASA + 1)
    if rodada >= 3:
        tipos.append(Itens.EIXO + 1)
    if rodada >= 4:
        tipos.append(Itens.RELIQUIA + 1)
    return tipos

func _init(p_rodada: int, semente: int, desafio: Desafio = null) -> void:
    rodada = p_rodada
    _rng = Aleatorio.new(semente)
    var quantas := VAGAS
    ## Geometria 5 — a loja perde uma vaga. Menos escolha, não menos poder: as
    ## vagas que sobram continuam sorteadas do mesmo saco.
    if desafio != null and desafio.tem(Desafio.GEO_LOJA_PERDE_VAGA):
        quantas -= 1
    for i in quantas:
        vagas.append(_sortear_vaga())

func _sortear_vaga() -> Dictionary:
    var tipos := tipos_da_rodada(rodada)
    var tipo: int = tipos[_rng.inteiro(tipos.size())]
    if tipo == NIVEL:
        ## Nível de mão nunca sorteia a Quina: ela só existe por uma rota que o
        ## jogo ainda não abre, e vender nível de uma mão inalcançável é vender
        ## nada com cara de item.
        var cat := _rng.inteiro(Maos.CATEGORIAS - 1)
        return {"tipo": NIVEL, "categoria": cat, "nome": Maos.NOMES[cat],
                "preco": Itens.PRECO_NIVEL,
                "frase": "+%d fichas e +1 mult" % Itens.passo_de_fichas(cat),
                "vendida": false}
    var familia := tipo - 1
    var lista := Itens.todos_de(familia)
    var item: Dictionary = lista[_rng.inteiro(lista.size())]
    return {"tipo": familia + 1, "familia": familia, "id": str(item["id"]),
            "nome": str(item["nome"]), "preco": int(item["preco"]),
            "frase": str(item["frase"]), "vendida": false}

func preco_da_vaga(i: int, poderes: Poderes) -> int:
    return Economia.preco(vagas[i], poderes)

func pode_comprar(i: int, poderes: Poderes) -> bool:
    if i < 0 or i >= vagas.size() or bool(vagas[i]["vendida"]):
        return false
    return poderes.dinheiro >= preco_da_vaga(i, poderes)

## Compra a vaga. Selos precisam de alvo: `alvo` é a casa (0..24) ou a linha
## (0..11). Devolve a vaga comprada, ou vazio se não deu.
func comprar(i: int, poderes: Poderes, alvo := -1) -> Dictionary:
    if not pode_comprar(i, poderes):
        return {}
    var vaga: Dictionary = vagas[i]
    var tipo := int(vaga["tipo"])
    if tipo == Itens.CASA + 1 and (alvo < 0 or alvo >= Geometria.CASAS):
        return {}
    if tipo == Itens.EIXO + 1 and (alvo < 0 or alvo >= Geometria.LINHAS):
        return {}
    poderes.dinheiro -= preco_da_vaga(i, poderes)
    match tipo:
        NIVEL: poderes.subir_nivel(int(vaga["categoria"]))
        Itens.CASA + 1: poderes.colar_na_casa(alvo, str(vaga["id"]))
        Itens.EIXO + 1: poderes.colar_no_eixo(alvo, str(vaga["id"]))
        _: poderes.guardar_reliquia(str(vaga["id"]))
    vagas[i]["vendida"] = true
    vagas[i]["alvo"] = alvo
    return vagas[i]

## Rerrolar troca as vagas não vendidas. Custa $1 e sobe $1 a cada vez na mesma
## loja: sem a escada, rerrolar vira o jogo, e o jogo é a grade.
func preco_da_rerrolagem() -> int:
    return 1 + rerrolagens

func rerrolar(poderes: Poderes) -> bool:
    var preco := preco_da_rerrolagem()
    if poderes.dinheiro < preco:
        return false
    poderes.dinheiro -= preco
    rerrolagens += 1
    for i in vagas.size():
        if not bool(vagas[i]["vendida"]):
            vagas[i] = _sortear_vaga()
    return true

func precisa_de_alvo(i: int) -> int:
    ## Devolve o que o selo pede: −1 nada, 0 uma casa, 1 uma linha.
    var tipo := int(vagas[i]["tipo"])
    if tipo == Itens.CASA + 1:
        return 0
    if tipo == Itens.EIXO + 1:
        return 1
    return -1
