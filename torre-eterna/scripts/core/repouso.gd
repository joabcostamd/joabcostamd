class_name Repouso
extends RefCounted

## O MODO REPOUSO — o jogo continua, a máquina descansa.
##
## Um idle é feito para ficar aberto. Este ficava aberto desenhando 60 quadros
## por segundo de arte procedural — cada inimigo é uma dezena de primitivas,
## mais partículas, mais o fundo animado da era — para uma pessoa que saiu para
## almoçar. Num notebook isso é a ventoinha ligada; num celular é a bateria indo
## embora e o aparelho esquentando na mão. "Deixar aberto" precisa ser barato,
## senão não é uma opção de verdade.
##
## POR QUE ISTO É SEGURO. A simulação deste jogo roda em `_physics_process`, e
## o Godot mantém esse relógio em 60 Hz fixo, independente de quantos quadros a
## tela desenha. Baixar `Engine.max_fps` corta o DESENHO e não encosta na
## simulação: o combate acontece igual, o ouro entra igual, a onda avança igual.
## Se a simulação estivesse em `_process` — como está em muito jogo — a mesma
## mudança faria o projétil andar 40 px por passo e atravessar inimigos de 15 px
## de raio, e o Modo Repouso seria uma máquina de bugs silenciosos.
##
## O que a pessoa perde é a animação, e é exatamente isso que ela pediu ao sair
## de perto. Qualquer toque, tecla ou clique acorda na hora.

## Quadros por segundo enquanto repousa. Seis é o suficiente para o número do
## ouro continuar visivelmente subindo — abaixo disso a tela parece travada, e
## uma tela que parece travada faz a pessoa fechar o jogo.
const FPS := 6

## Minutos parados até entrar sozinho. `0` desliga a entrada automática.
const MINUTOS_PADRAO := 5.0

var ativo := false
var _fps_anterior := 0
var _ocioso := 0.0
var _minutos := MINUTOS_PADRAO

func configurar(minutos: float) -> void:
	_minutos = maxf(0.0, minutos)
	if _minutos <= 0.0 and ativo:
		sair()

## Chamado a cada quadro pelo Main. `houve_entrada` vem do teclado, do mouse e
## do toque — os três, porque num celular não há teclado e num desktop não há
## toque, e cobrir só um deixaria metade dos jogadores presos no repouso.
func atualizar(dt: float, houve_entrada: bool) -> void:
	if houve_entrada:
		_ocioso = 0.0
		if ativo:
			sair()
		return
	if ativo or _minutos <= 0.0:
		return
	_ocioso += dt
	if _ocioso >= _minutos * 60.0:
		entrar()

func entrar() -> void:
	if ativo:
		return
	ativo = true
	_fps_anterior = Engine.max_fps
	Engine.max_fps = FPS
	Bus.repouso_mudou.emit(true)

func sair() -> void:
	if not ativo:
		return
	ativo = false
	_ocioso = 0.0
	# Devolve o limite que a pessoa escolheu, e não um número fixo: quem joga com
	# 30 fps por bateria não pode sair do repouso em 60.
	Engine.max_fps = _fps_anterior
	Bus.repouso_mudou.emit(false)

## A janela perdeu o foco. Entra na hora, sem esperar os minutos: a pessoa
## trocou de aba, e não há ninguém olhando para gastar quadro.
func ao_perder_foco() -> void:
	if _minutos > 0.0:
		entrar()
