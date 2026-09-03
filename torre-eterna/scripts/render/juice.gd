class_name Juice
extends RefCounted

## Tremor de tela, flash, zoom-punch e câmera lenta.
## O "peso" do jogo mora aqui.

var tremor_amp := 0.0
var tremor_dur := 0.0
var tremor_t := 0.0
var offset := Vector2.ZERO
var zoom := 1.0
var zoom_alvo := 1.0
var flash_cor := Color(1, 1, 1, 0)
var flash_forca := 0.0
var aberracao := 0.0
var rng := RngX.new()
var _timer_lenta := 0.0

## Todo tremor do jogo passa por aqui, e e aqui que a opcao vale.
##
## Antes, so os tres `Jogo.tremor()` multiplicavam por `Cfg.forca_tremor()`.
## Os outros dez disparos — critico, morte de chefe, dourado, golpe na torre,
## queda da torre, onda de chefe, explosao, surgimento de chefe e a Purga —
## chamavam esta funcao com a amplitude crua e passavam por fora da opcao.
## "Movimento reduzido" promete zerar o tremor e o slider promete camera imovel
## em 0%: com dez de onze caminhos escapando, as duas promessas eram falsas.
## Filtrar no unico ponto por onde todos passam e o que torna a opcao real.
## Relogio de parede do juice: ver `atualizar()`.
var _ms_anterior := Time.get_ticks_msec()

## A escala de tremor, publicada para quem DESENHA.
##
## A regra do projeto (cobrada pelo linter) e que `Cfg.forca_tremor()` tenha um
## unico chamador, aqui — foi assim que "movimento reduzido" deixou de ser meia
## verdade, quando dez de onze caminhos passavam por fora da opcao. Mas o tremor
## do CORPO do inimigo e desenhado em `art_enemy.gd`, que e estatico e nao tem a
## instancia do Juice. Em vez de abrir excecao na regra, o Juice publica o valor
## e quem desenha le daqui. O ponto unico continua sendo um so.
static var escala := 1.0

static func atualizar_escala() -> void:
	escala = Cfg.forca_tremor()

func tremer(amplitude: float, duracao: float) -> void:
	amplitude *= Cfg.forca_tremor()
	if amplitude <= 0.001:
		return
	if amplitude <= tremor_amp * 0.6 and tremor_t > 0.0:
		return
	tremor_amp = maxf(tremor_amp, amplitude)
	tremor_dur = maxf(duracao, 0.05)
	tremor_t = tremor_dur

func flash(cor: Color, forca: float) -> void:
	flash_cor = cor
	flash_forca = maxf(flash_forca, forca)

func zoom_punch(forca: float) -> void:
	zoom = 1.0 + forca
	aberracao = maxf(aberracao, forca * 2.4)

## A camera lenta e um FATOR, nao um relogio.
##
## Ela escrevia direto em `Engine.time_scale`, e quando o timer acabava
## restaurava a "velocidade base" — o que matava a Retomada no meio se as duas
## coincidissem, e cancelava a camera lenta se o jogador trocasse a velocidade
## durante ela. Agora quem multiplica os tres fatores e o Jogo.
var dono = null

func camera_lenta(escala: float, ms: float) -> void:
	if dono != null:
		dono.fator_lenta = clampf(escala, 0.05, 8.0)
		dono.aplicar_time_scale()
	_timer_lenta = ms / 1000.0

## O juice anda em TEMPO REAL, nao em tempo de jogo.
##
## `dt` aqui chega de `_process`, ja multiplicado por `Engine.time_scale` — e a
## camera lenta mexe justamente nesse fator. Com `camera_lenta(0.25, 800)` o
## relogio que devia contar 0,8 s recebia dt/4 e contava 3,2 s: um chefe morrendo
## congelava a tela por mais de tres segundos. Do outro lado, com o turbo em 4x
## o flash e o tremor evaporavam em um quarto do tempo — o jogador acelerava o
## jogo e o feedback sumia junto, bem quando havia MAIS coisa acontecendo.
##
## O motor de audio ja resolvia assim (dt derivado do relogio do sistema); o
## juice nao. Agora os dois medem o mesmo segundo.
func atualizar(dt: float, velocidade_base: float) -> void:
	atualizar_escala()
	var agora := Time.get_ticks_msec()
	var dt_real := clampf(float(agora - _ms_anterior) / 1000.0, 0.0, 0.1)
	_ms_anterior = agora
	if tremor_t > 0.0:
		tremor_t -= dt_real
		var k := clampf(tremor_t / maxf(0.001, tremor_dur), 0.0, 1.0)
		var amp := tremor_amp * k * k
		offset = Vector2(rng.entre(-amp, amp), rng.entre(-amp, amp))
		if tremor_t <= 0.0:
			tremor_amp = 0.0
			offset = Vector2.ZERO
	else:
		offset = offset.lerp(Vector2.ZERO, minf(1.0, dt_real * 12.0))

	zoom = lerpf(zoom, zoom_alvo, minf(1.0, dt_real * 9.0))
	flash_forca = maxf(0.0, flash_forca - dt_real * 3.2)
	aberracao = maxf(0.0, aberracao - dt_real * 4.0)

	if _timer_lenta > 0.0:
		_timer_lenta -= dt_real
		if _timer_lenta <= 0.0 and dono != null:
			dono.fator_lenta = 1.0
			dono.aplicar_time_scale()

func desenhar_flash(ci: CanvasItem, tam: Vector2) -> void:
	if flash_forca <= 0.01:
		return
	var c := flash_cor
	c.a = clampf(flash_forca, 0.0, 0.6)
	ci.draw_rect(Rect2(Vector2.ZERO, tam), c)
