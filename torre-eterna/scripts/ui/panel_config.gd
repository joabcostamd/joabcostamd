extends "res://scripts/ui/panel_base.gd"

## Painel de CONFIGURAÇÕES + GERENCIAMENTO DE SAVE.
##
## Seis abas: Jogo, Áudio, Gráficos, Acessibilidade, Save e Sobre.
## Regras da casa:
##   · todo controle nasce lendo o valor salvo em `Cfg`;
##   · toda mudança chama `Cfg.set_v(...)` e vale NA HORA (sem "aplicar");
##   · nada aqui mexe no save do jogo — as opções vivem em outro arquivo e
##     sobrevivem a um reset total, o que é meio poético.
##
## A aba SAVE é a única com poder destrutivo, então ela pede confirmação duas
## vezes e oferece um backup em texto antes de deixar você fazer besteira.

const NOME_JOGO := "TORRE ETERNA"
const VERSAO_JOGO := "0.9.0"

## Notações: pares de CHAVES de texto (nome, explicação). O texto sai do Txt.
const NOTACOES := [
	["cfg_not_mista", "cfg_not_mista_d"],
	["cfg_not_letras", "cfg_not_letras_d"],
	["cfg_not_cientifica", "cfg_not_cientifica_d"],
	["cfg_not_engenharia", "cfg_not_engenharia_d"],
	["cfg_not_extenso", "cfg_not_extenso_d"],
	["cfg_not_log", "cfg_not_log_d"],
]

## Atalhos: [ação do InputMap, CHAVE de texto da descrição].
const ATALHOS := [
	["ui_pausa", "cfg_at_pausa"],
	["painel_upgrades", "cfg_at_upgrades"],
	["painel_talentos", "cfg_at_talentos"],
	["painel_cartas", "cfg_at_cartas"],
	["painel_prestigio", "cfg_at_prestigio"],
	["painel_conquistas", "cfg_at_conquistas"],
	["painel_config", "cfg_at_config"],
	["comprar_max", "cfg_at_comprar_max"],
	["alternar_auto", "cfg_at_auto"],
	["turbo", "cfg_at_turbo"],
	["purga", "cfg_at_purga"],
	["salvar_agora", "salvar_agora"],
	["tela_cheia", "cfg_at_tela_cheia"],
	["debug_toggle", "cfg_at_fps"],
]

## Nome que o sistema devolve para a tecla → CHAVE de texto do nome amigável.
const TECLA_NOME := {
	"Escape": "cfg_tecla_esc", "Space": "cfg_tecla_espaco",
	"Enter": "cfg_tecla_enter", "KpEnter": "cfg_tecla_enter_num",
	"Backspace": "cfg_tecla_backspace", "Tab": "cfg_tecla_tab",
	"Shift": "cfg_tecla_shift", "Ctrl": "cfg_tecla_ctrl",
}

# ------------------------------------------------------------------ estado

var abas: TabBar
var rolagem: ScrollContainer
var conteudo: VBoxContainer
var aba := 0
var rodape_aviso: Label
var passo_restaurar := 0
var btn_restaurar: Button

# aba JOGO
var previa_linhas: Array = []          # [{caixa, valor, idx}]
var previa_titulo: Label
var menu_notacao: OptionButton
var _sb_previa_on: StyleBoxFlat
var _sb_previa_off: StyleBoxFlat

# aba ÁUDIO
var sliders_audio: Array = []          # [HSlider]
var rotulos_audio: Array = []          # [Label]

# aba GRÁFICOS
var lbl_densidade: Label

# aba SAVE
var lbl_tamanho: Label
var lbl_data: Label
var lbl_proximo: Label
var lbl_erro: Label
var te_exportar: TextEdit
var te_importar: TextEdit
var caixa_exportar: PanelContainer
var caixa_importar: PanelContainer
var caixa_apagar: PanelContainer
var btn_apagar: Button
var passo_apagar := 0

# aba SOBRE
var lbl_tempo_total: Label

# ================================================================ montagem

func configurar() -> void:
	titulo_texto = Txt.t("p_config")
	titulo_icone = "engrenagem"
	largura = 920.0
	altura = 648.0
	intervalo = 0.25

func montar(c: VBoxContainer) -> void:
	_sb_previa_on = UI.caixa(UI.PAINEL2, 8, 1, UI.ACENTO)
	_sb_previa_off = UI.caixa(Color(0, 0, 0, 0), 8, 0)

	abas = TabBar.new()
	abas.clip_tabs = false
	for nome in [Txt.t("c_jogo"), Txt.t("c_audio"), Txt.t("c_graficos"),
			Txt.t("c_acessibilidade"), Txt.t("c_save"), Txt.t("c_sobre")]:
		abas.add_tab(str(nome))
	abas.current_tab = aba
	abas.tab_changed.connect(func(i: int):
		aba = i
		_reconstruir())
	c.add_child(abas)

	rolagem = UI.scroll()
	conteudo = UI.vbox(10)
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(conteudo)
	c.add_child(rolagem)

	c.add_child(UI.separador())
	var pe := UI.hbox(10)
	rodape_aviso = UI.rotulo(Txt.t("cfg_rodape_opcoes"), 12, UI.TEXTO3)
	pe.add_child(rodape_aviso)
	pe.add_child(UI.espacador())
	btn_restaurar = UI.botao(Txt.t("c_restaurar"), _restaurar, Txt.t("cfg_restaurar_dica"))
	btn_restaurar.custom_minimum_size = Vector2(180, 36)
	pe.add_child(btn_restaurar)
	c.add_child(pe)

	# reaplica o que o painel controla e o resto do jogo ainda não lê sozinho
	_aplicar_escala()
	_aplicar_filtro()
	_reconstruir()

