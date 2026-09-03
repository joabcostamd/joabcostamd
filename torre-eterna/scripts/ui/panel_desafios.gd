extends "res://scripts/ui/panel_base.gd"

## Painel de DESAFIOS — runs com regras torcidas e recompensa permanente.
## Cada cartão traduz os modificadores crus do JSON para frases que um humano
## lê antes de aceitar sofrer: "Inimigos com 5x de vida", "Sem habilidades
## ativas", "A torre tem 1 de vida".

const ORDEM_MODS := [
	"vidaFixa", "hpInimigo", "velocidadeInimigo", "densidade", "danoTorre", "cadencia",
	"ouro", "xp", "ondaAuto", "semHabilidades", "semUpgrades", "semOrbes", "semCritico", "semRegen",
]
const FILTROS := [["todos", "Todos"], ["abertos", "Disponíveis"], ["completos", "Vencidos"]]
const LARGURA_CARD := 860.0

var lista: VBoxContainer
var filtro := "todos"
var botoes_filtro := []

var faixa: PanelContainer
var faixa_icone: Control
var faixa_nome: Label
var faixa_obj: Label
var faixa_barra: ProgressBar
var faixa_bt: Button
var faixa_vitoria: Button

var lbl_progresso: Label
var barra_progresso: ProgressBar
var cartoes := {}

var dlg: Control
var dlg_titulo: Label
var dlg_corpo: Label
var dlg_aviso: Label
var dlg_sim: Button
var _pendente := {}

func configurar() -> void:
	titulo_texto = "Desafios"
	titulo_icone = "desafio"
	largura = 960.0
	altura = 690.0
	intervalo = 0.2
	# trancado: uma janela pequena, só com o recado
	if jogo != null and not jogo.esp["desbloqueios"].has("desafios"):
		largura = 700.0
		altura = 176.0

# ================================================================== montagem

func montar(c: VBoxContainer) -> void:
	if not jogo.esp["desbloqueios"].has("desafios"):
		c.add_child(_vazio_trancado())
		return
	if Dados.desafios.is_empty():
		c.add_child(UI.rotulo("Nenhum desafio catalogado — o Enxame não teve ideias hoje.", 14, UI.TEXTO3))
		return

	c.add_child(_topo())
	faixa = _faixa()
	c.add_child(faixa)

	var rol := UI.scroll()
	lista = UI.vbox(8)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(lista)
	c.add_child(rol)

	_montar_dialogo()
	_reconstruir()

func _vazio_trancado() -> PanelContainer:
	var cx := UI.painel(UI.PAINEL2.darkened(0.2), 12)
	var v := UI.vbox(8)
	cx.add_child(v)
	var h := UI.hbox(10)
	v.add_child(h)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar("cadeado", UI.TEXTO3, 26)
	h.add_child(UI.rotulo("Os Desafios ainda estão lacrados", 18, UI.TEXTO2))
	var l := UI.rotulo("Compre 'Provações' na árvore de Núcleos (painel de Prestígio) para abrir as provações.\nSão runs com as regras torcidas: você aceita uma desvantagem e leva um bônus permanente.", 13, UI.TEXTO3)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 620
	v.add_child(l)
	return cx

func _topo() -> HBoxContainer:
	var h := UI.hbox(10)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	lbl_progresso = UI.rotulo("", 14, UI.TEXTO2)
	v.add_child(lbl_progresso)
	barra_progresso = UI.barra(UI.OURO, 8)
	barra_progresso.custom_minimum_size.x = 300
	v.add_child(barra_progresso)

	h.add_child(UI.espacador())
	for item in FILTROS:
		var par: Array = item
		var b := UI.botao(str(par[1]), func(): _definir_filtro(str(par[0])))
		b.custom_minimum_size = Vector2(112, 32)
		b.toggle_mode = true
		b.button_pressed = str(par[0]) == filtro
		h.add_child(b)
		botoes_filtro.append({"botao": b, "valor": str(par[0])})
	return h

