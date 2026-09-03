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

func _initialize() -> void:
	Dados.carregar(true)
	var lista := _todos_gd()
	for caminho in lista:
		_checar(caminho)
	_checar_paineis()
	_checar_recursos()

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

		# 1. emoji em string de interface: a fonte padrão não tem glifo
		if limpa.contains('"') and _tem_emoji(_antes_do_comentario(linha)):
			erros.append("%s:%d emoji em string (use Icone vetorial)" % [caminho, n])

		# 2. print() solto fora de ferramenta e fora de guarda de debug
		if not eh_ferramenta and limpa.begins_with("print(") and not caminho.ends_with("main.gd"):
			erros.append("%s:%d print() em código de produção" % [caminho, n])

		# 3. caminho res:// que não existe
		var pos := linha.find('"res://')
		if pos >= 0:
			var resto := linha.substr(pos + 1)
			var fim := resto.find('"')
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

func _tem_emoji(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if (c >= 0x1F300 and c <= 0x1FAFF) or (c >= 0x2600 and c <= 0x27BF) \
				or (c >= 0x2B00 and c <= 0x2BFF) or c == 0x2728 or c == 0x2B50:
			return true
	return false

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
	var re := RegEx.create_from_string('res://scripts/ui/(panel_\\w+)\\.gd')
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
