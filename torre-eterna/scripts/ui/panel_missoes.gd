extends "res://scripts/ui/panel_base.gd"

## Painel de MISSÕES E TEMPORADA — a agenda burocrática do fim do mundo.
##
## Diárias e semanais com barra de progresso e botão de coleta, a sequência
## de sete dias (voltar todo dia rende XP de temporada extra) e o passe de
## temporada: uma trilha rolável de 40 níveis com o nível atual em destaque.

const SEG_DIA := 86400
const SEG_SEMANA := 604800

var conteudo: VBoxContainer
var lbl_diario: Label
var lbl_semanal: Label
var lbl_vazio_d: Label
var lbl_vazio_s: Label
var caixa_diarias: VBoxContainer
var caixa_semanais: VBoxContainer
var caixa_sequencia: HBoxContainer
var lbl_sequencia: Label
var trilha: HBoxContainer
var rolagem_trilha: ScrollContainer
var lbl_nivel: Label
var lbl_xp: Label
var barra_xp: ProgressBar

var missoes: Dictionary = {}     # "grupo:indice" -> registro
var dias: Dictionary = {}        # dia -> registro
var niveis: Dictionary = {}      # nivel -> registro
var assinatura := ""

func configurar() -> void:
	titulo_texto = "Missões"
	titulo_icone = "missao"
	largura = 1020.0
	altura = 690.0
	intervalo = 0.3

# ------------------------------------------------------------------ montagem

func montar(c: VBoxContainer) -> void:
	var rolagem := UI.scroll()
	c.add_child(rolagem)
	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_right", 12)
	margem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(margem)
	conteudo = UI.vbox(10)
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margem.add_child(conteudo)

	# ---------------------------------------------------------- diárias
	lbl_diario = UI.rotulo("", 13, UI.TEXTO2)
	conteudo.add_child(_secao("Diárias", "ampulheta", UI.ACENTO,
		"Três contratos por dia. O relógio não perdoa, o Enxame também não.", lbl_diario))
	caixa_diarias = UI.vbox(6)
	conteudo.add_child(caixa_diarias)
	lbl_vazio_d = UI.rotulo("Nenhuma missão diária no quadro — volte depois do próximo reset.", 13, UI.TEXTO3)
	conteudo.add_child(lbl_vazio_d)

	# ------------------------------------------------------- sequência
	lbl_sequencia = UI.rotulo("", 13, UI.TEXTO2)
	conteudo.add_child(_secao("Sequência diária", "estrela", UI.OURO,
		"Aparecer todo dia multiplica o XP de temporada. Faltar zera a contagem.", lbl_sequencia))
	var cx_seq := UI.painel(UI.PAINEL2.darkened(0.15), 12)
	caixa_sequencia = UI.hbox(6)
	caixa_sequencia.alignment = BoxContainer.ALIGNMENT_CENTER
	cx_seq.add_child(caixa_sequencia)
	conteudo.add_child(cx_seq)
	_montar_sequencia()

	# --------------------------------------------------------- semanais
	lbl_semanal = UI.rotulo("", 13, UI.TEXTO2)
	conteudo.add_child(_secao("Semanais", "desafio", UI.ACENTO2,
		"Contratos longos, pagamento gordo. Sete dias para cumprir.", lbl_semanal))
	caixa_semanais = UI.vbox(6)
	conteudo.add_child(caixa_semanais)
	lbl_vazio_s = UI.rotulo("Nenhuma missão semanal no quadro.", 13, UI.TEXTO3)
	conteudo.add_child(lbl_vazio_s)

	# -------------------------------------------------------- temporada
	conteudo.add_child(_secao("Passe de Temporada", "prestigio", UI.ROSA,
		"XP vem de missões cumpridas. Cada nível libera uma recompensa — e ela não se coleta sozinha.", null))
	var cabeca := UI.painel(UI.PAINEL2.darkened(0.1), 12)
	var ch := UI.hbox(14)
	cabeca.add_child(ch)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	ch.add_child(ic)
	ic.configurar("estrela", UI.ROSA, 30)
	var cv := UI.vbox(3)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nivel = UI.rotulo("Nível 0", 18, UI.TEXTO)
	cv.add_child(lbl_nivel)
	barra_xp = UI.barra(UI.ROSA, 9)
	barra_xp.custom_minimum_size.x = 420
	barra_xp.tooltip_text = "XP acumulado rumo ao próximo nível da temporada."
	cv.add_child(barra_xp)
	ch.add_child(cv)
	lbl_xp = UI.rotulo("", 14, UI.TEXTO2)
	lbl_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ch.add_child(lbl_xp)
	conteudo.add_child(cabeca)

	rolagem_trilha = ScrollContainer.new()
	rolagem_trilha.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem_trilha.custom_minimum_size.y = 176
	trilha = UI.hbox(8)
	rolagem_trilha.add_child(trilha)
	conteudo.add_child(rolagem_trilha)
	_montar_trilha()

	_reconstruir_missoes()
	call_deferred("_centralizar_trilha")

