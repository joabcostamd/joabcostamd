extends "res://scripts/ui/panel_base.gd"

## Painel de MISSÕES E TEMPORADA — a agenda burocrática do fim do mundo.
##
## Diárias e semanais com barra de progresso e botão de coleta, a sequência
## de sete dias (voltar todo dia rende XP de temporada extra) e o passe de
## temporada: uma trilha rolável de 40 níveis com o nível atual em destaque.

const SEG_DIA := 86400
const SEG_SEMANA := 604800

var conteudo: VBoxContainer
var b_coletar_tudo: Button
var lbl_diario: Label
var lbl_semanal: Label
var lbl_vazio_d: Label
var lbl_vazio_s: Label
var caixa_diarias: VBoxContainer
var caixa_semanais: VBoxContainer
var caixa_sequencia: Container
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
	titulo_texto = Txt.t("p_missoes")
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

	# COLETAR TUDO. Fim de sessao era bracal: cada missao pronta e cada nivel de
	# temporada pedia o seu proprio clique, e depois de uma sessao longa sao ate
	# dez. O botao so aparece quando ha o que coletar, e diz quantos.
	var topo := UI.hbox(8)
	topo.alignment = BoxContainer.ALIGNMENT_END
	b_coletar_tudo = UI.botao("", _coletar_tudo)
	b_coletar_tudo.custom_minimum_size = Vector2(210, 38)
	topo.add_child(b_coletar_tudo)
	conteudo.add_child(topo)

	# ---------------------------------------------------------- diárias
	lbl_diario = UI.rotulo("", 13, UI.TEXTO2)
	conteudo.add_child(_secao(Txt.t("mis_sec_diarias"), "ampulheta", UI.ACENTO,
		Txt.t("mis_sec_diarias_dica"), lbl_diario))
	caixa_diarias = UI.vbox(6)
	conteudo.add_child(caixa_diarias)
	lbl_vazio_d = UI.rotulo(Txt.t("mis_vazio_diarias"), 13, UI.TEXTO3)
	conteudo.add_child(lbl_vazio_d)

	# ------------------------------------------------------- sequência
	lbl_sequencia = UI.rotulo("", 13, UI.TEXTO2)
	conteudo.add_child(_secao(Txt.t("mis_sec_sequencia"), "estrela", UI.OURO,
		Txt.t("mis_sec_sequencia_dica"), lbl_sequencia))
	var cx_seq := UI.painel(UI.PAINEL2.darkened(0.15), 12)
	# SETE CARTOES DE 122 px SAO 890 px, E A JANELA UTIL A 1,25 TEM 842.
	#
	# Era um `HBoxContainer`, que empurra em vez de quebrar: a fileira da
	# sequencia diaria sozinha punha o painel de Missoes alem da janela na
	# escala 1,25, e ele abria rolado para a direita com a coluna da esquerda
	# cortada. Num container que quebra, o setimo dia desce para a linha de
	# baixo e ninguem perde nada.
	caixa_sequencia = HFlowContainer.new()
	caixa_sequencia.add_theme_constant_override("h_separation", 6)
	caixa_sequencia.add_theme_constant_override("v_separation", 6)
	caixa_sequencia.alignment = BoxContainer.ALIGNMENT_CENTER
	cx_seq.add_child(caixa_sequencia)
	conteudo.add_child(cx_seq)
	_montar_sequencia()

	# --------------------------------------------------------- semanais
	lbl_semanal = UI.rotulo("", 13, UI.TEXTO2)
	conteudo.add_child(_secao(Txt.t("mis_sec_semanais"), "desafio", UI.ACENTO2,
		Txt.t("mis_sec_semanais_dica"), lbl_semanal))
	caixa_semanais = UI.vbox(6)
	conteudo.add_child(caixa_semanais)
	lbl_vazio_s = UI.rotulo(Txt.t("mis_vazio_semanais"), 13, UI.TEXTO3)
	conteudo.add_child(lbl_vazio_s)

	# -------------------------------------------------------- temporada
	conteudo.add_child(_secao(Txt.t("mis_sec_passe"), "prestigio", UI.ROSA,
		Txt.t("mis_sec_passe_dica"), null))
	var cabeca := UI.painel(UI.PAINEL2.darkened(0.1), 12)
	var ch := UI.hbox(14)
	cabeca.add_child(ch)
	var ic := UI.icone("estrela", UI.ROSA, 30)
	ch.add_child(ic)
	var cv := UI.vbox(3)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nivel = UI.rotulo(Txt.t("nivel") + " 0", 18, UI.TEXTO)
	cv.add_child(lbl_nivel)
	barra_xp = UI.barra(UI.ROSA, 9)
	# Mesma historia da descricao: a barra de XP da temporada exigia 420 px de
	# largura minima, e numa janela util de 842 isso nao sobra depois do icone,
	# do nivel e do contador. Ela ocupa o que houver.
	barra_xp.custom_minimum_size.x = 200
	barra_xp.tooltip_text = Txt.t("mis_dica_barra_xp")
	cv.add_child(barra_xp)
	ch.add_child(cv)
	lbl_xp = UI.rotulo("", 14, UI.TEXTO2)
	lbl_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ch.add_child(lbl_xp)
	conteudo.add_child(cabeca)

	rolagem_trilha = ScrollContainer.new()
	# A trilha de 40 niveis rola na horizontal DE PROPOSITO — e o desenho dela,
	# nao um transbordo. A marca abaixo diz isso a varredura de layout
	# (`--auditar-ui`), que sem ela acusava 250 falsos positivos so aqui.
	rolagem_trilha.set_meta("rolagem_horizontal_proposital", true)
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
	var ic := UI.icone(icone, cor, 20)
	h.add_child(ic)
	var l := UI.rotulo(titulo, 18, cor)
	l.tooltip_text = dica
	h.add_child(l)
	# A LINHA DE DICA NAO PODE EXIGIR LARGURA.
	#
	# Era um rotulo comum: sem quebra e sem limite, o minimo dele e o texto
	# inteiro — 557 px em portugues. Somado ao titulo, ao icone e ao botao da
	# direita, isso empurrava o painel de Missoes alem da janela na escala 1,25
	# e ele abria rolado para a direita, com a coluna da esquerda cortada.
	#
	# A dica e texto secundario, e o titulo ao lado ja a repete no tooltip: ela
	# ocupa o que sobrar e corta com reticencias quando nao couber. Assim a
	# altura da linha nao muda e a largura deixa de ser exigencia dela.
	var sub := UI.rotulo(dica, 12, UI.TEXTO3)
	sub.clip_text = true
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.custom_minimum_size.x = 0
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
	# A DESCRICAO PEDE POUCO E ACEITA O QUE SOBRAR.
	#
	# 460 px de minimo cabiam a 1,0 e nao cabiam a 1,25: somados ao icone, a
	# barra de progresso, aos premios e ao botao, punham a linha em 938 px numa
	# janela util de 842, e o painel abria rolado para a direita. Ela ja quebra
	# em varias linhas — o que ela nao pode e EXIGIR uma largura que a janela
	# nao tem. Com um minimo modesto e permissao para expandir, ela ocupa o que
	# sobrar: 460+ na tela larga, menos na estreita, e nunca empurra o painel.
	desc.custom_minimum_size.x = 240
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var ic_rec := UI.icone(_icone_recompensa(rec), _cor_recompensa(rec), 14)
	lp.add_child(ic_rec)
	lp.add_child(UI.rotulo(_texto_recompensa(rec), 12, _cor_recompensa(rec)))
	lp.add_child(UI.rotulo("·", 12, UI.BORDA_FORTE))
	var lxp := UI.rotulo(Txt.f("mis_xp_temporada", {"n": int(def.get("xpTemporada", 10))}), 12, UI.ROSA)
	lxp.tooltip_text = Txt.t("mis_dica_xp")
	lp.add_child(lxp)
	l["textos"].add_child(lp)

	var coluna := UI.vbox(4)
	var b := UI.botao(Txt.t("coletar"), func(): _coletar(grupo, indice))
	b.custom_minimum_size = Vector2(126, 40)
	coluna.add_child(b)
	# Rerrolagem: o Dado Viciado promete "+1 rerroll diário ... em missões" e
	# não havia botão nenhum para gastar a rerrolagem que ele dava.
	var br := UI.botao(Txt.t("mis_rerrolar"), func(): _rerrolar(grupo, indice))
	br.custom_minimum_size = Vector2(126, 26)
	coluna.add_child(br)
	l["direita"].add_child(coluna)

	if grupo == "diarias":
		caixa_diarias.add_child(l["caixa"])
	else:
		caixa_semanais.add_child(l["caixa"])
	missoes["%s:%d" % [grupo, indice]] = {
		"grupo": grupo, "indice": indice, "def": def, "caixa": l["caixa"],
		"barra": barra, "prog": lbl_prog, "botao": b, "rerrolar": br, "cor": cor,
	}

