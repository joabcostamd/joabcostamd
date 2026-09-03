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
const COLUNAS := 5

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
	titulo_texto = "Codex"
	titulo_icone = "livro"
	largura = 1130.0
	altura = 676.0
	intervalo = 0.4

# ============================================================== montagem

func montar(c: VBoxContainer) -> void:
	var topo := UI.hbox(10)
	abas = TabBar.new()
	abas.clip_tabs = false
	abas.add_tab("Bestiário")
	abas.add_tab("Chefes")
	abas.add_tab("História")
	abas.tab_changed.connect(func(i):
		aba = int(i)
		_reconstruir())
	topo.add_child(abas)
	topo.add_child(UI.espacador())
	lbl_progresso = UI.rotulo("", 14, UI.TEXTO2)
	lbl_progresso.tooltip_text = "Quanto do arquivo você já preencheu."
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
	var bd := UI.botao("Outra", func(): _sortear_dica(), "Sorteia outra dica do arquivo.")
	bd.custom_minimum_size = Vector2(72, 28)
	bd.add_theme_font_size_override("font_size", 12)
	rodape.add_child(bd)
	c.add_child(rodape)
	_sortear_dica()

	_reconstruir()

func _sortear_dica() -> void:
	if Dados.dicas.is_empty():
		lbl_dica.text = "O arquivo de dicas está vazio. Improvise."
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
	grade.columns = COLUNAS
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	coluna.add_child(grade)

	var lista := _lista()
	if lista.is_empty():
		coluna.add_child(UI.rotulo("Nenhuma criatura catalogada — os dados não carregaram.", 13, UI.TEXTO3))
	for item in lista:
		var def: Dictionary = item
		grade.add_child(_tile(def))

	if aba == 0 and not Dados.elites.is_empty():
		coluna.add_child(UI.separador())
		coluna.add_child(_titulo_secao("Variantes de elite", "estrela", UI.ACENTO2,
			"Qualquer inimigo pode vir com uma destas marcas — vale mais e incomoda mais."))
		var g2 := GridContainer.new()
		g2.columns = 3
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
	b.tooltip_text = ("%s — %s abate(s)." % [txt(def, "nome"), Fmt.inteiro(n)]) if conhecido \
		else "Ainda não catalogado. Derrote um para abrir a ficha."

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
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	linha_n.add_child(ic)
	ic.configurar("espada" if aba == 0 else "trofeu", cor if conhecido else UI.TEXTO3, 12)
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
	var ponto := Control.new()
	ponto.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ponto)
	ponto.configurar("orbe", cor, 14)
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
		detalhe.add_child(_aviso("Escolha uma criatura na grade para abrir a ficha."))
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
		detalhe.add_child(UI.rotulo("Espécime não catalogado", 18, UI.TEXTO2))
		var falta := UI.rotulo(
			"A Torre só registra o que morre na frente dela. Derrote um %s para abrir esta ficha."
			% ("chefe destes" if chefe else "destes"), 13, UI.TEXTO3)
		falta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		falta.custom_minimum_size.x = LARG_DETALHE - 46.0
		detalhe.add_child(falta)
		var pista := _bloco("Onde procurar", "alvo", UI.TEXTO2)
		pista.add_child(_texto_corpo(_texto_aparicao(def, chefe), UI.TEXTO2))
		_marcar_selecao()
		return

	# --- nome e abates ---
	var cab := UI.hbox(8)
	var ln := UI.rotulo(txt(def, "nome"), 21, cor)
	ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(ln)
	if chefe:
		cab.add_child(_selo("DERROTADO", UI.VERDE))
	detalhe.add_child(cab)

	var sub := UI.hbox(6)
	var ica := Control.new()
	ica.set_script(load("res://scripts/ui/icone_control.gd"))
	sub.add_child(ica)
	ica.configurar("trofeu" if chefe else "espada", UI.OURO, 15)
	lbl_abates = UI.rotulo("", 13, UI.TEXTO2)
	lbl_abates.tooltip_text = "Quantos deste tipo você já derrubou."
	sub.add_child(lbl_abates)
	sub.add_child(UI.espacador())
	sub.add_child(UI.rotulo(_texto_aparicao(def, chefe), 12, UI.TEXTO3))
	detalhe.add_child(sub)

	# --- multiplicadores ---
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 6)
	detalhe.add_child(g)
	g.add_child(_mini("coracao", UI.VERMELHO, "Vida", "×" + Fmt.num(float(def.get("hp", 1.0)), 2),
		"Multiplicador sobre a vida-base da onda."))
	g.add_child(_mini("ouro", UI.OURO, "Ouro", "×" + Fmt.num(float(def.get("ouro", 1.0)), 2),
		"Multiplicador sobre o ouro-base da onda."))
	g.add_child(_mini("velocidade", UI.ACENTO, "Velocidade", "×" + Fmt.num(float(def.get("vel", 1.0)), 2),
		"Multiplicador sobre a velocidade-base da onda."))

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
	var b1 := _bloco("Comportamento", "alvo", UI.ACENTO)
	b1.add_child(_texto_corpo(_texto_mov(def, chefe), UI.TEXTO))

	# --- habilidade ---
	var hab := _texto_hab(def, chefe)
	if hab != "":
		var b2 := _bloco("Habilidade especial" if not chefe else "Mecânica de chefe", "raio", UI.ACENTO2)
		b2.add_child(_texto_corpo(hab, UI.TEXTO))

	# --- lore ---
	var lore := txt(def, "lore")
	if lore != "":
		var b3 := _bloco("Arquivo", "livro", UI.TEXTO2)
		b3.add_child(_texto_corpo(lore, UI.TEXTO2))

	# --- dica ---
	var dica := str(def.get("dica", ""))
	if dica == "":
		dica = _dica_tatica(def)
	if dica != "":
		var b4 := _bloco("Dica", "estrela", UI.OURO)
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
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.lerp(cor_b, 0.14), 10, 2, cor_b))
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
		indice.add_child(UI.rotulo("Arquivo vazio.", 13, UI.TEXTO3))

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
		var ic := Control.new()
		ic.set_script(load("res://scripts/ui/icone_control.gd"))
		cab.add_child(ic)
		ic.configurar(_icone_capitulo(cid), cor if abertas > 0 else UI.TEXTO3, 17)
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
	b.tooltip_text = txt(ent, "titulo") if aberta else ("Trancada — " + _texto_cond(ent.get("cond", {})))

	var cx := UI.painel(UI.PAINEL2.darkened(0.3), 7)
	b.add_child(cx)
	cx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var h := UI.hbox(6)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10.0
	h.offset_right = -8.0
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(_icone_entrada(ent) if aberta else "cadeado", cor if aberta else UI.TEXTO3, 13)
	var l := UI.rotulo(txt(ent, "titulo") if aberta else "Entrada selada", 13,
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
		lore_texto.add_child(_aviso("Escolha uma entrada no índice à esquerda."))
		return
	var cap := _capitulo_por_id(str(ent.get("capitulo", "")))
	var cor := _cor(cap, "cor", "#93a3c4")
	var aberta := Progresso.cond_atendida(jogo.s, ent.get("cond", {}))

	var cab := UI.hbox(8)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	cab.add_child(ic)
	ic.configurar(_icone_capitulo(str(cap.get("id", ""))), cor, 18)
	cab.add_child(UI.rotulo(txt(cap, "nome").to_upper(), 12, cor))
	cab.add_child(UI.espacador())
	cab.add_child(UI.rotulo("Entrada %d de %d" % [int(ent.get("ordem", 0)),
		_entradas_do_capitulo(str(cap.get("id", ""))).size()], 12, UI.TEXTO3))
	lore_texto.add_child(cab)

	if not aberta:
		lore_texto.add_child(UI.rotulo("Entrada selada", 22, UI.TEXTO2))
		lore_texto.add_child(UI.separador())
		var av := _texto_corpo(
			"A Torre arquivou este documento, mas ainda não o entregou. Ela tem critérios.", UI.TEXTO3)
		lore_texto.add_child(av)
		var cond: Dictionary = ent.get("cond", {})
		var bloco := _bloco("Requisito", "cadeado", UI.LARANJA, lore_texto)
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
	var autor := UI.rotulo(str(ent.get("autor", "")), 12, cor.lerp(UI.TEXTO2, 0.4))
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
			cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.lerp(cor, 0.16), 7, 1, cor))
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
		lbl_progresso.text = "Arquivo: %d/%d entradas" % [abertas, Dados.entradas_lore.size()]
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
	lbl_progresso.text = ("Chefes derrotados: %d/%d" if aba == 1 else "Catalogados: %d/%d") % [vistos, lista.size()]
	if lbl_abates != null and is_instance_valid(lbl_abates):
		lbl_abates.text = "%s abate%s" % [Fmt.inteiro(_abates(sel_id)), "" if _abates(sel_id) == 1 else "s"]
	if _assinatura_bicho() != assinatura:
		_reconstruir()

