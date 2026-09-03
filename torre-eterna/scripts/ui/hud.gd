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
var barra_chefe: ProgressBar
var lbl_chefe_fase: Label
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
var b_mira: Button
var b_infinito: Button
var b_farm: Button
var aviso_pontos: Label
var ic_pontos: Control

signal painel_pedido(nome: String)

func _ready() -> void:
	jogo = get_node_or_null("/root/Jogo")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_construir()
	UI.liberar_dicas(self)
	Bus.nivel_subiu.connect(func(_n, _p): _pulsar_nivel())
	Bus.habilidade_pronta.connect(_ao_hab_pronta)
	Bus.ui_atualizar.connect(func(_c): _reconstruir_habilidades())
	Bus.config_mudou.connect(func(chave, _v):
		if str(chave) == "idioma" or str(chave) == "tudo":
			_retraduzir())
	Bus.onda_iniciou.connect(_ao_onda)
	Bus.jogo_pronto.connect(func(): _reconstruir_habilidades())
	if jogo != null and jogo.iniciado:
		_reconstruir_habilidades()

## ------------------------------------------------------------ construção

func _construir() -> void:
	# ---------- topo esquerdo: moedas ----------
	# HFlow, não HBox: seis moedas em fila reta ultrapassam 700px e entram por
	# baixo do contador de onda, que é centralizado. Com quebra automática e
	# largura amarrada ao meio da tela (menos a folga do contador), a fila passa
	# a virar duas linhas em vez de invadir o vizinho.
	var topo := HFlowContainer.new()
	topo.add_theme_constant_override("h_separation", 10)
	topo.add_theme_constant_override("v_separation", 5)
	topo.anchor_left = 0.0
	topo.anchor_right = 0.5
	topo.anchor_top = 0.0
	topo.anchor_bottom = 0.0
	topo.offset_left = 14
	topo.offset_right = -170
	topo.offset_top = 12
	topo.offset_bottom = 110
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topo)
	for chave in ["ouro", "gemas", "fragmentos", "nucleos", "eter", "poeira"]:
		var cx := UI.painel(UI.PAINEL.darkened(0.15), 9)
		cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var h := UI.hbox(5)
		var ic := UI.icone(Icone.da_moeda(chave), UI.MOEDA_COR.get(chave, UI.TEXTO), 17)
		h.add_child(ic)
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
	# Véu por trás do bloco da onda. Numa onda de chefe cheia de efeitos, os
	# anéis de morte passam por cima e o jogador perde justamente o que precisa
	# ler: o número da onda, o nome do chefe e a barra de vida dele. Escurecer o
	# fundo resolve sem tirar nada do juice.
	var veu := ColorRect.new()
	veu.color = Color(0.02, 0.03, 0.07, 0.45)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veu.anchor_left = 0.5
	veu.anchor_right = 0.5
	veu.offset_left = -210
	veu.offset_right = 210
	veu.offset_top = 4
	veu.offset_bottom = 96
	add_child(veu)
	add_child(centro)
	lbl_onda = UI.titulo(Txt.t("onda") + " 1", 24)
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

	# barra de vida do chefe: larga, no topo, impossível de não ver
	barra_chefe = UI.barra(UI.VERMELHO, 12)
	barra_chefe.custom_minimum_size.x = 320
	barra_chefe.visible = false
	centro.add_child(barra_chefe)
	lbl_chefe_fase = UI.rotulo("", 12, UI.TEXTO3)
	lbl_chefe_fase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(lbl_chefe_fase)

	# ---------- esquerda: vitais ----------
	var vitais := UI.vbox(4)
	vitais.position = Vector2(14, 62)
	vitais.custom_minimum_size.x = 230
	vitais.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vitais)

	var lv := UI.hbox(6)
	lbl_nivel = UI.rotulo("%s 1" % Txt.t("nivel"), 15, UI.ACENTO2)
	lv.add_child(lbl_nivel)
	# ponto de talento a gastar: icone VETORIAL (a fonte nao tem glifo de bolinha)
	ic_pontos = Control.new()
	ic_pontos.set_script(load("res://scripts/ui/icone_control.gd"))
	ic_pontos.visible = false
	lv.add_child(ic_pontos)
	ic_pontos.configurar("estrela", UI.OURO, 13)
	aviso_pontos = UI.rotulo("", 14, UI.OURO)
	lv.add_child(aviso_pontos)
	vitais.add_child(lv)
	barra_xp = UI.barra(UI.ACENTO2, 6)
	barra_xp.custom_minimum_size.x = 230
	vitais.add_child(barra_xp)

	var hv := UI.hbox(6)
	var ic_v := UI.icone("coracao", UI.VERMELHO, 14)
	hv.add_child(ic_v)
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
		var ic_a := UI.icone(chave if chave != "vazio" else "vazio", Color.html(str(Bal.ELEMENTOS[chave]["cor"])), 13)
		linha_a.add_child(ic_a)
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
	lbl_ouro_mult.tooltip_text = Txt.t("hud_dica_ouro_mult")
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
	# Uma linha ACIMA do menu de painéis. As duas barras ficavam na mesma faixa
	# (menu em x 14..620, habilidades centradas em 240..1040): com o menu
	# adicionado depois, ele ficava por cima e roubava o clique das habilidades.
	caixa_hab.offset_top = -138
	caixa_hab.offset_bottom = -74
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
	menu.offset_right = 680
	add_child(menu)
	# [id, icone, dica pronta, cor, CHAVE do texto, tecla] — a chave fica guardada
	# no botão para o rótulo poder ser retraduzido sem remontar a barra inteira.
	var paineis := [
		["upgrades", "espada", Txt.t("p_upgrades") + " (Q)", UI.VERMELHO, "p_upgrades", " (Q)"],
		["talentos", "arvore", Txt.t("p_talentos") + " (W)", UI.VERDE, "p_talentos", " (W)"],
		["cartas", "carta", Txt.t("p_cartas") + " (E)", UI.ACENTO, "p_cartas", " (E)"],
		["prestigio", "prestigio", Txt.t("p_prestigio") + " (R)", UI.ACENTO2, "p_prestigio", " (R)"],
		["reliquias", "reliquia", Txt.t("p_reliquias"), UI.OURO, "p_reliquias", ""],
		["missoes", "missao", Txt.t("p_missoes"), UI.LARANJA, "p_missoes", ""],
		["desafios", "desafio", Txt.t("p_desafios"), UI.ROSA, "p_desafios", ""],
		["conquistas", "trofeu", Txt.t("p_conquistas") + " (T)", UI.OURO, "p_conquistas", " (T)"],
		["codex", "livro", Txt.t("p_codex"), UI.TEXTO2, "p_codex", ""],
		["habilidades", "raio", Txt.t("p_habilidades"), UI.ACENTO, "p_habilidades", ""],
		["stats", "stats", Txt.t("p_stats"), UI.TEXTO2, "p_stats", ""],
		["config", "engrenagem", Txt.t("p_config") + " (O)", UI.TEXTO2, "p_config", " (O)"],
	]
	for p in paineis:
		var b := _botao_com_icone(str(p[1]), str(p[2]), p[3], func(): painel_pedido.emit(str(p[0])))
		menu.add_child(b)
		botoes_painel[str(p[0])] = b
		# guarda a CHAVE, não o texto: é o que permite retraduzir sem remontar
		b.set_meta("chave_dica", str(p[4]))
		b.set_meta("tecla_dica", str(p[5]))

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
	acoes.add_child(_botao_com_icone("velocidade", Txt.t("velocidade"), UI.ACENTO, _alternar_velocidade))
	acoes.add_child(lbl_velocidade)
	b_mira = _botao_com_icone("alvo", Txt.t("mira"), UI.VERDE, _alternar_mira)
	acoes.add_child(b_mira)
	_atualizar_dica_mira()
	# O Modo Infinito era prometido pelo no do topo da arvore de Eter e nao tinha
	# porta nenhuma no jogo. Agora tem: o botao so aparece quando o no e comprado.
	b_infinito = _botao_com_icone("nova", Txt.t("hud_infinito_dica"), UI.ACENTO2, _alternar_infinito)
	acoes.add_child(b_infinito)
	# O Modo Farm tinha o MESMO defeito do Infinito, e eu consertei o Infinito
	# sem perceber que o irmão ao lado estava igual: `alternar_farm` era a única
	# função capaz de ligar o modo e não tinha um chamador em todo o repositório.
	# O jogador comprava o desbloqueio por 35 fragmentos, o HUD sabia desenhar o
	# aviso de "onda travada", e não havia como chegar lá.
	b_farm = _botao_com_icone("ampulheta", Txt.t("hud_farm_dica"), UI.OURO, _alternar_farm)
	acoes.add_child(b_farm)
	acoes.add_child(_botao_com_icone("salvar", Txt.t("salvar_agora") + " (F5)", UI.TEXTO2, _salvar_agora))

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
		var nome_hab := Ux.txt(def, "nome", Cfg.ingles())
		if nome_hab.is_empty():
			nome_hab = id
		b.tooltip_text = "%s  [%s]\n%s" % [nome_hab, str(def.get("tecla", "")), _desc_hab(def, int(h.get("nivel", 1)))]
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
	# nos novos entram com as dicas fechadas de fabrica
	UI.liberar_dicas(caixa_hab)

