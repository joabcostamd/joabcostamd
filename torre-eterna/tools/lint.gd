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
	_checar_constantes_mortas()
	_checar_tipos_cond()
	_checar_tremor()
	_checar_texto_cru()
	_checar_aleatorio()

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
				# Caminho nao tem espaco: se a string continua em prosa depois
				# do arquivo ("res://x.gd nao compila"), so o comeco e caminho.
				var esp := alvo.find(" ")
				if esp > 0:
					alvo = alvo.substr(0, esp)
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

## Só o código: sem texto entre aspas e sem comentário, numa passada só.
##
## Fazer isso em dois passos separados quebra: `_antes_do_comentario` cortava a
## linha no primeiro `#`, e quando esse `#` estava DENTRO de uma string — como
## em `linha.find("#")` — a aspa ficava sem fechar. Dali para a frente o
## separador de strings entendia tudo ao contrário: texto virava código e
## código virava texto. A regra das entradas `-s` chegou a se acusar por causa
## disso. Aqui os dois estados são acompanhados juntos, que é a única forma de
## acertar os dois. Blocos `"""..."""` (o shader mora num) contam como texto.
func _codigo_puro(texto: String) -> String:
	var out := ""
	var em_bloco := false
	for bruta in texto.split("\n"):
		var linha := str(bruta)
		var limpa := ""
		var i := 0
		var dentro := false
		var aspa := ""
		while i < linha.length():
			var tres := linha.substr(i, 3)
			if tres == "\"\"\"" or tres == "'''":
				em_bloco = not em_bloco
				i += 3
				continue
			if em_bloco:
				i += 1
				continue
			var c := linha[i]
			if dentro:
				if c == "\\":
					i += 2
					continue
				if c == aspa:
					dentro = false
				i += 1
				continue
			if c == "\"" or c == "'":
				dentro = true
				aspa = c
				i += 1
				continue
			if c == "#":
				break
			limpa += c
			i += 1
		out += limpa + "\n"
	return out

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
	var limpo := _codigo_puro(texto)
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
		var limpo := _codigo_puro(texto)
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
		# NAO basta o nome aparecer em algum lugar do codigo.
		#
		# A regra antiga aceitava a passiva se a string existisse em qualquer
		# ponto de scripts/ — inclusive num rotulo de interface, numa lista morta
		# ou num dicionario de traducao. Uma passiva pode ter nome em cinco
		# arquivos de UI e nao ser lida uma vez pela simulacao, e a regra dizia
		# que estava tudo bem. Agora exige um contexto de LEITURA de verdade:
		# `pas.has(...)`, `pas.get(...)`, `pas[...]` ou `_tem_passiva(def, ...)`,
		# que sao as quatro formas pelas quais o jogo pergunta se a passiva esta
		# ativa. Medido antes de apertar: 16 das 17 ja passavam pelo criterio
		# apertado, entao a regra frouxa nao estava escondendo bagunca — estava
		# so pronta para deixar a proxima passar.
		var lida := (lidas.contains('pas.has("%s")' % k)
			or lidas.contains('pas.get("%s' % k)
			or lidas.contains('pas["%s"]' % k)
			or lidas.contains('_tem_passiva(def, "%s")' % k))
		if lida:
			continue
		erros.append("passiva declarada em %s e nunca LIDA pela simulacao: \"%s\" (o nome aparecer em scripts/ nao basta)" % [str(declaradas[chave]), k])

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
## A simulação não pode sortear pelo gerador GLOBAL.
##
## `randf()`, `randi()`, `randf_range()` e `Array.shuffle()` usam o gerador do
## Godot, que ninguém semeia. Uma simulação que os use deixa de ser
## reproduzível — e o portão de balanceamento passou a depender disso: com o
## gerador global, duas execuções do MESMO código deram onda 50 em 14m55 e em
## 15m07, uma reprovando e a outra passando. Portão que muda de resposta sem o
## código mudar não mede nada. Tudo que sorteia dentro de `scripts/sim` e
## `scripts/data` passa pelo `RngX` do jogo, que tem semente.
func _checar_aleatorio() -> void:
	var proibidos := ["randf(", "randi(", "randf_range(", "randi_range(", "randfn("]
	for caminho in _todos_gd():
		if not (caminho.begins_with("res://scripts/sim") or caminho.begins_with("res://scripts/data")):
			continue
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			continue
		var n := 0
		while not f.eof_reached():
			var linha := f.get_line()
			n += 1
			var limpa := _sem_strings(linha.strip_edges())
			var c := limpa.find("#")
			if c >= 0:
				limpa = limpa.substr(0, c)
			for nome in proibidos:
				if limpa.contains(nome) and not limpa.contains("rng." + nome):
					erros.append("%s:%d usa o sorteio global (%s) — a simulacao tem que sortear pelo RngX" % [
						caminho, n, nome])
			if limpa.contains(".shuffle()"):
				erros.append("%s:%d usa Array.shuffle(), que e global — use rng.embaralhar()" % [caminho, n])