func _reconstruir() -> void:
	if conteudo == null:
		return
	for n in conteudo.get_children():
		conteudo.remove_child(n)
		n.queue_free()
	previa_linhas.clear()
	sliders_audio.clear()
	rotulos_audio.clear()
	previa_titulo = null
	menu_notacao = null
	lbl_densidade = null
	lbl_tamanho = null
	lbl_data = null
	lbl_proximo = null
	lbl_erro = null
	lbl_tempo_total = null
	te_exportar = null
	te_importar = null
	caixa_exportar = null
	caixa_importar = null
	caixa_apagar = null
	btn_apagar = null
	passo_apagar = 0
	passo_restaurar = 0
	if btn_restaurar != null:
		btn_restaurar.text = Txt.t("c_restaurar")
		btn_restaurar.add_theme_color_override("font_color", UI.TEXTO)

	match aba:
		0: _aba_jogo()
		1: _aba_audio()
		2: _aba_graficos()
		3: _aba_acessibilidade()
		4: _aba_save()
		_: _aba_sobre()
	atualizar()

# ================================================================ aba: JOGO

func _aba_jogo() -> void:
	var b := _bloco("livro", UI.ACENTO, Txt.t("c_idioma"), Txt.t("cfg_idioma_sub"))
	var l := _opcao(b, "livro", UI.ACENTO, Txt.t("cfg_idioma_textos"), Txt.t("cfg_idioma_desc"))
	l["direita"].add_child(_menu("idioma", ["Português (BR)", "English"], ["pt", "en"],
		Txt.t("cfg_idioma_dica")))

	var b2 := _bloco("stats", UI.OURO, Txt.t("cfg_numeros"), Txt.t("cfg_numeros_sub"))
	var l2 := _opcao(b2, "stats", UI.OURO, Txt.t("c_notacao"), Txt.t("cfg_notacao_desc"))
	menu_notacao = _menu("notacao", _nomes_notacao(), [0, 1, 2, 3, 4, 5],
		Txt.t("cfg_notacao_dica"))
	l2["direita"].add_child(menu_notacao)

	# ---- prévia ao vivo: o MESMO número em todas as notações ----
	var cx := UI.painel(UI.PAINEL.darkened(0.25), 10)
	cx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(3)
	cx.add_child(v)
	previa_titulo = UI.rotulo(Txt.t("cfg_previa"), 12, UI.TEXTO3)
	v.add_child(previa_titulo)
	for i in NOTACOES.size():
		var item: Array = NOTACOES[i]
		var caixa := PanelContainer.new()
		caixa.add_theme_stylebox_override("panel", _sb_previa_off)
		caixa.mouse_filter = Control.MOUSE_FILTER_STOP
		caixa.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		caixa.tooltip_text = Txt.t(str(item[1]))
		var idx := i
		caixa.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed:
				_escolher_notacao(idx))
		var h := UI.hbox(10)
		caixa.add_child(h)
		var nome := UI.rotulo(Txt.t(str(item[0])), 13, UI.TEXTO2)
		nome.custom_minimum_size.x = 130
		h.add_child(nome)
		var valor := UI.rotulo("—", 16, UI.TEXTO)
		valor.custom_minimum_size.x = 160
		h.add_child(valor)
		var expl := UI.rotulo(Txt.t(str(item[1])), 11, UI.TEXTO3)
		expl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		expl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(expl)
		v.add_child(caixa)
		previa_linhas.append({"caixa": caixa, "valor": valor, "idx": idx})
	b2["corpo"].add_child(cx)

	var l3 := _opcao(b2, "balanca", UI.OURO, Txt.t("c_casas"), Txt.t("cfg_casas_desc"))
	l3["direita"].add_child(_slider("casas", 0, 4, 1, true, 60,
		func(x: float) -> String: return "%d" % int(x),
		Txt.t("cfg_casas_dica")))

	var b3 := _bloco("engrenagem", UI.VERDE, Txt.t("cfg_comportamento"), Txt.t("cfg_comportamento_sub"))
	var l4 := _opcao(b3, "escudo", UI.VERDE, Txt.t("cfg_confirmar_prestigio"), Txt.t("cfg_confirmar_prestigio_desc"))
	l4["direita"].add_child(_check("confirmar_prestigio", Txt.t("cfg_confirmar_prestigio_dica")))

	var l5 := _opcao(b3, "estrela", UI.VERDE, Txt.t("cfg_dicas"), Txt.t("cfg_dicas_desc"))
	l5["direita"].add_child(_check("dicas", Txt.t("cfg_dicas_dica")))

	# A CHAVE DA TRAVA. Quando o boot acha um save ilegivel, o jogo para de
	# gravar para nao apagar o que talvez de para recuperar — e ate agora nao
	# existia caminho nenhum para religar. Quem tivesse um save corrompido
	# jogava para sempre sem gravar nada. A linha so aparece quando a trava
	# esta ligada; no uso normal ninguem ve.
	if jogo != null and jogo.salvamento_travado:
		var lt := _opcao(b3, "cadeado", UI.VERMELHO, Txt.t("sv_travado_titulo"),
			Txt.t("sv_travado_texto"))
		lt["direita"].add_child(UI.botao(Txt.t("sv_travado_botao"), func():
			jogo.destravar_salvamento()
			Bus.ui_atualizar.emit(true)))

	var l6 := _opcao(b3, "salvar", UI.VERDE, Txt.t("cfg_autosave"), Txt.t("cfg_autosave_desc"))
	l6["direita"].add_child(_slider("autosave_seg", 5, 120, 5, false, 84,
		func(x: float) -> String: return "%d s" % int(x),
		Txt.t("cfg_autosave_dica")))

# =============================================================== aba: ÁUDIO

