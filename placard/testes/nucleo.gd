extends SceneTree
## Suíte do núcleo. Roda headless, imprime o que falhou e sai com código 1 —
## `testar.sh` interrompe, e uma regra quebrada não chega ao commit.
##
##     godot --headless --script res://testes/nucleo.gd

var _passou := 0
var _falhou := 0
var _secao := ""

func _init() -> void:
    _cartas()
    _avaliador()
    _padroes()
    _pontos()
    _hierarquia()
    _geometria()
    _metas()
    _aleatorio()

    print("")
    if _falhou > 0:
        print("NÚCLEO: %d de %d asserções FALHARAM" % [_falhou, _passou + _falhou])
        quit(1)
        return
    print("NÚCLEO OK — %d asserções" % _passou)
    quit(0)

# ──────────────────────────── a régua ────────────────────────────

func secao(nome: String) -> void:
    _secao = nome
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

## Monta uma carta pelo par (naipe, índice), que é como o teste pensa.
func c(naipe: int, indice: int) -> int:
    return naipe * 13 + indice

# ──────────────────────────── as cartas ────────────────────────────

func _cartas() -> void:
    secao("cartas")
    var b := Cartas.baralho()
    igual(b.size(), 52, "o baralho tem 52 cartas")
    var vistas := {}
    for carta in b:
        vistas[carta] = true
    igual(vistas.size(), 52, "as 52 são distintas")

    var por_naipe := [0, 0, 0, 0]
    for carta in b:
        por_naipe[Cartas.naipe(carta)] += 1
    igual(por_naipe, [13, 13, 13, 13], "13 cartas por naipe")

    igual(Cartas.fichas(c(Cartas.COPAS, 0)), 11, "o Ás vale 11 fichas")
    igual(Cartas.fichas(c(Cartas.OUROS, 1)), 2, "o 2 vale 2")
    igual(Cartas.fichas(c(Cartas.PAUS, 9)), 10, "o 10 vale 10")
    igual(Cartas.fichas(c(Cartas.ESPADAS, 10)), 10, "o J vale 10")
    igual(Cartas.fichas(c(Cartas.COPAS, 12)), 10, "o K vale 10")

    igual(Cartas.figura(c(Cartas.COPAS, 0)), 1, "o Ás desenha como 1")
    igual(Cartas.figura(c(Cartas.ESPADAS, 12)), 13, "o K desenha como 13")
    igual(Cartas.nome(c(Cartas.PAUS, 11)), "Q de paus", "o nome legível")

# ─────────────────────────── o avaliador ───────────────────────────

