extends "res://scripts/ui/panel_base.gd"

## Painel de CODEX — o arquivo da Torre: bestiário, chefes e história.
##
## Bestiário/Chefes: grade de fichas. Quem você nunca matou aparece como
## silhueta escura com "?"; quem já morreu na sua frente é DESENHADO com a
## mesma arte vetorial do campo (ArteInimigo), com números, comportamento,
## habilidade e lore.
## História: os 8 capítulos numa lista à esquerda, a entrada aberta à direita.
## Entradas ainda trancadas mostram o requisito e o quanto falta.

const LARG_DETALHE := 366.0
const LARG_INDICE := 316.0
const TILE_W := 126.0
const TILE_H := 128.0
const ART_TILE := 60.0
## Quantas fichas de inimigo por linha no bestiario.
##
## Eram cinco, e cinco so cabiam em ingles. A largura da ficha nao e fixa: ela e
## o maior dos minimos dos filhos, e o nome do inimigo esta entre eles. Em
## portugues os nomes sao mais longos ("Teleportador" por "Blinker",
## "Sanguessuga" por "Leech") e a ficha passou de ~124 px para ~158; cinco
## delas somam 790 px numa coluna de 730, entao a grade ganhava barra de
## rolagem horizontal e a quinta coluna ficava cortada atras do painel de
## detalhe. Quatro cabem nos dois idiomas com folga — e a grade rola na
## vertical de qualquer jeito, entao a densidade perdida nao custa nada.
const COLUNAS := 4

var abas: TabBar
var conteudo: HBoxContainer
var aba := 0
var lbl_progresso: Label
var lbl_dica: Label
var ic_dica: Control

# --- bestiário ---
var detalhe: VBoxContainer
var tiles := {}                  # id -> {caixa, nome, contagem, arte, conhecido}
var sel_id := ""
var lbl_abates: Label
var assinatura := ""

# --- história ---
var cap_sel := ""
var entrada_sel := ""
var lore_texto: VBoxContainer
var lore_rolagem: ScrollContainer
var botoes_lore := {}            # id -> {botao, def, aberta}
var assinatura_lore := ""

func configurar() -> void:
	titulo_texto = Txt.t("p_codex")
	titulo_icone = "livro"
	largura = 1130.0
	altura = 676.0
	intervalo = 0.4

# ============================================================== montagem

func montar(c: VBoxContainer) -> void:
	var topo := UI.hbox(10)
	abas = TabBar.new()
	abas.clip_tabs = false
	abas.add_tab(Txt.t("cdx_aba_bestiario"))
	abas.add_tab(Txt.t("cdx_aba_chefes"))
	abas.add_tab(Txt.t("cdx_aba_historia"))
	abas.tab_changed.connect(func(i):
		aba = int(i)
		_reconstruir())
	topo.add_child(abas)
	topo.add_child(UI.espacador())
	lbl_progresso = UI.rotulo("", 14, UI.TEXTO2)
	lbl_progresso.tooltip_text = Txt.t("cdx_dica_progresso")
	topo.add_child(lbl_progresso)
	c.add_child(topo)

	conteudo = UI.hbox(10)
	conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_child(conteudo)

	c.add_child(UI.separador())
	var rodape := UI.hbox(8)
	ic_dica = Control.new()
	ic_dica.set_script(load("res://scripts/ui/icone_control.gd"))
	rodape.add_child(ic_dica)
	ic_dica.configurar("estrela", UI.OURO, 17)
	lbl_dica = UI.rotulo("", 13, UI.TEXTO2)
	lbl_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_dica.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rodape.add_child(lbl_dica)
	var bd := UI.botao(Txt.t("cdx_outra"), func(): _sortear_dica(), Txt.t("cdx_outra_dica"))
	bd.custom_minimum_size = Vector2(72, 28)
	bd.add_theme_font_size_override("font_size", 12)
	rodape.add_child(bd)
	c.add_child(rodape)
	_sortear_dica()

	_reconstruir()

func _sortear_dica() -> void:
	if Dados.dicas.is_empty():
		lbl_dica.text = Txt.t("cdx_dicas_vazias")
		return
	var d: Dictionary = Dados.dicas[randi() % Dados.dicas.size()]
	lbl_dica.text = txt(d, "texto")
	ic_dica.configurar(_icone_tag(str(d.get("tag", ""))), _cor_tag(str(d.get("tag", ""))), 17)

func _reconstruir() -> void:
	for n in conteudo.get_children():
		n.queue_free()
	tiles.clear()
	botoes_lore.clear()
	detalhe = null
	lore_texto = null
	lbl_abates = null
	assinatura = _assinatura_bicho()
	assinatura_lore = _assinatura_lore()
	if aba == 2:
		_montar_historia()
	else:
		_montar_bestiario()
	atualizar()

func _assinatura_bicho() -> String:
	var out := "%d|" % aba
	for item in _lista():
		var def: Dictionary = item
		var id := str(def.get("id", ""))
		if _abates(id) > 0:
			out += id + ","
	return out

func _assinatura_lore() -> String:
	var out := ""
	for item in Dados.entradas_lore:
		var e: Dictionary = item
		if Progresso.cond_atendida(jogo.s, e.get("cond", {})):
			out += str(e.get("id", "")) + ","
	return out

# ============================================================== bestiário

func _lista() -> Array:
	if aba == 1:
		var out: Array = []
		out.append_array(Dados.chefes)
		out.append_array(Dados.super_chefes)
		return out
	return Dados.inimigos

func _chave_codex() -> String:
	return "chefes" if aba == 1 else "inimigos"

