extends "res://scripts/ui/panel_base.gd"

## Painel de CONQUISTAS — o mural de troféus da torre.
##
## Cabeçalho com o total desbloqueado, os pontos acumulados e o bônus global
## que eles concedem (a cada 10 pontos, +0,5% de dano e de ouro).
## Abas por categoria, filtro "só as que faltam" e, em cada linha, uma barra
## de progresso real: o jogador vê o quanto falta, não só o que já fez.
## Conquistas ocultas ficam como "???" até caírem — mas os pontos aparecem,
## porque esconder a recompensa inteira é sacanagem.

const BONUS_POR_PONTO := 0.0005      # 0,5% a cada 10 pontos

const COR_CAT := {
	"progresso": UI.ACENTO,
	"combate": UI.VERMELHO,
	"economia": UI.OURO,
	"colecao": UI.ACENTO2,
	"prestigio": UI.ROSA,
	"segredos": UI.LARANJA,
}

var abas: TabBar
var rolagem: ScrollContainer
var lista: VBoxContainer
var lbl_vazio: Label
var lbl_contagem: Label
var lbl_pontos: Label
var lbl_bonus: Label
var barra_total: ProgressBar
var check_faltam: CheckButton

var cats: Array = []            # [{id, nome}] com "todas" na frente
var cat_atual := 0
var so_faltam := false
var linhas: Dictionary = {}     # id -> registro de nós
var novas: Dictionary = {}      # id -> true (desbloqueada e ainda não vista)

func configurar() -> void:
	titulo_texto = "Conquistas"
	titulo_icone = "trofeu"
	largura = 960.0
	altura = 660.0
	intervalo = 0.4

# ------------------------------------------------------------------ montagem

func montar(c: VBoxContainer) -> void:
	_marcar_novas()

	# ---- resumo ----
	var topo := UI.painel(UI.PAINEL2.darkened(0.1), 12)
	var th := UI.hbox(18)
	topo.add_child(th)

	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	th.add_child(ic)
	ic.configurar("trofeu", UI.OURO, 34)

	var esq := UI.vbox(3)
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_contagem = UI.rotulo("0 de 0 desbloqueadas", 18, UI.TEXTO)
	esq.add_child(lbl_contagem)
	barra_total = UI.barra(UI.OURO, 9)
	barra_total.custom_minimum_size.x = 360
	barra_total.tooltip_text = "Progresso geral do mural."
	esq.add_child(barra_total)
	th.add_child(esq)

	var dir := UI.vbox(3)
	lbl_pontos = UI.rotulo("0 / 0 pontos", 17, UI.OURO)
	lbl_pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_pontos.tooltip_text = "Cada conquista vale pontos conforme a dificuldade."
	dir.add_child(lbl_pontos)
	lbl_bonus = UI.rotulo("", 13, UI.VERDE)
	lbl_bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_bonus.tooltip_text = "A cada 10 pontos de conquista: +0,5% de dano e +0,5% de ouro. Permanente, sobrevive a todo prestígio."
	dir.add_child(lbl_bonus)
	th.add_child(dir)
	c.add_child(topo)

	# ---- abas + filtro ----
	var barra_filtro := UI.hbox(10)
	abas = TabBar.new()
	abas.clip_tabs = false
	abas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cats = [{"id": "todas", "nome": "Todas"}]
	for item in Dados.categorias_conquista:
		var cat: Dictionary = item
		cats.append({"id": str(cat.get("id", "")), "nome": txt(cat, "nome")})
	for entrada in cats:
		var e: Dictionary = entrada
		abas.add_tab(str(e["nome"]))
	abas.tab_changed.connect(func(i):
		cat_atual = int(i)
		_reconstruir())
	barra_filtro.add_child(abas)

	check_faltam = CheckButton.new()
	check_faltam.text = "Só as que faltam"
	check_faltam.tooltip_text = "Esconde o que você já conquistou. Sobra a lista de coisas para fazer."
	check_faltam.toggled.connect(func(v):
		so_faltam = bool(v)
		_reconstruir())
	barra_filtro.add_child(check_faltam)
	c.add_child(barra_filtro)

	# ---- lista ----
	rolagem = UI.scroll()
	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_right", 12)
	margem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(margem)
	lista = UI.vbox(6)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margem.add_child(lista)
	c.add_child(rolagem)

	lbl_vazio = UI.rotulo("", 14, UI.TEXTO3)
	lbl_vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(lbl_vazio)

	_reconstruir()

