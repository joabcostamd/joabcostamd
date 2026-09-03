extends SceneTree

# =============================================================================
#  agent_verify.gd  —  Motor de verificacao para projetos Godot 4.x
#  As regras que este portao faz cumprir vivem em CLAUDE.md (raiz de trabalho),
#  plantado por instalar.ps1. Este arquivo e so o motor.
#
#  USO (quem digita isto e a IA, nao voce):
#    godot --headless --path . -s res://agent_verify.gd
#    godot --headless --path . -s res://agent_verify.gd -- full
#    godot --headless --path . -s res://agent_verify.gd -- doctor
#
#  O QUE FAZ:
#    1. Na primeira execucao instala-se sozinho (hook de git, settings, estado).
#    2. Reimporta o projeto se detectar arquivos novos sem .uid.
#    3. Carrega todo .gd  -> pega script que nao compila.
#    4. Carrega toda .tscn -> pega cena quebrada (script sumido, uid morto).
#    5. Carrega todo .tres -> pega recurso quebrado.
#    5b. Carrega todo .glb/.gltf/.fbx -> pega modelo 3D quebrado ou nao importado.
#    6. Audita strings escritas a mao: caminhos res://, acoes de input, grupos.
#    7. Compara com a foto anterior (baseline) e alarma SO no que mudou.
#
#  CONTRATO DE SAIDA:
#    Nunca confie no exit code do Godot. Confie no bloco delimitado:
#      ===AGENT-VERIFY=== { ... json ... } ===END===
#    Se o bloco nao aparecer, houve falha de infraestrutura (crash), nao de teste.
# =============================================================================

const KIT_VERSION := "1.5.2"

# Sondas de deteccao. O kit NAO assume qual metodo funciona nesta build:
# ele mede, com controle positivo (quebrado tem de falhar) e negativo
# (valido tem de passar). Sem os dois, o metodo e cego ou paranoico.
const PROBE_BROKEN_SRC := "extends Node\nfunc quebrado( -> void:\n\tpass\n"
const PROBE_OK_SRC := "extends Node\nfunc valido() -> void:\n\tpass\n"
const PROBE_BROKEN_PATH := "user://__agent_probe_broken.gd"
const PROBE_OK_PATH := "user://__agent_probe_ok.gd"

const STATE_PATH := "res://AGENT-STATE.md"
const CONCEITO_PATH := "res://CONCEITO.md"
const SELF_PATH := "res://agent_verify.gd"

const MARK_BASE_START := "<!-- BASELINE-JSON-START -->"
const MARK_BASE_END := "<!-- BASELINE-JSON-END -->"
const MARK_LOCAL_START := "<!-- LOCAL -->"
const MARK_LOCAL_END := "<!-- /LOCAL -->"

const MAX_LIST := 200      # teto de itens listados no inventario
const MAX_ERRORS_SHOWN := 5

var _mode := "check"
var _verbose := false
var _include_addons := false
var _first_run := false
var _dirs_ignorados: Array[String] = []   # prefixos res:// que o .gitignore declara saida

var _state: Dictionary = {}
var _inventory: Dictionary = {}
var _failures: Dictionary = {}   # "path::stage" -> motivo
var _counts: Dictionary = {}
var _notes: Array[String] = []


# =============================================================================
#  ENTRADA
# =============================================================================

func _initialize() -> void:
	var args := Array(OS.get_cmdline_user_args())
	if args.size() > 0:
		_mode = String(args[0]).strip_edges().to_lower()
	if _mode == "doctor":
		_verbose = true
		_include_addons = true

	var code := 1
	# Sem try/catch em GDScript: se algo estourar, o bloco final nao sai
	# e o hook trata como falha de infraestrutura. Comportamento desejado.
	code = _run()
	quit(code)


