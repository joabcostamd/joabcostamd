extends RefCounted
class_name Mesa
## Uma mesa do CRUZADA, inteira, sem uma linha de interface.
##
## Tudo que acontece numa partida acontece aqui: o turno, a Parcela, o Tear, a
## Janela da Colheita, o Avesso, o fecho e a vitória. A tela lê este objeto e
## desenha; ela nunca decide nada.
##
## Determinístico por semente: a mesma semente dá a mesma mesa, sempre. É o que
## torna o replay possível, o teste reprodutível e a repetição da mesa perdida
## (R20) uma coisa justa em vez de um novo sorteio de dificuldade.

const VAZIA := -1

## Um AVESSO é uma carta de duas caras, guardada num inteiro só:
##
##     AVESSO_BASE + cara_da_fileira * 52 + cara_da_coluna
##
## Números abaixo de 52 são cartas comuns; de AVESSO_BASE para cima, Avessos.
## Nada de objeto: a grade é um PackedInt32Array e continua sendo.
const AVESSO_BASE := 1000

# ─────────────────────────── o estado ───────────────────────────

var tipo := Metas.PEQUENA
var rodada := 1
var meta := 0
var posicionamentos_max := 0

var grade := PackedInt32Array()          ## 25 casas; VAZIA onde não há carta
var contagem := PackedInt32Array()       ## cartas em cada uma das 12 linhas
var madura := PackedInt32Array()         ## 1 = linha cheia esperando a colheita
var parcelas_dadas := PackedInt32Array() ## quantos limiares cada linha já pagou

var mao: Array[int] = []
var baralho: Array[int] = []
var descarte: Array[int] = []
var colhida: Array[int] = []

var pontos := 0
var tear := Metas.TEAR_INICIAL
var posicionamentos_usados := 0
var descartes_restantes := 0
var tamanho_da_mao := Metas.MAO_INICIAL

var acabou := false
var venceu := false

## Números que a tela e a autópsia usam. Não influenciam regra nenhuma.
var turno := 0
var colheitas := 0
var cruzadas := 0
var avessos_forjados := 0
var maior_evento := 0

var _rng: Aleatorio        ## o baralho
var _rng_semeadura: Aleatorio  ## a grade inicial (R06c)

# ─────────────────── a carta de duas caras (R21/R22) ───────────────────

static func eh_avesso(carta: int) -> bool:
    return carta >= AVESSO_BASE

## `fileira` é a cara que vale nas fileiras; `coluna`, a que vale nas colunas e
## nas duas diagonais. É a assimetria que faz a pergunta do item existir:
## não "o que esta carta é?", e sim "esta carta é boa para quem?".
static func forjar(cara_da_fileira: int, cara_da_coluna: int) -> int:
    return AVESSO_BASE + cara_da_fileira * 52 + cara_da_coluna

## Um toque na mão troca as caras. Ao ser posicionado, o Avesso congela.
static func girar(carta: int) -> int:
    if not eh_avesso(carta):
        return carta
    var d := carta - AVESSO_BASE
    return forjar(d % 52, d / 52)

## Qual das duas caras vale nesta linha. Carta comum devolve ela mesma.
static func face(carta: int, na_fileira: bool) -> int:
    if not eh_avesso(carta):
        return carta
    var d := carta - AVESSO_BASE
    return (d / 52) if na_fileira else (d % 52)

## Um Avesso conta como DUAS cartas do baralho — foi prensado de duas. Sem isso
## a identidade de conservação (R04) acusaria cartas sumindo a cada colheita.
static func quantas_cartas(carta: int) -> int:
    return 2 if eh_avesso(carta) else 1

# ──────────────────────────── nascer ────────────────────────────

