extends SceneTree
## Suíte da economia, dos poderes e da loja.
##
## É o sistema que transforma "impossível" em "difícil": sem ele a vitória da
## rodada 6 é ZERO, medido. Um erro aqui volta a fechar a porta, e a porta
## fechada não aparece como bug — aparece como desistência.
##
##     godot --headless --script res://testes/loja.gd

var _passou := 0
var _falhou := 0

func _init() -> void:
    _niveis()
    _selos_de_casa()
    _selos_de_eixo()
    _reliquias()
    _dinheiro()
    _vitrine()
    _a_promessa()

    print("")
    if _falhou > 0:
        print("LOJA: %d de %d asserções FALHARAM" % [_falhou, _passou + _falhou])
        quit(1)
        return
    print("LOJA OK — %d asserções" % _passou)
    quit(0)

func secao(nome: String) -> void:
    print("── %s" % nome)

func ok(condicao: bool, descricao: String) -> void:
    if condicao:
        _passou += 1
    else:
        _falhou += 1
        print("   FALHA  %s" % descricao)

func igual(obtido: Variant, esperado: Variant, descricao: String) -> void:
    if obtido == esperado:
        _passou += 1
    else:
        _falhou += 1
        print("   FALHA  %s — obtive %s, esperava %s"
              % [descricao, str(obtido), str(esperado)])

func c(naipe: int, indice: int) -> int:
    return naipe * 13 + indice

## Uma mesa com um flush de copas montado na fileira 1, para medir a conta.
func com_flush(poderes: Poderes = null) -> Mesa:
    var m := Mesa.new(Metas.CHEFE, 1, 5, 1, null, 0, 0, [], [], poderes)
    var flush := [c(Cartas.COPAS, 0), c(Cartas.COPAS, 3), c(Cartas.COPAS, 6),
                  c(Cartas.COPAS, 9), c(Cartas.COPAS, 12)]
    for i in 5:
        m.grade[Geometria.CELULAS[0][i]] = flush[i]
    return m

# ─────────────────────────── R24 — níveis de mão ───────────────────────────

func _niveis() -> void:
    secao("níveis de mão (R24)")
    var p := Poderes.new()
    igual(p.fichas_base(Maos.FULL), 40, "Full House começa em 40 fichas")
    igual(p.mult_da_categoria(Maos.FULL), 4, "e mult 4")

    igual(Itens.passo_de_fichas(Maos.FULL), 14, "o passo do Full House é 14")
    igual(Itens.passo_de_fichas(Maos.SEQ_COR), 35, "o da Sequência de Cor é 35")
    igual(Itens.passo_de_fichas(Maos.PAR), 8, "o do Par bate no piso de 8")

    for i in 3:
        p.subir_nivel(Maos.FULL)
    igual(p.fichas_base(Maos.FULL), 40 + 3 * 14,
          "três níveis: 40 + 3×14, e o passo NÃO é composto")
    igual(p.mult_da_categoria(Maos.FULL), 7, "e o mult sobe 1 por nível")
    igual(p.fichas_base(Maos.FLUSH), 35, "as outras categorias não se mexem")

    ## O nível entra na conta do evento de verdade.
    var sem := com_flush()
    var forte := Poderes.new()
    forte.subir_nivel(Maos.FLUSH)
    var com := com_flush(forte)
    ok(int(com.conta_do_evento([0])["total"]) > int(sem.conta_do_evento([0])["total"]),
       "o nível comprado paga mais na mesa")
    igual(int(com.conta_do_evento([0])["soma_dos_mults"]),
          int(sem.conta_do_evento([0])["soma_dos_mults"]) + 1,
          "o mult do evento sobe com o nível")

# ─────────────────────────── R25 — selos de casa ───────────────────────────

