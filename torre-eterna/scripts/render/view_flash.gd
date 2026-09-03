extends Control

## Camada de tela cheia: flashes, vinheta de perigo e aviso de chefe.

var campo: Node2D
var jogo: Node
var t := 0.0

var banner_t := 0.0
var banner_nome := ""
var banner_sub := ""
var banner_cor := Color.WHITE
var fonte: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	jogo = get_node_or_null("/root/Jogo")
	fonte = ThemeDB.fallback_font
	Bus.chefe_surgiu.connect(_ao_chefe)
	Bus.prestigio_feito.connect(_ao_prestigio)

func _ao_chefe(e) -> void:
	banner_nome = Ux.txt(e.def, "nome", Cfg.ingles())
	banner_sub = Ux.txt(e.def, "dica", Cfg.ingles())
	banner_cor = e.cor
	banner_t = 3.4
	Bus.banner_cinematico.emit(banner_t)

func _ao_prestigio(camada: String, ganho: float) -> void:
	banner_nome = camada.to_upper()
	banner_sub = "+" + Fmt.big(ganho)
	banner_cor = Color("#a855f7")
	banner_t = 2.6
	Bus.banner_cinematico.emit(banner_t)

func _process(delta: float) -> void:
	t += delta
	if banner_t > 0.0:
		banner_t -= delta
	queue_redraw()

## Faixa cinematográfica de chefe / prestígio.
func _desenhar_banner(tam: Vector2) -> void:
	if banner_t <= 0.0 or banner_nome == "":
		return
	var dur := 3.4
	var k := clampf(banner_t / dur, 0.0, 1.0)
	var entrada := clampf((dur - banner_t) / 0.35, 0.0, 1.0)
	var saida := clampf(banner_t / 0.6, 0.0, 1.0)
	var alfa := minf(Ux.ease_out_cubic(entrada), saida)
	var largura := tam.x * Ux.ease_out_cubic(entrada)
	var y := tam.y * 0.26
	var h := 74.0
	draw_rect(Rect2(tam.x * 0.5 - largura * 0.5, y, largura, h), Color(0, 0, 0, 0.62 * alfa))
	draw_line(Vector2(tam.x * 0.5 - largura * 0.5, y), Vector2(tam.x * 0.5 + largura * 0.5, y),
		Color(banner_cor.r, banner_cor.g, banner_cor.b, 0.9 * alfa), 2.0)
	draw_line(Vector2(tam.x * 0.5 - largura * 0.5, y + h), Vector2(tam.x * 0.5 + largura * 0.5, y + h),
		Color(banner_cor.r, banner_cor.g, banner_cor.b, 0.9 * alfa), 2.0)
	var tn := 34
	var w1 := fonte.get_string_size(banner_nome, HORIZONTAL_ALIGNMENT_LEFT, -1, tn).x
	draw_string(fonte, Vector2(tam.x * 0.5 - w1 * 0.5, y + 40.0), banner_nome,
		HORIZONTAL_ALIGNMENT_LEFT, -1, tn, Color(1, 1, 1, alfa))
	if banner_sub != "":
		var ts := 14
		var w2 := fonte.get_string_size(banner_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
		draw_string(fonte, Vector2(tam.x * 0.5 - w2 * 0.5, y + 62.0), banner_sub,
			HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Color(banner_cor.r, banner_cor.g, banner_cor.b, alfa * 0.9))

func _draw() -> void:
	var tam := size
	if campo != null and bool(Cfg.get_v("flashes", true)):
		campo.juice.desenhar_flash(self, tam)
	if jogo == null or not jogo.iniciado:
		return
	# A opção se chama, literalmente, "Clarões e vinhetas de perigo" — mas só o
	# clarão do Juice a consultava. A vinheta pulsante de perigo cobria a tela
	# inteira e o banner de chefe/prestígio piscava por cima, os dois sem
	# perguntar nada a ninguém: desligar "Flashes" não desligava nem um nem
	# outro. Agora os três obedecem à mesma chave.
	var pode_piscar := bool(Cfg.get_v("flashes", true))
	if not pode_piscar:
		return
	_desenhar_banner(tam)
	# vinheta vermelha quando a torre está em perigo
	var torre: Dictionary = jogo.s["torre"]
	var frac := Big.frac(torre["vida"], torre["vida_max"])
	if frac < 0.35 and bool(torre["viva"]):
		# Com movimento reduzido a vinheta continua avisando do perigo, só que
		# parada: quem liga a opção não pode perder a informação junto com a
		# animação. Sem o seno, dois quadros seguidos saem idênticos.
		var pulso := sin(t * 5.0) * 0.08 if not bool(Cfg.get_v("movimento_reduzido", false)) else 0.0
		var forca := (1.0 - frac / 0.35) * (0.28 + pulso)
		var passos := 6
		for i in passos:
			var f := float(i) / float(passos)
			var margem := tam * 0.5 * f * 0.55
			draw_rect(Rect2(margem, tam - margem * 2.0), Color(0.8, 0.05, 0.1, forca * 0.16), false, tam.x * 0.06)