func _abates(id: String) -> int:
	var codex: Dictionary = jogo.s["codex"]
	var mapa: Dictionary = codex.get(_chave_codex(), {})
	return int(mapa.get(id, 0))

func _montar_bestiario() -> void:
	var esq := UI.vbox(8)
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_child(esq)

	var rolagem := UI.scroll()
	esq.add_child(rolagem)
	var coluna := UI.vbox(10)
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(coluna)

	var grade := GridContainer.new()
	# A coluna da esquerda e a janela menos a ficha de detalhe e as molduras. A
	# quatro colunas fixas o bestiario ganhava rolagem horizontal a 1,25 — o que
	# cabe depende da escala, entao a conta e feita, nao chutada. `COLUNAS` vira
	# o teto: quatro em portugues e o maximo que o nome do inimigo permite.
	grade.columns = UI.colunas(UI.larg_util_painel(self, 190.0) - LARG_DETALHE, 158.0, 8.0, COLUNAS)
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	coluna.add_child(grade)

	var lista := _lista()
	if lista.is_empty():
		coluna.add_child(UI.rotulo(Txt.t("cdx_sem_criaturas"), 13, UI.TEXTO3))
	for item in lista:
		var def: Dictionary = item
		grade.add_child(_tile(def))

	if aba == 0 and not Dados.elites.is_empty():
		coluna.add_child(UI.separador())
		coluna.add_child(_titulo_secao(Txt.t("cdx_variantes_elite"), "estrela", UI.ACENTO2,
			Txt.t("cdx_variantes_elite_dica")))
		# DUAS POR LINHA, NAO TRES.
		#
		# A ficha de elite tem uma descricao com 190 px de largura minima, mais
		# icone, espacamentos e a moldura: da uns 240 px em ingles e uns 290 em
		# portugues, onde as frases sao mais longas. Tres delas somam ~880 px
		# numa coluna de 720, e era ISSO que deixava a barra de rolagem
		# horizontal no bestiario — nao a grade de inimigos, que eu tinha
		# acusado primeiro. Duas cabem nos dois idiomas com folga larga.
		var g2 := GridContainer.new()
		g2.columns = 2
		g2.add_theme_constant_override("h_separation", 6)
		g2.add_theme_constant_override("v_separation", 6)
		coluna.add_child(g2)
		for it2 in Dados.elites:
			var el: Dictionary = it2
			g2.add_child(_chip_elite(el))

	var dir := UI.painel(UI.PAINEL2.darkened(0.2), 12)
	dir.custom_minimum_size.x = LARG_DETALHE
	dir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_child(dir)
	var sc := UI.scroll()
	dir.add_child(sc)
	detalhe = UI.vbox(7)
	detalhe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(detalhe)

	if sel_id == "" or _def_por_id(sel_id).is_empty():
		sel_id = ""
		for item3 in lista:
			var d3: Dictionary = item3
			if _abates(str(d3.get("id", ""))) > 0:
				sel_id = str(d3.get("id", ""))
				break
		if sel_id == "" and not lista.is_empty():
			var d4: Dictionary = lista[0]
			sel_id = str(d4.get("id", ""))
	_mostrar_ficha()

func _tile(def: Dictionary) -> Control:
	var id := str(def.get("id", ""))
	var n := _abates(id)
	var conhecido := n > 0
	var cor := _cor(def, "cor", "#8b93a7")

	var b := _botao_limpo(TILE_W, TILE_H)
	b.pressed.connect(func():
		sel_id = id
		_mostrar_ficha()
		_marcar_selecao())
	b.tooltip_text = Txt.f("cdx_tile_abates", {"nome": txt(def, "nome"), "n": Fmt.inteiro(n)}) if conhecido \
		else Txt.t("cdx_nao_catalogado")

	var cx := UI.painel(UI.PAINEL2.darkened(0.16), 10)
	b.add_child(cx)
	cx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var v := UI.vbox(2)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6.0
	v.offset_right = -6.0
	v.offset_top = 6.0
	v.offset_bottom = -6.0

	var arte := ArteBicho.new()
	arte.custom_minimum_size = Vector2(0, ART_TILE)
	arte.clip_contents = true
	arte.raio = 20.0 if not conhecido else (19.0 if aba == 1 else 21.0)
	arte.oculto = not conhecido
	arte.bicho = _bicho(def, aba == 1, conhecido)
	v.add_child(arte)

	var nome := UI.rotulo(txt(def, "nome") if conhecido else "???", 12, UI.TEXTO if conhecido else UI.TEXTO3)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.custom_minimum_size.x = TILE_W - 14.0
	v.add_child(nome)

	var linha_n := UI.hbox(4)
	linha_n.alignment = BoxContainer.ALIGNMENT_CENTER
	var ic := UI.icone("espada" if aba == 0 else "trofeu", cor if conhecido else UI.TEXTO3, 12)
	linha_n.add_child(ic)
	var lc := UI.rotulo(Fmt.inteiro(n) if conhecido else "—", 12, UI.TEXTO2 if conhecido else UI.TEXTO3)
	linha_n.add_child(lc)
	v.add_child(linha_n)

	_ignorar_mouse(cx)
	_ignorar_mouse(v)
	tiles[id] = {"caixa": cx, "nome": nome, "contagem": lc, "arte": arte, "conhecido": conhecido, "cor": cor}
	return b

func _chip_elite(el: Dictionary) -> Control:
	var cor := _cor(el, "cor", "#93a3c4")
	var cx := UI.painel(UI.PAINEL2.darkened(0.24), 8)
	cx.tooltip_text = txt(el, "desc")
	var h := UI.hbox(6)
	cx.add_child(h)
	var ponto := UI.icone("orbe", cor, 14)
	h.add_child(ponto)
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.rotulo(txt(el, "nome"), 12, cor))
	var d := UI.rotulo(txt(el, "desc"), 11, UI.TEXTO3)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 190
	v.add_child(d)
	return cx

