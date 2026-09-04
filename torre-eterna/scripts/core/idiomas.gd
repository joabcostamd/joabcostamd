class_name Idiomas
extends RefCounted

## OS VINTE IDIOMAS, NUM LUGAR SÓ.
##
## O jogo falava dois. Passar para vinte não é multiplicar arquivos: é decidir,
## de uma vez, o que um idioma É. Cada entrada aqui carrega o código interno, o
## nome NA PRÓPRIA LÍNGUA (ninguém procura "German" numa lista, procura
## "Deutsch"), o código que a Steam usa — que não é o ISO, e essa diferença já
## derrubou muita página de loja —, e as duas coisas que mudam o desenho da tela:
## o separador decimal e a fonte de reserva.
##
## A ORDEM É POR PÚBLICO, NÃO POR ALFABETO. Inglês, chinês simplificado, russo,
## espanhol e português somam a maior parte das contas da Steam; um seletor em
## ordem alfabética esconderia o chinês simplificado — o segundo maior público do
## mundo — atrás de "Čeština".

## Código interno -> tudo o que o jogo precisa saber sobre o idioma.
##
## `steam` é o código da API da Steam, que tem casos que não seguem norma
## nenhuma: chinês simplificado é `schinese`, coreano é `koreana`, português do
## Brasil é `brazilian` e espanhol da América Latina é `latam`. Escrever `zh-CN`
## ali faz a loja ignorar o idioma em silêncio.
const LISTA := [
	{"cod": "en",      "nome": "English",              "steam": "english",    "dec": ".", "mil": ","},
	{"cod": "zh-Hans", "nome": "简体中文",               "steam": "schinese",   "dec": ".", "mil": ","},
	{"cod": "ru",      "nome": "Русский",              "steam": "russian",    "dec": ",", "mil": " "},
	{"cod": "es-ES",   "nome": "Español (España)",     "steam": "spanish",    "dec": ",", "mil": "."},
	{"cod": "pt-BR",   "nome": "Português (Brasil)",   "steam": "brazilian",  "dec": ",", "mil": "."},
	{"cod": "de",      "nome": "Deutsch",              "steam": "german",     "dec": ",", "mil": "."},
	{"cod": "fr",      "nome": "Français",             "steam": "french",     "dec": ",", "mil": " "},
	{"cod": "ja",      "nome": "日本語",                 "steam": "japanese",   "dec": ".", "mil": ","},
	{"cod": "ko",      "nome": "한국어",                 "steam": "koreana",    "dec": ".", "mil": ","},
	{"cod": "pl",      "nome": "Polski",               "steam": "polish",     "dec": ",", "mil": " "},
	{"cod": "tr",      "nome": "Türkçe",               "steam": "turkish",    "dec": ",", "mil": "."},
	{"cod": "zh-Hant", "nome": "繁體中文",               "steam": "tchinese",   "dec": ".", "mil": ","},
	{"cod": "it",      "nome": "Italiano",             "steam": "italian",    "dec": ",", "mil": "."},
	{"cod": "uk",      "nome": "Українська",           "steam": "ukrainian",  "dec": ",", "mil": " "},
	{"cod": "cs",      "nome": "Čeština",              "steam": "czech",      "dec": ",", "mil": " "},
	{"cod": "th",      "nome": "ไทย",                   "steam": "thai",       "dec": ".", "mil": ","},
	{"cod": "es-419",  "nome": "Español (LatAm)",      "steam": "latam",      "dec": ".", "mil": ","},
	{"cod": "nl",      "nome": "Nederlands",           "steam": "dutch",      "dec": ",", "mil": "."},
	{"cod": "hu",      "nome": "Magyar",               "steam": "hungarian",  "dec": ",", "mil": " "},
	{"cod": "vi",      "nome": "Tiếng Việt",           "steam": "vietnamese", "dec": ",", "mil": "."},
]

