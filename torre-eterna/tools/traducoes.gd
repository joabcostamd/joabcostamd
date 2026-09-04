extends SceneTree

## O PORTÃO DAS TRADUÇÕES.
##
## Traduzir para vinte idiomas é fácil de começar e impossível de manter no olho:
## são 1.094 chaves de interface mais 1.147 textos de conteúdo, vezes dezoito
## idiomas — quarenta mil textos. Nenhuma pessoa confere isso lendo.
##
## Então este arquivo confere. Ele NÃO julga a qualidade da tradução (isso é
## trabalho humano); ele julga o que dá para julgar por máquina, que é
## justamente onde os defeitos caros moram:
##
##   1. CHAVE FALTANDO. Sai a chave crua na tela — "cfg_repouso_dica" no lugar de
##      uma frase. É o defeito mais visível e o mais fácil de deixar passar,
##      porque só aparece naquele idioma, naquela tela.
##
##   2. MARCADOR TROCADO. `{n}` virou `{count}`, ou sumiu, ou apareceu um a mais.
##      O texto sai com a chave literal no meio da frase — "faltam {n}" — ou
##      pior: some o número e a frase mente. Este é o defeito que uma revisão
##      humana MAIS deixa passar, porque a frase traduzida parece perfeita.
##
##   3. TEXTO VAZIO. Pior que faltar: a chave existe, o portão de completude
##      passa, e a tela fica em branco.
##
##   4. COMPRIMENTO ABSURDO. Alemão e russo são naturalmente mais longos que
##      português; três vezes mais longo, não. Isso é sinal de que o tradutor
##      respondeu com uma explicação em vez de uma tradução — e o texto vai
##      estourar a caixa que a varredura de layout aprovou.
##
##   5. RESTO DE MARCAÇÃO. Aspas curvas trocadas, `\\n` virado em "n", colchete
##      de BBCode desbalanceado.
##
## Uso:
##   godot --headless --path . -s res://tools/traducoes.gd
##   godot --headless --path . -s res://tools/traducoes.gd -- --exportar
##       grava data/i18n/_fonte.json com tudo o que precisa ser traduzido

const PASTA_IDIOMAS := "res://data/i18n/idiomas"
const PASTA_CONTEUDO := "res://data/i18n/conteudo"
## Acima disto, o texto traduzido é longo demais para a caixa que o desenho
## reservou. 3,0 é folgado de propósito: alemão e russo esticam de verdade.
const RAZAO_MAXIMA := 3.0
## Textos muito curtos ("de", "OK") estouram a razão por nada. Abaixo disto a
## regra de comprimento não vale.
const CURTO_DEMAIS := 12

var erros: Array = []
var avisos: Array = []

func _initialize() -> void:
	Dados.carregar(true)
	Txt.carregar_extras(true)
	var args := OS.get_cmdline_user_args()
	if args.has("--exportar"):
		_exportar()
		quit(0)
		return
	_conferir()
	print("===TRADUCOES===")
	print("  erros: %d" % erros.size())
	for e in erros:
		print("    ERRO: ", e)
	print("  avisos: %d" % avisos.size())
	for a in avisos.slice(0, 40):
		print("    aviso: ", a)
	if avisos.size() > 40:
		print("    ... e mais %d avisos" % (avisos.size() - 40))
	print("===STATUS=== ", "PASS" if erros.is_empty() else "FAIL")
	quit(0 if erros.is_empty() else 1)

# ------------------------------------------------------------------ exportar

## Escreve tudo o que precisa ser traduzido, com o texto fonte e a versão em
## inglês lado a lado. É o arquivo que um tradutor (pessoa ou máquina) recebe:
## sem ele, traduzir exigiria caçar texto em 24 arquivos de interface e 18 de
## conteúdo.
func _exportar() -> void:
	var ui := {}
	for chave in Txt.todas_as_chaves():
		var k := str(chave)
		ui[k] = {"pt": Txt.fonte(k), "en": Txt.em(k, "en")}
	var conteudo := _fonte_conteudo()
	var doc := {
		"_nota": "Gerado por tools/traducoes.gd --exportar. NAO editar a mao.",
		"idiomas": Array(Idiomas.codigos()),
		"interface": ui,
		"conteudo": conteudo,
	}
	var f := FileAccess.open("res://data/i18n/_fonte.json", FileAccess.WRITE)
	if f == null:
		print("nao consegui gravar _fonte.json")
		return
	f.store_string(JSON.stringify(doc, " ", false))
	f.close()
	print("interface: %d chaves | conteudo: %d textos" % [ui.size(), conteudo.size()])
	print("gravado em res://data/i18n/_fonte.json")