## Quanto o botao de Melhorias deve chamar a atencao. Devolve 0 quando nao da
## para comprar nada, e vai ate 1 quando o ouro parado passa de 25x a melhoria
## mais barata disponivel.
func _urgencia_melhorias() -> float:
	if jogo == null:
		return 0.0
	var ouro: float = jogo.s["moedas"]["ouro"]
	var mais_barato := INF
	for def in Dados.upgrades:
		if not jogo.upgrade_disponivel(def):
			continue
		var nivel := int(jogo.s["upgrades"].get(str(def.get("id", "")), 0))
		var maxn := int(def.get("max", -1))
		if maxn >= 0 and nivel >= maxn:
			continue
		var custo := Big.geo_sum(float(def.get("base", 1)), float(def.get("cresc", 1.1)), nivel, 1)
		if not Big.gte(ouro, custo):
			continue
		mais_barato = minf(mais_barato, custo)
	if is_inf(mais_barato):
		return 0.0
	# em log10, "quantas vezes cabe" e uma subtracao
	var folga := ouro - mais_barato
	return clampf(folga / 1.4, 0.15, 1.0)

func _atualizar_brilho_melhorias() -> void:
	var b = botoes_painel.get("upgrades", null)
	if b == null:
		return
	var u := _urgencia_melhorias()
	if u <= 0.0:
		b.modulate = Color.WHITE
		return
	# pulsa devagar: o objetivo e ser notado de canto de olho, nao competir com
	# o combate no centro da tela
	var pulso := 0.72 + 0.28 * sin(float(Time.get_ticks_msec()) * 0.0035)
	b.modulate = Color.WHITE.lerp(UI.OURO, u * pulso)