# ============================================================== textos

func _texto_aparicao(def: Dictionary, chefe: bool) -> String:
	if chefe:
		var id := str(def.get("id", ""))
		for onda in range(10, 3010, 10):
			var c: Dictionary = Dados.chefe_da_onda(onda)
			if str(c.get("id", "")) == id:
				return "Guarda a onda %d" % onda
		return "Aparição irregular"
	return "A partir da onda %d" % int(def.get("onda", 1))

func _texto_mov(def: Dictionary, chefe: bool) -> String:
	if chefe:
		var f := maxi(1, int(def.get("fases", 1)))
		var base := "Avança devagar e sem desvio — não precisa de pressa."
		if f > 1:
			base += " Muda de comportamento a cada uma das %d fases, e cada troca o atordoa por um instante." % f
		return base
	match str(def.get("mov", "direto")):
		"direto": return "Avança em linha reta até a torre. Sem truque, sem hesitação."
		"zigue": return "Serpenteia em zigue-zague — projétil lento erra."
		"salto": return "Avança em arcos. Enquanto está no ar, nada o segura."
		"fantasma": return "Some e reaparece mais perto. Fica intangível no meio do salto."
		"teleporte": return "Pisca de um ponto a outro do campo, ignorando o caminho."
		"parar_atirar": return "Para no alcance e atira na torre em vez de encostar nela."
		"perseguidor": return "Persegue sem desviar e sem cansar. Corrige a rota o tempo todo."
		"errante": return "Trajetória errática, sem lógica aparente — nem para ele."
		"passa": return "Apenas atravessa o campo. Não ataca, não desvia, não olha."
	return "Avança em linha reta até a torre."

