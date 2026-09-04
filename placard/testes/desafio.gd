extends SceneTree
## Suíte da dificuldade e da rede de segurança.
##
## Estas regras existem para o jogo NÃO ficar impossível e para o jogador
## escolher quanto quer apanhar. Um erro aqui não aparece como bug: aparece como
## alguém desinstalando na rodada 4.
##
##     godot --headless --script res://testes/desafio.gd

var _passou := 0
var _falhou := 0

func _init() -> void:
    _reguas()
    _presets()
    _geometria()
    _fianca()
    _rede()
    _nada_e_impossivel()

    print("")
    if _falhou > 0:
        print("DESAFIO: %d de %d asserções FALHARAM" % [_falhou, _passou + _falhou])
        quit(1)
        return
    print("DESAFIO OK — %d asserções" % _passou)
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

func plantar(m: Mesa, casa: int, carta: int) -> Dictionary:
    var i := m.mao.find(carta)
    if i < 0:
        var j := m.baralho.find(carta)
        if j < 0:
            return {"valido": false}
        m.baralho.remove_at(j)
        m.mao.append(carta)
        i = m.mao.size() - 1
    return m.posicionar(i, casa)

func qualquer(m: Mesa, casa: int) -> Dictionary:
    return m.posicionar(0, casa)

# ───────────────────────────── as três réguas ─────────────────────────────

func _reguas() -> void:
    secao("as três réguas")
    var d := Desafio.new()
    igual(d.orcamento, 0, "o padrão não mexe no orçamento")
    igual(d.geometria, 0, "nem na geometria")
    igual(d.metas, 1.0, "nem nas metas")
    igual(d.posicionamentos(Metas.PEQUENA), 15, "15 posicionamentos na Pequena")
    igual(d.meta(Metas.PEQUENA, 1), 2178, "e a meta medida")

    var folgado := Desafio.new()
    folgado.orcamento = 4
    folgado.metas = 0.70
    igual(folgado.posicionamentos(Metas.PEQUENA), 19, "+4 no orçamento dá 19")
    igual(folgado.meta(Metas.PEQUENA, 1), int(round(2178 * 0.7)),
          "metas ×0,70 baixam a meta")

    ## O piso duro: numa grade 5×5, menos de 7 posicionamentos e nenhuma linha
    ## chega às 5 cartas. A mesa ficaria invencível por aritmética.
    var apertado := Desafio.new()
    apertado.orcamento = Desafio.ORCAMENTO_MIN
    apertado.geometria = Desafio.GEOMETRIA_MAX
    ok(apertado.posicionamentos(Metas.PEQUENA) >= Geometria.LADO + 2,
       "nunca menos de 7 posicionamentos, em nenhuma configuração")

func _presets() -> void:
    secao("o dial Tabuleiro")
    igual(Desafio.TABULEIROS.size(), 9, "nove graus")
    for grau in 9:
        var d := Desafio.tabuleiro(grau)
        igual(d.grau_do_dial(), grau, "o grau %d se reconhece" % grau)
        igual(d.nome(), "Tabuleiro %d" % grau, "e tem nome")

    ## O dial ESCREVE nos sliders, não soma com eles. Mexer à mão sai do dial.
    var meu := Desafio.tabuleiro(3)
    meu.orcamento += 2
    igual(meu.grau_do_dial(), -1, "mexer na régua sai do dial")
    igual(meu.nome(), "Personalizado", "e a tela diz isso, não finge um grau")

    ## Monotonia: subir o grau nunca deixa a vida mais fácil.
    var antes := 99999
    for grau in 9:
        var d := Desafio.tabuleiro(grau)
        var folga := d.posicionamentos(Metas.CHEFE) * 1000 - d.meta(Metas.CHEFE, 6) / 100
        ok(folga <= antes, "o grau %d não é mais fácil que o anterior" % grau)
        antes = folga

    var e := Desafio.estufa()
    igual(e.nome(), "Estufa", "a Estufa tem nome próprio")
    ok(e.sem_derrota, "e nela a derrota não existe")
    ok(e.posicionamentos(Metas.PEQUENA) > 15, "com orçamento maior")
    ok(e.quantos_descartes(Metas.PEQUENA) > 2, "e mais descartes")

# ───────────────────────────── a geometria ─────────────────────────────