func _init(p_tipo: int, p_rodada: int, semente_run: int, tentativa := 1) -> void:
    tipo = p_tipo
    rodada = p_rodada
    meta = Metas.meta(p_tipo, p_rodada)
    posicionamentos_max = Metas.posicionamentos(p_tipo)
    descartes_restantes = Metas.descartes(p_tipo)

    grade.resize(Geometria.CASAS)
    grade.fill(VAZIA)
    contagem.resize(Geometria.LINHAS)
    contagem.fill(0)
    madura.resize(Geometria.LINHAS)
    madura.fill(0)
    parcelas_dadas.resize(Geometria.LINHAS)
    parcelas_dadas.fill(0)

    ## R06c — dois fluxos, ambos derivados da semente da mesa (R20).
    var semente := Aleatorio.misturar(semente_run, p_rodada * 10 + p_tipo, tentativa)
    _rng = Aleatorio.new(Aleatorio.misturar(semente, 1, 0))
    _rng_semeadura = Aleatorio.new(Aleatorio.misturar(semente, 77, 0))

    baralho = Cartas.baralho()
    _rng.embaralhar(baralho)

    ## R06b — a Pequena nasce com 3 cartas postas, para o turno 1 não ser uma
    ## escolha entre 25 casas equivalentes por simetria.
    if tipo == Metas.PEQUENA:
        for i in 3:
            var vazias := casas_vazias()
            _pousar(vazias[_rng_semeadura.inteiro(vazias.size())], baralho.pop_back())

    comprar_mao()

# ──────────────────────────── o baralho ────────────────────────────

## R04 — baralho vazio reembaralha o descarte; a pilha colhida nunca volta.
func _comprar() -> int:
    if baralho.is_empty():
        if descarte.is_empty():
            return VAZIA
        baralho = descarte.duplicate()
        descarte.clear()
        _rng.embaralhar(baralho)
    return baralho.pop_back()

func comprar_mao() -> void:
    while mao.size() < tamanho_da_mao:
        var carta := _comprar()
        if carta == VAZIA:
            return
        mao.append(carta)

## R03 passo 1 — o descarte não gasta posicionamento.
func descartar(indices: Array) -> bool:
    if descartes_restantes <= 0 or indices.is_empty() or acabou:
        return false
    var ordenados := indices.duplicate()
    ordenados.sort()
    ordenados.reverse()
    for i in ordenados:
        if i < 0 or i >= mao.size():
            return false
    for i in ordenados:
        ## Um Avesso descartado vai inteiro para a pilha: ele pode voltar. Foi
        ## assim que a bancada mediu, e é a leitura mais generosa das duas —
        ## trocar um coringa não deveria destruí-lo.
        descarte.append(mao[i])
        mao.remove_at(i)
    descartes_restantes -= 1
    comprar_mao()
    return true

# ──────────────────────────── a grade ────────────────────────────

func _pousar(casa: int, carta: int) -> void:
    grade[casa] = carta
    for l in Geometria.linhas_da_casa(casa):
        contagem[l] += 1

func _levantar(casa: int) -> void:
    grade[casa] = VAZIA
    for l in Geometria.linhas_da_casa(casa):
        contagem[l] -= 1

func casas_vazias() -> Array[int]:
    var v: Array[int] = []
    for casa in Geometria.CASAS:
        if grade[casa] == VAZIA:
            v.append(casa)
    return v

func pode_posicionar(casa: int) -> bool:
    return not acabou and casa >= 0 and casa < Geometria.CASAS \
        and grade[casa] == VAZIA

## As cartas presentes numa linha, com a cara do Avesso já resolvida.
## `casa_hipotetica` e `carta_hipotetica` permitem perguntar "e se eu pusesse
## esta carta ali?" sem tocar na grade — é como a assistência (§6) calcula.
func cartas_da_linha(linha: int, casa_hipotetica := -1,
                     carta_hipotetica := VAZIA) -> Array:
    var na_fileira := linha < Geometria.COLUNA_0
    var lista := []
    for casa in Geometria.CELULAS[linha]:
        var bruta: int = carta_hipotetica if casa == casa_hipotetica else grade[casa]
        if bruta == VAZIA:
            continue
        lista.append(face(bruta, na_fileira))
    return lista

# ──────────────────── R08 — a Janela da Colheita ────────────────────