func _secao(titulo: String, icone: String, cor: Color, dica: String, extra: Label) -> HBoxContainer:
	var h := UI.hbox(8)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(icone, cor, 20)
	var l := UI.rotulo(titulo, 18, cor)
	l.tooltip_text = dica
	h.add_child(l)
	var sub := UI.rotulo(dica, 12, UI.TEXTO3)
	h.add_child(sub)
	h.add_child(UI.espacador())
	if extra != null:
		h.add_child(extra)
	return h

# --------------------------------------------------------------- missões

func _assinatura_atual() -> String:
	var m: Dictionary = jogo.s["missoes"]
	var partes: Array = []
	for grupo in ["diarias", "semanais"]:
		for item in m[grupo]:
			var mi: Dictionary = item
			partes.append("%s:%s" % [grupo, str(mi["id"])])
	partes.append(str(m["reset_diario"]))
	partes.append(str(m["reset_semanal"]))
	return "|".join(partes)

func _reconstruir_missoes() -> void:
	missoes.clear()
	for caixa in [caixa_diarias, caixa_semanais]:
		for n in caixa.get_children():
			caixa.remove_child(n)
			n.queue_free()
	var m: Dictionary = jogo.s["missoes"]
	for i in m["diarias"].size():
		_linha_missao("diarias", i)
	for i in m["semanais"].size():
		_linha_missao("semanais", i)
	lbl_vazio_d.visible = m["diarias"].is_empty()
	lbl_vazio_s.visible = m["semanais"].is_empty()
	assinatura = _assinatura_atual()