## Guarda quais conquistas ainda não foram olhadas — elas ganham destaque.
func _marcar_novas() -> void:
	novas.clear()
	var vistas: Array = jogo.s["conquistas_vistas"]
	for id in jogo.s["conquistas"].keys():
		if not vistas.has(id):
			novas[str(id)] = true

## Ao fechar, tudo que estava piscando passa a ser história.
func _exit_tree() -> void:
	if jogo == null or not is_instance_valid(jogo):
		return
	var vistas: Array = jogo.s["conquistas_vistas"]
	var mudou := false
	for id in jogo.s["conquistas"].keys():
		if not vistas.has(id):
			vistas.append(id)
			mudou = true
	if mudou:
		jogo.marcar_sujo()

# ------------------------------------------------------------ reconstrução

func _reconstruir() -> void:
	for n in lista.get_children():
		lista.remove_child(n)
		n.queue_free()
	linhas.clear()
	var cat_id := "todas"
	if cat_atual >= 0 and cat_atual < cats.size():
		var entrada: Dictionary = cats[cat_atual]
		cat_id = str(entrada["id"])
	var mostradas := 0
	for item in Dados.conquistas:
		var def: Dictionary = item
		if cat_id != "todas" and str(def.get("cat", "")) != cat_id:
			continue
		var feita: bool = jogo.s["conquistas"].has(str(def.get("id", "")))
		if so_faltam and feita:
			continue
		_linha_conquista(def)
		mostradas += 1
	lbl_vazio.visible = mostradas == 0
	if mostradas == 0:
		lbl_vazio.text = "Nada aqui. Ou você conquistou tudo, ou o filtro está esperto demais."
	atualizar()

