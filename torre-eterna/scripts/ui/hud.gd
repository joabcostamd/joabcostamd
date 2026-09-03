extends Control

## HUD — o que fica sempre visível. Construído em código, responsivo,
## atualizado ~12×/s (não a 60fps: economiza CPU e evita números tremendo).

var jogo: Node
var _t := 0.0
var _acc := 0.0

# referências
var lbl_moedas := {}
var lbl_onda: Label
var lbl_chefe: Label
var lbl_retomada: Label
var barra_onda: ProgressBar
var barra_vida: ProgressBar
var lbl_vida: Label
var barra_escudo: ProgressBar
var barra_xp: ProgressBar
var lbl_nivel: Label
var lbl_combo: Label
var lbl_dps: Label
var lbl_ouro_mult: Label
var lbl_fps: Label
var caixa_hab: HBoxContainer
var botoes_hab := {}
var caixa_buffs: HBoxContainer
var caixa_adapt: HBoxContainer
var rotulos_adapt := {}
var botoes_painel := {}
var lbl_velocidade: Label
var aviso_pontos: Label

signal painel_pedido(nome: String)

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_construir()
	Bus.nivel_subiu.connect(func(_n, _p): _pulsar_nivel())
	Bus.habilidade_pronta.connect(_ao_hab_pronta)
	Bus.ui_atualizar.connect(func(_c): _reconstruir_habilidades())
	Bus.onda_iniciou.connect(_ao_onda)

## ------------------------------------------------------------ construção