func linhas_maduras() -> Array[int]:
    var r: Array[int] = []
    for l in Geometria.LINHAS:
        if madura[l] == 1:
            r.append(l)
    return r

## As linhas que este posicionamento colhe AGORA.
##
## A janela é de exatamente 1 posicionamento: uma linha que enche neste turno
## espera, e uma que já esperava colhe junto com tudo que estiver cheio. Janela
## de 2 e janela até o fim foram medidas e reprovadas — a profundidade estoura
## (76,3% e 77,8% contra o teto de 75%) e a mesa vira um clique só.
func _alvo(novas: Array, ultimo_posicionamento: bool) -> Array[int]:
    var cheias := linhas_maduras()
    for l in novas:
        if not cheias.has(l):
            cheias.append(l)
    if cheias.is_empty():
        return [] as Array[int]
    ## O último posicionamento da mesa colhe na hora: não há próximo turno.
    if ultimo_posicionamento:
        return cheias
    ## Sem nenhuma madura esperando, ninguém dispara: as novas só amadurecem.
    if linhas_maduras().is_empty():
        return [] as Array[int]
    ## Colheita conjunta livre: tudo que estiver cheio vai junto, sem exigir
    ## perpendicularidade (93,8% já são perpendiculares sozinhas; exigir
    ## muda −1%) e sem limite por mesa (medido no-op).
    return cheias

# ──────────────────────── R03 — o posicionamento ────────────────────────

## O coração do jogo. Devolve o relatório do que aconteceu — a tela lê isto para
## animar, e a autópsia para explicar.
func posicionar(indice_na_mao: int, casa: int) -> Dictionary:
    var relato := _relato_vazio()
    if acabou or indice_na_mao < 0 or indice_na_mao >= mao.size() \
            or not pode_posicionar(casa):
        relato["valido"] = false
        return relato

    var carta: int = mao[indice_na_mao]
    var ultimo := posicionamentos_usados + 1 >= posicionamentos_max

    ## O que enche com esta carta, e o que colhe agora.
    var novas: Array[int] = []
    for l in Geometria.linhas_da_casa(casa):
        if contagem[l] == Geometria.LADO - 1:
            novas.append(l)
    var alvo := _alvo(novas, ultimo)

    ## R13 — as parcelas candidatas, medidas ANTES de a colheita mexer na grade.
    ## Uma linha que chega a 3/5 ou 4/5 e ainda não pagou aquele limiar.
    var candidatas := []
    for l in Geometria.linhas_da_casa(casa):
        var depois: int = contagem[l] + 1
        if (depois == 3 or depois == 4) and parcelas_dadas[l] < 2:
            candidatas.append([l, depois, _valor_da_parcela(l, casa, carta)])

    ## Aplica o posicionamento.
    mao.remove_at(indice_na_mao)
    _pousar(casa, carta)
    posicionamentos_usados += 1
    turno += 1
    relato["casa"] = casa
    relato["carta"] = carta

    ## O que encheu e não colheu fica maduro, esperando o próximo turno.
    for l in novas:
        if not alvo.has(l):
            madura[l] = 1
            relato["maduras_novas"].append(l)

    if not alvo.is_empty():
        _colher(alvo, relato)

    ## R13 — a parcela só paga se a linha realmente ficou naquele tamanho. Uma
    ## colheita cruzada pode ter esvaziado a linha no meio do caminho, e aí não
    ## há promessa nenhuma para pagar.
    var pontos_parcela := 0
    for c in candidatas:
        var l: int = c[0]
        if contagem[l] == int(c[1]) and madura[l] == 0:
            pontos_parcela += int(c[2])
            parcelas_dadas[l] += 1
            relato["parcelas"].append({"linha": l, "cartas": int(c[1]),
                                       "pontos": int(c[2])})
    if pontos_parcela > 0:
        pontos += pontos_parcela
        relato["pontos_parcela"] = pontos_parcela

    ## R14 — o tique do Tear, a cada 4 posicionamentos.
    if posicionamentos_usados % Metas.TEAR_POR_TIQUE == 0 and tear < Metas.TEAR_TETO:
        tear += 1
        relato["tique_do_tear"] = true

    comprar_mao()
    relato["tear"] = tear
    relato["pontos_total"] = relato["pontos_evento"] + pontos_parcela
    _conferir_fim(relato)
    return relato

