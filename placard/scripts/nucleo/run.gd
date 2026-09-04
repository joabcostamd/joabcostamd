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
## Tudo o que a run comprou. É o que cresce junto com a curva de metas.
var poderes := Poderes.new()
## A loja aberta agora, ou nula entre mesas.
var loja: Loja
## O último pagamento, para a tela mostrar de onde veio cada moeda.
var ultimo_pagamento := {}
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
## Categorias que a run já colheu, para o desbloqueio de tema.
var categorias_feitas := {}

## Cartas que a run já colheu e não devolve (geometria 4).
var fora_do_baralho: Array[int] = []
## Linhas que morreram de vez (geometria 7): uma por rodada.
var linhas_mortas: Array[int] = []
## As luzes da Fiança atravessam as mesas e zeram entre runs.
var fianca := 0
## Quantas vezes o Quase lá segurou a run. Vira conquista.
var quase_la := 0
## A TRAVESSIA: depois da rodada 6 o jogo não acaba — ele continua enquanto o
## jogador aguentar. A curva de metas é uma fórmula, então ela não tem fim; o
## que tem fim são as três vidas.
var travessia := false
## A rodada mais funda alcançada. É o placar da travessia.
var rodada_mais_funda := 1
## As marcas que as conquistas leem. Um dicionário achatado: a conquista diz
## qual chave olhar, e a conta é uma comparação — nunca um `if` por conquista.
var marcas := {}

func _init(p_semente: int, p_desafio: Desafio = null) -> void:
    semente = p_semente
    desafio = p_desafio if p_desafio != null else Desafio.new()
    _matar_linha_da_rodada()
    _abrir_mesa()

func _abrir_mesa() -> void:
    var catraca := mini(tentativa - 1, CATRACA_MAX)
    mesa = Mesa.new(indice_da_mesa, rodada, semente, tentativa, desafio, catraca,
                    fianca, fora_do_baralho, linhas_mortas, poderes)

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
    ## Nunca abaixo de quatro linhas vivas: numa travessia longa a regra mataria
    ## as doze, e um tabuleiro sem linha viva não é difícil, é encerrado.
    if linhas_mortas.size() >= Geometria.LINHAS - 4:
        return
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
    _absorver(mesa)
    _marcar_o_estado()

    fianca = mesa.fianca
    ## O pagamento acontece SEMPRE, vitória ou derrota. Sair de uma mesa perdida
    ## com zero no bolso é o que transforma uma mesa perdida em duas.
    ultimo_pagamento = Economia.pagamento(mesa, poderes)
    poderes.dinheiro += int(ultimo_pagamento["total"]) + mesa.moedas_da_mesa
    ultimo_pagamento["selos"] = mesa.moedas_da_mesa
    ultimo_pagamento["total"] = int(ultimo_pagamento["total"]) + mesa.moedas_da_mesa

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
        ## O piso: as cartas mais antigas voltam quando o baralho encolheria
        ## demais. A regra aperta a run inteira; ela não a mata na rodada 4.
        while Cartas.TAMANHO - fora_do_baralho.size() < Desafio.BARALHO_MINIMO:
            fora_do_baralho.pop_front()
    indice_da_mesa += 1
    if indice_da_mesa >= MESAS_POR_RODADA:
        indice_da_mesa = 0
        rodada += 1
        _matar_linha_da_rodada()
    rodada_mais_funda = maxi(rodada_mais_funda, rodada)
    _marcar("rodada_mais_funda", rodada_mais_funda)
    ## Fechar a rodada 6 vence a run — uma vez só, e a vitória não se perde
    ## depois. O que vem a seguir é a TRAVESSIA, e ela é escolha do jogador:
    ## parar aqui com a vitória na mão, ou seguir e ver até onde vai.
    if rodada > Metas.RODADAS and not travessia:
        venceu = true
        _marcar_o_estado()
        return {"pronto": true, "venceu_mesa": true, "fim_da_run": true,
                "venceu_run": true, "pode_continuar": true}
    _abrir_loja()
    _abrir_mesa()
    return {"pronto": true, "venceu_mesa": true, "fim_da_run": false,
            "loja": true}

## A loja abre depois de toda mesa vencida. A semente é derivada da run e da
## posição: a mesma run oferece a mesma loja, e um replay continua verificável.
func _abrir_loja() -> void:
    loja = Loja.new(rodada, Aleatorio.misturar(semente, 314, mesas_concluidas()),
                    desafio)

func fechar_loja() -> void:
    loja = null

## O jogador escolheu seguir depois da rodada 6. A run continua com a mesma
## build, as mesmas vidas e a curva subindo — não há teto, só as três vidas.
func continuar() -> void:
    if acabou:
        return
    travessia = true
    _matar_linha_da_rodada()
    _abrir_loja()
    _abrir_mesa()

## O jogador escolheu parar. A vitória fica registrada.
func encerrar() -> void:
    acabou = true

## Registra o que uma colheita produziu. É daqui que saem os desbloqueios de
## tema: a condição "faça uma Sequência de Cor" precisa de alguém contando.
## Absorve o que a mesa contou. A mesa conta sozinha — quem conta tem de ser quem
## acontece — e a run só junta as marcas de todas elas.
func _absorver(m: Mesa) -> void:
    for chave in m.marcas:
        _marcar(str(chave), int(m.marcas[chave]))
    for chave in m.contas:
        _somar(str(chave), int(m.contas[chave]))
    for cat in Maos.CATEGORIAS:
        if int(m.marcas.get("cat_%d" % cat, 0)) > 0:
            categorias_feitas[cat] = int(categorias_feitas.get(cat, 0)) + 1

## Uma marca guarda o MAIOR valor visto; um contador soma. A diferença importa:
## "colheu 10.000 numa vez" é máximo, "colheu 12 vezes" é soma.
func _marcar(chave: String, valor: int) -> void:
    marcas[chave] = maxi(int(marcas.get(chave, 0)), valor)

func _somar(chave: String, quanto: int) -> void:
    marcas[chave] = int(marcas.get(chave, 0)) + quanto

## As marcas que só existem no fim de uma mesa ou da run.
func _marcar_o_estado() -> void:
    _marcar("selos", poderes.quantos_selos())
    _marcar("reliquias", poderes.reliquias.size())
    var maior := 0
    for cat in Maos.CATEGORIAS:
        maior = maxi(maior, poderes.nivel(cat))
    _marcar("nivel_maximo", maior)
    _marcar("quase_la", quase_la)
    if mesa != null and mesa.meta > 0:
        _marcar("razao_maxima", 100 * mesa.pontos / mesa.meta)
    if venceu:
        _marcar("run_no_grau", maxi(0, desafio.grau_do_dial()))
        if vidas >= VIDAS:
            _marcar("run_limpa", 1)

## A CRUZADA DO CENTRO: um evento que colhe as quatro linhas que passam pela
## casa central. É o melhor jogo do PLACARD e o desbloqueio mais difícil.
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