func _linha_missao(grupo: String, indice: int) -> void:
	var mi: Dictionary = jogo.s["missoes"][grupo][indice]
	var def: Dictionary = Dados.missao_por_id.get(str(mi["id"]), {})
	var cor := UI.ACENTO if grupo == "diarias" else UI.ACENTO2
	var alvo: float = maxf(1.0, float(mi["alvo"]))
	var l := linha(_icone_de(def), cor)

	var nome := UI.rotulo(txt(def, "nome"), 16, UI.TEXTO)
	l["textos"].add_child(nome)
	var meta_tipo := str(def.get("meta", {}).get("tipo", ""))
	var alvo_txt := Fmt.inteiro(int(round(alvo / 60.0))) if meta_tipo == "tempoTotal" else Fmt.inteiro(int(round(alvo)))
	var desc := UI.rotulo(txt(def, "desc").replace("{v}", alvo_txt), 12, UI.TEXTO2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 460
	l["textos"].add_child(desc)

	var lp := UI.hbox(8)
	var barra := UI.barra(cor, 8)
	barra.custom_minimum_size.x = 230
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lp.add_child(barra)
	var lbl_prog := UI.rotulo("", 12, UI.TEXTO3)
	lp.add_child(lbl_prog)
	lp.add_child(UI.rotulo("·", 12, UI.BORDA_FORTE))
	var rec: Dictionary = def.get("recompensa", {})
	var ic_rec := Control.new()
	ic_rec.set_script(load("res://scripts/ui/icone_control.gd"))
	lp.add_child(ic_rec)
	ic_rec.configurar(_icone_recompensa(rec), _cor_recompensa(rec), 14)
	lp.add_child(UI.rotulo(_texto_recompensa(rec), 12, _cor_recompensa(rec)))
	lp.add_child(UI.rotulo("·", 12, UI.BORDA_FORTE))
	var lxp := UI.rotulo("+%d XP de temporada" % int(def.get("xpTemporada", 10)), 12, UI.ROSA)
	lxp.tooltip_text = "Coletar esta missão empurra o passe de temporada."
	lp.add_child(lxp)
	l["textos"].add_child(lp)

	var b := UI.botao("Coletar", func(): _coletar(grupo, indice))
	b.custom_minimum_size = Vector2(126, 44)
	l["direita"].add_child(b)

	if grupo == "diarias":
		caixa_diarias.add_child(l["caixa"])
	else:
		caixa_semanais.add_child(l["caixa"])
	missoes["%s:%d" % [grupo, indice]] = {
		"grupo": grupo, "indice": indice, "def": def, "caixa": l["caixa"],
		"barra": barra, "prog": lbl_prog, "botao": b, "cor": cor,
	}

func _coletar(grupo: String, indice: int) -> void:
	if not Progresso.coletar_missao(jogo, grupo, indice):
		Bus.toast("Essa missão ainda não está pronta", "info")
		return
	jogo.marcar_sujo()
	var chave := "%s:%d" % [grupo, indice]
	if missoes.has(chave):
		var reg: Dictionary = missoes[chave]
		var cx: PanelContainer = reg["caixa"]
		UI.pulsar(cx, UI.VERDE)
	Bus.toast("Missão coletada", "bom")
	atualizar()

# ------------------------------------------------------------- sequência

func _montar_sequencia() -> void:
	dias.clear()
	for item in Dados.sequencia_diaria:
		var d: Dictionary = item
		var dia := int(d.get("dia", 0))
		var destaque := bool(d.get("destaque", false))
		var cx := UI.painel(UI.PAINEL2.darkened(0.25), 10)
		cx.custom_minimum_size = Vector2(122, 0)
		var v := UI.vbox(3)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		cx.add_child(v)

		var lbl_dia := UI.rotulo("DIA %d" % dia, 12, UI.TEXTO3)
		lbl_dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lbl_dia)

		var linha_ic := UI.hbox(0)
		linha_ic.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := Control.new()
		ic.set_script(load("res://scripts/ui/icone_control.gd"))
		linha_ic.add_child(ic)
		var rec: Dictionary = d.get("recompensa", {})
		ic.configurar(_icone_recompensa(rec), UI.TEXTO3, 30 if destaque else 24)
		v.add_child(linha_ic)

		var lbl_rec := UI.rotulo(_texto_recompensa(rec), 11, UI.TEXTO3)
		lbl_rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lbl_rec)

		var mult := float(d.get("multXP", 1.0))
		var lbl_mult := UI.rotulo("XP ×%s" % Fmt.num(mult, 2), 11, UI.TEXTO3)
		lbl_mult.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lbl_mult)

		cx.tooltip_text = "%s — %s" % [txt(d, "nome"), txt(d, "desc")]
		caixa_sequencia.add_child(cx)
		dias[dia] = {"caixa": cx, "dia": lbl_dia, "icone": ic, "rec": lbl_rec,
			"mult": lbl_mult, "destaque": destaque, "recompensa": rec}

func _dia_da_sequencia() -> int:
	var seq := int(jogo.s["missoes"]["sequencia"])
	if seq <= 0:
		return 0
	var d := ((seq - 1) % 7) + 1
	return d

# -------------------------------------------------------------- trilha

func _montar_trilha() -> void:
	niveis.clear()
	for item in Dados.temporada:
		var r: Dictionary = item
		var nivel := int(r.get("nivel", 0))
		var destaque := bool(r.get("destaque", false))
		var cx := UI.painel(UI.PAINEL2.darkened(0.25), 10)
		cx.custom_minimum_size = Vector2(118 if destaque else 96, 150 if destaque else 132)
		var v := UI.vbox(3)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cx.add_child(v)

		var lbl_nv := UI.rotulo("NV %d" % nivel, 12, UI.TEXTO3)
		lbl_nv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lbl_nv)

		var lic := UI.hbox(0)
		lic.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := Control.new()
		ic.set_script(load("res://scripts/ui/icone_control.gd"))
		lic.add_child(ic)
		var rec: Dictionary = r.get("recompensa", {})
		ic.configurar(_icone_recompensa(rec), UI.TEXTO3, 34 if destaque else 26)
		v.add_child(lic)

		var lbl_rec := UI.rotulo(_texto_recompensa(rec), 11, UI.TEXTO3)
		lbl_rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_rec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_rec.custom_minimum_size.x = 104 if destaque else 84
		v.add_child(lbl_rec)

		v.add_child(UI.espacador(0, false))
		var b := UI.botao("Coletar", func(): _coletar_nivel(nivel))
		b.custom_minimum_size = Vector2(0, 26)
		b.add_theme_font_size_override("font_size", 12)
		v.add_child(b)
		var lbl_estado := UI.rotulo("", 11, UI.TEXTO3)
		lbl_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lbl_estado)

		cx.tooltip_text = "Nível %d — %s%s" % [nivel, txt(r, "nome"),
			"  (recompensa de destaque)" if destaque else ""]
		trilha.add_child(cx)
		niveis[nivel] = {"caixa": cx, "nv": lbl_nv, "icone": ic, "rec": lbl_rec,
			"botao": b, "estado": lbl_estado, "destaque": destaque, "recompensa": rec}

