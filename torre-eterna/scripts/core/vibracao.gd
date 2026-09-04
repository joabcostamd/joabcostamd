extends Node

## A VIBRAÇÃO, QUE ERA UMA OPÇÃO SEM CÓDIGO.
##
## `"vibracao": true` existia em `Cfg.PADRAO`, aparecia no painel de
## configurações, era salva e carregada — e **nenhuma linha do jogo a lia**. A
## pessoa desligava uma coisa que nunca esteve ligada, ou ligava uma coisa que
## nunca aconteceria. É o mesmo defeito que esta auditoria já encontrou nos
## modificadores de elite e na Adaptação do Enxame: promessa escrita na
## interface sem nada por trás.
##
## Agora ela existe, e existe com parcimônia. Vibração em jogo idle é
## perigosíssima: o jogo fica horas aberto, e um aparelho que treme a cada abate
## esvazia a bateria e vira intolerável em dez minutos. Então só quatro momentos
## vibram, e são os quatro em que ALGO ACONTECEU COM VOCÊ:
##
##   a torre levou dano · a torre caiu · a Purga saiu perfeita · conquista nova
##
## Abate, tiro, ouro e onda limpa NÃO vibram, de propósito. Eles acontecem
## dezenas de vezes por minuto.
##
## Vale para celular (`vibrate_handheld`) e para controle (`start_joy_vibration`)
## — o mesmo evento, o mesmo respeito pela opção, dois aparelhos diferentes.

## Duração de cada tipo, em milissegundos. Curto: o toque é pontuação, não alarme.
const MS_DANO := 25
const MS_QUEDA := 320
const MS_PERFEITA := 45
const MS_CONQUISTA := 70

## Mesmo com a opção ligada, dois toques colados viram um zumbido. Este é o
## intervalo mínimo entre duas vibrações.
const INTERVALO_MIN_MS := 90

var _ultima := 0

func _ready() -> void:
	name = "Vibracao"
	Bus.torre_atingida.connect(_ao_dano)
	Bus.torre_caiu.connect(_ao_cair)
	Bus.purga_usada.connect(_ao_purga)
	Bus.conquista_desbloqueada.connect(_ao_conquista)

func _ao_dano(_dano: float, _vida: float, _vida_max: float) -> void:
	_tocar(MS_DANO, 0.35)

func _ao_cair() -> void:
	_tocar(MS_QUEDA, 1.0)

func _ao_purga(_qualidade: float, perfeita: bool) -> void:
	# Só a perfeita. A Purga comum acontece a cada 26 segundos, e vibrar nela
	# seria vibrar o tempo todo — o que treina a pessoa a desligar a opção.
	if perfeita:
		_tocar(MS_PERFEITA, 0.6)

func _ao_conquista(_id: String) -> void:
	_tocar(MS_CONQUISTA, 0.5)

func _tocar(ms: int, forca: float) -> void:
	if not bool(Cfg.get_v("vibracao", true)):
		return
	var agora := Time.get_ticks_msec()
	if agora - _ultima < INTERVALO_MIN_MS:
		return
	_ultima = agora
	# Celular. Em desktop não faz nada e não custa nada.
	Input.vibrate_handheld(ms)
	# Controle. Só no primeiro conectado: vibrar todos seria vibrar o controle
	# de quem está assistindo.
	var conectados := Input.get_connected_joypads()
	if not conectados.is_empty():
		var f := clampf(forca, 0.0, 1.0)
		Input.start_joy_vibration(int(conectados[0]), f * 0.5, f, float(ms) / 1000.0)
