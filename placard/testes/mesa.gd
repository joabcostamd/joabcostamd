extends SceneTree
## Suíte da mesa — o turno inteiro, das regras R03 a R22.
##
## Onde a suíte do núcleo verifica aritmética, esta verifica COMPORTAMENTO: se a
## linha cheia realmente espera, se a cruzada realmente paga mais, se a carta
## não some da conta, se o fecho realmente vira a mesa.
##
##     godot --headless --script res://testes/mesa.gd

var _passou := 0
var _falhou := 0

func _init() -> void:
    _nascimento()
    _janela()
    _cruzada()
    _parcela()
    _tear()
    _avesso()
    _fim_da_mesa()
    _mesas_inteiras()
    _as_dicas()

    print("")
    if _falhou > 0:
        print("MESA: %d de %d asserções FALHARAM" % [_falhou, _passou + _falhou])
        quit(1)
        return
    print("MESA OK — %d asserções" % _passou)
    quit(0)

# ──────────────────────────── a régua ────────────────────────────

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

## Traz uma carta específica para a mão e a posiciona. Serve só ao teste: monta
## o cenário sem inventar carta nenhuma, então a conservação continua valendo.
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

## Põe qualquer carta da mão numa casa. Para encher a grade sem se importar com
## o quê.
func qualquer(m: Mesa, casa: int) -> Dictionary:
    return m.posicionar(0, casa)

func c(naipe: int, indice: int) -> int:
    return naipe * 13 + indice

# ──────────────────────────── nascer ────────────────────────────

func _nascimento() -> void:
    secao("nascimento da mesa (R02/R06/R06b)")
    var pequena := Mesa.new(Metas.PEQUENA, 1, 31337)
    igual(pequena.mao.size(), 5, "a mão nasce com 5 cartas")
    igual(pequena.meta, 2178, "a meta da Pequena na rodada 1")
    igual(pequena.posicionamentos_max, 15, "15 posicionamentos na Pequena")
    igual(pequena.descartes_restantes, 2, "2 descartes na Pequena")
    igual(pequena.tear, 1, "o Tear começa em 1")
    igual(25 - pequena.casas_vazias().size(), 3,
          "R06b — a Pequena nasce com 3 cartas na grade")
    ok(pequena.conservacao(), "a conta fecha ao nascer")

    var chefe := Mesa.new(Metas.CHEFE, 6, 31337)
    igual(chefe.casas_vazias().size(), 25, "a mesa do Chefe nasce vazia")
    igual(chefe.posicionamentos_max, 19, "19 posicionamentos no Chefe")
    igual(chefe.meta, 28922, "a meta do Chefe na rodada 6")

    ## R20 — a mesma semente dá a mesma mesa, sempre.
    var a := Mesa.new(Metas.GRANDE, 3, 480011)
    var b := Mesa.new(Metas.GRANDE, 3, 480011)
    igual(a.mao, b.mao, "a mesma semente dá a mesma mão")
    igual(a.baralho, b.baralho, "e o mesmo baralho")
    var d := Mesa.new(Metas.GRANDE, 3, 480012)
    ok(a.baralho != d.baralho, "sementes diferentes dão baralhos diferentes")
    ## A repetição da mesa perdida embaralha de novo sem mexer na run.
    var r := Mesa.new(Metas.GRANDE, 3, 480011, 2)
    ok(a.baralho != r.baralho, "a segunda tentativa é outro embaralhamento")

# ─────────────────── R08 — a Janela da Colheita ───────────────────

func _janela() -> void:
    secao("a Janela da Colheita (R08)")
    var m := Mesa.new(Metas.CHEFE, 1, 7)

    for casa in 4:
        var r := qualquer(m, casa)
        ok(not r["colheita"], "com %d cartas a fileira não colhe" % (casa + 1))

    var quinta := qualquer(m, 4)
    ok(not quinta["colheita"], "a 5ª carta NÃO colhe na hora — a linha amadurece")
    igual(quinta["maduras_novas"], [0] as Array[int], "a fileira 1 ficou madura")
    igual(m.linhas_maduras(), [0] as Array[int], "e continua madura na grade")
    igual(m.casas_vazias().size(), 20, "as 5 cartas continuam ocupando a grade")

    var seguinte := qualquer(m, 5)
    ok(seguinte["colheita"], "o posicionamento seguinte colhe")
    igual(seguinte["linhas"].size(), 1, "colheu uma linha")
    igual(int(seguinte["linhas"][0]["linha"]), 0, "colheu a fileira 1")
    igual(seguinte["grau"], "colheita", "uma linha só é 'colheita', não CRUZADA")
    ok(m.linhas_maduras().is_empty(), "não sobrou linha madura")
    ok(m.conservacao(), "a conta fecha depois de colher")

    ## As 5 casas voltaram a ficar vazias — menos a que acabou de receber carta.
    igual(m.contagem[0], 0, "a fileira colhida ficou vazia")

    ## A linha que amadurece no ÚLTIMO posicionamento colhe na hora, sem janela.
    var f := Mesa.new(Metas.CHEFE, 1, 11)
    while f.posicionamentos_usados < f.posicionamentos_max - 5 and not f.acabou:
        qualquer(f, f.casas_vazias()[0])
    if not f.acabou:
        ## Deixa a última fileira livre e enche-a no fim.
        var vazias := f.casas_vazias()
        var ultimo := {}
        while f.posicionamentos_usados < f.posicionamentos_max - 1 and not f.acabou:
            qualquer(f, f.casas_vazias()[0])
        if not f.acabou:
            ultimo = qualquer(f, f.casas_vazias()[0])
            ok(bool(ultimo["acabou"]),
               "o último posicionamento encerra a mesa")