func _desc_hab(def: Dictionary, nivel: int) -> String:
	var d := Ux.txt(def, "desc", Cfg.ingles())
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
	lbl_onda.text = "%s %d" % [Txt.t("onda"), onda]
	if bool(s["modo_farm"]):
		lbl_onda.text += "  · " + Txt.t("hud_farm")
	if bool(s.get("modo_infinito", false)):
		lbl_onda.text += "  · " + Txt.t("hud_infinito")
	var nec := maxi(1, int(s["necessarios"]))
	barra_onda.value = clampf(float(s["mortos_na_onda"]) / float(nec), 0.0, 1.0)
	if bool(s["em_chefe"]):
		var chefe := Dados.chefe_da_onda(onda)
		lbl_chefe.text = Ux.txt(chefe, "nome", Cfg.ingles())
		barra_onda.add_theme_stylebox_override("fill", UI.caixa(UI.VERMELHO, 3, 0))
		var alvo = jogo.diretor.chefe_atual
		if alvo != null and alvo.vivo():
			barra_chefe.visible = true
			barra_chefe.value = alvo.frac_vida()
			var fases := maxi(1, int(alvo.def.get("fases", 1)))
			lbl_chefe_fase.text = Txt.f("hud_chefe_fase", {"a": alvo.fase + 1, "b": fases, "hp": Fmt.big(alvo.hp)}) if fases > 1 else Fmt.big(alvo.hp)
		else:
			barra_chefe.visible = false
			lbl_chefe_fase.text = ""
	else:
		lbl_chefe.text = ""
		barra_chefe.visible = false
		lbl_chefe_fase.text = ""
		barra_onda.add_theme_stylebox_override("fill", UI.caixa(UI.ACENTO, 3, 0))

	var torre: Dictionary = s["torre"]
	barra_vida.value = Big.frac(torre["vida"], torre["vida_max"])
	lbl_vida.text = "%s / %s" % [Fmt.big(torre["vida"]), Fmt.big(torre["vida_max"])]
	var tem_escudo: bool = not Big.is_zero(torre["escudo_max"])
	barra_escudo.visible = tem_escudo
	if tem_escudo:
		barra_escudo.value = Big.frac(torre["escudo"], torre["escudo_max"])

	lbl_nivel.text = "%s %d" % [Txt.t("nivel"), int(s["nivel"])]
	barra_xp.value = Economia.progresso_nivel(s)
	var pts := int(s["pontos_talento"])
	ic_pontos.visible = pts > 0
	aviso_pontos.text = ("%d" % pts) if pts > 0 else ""

	if Mecanicas.em_retomada(s):
		var r: Dictionary = s["retomada"]
		lbl_retomada.text = "%s ×%d  ·  %s: %s %d" % [Txt.t("retomada"), int(Mecanicas.RETOMADA_VELOCIDADE), Txt.t("alvo"), Txt.t("onda").to_lower(), int(r["alvo"])]
	else:
		lbl_retomada.text = ""

	var combo := int(s["combo"]["atual"])
	lbl_combo.text = ("%d×" % combo) if combo >= 5 else ""
	lbl_combo.add_theme_color_override("font_color", UI.OURO.lerp(UI.VERMELHO, clampf(float(combo) / 150.0, 0.0, 1.0)))

	lbl_dps.text = Txt.t("dps") + " ~%s" % Fmt.big(Big.mul_f(jogo.stats.b("dano"), jogo.stats.n("cadencia") * jogo.stats.n("multiplicador") * (1.0 + jogo.stats.n("critChance") * (jogo.stats.n("critDano") - 1.0)) * maxf(1.0, jogo.stats.n("projeteis"))))
	var vivos: int = jogo.arena.contagem_viva()
	var mult_combo := 1.0 + float(combo) * float(jogo.esp.get("comboBonus", Bal.COMBO_BONUS_POR))
	var mult_aglom := Mecanicas.fator_aglomeracao(vivos)
	var mult_total := mult_combo * mult_aglom
	lbl_ouro_mult.text = ("%s ×%.2f" % [Txt.t("m_ouro"), mult_total]) if mult_total > 1.02 else ""
	lbl_ouro_mult.add_theme_color_override("font_color", UI.OURO.lerp(UI.VERDE, clampf((mult_total - 1.0) / 2.0, 0.0, 1.0)))

	lbl_fps.text = Txt.f("hud_fps_inimigos", {"f": int(Engine.get_frames_per_second()), "n": jogo.arena.inimigos.size()}) if bool(Cfg.get_v("mostrar_fps", false)) else ""
	lbl_velocidade.text = "×%d" % int(jogo.velocidade)

	_atualizar_buffs()
	_atualizar_adaptacao()
	botoes_painel["talentos"].modulate = UI.OURO if pts > 0 else Color.WHITE
	# O mesmo tratamento para MELHORIAS — e este faltava.
	#
	# O jogo tinha exatamente uma pista persistente de "voce tem algo para
	# gastar", e ela era so para talento. Para OURO nao havia nada: o botao de
	# Melhorias nunca mudava de cor, e a unica vez que o jogo dizia "gaste" era
	# um balao de nove segundos por volta dos 50 s, que depois de visto some
	# para sempre. Como a torre atira sozinha, nada obrigava a reabrir o painel:
	# aos sete minutos o jogador passivo estava com milhares de ouro parado e o
	# mesmo dano do segundo zero. O brilho cresce conforme o ouro parado passa
	# do custo da melhoria mais barata, entao pisca discreto quando da para
	# comprar uma e fica evidente quando da para comprar muitas.
	_atualizar_brilho_melhorias()
	# O botão do Modo Infinito só existe depois que o nó do topo da árvore de
	# Éter é comprado: antes disso ele seria uma promessa vazia no rodapé.
	if b_infinito != null:
		b_infinito.visible = jogo.esp["desbloqueios"].has("modoInfinito")
		b_infinito.modulate = UI.ACENTO2 if bool(jogo.s.get("modo_infinito", false)) else Color.WHITE
	if b_farm != null:
		b_farm.visible = jogo.esp["desbloqueios"].has("modoFarm")
		b_farm.modulate = UI.OURO if bool(jogo.s["modo_farm"]) else Color.WHITE

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
	caixa_adapt.tooltip_text = Txt.t("hud_dica_adaptacao") if algum else ""

