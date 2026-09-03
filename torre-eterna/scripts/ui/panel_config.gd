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

const NOTACOES := [
	["Mista", "Letras até Vg, depois científica. O padrão sensato."],
	["Letras", "1,23 K · 4,56 M · 7,89 Qa — e segue o alfabeto quando acabam os nomes."],
	["Científica", "1,23e15. Compacta e fria."],
	["Engenharia", "Expoentes múltiplos de 3: 1,23e15, 45,6e18."],
	["Por extenso", "1,23 quatrilhões. Ocupa espaço, mas se lê alto."],
	["Logarítmica", "e15,092. Para quem já pensa em log10."],
]

const ATALHOS := [
	["ui_pausa", "Pausar o jogo / fechar o painel aberto"],
	["painel_upgrades", "Abrir Melhorias"],
	["painel_talentos", "Abrir Talentos"],
	["painel_cartas", "Abrir Cartas"],
	["painel_prestigio", "Abrir Prestígio"],
	["painel_conquistas", "Abrir Conquistas"],
	["painel_config", "Abrir Configurações (este painel)"],
	["comprar_max", "Comprar o máximo da melhoria em foco"],
	["alternar_auto", "Ligar/desligar a compra automática"],
	["turbo", "Alternar a velocidade do jogo"],
	["purga", "Purga — limpa a tela quando a coisa aperta"],
	["salvar_agora", "Salvar agora"],
	["tela_cheia", "Alternar tela cheia"],
	["debug_toggle", "Mostrar/ocultar o contador de FPS"],
]

const TECLA_PT := {
	"Escape": "Esc", "Space": "Espaço", "Enter": "Enter", "KpEnter": "Enter (num)",
	"Backspace": "Backspace", "Tab": "Tab", "Shift": "Shift", "Ctrl": "Ctrl",
}

# ------------------------------------------------------------------ estado

var abas: TabBar
var rolagem: ScrollContainer
var conteudo: VBoxContainer
var aba := 4
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
	titulo_texto = "Configurações"
	titulo_icone = "engrenagem"
	largura = 920.0
	altura = 648.0
	intervalo = 0.25

