extends SceneTree

## Configura o projeto pela própria engine (autoloads, input map, janela, áudio).
## Rode:  godot --headless --path . -s res://tools/bootstrap.gd
## Motivo: a regra do kit proíbe editar project.godot como texto.

const AUTOLOADS := [
	["Bus", "res://scripts/core/event_bus.gd"],
	["Cfg", "res://scripts/core/config.gd"],
	["SaveSys", "res://scripts/core/save_system.gd"],
	["Audio", "res://scripts/audio/audio_engine.gd"],
	["Jogo", "res://scripts/sim/game.gd"],
]

const ACOES := {
	"ui_pausa": [KEY_ESCAPE],
	"hab_1": [KEY_1], "hab_2": [KEY_2], "hab_3": [KEY_3], "hab_4": [KEY_4], "hab_5": [KEY_5],
	"hab_6": [KEY_6], "hab_7": [KEY_7], "hab_8": [KEY_8], "hab_9": [KEY_9], "hab_0": [KEY_0],
	"painel_upgrades": [KEY_Q],
	"painel_talentos": [KEY_W],
	"painel_cartas": [KEY_E],
	"painel_prestigio": [KEY_R],
	"painel_conquistas": [KEY_T],
	"painel_config": [KEY_O],
	"comprar_max": [KEY_SHIFT],
	"turbo": [KEY_SPACE],
	"alternar_auto": [KEY_A],
	"salvar_agora": [KEY_F5],
	"tela_cheia": [KEY_F11],
	"debug_toggle": [KEY_F3],
}

func _initialize() -> void:
	var mudou := 0

	for par in AUTOLOADS:
		var chave: String = "autoload/" + str(par[0])
		var valor: String = "*" + str(par[1])
		if ProjectSettings.get_setting(chave, "") != valor:
			ProjectSettings.set_setting(chave, valor)
			mudou += 1

	for nome in ACOES.keys():
		var chave: String = "input/" + str(nome)
		var eventos: Array = []
		for kc in ACOES[nome]:
			var ev := InputEventKey.new()
			ev.physical_keycode = kc
			eventos.append(ev)
		ProjectSettings.set_setting(chave, {"deadzone": 0.5, "events": eventos})
		mudou += 1

	var cfg := {
		"application/config/name": "Torre Eterna",
		"application/config/description": "Idle/incremental de tower defense: uma torre, ondas infinitas e tres camadas de prestigio.",
		"application/run/main_scene": "res://scenes/main.tscn",
		"application/config/icon": "res://icon.svg",
		"display/window/size/viewport_width": 1280,
		"display/window/size/viewport_height": 720,
		"display/window/size/window_width_override": 1280,
		"display/window/size/window_height_override": 720,
		"display/window/stretch/mode": "canvas_items",
		"display/window/stretch/aspect": "expand",
		"display/window/handheld/orientation": 0,
		"rendering/renderer/rendering_method": "gl_compatibility",
		"rendering/renderer/rendering_method.mobile": "gl_compatibility",
		"rendering/2d/snap/snap_2d_transforms_to_pixel": false,
		"rendering/anti_aliasing/quality/msaa_2d": 2,
		"rendering/environment/defaults/default_clear_color": Color(0.043, 0.055, 0.098),
		"audio/buses/default_bus_layout": "res://audio_bus_layout.tres",
		"gui/theme/default_font_multichannel_signed_distance_field": true,
		"application/boot_splash/show_image": false,
		"application/boot_splash/bg_color": Color(0.043, 0.055, 0.098),
	}
	for k in cfg.keys():
		if ProjectSettings.get_setting(k, null) != cfg[k]:
			ProjectSettings.set_setting(k, cfg[k])
			mudou += 1

	# Barramentos de áudio: Master > SFX / Musica
	_criar_bus_layout()

	var err := ProjectSettings.save()
	print("===BOOTSTRAP=== alteracoes=%d salvo=%s" % [mudou, "ok" if err == OK else str(err)])
	quit(0 if err == OK else 1)

func _criar_bus_layout() -> void:
	var layout := AudioBusLayout.new()
	# índice 0 já é Master
	layout.set("bus_count", 3)
	layout.set("bus/1/name", "SFX")
	layout.set("bus/1/send", "Master")
	layout.set("bus/1/volume_db", 0.0)
	layout.set("bus/2/name", "Musica")
	layout.set("bus/2/send", "Master")
	layout.set("bus/2/volume_db", -4.0)
	var err := ResourceSaver.save(layout, "res://audio_bus_layout.tres")
	if err != OK:
		push_warning("[bootstrap] nao consegui salvar o layout de audio: %d" % err)