func _avaliador() -> void:
    secao("avaliador de mãos")
    var H := Cartas.COPAS
    var O := Cartas.OUROS
    var P := Cartas.PAUS
    var E := Cartas.ESPADAS

    igual(Maos.categoria(c(H, 9), c(H, 10), c(H, 11), c(H, 12), c(H, 0)),
          Maos.REAL, "10-J-Q-K-A do mesmo naipe é Sequência Real")
    igual(Maos.categoria(c(P, 4), c(P, 5), c(P, 6), c(P, 7), c(P, 8)),
          Maos.SEQ_COR, "6-7-8-9-10 do mesmo naipe é Sequência de Cor")
    igual(Maos.categoria(c(O, 0), c(O, 1), c(O, 2), c(O, 3), c(O, 4)),
          Maos.SEQ_COR, "A-2-3-4-5 do mesmo naipe também é Sequência de Cor")
    igual(Maos.categoria(c(H, 5), c(O, 5), c(P, 5), c(E, 5), c(H, 0)),
          Maos.QUADRA, "quatro iguais é Quadra")
    igual(Maos.categoria(c(H, 5), c(O, 5), c(P, 5), c(E, 8), c(H, 8)),
          Maos.FULL, "trinca mais par é Full House")
    igual(Maos.categoria(c(E, 0), c(E, 3), c(E, 6), c(E, 9), c(E, 12)),
          Maos.FLUSH, "cinco do mesmo naipe sem ordem é Flush")
    igual(Maos.categoria(c(H, 4), c(O, 5), c(P, 6), c(E, 7), c(H, 8)),
          Maos.SEQUENCIA, "cinco em ordem de naipes diferentes é Sequência")
    igual(Maos.categoria(c(H, 0), c(O, 1), c(P, 2), c(E, 3), c(H, 4)),
          Maos.SEQUENCIA, "A-2-3-4-5 é Sequência com o Ás embaixo")
    igual(Maos.categoria(c(H, 9), c(O, 10), c(P, 11), c(E, 12), c(H, 0)),
          Maos.SEQUENCIA, "10-J-Q-K-A é Sequência com o Ás em cima")
    igual(Maos.categoria(c(H, 10), c(O, 11), c(P, 12), c(E, 0), c(H, 1)),
          Maos.ALTA, "J-Q-K-A-2 NÃO dá a volta: é Carta Alta")
    igual(Maos.categoria(c(H, 7), c(O, 7), c(P, 7), c(E, 2), c(H, 11)),
          Maos.TRINCA, "três iguais é Trinca")
    igual(Maos.categoria(c(H, 7), c(O, 7), c(P, 2), c(E, 2), c(H, 11)),
          Maos.DOIS_PARES, "dois pares é Dois Pares")
    igual(Maos.categoria(c(H, 7), c(O, 7), c(P, 2), c(E, 5), c(H, 11)),
          Maos.PAR, "um par é Par")
    igual(Maos.categoria(c(H, 1), c(O, 3), c(P, 5), c(E, 8), c(H, 10)),
          Maos.ALTA, "nada é Carta Alta")
    igual(Maos.categoria(c(H, 6), c(O, 6), c(P, 6), c(E, 6), c(H, 6)),
          Maos.QUINA, "cinco iguais é Quina — só existe com Avesso")
    igual(Maos.categoria(c(H, 0), c(H, 1), c(H, 2), c(H, 3), c(H, 5)),
          Maos.FLUSH, "A-2-3-4-6 do mesmo naipe é só Flush")

    igual(Maos.fichas_de([c(H, 0), c(O, 12), c(P, 9), c(E, 1), c(H, 4)]),
          11 + 10 + 10 + 2 + 5, "a soma das fichas das cartas")
    igual(Maos.NOMES.size(), Maos.CATEGORIAS, "todas as categorias têm nome")
    igual(Maos.FICHAS_BASE.size(), Maos.CATEGORIAS, "todas têm fichas base")
    igual(Maos.MULTIPLICADOR.size(), Maos.CATEGORIAS, "todas têm multiplicador")

# ─────────────────── R15 — o piso do padrão parcial ───────────────────