func montar(c: VBoxContainer) -> void:
	_sb_previa_on = UI.caixa(UI.PAINEL2, 8, 1, UI.ACENTO)
	_sb_previa_off = UI.caixa(Color(0, 0, 0, 0), 8, 0)

	abas = TabBar.new()
	abas.clip_tabs = false
	for nome in ["Jogo", "Áudio", "Gráficos", "Acessibilidade", "Save", "Sobre"]:
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
	rodape_aviso = UI.rotulo("As opções ficam fora do save — sobrevivem até a um apagar tudo.", 12, UI.TEXTO3)
	pe.add_child(rodape_aviso)
	pe.add_child(UI.espacador())
	btn_restaurar = UI.botao("Restaurar padrões", _restaurar,
		"Devolve TODAS as opções ao estado de fábrica. Não toca no seu progresso.")
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
		btn_restaurar.text = "Restaurar padrões"
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
	var b := _bloco("livro", UI.ACENTO, "Idioma", "Vale para nomes e descrições vindos dos dados do jogo.")
	var l := _opcao(b, "livro", UI.ACENTO, "Idioma dos textos",
		"Português do Brasil ou inglês. Os menus do jogo permanecem em português.")
	l["direita"].add_child(_menu("idioma", ["Português (BR)", "English"], ["pt", "en"],
		"Troca o idioma de melhorias, cartas, conquistas e lore."))

	var b2 := _bloco("stats", UI.OURO, "Números",
		"Você vai passar de 1e100 mais cedo do que imagina. Escolha como quer ler isso.")
	var l2 := _opcao(b2, "stats", UI.OURO, "Notação numérica",
		"Como os valores gigantes aparecem no HUD e nos painéis.")
	menu_notacao = _menu("notacao", _nomes_notacao(), [0, 1, 2, 3, 4, 5],
		"Clique também numa linha da prévia abaixo para escolher.")
	l2["direita"].add_child(menu_notacao)

	# ---- prévia ao vivo: o MESMO número em todas as notações ----
	var cx := UI.painel(UI.PAINEL.darkened(0.25), 10)
	cx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(3)
	cx.add_child(v)
	previa_titulo = UI.rotulo("Prévia", 12, UI.TEXTO3)
	v.add_child(previa_titulo)
	for i in NOTACOES.size():
		var item: Array = NOTACOES[i]
		var caixa := PanelContainer.new()
		caixa.add_theme_stylebox_override("panel", _sb_previa_off)
		caixa.mouse_filter = Control.MOUSE_FILTER_STOP
		caixa.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		caixa.tooltip_text = str(item[1])
		var idx := i
		caixa.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed:
				_escolher_notacao(idx))
		var h := UI.hbox(10)
		caixa.add_child(h)
		var nome := UI.rotulo(str(item[0]), 13, UI.TEXTO2)
		nome.custom_minimum_size.x = 130
		h.add_child(nome)
		var valor := UI.rotulo("—", 16, UI.TEXTO)
		valor.custom_minimum_size.x = 160
		h.add_child(valor)
		var expl := UI.rotulo(str(item[1]), 11, UI.TEXTO3)
		expl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		expl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(expl)
		v.add_child(caixa)
		previa_linhas.append({"caixa": caixa, "valor": valor, "idx": idx})
	b2["corpo"].add_child(cx)

	var l3 := _opcao(b2, "balanca", UI.OURO, "Casas decimais",
		"Quantos dígitos depois da vírgula. Menos casas, HUD mais limpo.")
	l3["direita"].add_child(_slider("casas", 0, 4, 1, true, 60,
		func(x: float) -> String: return "%d" % int(x),
		"De 0 a 4 casas. A prévia acima muda junto."))

	var b3 := _bloco("engrenagem", UI.VERDE, "Comportamento", "Pequenas manias do jogo.")
	var l4 := _opcao(b3, "escudo", UI.VERDE, "Confirmar prestígio",
		"Pede confirmação antes de ascender, colapsar ou transcender. Desligue só se você já sabe o que está fazendo.")
	l4["direita"].add_child(_check("confirmar_prestigio", "Janela de confirmação antes de zerar a run."))

	var l5 := _opcao(b3, "estrela", UI.VERDE, "Dicas flutuantes",
		"Mostra dicas curtas de mecânica na tela de título e nos cantos ociosos da interface.")
	l5["direita"].add_child(_check("dicas", "Ligue para receber dicas; desligue se já decorou tudo."))

	var l6 := _opcao(b3, "salvar", UI.VERDE, "Intervalo de autosave",
		"De quanto em quanto tempo o jogo grava sozinho. O jogo também salva ao fechar a janela.")
	l6["direita"].add_child(_slider("autosave_seg", 5, 120, 5, false, 84,
		func(x: float) -> String: return "%d s" % int(x),
		"Entre 5 e 120 segundos."))

# =============================================================== aba: ÁUDIO

