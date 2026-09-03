extends "res://scripts/ui/panel_base.gd"

## Painel de ESTATÍSTICAS — tudo que a Torre anotou sobre você.
##
## Resumo: cartões agrupados (Progresso, Combate, Economia, Coleção, Tempo,
## Caçadas) com as derivadas que realmente importam — taxa de crítico, dano
## médio por tiro, ouro por minuto, ondas por hora — e um gráfico de onda ×
## tempo desenhado à mão em `_draw()`.
## Atributos: o estado atual de cada stat, grupo por grupo, com o mesmo
## formato que o resto do jogo usa (num, pct, mult, taxa, grande).

const COLUNAS := 3
const TOPO_CACADAS := 5

var abas: TabBar
var pagina_resumo: Control
var pagina_stats: Control
var campos: Array = []           # [{lbl, fn}]
var stats_campos: Array = []     # [{lbl, chave}]
var cacadas: Array = []          # [{nome, valor, barra}]
var grafico: Grafico
var aviso_grafico: Label
var lbl_grafico_info: Label

func configurar() -> void:
	titulo_texto = Txt.t("p_stats")
	titulo_icone = "stats"
	largura = 1060.0
	altura = 676.0
	intervalo = 0.5

# ============================================================== montagem

func montar(c: VBoxContainer) -> void:
	abas = TabBar.new()
	abas.clip_tabs = false
	abas.add_tab(Txt.t("sta_aba_resumo"))
	abas.add_tab(Txt.t("sta_aba_atributos"))
	abas.tab_changed.connect(func(i):
		pagina_resumo.visible = int(i) == 0
		pagina_stats.visible = int(i) == 1)
	var topo := UI.hbox(10)
	topo.add_child(abas)
	topo.add_child(UI.espacador())
	topo.add_child(UI.rotulo(Txt.t("sta_epigrafe"), 12, UI.TEXTO3))
	c.add_child(topo)

	pagina_resumo = _montar_resumo()
	c.add_child(pagina_resumo)
	pagina_stats = _montar_atributos()
	c.add_child(pagina_stats)
	pagina_stats.visible = false

## ------------------------------------------------------------- resumo

func _montar_resumo() -> Control:
	var sc := UI.scroll()
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)

	v.add_child(_painel_grafico())

	var g := GridContainer.new()
	g.columns = COLUNAS
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)

	_cartao_progresso(g)
	_cartao_combate(g)
	_cartao_economia(g)
	_cartao_colecao(g)
	_cartao_tempo(g)
	_cartao_cacadas(g)
	return sc

func _cartao_progresso(g: GridContainer) -> void:
	var v := _cartao(g, Txt.t("sta_c_progresso"), "torre", UI.ACENTO)
	_linha(v, Txt.t("sta_onda_atual"), Txt.t("sta_onda_atual_dica"),
		func(): return Fmt.inteiro(int(jogo.s["onda"])), UI.TEXTO)
	_linha(v, Txt.t("sta_melhor_corrida"), Txt.t("sta_melhor_corrida_dica"),
		func(): return Fmt.inteiro(int(jogo.s["onda_maxima"])))
	_linha(v, Txt.t("sta_recorde"), Txt.t("sta_recorde_dica"),
		func(): return Fmt.inteiro(int(jogo.s["onda_maxima_global"])), UI.OURO)
	_linha(v, Txt.t("sta_ondas_completas"), Txt.t("sta_ondas_completas_dica"),
		func(): return Fmt.inteiro(int(_st()["ondas_completas"])))
	_linha(v, Txt.t("nivel"), Txt.t("sta_nivel_dica"),
		func(): return Fmt.inteiro(int(jogo.s["nivel"])))
	_linha(v, Txt.t("sta_prestigio"), Txt.t("sta_prestigio_dica"),
		func(): return "%d · %d · %d" % [int(jogo.s["prestigio"]["ascensoes"]),
			int(jogo.s["prestigio"]["singularidades"]), int(jogo.s["prestigio"]["transcendencias"])], UI.ACENTO2)
	_linha(v, Txt.t("sta_media_onda"), Txt.t("sta_media_onda_dica"),
		func(): return _media_onda())
	_linha(v, Txt.t("sta_ondas_hora"), Txt.t("sta_ondas_hora_dica"),
		func(): return _ondas_hora())

