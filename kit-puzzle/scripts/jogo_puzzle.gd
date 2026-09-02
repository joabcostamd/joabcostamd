extends Node2D

const LADO := 48
const MARGEM := Vector2(40, 60)

@onready var titulo: Label = $HUD/Titulo
@onready var rodape: Label = $HUD/Rodape

var tabuleiro: Tabuleiro
var historico: Array[Tabuleiro] = []
var semente := 1
var movimentos := 0
var passos_ideais := 0
var dica: Vector2i = Vector2i.ZERO
var mostrando_dica := false

func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    if "--testes" in args:
        add_child(preload("res://tests/testes_puzzle.gd").new())
        return
    _novo_nivel(randi() % 100000)
    if "--captura" in args:
        add_child(preload("res://tests/captura.gd").new())

func _novo_nivel(nova_semente: int) -> void:
    semente = nova_semente
    var gerador := Gerador.new()
    var gerado := gerador.gerar(semente)
    if gerado == null:
        _novo_nivel(semente + 1)
        return
    tabuleiro = gerado
    passos_ideais = gerador.ultimo_tamanho_solucao
    historico.clear()
    movimentos = 0
    mostrando_dica = false
    _atualizar_textos()
    queue_redraw()

func _unhandled_key_input(evento: InputEvent) -> void:
    if not (evento is InputEventKey) or not evento.pressed or evento.echo:
        return
    match (evento as InputEventKey).physical_keycode:
        KEY_UP, KEY_W: _jogar(Tabuleiro.CIMA)
        KEY_DOWN, KEY_S: _jogar(Tabuleiro.BAIXO)
        KEY_LEFT, KEY_A: _jogar(Tabuleiro.ESQUERDA)
        KEY_RIGHT, KEY_D: _jogar(Tabuleiro.DIREITA)
        KEY_Z: _desfazer()
        KEY_R: _novo_nivel(semente)
        KEY_N: _novo_nivel(semente + 1)
        KEY_H: _pedir_dica()

func _jogar(direcao: Vector2i) -> void:
    if tabuleiro.resolvido():
        return
    var anterior := tabuleiro.clonar()
    if not tabuleiro.mover(direcao):
        return
    historico.append(anterior)
    movimentos += 1
    mostrando_dica = false
    _atualizar_textos()
    queue_redraw()

func _desfazer() -> void:
    if historico.is_empty():
        return
    tabuleiro = historico.pop_back()
    movimentos = maxi(movimentos - 1, 0)
    mostrando_dica = false
    _atualizar_textos()
    queue_redraw()

## A dica não é escrita à mão: o solucionador resolve o estado atual na hora.
func _pedir_dica() -> void:
    var solucao := Solucionador.new().resolver(tabuleiro)
    if solucao.is_empty():
        rodape.text = "Sem solução a partir daqui — aperte Z para desfazer."
        return
    dica = solucao[0]
    mostrando_dica = true
    _atualizar_textos()
    queue_redraw()

func _atualizar_textos() -> void:
    if not titulo:
        return
    titulo.text = "Nível %d   ·   movimentos: %d   ·   ideal: %d" % [semente, movimentos, passos_ideais]
    if tabuleiro.resolvido():
        var aviso := "  (solução perfeita!)" if movimentos <= passos_ideais else ""
        rodape.text = "RESOLVIDO em %d movimentos%s   —   N: próximo nível" % [movimentos, aviso]
    else:
        rodape.text = "setas: mover   ·   Z: desfazer   ·   R: reiniciar   ·   N: outro nível   ·   H: dica"

func _para_tela(p: Vector2i) -> Vector2:
    return MARGEM + Vector2(p.x * LADO, p.y * LADO)

func _draw() -> void:
    if tabuleiro == null:
        return
    draw_rect(Rect2(Vector2.ZERO, Vector2(640, 480)), Color("161a25"))

    for x in tabuleiro.largura:
        for y in tabuleiro.altura:
            var p := Vector2i(x, y)
            var canto := _para_tela(p)
            var celula := Rect2(canto, Vector2(LADO - 2, LADO - 2))
            if tabuleiro.e_parede(p):
                draw_rect(celula, Color("4b5578"))
            else:
                draw_rect(celula, Color("141824"))

    for alvo in tabuleiro.alvos:
        draw_circle(_para_tela(alvo) + Vector2(LADO, LADO) / 2.0 - Vector2.ONE, 9.0, Color("4d8f6a"))

    for caixa in tabuleiro.caixas:
        var no_lugar: bool = tabuleiro.alvos.has(caixa)
        var cor := Color("62c48c") if no_lugar else Color("c98a3e")
        draw_rect(Rect2(_para_tela(caixa) + Vector2(6, 6), Vector2(LADO - 14, LADO - 14)), cor)

    var centro := _para_tela(tabuleiro.jogador) + Vector2(LADO, LADO) / 2.0 - Vector2.ONE
    draw_circle(centro, 13.0, Color("e2574c"))

    if mostrando_dica:
        draw_line(centro, centro + Vector2(dica) * 26.0, Color("f2d06b"), 4.0)
