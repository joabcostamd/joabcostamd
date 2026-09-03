extends SceneTree

## Linter das convenções do projeto — o que o compilador não pega.
##   godot --headless --path . -s res://tools/lint.gd
##
## Cada regra aqui existe porque o problema JÁ aconteceu neste projeto.

var erros: Array = []
var avisos: Array = []
var arquivos := 0
var linhas := 0

const PASTAS := ["res://scripts", "res://tools"]
const Textos := preload("res://scripts/core/textos.gd")

func _initialize() -> void:
	Dados.carregar(true)
	var lista := _todos_gd()
	for caminho in lista:
		_checar(caminho)
	_checar_paineis()
	_checar_recursos()
	_checar_entradas()
	_checar_i18n()

	print("===LINT=== arquivos=%d linhas=%d erros=%d avisos=%d" % [arquivos, linhas, erros.size(), avisos.size()])
	for e in erros:
		print("  ERRO: ", e)
	for a in avisos:
		print("  aviso: ", a)
	print("===STATUS=== ", "PASS" if erros.is_empty() else "FAIL")
	quit(0 if erros.is_empty() else 1)

func _checar(caminho: String) -> void:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		erros.append("não consegui ler " + caminho)
		return
	arquivos += 1
	var n := 0
	var eh_ferramenta := caminho.begins_with("res://tools")
	while not f.eof_reached():
		var linha := f.get_line()
		n += 1
		linhas += 1
		var limpa := linha.strip_edges()
		if limpa.begins_with("#"):
			continue

		# 1. emoji/símbolo sem glifo na fonte: sairia como quadradinho na tela
		if limpa.contains('"'):
			var fora := _sem_glifo(_antes_do_comentario(linha))
			if fora != "":
				erros.append("%s:%d sem glifo na fonte: %s (use Icone vetorial)" % [caminho, n, fora])

		# 2. print() solto fora de ferramenta e fora de guarda de debug
		if not eh_ferramenta and limpa.begins_with("print(") and not caminho.ends_with("main.gd"):
			erros.append("%s:%d print() em código de produção" % [caminho, n])

		# 3. caminho res:// que não existe (aspas duplas e simples)
		var aspa := '"'
		var pos := linha.find('"res://')
		if pos < 0:
			pos = linha.find("'res://")
			aspa = "'"
		if pos >= 0:
			var resto := linha.substr(pos + 1)
			var fim := resto.find(aspa)
			if fim > 0:
				var alvo := resto.substr(0, fim)
				if not alvo.contains("%") and not FileAccess.file_exists(alvo) and not DirAccess.dir_exists_absolute(alvo):
					erros.append("%s:%d caminho inexistente: %s" % [caminho, n, alvo])

		# 4. pendência deixada para trás (a busca é montada em pedaços de
		#    propósito, para o linter não acusar a si mesmo)
		var marca_a := "TO" + "DO:"
		var marca_b := "FIX" + "ME"
		if limpa.contains(marca_a) or limpa.contains(marca_b):
			avisos.append("%s:%d pendência deixada no código" % [caminho, n])
	f.close()

func _antes_do_comentario(linha: String) -> String:
	var h := linha.find("#")
	return linha if h < 0 else linha.substr(0, h)

## A regra verdadeira não é "é emoji?", é "a fonte desenha isso?".
## Emoji, setas, bolinhas geométricas — tudo que a fonte padrão não cobre vira
## um quadradinho vazio na tela. Perguntamos direto para a fonte.
func _sem_glifo(s: String) -> String:
	var fonte := ThemeDB.fallback_font
	if fonte == null:
		return ""
	var fora := ""
	for i in s.length():
		var c := s.unicode_at(i)
		if c > 127 and not fonte.has_char(c) and not fora.contains(s[i]):
			fora += s[i]
	return fora

## Todo painel referenciado pelo gerente precisa existir, e todo painel
## existente precisa estar registrado (senão vira código morto).
func _checar_paineis() -> void:
	var f := FileAccess.open("res://scripts/ui/panel_manager.gd", FileAccess.READ)
	if f == null:
		erros.append("panel_manager.gd ausente")
		return
	var texto := f.get_as_text()
	f.close()
	var registrados := {}
	var re := RegEx.create_from_string('scripts/ui/(panel_\\w+)\\.gd')
	for m in re.search_all(texto):
		registrados[m.get_string(1)] = true
	var d := DirAccess.open("res://scripts/ui")
	if d == null:
		return
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if nome.begins_with("panel_") and nome.ends_with(".gd") and nome != "panel_base.gd" and nome != "panel_manager.gd":
			var chave := nome.replace(".gd", "")
			if not registrados.has(chave):
				erros.append("painel %s existe mas não está registrado no gerente" % nome)
		nome = d.get_next()
	d.list_dir_end()