func _aba_audio() -> void:
	var b := _bloco("velocidade", UI.ACENTO2, "Volumes",
		"Tudo passa pelo volume geral. Os outros dois são proporções dele.")

	_linha_volume(b, "vol_master", "Volume geral", "Controla o barramento Master — afeta absolutamente todo o som.")
	_linha_volume(b, "vol_sfx", "Efeitos", "Tiros, explosões, moedas, chefes. O barulho do combate.")
	_linha_volume(b, "vol_musica", "Música", "A trilha de fundo. Baixe sem culpa se estiver ouvindo outra coisa.")

	var b2 := _bloco("pausa", UI.VERMELHO, "Silêncio", "Para quando alguém entra na sala.")
	var l := _opcao(b2, "pausa", UI.VERMELHO, "Mudo",
		"Silencia o barramento Master inteiro sem perder os volumes que você ajustou.")
	var cb := _check("mudo", "Corta todo o som. Os sliders acima ficam guardados.")
	cb.toggled.connect(func(_v: bool): _sincronizar_audio())
	l["direita"].add_child(cb)
	_sincronizar_audio()

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
	var b := _bloco("nova", UI.ACENTO, "Desempenho",
		"Se o jogo engasgar na onda 400 com meio milhão de partículas, é aqui que se resolve.")

	var l := _opcao(b, "nova", UI.ACENTO, "Qualidade",
		"Preset que multiplica a densidade de partículas: baixa ×0,35 · média ×0,65 · alta ×1,0 · ultra ×1,45.")
	l["direita"].add_child(_menu("qualidade", ["Baixa", "Média", "Alta", "Ultra"], [0, 1, 2, 3],
		"Comece em alta. Caia para média ou baixa se os FPS derreterem."))

	var l2 := _opcao(b, "estrela", UI.ACENTO, "Densidade de partículas",
		"Multiplicador fino por cima da qualidade. Em 0% o jogo fica silencioso visualmente, mas roda em qualquer coisa.")
	l2["direita"].add_child(_slider("particulas", 0.0, 2.0, 0.05, false, 62,
		func(x: float) -> String: return "%d%%" % int(round(x * 100.0)),
		"De 0% a 200% das partículas normais."))

	lbl_densidade = UI.rotulo("", 12, UI.TEXTO3)
	b["corpo"].add_child(lbl_densidade)

	var l3 := _opcao(b, "raio", UI.ACENTO, "Limite de FPS",
		"Trava a taxa de quadros. Útil em notebook: menos calor, mesma torre.")
	l3["direita"].add_child(_menu("limite_fps", ["Sem limite", "30", "60", "120", "144"], [0, 30, 60, 120, 144],
		"0 = sem limite (usa o V-Sync do sistema)."))

	var l4 := _opcao(b, "stats", UI.ACENTO, "Mostrar FPS",
		"Exibe quadros por segundo e a contagem de inimigos vivos no canto do HUD. Atalho: %s." % _tecla("debug_toggle"))
	l4["direita"].add_child(_check("mostrar_fps", "Contador de desempenho no HUD."))

	var b2 := _bloco("fogo", UI.LARANJA, "Impacto",
		"O quanto o jogo reage quando algo grande morre.")

	var l5 := _opcao(b2, "fogo", UI.LARANJA, "Tremor de tela",
		"Intensidade do chacoalhar em explosões, chefes e golpes críticos. Em 0% a câmera fica imóvel.")
	l5["direita"].add_child(_slider("tremor", 0.0, 2.0, 0.05, false, 62,
		func(x: float) -> String: return "%d%%" % int(round(x * 100.0)),
		"Movimento reduzido, na aba Acessibilidade, zera isto de vez."))

	var l6 := _opcao(b2, "raio", UI.LARANJA, "Flashes",
		"Clarões de tela cheia em chefes, purgas e mortes. Desligue se incomodar os olhos.")
	l6["direita"].add_child(_check("flashes", "Clarões e vinhetas de perigo."))

	var l7 := _opcao(b2, "espada", UI.LARANJA, "Números de dano",
		"Os números que sobem dos inimigos. Em ondas cheias, filtrar por críticos deixa a tela legível.")
	l7["direita"].add_child(_menu("numeros_dano", ["Todos", "Só críticos", "Nenhum"], [0, 1, 2],
		"Aplica na hora, sem reiniciar a onda."))

	var b3 := _bloco("engrenagem", UI.ACENTO2, "Janela", "Onde o jogo mora.")

	var l8 := _opcao(b3, "nova", UI.ACENTO2, "Tela cheia",
		"Ocupa o monitor inteiro. Atalho: %s." % _tecla("tela_cheia"))
	l8["direita"].add_child(_check("tela_cheia", "Alterna entre janela e tela cheia."))

	var l9 := _opcao(b3, "mais", UI.ACENTO2, "Escala da interface",
		"Aumenta ou reduz todo o jogo proporcionalmente. Acima de 115% os painéis grandes ficam apertados em 1280×720.")
	l9["direita"].add_child(_slider("escala_ui", 0.85, 1.25, 0.05, false, 62,
		func(x: float) -> String: return "%d%%" % int(round(x * 100.0)),
		"Vale na hora, para a interface e para o campo de batalha."))

# ====================================================== aba: ACESSIBILIDADE

