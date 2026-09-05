extends Control
class_name Jogo
## A raiz. Guarda o perfil e a run, e troca as telas.
##
## Nenhuma regra mora aqui: ela só decide QUAL tela está no ar e passa adiante o
## que a `Run` respondeu.

enum { MENU, PARTIDA, TEMAS, DESAFIO, LOJA, CONQUISTAS, FIM_DA_RUN }

## Onde o progresso é gravado. O teste de fluxo aponta para outro arquivo:
## rodar a suíte não pode apagar o que o jogador conquistou.
static var caminho_do_perfil := Perfil.CAMINHO

var perfil: Perfil
var run: Run
var _onde := MENU
var _tela: Control
var _poeira: Array[Vector3] = []
var som: Som
var _anuncios: Array[String] = []      ## temas destravados esperando anúncio
var _conquistas: Array[String] = []    ## conquistas recém-caídas, esperando anúncio
## Quando a rodada 6 fecha, o fecho oferece seguir. Guarda os dois botões.
var _pode_continuar := false
var _r_continuar := Rect2()
var _r_encerrar := Rect2()

func _ready() -> void:
    _poeira = Pintura.semear_poeira()
    som = Som.new()
    add_child(som)
    perfil = Perfil.ler(caminho_do_perfil)
    som.volume = perfil.volume
    Temas.quatro_cores = perfil.quatro_cores
    Temas.usar(perfil.tema, perfil.escala_de_cinza)
    _acompanhar()
    get_viewport().size_changed.connect(_acompanhar)
    _ir(MENU)

func _acompanhar() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    queue_redraw()

func _ir(onde: int) -> void:
    _onde = onde
    if _tela != null:
        _tela.queue_free()
        _tela = null
    match onde:
        PARTIDA:
            var p: Partida = preload("res://cenas/partida.tscn").instantiate()
            p.run = run
            p.mesa = run.mesa
            p.volume = perfil.volume
            p.dicas = perfil.dicas
            p.mesa_terminada.connect(_mesa_terminada)
            _tela = p
        TEMAS:
            _tela = preload("res://cenas/temas.tscn").instantiate()
            _tela.set("perfil", perfil)
            _tela.connect("fechou", _voltar_ao_menu)
        LOJA:
            _tela = preload("res://cenas/loja.tscn").instantiate()
            _tela.set("run", run)
            _tela.set("som", som)
            _tela.connect("seguir", _sair_da_loja)
        CONQUISTAS:
            _tela = preload("res://cenas/conquistas.tscn").instantiate()
            _tela.set("perfil", perfil)
            _tela.connect("fechou", func(): _ir(MENU))
        DESAFIO:
            _tela = preload("res://cenas/desafio.tscn").instantiate()
            _tela.set("desafio", perfil.desafio.copia())
            _tela.connect("fechou", _guardar_desafio)
        FIM_DA_RUN:
            ## Sem tela filha: o fim da run é uma folha de papel com o resultado
            ## e os temas que abriram. Quem sai daqui volta ao menu.
            ##
            ## O traçado é calculado ao ENTRAR, não ao desenhar: botão que só
            ## existe depois do primeiro quadro é botão que não responde nele.
            _layout_do_fecho()
            queue_redraw()
            return
        _:
            _tela = preload("res://cenas/menu.tscn").instantiate()
            _tela.set("perfil", perfil)
            _tela.connect("jogar", _comecar_run)
            _tela.connect("temas", func(): _ir(TEMAS))
            _tela.connect("desafio", func(): _ir(DESAFIO))
            _tela.connect("conquistas", func(): _ir(CONQUISTAS))
    _tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_tela)
    queue_redraw()

func _sair_da_loja() -> void:
    run.fechar_loja()
    perfil.gravar(caminho_do_perfil)
    _ir(PARTIDA)

func _guardar_desafio() -> void:
    perfil.desafio = (_tela.get("desafio") as Desafio).copia()
    perfil.gravar(caminho_do_perfil)
    _ir(MENU)

func _voltar_ao_menu() -> void:
    perfil.tema = Temas.atual
    perfil.quatro_cores = Temas.quatro_cores
    perfil.escala_de_cinza = Temas.escala_de_cinza
    som.volume = perfil.volume
    perfil.gravar(caminho_do_perfil)
    _ir(MENU)

func _comecar_run() -> void:
    ## Semente da run tirada do relógio: é o único sorteio do jogo inteiro que
    ## não é derivado, e ele acontece uma vez por partida.
    run = Run.new(int(Time.get_unix_time_from_system()) & 0x7FFFFFFF,
                  perfil.desafio.copia())
    _ir(PARTIDA)

