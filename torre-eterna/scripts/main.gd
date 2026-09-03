extends Node2D

## Raiz do jogo. Monta a árvore inteira em código (nenhum .tscn escrito à mão),
## conecta entrada, painéis e ciclo de vida.

var jogo: Node
var fundo: Node2D
var campo: Node2D
var flash: Control
var camada_ui: CanvasLayer
var hud: Control
var gerente: Node          # GerentePaineis

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	name = "Main"
	_montar()
	get_viewport().size_changed.connect(_ao_redimensionar)
	_ao_redimensionar()
	jogo.iniciar()
	_talvez_capturar()

## Captura de tela para verificação automatizada:
##   godot --path . -- --shot=5 --saida=/tmp/tela.png [--onda=40]
func _talvez_capturar() -> void:
	var args := OS.get_cmdline_user_args()
	var segundos := -1.0
	var saida := "user://captura.png"
	var onda := -1
	for a in args:
		if a.begins_with("--shot="):
			segundos = float(a.substr(7))
		elif a.begins_with("--saida="):
			saida = a.substr(8)
		elif a.begins_with("--onda="):
			onda = int(a.substr(7))
		elif a.begins_with("--painel="):
			_painel_alvo = a.substr(9)
	if segundos < 0.0:
		return
	if onda > 0:
		jogo.s["onda_maxima"] = onda
		jogo.s["onda_maxima_global"] = onda
		jogo.diretor.ir_para(onda)
		for i in 40:
			jogo.comprar_upgrade("dano", 12)
			jogo.comprar_upgrade("cadencia", 4)
			jogo.comprar_upgrade("vida", 8)
			jogo.ganhar_ouro(Big.mul_f(Bal.ouro_onda(onda), 400.0), "debug", true)
	_capturar_em(segundos, saida)

var _painel_alvo := ""

func _capturar_em(segundos: float, saida: String) -> void:
	await get_tree().create_timer(segundos).timeout
	if _painel_alvo != "":
		gerente.abrir(_painel_alvo)
		await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var caminho := saida if saida.begins_with("user://") or saida.begins_with("res://") else saida
	var err := img.save_png(caminho)
	print("===CAPTURA=== %s -> %s" % [caminho, "ok" if err == OK else str(err)])
	get_tree().quit()

func _montar() -> void:
	# --- mundo ---
	fundo = Node2D.new()
	fundo.name = "Fundo"
	fundo.set_script(load("res://scripts/render/view_fundo.gd"))
	add_child(fundo)

	campo = Node2D.new()
	campo.name = "Campo"
	campo.set_script(load("res://scripts/render/view_campo.gd"))
	add_child(campo)

	# --- interface ---
	camada_ui = CanvasLayer.new()
	camada_ui.name = "UI"
	camada_ui.layer = 10
	add_child(camada_ui)

	flash = Control.new()
	flash.name = "Flash"
	flash.set_script(load("res://scripts/render/view_flash.gd"))
	camada_ui.add_child(flash)
	flash.campo = campo

	var raiz_ui := Control.new()
	raiz_ui.name = "RaizUI"
	raiz_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz_ui.theme = UI.tema()
	camada_ui.add_child(raiz_ui)

	hud = Control.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/ui/hud.gd"))
	raiz_ui.add_child(hud)

	gerente = Node.new()
	gerente.name = "Paineis"
	gerente.set_script(load("res://scripts/ui/panel_manager.gd"))
	raiz_ui.add_child(gerente)
	gerente.raiz = raiz_ui
	hud.painel_pedido.connect(func(nome): gerente.alternar(nome))

func _ao_redimensionar() -> void:
	var tam := get_viewport_rect().size
	jogo.arena.redimensionar(tam.x, tam.y)
	if fundo:
		fundo.preparar(tam)

func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed or evento.echo:
		return
	for i in range(0, 10):
		var acao := "hab_%d" % i
		if InputMap.has_action(acao) and evento.is_action_pressed(acao):
			_usar_hab_por_tecla(str(i))
			get_viewport().set_input_as_handled()
			return
	if evento.is_action_pressed("ui_pausa"):
		gerente.fechar_ou_pausar()
	elif evento.is_action_pressed("painel_upgrades"):
		gerente.alternar("upgrades")
	elif evento.is_action_pressed("painel_talentos"):
		gerente.alternar("talentos")
	elif evento.is_action_pressed("painel_cartas"):
		gerente.alternar("cartas")
	elif evento.is_action_pressed("painel_prestigio"):
		gerente.alternar("prestigio")
	elif evento.is_action_pressed("painel_conquistas"):
		gerente.alternar("conquistas")
	elif evento.is_action_pressed("painel_config"):
		gerente.alternar("config")
	elif evento.is_action_pressed("salvar_agora"):
		jogo.salvar()
		Bus.toast("Jogo salvo", "bom", "💾")
	elif evento.is_action_pressed("tela_cheia"):
		Cfg.set_v("tela_cheia", not bool(Cfg.get_v("tela_cheia", false)))
	elif evento.is_action_pressed("debug_toggle"):
		Cfg.set_v("mostrar_fps", not bool(Cfg.get_v("mostrar_fps", false)))
	elif evento.is_action_pressed("turbo"):
		hud._alternar_velocidade()

func _usar_hab_por_tecla(tecla: String) -> void:
	for def in Dados.habilidades:
		if str(def.get("tecla", "")) == tecla:
			jogo.usar_habilidade(str(def.get("id", "")))
			return

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if jogo and jogo.iniciado:
			jogo.salvar()
		get_tree().quit()
