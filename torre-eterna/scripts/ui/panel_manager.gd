extends Node

## Gerente de painéis: abre/fecha janelas, cuida do fundo escurecido,
## das notificações (toasts) e da tela de pausa.

var raiz: Control
var atual := ""
var painel_atual: Control
var fundo_escuro: ColorRect
var caixa_toast: VBoxContainer
var dialogo: Control          # janela de evento (vive fora do ciclo dos painéis)
var jogo: Node

const PAINEIS := {
	"upgrades": "res://scripts/ui/panel_upgrades.gd",
	"talentos": "res://scripts/ui/panel_talentos.gd",
	"cartas": "res://scripts/ui/panel_cartas.gd",
	"prestigio": "res://scripts/ui/panel_prestigio.gd",
	"conquistas": "res://scripts/ui/panel_conquistas.gd",
	"config": "res://scripts/ui/panel_config.gd",
	"codex": "res://scripts/ui/panel_codex.gd",
	"stats": "res://scripts/ui/panel_stats.gd",
	"missoes": "res://scripts/ui/panel_missoes.gd",
	"reliquias": "res://scripts/ui/panel_reliquias.gd",
	"desafios": "res://scripts/ui/panel_desafios.gd",
	"habilidades": "res://scripts/ui/panel_habilidades.gd",
}

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	await get_tree().process_frame
	_montar_overlay()
	Bus.aviso.connect(_toast)
	Bus.relatorio_offline.connect(_relatorio_offline)
	Bus.evento_sorteado.connect(abrir_evento)
	# fechou o jogo com um evento na tela? ele continua esperando resposta.
	if jogo != null:
		var pendente := Eventos.pendente(jogo.s)
		if not pendente.is_empty():
			abrir_evento(pendente)

func _montar_overlay() -> void:
	fundo_escuro = ColorRect.new()
	fundo_escuro.color = Color(0, 0, 0, 0.62)
	fundo_escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo_escuro.visible = false
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo_escuro.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			fechar())
	raiz.add_child(fundo_escuro)

	caixa_toast = VBoxContainer.new()
	caixa_toast.anchor_left = 0.5
	caixa_toast.anchor_right = 0.5
	caixa_toast.anchor_top = 0.0
	caixa_toast.anchor_bottom = 0.0
	caixa_toast.offset_left = -220
	caixa_toast.offset_right = 220
	caixa_toast.offset_top = 96
	caixa_toast.offset_bottom = 300
	caixa_toast.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa_toast.add_theme_constant_override("separation", 6)
	raiz.add_child(caixa_toast)

func alternar(nome: String) -> void:
	if atual == nome:
		fechar()
	else:
		abrir(nome)

func abrir(nome: String) -> void:
	# atalho de captura/depuração: --painel=evento abre a janela de evento
	if nome == "evento":
		abrir_evento(Eventos.sortear(jogo))
		return
	if not PAINEIS.has(nome):
		return
	fechar()
	var caminho := str(PAINEIS[nome])
	if not ResourceLoader.exists(caminho):
		Bus.toast("Painel em construção: " + nome, "info", "🚧")
		return
	var script := load(caminho)
	if script == null:
		return
	painel_atual = Control.new()
	painel_atual.set_script(script)
	painel_atual.set_meta("gerente", self)
	painel_atual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(painel_atual)
	fundo_escuro.visible = true
	fundo_escuro.move_to_front()
	painel_atual.move_to_front()
	caixa_toast.move_to_front()
	atual = nome
	Bus.painel_aberto.emit(nome)

func fechar() -> void:
	if painel_atual and is_instance_valid(painel_atual):
		painel_atual.queue_free()
	painel_atual = null
	atual = ""
	if fundo_escuro:
		fundo_escuro.visible = false

func fechar_ou_pausar() -> void:
	if atual != "":
		fechar()
	else:
		abrir("config")

## ------------------------------------------------------- janela de evento

## O jogo NÃO pausa: a janela sobe por cima e a torre continua trabalhando.
func abrir_evento(def: Dictionary) -> void:
	if def.is_empty():
		return
	if dialogo != null and is_instance_valid(dialogo):
		return
	var script := load("res://scripts/ui/dialogo_evento.gd")
	if script == null:
		return
	dialogo = Control.new()
	dialogo.name = "DialogoEvento"
	dialogo.set_script(script)
	dialogo.evento = def
	raiz.add_child(dialogo)
	dialogo.move_to_front()
	caixa_toast.move_to_front()

## ------------------------------------------------------------- toasts

