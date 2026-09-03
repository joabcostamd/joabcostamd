extends "res://scripts/ui/panel_base.gd"

## Painel de MELHORIAS — o coração do loop de compra.
## Abas por categoria, compra em lote, destaque do que dá pra pagar.

var abas: TabBar
var lista: VBoxContainer
var rolagem: ScrollContainer
var lote := 1                  # 1 · 10 · 25 · -1 (máx)
var cat_atual := 0
var linhas := {}
var lbl_ouro: Label
var botoes_lote := []
var check_auto: CheckButton
var cats: Array = []

func configurar() -> void:
	titulo_texto = Txt.t("p_upgrades")
	titulo_icone = "espada"
	largura = 860.0
	altura = 620.0
	intervalo = 0.15

func montar(c: VBoxContainer) -> void:
	# ---- barra superior: ouro + lote + auto ----
	var topo := UI.hbox(10)
	var ic := UI.icone("ouro", UI.OURO, 20)
	topo.add_child(ic)
	lbl_ouro = UI.rotulo("0", 19, UI.OURO)
	topo.add_child(lbl_ouro)
	topo.add_child(UI.espacador())

	for opcao in [[1, "×1"], [10, "×10"], [25, "×25"], [-1, Txt.t("upg_max_curto")]]:
		var b := UI.botao(str(opcao[1]), func(): _definir_lote(int(opcao[0])))
		b.custom_minimum_size = Vector2(56, 32)
		b.toggle_mode = true
		b.button_pressed = int(opcao[0]) == lote
		topo.add_child(b)
		botoes_lote.append({"botao": b, "valor": int(opcao[0])})

	check_auto = CheckButton.new()
	check_auto.text = Txt.t("upg_auto")
	check_auto.tooltip_text = Txt.t("upg_auto_dica")
	check_auto.button_pressed = bool(jogo.s["auto"]["comprar"])
	check_auto.toggled.connect(func(v):
		if not jogo.esp["desbloqueios"].has("autoCompra"):
			check_auto.button_pressed = false
			Bus.toast(Txt.t("upg_auto_bloqueado"), "info")
			return
		jogo.s["auto"]["comprar"] = v)
	topo.add_child(check_auto)
	c.add_child(topo)

	# ---- abas de categoria ----
	abas = TabBar.new()
	abas.clip_tabs = false
	cats = []
	for cat in Dados.categorias_upgrade:
		var req = cat.get("requer", null)
		if req is Dictionary and int(jogo.s["onda_maxima_global"]) < int(req.get("onda", 0)):
			continue
		cats.append(cat)
		abas.add_tab(txt(cat, "nome"))
	abas.tab_changed.connect(func(i):
		cat_atual = i
		_reconstruir())
	c.add_child(abas)

	rolagem = UI.scroll()
	lista = UI.vbox(6)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(lista)
	c.add_child(rolagem)
	_reconstruir()

func _definir_lote(v: int) -> void:
	lote = v
	for b in botoes_lote:
		b["botao"].button_pressed = int(b["valor"]) == v
	atualizar()

func _reconstruir() -> void:
	for n in lista.get_children():
		n.queue_free()
	linhas.clear()
	if cats.is_empty():
		return
	var cat_id := str(cats[clampi(cat_atual, 0, cats.size() - 1)].get("id", ""))
	for def in Dados.upgrades:
		if str(def.get("cat", "")) != cat_id:
			continue
		if not jogo.upgrade_disponivel(def):
			_linha_bloqueada(def)
			continue
		_linha_upgrade(def)

func _linha_bloqueada(def: Dictionary) -> void:
	var l := linha("cadeado", UI.TEXTO3)
	var req: Dictionary = def.get("requer", {})
	var motivo: String = Txt.f("upg_desbloqueia_onda", {"n": int(req.get("onda", 0))}) if req.has("onda") else Txt.f("upg_desbloqueia_upg", {"u": str(req.get("upgrade", "?"))})
	l["textos"].add_child(UI.rotulo("???", 15, UI.TEXTO3))
	l["textos"].add_child(UI.rotulo(motivo, 12, UI.TEXTO3))
	lista.add_child(l["caixa"])

