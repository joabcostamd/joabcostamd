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
	if not _modo_captura():
		_mostrar_titulo()
	_talvez_capturar()

func _modo_captura() -> bool:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--shot="):
			return true
	return false

## ------------------------------------------------------------- telas

func _mostrar_titulo() -> void:
	jogo.pausado = true
	var tela := Control.new()
	tela.name = "Titulo"
	tela.theme = UI.tema()
	tela.set_script(load("res://scripts/ui/tela_titulo.gd"))
	camada_ui.add_child(tela)
	tela.jogar.connect(func():
		tela.queue_free()
		jogo.pausado = false)
	tela.apagar_e_jogar.connect(func():
		jogo.apagar_tudo()
		tela.queue_free()
		jogo.pausado = false)

func alternar_pausa() -> void:
	var atual := camada_ui.get_node_or_null("Pausa")
	if atual != null:
		atual.queue_free()
		jogo.pausado = false
		return
	if gerente.atual != "":
		gerente.fechar()
		return
	jogo.pausado = true
	var tela := Control.new()
	tela.name = "Pausa"
	tela.theme = UI.tema()
	tela.set_script(load("res://scripts/ui/tela_pausa.gd"))
	camada_ui.add_child(tela)
	tela.retomar.connect(func():
		tela.queue_free()
		jogo.pausado = false)
	tela.abrir_painel.connect(func(nome):
		tela.queue_free()
		jogo.pausado = false
		gerente.abrir(nome))

func _ao_prestigio(camada: String, _ganho: float) -> void:
	if camada != "transcendencia":
		return
	if bool(jogo.s.get("viu_final", false)):
		return
	jogo.s["viu_final"] = true
	var tela := Control.new()
	tela.name = "Final"
	tela.theme = UI.tema()
	tela.set_script(load("res://scripts/ui/tela_final.gd"))
	camada_ui.add_child(tela)

## Captura de tela para verificação automatizada:
##   godot --path . -- --shot=5 --saida=/tmp/tela.png [--onda=40]
## `--abrir=desafios,modoFarm` liga desbloqueios para fotografar painéis trancados.
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
		elif a.begins_with("--tela="):
			_tela_alvo = a.substr(7)
		elif a.begins_with("--cartas="):
			_cartas_debug = int(a.substr(9))
		elif a.begins_with("--abrir="):
			_abrir_debug = a.substr(8)
		elif a.begins_with("--clicar="):
			_clicar_debug = a.substr(9)
		elif a.begins_with("--celebrar="):
			_celebrar_debug = a.substr(11)
		elif a == "--en":
			Cfg.set_v("idioma", "en")
		elif a == "--pt":
			# O par de `--en`. Sem ele, conferir o layout em portugues dependia
			# do idioma que a maquina da captura estivesse configurada — e as
			# frases em portugues sao mais longas que as inglesas, que e
			# exatamente o caso que estoura caixa.
			Cfg.set_v("idioma", "pt")
		elif a.begins_with("--daltonismo="):
			Cfg.set_v("daltonismo", int(a.substr(13)))
		elif a == "--contraste":
			Cfg.set_v("alto_contraste", true)
		elif a == "--codex":
			_codex_debug = true
		elif a.begins_with("--escala="):
			Cfg.set_v("escala_ui", float(a.substr(9)))
		elif a == "--fonte-grande":
			Cfg.set_v("fonte_grande", true)
	if segundos < 0.0:
		return
	if _abrir_debug != "":
		for chave in _abrir_debug.split(",", false):
			jogo.s["desbloqueios"][str(chave).strip_edges()] = true
		jogo.marcar_sujo()
		jogo.recalcular()
		Bus.ui_atualizar.emit(true)
	if _cartas_debug > 0:
		for i in _cartas_debug:
			Saque.criar_carta(jogo, "", i % 3 == 0)
		Bus.ui_atualizar.emit(true)
	if _codex_debug:
		for e in Dados.inimigos:
			jogo.s["codex"]["inimigos"][str(e["id"])] = 9
		for b in Dados.chefes + Dados.super_chefes:
			jogo.s["codex"]["chefes"][str(b["id"])] = 3
		Bus.ui_atualizar.emit(true)
	if onda > 0:
		jogo.s["onda_maxima"] = onda
		jogo.s["onda_maxima_global"] = onda
		jogo.diretor.ir_para(onda)
		for i in 40:
			jogo.comprar_upgrade("dano", 12)
			jogo.comprar_upgrade("cadencia", 4)
			jogo.comprar_upgrade("vida", 8)
			jogo.ganhar_ouro(Big.mul_f(Bal.ouro_onda(onda), 400.0), "debug", true)
	# DEPOIS do salto de onda, senao `ir_para()` sorteia um evento e o dialogo
	# cobre justamente o que a captura veio provar.
	if _celebrar_debug != "":
		jogo.s["eventos"]["proximo_em"] = 9999.0
		jogo.s["eventos"]["ativo"] = ""
		# A era e a camada de prestigio trazem o proprio nome, cor e texto: sem
		# eles a comemoracao sai em branco e a captura nao prova nada.
		var dados_cel := {"mortos": 47, "nivel": 3, "alvo": 210, "onda": 211}
		if _celebrar_debug == "era":
			dados_cel["era"] = Dados.era_atual(120)
		elif _celebrar_debug == "prestigio":
			dados_cel["camada"] = "ascensao"
			dados_cel["ganho"] = Big.from(2917.0)
			for c in Dados.camadas_prestigio:
				if str((c as Dictionary).get("id", "")) == "ascensao":
					dados_cel["def"] = c
					break
		Bus.celebracao.emit(_celebrar_debug, dados_cel)
	_capturar_em(segundos, saida)

