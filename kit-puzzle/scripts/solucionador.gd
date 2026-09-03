extends RefCounted
class_name Solucionador
## Busca em largura: acha a solução mais curta, ou prova que não existe.
## É a peça que garante que todo nível gerado é jogável.

const LIMITE_ESTADOS := 300000

var estados_visitados := 0

## Devolve a menor sequência de direções que resolve, ou [] se não houver.
func resolver(inicial: Tabuleiro) -> Array[Vector2i]:
    estados_visitados = 0
    var vazio: Array[Vector2i] = []
    if inicial.resolvido():
        return vazio
    if inicial.tem_travamento():
        return vazio

    var fila: Array[Tabuleiro] = [inicial]
    var origem := {}                      # chave -> [chave_anterior, direcao]
    var vistos := {inicial.chave(): true}

    while not fila.is_empty():
        var atual: Tabuleiro = fila.pop_front()
        estados_visitados += 1
        if estados_visitados > LIMITE_ESTADOS:
            return vazio

        for direcao in Tabuleiro.DIRECOES:
            var proximo := atual.clonar()
            if not proximo.mover(direcao):
                continue
            var chave := proximo.chave()
            if vistos.has(chave):
                continue
            if proximo.tem_travamento():
                continue
            vistos[chave] = true
            origem[chave] = [atual.chave(), direcao]
            if proximo.resolvido():
                return _reconstruir(origem, chave, inicial.chave())
            fila.append(proximo)

    return vazio

func _reconstruir(origem: Dictionary, final: String, inicio: String) -> Array[Vector2i]:
    var caminho: Array[Vector2i] = []
    var atual := final
    while atual != inicio:
        var passo: Array = origem[atual]
        caminho.push_front(passo[1])
        atual = passo[0]
    return caminho
