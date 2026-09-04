extends Node
## Compara candidatos a nome no menu de verdade.
##
## Nome se decide olhando, não lendo lista — a mesma razão pela qual o tema foi
## escolhido numa folha de contato e não por adjetivo. Uma palavra de quatro
## letras e uma de oito ocupam o título de formas muito diferentes, e isso só
## aparece no tamanho real.
##
##     xvfb-run -a godot res://ferramentas/nomes.tscn -- URDA ORDO TESSERA

const PADRAO := ["CRUZADA", "URDA", "URDIA", "TESSERA", "ORDO", "AXIA"]

func _ready() -> void:
    var candidatos := OS.get_cmdline_user_args()
    if candidatos.is_empty():
        candidatos = PADRAO
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://capturas-do-jogo"))
    Temas.usar(Temas.PADRAO)

    var cel := Vector2i(620, 349)
    var colunas := 3
    var linhas := int(ceil(float(candidatos.size()) / float(colunas)))
    var folha := Image.create(cel.x * colunas + (colunas + 1) * 4,
                              cel.y * linhas + (linhas + 1) * 4, false,
                              Image.FORMAT_RGBA8)
    folha.fill(Color("#050d09"))
    for i in candidatos.size():
        Marca.NOME = str(candidatos[i]).to_upper()
        var sub := SubViewport.new()
        sub.size = Vector2i(1280, 720)
        sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        add_child(sub)
        var tela: Menu = preload("res://cenas/menu.tscn").instantiate()
        tela.perfil = Perfil.new()
        sub.add_child(tela)
        tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        var img := sub.get_texture().get_image()
        img.resize(cel.x, cel.y, Image.INTERPOLATE_LANCZOS)
        folha.blit_rect(img, Rect2i(Vector2i.ZERO, cel),
                        Vector2i(4 + (i % colunas) * (cel.x + 4),
                                 4 + (i / colunas) * (cel.y + 4)))
        sub.queue_free()
    folha.save_png(ProjectSettings.globalize_path("res://capturas-do-jogo/nomes.png"))
    print("NOMES: %d candidatos na folha" % candidatos.size())
    get_tree().quit()