func _definir_filtro(v: String) -> void:
	filtro = v
	for item in botoes_filtro:
		var r: Dictionary = item
		r["botao"].button_pressed = str(r["valor"]) == v
	_reconstruir()

# ============================================================ faixa do ativo

func _faixa() -> PanelContainer:
	var cx := PanelContainer.new()
	cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.1), 10, 2, UI.LARANJA.darkened(0.3)))
	cx.visible = false
	var v := UI.vbox(4)
	cx.add_child(v)

	var h := UI.hbox(10)
	v.add_child(h)
	faixa_icone = Control.new()
	faixa_icone.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(faixa_icone)
	faixa_icone.configurar("desafio", UI.LARANJA, 26)
	var t := UI.vbox(0)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	t.add_child(UI.rotulo("DESAFIO EM ANDAMENTO", 10, UI.TEXTO3))
	faixa_nome = UI.rotulo("", 17, UI.LARANJA)
	t.add_child(faixa_nome)
	faixa_obj = UI.rotulo("", 12, UI.TEXTO2)
	t.add_child(faixa_obj)

	faixa_vitoria = UI.botao("RECLAMAR VITÓRIA", func(): _reclamar(), "Objetivo cumprido — leve a recompensa permanente.")
	faixa_vitoria.custom_minimum_size = Vector2(180, 40)
	faixa_vitoria.add_theme_color_override("font_color", UI.VERDE)
	faixa_vitoria.visible = false
	h.add_child(faixa_vitoria)

	faixa_bt = UI.botao("Abandonar", func(): _pedir_abandono(), "Encerra o desafio e reinicia a run normal.")
	faixa_bt.custom_minimum_size = Vector2(120, 40)
	faixa_bt.add_theme_color_override("font_color", UI.VERMELHO)
	h.add_child(faixa_bt)

	faixa_barra = UI.barra(UI.LARANJA, 8)
	v.add_child(faixa_barra)
	return cx

# =================================================================== cartões

func _reconstruir() -> void:
	if lista == null:
		return
	for n in lista.get_children():
		lista.remove_child(n)
		n.queue_free()
	cartoes.clear()

	var mostrados := 0
	for item in Dados.desafios:
		var def: Dictionary = item
		var estado := _estado(def)
		if filtro == "abertos" and estado != "aberto" and estado != "ativo":
			continue
		if filtro == "completos" and estado != "completo":
			continue
		lista.add_child(_cartao(def))
		mostrados += 1
	if mostrados == 0:
		var l := UI.rotulo(_texto_vazio(), 13, UI.TEXTO3)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = LARGURA_CARD
		lista.add_child(l)
	atualizar()

func _texto_vazio() -> String:
	match filtro:
		"abertos": return "Nenhum desafio disponível agora — suba de onda, acumule núcleos e ascensões e eles vão abrindo."
		"completos": return "Nenhum desafio vencido ainda. O primeiro é sempre o mais caro."
	return "Nada por aqui."