func _aba_audio() -> void:
	var b := _bloco("velocidade", UI.ACENTO2, Txt.t("cfg_volumes"), Txt.t("cfg_volumes_sub"))

	_linha_volume(b, "vol_master", Txt.t("c_volume_geral"), Txt.t("cfg_vol_master_desc"))
	_linha_volume(b, "vol_sfx", Txt.t("c_volume_efeitos"), Txt.t("cfg_vol_sfx_desc"))
	_linha_volume(b, "vol_musica", Txt.t("c_volume_musica"), Txt.t("cfg_vol_musica_desc"))

	var b2 := _bloco("pausa", UI.VERMELHO, Txt.t("cfg_silencio"), Txt.t("cfg_silencio_sub"))
	var l := _opcao(b2, "pausa", UI.VERMELHO, Txt.t("c_mudo"), Txt.t("cfg_mudo_desc"))
	var cb := _check("mudo", Txt.t("cfg_mudo_dica"))
	cb.toggled.connect(func(_v: bool): _sincronizar_audio())
	l["direita"].add_child(cb)
	_sincronizar_audio()

	var nota := UI.painel(UI.PAINEL.darkened(0.25), 10)
	var nv := UI.vbox(4)
	nota.add_child(nv)
	nv.add_child(UI.rotulo(Txt.t("cfg_som_titulo"), 13, UI.ACENTO))
	var t := UI.rotulo(Txt.t("cfg_som_texto"), 12, UI.TEXTO2)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nv.add_child(t)
	var t2 := UI.rotulo(Txt.t("cfg_som_dica"), 12, UI.TEXTO3)
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nv.add_child(t2)
	conteudo.add_child(nota)

func _linha_volume(b: Dictionary, chave: String, nome: String, desc: String) -> void:
	var l := _opcao(b, "velocidade", UI.ACENTO2, nome, desc)
	var h := _slider(chave, 0.0, 1.0, 0.01, false, 56,
		func(x: float) -> String: return "%d%%" % int(round(x * 100.0)), desc)
	l["direita"].add_child(h)
	sliders_audio.append(h.get_child(0))
	rotulos_audio.append(h.get_child(1))

func _sincronizar_audio() -> void:
	var mudo := bool(Cfg.get_v("mudo", false))
	for s in sliders_audio:
		var sl: HSlider = s
		sl.editable = not mudo
		sl.modulate = Color(1, 1, 1, 0.4) if mudo else Color.WHITE
	for r in rotulos_audio:
		var lb: Label = r
		lb.add_theme_color_override("font_color", UI.TEXTO3 if mudo else UI.ACENTO)

# ============================================================ aba: GRÁFICOS

func _aba_graficos() -> void:
	var b := _bloco("nova", UI.ACENTO, Txt.t("cfg_desempenho"), Txt.t("cfg_desempenho_sub"))

	var l := _opcao(b, "nova", UI.ACENTO, Txt.t("c_qualidade"), Txt.t("cfg_qualidade_desc"))
	l["direita"].add_child(_menu("qualidade", [Txt.t("cfg_q_baixa"), Txt.t("cfg_q_media"), Txt.t("cfg_q_alta"), Txt.t("cfg_q_ultra")],
		[0, 1, 2, 3], Txt.t("cfg_qualidade_dica")))

	var l2 := _opcao(b, "estrela", UI.ACENTO, Txt.t("c_particulas"), Txt.t("cfg_densidade_desc"))
	l2["direita"].add_child(_slider("particulas", 0.0, 2.0, 0.05, false, 62,
		func(x: float) -> String: return "%d%%" % int(round(x * 100.0)),
		Txt.t("cfg_densidade_dica")))

	lbl_densidade = UI.rotulo("", 12, UI.TEXTO3)
	b["corpo"].add_child(lbl_densidade)

	var l3 := _opcao(b, "raio", UI.ACENTO, Txt.t("cfg_limite_fps"), Txt.t("cfg_limite_fps_desc"))
	l3["direita"].add_child(_menu("limite_fps", [Txt.t("cfg_sem_limite"), "30", "60", "120", "144"], [0, 30, 60, 120, 144],
		Txt.t("cfg_limite_fps_dica")))

	var l4 := _opcao(b, "stats", UI.ACENTO, Txt.t("c_mostrar_fps"),
		Txt.f("cfg_mostrar_fps_desc", {"t": _tecla("debug_toggle")}))
	l4["direita"].add_child(_check("mostrar_fps", Txt.t("cfg_mostrar_fps_dica")))

	var b2 := _bloco("fogo", UI.LARANJA, Txt.t("cfg_impacto"), Txt.t("cfg_impacto_sub"))

	var l5 := _opcao(b2, "fogo", UI.LARANJA, Txt.t("c_tremor"), Txt.t("cfg_tremor_desc"))
	l5["direita"].add_child(_slider("tremor", 0.0, 2.0, 0.05, false, 62,
		func(x: float) -> String: return "%d%%" % int(round(x * 100.0)),
		Txt.t("cfg_tremor_dica")))

	var l6 := _opcao(b2, "raio", UI.LARANJA, Txt.t("c_flashes"), Txt.t("cfg_flashes_desc"))
	l6["direita"].add_child(_check("flashes", Txt.t("cfg_flashes_dica")))

	var l7 := _opcao(b2, "espada", UI.LARANJA, Txt.t("c_numeros_dano"), Txt.t("cfg_numeros_dano_desc"))
	l7["direita"].add_child(_menu("numeros_dano", [Txt.t("cfg_dano_todos"), Txt.t("cfg_dano_criticos"), Txt.t("nenhum")], [0, 1, 2],
		Txt.t("cfg_numeros_dano_dica")))

	var b3 := _bloco("engrenagem", UI.ACENTO2, Txt.t("cfg_janela"), Txt.t("cfg_janela_sub"))

	var l8 := _opcao(b3, "nova", UI.ACENTO2, Txt.t("c_tela_cheia"),
		Txt.f("cfg_tela_cheia_desc", {"t": _tecla("tela_cheia")}))
	l8["direita"].add_child(_check("tela_cheia", Txt.t("cfg_tela_cheia_dica")))

	var l9 := _opcao(b3, "mais", UI.ACENTO2, Txt.t("cfg_escala_ui"), Txt.t("cfg_escala_ui_desc"))
	l9["direita"].add_child(_slider("escala_ui", 0.85, 1.25, 0.05, false, 62,
		func(x: float) -> String: return "%d%%" % int(round(x * 100.0)),
		Txt.t("cfg_escala_ui_dica")))