func _linha_conquista(def: Dictionary) -> void:
	var id := str(def.get("id", ""))
	var feita: bool = jogo.s["conquistas"].has(id)
	var oculta: bool = bool(def.get("oculta", false)) and not feita
	var cor: Color = COR_CAT.get(str(def.get("cat", "")), UI.ACENTO)
	var cor_ic := cor if feita else (UI.TEXTO3 if oculta else cor.darkened(0.35))
	var l := linha("cadeado" if oculta else _icone_de(def), cor_ic)

	# --- linha do nome ---
	var cabeca := UI.hbox(8)
	var nome := UI.rotulo("???" if oculta else txt(def, "nome"), 16, UI.TEXTO if feita else UI.TEXTO2)
	cabeca.add_child(nome)
	var selo := UI.rotulo("NOVA", 11, UI.VERDE)
	selo.visible = novas.has(id)
	selo.tooltip_text = "Desbloqueada desde a última vez que você abriu este mural."
	cabeca.add_child(selo)
	l["textos"].add_child(cabeca)

	# --- descrição ---
	var desc_txt := _frase_selada(id) if oculta else txt(def, "desc")
	var desc := UI.rotulo(desc_txt, 12, UI.TEXTO2 if feita else UI.TEXTO3)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 430
	l["textos"].add_child(desc)

	# --- progresso + recompensa, na mesma linha ---
	var lp := UI.hbox(8)
	var barra := UI.barra(UI.VERDE if feita else cor, 8)
	barra.custom_minimum_size.x = 190
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.tooltip_text = "Progresso rumo a algo que você ainda não deveria saber." if oculta else _dica_meta(def)
	lp.add_child(barra)
	var lbl_prog := UI.rotulo("", 12, UI.TEXTO3)
	lp.add_child(lbl_prog)
	lp.add_child(UI.rotulo("·", 12, UI.BORDA_FORTE))

	var rec: Dictionary = def.get("recompensa", {})
	var ic_rec := Control.new()
	ic_rec.set_script(load("res://scripts/ui/icone_control.gd"))
	lp.add_child(ic_rec)
	var cor_rec: Color = _cor_recompensa(rec)
	ic_rec.configurar("cadeado" if oculta else _icone_recompensa(rec), UI.TEXTO3 if oculta else (cor_rec if feita else cor_rec.darkened(0.4)), 14)
	var lbl_rec := UI.rotulo("recompensa selada" if oculta else _texto_recompensa(rec), 12, UI.TEXTO3 if oculta else (cor_rec if feita else UI.TEXTO3))
	lbl_rec.tooltip_text = "O prêmio só aparece quando o registro abrir." if oculta else "Recompensa entregue no instante em que a conquista cai."
	lp.add_child(lbl_rec)
	l["textos"].add_child(lp)

	# --- coluna direita: pontos e data ---
	var col := UI.vbox(2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var pontos := int(def.get("pontos", 5))
	var lp2 := UI.rotulo("%d pts" % pontos, 17, UI.OURO if feita else UI.TEXTO3)
	lp2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lp2.tooltip_text = "Vale %d pontos para o bônus global." % pontos
	col.add_child(lp2)
	var ldata := UI.rotulo("", 11, UI.TEXTO3)
	ldata.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(ldata)
	l["direita"].add_child(col)

	l["caixa"].tooltip_text = "Conquista oculta: nem a meta aparece. A barra mede o quanto falta." if oculta else _dica_meta(def)
	lista.add_child(l["caixa"])
	linhas[id] = {
		"def": def, "caixa": l["caixa"], "icone": l["icone"], "nome": nome, "desc": desc,
		"selo": selo, "barra": barra, "prog": lbl_prog, "data": ldata, "pontos": lp2,
		"ic_rec": ic_rec, "lbl_rec": lbl_rec, "feita": feita, "cor": cor, "oculta": oculta,
	}
	var reg: Dictionary = linhas[id]
	_pintar(reg, feita)

func _pintar(reg: Dictionary, feita: bool) -> void:
	var cor: Color = reg["cor"]
	var caixa: PanelContainer = reg["caixa"]
	var selo: Label = reg["selo"]
	var destaque := feita and selo.visible
	if destaque:
		caixa.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.lerp(UI.VERDE, 0.1), 10, 2, UI.VERDE))
	elif feita:
		caixa.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2, 10, 1, cor.darkened(0.4)))
	else:
		caixa.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.3), 10, 1, UI.BORDA.darkened(0.2)))

# ----------------------------------------------------------- atualização

