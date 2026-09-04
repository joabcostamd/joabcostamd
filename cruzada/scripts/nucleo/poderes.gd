extends RefCounted
class_name Poderes
## Tudo o que o jogador comprou, e o único lugar que sabe somar isso.
##
## A `Mesa` nunca pergunta "tenho a relíquia Novelo?". Ela pergunta "qual é o
## Tear inicial?" e este objeto responde. É o que permite ter dezenas de itens
## sem um único `if` de item dentro do motor — e é o que faz um item novo custar
## uma linha de tabela em vez de uma cirurgia.

## Níveis comprados por categoria de mão. Índice = categoria.
var niveis := PackedInt32Array()
## casa (0..24) → lista de ids de selo colados ali.
var selos_de_casa := {}
## linha (0..11) → lista de ids de selo de eixo.
var selos_de_eixo := {}
## ids das relíquias.
var reliquias: Array[String] = []
var dinheiro := 0

func _init() -> void:
    niveis.resize(Maos.CATEGORIAS)
    niveis.fill(0)

# ───────────────────────── comprar e colar ─────────────────────────

func subir_nivel(categoria: int) -> void:
    niveis[categoria] += 1

func colar_na_casa(casa: int, id: String) -> void:
    if not selos_de_casa.has(casa):
        selos_de_casa[casa] = []
    selos_de_casa[casa].append(id)

func colar_no_eixo(linha: int, id: String) -> void:
    if not selos_de_eixo.has(linha):
        selos_de_eixo[linha] = []
    selos_de_eixo[linha].append(id)

func guardar_reliquia(id: String) -> void:
    reliquias.append(id)

func tem_reliquia(id: String) -> bool:
    return reliquias.has(id)

func quantos_selos() -> int:
    var n := 0
    for casa in selos_de_casa:
        n += selos_de_casa[casa].size()
    for linha in selos_de_eixo:
        n += selos_de_eixo[linha].size()
    return n

# ─────────────────────── a soma de cada efeito ───────────────────────

## Quanto as relíquias somam num efeito. Uma soma, sempre — duas relíquias do
## mesmo efeito empilham, e é assim que builds extremas existem.
func _das_reliquias(efeito: int) -> int:
    var soma := 0
    for id in reliquias:
        var item := Itens.achar(Itens.RELIQUIA, id)
        if not item.is_empty() and int(item["efeito"]) == efeito:
            soma += int(item["valor"])
    return soma

func _tem_efeito_de_reliquia(efeito: int) -> bool:
    for id in reliquias:
        var item := Itens.achar(Itens.RELIQUIA, id)
        if not item.is_empty() and int(item["efeito"]) == efeito:
            return true
    return false

# ────────────────────────── o que a Mesa pergunta ──────────────────────────

## R24 — as fichas base da categoria, já com os níveis comprados.
func fichas_base(categoria: int) -> int:
    return Maos.FICHAS_BASE[categoria] \
        + niveis[categoria] * Itens.passo_de_fichas(categoria)

func mult_da_categoria(categoria: int) -> int:
    return Maos.MULTIPLICADOR[categoria] + niveis[categoria] * Itens.NIVEL_PASSO_MULT

func nivel(categoria: int) -> int:
    return niveis[categoria]

func tear_inicial() -> int:
    return Metas.TEAR_INICIAL + _das_reliquias(Itens.TEAR_INICIAL)

func tear_teto() -> int:
    return Metas.TEAR_TETO + _das_reliquias(Itens.TEAR_TETO)

## O tique do Tear: a cada quantos posicionamentos. Menor é melhor, então a
## relíquia SUBSTITUI em vez de somar — e nunca abaixo de 2, que é o ponto onde
## o Tear encostaria no teto antes da primeira colheita.
func tear_por_tique() -> int:
    if _tem_efeito_de_reliquia(Itens.TEAR_POR_TIQUE):
        var menor := Metas.TEAR_POR_TIQUE
        for id in reliquias:
            var item := Itens.achar(Itens.RELIQUIA, id)
            if not item.is_empty() and int(item["efeito"]) == Itens.TEAR_POR_TIQUE:
                menor = mini(menor, int(item["valor"]))
        return maxi(2, menor)
    return Metas.TEAR_POR_TIQUE

func tamanho_da_mao() -> int:
    return Metas.MAO_INICIAL + _das_reliquias(Itens.MAO_MAIOR)

func posicionamentos_extra() -> int:
    return _das_reliquias(Itens.POSICIONAMENTOS)

func descartes_extra() -> int:
    return _das_reliquias(Itens.DESCARTES)

