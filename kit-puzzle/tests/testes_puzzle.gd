extends Node
## Toda a regra do jogo é testada sem abrir janela: `./testar.sh`

var _falhas := 0
var _total := 0

func _ready() -> void:
    _rodar.call_deferred()

func _rodar() -> void:
    _regras_de_movimento()
    _solucionador()
    _gerador()
    _lote_de_niveis()

    print("")
    if _falhas == 0:
        print("TODOS OS TESTES PASSARAM (%d/%d)" % [_total, _total])
    else:
        print("FALHOU: %d de %d testes" % [_falhas, _total])
    get_tree().quit(1 if _falhas > 0 else 0)

func _sala(linhas: Array) -> Tabuleiro:
    # '#' parede, '@' jogador, '$' caixa, '.' alvo, '*' caixa já no alvo, ' ' vazio
    var t := Tabuleiro.new()
    t.altura = linhas.size()
    t.largura = (linhas[0] as String).length()
    for y in linhas.size():
        var linha: String = linhas[y]
        for x in linha.length():
            var p := Vector2i(x, y)
            match linha[x]:
                "#": t.paredes[p] = true
                "@": t.jogador = p
                "$": t.caixas.append(p)
                ".": t.alvos[p] = true
                "*":
                    t.caixas.append(p)
                    t.alvos[p] = true
                "+":
                    t.jogador = p
                    t.alvos[p] = true
    return t

func _regras_de_movimento() -> void:
    var t := _sala(["#####", "#@  #", "#####"])
    _ok("anda para espaço livre", t.mover(Tabuleiro.DIREITA) and t.jogador == Vector2i(2, 1))

    t = _sala(["#####", "#@  #", "#####"])
    _ok("não atravessa parede", not t.mover(Tabuleiro.ESQUERDA) and t.jogador == Vector2i(1, 1))

    t = _sala(["######", "#@$ .#", "######"])
    _ok("empurra a caixa", t.mover(Tabuleiro.DIREITA) and t.caixas[0] == Vector2i(3, 1))

    t = _sala(["#####", "#@$##", "#####"])
    _ok("não empurra caixa contra parede", not t.mover(Tabuleiro.DIREITA))

    t = _sala(["#######", "#@$$ .#", "#######"])
    _ok("não empurra duas caixas juntas", not t.mover(Tabuleiro.DIREITA))

    t = _sala(["#####", "#@$.#", "#####"])
    _ok("não declara vitória com caixa fora do alvo", not t.resolvido())

    t = _sala(["#####", "#@* #", "#####"])
    _ok("declara vitória com tudo no lugar", t.resolvido())

func _solucionador() -> void:
    var solucionador := Solucionador.new()

    var facil := _sala(["######", "#@$ .#", "######"])
    var solucao := solucionador.resolver(facil)
    _ok("acha a solução mais curta (2 empurrões)", solucao.size() == 2)

    var aplicado := facil.clonar()
    for direcao in solucao:
        aplicado.mover(direcao)
    _ok("a solução realmente resolve o nível", aplicado.resolvido())

    var impossivel := _sala(["#####", "#@$##", "#  .#", "#####"])
    _ok("prova que nível travado não tem solução", solucionador.resolver(impossivel).is_empty())

    var travado := _sala(["#####", "#@ .#", "# $##", "#####"])
    _ok("detecta caixa morta no canto", travado.tem_travamento())

func _gerador() -> void:
    var gerador := Gerador.new()
    var a := gerador.gerar(4242)
    _ok("gera um nível a partir da semente", a != null)
    if a == null:
        return
    _ok("o nível gerado tem solução conhecida", gerador.ultimo_tamanho_solucao >= 8)
    _ok("o nível gerado não nasce resolvido", not a.resolvido())

    var b := Gerador.new().gerar(4242)
    _ok("a mesma semente gera o mesmo nível", b != null and a.chave() == b.chave())

func _lote_de_niveis() -> void:
    # A vantagem de rodar sem tela: validar um lote inteiro de níveis de uma vez.
    var solucionador := Solucionador.new()
    var validos := 0
    var passos_total := 0
    for semente in range(1, 13):
        var nivel := Gerador.new().gerar(semente)
        if nivel == null:
            continue
        var solucao := solucionador.resolver(nivel)
        var copia := nivel.clonar()
        for direcao in solucao:
            copia.mover(direcao)
        if not solucao.is_empty() and copia.resolvido():
            validos += 1
            passos_total += solucao.size()
    _ok("lote de 12 níveis: todos jogáveis (%d validados, média de %d passos)" % [validos, passos_total / maxi(validos, 1)], validos >= 10)

func _ok(nome: String, condicao: bool) -> void:
    _total += 1
    if condicao:
        print("  [ok]    ", nome)
    else:
        _falhas += 1
        print("  [FALHA] ", nome)
