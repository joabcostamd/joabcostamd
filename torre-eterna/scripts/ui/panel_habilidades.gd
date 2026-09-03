extends "res://scripts/ui/panel_base.gd"

## Painel de HABILIDADES ativas — o que você aperta quando a torre está gritando.
## Mostra cada habilidade com os números já resolvidos no nível atual e no próximo,
## recarga efetiva (com a sua redução), usos e a barra de recarga em tempo real.

var lbl_gemas: Label
var check_auto: CheckButton
var cartoes := {}           # id -> refs dos controles

func configurar() -> void:
	titulo_texto = "Habilidades"
	titulo_icone = "raio"
	largura = 880.0
	altura = 660.0
	intervalo = 0.08

func montar(c: VBoxContainer) -> void:
	var topo := UI.hbox(8)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	topo.add_child(ic)
	ic.configurar("gema", UI.MOEDA_COR["gemas"], 20)
	lbl_gemas = UI.rotulo("0", 19, UI.MOEDA_COR["gemas"])
	topo.add_child(lbl_gemas)
	topo.add_child(UI.rotulo("gemas", 13, UI.TEXTO2))
	topo.add_child(UI.espacador())
	topo.add_child(UI.rotulo("cada nível encurta a recarga em 3% (teto de -40%)", 12, UI.TEXTO3))

	check_auto = CheckButton.new()
	check_auto.text = "Auto"
	check_auto.tooltip_text = "Usa as habilidades sozinho, com bom senso.\nDesbloqueado na árvore de prestígio."
	check_auto.button_pressed = bool(jogo.s["auto"]["habilidades"])
	check_auto.toggled.connect(func(v):
		if not jogo.esp["desbloqueios"].has("autoHabilidade"):
			check_auto.button_pressed = false
			Bus.toast("Requer o nó 'Piloto Automático' na árvore de prestígio", "info")
			return
		jogo.s["auto"]["habilidades"] = v)
	topo.add_child(check_auto)
	c.add_child(topo)

	var rolagem := UI.scroll()
	var lista := UI.vbox(7)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(lista)
	c.add_child(rolagem)

	if Dados.habilidades.is_empty():
		lista.add_child(UI.rotulo("Nenhuma habilidade catalogada — a torre está muda.", 14, UI.TEXTO3))
		return
	for item in Dados.habilidades:
		var def: Dictionary = item
		lista.add_child(_cartao(def))

## ---------------------------------------------------------------- cartão