func _padroes() -> void:
    secao("piso do padrão parcial (R15)")
    var H := Cartas.COPAS
    var O := Cartas.OUROS
    var P := Cartas.PAUS
    var E := Cartas.ESPADAS

    igual(Maos.padroes_parciais([c(H, 1), c(H, 4), c(H, 8), c(O, 11), c(P, 6)]),
          1, "três do mesmo naipe é um quase-flush")
    igual(Maos.padroes_parciais([c(H, 1), c(H, 4), c(H, 8), c(H, 11), c(P, 6)]),
          2, "quatro do mesmo naipe são dois quase-flushes")
    igual(Maos.padroes_parciais([c(H, 3), c(O, 4), c(P, 5), c(E, 8), c(H, 11)]),
          1, "três em sequência é um quase-escada")
    igual(Maos.padroes_parciais([c(H, 3), c(O, 4), c(P, 5), c(E, 6), c(H, 11)]),
          2, "quatro em sequência são dois quase-escadas")
    igual(Maos.padroes_parciais([c(H, 0), c(O, 1), c(P, 2), c(E, 8), c(H, 11)]),
          1, "A-2-3 conta: o Ás vale embaixo")
    igual(Maos.padroes_parciais([c(H, 11), c(O, 12), c(P, 0), c(E, 5), c(H, 8)]),
          1, "Q-K-A conta: o Ás vale em cima também")
    igual(Maos.padroes_parciais([c(H, 1), c(O, 5), c(P, 9), c(E, 12), c(H, 7)]),
          0, "espalhada não tem padrão nenhum")
    igual(Maos.padroes_parciais([c(H, 3), c(H, 4), c(H, 5), c(H, 6), c(O, 11)]),
          3, "quase-flush duplo mais quase-escada duplo bate no teto de 3")
    ok(Maos.padroes_parciais([c(H, 3), c(H, 4), c(H, 5), c(H, 6), c(O, 11)])
       <= Maos.PISO_TETO_PADROES, "o teto de padrões é respeitado")

    ok(Maos.fraca(Maos.ALTA) and Maos.fraca(Maos.PAR)
       and Maos.fraca(Maos.DOIS_PARES), "Alta, Par e Dois Pares são fracas")
    ok(not Maos.fraca(Maos.TRINCA), "Trinca não é fraca")
    ok(Maos.devolve_troco(Maos.PAR) and not Maos.devolve_troco(Maos.DOIS_PARES),
       "só Alta e Par devolvem troco (R16)")

# ───────────────── R11/R12 — a conta do evento ─────────────────