func _construir() -> void:
	# ---------- topo esquerdo: moedas ----------
	var topo := UI.hbox(10)
	topo.position = Vector2(14, 12)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topo)
	for chave in ["ouro", "gemas", "fragmentos", "nucleos", "eter", "poeira"]:
		var cx := UI.painel(UI.PAINEL.darkened(0.15), 9)
		cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var h := UI.hbox(5)
		var ic := Control.new()
		ic.set_script(load("res://scripts/ui/icone_control.gd"))
		h.add_child(ic)
		ic.configurar(Icone.da_moeda(chave), UI.MOEDA_COR.get(chave, UI.TEXTO), 17)
		var l := UI.rotulo("0", 15, UI.MOEDA_COR.get(chave, UI.TEXTO))
		h.add_child(l)
		cx.add_child(h)
		topo.add_child(cx)
		lbl_moedas[chave] = l
		cx.visible = chave in ["ouro", "gemas"]
		lbl_moedas[chave + "_cx"] = cx

	# ---------- topo centro: onda ----------
	var centro := UI.vbox(2)
	centro.anchor_left = 0.5
	centro.anchor_right = 0.5
	centro.anchor_top = 0.0
	centro.anchor_bottom = 0.0
	centro.offset_left = -160
	centro.offset_right = 160
	centro.offset_top = 10
	centro.offset_bottom = 90
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	lbl_onda = UI.titulo("ONDA 1", 24)
	lbl_onda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(lbl_onda)
	barra_onda = UI.barra(UI.ACENTO, 7)
	barra_onda.custom_minimum_size.x = 300
	centro.add_child(barra_onda)
	lbl_chefe = UI.rotulo("", 14, UI.VERMELHO)
	lbl_chefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(lbl_chefe)
	lbl_retomada = UI.rotulo("", 15, UI.ACENTO2)
	lbl_retomada.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(lbl_retomada)

	# ---------- esquerda: vitais ----------
	var vitais := UI.vbox(4)
	vitais.position = Vector2(14, 62)
	vitais.custom_minimum_size.x = 230
	vitais.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vitais)

	var lv := UI.hbox(6)
	lbl_nivel = UI.rotulo("Nível 1", 15, UI.ACENTO2)
	lv.add_child(lbl_nivel)
	aviso_pontos = UI.rotulo("", 14, UI.OURO)
	lv.add_child(aviso_pontos)
	vitais.add_child(lv)
	barra_xp = UI.barra(UI.ACENTO2, 6)
	barra_xp.custom_minimum_size.x = 230
	vitais.add_child(barra_xp)

	var hv := UI.hbox(6)
	var ic_v := Control.new()
	ic_v.set_script(load("res://scripts/ui/icone_control.gd"))
	hv.add_child(ic_v)
	ic_v.configurar("coracao", UI.VERMELHO, 14)
	lbl_vida = UI.rotulo("100 / 100", 14, UI.TEXTO2)
	hv.add_child(lbl_vida)
	vitais.add_child(hv)
	barra_vida = UI.barra(UI.VERDE, 10)
	barra_vida.custom_minimum_size.x = 230
	vitais.add_child(barra_vida)
	barra_escudo = UI.barra(Color("#60a5fa"), 5)
	barra_escudo.custom_minimum_size.x = 230
	vitais.add_child(barra_escudo)

	caixa_buffs = UI.hbox(4)
	caixa_buffs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitais.add_child(caixa_buffs)

	# adaptação do Enxame: o jogador precisa VER o mundo aprendendo
	caixa_adapt = UI.hbox(6)
	caixa_adapt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitais.add_child(caixa_adapt)
	for chave in ["fogo", "gelo", "raio", "veneno", "vazio"]:
		var linha_a := UI.hbox(2)
		linha_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic_a := Control.new()
		ic_a.set_script(load("res://scripts/ui/icone_control.gd"))
		linha_a.add_child(ic_a)
		ic_a.configurar(chave if chave != "vazio" else "vazio", Color.html(str(Bal.ELEMENTOS[chave]["cor"])), 13)
		var l_a := UI.rotulo("", 11, UI.TEXTO3)
		linha_a.add_child(l_a)
		caixa_adapt.add_child(linha_a)
		linha_a.visible = false
		rotulos_adapt[chave] = {"linha": linha_a, "label": l_a}

	# ---------- direita: combo / dps / fps ----------
	var dir := UI.vbox(2)
	dir.anchor_left = 1.0
	dir.anchor_right = 1.0
	dir.anchor_top = 0.0
	dir.anchor_bottom = 0.0
	dir.offset_left = -230
	dir.offset_right = -14
	dir.offset_top = 56
	dir.offset_bottom = 160
	dir.alignment = BoxContainer.ALIGNMENT_END
	dir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dir)
	lbl_combo = UI.rotulo("", 26, UI.OURO)
	lbl_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dir.add_child(lbl_combo)
	lbl_dps = UI.rotulo("", 14, UI.TEXTO2)
	lbl_dps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dir.add_child(lbl_dps)
	lbl_ouro_mult = UI.rotulo("", 14, UI.OURO)
	lbl_ouro_mult.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_ouro_mult.tooltip_text = "Multiplicador de ouro no momento: combo × aglomeração.\nQuanto mais inimigos vivos na tela, mais cada abate rende."
	dir.add_child(lbl_ouro_mult)
	lbl_fps = UI.rotulo("", 12, UI.TEXTO3)
	lbl_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dir.add_child(lbl_fps)

	# ---------- rodapé: habilidades ----------
	caixa_hab = UI.hbox(8)
	caixa_hab.anchor_left = 0.5
	caixa_hab.anchor_right = 0.5
	caixa_hab.anchor_top = 1.0
	caixa_hab.anchor_bottom = 1.0
	caixa_hab.offset_top = -78
	caixa_hab.offset_bottom = -14
	caixa_hab.offset_left = -400
	caixa_hab.offset_right = 400
	caixa_hab.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(caixa_hab)

	# ---------- rodapé esquerdo: painéis ----------
	var menu := UI.hbox(6)
	menu.anchor_left = 0.0
	menu.anchor_right = 0.0
	menu.anchor_top = 1.0
	menu.anchor_bottom = 1.0
	menu.offset_top = -58
	menu.offset_bottom = -14
	menu.offset_left = 14
	menu.offset_right = 620
	add_child(menu)
	var paineis := [
		["upgrades", "espada", "Melhorias (Q)", UI.VERMELHO],
		["talentos", "arvore", "Talentos (W)", UI.VERDE],
		["cartas", "carta", "Cartas (E)", UI.ACENTO],
		["prestigio", "prestigio", "Prestígio (R)", UI.ACENTO2],
		["reliquias", "reliquia", "Relíquias", UI.OURO],
		["missoes", "missao", "Missões", UI.LARANJA],
		["desafios", "desafio", "Desafios", UI.ROSA],
		["conquistas", "trofeu", "Conquistas (T)", UI.OURO],
		["codex", "livro", "Codex", UI.TEXTO2],
		["stats", "stats", "Estatísticas", UI.TEXTO2],
		["config", "engrenagem", "Configurações (O)", UI.TEXTO2],
	]
	for p in paineis:
		var b := _botao_com_icone(str(p[1]), str(p[2]), p[3], func(): painel_pedido.emit(str(p[0])))
		menu.add_child(b)
		botoes_painel[str(p[0])] = b

	# ---------- rodapé direito: velocidade / auto ----------
	var acoes := UI.hbox(6)
	acoes.anchor_left = 1.0
	acoes.anchor_right = 1.0
	acoes.anchor_top = 1.0
	acoes.anchor_bottom = 1.0
	acoes.offset_top = -58
	acoes.offset_bottom = -14
	acoes.offset_left = -240
	acoes.offset_right = -14
	acoes.alignment = BoxContainer.ALIGNMENT_END
	add_child(acoes)
	lbl_velocidade = UI.rotulo("×1", 15, UI.ACENTO)
	acoes.add_child(_botao_com_icone("velocidade", "Velocidade do jogo (Espaço)", UI.ACENTO, _alternar_velocidade))
	acoes.add_child(lbl_velocidade)
	acoes.add_child(_botao_com_icone("alvo", "Modo de mira", UI.VERDE, _alternar_mira))
	acoes.add_child(_botao_com_icone("salvar", "Salvar agora (F5)", UI.TEXTO2, func(): jogo.salvar(); Bus.toast("Jogo salvo", "bom")))

	# a Purga fica à esquerda da barra de habilidades, com destaque próprio
	var b_purga := Button.new()
	b_purga.set_script(load("res://scripts/ui/botao_purga.gd"))
	caixa_hab.add_child(b_purga)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 1)
	caixa_hab.add_child(sep)

	_reconstruir_habilidades()

