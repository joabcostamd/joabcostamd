extends Node
## Fotografa as telas de fora da partida: o menu e o seletor de temas.
##
##     xvfb-run -a godot res://ferramentas/fotografar_telas.tscn -- <menu|temas> [larg] [alt]
func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    var qual := args[0] if args.size() > 0 else "menu"
    var larg := int(args[1]) if args.size() > 1 else 1280
    var alt := int(args[2]) if args.size() > 2 else 720
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://capturas-do-jogo"))
    Temas.usar(Temas.PADRAO)
    var sub := SubViewport.new()
    sub.size = Vector2i(larg, alt)
    sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(sub)
    var perfil := Perfil.new()
    if qual == "temas-abertos":
        for i in Temas.total():
            perfil.destravar(str(Temas.dados(i)["id"]))
    var tela: Control = preload("res://cenas/menu.tscn").instantiate() if qual == "menu" \
        else preload("res://cenas/temas.tscn").instantiate()
    tela.set("perfil", perfil)
    sub.add_child(tela)
    tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tela.queue_redraw()
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    sub.get_texture().get_image().save_png(
        ProjectSettings.globalize_path("res://capturas-do-jogo/%s.png" % qual))
    get_tree().quit()