func _aba_acessibilidade() -> void:
	var b := _bloco("coracao", UI.ROSA, "Conforto",
		"Nada aqui altera a dificuldade — só como o jogo chega até você.")

	var l := _opcao(b, "coracao", UI.ROSA, "Movimento reduzido",
		"Zera o tremor de tela e corta as partículas para 40% do valor escolhido, por cima da qualidade. Os efeitos continuam existindo, só param de sacudir.")
	l["direita"].add_child(_check("movimento_reduzido",
		"Anula o tremor e reduz partículas — recomendado para enjoo de movimento."))

	var l2 := _opcao(b, "orbe", UI.ROSA, "Modo daltônico",
		"Redistribui os canais de cor da tela inteira para separar tons que se confundem. Elementos, raridades e barras de vida ficam distinguíveis.")
	l2["direita"].add_child(_menu("daltonismo",
		["Nenhum", "Protanopia", "Deuteranopia", "Tritanopia"], [0, 1, 2, 3],
		"Protanopia e deuteranopia: vermelho/verde. Tritanopia: azul/amarelo."))

	var l3 := _opcao(b, "escudo", UI.ROSA, "Alto contraste",
		"Aumenta o contraste e a saturação da imagem final. O fundo escuro afunda, o que importa salta.")
	l3["direita"].add_child(_check("alto_contraste",
		"Separa melhor inimigo, projétil e cenário."))

	var l4 := _opcao(b, "livro", UI.ROSA, "Fonte grande",
		"Amplia todo o texto em 12% junto com a interface. Combina com a escala da UI na aba Gráficos, então não exagere nas duas.")
	l4["direita"].add_child(_check("fonte_grande",
		"Texto 12% maior em todo o jogo."))

	var l5 := _opcao(b, "raio", UI.ROSA, "Vibração",
		"Vibra o controle (ou o aparelho, no celular) em impactos fortes e na morte da torre. Sem efeito em teclado e mouse.")
	l5["direita"].add_child(_check("vibracao",
		"Retorno tátil em impactos — só em dispositivos que suportam."))

	var nota := UI.painel(UI.PAINEL.darkened(0.25), 10)
	var nv := UI.vbox(3)
	nota.add_child(nv)
	nv.add_child(UI.rotulo("Sobre o filtro de cor", 13, UI.ACENTO))
	var texto := UI.rotulo("O modo daltônico e o alto contraste são aplicados como uma camada sobre a imagem final, inclusive sobre este painel. Se algo parecer estranho, é porque está funcionando — volte para \"Nenhum\" para comparar.", 12, UI.TEXTO2)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nv.add_child(texto)
	conteudo.add_child(nota)

# ================================================================ aba: SAVE

