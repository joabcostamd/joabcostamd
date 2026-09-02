extends Node
## Efeitos sonoros sintetizados por código — nenhum arquivo de áudio no repositório.

const TAXA := 22050

var _tocadores: Array[AudioStreamPlayer] = []
var _proximo := 0
var _sons := {}
var _musica: AudioStreamPlayer

func _ready() -> void:
    for i in 8:
        var tocador := AudioStreamPlayer.new()
        add_child(tocador)
        _tocadores.append(tocador)
    _musica = AudioStreamPlayer.new()
    add_child(_musica)

    _sons["pintar"] = _tom([660.0], 0.06, 0.25)
    _sons["cruz"] = _tom([330.0], 0.05, 0.18)
    _sons["erro"] = _tom([160.0, 120.0], 0.28, 0.35)
    _sons["vitoria"] = _tom([523.0, 659.0, 784.0, 1046.0], 0.55, 0.30)
    _sons["derrota"] = _tom([392.0, 311.0, 233.0], 0.6, 0.32)
    _sons["clique"] = _tom([880.0], 0.04, 0.2)
    _sons["estrela"] = _tom([1046.0, 1318.0], 0.22, 0.25)

    _musica.stream = _trilha()
    _atualizar_volume_musica()
    _musica.play()
    Progresso.opcoes_mudaram.connect(_atualizar_volume_musica)

## Encerra o áudio antes do jogo fechar: sem isso a trilha em execução fica
## pendurada e o Godot avisa de instâncias vazadas na saída.
func _exit_tree() -> void:
    parar_tudo()

## Para tudo e solta as amostras. Chamado ao sair e pelos testes.
func parar_tudo() -> void:
    _musica.stop()
    _musica.stream = null
    for tocador in _tocadores:
        tocador.stop()
        tocador.stream = null
    _sons.clear()

func _atualizar_volume_musica() -> void:
    var volume := float(Progresso.opcoes["volume_musica"])
    _musica.volume_db = linear_to_db(maxf(volume, 0.0001))
    _musica.stream_paused = volume <= 0.001

## Trilha de fundo: quatro acordes longos em looping, sintetizados como os
## efeitos. Fica discreta de propósito — é um jogo de concentração.
func _trilha() -> AudioStreamWAV:
    var acordes := [
        [220.00, 261.63, 329.63],   # Lá menor
        [174.61, 220.00, 261.63],   # Fá maior
        [130.81, 164.81, 196.00],   # Dó maior
        [196.00, 246.94, 293.66],   # Sol maior
    ]
    var por_acorde := int(TAXA * 2.4)
    var total := por_acorde * acordes.size()
    var dados := PackedByteArray()
    dados.resize(total * 2)
    for i in total:
        var indice := int(i / por_acorde)
        var posicao := float(i % por_acorde) / float(por_acorde)
        # entra e sai devagar, para os acordes se encadearem sem corte
        var envelope := minf(posicao * 5.0, 1.0) * minf((1.0 - posicao) * 5.0, 1.0)
        var t := float(i) / TAXA
        var onda := 0.0
        for frequencia in acordes[indice]:
            onda += sin(TAU * frequencia * t)
        onda /= float(acordes[indice].size())
        var amostra := int(clampf(onda * envelope * 0.16, -1.0, 1.0) * 32767.0)
        dados.encode_s16(i * 2, amostra)
    var fluxo := AudioStreamWAV.new()
    fluxo.format = AudioStreamWAV.FORMAT_16_BITS
    fluxo.mix_rate = TAXA
    fluxo.stereo = false
    fluxo.loop_mode = AudioStreamWAV.LOOP_FORWARD
    fluxo.loop_begin = 0
    fluxo.loop_end = total
    fluxo.data = dados
    return fluxo

func tocar(nome: String) -> void:
    if not _sons.has(nome):
        return
    var tocador := _tocadores[_proximo]
    _proximo = (_proximo + 1) % _tocadores.size()
    tocador.stream = _sons[nome]
    tocador.volume_db = linear_to_db(maxf(float(Progresso.opcoes["volume_efeitos"]), 0.0001))
    tocador.play()

## Sequência de notas com ataque e queda suaves, para não estalar.
func _tom(frequencias: Array, duracao: float, volume: float) -> AudioStreamWAV:
    var total := int(TAXA * duracao)
    var dados := PackedByteArray()
    dados.resize(total * 2)
    var por_nota := maxi(int(total / float(frequencias.size())), 1)
    for i in total:
        var indice_nota := mini(int(i / por_nota), frequencias.size() - 1)
        var frequencia: float = frequencias[indice_nota]
        var t := float(i) / TAXA
        var posicao_na_nota := float(i % por_nota) / float(por_nota)
        var envelope := minf(posicao_na_nota * 12.0, 1.0) * pow(1.0 - posicao_na_nota, 1.6)
        var onda := sin(TAU * frequencia * t) * 0.7 + sin(TAU * frequencia * 2.0 * t) * 0.3
        var amostra := int(clampf(onda * envelope * volume, -1.0, 1.0) * 32767.0)
        dados.encode_s16(i * 2, amostra)
    var fluxo := AudioStreamWAV.new()
    fluxo.format = AudioStreamWAV.FORMAT_16_BITS
    fluxo.mix_rate = TAXA
    fluxo.stereo = false
    fluxo.data = dados
    return fluxo
