extends Node
## Áudio central: um player de música e um pequeno pool de efeitos.

const VOZES_SFX := 8

var _musica: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _proxima := 0


func _ready() -> void:
	_musica = AudioStreamPlayer.new()
	_musica.bus = "Master"
	add_child(_musica)
	for i in VOZES_SFX:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx.append(p)
	aplicar_opcoes()


func aplicar_opcoes() -> void:
	var op: Dictionary = Progresso.dados.get("opcoes", {})
	var v := float(op.get("volume_master", 1.0))
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(v, 0.0001, 1.0)))


func tocar_musica(fluxo: AudioStream) -> void:
	if fluxo == null or _musica.stream == fluxo:
		return
	_musica.stream = fluxo
	_musica.play()


func tocar_sfx(fluxo: AudioStream, tom: float = 1.0) -> void:
	if fluxo == null:
		return
	var p := _sfx[_proxima]
	_proxima = (_proxima + 1) % _sfx.size()
	p.stream = fluxo
	p.pitch_scale = tom
	p.play()