func _cartao(def: Dictionary) -> PanelContainer:
	var id := str(def.get("id", ""))
	var cor := Color.html(str(def.get("cor", "#38bdf8")))
	var cx := PanelContainer.new()
	cx.custom_minimum_size.x = LARGURA_CARD
	cx.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2.darkened(0.2), 10, 1, UI.BORDA))
	var v := UI.vbox(5)
	cx.add_child(v)

	# ---- cabeçalho ----
	var cab := UI.hbox(10)
	v.add_child(cab)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	cab.add_child(ic)
	ic.configurar(_icone_desafio(id), cor, 28)

	var t := UI.vbox(1)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	t.add_child(UI.rotulo(txt(def, "nome"), 17, cor))
	var dif := UI.hbox(6)
	t.add_child(dif)
	dif.add_child(_pips(int(def.get("dificuldade", 1)), cor))
	dif.add_child(UI.rotulo("dificuldade %d de 5" % int(def.get("dificuldade", 1)), 11, UI.TEXTO3))

	var lado := UI.vbox(3)
	lado.alignment = BoxContainer.ALIGNMENT_CENTER
	cab.add_child(lado)
	var b := UI.botao("Iniciar", func(): _pedir_inicio(id))
	b.custom_minimum_size = Vector2(160, 40)
	lado.add_child(b)
	var badge := UI.rotulo("", 11, UI.TEXTO3)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lado.add_child(badge)

	# ---- descrição ----
	var desc := UI.rotulo(txt(def, "desc"), 12, UI.TEXTO2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = LARGURA_CARD - 40.0
	v.add_child(desc)
	v.add_child(UI.separador())

	# ---- colunas: modificadores | objetivo e recompensa ----
	var col := UI.hbox(18)
	v.add_child(col)

	var esq := UI.vbox(2)
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(esq)
	esq.add_child(UI.rotulo("AS REGRAS MUDAM ASSIM", 10, UI.TEXTO3))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 1)
	esq.add_child(g)
	for frase in _frases_mods(def):
		var f: Dictionary = frase
		var l := UI.rotulo("— " + str(f["texto"]), 12, f["cor"])
		l.custom_minimum_size.x = 232
		g.add_child(l)

	var dir := UI.vbox(2)
	dir.custom_minimum_size.x = 320
	col.add_child(dir)
	dir.add_child(UI.rotulo("OBJETIVO", 10, UI.TEXTO3))
	dir.add_child(UI.rotulo("Chegar à onda %d — a run termina ali." % int(def.get("objetivo", {}).get("onda", 0)), 12, UI.TEXTO))
	dir.add_child(UI.rotulo("RECOMPENSA PERMANENTE", 10, UI.TEXTO3))
	for texto in _recompensas(def):
		dir.add_child(UI.rotulo("·  " + str(texto), 12, UI.OURO))

	# ---- lore + tentativas ----
	var pe := UI.hbox(8)
	v.add_child(pe)
	var lore := UI.rotulo(str(def.get("lore", "")), 11, UI.TEXTO3)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size.x = LARGURA_CARD - 200.0
	lore.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pe.add_child(lore)
	var tent := UI.rotulo("", 11, UI.TEXTO3)
	pe.add_child(tent)

	cartoes[id] = {"def": def, "cor": cor, "caixa": cx, "botao": b, "badge": badge,
		"tentativas": tent, "icone": ic, "estado": ""}
	return cx

## Cinco losangos: os cheios contam a dificuldade.
func _pips(nivel: int, cor: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(72, 14)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		for i in 5:
			var p := Vector2(7.0 + float(i) * 13.0, 7.0)
			if i < nivel:
				c.draw_circle(p, 5.0, Ux.com_alfa(cor, 0.25))
				c.draw_circle(p, 3.2, cor)
			else:
				c.draw_arc(p, 3.6, 0.0, TAU, 12, Ux.com_alfa(UI.TEXTO3, 0.7), 1.2, true))
	return c

# ==================================================================== estado

func _estado(def: Dictionary) -> String:
	var id := str(def.get("id", ""))
	if str(jogo.s["desafios"]["ativo"]) == id:
		return "ativo"
	if jogo.s["desafios"]["completos"].has(id):
		return "completo"
	if not _faltando(def).is_empty():
		return "bloqueado"
	return "aberto"

## Requisitos ainda não cumpridos, em texto.
func _faltando(def: Dictionary) -> Array:
	var req: Dictionary = def.get("requer", {})
	var out: Array = []
	if req.has("nucleos") and not Big.gte(float(jogo.s["moedas"]["nucleos"]), Big.from(float(req["nucleos"]))):
		out.append("%s núcleos" % Fmt.num(float(req["nucleos"]), 0))
	if req.has("ascensoes") and int(jogo.s["prestigio"]["ascensoes"]) < int(req["ascensoes"]):
		out.append("%d ascensões" % int(req["ascensoes"]))
	if req.has("onda") and int(jogo.s["onda_maxima_global"]) < int(req["onda"]):
		out.append("onda %d" % int(req["onda"]))
	return out