func _atualizar_buffs() -> void:
	var buffs: Array = jogo.s["buffs"]
	# recicla as caixas existentes; nunca reconstrói a árvore a cada tick
	while caixa_buffs.get_child_count() < buffs.size():
		var cx := UI.hbox(3)
		cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := UI.icone("estrela", UI.ACENTO, 14)
		cx.add_child(ic)
		cx.add_child(UI.rotulo("", 12, UI.TEXTO2))
		caixa_buffs.add_child(cx)
	for i in caixa_buffs.get_child_count():
		var cx2: Control = caixa_buffs.get_child(i)
		if i >= buffs.size():
			cx2.visible = false
			continue
		cx2.visible = true
		var b: Dictionary = buffs[i]
		var cor := Color.html(str(b.get("cor", "#ffffff")))
		var ic2: Control = cx2.get_child(0)
		ic2.configurar(str(b.get("icone", "estrela")), cor, 14)
		var l: Label = cx2.get_child(1)
		l.text = "%ds" % int(ceil(float(b["restante"])))
		l.add_theme_color_override("font_color", cor)
		# O tooltip mostrava a chave interna ("ganhoOuro"). data/stats.json já tem
		# o nome legível de cada atributo — é de lá que ele sai agora, junto com
		# o tamanho do efeito, que é a informação que o jogador realmente quer.
		cx2.tooltip_text = "%s — %s" % [str(b.get("fonte", "")), _descrever_buff(b)]