func _texto_hab(def: Dictionary, chefe: bool) -> String:
	if chefe:
		var extra := ""
		var invoca: Array = def.get("invoca", [])
		if not invoca.is_empty():
			var nomes: Array = []
			for iid in invoca:
				var d: Dictionary = Dados.inimigo_por_id.get(str(iid), {})
				nomes.append(txt(d, "nome") if not d.is_empty() else str(iid))
			extra = " Traz consigo: %s." % ", ".join(nomes)
		var seg := int(def.get("segmentos", 0))
		if seg > 1:
			extra += " Corpo em %d segmentos: cada um cai por vez." % seg
		match str(def.get("mecanica", "")):
			"invocar": return "Invoca reforços entre as fases e deixa que eles gastem seus tiros." + extra
			"ninhada": return "Põe crias mais rápido do que você as mata. A matemática é o chefe real." + extra
			"onda_choque": return "Pulsa em ondas de choque que machucam a torre de longe, sem encostar." + extra
			"fissuras": return "Abre fissuras no campo que corroem a sua invulnerabilidade." + extra
			"segmentos": return "Um corpo em vários anéis; enquanto houver anel, há chefe." + extra
			"refletir": return "Devolve ao atirador o dano que não for crítico." + extra
			"escudo_regen": return "Recupera escudo se ficar mais de um segundo e meio sem levar dano." + extra
			"teleporte_drenar": return "Teleporta para o colo da torre, drena vida e volta mais inteiro." + extra
			"silenciar": return "Bloqueia as suas habilidades por 5s a cada 12s. Silêncio é a arma." + extra
			"engolir": return "Engole projéteis e coletáveis, e engorda com cada gole." + extra
			"combinado": return "Tudo que o Enxame aprendeu, ao mesmo tempo, em fases." + extra
		return "Mecânica desconhecida — o arquivo está incompleto." + extra
	match str(def.get("hab", "")):
		"curar": return "Cura os aliados por perto em 6% da vida deles a cada 2s."
		"cuspir": return "Cospe projéteis na torre à distância, sem nunca encostar."
		"explodir": return "Explode ao morrer e leva a vizinhança junto — inclusive a sua paciência."
		"roubar_ouro": return "Recolhe o ouro caído no chão antes de você. Cada moeda dele é sua."
		"refletir": return "Devolve parte do dano não-crítico a quem atirou."
		"grudar": return "Gruda no casco da torre e drena vida sem pressa nenhuma."
		"chocar": return "Choca a cada 4,5s e solta três crias de Enxame."
		"devorar": return "Engole o ouro do chão, ganha vida e cresce a cada gole."
		"mutar": return "Alterna a cada 3s entre blindado e lento, e rápido e nu."
		"ceifar": return "A cada 5s, salta 120 unidades em direção à torre para ceifar de perto."
	return ""