func _cartao_combate(g: GridContainer) -> void:
	var v := _cartao(g, Txt.t("sta_c_combate"), "espada", UI.VERMELHO)
	_linha(v, Txt.t("sta_mortos"), Txt.t("sta_mortos_dica"),
		func(): return Fmt.inteiro(int(_st()["mortos"])), UI.TEXTO)
	_linha(v, Txt.t("sta_chefes"), Txt.t("sta_chefes_dica"),
		func(): return Fmt.inteiro(int(_st()["chefes_mortos"])))
	_linha(v, Txt.t("sta_dourados"), Txt.t("sta_dourados_dica"),
		func(): return Fmt.inteiro(int(_st()["dourados"])), UI.OURO)
	_linha(v, Txt.t("sta_tiros"), Txt.t("sta_tiros_dica"),
		func(): return Fmt.inteiro(int(_st()["tiros"])))
	_linha(v, Txt.t("sta_criticos"), Txt.t("sta_criticos_dica"),
		func(): return "%s  (%s)" % [Fmt.inteiro(int(_st()["criticos"])), _taxa_critico()])
	_linha(v, Txt.t("sta_dano_total"), Txt.t("sta_dano_total_dica"),
		func(): return Fmt.big(_st()["dano_total"]), UI.VERMELHO)
	_linha(v, Txt.t("sta_maior_golpe"), Txt.t("sta_maior_golpe_dica"),
		func(): return Fmt.big(_st()["dano_maximo"]), UI.LARANJA)
	_linha(v, Txt.t("sta_dano_medio"), Txt.t("sta_dano_medio_dica"),
		func(): return _dano_medio())
	_linha(v, Txt.t("sta_combo_max"), Txt.t("sta_combo_max_dica"),
		func(): return Fmt.inteiro(int(_st()["combo_maximo"])))
	_linha(v, Txt.t("sta_mortes"), Txt.t("sta_mortes_dica"),
		func(): return Fmt.inteiro(int(_st()["mortes"])), UI.TEXTO2)

func _cartao_economia(g: GridContainer) -> void:
	var v := _cartao(g, Txt.t("sta_c_economia"), "ouro", UI.OURO)
	_linha(v, Txt.t("sta_ouro_total"), Txt.t("sta_ouro_total_dica"),
		func(): return Fmt.big(_st()["ouro_total"]), UI.OURO)
	_linha(v, Txt.t("sta_ouro_gasto"), Txt.t("sta_ouro_gasto_dica"),
		func(): return Fmt.big(_st()["ouro_gasto"]))
	_linha(v, Txt.t("sta_ouro_min"), Txt.t("sta_ouro_min_dica"),
		func(): return _ouro_minuto(), UI.VERDE)
	_linha(v, Txt.t("sta_ouro_caixa"), Txt.t("sta_ouro_caixa_dica"),
		func(): return Fmt.big(jogo.s["moedas"]["ouro"]), UI.OURO)
	_linha(v, Txt.t("m_gemas").capitalize(), Txt.t("sta_gemas_dica"),
		func(): return Fmt.big(jogo.s["moedas"]["gemas"]), UI.MOEDA_COR["gemas"])
	_linha(v, Txt.t("m_fragmentos").capitalize(), Txt.t("sta_fragmentos_dica"),
		func(): return Fmt.big(jogo.s["moedas"]["fragmentos"]), UI.MOEDA_COR["fragmentos"])
	_linha(v, Txt.t("m_nucleos").capitalize(), Txt.t("sta_nucleos_dica"),
		func(): return Fmt.big(jogo.s["moedas"]["nucleos"]), UI.MOEDA_COR["nucleos"])
	_linha(v, Txt.t("m_eter").capitalize(), Txt.t("sta_eter_dica"),
		func(): return Fmt.big(jogo.s["moedas"]["eter"]), UI.MOEDA_COR["eter"])
	_linha(v, Txt.t("m_poeira").capitalize(), Txt.t("sta_poeira_dica"),
		func(): return Fmt.big(jogo.s["moedas"]["poeira"]), UI.MOEDA_COR["poeira"])

