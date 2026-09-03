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
const Sons := preload("res://scripts/audio/sfx.gd")

func _initialize() -> void:
	Dados.carregar(true)
	var lista := _todos_gd()
	for caminho in lista:
		_checar(caminho)
	_checar_paineis()
	_checar_recursos()
	_checar_entradas()
	_checar_i18n()
	_checar_sons()
	_checar_passivas()
	_checar_especiais()

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
	# Ferramenta é o que roda fora do jogo: tools/ e os .gd soltos na raiz
	# (`agent_verify.gd`). Nenhum código de jogo mora na raiz — tudo que é
	# jogado vive em scripts/ —, então `print()` ali é saída de portão, não
	# depuração esquecida.
	var eh_ferramenta := caminho.begins_with("res://tools") \
		or caminho.get_slice_count("/") == 3
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
				# O Godot esconde de `res://` tudo que começa com ponto, então
				# `.gitignore` e `.verify/` existem no disco e somem daqui. A
				# regra não pode acusar de inexistente o que ela não consegue
				# enxergar.
				var oculto := alvo.contains("/.")
				if not alvo.contains("%") and not oculto and not FileAccess.file_exists(alvo) and not DirAccess.dir_exists_absolute(alvo):
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
	# Os .gd soltos na raiz também: `agent_verify.gd` mora lá e escapava do
	# linter só por causa de onde está. Sem descer, senão repetiria as pastas.
	var d := DirAccess.open("res://")
	if d != null:
		d.list_dir_begin()
		var nome := d.get_next()
		while nome != "":
			if not d.current_is_dir() and nome.ends_with(".gd"):
				out.append("res://" + nome)
			nome = d.get_next()
		d.list_dir_end()
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
	# `bootstrap` e `build_scene` mexem em ProjectSettings e cenas, não tocam na
	# simulação: para eles a regra não faz sentido.
	for isento in ["bootstrap.gd", "build_scene.gd"]:
		if caminho.ends_with(isento):
			return
	# Sem comentários E sem strings: um nome de classe DENTRO de aspas (um padrão
	# de regex, um caminho, uma mensagem) não é dependência de compilação. A
	# própria regra se acusou uma vez por causa do regex `Audio\.tocar`.
	var limpo := _sem_strings(_sem_comentarios(texto))
	var citadas: Array = []
	for classe in _classes_contaminadas():
		var re := RegEx.create_from_string("(?<![\\w.\"])" + classe + "(?![\\w\"])")
		if re.search(limpo) != null and not citadas.has(classe):
			citadas.append(classe)
	if not citadas.is_empty():
		citadas.sort()
		erros.append("%s é entrada `-s` e cita classe que depende de autoload (%s): mova o corpo para tools/suites/" % [
			caminho, ", ".join(citadas)])

## Nomes dos autoloads, lidos do próprio project.godot — lista escrita à mão
## apodrece.
func _autoloads() -> Array:
	var out: Array = []
	for chave in ProjectSettings.get_property_list():
		var nome := str(chave.get("name", ""))
		if nome.begins_with("autoload/"):
			out.append(nome.substr(9))
	return out

## Todo script com `class_name` que cite um autoload em tempo de parse. É esta
## a lista que importa, e ela é DERIVADA: quando alguém renomeia uma classe ou
## cria outra, a regra continua certa sozinha. A versão anterior era uma lista
## fixa que já tinha dois nomes mortos ("Modificadores", "Estado") e faltava
## "Mods" e "GameState" — ou seja, protegia menos do que parecia.
func _classes_contaminadas() -> Array:
	if not _cache_contaminadas.is_empty():
		return _cache_contaminadas
	var autos := _autoloads()
	var re_nome := RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	for caminho in _todos_gd():
		if caminho.begins_with("res://tools"):
			continue
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			continue
		var texto := f.get_as_text()
		f.close()
		var m := re_nome.search(texto)
		if m == null:
			continue
		var limpo := _sem_strings(_sem_comentarios(texto))
		for a in autos:
			var re_uso := RegEx.create_from_string("(?<![\\w.\"])" + str(a) + "\\.")
			if re_uso.search(limpo) != null:
				_cache_contaminadas.append(m.get_string(1))
				break
	# os próprios autoloads também não podem aparecer na entrada
	for a in autos:
		_cache_contaminadas.append(str(a))
	return _cache_contaminadas

var _cache_contaminadas: Array = []

## Troca todo literal de texto por aspas vazias. Só para regras que perguntam
## "este código DEPENDE de X?" — nunca para as que leem o conteúdo das strings.
func _sem_strings(texto: String) -> String:
	var out := ""
	var dentro := false
	var aspa := ""
	var i := 0
	while i < texto.length():
		var c := texto[i]
		if dentro:
			if c == "\\":
				i += 2
				continue
			if c == aspa:
				dentro = false
				out += aspa
		elif c == "\"" or c == "'":
			dentro = true
			aspa = c
			out += c
		else:
			out += c
		i += 1
	return out

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
	# `Txt.t("m_" + chave)` monta a chave em tempo de execução: o pedaço literal
	# não é uma chave e não dá para verificar aqui. O `(?!\\s*\\+)` deixa passar.
	var re := RegEx.create_from_string('Txt\\.[tf]\\("([a-z0-9_]+)"(?!\\s*\\+)')
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