func _dica_tatica(def: Dictionary) -> String:
	match str(def.get("hab", "")):
		"curar": return "Mate o curandeiro primeiro. Ele desfaz o seu trabalho de graça e sem pressa."
		"cuspir": return "Alcance e velocidade de projétil: ele morre antes de mirar."
		"explodir": return "Mate longe da torre. Ou aceite o troco."
		"roubar_ouro": return "Aumente a coleta — o que está no chão é dele até você pegar."
		"refletir": return "Crítico passa reto pelo espelho. Invista em chance crítica."
		"grudar": return "Não deixe encostar: cadência alta e área resolvem antes do abraço."
		"chocar": return "Dano em área antes que o casulo abra. Depois é limpeza."
		"devorar": return "Colete rápido ou negue o banquete — cada moeda o engorda."
		"mutar": return "Espere a janela sem armadura; ela chega a cada três segundos."
		"ceifar": return "Empurrões e gelo. Se ele fechar a distância, você já perdeu o turno."
	if bool(def.get("invisivel", false)):
		return "Só aparece quando revelado — leve algo que marque alvos."
	if bool(def.get("voa", false)):
		return "Voa: nada no chão o atrasa. Cadência resolve melhor que armadilha."
	if def.has("divide"):
		return "Ele vira dois. Área é o único jeito honesto de fechar a conta."
	if float(def.get("escudoFrac", 0.0)) > 0.0:
		return "Quebre o escudo de uma vez; ele volta se você der intervalo."
	if float(def.get("armadura", 0.0)) > 0.0:
		return "Armadura alta: leve penetração, não orgulho."
	if str(def.get("mov", "")) == "passa":
		return "Não faz nada com você. Faça você algo com ele — vale ouro."
	if float(def.get("vel", 1.0)) >= 1.4:
		return "Rápido demais para o alcance curto. Congele ou atire mais longe."
	if float(def.get("hp", 1.0)) >= 2.0:
		return "Saco de vida: dano bruto e paciência, nesta ordem."
	return "Nada de especial. Morre como todo mundo — só precisa de sua vez."