func _relato_vazio() -> Dictionary:
    return {
        "valido": true, "casa": -1, "carta": VAZIA,
        "colheita": false, "linhas": [], "pontos_evento": 0, "fator": 0,
        "grau": "", "cruzada": false,
        "maduras_novas": [] as Array[int],
        "parcelas": [], "pontos_parcela": 0,
        "avessos": [], "troco": {},
        "tique_do_tear": false, "tear": tear, "tear_do_evento": tear,
        "soma_dos_mults": 0,
        "pontos_total": 0, "acabou": false, "venceu": false,
    }

# ──────────────────── R11/R12 — a conta da colheita ────────────────────

const GRAUS: PackedStringArray = ["", "colheita", "DUPLA", "TRIPLA", "CRUZ TOTAL"]

## A conta de um evento, SEM tocar em nada. A colheita usa para pagar e a
## assistência (§6) usa para responder "quanto eu ganho se puser aqui?" — a mesma
## conta nos dois lugares, que é a única forma de a dica não mentir.
##
## `casa`/`carta` permitem perguntar sobre uma jogada que ainda não aconteceu.
func conta_do_evento(alvo: Array, casa := -1, carta := VAZIA) -> Dictionary:
    var linhas := []
    var categorias: Array[int] = []
    for l: int in alvo:
        var cartas := cartas_da_linha(l, casa, carta)
        if cartas.size() != Geometria.LADO:
            continue
        var cat := Maos.categoria(cartas[0], cartas[1], cartas[2], cartas[3], cartas[4])
        categorias.append(cat)
        linhas.append({
            "linha": l, "categoria": cat, "nome": Maos.NOMES[cat],
            "fichas": Maos.fichas_da_linha(cartas), "pontos": 0,
            "diagonal": Geometria.diagonal(l), "cartas": cartas,
        })
    var fator := Maos.fator_do_evento(categorias, tear)
    var total := 0
    for linha in linhas:
        var p := Maos.pontos_da_linha(int(linha["fichas"]), fator,
                                      bool(linha["diagonal"]))
        linha["pontos"] = p
        total += p
    return {"linhas": linhas, "fator": fator, "total": total,
            "soma_dos_mults": fator / maxi(1, tear), "tear": tear}