# ====================================================== aba: ACESSIBILIDADE

func _aba_acessibilidade() -> void:
	var b := _bloco("coracao", UI.ROSA, Txt.t("cfg_conforto"), Txt.t("cfg_conforto_sub"))

	var l := _opcao(b, "coracao", UI.ROSA, Txt.t("c_movimento_reduzido"), Txt.t("cfg_mov_reduzido_desc"))
	l["direita"].add_child(_check("movimento_reduzido", Txt.t("cfg_mov_reduzido_dica")))

	var l2 := _opcao(b, "orbe", UI.ROSA, Txt.t("c_daltonismo"), Txt.t("cfg_daltonismo_desc"))
	l2["direita"].add_child(_menu("daltonismo",
		[Txt.t("nenhum"), "Protanopia", "Deuteranopia", "Tritanopia"], [0, 1, 2, 3],
		Txt.t("cfg_daltonismo_dica")))

	var l3 := _opcao(b, "escudo", UI.ROSA, Txt.t("c_alto_contraste"), Txt.t("cfg_alto_contraste_desc"))
	l3["direita"].add_child(_check("alto_contraste", Txt.t("cfg_alto_contraste_dica")))

	var l4 := _opcao(b, "livro", UI.ROSA, Txt.t("c_fonte_grande"), Txt.t("cfg_fonte_grande_desc"))
	l4["direita"].add_child(_check("fonte_grande", Txt.t("cfg_fonte_grande_dica")))

	var l5 := _opcao(b, "raio", UI.ROSA, Txt.t("cfg_vibracao"), Txt.t("cfg_vibracao_desc"))
	l5["direita"].add_child(_check("vibracao", Txt.t("cfg_vibracao_dica")))

	var nota := UI.painel(UI.PAINEL.darkened(0.25), 10)
	var nv := UI.vbox(3)
	nota.add_child(nv)
	nv.add_child(UI.rotulo(Txt.t("cfg_filtro_titulo"), 13, UI.ACENTO))
	var texto := UI.rotulo(Txt.t("cfg_filtro_texto"), 12, UI.TEXTO2)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nv.add_child(texto)
	conteudo.add_child(nota)

# ================================================================ aba: SAVE

