extends Node
## Suíte do núcleo. Roda sem janela: ./testar.sh

var _falhas := 0
var _total := 0

func _ready() -> void:
    _rodar.call_deferred()

func _rodar() -> void:
    _dados()
    _pistas_conferem()
    _regras()
    _estrelas()
    _desfazer_e_dica()
    _progresso()
    _resolver_todas()

    print("")
    if _falhas == 0:
        print("NÚCLEO OK — %d/%d testes" % [_total, _total])
    else:
        print("NÚCLEO FALHOU: %d de %d" % [_falhas, _total])
    Audio.parar_tudo()
    await get_tree().create_timer(0.15).timeout
    get_tree().quit(1 if _falhas > 0 else 0)

func _dados() -> void:
    _ok("carrega 50 fases", Catalogo.fases.size() == 50)
    _ok("carrega 4 capítulos", Catalogo.capitulos.size() == 4)
    _ok("a fase 1 é 5x5", Catalogo.fase(1).lado == 5)
    _ok("a fase 50 é 20x20", Catalogo.fase(50).lado == 20)
    var ids_ok := true
    for i in Catalogo.fases.size():
        if Catalogo.fases[i].id != i + 1:
            ids_ok = false
    _ok("os ids vão de 1 a 50 sem buraco", ids_ok)

    var dificuldade_sobe := true
    for capitulo in Catalogo.capitulos:
        var anterior := -1.0
        for id in capitulo["fases"]:
            var d := Catalogo.fase(int(id)).dificuldade
            if d < anterior:
                dificuldade_sobe = false
            anterior = d
    _ok("dentro de cada capítulo a dificuldade só cresce", dificuldade_sobe)

## Confere, sem confiar no Python, que as pistas do arquivo batem com o desenho.
func _pistas_conferem() -> void:
    var todas_ok := true
    for p in Catalogo.fases:
        for y in p.lado:
            var esperada: Array = _pistas_de_linha(p, y, true)
            if not _mesma_lista(esperada, p.pistas_linhas[y]):
                todas_ok = false
        for x in p.lado:
            var esperada: Array = _pistas_de_linha(p, x, false)
            if not _mesma_lista(esperada, p.pistas_colunas[x]):
                todas_ok = false
    _ok("as pistas de todas as 50 fases batem com o desenho", todas_ok)

func _pistas_de_linha(p: Puzzle, indice: int, horizontal: bool) -> Array:
    var blocos: Array = []
    var atual := 0
    for i in p.lado:
        var cheia := p.e_cheia(i, indice) if horizontal else p.e_cheia(indice, i)
        if cheia:
            atual += 1
        elif atual > 0:
            blocos.append(atual)
            atual = 0
    if atual > 0:
        blocos.append(atual)
    return blocos if not blocos.is_empty() else [0]

func _mesma_lista(a: Array, b: Array) -> bool:
    if a.size() != b.size():
        return false
    for i in a.size():
        if int(a[i]) != int(b[i]):
            return false
    return true

func _regras() -> void:
    var p := Catalogo.fase(1)
    var celula_cheia := _achar(p, true)
    var celula_vazia := _achar(p, false)

    var partida := Partida.new(p)
    _ok("pintar célula cheia é acerto",
        partida.pintar(celula_cheia.x, celula_cheia.y) == Partida.Jogada.ACERTO)
    _ok("pintar de novo a mesma célula não faz nada",
        partida.pintar(celula_cheia.x, celula_cheia.y) == Partida.Jogada.NADA)
    _ok("pintar célula vazia é erro",
        partida.pintar(celula_vazia.x, celula_vazia.y) == Partida.Jogada.ERRO)
    _ok("o erro custa uma vida", partida.vidas == 2)
    _ok("a célula errada vira anotação de vazia",
        partida.marca_em(celula_vazia.x, celula_vazia.y) == Partida.Marca.CRUZ)

    var relaxada := Partida.new(p, true)
    relaxada.pintar(celula_vazia.x, celula_vazia.y)
    _ok("no modo relaxado o erro não custa vida", relaxada.vidas == Partida.VIDAS_INICIAIS)
    _ok("no modo relaxado o erro ainda é contado", relaxada.erros == 1)

    var perdedora := Partida.new(p)
    for i in 3:
        perdedora.marcas[celula_vazia.y][celula_vazia.x] = Partida.Marca.LIMPA
        perdedora.pintar(celula_vazia.x, celula_vazia.y)
    _ok("três erros encerram a partida", perdedora.perdeu)
    _ok("depois de perder, pintar não responde mais",
        perdedora.pintar(celula_cheia.x, celula_cheia.y) == Partida.Jogada.NADA)

    var anotando := Partida.new(p)
    anotando.alternar_cruz(celula_vazia.x, celula_vazia.y)
    _ok("anotar vazia marca a cruz",
        anotando.marca_em(celula_vazia.x, celula_vazia.y) == Partida.Marca.CRUZ)
    anotando.alternar_cruz(celula_vazia.x, celula_vazia.y)
    _ok("anotar de novo limpa a cruz",
        anotando.marca_em(celula_vazia.x, celula_vazia.y) == Partida.Marca.LIMPA)
    _ok("anotação não custa vida nem conta erro",
        anotando.vidas == Partida.VIDAS_INICIAIS and anotando.erros == 0)

    # A marca X não pode entregar a solução: se ela ficasse vermelha sobre uma
    # célula cheia, dava para achar o desenho inteiro sem nunca ser punido.
    var espiando := Partida.new(p)
    espiando.alternar_cruz(celula_cheia.x, celula_cheia.y)
    _ok("anotar X sobre célula cheia não marca como erro",
        not espiando.celulas_erradas.has(celula_cheia))
    espiando.pintar(celula_vazia.x, celula_vazia.y)
    _ok("pintar errado sim marca a célula como errada",
        espiando.celulas_erradas.has(celula_vazia))

