extends Control

## TUTORIAL — a Torre falando com o Operador.
##
## Onboarding não-intrusivo: nada bloqueia, nada exige clique. Um balão
## aparece no momento em que o assunto vira problema real (o primeiro ouro,
## a primeira carta, a onda 25), aponta para a região certa da tela, e some
## sozinho. O que já foi visto fica gravado em `jogo.s["tutorial"]["vistas"]`.
##
## Adicionado pelo `main` dentro da camada de UI, acima do HUD.

const DURACAO := 9.5              ## segundos que um balão fica na tela
const ESPERA_ENTRE := 5.0         ## respiro entre um balão e o próximo
const ATRASO_INICIAL := 5.0       ## deixa o jogador ver a torre atirar antes
const LARGURA := 330.0

## A sequência. `alvo` é uma região da tela; `id` é o que fica salvo.
const PASSOS := [
	{
		"id": "inicio", "alvo": "torre",
		"texto": "Eu sou a Torre. Atiro sozinha, enferrujo devagar e não durmo.\nO resto é com você.",
	},
	{
		"id": "ouro", "alvo": "moedas",
		"texto": "Isso que você recolheu é ouro.\nParado no bolso, ele não mata ninguém.",
	},
	{
		"id": "melhorias", "alvo": "menu_upgrades",
		"texto": "Melhorias ficam aqui embaixo.\nGaste tudo, sempre. Poupar é uma forma lenta de morrer.",
	},
	{
		"id": "nivel", "alvo": "menu_talentos",
		"texto": "Subiu de nível: ganhou pontos de talento.\nA árvore lembra de cada um deles.",
	},
	{
		"id": "chefe", "alvo": "onda",
		"texto": "Esse tem nome próprio e mais de uma fase.\nMorre soltando gemas — se morrer.",
	},
	{
		"id": "carta", "alvo": "menu_cartas",
		"texto": "Caiu uma carta.\nNo inventário ela é enfeite; equipada, ela é dano.",
	},
	{
		"id": "habilidade", "alvo": "habilidades",
		"texto": "Uma habilidade acordou.\nTem tecla, tem recarga e tem hora certa de usar.",
	},
	{
		"id": "purga", "alvo": "purga",
		"texto": "A Purga é a única coisa que eu não faço sozinha.\nDeixe encher e solte na faixa dourada.",
	},
	{
		"id": "casco", "alvo": "vitais",
		"texto": "Metade do meu casco já era.\nVida também está à venda, caso lhe interesse.",
	},
	{
		"id": "evento", "alvo": "centro",
		"texto": "Entre as ondas, o mundo bate à porta.\nEscolha rápido: as consequências ficam.",
	},
	{
		"id": "ascensao", "alvo": "menu_prestigio",
		"texto": "Onda 25. Dá para Ascender: perde-se tudo, ganham-se fragmentos.\nÉ assim que se avança de verdade.",
	},
]

var jogo: Node
var hud: Control                  ## definido pelo main (para apontar nos botões reais)
var gerente: Node                 ## GerentePaineis — para não falar por cima de um painel

var balao: PanelContainer
var seta: Control
var _espera := ATRASO_INICIAL
var _acc := 0.0
var _passo_atual := ""
var _viu_ouro := false
var _subiu_nivel := false
var _viu_chefe := false
var _caiu_carta := false

## Seta do balão — desenhada, porque a fonte não tem emoji e nem deveria.
class Seta extends Control:
	var cor := UI.ACENTO
	var direcao := Vector2.DOWN

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(20, 20)

	func _draw() -> void:
		var c := size * 0.5
		var d := direcao.normalized()
		var p := Vector2(-d.y, d.x)
		var pontos := PackedVector2Array([c + d * 9.0, c - d * 4.0 + p * 8.0, c - d * 4.0 - p * 8.0])
		draw_colored_polygon(pontos, cor)

## ---------------------------------------------------------------- ciclo

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Bus.ouro_ganho.connect(func(_v, fonte): _viu_ouro = _viu_ouro or str(fonte) != "debug")
	Bus.nivel_subiu.connect(func(_n, _p): _subiu_nivel = true)
	Bus.carta_caiu.connect(func(_i): _caiu_carta = true)
	Bus.onda_iniciou.connect(func(_n, eh_chefe): _viu_chefe = _viu_chefe or eh_chefe)

func _process(dt: float) -> void:
	if jogo == null or not jogo.iniciado:
		return
	if _passo_atual != "":
		# painel, evento ou pausa entrou na frente: some e tenta de novo depois
		if _ocupado():
			_recolher()
		return
	_espera -= dt
	if _espera > 0.0:
		return
	_acc += dt
	if _acc < 0.4:
		return
	_acc = 0.0
	if not _pode_falar():
		return
	var passo := _proximo()
	if passo.is_empty():
		return
	_mostrar(passo)