func _aba_save() -> void:
	var b := _bloco("salvar", UI.VERDE, Txt.t("cfg_este_save"), Txt.t("cfg_este_save_sub"))

	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 18)
	grade.add_theme_constant_override("v_separation", 4)
	lbl_tamanho = _info(grade, Txt.t("cfg_tamanho"))
	lbl_data = _info(grade, Txt.t("cfg_ultimo_salvamento"))
	lbl_proximo = _info(grade, Txt.t("cfg_proximo_autosave"))
	_info(grade, Txt.t("cfg_formato")).text = Txt.f("cfg_versao_n", {"n": SaveSys.VERSAO})
	b["corpo"].add_child(grade)

	var acoes := UI.hbox(8)
	var b_salvar := UI.botao(Txt.t("salvar_agora"), _salvar_agora,
		Txt.f("cfg_salvar_dica", {"t": _tecla("salvar_agora")}))
	b_salvar.custom_minimum_size = Vector2(150, 40)
	acoes.add_child(b_salvar)

	var b_exp := UI.botao(Txt.t("c_exportar"), _exportar, Txt.t("cfg_exportar_dica"))
	b_exp.custom_minimum_size = Vector2(150, 40)
	acoes.add_child(b_exp)

	var b_imp := UI.botao(Txt.t("c_importar"), func(): _mostrar_importar(true), Txt.t("cfg_importar_dica"))
	b_imp.custom_minimum_size = Vector2(150, 40)
	acoes.add_child(b_imp)

	acoes.add_child(UI.espacador())

	btn_apagar = UI.botao(Txt.t("c_apagar"), _apagar_passo, Txt.t("cfg_apagar_dica"))
	btn_apagar.custom_minimum_size = Vector2(150, 40)
	btn_apagar.add_theme_color_override("font_color", UI.VERMELHO)
	acoes.add_child(btn_apagar)
	b["corpo"].add_child(acoes)

	# ---- exportar ----
	caixa_exportar = UI.painel(UI.PAINEL.darkened(0.25), 10)
	caixa_exportar.visible = false
	var ve := UI.vbox(6)
	caixa_exportar.add_child(ve)
	ve.add_child(UI.rotulo(Txt.t("cfg_export_aviso"), 12, UI.TEXTO2))
	te_exportar = _texto_area(96, false)
	ve.add_child(te_exportar)
	var he := UI.hbox(8)
	var b_copiar := UI.botao(Txt.t("c_copiar"), func():
		DisplayServer.clipboard_set(te_exportar.text)
		UI.pulsar(caixa_exportar, UI.VERDE)
		Bus.toast(Txt.t("cfg_copiado"), "bom"), Txt.t("cfg_copiar_dica"))
	b_copiar.custom_minimum_size = Vector2(120, 34)
	he.add_child(b_copiar)
	var b_sel := UI.botao(Txt.t("cfg_selecionar_tudo"), func():
		te_exportar.grab_focus()
		te_exportar.select_all(), Txt.t("cfg_selecionar_dica"))
	b_sel.custom_minimum_size = Vector2(140, 34)
	he.add_child(b_sel)
	he.add_child(UI.espacador())
	var b_fec := UI.botao(Txt.t("cfg_ocultar"), func(): caixa_exportar.visible = false)
	b_fec.custom_minimum_size = Vector2(100, 34)
	he.add_child(b_fec)
	ve.add_child(he)
	b["corpo"].add_child(caixa_exportar)

	# ---- importar ----
	caixa_importar = UI.painel(UI.PAINEL.darkened(0.25), 10)
	caixa_importar.visible = false
	var vi := UI.vbox(6)
	caixa_importar.add_child(vi)
	vi.add_child(UI.rotulo(Txt.t("cfg_import_aviso"), 12, UI.LARANJA))
	te_importar = _texto_area(96, true)
	te_importar.placeholder_text = "TORRE1|..."
	vi.add_child(te_importar)
	lbl_erro = UI.rotulo("", 12, UI.VERMELHO)
	lbl_erro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vi.add_child(lbl_erro)
	var hi := UI.hbox(8)
	var b_ok := UI.botao(Txt.t("cfg_importar_substituir"), _importar, Txt.t("cfg_importar_ok_dica"))
	b_ok.custom_minimum_size = Vector2(190, 34)
	hi.add_child(b_ok)
	var b_colar := UI.botao(Txt.t("cfg_colar"), func():
		te_importar.text = DisplayServer.clipboard_get()
		lbl_erro.text = "", Txt.t("cfg_colar_dica"))
	b_colar.custom_minimum_size = Vector2(100, 34)
	hi.add_child(b_colar)
	hi.add_child(UI.espacador())
	var b_can := UI.botao(Txt.t("cancelar"), func(): _mostrar_importar(false))
	b_can.custom_minimum_size = Vector2(100, 34)
	hi.add_child(b_can)
	vi.add_child(hi)
	b["corpo"].add_child(caixa_importar)

	# ---- apagar tudo ----
	caixa_apagar = UI.painel(UI.PAINEL.darkened(0.25), 10)
	caixa_apagar.add_theme_stylebox_override("panel", UI.caixa(UI.PAINEL.darkened(0.25), 10, 1, UI.VERMELHO.darkened(0.35)))
	caixa_apagar.visible = false
	var va := UI.vbox(5)
	caixa_apagar.add_child(va)
	va.add_child(UI.rotulo(Txt.t("cfg_apagar_titulo"), 14, UI.VERMELHO))
	for linha_perda in _lista_perdas():
		va.add_child(UI.rotulo("·  " + str(linha_perda), 12, UI.TEXTO2))
	va.add_child(UI.rotulo(Txt.t("cfg_apagar_config_nota"), 12, UI.TEXTO3))
	var ha := UI.hbox(8)
	var b_backup := UI.botao(Txt.t("cfg_exportar_antes"), _exportar, Txt.t("cfg_exportar_antes_dica"))
	b_backup.custom_minimum_size = Vector2(150, 34)
	ha.add_child(b_backup)
	ha.add_child(UI.espacador())
	var b_cancelar := UI.botao(Txt.t("cancelar"), func(): _apagar_cancelar())
	b_cancelar.custom_minimum_size = Vector2(120, 34)
	ha.add_child(b_cancelar)
	va.add_child(ha)
	b["corpo"].add_child(caixa_apagar)

	# ---- atalhos ----
	var b2 := _bloco("engrenagem", UI.ACENTO, Txt.t("c_atalhos"), Txt.t("cfg_atalhos_sub"))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 5)
	for item in ATALHOS:
		var par: Array = item
		_par_atalho(g, _tecla(str(par[0])), Txt.t(str(par[1])))
	_par_atalho(g, "1 – 0", Txt.t("cfg_at_slots"))
	_par_atalho(g, Txt.t("cfg_tecla_clique"), Txt.t("cfg_at_clique"))
	b2["corpo"].add_child(g)

func _par_atalho(g: GridContainer, tecla: String, desc: String) -> void:
	var cx := UI.painel(UI.PAINEL2.darkened(0.1), 6)
	var lt := UI.rotulo(tecla, 13, UI.ACENTO)
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lt.custom_minimum_size.x = 62
	cx.add_child(lt)
	g.add_child(cx)
	var ld := UI.rotulo(desc, 12, UI.TEXTO2)
	ld.custom_minimum_size.x = 300
	g.add_child(ld)

# =============================================================== aba: SOBRE