func _run() -> int:
	_carrega_dirs_ignorados()
	var t0 := Time.get_ticks_msec()

	_state = _read_state()
	var first_run: bool = not _state.has("meta")
	_first_run = first_run

	# A engine mudou desde a instalacao? A sonda de deteccao foi validada NAQUELA
	# build; usar a conclusao dela em outra e confiar num teste que nunca rodou
	# aqui. Alem disso o cabecalho passava a mentir: mostrava a versao gravada na
	# instalacao, nao a que esta rodando. Medido em 31/08/2026 no
	# game-chaves-e-cadeados: cabecalho dizia 4.7.1 com a 4.7.2 em execucao.
	var engine_agora: String = Engine.get_version_info().get("string", "desconhecida")
	var engine_estado: String = String((_state.get("meta", {}) as Dictionary).get("engine", ""))
	var trocou_engine: bool = engine_estado != "" and engine_estado != engine_agora

	if first_run or _mode == "install" or _mode == "doctor" or trocou_engine:
		if trocou_engine:
			_notes.append("engine mudou de %s para %s — sonda revalidada nesta build." % [engine_estado, engine_agora])
		_bootstrap(first_run)

	# ---- portao: existe detector? ----
	var _meta: Dictionary = _state.get("meta", {})
	var _probe: Dictionary = _meta.get("probe", {})
	var metodo_script: String = String(_probe.get("metodo", ""))
	if metodo_script == "" or metodo_script == "nenhum":
		_print_header()
		print("  BLOQUEADO: nenhum metodo de deteccao de script funciona nesta build.")
		print("  detalhe: %s" % String(_probe.get("detalhe", "estado ausente — apague AGENT-STATE.md e rode -- install")))
		_emit_block("BLOQUEADO", 0, 0)
		return 2

	# ---- etapa 1: import ----
	var gd_files := _walk(["gd"])
	var import_state := _ensure_import(gd_files)
	if import_state == "reimported":
		gd_files = _walk(["gd"])   # arquivos podem ter ganho .uid

	# ---- etapa 2: scripts ----
	var n_gd := _check_scripts(gd_files)

	# ---- etapa 3: cenas ----
	var scn_files := _walk(["tscn", "scn"])
	var n_scn := _check_scenes(scn_files)

	# ---- etapa 4: recursos ----
	var res_files := _walk(["tres", "res"])
	var n_res := _check_resources_of(res_files, "recurso", "")

	# ---- etapa 4b: modelos 3D ----
	#
	# ADICIONADO NO KIT 1.5.0. Antes desta etapa o portao era CEGO a asset 3D: ele
	# carregava .gd, .tscn e .tres e mais nada. Medido em 02/09/2026 no
	# game-spell-brigade-like: `scripts/renderizar.gd` referenciava TRES arquivos .fbx
	# que nao existiam e o portao dizia PASS.
	#
	# Um .glb quebrado, nao importado, ou com o .import apontando para um .scn que
	# sumiu do `.godot/` da a mesma falha de sempre — no jogo, em runtime, no
	# meio de uma onda. Aqui ele cai antes do commit.
	var mod_files := _walk(["glb", "gltf", "fbx"])
	var n_mod := _check_resources_of(mod_files, "modelo3d", "PackedScene")

	# ---- etapa 5: inventario + auditoria de strings ----
	_inventory = _build_inventory(gd_files, scn_files)
	var n_str := _audit_strings(gd_files)

	# ---- comparacao com baseline ----
	var baseline: Dictionary = _state.get("baseline", {})
	var novas: Array[String] = []
	var corrigidas: Array[String] = []
	if not first_run:
		for k in _failures.keys():
			if not baseline.has(k):
				novas.append(k)
		for k in baseline.keys():
			if not _failures.has(k):
				corrigidas.append(k)

	_counts = {
		"scripts": n_gd,
		"cenas": n_scn,
		"recursos": n_res,
		"modelos3d": n_mod,
		"strings_auditadas": n_str,
	}

	# ---- relatorio ----
	_print_header()
	_print_line("import", import_state, 0)
	_print_stage("scripts", n_gd, "script")
	_print_stage("cenas", n_scn, "cena")
	_print_stage("recursos", n_res, "recurso")
	_print_stage("strings", n_str, "string")

	if corrigidas.size() > 0:
		print("")
		print("  corrigido desde a ultima foto: %d" % corrigidas.size())
		if _verbose:
			for k in corrigidas:
				print("    + " + k)

	if novas.size() > 0:
		print("")
		print("  NOVAS FALHAS (%d):" % novas.size())
		var shown := 0
		for k in novas:
			if shown >= MAX_ERRORS_SHOWN and not _verbose:
				print("    ... e mais %d (rode com -- doctor)" % (novas.size() - shown))
				break
			print("    ! %s" % _failures[k])
			shown += 1

	for n in _notes:
		print("  nota: " + n)

	var status := "PASS" if novas.is_empty() else "FAIL"
	print("")
	print("-".repeat(60))
	if status == "PASS":
		print("STATUS: PASS   (%d ms)" % (Time.get_ticks_msec() - t0))
	else:
		print("STATUS: FAIL   %d nova(s) falha(s)   (%d ms)" % [novas.size(), Time.get_ticks_msec() - t0])

	# ---- avanco da baseline: SO em full e SO se verde ----
	if _mode == "full" and status == "PASS":
		_state["baseline"] = _failures.duplicate(true)
		_notes.append("baseline atualizada")
	elif first_run:
		_state["baseline"] = _failures.duplicate(true)
		print("")
		print("primeira execucao: %d falha(s) pre-existente(s) registrada(s) como estado conhecido." % _failures.size())
		print("elas nao vao alarmar. so mudancas a partir de agora alarmam.")

	# doctor e DIAGNOSTICO: nao mexe no estado versionado. Ele varre addons/ e o
	# full nao, entao os dois produziam inventarios diferentes do mesmo projeto e
	# ficavam se sobrescrevendo. Medido em 31/08/2026 no game-star-colony: um
	# doctor seguido de um full trocava "Sinais declarados" de 45 para 5, deixando
	# AGENT-STATE.md sujo depois de todo commit. Arquivo gerado, versionado e
	# oscilante e conflito garantido ao trocar de maquina.
	# Excecao: primeira execucao precisa gravar, senao o kit nunca se instala.
	if _mode == "doctor" and not first_run:
		_notes.append("modo doctor: AGENT-STATE.md preservado (diagnostico nao grava estado).")
	else:
		_write_state()
	_emit_block(status, novas.size(), corrigidas.size())
	return 0 if status == "PASS" else 1