## Nada de balão por cima de painel aberto, janela de evento ou pausa.
func _ocupado() -> bool:
	if jogo.pausado or not bool(jogo.s["torre"]["viva"]):
		return true
	if gerente != null and is_instance_valid(gerente):
		if str(gerente.atual) != "":
			return true
		if "dialogo" in gerente and gerente.dialogo != null and is_instance_valid(gerente.dialogo):
			return true
	return false

func _pode_falar() -> bool:
	if bool(_estado()["completo"]):
		return false
	return not _ocupado()

## Tira o balão da tela sem marcar como visto — ele volta na próxima brecha.
func _recolher() -> void:
	_passo_atual = ""
	_espera = ESPERA_ENTRE
	_sumir()

func _estado() -> Dictionary:
	var s: Dictionary = jogo.s
	if not (s.get("tutorial", null) is Dictionary):
		s["tutorial"] = {"passo": 0, "completo": false, "vistas": []}
	var t: Dictionary = s["tutorial"]
	if not (t.get("vistas", null) is Array):
		t["vistas"] = []
	return t

## Primeiro passo ainda não visto cujo gatilho já aconteceu.
func _proximo() -> Dictionary:
	var vistas: Array = _estado()["vistas"]
	for item in PASSOS:
		var p: Dictionary = item
		var id := str(p["id"])
		if vistas.has(id):
			continue
		if _gatilho(id):
			return p
	return {}

func _gatilho(id: String) -> bool:
	var s: Dictionary = jogo.s
	match id:
		"inicio":
			return true
		"ouro":
			return _viu_ouro
		"melhorias":
			var def: Dictionary = Dados.upgrade_por_id.get("dano", {})
			if def.is_empty():
				return false
			var nivel := int(s["upgrades"].get("dano", 0))
			return Big.gte(float(s["moedas"]["ouro"]), jogo.custo_upgrade(def, nivel))
		"nivel":
			return _subiu_nivel or int(s["nivel"]) > 1
		"chefe":
			return _viu_chefe or bool(s["em_chefe"])
		"carta":
			var inv: Array = s["cartas"]["inventario"]
			return _caiu_carta or not inv.is_empty()
		"habilidade":
			for chave in s["habilidades"].keys():
				var h: Dictionary = s["habilidades"][chave]
				if bool(h.get("desbloqueada", false)):
					return true
			return false
		"purga":
			return float(Mecanicas.estado_purga(s)["carga"]) >= 0.72
		"casco":
			var t: Dictionary = s["torre"]
			return Big.frac(float(t["vida"]), float(t["vida_max"])) < 0.6
		"evento":
			var hist: Array = Eventos.estado(s)["historico"]
			return not hist.is_empty()
		"ascensao":
			return int(s["onda_maxima"]) >= Bal.ASC_ONDA_MIN
	return false

## ---------------------------------------------------------------- balão

func _mostrar(passo: Dictionary) -> void:
	var id := str(passo["id"])
	_passo_atual = id
	var primeiro := id == str(PASSOS[0]["id"])

	balao = UI.painel(UI.PAINEL, 12)
	balao.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL.lerp(UI.ACENTO, 0.06), 12, 2, UI.ACENTO.darkened(0.35)))
	balao.custom_minimum_size.x = LARGURA
	balao.mouse_filter = Control.MOUSE_FILTER_STOP
	balao.modulate = Color(1, 1, 1, 0)
	balao.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_fechar(id))
	add_child(balao)

	seta = Seta.new()
	seta.cor = UI.ACENTO.darkened(0.35)
	add_child(seta)

	var v := UI.vbox(6)
	balao.add_child(v)

	var topo := UI.hbox(8)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	topo.add_child(ic)
	ic.configurar("torre", UI.ACENTO, 18)
	topo.add_child(UI.rotulo("A TORRE", 11, UI.TEXTO3))
	topo.add_child(UI.espacador())
	topo.add_child(UI.rotulo("clique para dispensar", 10, UI.TEXTO3.darkened(0.1)))
	v.add_child(topo)

	var l := UI.rotulo(str(passo["texto"]), 14, UI.TEXTO)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = LARGURA - 30.0
	l.add_theme_constant_override("line_spacing", 5)
	v.add_child(l)

	if primeiro:
		var linha := UI.hbox(6)
		linha.add_child(UI.espacador())
		var b := UI.botao("Pular tutorial", _pular, "Some com os balões para sempre. Não vou insistir.")
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", UI.TEXTO3)
		b.add_theme_stylebox_override("normal", UI.caixa(UI.PAINEL2.darkened(0.2), 7, 1, UI.BORDA.darkened(0.2)))
		linha.add_child(b)
		v.add_child(linha)

	var barra := UI.barra(UI.ACENTO.darkened(0.2), 3)
	barra.value = 1.0
	v.add_child(barra)
	var tb := barra.create_tween()
	tb.tween_property(barra, "value", 0.0, DURACAO)

	var tw := balao.create_tween()
	tw.tween_property(balao, "modulate:a", 1.0, 0.25)

	await get_tree().process_frame
	if not is_instance_valid(balao):
		return
	_posicionar(_regiao(str(passo.get("alvo", "centro"))))
	UI.saltar(balao, 1.08)
	Bus.tutorial_passo.emit(id)
	await get_tree().create_timer(DURACAO).timeout
	_fechar(id)

