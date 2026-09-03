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
	# As conexões vêm ANTES do await de propósito: `Jogo.iniciar()` roda no mesmo
	# quadro em que este nó nasce e emite `relatorio_offline` na hora, então
	# conectar depois do await perdia o sinal e quem voltava de horas fora não
	# via relatório nenhum. Só que a interface do overlay ainda NÃO EXISTE nessa
	# hora (ela precisa de `raiz`, que main.gd atribui depois do add_child), e
	# desenhar em cima dela dava erro em execução. Por isso a fila: o sinal é
	# guardado agora e desenhado assim que houver onde desenhar.
	Bus.aviso.connect(_toast)
	Bus.relatorio_offline.connect(_relatorio_offline)
	Bus.evento_sorteado.connect(abrir_evento)
	# Trocar o idioma com um painel aberto deixava título, abas e botões na
	# língua velha — eles nascem em `montar()` e ninguém os reconstruía. Reabrir
	# resolve, e tem que ser DIFERIDO: o pedido vem de dentro do callback do
	# próprio seletor, que seria liberado no meio da própria execução.
	# Mudar a escala da interface ou a fonte grande muda o tamanho da tela
	# LÓGICA, e é dele que sai toda a largura calculada em `panel_base`. Sem
	# reconstruir, o painel aberto continuava com a largura da escala anterior:
	# acima de 1,05 o conteúdo saía pela direita e levava junto o botão de
	# fechar. Mesmo tratamento que o idioma já tinha, e pela mesma razão.
	Bus.config_mudou.connect(func(chave, _v):
		var c := str(chave)
		if (c == "idioma" or c == "escala_ui" or c == "fonte_grande") and atual != "":
			_reabrir.call_deferred(atual))
	await get_tree().process_frame
	_montar_overlay()
	_escoar_fila_inicial()
	# Cinto e suspensório: se nem pela fila veio, o Jogo guarda o relatório.
	if jogo != null and not _offline_mostrado:
		var guardado: Dictionary = jogo.relatorio_offline
		if not guardado.is_empty() and bool(guardado.get("aplicado", false)):
			_relatorio_offline(guardado)
	# fechou o jogo com um evento na tela? ele continua esperando resposta.
	if jogo != null:
		var pendente := Eventos.pendente(jogo.s)
		if not pendente.is_empty():
			abrir_evento(pendente)

## O relatório aparece uma vez por abertura de jogo, venha pelo sinal, pela fila
## ou do estado guardado no Jogo.
var _offline_mostrado := false

## Sinais que chegaram antes de existir onde desenhar.
var _fila_inicial: Array = []

func _pronto_para_desenhar() -> bool:
	return raiz != null and fundo_escuro != null and caixa_toast != null

func _escoar_fila_inicial() -> void:
	var fila := _fila_inicial.duplicate()
	_fila_inicial.clear()
	for item in fila:
		var e: Array = item
		match str(e[0]):
			"toast": _toast(str(e[1]), str(e[2]), str(e[3]))
			"offline": _relatorio_offline(e[1])

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
	caixa_toast.offset_left = -220
	caixa_toast.offset_right = 220
	caixa_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa_toast.add_theme_constant_override("separation", 6)
	raiz.add_child(caixa_toast)
	_posicionar_toasts()

## Os avisos fogem do painel aberto.
##
## Eles ficavam fixos a 96px do topo — exatamente onde o painel desenha a
## primeira linha de conteúdo. Com um painel aberto, o aviso caía em cima de um
## card e escondia justamente o que o jogador tinha ido ler. Com o painel
## fechado essa posição é a melhor que existe; com painel aberto, a única faixa
## que sobra é o rodapé. Então a caixa se muda.
## Quantos avisos cabem sem atrapalhar. Com painel aberto, dois.
func _teto_toasts() -> int:
	return 2 if atual != "" else 5

func _posicionar_toasts() -> void:
	if caixa_toast == null:
		return
	var aberto := atual != ""
	caixa_toast.anchor_top = 1.0 if aberto else 0.0
	caixa_toast.anchor_bottom = 1.0 if aberto else 0.0
	# No rodapé a caixa cresce PARA CIMA (senão os últimos avisos saem da tela) e
	# fica curta de propósito: com o painel aberto só cabem DOIS avisos antes de
	# começar a cobrir conteúdo, então o teto cai de cinco para dois enquanto o
	# painel estiver na frente.
	caixa_toast.offset_top = -110.0 if aberto else 96.0
	caixa_toast.offset_bottom = -10.0 if aberto else 300.0
	caixa_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN if aberto else Control.GROW_DIRECTION_END
	caixa_toast.alignment = BoxContainer.ALIGNMENT_END if aberto else BoxContainer.ALIGNMENT_CENTER
	# Abrir um painel também precisa aparar o que já estava na tela: avisos
	# criados antes da abertura ficavam lá, cinco deles, cobrindo o conteúdo.
	_aparar_toasts()

func _aparar_toasts() -> void:
	while caixa_toast != null and caixa_toast.get_child_count() > _teto_toasts():
		var velho := caixa_toast.get_child(0)
		caixa_toast.remove_child(velho)
		velho.queue_free()

## Fecha e abre o mesmo painel, para ele renascer na língua nova.
func _reabrir(nome: String) -> void:
	if atual != nome:
		return
	fechar()
	abrir(nome)

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
		Bus.toast(Txt.f("ger_painel_em_obra", {"n": nome}), "info", "cadeado")
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
	_posicionar_toasts()
	Bus.painel_aberto.emit(nome)