func _pontos() -> void:
    secao("a conta do evento (R11/R12)")
    var H := Cartas.COPAS
    var O := Cartas.OUROS
    var P := Cartas.PAUS
    var E := Cartas.ESPADAS

    ## Carta Alta com um quase-flush: 2♥ 5♥ 9♥ Q♦ 7♣
    var fraca := [c(H, 1), c(H, 4), c(H, 8), c(O, 11), c(P, 6)]
    igual(Maos.fichas_da_linha(fraca),
          Maos.FICHAS_BASE[Maos.ALTA] + (2 + 5 + 9 + 10 + 7) + Maos.PISO_POR_PADRAO,
          "a mão fraca recebe o piso do padrão parcial")

    ## Flush: o piso NÃO entra, mesmo com cinco cartas do mesmo naipe.
    var forte := [c(E, 0), c(E, 3), c(E, 6), c(E, 9), c(E, 12)]
    igual(Maos.fichas_da_linha(forte),
          Maos.FICHAS_BASE[Maos.FLUSH] + Maos.fichas_de(forte),
          "a mão forte não recebe piso")

    ## R12 — o fator é a SOMA dos multiplicadores, vezes o Tear.
    igual(Maos.fator_do_evento([Maos.TRINCA], 1), 3,
          "uma Trinca sozinha com Tear 1 dá fator 3")
    igual(Maos.fator_do_evento([Maos.TRINCA], 5), 15, "o Tear multiplica o fator")
    igual(Maos.fator_do_evento([Maos.TRINCA, Maos.FLUSH], 1), 7,
          "Trinca mais Flush somam os multiplicadores: 3 + 4")
    igual(Maos.fator_do_evento([Maos.TRINCA, Maos.FLUSH], 8), 56,
          "e o Tear multiplica a soma inteira")
    igual(Maos.fator_do_evento([], 8), 0, "evento sem linha não tem fator")

    ## O NÚMERO QUE JUSTIFICA A JANELA DA COLHEITA (R08).
    ## Colher junto tem de pagar mais que colher separado — senão a regra que
    ## faz o jogador esperar um turno não teria razão de existir.
    var fichas_t: int = Maos.fichas_da_linha(
        [c(H, 7), c(O, 7), c(P, 7), c(E, 2), c(H, 11)])   # Trinca
    var fichas_f: int = Maos.fichas_da_linha(forte)        # Flush
    var tear := 4
    var separado: int = (
        Maos.pontos_da_linha(fichas_t, Maos.fator_do_evento([Maos.TRINCA], tear), false)
        + Maos.pontos_da_linha(fichas_f, Maos.fator_do_evento([Maos.FLUSH], tear), false))
    var fator_junto: int = Maos.fator_do_evento([Maos.TRINCA, Maos.FLUSH], tear)
    var junto: int = (Maos.pontos_da_linha(fichas_t, fator_junto, false)
                      + Maos.pontos_da_linha(fichas_f, fator_junto, false))
    ok(junto > separado,
       "a CRUZADA paga mais que as duas colheitas separadas — a razão da R08")
    ok(float(junto) / float(separado) > 1.5,
       "e paga bem mais: pelo menos uma vez e meia")

    ## R07 — a diagonal paga 60%.
    var fator := Maos.fator_do_evento([Maos.FLUSH], 3)
    var reto := Maos.pontos_da_linha(fichas_f, fator, false)
    var diag := Maos.pontos_da_linha(fichas_f, fator, true)
    igual(diag, int(floor(float(reto) * 0.60)), "a diagonal paga 60%")
    ok(diag < reto, "a diagonal paga menos que a fileira")

    secao("parcela e fecho (R13/R19)")
    ## Com menos de 5 cartas, só categoria por valor: nada de promessa de naipe.
    igual(Maos.categoria_parcial([c(H, 1), c(H, 4), c(H, 8)]), Maos.ALTA,
          "três do mesmo naipe ainda não é Flush")
    igual(Maos.categoria_parcial([c(H, 7), c(O, 7), c(P, 2)]), Maos.PAR,
          "a linha em 3/5 com um par vale Par")

    var tres := [c(H, 7), c(O, 7), c(P, 2)]
    var cheio := Maos.pontos_parciais(tres, false, 1, 1.0)
    igual(Maos.pontos_parciais(tres, false, 1, Metas.PARCELA),
          int(floor(float(cheio) * Metas.PARCELA)), "a parcela paga 35%")
    igual(Maos.pontos_parciais(tres, false, 1, Metas.FECHO),
          int(floor(float(cheio) * Metas.FECHO)), "o fecho paga 50%")
    ok(Maos.pontos_parciais(tres, false, 8, Metas.PARCELA)
       > Maos.pontos_parciais(tres, false, 1, Metas.PARCELA),
       "o Tear também multiplica a parcela")
    igual(Maos.pontos_parciais([], false, 4, Metas.FECHO), 0,
          "linha vazia não paga nada")
    ok(Maos.pontos_parciais(tres, false, 1, Metas.PARCELA) > 0,
       "linha em 3/5 paga alguma coisa — nada vale zero")

    ## O piso do padrão parcial NÃO entra na parcela nem no fecho: ele é
    ## recompensa de colheita, não de promessa.
    var quatro_copas := [c(H, 1), c(H, 4), c(H, 8), c(H, 11)]
    igual(Maos.pontos_parciais(quatro_copas, false, 1, 1.0),
          (Maos.FICHAS_BASE[Maos.ALTA] + Maos.fichas_de(quatro_copas)) * 1,
          "quatro do mesmo naipe em 4/5 não ganham piso")

# ──────────────── R17 — a hierarquia do pôquer não inverte ────────────────