# ─────────────────────── R12 — a cruzada ───────────────────────

func _cruzada() -> void:
    secao("a CRUZADA (R09/R12)")
    var m := Mesa.new(Metas.CHEFE, 1, 3)

    ## A ordem importa, e é ela que o jogador precisa aprender: com a janela de
    ## um turno, uma linha madura colhe no posicionamento SEGUINTE, qualquer que
    ## ele seja. Para colher duas juntas, a segunda linha tem de estar em 4/5
    ## ANTES de a primeira amadurecer — e completar no turno da colheita.
    for casa in range(5, 9):
        qualquer(m, casa)
    igual(m.contagem[1], 4, "a fileira 2 fica esperando em 4/5")

    for casa in 5:
        qualquer(m, casa)
    igual(m.linhas_maduras(), [0] as Array[int], "a fileira 1 amadurece depois")

    var evento := qualquer(m, 9)
    ok(evento["colheita"], "completar a fileira 2 dispara a colheita")
    igual(evento["linhas"].size(), 2, "as duas fileiras colhem no mesmo evento")
    ok(bool(evento["cruzada"]), "e isso é uma CRUZADA")
    igual(evento["grau"], "DUPLA", "duas linhas se chamam DUPLA")

    ## R12 — o fator é a SOMA dos multiplicadores, vezes o Tear, e é COMUM.
    var soma := 0
    for linha in evento["linhas"]:
        soma += Maos.MULTIPLICADOR[int(linha["categoria"])]
    igual(int(evento["soma_dos_mults"]), soma,
          "a soma dos multiplicadores das mãos colhidas")
    igual(int(evento["fator"]), soma * int(evento["tear_do_evento"]),
          "o fator é a soma dos multiplicadores vezes o Tear de então")
    ok(int(evento["tear_do_evento"]) < m.tear,
       "e o Tear mostrado é o de ANTES da colheita, não o de depois")

    ## Cada linha pagou fichas × fator (com o piso da diagonal onde couber).
    var conferiu := true
    for linha in evento["linhas"]:
        var esperado := Maos.pontos_da_linha(int(linha["fichas"]),
                                             int(evento["fator"]),
                                             bool(linha["diagonal"]))
        if int(linha["pontos"]) != esperado:
            conferiu = false
    ok(conferiu, "cada linha pagou fichas × fator")
    igual(int(evento["pontos_evento"]),
          int(evento["linhas"][0]["pontos"]) + int(evento["linhas"][1]["pontos"]),
          "o evento é a soma das linhas")
    ok(m.conservacao(), "a conta fecha depois da cruzada")

    ## E o Tear subiu uma vez por linha colhida.
    igual(m.tear, 1 + 2 + int(m.posicionamentos_usados / Metas.TEAR_POR_TIQUE)
          + int(evento["troco"].get("tear", 0)),
          "o Tear subiu +1 por linha, mais os tiques e o troco")

# ────────────────────── R13 — a parcela ──────────────────────

