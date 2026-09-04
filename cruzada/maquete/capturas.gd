extends Node
## Renderiza a maquete nos oito temas e salva as capturas.
##
## Três modos por tema: paisagem 1280×720, retrato 360×800 e escala de cinza.
## O retrato é o modo onde a interface quebra primeiro; o cinza é o teste de
## daltonismo — se a grade continuar legível sem cor nenhuma, a forma está
## fazendo o trabalho.
##
## Usa SubViewport em vez de redimensionar a janela: o viewport principal fica
## preso à resolução base pelo `stretch/mode`, então mudar a janela não mudaria
## o que é desenhado. Cada captura sai no tamanho real que se quer medir.

const MODOS := [
    {"nome": "paisagem", "tamanho": Vector2i(1280, 720), "cinza": false},
    {"nome": "retrato", "tamanho": Vector2i(360, 800), "cinza": false},
    {"nome": "cinza", "tamanho": Vector2i(1280, 720), "cinza": true},
]

const PASTA := "res://maquete/capturas"

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
    var feitas := 0
    for indice in Temas.total():
        for modo in MODOS:
            if await _capturar(indice, modo):
                feitas += 1
    _salvar_paletas()
    await _folha_de_contato()
    print("CAPTURAS: %d de %d" % [feitas, Temas.total() * MODOS.size()])
    get_tree().quit(0 if feitas == Temas.total() * MODOS.size() else 1)

## Uma folha só com os oito temas lado a lado. Comparar tema abrindo oito
## arquivos não funciona: a escolha é relativa, e o olho precisa dos oito no
## mesmo campo de visão.
func _folha_de_contato() -> void:
    const CEL := Vector2(620, 349)
    const ROTULO := 30.0
    const PAD := 14.0
    var colunas := 2
    var linhas := int(ceil(float(Temas.total()) / colunas))

    var sub := SubViewport.new()
    sub.size = Vector2i(int(PAD + colunas * (CEL.x + PAD)),
                        int(PAD + linhas * (CEL.y + ROTULO + PAD)))
    sub.transparent_bg = false
    sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(sub)

    var folha := Control.new()
    folha.set_script(load("res://maquete/folha.gd"))
    folha.set("colunas", colunas)
    folha.set("celula", CEL)
    folha.set("rotulo", ROTULO)
    folha.set("pad", PAD)
    sub.add_child(folha)
    folha.size = Vector2(sub.size)

    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    var imagem := sub.get_texture().get_image()
    if imagem != null:
        imagem.save_png(ProjectSettings.globalize_path(PASTA + "/FOLHA-DE-CONTATO.png"))
    sub.queue_free()

func _capturar(indice: int, modo: Dictionary) -> bool:
    Temas.usar(indice, bool(modo["cinza"]))

    var sub := SubViewport.new()
    sub.size = modo["tamanho"]
    sub.transparent_bg = false
    sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(sub)

    var tela := Control.new()
    tela.set_script(load("res://maquete/tela.gd"))
    sub.add_child(tela)

    # Dois quadros: o primeiro monta a árvore, o segundo é o que já tem tudo
    # desenhado. Capturar no primeiro devolve tela preta.
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw

    var imagem := sub.get_texture().get_image()
    var ok := imagem != null and not _vazia(imagem)
    if ok:
        var id: String = Temas.dados(indice)["id"]
        var caminho := "%s/%s-%s.png" % [PASTA, id, modo["nome"]]
        imagem.save_png(ProjectSettings.globalize_path(caminho))
    else:
        push_error("captura vazia: tema %d modo %s" % [indice, modo["nome"]])
    sub.queue_free()
    return ok

## Uma captura toda de uma cor só é um erro de render, não uma tela. Sem esta
## checagem o build passa com oito PNG pretos.
func _vazia(imagem: Image) -> bool:
    var primeira := imagem.get_pixel(4, 4)
    var amostras := [Vector2i(imagem.get_width() / 2, imagem.get_height() / 2),
                     Vector2i(imagem.get_width() - 5, imagem.get_height() - 5),
                     Vector2i(imagem.get_width() / 3, imagem.get_height() / 4)]
    for p in amostras:
        if imagem.get_pixel(p.x, p.y) != primeira:
            return false
    return true

## Exporta as paletas para o validador de contraste em Python ler. A fonte de
## verdade continua sendo `temas.gd`: este JSON é derivado, nunca editado.
func _salvar_paletas() -> void:
    var lista: Array = []
    for i in Temas.total():
        lista.append(Temas.dados(i))
    var arquivo := FileAccess.open(PASTA + "/paletas.json", FileAccess.WRITE)
    if arquivo == null:
        push_error("não consegui escrever paletas.json")
        return
    arquivo.store_string(JSON.stringify(lista, "  "))
    arquivo.close()