func _rerrolar(grupo: String, indice: int) -> void:
	if Progresso.rerrolar_missao(jogo, grupo, indice):
		Bus.toast(Txt.f("mis_rerrolada", {"n": Progresso.rerrolagens_restantes(jogo)}), "bom", "missao")
		_reconstruir_missoes()
	else:
		Bus.toast(Txt.t("mis_sem_rerroll"), "info", "cadeado")

func _coletar(grupo: String, indice: int) -> void:
	if not Progresso.coletar_missao(jogo, grupo, indice):
		Bus.toast(Txt.t("mis_toast_nao_pronta"), "info")
		return
	jogo.marcar_sujo()
	var chave := "%s:%d" % [grupo, indice]
	if missoes.has(chave):
		var reg: Dictionary = missoes[chave]
		var cx: PanelContainer = reg["caixa"]
		UI.pulsar(cx, UI.VERDE)
	Bus.toast(Txt.t("mis_toast_coletada"), "bom")
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

		var lbl_dia := UI.rotulo(Txt.f("mis_dia_n", {"n": dia}), 12, UI.TEXTO3)
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

		var lbl_nv := UI.rotulo(Txt.f("mis_nv_n", {"n": nivel}), 12, UI.TEXTO3)
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
		var b := UI.botao(Txt.t("coletar"), func(): _coletar_nivel(nivel))
		b.custom_minimum_size = Vector2(0, 26)
		b.add_theme_font_size_override("font_size", 12)
		v.add_child(b)
		var lbl_estado := UI.rotulo("", 11, UI.TEXTO3)
		lbl_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lbl_estado)

		var dica_extra := Txt.t("mis_dica_destaque") if destaque else ""
		cx.tooltip_text = Txt.f("mis_dica_nivel", {"n": nivel, "nome": txt(r, "nome")}) + dica_extra
		trilha.add_child(cx)
		niveis[nivel] = {"caixa": cx, "nv": lbl_nv, "icone": ic, "rec": lbl_rec,
			"botao": b, "estado": lbl_estado, "destaque": destaque, "recompensa": rec}