func _toast(texto: String, tipo: String, icone: String) -> void:
	if caixa_toast == null:
		return
	var cor := UI.ACENTO
	match tipo:
		"bom": cor = UI.VERDE
		"ruim": cor = UI.VERMELHO
		"epico": cor = UI.OURO
	var cx := UI.painel(UI.PAINEL.darkened(0.1), 10)
	cx.modulate = Color(1, 1, 1, 0)
	cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(8)
	if icone != "":
		h.add_child(UI.rotulo(icone, 17))
	h.add_child(UI.rotulo(texto, 15, cor))
	cx.add_child(h)
	caixa_toast.add_child(cx)
	var tw := cx.create_tween()
	tw.tween_property(cx, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.4)
	tw.tween_property(cx, "modulate:a", 0.0, 0.4)
	tw.tween_callback(cx.queue_free)
	while caixa_toast.get_child_count() > 5:
		caixa_toast.get_child(0).queue_free()
		break

## ------------------------------------------------- relatório offline

func _relatorio_offline(dados: Dictionary) -> void:
	if not bool(dados.get("aplicado", false)):
		return
	var janela := UI.painel(UI.PAINEL, 16)
	janela.anchor_left = 0.5
	janela.anchor_right = 0.5
	janela.anchor_top = 0.5
	janela.anchor_bottom = 0.5
	janela.offset_left = -250
	janela.offset_right = 250
	janela.offset_top = -200
	janela.offset_bottom = 200
	var v := UI.vbox(10)
	v.add_child(UI.titulo("A torre continuou lutando", 21))
	v.add_child(UI.separador())
	v.add_child(UI.rotulo("Você ficou fora por %s." % Ux.tempo_curto(float(dados["segundos"])), 15, UI.TEXTO2))
	if float(dados.get("cortado", 0.0)) > 1.0:
		v.add_child(UI.rotulo("Limite de acúmulo: %s (o resto se perdeu)." % Ux.tempo_curto(float(dados["usado"])), 13, UI.TEXTO3))
	v.add_child(UI.rotulo("Eficiência offline: %s" % Fmt.pct(float(dados["eficiencia"])), 13, UI.TEXTO3))
	v.add_child(UI.separador())
	v.add_child(_linha_ganho("ouro", UI.OURO, "+" + Fmt.big(dados["ouro"]), 22))
	v.add_child(_linha_ganho("livro", UI.ACENTO2, "+" + Fmt.big(dados["xp"]) + " XP", 18))

	# --- Caixa da Vigília: o saque offline chega LACRADO ---
	var seladas := int(dados.get("seladas", 0))
	if seladas > 0:
		v.add_child(UI.separador())
		v.add_child(UI.rotulo("CAIXA DA VIGÍLIA", 13, UI.TEXTO3))
		var lbl := UI.rotulo("%d carta(s) lacrada(s) enquanto você dormia." % seladas, 14, UI.TEXTO2)
		v.add_child(lbl)
		var b_abrir := UI.botao("Abrir uma carta", Callable())
		b_abrir.custom_minimum_size.y = 40
		b_abrir.pressed.connect(func():
			var carta: Dictionary = Mecanicas.abrir_caixa(jogo)
			if carta.is_empty():
				b_abrir.disabled = true
				lbl.text = "A caixa está vazia."
				return
			var def: Dictionary = Dados.carta_por_id.get(str(carta.get("id", "")), {})
			var rar := str(carta.get("raridade", "comum"))
			lbl.text = "%s  ·  %s" % [Ux.txt(def, "nome", Cfg.ingles()), str(Dados.raridade(rar).get("nome", rar))]
			lbl.add_theme_color_override("font_color", UI.cor_raridade(rar))
			UI.saltar(lbl, 1.25)
			var restam := int(jogo.s["caixa"]["seladas"])
			b_abrir.text = "Abrir uma carta (%d)" % restam if restam > 0 else "Caixa vazia"
			b_abrir.disabled = restam <= 0)
		b_abrir.text = "Abrir uma carta (%d)" % seladas
		v.add_child(b_abrir)

	v.add_child(UI.espacador(0, false))
	var b := UI.botao("Continuar", func(): janela.queue_free(); fundo_escuro.visible = false)
	b.custom_minimum_size.y = 42
	v.add_child(b)
	janela.add_child(v)
	raiz.add_child(janela)
	fundo_escuro.visible = true
	janela.move_to_front()
	UI.saltar(janela, 1.06)

## Linha "ícone + valor" sem emoji (a fonte padrão não tem glifo).
func _linha_ganho(icone: String, cor: Color, texto: String, tamanho: int) -> HBoxContainer:
	var h := UI.hbox(8)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(icone, cor, float(tamanho))
	h.add_child(UI.rotulo(texto, tamanho, cor))
	return h