func _tracos(def: Dictionary, chefe: bool) -> Array:
	var out: Array = []
	if chefe:
		var f := int(def.get("fases", 1))
		if f > 1:
			out.append(["%d fases" % f, UI.ACENTO2])
		if int(def.get("segmentos", 0)) > 1:
			out.append(["%d segmentos" % int(def.get("segmentos", 0)), UI.ACENTO])
		if float(def.get("armadura", 0.0)) > 0.0:
			out.append(["Armadura %d" % int(def.get("armadura", 0)), UI.TEXTO2])
		for sc in Dados.super_chefes:
			var d: Dictionary = sc
			if str(d.get("id", "")) == str(def.get("id", "")):
				out.append(["Superchefe", UI.VERMELHO])
		return out
	if bool(def.get("voa", false)):
		out.append(["Voa", UI.ACENTO])
	if bool(def.get("invisivel", false)):
		out.append(["Invisível", UI.ACENTO2])
	if def.has("divide"):
		out.append(["Divide-se", UI.VERDE])
	if def.has("grupo"):
		var gr: Array = def.get("grupo", [])
		if gr.size() >= 2:
			out.append(["Bando de %d a %d" % [int(gr[0]), int(gr[1])], UI.VERDE])
		else:
			out.append(["Vem em bando", UI.VERDE])
	if float(def.get("armadura", 0.0)) > 0.0:
		out.append(["Armadura %d" % int(def.get("armadura", 0)), UI.TEXTO2])
	if float(def.get("escudoFrac", 0.0)) > 0.0:
		out.append(["Escudo", UI.ACENTO])
	if float(def.get("esc", 1.0)) >= 1.4:
		out.append(["Grande", UI.LARANJA])
	elif float(def.get("esc", 1.0)) <= 0.7:
		out.append(["Miúdo", UI.TEXTO2])
	return out

func _texto_cond(cond: Dictionary) -> String:
	var v := float(cond.get("valor", 0.0))
	var chave := str(cond.get("chave", ""))
	match str(cond.get("tipo", "")):
		"onda": return "Chegue à onda %d nesta corrida." % int(v)
		"ondaMaxima": return "Alcance a onda %d nesta ascensão." % int(v)
		"ondaMaximaGlobal": return "Alcance a onda %d alguma vez." % int(v)
		"ondasCompletas": return "Limpe %s ondas no total." % Fmt.inteiro(int(v))
		"inimigosMortos": return "Abata %s inimigos." % Fmt.inteiro(int(v))
		"chefesMortos": return "Derrote %s chefes." % Fmt.inteiro(int(v))
		"inimigoTipo":
			var d: Dictionary = Dados.inimigo_por_id.get(chave, {})
			if d.is_empty():
				for c in Dados.chefes:
					var cd: Dictionary = c
					if str(cd.get("id", "")) == chave:
						d = cd
			var nome := txt(d, "nome") if not d.is_empty() else chave
			return "Abata %s do tipo %s." % [Fmt.inteiro(int(v)), nome]
		"nivel": return "Chegue ao nível %d." % int(v)
		"mortes": return "Perca a torre %s vez(es). Vai acontecer." % Fmt.inteiro(int(v))
		"ouroTotal": return "Acumule %s de ouro no total." % Fmt.big(Big.from(v))
		"danoMaximo": return "Dê um golpe de %s de dano." % Fmt.big(Big.from(v))
		"tempoTotal": return "Some %s de jogo." % Ux.tempo_curto(v)
		"ascensoes": return "Ascenda %d vez(es)." % int(v)
		"singularidades": return "Colapse %d vez(es)." % int(v)
		"transcendencias": return "Transcenda %d vez(es)." % int(v)
		"cartas": return "Tenha %d cartas no inventário." % int(v)
		"lendarios": return "Ganhe %d carta(s) lendária(s)." % int(v)
		"relicas": return "Possua %d relíquia(s)." % int(v)
		"conquistasTotal": return "Desbloqueie %d conquistas." % int(v)
		"desafiosCompletos": return "Complete %d desafio(s)." % int(v)
		"criticos": return "Acerte %s críticos." % Fmt.inteiro(int(v))
		"tiros": return "Dispare %s tiros." % Fmt.inteiro(int(v))
		"comboMaximo": return "Chegue a um combo de %d." % int(v)
	return "Continue jogando. A Torre avisa quando achar apropriado."

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
	return e

func _botao_limpo(w: float, h: float) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
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
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(icone, cor, 13)
	h.add_child(UI.rotulo(titulo.to_upper(), 10, cor.lerp(UI.TEXTO3, 0.4)))
	v.add_child(h)
	return v

func _titulo_secao(texto: String, icone: String, cor: Color, dica: String) -> HBoxContainer:
	var h := UI.hbox(6)
	h.tooltip_text = dica
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(icone, cor, 16)
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
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(icone, cor, 14)
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