func _aba_sobre() -> void:
	var capa := UI.painel(UI.PAINEL.darkened(0.25), 12)
	var v := UI.vbox(6)
	capa.add_child(v)
	var h := UI.hbox(12)
	var ic := UI.icone("torre", UI.ACENTO, 46)
	h.add_child(ic)
	var vt := UI.vbox(2)
	h.add_child(vt)
	var t := UI.titulo(NOME_JOGO, 30)
	vt.add_child(t)
	vt.add_child(UI.rotulo(Txt.t("cfg_subtitulo"), 14, UI.TEXTO2))
	v.add_child(h)
	v.add_child(UI.separador())
	var p := UI.rotulo(Txt.t("cfg_sobre_texto"), 13, UI.TEXTO2)
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(p)
	conteudo.add_child(capa)

	var b := _bloco("livro", UI.ACENTO, Txt.t("cfg_versao"), Txt.t("cfg_versao_sub"))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 4)
	_info(g, Txt.t("c_jogo")).text = "v" + VERSAO_JOGO
	_info(g, Txt.t("cfg_formato_save")).text = Txt.f("cfg_versao_n", {"n": SaveSys.VERSAO})
	var vi: Dictionary = Engine.get_version_info()
	_info(g, Txt.t("cfg_motor")).text = "Godot %s" % str(vi.get("string", "4.4"))
	_info(g, Txt.t("cfg_plataforma")).text = OS.get_name()
	b["corpo"].add_child(g)

	var b2 := _bloco("trofeu", UI.OURO, Txt.t("cfg_sua_torre"), Txt.t("cfg_sua_torre_sub"))
	var g2 := GridContainer.new()
	g2.columns = 4
	g2.add_theme_constant_override("h_separation", 18)
	g2.add_theme_constant_override("v_separation", 4)
	lbl_tempo_total = _info(g2, Txt.t("cfg_tempo_total"))
	_info(g2, Txt.t("cfg_onda_maxima")).text = Fmt.inteiro(int(jogo.s["onda_maxima_global"]))
	_info(g2, Txt.t("ascensoes").capitalize()).text = Fmt.inteiro(int(jogo.s["prestigio"]["ascensoes"]))
	_info(g2, Txt.t("cfg_criado_em")).text = _data_br(int(jogo.s["criado_em"]))
	b2["corpo"].add_child(g2)

	var b3 := _bloco("carta", UI.ACENTO2, Txt.t("cfg_creditos"), Txt.t("cfg_creditos_sub"))
	for par in [
		[Txt.t("cfg_cred_projeto"), "Joab Costa"],
		[Txt.t("cfg_motor"), "Godot Engine 4.4 — MIT"],
		[Txt.t("cfg_arte"), Txt.t("cfg_cred_arte_v")],
		[Txt.t("c_audio"), Txt.t("cfg_cred_audio_v")],
		[Txt.t("cfg_agradecimentos"), Txt.t("cfg_cred_obrigado_v")],
	]:
		var linha_par: Array = par
		var hh := UI.hbox(10)
		var a := UI.rotulo(str(linha_par[0]), 13, UI.TEXTO3)
		a.custom_minimum_size.x = 250
		hh.add_child(a)
		hh.add_child(UI.rotulo(str(linha_par[1]), 13, UI.TEXTO))
		b3["corpo"].add_child(hh)

	var rodape := UI.rotulo(Txt.t("cfg_rodape_sobre"), 12, UI.TEXTO3)
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(rodape)

# ============================================================ ações do save

func _salvar_agora() -> void:
	if jogo == null:
		return
	if jogo.salvar():
		Bus.toast(Txt.t("jogo_salvo"), "bom")
		if lbl_tamanho != null:
			UI.pulsar(lbl_tamanho, UI.VERDE)
	else:
		Bus.toast(SaveSys.ultimo_erro if SaveSys.ultimo_erro != "" else Txt.t("cfg_falha_salvar"), "ruim")
	atualizar()

func _exportar() -> void:
	if jogo == null or te_exportar == null:
		return
	te_exportar.text = str(jogo.exportar())
	caixa_exportar.visible = true
	UI.pulsar(caixa_exportar, UI.ACENTO)
	Bus.toast(Txt.t("cfg_codigo_gerado"), "info")
	atualizar()

func _mostrar_importar(v: bool) -> void:
	if caixa_importar == null:
		return
	caixa_importar.visible = v
	if v:
		lbl_erro.text = ""
		te_importar.grab_focus()

func _importar() -> void:
	if jogo == null or te_importar == null:
		return
	var texto := te_importar.text.strip_edges()
	if texto.is_empty():
		lbl_erro.text = Txt.t("cfg_cole_antes")
		return
	SaveSys.ultimo_erro = ""
	if jogo.importar(texto):
		lbl_erro.text = ""
		caixa_importar.visible = false
		te_importar.text = ""
		Bus.toast(Txt.t("save_importado"), "epico")
		jogo.salvar()
		_reconstruir()
	else:
		lbl_erro.text = SaveSys.ultimo_erro if SaveSys.ultimo_erro != "" else Txt.t("save_invalido")
		UI.pulsar(caixa_importar, UI.VERMELHO)

func _apagar_passo() -> void:
	if btn_apagar == null:
		return
	passo_apagar += 1
	match passo_apagar:
		1:
			caixa_apagar.visible = true
			btn_apagar.text = Txt.t("cfg_sim_apagar")
			btn_apagar.tooltip_text = Txt.t("cfg_apagar_conf1")
			UI.pulsar(caixa_apagar, UI.VERMELHO)
		2:
			btn_apagar.text = Txt.t("confirmar").to_upper()
			btn_apagar.tooltip_text = Txt.t("cfg_apagar_conf2")
			UI.saltar(btn_apagar, 1.1)
		_:
			jogo.apagar_tudo()
			jogo.salvar()
			Bus.toast(Txt.t("cfg_tudo_apagado"), "ruim")
			_apagar_cancelar()
			_reconstruir()

func _apagar_cancelar() -> void:
	passo_apagar = 0
	if caixa_apagar != null:
		caixa_apagar.visible = false
	if btn_apagar != null:
		btn_apagar.text = Txt.t("c_apagar")
		btn_apagar.tooltip_text = Txt.t("cfg_apagar_dica2")

func _lista_perdas() -> Array:
	var out: Array = []
	if jogo == null:
		return out
	var s: Dictionary = jogo.s
	var pres: Dictionary = s["prestigio"]
	var cartas: Dictionary = s["cartas"]
	var inv: Array = cartas["inventario"]
	var conq: Dictionary = s["conquistas"]
	out.append(Txt.f("cfg_perda_onda", {
		"n": Fmt.inteiro(int(s["onda_maxima"])), "g": Fmt.inteiro(int(s["onda_maxima_global"]))}))
	out.append(Txt.f("cfg_perda_nivel", {
		"n": Fmt.inteiro(int(s["nivel"])),
		"p": Fmt.inteiro(int(s["pontos_talento"]) + int(s["pontos_talento_gastos"]))}))
	out.append(Txt.f("cfg_perda_prestigio", {
		"a": Fmt.inteiro(int(pres["ascensoes"])), "s": Fmt.inteiro(int(pres["singularidades"])),
		"t": Fmt.inteiro(int(pres["transcendencias"]))}))
	out.append(Txt.t("cfg_perda_arvores"))
	out.append(Txt.f("cfg_perda_cartas", {"c": Fmt.inteiro(inv.size()), "q": Fmt.inteiro(conq.size())}))
	out.append(Txt.t("cfg_perda_moedas"))
	return out

