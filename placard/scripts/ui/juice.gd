extends RefCounted
class_name Juice
## O peso. Tremor, fagulhas, cartas voando e a pausa que faz o golpe acertar.
##
## Tudo aqui é enfeite, e enfeite tem regra: **nenhum efeito pode esconder
## informação, atrasar o próximo clique ou durar mais que o gesto que o causou.**
## Um tremor que continua depois do impacto é enjoo, não impacto; uma partícula
## que cobre a carta é ruído com cara de produção.
##
## Cada efeito escala com o TAMANHO do que aconteceu. Uma colheita de uma linha
## treme de leve; uma cruz total sacode a tela — e a diferença entre as duas é a
## própria informação, sentida antes de lida.

## O tremor nunca passa disto. Acima de 10 px a tela deixa de ser legível e o
## jogador perde o tabuleiro justamente no instante em que ele mudou.
const TREMOR_MAXIMO := 9.0

## A pausa que precede o pagamento. É curta de propósito: meio segundo de
## congelamento é peso, um segundo é travamento.
const PAUSA_MAXIMA := 0.14

var tremor := 0.0
var pausa := 0.0
var pulso_do_tear := 0.0

## Fagulhas: (posição, velocidade, vida restante, vida total, cor).
var _fagulhas: Array = []
## Cartas voando da grade para o placar: (de, para, t, valor, naipe).
var _voos: Array = []

var _rng := RandomNumberGenerator.new()

func _init() -> void:
    _rng.randomize()

func vazio() -> bool:
    return tremor <= 0.0 and pausa <= 0.0 and _fagulhas.is_empty() \
        and _voos.is_empty() and pulso_do_tear <= 0.0

## Avança o tempo. Devolve `true` se algo mudou e a tela precisa redesenhar.
func avancar(delta: float) -> bool:
    if vazio():
        return false
    ## A pausa congela o resto: é ela que separa o impacto do pagamento.
    if pausa > 0.0:
        pausa = maxf(0.0, pausa - delta)
        return true
    tremor = maxf(0.0, tremor - delta * 34.0)
    pulso_do_tear = maxf(0.0, pulso_do_tear - delta * 2.2)
    var vivas := []
    for f in _fagulhas:
        f[2] -= delta
        if f[2] <= 0.0:
            continue
        f[0] += f[1] * delta
        ## Gravidade leve: a fagulha cai, não flutua. Flutuar lê como fumaça.
        f[1].y += 420.0 * delta
        f[1] *= 1.0 - minf(1.0, delta * 1.6)
        vivas.append(f)
    _fagulhas = vivas
    var voando := []
    for v in _voos:
        v[2] = minf(1.0, v[2] + delta * 2.6)
        if v[2] < 1.0:
            voando.append(v)
    _voos = voando
    return true

## O deslocamento da tela neste quadro. Aleatório dentro do raio do tremor.
func deslocamento() -> Vector2:
    if tremor <= 0.0:
        return Vector2.ZERO
    return Vector2(_rng.randf_range(-tremor, tremor),
                   _rng.randf_range(-tremor, tremor))

# ─────────────────────────── os gatilhos ───────────────────────────

## Uma carta pousou. Tremor mínimo — acontece a cada turno, e o que acontece
## sempre não pode chamar atenção.
func pousou(onde: Rect2) -> void:
    tremor = maxf(tremor, 1.6)
    _fagulhar(onde.get_center(), 5, 90.0, Temas.TEXTO_SUAVE, 0.25)

## A parcela pagou. Um punhado de fagulhas na linha, sem tremor: é troco.
func parcelou(onde: Rect2, quantas: int) -> void:
    _fagulhar(onde.get_center(), 4 + quantas * 2, 130.0, Temas.ACENTO, 0.4)

## A colheita. O tamanho de tudo — pausa, tremor e fagulhas — vem do número de
## linhas e do fator, que é exatamente a informação que o jogador precisa sentir.
func colheu(caixas: Array, destino: Vector2, cartas: Array, linhas: int,
            fator: int) -> void:
    var forca := clampf(float(linhas) / 4.0 + float(fator) / 90.0, 0.25, 1.0)
    pausa = PAUSA_MAXIMA * forca
    tremor = maxf(tremor, TREMOR_MAXIMO * forca)
    for i in caixas.size():
        var caixa: Rect2 = caixas[i]
        _fagulhar(caixa.get_center(), 10 + int(14.0 * forca), 200.0 + 260.0 * forca,
                  Temas.DESTAQUE, 0.55 + 0.35 * forca)
        if i < cartas.size():
            _voos.append([caixa, destino, 0.0, int(cartas[i][0]), int(cartas[i][1])])

## O Tear subiu. Um pulso no número, sem tremor: ele muda muitas vezes por mesa.
func tear_subiu() -> void:
    pulso_do_tear = 1.0

## A Fiança pagou o dobro. O evento mais raro do jogo treme mais que tudo.
func fianca(centro: Vector2) -> void:
    tremor = TREMOR_MAXIMO
    pausa = PAUSA_MAXIMA
    _fagulhar(centro, 60, 520.0, Temas.SUCESSO, 1.1)

func _fagulhar(centro: Vector2, quantas: int, forca: float, cor: Color,
               vida: float) -> void:
    ## O tema decide se há fagulha: sobre creme, partícula clara some e a que
    ## aparece vira sujeira. `PARTICULA` é o parâmetro que o tema declara.
    var densidade := clampf(Temas.PARTICULA * 4.0, 0.35, 1.4)
    for i in int(float(quantas) * densidade):
        var angulo := _rng.randf() * TAU
        var v := Vector2(cos(angulo), sin(angulo)) * forca * _rng.randf_range(0.4, 1.0)
        v.y -= forca * 0.35   ## joga um pouco para cima, para a queda ser vista
        _fagulhas.append([centro, v, vida, vida, cor])

# ─────────────────────────── o desenho ───────────────────────────

func desenhar(alvo: CanvasItem) -> void:
    for v in _voos:
        var t: float = v[2]
        ## Arco: a carta sai da grade, sobe e cai no placar. Linha reta lê como
        ## deslize; o arco lê como objeto sendo arremessado.
        var de: Rect2 = v[0]
        var para: Vector2 = v[1]
        var pos := de.get_center().lerp(para, t)
        pos.y -= sin(t * PI) * 90.0
        var escala := 1.0 - t * 0.65
        var r := Rect2(pos - de.size * escala * 0.5, de.size * escala)
        Carta.desenhar(alvo, r, int(v[3]), int(v[4]), Carta.NORMAL)
    for f in _fagulhas:
        var vida: float = f[2] / maxf(0.001, f[3])
        var cor: Color = f[4]
        alvo.draw_circle(f[0], 1.0 + 2.6 * vida, Color(cor, vida * 0.9))
