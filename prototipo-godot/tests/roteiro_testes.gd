extends Node
## Testes de verdade rodando sem tela: liga em `godot --headless -- --testes`.
## O jogador é dirigido pela `intencao_*`, então dá para simular o jogo inteiro
## sem teclado e sem janela — é isso que permite testar na nuvem.

var _falhas := 0
var _total := 0

func _ready() -> void:
    _rodar.call_deferred()

func _rodar() -> void:
    var jogo: Node2D = get_parent()
    var jogador: Jogador = jogo.jogador
    jogador.ler_teclado = false

    await _teste_gravidade(jogador)
    await _teste_pousa_no_chao(jogador)
    await _teste_anda(jogador)
    await _teste_pula(jogador)
    await _teste_sem_pulo_duplo(jogador)
    await _teste_coleta_moeda(jogo, jogador)

    print("")
    if _falhas == 0:
        print("TODOS OS TESTES PASSARAM (%d/%d)" % [_total, _total])
    else:
        print("FALHOU: %d de %d testes" % [_falhas, _total])
    get_tree().quit(1 if _falhas > 0 else 0)

# --- testes ---

func _teste_gravidade(jogador: Jogador) -> void:
    _posicionar(jogador, Vector2(40, 60))
    var y_inicial := jogador.global_position.y
    await _avancar(10)
    _verificar("cai por gravidade quando está no ar", jogador.global_position.y > y_inicial + 5.0)

func _teste_pousa_no_chao(jogador: Jogador) -> void:
    _posicionar(jogador, Vector2(40, 200))
    await _avancar(60)
    _verificar("pousa no chão e para de cair", jogador.is_on_floor() and absf(jogador.velocity.y) < 50.0)

func _teste_anda(jogador: Jogador) -> void:
    _posicionar(jogador, Vector2(40, 290))
    await _avancar(10)
    var x_inicial := jogador.global_position.x
    jogador.intencao_x = 1.0
    await _avancar(30)
    jogador.intencao_x = 0.0
    _verificar("anda para a direita ao receber intenção", jogador.global_position.x > x_inicial + 40.0)

func _teste_pula(jogador: Jogador) -> void:
    _posicionar(jogador, Vector2(40, 290))
    await _avancar(20)
    var y_chao := jogador.global_position.y
    jogador.intencao_pulo = true
    await _avancar(15)
    _verificar("pula quando está no chão", jogador.global_position.y < y_chao - 30.0)

func _teste_sem_pulo_duplo(jogador: Jogador) -> void:
    _posicionar(jogador, Vector2(40, 100))
    await _avancar(20)  # já passou do coyote time, está caindo
    var y_antes := jogador.global_position.y
    jogador.intencao_pulo = true
    await _avancar(5)
    _verificar("não pula no ar (sem pulo duplo)", jogador.global_position.y > y_antes)

func _teste_coleta_moeda(jogo: Node2D, jogador: Jogador) -> void:
    var pontos_antes: int = jogo.pontos
    var alvo: Vector2 = jogo.moedas_restantes[0]
    _posicionar(jogador, alvo)
    await _avancar(3)
    _verificar("coleta a moeda ao encostar nela", jogo.pontos == pontos_antes + 1)

# --- utilidades ---

func _posicionar(jogador: Jogador, pos: Vector2) -> void:
    jogador.global_position = pos
    jogador.velocity = Vector2.ZERO
    jogador.intencao_x = 0.0
    jogador.intencao_pulo = false

func _avancar(quadros: int) -> void:
    for i in quadros:
        await get_tree().physics_frame

func _verificar(nome: String, condicao: bool) -> void:
    _total += 1
    if condicao:
        print("  [ok]    ", nome)
    else:
        _falhas += 1
        print("  [FALHA] ", nome)