func _fechar(id: String) -> void:
	if _passo_atual != id:
		return
	_passo_atual = ""
	_espera = ESPERA_ENTRE
	var t := _estado()
	var vistas: Array = t["vistas"]
	if not vistas.has(id):
		vistas.append(id)
	t["passo"] = vistas.size()
	if vistas.size() >= PASSOS.size():
		t["completo"] = true
	_sumir()

func _pular() -> void:
	var t := _estado()
	t["completo"] = true
	_passo_atual = ""
	_sumir()
	Bus.toast("Tutorial encerrado. Você por sua conta.", "info")

func _sumir() -> void:
	if is_instance_valid(seta):
		seta.queue_free()
	seta = null
	if not is_instance_valid(balao):
		balao = null
		return
	var alvo := balao
	balao = null
	var tw := alvo.create_tween()
	tw.tween_property(alvo, "modulate:a", 0.0, 0.25)
	tw.tween_callback(alvo.queue_free)

## ------------------------------------------------------------ geometria

## Coloca o balão do lado mais livre do alvo e vira a seta para ele.
func _posicionar(alvo: Rect2) -> void:
	var tam := get_viewport_rect().size
	var b := balao.size
	var centro := alvo.get_center()
	var margem := 14.0
	var lado := "baixo"
	if centro.y > tam.y * 0.6:
		lado = "cima"
	elif centro.y < tam.y * 0.34:
		lado = "baixo"
	else:
		lado = "esquerda" if centro.x > tam.x * 0.5 else "direita"

	var pos := Vector2.ZERO
	match lado:
		"cima": pos = Vector2(centro.x - b.x * 0.5, alvo.position.y - b.y - 20.0)
		"baixo": pos = Vector2(centro.x - b.x * 0.5, alvo.end.y + 20.0)
		"direita": pos = Vector2(alvo.end.x + 20.0, centro.y - b.y * 0.5)
		_: pos = Vector2(alvo.position.x - b.x - 20.0, centro.y - b.y * 0.5)
	pos.x = clampf(pos.x, margem, maxf(margem, tam.x - b.x - margem))
	pos.y = clampf(pos.y, margem, maxf(margem, tam.y - b.y - margem))
	balao.position = pos

	var direcao := Vector2.DOWN
	var ponta := Vector2.ZERO
	match lado:
		"cima":
			direcao = Vector2.DOWN
			ponta = Vector2(clampf(centro.x, pos.x + 20.0, pos.x + b.x - 20.0), pos.y + b.y + 8.0)
		"baixo":
			direcao = Vector2.UP
			ponta = Vector2(clampf(centro.x, pos.x + 20.0, pos.x + b.x - 20.0), pos.y - 8.0)
		"direita":
			direcao = Vector2.LEFT
			ponta = Vector2(pos.x - 8.0, clampf(centro.y, pos.y + 20.0, pos.y + b.y - 20.0))
		_:
			direcao = Vector2.RIGHT
			ponta = Vector2(pos.x + b.x + 8.0, clampf(centro.y, pos.y + 20.0, pos.y + b.y - 20.0))
	if is_instance_valid(seta):
		seta.direcao = direcao
		seta.position = ponta - Vector2(10, 10)
		seta.queue_redraw()

## Região da tela de cada alvo — usa os widgets reais do HUD quando existem.
func _regiao(nome: String) -> Rect2:
	var tam := get_viewport_rect().size
	if hud != null and is_instance_valid(hud):
		if nome.begins_with("menu_"):
			var chave := nome.substr(5)
			var botoes: Dictionary = hud.botoes_painel
			if botoes.has(chave):
				var bt: Control = botoes[chave]
				if is_instance_valid(bt) and bt.size.x > 1.0:
					return Rect2(bt.global_position, bt.size)
		if nome == "purga" and hud.caixa_hab != null and hud.caixa_hab.get_child_count() > 0:
			var p: Control = hud.caixa_hab.get_child(0)
			if is_instance_valid(p) and p.size.x > 1.0:
				return Rect2(p.global_position, p.size)
	match nome:
		"moedas": return Rect2(14, 12, 240, 38)
		"vitais": return Rect2(14, 58, 236, 120)
		"onda": return Rect2(tam.x * 0.5 - 150.0, 10, 300, 108)
		"habilidades": return Rect2(tam.x * 0.5 - 200.0, tam.y - 84.0, 400, 62)
		"menu": return Rect2(14, tam.y - 58.0, 320, 44)
		"acoes": return Rect2(tam.x - 240.0, tam.y - 58.0, 226, 44)
	return Rect2(tam.x * 0.5 - 80.0, tam.y * 0.5 - 80.0, 160, 160)