# ---------------------------------------------------------------- ficha

func _mostrar_ficha() -> void:
	if detalhe == null:
		return
	for n in detalhe.get_children():
		n.queue_free()
	lbl_abates = null

	var def := _def_por_id(sel_id)
	if def.is_empty():
		detalhe.add_child(_aviso(Txt.t("cdx_escolha_criatura")))
		return
	var id := str(def.get("id", ""))
	var n := _abates(id)
	var conhecido := n > 0
	var cor := _cor(def, "cor", "#8b93a7")
	var chefe := aba == 1

	# --- retrato ---
	var moldura := UI.painel(UI.FUNDO2.darkened(0.25), 10)
	moldura.custom_minimum_size.y = 142
	detalhe.add_child(moldura)
	var arte := ArteBicho.new()
	arte.raio = 30.0 if chefe else 34.0
	arte.oculto = not conhecido
	arte.animar = true
	arte.brilho = cor
	arte.bicho = _bicho(def, chefe, conhecido)
	moldura.add_child(arte)

	if not conhecido:
		detalhe.add_child(UI.rotulo(Txt.t("cdx_especime_nao_catalogado"), 18, UI.TEXTO2))
		var falta := UI.rotulo(
			Txt.t("cdx_falta_chefe" if chefe else "cdx_falta_inimigo"), 13, UI.TEXTO3)
		falta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		falta.custom_minimum_size.x = LARG_DETALHE - 46.0
		detalhe.add_child(falta)
		var pista := _bloco(Txt.t("cdx_onde_procurar"), "alvo", UI.TEXTO2)
		pista.add_child(_texto_corpo(_texto_aparicao(def, chefe), UI.TEXTO2))
		_marcar_selecao()
		return

	# --- nome e abates ---
	var cab := UI.hbox(8)
	var ln := UI.rotulo(txt(def, "nome"), 21, cor)
	ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(ln)
	if chefe:
		cab.add_child(_selo(Txt.t("cdx_derrotado"), UI.VERDE))
	detalhe.add_child(cab)

	var sub := UI.hbox(6)
	var ica := UI.icone("trofeu" if chefe else "espada", UI.OURO, 15)
	sub.add_child(ica)
	lbl_abates = UI.rotulo("", 13, UI.TEXTO2)
	lbl_abates.tooltip_text = Txt.t("cdx_dica_abates")
	sub.add_child(lbl_abates)
	sub.add_child(UI.espacador())
	sub.add_child(UI.rotulo(_texto_aparicao(def, chefe), 12, UI.TEXTO3))
	detalhe.add_child(sub)

	# --- multiplicadores ---
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 6)
	detalhe.add_child(g)
	g.add_child(_mini("coracao", UI.VERMELHO, Txt.t("cdx_m_vida"), "×" + Fmt.num(float(def.get("hp", 1.0)), 2),
		Txt.t("cdx_mult_vida")))
	g.add_child(_mini("ouro", UI.OURO, Txt.t("m_ouro").capitalize(), "×" + Fmt.num(float(def.get("ouro", 1.0)), 2),
		Txt.t("cdx_mult_ouro")))
	g.add_child(_mini("velocidade", UI.ACENTO, Txt.t("cdx_m_velocidade"), "×" + Fmt.num(float(def.get("vel", 1.0)), 2),
		Txt.t("cdx_mult_velocidade")))

	# --- traços ---
	var tracos := _tracos(def, chefe)
	if not tracos.is_empty():
		var caixa_t := UI.hbox(4)
		detalhe.add_child(caixa_t)
		var fluxo := _fluxo()
		caixa_t.add_child(fluxo)
		for t in tracos:
			var par: Array = t
			fluxo.add_child(_selo(str(par[0]), par[1]))

	# --- comportamento ---
	var b1 := _bloco(Txt.t("cdx_comportamento"), "alvo", UI.ACENTO)
	b1.add_child(_texto_corpo(_texto_mov(def, chefe), UI.TEXTO))

	# --- habilidade ---
	var hab := _texto_hab(def, chefe)
	if hab != "":
		var b2 := _bloco(Txt.t("cdx_mecanica_chefe" if chefe else "cdx_habilidade_especial"), "raio", UI.ACENTO2)
		b2.add_child(_texto_corpo(hab, UI.TEXTO))

	# --- lore ---
	var lore := txt(def, "lore")
	if lore != "":
		var b3 := _bloco(Txt.t("cdx_arquivo"), "livro", UI.TEXTO2)
		b3.add_child(_texto_corpo(lore, UI.TEXTO2))

	# --- verdade (Bestiário Verdadeiro) ---
	# O nó do topo da árvore de Éter prometia isto e não entregava nada. Cada
	# chefe é uma versão anterior da própria torre; aqui o jogo finalmente diz
	# QUAL. Só aparece com o nó comprado — é o pagamento da revelação, não uma
	# curiosidade solta no começo.
	if jogo.esp["desbloqueios"].has("modoInfinito"):
		var verdade := txt(def, "verdade")
		if verdade != "":
			var bv := _bloco(Txt.t("cdx_verdade"), "prestigio", UI.ACENTO2)
			var nome_v := txt(def, "verdadeNome")
			if nome_v != "":
				bv.add_child(UI.rotulo(nome_v, 16, UI.ACENTO2, true))
			bv.add_child(_texto_corpo(verdade, UI.TEXTO))

	# --- dica ---
	var dica := txt(def, "dica")
	if dica == "":
		dica = _dica_tatica(def)
	if dica != "":
		var b4 := _bloco(Txt.t("cdx_dica"), "estrela", UI.OURO)
		b4.add_child(_texto_corpo(dica, UI.OURO.lerp(UI.TEXTO, 0.45)))

	_marcar_selecao()