func _cartao_colecao(g: GridContainer) -> void:
	var v := _cartao(g, Txt.t("sta_c_colecao"), "carta", UI.ACENTO2)
	_linha(v, Txt.t("sta_cartas"), Txt.t("sta_cartas_dica"),
		func(): return Fmt.inteiro(int(_st()["cartas_obtidas"])))
	_linha(v, Txt.t("sta_lendarias"), Txt.t("sta_lendarias_dica"),
		func(): return Fmt.inteiro(int(_st()["lendarios"])), UI.OURO)
	_linha(v, Txt.t("sta_inventario"), Txt.t("sta_inventario_dica"),
		func(): return Fmt.inteiro(jogo.s["cartas"]["inventario"].size()))
	_linha(v, Txt.t("p_reliquias"), Txt.t("sta_reliquias_dica"),
		func(): return Fmt.inteiro(jogo.s["relicas"].size()))
	_linha(v, Txt.t("p_conquistas"), Txt.t("sta_conquistas_dica"),
		func(): return "%s / %s" % [Fmt.inteiro(jogo.s["conquistas"].size()), Fmt.inteiro(Dados.conquistas.size())])
	_linha(v, Txt.t("sta_desafios"), Txt.t("sta_desafios_dica"),
		func(): return Fmt.inteiro(jogo.s["desafios"]["completos"].size()))
	_linha(v, Txt.t("sta_habilidades"), Txt.t("sta_habilidades_dica"),
		func(): return Fmt.inteiro(int(_st()["habilidades_usadas"])))
	_linha(v, Txt.t("sta_lore"), Txt.t("sta_lore_dica"),
		func(): return "%s / %s" % [Fmt.inteiro(_lore_abertas()), Fmt.inteiro(Dados.entradas_lore.size())], UI.ACENTO)

func _cartao_tempo(g: GridContainer) -> void:
	var v := _cartao(g, Txt.t("sta_c_tempo"), "ampulheta", UI.ACENTO)
	_linha(v, Txt.t("sta_tempo_total"), Txt.t("sta_tempo_total_dica"),
		func(): return Ux.tempo_curto(float(_st()["tempo_total"])), UI.TEXTO)
	_linha(v, Txt.t("sta_sessao"), Txt.t("sta_sessao_dica"),
		func(): return Ux.tempo_curto(float(_st()["tempo_sessao"])))
	_linha(v, Txt.t("sta_offline"), Txt.t("sta_offline_dica"),
		func(): return Ux.tempo_curto(float(_st()["tempo_offline"])))
	_linha(v, Txt.t("sta_frac_offline"), Txt.t("sta_frac_offline_dica"),
		func(): return _frac_offline(), UI.ACENTO2)
	_linha(v, Txt.t("sta_criacao"), Txt.t("sta_criacao_dica"),
		func(): return _data_criacao(), UI.TEXTO2)
	_linha(v, Txt.t("velocidade"), Txt.t("sta_velocidade_dica"),
		func(): return Fmt.mult(float(jogo.s["auto"]["velocidade"])))

func _cartao_cacadas(g: GridContainer) -> void:
	var v := _cartao(g, Txt.t("sta_c_cacadas"), "alvo", UI.VERDE)
	v.add_child(UI.rotulo(Txt.t("sta_cacadas_sub"), 11, UI.TEXTO3))
	for i in TOPO_CACADAS:
		var linha_c := UI.vbox(1)
		var h := UI.hbox(6)
		var ln := UI.rotulo("—", 12, UI.TEXTO2)
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.clip_text = true
		h.add_child(ln)
		var lv := UI.rotulo("", 12, UI.TEXTO)
		h.add_child(lv)
		linha_c.add_child(h)
		var b := UI.barra(UI.VERDE, 5)
		b.value = 0.0
		linha_c.add_child(b)
		v.add_child(linha_c)
		cacadas.append({"nome": ln, "valor": lv, "barra": b})

## ------------------------------------------------------------- gráfico