func _coletar_nivel(nivel: int) -> void:
	if not Progresso.coletar_temporada(jogo, nivel):
		Bus.toast(Txt.f("mis_toast_nivel_travado", {"n": nivel}), "info")
		return
	jogo.marcar_sujo()
	if niveis.has(nivel):
		var reg: Dictionary = niveis[nivel]
		var cx: PanelContainer = reg["caixa"]
		UI.pulsar(cx, UI.VERDE)
	Bus.toast(Txt.t("mis_toast_temporada"), "bom")
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

func _coletar_tudo() -> void:
	var n := Progresso.coletar_tudo(jogo)
	if n <= 0:
		return
	Bus.toast(Txt.f("mis_coletou_tudo", {"n": n}), "bom", "missao")
	UI.pulsar(b_coletar_tudo, UI.VERDE)
	Bus.ui_atualizar.emit(true)

func atualizar() -> void:
	if jogo == null or lbl_diario == null:
		return
	if b_coletar_tudo != null:
		var quantas := Progresso.quantas_a_coletar(jogo.s)
		b_coletar_tudo.visible = quantas > 0
		b_coletar_tudo.text = Txt.f("mis_coletar_tudo", {"n": quantas})
	if _assinatura_atual() != assinatura:
		_reconstruir_missoes()

	var m: Dictionary = jogo.s["missoes"]
	var agora := Time.get_unix_time_from_system()
	var falta_d := float(int(m["reset_diario"]) + SEG_DIA) - agora
	var falta_s := float(int(m["reset_semanal"]) + SEG_SEMANA) - agora
	lbl_diario.text = Txt.f("mis_renova_em", {"t": Ux.tempo_curto(maxf(0.0, falta_d))})
	lbl_diario.tooltip_text = Txt.t("mis_dica_reset_diario")
	lbl_semanal.text = Txt.f("mis_renova_em", {"t": Ux.tempo_curto(maxf(0.0, falta_s))})
	lbl_semanal.tooltip_text = Txt.t("mis_dica_reset_semanal")

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
			b.text = Txt.t("coletado")
			b.tooltip_text = Txt.t("mis_dica_ja_pago")
		elif pronta:
			b.text = Txt.t("coletar")
			b.tooltip_text = Txt.t("mis_dica_pronta")
		else:
			b.text = Txt.t("mis_em_curso")
			b.tooltip_text = Txt.f("mis_dica_em_curso", {"n": Fmt.pct(f)})

		var br2: Button = reg["rerrolar"]
		var sobrando := Progresso.rerrolagens_restantes(jogo)
		br2.visible = sobrando > 0 and not coletada and not pronta
		br2.text = Txt.f("mis_rerrolar_n", {"n": sobrando})
		br2.tooltip_text = Txt.t("mis_dica_rerrolar")

		var cx: PanelContainer = reg["caixa"]
		var cor: Color = reg["cor"]
		if coletada:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.35), 10, 1, UI.BORDA.darkened(0.2)))
		elif pronta:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.tingir(UI.VERDE, 0.1), 10, 2, UI.VERDE))
		else:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.12), 10, 1, cor.darkened(0.45)))