func _marcar_selecao() -> void:
	for id in tiles.keys():
		var r: Dictionary = tiles[id]
		var cx: PanelContainer = r["caixa"]
		if not is_instance_valid(cx):
			continue
		var cor_b: Color = r["cor"] if bool(r["conhecido"]) else UI.BORDA_FORTE
		if str(id) == sel_id:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.tingir(cor_b, 0.14), 10, 2, cor_b))
		else:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.16), 10, 1, UI.BORDA))

# ============================================================== história

func _montar_historia() -> void:
	var esq := UI.painel(UI.PAINEL2.darkened(0.22), 12)
	esq.custom_minimum_size.x = LARG_INDICE
	esq.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_child(esq)
	var sc := UI.scroll()
	lore_rolagem = sc
	esq.add_child(sc)
	var indice := UI.vbox(4)
	indice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(indice)

	if Dados.capitulos_lore.is_empty():
		indice.add_child(UI.rotulo(Txt.t("cdx_arquivo_vazio"), 13, UI.TEXTO3))

	for item in Dados.capitulos_lore:
		var cap: Dictionary = item
		var cid := str(cap.get("id", ""))
		var cor := _cor(cap, "cor", "#93a3c4")
		var entradas := _entradas_do_capitulo(cid)
		var abertas := 0
		for e in entradas:
			if Progresso.cond_atendida(jogo.s, e.get("cond", {})):
				abertas += 1

		var cab := UI.hbox(6)
		var ic := UI.icone(_icone_capitulo(cid), cor if abertas > 0 else UI.TEXTO3, 17)
		cab.add_child(ic)
		var lt := UI.rotulo("%d. %s" % [int(cap.get("ordem", 0)), txt(cap, "nome")], 14,
			cor if abertas > 0 else UI.TEXTO3)
		lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cab.add_child(lt)
		cab.add_child(UI.rotulo("%d/%d" % [abertas, entradas.size()], 12, UI.TEXTO3))
		cab.tooltip_text = txt(cap, "resumo")
		indice.add_child(cab)

		for it2 in entradas:
			var ent: Dictionary = it2
			indice.add_child(_botao_entrada(ent, cor))
		indice.add_child(UI.espacador(6, false))

	var dir := UI.painel(UI.PAINEL2.darkened(0.2), 12)
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_child(dir)
	var sc2 := UI.scroll()
	dir.add_child(sc2)
	lore_texto = UI.vbox(8)
	lore_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.add_child(lore_texto)

	if entrada_sel == "" or _entrada_por_id(entrada_sel).is_empty():
		entrada_sel = ""
		for item3 in Dados.entradas_lore:
			var e3: Dictionary = item3
			if Progresso.cond_atendida(jogo.s, e3.get("cond", {})):
				entrada_sel = str(e3.get("id", ""))
		if entrada_sel == "" and not Dados.entradas_lore.is_empty():
			var e4: Dictionary = Dados.entradas_lore[0]
			entrada_sel = str(e4.get("id", ""))
	_mostrar_entrada()

func _botao_entrada(ent: Dictionary, cor: Color) -> Control:
	var eid := str(ent.get("id", ""))
	var aberta := Progresso.cond_atendida(jogo.s, ent.get("cond", {}))
	var b := _botao_limpo(0, 28)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func():
		entrada_sel = eid
		_mostrar_entrada()
		_marcar_entrada())
	b.tooltip_text = txt(ent, "titulo") if aberta else Txt.f("cdx_trancada", {"cond": _texto_cond(ent.get("cond", {}))})

	var cx := UI.painel(UI.PAINEL2.darkened(0.3), 7)
	b.add_child(cx)
	cx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var h := UI.hbox(6)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10.0
	h.offset_right = -8.0
	var ic := UI.icone(_icone_entrada(ent) if aberta else "cadeado", cor if aberta else UI.TEXTO3, 13)
	h.add_child(ic)
	var l := UI.rotulo(txt(ent, "titulo") if aberta else Txt.t("cdx_entrada_selada"), 13,
		UI.TEXTO if aberta else UI.TEXTO3)
	l.clip_text = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	_ignorar_mouse(cx)
	_ignorar_mouse(h)
	botoes_lore[eid] = {"caixa": cx, "botao": b, "aberta": aberta, "cor": cor}
	return b