## Os campos de conteúdo que precisam de tradução, com a chave `arquivo:id.campo`
## que `Ux.txt` vai procurar. A lista de campos é a mesma que o validador de
## dados cobra — as duas não podem divergir, senão um cobra o que o outro não
## exporta.
const CAMPOS := ["nome", "desc", "descricao", "titulo", "lore", "dica", "autor",
	"verdade", "verdadeNome", "resetaTexto", "mantemTexto", "requisito",
	"texto", "subtitulo"]

func _fonte_conteudo() -> Dictionary:
	var fora := {}
	var d := DirAccess.open("res://data")
	if d == null:
		return fora
	d.list_dir_begin()
	var arquivo := d.get_next()
	while arquivo != "":
		if arquivo.ends_with(".json") and not arquivo.begins_with("_"):
			var f := FileAccess.open("res://data/" + arquivo, FileAccess.READ)
			if f != null:
				var bruto = JSON.parse_string(f.get_as_text())
				f.close()
				_varrer(bruto, arquivo, fora)
		arquivo = d.get_next()
	d.list_dir_end()
	return fora

func _varrer(o, arquivo: String, fora: Dictionary) -> void:
	if o is Dictionary:
		var dd: Dictionary = o
		var id := str(dd.get("id", ""))
		if id != "":
			for campo in CAMPOS:
				var c := str(campo)
				if not (dd.get(c, null) is String):
					continue
				var pt := str(dd[c])
				# a paleta das eras tem uma chave "texto" que é uma COR
				if pt.begins_with("#") or pt == "":
					continue
				fora["%s:%s.%s" % [arquivo, id, c]] = {
					"pt": pt, "en": str(dd.get(c + "En", "")),
				}
		for v in dd.values():
			_varrer(v, arquivo, fora)
	elif o is Array:
		for v2 in o:
			_varrer(v2, arquivo, fora)

# ------------------------------------------------------------------ conferir

## O MESMO TEXTO FONTE PRECISA VIRAR O MESMO TEXTO TRADUZIDO.
##
## Esta conferência nasceu de um achado real: o vietnamita traduzia "carta" como
## "thẻ" em setenta e cinco lugares e como "lá bài" em sete, e "Singularidade"
## de dois jeitos diferentes. Nada no portão pegava — completude, marcadores,
## comprimento e formatação estavam todos verdes, e mesmo assim o jogo falava
## duas línguas dentro da mesma língua.
##
## A regra é exata e não depende de heurística: cinquenta e três textos fonte
## aparecem em mais de uma chave (a mesma frase de condição serve conquista e
## codex, por exemplo). Se duas chaves têm o MESMO português, elas têm que ter a
## mesma tradução — não é questão de estilo, é a mesma frase.
##
## O que ela NÃO cobre, e vale dizer: um termo que aparece dentro de frases
## diferentes ("cinquenta cartas" e "carta lendária") não é comparável assim,
## porque línguas flexionam. Esse caso continua sendo trabalho de revisão humana.
func _conferir_coerencia(cod: String, ui: Dictionary, ct: Dictionary,
		chaves_ui: Array, fonte_conteudo: Dictionary) -> void:
	var por_fonte := {}
	for chave in chaves_ui:
		var k := str(chave)
		var pt := Txt.fonte(k).strip_edges()
		if pt.length() < 3 or not ui.has(k):
			continue
		if not por_fonte.has(pt):
			por_fonte[pt] = {}
		por_fonte[pt][str(ui[k])] = k
	for chave2 in fonte_conteudo.keys():
		var k2 := str(chave2)
		var pt2 := str((fonte_conteudo[k2] as Dictionary).get("pt", "")).strip_edges()
		if pt2.length() < 3 or not ct.has(k2):
			continue
		if not por_fonte.has(pt2):
			por_fonte[pt2] = {}
		por_fonte[pt2][str(ct[k2])] = k2
	for pt3 in por_fonte.keys():
		var variantes: Dictionary = por_fonte[pt3]
		if variantes.size() > 1:
			avisos.append("%s: \"%s\" tem %d traduções diferentes (%s)" % [
				cod, str(pt3).substr(0, 34), variantes.size(),
				str(variantes.values()).substr(0, 60)])