func _painel_grafico() -> Control:
	var p := UI.painel(UI.PAINEL2.darkened(0.24), 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.tooltip_text = Txt.t("sta_grafico_dica")
	var v := UI.vbox(6)
	p.add_child(v)

	var cab := UI.hbox(6)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	cab.add_child(ic)
	ic.configurar("stats", UI.ACENTO, 16)
	cab.add_child(UI.rotulo(Txt.t("sta_grafico_titulo"), 15, UI.TEXTO))
	cab.add_child(UI.espacador())
	lbl_grafico_info = UI.rotulo("", 12, UI.TEXTO3)
	cab.add_child(lbl_grafico_info)
	v.add_child(cab)

	var caixa := Control.new()
	caixa.custom_minimum_size.y = 208
	caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(caixa)

	grafico = Grafico.new()
	caixa.add_child(grafico)
	grafico.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	aviso_grafico = UI.rotulo(Txt.t("sta_grafico_vazio"), 13, UI.TEXTO3)
	aviso_grafico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso_grafico.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aviso_grafico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(aviso_grafico)
	aviso_grafico.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return p

## ---------------------------------------------------------- atributos

func _montar_atributos() -> Control:
	var sc := UI.scroll()
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)

	if Dados.stat_grupos.is_empty():
		v.add_child(UI.rotulo(Txt.t("sta_sem_atributos"), 13, UI.TEXTO3))
		return sc

	for item in Dados.stat_grupos:
		var grupo: Dictionary = item
		var cor := _cor_grupo(str(grupo.get("id", "")))
		var p := UI.painel(UI.PAINEL2.darkened(0.24), 12)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(p)
		var pv := UI.vbox(5)
		p.add_child(pv)

		var cab := UI.hbox(6)
		var ic := Control.new()
		ic.set_script(load("res://scripts/ui/icone_control.gd"))
		cab.add_child(ic)
		ic.configurar(_icone_grupo(str(grupo.get("id", ""))), cor, 16)
		cab.add_child(UI.rotulo(txt(grupo, "nome"), 15, cor))
		pv.add_child(cab)
		pv.add_child(UI.separador())

		var g := GridContainer.new()
		g.columns = 3
		g.add_theme_constant_override("h_separation", 18)
		g.add_theme_constant_override("v_separation", 3)
		pv.add_child(g)
		for chave in grupo.get("chaves", []):
			var k := str(chave)
			var sd: Dictionary = Dados.stat_defs.get(k, {})
			if sd.is_empty():
				continue
			var h := UI.hbox(8)
			h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.tooltip_text = "%s\n%s: %s" % [txt(sd, "desc"), Txt.t("sta_base"), str(sd.get("base", 0))]
			var ln := UI.rotulo(txt(sd, "nome"), 13, UI.TEXTO2)
			ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(ln)
			var lv := UI.rotulo("—", 13, UI.TEXTO)
			h.add_child(lv)
			g.add_child(h)
			stats_campos.append({"lbl": lv, "chave": k})
	return sc

# ============================================================== atualizar

func atualizar() -> void:
	if jogo == null:
		return
	for item in campos:
		var r: Dictionary = item
		var l: Label = r["lbl"]
		if not is_instance_valid(l):
			continue
		var fn: Callable = r["fn"]
		l.text = str(fn.call())

	for item2 in stats_campos:
		var r2: Dictionary = item2
		var l2: Label = r2["lbl"]
		if is_instance_valid(l2):
			l2.text = _valor_stat(str(r2["chave"]))

	_atualizar_cacadas()
	_atualizar_grafico()