# =================================================================== ações

func _pedir_inicio(id: String) -> void:
	var def: Dictionary = Dados.desafio_por_id.get(id, {})
	if def.is_empty():
		return
	var falta := _faltando(def)
	if not falta.is_empty():
		Bus.toast("Bloqueado — falta " + " e ".join(falta), "info")
		return
	_pendente = {"acao": "iniciar", "id": id}
	dlg_titulo.text = "Entrar em %s?" % txt(def, "nome")
	dlg_titulo.add_theme_color_override("font_color", Color.html(str(def.get("cor", "#38bdf8"))))
	var linhas: Array = []
	for frase in _frases_mods(def):
		var f: Dictionary = frase
		linhas.append("— " + str(f["texto"]))
	dlg_corpo.text = "\n".join(linhas)
	dlg_aviso.text = "A RUN ATUAL SERÁ REINICIADA: ouro, melhorias, nível e onda voltam ao zero. Fragmentos, cartas e relíquias continuam onde estão."
	dlg_sim.text = "COMEÇAR"
	dlg_sim.add_theme_color_override("font_color", UI.TEXTO)
	dlg.visible = true
	UI.saltar(dlg, 1.05)

func _pedir_abandono() -> void:
	var id := str(jogo.s["desafios"]["ativo"])
	if id == "":
		return
	var def: Dictionary = Dados.desafio_por_id.get(id, {})
	_pendente = {"acao": "abandonar", "id": id}
	dlg_titulo.text = "Abandonar %s?" % txt(def, "nome")
	dlg_titulo.add_theme_color_override("font_color", UI.VERMELHO)
	dlg_corpo.text = "Você para na onda %d, sem recompensa. A tentativa fica registrada." % int(jogo.s["onda"])
	dlg_aviso.text = "A RUN ATUAL SERÁ REINICIADA: ouro, melhorias, nível e onda voltam ao zero."
	dlg_sim.text = "ABANDONAR"
	dlg_sim.add_theme_color_override("font_color", UI.VERMELHO)
	dlg.visible = true
	UI.saltar(dlg, 1.05)

func _confirmar() -> void:
	dlg.visible = false
	var acao := str(_pendente.get("acao", ""))
	var id := str(_pendente.get("id", ""))
	_pendente = {}
	if acao == "iniciar":
		if bool(jogo.iniciar_desafio(id)):
			var def: Dictionary = Dados.desafio_por_id.get(id, {})
			Bus.toast("Desafio iniciado: " + txt(def, "nome"), "epico")
			UI.pulsar(janela, Color.html(str(def.get("cor", "#38bdf8"))))
			_reconstruir()
		else:
			Bus.toast("Não foi possível iniciar o desafio", "ruim")
	elif acao == "abandonar":
		jogo.encerrar_desafio(false)
		Bus.toast("Desafio abandonado — a torre volta ao normal", "info")
		_reconstruir()

func _reclamar() -> void:
	var id := str(jogo.s["desafios"]["ativo"])
	if id == "":
		return
	var def: Dictionary = Dados.desafio_por_id.get(id, {})
	jogo.encerrar_desafio(true)
	Bus.toast("Desafio vencido: " + txt(def, "nome"), "epico")
	UI.pulsar(janela, UI.OURO)
	UI.saltar(janela, 1.06)
	_reconstruir()