## A mesa acabou e a tela pediu para seguir. Quem decide o que vem é a Run.
func _mesa_terminada(_venceu: bool) -> void:
    var passo := run.concluir_mesa()
    if not bool(passo.get("pronto", false)):
        return
    perfil.mesas_jogadas += 1
    perfil.maior_evento = maxi(perfil.maior_evento, run.maior_evento)
    if run.venceu:
        perfil.runs_vencidas += 1
    for id in perfil.conferir(run, _ultimo_relato()):
        _anuncios.append(id)
    for id in perfil.conferir_conquistas(run):
        if not _conquistas.has(id):
            _conquistas.append(id)
            som.conquista()
    perfil.gravar(caminho_do_perfil)

    _pode_continuar = bool(passo.get("pode_continuar", false))
    if run.acabou or _pode_continuar:
        _ir(FIM_DA_RUN)
        return
    ## A loja só abre depois de uma mesa vencida. Perder repete a mesa na hora:
    ## passar pela vitrine sem dinheiro novo seria só atrito.
    if bool(passo.get("loja", false)) and run.loja != null:
        _ir(LOJA)
        return
    _ir(PARTIDA)

func _ultimo_relato() -> Dictionary:
    if _tela is Partida:
        return (_tela as Partida)._relato
    return {}

func _gui_input(evento: InputEvent) -> void:
    if _onde != FIM_DA_RUN:
        return
    if not (evento is InputEventMouseButton and evento.pressed
            and evento.button_index == MOUSE_BUTTON_LEFT):
        return
    ## Botão cujo alvo de toque só existe depois de um desenho é botão que não
    ## responde no primeiro quadro. O traçado do fecho é calculado aqui também.
    _layout_do_fecho()
    ## Fechar a rodada 6 é uma escolha, não um fim: parar com a vitória na mão,
    ## ou seguir e ver até onde vai. Quem segue não arrisca a vitória — ela já
    ## está registrada.
    if _pode_continuar and _r_continuar.has_point(evento.position):
        _pode_continuar = false
        _anuncios.clear()
        _conquistas.clear()
        run.continuar()
        perfil.gravar(caminho_do_perfil)
        _ir(LOJA if run.loja != null else PARTIDA)
        return
    if _pode_continuar and not _r_encerrar.has_point(evento.position):
        return
    if _pode_continuar:
        run.encerrar()
        _pode_continuar = false
    _anuncios.clear()
    _conquistas.clear()
    _ir(MENU)

func _draw() -> void:
    if _tela != null:
        return
    Pintura.fundo(self, size, _poeira)
    if _onde == FIM_DA_RUN:
        _fim_da_run()

## O fecho da run. Existe porque voltar direto ao menu apaga a única coisa que o
## jogador quer ver depois de 18 mesas — o que ele conseguiu, e o que ganhou.
## O traçado do fecho, sem desenhar nada. Chamado pelo desenho E pelo toque,
## para os dois concordarem sobre onde estão os botões.
func _layout_do_fecho() -> Rect2:
    var larg := minf(size.x - 64.0, 560.0)
    ## A caixa tem a altura do conteúdo: quatro linhas fixas, mais o que
    ## conquistou e o que destravou.
    var altura := 300.0 + float(mini(_conquistas.size(), 5)) * 24.0 \
                  + float(_anuncios.size()) * 26.0 + (60.0 if _pode_continuar else 0.0)
    altura = minf(altura, size.y - 48.0)
    var caixa := Rect2((size.x - larg) * 0.5, (size.y - altura) * 0.5, larg, altura)
    if _pode_continuar:
        var larg_b := (caixa.size.x - 76.0) * 0.5
        _r_encerrar = Rect2(caixa.position.x + 24, caixa.end.y - 74, larg_b, 50)
        _r_continuar = Rect2(_r_encerrar.end.x + 28, caixa.end.y - 74, larg_b, 50)
    return caixa