func _hierarquia() -> void:
    secao("hierarquia do pôquer (R17)")

    ## Valor intrínseco: fichas efetivas × multiplicador, com a soma das cartas
    ## fixada na média de cinco cartas (≈ 8 cada). É a mesma conta da bancada.
    var media := 40

    var anterior := 0
    var estritamente_crescente := true
    for cat in Maos.CATEGORIAS:
        var v: int = (Maos.FICHAS_BASE[cat] + media) * Maos.MULTIPLICADOR[cat]
        if v <= anterior:
            estritamente_crescente = false
        anterior = v
    ok(estritamente_crescente, "as 11 categorias são estritamente crescentes")

    ## O caso extremo: mão fraca com o piso cheio (3 padrões, +45 fichas).
    var piso_cheio: int = Maos.PISO_TETO_PADROES * Maos.PISO_POR_PADRAO
    var alta: int = (Maos.FICHAS_BASE[Maos.ALTA] + media + piso_cheio) * 1
    var par: int = (Maos.FICHAS_BASE[Maos.PAR] + media + piso_cheio) * 2
    var dois: int = (Maos.FICHAS_BASE[Maos.DOIS_PARES] + media + piso_cheio) * 2
    var full: int = (Maos.FICHAS_BASE[Maos.FULL] + media) * 4

    ok(par < dois, "com o piso cheio, o Par continua abaixo do Dois Pares")
    ok(float(full) / float(alta) > 3.0,
       "Full House vale mais que 3× a Carta Alta mesmo com o piso cheio")

    ## Prova de que o teste é sensível: em +25 fichas por padrão a hierarquia
    ## inverteria, e foi por isso que a bancada parou em 15.
    var alta25: int = (Maos.FICHAS_BASE[Maos.ALTA] + media + 3 * 25) * 1
    ok(float(full) / float(alta25) < float(full) / float(alta),
       "um piso maior aproximaria a Carta Alta do Full — o teste enxerga isso")
    igual(Maos.PISO_POR_PADRAO, 15, "o piso está na fronteira medida: 15")

# ────────────────────────── a grade ──────────────────────────

func _geometria() -> void:
    secao("geometria da grade")
    igual(Geometria.CELULAS.size(), 12, "doze linhas vivas")
    var todas_com_cinco := true
    for l in Geometria.CELULAS:
        if l.size() != 5:
            todas_com_cinco = false
    ok(todas_com_cinco, "cada linha tem exatamente 5 casas")

    ## Cada casa é coberta o número certo de vezes: 12 linhas × 5 casas = 60.
    var cobertura := 0
    for casa in Geometria.CASAS:
        cobertura += Geometria.linhas_da_casa(casa).size()
    igual(cobertura, 60, "as 12 linhas cobrem 60 pertencimentos")

    igual(Geometria.linhas_da_casa(12).size(), 4,
          "o centro pertence a 4 linhas — fileira, coluna e as duas diagonais")
    igual(Geometria.linhas_da_casa(0).size(), 3, "o canto pertence a 3 linhas")
    igual(Geometria.linhas_da_casa(1).size(), 2, "a casa comum pertence a 2")

    var diagonais := 0
    for l in Geometria.LINHAS:
        if Geometria.diagonal(l):
            diagonais += 1
    igual(diagonais, 2, "duas linhas são diagonais")
    ok(not Geometria.diagonal(0) and Geometria.diagonal(10)
       and Geometria.diagonal(11), "as diagonais são as duas últimas")

    igual(Geometria.nome_da_casa(12), "C3", "a casa central se chama C3")
    igual(Geometria.nome_da_casa(0), "A1", "a casa do canto se chama A1")
    igual(Geometria.nome_da_casa(24), "E5", "a última casa se chama E5")
    igual(Geometria.nome(0), "fileira 1", "a primeira linha é a fileira 1")
    igual(Geometria.nome(7), "coluna C", "a oitava linha é a coluna C")
    ok(Geometria.nome(10).begins_with("diagonal"), "a décima primeira é diagonal")

    ## As duas diagonais se cruzam só no centro.
    var d1: Array = Geometria.CELULAS[10]
    var d2: Array = Geometria.CELULAS[11]
    var comuns := 0
    for casa in d1:
        if d2.has(casa):
            comuns += 1
    igual(comuns, 1, "as duas diagonais se cruzam numa casa só")

# ────────────────────────── R18 — a curva ──────────────────────────