func _aba_save() -> void:
	var b := _bloco("salvar", UI.VERDE, "Este save",
		"Um arquivo JSON em user://. Há sempre um backup da gravação anterior ao lado.")

	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 18)
	grade.add_theme_constant_override("v_separation", 4)
	lbl_tamanho = _info(grade, "Tamanho")
	lbl_data = _info(grade, "Último salvamento")
	lbl_proximo = _info(grade, "Próximo autosave")
	_info(grade, "Formato").text = "versão %d" % SaveSys.VERSAO
	b["corpo"].add_child(grade)

	var acoes := UI.hbox(8)
	var b_salvar := UI.botao("Salvar agora", _salvar_agora,
		"Grava o progresso imediatamente. Atalho: %s." % _tecla("salvar_agora"))
	b_salvar.custom_minimum_size = Vector2(150, 40)
	acoes.add_child(b_salvar)

	var b_exp := UI.botao("Exportar", _exportar,
		"Gera um código de texto com todo o seu progresso — cole num arquivo e guarde.")
	b_exp.custom_minimum_size = Vector2(150, 40)
	acoes.add_child(b_exp)

	var b_imp := UI.botao("Importar", func(): _mostrar_importar(true),
		"Cola um código de save e substitui o progresso atual.")
	b_imp.custom_minimum_size = Vector2(150, 40)
	acoes.add_child(b_imp)

	acoes.add_child(UI.espacador())

	btn_apagar = UI.botao("Apagar tudo", _apagar_passo,
		"Destrói o save e recomeça do zero. Duas confirmações — e você vai precisar delas.")
	btn_apagar.custom_minimum_size = Vector2(150, 40)
	btn_apagar.add_theme_color_override("font_color", UI.VERMELHO)
	acoes.add_child(btn_apagar)
	b["corpo"].add_child(acoes)

	# ---- exportar ----
	caixa_exportar = UI.painel(UI.PAINEL.darkened(0.25), 10)
	caixa_exportar.visible = false
	var ve := UI.vbox(6)
	caixa_exportar.add_child(ve)
	ve.add_child(UI.rotulo("Código do save — selecione tudo e guarde em lugar seguro.", 12, UI.TEXTO2))
	te_exportar = _texto_area(96, false)
	ve.add_child(te_exportar)
	var he := UI.hbox(8)
	var b_copiar := UI.botao("Copiar", func():
		DisplayServer.clipboard_set(te_exportar.text)
		UI.pulsar(caixa_exportar, UI.VERDE)
		Bus.toast("Código copiado para a área de transferência", "bom"), "Copia o código inteiro.")
	b_copiar.custom_minimum_size = Vector2(120, 34)
	he.add_child(b_copiar)
	var b_sel := UI.botao("Selecionar tudo", func():
		te_exportar.grab_focus()
		te_exportar.select_all(), "Marca o texto para copiar à mão (Ctrl+C).")
	b_sel.custom_minimum_size = Vector2(140, 34)
	he.add_child(b_sel)
	he.add_child(UI.espacador())
	var b_fec := UI.botao("Ocultar", func(): caixa_exportar.visible = false)
	b_fec.custom_minimum_size = Vector2(100, 34)
	he.add_child(b_fec)
	ve.add_child(he)
	b["corpo"].add_child(caixa_exportar)

	# ---- importar ----
	caixa_importar = UI.painel(UI.PAINEL.darkened(0.25), 10)
	caixa_importar.visible = false
	var vi := UI.vbox(6)
	caixa_importar.add_child(vi)
	vi.add_child(UI.rotulo("Cole aqui um código começando com TORRE1|. Isto SUBSTITUI o progresso atual.", 12, UI.LARANJA))
	te_importar = _texto_area(96, true)
	te_importar.placeholder_text = "TORRE1|..."
	vi.add_child(te_importar)
	lbl_erro = UI.rotulo("", 12, UI.VERMELHO)
	lbl_erro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vi.add_child(lbl_erro)
	var hi := UI.hbox(8)
	var b_ok := UI.botao("Importar e substituir", _importar,
		"Valida a assinatura e o checksum antes de aplicar.")
	b_ok.custom_minimum_size = Vector2(190, 34)
	hi.add_child(b_ok)
	var b_colar := UI.botao("Colar", func():
		te_importar.text = DisplayServer.clipboard_get()
		lbl_erro.text = "", "Cola o que estiver na área de transferência.")
	b_colar.custom_minimum_size = Vector2(100, 34)
	hi.add_child(b_colar)
	hi.add_child(UI.espacador())
	var b_can := UI.botao("Cancelar", func(): _mostrar_importar(false))
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
	va.add_child(UI.rotulo("Isto apaga o save e o backup. Você perde, para sempre:", 14, UI.VERMELHO))
	for linha_perda in _lista_perdas():
		va.add_child(UI.rotulo("·  " + str(linha_perda), 12, UI.TEXTO2))
	va.add_child(UI.rotulo("As configurações desta janela NÃO são apagadas.", 12, UI.TEXTO3))
	var ha := UI.hbox(8)
	var b_backup := UI.botao("Exportar antes", _exportar, "Gera o código de backup agora — é a última chance.")
	b_backup.custom_minimum_size = Vector2(150, 34)
	ha.add_child(b_backup)
	ha.add_child(UI.espacador())
	var b_cancelar := UI.botao("Cancelar", func(): _apagar_cancelar())
	b_cancelar.custom_minimum_size = Vector2(120, 34)
	ha.add_child(b_cancelar)
	va.add_child(ha)
	b["corpo"].add_child(caixa_apagar)

	# ---- atalhos ----
	var b2 := _bloco("engrenagem", UI.ACENTO, "Atalhos de teclado",
		"Tudo que dá para fazer sem tirar a mão do teclado.")
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 5)
	for item in ATALHOS:
		var par: Array = item
		_par_atalho(g, _tecla(str(par[0])), str(par[1]))
	_par_atalho(g, "1 – 0", "Usar as habilidades equipadas nos slots")
	_par_atalho(g, "Clique", "Fora da janela fecha o painel aberto")
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
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar("torre", UI.ACENTO, 46)
	var vt := UI.vbox(2)
	h.add_child(vt)
	var t := UI.titulo(NOME_JOGO, 30)
	vt.add_child(t)
	vt.add_child(UI.rotulo("Uma torre. Ondas infinitas. Três camadas de prestígio.", 14, UI.TEXTO2))
	v.add_child(h)
	v.add_child(UI.separador())
	var p := UI.rotulo("Um idle de tower defense feito inteiramente em código: nenhuma imagem, nenhuma cena montada à mão, nenhum emoji. Cada ícone é geometria desenhada em tempo real e cada número gigante mora em log10, porque em algum momento o ouro passa de 1e300 e o ponto flutuante desiste antes de você.", 13, UI.TEXTO2)
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(p)
	conteudo.add_child(capa)

	var b := _bloco("livro", UI.ACENTO, "Versão", "Para quando algo quebrar e alguém perguntar qual build era.")
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 4)
	_info(g, "Jogo").text = "v" + VERSAO_JOGO
	_info(g, "Formato do save").text = "versão %d" % SaveSys.VERSAO
	var vi: Dictionary = Engine.get_version_info()
	_info(g, "Motor").text = "Godot %s" % str(vi.get("string", "4.4"))
	_info(g, "Plataforma").text = OS.get_name()
	b["corpo"].add_child(g)

	var b2 := _bloco("trofeu", UI.OURO, "Sua torre", "O que este save já viveu.")
	var g2 := GridContainer.new()
	g2.columns = 4
	g2.add_theme_constant_override("h_separation", 18)
	g2.add_theme_constant_override("v_separation", 4)
	lbl_tempo_total = _info(g2, "Tempo total")
	_info(g2, "Onda máxima").text = Fmt.inteiro(int(jogo.s["onda_maxima_global"]))
	_info(g2, "Ascensões").text = Fmt.inteiro(int(jogo.s["prestigio"]["ascensoes"]))
	_info(g2, "Torre erguida em").text = _data_br(int(jogo.s["criado_em"]))
	b2["corpo"].add_child(g2)

	var b3 := _bloco("carta", UI.ACENTO2, "Créditos", "Poucos nomes, muitas linhas.")
	for par in [
		["Projeto, código e balanceamento", "Joab Costa"],
		["Motor", "Godot Engine 4.4 — MIT"],
		["Arte", "Vetorial, gerada em código (scripts/ui/icone.gd)"],
		["Áudio", "Sintetizado em tempo de execução"],
		["Agradecimentos", "A quem testou até a onda 500 e reclamou do tremor de tela"],
	]:
		var linha_par: Array = par
		var hh := UI.hbox(10)
		var a := UI.rotulo(str(linha_par[0]), 13, UI.TEXTO3)
		a.custom_minimum_size.x = 250
		hh.add_child(a)
		hh.add_child(UI.rotulo(str(linha_par[1]), 13, UI.TEXTO))
		b3["corpo"].add_child(hh)

	var rodape := UI.rotulo("A torre é eterna. Você, não — mas o save fica.", 12, UI.TEXTO3)
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(rodape)