func _parcela() -> void:
    secao("a PARCELA (R13)")
    var m := Mesa.new(Metas.CHEFE, 1, 5)

    var r1 := qualquer(m, 0)
    var r2 := qualquer(m, 1)
    ok(r1["parcelas"].is_empty() and r2["parcelas"].is_empty(),
       "com 1 e 2 cartas a linha não paga parcela")

    var r3 := qualquer(m, 2)
    igual(r3["parcelas"].size(), 1, "com 3 cartas a linha paga uma parcela")
    igual(int(r3["parcelas"][0]["linha"]), 0, "e é a fileira 1")
    igual(int(r3["parcelas"][0]["cartas"]), 3, "no limiar de 3 cartas")
    ok(int(r3["pontos_parcela"]) > 0, "a parcela vale alguma coisa")
    ok(m.pontos > 0, "e entra na pontuação sem gastar turno")

    var r4 := qualquer(m, 3)
    igual(r4["parcelas"].size(), 1, "com 4 cartas paga a segunda parcela")
    igual(int(r4["parcelas"][0]["cartas"]), 4, "no limiar de 4 cartas")

    var r5 := qualquer(m, 4)
    ok(r5["parcelas"].is_empty(),
       "a linha cheia não pulsa: são dois limiares e só")
    ok(int(r5["pontos_parcela"]) == 0, "e não paga nada por isso")

    ## Uma linha madura não volta a pulsar mesmo que outra a atravesse.
    var r6 := qualquer(m, 5)
    ok(r6["colheita"], "o turno seguinte colhe a madura")
    var voltou := false
    for p in r6["parcelas"]:
        if int(p["linha"]) == 0:
            voltou = true
    ok(not voltou, "a fileira colhida não paga parcela no mesmo turno")

# ───────────────────────── R14 — o Tear ─────────────────────────

func _tear() -> void:
    secao("o TEAR (R14)")
    var m := Mesa.new(Metas.CHEFE, 1, 13)
    igual(m.tear, 1, "começa em 1")

    ## O tique: +1 a cada 4 posicionamentos. Escolho casas que não fecham linha
    ## para isolar o tique — quatro casas na mesma fileira só chegam a 4/5.
    var subiu_no_quarto := false
    for i in 4:
        var r := qualquer(m, i)
        if i == 3:
            subiu_no_quarto = bool(r["tique_do_tear"])
        elif bool(r["tique_do_tear"]):
            subiu_no_quarto = false
    ok(subiu_no_quarto, "o Tear sobe no 4º posicionamento, e não antes")
    igual(m.tear, 2, "e vale 2 depois do primeiro tique")

    ## O teto de 8 é duro. Acima dele o dial mede zero — não vire parâmetro.
    var t := Mesa.new(Metas.CHEFE, 1, 17)
    t.tear = Metas.TEAR_TETO
    for i in 8:
        if t.acabou:
            break
        qualquer(t, t.casas_vazias()[0])
    igual(t.tear, Metas.TEAR_TETO, "o Tear não passa de 8, aconteça o que acontecer")

# ─────────────────────── R21/R22 — o Avesso ───────────────────────

func _avesso() -> void:
    secao("o AVESSO (R21/R22)")
    ## A codificação, antes de qualquer jogo.
    var a := Mesa.forjar(c(Cartas.COPAS, 0), c(Cartas.ESPADAS, 12))
    ok(Mesa.eh_avesso(a), "um Avesso se reconhece como Avesso")
    ok(not Mesa.eh_avesso(51), "uma carta comum não")
    igual(Mesa.face(a, true), c(Cartas.COPAS, 0), "a cara da fileira")
    igual(Mesa.face(a, false), c(Cartas.ESPADAS, 12), "a cara da coluna")
    igual(Mesa.face(30, true), 30, "uma carta comum é a mesma nos dois eixos")
    var girado := Mesa.girar(a)
    igual(Mesa.face(girado, true), c(Cartas.ESPADAS, 12), "girar troca as caras")
    igual(Mesa.face(girado, false), c(Cartas.COPAS, 0), "nos dois sentidos")
    igual(Mesa.girar(girado), a, "girar duas vezes volta ao começo")
    igual(Mesa.quantas_cartas(a), 2, "um Avesso vale duas cartas na conta")
    igual(Mesa.quantas_cartas(30), 1, "uma carta comum vale uma")

    ## A forja: toda colheita prensa as duas cartas de maior valor da linha.
    var m := Mesa.new(Metas.CHEFE, 1, 23)
    for casa in 5:
        qualquer(m, casa)
    var evento := qualquer(m, 5)
    ok(evento["colheita"], "a colheita aconteceu")
    igual(evento["avessos"].size(), 1, "toda colheita forja um Avesso")
    var forjado: int = int(evento["avessos"][0]["carta"])
    ok(Mesa.eh_avesso(forjado), "e o que ela forja é um Avesso")
    igual(evento["avessos"][0]["casas"].size(), 2, "prensado de duas cartas")
    ok(m.conservacao(), "a conta fecha com o Avesso forjado")

    ## Ele vai para o TOPO do baralho, então cai na compra deste mesmo turno e
    ## está na mão para o posicionamento seguinte: a espera medida é 1 turno.
    ok(m.mao.has(forjado), "o Avesso chega à mão a tempo do turno seguinte")
    ok(not m.baralho.has(forjado), "e saiu do baralho ao ser comprado")

    ## E as duas caras são as duas maiores da linha colhida.
    var maiores := [Cartas.fichas(Mesa.face(forjado, true)),
                    Cartas.fichas(Mesa.face(forjado, false))]
    ok(int(maiores[0]) >= int(maiores[1]),
       "a cara da fileira é a de maior valor das duas")

    ## Posicionado, ele vale caras diferentes na fileira e na coluna.
    var t := Mesa.new(Metas.CHEFE, 1, 29)
    var falso := Mesa.forjar(c(Cartas.COPAS, 4), c(Cartas.ESPADAS, 9))
    t.grade[12] = falso
    igual(t.cartas_da_linha(2), [c(Cartas.COPAS, 4)],
          "na fileira vale a cara da fileira")
    igual(t.cartas_da_linha(7), [c(Cartas.ESPADAS, 9)],
          "na coluna vale a outra cara")
    igual(t.cartas_da_linha(10), [c(Cartas.ESPADAS, 9)],
          "e na diagonal também é a cara da coluna")