func _coletar_nivel(nivel: int) -> void:
	if not Progresso.coletar_temporada(jogo, nivel):
		Bus.toast("Nível %d ainda não liberado" % nivel, "info")
		return
	jogo.marcar_sujo()
	if niveis.has(nivel):
		var reg: Dictionary = niveis[nivel]
		var cx: PanelContainer = reg["caixa"]
		UI.pulsar(cx, UI.VERDE)
	Bus.toast("Recompensa de temporada coletada", "bom")
	atualizar()

func _centralizar_trilha() -> void:
	if rolagem_trilha == null:
		return
	var t: Dictionary = jogo.s["temporada"]
	var nivel := int(t["nivel"])
	if not niveis.has(maxi(1, nivel)):
		return
	var reg: Dictionary = niveis[maxi(1, nivel)]
	var cx: PanelContainer = reg["caixa"]
	rolagem_trilha.scroll_horizontal = int(maxf(0.0, cx.position.x - 330.0))

# ---------------------------------------------------------- atualização

func atualizar() -> void:
	if jogo == null or lbl_diario == null:
		return
	if _assinatura_atual() != assinatura:
		_reconstruir_missoes()

	var m: Dictionary = jogo.s["missoes"]
	var agora := Time.get_unix_time_from_system()
	var falta_d := float(int(m["reset_diario"]) + SEG_DIA) - agora
	var falta_s := float(int(m["reset_semanal"]) + SEG_SEMANA) - agora
	lbl_diario.text = "Renova em %s" % Ux.tempo_curto(maxf(0.0, falta_d))
	lbl_diario.tooltip_text = "Quando o prazo estoura, três contratos novos entram no lugar."
	lbl_semanal.text = "Renova em %s" % Ux.tempo_curto(maxf(0.0, falta_s))
	lbl_semanal.tooltip_text = "Missões semanais são sorteadas de novo a cada sete dias."

	_atualizar_missoes()
	_atualizar_sequencia()
	_atualizar_temporada()

func _atualizar_missoes() -> void:
	for chave in missoes.keys():
		var reg: Dictionary = missoes[chave]
		var grupo := str(reg["grupo"])
		var indice := int(reg["indice"])
		var lista: Array = jogo.s["missoes"][grupo]
		if indice >= lista.size():
			continue
		var mi: Dictionary = lista[indice]
		var def: Dictionary = reg["def"]
		var meta: Dictionary = def.get("meta", {})
		var alvo: float = maxf(1.0, float(mi["alvo"]))
		var atual: float = Progresso.valor_cond(jogo.s, str(meta.get("tipo", "")), str(meta.get("chave", "")))
		var feito := clampf(atual - float(mi["base"]), 0.0, alvo)
		var f := Progresso.progresso_missao(jogo.s, mi)
		var pronta := bool(mi["pronta"])
		var coletada := bool(mi["coletada"])

		var barra: ProgressBar = reg["barra"]
		barra.value = 1.0 if pronta else f
		var lbl_prog: Label = reg["prog"]
		var tipo := str(meta.get("tipo", ""))
		lbl_prog.text = "%s / %s" % [_num(alvo if pronta else feito, tipo), _num(alvo, tipo)]
		lbl_prog.add_theme_color_override("font_color", UI.VERDE if pronta else UI.TEXTO3)

		var b: Button = reg["botao"]
		b.disabled = coletada or not pronta
		if coletada:
			b.text = "Coletado"
			b.tooltip_text = "Já pago. Volte amanhã."
		elif pronta:
			b.text = "Coletar"
			b.tooltip_text = "Recompensa pronta para retirada."
		else:
			b.text = "Em curso"
			b.tooltip_text = "Continue jogando: %s" % Fmt.pct(f)

		var cx: PanelContainer = reg["caixa"]
		var cor: Color = reg["cor"]
		if coletada:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.35), 10, 1, UI.BORDA.darkened(0.2)))
		elif pronta:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.lerp(UI.VERDE, 0.1), 10, 2, UI.VERDE))
		else:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.12), 10, 1, cor.darkened(0.45)))