func _montar_dialogo() -> void:
	dlg = Control.new()
	dlg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dlg.visible = false
	add_child(dlg)

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.6)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	dlg.add_child(fundo)

	var cx := UI.painel(UI.PAINEL, 14)
	cx.anchor_left = 0.5
	cx.anchor_right = 0.5
	cx.anchor_top = 0.5
	cx.anchor_bottom = 0.5
	cx.offset_left = -260
	cx.offset_right = 260
	cx.offset_top = -170
	cx.offset_bottom = 170
	dlg.add_child(cx)

	var v := UI.vbox(8)
	cx.add_child(v)
	dlg_titulo = UI.rotulo("", 22, UI.ACENTO)
	v.add_child(dlg_titulo)
	v.add_child(UI.separador())
	dlg_corpo = UI.rotulo("", 13, UI.TEXTO2)
	dlg_corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_corpo.custom_minimum_size.x = 470
	dlg_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(dlg_corpo)
	var aviso_cx := UI.painel(UI.VERMELHO.darkened(0.78), 8)
	dlg_aviso = UI.rotulo("", 12, UI.VERMELHO.lerp(UI.TEXTO, 0.3))
	dlg_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_aviso.custom_minimum_size.x = 450
	aviso_cx.add_child(dlg_aviso)
	v.add_child(aviso_cx)

	var h := UI.hbox(8)
	v.add_child(h)
	var nao := UI.botao("Cancelar", func(): dlg.visible = false)
	nao.custom_minimum_size = Vector2(150, 42)
	h.add_child(nao)
	h.add_child(UI.espacador())
	dlg_sim = UI.botao("", _confirmar)
	dlg_sim.custom_minimum_size = Vector2(200, 42)
	dlg_sim.add_theme_font_size_override("font_size", 16)
	h.add_child(dlg_sim)

# ================================================================ atualizar

func atualizar() -> void:
	if jogo == null or lista == null:
		return
	var ativo := str(jogo.s["desafios"]["ativo"])
	var completos: Dictionary = jogo.s["desafios"]["completos"]

	if lbl_progresso != null:
		var total := Dados.desafios.size()
		var venc := 0
		for item in Dados.desafios:
			var d: Dictionary = item
			if completos.has(str(d.get("id", ""))):
				venc += 1
		lbl_progresso.text = "%d de %d provações vencidas" % [venc, total]
		barra_progresso.value = float(venc) / float(maxi(1, total))

	# ---- faixa do desafio ativo ----
	faixa.visible = ativo != ""
	if ativo != "":
		var def: Dictionary = Dados.desafio_por_id.get(ativo, {})
		var alvo := int(def.get("objetivo", {}).get("onda", 1))
		var onda := int(jogo.s["onda"])
		var melhor := int(jogo.s["onda_maxima"])
		var cor := Color.html(str(def.get("cor", "#fb923c")))
		faixa_icone.configurar(_icone_desafio(ativo), cor, 26)
		faixa_nome.text = txt(def, "nome")
		faixa_nome.add_theme_color_override("font_color", cor)
		faixa_obj.text = "Onda %d de %d — chegue lá e a recompensa é sua para sempre." % [onda, alvo]
		faixa_barra.value = clampf(float(melhor) / float(maxi(1, alvo)), 0.0, 1.0)
		faixa_vitoria.visible = melhor >= alvo

	# ---- cartões ----
	for chave in cartoes.keys():
		var id := str(chave)
		var r: Dictionary = cartoes[id]
		var def2: Dictionary = r["def"]
		var estado := _estado(def2)
		var tentativas := int(jogo.s["desafios"]["tentativas"].get(id, 0))
		var marca := "%s|%d|%s" % [estado, tentativas, ativo]
		var tent: Label = r["tentativas"]
		tent.text = "" if tentativas == 0 else ("1 tentativa" if tentativas == 1 else "%d tentativas" % tentativas)
		if str(r["estado"]) == marca:
			continue
		r["estado"] = marca

		var b: Button = r["botao"]
		var badge: Label = r["badge"]
		var cx: PanelContainer = r["caixa"]
		var cor2: Color = r["cor"]
		var cor_borda := UI.BORDA
		var fundo := UI.PAINEL2.darkened(0.2)
		b.disabled = false
		b.visible = true

		match estado:
			"ativo":
				b.text = "Abandonar"
				badge.text = "EM ANDAMENTO"
				badge.add_theme_color_override("font_color", UI.LARANJA)
				cor_borda = UI.LARANJA
				fundo = UI.PAINEL2.darkened(0.2).lerp(UI.LARANJA.darkened(0.75), 0.5)
				b.visible = false
			"completo":
				b.text = "Refazer"
				b.disabled = ativo != ""
				badge.text = "VENCIDO em " + _data(int(completos.get(id, 0)))
				badge.add_theme_color_override("font_color", UI.VERDE)
				cor_borda = UI.VERDE.darkened(0.3)
				fundo = UI.PAINEL2.darkened(0.2).lerp(UI.VERDE.darkened(0.8), 0.4)
			"bloqueado":
				b.text = "Bloqueado"
				b.disabled = true
				badge.text = "falta " + " · ".join(_faltando(def2))
				badge.add_theme_color_override("font_color", UI.TEXTO3)
				cx.modulate = Color(1, 1, 1, 0.78)
			_:
				b.text = "Iniciar"
				b.disabled = ativo != ""
				badge.text = "disponível" if ativo == "" else "termine o desafio atual"
				badge.add_theme_color_override("font_color", UI.TEXTO3)
				cor_borda = cor2.darkened(0.45)
		if estado != "bloqueado":
			cx.modulate = Color(1, 1, 1, 1)
		cx.add_theme_stylebox_override("panel", UI.caixa(fundo, 10, 1, cor_borda))
		var ic: Control = r["icone"]
		ic.configurar(_icone_desafio(id), cor2 if estado != "bloqueado" else UI.TEXTO3, 28)
		b.tooltip_text = "Reinicia a run atual e liga os modificadores deste desafio."

