extends RefCounted
class_name Aleatorio
## O único gerador de números aleatórios do jogo. Semeado, determinístico,
## reprodutível.
##
## `randi()`, `randf()` e `randomize()` são proibidos no núcleo: uma partida
## precisa poder ser repetida a partir da semente — para o replay, para o teste
## e para repetir a mesa perdida sem sortear uma dificuldade nova por acidente.
##
## É um xorshift64* mascarado em 63 bits. A máscara não é decoração: os inteiros
## do GDScript são com sinal, e `>>` num número negativo é deslocamento
## aritmético — sem a máscara o gerador degenera.

const MASCARA := 0x7FFFFFFFFFFFFFFF

var _s: int

func _init(semente: int) -> void:
    _s = semente if semente != 0 else 0x1E3779B97F4A7C15
    ## Descarta os primeiros passos: sementes pequenas e próximas produzem
    ## primeiras saídas parecidas, e a mesa 1 de duas runs vizinhas ficaria igual.
    for i in 4:
        _passo()

func _passo() -> int:
    _s ^= (_s << 13) & MASCARA
    _s ^= (_s >> 7)
    _s ^= (_s << 17) & MASCARA
    _s &= MASCARA
    return _s

## Um inteiro em [0, n). Devolve 0 para n <= 1, que é o caso degenerado honesto.
func inteiro(n: int) -> int:
    if n <= 1:
        return 0
    return _passo() % n

## Um real em [0, 1).
func real() -> float:
    return float(_passo() % 1000000) / 1000000.0

## Embaralhamento de Fisher–Yates, no lugar. `Array.shuffle()` usa o RNG global
## do Godot e quebraria a reprodutibilidade sem avisar.
func embaralhar(lista: Array) -> void:
    for i in range(lista.size() - 1, 0, -1):
        var j := inteiro(i + 1)
        var tmp: Variant = lista[i]
        lista[i] = lista[j]
        lista[j] = tmp

## A semente de uma mesa nunca é sorteada: é derivada da semente da run.
## Repetir a mesa perdida (R20) usa `tentativa` e chega noutro embaralhamento
## sem que a run inteira mude.
static func misturar(a: int, b: int, c: int) -> int:
    var x := (a * 1000003 + b * 2654435761 + c * 40503) & MASCARA
    x ^= (x >> 31)
    x = (x * 0x27220A95) & MASCARA
    x ^= (x >> 29)
    return x