## Botão quadrado com ícone vetorial centralizado.
func _botao_com_icone(icone: String, dica: String, cor: Color, ao_clicar: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(46, 44)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = dica
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(ao_clicar)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(ic)
	ic.configurar(icone, cor, 22)
	return b

func _reconstruir_habilidades() -> void:
	# preserva o botão da Purga e o separador (os dois primeiros filhos)
	var filhos := caixa_hab.get_children()
	for i in range(filhos.size() - 1, 1, -1):
		filhos[i].queue_free()
	botoes_hab.clear()
	if jogo == null:
		return
	for def in Dados.habilidades:
		var id := str(def.get("id", ""))
		var h: Dictionary = jogo.s["habilidades"].get(id, {})
		if h.is_empty() or not bool(h.get("desbloqueada", false)):
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(58, 58)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "%s  [%s]\n%s" % [str(def.get("nome", id)), str(def.get("tecla", "")), _desc_hab(def, int(h.get("nivel", 1)))]
		b.pressed.connect(func(): jogo.usar_habilidade(id))
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		caixa_hab.add_child(b)
		var ic_h := Control.new()
		ic_h.set_script(load("res://scripts/ui/icone_control.gd"))
		ic_h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic_h.offset_bottom = -8
		b.add_child(ic_h)
		ic_h.configurar(Icone.da_habilidade(id), Color.html(str(def.get("cor", "#ffffff"))), 28)
		var tec := UI.rotulo(str(def.get("tecla", "")), 10, UI.TEXTO3)
		tec.position = Vector2(4, 2)
		tec.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tec)
		# barra de recarga por baixo
		var pb := UI.barra(Color.html(str(def.get("cor", "#ffffff"))), 4)
		pb.custom_minimum_size = Vector2(58, 4)
		pb.position = Vector2(0, 54)
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pb)
		botoes_hab[id] = {"botao": b, "barra": pb}