func _selos_de_casa() -> void:
    secao("selos de casa (R25)")
    var base := com_flush()
    var antes := int(base.conta_do_evento([0])["total"])

    var p := Poderes.new()
    p.colar_na_casa(Geometria.CELULAS[0][2], "brasa")
    var com := com_flush(p)
    var conta := com.conta_do_evento([0])
    igual(int(conta["linhas"][0]["fichas"]),
          int(base.conta_do_evento([0])["linhas"][0]["fichas"]) + 30,
          "a Brasa soma 30 fichas à linha que passa pela casa dela")
    ok(int(conta["total"]) > antes, "e a linha paga mais")

    ## O MESMO selo em casas diferentes é uma build diferente: a casa central
    ## participa de quatro linhas, o canto de três, a borda de duas.
    var centro := Poderes.new()
    centro.colar_na_casa(Geometria.CASAS / 2, "cunha")
    igual(Geometria.linhas_da_casa(Geometria.CASAS / 2).size(), 4,
          "o centro toca quatro linhas")
    igual(Geometria.linhas_da_casa(1).size(), 2, "a borda toca duas")

    var mult := Poderes.new()
    mult.colar_na_casa(Geometria.CELULAS[0][0], "cunha")
    igual(int(com_flush(mult).conta_do_evento([0])["soma_dos_mults"]),
          int(base.conta_do_evento([0])["soma_dos_mults"]) + 2,
          "a Cunha soma 2 mult à linha")

    ## O Espelho dobra as fichas da carta daquela casa.
    var espelho := Poderes.new()
    espelho.colar_na_casa(Geometria.CELULAS[0][0], "espelho")
    igual(int(com_flush(espelho).conta_do_evento([0])["linhas"][0]["fichas"]),
          int(base.conta_do_evento([0])["linhas"][0]["fichas"])
              + Cartas.fichas(c(Cartas.COPAS, 0)),
          "o Espelho dobra a carta da casa — e um Ás vale 11")

    ## Dois selos na mesma casa somam.
    var dois := Poderes.new()
    dois.colar_na_casa(Geometria.CELULAS[0][0], "brasa")
    dois.colar_na_casa(Geometria.CELULAS[0][0], "lastro")
    igual(int(com_flush(dois).conta_do_evento([0])["linhas"][0]["fichas"]),
          int(base.conta_do_evento([0])["linhas"][0]["fichas"]) + 85,
          "dois selos na mesma casa empilham")

    ## O Cofre paga dinheiro quando a casa colhe.
    var cofre := Poderes.new()
    cofre.colar_na_casa(0, "cofre")
    var m := Mesa.new(Metas.CHEFE, 1, 5, 1, null, 0, 0, [], [], cofre)
    for casa in 5:
        m.posicionar(0, casa)
    m.posicionar(0, 5)
    igual(m.moedas_da_mesa, 2, "o Cofre pagou $2 na colheita")

# ─────────────────────────── R26 — selos de eixo ───────────────────────────

func _selos_de_eixo() -> void:
    secao("selos de eixo (R26)")
    var base := com_flush()
    var p := Poderes.new()
    p.colar_no_eixo(0, "bordado")
    igual(int(com_flush(p).conta_do_evento([0])["soma_dos_mults"]),
          int(base.conta_do_evento([0])["soma_dos_mults"]) + 3,
          "o Bordado soma 3 mult à linha dele")

    var outra := Poderes.new()
    outra.colar_no_eixo(1, "bordado")
    igual(int(com_flush(outra).conta_do_evento([0])["soma_dos_mults"]),
          int(base.conta_do_evento([0])["soma_dos_mults"]),
          "e não vale para as outras linhas")

    ## A Bússola tira o piso de 60% de UMA diagonal.
    var b := Poderes.new()
    igual(b.piso_da_diagonal(Geometria.DIAGONAL_0), Maos.PISO_DIAGONAL,
          "sem selo, a diagonal paga 60%")
    b.colar_no_eixo(Geometria.DIAGONAL_0, "bussola")
    igual(b.piso_da_diagonal(Geometria.DIAGONAL_0), 1.0,
          "com a Bússola, ela paga inteiro")
    igual(b.piso_da_diagonal(Geometria.DIAGONAL_0 + 1), Maos.PISO_DIAGONAL,
          "a outra diagonal continua a 60%")

# ─────────────────────────── R27 — relíquias ───────────────────────────

