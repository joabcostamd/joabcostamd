extends Node

## Cfg (autoload) — configurações do jogador. Persistem fora do save do jogo,
## então sobrevivem a um reset total.

const PADRAO := {
	"idioma": "pt",
	"notacao": 0,              # Fmt.Notacao
	"casas": 2,
	"vol_master": 0.75,
	"vol_sfx": 0.85,
	"vol_musica": 0.45,
	"mudo": false,
	"qualidade": 2,            # 0 baixa · 1 média · 2 alta · 3 ultra
	"particulas": 1.0,
	"tremor": 1.0,
	"flashes": true,
	"numeros_dano": 0,         # 0 todos · 1 só críticos · 2 nenhum
	"movimento_reduzido": false,
	"daltonismo": 0,           # 0 nenhum · 1 protanopia · 2 deuteranopia · 3 tritanopia
	"alto_contraste": false,
	"fonte_grande": false,
	"mostrar_fps": false,
	"autosave_seg": 20.0,
	"confirmar_prestigio": true,
	"vibracao": true,
	"dicas": true,
	"escala_ui": 1.0,
	"tela_cheia": false,
	"limite_fps": 0,
	# Minutos parados ate o Modo Repouso entrar sozinho. 0 desliga.
	# Ver `scripts/core/repouso.gd`.
	"repouso_min": 5.0,
}

var v: Dictionary = PADRAO.duplicate(true)
## Espelho do estado do Modo Repouso, para que `aplicar()` nao o cancele sem
## querer. Ver `scripts/core/repouso.gd`.
var _repousando := false
var _filtro: CanvasLayer = null

func repousando() -> bool:
	return _repousando

func _ready() -> void:
	Bus.repouso_mudou.connect(func(ativo: bool): _repousando = ativo)
	var salvo := SaveSys.carregar_config()
	# PRIMEIRA execucao: abre no idioma do sistema. Depois disso quem manda e a
	# escolha salva, mesmo que o jogador tenha escolhido o mesmo que o sistema.
	# O jogo tem 1.040 chaves em ingles prontas e abria em portugues para todo
	# mundo, no mundo inteiro, sem nunca perguntar.
	if not salvo.has("idioma"):
		v["idioma"] = idioma_do_sistema()
	for k in PADRAO.keys():
		if salvo.has(k):
			v[k] = salvo[k]
	aplicar()

## Idioma que o sistema operacional pede, reduzido aos dois que o jogo fala.
##
## `headless` e ferramenta, nao jogador: os portoes medem textos em portugues e
## nao podem mudar de resposta porque a maquina do CI esta configurada em outro
## idioma. Entao sem tela o padrao continua sendo `pt`, sempre.
static func idioma_do_sistema() -> String:
	if DisplayServer.get_name() == "headless":
		return "pt"
	return "pt" if OS.get_locale().to_lower().begins_with("pt") else "en"

func get_v(chave: String, padrao = null):
	return v.get(chave, PADRAO.get(chave, padrao))

func set_v(chave: String, valor) -> void:
	if v.get(chave) == valor:
		return
	v[chave] = valor
	aplicar()
	SaveSys.salvar_config(v)
	Bus.config_mudou.emit(chave, valor)

func restaurar_padrao() -> void:
	v = PADRAO.duplicate(true)
	aplicar()
	SaveSys.salvar_config(v)
	Bus.config_mudou.emit("tudo", null)

## Aplica o que depende de sistemas globais.
func aplicar() -> void:
	Fmt.notacao = int(v["notacao"]) as Fmt.Notacao
	Fmt.casas = int(v["casas"])
	Fmt.ingles = v["idioma"] == "en"
	Txt.definir_idioma(v["idioma"] == "en")

	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, bool(v["mudo"]))
		AudioServer.set_bus_volume_db(master, linear_to_db(maxf(0.0001, float(v["vol_master"]))))
	_vol_bus("SFX", float(v["vol_sfx"]))
	_vol_bus("Musica", float(v["vol_musica"]))

	if not Engine.is_editor_hint() and DisplayServer.get_name() != "headless":
		var alvo := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(v["tela_cheia"]) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != alvo:
			DisplayServer.window_set_mode(alvo)
	# So mexe no limite quando NAO esta repousando: aplicar a configuracao no
	# meio do repouso o cancelaria em silencio, e o jogo voltaria a 60 quadros
	# com a pessoa longe da maquina.
	if not repousando():
		Engine.max_fps = int(v["limite_fps"])
	_aplicar_escala()
	_aplicar_filtro()

## Escala global (interface e campo juntos) aplicada já na abertura — antes
## isso só acontecia se o jogador reabrisse o painel de configurações.
func _aplicar_escala() -> void:
	if not is_inside_tree():
		return
	var e := float(v["escala_ui"])
	if bool(v["fonte_grande"]):
		e *= 1.12
	var jan := get_window()
	if jan == null:
		return
	# CANVAS_ITEMS + EXPAND é o modo que faz a escala funcionar de verdade: a
	# interface é desenhada num espaço LÓGICO menor e só depois ampliada, então
	# âncoras e centralização continuam certas e `get_viewport_rect()` devolve o
	# tamanho lógico. No modo padrão (DISABLED) a ampliação acontece em volta do
	# canto superior esquerdo: com escala 1,4 os painéis escorregavam para baixo
	# e para a direita e o botão de fechar saía da tela.
	jan.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	jan.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	jan.content_scale_factor = clampf(e, 0.7, 1.6)

## O filtro de acessibilidade é um CanvasLayer global criado sob demanda —
## fica acima de tudo, inclusive dos painéis, para a opção valer na hora.
func _aplicar_filtro() -> void:
	var modo := int(v["daltonismo"])
	var contraste := 0.35 if bool(v["alto_contraste"]) else 0.0
	if modo == 0 and contraste <= 0.0:
		if _filtro != null:
			_filtro.configurar(0, 0.0)
		return
	if not is_inside_tree():
		return
	if _filtro == null or not is_instance_valid(_filtro):
		if DisplayServer.get_name() == "headless":
			return
		_filtro = CanvasLayer.new()
		_filtro.name = "FiltroAcessibilidade"
		_filtro.set_script(load("res://scripts/render/filtro_acessibilidade.gd"))
		add_child(_filtro)
	_filtro.configurar(modo, contraste)

func _vol_bus(nome: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(nome)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(0.0001, linear)))

## Multiplicador de partículas conforme qualidade + preferência.
func densidade_particulas() -> float:
	# NO REPOUSO, PARTICULA E DESPERDICIO PURO.
	#
	# A tela desenha 6 quadros por segundo: uma faisca que vive 0,3 s aparece em
	# um quadro e meio, ou seja, ninguem a ve — mas o custo de criar, mover e
	# desenhar cada uma continua sendo pago. Cortar a densidade a um decimo tira
	# trabalho que nao produz imagem nenhuma. Nao vai a zero porque a explosao
	# de um chefe ainda tem que aparecer para quem estiver de olho na tela.
	if _repousando:
		return 0.1
	var q: float = [0.35, 0.65, 1.0, 1.45][clampi(int(v["qualidade"]), 0, 3)]
	return q * float(v["particulas"]) * (0.4 if bool(v["movimento_reduzido"]) else 1.0)

func forca_tremor() -> float:
	return 0.0 if bool(v["movimento_reduzido"]) else float(v["tremor"])

func ingles() -> bool:
	return v["idioma"] == "en"