func _conferir() -> void:
	var chaves_ui := Txt.todas_as_chaves()
	var fonte_conteudo := _fonte_conteudo()
	var traduzir := []
	for c in Idiomas.codigos():
		var cod := str(c)
		if cod != Idiomas.FONTE and cod != Idiomas.PONTE:
			traduzir.append(cod)

	# A FONTE PRECISA ESTAR COMPLETA ANTES DE QUALQUER TRADUÇÃO. Traduzir a
	# partir de um texto que falta em inglês produz dezoito buracos iguais.
	var sem_en: Array = []
	for chave in chaves_ui:
		if Txt.em(str(chave), "en").strip_edges() == "":
			sem_en.append(str(chave))
	if not sem_en.is_empty():
		erros.append("interface sem inglês (%d): %s" % [sem_en.size(), str(sem_en.slice(0, 6))])

	for cod in traduzir:
		_conferir_idioma(str(cod), chaves_ui, fonte_conteudo)

func _conferir_idioma(cod: String, chaves_ui: Array, fonte_conteudo: Dictionary) -> void:
	var arq_ui := "%s/%s.json" % [PASTA_IDIOMAS, cod]
	var arq_ct := "%s/%s.json" % [PASTA_CONTEUDO, cod]
	var ui := _ler(arq_ui)
	var ct := _ler(arq_ct)

	# Idioma ainda não traduzido é AVISO, não erro: o portão precisa passar
	# enquanto a tradução está em andamento, senão ele bloqueia o próprio
	# trabalho que existe para proteger. O que é erro é tradução ERRADA.
	var tem_irmao := Idiomas.IRMAOS.has(cod) \
		and (FileAccess.file_exists("%s/%s.json" % [PASTA_IDIOMAS, str(Idiomas.IRMAOS[cod])]))
	if ui.is_empty() and ct.is_empty() and not tem_irmao:
		if Idiomas.esta_pronto(cod):
			erros.append("%s: declarado pronto e sem nenhuma tradução" % cod)
		else:
			avisos.append("%s: ainda não traduzido" % cod)
		return

	# O IRMÃO NA CADEIA NÃO É BURACO, É O DESENHO FUNCIONANDO.
	#
	# Espanhol da América Latina que caia no espanhol da Espanha está CERTO: são
	# a mesma língua, e a frase da Espanha é melhor do que uma frase inglesa no
	# meio da tela. Cobrar tradução própria para cada chave de `es-419` seria
	# cobrar 2.357 textos que a cadeia já resolve — e o resultado seriam duas
	# traduções quase idênticas mantidas em paralelo, divergindo com o tempo.
	#
	# O que continua sendo erro é a chave que não existe em NENHUM dos dois.
	var irmao := str(Idiomas.IRMAOS.get(cod, ""))
	var ui_irmao := _ler("%s/%s.json" % [PASTA_IDIOMAS, irmao]) if irmao != "" else {}
	var ct_irmao := _ler("%s/%s.json" % [PASTA_CONTEUDO, irmao]) if irmao != "" else {}

	var faltando := 0
	for chave in chaves_ui:
		var k := str(chave)
		var pt := Txt.fonte(k)
		if pt.strip_edges() == "":
			continue
		if not ui.has(k):
			if not ui_irmao.has(k):
				faltando += 1
			continue
		_conferir_texto(cod, "interface", k, pt, str(ui[k]))
	# Completude só é ERRO em idioma declarado pronto. Ver `Idiomas.esta_pronto`.
	var exigir := Idiomas.esta_pronto(cod)
	if faltando > 0:
		if exigir:
			erros.append("%s: %d chaves de interface faltando" % [cod, faltando])
		else:
			avisos.append("%s: %d de %d chaves de interface traduzidas" % [
				cod, chaves_ui.size() - faltando, chaves_ui.size()])

	var faltando_ct := 0
	for chave2 in fonte_conteudo.keys():
		var k2 := str(chave2)
		var pt2 := str((fonte_conteudo[k2] as Dictionary).get("pt", ""))
		if pt2.strip_edges() == "":
			continue
		if not ct.has(k2):
			if not ct_irmao.has(k2):
				faltando_ct += 1
			continue
		_conferir_texto(cod, "conteúdo", k2, pt2, str(ct[k2]))
	if faltando_ct > 0:
		if exigir:
			erros.append("%s: %d textos de conteúdo faltando" % [cod, faltando_ct])
		else:
			avisos.append("%s: %d de %d textos de conteúdo traduzidos" % [
				cod, fonte_conteudo.size() - faltando_ct, fonte_conteudo.size()])

	# SOBRA TAMBÉM É DEFEITO: chave que não existe mais na fonte é tradução de
	# texto apagado, e ela esconde o fato de que o idioma está desatualizado.
	var conhecidas := {}
	for c3 in chaves_ui:
		conhecidas[str(c3)] = true
	var sobra: Array = []
	for k3 in ui.keys():
		if not conhecidas.has(str(k3)):
			sobra.append(str(k3))
	if not sobra.is_empty():
		avisos.append("%s: %d chaves de interface que não existem mais: %s" % [
			cod, sobra.size(), str(sobra.slice(0, 4))])

	_conferir_coerencia(cod, ui, ct, chaves_ui, fonte_conteudo)

