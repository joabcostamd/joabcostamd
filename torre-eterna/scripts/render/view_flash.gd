extends Control

## Camada de tela cheia: flashes, vinheta de perigo e aviso de chefe.

var campo: Node2D
var jogo: Node
var t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	jogo = get_node_or_null("/root/Jogo")

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var tam := size
	if campo != null and bool(Cfg.get_v("flashes", true)):
		campo.juice.desenhar_flash(self, tam)
	if jogo == null or not jogo.iniciado:
		return
	# vinheta vermelha quando a torre está em perigo
	var torre: Dictionary = jogo.s["torre"]
	var frac := float(torre["vida"]) / maxf(1.0, float(torre["vida_max"]))
	if frac < 0.35 and bool(torre["viva"]):
		var forca := (1.0 - frac / 0.35) * (0.28 + sin(t * 5.0) * 0.08)
		var passos := 6
		for i in passos:
			var f := float(i) / float(passos)
			var margem := tam * 0.5 * f * 0.55
			draw_rect(Rect2(margem, tam - margem * 2.0), Color(0.8, 0.05, 0.1, forca * 0.16), false, tam.x * 0.06)