func _mostrar_entrada() -> void:
	if lore_texto == null:
		return
	for n in lore_texto.get_children():
		n.queue_free()
	var ent := _entrada_por_id(entrada_sel)
	if ent.is_empty():
		lore_texto.add_child(_aviso(Txt.t("cdx_escolha_entrada")))
		return
	var cap := _capitulo_por_id(str(ent.get("capitulo", "")))
	var cor := _cor(cap, "cor", "#93a3c4")
	var aberta := Progresso.cond_atendida(jogo.s, ent.get("cond", {}))

	var cab := UI.hbox(8)
	var ic := UI.icone(_icone_capitulo(str(cap.get("id", ""))), cor, 18)
	cab.add_child(ic)
	cab.add_child(UI.rotulo(txt(cap, "nome").to_upper(), 12, cor))
	cab.add_child(UI.espacador())
	cab.add_child(UI.rotulo(Txt.f("cdx_entrada_de", {"a": int(ent.get("ordem", 0)),
		"b": _entradas_do_capitulo(str(cap.get("id", ""))).size()}), 12, UI.TEXTO3))
	lore_texto.add_child(cab)

	if not aberta:
		lore_texto.add_child(UI.rotulo(Txt.t("cdx_entrada_selada"), 22, UI.TEXTO2))
		lore_texto.add_child(UI.separador())
		var av := _texto_corpo(Txt.t("cdx_selada_aviso"), UI.TEXTO3)
		lore_texto.add_child(av)
		var cond: Dictionary = ent.get("cond", {})
		var bloco := _bloco(Txt.t("requer"), "cadeado", UI.LARANJA, lore_texto)
		bloco.add_child(_texto_corpo(_texto_cond(cond), UI.TEXTO))
		var atual := Progresso.valor_cond(jogo.s, str(cond.get("tipo", "")), str(cond.get("chave", "")))
		var alvo := float(cond.get("valor", 1.0))
		var barra := UI.barra(UI.LARANJA, 10)
		barra.value = clampf(atual / maxf(alvo, 0.0001), 0.0, 1.0)
		bloco.add_child(barra)
		bloco.add_child(UI.rotulo("%s / %s" % [_num_cond(atual), _num_cond(alvo)], 12, UI.TEXTO2))
		return

	var titulo := UI.rotulo(txt(ent, "titulo"), 23, Color.WHITE)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_texto.add_child(titulo)
	var autor := UI.rotulo(txt(ent, "autor"), 12, cor.lerp(UI.TEXTO2, 0.4))
	autor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_texto.add_child(autor)
	var epi := txt(cap, "epigrafe")
	if epi != "":
		var le := UI.rotulo("“" + epi + "”", 12, UI.TEXTO3)
		le.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lore_texto.add_child(le)
	lore_texto.add_child(UI.separador())

	var corpo := UI.rotulo(txt(ent, "texto"), 15, UI.TEXTO.lerp(UI.TEXTO2, 0.15))
	corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corpo.add_theme_constant_override("line_spacing", 7)
	corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lore_texto.add_child(corpo)
	_marcar_entrada()
	_rolar_ate_selecao()

## Traz a entrada aberta para dentro do índice visível.
func _rolar_ate_selecao() -> void:
	if lore_rolagem == null or not botoes_lore.has(entrada_sel):
		return
	var r: Dictionary = botoes_lore[entrada_sel]
	var b: Control = r["botao"]
	if is_instance_valid(b):
		lore_rolagem.call_deferred("ensure_control_visible", b)

func _marcar_entrada() -> void:
	for id in botoes_lore.keys():
		var r: Dictionary = botoes_lore[id]
		var cx: PanelContainer = r["caixa"]
		if not is_instance_valid(cx):
			continue
		var cor: Color = r["cor"]
		if str(id) == entrada_sel:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.tingir(cor, 0.16), 7, 1, cor))
		else:
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.3), 7, 0))

# ============================================================== atualizar

func atualizar() -> void:
	if jogo == null or lbl_progresso == null:
		return
	if aba == 2:
		var abertas := 0
		for item in Dados.entradas_lore:
			var e: Dictionary = item
			if Progresso.cond_atendida(jogo.s, e.get("cond", {})):
				abertas += 1
		lbl_progresso.text = Txt.f("cdx_progresso_arquivo", {"a": abertas, "b": Dados.entradas_lore.size()})
		if _assinatura_lore() != assinatura_lore:
			_reconstruir()
		return

	var lista := _lista()
	var vistos := 0
	for item2 in lista:
		var def: Dictionary = item2
		var id := str(def.get("id", ""))
		var n := _abates(id)
		if n > 0:
			vistos += 1
		if tiles.has(id):
			var r: Dictionary = tiles[id]
			var lc: Label = r["contagem"]
			if is_instance_valid(lc) and bool(r["conhecido"]):
				lc.text = Fmt.inteiro(n)
	lbl_progresso.text = Txt.f("cdx_progresso_chefes" if aba == 1 else "cdx_progresso_catalogados",
		{"a": vistos, "b": lista.size()})
	if lbl_abates != null and is_instance_valid(lbl_abates):
		lbl_abates.text = Txt.f("cdx_abates_um" if _abates(sel_id) == 1 else "cdx_abates_n",
			{"n": Fmt.inteiro(_abates(sel_id))})
	if _assinatura_bicho() != assinatura:
		_reconstruir()

# ============================================================== textos

func _texto_aparicao(def: Dictionary, chefe: bool) -> String:
	if chefe:
		var id := str(def.get("id", ""))
		for onda in range(10, 3010, 10):
			var c: Dictionary = Dados.chefe_da_onda(onda)
			if str(c.get("id", "")) == id:
				return Txt.f("cdx_guarda_onda", {"n": onda})
		return Txt.t("cdx_aparicao_irregular")
	return Txt.f("cdx_a_partir_onda", {"n": int(def.get("onda", 1))})

func _texto_mov(def: Dictionary, chefe: bool) -> String:
	if chefe:
		var f := maxi(1, int(def.get("fases", 1)))
		var base := Txt.t("cdx_mov_chefe_base")
		if f > 1:
			base += " " + Txt.f("cdx_mov_chefe_fases", {"n": f})
		return base
	match str(def.get("mov", "direto")):
		"direto": return Txt.t("cdx_mov_direto")
		"zigue": return Txt.t("cdx_mov_zigue")
		"salto": return Txt.t("cdx_mov_salto")
		"fantasma": return Txt.t("cdx_mov_fantasma")
		"teleporte": return Txt.t("cdx_mov_teleporte")
		"parar_atirar": return Txt.t("cdx_mov_parar_atirar")
		"perseguidor": return Txt.t("cdx_mov_perseguidor")
		"errante": return Txt.t("cdx_mov_errante")
		"passa": return Txt.t("cdx_mov_passa")
	return Txt.t("cdx_mov_padrao")