func _atualizar_cacadas() -> void:
	var por: Dictionary = _st()["por_inimigo"]
	var lista: Array = []
	for k in por.keys():
		lista.append({"id": str(k), "n": int(por[k])})
	lista.sort_custom(func(a, b): return int(a["n"]) > int(b["n"]))
	var topo := 1.0
	if not lista.is_empty():
		topo = maxf(1.0, float(int(lista[0]["n"])))
	for i in cacadas.size():
		var ui_r: Dictionary = cacadas[i]
		var ln: Label = ui_r["nome"]
		var lv: Label = ui_r["valor"]
		var b: ProgressBar = ui_r["barra"]
		if i >= lista.size():
			ln.text = "—"
			lv.text = ""
			b.value = 0.0
			continue
		var reg: Dictionary = lista[i]
		var id := str(reg["id"])
		var def: Dictionary = Dados.inimigo_por_id.get(id, {})
		ln.text = txt(def, "nome") if not def.is_empty() else id
		lv.text = Fmt.inteiro(int(reg["n"]))
		b.value = clampf(float(int(reg["n"])) / topo, 0.0, 1.0)

func _atualizar_grafico() -> void:
	if grafico == null:
		return
	var hist: Array = _st()["historico"]
	var pontos: Array = []
	for item in hist:
		if not (item is Dictionary):
			continue
		var d: Dictionary = item
		pontos.append(Vector2(float(d.get("t", 0.0)), float(d.get("onda", 0))))
	grafico.pontos = pontos
	grafico.queue_redraw()
	var tem := pontos.size() >= 2
	aviso_grafico.visible = not tem
	lbl_grafico_info.text = Txt.f("sta_grafico_info", {"n": pontos.size(), "pico": int(grafico.pico())}) if tem \
		else Txt.t("sta_sem_amostras")

# ============================================================== cálculos

func _st() -> Dictionary:
	return jogo.s["stats"]

func _taxa_critico() -> String:
	var tiros := float(_st()["tiros"])
	if tiros <= 0.0:
		return "—"
	return Fmt.pct(float(_st()["criticos"]) / tiros)

func _dano_medio() -> String:
	var tiros := float(_st()["tiros"])
	if tiros <= 0.0:
		return "—"
	return Fmt.big(Big.div_f(float(_st()["dano_total"]), tiros))

func _ouro_minuto() -> String:
	var t := float(_st()["tempo_total"])
	if t < 30.0:
		return "—"
	return Fmt.big(Big.div_f(float(_st()["ouro_total"]), t / 60.0)) + "/min"

func _ondas_hora() -> String:
	var t := float(_st()["tempo_total"])
	if t < 60.0:
		return "—"
	return Fmt.num(float(int(_st()["ondas_completas"])) / (t / 3600.0), 1) + "/h"

func _media_onda() -> String:
	var n := int(_st()["ondas_completas"])
	if n <= 0:
		return "—"
	return Ux.tempo_curto(float(_st()["tempo_total"]) / float(n))

func _frac_offline() -> String:
	var t := float(_st()["tempo_total"])
	if t <= 0.0:
		return "—"
	return Fmt.pct(clampf(float(_st()["tempo_offline"]) / t, 0.0, 1.0))

func _data_criacao() -> String:
	var ts := int(jogo.s.get("criado_em", 0))
	if ts <= 0:
		return Txt.t("sta_hoje")
	var d := Time.get_datetime_dict_from_unix_time(ts)
	return Txt.f("sta_data", {"d": "%02d" % int(d["day"]), "m": "%02d" % int(d["month"]), "a": "%04d" % int(d["year"])})

func _lore_abertas() -> int:
	var n := 0
	for item in Dados.entradas_lore:
		var e: Dictionary = item
		if Progresso.cond_atendida(jogo.s, e.get("cond", {})):
			n += 1
	return n

func _valor_stat(chave: String) -> String:
	var sd: Dictionary = Dados.stat_defs.get(chave, {})
	var tipo := str(sd.get("tipo", "num"))
	var unidade := str(sd.get("unidade", ""))
	if StatEngine.GRANDES.has(chave):
		return Fmt.big(jogo.stats.b(chave)) + unidade
	var v: float = jogo.stats.n(chave)
	match tipo:
		"pct": return Fmt.pct(v)
		"mult": return Fmt.mult(v)
		"taxa": return Fmt.num(v, 2) + unidade
		"grande": return Fmt.big(Big.from(v)) + unidade
	if bool(sd.get("inteiro", false)):
		return Fmt.inteiro(int(v))
	return Fmt.num(v, 2) + unidade

# ============================================================== widgets