func _atualizar_sequencia() -> void:
	var seq := int(jogo.s["missoes"]["sequencia"])
	var hoje := _dia_da_sequencia()
	if seq <= 0:
		lbl_sequencia.text = "Nenhum dia registrado ainda"
	else:
		lbl_sequencia.text = "1 dia seguido" if seq == 1 else "%d dias seguidos" % seq
	for dia in dias.keys():
		var reg: Dictionary = dias[dia]
		var d := int(dia)
		var cx: PanelContainer = reg["caixa"]
		var ic: Control = reg["icone"]
		var lbl_dia: Label = reg["dia"]
		var lbl_rec: Label = reg["rec"]
		var lbl_mult: Label = reg["mult"]
		var rec: Dictionary = reg["recompensa"]
		var tam: float = 30.0 if bool(reg["destaque"]) else 24.0
		if d == hoje:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.lerp(UI.OURO, 0.12), 10, 2, UI.OURO))
			ic.configurar(_icone_recompensa(rec), UI.OURO, tam)
			lbl_dia.text = "HOJE"
			lbl_dia.add_theme_color_override("font_color", UI.OURO)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO)
			lbl_mult.add_theme_color_override("font_color", UI.OURO)
		elif d < hoje:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.1), 10, 1, UI.VERDE.darkened(0.4)))
			ic.configurar(_icone_recompensa(rec), UI.VERDE.darkened(0.15), tam)
			lbl_dia.text = "DIA %d" % d
			lbl_dia.add_theme_color_override("font_color", UI.VERDE)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO2)
			lbl_mult.add_theme_color_override("font_color", UI.TEXTO2)
		else:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.3), 10, 1, UI.BORDA.darkened(0.25)))
			ic.configurar(_icone_recompensa(rec), UI.TEXTO3, tam)
			lbl_dia.text = "DIA %d" % d
			lbl_dia.add_theme_color_override("font_color", UI.TEXTO3)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO3)
			lbl_mult.add_theme_color_override("font_color", UI.TEXTO3)

func _atualizar_temporada() -> void:
	var t: Dictionary = jogo.s["temporada"]
	var nivel := int(t["nivel"])
	var xp := int(t["xp"])
	var custo := int(Progresso.xp_para_nivel(nivel + 1))
	lbl_nivel.text = "Nível %d de %d" % [nivel, Dados.temporada.size()]
	barra_xp.value = clampf(float(xp) / maxf(1.0, float(custo)), 0.0, 1.0)
	lbl_xp.text = "%s / %s XP\nfaltam %s" % [Fmt.inteiro(xp), Fmt.inteiro(custo), Fmt.inteiro(maxi(0, custo - xp))]

	var coletadas: Array = t["coletadas"]
	var pendentes := 0
	for chave in niveis.keys():
		var reg: Dictionary = niveis[chave]
		var n := int(chave)
		var cx: PanelContainer = reg["caixa"]
		var b: Button = reg["botao"]
		var lbl_estado: Label = reg["estado"]
		var lbl_nv: Label = reg["nv"]
		var lbl_rec: Label = reg["rec"]
		var ic: Control = reg["icone"]
		var rec: Dictionary = reg["recompensa"]
		var destaque := bool(reg["destaque"])
		var tam: float = 34.0 if destaque else 26.0
		var cor_rec: Color = _cor_recompensa(rec)
		var atual := n == nivel + 1
		if coletadas.has(n):
			b.visible = false
			lbl_estado.visible = true
			lbl_estado.text = "Coletado"
			lbl_estado.add_theme_color_override("font_color", UI.VERDE)
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.2), 10, 1, UI.VERDE.darkened(0.45)))
			ic.configurar(_icone_recompensa(rec), UI.VERDE.darkened(0.1), tam)
			lbl_nv.add_theme_color_override("font_color", UI.VERDE.darkened(0.1))
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO3)
		elif n <= nivel:
			pendentes += 1
			b.visible = true
			b.disabled = false
			lbl_estado.visible = false
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.lerp(UI.OURO, 0.14), 10, 2, UI.OURO))
			ic.configurar(_icone_recompensa(rec), UI.OURO, tam)
			lbl_nv.add_theme_color_override("font_color", UI.OURO)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO)
		else:
			b.visible = false
			lbl_estado.visible = true
			lbl_estado.text = "Próximo" if atual else "Bloqueado"
			lbl_estado.add_theme_color_override("font_color", UI.ROSA if atual else UI.TEXTO3)
			var borda := UI.ROSA if atual else UI.BORDA.darkened(0.25)
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.1 if atual else 0.35), 10, 2 if atual else 1, borda))
			ic.configurar(_icone_recompensa(rec), cor_rec.darkened(0.2) if atual else UI.TEXTO3, tam)
			lbl_nv.add_theme_color_override("font_color", UI.ROSA if atual else UI.TEXTO3)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO2 if atual else UI.TEXTO3)
	if pendentes > 0:
		lbl_nivel.text += "  ·  %s esperando" % ("1 recompensa" if pendentes == 1 else "%d recompensas" % pendentes)