## `Audio.tocar("nome")` com nome que não existe no catálogo é silêncio: não
## quebra nada, não avisa nada, e a cena que devia ter som fica muda. Aconteceu
## com a camada de comemoração, que pedia um "celebracao" inexistente.
func _checar_sons() -> void:
	var catalogo := Sons.catalogo()
	var re := RegEx.create_from_string('Audio\\.tocar(?:_em)?\\("([a-z0-9_]+)"')
	for caminho in _todos_gd():
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			continue
		var texto := _sem_comentarios(f.get_as_text())
		f.close()
		for m in re.search_all(texto):
			var nome := m.get_string(1)
			if not catalogo.has(nome):
				erros.append("%s toca som inexistente: \"%s\"" % [caminho, nome])

## Passiva declarada no JSON e nunca lida pelo código é promessa vazia: o
## jogador compra a relíquia, o texto diz o que ela faz, e não acontece nada.
## Sete estavam assim. É o pior tipo de bug do projeto — passa em todo teste e
## ainda assim engana quem joga.
func _checar_passivas() -> void:
	var declaradas := {}
	var d := DirAccess.open("res://data")
	if d == null:
		return
	d.list_dir_begin()
	var arq := d.get_next()
	while arq != "":
		if arq.ends_with(".json"):
			var f := FileAccess.open("res://data/" + arq, FileAccess.READ)
			if f != null:
				var bruto = JSON.parse_string(f.get_as_text())
				f.close()
				_coletar_passivas(bruto, arq, declaradas)
		arq = d.get_next()
	d.list_dir_end()

	var lidas := ""
	for caminho in _todos_gd():
		if not caminho.begins_with("res://scripts"):
			continue
		var f2 := FileAccess.open(caminho, FileAccess.READ)
		if f2 == null:
			continue
		lidas += _sem_comentarios(f2.get_as_text())
		f2.close()

	for chave in declaradas.keys():
		var k := str(chave)
		# basta o nome aparecer no código da simulação: além de `pas.has`, há
		# leitor legítimo por comparação direta (Espelho do Operador).
		if lidas.contains('"%s"' % k):
			continue
		erros.append("passiva declarada em %s e nunca lida: \"%s\"" % [str(declaradas[chave]), k])

## Só o que está dentro de um `efeito` conta. `chave` também aparece em
## CONDIÇÃO de missão e conquista ({"tipo": "inimigoTipo", "chave": "grunhido"}),
## que é outra coisa: ali a chave é o alvo da condição, não uma passiva.
func _coletar_passivas(o, arquivo: String, saida: Dictionary) -> void:
	if o is Dictionary:
		var ef = o.get("efeito", null)
		if ef is Array:
			for item in ef:
				if not (item is Dictionary) or item.has("stat"):
					continue
				var ch = item.get("chave", null)
				if ch is String and str(ch) != "":
					saida[str(ch)] = arquivo
		for v in o.values():
			_coletar_passivas(v, arquivo, saida)
	elif o is Array:
		for v in o:
			_coletar_passivas(v, arquivo, saida)

## Mesmo raciocínio das passivas, para os "especiais" (slotsCartas, rerolls,
## revivesExtra, ondaInicial...). `slotsHabilidade` estava declarado numa
## relíquia comprável e pressupunha um sistema de slots de habilidade que este
## jogo nunca teve: a relíquia custava núcleos e não fazia absolutamente nada.
func _checar_especiais() -> void:
	var declarados := {}
	var d := DirAccess.open("res://data")
	if d == null:
		return
	d.list_dir_begin()
	var arq := d.get_next()
	while arq != "":
		if arq.ends_with(".json"):
			var f := FileAccess.open("res://data/" + arq, FileAccess.READ)
			if f != null:
				var bruto = JSON.parse_string(f.get_as_text())
				f.close()
				_coletar_especiais(bruto, arq, declarados)
		arq = d.get_next()
	d.list_dir_end()

	var lidos := ""
	for caminho in _todos_gd():
		if not caminho.begins_with("res://scripts/sim") and not caminho.begins_with("res://scripts/core"):
			continue
		var f2 := FileAccess.open(caminho, FileAccess.READ)
		if f2 == null:
			continue
		lidos += _sem_comentarios(f2.get_as_text())
		f2.close()

	for chave in declarados.keys():
		var k := str(chave)
		if k == "desbloqueio" or lidos.contains('"%s"' % k):
			continue
		erros.append("especial declarado em %s e nunca lido pela simulação: \"%s\"" % [
			str(declarados[chave]), k])

func _coletar_especiais(o, arquivo: String, saida: Dictionary) -> void:
	if o is Dictionary:
		var ef = o.get("efeito", null)
		if ef is Array:
			for item in ef:
				if not (item is Dictionary):
					continue
				var esp = item.get("especial", null)
				if esp is String and str(esp) != "":
					saida[str(esp)] = arquivo
		for v in o.values():
			_coletar_especiais(v, arquivo, saida)
	elif o is Array:
		for v in o:
			_coletar_especiais(v, arquivo, saida)