func _geometria() -> void:
    secao("os graus da geometria")
    var g1 := Desafio.tabuleiro(1)
    igual(g1.posicionamentos(Metas.PEQUENA), 14, "grau 1 tira um posicionamento")

    ## Grau 2 — duas casas lacradas, nunca o centro.
    var g2 := Desafio.tabuleiro(2)
    var centrais := 0
    for s in 40:
        var m := Mesa.new(Metas.CHEFE, 1, 900 + s, 1, g2)
        igual(m.lacradas.size(), 2, "duas casas lacradas") if s == 0 else null
        if m.lacradas.has(Geometria.CASAS / 2):
            centrais += 1
        if s == 0:
            ok(not m.pode_posicionar(m.lacradas[0]), "casa lacrada não recebe carta")
            ok(not m.casas_vazias().has(m.lacradas[0]),
               "e não conta como casa vazia")
    igual(centrais, 0, "o centro nunca é lacrado em 40 mesas — lacrar C3 tira 4 linhas")

    ## Grau 3 — a coluna paga um mult a menos.
    var g3 := Desafio.tabuleiro(3)
    var reto := Mesa.new(Metas.CHEFE, 1, 5, 1)
    var punido := Mesa.new(Metas.CHEFE, 1, 5, 1, g3)
    var flush := [c(0, 0), c(0, 3), c(0, 6), c(0, 9), c(0, 12)]
    for i in 5:
        reto.grade[Geometria.CELULAS[Geometria.COLUNA_0][i]] = flush[i]
        punido.grade[Geometria.CELULAS[Geometria.COLUNA_0][i]] = flush[i]
    var a := reto.conta_do_evento([Geometria.COLUNA_0])
    var b := punido.conta_do_evento([Geometria.COLUNA_0])
    igual(int(b["soma_dos_mults"]), int(a["soma_dos_mults"]) - 1,
          "a coluna perde um mult")
    ok(int(b["total"]) < int(a["total"]), "e paga menos")
    ## A fileira não é atingida.
    for i in 5:
        punido.grade[Geometria.CELULAS[Geometria.COLUNA_0][i]] = Mesa.VAZIA
        punido.grade[Geometria.CELULAS[0][i]] = flush[i]
    igual(int(punido.conta_do_evento([0])["soma_dos_mults"]),
          Maos.MULTIPLICADOR[Maos.FLUSH], "a fileira segue inteira")

    ## Grau 6 — a cruzada só soma mults de categorias diferentes.
    var g6 := Desafio.tabuleiro(6)
    var normal := Mesa.new(Metas.CHEFE, 1, 5, 1)
    var exigente := Mesa.new(Metas.CHEFE, 1, 5, 1, g6)
    var trinca_a := [c(0, 7), c(1, 7), c(2, 7), c(3, 2), c(0, 11)]
    var trinca_b := [c(0, 4), c(1, 4), c(2, 4), c(3, 9), c(0, 12)]
    for m in [normal, exigente]:
        for i in 5:
            m.grade[Geometria.CELULAS[0][i]] = trinca_a[i]
            m.grade[Geometria.CELULAS[1][i]] = trinca_b[i]
    igual(int(normal.conta_do_evento([0, 1])["soma_dos_mults"]),
          Maos.MULTIPLICADOR[Maos.TRINCA] * 2, "duas trincas somam os dois mults")
    igual(int(exigente.conta_do_evento([0, 1])["soma_dos_mults"]),
          Maos.MULTIPLICADOR[Maos.TRINCA],
          "no grau 6, a segunda trinca não soma — só variedade paga")

    ## Grau 7 — a linha morta colhe e paga zero.
    var morta := Mesa.new(Metas.CHEFE, 1, 5, 1, Desafio.tabuleiro(7), 0, 0, [], [0])
    for i in 5:
        morta.grade[Geometria.CELULAS[0][i]] = flush[i]
    igual(int(morta.conta_do_evento([0])["total"]), 0, "a linha morta paga zero")
    ok(bool(morta.conta_do_evento([0])["linhas"][0].get("morta", false)),
       "e o relato diz que ela está morta")
    igual(int(morta._valor_da_parcela(0, -1, Mesa.VAZIA)), 0,
          "linha morta também não paga parcela")

    ## Grau 4 — o que a run colheu não volta.
    var sem := Mesa.new(Metas.CHEFE, 1, 5, 1, Desafio.tabuleiro(4), 0, 0, [0, 1, 2, 3])
    igual(sem.cartas_da_mesa, Cartas.TAMANHO - 4, "quatro cartas fora do baralho")
    ok(sem.conservacao(), "e a conta de conservação passa a ser sobre o que sobrou")
    var achou := false
    for carta in sem.baralho + sem.mao:
        if carta <= 3:
            achou = true
    ok(not achou, "nenhuma das cartas removidas aparece na mesa")

# ───────────────────────────── a Fiança ─────────────────────────────