func _atualizar_sequencia() -> void:
	var seq := int(jogo.s["missoes"]["sequencia"])
	var hoje := _dia_da_sequencia()
	if seq <= 0:
		lbl_sequencia.text = Txt.t("mis_seq_zero")
	else:
		lbl_sequencia.text = Txt.t("mis_seq_1") if seq == 1 else Txt.f("mis_seq_n", {"n": seq})
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
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.tingir(UI.OURO, 0.12), 10, 2, UI.OURO))
			ic.configurar(_icone_recompensa(rec), UI.OURO, tam)
			lbl_dia.text = Txt.t("mis_hoje")
			lbl_dia.add_theme_color_override("font_color", UI.OURO)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO)
			lbl_mult.add_theme_color_override("font_color", UI.OURO)
		elif d < hoje:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.1), 10, 1, UI.VERDE.darkened(0.4)))
			ic.configurar(_icone_recompensa(rec), UI.VERDE.darkened(0.15), tam)
			lbl_dia.text = Txt.f("mis_dia_n", {"n": d})
			lbl_dia.add_theme_color_override("font_color", UI.VERDE)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO2)
			lbl_mult.add_theme_color_override("font_color", UI.TEXTO2)
		else:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.3), 10, 1, UI.BORDA.darkened(0.25)))
			ic.configurar(_icone_recompensa(rec), UI.TEXTO3, tam)
			lbl_dia.text = Txt.f("mis_dia_n", {"n": d})
			lbl_dia.add_theme_color_override("font_color", UI.TEXTO3)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO3)
			lbl_mult.add_theme_color_override("font_color", UI.TEXTO3)

