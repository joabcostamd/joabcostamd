extends Control
## Salvamento: estado da sincronização, e um código para levar o progresso
## de um aparelho a outro.

var _campo: TextEdit
var _aviso: Label

func _ready() -> void:
    Estilo.aplicar(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var coluna := VBoxContainer.new()
    coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
    coluna.offset_left = 150
    coluna.offset_right = -150
    coluna.offset_top = 26
    coluna.offset_bottom = -20
    coluna.add_theme_constant_override("separation", 10)
    add_child(coluna)

    coluna.add_child(Estilo.titulo(tr("NUVEM_TITULO"), 38))
    coluna.add_child(Estilo.legenda(_estado_da_nuvem(), 18,
        Estilo.SUCESSO if _tem_nuvem() else Estilo.TEXTO_SUAVE))

    var resumo := Estilo.legenda(tr("GALERIA_CONTAGEM") %
        [Progresso.total_resolvidas(), Catalogo.fases.size()], 17)
    coluna.add_child(resumo)

    _campo = TextEdit.new()
    _campo.custom_minimum_size.y = 190
    _campo.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    _campo.placeholder_text = tr("NUVEM_IMPORTAR")
    coluna.add_child(_campo)

    _aviso = Estilo.legenda("", 16)
    coluna.add_child(_aviso)

    var linha := HBoxContainer.new()
    linha.alignment = BoxContainer.ALIGNMENT_CENTER
    linha.add_theme_constant_override("separation", 12)
    coluna.add_child(linha)

    var exportar := Estilo.botao(tr("NUVEM_EXPORTAR"), 260)
    exportar.pressed.connect(_exportar)
    linha.add_child(exportar)

    var importar := Estilo.botao(tr("NUVEM_IMPORTAR"), 260)
    importar.pressed.connect(_importar)
    linha.add_child(importar)

    var voltar := Estilo.botao(tr("COMUM_VOLTAR"), 220)
    voltar.pressed.connect(func():
        Audio.tocar("clique")
        Navegacao.ir_para("opcoes"))
    var rodape := HBoxContainer.new()
    rodape.alignment = BoxContainer.ALIGNMENT_CENTER
    rodape.add_child(voltar)
    coluna.add_child(rodape)
    Juice.entrada(coluna)

## O jogo grava em user://, que é a pasta que Steam Cloud e equivalentes
## sincronizam sozinhos quando o jogo é publicado com essa opção ligada.
func _tem_nuvem() -> bool:
    return OS.has_feature("steam") or OS.get_environment("SteamAppId") != ""

func _estado_da_nuvem() -> String:
    return tr("NUVEM_SINCRONIZADO") if _tem_nuvem() else tr("NUVEM_LOCAL")

func _exportar() -> void:
    Audio.tocar("clique")
    var codigo := Sincronizacao.exportar(Progresso.como_dicionario())
    _campo.text = codigo
    DisplayServer.clipboard_set(codigo)
    _aviso.text = "%s  ·  %d" % [tr("NUVEM_EXPORTAR"), codigo.length()]
    _aviso.add_theme_color_override("font_color", Estilo.SUCESSO)
    Juice.pulsar(_aviso, 1.1, 0.3)

func _importar() -> void:
    Audio.tocar("clique")
    var lido := Sincronizacao.importar(_campo.text)
    if lido.is_empty():
        _aviso.text = "✕"
        _aviso.add_theme_color_override("font_color", Estilo.ERRO)
        Audio.tocar("erro")
        Juice.tremer(_campo, 8.0, 0.3)
        return
    var melhoraram := Progresso.mesclar_de(lido)
    _aviso.text = "✓  +%d" % maxi(melhoraram, 0)
    _aviso.add_theme_color_override("font_color", Estilo.SUCESSO)
    Audio.tocar("vitoria")
    Juice.pulsar(_aviso, 1.3, 0.4)