func _estrelas() -> void:
    var p := Catalogo.fase(1)

    var perfeita := _resolver(p)
    perfeita.tempo = 1.0
    _ok("resolver rápido e limpo dá 3 estrelas", perfeita.estrelas() == 3)

    var devagar := _resolver(p)
    devagar.tempo = p.tempo_alvo + 10.0
    _ok("resolver limpo mas devagar dá 2 estrelas", devagar.estrelas() == 2)

    var com_erro := _resolver(p)
    com_erro.erros = 1
    com_erro.tempo = 1.0
    _ok("resolver com erro dá 1 estrela", com_erro.estrelas() == 1)

    var em_andamento := Partida.new(p)
    _ok("partida não terminada vale 0 estrelas", em_andamento.estrelas() == 0)

func _desfazer_e_dica() -> void:
    var p := Catalogo.fase(1)
    var celula := _achar(p, true)

    var partida := Partida.new(p)
    partida.pintar(celula.x, celula.y)
    var antes := partida.pintadas_corretas
    _ok("desfazer devolve verdadeiro quando há o que desfazer", partida.desfazer())
    _ok("desfazer limpa a célula", partida.marca_em(celula.x, celula.y) == Partida.Marca.LIMPA)
    _ok("desfazer corrige a contagem de acertos", partida.pintadas_corretas == antes - 1)
    _ok("desfazer no começo não faz nada", not partida.desfazer())

    var com_dica := Partida.new(p)
    var revelada := com_dica.pedir_dica()
    _ok("a dica revela uma célula que é mesmo cheia", p.e_cheia(revelada.x, revelada.y))
    _ok("a dica marca a célula como pintada",
        com_dica.marca_em(revelada.x, revelada.y) == Partida.Marca.PINTADA)
    var terminada := _resolver(p)
    terminada.usou_dica = true
    terminada.tempo = 1.0
    _ok("quem usa dica não tira 3 estrelas", terminada.estrelas() == 1)

func _progresso() -> void:
    Progresso.fases.clear()
    _ok("sem progresso, a fase 1 está aberta", Progresso.desbloqueada(1))
    _ok("sem progresso, a fase 2 está fechada", not Progresso.desbloqueada(2))
    _ok("sem progresso, o capítulo 2 está fechado", not Progresso.capitulo_aberto(1))

    Progresso.registrar(1, 3, 42.0)
    _ok("a fase resolvida fica marcada", Progresso.resolvida(1))
    _ok("guarda as estrelas", Progresso.estrelas_de(1) == 3)
    _ok("guarda o tempo", is_equal_approx(Progresso.tempo_de(1), 42.0))
    _ok("resolver a fase 1 abre a fase 2", Progresso.desbloqueada(2))

    Progresso.registrar(1, 1, 20.0)
    _ok("uma repetição pior não rebaixa as estrelas", Progresso.estrelas_de(1) == 3)
    _ok("mas guarda o tempo melhor", is_equal_approx(Progresso.tempo_de(1), 20.0))

    # Contrato entre as duas regras: não adianta abrir um capítulo se a
    # primeira fase dele continuar trancada.
    Progresso.fases.clear()
    var capitulo_um: Array = Catalogo.capitulos[0]["fases"]
    for i in capitulo_um.size() - 2:
        Progresso.fases[str(int(capitulo_um[i]))] = {"estrelas": 1, "tempo": 10.0}
    _ok("faltando duas fases, o capítulo seguinte abre", Progresso.capitulo_aberto(1))
    var primeira_do_dois: int = int(Catalogo.capitulos[1]["fases"][0])
    _ok("e a primeira fase dele fica jogável", Progresso.desbloqueada(primeira_do_dois))

    var coerente := true
    for indice in Catalogo.capitulos.size():
        if Progresso.capitulo_aberto(indice):
            var primeira: int = int(Catalogo.capitulos[indice]["fases"][0])
            if not Progresso.desbloqueada(primeira):
                coerente = false
    _ok("todo capítulo aberto tem a primeira fase liberada", coerente)

    Progresso.apagar_tudo()
    _ok("apagar tudo zera o progresso", Progresso.total_resolvidas() == 0)

## Teste mais forte: joga as 50 fases até o fim, conferindo cada vitória.
func _resolver_todas() -> void:
    var todas_ok := true
    var celulas := 0
    for p in Catalogo.fases:
        var partida := _resolver(p)
        celulas += p.total_cheias
        if not partida.concluida or partida.erros > 0 or partida.vidas != Partida.VIDAS_INICIAIS:
            todas_ok = false
            print("      falhou em: ", p.nome)
    _ok("as 50 fases são vencíveis pintando a solução (%d células)" % celulas, todas_ok)

func _resolver(p: Puzzle) -> Partida:
    var partida := Partida.new(p)
    for y in p.lado:
        for x in p.lado:
            if p.e_cheia(x, y):
                partida.pintar(x, y)
    return partida

func _achar(p: Puzzle, cheia: bool) -> Vector2i:
    for y in p.lado:
        for x in p.lado:
            if p.e_cheia(x, y) == cheia:
                return Vector2i(x, y)
    return Vector2i(0, 0)

func _ok(nome: String, condicao: bool) -> void:
    _total += 1
    if condicao:
        print("  [ok]    ", nome)
    else:
        _falhas += 1
        print("  [FALHA] ", nome)