# ────────────────── R19/R20 — o fim da mesa ──────────────────

func _fim_da_mesa() -> void:
    secao("o fim da mesa (R19/R20)")

    ## Uma mesa com meta inalcançável chega ao fim pelos posicionamentos.
    var m := Mesa.new(Metas.CHEFE, 1, 41)
    m.meta = 99999999
    var ultimo := {}
    while not m.acabou:
        ultimo = qualquer(m, m.casas_vazias()[0])
    igual(m.posicionamentos_usados, m.posicionamentos_max,
          "a mesa acaba ao esgotar os posicionamentos")
    ok(not m.venceu, "e sem bater a meta é derrota")
    ok(ultimo.has("fecho"), "o último posicionamento faz o fecho")
    ok(int(ultimo["fecho"]["total"]) > 0, "e o fecho paga alguma coisa")
    ok(m.conservacao(), "a conta fecha no fim da mesa")

    ## O `if` que valia 6,1 pontos percentuais: o fecho CONTA para a meta.
    ## A prova é montar uma meta que só o fecho alcança.
    var pontos_finais := m.pontos
    var fecho_total := int(ultimo["fecho"]["total"])
    var so_com_fecho := Mesa.new(Metas.CHEFE, 1, 41)
    so_com_fecho.meta = pontos_finais
    while not so_com_fecho.acabou:
        qualquer(so_com_fecho, so_com_fecho.casas_vazias()[0])
    ok(so_com_fecho.venceu,
       "com a meta exatamente na soma final, o fecho vira a mesa")

    var sem_o_fecho := Mesa.new(Metas.CHEFE, 1, 41)
    sem_o_fecho.meta = pontos_finais - fecho_total + 1
    while not sem_o_fecho.acabou:
        qualquer(sem_o_fecho, sem_o_fecho.casas_vazias()[0])
    ok(fecho_total > 0 and sem_o_fecho.venceu,
       "e essa meta só é alcançável porque o fecho conta")

    ## Bater a meta encerra na hora, sem gastar o resto do orçamento.
    var v := Mesa.new(Metas.CHEFE, 1, 41)
    v.meta = 1
    qualquer(v, 0)
    qualquer(v, 1)
    ## A terceira carta paga a primeira parcela, e a parcela sozinha já basta.
    var r := qualquer(v, 2)
    ok(int(r["pontos_parcela"]) > 0, "a parcela pagou")
    ok(bool(r["venceu"]), "bater a meta vence")
    ok(v.acabou, "e encerra a mesa na hora")
    ok(v.posicionamentos_usados < v.posicionamentos_max,
       "sem gastar o resto dos posicionamentos")
    ok(not r.has("fecho"), "vitória antecipada não faz fecho")

# ────────────────── mesas inteiras, muitas vezes ──────────────────