func _ler(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return {}
	var r = JSON.parse_string(f.get_as_text())
	f.close()
	if not (r is Dictionary):
		erros.append("%s não é um objeto JSON" % caminho)
		return {}
	return r

## As quatro conferências que valem por máquina.
func _conferir_texto(cod: String, onde: String, chave: String, pt: String, tr: String) -> void:
	var rotulo := "%s/%s/%s" % [cod, onde, chave]

	if tr.strip_edges() == "":
		erros.append("%s: vazio" % rotulo)
		return

	# MARCADOR. É o defeito que uma revisão humana mais deixa passar, porque a
	# frase traduzida parece perfeita — e aí sai "faltam {n}" na tela, ou o
	# número some e a frase mente.
	var a := _marcadores(pt)
	var b := _marcadores(tr)
	if a != b:
		erros.append("%s: marcadores %s viraram %s" % [rotulo, str(a), str(b)])

	# BBCODE desbalanceado quebra o texto inteiro a partir do erro.
	if pt.count("[") == pt.count("]") and tr.count("[") != tr.count("]"):
		erros.append("%s: colchete de marcação desbalanceado" % rotulo)

	# QUEBRA DE LINHA literal virou a letra "n" — acontece quando a tradução
	# passa por uma ferramenta que não escapa a barra.
	if pt.contains("\\n") and not tr.contains("\\n"):
		avisos.append("%s: perdeu a quebra de linha" % rotulo)

	if pt.length() >= CURTO_DEMAIS:
		var razao := float(tr.length()) / float(pt.length())
		if razao > RAZAO_MAXIMA:
			avisos.append("%s: %.1fx mais longo que o original (%d -> %d)" % [
				rotulo, razao, pt.length(), tr.length()])

## Os `{marcadores}` de um texto, ordenados. A ordem sai da conta de propósito:
## línguas mudam a ordem das palavras, e "{a} de {b}" virar "{b} para {a}" é
## tradução certa, não defeito. O que não pode é sumir, sobrar ou trocar de nome.
func _marcadores(s: String) -> Array:
	var fora: Array = []
	var i := 0
	while true:
		var ab := s.find("{", i)
		if ab < 0:
			break
		var fe := s.find("}", ab)
		if fe < 0:
			break
		fora.append(s.substr(ab, fe - ab + 1))
		i = fe + 1
	fora.sort()
	return fora