func _cartao(def: Dictionary) -> PanelContainer:
	var id := str(def.get("id", ""))
	var cor := Color.html(str(def.get("cor", "#38bdf8")))

	var cx := PanelContainer.new()
	cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.12), 10, 1, UI.BORDA))
	var h := UI.hbox(12)
	cx.add_child(h)

	# --- selo do ícone ---
	var selo := PanelContainer.new()
	selo.add_theme_stylebox_override("panel", UI.caixa(cor.darkened(0.78), 12, 1, cor.darkened(0.35)))
	selo.custom_minimum_size = Vector2(66, 66)
	selo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selo.add_child(ic)
	ic.configurar(Icone.da_habilidade(id), cor, 38)
	h.add_child(selo)

	# --- miolo ---
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)

	var cab := UI.hbox(8)
	var nome := UI.rotulo(txt(def, "nome"), 17, cor)
	cab.add_child(nome)
	var tecla := str(def.get("tecla", ""))
	if tecla != "":
		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", UI.caixa(UI.FUNDO2, 6, 1, UI.BORDA_FORTE))
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.tooltip_text = "Atalho de teclado: %s" % tecla
		var lt := UI.rotulo(tecla, 12, UI.TEXTO2)
		badge.add_child(lt)
		cab.add_child(badge)
	var lbl_nivel := UI.rotulo("", 13, UI.TEXTO2)
	cab.add_child(lbl_nivel)
	cab.add_child(UI.espacador())
	var lbl_usos := UI.rotulo("", 12, UI.TEXTO3)
	cab.add_child(lbl_usos)
	v.add_child(cab)

	var lbl_agora := UI.rotulo("", 13, UI.TEXTO2)
	lbl_agora.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_agora.custom_minimum_size.x = 400
	v.add_child(lbl_agora)

	var lbl_prox := UI.rotulo("", 12, UI.VERDE)
	lbl_prox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_prox.custom_minimum_size.x = 400
	v.add_child(lbl_prox)

	var linha_num := UI.hbox(12)
	var lbl_cd := UI.rotulo("", 12, UI.TEXTO3)
	lbl_cd.tooltip_text = "Recarga já com a sua Redução de Recarga aplicada."
	linha_num.add_child(lbl_cd)
	var lbl_dur := UI.rotulo("", 12, UI.TEXTO3)
	linha_num.add_child(lbl_dur)
	v.add_child(linha_num)

	var barra := UI.barra(cor, 7)
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.tooltip_text = "Recarga em tempo real."
	var linha_barra := UI.hbox(8)
	linha_barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha_barra.add_child(barra)
	var lbl_pronta := UI.rotulo("", 12, UI.TEXTO3)
	lbl_pronta.custom_minimum_size.x = 76
	lbl_pronta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	linha_barra.add_child(lbl_pronta)
	v.add_child(linha_barra)

	# --- direita: melhoria ou cadeado ---
	var dir := UI.vbox(3)
	dir.alignment = BoxContainer.ALIGNMENT_CENTER
	dir.custom_minimum_size.x = 168
	h.add_child(dir)

	var caixa_bt := UI.vbox(3)
	var bt := UI.botao("Melhorar", func(): _melhorar(id))
	bt.custom_minimum_size = Vector2(160, 40)
	caixa_bt.add_child(bt)
	var caixa_custo := UI.hbox(0)
	caixa_custo.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa_bt.add_child(caixa_custo)
	dir.add_child(caixa_bt)

	var caixa_lock := UI.hbox(6)
	caixa_lock.alignment = BoxContainer.ALIGNMENT_CENTER
	var ic_lock := Control.new()
	ic_lock.set_script(load("res://scripts/ui/icone_control.gd"))
	caixa_lock.add_child(ic_lock)
	ic_lock.configurar("cadeado", UI.TEXTO3, 18)
	var lbl_lock := UI.rotulo("", 13, UI.TEXTO3)
	caixa_lock.add_child(lbl_lock)
	caixa_lock.visible = false
	dir.add_child(caixa_lock)

	cartoes[id] = {
		"def": def, "cor": cor, "caixa": cx, "icone": ic, "selo": selo, "nome": nome,
		"nivel": lbl_nivel, "usos": lbl_usos, "agora": lbl_agora, "prox": lbl_prox,
		"cd": lbl_cd, "dur": lbl_dur, "barra": barra, "pronta": lbl_pronta,
		"botao": bt, "custo": caixa_custo, "caixa_bt": caixa_bt, "lock": caixa_lock,
		"linha_barra": linha_barra,
		"lock_txt": lbl_lock, "estado": "",
	}
	return cx

## ---------------------------------------------------------------- compra

func _melhorar(id: String) -> void:
	var r: Dictionary = cartoes.get(id, {})
	if r.is_empty():
		return
	var def: Dictionary = r["def"]
	var h: Dictionary = GameState.hab(jogo.s, id)
	if not bool(h["desbloqueada"]):
		Bus.toast("Ainda trancada", "info")
		return
	if int(h["nivel"]) >= Dados.nivel_max_habilidade:
		Bus.toast("%s já está no máximo" % txt(def, "nome"), "info")
		return
	if jogo.melhorar_habilidade(id):
		UI.pulsar(r["caixa"], r["cor"])
		UI.saltar(r["selo"], 1.18)
		Bus.toast("%s  Nv %d" % [txt(def, "nome"), int(h["nivel"])], "bom")
		atualizar()
	else:
		Bus.toast("Gemas insuficientes", "ruim")

## ------------------------------------------------------------ atualização

func atualizar() -> void:
	if jogo == null or lbl_gemas == null:
		return
	lbl_gemas.text = Fmt.big(jogo.s["moedas"]["gemas"])
	check_auto.button_pressed = bool(jogo.s["auto"]["habilidades"])
	for chave in cartoes.keys():
		var r: Dictionary = cartoes[str(chave)]
		_atualizar_cartao(r)