func _colher(alvo: Array, relato: Dictionary) -> void:
    ## Primeiro a conta, com a grade ainda intacta.
    var conta := conta_do_evento(alvo)
    var total: int = conta["total"]
    var troco_tear := 0
    var troco_descartes := 0
    var troco_mao := 0
    for linha in conta["linhas"]:
        relato["linhas"].append(linha)
        ## R16 — o troco da linha fraca. Devolve recurso, não pontos: é o que
        ## reembolsa quem planejou a cruz e teve de encher a linha com o que veio.
        if Maos.devolve_troco(int(linha["categoria"])):
            troco_tear += Maos.TROCO_TEAR
            troco_descartes += Maos.TROCO_DESCARTES
            troco_mao += Maos.TROCO_MAO

    pontos += total
    colheitas += 1
    if total > maior_evento:
        maior_evento = total
    relato["colheita"] = true
    relato["pontos_evento"] = total
    relato["fator"] = conta["fator"]
    ## O Tear que valeu NESTE evento, antes de a colheita levantá-lo. É o número
    ## que a tela mostra na animação — o de depois seria uma promessa, não a conta.
    relato["tear_do_evento"] = tear
    relato["soma_dos_mults"] = conta["soma_dos_mults"]
    relato["grau"] = GRAUS[mini(alvo.size(), 4)]
    if alvo.size() >= 2:
        cruzadas += 1
        relato["cruzada"] = true

    ## R21 — a forja do Avesso, antes de as cartas saírem da grade.
    var avessos := _forjar_avessos(alvo)
    relato["avessos"] = avessos

    ## Limpa as casas colhidas.
    var prensadas := {}
    for a in avessos:
        for casa: int in a["casas"]:
            prensadas[casa] = true
    var remover := {}
    for l: int in alvo:
        for casa: int in Geometria.CELULAS[l]:
            remover[casa] = true
    for casa: int in remover:
        var carta: int = grade[casa]
        if carta == VAZIA:
            continue
        ## As cartas prensadas num Avesso não vão para a pilha colhida: elas
        ## voltam ao baralho dentro dele.
        if not prensadas.has(casa):
            if eh_avesso(carta):
                colhida.append(face(carta, true))
                colhida.append(face(carta, false))
            else:
                colhida.append(carta)
        _levantar(casa)

    ## Os Avessos recém-forjados vão para o topo do baralho: chegam à mão no
    ## turno seguinte (espera mediana medida: 1 turno).
    for a in avessos:
        baralho.push_back(int(a["carta"]))
        avessos_forjados += 1

    ## R14 — o Tear sobe uma vez por linha colhida.
    tear = mini(Metas.TEAR_TETO, tear + conta["linhas"].size())

    ## As colhidas deixam de ser maduras; e uma madura que perdeu carta para uma
    ## colheita perpendicular deixa de estar cheia, então também deixa de esperar.
    for l: int in alvo:
        madura[l] = 0
    for l in Geometria.LINHAS:
        if madura[l] == 1 and contagem[l] < Geometria.LADO:
            madura[l] = 0

    if troco_tear > 0 or troco_descartes > 0 or troco_mao > 0:
        tear = mini(Metas.TEAR_TETO, tear + troco_tear)
        descartes_restantes += troco_descartes
        tamanho_da_mao += troco_mao
        relato["troco"] = {"tear": troco_tear, "descartes": troco_descartes,
                           "mao": troco_mao}

## R21 — cada linha colhida prensa as suas DUAS CARTAS DE MAIOR VALOR num
## Avesso. O gatilho é toda colheita, sem exigir categoria: exigir Trinca+
## derruba de 1,66 para 0,97 por mesa e exigir Flush+ derruba para 0,42 — nesse
## ponto o item vira decoração.
func _forjar_avessos(alvo: Array) -> Array:
    var forjados := []
    var consumidas := {}
    for l: int in alvo:
        var na_fileira := l < Geometria.COLUNA_0
        var ordem := []
        for casa in Geometria.CELULAS[l]:
            if grade[casa] == VAZIA or consumidas.has(casa):
                continue
            ordem.append([Cartas.fichas(face(grade[casa], na_fileira)), casa])
        if ordem.size() < 2:
            continue
        ## Desempate pela casa, para a forja ser determinística: duas cartas de
        ## mesmo valor não podem depender da ordem em que o sort as encontrou.
        ordem.sort_custom(func(a, b):
            return a[0] > b[0] if a[0] != b[0] else a[1] < b[1])
        var casa_a: int = ordem[0][1]
        var casa_b: int = ordem[1][1]
        ## A cara que fica é a que estava valendo nesta linha; a outra cara de um
        ## Avesso reprensado volta para a pilha colhida, e a conta fecha.
        var cara_a := face(grade[casa_a], na_fileira)
        var cara_b := face(grade[casa_b], na_fileira)
        if eh_avesso(grade[casa_a]):
            colhida.append(face(grade[casa_a], not na_fileira))
        if eh_avesso(grade[casa_b]):
            colhida.append(face(grade[casa_b], not na_fileira))
        consumidas[casa_a] = true
        consumidas[casa_b] = true
        forjados.append({"linha": l, "casas": [casa_a, casa_b],
                         "carta": forjar(cara_a, cara_b)})
    return forjados

# ───────────────── a pergunta da assistência (§6) ─────────────────

