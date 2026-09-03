extends Node
## Auditoria de fluxo: monta cada tela de verdade e confere que ela sobe.
##
## As telas são instanciadas à mão em vez de trocar a cena principal: assim o
## teste não é destruído junto com a tela que ele acabou de abrir.

var _falhas := 0
var _total := 0

func _ready() -> void:
    _rodar.call_deferred()

func _rodar() -> void:
    Progresso.fases.clear()

    await _montar("abertura")
    await _montar("menu")
    await _montar("capitulos")
    await _montar("fases", {"capitulo": 0})
    var trancado := await _montar("fases", {"capitulo": 4})
    _ok("pedir um capítulo fechado cai para o último aberto",
        trancado != null and trancado.get("_capitulo") == 0)
    await _jogar_fase_1()
    await _montar("revelacao", {"fase": 1, "tempo": 40.0, "estrelas": 3})
    await _montar("galeria")
    await _montar("opcoes")
    await _montar("creditos")
    await _montar("conquistas")
    await _montar("estatisticas")

    await _conferir_juice()

    _ok("a fase 1 ficou registrada como resolvida", Progresso.resolvida(1))
    _ok("resolver a fase 1 abriu a fase 2", Progresso.desbloqueada(2))

    # A galeria precisa refletir o que foi conquistado.
    var galeria := await _montar("galeria")
    _ok("a galeria monta com a fase já resolvida", galeria != null)
    if galeria != null:
        galeria.queue_free()

    Progresso.apagar_tudo()
    # Libera o que ainda estiver montado antes de sair, para não vazar objetos.
    for filho in get_children():
        filho.free()
    print("")
    if _falhas == 0:
        print("FLUXO OK — %d/%d verificações" % [_total, _total])
    else:
        print("FLUXO FALHOU: %d de %d" % [_falhas, _total])
    Audio.parar_tudo()
    await get_tree().create_timer(0.4).timeout
    get_tree().quit(1 if _falhas > 0 else 0)

## O juice é invisível nos testes de regra, então é aqui que ele é travado:
## se alguém remover o fundo, as partículas ou o equipador de botões, quebra.
func _conferir_juice() -> void:
    var tela := await _montar("menu")
    if tela == null:
        return
    var fundos := _procurar(tela, "FundoAnimado")
    var camadas := _procurar(tela, "CamadaParticulas")
    _ok("a tela tem fundo animado", fundos.size() == 1)
    _ok("a tela tem camada de partículas", camadas.size() == 1)

    var botoes := _procurar(tela, "Button")
    _ok("a tela tem botões", botoes.size() > 0)
    var todos_equipados := true
    for b in botoes:
        if not b.has_meta("com_juice"):
            todos_equipados = false
    _ok("todo botão foi equipado com resposta ao toque", todos_equipados)

    # Partículas de verdade: pedir um jato tem de encher a camada.
    if camadas.size() == 1:
        var camada: CamadaParticulas = camadas[0]
        camada.jato(Vector2(100, 100), Color.WHITE, 10)
        _ok("pedir faíscas cria partículas", camada.get("_faiscas").size() == 10)
        camada.confete(640.0, [Color.WHITE], 20)
        _ok("o confete soma às partículas", camada.get("_faiscas").size() == 30)
    tela.queue_free()
    await get_tree().process_frame

func _procurar(no: Node, classe: String) -> Array[Node]:
    var achados: Array[Node] = []
    if no.is_class(classe) or (no.get_script() != null and \
            no.get_script().get_global_name() == classe):
        achados.append(no)
    for filho in no.get_children():
        achados.append_array(_procurar(filho, classe))
    return achados

func _montar(tela: String, parametros := {}) -> Node:
    Navegacao.parametros = parametros
    var cena: PackedScene = load(Navegacao.TELAS[tela])
    if cena == null:
        _ok("a tela '%s' existe" % tela, false)
        return null
    var instancia := cena.instantiate()
    add_child(instancia)
    for i in 3:
        await get_tree().process_frame
    var montou := instancia.get_child_count() > 0
    _ok("a tela '%s' monta o conteúdo" % tela, montou)
    if tela != "jogo":
        instancia.queue_free()
    return instancia

func _jogar_fase_1() -> void:
    var tela := await _montar("jogo", {"fase": 1})
    if tela == null:
        return
    var partida: Partida = tela.partida
    _ok("a tela do jogo criou a partida", partida != null)
    if partida == null:
        return
    _ok("a partida começa com 3 vidas", partida.vidas == 3)
    for y in partida.puzzle.lado:
        for x in partida.puzzle.lado:
            if partida.puzzle.e_cheia(x, y):
                partida.pintar(x, y)
    _ok("pintar a solução completa vence a fase", partida.concluida)
    _ok("vencer sem errar vale 3 estrelas", partida.estrelas() == 3)
    Progresso.registrar(partida.puzzle.id, partida.estrelas(), partida.tempo)
    tela.queue_free()
    await get_tree().process_frame

func _ok(nome: String, condicao: bool) -> void:
    _total += 1
    if condicao:
        print("  [ok]    ", nome)
    else:
        _falhas += 1
        print("  [FALHA] ", nome)
