extends Control
class_name ImagemPuzzle
## Desenha a solução de uma fase como imagem colorida. Usada na revelação
## (com animação) e na galeria (parada).

var puzzle: Puzzle
var progresso := 1.0        # 0 a 1: quanto da imagem já apareceu
var mostrar_moldura := true
var bloqueada := false

func definir(novo: Puzzle) -> void:
    puzzle = novo
    queue_redraw()

func animar(duracao := 1.1) -> void:
    progresso = 0.0
    var animacao := create_tween()
    animacao.tween_property(self, "progresso", 1.0, duracao).set_trans(Tween.TRANS_CUBIC)
    animacao.tween_callback(queue_redraw)
    set_process(true)

func _process(_delta: float) -> void:
    queue_redraw()
    if progresso >= 1.0:
        set_process(false)

func _draw() -> void:
    if puzzle == null:
        return
    var lado := puzzle.lado
    var celula := floorf(minf(size.x, size.y) / lado)
    var total := celula * lado
    var canto := (size - Vector2(total, total)) * 0.5

    if mostrar_moldura:
        draw_rect(Rect2(canto - Vector2(6, 6), Vector2(total + 12, total + 12)),
                  Estilo.FUNDO_ALTO)
        draw_rect(Rect2(canto - Vector2(6, 6), Vector2(total + 12, total + 12)),
                  Estilo.BORDA, false, 2.0)

    if bloqueada:
        var fonte := get_theme_default_font()
        draw_string(fonte, canto + Vector2(0, total * 0.58), "?",
                    HORIZONTAL_ALIGNMENT_CENTER, total, int(total * 0.5),
                    Color(Estilo.TEXTO_SUAVE, 0.45))
        return

    # A revelação corre na diagonal, do canto superior esquerdo para o inferior
    # direito: fica mais bonito que aparecer tudo de uma vez.
    var limite := progresso * (lado * 2.0)
    for y in lado:
        for x in lado:
            if not puzzle.e_cheia(x, y):
                continue
            var distancia := float(x + y)
            if distancia > limite:
                continue
            var surgindo := clampf(limite - distancia, 0.0, 1.0)
            var cor := puzzle.cor
            # halo enquanto a célula está chegando
            if surgindo < 0.999:
                var halo := celula * 0.9 * (1.0 - surgindo)
                draw_rect(Rect2(canto + Vector2(x, y) * celula - Vector2(halo, halo) * 0.5,
                                Vector2(celula + halo, celula + halo)),
                          Color(Estilo.DESTAQUE, 0.30 * (1.0 - surgindo)))
            # Variação de tom bem leve para a imagem não ficar chapada.
            # Por linha, e não por diagonal: em diagonal virava um xadrez.
            cor = cor.lerp(Color.WHITE, 0.035 * (y % 3))
            cor = cor.lerp(Estilo.DESTAQUE, (1.0 - surgindo) * 0.8)
            # passa um pouco do tamanho final antes de assentar
            var exagero := sin(surgindo * PI) * 0.16
            var recuo := celula * (0.5 * (1.0 - surgindo) - exagero)
            draw_rect(Rect2(canto + Vector2(x, y) * celula + Vector2(recuo, recuo),
                            Vector2(celula - recuo * 2, celula - recuo * 2)), cor)