func _reliquias() -> void:
    secao("relíquias (R27)")
    var p := Poderes.new()
    igual(p.tear_inicial(), Metas.TEAR_INICIAL, "sem relíquia, o Tear começa em 1")
    p.guardar_reliquia("novelo")
    igual(p.tear_inicial(), 4, "o Novelo começa o Tear em 4")
    igual(Mesa.new(Metas.PEQUENA, 1, 5, 1, null, 0, 0, [], [], p).tear, 4,
          "e a mesa nasce com ele")

    var teto := Poderes.new()
    teto.guardar_reliquia("roca")
    igual(teto.tear_teto(), 12, "a Roca leva o teto do Tear a 12")

    var mao := Poderes.new()
    mao.guardar_reliquia("manga")
    igual(mao.tamanho_da_mao(), Metas.MAO_INICIAL + 2, "a Manga larga dá +2 na mão")
    igual(Mesa.new(Metas.PEQUENA, 1, 5, 1, null, 0, 0, [], [], mao).mao.size(),
          Metas.MAO_INICIAL + 2, "e a mesa nasce com a mão maior")

    var espaco := Poderes.new()
    espaco.guardar_reliquia("sirga")
    igual(Mesa.new(Metas.PEQUENA, 1, 5, 1, null, 0, 0, [], [], espaco).posicionamentos_max,
          15 + 3, "a Sirga dá +3 posicionamentos")

    ## Duas relíquias do mesmo efeito EMPILHAM — é assim que build extrema existe.
    var duas := Poderes.new()
    duas.guardar_reliquia("carmim")
    duas.guardar_reliquia("carmim")
    var base := com_flush()
    var com := com_flush(duas)
    igual(int(com.conta_do_evento([0])["linhas"][0]["fichas"]),
          int(base.conta_do_evento([0])["linhas"][0]["fichas"]) + 5 * 50,
          "dois Carmins num flush de copas: +50 fichas por carta")

    ## O Prumo tira o piso das DUAS diagonais.
    var prumo := Poderes.new()
    prumo.guardar_reliquia("prumo")
    igual(prumo.piso_da_diagonal(Geometria.DIAGONAL_0), 1.0, "o Prumo abre a ↘")
    igual(prumo.piso_da_diagonal(Geometria.DIAGONAL_0 + 1), 1.0, "e a ↗")

    ## A Lançadeira acelera o tique, e nunca abaixo de 2.
    var lanc := Poderes.new()
    lanc.guardar_reliquia("lancadeira")
    igual(lanc.tear_por_tique(), 3, "a Lançadeira leva o tique a 3")
    ok(Poderes.new().tear_por_tique() == Metas.TEAR_POR_TIQUE,
       "sem ela, o tique é o medido")

    ## O Remendo paga mult por mão fraca — a relíquia que faz a build ruim virar
    ## build boa, que é o tipo de item que muda como se joga e não só quanto.
    var remendo := Poderes.new()
    remendo.guardar_reliquia("remendo")
    var m := Mesa.new(Metas.CHEFE, 1, 5, 1, null, 0, 0, [], [], remendo)
    var fraca := [c(0, 1), c(1, 4), c(2, 8), c(3, 11), c(0, 6)]
    for i in 5:
        m.grade[Geometria.CELULAS[0][i]] = fraca[i]
    var lisa := Mesa.new(Metas.CHEFE, 1, 5, 1)
    for i in 5:
        lisa.grade[Geometria.CELULAS[0][i]] = fraca[i]
    igual(int(m.conta_do_evento([0])["soma_dos_mults"]),
          int(lisa.conta_do_evento([0])["soma_dos_mults"]) + 3,
          "o Remendo paga +3 mult pela mão fraca colhida")

# ─────────────────────────── R22/R23 — o dinheiro ───────────────────────────

