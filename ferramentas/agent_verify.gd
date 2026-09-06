extends SceneTree
# =====================================================================
# agent_verify — portao frio de verificacao estrutural (nuvem/headless)
# Copia canonica: ferramentas/agent_verify.gd no repo raiz.
# Nunca edite a copia plantada dentro de um jogo: edite esta e reinstale.
#
#   godot --headless --path . -s res://agent_verify.gd
#   godot --headless --path . -s res://agent_verify.gd -- doctor
#
# Contrato: o bloco ===AGENT-VERIFY=== e a UNICA fonte de verdade.
# O exit code do Godot nao e confiavel (ja saiu 0 com erro de parse).
# =====================================================================

const VERSAO := "2.0.0-nuvem"
const IGNORAR := [".godot", ".git", ".verify", ".import", "addons/gdUnit4"]

var falhas: Array[String] = []
var avisos: Array[String] = []
var contagem := {}
var detalhado := false


func _initialize() -> void:
	detalhado = OS.get_cmdline_user_args().has("doctor")

	var gds := _listar("res://", ".gd")
	var tscns := _listar("res://", ".tscn")
	var tres := _listar("res://", ".tres")
	contagem = {"scripts": gds.size(), "cenas": tscns.size(), "recursos": tres.size()}

	_checar_projeto()
	_checar_autoloads()
	_checar_scripts(gds)
	_checar_cenas(tscns)
	_checar_recursos(tres)
	_checar_uid(gds)
	_checar_traducoes()

	_relatar()
	quit(0 if falhas.is_empty() else 1)


# ----------------------------------------------------------------- checagens

func _checar_projeto() -> void:
	if not FileAccess.file_exists("res://project.godot"):
		falhas.append("project.godot nao encontrado")
		return
	var principal := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if principal == "":
		falhas.append("application/run/main_scene vazio")
	elif not ResourceLoader.exists(principal):
		falhas.append("cena principal inexistente: %s" % principal)


func _checar_autoloads() -> void:
	for prop in ProjectSettings.get_property_list():
		var nome: String = prop.get("name", "")
		if not nome.begins_with("autoload/"):
			continue
		var chave := nome.substr(9)
		var caminho := str(ProjectSettings.get_setting(nome, "")).lstrip("*")
		if caminho == "":
			continue
		if not ResourceLoader.exists(caminho):
			falhas.append("autoload %s aponta para arquivo inexistente: %s" % [chave, caminho])
		elif load(caminho) == null:
			falhas.append("autoload %s nao compila: %s" % [chave, caminho])


func _checar_scripts(gds: Array) -> void:
	# load() devolve a copia em cache e mascara erro de parse. Compilamos do
	# codigo-fonte, sempre com reload(true) — sem keep_state o guard interno
	# devolve erro 22 em todo script com instancia viva (F-19).
	for caminho in gds:
		if caminho.ends_with("agent_verify.gd"):
			continue
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			falhas.append("script ilegivel: %s" % caminho)
			continue
		var fonte := f.get_as_text()
		f.close()

		# Recarregamos o PROPRIO script (mesmo resource_path), nunca uma copia:
		# uma copia com `class_name` colide com a classe global ja registrada e
		# devolve ERR_PARSE_ERROR num arquivo perfeitamente valido.
		var recurso = load(caminho)
		if recurso == null or not (recurso is GDScript):
			falhas.append("script nao carrega como GDScript: %s" % caminho)
			continue
		var gd := recurso as GDScript
		gd.source_code = fonte
		var erro := gd.reload(true)
		if erro != OK:
			falhas.append("script nao compila (erro %d): %s" % [erro, caminho])
			continue

		_checar_caminhos_no_texto(fonte, caminho)


func _checar_caminhos_no_texto(fonte: String, origem: String) -> void:
	# Caminho res:// escrito dentro do codigo (const, dicionario, preload
	# montado a mao) nao aparece em nenhuma cena — e some sem aviso nenhum.
	var re := RegEx.new()
	re.compile("res://[A-Za-z0-9_./\\-]+")
	for m in re.search_all(fonte):
		var alvo := m.get_string()
		if "%s" in alvo or "{" in alvo:
			continue
		if alvo.get_extension() == "":
			continue
		if not ResourceLoader.exists(alvo) and not FileAccess.file_exists(alvo):
			falhas.append("caminho inexistente citado em %s -> %s" % [origem, alvo])


func _checar_cenas(tscns: Array) -> void:
	for caminho in tscns:
		var cena = load(caminho)
		if cena == null:
			falhas.append("cena nao carrega: %s" % caminho)
			continue
		if not (cena is PackedScene):
			falhas.append("cena nao e PackedScene: %s" % caminho)
			continue
		var estado: SceneState = (cena as PackedScene).get_state()
		for i in estado.get_node_count():
			for j in estado.get_node_property_count(i):
				var v = estado.get_node_property_value(i, j)
				_checar_referencia(v, caminho)


func _checar_recursos(tres: Array) -> void:
	for caminho in tres:
		if load(caminho) == null:
			falhas.append("recurso nao carrega: %s" % caminho)


func _checar_referencia(v: Variant, origem: String) -> void:
	if v is String or v is StringName:
		var s := str(v)
		# caminho montado em tempo de execucao nao e verificavel (F-20)
		if s.begins_with("res://") and not ("%s" in s or "{" in s):
			if not ResourceLoader.exists(s) and not FileAccess.file_exists(s):
				falhas.append("referencia quebrada em %s -> %s" % [origem, s])
	elif v is Array:
		for item in v:
			_checar_referencia(item, origem)


func _checar_uid(gds: Array) -> void:
	var faltando := 0
	for caminho in gds:
		if not FileAccess.file_exists(caminho + ".uid"):
			faltando += 1
			if detalhado:
				avisos.append("sem .uid: %s" % caminho)
	if faltando > 0 and not detalhado:
		avisos.append("%d script(s) sem .uid — rode --headless --import e versione os .uid" % faltando)


func _checar_traducoes() -> void:
	var lista = ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())
	for t in lista:
		if not ResourceLoader.exists(str(t)):
			falhas.append("traducao inexistente: %s" % t)


# ------------------------------------------------------------------ utilidade

func _listar(base: String, ext: String) -> Array:
	var achados: Array = []
	var dir := DirAccess.open(base)
	if dir == null:
		return achados
	dir.list_dir_begin()
	var nome := dir.get_next()
	while nome != "":
		var cheio := base.path_join(nome) if base != "res://" else "res://" + nome
		var pular := false
		for ig in IGNORAR:
			if cheio.contains(ig):
				pular = true
				break
		if not pular:
			if dir.current_is_dir():
				achados.append_array(_listar(cheio, ext))
			elif nome.ends_with(ext):
				achados.append(cheio)
		nome = dir.get_next()
	dir.list_dir_end()
	return achados


func _relatar() -> void:
	var status := "PASS" if falhas.is_empty() else "FAIL"
	var res := {
		"versao": VERSAO,
		"status": status,
		"projeto": str(ProjectSettings.get_setting("application/config/name", "?")),
		"contagem": contagem,
		"falhas": falhas,
		"avisos": avisos,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.verify"))
	var f := FileAccess.open("res://.verify/result.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(res, "  "))
		f.close()
	print("\n===AGENT-VERIFY===")
	print(JSON.stringify(res, "  "))
	print("===FIM-AGENT-VERIFY===")