## Texto em português escrito direto no código, sem passar pelo `Txt`.
##
## A regra de i18n só conferia se uma chave USADA existia — nunca se um texto
## tinha sido escrito sem chave nenhuma. Por essa fresta passaram onze frases em
## `events_sim.gd`: em inglês, o diálogo de evento misturava "+20 gemas" com
## "guaranteed" na mesma caixa. Aqui a pergunta é a outra: existe string com
## cara de frase em português fora de um `Txt`?
##
## O sinal é acento ou palavra funcional portuguesa numa string com espaço.
## Chave de tradução, caminho, id e formato não têm nenhum dos dois.
## Textos que ficam crus de propósito, com a razão ao lado.
const EXCECOES_TEXTO := {
	"Português (BR)": "nome de idioma fica no próprio idioma",
}

const PALAVRAS_PT := ["de ", "da ", "do ", " e ", " ou ", " por ", " com ", " sem ",
	" que ", " para ", " uma ", " um ", " os ", " as ", " no ", " na "]

func _checar_texto_cru() -> void:
	var acentos := "áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ"
	for caminho in _todos_gd():
		# ferramentas e dados não vão para a tela do jogador
		if caminho.begins_with("res://tools") or caminho.get_slice_count("/") == 3:
			continue
		# O próprio módulo de tradução guarda os textos padrão.
		if caminho.ends_with("textos.gd"):
			continue
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			continue
		var n := 0
		while not f.eof_reached():
			var linha := f.get_line()
			n += 1
			var limpa := linha.strip_edges()
			if limpa.begins_with("#"):
				continue
			# a linha já usa Txt: o texto ali é chave ou molde, não frase solta
			if limpa.contains("Txt.t(") or limpa.contains("Txt.f(") or limpa.contains("push_error") \
					or limpa.contains("push_warning") or limpa.contains("print("):
				continue
			# Rótulo de ATRIBUIÇÃO de atributo. `add_mult(stat, v, "Álbum de
			# Ecos")` guarda de onde veio o bônus para depuração; esse texto não
			# é desenhado em lugar nenhum (`StatEngine.fontes` não tem leitor de
			# interface). Traduzi-lo seria trocar dívida por ruído.
			var atribui := false
			for chamada in ["add_flat(", "add_pct(", "add_mult(", "add_mult_log(",
					"ganhar_moeda(", "ganhar_ouro(", "faltando.append("]:
				if limpa.contains(chamada):
					atribui = true
					break
			if atribui:
				continue
			for trecho in _strings_de(limpa):
				if not trecho.contains(" "):
					continue
				# Nome de idioma fica no idioma dele: traduzir "Português (BR)"
				# para "Portuguese (BR)" torna o seletor pior para quem o procura.
				if EXCECOES_TEXTO.has(trecho):
					continue
				var suspeita := false
				for c in acentos:
					if trecho.contains(c):
						suspeita = true
						break
				if not suspeita:
					for pal in PALAVRAS_PT:
						if trecho.to_lower().contains(pal):
							suspeita = true
							break
				if suspeita:
					erros.append("%s:%d texto em portugues fora do Txt: \"%s\"" % [
						caminho, n, trecho.substr(0, 48)])

## As strings literais de uma linha, sem as aspas.
func _strings_de(linha: String) -> Array:
	var out: Array = []
	var i := 0
	while i < linha.length():
		var c := linha[i]
		if c == "\"" or c == "'":
			var fim := i + 1
			var atual := ""
			while fim < linha.length() and linha[fim] != c:
				if linha[fim] == "\\":
					fim += 2
					continue
				atual += linha[fim]
				fim += 1
			out.append(atual)
			i = fim + 1
			continue
		if c == "#":
			break
		i += 1
	return out

## `Cfg.forca_tremor()` só pode ser chamado de dentro do Juice.
##
## A escala do tremor vale no único ponto por onde todo tremor passa. Chamar de
## novo em qualquer outro lugar aplica DUAS vezes — e foi o contrário disso
## (dez dos onze disparos passando por fora) que deixou "movimento reduzido"
## sem efeito por muito tempo. Um ponto só, e o linter guarda a porta.
func _checar_tremor() -> void:
	for caminho in _todos_gd():
		if caminho == "res://scripts/render/juice.gd" or caminho == "res://scripts/core/config.gd":
			continue
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			continue
		var n := 0
		while not f.eof_reached():
			var linha := _sem_strings(f.get_line())
			n += 1
			var c := linha.find("#")
			if c >= 0:
				linha = linha.substr(0, c)
			if linha.contains("forca_tremor("):
				erros.append("%s:%d chama forca_tremor() fora do Juice — a escala do tremor vale num ponto so" % [caminho, n])