func atualizar() -> void:
	if jogo == null or lbl_contagem == null:
		return
	var feitas := int(jogo.s["conquistas"].size())
	var total := int(Dados.conquistas.size())
	var pontos := 0
	for id in jogo.s["conquistas"].keys():
		var def: Dictionary = Dados.conquista_por_id.get(id, {})
		pontos += int(def.get("pontos", 5))
	lbl_contagem.text = "%d de %d desbloqueadas" % [feitas, total]
	barra_total.value = float(feitas) / maxf(1.0, float(total))
	lbl_pontos.text = "%s / %s pontos" % [Fmt.inteiro(pontos), Fmt.inteiro(int(Dados.pontos_totais))]
	var bonus := float(pontos) * BONUS_POR_PONTO
	lbl_bonus.text = "Bônus global: +%s de dano e de ouro" % Fmt.pct(bonus)
	lbl_bonus.add_theme_color_override("font_color", UI.VERDE if bonus > 0.0 else UI.TEXTO3)

	_atualizar_abas()

	for chave in linhas.keys():
		var reg: Dictionary = linhas[chave]
		var def: Dictionary = reg["def"]
		var id := str(def.get("id", ""))
		var feita: bool = jogo.s["conquistas"].has(id)

		# caiu agora, com o painel aberto: revela e comemora
		if feita and not bool(reg["feita"]):
			reg["feita"] = true
			novas[id] = true
			var selo: Label = reg["selo"]
			selo.visible = true
			var lnome: Label = reg["nome"]
			lnome.text = txt(def, "nome")
			lnome.add_theme_color_override("font_color", UI.TEXTO)
			var ldesc: Label = reg["desc"]
			ldesc.text = txt(def, "desc")
			ldesc.add_theme_color_override("font_color", UI.TEXTO2)
			var lpts: Label = reg["pontos"]
			lpts.add_theme_color_override("font_color", UI.OURO)
			reg["oculta"] = false
			var ic: Control = reg["icone"]
			ic.configurar(_icone_de(def), reg["cor"], 26)
			var rec_nova: Dictionary = def.get("recompensa", {})
			var ic_rec: Control = reg["ic_rec"]
			ic_rec.configurar(_icone_recompensa(rec_nova), _cor_recompensa(rec_nova), 14)
			var lbl_rec: Label = reg["lbl_rec"]
			lbl_rec.text = _texto_recompensa(rec_nova)
			lbl_rec.add_theme_color_override("font_color", _cor_recompensa(rec_nova))
			var barra_nova: ProgressBar = reg["barra"]
			barra_nova.add_theme_stylebox_override("fill", UI.caixa(UI.VERDE, 4, 0))
			_pintar(reg, true)
			var cx: PanelContainer = reg["caixa"]
			UI.pulsar(cx, UI.VERDE)

		var cond: Dictionary = def.get("cond", {})
		var alvo: float = maxf(1.0, float(cond.get("valor", 1)))
		var atual: float = Progresso.valor_cond(jogo.s, str(cond.get("tipo", "")), str(cond.get("chave", "")))
		if feita:
			atual = maxf(atual, alvo)
		var barra: ProgressBar = reg["barra"]
		barra.value = clampf(atual / alvo, 0.0, 1.0)
		var lbl_prog: Label = reg["prog"]
		var tipo := str(cond.get("tipo", ""))
		if bool(reg["oculta"]):
			lbl_prog.text = "meta selada"
		else:
			lbl_prog.text = "%s / %s" % [_valor(minf(atual, alvo), tipo), _valor(alvo, tipo)]
		lbl_prog.add_theme_color_override("font_color", UI.VERDE if feita else UI.TEXTO3)
		var ldata: Label = reg["data"]
		if feita:
			ldata.text = _data(int(jogo.s["conquistas"].get(id, 0)))
		else:
			ldata.text = Fmt.pct(clampf(atual / alvo, 0.0, 1.0), 0)

func _atualizar_abas() -> void:
	if abas == null:
		return
	var por_cat: Dictionary = {}
	var tot_cat: Dictionary = {}
	for item in Dados.conquistas:
		var def: Dictionary = item
		var cat := str(def.get("cat", ""))
		tot_cat[cat] = int(tot_cat.get(cat, 0)) + 1
		if jogo.s["conquistas"].has(str(def.get("id", ""))):
			por_cat[cat] = int(por_cat.get(cat, 0)) + 1
	for i in cats.size():
		var entrada: Dictionary = cats[i]
		var id := str(entrada["id"])
		var nome := str(entrada["nome"])
		if id == "todas":
			abas.set_tab_title(i, "%s  %d/%d" % [nome, int(jogo.s["conquistas"].size()), Dados.conquistas.size()])
		else:
			abas.set_tab_title(i, "%s  %d/%d" % [nome, int(por_cat.get(id, 0)), int(tot_cat.get(id, 0))])

# ------------------------------------------------------------- utilidades

## Descrições seladas variadas — repetir a mesma frase 10 vezes é preguiça.
func _frase_selada(id: String) -> String:
	var frases := [
		"Registro selado. Faça algo estranho o bastante e ele se abre.",
		"O Comando classificou esta entrada. A barra abaixo é tudo que vazou.",
		"Ninguém escreveu esta regra. Alguém, um dia, vai tropeçar nela.",
		"Existe. Conta pontos. Não pergunte mais nada.",
	]
	return str(frases[absi(id.hash()) % frases.size()])

func _valor(v: float, tipo: String) -> String:
	if tipo == "tempoTotal":
		return Ux.tempo_curto(v)
	if is_inf(v) or v >= 1000000.0:
		return Fmt.num(v)
	return Fmt.inteiro(int(round(v)))

