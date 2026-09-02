extends RefCounted
class_name Gerador
## Gera níveis aleatórios e só entrega os que o solucionador conseguiu resolver.
## Com a mesma semente, gera exatamente o mesmo nível — por isso dá para testar.

const TENTATIVAS_MAXIMAS := 400

var ultimo_tamanho_solucao := 0
var tentativas_gastas := 0

func gerar(semente: int, largura := 8, altura := 8, qtd_caixas := 2, passos_minimos := 8) -> Tabuleiro:
    var aleatorio := RandomNumberGenerator.new()
    aleatorio.seed = semente
    var solucionador := Solucionador.new()
    tentativas_gastas = 0

    for tentativa in TENTATIVAS_MAXIMAS:
        tentativas_gastas += 1
        var tabuleiro := _sortear(aleatorio, largura, altura, qtd_caixas)
        if tabuleiro == null:
            continue
        var solucao := solucionador.resolver(tabuleiro)
        if solucao.size() >= passos_minimos:
            ultimo_tamanho_solucao = solucao.size()
            return tabuleiro

    ultimo_tamanho_solucao = 0
    return null

func _sortear(aleatorio: RandomNumberGenerator, largura: int, altura: int, qtd_caixas: int) -> Tabuleiro:
    var tabuleiro := Tabuleiro.new()
    tabuleiro.largura = largura
    tabuleiro.altura = altura

    # moldura de paredes
    for x in largura:
        tabuleiro.paredes[Vector2i(x, 0)] = true
        tabuleiro.paredes[Vector2i(x, altura - 1)] = true
    for y in altura:
        tabuleiro.paredes[Vector2i(0, y)] = true
        tabuleiro.paredes[Vector2i(largura - 1, y)] = true

    # obstáculos internos esparsos
    var internas := int((largura - 2) * (altura - 2) * 0.10)
    for i in internas:
        var p := Vector2i(aleatorio.randi_range(1, largura - 2), aleatorio.randi_range(1, altura - 2))
        tabuleiro.paredes[p] = true

    var livres: Array[Vector2i] = []
    for x in range(1, largura - 1):
        for y in range(1, altura - 1):
            var p := Vector2i(x, y)
            if not tabuleiro.paredes.has(p):
                livres.append(p)

    if livres.size() < qtd_caixas * 2 + 1:
        return null

    _embaralhar(livres, aleatorio)
    var cursor := 0

    # caixas nunca nascem coladas na borda: lá elas travam de imediato
    for i in qtd_caixas:
        while cursor < livres.size() and _perto_da_borda(livres[cursor], largura, altura):
            cursor += 1
        if cursor >= livres.size():
            return null
        tabuleiro.caixas.append(livres[cursor])
        cursor += 1

    for i in qtd_caixas:
        if cursor >= livres.size():
            return null
        tabuleiro.alvos[livres[cursor]] = true
        cursor += 1

    if cursor >= livres.size():
        return null
    tabuleiro.jogador = livres[cursor]
    return tabuleiro

func _perto_da_borda(p: Vector2i, largura: int, altura: int) -> bool:
    return p.x <= 1 or p.y <= 1 or p.x >= largura - 2 or p.y >= altura - 2

func _embaralhar(lista: Array[Vector2i], aleatorio: RandomNumberGenerator) -> void:
    for i in range(lista.size() - 1, 0, -1):
        var j := aleatorio.randi_range(0, i)
        var tmp := lista[i]
        lista[i] = lista[j]
        lista[j] = tmp