func fechar() -> void:
	if painel_atual and is_instance_valid(painel_atual):
		painel_atual.queue_free()
	painel_atual = null
	atual = ""
	_posicionar_toasts()
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
	if not _pronto_para_desenhar():
		# Aviso disparado antes de existir onde desenhar (o boot emite alguns):
		# guarda na fila em vez de sumir com ele.
		if _fila_inicial.size() < 8:
			_fila_inicial.append(["toast", texto, tipo, icone])
		return
	var cor := UI.ACENTO
	match tipo:
		"bom": cor = UI.VERDE
		"ruim": cor = UI.VERMELHO
		"epico": cor = UI.OURO
		# "não dá para fazer isso" não é erro nem informação neutra: tem cor e
		# som próprios, senão o aviso mais frequente do jogo é o mais mudo
		"bloqueado": cor = UI.TEXTO3
	var cx := UI.painel(UI.PAINEL.darkened(0.1), 10)
	cx.modulate = Color(1, 1, 1, 0)
	cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(8)
	if icone != "":
		# `icone` é NOME de ícone vetorial (ver scripts/ui/icone.gd), nunca emoji
		var ic := UI.icone(icone, cor, 18)
		h.add_child(ic)
	h.add_child(UI.rotulo(texto, 15, cor))
	cx.add_child(h)
	caixa_toast.add_child(cx)
	var tw := cx.create_tween()
	tw.tween_property(cx, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.4)
	tw.tween_property(cx, "modulate:a", 0.0, 0.4)
	tw.tween_callback(cx.queue_free)
	# O `break` aqui dentro fazia o teto valer para UM toast só: numa rajada de
	# avisos a tela enchia. Sem ele o excedente sai de verdade. `queue_free` só
	# libera no fim do quadro, então tiramos o filho da árvore na hora — senão o
	# laço veria o mesmo filho para sempre.
	_aparar_toasts()

## ------------------------------------------------- relatório offline

func _relatorio_offline(dados: Dictionary) -> void:
	if not bool(dados.get("aplicado", false)) or _offline_mostrado:
		return
	if not _pronto_para_desenhar():
		_fila_inicial.append(["offline", dados])
		return
	_offline_mostrado = true
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
	v.add_child(UI.titulo(Txt.t("ger_offline_titulo"), 21))
	v.add_child(UI.separador())
	v.add_child(UI.rotulo(Txt.f("ger_offline_fora", {"n": Ux.tempo_curto(float(dados["segundos"]))}), 15, UI.TEXTO2))
	if float(dados.get("cortado", 0.0)) > 1.0:
		v.add_child(UI.rotulo(Txt.f("ger_offline_teto", {"n": Ux.tempo_curto(float(dados["usado"]))}), 13, UI.TEXTO3))
	v.add_child(UI.rotulo(Txt.f("ger_offline_eficiencia", {"n": Fmt.pct(float(dados["eficiencia"]))}), 13, UI.TEXTO3))
	v.add_child(UI.separador())
	v.add_child(_linha_ganho("ouro", UI.OURO, "+" + Fmt.big(dados["ouro"]), 22))
	v.add_child(_linha_ganho("livro", UI.ACENTO2, "+" + Fmt.big(dados["xp"]) + " XP", 18))

	# --- Caixa da Vigília: o saque offline chega LACRADO ---
	var seladas := int(dados.get("seladas", 0))
	if seladas > 0:
		v.add_child(UI.separador())
		v.add_child(UI.rotulo(Txt.t("ger_caixa_titulo"), 13, UI.TEXTO3))
		var lbl := UI.rotulo(Txt.f("ger_caixa_lacradas", {"n": seladas}), 14, UI.TEXTO2)
		v.add_child(lbl)
		var b_abrir := UI.botao(Txt.t("ger_caixa_abrir"), Callable())
		b_abrir.custom_minimum_size.y = 40
		b_abrir.pressed.connect(func():
			var carta: Dictionary = Mecanicas.abrir_caixa(jogo)
			if carta.is_empty():
				b_abrir.disabled = true
				lbl.text = Txt.t("ger_caixa_vazia_msg")
				return
			var def: Dictionary = Dados.carta_por_id.get(str(carta.get("id", "")), {})
			var rar := str(carta.get("raridade", "comum"))
			# A raridade também é conteúdo bilíngue (data/rarities.json tem `nomeEn`);
			# lida direto do campo "nome" ela ficava em português no jogo em inglês.
			var nome_rar := Ux.txt(Dados.raridade(rar), "nome", Cfg.ingles())
			if nome_rar.is_empty():
				nome_rar = rar
			lbl.text = "%s  ·  %s" % [Ux.txt(def, "nome", Cfg.ingles()), nome_rar]
			lbl.add_theme_color_override("font_color", UI.cor_raridade(rar))
			UI.saltar(lbl, 1.25)
			var restam := int(jogo.s["caixa"]["seladas"])
			b_abrir.text = Txt.f("ger_caixa_abrir_n", {"n": restam}) if restam > 0 else Txt.t("ger_caixa_vazia")
			b_abrir.disabled = restam <= 0)
		b_abrir.text = Txt.f("ger_caixa_abrir_n", {"n": seladas})
		v.add_child(b_abrir)

	v.add_child(UI.espacador(0, false))
	var b := UI.botao(Txt.t("ger_continuar"), func(): janela.queue_free(); fundo_escuro.visible = false)
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
	var ic := UI.icone(icone, cor, float(tamanho))
	h.add_child(ic)
	h.add_child(UI.rotulo(texto, tamanho, cor))
	return h
