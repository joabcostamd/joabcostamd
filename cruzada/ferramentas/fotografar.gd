extends Node
## Fotografa a partida num estado escolhido. Ferramenta de trabalho: serve para
## OLHAR o jogo, que é a única forma de achar o que nenhum teste acha — o
## fantasma que virou retângulo cinza, o rótulo que estourou o painel, a
## diagonal que não tinha estado na tela.
##
##     xvfb-run -a godot res://ferramentas/fotografar.tscn \
##         -- <turnos> <nome> <semente> <largura> <altura> [cinza]
##
## `nome` começando com "colheita" para no primeiro evento de colheita, que é o
## instante que interessa ver. A foto sai em `capturas-do-jogo/<nome>.png`.

func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    var turnos := int(args[0]) if args.size() > 0 else 9
    var nome := args[1] if args.size() > 1 else "x"
    var semente := int(args[2]) if args.size() > 2 else 20260904
    var larg := int(args[3]) if args.size() > 3 else 1280
    var alt := int(args[4]) if args.size() > 4 else 720
    var cinza := args.size() > 5

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://capturas-do-jogo"))
    Temas.usar(Temas.PADRAO, cinza)
    var sub := SubViewport.new()
    sub.size = Vector2i(larg, alt)
    sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(sub)

    var tela: Partida = preload("res://cenas/partida.tscn").instantiate()
    tela.semente = semente
    sub.add_child(tela)
    tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    for i in turnos:
        if tela.mesa.acabou:
            break
        Politica.talvez_descartar(tela.mesa)
        var j := Politica.gulosa(tela.mesa)
        if int(j[0]) < 0:
            break
        if int(j[2]) != tela.mesa.mao[int(j[0])]:
            tela.mesa.girar_na_mao(int(j[0]))
        tela.jogar(int(j[0]), int(j[1]))
        if nome.begins_with("colheita") and bool(tela._relato.get("colheita", false)):
            break
    if nome.begins_with("regras"):
        tela._regras_abertas = true
    tela._selecionada = 0
    var vazias := tela.mesa.casas_vazias()
    if not vazias.is_empty():
        tela._casa_sob_o_dedo = vazias[vazias.size() / 2]
    tela.queue_redraw()

    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    sub.get_texture().get_image().save_png(
        ProjectSettings.globalize_path("res://capturas-do-jogo/%s.png" % nome))
    get_tree().quit()