func _linha_upgrade(def: Dictionary) -> void:
	var id := str(def.get("id", ""))
	var cor := UI.ACENTO
	for cat in Dados.categorias_upgrade:
		if str(cat.get("id", "")) == str(def.get("cat", "")):
			cor = Color.html(str(cat.get("cor", "#38bdf8")))
	var l := linha(_icone_de(def), cor)

	var nome := UI.rotulo(txt(def, "nome"), 16, UI.TEXTO)
	l["textos"].add_child(nome)
	var desc := UI.rotulo(txt(def, "desc"), 12, UI.TEXTO2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 330
	l["textos"].add_child(desc)
	var efeito := UI.rotulo("", 12, UI.VERDE)
	l["textos"].add_child(efeito)

	var nivel := UI.rotulo("", 15, UI.TEXTO2)
	l["direita"].add_child(nivel)
	var b := UI.botao("", func(): _comprar(id))
	b.custom_minimum_size = Vector2(150, 46)
	l["direita"].add_child(b)

	if bool(def.get("destaque", false)):
		l["caixa"].add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2, 10, 1, cor.darkened(0.3)))

	lista.add_child(l["caixa"])
	linhas[id] = {"def": def, "botao": b, "nivel": nivel, "efeito": efeito, "caixa": l["caixa"]}

func _icone_de(def: Dictionary) -> String:
	match str(def.get("id", "")):
		"dano", "dano_critico", "critico": return "espada"
		"vida", "regen": return "coracao"
		"armadura", "escudo", "escudo_regen": return "escudo"
		"orbe", "dano_orbe", "vel_orbe": return "orbe"
		"ouro", "juros", "ima", "forja_ouro": return "ouro"
		"fogo": return "fogo"
		"gelo": return "gelo"
		"veneno": return "veneno"
		"vazio": return "vazio"
		"raio", "cadencia": return "raio"
		"sorte", "sorte_drop": return "estrela"
		"alcance", "penetracao": return "alvo"
		"cdr", "duracao": return "ampulheta"
		"multishot", "vel_projetil", "ricochete", "perfuracao": return "foguete"
	return "torre"

func _comprar(id: String) -> void:
	var qtd = "max" if lote < 0 else lote
	var n: int = jogo.comprar_upgrade(id, qtd)
	if n > 0:
		if linhas.has(id):
			UI.pulsar(linhas[id]["caixa"], UI.VERDE)
		atualizar()
	else:
		Bus.toast(Txt.t("ouro_insuficiente"), "ruim")

func atualizar() -> void:
	if jogo == null or lbl_ouro == null:
		return
	lbl_ouro.text = Fmt.big(jogo.s["moedas"]["ouro"])
	check_auto.button_pressed = bool(jogo.s["auto"]["comprar"])
	for id in linhas.keys():
		var r: Dictionary = linhas[id]
		var def: Dictionary = r["def"]
		var nivel := int(jogo.s["upgrades"].get(id, 0))
		var maxn := int(def.get("max", -1))
		var no_teto := maxn >= 0 and nivel >= maxn
		var sufixo: String = ("/%d" % maxn) if maxn >= 0 else ""
		r["nivel"].text = Txt.t("upg_max_curto") if no_teto else (Txt.f("upg_nv", {"n": nivel}) + sufixo)
		r["efeito"].text = _texto_efeito(def, nivel)
		var b: Button = r["botao"]
		if no_teto:
			b.text = Txt.t("maximo")
			b.disabled = true
			continue
		var n: int = 1
		if lote < 0:
			n = maxi(1, int(jogo.max_upgrade(def, nivel)))
		else:
			n = lote if maxn < 0 else mini(lote, maxn - nivel)
		var custo := Big.geo_sum(float(def.get("base", 1)), float(def.get("cresc", 1.1)), nivel, n)
		var pode := Big.gte(jogo.s["moedas"]["ouro"], custo)
		b.disabled = not pode
		b.text = "%s  ×%d" % [Fmt.big(custo), n]
		b.add_theme_color_override("font_color", UI.TEXTO if pode else UI.TEXTO3)

func _texto_efeito(def: Dictionary, nivel: int) -> String:
	var partes: Array = []
	for item in def.get("efeito", []):
		var ef: Dictionary = item
		if not ef.has("stat"):
			continue
		var sd: Dictionary = Dados.stat_defs.get(str(ef["stat"]), {})
		var nome := txt(sd, "nome")
		var v := float(ef.get("valor", 0.0))
		match str(ef.get("tipo", "flat")):
			"flat":
				var total := v * float(nivel)
				partes.append(Txt.f("upg_efeito_flat", {"s": nome, "v": Fmt.num(v, 2), "t": Fmt.num(total, 2)}))
			"pct":
				partes.append(Txt.f("upg_efeito_pct", {"s": nome, "v": Fmt.pct(v), "t": Fmt.pct(v * float(nivel))}))
			"mult":
				partes.append(Txt.f("upg_efeito_mult", {"s": nome, "v": Fmt.num(v, 2), "t": Fmt.big(Big.pow_n(Big.from(v), float(nivel)))}))
	return "  ·  ".join(partes)
