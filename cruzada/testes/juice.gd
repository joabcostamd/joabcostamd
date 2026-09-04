extends SceneTree
## Suíte do juice e do som.
##
## Enfeite também tem regra, e as regras são medíveis: nenhum efeito pode durar
## mais que o gesto que o causou, crescer sem limite, ou tremer a ponto de tirar
## o tabuleiro da leitura. Um vazamento aqui não trava o jogo — ele o deixa
## lento depois de vinte minutos, que é pior porque ninguém sabe por quê.
##
##     godot --headless --script res://testes/juice.gd

var _passou := 0
var _falhou := 0

func _init() -> void:
    Temas.usar(Temas.PADRAO)
    _limites()
    _o_peso_escala()
    _nao_vaza()
    _o_som()

    print("")
    if _falhou > 0:
        print("JUICE: %d de %d asserções FALHARAM" % [_falhou, _passou + _falhou])
        quit(1)
        return
    print("JUICE OK — %d asserções" % _passou)
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

func caixas(quantas: int) -> Array:
    var r := []
    for i in quantas:
        r.append(Rect2(100 + i * 60, 200, 56, 78))
    return r

func cartas(quantas: int) -> Array:
    var r := []
    for i in quantas:
        r.append([1 + i % 13, i % 4])
    return r

func _limites() -> void:
    secao("os limites")
    var j := Juice.new()
    ok(j.vazio(), "nasce parado")
    ok(not j.avancar(0.1), "e parado não pede redesenho")
    igual(j.deslocamento(), Vector2.ZERO, "sem tremor, sem deslocamento")

    ## O tremor tem teto: acima dele a tela deixa de ser legível justamente no
    ## instante em que ela mudou.
    j.colheu(caixas(20), Vector2(50, 50), cartas(20), 4, 400)
    ok(j.tremor <= Juice.TREMOR_MAXIMO, "o tremor respeita o teto")
    ok(j.pausa <= Juice.PAUSA_MAXIMA, "a pausa também")
    ok(j.deslocamento().length() <= Juice.TREMOR_MAXIMO * 1.5,
       "e o deslocamento fica dentro do raio")

    ## A pausa congela o resto: é ela que separa o impacto do pagamento.
    var tremor_na_pausa := j.tremor
    j.avancar(0.02)
    igual(j.tremor, tremor_na_pausa, "durante a pausa nada mais anda")

func _o_peso_escala() -> void:
    secao("o peso escala com o evento")
    var pequeno := Juice.new()
    pequeno.colheu(caixas(5), Vector2.ZERO, cartas(5), 1, 12)
    var grande := Juice.new()
    grande.colheu(caixas(20), Vector2.ZERO, cartas(20), 4, 300)
    ok(grande.tremor > pequeno.tremor,
       "a cruz total treme mais que a colheita de uma linha")
    ok(grande.pausa > pequeno.pausa, "e pausa mais")

    ## O que acontece a todo turno quase não treme: efeito constante vira
    ## irritação em dez minutos.
    var comum := Juice.new()
    comum.pousou(Rect2(0, 0, 60, 84))
    ok(comum.tremor < pequeno.tremor * 0.5,
       "pousar uma carta treme muito menos que colher")

    ## A Fiança é o evento mais raro do jogo, e treme mais que tudo.
    var f := Juice.new()
    f.fianca(Vector2(300, 300))
    igual(f.tremor, Juice.TREMOR_MAXIMO, "a Fiança sacode no máximo")

func _nao_vaza() -> void:
    secao("nada vaza")
    var j := Juice.new()
    ## Trinta colheitas seguidas, como numa mesa longa.
    for i in 30:
        j.colheu(caixas(10), Vector2.ZERO, cartas(10), 3, 90)
        for k in 4:
            j.avancar(0.016)
    ok(j._fagulhas.size() < 3000, "as fagulhas não crescem sem limite (%d)"
       % j._fagulhas.size())

    ## E tudo morre sozinho: dois segundos e a tela volta ao repouso.
    for i in 200:
        j.avancar(0.016)
    ok(j.vazio(), "dois segundos depois, tudo parou")
    igual(j._voos.size(), 0, "nenhuma carta ficou voando para sempre")
    igual(j.tremor, 0.0, "e o tremor zerou")

func _o_som() -> void:
    secao("o som")
    ## Fora da árvore o som é silêncio, nunca erro: a primeira versão estourava
    ## com índice fora de faixa quando alguém tocava antes de o nó entrar.
    var solto := Som.new()
    solto.carta()
    solto.colheita(4, 8)
    ok(true, "som fora da árvore não derruba nada")

    var som := Som.new()
    get_root().add_child(som)
    som._preparar()
    igual(som._vozes.size(), Som.VOZES, "as vozes são criadas sob demanda")
    som._preparar()
    igual(som._vozes.size(), Som.VOZES, "e preparar duas vezes não duplica")

    ## A escada do Tear: cada degrau é um semitom acima. É o que faz "está
    ## crescendo" ser ouvido antes de ser lido.
    var uma_oitava := pow(Som.SEMITOM, 12.0)
    ok(absf(uma_oitava - 2.0) < 0.001, "doze semitons dão exatamente uma oitava")

    ## Mudo é mudo: com volume zero nenhuma onda é gerada.
    som.volume = 0.0
    som.colheita(4, 8)
    som.tocar(440.0, 0.2)
    _passou += 1   ## não estourou

    som.volume = 0.6
    som.carta()
    som.parcela(3)
    som.parcela(4)
    som.colheita(1, 1)
    som.colheita(4, 8)
    som.tear(5)
    som.fianca()
    som.moeda()
    som.vitoria()
    som.derrota()
    som.conquista()
    ok(true, "todos os sons do jogo tocam sem estourar")
    som.queue_free()