# ============================================================ ações do save

func _salvar_agora() -> void:
	if jogo == null:
		return
	if jogo.salvar():
		Bus.toast("Jogo salvo", "bom")
		if lbl_tamanho != null:
			UI.pulsar(lbl_tamanho, UI.VERDE)
	else:
		Bus.toast(SaveSys.ultimo_erro if SaveSys.ultimo_erro != "" else "Falha ao salvar", "ruim")
	atualizar()

func _exportar() -> void:
	if jogo == null or te_exportar == null:
		return
	te_exportar.text = str(jogo.exportar())
	caixa_exportar.visible = true
	UI.pulsar(caixa_exportar, UI.ACENTO)
	Bus.toast("Código gerado — copie e guarde", "info")
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
		lbl_erro.text = "Cole um código antes de importar."
		return
	SaveSys.ultimo_erro = ""
	if jogo.importar(texto):
		lbl_erro.text = ""
		caixa_importar.visible = false
		te_importar.text = ""
		Bus.toast("Save importado", "epico")
		jogo.salvar()
		_reconstruir()
	else:
		lbl_erro.text = SaveSys.ultimo_erro if SaveSys.ultimo_erro != "" else "Não consegui ler esse código."
		UI.pulsar(caixa_importar, UI.VERMELHO)

