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

func camera_lenta(escala: float, ms: float) -> void:
	Engine.time_scale = clampf(escala, 0.05, 8.0)
	_timer_lenta = ms / 1000.0

func atualizar(dt: float, velocidade_base: float) -> void:
	if tremor_t > 0.0:
		tremor_t -= dt
		var k := clampf(tremor_t / maxf(0.001, tremor_dur), 0.0, 1.0)
		var amp := tremor_amp * k * k
		offset = Vector2(rng.entre(-amp, amp), rng.entre(-amp, amp))
		if tremor_t <= 0.0:
			tremor_amp = 0.0
			offset = Vector2.ZERO
	else:
		offset = offset.lerp(Vector2.ZERO, minf(1.0, dt * 12.0))

	zoom = lerpf(zoom, zoom_alvo, minf(1.0, dt * 9.0))
	flash_forca = maxf(0.0, flash_forca - dt * 3.2)
	aberracao = maxf(0.0, aberracao - dt * 4.0)

	if _timer_lenta > 0.0:
		_timer_lenta -= dt
		if _timer_lenta <= 0.0:
			Engine.time_scale = velocidade_base

func desenhar_flash(ci: CanvasItem, tam: Vector2) -> void:
	if flash_forca <= 0.01:
		return
	var c := flash_cor
	c.a = clampf(flash_forca, 0.0, 0.6)
	ci.draw_rect(Rect2(Vector2.ZERO, tam), c)
