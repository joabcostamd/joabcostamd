extends Control

## O Fim Verdadeiro. Aparece uma vez, quando a torre entende o que ela é.
## Não é game over: o jogo continua depois. É o pagamento da história.

var t := 0.0
var fonte: Font
var jogo: Node
var linhas: Array = []

## O que a tela esconde enquanto estiver na frente, para devolver depois.
var _escondidos: Array[Node] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# O fim do jogo desenhava POR CIMA do HUD vivo e do balão de tutorial: o
	# epílogo aparecia atravessado por barra de vida, contador de ouro e botões
	# de painel. É o último texto do jogo, e era o mais bagunçado. Agora ele vai
	# para a frente de tudo e apaga o resto da interface enquanto durar — e
	# devolve na saída, porque o jogo continua depois dele.
	move_to_front()
	var raiz := get_parent()
	if raiz != null:
		for irmao in raiz.get_children():
			if irmao == self or not (irmao is CanvasItem):
				continue
			if (irmao as CanvasItem).visible:
				(irmao as CanvasItem).visible = false
				_escondidos.append(irmao)
	tree_exiting.connect(func():
		for n in _escondidos:
			if is_instance_valid(n):
				(n as CanvasItem).visible = true)
	fonte = ThemeDB.fallback_font
	jogo = get_node_or_null("/root/Jogo")
	var poupados := int(jogo.s.get("peregrinos_poupados", 0))
	var mortos := int(jogo.s.get("peregrinos_mortos", 0))
	linhas = [
		Txt.f("fim_reinicios", {"n": int(jogo.s["prestigio"]["transcendencias"])}),
		Txt.t("fim_ficou_para_tras"),
		Txt.t("fim_enxame"),
		Txt.t("fim_versoes"),
		"",
		Txt.f("fim_peregrinos", {"a": poupados, "b": mortos}),
		_veredito(poupados, mortos),
		"",
		Txt.t("fim_continua"),
	]
	var b := UI.botao(Txt.t("fim_continuar_existindo"), func(): queue_free())
	b.anchor_left = 0.5
	b.anchor_right = 0.5
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = -120
	b.offset_right = 120
	b.offset_top = -86
	b.offset_bottom = -44
	add_child(b)
	b.modulate.a = 0.0
	var tw := b.create_tween()
	tw.tween_interval(float(linhas.size()) * 1.1 + 1.0)
	tw.tween_property(b, "modulate:a", 1.0, 0.8)

func _veredito(poupados: int, mortos: int) -> String:
	if poupados == 0 and mortos == 0:
		return Txt.t("fim_veredito_nenhum")
	if poupados > mortos * 2:
		return Txt.t("fim_veredito_poupou")
	if mortos > poupados * 2:
		return Txt.t("fim_veredito_matou")
	return Txt.t("fim_veredito_hesitou")

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var tam := size
	draw_rect(Rect2(Vector2.ZERO, tam), Color(0.01, 0.01, 0.03, minf(0.94, t * 0.6)))
	# estratigrafia: uma faixa por transcendência, sedimentada no fundo
	var camadas := int(jogo.s["prestigio"]["transcendencias"])
	for i in camadas:
		var h := 14.0
		var y := tam.y - float(i + 1) * h
		var cor := Color.from_hsv(fmod(0.58 + float(i) * 0.07, 1.0), 0.5, 0.35)
		draw_rect(Rect2(0, y, tam.x, h), Color(cor.r, cor.g, cor.b, 0.35 * minf(1.0, t * 0.4)))
	var y0 := tam.y * 0.26
	for i in linhas.size():
		var atraso := float(i) * 1.1
		var k := clampf((t - atraso) / 1.4, 0.0, 1.0)
		if k <= 0.0:
			break
		var linha := str(linhas[i])
		if linha == "":
			continue
		var tf := 22 if i < 4 else 16
		var w := fonte.get_string_size(linha, HORIZONTAL_ALIGNMENT_LEFT, -1, tf).x
		draw_string(fonte, Vector2(tam.x * 0.5 - w * 0.5, y0 + float(i) * 34.0), linha,
			HORIZONTAL_ALIGNMENT_LEFT, -1, tf, Color(1, 1, 1, k * (1.0 if i < 4 else 0.85)))
