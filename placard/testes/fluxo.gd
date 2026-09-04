extends Node
## Percorre o jogo inteiro de ponta a ponta, como quem joga: menu → partida →
## mesa após mesa → fim da run.
##
## É o teste que pega o que os outros não pegam — fiação. Um sinal desconectado,
## uma tela que não troca, um perfil que não grava: nada disso aparece num teste
## de regra, e tudo isso quebra o jogo por inteiro.
##
## Roda como CENA, não com `--script`: o `_ready` das telas só acontece depois
## que o laço principal começa, e um teste que não espera por ele mede um jogo
## que ainda não nasceu.
##
##     godot --headless res://testes/fluxo.tscn

var _passou := 0
var _falhou := 0
var _vitrines := 0

const PERFIL_DO_TESTE := "user://teste-fluxo.save"

func _ready() -> void:
    Temas.usar(Temas.PADRAO)
    Jogo.caminho_do_perfil = PERFIL_DO_TESTE
    DirAccess.remove_absolute(ProjectSettings.globalize_path(PERFIL_DO_TESTE))
    await _uma_run_inteira()
    await _a_travessia_pela_tela()
    await _derrota_gasta_as_vidas()

    print("")
    if _falhou > 0:
        print("FLUXO: %d de %d asserções FALHARAM" % [_falhou, _passou + _falhou])
        get_tree().quit(1)
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(PERFIL_DO_TESTE))
    print("FLUXO OK — %d asserções" % _passou)
    get_tree().quit(0)

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

func abrir() -> Jogo:
    var jogo: Jogo = preload("res://cenas/jogo.tscn").instantiate()
    add_child(jogo)
    await get_tree().process_frame
    return jogo

## Passa pela loja, se ela estiver aberta: compra o que der e segue.
func passar_pela_loja(jogo: Jogo) -> bool:
    if jogo._onde != Jogo.LOJA:
        return false
    var tela: TelaLoja = jogo._tela as TelaLoja
    ok(tela.run == jogo.run, "a loja conhece a run") if _vitrines == 0 else null
    Politica.comprar(jogo.run.loja, jogo.run.poderes)
    _vitrines += 1
    tela.emit_signal("seguir")
    return true

## Joga a mesa da tela até ela acabar, com a política gulosa, e avisa a tela.
func jogar_a_mesa(jogo: Jogo) -> void:
    if passar_pela_loja(jogo):
        return
    var tela: Partida = jogo._tela as Partida
    var passos := 0
    while not tela.mesa.acabou and passos < 200:
        passos += 1
        Politica.talvez_descartar(tela.mesa)
        var j := Politica.gulosa(tela.mesa)
        if int(j[0]) < 0:
            break
        if int(j[2]) != tela.mesa.mao[int(j[0])]:
            tela.mesa.girar_na_mao(int(j[0]))
        tela.jogar(int(j[0]), int(j[1]))
    tela.emit_signal("mesa_terminada", tela.mesa.venceu)

func _a_travessia_pela_tela() -> void:
    print("── a travessia, do fecho da rodada 6 em diante")
    var jogo: Jogo = await abrir()
    jogo._comecar_run()
    ## Força o fecho da rodada 6 sem jogar 18 mesas: o que se testa aqui é a
    ## FIAÇÃO da escolha, não o motor, que a suíte da run já cobre.
    var voltas := 0
    while not jogo._pode_continuar and voltas < 40:
        voltas += 1
        var tela: Partida = jogo._tela as Partida
        if tela == null:
            passar_pela_loja(jogo)
            continue
        tela.mesa.acabou = true
        tela.mesa.venceu = true
        tela.emit_signal("mesa_terminada", true)
    ok(jogo._pode_continuar, "a tela oferece a travessia ao fechar a rodada 6")
    ok(jogo._r_continuar.size.x > 0.0,
       "e o botão tem alvo de toque antes do primeiro desenho")
    ok(jogo._r_continuar.size.y >= 44.0, "com 44 px de altura, onde o dedo trabalha")
    igual(jogo._onde, Jogo.FIM_DA_RUN, "no fecho da run")
    ok(jogo.run.venceu, "com a run já vencida")

    ## Tocar em A TRAVESSIA segue; a vitória fica.
    var clique := InputEventMouseButton.new()
    clique.button_index = MOUSE_BUTTON_LEFT
    clique.pressed = true
    clique.position = jogo._r_continuar.get_center()
    jogo._gui_input(clique)
    ok(jogo.run.travessia, "seguir liga a travessia")
    ok(not jogo.run.acabou, "e a run continua")
    ok(jogo._onde == Jogo.LOJA or jogo._onde == Jogo.PARTIDA,
       "a tela volta para a loja ou para a mesa")
    igual(jogo.run.rodada, Metas.RODADAS + 1, "na rodada 7")
    jogo.free()