func _texto_hab(def: Dictionary, chefe: bool) -> String:
	if chefe:
		var extra := ""
		var invoca: Array = def.get("invoca", [])
		if not invoca.is_empty():
			var nomes: Array = []
			for iid in invoca:
				var d: Dictionary = Dados.inimigo_por_id.get(str(iid), {})
				nomes.append(txt(d, "nome") if not d.is_empty() else str(iid))
			extra = " " + Txt.f("cdx_traz_consigo", {"lista": ", ".join(nomes)})
		var seg := int(def.get("segmentos", 0))
		if seg > 1:
			extra += " " + Txt.f("cdx_corpo_segmentos", {"n": seg})
		match str(def.get("mecanica", "")):
			"invocar": return Txt.t("cdx_mec_invocar") + extra
			"ninhada": return Txt.t("cdx_mec_ninhada") + extra
			"onda_choque": return Txt.t("cdx_mec_onda_choque") + extra
			"fissuras": return Txt.t("cdx_mec_fissuras") + extra
			"segmentos": return Txt.t("cdx_mec_segmentos") + extra
			"refletir": return Txt.t("cdx_mec_refletir") + extra
			"escudo_regen": return Txt.t("cdx_mec_escudo_regen") + extra
			"teleporte_drenar": return Txt.t("cdx_mec_teleporte_drenar") + extra
			"silenciar": return Txt.t("cdx_mec_silenciar") + extra
			"engolir": return Txt.t("cdx_mec_engolir") + extra
			"combinado": return Txt.t("cdx_mec_combinado") + extra
		return Txt.t("cdx_mec_desconhecida") + extra
	match str(def.get("hab", "")):
		"curar": return Txt.t("cdx_hab_curar")
		"cuspir": return Txt.t("cdx_hab_cuspir")
		"explodir": return Txt.t("cdx_hab_explodir")
		"roubar_ouro": return Txt.t("cdx_hab_roubar_ouro")
		"refletir": return Txt.t("cdx_hab_refletir")
		"grudar": return Txt.t("cdx_hab_grudar")
		"chocar": return Txt.t("cdx_hab_chocar")
		"devorar": return Txt.t("cdx_hab_devorar")
		"mutar": return Txt.t("cdx_hab_mutar")
		"ceifar": return Txt.t("cdx_hab_ceifar")
	return ""

func _dica_tatica(def: Dictionary) -> String:
	match str(def.get("hab", "")):
		"curar": return Txt.t("cdx_dica_curar")
		"cuspir": return Txt.t("cdx_dica_cuspir")
		"explodir": return Txt.t("cdx_dica_explodir")
		"roubar_ouro": return Txt.t("cdx_dica_roubar_ouro")
		"refletir": return Txt.t("cdx_dica_refletir")
		"grudar": return Txt.t("cdx_dica_grudar")
		"chocar": return Txt.t("cdx_dica_chocar")
		"devorar": return Txt.t("cdx_dica_devorar")
		"mutar": return Txt.t("cdx_dica_mutar")
		"ceifar": return Txt.t("cdx_dica_ceifar")
	if bool(def.get("invisivel", false)):
		return Txt.t("cdx_dica_invisivel")
	if bool(def.get("voa", false)):
		return Txt.t("cdx_dica_voa")
	if def.has("divide"):
		return Txt.t("cdx_dica_divide")
	if float(def.get("escudoFrac", 0.0)) > 0.0:
		return Txt.t("cdx_dica_escudo")
	if float(def.get("armadura", 0.0)) > 0.0:
		return Txt.t("cdx_dica_armadura")
	if str(def.get("mov", "")) == "passa":
		return Txt.t("cdx_dica_passa")
	if float(def.get("vel", 1.0)) >= 1.4:
		return Txt.t("cdx_dica_rapido")
	if float(def.get("hp", 1.0)) >= 2.0:
		return Txt.t("cdx_dica_tanque")
	return Txt.t("cdx_dica_comum")

func _tracos(def: Dictionary, chefe: bool) -> Array:
	var out: Array = []
	if chefe:
		var f := int(def.get("fases", 1))
		if f > 1:
			out.append([Txt.f("cdx_traco_fases", {"n": f}), UI.ACENTO2])
		if int(def.get("segmentos", 0)) > 1:
			out.append([Txt.f("cdx_traco_segmentos", {"n": int(def.get("segmentos", 0))}), UI.ACENTO])
		if float(def.get("armadura", 0.0)) > 0.0:
			out.append([Txt.f("cdx_traco_armadura", {"n": int(def.get("armadura", 0))}), UI.TEXTO2])
		for sc in Dados.super_chefes:
			var d: Dictionary = sc
			if str(d.get("id", "")) == str(def.get("id", "")):
				out.append([Txt.t("cdx_traco_superchefe"), UI.VERMELHO])
		return out
	if bool(def.get("voa", false)):
		out.append([Txt.t("cdx_traco_voa"), UI.ACENTO])
	if bool(def.get("invisivel", false)):
		out.append([Txt.t("cdx_traco_invisivel"), UI.ACENTO2])
	if def.has("divide"):
		out.append([Txt.t("cdx_traco_divide"), UI.VERDE])
	if def.has("grupo"):
		var gr: Array = def.get("grupo", [])
		if gr.size() >= 2:
			out.append([Txt.f("cdx_traco_bando_de", {"a": int(gr[0]), "b": int(gr[1])}), UI.VERDE])
		else:
			out.append([Txt.t("cdx_traco_bando"), UI.VERDE])
	if float(def.get("armadura", 0.0)) > 0.0:
		out.append([Txt.f("cdx_traco_armadura", {"n": int(def.get("armadura", 0))}), UI.TEXTO2])
	if float(def.get("escudoFrac", 0.0)) > 0.0:
		out.append([Txt.t("cdx_traco_escudo"), UI.ACENTO])
	if float(def.get("esc", 1.0)) >= 1.4:
		out.append([Txt.t("cdx_traco_grande"), UI.LARANJA])
	elif float(def.get("esc", 1.0)) <= 0.7:
		out.append([Txt.t("cdx_traco_miudo"), UI.TEXTO2])
	return out