## O idioma em que o jogo é ESCRITO. Todo texto nasce aqui e é traduzido a partir
## daqui — e é para cá que a busca volta quando uma tradução falta.
const FONTE := "pt-BR"
## A ponte. Nem todo tradutor lê português; o inglês é a segunda rede de
## segurança antes de a chave crua aparecer na tela.
const PONTE := "en"

static func codigos() -> PackedStringArray:
	var v := PackedStringArray()
	for d in LISTA:
		v.append(str((d as Dictionary)["cod"]))
	return v

static func existe(cod: String) -> bool:
	return not por_cod(cod).is_empty()

static func por_cod(cod: String) -> Dictionary:
	for d in LISTA:
		if str((d as Dictionary)["cod"]) == cod:
			return d
	return {}

static func nome(cod: String) -> String:
	return str(por_cod(cod).get("nome", cod))

static func steam(cod: String) -> String:
	return str(por_cod(cod).get("steam", ""))

## Separador decimal e de milhar do idioma. O jogo mostra número o tempo todo, e
## "1.234,56" em alemão contra "1,234.56" em inglês não é preciosismo: trocados,
## o jogador lê a grandeza errada por uma ordem de mil.
static func decimal(cod: String) -> String:
	return str(por_cod(cod).get("dec", "."))

static func milhar(cod: String) -> String:
	return str(por_cod(cod).get("mil", ","))

## A CADEIA DE BUSCA de um idioma: ele mesmo, depois as variantes irmãs, depois
## a ponte, depois a fonte.
##
## Espanhol da América Latina que não tenha uma frase cai no espanhol da Espanha
## antes de cair no inglês — são a mesma língua, e a frase da Espanha é sempre
## melhor do que uma frase em inglês no meio da tela. Vale igual para os dois
## chineses e para os dois portugueses.
const IRMAOS := {
	"es-419": "es-ES", "es-ES": "es-419",
	"zh-Hant": "zh-Hans", "zh-Hans": "zh-Hant",
	"pt-BR": "pt-PT", "pt-PT": "pt-BR",
}

static func cadeia(cod: String) -> PackedStringArray:
	var v := PackedStringArray()
	if cod != "":
		v.append(cod)
	var irmao := str(IRMAOS.get(cod, ""))
	if irmao != "" and not v.has(irmao):
		v.append(irmao)
	if not v.has(PONTE):
		v.append(PONTE)
	if not v.has(FONTE):
		v.append(FONTE)
	return v

## O idioma que o sistema operacional pede, reduzido ao que o jogo fala.
##
## `OS.get_locale()` devolve coisas como "pt_BR", "zh_CN", "zh_TW", "es_MX".
## Casar isso com os códigos daqui exige tratar o script e a região na ordem
## certa: "zh_TW" tem que virar `zh-Hant` e não `zh-Hans`, senão o público de
## Taiwan e Hong Kong abre o jogo em caracteres simplificados.
static func do_sistema() -> String:
	if DisplayServer.get_name() == "headless":
		return FONTE
	var bruto := OS.get_locale().replace("_", "-")
	var baixo := bruto.to_lower()
	if baixo.begins_with("zh"):
		for marca in ["hant", "tw", "hk", "mo"]:
			if baixo.contains(marca):
				return "zh-Hant"
		return "zh-Hans"
	if baixo.begins_with("pt"):
		return "pt-BR"
	if baixo.begins_with("es"):
		return "es-ES" if baixo.contains("es") and (baixo.ends_with("es") or baixo == "es") else "es-419"
	# Casamento exato primeiro (pega "es-ES"), depois só a língua (pega "de-AT").
	for d in LISTA:
		if str((d as Dictionary)["cod"]).to_lower() == baixo:
			return str((d as Dictionary)["cod"])
	var lingua := baixo.split("-")[0]
	for d2 in LISTA:
		if str((d2 as Dictionary)["cod"]).to_lower().split("-")[0] == lingua:
			return str((d2 as Dictionary)["cod"])
	return PONTE