func _apagar_passo() -> void:
	if btn_apagar == null:
		return
	passo_apagar += 1
	match passo_apagar:
		1:
			caixa_apagar.visible = true
			btn_apagar.text = "Sim, apagar"
			btn_apagar.tooltip_text = "Primeira confirmação. Ainda dá para cancelar."
			UI.pulsar(caixa_apagar, UI.VERMELHO)
		2:
			btn_apagar.text = "CONFIRMAR"
			btn_apagar.tooltip_text = "Segunda e última confirmação. Não há desfazer."
			UI.saltar(btn_apagar, 1.1)
		_:
			jogo.apagar_tudo()
			jogo.salvar()
			Bus.toast("Tudo apagado. A torre recomeça do pó.", "ruim")
			_apagar_cancelar()
			_reconstruir()

func _apagar_cancelar() -> void:
	passo_apagar = 0
	if caixa_apagar != null:
		caixa_apagar.visible = false
	if btn_apagar != null:
		btn_apagar.text = "Apagar tudo"
		btn_apagar.tooltip_text = "Destrói o save e recomeça do zero. Duas confirmações."

func _lista_perdas() -> Array:
	var out: Array = []
	if jogo == null:
		return out
	var s: Dictionary = jogo.s
	var pres: Dictionary = s["prestigio"]
	var cartas: Dictionary = s["cartas"]
	var inv: Array = cartas["inventario"]
	var conq: Dictionary = s["conquistas"]
	out.append("Onda máxima %s (melhor de todas: %s)" % [Fmt.inteiro(int(s["onda_maxima"])), Fmt.inteiro(int(s["onda_maxima_global"]))])
	out.append("Nível %s e %s pontos de talento" % [Fmt.inteiro(int(s["nivel"])), Fmt.inteiro(int(s["pontos_talento"]) + int(s["pontos_talento_gastos"]))])
	out.append("%s ascensões, %s singularidades, %s transcendências" % [
		Fmt.inteiro(int(pres["ascensoes"])), Fmt.inteiro(int(pres["singularidades"])), Fmt.inteiro(int(pres["transcendencias"]))])
	out.append("As três árvores permanentes (fragmentos, núcleos e éter)")
	out.append("%s cartas no inventário e %s conquistas desbloqueadas" % [Fmt.inteiro(inv.size()), Fmt.inteiro(conq.size())])
	out.append("Todo o ouro, gemas e moedas de prestígio acumulados")
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
			Bus.toast("Idioma alterado", "info")
		"tela_cheia":
			await get_tree().process_frame
			_ajustar_janela()

func _escolher_notacao(idx: int) -> void:
	_mudar("notacao", idx)
	if menu_notacao != null:
		menu_notacao.select(idx)
	atualizar()

func _restaurar() -> void:
	passo_restaurar += 1
	if passo_restaurar < 2:
		btn_restaurar.text = "Confirmar padrões"
		btn_restaurar.add_theme_color_override("font_color", UI.LARANJA)
		return
	Cfg.restaurar_padrao()
	_aplicar_escala()
	_aplicar_filtro()
	Bus.toast("Configurações de fábrica restauradas", "info")
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
const SHADER_FILTRO := """
shader_type canvas_item;
uniform sampler2D tela : hint_screen_texture, repeat_disable, filter_nearest;
uniform int modo = 0;
uniform float contraste = 0.0;

vec3 lms_de(vec3 c) {
	return vec3(
		17.8824 * c.r + 43.5161 * c.g + 4.11935 * c.b,
		3.45565 * c.r + 27.1554 * c.g + 3.86714 * c.b,
		0.0299566 * c.r + 0.184309 * c.g + 1.46709 * c.b);
}

vec3 rgb_de(vec3 l) {
	return vec3(
		0.0809444479 * l.x - 0.130504409 * l.y + 0.116721066 * l.z,
		-0.0102485335 * l.x + 0.0540193266 * l.y - 0.113614708 * l.z,
		-0.000365296938 * l.x - 0.00412161469 * l.y + 0.693511405 * l.z);
}

void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;
	if (modo > 0) {
		vec3 l = lms_de(c);
		vec3 s = l;
		if (modo == 1) { s.x = 2.02344 * l.y - 2.52581 * l.z; }
		else if (modo == 2) { s.y = 0.494207 * l.x + 1.24827 * l.z; }
		else { s.z = -0.395913 * l.x + 0.801109 * l.y; }
		vec3 sim = rgb_de(s);
		vec3 err = c - sim;
		vec3 desvio = vec3(
			0.0,
			0.7 * err.r + err.g,
			0.7 * err.r + err.b);
		c = clamp(c + desvio, vec3(0.0), vec3(1.0));
	}
	if (contraste > 0.0) {
		c = clamp((c - 0.5) * (1.0 + 0.34 * contraste) + 0.5, vec3(0.0), vec3(1.0));
		float cinza = dot(c, vec3(0.299, 0.587, 0.114));
		c = clamp(mix(vec3(cinza), c, 1.0 + 0.2 * contraste), vec3(0.0), vec3(1.0));
	}
	COLOR = vec4(c, 1.0);
}
"""