func _atualizar_cartao(r: Dictionary) -> void:
	var def: Dictionary = r["def"]
	var id := str(def.get("id", ""))
	var cor: Color = r["cor"]
	var h: Dictionary = GameState.hab(jogo.s, id)
	var aberta := bool(h["desbloqueada"])
	var nivel := int(h["nivel"])
	var maxn := int(Dados.nivel_max_habilidade)
	var no_teto := nivel >= maxn
	var custo := Habilidades.custo_melhoria(def, nivel)
	var pode := aberta and not no_teto and Big.gte(jogo.s["moedas"]["gemas"], Big.from(custo))

	# --- barra de recarga (sempre, é tempo real) ---
	var barra: ProgressBar = r["barra"]
	var cd := float(h["cd"])
	var cd_max := maxf(0.001, float(h["cd_max"]))
	var lbl_pronta: Label = r["pronta"]
	var linha_barra: HBoxContainer = r["linha_barra"]
	linha_barra.visible = aberta
	if not aberta:
		barra.value = 0.0
		lbl_pronta.text = ""
	elif cd <= 0.0:
		barra.value = 1.0
		lbl_pronta.text = "PRONTA"
		lbl_pronta.add_theme_color_override("font_color", UI.VERDE)
	else:
		barra.value = clampf(1.0 - cd / cd_max, 0.0, 1.0)
		lbl_pronta.text = "%ss" % Fmt.num(cd, 1)
		lbl_pronta.add_theme_color_override("font_color", UI.TEXTO2)

	var lbl_usos: Label = r["usos"]
	var usos := int(h["usos"])
	lbl_usos.text = ("%s uso" % Fmt.inteiro(usos) if usos == 1 else "%s usos" % Fmt.inteiro(usos)) if aberta else ""

	# --- o resto só muda quando o estado muda ---
	var estado := "%d|%d|%d|%d" % [nivel, int(aberta), int(pode), int(custo)]
	if str(r["estado"]) == estado:
		return
	r["estado"] = estado

	var cx: PanelContainer = r["caixa"]
	var nome: Label = r["nome"]
	var ic: Control = r["icone"]
	var selo: PanelContainer = r["selo"]
	var caixa_bt: VBoxContainer = r["caixa_bt"]
	var lock: HBoxContainer = r["lock"]
	var bt: Button = r["botao"]

	caixa_bt.visible = aberta
	lock.visible = not aberta

	if not aberta:
		var onda_req := int(def.get("requer", {}).get("onda", 1))
		var faltam: int = maxi(0, onda_req - int(jogo.s["onda_maxima_global"]))
		cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL.darkened(0.25), 10, 1, UI.BORDA.darkened(0.3)))
		selo.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL.darkened(0.4), 12, 1, UI.BORDA.darkened(0.3)))
		ic.configurar(Icone.da_habilidade(id), UI.TEXTO3, 38)
		nome.add_theme_color_override("font_color", UI.TEXTO3)
		r["nivel"].text = ""
		r["agora"].text = "Desbloqueia na onda %d." % onda_req
		r["agora"].add_theme_color_override("font_color", UI.TEXTO3)
		r["prox"].text = ("Faltam %d onda%s — continue subindo." % [faltam, "" if faltam == 1 else "s"]) if faltam > 0 else "Requisito cumprido — abre na virada da onda."
		r["prox"].add_theme_color_override("font_color", UI.TEXTO3)
		r["cd"].text = "Recarga base %ss" % Fmt.num(float(def.get("cd", 0.0)), 0)
		r["dur"].text = ""
		r["lock_txt"].text = "Onda %d" % onda_req
		cx.tooltip_text = "%s\n%s\nAinda selada." % [txt(def, "nome"), txt(def, "desc")]
		return

	cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.12), 10, 1, cor.darkened(0.55)))
	selo.add_theme_stylebox_override("panel", UI.caixa(cor.darkened(0.78), 12, 1, cor.darkened(0.3)))
	ic.configurar(Icone.da_habilidade(id), cor, 38)
	nome.add_theme_color_override("font_color", cor)

	var lbl_nivel: Label = r["nivel"]
	lbl_nivel.text = "Nv %d/%d" % [nivel, maxn]
	lbl_nivel.add_theme_color_override("font_color", UI.OURO if no_teto else UI.TEXTO2)

	var agora: Label = r["agora"]
	agora.text = _desc_nivel(def, nivel)
	agora.add_theme_color_override("font_color", UI.TEXTO2)

	var prox: Label = r["prox"]
	if no_teto:
		prox.text = "No máximo. Não dá pra espremer mais nada."
		prox.add_theme_color_override("font_color", UI.OURO)
	else:
		prox.text = "Nv %d:  %s" % [nivel + 1, _delta_nivel(def, nivel)]
		prox.add_theme_color_override("font_color", UI.VERDE)

	var cdr := float(jogo.stats.n("cdr"))
	var cd_agora := Habilidades.cd_efetivo(def, nivel, cdr)
	var texto_cd := "Recarga %ss" % Fmt.num(cd_agora, 1)
	if not no_teto:
		texto_cd += "  ->  %ss" % Fmt.num(Habilidades.cd_efetivo(def, nivel + 1, cdr), 1)
	r["cd"].text = texto_cd

	var mult_dur := float(jogo.stats.n("duracaoHab"))
	var dur := Habilidades.duracao(def, nivel, mult_dur)
	var lbl_dur: Label = r["dur"]
	lbl_dur.text = "Duração %ss" % Fmt.num(dur, 1) if dur > 0.0 else "Instantânea"

	var caixa_custo: HBoxContainer = r["custo"]
	for n in caixa_custo.get_children():
		n.queue_free()
	if no_teto:
		bt.text = "MÁXIMO"
		bt.disabled = true
	else:
		bt.text = "Melhorar"
		bt.disabled = not pode
		bt.tooltip_text = "Sobe %s para o nível %d por %s gemas." % [txt(def, "nome"), nivel + 1, Fmt.num(custo, 0)]
		caixa_custo.add_child(custo_label("gemas", Big.from(custo), pode))

	cx.tooltip_text = "%s\n%s\nTecla %s  ·  %s" % [
		txt(def, "nome"), txt(def, "desc"), str(def.get("tecla", "-")),
		"pronta" if cd <= 0.0 else "recarregando",
	]

