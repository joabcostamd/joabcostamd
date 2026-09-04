extends RefCounted
class_name Politica
## Jogadores simulados. Existem para AFERIR o motor, não para jogar por ninguém.
##
## A política GULOSA aqui não é "clicar em qualquer lugar": ela é a mesma da
## bancada que produziu os números do DESIGN §9 — colher quando dá, e, quando não
## dá, fazer as linhas prometerem mais. É o jogador competente mas sem plano, e
## é contra ele que as bandas foram calibradas.
##
## O detalhe que decide tudo está no `dp`: sem a conta de potencial, o simulador
## enche casas ao acaso e colhe Par em metade das linhas; com ela, colhe Trinca,
## Flush e Quadra nas taxas medidas. A diferença entre os dois é a diferença
## entre medir o jogo e medir ruído.

## Escolhe uma jogada: [indice_na_mao, casa, carta_efetiva].
## `carta_efetiva` pode ser um Avesso girado — a política considera as duas caras.
static func gulosa(m: Mesa) -> Array:
    var vazias := m.casas_vazias()
    if vazias.is_empty() or m.mao.is_empty():
        return [-1, -1, Mesa.VAZIA]

    ## Onde uma jogada pode colher. Com linha madura esperando, qualquer casa
    ## colhe — a janela expira no próximo posicionamento, seja ele qual for.
    var criticas := {}
    if m.gatilho_pendente():
        for casa in vazias:
            criticas[casa] = true
    else:
        for casa in m.casas_criticas():
            criticas[casa] = true

    var potencial_agora := PackedFloat32Array()
    potencial_agora.resize(Geometria.LINHAS)
    for l in Geometria.LINHAS:
        potencial_agora[l] = m.potencial_da_linha(l)

    ## Cada carta da mão entra uma vez; um Avesso entra duas, uma por cara.
    var variantes := []
    for i in m.mao.size():
        var carta: int = m.mao[i]
        variantes.append([i, carta])
        if Mesa.eh_avesso(carta):
            variantes.append([i, Mesa.girar(carta)])

    var melhor := [-1, -1, Mesa.VAZIA]
    var melhor_nota := -1.0e30
    for v in variantes:
        var indice: int = v[0]
        var carta: int = v[1]
        for casa in vazias:
            var imediato := 0
            if criticas.has(casa):
                imediato = m.ganho_de_colheita(carta, casa)
            ## Quanto as linhas desta casa passam a prometer.
            var delta := 0.0
            for l in Geometria.linhas_da_casa(casa):
                delta += m.potencial_da_linha(l, carta) - potencial_agora[l]
            ## Colher vem sempre antes de prometer: a ordem é léxica, não uma
            ## soma ponderada. Pontos na mão valem mais que pontos no futuro.
            var nota := float(imediato) * 1000000.0 + delta
            if nota > melhor_nota:
                melhor_nota = nota
                melhor = [indice, casa, carta]
    return melhor

## O descarte da política gulosa, com a mesma régua da bancada: só quando nada
## colhe agora, só com folga de orçamento, e só as cartas que prometem bem menos
## que a melhor da mão. Um jogador que nunca troca é um jogador pior que o real,
## e calibrar a dificuldade contra ele daria um jogo fácil demais.
static func talvez_descartar(m: Mesa) -> bool:
    if m.descartes_restantes <= 0:
        return false
    if m.posicionamentos_max - m.posicionamentos_usados < 4:
        return false
    var vazias := m.casas_vazias()
    if vazias.is_empty() or m.mao.size() < 2:
        return false

    ## Se alguma jogada colhe agora, não se troca nada: colher vem primeiro.
    for i in m.mao.size():
        for casa in vazias:
            if m.ganho_de_colheita(m.mao[i], casa) > 0:
                return false

    var potencial_agora := PackedFloat32Array()
    potencial_agora.resize(Geometria.LINHAS)
    for l in Geometria.LINHAS:
        potencial_agora[l] = m.potencial_da_linha(l)

    ## O quanto cada carta da mão promete, na melhor casa dela.
    var util := []
    var melhor := -1.0e30
    for i in m.mao.size():
        var melhor_da_carta := -1.0e30
        for casa in vazias:
            var delta := 0.0
            for l in Geometria.linhas_da_casa(casa):
                delta += m.potencial_da_linha(l, m.mao[i]) - potencial_agora[l]
            if delta > melhor_da_carta:
                melhor_da_carta = delta
        util.append([i, melhor_da_carta])
        if melhor_da_carta > melhor:
            melhor = melhor_da_carta

    var corte := melhor * 0.35 if melhor > 0.0 else melhor
    var fracas := []
    for x in util:
        if float(x[1]) < corte:
            fracas.append(int(x[0]))
    ## Trocar uma carta só quase nunca compensa: gasta um descarte inteiro.
    if fracas.size() < 2:
        return false
    if fracas.size() > 3:
        util.sort_custom(func(a, b): return float(a[1]) < float(b[1]))
        fracas = [int(util[0][0]), int(util[1][0]), int(util[2][0])]
    return m.descartar(fracas)