## Qualquer posicionamento já dispara colheita? Verdadeiro quando existe linha
## madura esperando (a janela expira no próximo turno, seja ele qual for) ou
## quando este é o último posicionamento da mesa.
func gatilho_pendente() -> bool:
    if posicionamentos_usados + 1 >= posicionamentos_max:
        return true
    return not linhas_maduras().is_empty()

## As casas onde um posicionamento pode fechar linha — as vazias de uma linha em
## 4/5. Fora delas, nenhuma jogada colhe.
func casas_criticas() -> Array[int]:
    var s := {}
    for l in Geometria.LINHAS:
        if contagem[l] == Geometria.LADO - 1:
            for casa in Geometria.CELULAS[l]:
                if grade[casa] == VAZIA:
                    s[casa] = true
    var r: Array[int] = []
    for casa in s:
        r.append(casa)
    return r

## As linhas que uma jogada colheria, sem executá-la.
func alvo_de(casa: int) -> Array[int]:
    var novas: Array[int] = []
    for l in Geometria.linhas_da_casa(casa):
        if contagem[l] == Geometria.LADO - 1:
            novas.append(l)
    return _alvo(novas, posicionamentos_usados + 1 >= posicionamentos_max)

## Só os pontos da colheita — sem as parcelas.
func ganho_de_colheita(carta: int, casa: int) -> int:
    if not pode_posicionar(casa):
        return 0
    var alvo := alvo_de(casa)
    if alvo.is_empty():
        return 0
    return int(conta_do_evento(alvo, casa, carta)["total"])

## Quanto esta jogada paga AGORA — colheita mais parcelas — sem alterar a mesa.
##
## É o número que o nível 3 das DICAS mostra, e o rótulo dele é "maior ganho
## agora", nunca "melhor jogada": medimos que ele não é o melhor em 41% dos
## turnos, e uma lista ordenada por ganho imediato sempre manda fechar a linha em
## 4/5 — que é exatamente o que impede a cruzada.
func ganho(indice_na_mao: int, casa: int) -> int:
    if indice_na_mao < 0 or indice_na_mao >= mao.size() or not pode_posicionar(casa):
        return 0
    var carta: int = mao[indice_na_mao]
    var alvo := alvo_de(casa)
    var total := 0
    if not alvo.is_empty():
        total += int(conta_do_evento(alvo, casa, carta)["total"])
    for l in Geometria.linhas_da_casa(casa):
        if alvo.has(l):
            continue
        var depois: int = contagem[l] + 1
        if (depois == 3 or depois == 4) and parcelas_dadas[l] < 2:
            total += _valor_da_parcela(l, casa, carta)
    return total

## O peso de uma linha por quantas cartas ela já tem. Uma linha com 1 carta quase
## não promete nada; com 4 ela é uma promessa quase inteira. A curva é medida:
## foi ela que fez o simulador jogar como gente em vez de encher casa à toa.
const PESO_POR_CARTA: PackedFloat32Array = [0.0, 0.02, 0.08, 0.30, 0.75, 1.0]

## Quanto esta linha ainda PROMETE: a melhor categoria que ela ainda alcança,
## projetada para 5 cartas e pesada pelo quanto já está montada.
##
## É a diferença entre um jogador que enche casas e um que monta mãos. Sem esta
## conta, o simulador colhe Par em 54% das linhas; com ela, colhe Trinca, Flush e
## Quadra nas taxas que a bancada mediu.
func potencial_da_linha(linha: int, extra := VAZIA) -> float:
    var cartas := cartas_da_linha(linha)
    if extra != VAZIA:
        cartas.append(face(extra, linha < Geometria.COLUNA_0))
    var k := cartas.size()
    if k == 0 or k > Geometria.LADO:
        return 0.0
    var cat := Maos.melhor_alcancavel(cartas)
    var projetadas := float(Maos.fichas_de(cartas)) * float(Geometria.LADO) / float(k)
    var v := (float(Maos.FICHAS_BASE[cat]) + projetadas) \
             * float(Maos.MULTIPLICADOR[cat] * tear) * PESO_POR_CARTA[k]
    if Geometria.diagonal(linha):
        v *= Maos.PISO_DIAGONAL
    return v

