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
    await _jogar_fase_1()
    await _montar("revelacao", {"fase": 1, "tempo": 40.0, "estrelas": 3})
    await _montar("galeria")
    await _montar("opcoes")
    await _montar("creditos")

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
    await get_tree().create_timer(0.15).timeout
    get_tree().quit(1 if _falhas > 0 else 0)

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