func _metas() -> void:
    secao("curva de metas (R18)")
    var pequena: Array[int] = []
    for r in range(1, 7):
        pequena.append(Metas.meta(Metas.PEQUENA, r))
    igual(pequena, [2178, 3093, 4392, 6236, 8855, 12575] as Array[int],
          "a curva da mesa Pequena")

    igual(Metas.meta(Metas.GRANDE, 1), 3267, "a Grande da rodada 1")
    igual(Metas.meta(Metas.CHEFE, 1), 5009, "o Chefe da rodada 1")
    igual(Metas.meta(Metas.CHEFE, 6), 28922, "o Chefe da rodada 6")

    var crescente := true
    for tipo in Metas.TIPOS:
        for r in range(2, 7):
            if Metas.meta(tipo, r) <= Metas.meta(tipo, r - 1):
                crescente = false
    ok(crescente, "a meta sobe a cada rodada, nos três tipos")

    var ordenado := true
    for r in range(1, 7):
        if not (Metas.meta(Metas.PEQUENA, r) < Metas.meta(Metas.GRANDE, r)
                and Metas.meta(Metas.GRANDE, r) < Metas.meta(Metas.CHEFE, r)):
            ordenado = false
    ok(ordenado, "Pequena < Grande < Chefe em todas as rodadas")

    igual(Metas.posicionamentos(Metas.PEQUENA), 15, "15 posicionamentos na Pequena")
    igual(Metas.posicionamentos(Metas.GRANDE), 17, "17 na Grande")
    igual(Metas.posicionamentos(Metas.CHEFE), 19, "19 no Chefe")
    igual(Metas.descartes(Metas.PEQUENA), 2, "2 descartes na Pequena")
    igual(Metas.descartes(Metas.CHEFE), 3, "3 no Chefe")

    ## A CRUZ TOTAL custa 17 posicionamentos e cabe EXATAMENTE na Grande.
    igual(Metas.posicionamentos(Metas.GRANDE), 17,
          "a Grande cabe a CRUZ TOTAL na medida exata")

# ────────────────────── R34 — o acaso é semeado ──────────────────────

func _aleatorio() -> void:
    secao("aleatório semeado")
    var a := Aleatorio.new(31337)
    var b := Aleatorio.new(31337)
    var iguais := true
    for i in 200:
        if a.inteiro(1000) != b.inteiro(1000):
            iguais = false
    ok(iguais, "a mesma semente dá a mesma sequência")

    var x := Aleatorio.new(31337)
    var y := Aleatorio.new(31338)
    var diferencas := 0
    for i in 200:
        if x.inteiro(1000) != y.inteiro(1000):
            diferencas += 1
    ok(diferencas > 150, "sementes vizinhas dão sequências diferentes")

    var dentro := true
    var r := Aleatorio.new(7)
    for i in 2000:
        var v := r.inteiro(52)
        if v < 0 or v >= 52:
            dentro = false
    ok(dentro, "inteiro(52) fica sempre em [0, 52)")
    igual(r.inteiro(1), 0, "inteiro(1) é sempre 0")
    igual(r.inteiro(0), 0, "inteiro(0) não estoura")

    var real_dentro := true
    for i in 500:
        var v := r.real()
        if v < 0.0 or v >= 1.0:
            real_dentro = false
    ok(real_dentro, "real() fica em [0, 1)")

    ## Embaralhar é permutação: nada some, nada duplica.
    var baralho := Cartas.baralho()
    var e := Aleatorio.new(2026)
    e.embaralhar(baralho)
    igual(baralho.size(), 52, "o baralho embaralhado continua com 52")
    var vistas := {}
    for carta in baralho:
        vistas[carta] = true
    igual(vistas.size(), 52, "embaralhar é permutação — nada some nem duplica")
    ok(baralho != Cartas.baralho(), "e a ordem realmente mudou")

    ## A semente da mesa é derivada, nunca sorteada (R20).
    igual(Aleatorio.misturar(99, 31, 0), Aleatorio.misturar(99, 31, 0),
          "misturar é determinístico")
    ok(Aleatorio.misturar(99, 31, 0) != Aleatorio.misturar(99, 31, 1),
       "a repetição da mesa muda o embaralhamento, não a run")
    ok(Aleatorio.misturar(99, 31, 0) >= 0, "a semente derivada é positiva")