func _dinheiro() -> void:
    secao("a economia (R22/R23)")
    var m := Mesa.new(Metas.PEQUENA, 1, 5)
    m.acabou = true
    m.venceu = true
    m.posicionamentos_usados = m.posicionamentos_max - 2
    var pago := Economia.pagamento(m)
    igual(int(pago["premio"]), 3, "a Pequena paga $3")
    igual(int(pago["sobra"]), 2, "e $1 por posicionamento não usado")
    igual(int(pago["total"]), 5, "total $5")

    m.posicionamentos_usados = 0
    igual(int(Economia.pagamento(m)["sobra"]), Economia.SOBRA_TETO,
          "a sobra tem teto de $4")

    ## Derrota paga. Sair de uma mesa perdida com zero faz de uma mesa perdida
    ## duas: sem dinheiro não há loja, e sem loja não há como virar.
    var perdida := Mesa.new(Metas.CHEFE, 3, 5)
    perdida.acabou = true
    perdida.venceu = false
    perdida.pontos = 0
    igual(int(Economia.pagamento(perdida)["premio"]), 0, "a derrota não paga prêmio")
    ## A escada: $1 por fatia inteira de 20% da meta. Fatia INTEIRA — quem ficou
    ## a um ponto dos 60% recebe por 40%, e é assim que tem de ser: o contrário
    ## seria arredondar a favor e ninguém entenderia de onde veio a moeda.
    var escada := [0, 1, 2, 3, 4, 4]
    for k in escada.size():
        ## Arredondando para CIMA: "alcançou 20%" é o ponto em que a fatia
        ## fecha, e `meta * k / 5` em inteiro fica um ponto abaixo disso.
        perdida.pontos = int(ceil(float(perdida.meta) * float(k) / 5.0))
        igual(int(Economia.pagamento(perdida)["consolo"]), int(escada[k]),
              "%d%% da meta pagam $%d" % [k * 20, int(escada[k])])

    ## Juros: $1 a cada $5 guardados.
    var p := Poderes.new()
    p.dinheiro = 17
    igual(int(Economia.pagamento(m, p)["juros"]), 3, "$17 guardados rendem $3")
    p.dinheiro = 90
    igual(int(Economia.pagamento(m, p)["juros"]), Economia.JUROS_TETO,
          "e o teto dos juros é $4")
    p.guardar_reliquia("juro")
    igual(int(Economia.pagamento(m, p)["juros"]), 8, "o Juro composto leva o teto a $8")

    var caro := Itens.achar(Itens.RELIQUIA, "prumo")
    igual(Economia.preco(caro, Poderes.new()), Itens.PRECO_RELIQUIA, "a relíquia custa $8")
    var pechincha := Poderes.new()
    pechincha.guardar_reliquia("pechincha")
    igual(Economia.preco(caro, pechincha), Itens.PRECO_RELIQUIA - 2, "a Pechincha desconta $2")
    var muitas := Poderes.new()
    for i in 9:
        muitas.guardar_reliquia("pechincha")
    igual(Economia.preco(caro, muitas), 1,
          "e nada fica de graça: item grátis tira a decisão de comprar")

# ─────────────────────────── a vitrine ───────────────────────────

