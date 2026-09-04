extends Node
## Fotografa a loja, com e sem o seletor de alvo aberto.
##
##     xvfb-run -a godot res://ferramentas/fotografar_loja.tscn -- <loja|selo|eixo> [larg] [alt]

func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    var qual := args[0] if args.size() > 0 else "loja"
    var larg := int(args[1]) if args.size() > 1 else 1280
    var alt := int(args[2]) if args.size() > 2 else 720
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://capturas-do-jogo"))
    Temas.usar(Temas.PADRAO)

    ## Uma run de verdade, jogada até a loja da rodada 4 — é onde a vitrine tem
    ## as quatro famílias e a build já tem o que mostrar.
    var run := Run.new(31337)
    var voltas := 0
    while not run.acabou and voltas < 60 and run.rodada < 4:
        voltas += 1
        Politica.jogar(run.mesa)
        run.concluir_mesa()
        if run.loja != null and run.rodada < 4:
            Politica.comprar(run.loja, run.poderes)
            run.fechar_loja()
    run.poderes.dinheiro = maxi(run.poderes.dinheiro, 22)

    var sub := SubViewport.new()
    sub.size = Vector2i(larg, alt)
    sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(sub)
    var tela: TelaLoja = preload("res://cenas/loja.tscn").instantiate()
    tela.run = run
    sub.add_child(tela)
    tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if qual != "loja":
        var busca := 0 if qual == "selo" else 1
        for i in run.loja.vagas.size():
            if run.loja.precisa_de_alvo(i) == busca:
                tela._escolhendo = i
                break
    tela.queue_redraw()
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    sub.get_texture().get_image().save_png(
        ProjectSettings.globalize_path("res://capturas-do-jogo/%s.png" % qual))
    get_tree().quit()
