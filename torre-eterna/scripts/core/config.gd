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
}

var v: Dictionary = PADRAO.duplicate(true)

func _ready() -> void:
	var salvo := SaveSys.carregar_config()
	for k in PADRAO.keys():
		if salvo.has(k):
			v[k] = salvo[k]
	aplicar()

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
	Engine.max_fps = int(v["limite_fps"])

func _vol_bus(nome: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(nome)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(0.0001, linear)))

## Multiplicador de partículas conforme qualidade + preferência.
func densidade_particulas() -> float:
	var q: float = [0.35, 0.65, 1.0, 1.45][clampi(int(v["qualidade"]), 0, 3)]
	return q * float(v["particulas"]) * (0.4 if bool(v["movimento_reduzido"]) else 1.0)

func forca_tremor() -> float:
	return 0.0 if bool(v["movimento_reduzido"]) else float(v["tremor"])

func ingles() -> bool:
	return v["idioma"] == "en"
