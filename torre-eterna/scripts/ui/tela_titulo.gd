extends Control

## Tela de título. A torre se monta sozinha enquanto você decide.
## Tudo desenhado — o "logo" é geometria, não imagem.

signal jogar()
signal apagar_e_jogar()

var t := 0.0
var fonte: Font
var dica := ""
var tem_save := false
var _pediu_apagar := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	fonte = ThemeDB.fallback_font
	tem_save = SaveSys.existe_save()
	dica = Mecanicas.dica_aleatoria(randi())
	_montar()

func _montar() -> void:
	var v := UI.vbox(10)
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.anchor_top = 0.5
	v.anchor_bottom = 0.5
	v.offset_left = -170
	v.offset_right = 170
	v.offset_top = 60
	v.offset_bottom = 250
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(v)

	var b1 := UI.botao(Txt.t("tit_continuar") if tem_save else Txt.t("tit_comecar"), func(): jogar.emit())
	b1.custom_minimum_size = Vector2(300, 54)
	b1.add_theme_font_size_override("font_size", 19)
	v.add_child(b1)

	if tem_save:
		var b2 := UI.botao(Txt.t("tit_recomecar"), _confirmar_apagar)
		b2.custom_minimum_size = Vector2(300, 40)
		b2.add_theme_color_override("font_color", UI.TEXTO2)
		v.add_child(b2)

	var rodape := UI.vbox(2)
	rodape.anchor_top = 1.0
	rodape.anchor_bottom = 1.0
	rodape.anchor_left = 0.0
	rodape.anchor_right = 1.0
	rodape.offset_top = -74
	rodape.offset_bottom = -14
	rodape.offset_left = 20
	rodape.offset_right = -20
	rodape.alignment = BoxContainer.ALIGNMENT_END
	add_child(rodape)
	if dica != "":
		var ld := UI.rotulo(dica, 13, UI.TEXTO3)
		ld.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ld.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rodape.add_child(ld)
	# O NOME SAI DA MARCA, NAO DA TRADUCAO. Este rodape ja teve o nome do jogo
	# escrito dentro da frase traduzida — e a frase estava traduzida em 20
	# idiomas, entao o nome antigo continuou aparecendo em 20 telas depois da
	# troca. Nome dentro de texto traduzido e o nome multiplicado por 20.
	var lv := UI.rotulo("%s · %s" % [Marca.nome(), Txt.t("tit_rodape")], 11,
		UI.TEXTO3.darkened(0.2))
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.add_child(lv)

func _confirmar_apagar() -> void:
	if not _pediu_apagar:
		_pediu_apagar = true
		Bus.toast(Txt.t("tit_apagar_confirma"), "ruim")
		get_tree().create_timer(4.0).timeout.connect(func(): _pediu_apagar = false)
		return
	apagar_e_jogar.emit()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var tam := size
	var c := Vector2(tam.x * 0.5, tam.y * 0.34)

	draw_rect(Rect2(Vector2.ZERO, tam), UI.FUNDO)
	for i in 90:
		var x := fmod(float(i) * 137.5, tam.x)
		var y := fmod(float(i) * 311.7 + t * (4.0 + float(i % 5)), tam.y)
		var b := 0.25 + 0.55 * absf(sin(t * 0.7 + float(i)))
		draw_circle(Vector2(x, y), 1.0 + b, Color(0.55, 0.72, 1.0, b * 0.35))

	# a torre se monta: cada anel entra em sequência
	for i in 5:
		var atraso := float(i) * 0.28
		var k := clampf((t - atraso) / 0.9, 0.0, 1.0)
		if k <= 0.0:
			continue
		var e := Ux.ease_out_back(k)
		var raio := (46.0 + float(i) * 26.0) * e
		var vel := (0.4 + float(i) * 0.22) * (1.0 if i % 2 == 0 else -1.0)
		var cor := Color("#38bdf8").lerp(Color("#f472b6"), float(i) / 4.0)
		draw_arc(c, raio, t * vel, t * vel + PI * (1.35 - float(i) * 0.1), 40,
			Color(cor.r, cor.g, cor.b, 0.55 * k), 3.0 - float(i) * 0.25, true)

	var kc := clampf(t / 0.7, 0.0, 1.0)
	if kc > 0.0:
		var rr := 30.0 * Ux.ease_out_back(kc)
		var pts := PackedVector2Array()
		for i in 8:
			var a := float(i) / 8.0 * TAU + t * 0.15
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, Color("#1b2742"))
		draw_circle(c, rr * 0.5 * (1.0 + sin(t * 2.2) * 0.09), Color("#7dd3fc"))
		draw_circle(c, rr * 0.24, Color(1, 1, 1, 0.92))

	var kt := clampf((t - 1.0) / 0.8, 0.0, 1.0)
	if kt > 0.0:
		# O NOME VEM DE `data/marca.json`, NUNCA DAQUI. Esta linha ja foi um
		# literal, e o literal sobreviveu a uma troca de nome sem ninguem notar:
		# o teste so proibia escrever o nome ATUAL a mao, entao o nome ANTIGO
		# continuou desenhado na tela de titulo, calado.
		var titulo := Marca.nome()
		var tam_f := 54
		var w := fonte.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_f).x
		var y := c.y + 126.0 - (1.0 - Ux.ease_out_cubic(kt)) * 16.0
		draw_string(fonte, Vector2(c.x - w * 0.5, y), titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_f,
			Color(1, 1, 1, kt))
		var sub := Txt.t("tit_subtitulo")
		var ws := fonte.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(fonte, Vector2(c.x - ws * 0.5, y + 26.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(UI.TEXTO2.r, UI.TEXTO2.g, UI.TEXTO2.b, kt * 0.9))