## Joga uma mesa inteira com a política gulosa. Devolve a própria mesa, no fim.
static func jogar(m: Mesa, limite := 400) -> Mesa:
    var passos := 0
    while not m.acabou and passos < limite:
        passos += 1
        talvez_descartar(m)
        var jogada := gulosa(m)
        if int(jogada[0]) < 0:
            break
        ## A política pode ter escolhido a outra cara de um Avesso.
        if int(jogada[2]) != m.mao[int(jogada[0])]:
            m.girar_na_mao(int(jogada[0]))
        if not bool(m.posicionar(int(jogada[0]), int(jogada[1]))["valido"]):
            break
    return m

# ─────────────────────────── o comprador ───────────────────────────

## Um comprador simulado, para medir se a loja resolve a curva. Ele NÃO é o
## jogador: é o jogador mediano — compra o que couber no bolso, do mais caro
## para o mais barato, e cola os selos onde a geometria toca mais linhas.
##
## Se a rodada 6 ficar possível com ESTE comprador, ela fica possível para
## qualquer um que preste atenção. Medir com um comprador ótimo mediria o teto,
## e o teto não é onde as pessoas jogam.
static func comprar(loja: Loja, poderes: Poderes) -> int:
    if loja == null:
        return 0
    var compras := 0
    var voltas := 0
    while voltas < 8:
        voltas += 1
        var melhor := -1
        var melhor_preco := -1
        for i in loja.vagas.size():
            if not loja.pode_comprar(i, poderes):
                continue
            var preco := loja.preco_da_vaga(i, poderes)
            if preco > melhor_preco:
                melhor_preco = preco
                melhor = i
        if melhor < 0:
            break
        if not loja.comprar(melhor, poderes, _onde_colar(loja, melhor, poderes)).is_empty():
            compras += 1
    return compras

## Onde colar. As casas valem por quantas linhas passam por elas — o centro toca
## quatro, os cantos três, o resto duas — e as linhas valem pelo que já carregam.
## É a mesma conta que um jogador atento faz olhando a grade.
static func _onde_colar(loja: Loja, i: int, poderes: Poderes) -> int:
    match loja.precisa_de_alvo(i):
        0:
            var melhor := Geometria.CASAS / 2
            var melhor_nota := -1
            for casa in Geometria.CASAS:
                ## Espalhar: duas Brasas na mesma casa somam, mas uma casa só
                ## participa das linhas dela, e a grade tem doze.
                var nota := Geometria.linhas_da_casa(casa).size() * 10
                nota -= int(poderes.selos_de_casa.get(casa, []).size()) * 12
                if nota > melhor_nota:
                    melhor_nota = nota
                    melhor = casa
            return melhor
        1:
            ## Diagonais por último: elas pagam 60%, então um selo nelas rende
            ## menos — a não ser que o selo seja justamente a Bússola.
            var eh_bussola := str(loja.vagas[i].get("id", "")) == "bussola"
            var melhor := 0
            var melhor_nota := -999
            for l in Geometria.LINHAS:
                var nota := 0
                if Geometria.diagonal(l):
                    nota = 20 if eh_bussola else -20
                nota -= int(poderes.selos_de_eixo.get(l, []).size()) * 12
                if nota > melhor_nota:
                    melhor_nota = nota
                    melhor = l
            return melhor
    return -1

## Uma run inteira com loja: joga a mesa, compra o que der, segue.
##
## `travessia` decide o que fazer quando a rodada 6 fecha: o padrão é PARAR, que
## é o que o jogador mediano faz com a vitória na mão. Medir a travessia é outra
## pergunta, e ela tem o seu próprio parâmetro.
static func jogar_run(run: Run, limite := 90, travessia := false,
                      ate_a_rodada := 0) -> Run:
    var voltas := 0
    while not run.acabou and voltas < limite:
        voltas += 1
        jogar(run.mesa)
        var passo := run.concluir_mesa()
        if bool(passo.get("pode_continuar", false)):
            if travessia and (ate_a_rodada <= 0 or run.rodada <= ate_a_rodada):
                run.continuar()
            else:
                run.encerrar()
                break
        if run.loja != null:
            comprar(run.loja, run.poderes)
            run.fechar_loja()
    return run