func _fianca() -> void:
    secao("a FIANÇA")
    var m := Mesa.new(Metas.CHEFE, 1, 5, 1)
    igual(m.fianca, 0, "começa apagada")

    ## Três luzes acesas dobram a colheita e apagam.
    var cheia := Mesa.new(Metas.CHEFE, 1, 5, 1, null, 0, Mesa.FIANCA_LUZES)
    igual(cheia.fianca, 3, "a mesa recebe as luzes da run")
    for casa in 5:
        qualquer(cheia, casa)
    var evento := qualquer(cheia, 5)
    ok(bool(evento["colheita"]), "colheu")
    ok(bool(evento["fianca_pagou"]), "e a Fiança pagou")
    igual(cheia.fianca, 0, "as luzes zeram depois de pagar")

    var simples := Mesa.new(Metas.CHEFE, 1, 5, 1)
    for casa in 5:
        qualquer(simples, casa)
    var normal := qualquer(simples, 5)
    igual(int(evento["pontos_evento"]), int(normal["pontos_evento"]) * 2,
          "a Fiança paga exatamente o dobro")

    ## Ela NUNCA acende pela demolição que o próprio jogador escolheu: a Janela
    ## demole 4/5 por design, e premiar isso faria da autossabotagem a estratégia.
    var escolhida := Mesa.new(Metas.CHEFE, 1, 5, 1)
    for casa in 5:
        qualquer(escolhida, casa)
    ## A fileira 1 está madura; a coluna A está em 1/5. Nenhuma perda alheia.
    var seguinte := qualquer(escolhida, 5)
    ok(not bool(seguinte["fianca_acendeu"]),
       "colher a própria linha não acende a Fiança")

func _rede() -> void:
    secao("a rede de segurança")
    ## SEGUNDA MÃO — repetir dá uma carta a mais na manga, até três.
    var d := Desafio.new()
    igual(d.posicionamentos(Metas.PEQUENA, 0), 15, "primeira tentativa: 15")
    igual(d.posicionamentos(Metas.PEQUENA, 1), 16, "segunda: 16")
    igual(d.posicionamentos(Metas.PEQUENA, 3), 18, "quarta: 18")

    var r := Run.new(31337)
    r.mesa.acabou = true
    r.mesa.venceu = false
    r.mesa.pontos = 0
    var passo := r.concluir_mesa()
    igual(r.vidas, 2, "derrota longe da meta gasta a vida")
    igual(int(passo["catraca"]), 1, "e a catraca sobe para 1")
    igual(r.mesa.posicionamentos_max, 16, "a mesa repetida tem um posicionamento a mais")
    ok(r.mesa.meta == Metas.meta(Metas.PEQUENA, 1),
       "e a MESMA meta — ferramenta, nunca desconto")

    ## QUASE LÁ — 80% da meta devolve a vida.
    var q := Run.new(31337)
    q.mesa.acabou = true
    q.mesa.venceu = false
    q.mesa.pontos = int(q.mesa.meta * 0.85)
    var perto := q.concluir_mesa()
    igual(q.vidas, 3, "chegar a 85% da meta não gasta vida")
    ok(bool(perto["quase_la"]), "e o relato diz que foi por pouco")
    igual(q.quase_la, 1, "a run conta quantas vezes o Quase lá segurou")

    var longe := Run.new(31337)
    longe.mesa.acabou = true
    longe.mesa.venceu = false
    longe.mesa.pontos = int(longe.mesa.meta * 0.79)
    longe.concluir_mesa()
    igual(longe.vidas, 2, "79% não basta: a fronteira é dura")

    ## ESTUFA — a derrota não existe. Repete de graça, sem gastar vida.
    var e := Run.new(31337, Desafio.estufa())
    for i in 6:
        e.mesa.acabou = true
        e.mesa.venceu = false
        e.mesa.pontos = 0
        e.concluir_mesa()
    igual(e.vidas, 3, "seis derrotas na Estufa e nenhuma vida gasta")
    ok(not e.acabou, "e a run continua de pé")

# ─────────────── a promessa: nenhuma mesa é impossível ───────────────

func _nada_e_impossivel() -> void:
    secao("nenhuma configuração fecha a porta")
    ## Para toda combinação de grau × rodada × tipo, uma mesa precisa ter
    ## posicionamentos suficientes para colher pelo menos uma vez. Menos que isso
    ## não é dificuldade, é aritmética fechada — e é a diferença entre um jogo
    ## duro e um jogo quebrado.
    var falhas := 0
    for grau in Desafio.TABULEIROS.size():
        var d := Desafio.tabuleiro(grau)
        for tipo in Metas.TIPOS:
            if d.posicionamentos(tipo) < Geometria.LADO + 2:
                falhas += 1
    igual(falhas, 0, "todo grau permite fechar linha em toda mesa")

    ## E a grade precisa sobrar casa: com casas lacradas e linhas mortas, ainda
    ## tem de existir jogada legal em todo turno até o orçamento acabar.
    var travadas := 0
    var mortas: Array[int] = [0, 5, 10]
    for s in 30:
        var m := Mesa.new(Metas.CHEFE, 6, 4000 + s, 1, Desafio.tabuleiro(8),
                          0, 0, [], mortas)
        var passos := 0
        while not m.acabou and passos < 60:
            passos += 1
            if m.casas_vazias().is_empty() or m.mao.is_empty():
                travadas += 1
                break
            Politica.talvez_descartar(m)
            var j := Politica.gulosa(m)
            if int(j[0]) < 0:
                travadas += 1
                break
            m.posicionar(int(j[0]), int(j[1]))
    igual(travadas, 0, "no grau mais duro, com três linhas mortas, nunca travou")