func _fim_da_run() -> void:
    var ff := Temas.fonte_do_tema(true)
    var f := Temas.fonte_do_tema()
    var caixa := _layout_do_fecho()
    Pintura.caixa(self, caixa, 14, 0.95)

    var titulo := "RUN VENCIDA" if run.venceu else "RUN ENCERRADA"
    if run.travessia and run.acabou:
        titulo = "TRAVESSIA: RODADA %d" % run.rodada_mais_funda
    Pintura.centrado(self, ff, Rect2(caixa.position.x, caixa.position.y + 24,
                                     caixa.size.x, 44), titulo, Temas.T_TITULO,
                     Temas.SUCESSO if run.venceu else Temas.ALERTA)

    var linhas := [
        ["mesas vencidas", "%d de %d" % [run.mesas_vencidas, run.total_de_mesas()]
            if not run.travessia else str(run.mesas_vencidas)],
        ["chegou até", "rodada %d · mesa %s" % [mini(run.rodada, Metas.RODADAS),
                                                Metas.NOMES[run.indice_da_mesa]]],
        ["maior colheita", Pintura.milhar(run.maior_evento)],
        ["maior cruz", "%d linha%s de uma vez" % [run.maior_cruz,
                          "" if run.maior_cruz == 1 else "s"]],
    ]
    var y := caixa.position.y + 92.0
    for linha in linhas:
        draw_string(f, Vector2(caixa.position.x + 32, y), str(linha[0]),
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO_SUAVE)
        draw_string(ff, Vector2(caixa.end.x - 32, y), str(linha[1]),
                    HORIZONTAL_ALIGNMENT_RIGHT, caixa.size.x - 64, Temas.T_CORPO,
                    Temas.TEXTO)
        y += 34.0

    if not _conquistas.is_empty():
        y += 12.0
        draw_rect(Rect2(caixa.position.x + 32, y - 14, caixa.size.x - 64, 1),
                  Color(Temas.FILETE, 0.25))
        draw_string(ff, Vector2(caixa.position.x + 32, y + 14),
                    "CONQUISTA" if _conquistas.size() == 1 else "CONQUISTAS",
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.SUCESSO)
        y += 34.0
        ## No máximo quatro na tela: uma lista de doze conquistas vira parede de
        ## texto e o jogador não lê nenhuma. O resto está na tela de conquistas.
        for i in mini(_conquistas.size(), 4):
            var c := Conquistas.achar(_conquistas[i])
            draw_string(f, Vector2(caixa.position.x + 32, y), str(c["nome"]),
                        HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_CORPO, Temas.TEXTO)
            y += 24.0
        if _conquistas.size() > 4:
            draw_string(f, Vector2(caixa.position.x + 32, y),
                        "e mais %d" % (_conquistas.size() - 4),
                        HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.TEXTO_SUAVE)
            y += 24.0

    if not _anuncios.is_empty():
        y += 12.0
        draw_rect(Rect2(caixa.position.x + 32, y - 14, caixa.size.x - 64, 1),
                  Color(Temas.FILETE, 0.25))
        draw_string(ff, Vector2(caixa.position.x + 32, y + 14),
                    "TEMA DESTRAVADO" if _anuncios.size() == 1 else "TEMAS DESTRAVADOS",
                    HORIZONTAL_ALIGNMENT_LEFT, -1, Temas.T_ROTULO, Temas.DESTAQUE)
        y += 38.0
        for id in _anuncios:
            for i in Temas.total():
                if str(Temas.dados(i)["id"]) == id:
                    draw_string(f, Vector2(caixa.position.x + 32, y),
                                str(Temas.dados(i)["nome"]), HORIZONTAL_ALIGNMENT_LEFT,
                                -1, Temas.T_CORPO, Temas.TEXTO)
                    y += 26.0

    if _pode_continuar:
        ## Dois botões, e o de seguir é o destacado: quem acabou de vencer a
        ## rodada 6 quer saber o que vem depois, e a resposta é "mais".
        Pintura.caixa(self, _r_encerrar, 10, 0.9)
        Pintura.centrado(self, ff, _r_encerrar, "ENCERRAR", Temas.T_CORPO, Temas.TEXTO)
        var b := StyleBoxFlat.new()
        b.bg_color = Temas.DESTAQUE
        b.set_corner_radius_all(10)
        draw_style_box(b, _r_continuar)
        Pintura.centrado(self, ff, _r_continuar, "A TRAVESSIA", Temas.T_CORPO,
                         Temas.CARTA if Temas.e_claro() else Temas.FUNDO)
        Pintura.centrado(self, f, Rect2(caixa.position.x, caixa.end.y - 100,
                                        caixa.size.x, 24),
                         "a vitória já está guardada — a travessia não a arrisca",
                         Temas.T_ROTULO, Temas.TEXTO_SUAVE)
        return
    Pintura.centrado(self, f, Rect2(caixa.position.x, caixa.end.y - 44,
                                    caixa.size.x, 28), "toque para voltar ao menu",
                     Temas.T_ROTULO, Temas.TEXTO_SUAVE)