## Nome legível do atributo mais o tamanho do efeito ("Ganho de Ouro ×1,5").
func _descrever_buff(b: Dictionary) -> String:
	var chave := str(b.get("stat", ""))
	var def: Dictionary = Dados.stat_defs.get(chave, {})
	var nome := Ux.txt(def, "nome", Cfg.ingles()) if not def.is_empty() else chave
	var v := float(b.get("valor", 0.0))
	match str(b.get("tipo", "")):
		"mult": return "%s ×%s" % [nome, Fmt.num(v, 2)]
		"pct": return "%s %s%s" % [nome, "+" if v >= 0.0 else "", Fmt.pct(v, 0)]
		_: return "%s %s%s" % [nome, "+" if v >= 0.0 else "", Fmt.num(v, 2)]

## --------------------------------------------------------------- ações

func _alternar_velocidade() -> void:
	var teto := maxf(1.0, float(jogo.esp.get("velocidadeMax", 1.0)))
	var nova: float = float(jogo.velocidade) + 1.0
	if nova > teto:
		nova = 1.0
	jogo.definir_velocidade(nova)
	if teto <= 1.0:
		Bus.toast(Txt.t("hud_velocidade_trancada"), "info", "velocidade")

## Dizia "Jogo salvo" mesmo quando a gravação falhava — que é justamente a hora
## em que o jogador precisa saber a verdade.
func _salvar_agora() -> void:
	if jogo.salvar():
		Bus.toast(Txt.t("jogo_salvo"), "bom", "salvar")
	else:
		Bus.toast(Txt.t("save_falhou"), "ruim", "cadeado")

