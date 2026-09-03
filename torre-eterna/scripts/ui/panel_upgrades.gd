extends "res://scripts/ui/panel_base.gd"

## Painel de MELHORIAS — o coração do loop de compra.
## Abas por categoria, compra em lote, destaque do que dá pra pagar.

var abas: TabBar
var lista: VBoxContainer
var rolagem: ScrollContainer
var lote := 1                  # 1 · 10 · 25 · -1 (máx)
var cat_atual := 0
## A aba escolhida sobrevive ao fechar do painel. `montar()` roda inteiro a cada
## abertura, entao o painel voltava sempre para a primeira categoria: quem estava
## comprando Defesa reabria em Ataque e tinha que procurar de novo, toda vez.
## Guardamos o ID, nao o indice: a lista de categorias cresce com os desbloqueios
## e um indice guardado apontaria para outra aba depois.
static var ultima_aba_id := ""
const ABA_TUDO := "__tudo"
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
			Bus.toast(Txt.t("upg_auto_bloqueado"), "bloqueado")
			return
		jogo.s["auto"]["comprar"] = v)
	topo.add_child(check_auto)
	c.add_child(topo)

	# ---- abas de categoria ----
	abas = TabBar.new()
	abas.clip_tabs = false
	cats = []
	# A ABA "TUDO" VEM PRIMEIRO. Sem ela, descobrir o que da para comprar agora
	# custava passar por sete abas, uma de cada vez, sempre que o ouro subia — e
	# o ouro sobe o tempo todo. Aqui a lista sai ordenada pelo custo do proximo
	# nivel, entao o que cabe no bolso fica em cima.
	cats.append({"id": ABA_TUDO, "nome": Txt.t("upg_aba_tudo"), "nomeEn": Txt.t("upg_aba_tudo")})
	abas.add_tab(Txt.t("upg_aba_tudo"))
	for cat in Dados.categorias_upgrade:
		var req = cat.get("requer", null)
		if req is Dictionary and int(jogo.s["onda_maxima_global"]) < int(req.get("onda", 0)):
			continue
		cats.append(cat)
		abas.add_tab(txt(cat, "nome"))
	cat_atual = 0
	for i in cats.size():
		if str(cats[i].get("id", "")) == ultima_aba_id:
			cat_atual = i
			break
	abas.current_tab = cat_atual
	abas.tab_changed.connect(func(i):
		cat_atual = i
		ultima_aba_id = str(cats[clampi(i, 0, cats.size() - 1)].get("id", ""))
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
	var pedido: Array = []
	for def in Dados.upgrades:
		if cat_id != ABA_TUDO and str(def.get("cat", "")) != cat_id:
			continue
		pedido.append(def)
	if cat_id == ABA_TUDO:
		# Ordena pelo custo do PROXIMO nivel, do mais barato para o mais caro. A
		# ordem e calculada na montagem e nao se mexe enquanto o painel esta
		# aberto: linha que pula de lugar sozinha enquanto o dedo desce a lista e
		# pior do que uma ordem um pouco velha.
		pedido.sort_custom(func(a, b): return _peso_na_lista(a) < _peso_na_lista(b))
	for def in pedido:
		if not jogo.upgrade_disponivel(def):
			_linha_bloqueada(def)
			continue
		_linha_upgrade(def)

## Chave de ordenacao da aba "Tudo": no maximo e bloqueado afundam, o resto sobe
## pelo custo. O custo e log10, entao somar 1e6 joga para o fim sem risco.
func _peso_na_lista(def: Dictionary) -> float:
	var id := str(def.get("id", ""))
	if not jogo.upgrade_disponivel(def):
		return 2.0e6
	var nivel := int(jogo.s["upgrades"].get(id, 0))
	var maxn: int = jogo.teto_upgrade(def)
	if maxn >= 0 and nivel >= maxn:
		return 1.0e6
	return jogo.custo_upgrade(def, nivel)

func _linha_bloqueada(def: Dictionary) -> void:
	var l := linha("cadeado", UI.TEXTO3)
	var req: Dictionary = def.get("requer", {})
	# Mostrava o id interno: "Desbloqueia com dano_critico". Quem joga nunca viu
	# esse nome — na tela a melhoria se chama "Ogiva Perfurante".
	var motivo := ""
	if req.has("onda"):
		motivo = Txt.f("upg_desbloqueia_onda", {"n": int(req.get("onda", 0))})
	else:
		var id_req := str(req.get("upgrade", ""))
		var def_req: Dictionary = Dados.upgrade_por_id.get(id_req, {})
		var nome_req := txt(def_req, "nome") if not def_req.is_empty() else id_req
		if req.has("nivel"):
			motivo = Txt.f("upg_desbloqueia_upg_nv", {"u": nome_req, "n": int(req["nivel"])})
		else:
			motivo = Txt.f("upg_desbloqueia_upg", {"u": nome_req})
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

	var col := UI.vbox(1)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var nivel := UI.rotulo("", 15, UI.TEXTO2)
	nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(nivel)
	# O BOTAO DIZIA O PRECO E NUNCA O QUE VOCE LEVA. Comprar as cegas e o
	# contrario de um jogo de decisao: aqui fica, ao lado do custo, o ganho
	# exato do lote selecionado.
	var ganho := UI.rotulo("", 12, UI.VERDE)
	ganho.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(ganho)
	l["direita"].add_child(col)
	var b := UI.botao("", func(): _comprar(id))
	b.custom_minimum_size = Vector2(150, 46)
	l["direita"].add_child(b)

	if bool(def.get("destaque", false)):
		l["caixa"].add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL2, 10, 1, cor.darkened(0.3)))

	lista.add_child(l["caixa"])
	linhas[id] = {"def": def, "botao": b, "nivel": nivel, "efeito": efeito, "ganho": ganho,
		"caixa": l["caixa"]}

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
	# SHIFT COMPRA O MAXIMO. A acao `comprar_max` esta no InputMap (bootstrap.gd)
	# e o painel de Configuracoes ANUNCIA o atalho ao jogador, nos dois idiomas
	# — e nenhum codigo lia a acao. O jogo prometia um atalho que nao existia.
	var qtd = "max" if (lote < 0 or Input.is_action_pressed("comprar_max")) else lote
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
		var maxn: int = jogo.teto_upgrade(def)
		var no_teto := maxn >= 0 and nivel >= maxn
		var sufixo: String = ("/%d" % maxn) if maxn >= 0 else ""
		r["nivel"].text = Txt.t("upg_max_curto") if no_teto else (Txt.f("upg_nv", {"n": nivel}) + sufixo)
		r["efeito"].text = _texto_efeito(def, nivel)
		var b: Button = r["botao"]
		if no_teto:
			b.text = Txt.t("maximo")
			b.disabled = true
			continue
		# O LOTE DEGRADA, NAO TRAVA. Com "×25" escolhido e ouro para tres, o
		# botao ficava desligado e o jogador tinha que voltar em "×1" para
		# comprar — o modo de compra em lote punia quem o escolhia. Agora o lote
		# e um TETO: compra o que couber, ate ele.
		var cabe: int = maxi(1, int(jogo.max_upgrade(def, nivel)))
		var n := quantidade_do_lote(lote, nivel, maxn, cabe)
		var custo := Big.geo_sum(float(def.get("base", 1)), float(def.get("cresc", 1.1)), nivel, n)
		var pode := Big.gte(jogo.s["moedas"]["ouro"], custo)
		b.disabled = not pode
		b.text = "%s  ×%d" % [Fmt.big(custo), n]
		b.add_theme_color_override("font_color", UI.TEXTO if pode else UI.TEXTO3)
		r["ganho"].text = _texto_ganho(def, nivel, n)
		r["ganho"].add_theme_color_override("font_color", UI.VERDE if pode else UI.TEXTO3)

## Quantos niveis este clique compra. Estatica para o portao poder perguntar
## direto, sem montar painel: e ela que garante que o lote DEGRADA em vez de
## travar.
static func quantidade_do_lote(lote_v: int, nivel: int, maxn: int, cabe: int) -> int:
	if lote_v < 0:
		return maxi(1, cabe)
	var n := lote_v if maxn < 0 else mini(lote_v, maxn - nivel)
	return maxi(1, mini(n, cabe))

## O que ESTA compra entrega — o delta de `n` niveis a partir do nivel atual.
func _texto_ganho(def: Dictionary, nivel: int, n: int) -> String:
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
				partes.append(Txt.f("upg_ganho_flat", {"v": Fmt.num(v * float(n), 2), "s": nome}))
			"pct":
				partes.append(Txt.f("upg_ganho_pct", {"v": Fmt.pct(v * float(n)), "s": nome}))
			"mult":
				partes.append(Txt.f("upg_ganho_mult", {
					"v": Fmt.big(Big.pow_n(Big.from(v), float(n))), "s": nome}))
	return "  ·  ".join(partes)

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