func _desc_hab(def: Dictionary, nivel: int) -> String:
	var d := str(def.get("desc", ""))
	var esc = def.get("escala", {})
	if esc is Dictionary:
		for chave in esc.keys():
			d = d.replace("{%s}" % chave, Fmt.num(Habilidades.valor(def, str(chave), nivel), 1))
	d = d.replace("{dur}", Fmt.num(Habilidades.duracao(def, nivel, 1.0), 1))
	return d

## ------------------------------------------------------------ atualização

func _process(delta: float) -> void:
	_t += delta
	_acc += delta
	_atualizar_rapido()
	if _acc < 0.08:
		return
	_acc = 0.0
	_atualizar_lento()

func _atualizar_rapido() -> void:
	if jogo == null or not jogo.iniciado:
		return
	# recargas precisam de suavidade
	for id in botoes_hab.keys():
		var h: Dictionary = jogo.s["habilidades"].get(id, {})
		var ref: Dictionary = botoes_hab[id]
		var cd := float(h.get("cd", 0.0))
		var cd_max := maxf(0.001, float(h.get("cd_max", 1.0)))
		var pronto := cd <= 0.0
		ref["barra"].value = 1.0 - clampf(cd / cd_max, 0.0, 1.0)
		var b: Button = ref["botao"]
		b.disabled = not pronto
		b.modulate = Color.WHITE if pronto else Color(0.55, 0.6, 0.7)

func _atualizar_lento() -> void:
	if jogo == null or not jogo.iniciado:
		return
	var s: Dictionary = jogo.s

	for chave in lbl_moedas.keys():
		if chave.ends_with("_cx"):
			continue
		var v: float = s["moedas"].get(chave, Big.ZERO)
		lbl_moedas[chave].text = Fmt.big(v)
		var cx: Control = lbl_moedas[chave + "_cx"]
		cx.visible = chave in ["ouro", "gemas"] or not Big.is_zero(v)

	var onda := int(s["onda"])
	lbl_onda.text = "ONDA %d" % onda
	if bool(s["modo_farm"]):
		lbl_onda.text += "  🎯"
	var nec := maxi(1, int(s["necessarios"]))
	barra_onda.value = clampf(float(s["mortos_na_onda"]) / float(nec), 0.0, 1.0)
	if bool(s["em_chefe"]):
		var chefe := Dados.chefe_da_onda(onda)
		lbl_chefe.text = Ux.txt(chefe, "nome", Cfg.ingles())
		barra_onda.add_theme_stylebox_override("fill", UI.caixa(UI.VERMELHO, 3, 0))
	else:
		lbl_chefe.text = ""
		barra_onda.add_theme_stylebox_override("fill", UI.caixa(UI.ACENTO, 3, 0))

	var torre: Dictionary = s["torre"]
	barra_vida.value = Big.frac(torre["vida"], torre["vida_max"])
	lbl_vida.text = "%s / %s" % [Fmt.big(torre["vida"]), Fmt.big(torre["vida_max"])]
	var tem_escudo: bool = not Big.is_zero(torre["escudo_max"])
	barra_escudo.visible = tem_escudo
	if tem_escudo:
		barra_escudo.value = Big.frac(torre["escudo"], torre["escudo_max"])

	lbl_nivel.text = "Nível %d" % int(s["nivel"])
	barra_xp.value = Economia.progresso_nivel(s)
	var pts := int(s["pontos_talento"])
	aviso_pontos.text = ("  ●%d" % pts) if pts > 0 else ""

	if Mecanicas.em_retomada(s):
		var r: Dictionary = s["retomada"]
		lbl_retomada.text = "RETOMADA ×%d  ·  alvo: onda %d" % [int(Mecanicas.RETOMADA_VELOCIDADE), int(r["alvo"])]
	else:
		lbl_retomada.text = ""

	var combo := int(s["combo"]["atual"])
	lbl_combo.text = ("%d×" % combo) if combo >= 5 else ""
	lbl_combo.add_theme_color_override("font_color", UI.OURO.lerp(UI.VERMELHO, clampf(float(combo) / 150.0, 0.0, 1.0)))

	lbl_dps.text = "DPS ~%s" % Fmt.big(Big.mul_f(jogo.stats.b("dano"), jogo.stats.n("cadencia") * jogo.stats.n("multiplicador") * (1.0 + jogo.stats.n("critChance") * (jogo.stats.n("critDano") - 1.0)) * maxf(1.0, jogo.stats.n("projeteis"))))
	var vivos: int = jogo.arena.contagem_viva()
	var mult_combo := 1.0 + float(combo) * float(jogo.esp.get("comboBonus", Bal.COMBO_BONUS_POR))
	var mult_aglom := Mecanicas.fator_aglomeracao(vivos)
	var mult_total := mult_combo * mult_aglom
	lbl_ouro_mult.text = ("ouro ×%.2f" % mult_total) if mult_total > 1.02 else ""
	lbl_ouro_mult.add_theme_color_override("font_color", UI.OURO.lerp(UI.VERDE, clampf((mult_total - 1.0) / 2.0, 0.0, 1.0)))

	lbl_fps.text = ("%d fps · %d inim." % [int(Engine.get_frames_per_second()), jogo.arena.inimigos.size()]) if bool(Cfg.get_v("mostrar_fps", false)) else ""
	lbl_velocidade.text = "×%d" % int(jogo.velocidade)

	_atualizar_buffs()
	_atualizar_adaptacao()
	botoes_painel["talentos"].modulate = UI.OURO if pts > 0 else Color.WHITE

