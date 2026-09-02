extends Node
## Faz o jogo se jogar sozinho, do início ao fim, para gravar em vídeo.
##   xvfb-run godot --write-movie demo.avi --fixed-fps 30 -- --demonstracao
##
## Vive pendurado no autoload de navegação, e não numa cena, para sobreviver
## às trocas de tela que ele mesmo provoca.

const FASE := 13          # 10x10, resolve num tempo bom de assistir
const RITMO := 0.055      # intervalo entre as jogadas

func _ready() -> void:
    _rodar.call_deferred()

func _rodar() -> void:
    _preparar_progresso()
    await _esperar(2.4)                       # abertura

    Navegacao.ir_para("menu")
    await _esperar(2.4)

    Navegacao.ir_para("capitulos")
    await _esperar(2.2)

    Navegacao.ir_para("fases", {"capitulo": 1})
    await _esperar(2.4)

    Navegacao.ir_para("jogo", {"fase": FASE})
    await _esperar(1.4)
    await _jogar()

    await _esperar(7.5)                       # revelação inteira
    Navegacao.ir_para("galeria")
    await _esperar(3.2)
    get_tree().quit()

## Resolve a fase pintando célula a célula, com um erro proposital no meio
## para o vídeo mostrar também a reação de quando o jogador erra.
func _jogar() -> void:
    var tela := get_tree().current_scene
    if tela == null or not ("grade" in tela):
        return
    var grade: GradeJogo = tela.grade
    var partida: Partida = tela.partida
    var lado: int = partida.puzzle.lado

    var alvos: Array[Vector2i] = []
    for y in lado:
        for x in lado:
            if partida.puzzle.e_cheia(x, y):
                alvos.append(Vector2i(x, y))

    var errou := false
    for i in alvos.size():
        # lá pelo meio, erra de propósito uma vez
        if not errou and i == int(alvos.size() * 0.45):
            errou = true
            var vazia := _achar_vazia(partida, lado)
            if vazia.x >= 0:
                grade.aplicar_em(vazia)
                await _esperar(0.9)
        grade.aplicar_em(alvos[i])
        await _esperar(RITMO)
        if partida.concluida:
            return

func _achar_vazia(partida: Partida, lado: int) -> Vector2i:
    for y in lado:
        for x in lado:
            if not partida.puzzle.e_cheia(x, y) \
                    and partida.marca_em(x, y) == Partida.Marca.LIMPA:
                return Vector2i(x, y)
    return Vector2i(-1, -1)

func _preparar_progresso() -> void:
    var estrelas := [3, 2, 3, 1, 3, 3, 2, 3, 3, 2, 3, 1]
    for i in estrelas.size():
        var fase := Catalogo.fase(i + 1)
        if fase != null:
            Progresso.fases[str(i + 1)] = {
                "estrelas": estrelas[i], "tempo": fase.tempo_alvo * 0.7}

func _esperar(segundos: float) -> void:
    await get_tree().create_timer(segundos).timeout