## Nenhuma imagem ou som no repositório — a promessa do projeto.
func _checar_recursos() -> void:
	var proibidas := ["png", "jpg", "jpeg", "webp", "ogg", "wav", "mp3", "ttf", "otf"]
	var achados: Array = []
	_varrer("res://", proibidas, achados)
	# icon.svg é a única exceção: é vetor, e é o ícone da janela.
	if not achados.is_empty():
		erros.append("arquivos de mídia no projeto (tudo deve ser procedural): %s" % str(achados))

func _varrer(pasta: String, exts: Array, saida: Array) -> void:
	var d := DirAccess.open(pasta)
	if d == null:
		return
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if nome.begins_with("."):
			nome = d.get_next()
			continue
		var caminho := pasta.path_join(nome)
		if d.current_is_dir():
			_varrer(caminho, exts, saida)
		else:
			var ext := nome.get_extension().to_lower()
			if exts.has(ext) and saida.size() < 12:
				saida.append(caminho)
		nome = d.get_next()
	d.list_dir_end()

func _todos_gd() -> Array:
	var out: Array = []
	for p in PASTAS:
		_coletar(p, out)
	return out

func _coletar(pasta: String, out: Array) -> void:
	var d := DirAccess.open(pasta)
	if d == null:
		return
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if d.current_is_dir():
			if not nome.begins_with("."):
				_coletar(pasta.path_join(nome), out)
		elif nome.ends_with(".gd"):
			out.append(pasta.path_join(nome))
		nome = d.get_next()
	d.list_dir_end()

## Entrada de ferramenta (`-s`) não pode citar classe do jogo.
##
## Por quê: em modo `-s` o Godot compila o script de entrada ANTES de registrar
## os autoloads. Qualquer `class_name` que use `Bus`/`Cfg` falha a compilar — e
## falha de forma INTERMITENTE, dependendo da ordem em que a engine resolve os
## scripts. O portão de testes passou verde por semanas e depois começou a
## quebrar sozinho por causa disso. A entrada fica magra; o corpo vai para
## `tools/suites/` e é carregado dentro de `_initialize()`.
func _checar_entradas() -> void:
	var d := DirAccess.open("res://tools")
	if d == null:
		return
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if not d.current_is_dir() and nome.ends_with(".gd"):
			_checar_entrada("res://tools/" + nome)
		nome = d.get_next()
	d.list_dir_end()

func _checar_entrada(caminho: String) -> void:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return
	var texto := f.get_as_text()
	f.close()
	if not texto.begins_with("extends SceneTree"):
		return
	# `bootstrap`, `build_scene` e `probe` mexem em ProjectSettings/cenas e não
	# tocam na simulação: para eles a regra não faz sentido.
	for isento in ["bootstrap.gd", "build_scene.gd", "probe.gd", "test_big.gd"]:
		if caminho.ends_with(isento):
			return
	var citadas: Array = []
	for classe in CLASSES_DO_JOGO:
		var re := RegEx.create_from_string("(?<![\\w.\"])" + classe + "(?![\\w\"])")
		if re.search(_sem_comentarios(texto)) != null and not citadas.has(classe):
			citadas.append(classe)
	if not citadas.is_empty():
		erros.append("%s é entrada `-s` e cita classe do jogo (%s): mova o corpo para tools/suites/" % [
			caminho, ", ".join(citadas)])

## Tudo que depende de autoload em tempo de parse, direta ou indiretamente.
const CLASSES_DO_JOGO := [
	"Jogo", "Bus", "Cfg", "SaveSys", "Audio",
	"Economia", "Combate", "EnemyAI", "TorreSim", "Diretor", "Saque", "Progresso",
	"Mecanicas", "Eventos", "Habilidades", "Offline", "Modificadores", "Estado",
	"Arena", "StatEngine", "Prestigio",
]

func _sem_comentarios(texto: String) -> String:
	var out := ""
	for linha in texto.split("\n"):
		var l := str(linha)
		if l.strip_edges().begins_with("#"):
			continue
		out += _antes_do_comentario(l) + "\n"
	return out

## Toda `Txt.t("chave")` precisa ter tradução. Sem esta regra a chave aparece
## crua na tela (é assim que o Txt sinaliza chave perdida) e ninguém percebe
## até um jogador tirar print.
func _checar_i18n() -> void:
	var re := RegEx.create_from_string('Txt\\.[tf]\\("([a-z0-9_]+)"')
	for caminho in _todos_gd():
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			continue
		var texto := _sem_comentarios(f.get_as_text())
		f.close()
		for m in re.search_all(texto):
			var chave := m.get_string(1)
			if not Textos.tem(chave):
				erros.append("%s usa Txt.t(\"%s\") sem tradução" % [caminho, chave])