func _vitrine() -> void:
    secao("a loja")
    ## Divulgação progressiva: um conceito por vez.
    igual(Loja.tipos_da_rodada(1).size(), 1, "a rodada 1 só vende nível de mão")
    igual(Loja.tipos_da_rodada(2).size(), 2, "selo de casa entra na 2")
    igual(Loja.tipos_da_rodada(3).size(), 3, "selo de eixo na 3")
    igual(Loja.tipos_da_rodada(4).size(), 4, "relíquia na 4")

    var l1 := Loja.new(1, 99)
    igual(l1.vagas.size(), 3, "três vagas")
    var so_nivel := true
    for v in l1.vagas:
        if int(v["tipo"]) != Loja.NIVEL:
            so_nivel = false
    ok(so_nivel, "e na rodada 1 as três são nível de mão")

    ## Geometria 5 — a loja perde uma vaga.
    igual(Loja.new(4, 99, Desafio.tabuleiro(5)).vagas.size(), 2,
          "no grau 5 a loja tem duas vagas")

    ## Comprar tira o dinheiro e entrega o poder.
    var p := Poderes.new()
    p.dinheiro = 20
    var loja := Loja.new(1, 7)
    var cat := int(loja.vagas[0]["categoria"])
    ok(loja.pode_comprar(0, p), "dá para comprar com dinheiro")
    var comprada := loja.comprar(0, p)
    ok(not comprada.is_empty(), "a compra aconteceu")
    igual(p.dinheiro, 20 - Itens.PRECO_NIVEL, "o preço saiu do bolso")
    igual(p.nivel(cat), 1, "e o nível subiu")
    ok(not loja.pode_comprar(0, p), "a vaga vendida não vende de novo")

    var pobre := Poderes.new()
    pobre.dinheiro = 1
    ok(not Loja.new(1, 7).pode_comprar(0, pobre), "sem dinheiro não compra")

    ## Selo sem alvo não é vendido: colar onde é a decisão, e uma compra sem
    ## decisão seria pontos disfarçados de escolha.
    var lj := Loja.new(2, 12)
    var pd := Poderes.new()
    pd.dinheiro = 50
    for i in lj.vagas.size():
        if lj.precisa_de_alvo(i) == 0:
            ok(lj.comprar(i, pd).is_empty(), "selo de casa sem alvo não é vendido")
            ok(not lj.comprar(i, pd, 12).is_empty(), "com alvo, sim")
            ok(pd.selos_de_casa.has(12), "e o selo colou na casa escolhida")
            break

    ## Rerrolar tem escada de preço, senão vira o jogo.
    var r := Loja.new(4, 33)
    var rico := Poderes.new()
    rico.dinheiro = 30
    igual(r.preco_da_rerrolagem(), 1, "a primeira rerrolagem custa $1")
    r.rerrolar(rico)
    igual(r.preco_da_rerrolagem(), 2, "a segunda custa $2")
    igual(rico.dinheiro, 29, "e o dinheiro saiu")

# ─────────────── a promessa: com loja, a rodada 6 existe ───────────────

func _a_promessa() -> void:
    secao("a promessa: a loja abre a rodada 6")
    ## Sem loja a vitória da rodada 6 é ZERO — medido, e é o motivo de tudo isto
    ## existir. Este teste guarda o número: se ele voltar a zero, o jogo voltou a
    ## ter uma porta fechada com o jogador do lado de fora.
    var venceu_na_6 := 0
    var chegou_na_6 := 0
    var travou := 0
    for s in 10:
        var run := Run.new(31337 + s * 7919)
        var voltas := 0
        while not run.acabou and voltas < 90:
            voltas += 1
            var rodada := run.rodada
            var antes := run.mesa.posicionamentos_usados
            Politica.jogar(run.mesa)
            if not run.mesa.acabou:
                travou += 1
            if rodada == Metas.RODADAS:
                chegou_na_6 += 1
                if run.mesa.venceu:
                    venceu_na_6 += 1
            run.concluir_mesa()
            if run.loja != null:
                Politica.comprar(run.loja, run.poderes)
                run.fechar_loja()
    igual(travou, 0, "nenhuma mesa ficou sem fim — a run nunca congela")
    ok(chegou_na_6 > 0, "o jogador simulado chega à rodada 6 (%d mesas)" % chegou_na_6)
    ok(venceu_na_6 > 0, "e vence lá (%d de %d)" % [venceu_na_6, chegou_na_6])
    ok(float(venceu_na_6) / float(maxi(1, chegou_na_6)) > 0.30,
       "com folga: mais de 30%% das mesas da rodada 6")

    ## E o baralho nunca zera, nem no grau que tira as cartas de circulação.
    var run4 := Run.new(31337, Desafio.tabuleiro(4))
    var voltas := 0
    var menor := Cartas.TAMANHO
    while not run4.acabou and voltas < 90:
        voltas += 1
        menor = mini(menor, run4.mesa.cartas_da_mesa)
        Politica.jogar(run4.mesa)
        run4.concluir_mesa()
        if run4.loja != null:
            Politica.comprar(run4.loja, run4.poderes)
            run4.fechar_loja()
    ok(menor >= Desafio.BARALHO_MINIMO,
       "o baralho nunca desce de %d cartas (menor: %d)" % [Desafio.BARALHO_MINIMO, menor])