## R22 — girar um Avesso na mão troca as caras. Numa carta comum, não faz nada.
func girar_na_mao(indice_na_mao: int) -> bool:
    if indice_na_mao < 0 or indice_na_mao >= mao.size():
        return false
    if not eh_avesso(mao[indice_na_mao]):
        return false
    mao[indice_na_mao] = girar(mao[indice_na_mao])
    return true

## A jogada de maior ganho imediato: [indice_na_mao, casa, ganho].
func maior_ganho_agora() -> Array:
    var melhor := [-1, -1, -1]
    for i in mao.size():
        for casa in casas_vazias():
            var g := ganho(i, casa)
            if g > int(melhor[2]):
                melhor = [i, casa, g]
    if int(melhor[0]) < 0 and not mao.is_empty():
        var vazias := casas_vazias()
        if not vazias.is_empty():
            melhor = [0, vazias[0], 0]
    return melhor

# ──────────────────────── R13 — o valor da parcela ────────────────────────

func _valor_da_parcela(linha: int, casa: int, carta: int) -> int:
    var cartas := cartas_da_linha(linha, casa, carta)
    return Maos.pontos_parciais(cartas, Geometria.diagonal(linha), tear,
                                Metas.PARCELA)

# ─────────────────────── R19/R20 — o fim da mesa ───────────────────────

func _conferir_fim(relato: Dictionary) -> void:
    ## R20 — bater a meta encerra na hora, com vitória.
    if pontos >= meta:
        acabou = true
        venceu = true
    elif posicionamentos_usados >= posicionamentos_max:
        ## R19 — o fecho conta para a meta, e por isso é calculado ANTES de
        ## decidir a derrota. Este `if` na ordem errada valia 6,1 pontos
        ## percentuais de vitória: o fecho nunca virava a mesa.
        var fecho := colheita_final()
        relato["fecho"] = fecho
        acabou = true
        venceu = pontos >= meta
    relato["acabou"] = acabou
    relato["venceu"] = venceu

## R19 — o que sobrou. Primeiro as maduras, inteiras; depois as linhas com 3 ou
## 4 cartas, por metade. Linha com 1 ou 2 cartas não paga nada.
func colheita_final() -> Dictionary:
    var resultado := {"maduras": {}, "pontos_maduras": 0, "linhas": [],
                      "pontos_fecho": 0, "total": 0}
    var restantes := linhas_maduras()
    if not restantes.is_empty():
        var relato := _relato_vazio()
        _colher(restantes, relato)
        resultado["maduras"] = relato
        resultado["pontos_maduras"] = relato["pontos_evento"]

    var fecho := 0
    for l in Geometria.LINHAS:
        if contagem[l] < 3:
            continue
        var cartas := cartas_da_linha(l)
        var p := Maos.pontos_parciais(cartas, Geometria.diagonal(l), tear,
                                      Metas.FECHO)
        if p <= 0:
            continue
        fecho += p
        resultado["linhas"].append({"linha": l, "cartas": cartas.size(), "pontos": p})
    pontos += fecho
    resultado["pontos_fecho"] = fecho
    resultado["total"] = int(resultado["pontos_maduras"]) + fecho
    return resultado

# ───────────────────── R04 — a conservação das pilhas ─────────────────────

## `52 = mão + grade + colhida + baralho + descarte`, verdadeira a todo instante.
## Um Avesso conta como duas — foi prensado de duas.
func cartas_em_jogo() -> int:
    var total := 0
    for lista in [mao, baralho, descarte, colhida]:
        for carta in lista:
            total += quantas_cartas(carta)
    for casa in Geometria.CASAS:
        if grade[casa] != VAZIA:
            total += quantas_cartas(grade[casa])
    return total

func conservacao() -> bool:
    return cartas_em_jogo() == Cartas.TAMANHO