# =============================================================================
#  BOOTSTRAP / INSTALACAO
# =============================================================================

func _bootstrap(first_run: bool) -> void:
	_state["meta"] = {
		"kit_version": KIT_VERSION,
		"engine": Engine.get_version_info().get("string", "desconhecida"),
		"binario": OS.get_executable_path(),
		"instalado_em": Time.get_datetime_string_from_system(),
		"probe": _probe_detection(),
	}
	if first_run:
		print("primeira execucao — instalando o kit...")
	_install_git_hook()
	# AGENTS.md era o arquivo de regras do arranjo antigo; hoje as regras vivem
	# em CLAUDE.md, plantado na raiz de trabalho. O que falta cobrar aqui e a
	# regra 1: sem CONCEITO.md nao entra GDScript novo no projeto.
	if not FileAccess.file_exists(CONCEITO_PATH):
		_notes.append("sem CONCEITO.md na raiz — regra 1: nenhuma linha de GDScript nova ate ele existir.")


# Descobre qual metodo de deteccao de script quebrado funciona NESTA build.
# Testa tres, do mais barato ao mais caro, e exige que o metodo reprove o
# script quebrado E aprove o script valido.
#   M1 load_null  — ResourceLoader.load() devolve null
#   M2 reload     — GDScript.reload(true) devolve erro
#   M3 check_only — subprocesso com --check-only (correto, porem lento)
func _probe_detection() -> Dictionary:
	_write_text(PROBE_BROKEN_PATH, PROBE_BROKEN_SRC)
	_write_text(PROBE_OK_PATH, PROBE_OK_SRC)

	var res := {"metodo": "nenhum", "detalhe": "nenhum metodo reprovou o script quebrado"}

	var b: Variant = ResourceLoader.load(PROBE_BROKEN_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	var g: Variant = ResourceLoader.load(PROBE_OK_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

	# M1
	if b == null and g != null:
		res = {"metodo": "load_null", "detalhe": "load() devolve null em script quebrado"}
	else:
		# M2
		var reprova_quebrado := (b == null)
		var aprova_valido := false
		if b is GDScript:
			reprova_quebrado = ((b as GDScript).reload(true) != OK)
		if g is GDScript:
			aprova_valido = ((g as GDScript).reload(true) == OK)
		if reprova_quebrado and aprova_valido:
			res = {"metodo": "reload", "detalhe": "GDScript.reload(true) devolve erro em script quebrado"}
		elif reprova_quebrado and not aprova_valido:
			res = {"metodo": "nenhum", "detalhe": "reload() reprova ate script valido — paranoico, inutilizavel"}
		else:
			# M3
			if _check_only(PROBE_BROKEN_PATH) != 0 and _check_only(PROBE_OK_PATH) == 0:
				res = {"metodo": "check_only", "detalhe": "subprocesso --check-only (lento: 1 processo por script)"}

	_erase(PROBE_BROKEN_PATH)
	_erase(PROBE_OK_PATH)
	return res


# Roda o parser da engine num unico arquivo. 0 = compila.
func _check_only(path: String) -> int:
	var bin := OS.get_executable_path()
	var proj := ProjectSettings.globalize_path("res://").rstrip("/")
	var out: Array = []
	var code := OS.execute(bin, ["--headless", "--path", proj, "--check-only", "--script", path], out, true)
	if code != 0:
		return code
	var txt := "\n".join(PackedStringArray(out))
	if txt.contains("SCRIPT ERROR") or txt.contains("Parse Error") or txt.contains("Parser Error"):
		return 1
	return 0


func _write_text(path: String, txt: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(txt)
	f.close()


func _erase(path: String) -> void:
	var abs := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(abs)
	DirAccess.remove_absolute(abs + ".uid")


func _install_git_hook() -> void:
	var root := ProjectSettings.globalize_path("res://")
	var hooks_dir := root.path_join(".git").path_join("hooks")
	if not DirAccess.dir_exists_absolute(root.path_join(".git")):
		_notes.append("sem repositorio git — hook nao instalado (recomendado: git init)")
		return
	DirAccess.make_dir_recursive_absolute(hooks_dir)

	var hook_path := hooks_dir.path_join("pre-commit")
	# Git Bash nao entende "C:\\..." em [ -x ]. Sem barra normal o hook
	# falha mesmo com o binario existindo, e o portao morre em silencio.
	var godot_bin := OS.get_executable_path().replace("\\\\", "/")
	var body := ""
	body += "#!/bin/sh\n"
	body += "# instalado por agent_verify.gd (kit %s) — remova o arquivo para desativar\n" % KIT_VERSION
	body += "GODOT=\"%s\"\n" % godot_bin
	body += "PROJ=\"%s\"\n" % root.rstrip("/")
	body += "[ -n \"$GODOT_BIN\" ] && [ -x \"$GODOT_BIN\" ] && GODOT=\"$GODOT_BIN\"\n"
	body += "if [ ! -x \"$GODOT\" ]; then\n"
	body += "  echo \"[agent_verify] BLOQUEADO: binario do Godot nao encontrado. Defina GODOT_BIN.\"\n"
	body += "  echo \"  O portao NAO rodou - este commit nao foi verificado.\"\n"
	body += "  echo \"  Se for deliberado: git commit --no-verify\"\n"
	body += "  exit 1\n"
	body += "fi\n"
	body += "OUT=$(\"$GODOT\" --headless --path \"$PROJ\" -s res://agent_verify.gd -- full 2>&1)\n"
	body += "echo \"$OUT\"\n"
	body += "if echo \"$OUT\" | grep -q '\"status\": \"PASS\"'; then\n"
	body += "  exit 0\n"
	body += "fi\n"
	body += "echo \"\"\n"
	body += "echo \"[agent_verify] commit bloqueado. corrija as falhas acima ou use --no-verify.\"\n"
	body += "exit 1\n"

	var f := FileAccess.open(hook_path, FileAccess.WRITE)
	if f == null:
		_notes.append("nao consegui escrever o hook de pre-commit")
		return
	f.store_string(body)
	f.close()
	if OS.get_name() != "Windows":
		OS.execute("chmod", ["+x", hook_path])
	_notes.append("hook de pre-commit instalado")


# _patch_vscode_settings foi REMOVIDA em 31/08/2026. Ela escrevia
# .vscode/settings.json com chat.useAgentsMdFile e
# github.copilot.chat.codeGeneration.useInstructionFiles — configuracao do
# arranjo Copilot, que apontava para AGENTS.md e nao tem efeito nenhum no
# Claude Code. O kit criava arquivo nao rastreado em todo projeto para
# ligar uma integracao que nao usamos mais.
func _ensure_import(gd_files: PackedStringArray) -> String:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://.godot")):
		return _do_import("projeto nunca importado")

	var faltando := 0
	for p in gd_files:
		if not FileAccess.file_exists(p + ".uid"):
			faltando += 1
	if faltando == 0:
		return "ok"
	# NAO reimportar aqui. `--import` e all-or-nothing: reescreve o .import de
	# todo asset do projeto e suja centenas de arquivos no git, destruindo a
	# leitura do `git status`. Script sem .uid nao e fatal — ele so importa
	# quando alguma cena passa a referencia-lo por UID.
	_notes.append("%d script(s) sem .uid. Quando for conveniente, com o editor fechado: godot --headless --path . --import" % faltando)
	return "%d sem .uid (nao reimportado de proposito)" % faltando


func _do_import(motivo: String) -> String:
	var bin := OS.get_executable_path()
	var proj := ProjectSettings.globalize_path("res://").rstrip("/")
	var out: Array = []
	var code := OS.execute(bin, ["--headless", "--path", proj, "--import"], out, true)
	if code == 0:
		return "reimportado (%s)" % motivo
	_notes.append("reimportacao automatica falhou (%s). Feche o editor do Godot e rode: godot --headless --path . --import" % motivo)
	return "FALHOU"


# =============================================================================
#  ETAPAS 2-4 — CARREGAMENTO
# =============================================================================

func _check_scripts(files: PackedStringArray) -> int:
	var meta: Dictionary = _state.get("meta", {})
	var probe: Dictionary = meta.get("probe", {})
	var metodo: String = String(probe.get("metodo", "nenhum"))
	for p in files:
		if p == SELF_PATH:
			continue
		var r: Variant = ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_IGNORE)
		if r == null:
			_fail(p, "script", "script nao carrega: %s" % p)
			continue
		match metodo:
			"reload":
				if r is GDScript:
					var err: int = (r as GDScript).reload(true)
					if err != OK:
						_fail(p, "script", "script nao compila (erro %d): %s" % [err, p])
			"check_only":
				if _check_only(p) != 0:
					_fail(p, "script", "script nao compila: %s" % p)
	return files.size()


func _check_resources_of(files: PackedStringArray, rotulo: String, hint: String) -> int:
	for p in files:
		if p == SELF_PATH:
			continue
		var r: Variant = ResourceLoader.load(p, hint, ResourceLoader.CACHE_MODE_IGNORE)
		if r == null:
			_fail(p, rotulo, "%s nao carrega: %s" % [rotulo, p])
	return files.size()


func _check_scenes(files: PackedStringArray) -> int:
	for p in files:
		var ps: Variant = ResourceLoader.load(p, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
		if ps == null:
			_fail(p, "cena_load", "cena nao carrega: %s" % p)
			continue
		var packed := ps as PackedScene
		if packed == null:
			_fail(p, "cena_load", "arquivo nao e uma PackedScene valida: %s" % p)
			continue
		if not packed.can_instantiate():
			_fail(p, "cena_inst", "cena nao pode ser instanciada: %s" % p)
			continue
		# Nivel 2 so no modo completo. instantiate() NAO chama _ready(),
		# entao nao dispara efeito colateral (save, rede, audio).
		if _mode == "full" or _mode == "doctor" or _first_run:
			var inst: Node = packed.instantiate()
			if inst == null:
				_fail(p, "cena_inst", "instantiate() devolveu null: %s" % p)
			else:
				inst.free()
	return files.size()


# =============================================================================
#  ETAPA 5 — INVENTARIO
# =============================================================================

func _build_inventory(gd_files: PackedStringArray, scn_files: PackedStringArray) -> Dictionary:
	var inv := {
		"autoloads": [],
		"acoes_input": [],
		"class_names": [],
		"sinais": [],
		"grupos": [],
	}

	for prop in ProjectSettings.get_property_list():
		var n: String = prop.get("name", "")
		if n.begins_with("autoload/"):
			inv["autoloads"].append(n.substr(9))

	for a in InputMap.get_actions():
		inv["acoes_input"].append(String(a))

	for c in ProjectSettings.get_global_class_list():
		inv["class_names"].append("%s  (%s)" % [c.get("class", "?"), c.get("path", "?")])

	var re_signal := RegEx.create_from_string("^\\s*signal\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var re_addgroup := RegEx.create_from_string("add_to_group\\s*\\(\\s*[\"']([^\"']+)[\"']")
	var grupos := {}

	for p in gd_files:
		var txt := FileAccess.get_file_as_string(p)
		if txt.is_empty():
			continue
		for line in txt.split("\n"):
			var m := re_signal.search(line)
			if m != null:
				inv["sinais"].append("%s  (%s)" % [m.get_string(1), p])
			var g := re_addgroup.search(line)
			if g != null:
				grupos[g.get_string(1)] = true

	var re_tscn_groups := RegEx.create_from_string("groups\\s*=\\s*\\[([^\\]]*)\\]")
	var re_quoted := RegEx.create_from_string("[\"']([^\"']+)[\"']")
	for p in scn_files:
		if not p.ends_with(".tscn"):
			continue
		var txt := FileAccess.get_file_as_string(p)
		for m in re_tscn_groups.search_all(txt):
			for q in re_quoted.search_all(m.get_string(1)):
				grupos[q.get_string(1)] = true

	inv["grupos"] = grupos.keys()
	return inv


# =============================================================================
#  ETAPA 6 — AUDITORIA DE STRINGS
#  Pega o que o parser nunca pega: nome escrito a mao que so falha em runtime.
#  Tres checagens, todas de falso-positivo praticamente zero.
# =============================================================================

func _audit_strings(gd_files: PackedStringArray) -> int:
	var re_path := RegEx.create_from_string("(?:preload|load)\\s*\\(\\s*[\"'](res://[^\"']+)[\"']")
	# KIT 1.5.0 — caminho res:// EM QUALQUER LUGAR, nao so colado no load().
	#
	# A regex acima exige o literal dentro de `load(` ou `preload(`. Medido em
	# 02/09/2026 no game-spell-brigade-like: `scripts/renderizar.gd` guardava o caminho
	# num DICIONARIO (`"modelo": "res://modelos/inimigos/Bat.fbx"`) e carregava
	# depois por variavel. Tres arquivos inexistentes, portao VERDE.
	#
	# Exige EXTENSAO CONHECIDA de proposito: sem isso, todo prefixo de pasta
	# montado por concatenacao viraria falso positivo — e penalizar codigo correto
	# e o caminho mais rapido para alguem desligar a checagem (mesma licao da F-21).
	var re_qualquer := RegEx.create_from_string("[\"'](res://[^\"']+\\.(?:gd|tscn|scn|tres|res|glb|gltf|fbx|obj|dae|png|jpg|jpeg|svg|webp|ogg|wav|mp3|ttf|otf|gdshader|json|csv|po|translation))[\"']")
	var re_action := RegEx.create_from_string("Input\\.is_action_(?:pressed|just_pressed|just_released)\\s*\\(\\s*[\"']([^\"']+)[\"']")
	var re_group := RegEx.create_from_string("(?:is_in_group|get_nodes_in_group|remove_from_group)\\s*\\(\\s*[\"']([^\"']+)[\"']")

	var acoes := {}
	for a in _inventory.get("acoes_input", []):
		acoes[a] = true
	var grupos := {}
	for g in _inventory.get("grupos", []):
		grupos[g] = true

	var total := 0
	for p in gd_files:
		if p == SELF_PATH:
			continue
		var txt := FileAccess.get_file_as_string(p)
		if txt.is_empty():
			continue
		var lines := txt.split("\n")
		for i in lines.size():
			var line: String = lines[i]
			var trimmed := line.strip_edges()
			if trimmed.begins_with("#"):
				continue
			var ln := i + 1

			# KIT 1.5.0 — todo caminho res:// com extensao conhecida, esteja ele
			# dentro de load(), num dicionario, numa constante ou num array.
			# VALVULA DECLARADA. Existe codigo que passa um caminho FALSO de
			# proposito -- um teste de logger, por exemplo, que verifica o que
			# acontece com erro vindo de arquivo que nao existe. Medido: o
			# `test_erro_repetido_NAO_enche_o_disco` usa "res://x.gd".
			#
			# A valvula e um comentario NA LINHA, visivel na revisao. Lista de
			# excecao dentro do portao seria invisivel e cresceria sozinha.
			if line.contains("portao:caminho-falso"):
				pass
			else:
				for m in re_qualquer.search_all(line):
					var caminho := m.get_string(1)
					# as mesmas duas guardas da checagem de baixo: caminho montado
					# por formatacao nao e literal e nao da para conferir
					if caminho.contains("%") or caminho.contains("{"):
						continue
					# KIT 1.5.1 — `.verify/` E SAIDA, e saida nao existe antes de
					# existir.
					#
					# MEDIDO em 02/09/2026: clonei o game-spell-brigade-like num
					# diretorio limpo e o portao frio reprovou com 15 falhas, TODAS
					# apontando para `res://.verify/*.json` e `.png` -- os arquivos
					# que as proprias bancadas ESCREVEM. Nenhuma delas e defeito:
					# `.verify/` esta no `.gitignore` por contrato do harness ("nao
					# vai para o git, e saida pura"), entao num clone ele nunca
					# existe ate a primeira execucao.
					#
					# Portao que reprova clone recem-feito por um motivo que nao e
					# defeito treina quem le a ignorar o vermelho -- e ai o portao
					# para de servir. A pasta de saida do proprio portao e a unica
					# excecao embutida, e ela e embutida porque e do CONTRATO, nao
					# de um projeto.
					if _e_saida_declarada(caminho):
						continue
					if FileAccess.file_exists(caminho) or ResourceLoader.exists(caminho):
						continue
					# a chave inclui o CAMINHO: duas referencias quebradas na mesma
					# linha sao dois defeitos, e uma chave sem o caminho esconderia
					# a segunda por colisao
					_fail("%s:%d:%s" % [p, ln, caminho], "res_path",
						"%s:%d — caminho res:// inexistente: %s" % [p, ln, caminho])

			for m in re_path.search_all(line):
				total += 1
				var alvo := m.get_string(1)
				# F-20: caminho montado por formatacao nao e literal — nao da para
				# checar existencia de "res://data/towers/%s". Penalizar codigo correto
				# e o caminho mais rapido para o usuario desligar a checagem.
				if alvo.contains("%") or alvo.contains("{"):
					continue
				# F-21: prefixo de DIRETORIO nao e arquivo. Codigo que varre uma
				# pasta escreve load("res://resources/upgrades/" + nome), e o
				# literal termina em "/". FileAccess.file_exists e
				# ResourceLoader.exists devolvem false para diretorio — a pasta
				# existia e o portao acusava mesmo assim. Medido em 31/08/2026 no
				# game-shardbreaker: 2 falsos positivos entraram no baseline.
				if alvo.ends_with("/"):
					if not DirAccess.dir_exists_absolute(alvo):
						_fail("%s:%d" % [p, ln], "string_path", "%s:%d — pasta inexistente: %s" % [p, ln, alvo])
					continue
				if not FileAccess.file_exists(alvo) and not ResourceLoader.exists(alvo):
					_fail("%s:%d" % [p, ln], "string_path", "%s:%d — caminho inexistente: %s" % [p, ln, alvo])

			for m in re_action.search_all(line):
				total += 1
				var acao := m.get_string(1)
				if not acoes.has(acao):
					_fail("%s:%d" % [p, ln], "string_input", "%s:%d — acao de input inexistente: \"%s\"" % [p, ln, acao])

			for m in re_group.search_all(line):
				total += 1
				var grupo := m.get_string(1)
				if not grupos.has(grupo):
					_fail("%s:%d" % [p, ln], "string_grupo", "%s:%d — grupo nunca criado: \"%s\"" % [p, ln, grupo])

	return total


# =============================================================================
#  ESTADO (AGENT-STATE.md)
# =============================================================================

func _read_state() -> Dictionary:
	var st := {}
	if not FileAccess.file_exists(STATE_PATH):
		return st
	var txt := FileAccess.get_file_as_string(STATE_PATH)

	var a := txt.find(MARK_BASE_START)
	var b := txt.find(MARK_BASE_END)
	if a >= 0 and b > a:
		var raw := txt.substr(a + MARK_BASE_START.length(), b - a - MARK_BASE_START.length())
		raw = raw.replace("```json", "").replace("```", "").strip_edges()
		var parsed: Variant = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			st = parsed

	var la := txt.find(MARK_LOCAL_START)
	var lb := txt.find(MARK_LOCAL_END)
	if la >= 0 and lb > la:
		st["local"] = txt.substr(la + MARK_LOCAL_START.length(), lb - la - MARK_LOCAL_START.length())
	return st


func _write_state() -> void:
	var local: String = _state.get("local", "\n_Espaco livre. Escreva aqui o que for especifico deste projeto._\n_Este bloco nunca e sobrescrito._\n")
	var meta: Dictionary = _state.get("meta", {})

	var s := ""
	s += "# AGENT-STATE.md\n\n"
	s += "> Arquivo **gerado** por `agent_verify.gd`. Nao edite fora do bloco LOCAL no fim.\n"
	s += "> Versione este arquivo no git.\n\n"

	s += "## Ambiente\n\n"
	s += "| item | valor |\n|---|---|\n"
	s += "| engine | %s |\n" % meta.get("engine", "?")
	s += "| kit | %s |\n" % meta.get("kit_version", KIT_VERSION)
	s += "| binario | `%s` |\n" % meta.get("binario", "?")
	s += "| instalado em | %s |\n" % meta.get("instalado_em", "?")
	var probe: Dictionary = meta.get("probe", {})
	s += "| metodo de deteccao | %s |\n" % String(probe.get("metodo", "?"))
	s += "| deteccao — detalhe | %s |\n\n" % String(probe.get("detalhe", "?"))

	s += "## Contagem\n\n"
	for k in _counts.keys():
		s += "- %s: %s\n" % [k, _counts[k]]
	s += "\n"

	s += "## Inventario do projeto\n\n"
	s += "_A IA deve consultar esta secao antes de criar qualquer coisa nova, para nao reimplementar o que ja existe._\n\n"
	s += _inv_section("Autoloads", "autoloads")
	s += _inv_section("Acoes de input", "acoes_input")
	s += _inv_section("Classes globais (class_name)", "class_names")
	s += _inv_section("Sinais declarados", "sinais")
	s += _inv_section("Grupos usados", "grupos")

	s += "## Falhas conhecidas (baseline)\n\n"
	s += "_Isto e a foto do que ja falhava. Nao alarma. So mudanca em relacao a isto alarma._\n\n"
	s += MARK_BASE_START + "\n```json\n"
	s += JSON.stringify({"baseline": _state.get("baseline", {}), "meta": meta}, "  ")
	s += "\n```\n" + MARK_BASE_END + "\n\n"

	s += "## Local\n\n"
	s += MARK_LOCAL_START + local + MARK_LOCAL_END + "\n"

	# So reescreve se o conteudo mudou. Sem isso, toda checagem deixaria o
	# arquivo modificado no git e a arvore nunca ficaria limpa.
	if FileAccess.file_exists(STATE_PATH):
		if FileAccess.get_file_as_string(STATE_PATH) == s:
			return

	var f := FileAccess.open(STATE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("nao consegui escrever AGENT-STATE.md")
		return
	f.store_string(s)
	f.close()


func _inv_section(titulo: String, chave: String) -> String:
	var itens: Array = _inventory.get(chave, [])
	var s := "### %s (%d)\n\n" % [titulo, itens.size()]
	if itens.is_empty():
		return s + "_nenhum_\n\n"
	var n := 0
	for it in itens:
		if n >= MAX_LIST:
			s += "- _... e mais %d_\n" % (itens.size() - n)
			break
		s += "- `%s`\n" % str(it)
		n += 1
	return s + "\n"


# =============================================================================
#  UTIL
# =============================================================================

func _walk(exts: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	var stack: Array[String] = ["res://"]
	while stack.size() > 0:
		var cur: String = stack.pop_back()
		var dir := DirAccess.open(cur)
		if dir == null:
			continue
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.begins_with("."):
				fname = dir.get_next()
				continue
			var full: String = cur.path_join(fname) if cur != "res://" else "res://" + fname
			if dir.current_is_dir():
				# KIT 1.5.2 — `_arquivo/` e a pasta de codigo APOSENTADO por
				# convencao do harness, e codigo aposentado nao e codigo vivo:
				# ele referencia caminhos que deixaram de existir justamente
				# porque foi aposentado. Medido em 02/09/2026 no apps/mcp-godot:
				# 18 das 18 falhas do portao frio vinham de `_arquivo/`, e
				# nenhuma era defeito. Mesma regra do `addons/` — o `-- doctor`
				# varre, o `-- full` nao.
				if (fname == "addons" or fname == "_arquivo") and not _include_addons:
					fname = dir.get_next()
					continue
				# KIT 1.5.2 — `.gdignore` e o mecanismo NATIVO da engine para tirar
				# uma pasta da importacao: o proprio Godot nao olha para dentro,
				# entao o portao tambem nao deve. Medido em 02/09/2026 no
				# game-zombie-survivors: `output/` tem `.gdignore` e 4 .glb
				# intermediarios de pipeline que nao carregam -- e nao sao defeito.
				#
				# Por que aqui e nao pelo .gitignore: a primeira tentativa filtrou
				# pelo .gitignore e derrubou a contagem de modelos do projeto ativo
				# de 139 para ZERO, em silencio e com o portao ainda em PASS.
				# `modelos/` esta no .gitignore de proposito (binario reproduzivel,
				# o que viaja e a lista) e mesmo assim precisa ser verificado.
				# Ignorar do git e ignorar da engine sao decisoes diferentes.
				if FileAccess.file_exists(full.path_join(".gdignore")):
					fname = dir.get_next()
					continue
				stack.push_back(full)
			else:
				var e := fname.get_extension().to_lower()
				for want in exts:
					if e == want:
						out.append(full)
						break
			fname = dir.get_next()
		dir.list_dir_end()
	return out


func _carrega_dirs_ignorados() -> void:
	# KIT 1.5.2 — GENERALIZACAO da excecao que ja existia para `.verify/`.
	#
	# O argumento escrito ali valia para qualquer pasta de saida, nao so para a
	# do portao: "esta no .gitignore por contrato, entao num clone ele nunca
	# existe ate a primeira execucao". Enquanto so `.verify/` era excecao, todo
	# projeto com pasta de saida propria reprovava por um motivo que nao e
	# defeito. Medido em 02/09/2026 no game-zombie-survivors: 4 das 5 falhas
	# apontavam `res://output/`, que o .gitignore do projeto declara na linha 14.
	#
	# So diretorio (linha terminada em `/`). Regra de ARQUIVO no .gitignore nao
	# entra: arquivo solto ignorado costuma ser segredo ou artefato que o codigo
	# realmente precisa, e engolir isso esconderia defeito de verdade.
	_dirs_ignorados = [".verify/", ".godot/"]   # do contrato, sempre
	var f := FileAccess.open("res://.gitignore", FileAccess.READ)
	if f == null:
		return
	while not f.eof_reached():
		var linha := f.get_line().strip_edges()
		if linha.is_empty() or linha.begins_with("#") or linha.begins_with("!"):
			continue
		if not linha.ends_with("/"):
			continue
		if linha.begins_with("/"):
			linha = linha.substr(1)
		if linha.contains("*"):
			continue
		if not _dirs_ignorados.has(linha):
			_dirs_ignorados.append(linha)
	f.close()


func _e_saida_declarada(caminho: String) -> bool:
	var rel := caminho.trim_prefix("res://")
	for d in _dirs_ignorados:
		if rel.begins_with(d):
			return true
	return false


func _fail(chave: String, etapa: String, msg: String) -> void:
	_failures["%s::%s" % [chave, etapa]] = msg


func _print_header() -> void:
	var meta: Dictionary = _state.get("meta", {})
	print("")
	print("agent_verify %s | engine %s | modo %s" % [KIT_VERSION, meta.get("engine", "?"), _mode])
	print("-".repeat(60))


func _print_line(rotulo: String, valor: String, _pad: int) -> void:
	print("  %-12s %s" % [rotulo, valor])


func _print_stage(rotulo: String, total: int, prefixo: String) -> void:
	var falhas := 0
	for k in _failures.keys():
		if String(k).contains("::" + prefixo):
			falhas += 1
	if falhas == 0:
		_print_line(rotulo, "%d ok" % total, 0)
	else:
		_print_line(rotulo, "%d verificados, %d com problema" % [total, falhas], 0)


func _emit_block(status: String, novas: int, corrigidas: int) -> void:
	var payload := {
		"status": status,
		"kit": KIT_VERSION,
		"modo": _mode,
		"novas_falhas": novas,
		"corrigidas": corrigidas,
		"total_falhas_conhecidas": _failures.size(),
		"contagem": _counts,
	}
	print("")
	print("===AGENT-VERIFY===")
	print(JSON.stringify(payload, "  "))
	print("===END===")
	# Arquivo e o contrato; stdout e conveniencia. O binario GUI do Windows
	# pode nao entregar stdout quando spawnado por hook sem console.
	#
	# doctor grava em arquivo SEPARADO. Ele varre addons/, entao acusa placeholder
	# de template de terceiro e quase sempre da FAIL — um FAIL que nao e veredito
	# de portao. Como o hook de SessionStart le result.json para dizer "ultimo
	# portao", um diagnostico sobrescrevendo esse arquivo faria a sessao abrir
	# anunciando uma falha que nunca existiu. Medido em 31/08/2026 no
	# game-star-colony.
	DirAccess.make_dir_recursive_absolute("res://.verify")
	var destino := "res://.verify/doctor.json" if _mode == "doctor" else "res://.verify/result.json"
	var rf := FileAccess.open(destino, FileAccess.WRITE)
	if rf != null:
		rf.store_string(JSON.stringify(payload, "  "))
		rf.flush()
		rf.close()