func _mesas_inteiras() -> void:
    secao("mesas inteiras (R04 — a conservação)")
    var quebrou_conservacao := 0
    var mao_morta := 0
    var invalidos := 0
    var vitorias := 0
    var mesas := 0
    var com_cruzada := 0
    var com_avesso := 0

    for s in 60:
        for tipo in Metas.TIPOS:
            var m := Mesa.new(tipo, 1 + s % 6, 31337 + s * 7919)
            mesas += 1
            var passos := 0
            while not m.acabou and passos < 200:
                passos += 1
                if not m.conservacao():
                    quebrou_conservacao += 1
                    break
                var vazias := m.casas_vazias()
                if vazias.is_empty() or m.mao.is_empty():
                    mao_morta += 1
                    break
                ## Um descarte de vez em quando, para exercitar o caminho.
                if passos % 5 == 0 and m.descartes_restantes > 0:
                    m.descartar([0])
                var alvo: int = vazias[(passos * 7 + s) % vazias.size()]
                var r := m.posicionar(passos % m.mao.size(), alvo)
                if not bool(r["valido"]):
                    invalidos += 1
                    break
                if bool(r["cruzada"]):
                    com_cruzada += 1
                if not r["avessos"].is_empty():
                    com_avesso += 1
            if not m.conservacao():
                quebrou_conservacao += 1
            if m.venceu:
                vitorias += 1

    igual(mesas, 180, "rodei 180 mesas")
    igual(quebrou_conservacao, 0,
          "a conta 52 = mão + grade + colhida + baralho + descarte nunca quebrou")
    igual(mao_morta, 0, "nunca faltou casa vazia nem carta na mão")
    igual(invalidos, 0, "nenhum posicionamento inválido")
    ok(com_cruzada > 0, "cruzadas aconteceram (%d)" % com_cruzada)
    ok(com_avesso > 0, "Avessos foram forjados (%d)" % com_avesso)
    ok(vitorias >= 0, "vitórias contadas: %d de 180" % vitorias)

# ─────────────────── §6 — a conta dos dois lados ───────────────────

func _as_dicas() -> void:
    secao("as DICAS (§6)")
    var m := Mesa.new(Metas.CHEFE, 1, 5)

    ## Sem nada montado, a jogada não fecha nem derruba nada.
    var seca := m.a_conta(0, 0)
    igual(seca["fecha"].size(), 0, "casa vazia não fecha linha")
    igual(seca["derruba"].size(), 0, "nem derruba")

    ## Quatro cartas na fileira 1: a quinta AMADURECE a linha.
    for casa in 4:
        qualquer(m, casa)
    var madura := m.a_conta(0, 4)
    igual(madura["amadurece"].size(), 1, "a quinta carta deixa a fileira madura")
    igual(int(madura["amadurece"][0]), 0, "e é a fileira 1")

    ## Agora o caso que importa, montado na ordem certa: uma coluna carregada
    ## ATRAVÉS da fileira, a fileira amadurecendo, e uma jogada que colhe a
    ## fileira e leva a coluna junto. É a conta que ensina a recusa.
    var t := Mesa.new(Metas.CHEFE, 1, 5)
    for casa in [6, 11, 16]:          ## coluna B, fora da fileira 1
        qualquer(t, casa)
    for casa in [0, 1, 2, 3]:         ## fileira 1 em 4/5; a casa 1 é da coluna B
        qualquer(t, casa)
    igual(t.contagem[Geometria.COLUNA_0 + 1], 4, "a coluna B ficou em 4/5")
    qualquer(t, 4)                    ## a fileira 1 enche e AMADURECE
    igual(t.linhas_maduras(), [0] as Array[int], "a fileira 1 está madura")

    ## Qualquer posicionamento agora colhe a fileira — e a colheita leva a casa
    ## B1, derrubando a coluna B de 4/5 para 3/5.
    var conta := t.a_conta(0, 20)
    ok(conta["fecha"].size() >= 1, "a jogada colhe a fileira madura")
    var derruba := false
    for d in conta["derruba"]:
        if int(d["linha"]) == Geometria.COLUNA_0 + 1:
            derruba = true
            igual(int(d["de"]), 4, "a coluna B estava em 4/5")
            igual(int(d["para"]), 3, "e cai para 3/5")
    ok(derruba,
       "a conta MOSTRA o que a colheita derruba — o preço que ensina a recusa")
    ok(int(conta["ganha"]) > 0, "e diz quanto a jogada paga")

    ## As casas que não mudam nada: num tabuleiro com cartas, quase toda casa
    ## encosta em alguma linha; a lista existe para o caso em que não.
    var vazia := Mesa.new(Metas.CHEFE, 1, 5)
    igual(vazia.casas_que_mudam(0).size(), 0,
          "numa grade vazia, nenhuma casa muda nada — todas são iguais por simetria")
    qualquer(vazia, 12)
    ok(vazia.casas_que_mudam(0).size() > 0,
       "com uma carta na grade, as casas das linhas dela passam a mudar")
    ok(vazia.casas_que_mudam(0).size() < Geometria.CASAS,
       "e as casas longe dela continuam sem mudar nada")