## O que muda ao subir um nível, em números (nível atual -> próximo).
func _delta_nivel(def: Dictionary, nivel: int) -> String:
	var partes: Array = []
	var esc = def.get("escala", {})
	if esc is Dictionary:
		for chave in esc.keys():
			var k := str(chave)
			var a := Habilidades.valor(def, k, nivel)
			var b := Habilidades.valor(def, k, nivel + 1)
			if k == "dur":
				var m := float(jogo.stats.n("duracaoHab"))
				a = Habilidades.duracao(def, nivel, m)
				b = Habilidades.duracao(def, nivel + 1, m)
			if absf(b - a) < 0.001:
				continue
			partes.append("%s %s -> %s" % [_rotulo_escala(k), Fmt.num(a, 1), Fmt.num(b, 1)])
	if partes.is_empty():
		var cdr := float(jogo.stats.n("cdr"))
		partes.append("recarga %ss -> %ss" % [
			Fmt.num(Habilidades.cd_efetivo(def, nivel, cdr), 1),
			Fmt.num(Habilidades.cd_efetivo(def, nivel + 1, cdr), 1)])
	return "  ·  ".join(partes)

func _rotulo_escala(chave: String) -> String:
	match chave:
		"dano": return "dano"
		"cad": return "cadência"
		"dur": return "duração"
		"mult": return "multiplicador"
		"qtd": return "quantidade"
		"cura": return "cura"
	return chave

## Descrição com os {marcadores} trocados pelos números daquele nível.
func _desc_nivel(def: Dictionary, nivel: int) -> String:
	var s := txt(def, "desc")
	var esc = def.get("escala", {})
	if esc is Dictionary:
		for chave in esc.keys():
			var k := str(chave)
			if k == "dur":
				continue
			s = s.replace("{%s}" % k, Fmt.num(Habilidades.valor(def, k, nivel), 1))
	if s.contains("{dur}"):
		var dur := Habilidades.duracao(def, nivel, float(jogo.stats.n("duracaoHab")))
		s = s.replace("{dur}", Fmt.num(dur, 1))
	return s
