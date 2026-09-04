extends Node
class_name Som
## O som do CRUZADA, sintetizado em tempo real. Nenhum arquivo de áudio.
##
## Tudo aqui é onda gerada por código num `AudioStreamGenerator`: senoide com
## envelope, ruído filtrado para o baque, e uma escada de semitons para o Tear.
## É a mesma escolha da arte — o jogo inteiro cabe no repositório porque nada
## dele é asset.
##
## **A escada do Tear** é a peça central: cada degrau do Tear toca um semitom
## acima do anterior. Subir o Tear deixa de ser um número mudando num painel e
## passa a ser uma nota mais alta — e o ouvido entende "está crescendo" antes de
## o olho ler o número.

const TAXA := 44100.0
const VOZES := 8          ## quantos sons podem soar ao mesmo tempo

## A quinta justa e a terça maior, para os acordes da colheita saírem afinados.
const SEMITOM := 1.0594630943592953

var volume := 0.7
var ligado := true

var _vozes: Array[AudioStreamPlayer] = []
var _proxima := 0

func _ready() -> void:
    _preparar()

## Cria as vozes, uma vez só. Chamada também de `tocar`: o `_ready` de um nó só
## acontece depois que ele entra na árvore, e um som pedido antes disso estourava
## com índice fora de faixa — som de interface nunca pode derrubar a tela.
func _preparar() -> void:
    if not _vozes.is_empty():
        return
    for i in VOZES:
        var tocador := AudioStreamPlayer.new()
        var fluxo := AudioStreamGenerator.new()
        fluxo.mix_rate = TAXA
        ## Buffer curto: som de interface precisa sair no quadro do clique, e
        ## meio segundo de buffer é meio segundo de atraso.
        fluxo.buffer_length = 0.25
        tocador.stream = fluxo
        add_child(tocador)
        _vozes.append(tocador)

## Toca uma onda montada agora. `forma` escolhe o timbre; `envelope` decide se é
## um toque seco ou uma nota que decai.
func tocar(frequencia: float, duracao: float, ganho := 0.35, forma := 0,
           deslize := 0.0) -> void:
    if not ligado or volume <= 0.0:
        return
    _preparar()
    ## Fora da árvore não há saída de áudio: silêncio, e nunca erro.
    if _vozes.is_empty() or not is_inside_tree():
        return
    var tocador := _vozes[_proxima]
    _proxima = (_proxima + 1) % VOZES
    tocador.play()
    var buffer: AudioStreamGeneratorPlayback = tocador.get_stream_playback()
    if buffer == null:
        return
    var quadros := mini(int(duracao * TAXA), buffer.get_frames_available())
    var fase := 0.0
    for i in quadros:
        var t := float(i) / TAXA
        var progresso := float(i) / float(maxi(1, quadros))
        ## Ataque rápido e queda exponencial: é o envelope de tudo que é
        ## percussivo, e o que evita o clique no começo da onda.
        var envelope := minf(1.0, progresso * 40.0) * pow(1.0 - progresso, 2.2)
        var f := frequencia * (1.0 + deslize * progresso)
        fase += f / TAXA
        var amostra := 0.0
        match forma:
            0: amostra = sin(fase * TAU)
            1: amostra = sin(fase * TAU) * 0.6 + sin(fase * TAU * 2.0) * 0.3 \
                       + sin(fase * TAU * 3.0) * 0.1
            2: amostra = (randf() * 2.0 - 1.0) * 0.5 + sin(fase * TAU) * 0.5
        var v := amostra * envelope * ganho * volume
        buffer.push_frame(Vector2(v, v))

# ─────────────────────── os sons do jogo, nomeados ───────────────────────

## A carta pousando na casa. Curto e seco, com um pouco de ruído: é madeira, não
## sino. Toca em TODO posicionamento, então precisa ser discreto — som de ação
## comum que chama atenção vira irritação em dez minutos.
func carta() -> void:
    tocar(180.0 + randf() * 40.0, 0.06, 0.22, 2, -0.4)

## A carta sendo escolhida na mão. Ainda mais discreto: é confirmação de toque.
func toque() -> void:
    tocar(520.0, 0.03, 0.10, 0)

## A PARCELA: a linha chegando a 3/5 e 4/5. Duas notas curtas subindo, para o
## troco soar como promessa e não como prêmio.
func parcela(limiar: int) -> void:
    var base := 660.0 * pow(SEMITOM, 2.0 * float(limiar - 3))
    tocar(base, 0.09, 0.16, 0)
    tocar(base * 1.5, 0.07, 0.10, 0)

## A COLHEITA. Um acorde cuja altura sobe com o Tear — a escada de semitons — e
## cuja largura cresce com o número de linhas. Uma cruz total soa como um acorde
## de quatro notas uma oitava acima de uma colheita simples de Tear baixo.
func colheita(linhas: int, tear: int) -> void:
    var base := 220.0 * pow(SEMITOM, float(tear - 1))
    for i in mini(linhas, 4):
        ## Terça, quinta e oitava: o acorde cresce para cima, e cada linha a mais
        ## é literalmente uma nota a mais.
        var intervalos := [1.0, 1.5, 2.0, 3.0]
        tocar(base * float(intervalos[i]), 0.42 + 0.08 * i, 0.30, 1)

## O TEAR subindo. A nota do degrau novo, sozinha e curta: é o som que ensina a
## escada, e ele precisa ser reconhecível fora do acorde da colheita.
func tear(nivel: int) -> void:
    tocar(330.0 * pow(SEMITOM, float(nivel - 1)), 0.16, 0.18, 1)

## A FIANÇA pagando o dobro. Grave e largo, para o evento raro soar diferente e
## não só mais alto.
func fianca() -> void:
    tocar(110.0, 0.7, 0.34, 1)
    tocar(165.0, 0.6, 0.24, 1)

## A moeda do pagamento.
func moeda() -> void:
    tocar(1180.0 + randf() * 120.0, 0.07, 0.12, 0, -0.3)

## A vitória da mesa: tríade maior ascendente.
func vitoria() -> void:
    var base := 392.0
    for i in 3:
        tocar(base * pow(SEMITOM, float([0, 4, 7][i])), 0.5, 0.26, 1)

## A derrota. Duas notas descendo — sem estridência: perder já é o castigo.
func derrota() -> void:
    tocar(220.0, 0.35, 0.22, 1)
    tocar(174.6, 0.55, 0.20, 1)

## A conquista.
func conquista() -> void:
    for i in 3:
        tocar(523.0 * pow(SEMITOM, float([0, 7, 12][i])), 0.3, 0.20, 1)