func _atualizar_temporada() -> void:
	var t: Dictionary = jogo.s["temporada"]
	var nivel := int(t["nivel"])
	var xp := int(t["xp"])
	var custo := int(Progresso.xp_para_nivel(nivel + 1))
	lbl_nivel.text = Txt.f("mis_nivel_de", {"a": nivel, "b": Dados.temporada.size()})
	barra_xp.value = clampf(float(xp) / maxf(1.0, float(custo)), 0.0, 1.0)
	lbl_xp.text = Txt.f("mis_xp_barra", {"a": Fmt.inteiro(xp), "b": Fmt.inteiro(custo),
		"c": Fmt.inteiro(maxi(0, custo - xp))})

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
			lbl_estado.text = Txt.t("coletado")
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
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.tingir(UI.OURO, 0.14), 10, 2, UI.OURO))
			ic.configurar(_icone_recompensa(rec), UI.OURO, tam)
			lbl_nv.add_theme_color_override("font_color", UI.OURO)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO)
		else:
			b.visible = false
			lbl_estado.visible = true
			lbl_estado.text = Txt.t("proximo") if atual else Txt.t("bloqueado")
			lbl_estado.add_theme_color_override("font_color", UI.ROSA if atual else UI.TEXTO3)
			var borda := UI.ROSA if atual else UI.BORDA.darkened(0.25)
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.1 if atual else 0.35), 10, 2 if atual else 1, borda))
			ic.configurar(_icone_recompensa(rec), cor_rec.darkened(0.2) if atual else UI.TEXTO3, tam)
			lbl_nv.add_theme_color_override("font_color", UI.ROSA if atual else UI.TEXTO3)
			lbl_rec.add_theme_color_override("font_color", UI.TEXTO2 if atual else UI.TEXTO3)
	if pendentes > 0:
		lbl_nivel.text += Txt.t("mis_1_esperando") if pendentes == 1 else Txt.f("mis_n_esperando", {"n": pendentes})

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
		return Txt.t("mis_sem_premio")
	var v: float = float(r.get("valor", 0))
	match str(r.get("tipo", "")):
		"gemas": return "+%s %s" % [Fmt.inteiro(int(v)), Txt.t("m_gemas")]
		"fragmentos": return "+%s %s" % [Fmt.inteiro(int(v)), Txt.t("m_fragmentos")]
		"nucleos": return "+%s %s" % [Fmt.inteiro(int(v)), Txt.t("m_nucleos")]
		"eter": return "+%s %s" % [Fmt.inteiro(int(v)), Txt.t("m_eter")]
		"poeira": return "+%s %s" % [Fmt.inteiro(int(v)), Txt.t("m_poeira")]
		"ouro": return Txt.f("mis_rec_ouro_ondas", {"n": Fmt.num(v, 1)})
		"xp": return Txt.f("mis_rec_xp_ondas", {"n": Fmt.num(v, 1)})
		"pontosTalento": return Txt.t("mis_rec_ponto_talento") if int(v) == 1 else "+%s %s" % [Fmt.inteiro(int(v)), Txt.t("pontos_talento")]
		"stat":
			var sd: Dictionary = Dados.stat_defs.get(str(r.get("stat", "")), {})
			var nome := txt(sd, "nome")
			if nome.is_empty():
				nome = str(r.get("stat", Txt.t("mis_atributo")))
			if str(r.get("tipoEfeito", "pct")) == "mult":
				return "%s ×%s" % [nome, Fmt.num(v, 2)]
			return "%s +%s" % [nome, Fmt.pct(v)]
	return Txt.t("recompensa").to_lower()