func _texto_cond(cond: Dictionary) -> String:
	var v := float(cond.get("valor", 0.0))
	var chave := str(cond.get("chave", ""))
	match str(cond.get("tipo", "")):
		"onda": return Txt.f("cdx_cond_onda", {"n": int(v)})
		"ondaMaxima": return Txt.f("cdx_cond_onda_maxima", {"n": int(v)})
		"ondaMaximaGlobal": return Txt.f("cdx_cond_onda_maxima_global", {"n": int(v)})
		"ondasCompletas": return Txt.f("cdx_cond_ondas_completas", {"n": Fmt.inteiro(int(v))})
		"inimigosMortos": return Txt.f("cdx_cond_inimigos_mortos", {"n": Fmt.inteiro(int(v))})
		"chefesMortos": return Txt.f("cdx_cond_chefes_mortos", {"n": Fmt.inteiro(int(v))})
		"inimigoTipo":
			var d: Dictionary = Dados.inimigo_por_id.get(chave, {})
			if d.is_empty():
				for c in Dados.chefes:
					var cd: Dictionary = c
					if str(cd.get("id", "")) == chave:
						d = cd
			var nome := txt(d, "nome") if not d.is_empty() else chave
			return Txt.f("cdx_cond_inimigo_tipo", {"n": Fmt.inteiro(int(v)), "nome": nome})
		"nivel": return Txt.f("cdx_cond_nivel", {"n": int(v)})
		"mortes": return Txt.f("cdx_cond_mortes", {"n": Fmt.inteiro(int(v))})
		"ouroTotal": return Txt.f("cdx_cond_ouro_total", {"n": Fmt.big(Big.from(v))})
		"danoMaximo": return Txt.f("cdx_cond_dano_maximo", {"n": Fmt.big(Big.from(v))})
		"tempoTotal": return Txt.f("cdx_cond_tempo_total", {"n": Ux.tempo_curto(v)})
		"ascensoes": return Txt.f("cdx_cond_ascensoes", {"n": int(v)})
		"singularidades": return Txt.f("cdx_cond_singularidades", {"n": int(v)})
		"transcendencias": return Txt.f("cdx_cond_transcendencias", {"n": int(v)})
		"cartas": return Txt.f("cdx_cond_cartas", {"n": int(v)})
		"lendarios": return Txt.f("cdx_cond_lendarios", {"n": int(v)})
		"relicas": return Txt.f("cdx_cond_relicas", {"n": int(v)})
		"conquistasTotal": return Txt.f("cdx_cond_conquistas", {"n": int(v)})
		"desafiosCompletos": return Txt.f("cdx_cond_desafios", {"n": int(v)})
		"criticos": return Txt.f("cdx_cond_criticos", {"n": Fmt.inteiro(int(v))})
		"tiros": return Txt.f("cdx_cond_tiros", {"n": Fmt.inteiro(int(v))})
		"comboMaximo": return Txt.f("cdx_cond_combo", {"n": int(v)})
	return Txt.t("cdx_cond_padrao")

func _num_cond(v: float) -> String:
	if v >= 100000.0:
		return Fmt.big(Big.from(v))
	return Fmt.inteiro(int(v))

# ============================================================== auxiliares

func _def_por_id(id: String) -> Dictionary:
	for item in _lista():
		var d: Dictionary = item
		if str(d.get("id", "")) == id:
			return d
	return {}

func _entrada_por_id(id: String) -> Dictionary:
	for item in Dados.entradas_lore:
		var d: Dictionary = item
		if str(d.get("id", "")) == id:
			return d
	return {}

func _capitulo_por_id(id: String) -> Dictionary:
	for item in Dados.capitulos_lore:
		var d: Dictionary = item
		if str(d.get("id", "")) == id:
			return d
	return {}

func _entradas_do_capitulo(cid: String) -> Array:
	var out: Array = []
	for item in Dados.entradas_lore:
		var d: Dictionary = item
		if str(d.get("capitulo", "")) == cid:
			out.append(d)
	out.sort_custom(func(a, b): return int(a.get("ordem", 0)) < int(b.get("ordem", 0)))
	return out

func _cor(d: Dictionary, campo: String, padrao: String) -> Color:
	var s := str(d.get(campo, padrao))
	if s.is_empty() or not s.begins_with("#"):
		s = padrao
	return Ux.hex(s)

func _bicho(def: Dictionary, chefe: bool, conhecido: bool) -> Inimigo:
	var e := Inimigo.new()
	e.ativo = true
	e.def = def
	e.tipo = str(def.get("id", ""))
	e.forma = str(def.get("forma", "circulo"))
	e.chefe = chefe
	e.hp = Big.from(100.0)
	e.hp_max = Big.from(100.0)
	e.ang = 0.0
	e.fase_anim = float(abs(hash(e.tipo) % 100)) * 0.0628
	e.cor = _cor(def, "cor", "#8b93a7")
	e.cor2 = _cor(def, "cor2", str(def.get("cor", "#3a4152")))
	if not conhecido:
		e.chefe = false
		e.cor = Color(0.78, 0.81, 0.90)
		e.cor2 = Color(0.55, 0.58, 0.68)
	# O DISFARCE E ESTADO DE COMBATE, NAO PROPRIEDADE DA ESPECIE.
	#
	# `art_enemy` corta o alfa de quem tem `invisivel` no JSON e ainda nao foi
	# revelado. Na arena isso esta certo — a Sombra so aparece quando encosta.
	# Na ficha do Codex, nao: era o unico bicho cuja ficha mostrava um retangulo
	# vazio, e justamente o que mais precisa ser estudado com calma, porque no
	# campo ele tem meio segundo para ser reconhecido. A pessoa pagava 9 abates
	# para desbloquear nada.
	e.revelado = true
	return e