func _aplicar_filtro() -> void:
	var raiz := get_tree().root
	if raiz == null:
		return
	var modo := int(Cfg.get_v("daltonismo", 0))
	var contraste := 1.0 if bool(Cfg.get_v("alto_contraste", false)) else 0.0
	var camada := raiz.get_node_or_null("FiltroAcessibilidade")
	if modo <= 0 and contraste <= 0.0:
		if camada != null:
			camada.queue_free()
		return
	if camada == null:
		camada = CanvasLayer.new()
		camada.name = "FiltroAcessibilidade"
		camada.layer = 120
		var rc := ColorRect.new()
		rc.name = "Filtro"
		rc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = SHADER_FILTRO
		var mat := ShaderMaterial.new()
		mat.shader = sh
		rc.material = mat
		camada.add_child(rc)
		raiz.add_child(camada)
	var alvo := camada.get_node_or_null("Filtro")
	if alvo != null and alvo.material is ShaderMaterial:
		var m: ShaderMaterial = alvo.material
		m.set_shader_parameter("modo", modo)
		m.set_shader_parameter("contraste", contraste)

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
		previa_titulo.text = "Prévia do mesmo número (%s) — clique para escolher" % _fmt_em(2, amostra)
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
	var extra := "  ·  movimento reduzido está cortando isto em 60%" if bool(Cfg.get_v("movimento_reduzido", false)) else ""
	lbl_densidade.text = "Resultado final: %s das partículas base%s" % [Fmt.pct(d, 0), extra]

func _atualizar_save() -> void:
	if lbl_tamanho == null:
		return
	var kb := SaveSys.tamanho_kb()
	lbl_tamanho.text = "sem arquivo ainda" if kb <= 0.0 else "%s KB" % Fmt.num(kb, 1)
	var ts := int(jogo.s["salvo_em"])
	if ts <= 0:
		lbl_data.text = "nunca"
	else:
		var agora := int(Time.get_unix_time_from_system())
		lbl_data.text = "%s  (há %s)" % [_data_br(ts), Ux.tempo_curto(float(maxi(0, agora - ts)))]
	var intervalo_auto := float(Cfg.get_v("autosave_seg", 20.0))
	var falta := maxf(0.0, intervalo_auto - float(jogo.tempo_autosave))
	lbl_proximo.text = "em %s (a cada %d s)" % [Ux.tempo_curto(falta), int(intervalo_auto)]

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
	var ic := Control.new()
	ic.set_script(load("res://scripts/ui/icone_control.gd"))
	h.add_child(ic)
	ic.configurar(icone, cor, 20)
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
	cb.focus_mode = Control.FOCUS_NONE
	cb.tooltip_text = dica
	cb.button_pressed = bool(Cfg.get_v(chave, false))
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb.toggled.connect(func(v: bool): _mudar(chave, v))
	return cb

func _menu(chave: String, itens: Array, valores: Array, dica: String) -> OptionButton:
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
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
	sl.focus_mode = Control.FOCUS_NONE
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
		out.append(str(par[0]))
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
	return "%02d/%02d/%04d às %02d:%02d" % [int(d["day"]), int(d["month"]), int(d["year"]), int(d["hour"]), int(d["minute"])]

func _tecla(acao: String) -> String:
	if not InputMap.has_action(acao):
		return "—"
	for e in InputMap.action_get_events(acao):
		if e is InputEventKey:
			var k: InputEventKey = e
			var codigo := k.physical_keycode if k.physical_keycode != 0 else k.keycode
			var nome := OS.get_keycode_string(codigo)
			return str(TECLA_PT.get(nome, nome))
	return "—"