func _alternar_infinito() -> void:
	if not jogo.alternar_infinito():
		Bus.toast(Txt.t("hud_infinito_trancado"), "info", "cadeado")

func _alternar_farm() -> void:
	if not jogo.esp["desbloqueios"].has("modoFarm"):
		Bus.toast(Txt.t("hud_farm_trancado"), "info", "cadeado")
		return
	var ligou: bool = jogo.alternar_farm()
	jogo.marcar_sujo()
	Bus.ui_atualizar.emit(false)
	if ligou:
		Bus.toast(Txt.f("hud_farm_ligado", {"n": int(jogo.s["onda_farm"])}), "bom", "ampulheta")
	else:
		Bus.toast(Txt.t("hud_farm_desligado"), "info", "ampulheta")

func _alternar_mira() -> void:
	var modos: Array = TorreSim.MODOS_MIRA
	var atual := str(jogo.s["torre"]["mira"])
	var i := modos.find(atual)
	var novo := str(modos[(i + 1) % modos.size()])
	jogo.definir_mira(novo)
	# O aviso mostrava o identificador interno ("avancado"). Agora mostra o nome
	# do modo, e o botão passa a dizer em qual modo você está sem precisar clicar.
	Bus.toast("%s: %s" % [Txt.t("mira"), Txt.t("mira_" + novo)], "info", "alvo")
	_atualizar_dica_mira()

## Retraduz o que nasceu em `_construir()` e não passa pelo ciclo de update.
func _retraduzir() -> void:
	for id in botoes_painel.keys():
		var b: Button = botoes_painel[id]
		if not is_instance_valid(b) or not b.has_meta("chave_dica"):
			continue
		b.tooltip_text = Txt.t(str(b.get_meta("chave_dica"))) + str(b.get_meta("tecla_dica"))
	_atualizar_dica_mira()
	if b_infinito != null and is_instance_valid(b_infinito):
		b_infinito.tooltip_text = Txt.t("hud_infinito_dica")
	if b_farm != null and is_instance_valid(b_farm):
		b_farm.tooltip_text = Txt.t("hud_farm_dica")

func _atualizar_dica_mira() -> void:
	if b_mira == null:
		return
	b_mira.tooltip_text = "%s: %s" % [Txt.t("mira"), Txt.t("mira_" + str(jogo.s["torre"]["mira"]))]

func _pulsar_nivel() -> void:
	UI.pulsar(lbl_nivel, UI.OURO)

func _ao_hab_pronta(id: String) -> void:
	if botoes_hab.has(id):
		UI.saltar(botoes_hab[id]["botao"], 1.2)

func _ao_onda(_n: int, eh_chefe: bool) -> void:
	if eh_chefe:
		UI.saltar(lbl_onda, 1.3)