func _botao_limpo(w: float, h: float) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for est in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(est, UI.caixa_vazia())
	return b

func _ignorar_mouse(no: Node) -> void:
	if no is Control:
		(no as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for f in no.get_children():
		_ignorar_mouse(f)

func _bloco(titulo: String, icone: String, cor: Color, pai: VBoxContainer = null) -> VBoxContainer:
	var alvo := pai if pai != null else detalhe
	var cx := UI.painel(UI.PAINEL2.darkened(0.28), 9)
	cx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alvo.add_child(cx)
	var v := UI.vbox(3)
	cx.add_child(v)
	var h := UI.hbox(5)
	var ic := UI.icone(icone, cor, 13)
	h.add_child(ic)
	h.add_child(UI.rotulo(titulo.to_upper(), 10, cor.lerp(UI.TEXTO3, 0.4)))
	v.add_child(h)
	return v

func _titulo_secao(texto: String, icone: String, cor: Color, dica: String) -> HBoxContainer:
	var h := UI.hbox(6)
	h.tooltip_text = dica
	var ic := UI.icone(icone, cor, 16)
	h.add_child(ic)
	h.add_child(UI.rotulo(texto, 14, UI.TEXTO2))
	return h

func _texto_corpo(texto: String, cor: Color) -> Label:
	var l := UI.rotulo(texto, 13, cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = LARG_DETALHE - 74.0
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_constant_override("line_spacing", 4)
	return l

func _aviso(texto: String) -> Label:
	var l := UI.rotulo(texto, 13, UI.TEXTO3)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 240
	return l

func _selo(texto: String, cor: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UI.caixa(cor.darkened(0.72), 6, 1, cor.darkened(0.25))
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(UI.rotulo(texto, 11, cor))
	return p

func _fluxo() -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 4)
	f.add_theme_constant_override("v_separation", 4)
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return f

func _mini(icone: String, cor: Color, rotulo: String, valor: String, dica: String) -> PanelContainer:
	var p := UI.painel(UI.PAINEL2.darkened(0.28), 8)
	p.tooltip_text = dica
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(1)
	p.add_child(v)
	var h := UI.hbox(4)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var ic := UI.icone(icone, cor, 14)
	h.add_child(ic)
	h.add_child(UI.rotulo(valor, 14, UI.TEXTO))
	v.add_child(h)
	var l := UI.rotulo(rotulo, 10, UI.TEXTO3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return p

func _icone_capitulo(id: String) -> String:
	match id:
		"fundacao": return "torre"
		"ferramenta": return "engrenagem"
		"colheita": return "desafio"
		"silencio": return "ampulheta"
		"poeira": return "fragmento"
		"ponto": return "vazio"
		"espelho": return "gema"
		"depois": return "eter"
	return "livro"

func _icone_entrada(ent: Dictionary) -> String:
	var autor := str(ent.get("autor", ""))
	if autor.contains("TORRE-0") or autor.contains("TORRE-1440"):
		return "torre"
	if autor.contains("Ilaria"):
		return "livro"
	if autor.contains("Serj"):
		return "engrenagem"
	if autor.contains("Teo"):
		return "estrela"
	if autor.contains("Conselho") or autor.contains("Comissária"):
		return "balanca"
	if autor.contains("Rede") or autor.contains("Rotina"):
		return "raio"
	return "missao"

func _icone_tag(tag: String) -> String:
	match tag:
		"combate": return "espada"
		"economia": return "ouro"
		"prestigio": return "prestigio"
		"cartas": return "carta"
		"defesa": return "escudo"
		"meta": return "engrenagem"
		"piada": return "estrela"
	return "livro"

func _cor_tag(tag: String) -> Color:
	match tag:
		"combate": return UI.VERMELHO
		"economia": return UI.OURO
		"prestigio": return UI.ACENTO
		"cartas": return UI.ACENTO2
		"defesa": return UI.VERDE
		"piada": return UI.ROSA
	return UI.TEXTO2

# ==============================================================================
# ARTE — o inimigo desenhado com o mesmo pincel do campo de batalha.
# ==============================================================================

class ArteBicho extends Control:
	var bicho: Inimigo
	var raio := 22.0
	var animar := false
	var oculto := false
	var brilho := Color.TRANSPARENT
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_t = randf() * 4.0
		set_process(animar)
		if not oculto:
			return
		# silhueta: achata toda a paleta do bicho num vulto escuro
		self_modulate = Color(0.30, 0.33, 0.44)
		var q := UI.rotulo("?", int(raio * 1.15), UI.TEXTO3)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(q)
		q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if bicho == null or size.x < 8.0 or size.y < 8.0:
			return
		var c := size * 0.5
		if brilho.a > 0.0:
			draw_circle(c, minf(size.x, size.y) * 0.44, Color(brilho.r, brilho.g, brilho.b, 0.08))
		bicho.pos = c
		bicho.raio = raio
		bicho.altura = 0.0
		ArteInimigo.desenhar(self, bicho, _t)