# ================================================== tradução dos modificadores

func _frases_mods(def: Dictionary) -> Array:
	var mods: Dictionary = def.get("mods", {})
	var out: Array = []
	var vistos := {}
	for chave in ORDEM_MODS:
		if mods.has(chave):
			vistos[chave] = true
			var f := _frase_mod(str(chave), mods[chave])
			if not f.is_empty():
				out.append(f)
	for chave2 in mods.keys():
		var k := str(chave2)
		if vistos.has(k) or k == "ondaMax":
			continue
		var f2 := _frase_mod(k, mods[k])
		if not f2.is_empty():
			out.append(f2)
	return out

func _frase_mod(chave: String, valor) -> Dictionary:
	var ruim := UI.VERMELHO.lerp(UI.TEXTO, 0.25)
	var bom := UI.VERDE.lerp(UI.TEXTO, 0.2)
	if valor is bool:
		if not bool(valor):
			return {}
		match chave:
			"semHabilidades": return {"texto": "Sem habilidades ativas", "cor": ruim}
			"semUpgrades": return {"texto": "Loja de melhorias fechada a run inteira", "cor": ruim}
			"semOrbes": return {"texto": "Sem orbes — de carta, talento ou habilidade", "cor": ruim}
			"semCritico": return {"texto": "Sem acertos críticos", "cor": ruim}
			"semRegen": return {"texto": "Sem regeneração de vida", "cor": ruim}
		return {"texto": chave, "cor": UI.TEXTO2}

	var v := float(valor)
	match chave:
		"vidaFixa":
			return {"texto": "A torre tem %s de vida" % Fmt.num(v, 0), "cor": ruim}
		"hpInimigo":
			if v > 1.0:
				return {"texto": "Inimigos com %sx de vida" % Fmt.num(v, 2), "cor": ruim}
			return {"texto": "Inimigos com %s da vida normal" % Fmt.pct(v), "cor": bom}
		"velocidadeInimigo":
			if v > 1.0:
				return {"texto": "Inimigos %s mais rápidos" % Fmt.pct(v - 1.0), "cor": ruim}
			return {"texto": "Inimigos %s mais lentos" % Fmt.pct(1.0 - v), "cor": bom}
		"densidade":
			return {"texto": "%sx mais inimigos por onda" % Fmt.num(v, 2), "cor": ruim}
		"danoTorre":
			if v >= 1.0:
				return {"texto": "Seu dano ×%s" % Fmt.num(v, 2), "cor": bom}
			return {"texto": "Seu dano cai para %s" % Fmt.pct(v), "cor": ruim}
		"cadencia":
			if v >= 1.0:
				return {"texto": "Cadência de tiro ×%s" % Fmt.num(v, 2), "cor": bom}
			return {"texto": "Cadência de tiro em %s (um tiro a cada ~%ss)" % [Fmt.pct(v), Fmt.num(1.0 / maxf(0.01, v), 1)], "cor": ruim}
		"ouro":
			if v <= 0.0:
				return {"texto": "Os inimigos não soltam nenhum ouro", "cor": ruim}
			if v >= 1.0:
				return {"texto": "Ouro dos inimigos ×%s" % Fmt.num(v, 2), "cor": bom}
			return {"texto": "Ouro dos inimigos em %s" % Fmt.pct(v), "cor": ruim}
		"xp":
			if v >= 1.0:
				return {"texto": "XP ×%s" % Fmt.num(v, 2), "cor": bom}
			return {"texto": "XP em %s" % Fmt.pct(v), "cor": ruim}
		"ondaAuto":
			return {"texto": "A onda avança sozinha a cada %ss" % Fmt.num(v, 0), "cor": ruim}
		"ondaMax":
			return {"texto": "A run termina na onda %s" % Fmt.num(v, 0), "cor": UI.TEXTO2}
	return {"texto": "%s: %s" % [chave, Fmt.num(v, 2)], "cor": UI.TEXTO2}