func _uma_run_inteira() -> void:
    print("── uma run inteira, do menu ao fecho")
    var jogo: Jogo = await abrir()
    igual(jogo._onde, Jogo.MENU, "o jogo abre no menu")
    ok(jogo.perfil != null, "com um perfil carregado")
    ok(jogo._tela is Menu, "e a tela do menu no ar")

    jogo._comecar_run()
    igual(jogo._onde, Jogo.PARTIDA, "JOGAR abre a partida")
    ok(jogo._tela is Partida, "com a tela da partida")
    var tela: Partida = jogo._tela as Partida
    ok(tela.run == jogo.run, "a tela conhece a run")
    ok(tela.mesa == jogo.run.mesa, "e desenha a mesa da run")
    igual(tela.rodada(), 1, "rodada 1")
    igual(tela.vidas(), 3, "três vidas")

    ## A run termina quando as vidas acabam OU quando a rodada 6 fecha e a tela
    ## passa a oferecer a travessia.
    var mesas := 0
    while not jogo.run.acabou and not jogo._pode_continuar and mesas < 90:
        mesas += 1
        jogar_a_mesa(jogo)
    ok(jogo.run.acabou or jogo._pode_continuar,
       "a run chega a um fim (%d passos)" % mesas)
    igual(jogo._onde, Jogo.FIM_DA_RUN, "e a tela vira o fecho da run")
    ok(jogo._tela == null, "o fecho é desenhado pelo próprio Jogo")
    igual(jogo.perfil.mesas_jogadas, jogo.run.mesas_jogadas,
          "o perfil contou exatamente as mesas que a run jogou")
    ok(jogo.run.maior_evento > 0, "houve pelo menos uma colheita na run")
    ok(_vitrines > 0, "a loja abriu entre as mesas (%d vezes)" % _vitrines)
    ok(jogo.run.poderes.quantos_selos() + _niveis(jogo) > 0,
       "e o jogador saiu dela com poder comprado")

    ## A conservação continua valendo depois de uma run inteira.
    ok(jogo.run.mesa.conservacao(), "a conta das cartas fecha no fim da run")
    jogo._pode_continuar = false

    jogo.free()

func _niveis(jogo: Jogo) -> int:
    var n := 0
    for cat in Maos.CATEGORIAS:
        n += jogo.run.poderes.nivel(cat)
    return n

func _derrota_gasta_as_vidas() -> void:
    print("── três derrotas encerram a run")
    var jogo: Jogo = await abrir()
    jogo._comecar_run()
    for i in 3:
        var tela: Partida = jogo._tela as Partida
        ok(tela.vidas() == 3 - i, "vida %d de 3" % (3 - i))
        ## Força a derrota sem jogar: esgota o orçamento com a meta no teto.
        tela.mesa.meta = 999999999
        tela.mesa.acabou = true
        tela.mesa.venceu = false
        tela.emit_signal("mesa_terminada", false)
    igual(jogo._onde, Jogo.FIM_DA_RUN, "a terceira derrota encerra a run")
    ok(not jogo.run.venceu, "e a run está perdida")
    igual(jogo.run.vidas, 0, "sem vidas sobrando")
    jogo.free()
