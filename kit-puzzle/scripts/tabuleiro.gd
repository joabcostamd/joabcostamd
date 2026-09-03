extends RefCounted
class_name Tabuleiro
## Estado puro do puzzle: sem nós, sem desenho, sem Godot visual.
## É isso que permite rodar milhares de partidas por segundo para testar e balancear.

const CIMA := Vector2i(0, -1)
const BAIXO := Vector2i(0, 1)
const ESQUERDA := Vector2i(-1, 0)
const DIREITA := Vector2i(1, 0)
const DIRECOES: Array[Vector2i] = [CIMA, BAIXO, ESQUERDA, DIREITA]

var largura := 0
var altura := 0
var paredes := {}            # Vector2i -> true
var alvos := {}              # Vector2i -> true
var caixas: Array[Vector2i] = []
var jogador := Vector2i.ZERO

func clonar() -> Tabuleiro:
    var copia := Tabuleiro.new()
    copia.largura = largura
    copia.altura = altura
    copia.paredes = paredes          # imutável durante a partida: pode compartilhar
    copia.alvos = alvos
    copia.caixas = caixas.duplicate()
    copia.jogador = jogador
    return copia

func e_parede(p: Vector2i) -> bool:
    return paredes.has(p) or p.x < 0 or p.y < 0 or p.x >= largura or p.y >= altura

func caixa_em(p: Vector2i) -> int:
    return caixas.find(p)

## Tenta mover o jogador. Devolve true se o movimento aconteceu.
func mover(direcao: Vector2i) -> bool:
    var destino := jogador + direcao
    if e_parede(destino):
        return false
    var indice := caixa_em(destino)
    if indice >= 0:
        var atras := destino + direcao
        if e_parede(atras) or caixa_em(atras) >= 0:
            return false
        caixas[indice] = atras
    jogador = destino
    return true

## Vitória é "toda caixa está num alvo" — a regra padrão do gênero.
## O gerador sempre cria a mesma quantidade de caixas e de alvos, então
## nunca sobra alvo vazio ao fim.
func resolvido() -> bool:
    for caixa in caixas:
        if not alvos.has(caixa):
            return false
    return true

## Identidade do estado, para o solucionador não repetir trabalho.
func chave() -> String:
    var partes: Array[String] = []
    for caixa in caixas:
        partes.append("%d.%d" % [caixa.x, caixa.y])
    partes.sort()
    return "%d.%d|%s" % [jogador.x, jogador.y, "_".join(partes)]

## Caixa encostada em duas paredes perpendiculares e fora do alvo nunca mais sai:
## detectar isso poda a busca e é o que torna o solucionador rápido.
func tem_travamento() -> bool:
    for caixa in caixas:
        if alvos.has(caixa):
            continue
        var vertical := e_parede(caixa + CIMA) or e_parede(caixa + BAIXO)
        var horizontal := e_parede(caixa + ESQUERDA) or e_parede(caixa + DIREITA)
        if vertical and horizontal:
            return true
    return false