## Mostra só os elementos em que o Enxame já criou resistência.
func _atualizar_adaptacao() -> void:
	var a: Dictionary = Mecanicas.estado_adaptacao(jogo.s)
	var algum := false
	for chave in rotulos_adapt.keys():
		var r := float(a.get(chave, 0.0))
		var ref: Dictionary = rotulos_adapt[chave]
		var mostrar := r > 0.04
		ref["linha"].visible = mostrar
		if mostrar:
			algum = true
			ref["label"].text = "-" + Fmt.pct(r, 0)
			var quente := clampf(r / Mecanicas.ADAPT_TETO, 0.0, 1.0)
			ref["label"].add_theme_color_override("font_color", UI.TEXTO3.lerp(UI.VERMELHO, quente))
	caixa_adapt.tooltip_text = "O Enxame se adapta ao que você mais usa.\nDiversifique os elementos para o dano voltar ao normal." if algum else ""

func _atualizar_buffs() -> void:
	var buffs: Array = jogo.s["buffs"]
	while caixa_buffs.get_child_count() > buffs.size():
		caixa_buffs.get_child(caixa_buffs.get_child_count() - 1).queue_free()
		await get_tree().process_frame
	for i in buffs.size():
		var b: Dictionary = buffs[i]
		var l: Label
		if i < caixa_buffs.get_child_count():
			l = caixa_buffs.get_child(i)
		else:
			l = UI.rotulo("", 14)
			caixa_buffs.add_child(l)
		l.text = "%s %ds" % [str(b.get("icone", "✦")), int(ceil(float(b["restante"])))]
		l.add_theme_color_override("font_color", Color.html(str(b.get("cor", "#ffffff"))))

## --------------------------------------------------------------- ações

func _alternar_velocidade() -> void:
	var teto := maxf(1.0, float(jogo.esp.get("velocidadeMax", 1.0)))
	var nova: float = float(jogo.velocidade) + 1.0
	if nova > teto:
		nova = 1.0
	jogo.definir_velocidade(nova)
	if teto <= 1.0:
		Bus.toast("Desbloqueie Aceleração na árvore de Fragmentos", "info", "⏩")

func _alternar_mira() -> void:
	var modos: Array = TorreSim.MODOS_MIRA
	var atual := str(jogo.s["torre"]["mira"])
	var i := modos.find(atual)
	var novo := str(modos[(i + 1) % modos.size()])
	jogo.definir_mira(novo)
	Bus.toast("Mira: " + novo, "info", "🎯")

func _pulsar_nivel() -> void:
	UI.pulsar(lbl_nivel, UI.OURO)

func _ao_hab_pronta(id: String) -> void:
	if botoes_hab.has(id):
		UI.saltar(botoes_hab[id]["botao"], 1.2)

func _ao_onda(_n: int, eh_chefe: bool) -> void:
	if eh_chefe:
		UI.saltar(lbl_onda, 1.3)