# ------------------------------------------------------------- utilidades

func _num(v: float, tipo: String = "") -> String:
	if tipo == "tempoTotal":
		return Ux.tempo_curto(v)
	if is_inf(v) or v >= 1000000.0:
		return Fmt.num(v)
	return Fmt.inteiro(int(round(v)))

func _icone_de(def: Dictionary) -> String:
	var meta: Dictionary = def.get("meta", {})
	match str(meta.get("tipo", "")):
		"onda", "ondaMaxima", "ondaMaximaGlobal", "ondasCompletas": return "torre"
		"inimigosMortos", "criticos", "danoMaximo", "comboMaximo": return "espada"
		"tiros": return "foguete"
		"inimigoTipo": return "alvo"
		"chefesMortos": return "desafio"
		"ouroTotal", "ouroGasto", "douradosAbatidos", "dourados": return "ouro"
		"gemas": return "gema"
		"fragmentos": return "fragmento"
		"nucleos": return "nucleo"
		"eter": return "eter"
		"nivel": return "estrela"
		"tempoTotal": return "ampulheta"
		"mortes": return "coracao"
		"habilidadesUsadas": return "raio"
		"cartas", "lendarios": return "carta"
		"relicas": return "reliquia"
		"ascensoes": return "prestigio"
		"upgradeNivel": return "espada"
		"talentoNivel": return "arvore"
		"desafiosCompletos": return "desafio"
	return "missao"

func _icone_recompensa(r: Dictionary) -> String:
	match str(r.get("tipo", "")):
		"gemas": return "gema"
		"fragmentos": return "fragmento"
		"nucleos": return "nucleo"
		"eter": return "eter"
		"poeira": return "poeira"
		"ouro": return "ouro"
		"pontosTalento": return "arvore"
		"xp": return "livro"
		"stat": return "stats"
	return "estrela"

func _cor_recompensa(r: Dictionary) -> Color:
	var tipo := str(r.get("tipo", ""))
	if UI.MOEDA_COR.has(tipo):
		return UI.MOEDA_COR[tipo]
	if tipo == "stat":
		return UI.VERDE
	if tipo == "pontosTalento":
		return UI.ACENTO2
	return UI.ACENTO

func _texto_recompensa(r: Dictionary) -> String:
	if r.is_empty():
		return "sem prêmio"
	var v: float = float(r.get("valor", 0))
	match str(r.get("tipo", "")):
		"gemas": return "+%s gemas" % Fmt.inteiro(int(v))
		"fragmentos": return "+%s fragmentos" % Fmt.inteiro(int(v))
		"nucleos": return "+%s núcleos" % Fmt.inteiro(int(v))
		"eter": return "+%s éter" % Fmt.inteiro(int(v))
		"poeira": return "+%s poeira" % Fmt.inteiro(int(v))
		"ouro": return "ouro de %s ondas" % Fmt.num(v, 1)
		"xp": return "XP de %s ondas" % Fmt.num(v, 1)
		"pontosTalento": return "+%d ponto de talento" % int(v) if int(v) == 1 else "+%s pontos de talento" % Fmt.inteiro(int(v))
		"stat":
			var sd: Dictionary = Dados.stat_defs.get(str(r.get("stat", "")), {})
			var nome := txt(sd, "nome")
			if nome.is_empty():
				nome = str(r.get("stat", "atributo"))
			if str(r.get("tipoEfeito", "pct")) == "mult":
				return "%s ×%s" % [nome, Fmt.num(v, 2)]
			return "%s +%s" % [nome, Fmt.pct(v)]
	return "recompensa"