func _cartao(g: GridContainer, titulo: String, icone: String, cor: Color) -> VBoxContainer:
	var p := UI.painel(UI.PAINEL2.darkened(0.24), 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g.add_child(p)
	var v := UI.vbox(3)
	p.add_child(v)
	var cab := UI.hbox(6)
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	cab.add_child(ic)
	ic.configurar(icone, cor, 17)
	cab.add_child(UI.rotulo(titulo, 15, cor))
	v.add_child(cab)
	v.add_child(UI.separador())
	return v

func _linha(v: VBoxContainer, rotulo: String, dica: String, fn: Callable, cor: Color = UI.TEXTO) -> void:
	var h := UI.hbox(8)
	h.tooltip_text = dica
	var l := UI.rotulo(rotulo, 12, UI.TEXTO2)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	var lv := UI.rotulo("—", 13, cor)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(lv)
	v.add_child(h)
	campos.append({"lbl": lv, "fn": fn})

func _cor_grupo(id: String) -> Color:
	match id:
		"ofensivo": return UI.VERMELHO
		"elemental": return UI.ACENTO2
		"defensivo": return UI.VERDE
		"orbes": return UI.ACENTO
		"economia": return UI.OURO
		"utilidade": return UI.ROSA
	return UI.TEXTO2

func _icone_grupo(id: String) -> String:
	match id:
		"ofensivo": return "espada"
		"elemental": return "fogo"
		"defensivo": return "escudo"
		"orbes": return "orbe"
		"economia": return "ouro"
		"utilidade": return "ampulheta"
	return "engrenagem"

# ==============================================================================
# GRÁFICO — onda × tempo, desenhado à mão. Sem biblioteca, sem imagem.
# ==============================================================================

class Grafico extends Control:
	var pontos: Array = []            # [Vector2(t_segundos, onda)]
	const ML := 54.0
	const MR := 16.0
	const MT := 22.0
	const MB := 26.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func pico() -> float:
		var m := 0.0
		for p in pontos:
			m = maxf(m, (p as Vector2).y)
		return m

	func _draw() -> void:
		if size.x < 120.0 or size.y < 80.0:
			return
		var area := Rect2(ML, MT, size.x - ML - MR, size.y - MT - MB)
		draw_rect(area, Color(0.02, 0.03, 0.07, 0.55))
		var f := ThemeDB.fallback_font
		if pontos.size() < 2:
			_moldura(area, f, 0.0, 1.0, 0.0, 1.0, true)
			return

		var t0: float = (pontos[0] as Vector2).x
		var t1: float = (pontos[pontos.size() - 1] as Vector2).x
		var onda_max := 1.0
		var onda_min := INF
		for p in pontos:
			var v := p as Vector2
			t0 = minf(t0, v.x)
			t1 = maxf(t1, v.x)
			onda_max = maxf(onda_max, v.y)
			onda_min = minf(onda_min, v.y)
		if t1 - t0 < 1.0:
			t1 = t0 + 1.0
		var y_base := 0.0 if onda_min < 8.0 else maxf(0.0, onda_min - 2.0)
		var y_topo := onda_max * 1.08 + 1.0
		_moldura(area, f, t0, t1, y_base, y_topo, false)

		# --- pontos em tela ---
		var tela := PackedVector2Array()
		for p in pontos:
			var v2 := p as Vector2
			tela.append(Vector2(
				area.position.x + area.size.x * clampf((v2.x - t0) / (t1 - t0), 0.0, 1.0),
				area.position.y + area.size.y * (1.0 - clampf((v2.y - y_base) / maxf(y_topo - y_base, 0.001), 0.0, 1.0))))
		if tela.size() > 320:
			var passo := int(ceil(float(tela.size()) / 320.0))
			var reduzido := PackedVector2Array()
			for i in range(0, tela.size(), passo):
				reduzido.append(tela[i])
			reduzido.append(tela[tela.size() - 1])
			tela = reduzido
		var suave := _suavizar(tela)

		# --- área sob a curva ---
		var poli := PackedVector2Array(suave)
		poli.append(Vector2(suave[suave.size() - 1].x, area.position.y + area.size.y))
		poli.append(Vector2(suave[0].x, area.position.y + area.size.y))
		draw_colored_polygon(poli, Color(UI.ACENTO.r, UI.ACENTO.g, UI.ACENTO.b, 0.16))

		# --- linha ---
		draw_polyline(suave, Color(UI.ACENTO.r, UI.ACENTO.g, UI.ACENTO.b, 0.30), 5.0, true)
		draw_polyline(suave, UI.ACENTO.lightened(0.15), 2.0, true)

		# --- pico e ponto final ---
		var i_pico := 0
		for i in pontos.size():
			if (pontos[i] as Vector2).y >= (pontos[i_pico] as Vector2).y:
				i_pico = i
		var v_pico := pontos[i_pico] as Vector2
		var p_pico := Vector2(
			area.position.x + area.size.x * clampf((v_pico.x - t0) / (t1 - t0), 0.0, 1.0),
			area.position.y + area.size.y * (1.0 - clampf((v_pico.y - y_base) / maxf(y_topo - y_base, 0.001), 0.0, 1.0)))
		draw_circle(p_pico, 6.0, Color(UI.OURO.r, UI.OURO.g, UI.OURO.b, 0.25))
		draw_circle(p_pico, 3.0, UI.OURO)
		if f != null:
			var rotulo := Txt.f("sta_grafico_pico", {"n": int(v_pico.y)})
			var w := f.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var px := clampf(p_pico.x - w * 0.5, area.position.x, area.position.x + area.size.x - w)
			draw_string(f, Vector2(px, maxf(p_pico.y - 10.0, area.position.y + 11.0)), rotulo,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.OURO)
		var ultimo := tela[tela.size() - 1]
		draw_circle(ultimo, 3.0, Color.WHITE)

	## Moldura: eixos, grade e rótulos.
	func _moldura(area: Rect2, f: Font, t0: float, t1: float, y0: float, y1: float, vazio: bool) -> void:
		var cor_grade := Color(UI.BORDA.r, UI.BORDA.g, UI.BORDA.b, 0.55)
		for i in 5:
			var fy := float(i) / 4.0
			var y := area.position.y + area.size.y * fy
			draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), cor_grade, 1.0)
			if f != null and not vazio:
				var val := lerpf(y1, y0, fy)
				var s := Fmt.inteiro(int(round(val)))
				var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
				draw_string(f, Vector2(area.position.x - 8.0 - w, y + 4.0), s,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.TEXTO3)
		for i in 5:
			var fx := float(i) / 4.0
			var x := area.position.x + area.size.x * fx
			draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), cor_grade, 1.0)
			if f != null and not vazio:
				var s2 := Ux.tempo_curto(lerpf(t0, t1, fx))
				var w2 := f.get_string_size(s2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
				var px := clampf(x - w2 * 0.5, area.position.x, area.end.x - w2)
				draw_string(f, Vector2(px, area.end.y + 15.0), s2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.TEXTO3)
		draw_line(area.position + Vector2(0, area.size.y), area.end, UI.BORDA_FORTE, 1.5)
		draw_line(area.position, area.position + Vector2(0, area.size.y), UI.BORDA_FORTE, 1.5)
		if f != null:
			draw_string(f, Vector2(area.position.x - 46.0, area.position.y - 9.0), Txt.t("onda").to_lower(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.TEXTO3)
			var st := Txt.t("sta_eixo_tempo")
			var wt := f.get_string_size(st, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(f, Vector2(area.end.x - wt, area.position.y - 9.0), st,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.TEXTO3)

	## Chaikin: tira os cantos duros sem inventar dados.
	func _suavizar(pts: PackedVector2Array) -> PackedVector2Array:
		if pts.size() < 3:
			return pts
		var atual := pts
		for _passo in 2:
			if atual.size() > 600:
				break
			var novo := PackedVector2Array()
			novo.append(atual[0])
			for i in range(atual.size() - 1):
				var a := atual[i]
				var b := atual[i + 1]
				novo.append(a.lerp(b, 0.25))
				novo.append(a.lerp(b, 0.75))
			novo.append(atual[atual.size() - 1])
			atual = novo
		return atual