func _data(ts: int) -> String:
	if ts <= 0:
		return "—"
	var d := Time.get_datetime_dict_from_unix_time(ts)
	return "%02d/%02d/%02d" % [int(d["day"]), int(d["month"]), int(d["year"]) % 100]

func _dica_meta(def: Dictionary) -> String:
	var cond: Dictionary = def.get("cond", {})
	var tipo := str(cond.get("tipo", ""))
	var alvo: float = float(cond.get("valor", 0))
	var chave := str(cond.get("chave", ""))
	var alvo_txt := _valor(alvo, tipo)
	match tipo:
		"onda": return "Chegue à onda %s nesta corrida." % alvo_txt
		"ondaMaxima": return "Melhor onda desta ascensão: %s." % alvo_txt
		"ondaMaximaGlobal": return "Melhor onda de todos os tempos: %s." % alvo_txt
		"ondasCompletas": return "Complete %s ondas ao todo." % alvo_txt
		"inimigosMortos": return "Abata %s inimigos ao todo." % alvo_txt
		"inimigoTipo": return "Abata %s inimigos do tipo '%s'." % [alvo_txt, chave]
		"chefesMortos": return "Derrube %s chefes." % alvo_txt
		"criticos": return "Acerte %s golpes críticos." % alvo_txt
		"tiros": return "Dispare %s projéteis." % alvo_txt
		"danoMaximo": return "Dê um único golpe de %s de dano." % alvo_txt
		"comboMaximo": return "Chegue a um combo de %s." % alvo_txt
		"ouroTotal": return "Acumule %s de ouro ao longo do jogo." % alvo_txt
		"ouroGasto": return "Gaste %s de ouro em melhorias." % alvo_txt
		"nivel": return "Chegue ao nível %s." % alvo_txt
		"tempoTotal": return "Jogue por %s no total." % alvo_txt
		"mortes": return "Perca a torre %s vezes. Sim, isso conta." % alvo_txt
		"habilidadesUsadas": return "Use habilidades %s vezes." % alvo_txt
		"douradosAbatidos", "dourados": return "Abata %s inimigos dourados." % alvo_txt
		"cartas": return "Tenha %s cartas no inventário." % alvo_txt
		"lendarios": return "Encontre %s cartas lendárias." % alvo_txt
		"relicas": return "Tenha %s relíquias." % alvo_txt
		"ascensoes": return "Ascenda %s vezes." % alvo_txt
		"singularidades": return "Colapse %s vezes." % alvo_txt
		"transcendencias": return "Transcenda %s vezes." % alvo_txt
		"upgradeNivel": return "Leve a melhoria '%s' ao nível %s." % [chave, alvo_txt]
		"talentoNivel": return "Leve o talento '%s' ao nível %s." % [chave, alvo_txt]
		"missoesCompletas": return "Complete %s missões." % alvo_txt
		"desafiosCompletos": return "Complete %s desafios." % alvo_txt
		"conquistasTotal": return "Desbloqueie %s conquistas." % alvo_txt
		"eras": return "Veja %s eras diferentes." % alvo_txt
		"gemas", "fragmentos", "nucleos", "eter": return "Tenha %s de %s guardados." % [alvo_txt, tipo]
	return "Meta: %s" % alvo_txt

func _icone_de(def: Dictionary) -> String:
	var cond: Dictionary = def.get("cond", {})
	match str(cond.get("tipo", "")):
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
		"singularidades": return "vazio"
		"transcendencias": return "nova"
		"upgradeNivel": return "espada"
		"talentoNivel": return "arvore"
		"missoesCompletas": return "missao"
		"desafiosCompletos": return "desafio"
		"conquistasTotal": return "trofeu"
		"eras": return "livro"
	return "trofeu"

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
		return "Só a glória, e os pontos."
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
				return "%s ×%s permanente" % [nome, Fmt.num(v, 2)]
			return "%s +%s permanente" % [nome, Fmt.pct(v)]
	return "Recompensa misteriosa"
