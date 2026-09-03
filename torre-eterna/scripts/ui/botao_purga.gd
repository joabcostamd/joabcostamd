extends Button

## O botão da PURGA — a única ação que o jogo pede do jogador.
## Desenha a própria carga em anel e grita quando entra na janela perfeita.

var jogo: Node
var t := 0.0

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	custom_minimum_size = Vector2(72, 72)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# A porcentagem sai da constante, e não de um número escrito à mão: se a
	# janela mudar, a dica muda junto.
	var pct_janela := int(round(Mecanicas.PURGA_JANELA_PERFEITA * 100.0))
	tooltip_text = "%s  [%s]\n%s\n%s (%d%%+)\n%s\n%s" % [
		Txt.t("purga"), Txt.t("pur_atalho"), Txt.t("pur_acumula"),
		Txt.t("purga_dica"), pct_janela, Txt.t("pur_efeito"), Txt.t("pur_estourar"),
	]
	pressed.connect(func(): jogo.purgar())

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	if jogo == null or not jogo.iniciado:
		return
	var p: Dictionary = Mecanicas.estado_purga(jogo.s)
	var carga := clampf(float(p["carga"]), 0.0, 1.0)
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.40
	var na_janela := carga >= Mecanicas.PURGA_JANELA_PERFEITA
	var boa := carga >= Mecanicas.PURGA_JANELA_BOA

	var cor := UI.ACENTO
	if na_janela:
		cor = UI.OURO
	elif boa:
		cor = UI.VERDE

	draw_arc(c, r, 0, TAU, 40, Color(0.10, 0.14, 0.22, 0.9), 7.0, true)
	var a0 := -PI * 0.5 + TAU * Mecanicas.PURGA_JANELA_PERFEITA
	draw_arc(c, r, a0, -PI * 0.5 + TAU, 12, Color(UI.OURO.r, UI.OURO.g, UI.OURO.b, 0.45), 9.0, true)
	if carga > 0.001:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * carga, 40, cor, 6.0, true)

	var escala := 1.0
	if na_janela:
		escala = 1.0 + sin(t * 12.0) * 0.10
		draw_circle(c, r * 1.35, Color(UI.OURO.r, UI.OURO.g, UI.OURO.b, 0.16 + sin(t * 12.0) * 0.08))
	Icone.desenhar(self, "purga", c, r * 1.05 * escala, cor, cor.darkened(0.4))

	# A tecla, no mesmo canto em que as habilidades mostram 1–0. A Purga era a
	# única ação do rodapé sem atalho visível, apesar de ser a única que o jogo
	# pede de verdade.
	var fonte_t := ThemeDB.fallback_font
	draw_string(fonte_t, Vector2(6.0, 15.0), Txt.t("pur_tecla"),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(cor.r, cor.g, cor.b, 0.85))

	var pct := "%d%%" % int(carga * 100.0)
	var fonte := ThemeDB.fallback_font
	var w := fonte.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(fonte, c + Vector2(-w * 0.5, r + 12.0), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color(cor.r, cor.g, cor.b, 0.95))