# ================================================================ aplicação

func _mudar(chave: String, valor: Variant) -> void:
	Cfg.set_v(chave, valor)
	match chave:
		"escala_ui", "fonte_grande":
			_aplicar_escala()
		"daltonismo", "alto_contraste":
			_aplicar_filtro()
		"idioma":
			Bus.toast(Txt.t("cfg_idioma_alterado"), "info")
		"tela_cheia":
			await get_tree().process_frame
			if is_inside_tree():
				_ajustar_janela()

func _escolher_notacao(idx: int) -> void:
	_mudar("notacao", idx)
	if menu_notacao != null:
		menu_notacao.select(idx)
	atualizar()

func _restaurar() -> void:
	passo_restaurar += 1
	if passo_restaurar < 2:
		btn_restaurar.text = Txt.t("cfg_confirmar_padroes")
		btn_restaurar.add_theme_color_override("font_color", UI.LARANJA)
		return
	Cfg.restaurar_padrao()
	_aplicar_escala()
	_aplicar_filtro()
	Bus.toast(Txt.t("cfg_restaurado"), "info")
	_reconstruir()

## Escala global da janela (interface e campo juntos), com o bônus de fonte grande.
func _aplicar_escala() -> void:
	var e := float(Cfg.get_v("escala_ui", 1.0))
	if bool(Cfg.get_v("fonte_grande", false)):
		e *= 1.12
	var jan := get_window()
	if jan != null:
		jan.content_scale_factor = clampf(e, 0.7, 1.6)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_ajustar_janela()

## Mantém a janela do painel dentro da tela quando a escala ou o tamanho mudam.
func _ajustar_janela() -> void:
	if janela == null or not is_instance_valid(janela):
		return
	var tam := get_viewport_rect().size
	var w := minf(largura, tam.x - 32.0)
	var h := minf(altura, tam.y - 32.0)
	if absf(janela.offset_right - w * 0.5) < 0.5 and absf(janela.offset_bottom - h * 0.5) < 0.5:
		return
	janela.offset_left = -w * 0.5
	janela.offset_right = w * 0.5
	janela.offset_top = -h * 0.5
	janela.offset_bottom = h * 0.5

## Camada de correção de cor sobre a imagem final (daltonismo / alto contraste).

## O filtro mora no Cfg (autoload), para valer desde a abertura do jogo e não
## só quando alguém abre este painel. Aqui só pedimos a reaplicação.
func _aplicar_filtro() -> void:
	Cfg.aplicar()

# =============================================================== atualização

func atualizar() -> void:
	if jogo == null or conteudo == null:
		return
	_ajustar_janela()
	match aba:
		0: _atualizar_jogo()
		2: _atualizar_graficos()
		4: _atualizar_save()
		5: _atualizar_sobre()

func _atualizar_jogo() -> void:
	if previa_linhas.is_empty():
		return
	var amostra := _valor_amostra()
	if previa_titulo != null:
		previa_titulo.text = Txt.f("cfg_previa_titulo", {"n": _fmt_em(2, amostra)})
	var atual := int(Cfg.get_v("notacao", 0))
	for item in previa_linhas:
		var r: Dictionary = item
		var i := int(r["idx"])
		var lbl: Label = r["valor"]
		lbl.text = _fmt_em(i, amostra)
		lbl.add_theme_color_override("font_color", UI.ACENTO if i == atual else UI.TEXTO)
		var cx: PanelContainer = r["caixa"]
		cx.add_theme_stylebox_override("panel", _sb_previa_on if i == atual else _sb_previa_off)

func _atualizar_graficos() -> void:
	if lbl_densidade == null:
		return
	var d := Cfg.densidade_particulas()
	var extra := Txt.t("cfg_densidade_corte") if bool(Cfg.get_v("movimento_reduzido", false)) else ""
	lbl_densidade.text = Txt.f("cfg_densidade_resultado", {"p": Fmt.pct(d, 0), "extra": extra})

func _atualizar_save() -> void:
	if lbl_tamanho == null:
		return
	var kb := SaveSys.tamanho_kb()
	lbl_tamanho.text = Txt.t("cfg_sem_arquivo") if kb <= 0.0 else "%s KB" % Fmt.num(kb, 1)
	var ts := int(jogo.s["salvo_em"])
	if ts <= 0:
		lbl_data.text = Txt.t("cfg_nunca")
	else:
		var agora := int(Time.get_unix_time_from_system())
		lbl_data.text = Txt.f("cfg_data_ha", {
			"d": _data_br(ts), "t": Ux.tempo_curto(float(maxi(0, agora - ts)))})
	var intervalo_auto := float(Cfg.get_v("autosave_seg", 20.0))
	var falta := maxf(0.0, intervalo_auto - float(jogo.tempo_autosave))
	lbl_proximo.text = Txt.f("cfg_proximo_em", {"t": Ux.tempo_curto(falta), "s": int(intervalo_auto)})

func _atualizar_sobre() -> void:
	if lbl_tempo_total == null:
		return
	lbl_tempo_total.text = Ux.tempo_curto(float(jogo.s["stats"]["tempo_total"]))

# ================================================================ utilidades