var _painel_alvo := ""
var _tela_alvo := ""
var _cartas_debug := 0
var _abrir_debug := ""
var _clicar_debug := ""
var _celebrar_debug := ""
var _codex_debug := false

func _capturar_em(segundos: float, saida: String) -> void:
	await get_tree().create_timer(segundos).timeout
	if _tela_alvo != "":
		match _tela_alvo:
			"titulo": _mostrar_titulo()
			"pausa": alternar_pausa()
			"final":
				jogo.s["prestigio"]["transcendencias"] = 3
				jogo.s["peregrinos_poupados"] = 4
				jogo.s["peregrinos_mortos"] = 1
				jogo.s["viu_final"] = false
				_ao_prestigio("transcendencia", 0.0)
		await get_tree().create_timer(segundos * 0.9).timeout
	if _painel_alvo != "":
		gerente.abrir(_painel_alvo)
		await get_tree().create_timer(0.6).timeout
	# `--clicar=Aba1>Aba2` aciona abas e botões pelo TEXTO, um por vez: é assim
	# que a captura chega no que só existe depois de um clique, sem mouse.
	if _clicar_debug != "":
		for alvo in _clicar_debug.split(">", false):
			var achou := _acionar(camada_ui, str(alvo).strip_edges())
			print("===CLIQUE=== %s -> %s" % [str(alvo), "ok" if achou else "NAO ACHEI"])
			await get_tree().create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var caminho := saida if saida.begins_with("user://") or saida.begins_with("res://") else saida
	var err := img.save_png(caminho)
	print("===CAPTURA=== %s -> %s" % [caminho, "ok" if err == OK else str(err)])
	get_tree().quit()

## Aciona o primeiro alvo visível cujo texto bate: aba de TabBar ou Button.
## Só serve à captura automatizada (`--clicar=`).
func _acionar(no: Node, texto: String) -> bool:
	if no is TabBar and no.visible:
		for i in no.tab_count:
			if no.get_tab_title(i).strip_edges() == texto:
				no.current_tab = i
				no.tab_changed.emit(i)
				return true
	if no is Button and no.visible and str(no.text).strip_edges() == texto:
		no.pressed.emit()
		return true
	for f in no.get_children():
		if _acionar(f, texto):
			return true
	return false

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

	# --- comemorações: `Bus.celebracao` era emitido e ninguém escutava ---
	var celebra := Control.new()
	celebra.set_script(load("res://scripts/ui/celebracao.gd"))
	camada_ui.add_child(celebra)
	celebra.gerente = gerente

	# --- tutorial: balões que aparecem na hora certa e somem sozinhos ---
	var tutorial := Control.new()
	tutorial.name = "Tutorial"
	tutorial.theme = UI.tema()
	tutorial.set_script(load("res://scripts/ui/tutorial.gd"))
	camada_ui.add_child(tutorial)
	tutorial.hud = hud
	tutorial.gerente = gerente

	Bus.prestigio_feito.connect(_ao_prestigio)

func _ao_redimensionar() -> void:
	var tam := get_viewport_rect().size
	jogo.arena.redimensionar(tam.x, tam.y)
	if fundo:
		fundo.preparar(tam)

## Existe uma tela modal na frente? Título, Pausa, Fim de jogo ou diálogo de
## evento. Enquanto houver, o teclado do jogo fica calado.
func _tela_modal() -> bool:
	for nome in ["Titulo", "Pausa", "Final"]:
		if camada_ui != null and camada_ui.get_node_or_null(nome) != null:
			return true
	return gerente != null and gerente.dialogo != null and is_instance_valid(gerente.dialogo)

func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed or evento.echo:
		return
	# Com a tela de Título ou de Fim de jogo aberta, apertar Q abria o painel de
	# Melhorias ATRÁS dela e 1–0 disparava habilidades numa partida que o
	# jogador nem começou. Só o Esc continua passando, para poder sair.
	if _tela_modal() and not evento.is_action_pressed("ui_pausa"):
		return
	for i in range(0, 10):
		var acao := "hab_%d" % i
		if InputMap.has_action(acao) and evento.is_action_pressed(acao):
			_usar_hab_por_tecla(str(i))
			get_viewport().set_input_as_handled()
			return
	if evento.is_action_pressed("ui_pausa"):
		alternar_pausa()
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
		hud._salvar_agora()
	elif evento.is_action_pressed("tela_cheia"):
		Cfg.set_v("tela_cheia", not bool(Cfg.get_v("tela_cheia", false)))
	elif evento.is_action_pressed("debug_toggle"):
		Cfg.set_v("mostrar_fps", not bool(Cfg.get_v("mostrar_fps", false)))
	elif evento.is_action_pressed("turbo"):
		hud._alternar_velocidade()
	# O painel de Configurações listava P e A como atalhos e nenhum dos dois
	# existia: a tecla não fazia nada e a lista mentia para o jogador.
	elif evento.is_action_pressed("purga"):
		if not Mecanicas.disparar_purga(jogo):
			Bus.toast(Txt.t("purga_sem_carga"), "info", "nova")
	elif evento.is_action_pressed("alternar_auto"):
		if jogo.esp["desbloqueios"].has("autoCompra"):
			var ligado := not bool(jogo.s["auto"]["comprar"])
			jogo.s["auto"]["comprar"] = ligado
			jogo.marcar_sujo()
			Bus.ui_atualizar.emit(false)
			Bus.toast(Txt.t("auto_compra_ligada" if ligado else "auto_compra_desligada"), "info", "engrenagem")
		else:
			Bus.toast(Txt.t("auto_compra_trancada"), "info", "cadeado")

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