func _recompensas(def: Dictionary) -> Array:
	var out: Array = []
	for item in def.get("recompensa", []):
		var ef: Dictionary = item
		if ef.has("especial"):
			var chave := str(ef.get("especial", ""))
			var val = ef.get("valor", 0)
			if val is String:
				out.append("desbloqueia " + str(val))
			else:
				out.append("%s +%s" % [_nome_especial(chave), Fmt.num(float(val), 2)])
			continue
		if not ef.has("stat"):
			continue
		var sd: Dictionary = Dados.stat_defs.get(str(ef["stat"]), {})
		var nome := txt(sd, "nome")
		if nome == "":
			nome = str(ef["stat"])
		var v := float(ef.get("valor", 0.0))
		var pct_stat := str(sd.get("tipo", "")) == "pct"
		match str(ef.get("tipo", "flat")):
			"flat": out.append("%s +%s" % [nome, Fmt.pct(v) if pct_stat else Fmt.num(v, 2)])
			"pct": out.append("%s +%s" % [nome, Fmt.pct(v)])
			"mult": out.append("%s ×%s" % [nome, Fmt.num(v, 2)])
	if out.is_empty():
		out.append("orgulho, basicamente")
	return out

func _nome_especial(chave: String) -> String:
	match chave:
		"ondaInicial": return "onda inicial"
		"slotsCartas": return "slots de carta"
		"pontosTalento": return "pontos de talento"
		"comboTeto": return "teto de combo"
		"comboBonus": return "bônus de combo"
		"offlineHoras": return "horas de progresso offline"
		"velocidadeMax": return "limite de velocidade"
	return chave

func _data(ts: int) -> String:
	if ts <= 0:
		return "data desconhecida"
	var d := Time.get_datetime_dict_from_unix_time(ts)
	return "%02d/%02d/%d" % [int(d["day"]), int(d["month"]), int(d["year"])]

## A fonte não tem emoji: cada desafio vira um ícone vetorial.
func _icone_desafio(id: String) -> String:
	match id:
		"ferrugem": return "ampulheta"
		"metralha": return "foguete"
		"enxame": return "veneno"
		"pobreza": return "ouro"
		"apneia": return "coracao"
		"vidro": return "gelo"
		"silencio": return "vazio"
		"azar": return "estrela"
		"orbita": return "orbe"
		"doutrina": return "livro"
		"hipervelocidade": return "velocidade"
		"muralha": return "escudo"
		"esteira": return "engrenagem"
		"purgatorio": return "fogo"
	return "desafio"