## `Progresso.TIPOS_COND` tem que listar exatamente os casos de `valor_cond`.
##
## A lista existe para o portão perguntar "todo tipo citado pelo conteúdo tem
## leitor?". Se ela e a função divergirem, a pergunta passa a ter resposta
## errada e o tipo órfão volta a ficar invisível — que é justamente o bug que
## ela foi criada para pegar. Aqui as duas são comparadas no arquivo.
func _checar_tipos_cond() -> void:
	var f := FileAccess.open("res://scripts/sim/progress.gd", FileAccess.READ)
	if f == null:
		erros.append("nao consegui ler progress.gd para conferir TIPOS_COND")
		return
	var texto := f.get_as_text()
	f.close()
	var na_lista := {}
	var re_lista := RegEx.new()
	re_lista.compile("^\\t\"(\\w+)\",$")
	var re_caso := RegEx.new()
	# Um caso pode ter vários rótulos: `"douradosAbatidos", "dourados": return`.
	# A primeira versão desta regra só via o rótulo único e deu falso positivo.
	re_caso.compile("^\\t\\t((?:\"\\w+\"(?:,\\s*)?)+):\\s*return")
	var dentro_lista := false
	var dentro_func := false
	var nos_casos := {}
	for linha in texto.split("\n"):
		if linha.begins_with("const TIPOS_COND"):
			dentro_lista = true
			continue
		if dentro_lista:
			if linha.begins_with("]"):
				dentro_lista = false
			else:
				var m := re_lista.search(linha)
				if m != null:
					na_lista[m.get_string(1)] = true
			continue
		if linha.begins_with("static func valor_cond"):
			dentro_func = true
			continue
		if dentro_func:
			if linha.begins_with("static func"):
				dentro_func = false
				continue
			var m2 := re_caso.search(linha)
			if m2 != null:
				for rotulo in m2.get_string(1).split(","):
					nos_casos[rotulo.strip_edges().trim_prefix("\"").trim_suffix("\"")] = true
	if nos_casos.size() < 10 or na_lista.size() < 10:
		erros.append("conferencia de TIPOS_COND leu de menos (%d casos, %d na lista) — o parser quebrou" % [
			nos_casos.size(), na_lista.size()])
	for t in nos_casos.keys():
		if not na_lista.has(t):
			erros.append("valor_cond le '%s' e TIPOS_COND nao lista" % t)
	for t in na_lista.keys():
		if not nos_casos.has(t):
			erros.append("TIPOS_COND lista '%s' e valor_cond nao le" % t)

## Constante declarada e nunca lida.
##
## `PURGA_POR_ABATE := 0.006  ## cada abate adianta a carga` viveu no repositório
## com esse comentário e ZERO leitores: a carga da Purga só andava pelo relógio,
## então o acoplamento que o comentário anunciava era ficção. O linter dava
## `avisos=0`. Uma constante morta é sempre uma de duas coisas — uma promessa
## que ninguém cumpriu, ou lixo. As duas merecem aparecer.
func _checar_constantes_mortas() -> void:
	var decl := {}          # nome -> "arquivo:linha"
	var usos := {}          # nome -> quantas vezes aparece fora da declaração
	var re := RegEx.new()
	re.compile("^const ([A-Z][A-Z0-9_]*)\\s*(:=|:|=)")
	for caminho in _todos_gd():
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			continue
		var n := 0
		while not f.eof_reached():
			var linha := f.get_line()
			n += 1
			var limpa := linha.strip_edges()
			var m := re.search(limpa)
			if m != null:
				decl[m.get_string(1)] = "%s:%d" % [caminho, n]
				continue
			# conta os usos no código, ignorando comentário e texto entre aspas
			var corpo := _sem_strings(limpa)
			var c := corpo.find("#")
			if c >= 0:
				corpo = corpo.substr(0, c)
			for nome in decl.keys():
				if _cita(corpo, str(nome)):
					usos[nome] = int(usos.get(nome, 0)) + 1
	# segunda passada: uma constante pode ser usada ANTES de ser declarada no
	# arquivo, ou por outro arquivo lido antes dela
	for caminho in _todos_gd():
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			continue
		while not f.eof_reached():
			var limpa := f.get_line().strip_edges()
			if re.search(limpa) != null:
				continue
			var corpo := _sem_strings(limpa)
			var c := corpo.find("#")
			if c >= 0:
				corpo = corpo.substr(0, c)
			for nome in decl.keys():
				if _cita(corpo, str(nome)):
					usos[nome] = int(usos.get(nome, 0)) + 1
	for nome in decl.keys():
		if int(usos.get(nome, 0)) == 0:
			erros.append("%s constante declarada e nunca lida: %s" % [decl[nome], nome])

## Palavra inteira: `PURGA_DANO` não pode contar como uso de `PURGA_DAN`.
func _cita(texto: String, nome: String) -> bool:
	var i := texto.find(nome)
	while i >= 0:
		var antes := "" if i == 0 else texto[i - 1]
		var fim := i + nome.length()
		var depois := "" if fim >= texto.length() else texto[fim]
		var borda_ok := func(c: String) -> bool:
			return c == "" or not (c == "_" or c.to_lower() != c.to_upper() or c.is_valid_int())
		if borda_ok.call(antes) and borda_ok.call(depois):
			return true
		i = texto.find(nome, i + 1)
	return false

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