## Bloco de seção: título, subtítulo e um corpo onde as opções entram.
func _bloco(icone: String, cor: Color, titulo: String, subtitulo: String) -> Dictionary:
	var cx := UI.painel(UI.PAINEL2.darkened(0.2), 12)
	cx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	cx.add_child(v)
	var h := UI.hbox(8)
	var ic := UI.icone(icone, cor, 20)
	h.add_child(ic)
	h.add_child(UI.rotulo(titulo, 17, cor))
	v.add_child(h)
	if subtitulo != "":
		var sub := UI.rotulo(subtitulo, 12, UI.TEXTO3)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(sub)
	v.add_child(UI.separador())
	var corpo_bloco := UI.vbox(5)
	corpo_bloco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(corpo_bloco)
	conteudo.add_child(cx)
	return {"caixa": cx, "corpo": corpo_bloco}

## Linha de opção: ícone, nome, explicação do efeito real e o controle à direita.
func _opcao(b: Dictionary, icone: String, cor: Color, nome: String, desc: String) -> Dictionary:
	var l := linha(icone, cor)
	l["textos"].add_child(UI.rotulo(nome, 15, UI.TEXTO))
	var d := UI.rotulo(desc, 12, UI.TEXTO2)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 470
	l["textos"].add_child(d)
	l["caixa"].tooltip_text = desc
	l["caixa"].mouse_filter = Control.MOUSE_FILTER_PASS
	var dir: HBoxContainer = l["direita"]
	dir.alignment = BoxContainer.ALIGNMENT_END
	dir.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var corpo_bloco: VBoxContainer = b["corpo"]
	corpo_bloco.add_child(l["caixa"])
	return l

func _check(chave: String, dica: String) -> CheckButton:
	var cb := CheckButton.new()
	cb.focus_mode = Control.FOCUS_ALL
	cb.tooltip_text = dica
	cb.button_pressed = bool(Cfg.get_v(chave, false))
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb.toggled.connect(func(v: bool): _mudar(chave, v))
	return cb

func _menu(chave: String, itens: Array, valores: Array, dica: String) -> OptionButton:
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_ALL
	ob.tooltip_text = dica
	ob.custom_minimum_size = Vector2(186, 36)
	ob.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in itens.size():
		ob.add_item(str(itens[i]), i)
	var atual: Variant = Cfg.get_v(chave, valores[0])
	var sel := 0
	for i in valores.size():
		if valores[i] == atual:
			sel = i
	ob.select(sel)
	ob.item_selected.connect(func(i: int): _mudar(chave, valores[i]))
	return ob

func _slider(chave: String, minimo: float, maximo: float, passo: float, inteiro: bool,
		largura_rotulo: float, formato: Callable, dica: String) -> HBoxContainer:
	var h := UI.hbox(8)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sl := HSlider.new()
	sl.min_value = minimo
	sl.max_value = maximo
	sl.step = passo
	sl.value = float(Cfg.get_v(chave, minimo))
	sl.custom_minimum_size = Vector2(200, 22)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.focus_mode = Control.FOCUS_ALL
	sl.tooltip_text = dica
	h.add_child(sl)
	var lv := UI.rotulo(str(formato.call(sl.value)), 14, UI.ACENTO)
	lv.custom_minimum_size.x = largura_rotulo
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(lv)
	sl.value_changed.connect(func(v: float):
		lv.text = str(formato.call(v))
		_mudar(chave, int(round(v)) if inteiro else v))
	return h

## Par rótulo/valor para as grades de informação.
func _info(g: GridContainer, nome: String) -> Label:
	var a := UI.rotulo(nome, 12, UI.TEXTO3)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	a.custom_minimum_size.x = 130
	g.add_child(a)
	var b := UI.rotulo("—", 14, UI.TEXTO)
	b.custom_minimum_size.x = 200
	g.add_child(b)
	return b

func _texto_area(alt: float, editavel: bool) -> TextEdit:
	var te := TextEdit.new()
	te.custom_minimum_size.y = alt
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.editable = editavel
	te.selecting_enabled = true
	te.add_theme_font_size_override("font_size", 12)
	te.scroll_fit_content_height = false
	return te

func _nomes_notacao() -> Array:
	var out: Array = []
	for item in NOTACOES:
		var par: Array = item
		out.append(Txt.t(str(par[0])))
	return out

## Formata um valor em log10 numa notação específica sem mexer na do jogador.
func _fmt_em(n: int, valor_log: float) -> String:
	var antes := int(Fmt.notacao)
	Fmt.notacao = n as Fmt.Notacao
	var s := Fmt.big(valor_log)
	Fmt.notacao = antes as Fmt.Notacao
	return s

## Número da prévia: usa o ouro do jogador quando já é grande o bastante.
func _valor_amostra() -> float:
	var ouro := float(jogo.s["moedas"]["ouro"])
	return ouro if ouro > 9.0 else 15.0915

func _data_br(ts: int) -> String:
	if ts <= 0:
		return "—"
	var fuso: Dictionary = Time.get_time_zone_from_system()
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(ts + int(fuso.get("bias", 0)) * 60)
	return Txt.f("cfg_data_hora", {
		"d": "%02d" % int(d["day"]), "m": "%02d" % int(d["month"]), "a": "%04d" % int(d["year"]),
		"h": "%02d" % int(d["hour"]), "min": "%02d" % int(d["minute"])})

func _tecla(acao: String) -> String:
	if not InputMap.has_action(acao):
		return "—"
	for e in InputMap.action_get_events(acao):
		if e is InputEventKey:
			var k: InputEventKey = e
			var codigo := k.physical_keycode if k.physical_keycode != 0 else k.keycode
			var nome := OS.get_keycode_string(codigo)
			var chave := str(TECLA_NOME.get(nome, ""))
			return Txt.t(chave) if chave != "" else nome
	return "—"