## A parcela (R13), em fração. A relíquia soma pontos percentuais.
func parcela() -> float:
    return Metas.PARCELA + float(_das_reliquias(Itens.PARCELA_MAIOR)) / 100.0

## O piso da diagonal. Com Prumo, elas pagam inteiro.
func piso_da_diagonal(linha: int) -> float:
    if _tem_efeito_de_reliquia(Itens.DIAGONAL_CHEIA):
        return 1.0
    for id in selos_de_eixo.get(linha, []):
        var item := Itens.achar(Itens.EIXO, str(id))
        if not item.is_empty() and int(item["efeito"]) == Itens.EIXO_PAGA_INTEIRO:
            return 1.0
    return Maos.PISO_DIAGONAL

func juros_teto() -> int:
    return Economia.JUROS_TETO + _das_reliquias(Itens.JUROS)

func desconto() -> int:
    return _das_reliquias(Itens.DESCONTO)

func renda_extra() -> int:
    return _das_reliquias(Itens.RENDA)

# ───────────────── o bônus de uma linha colhida ─────────────────

## Tudo o que os selos e as relíquias somam a UMA linha que está sendo colhida.
##
## `cartas` são as cartas já resolvidas da linha, na ordem das casas; `avessos` é
## quantos Avessos estão nela; `fracas` é quantas mãos fracas há no evento
## inteiro. Devolve fichas, mult, Tear e dinheiro extras.
func bonus_da_linha(linha: int, casas: Array, cartas: Array, avessos: int,
                    fracas: int) -> Dictionary:
    var fichas := 0
    var mult := 0
    var tear := 0
    var moedas := 0

    ## Selos de casa: valem pela casa onde estão, e uma casa participa de duas a
    ## quatro linhas — é isso que faz a escolha de ONDE colar ser o jogo.
    for i in casas.size():
        var casa: int = casas[i]
        if not selos_de_casa.has(casa):
            continue
        for id in selos_de_casa[casa]:
            var item := Itens.achar(Itens.CASA, str(id))
            if item.is_empty():
                continue
            match int(item["efeito"]):
                Itens.FICHAS_NA_CASA:
                    fichas += int(item["valor"])
                Itens.MULT_NA_CASA:
                    mult += int(item["valor"])
                Itens.DOBRA_A_CASA:
                    if i < cartas.size():
                        fichas += Cartas.fichas(int(cartas[i]))
                Itens.TEAR_NA_CASA:
                    tear += int(item["valor"])
                Itens.DINHEIRO_NA_CASA:
                    moedas += int(item["valor"])

    ## Selos de eixo: valem pela linha inteira, toda vez que ela colhe.
    for id in selos_de_eixo.get(linha, []):
        var item := Itens.achar(Itens.EIXO, str(id))
        if item.is_empty():
            continue
        match int(item["efeito"]):
            Itens.FICHAS_NO_EIXO:
                fichas += int(item["valor"])
            Itens.MULT_NO_EIXO:
                mult += int(item["valor"])

    ## Relíquias que olham para o conteúdo da linha.
    for id in reliquias:
        var item := Itens.achar(Itens.RELIQUIA, id)
        if item.is_empty():
            continue
        match int(item["efeito"]):
            Itens.FICHAS_POR_NAIPE:
                var naipe := int(item["naipe"])
                for c in cartas:
                    if Cartas.naipe(int(c)) == naipe:
                        fichas += int(item["valor"])
            Itens.MULT_POR_AVESSO:
                mult += int(item["valor"]) * avessos
            Itens.MULT_POR_FRACA:
                mult += int(item["valor"]) * fracas

    return {"fichas": fichas, "mult": mult, "tear": tear, "dinheiro": moedas}

# ──────────────────────────── gravar e ler ────────────────────────────

func para_dicionario() -> Dictionary:
    return {"niveis": Array(niveis), "selos_de_casa": selos_de_casa,
            "selos_de_eixo": selos_de_eixo, "reliquias": reliquias,
            "dinheiro": dinheiro}

static func de_dicionario(d: Dictionary) -> Poderes:
    var p := Poderes.new()
    var lista: Array = d.get("niveis", [])
    for i in mini(lista.size(), Maos.CATEGORIAS):
        p.niveis[i] = int(lista[i])
    for casa in d.get("selos_de_casa", {}):
        p.selos_de_casa[int(casa)] = Array(d["selos_de_casa"][casa])
    for linha in d.get("selos_de_eixo", {}):
        p.selos_de_eixo[int(linha)] = Array(d["selos_de_eixo"][linha])
    for id in d.get("reliquias", []):
        p.reliquias.append(str(id))
    p.dinheiro = int(d.get("dinheiro", 0))
    return p
