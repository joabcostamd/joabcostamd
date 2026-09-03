extends Node
## Progresso e opções do jogador, gravados em user://progresso.save.

const CAMINHO := "user://progresso.save"

## Idiomas com tradução completa. A ordem é a que aparece nas opções.
const IDIOMAS := ["pt", "en", "es", "fr", "de", "it", "nl", "pl", "sv", "da",
                  "nb", "fi", "cs", "hu", "ro", "tr", "ru", "uk", "ja", "ko", "zh"]
const NOMES_IDIOMAS := {
    "pt": "Português", "en": "English", "es": "Español", "fr": "Français",
    "de": "Deutsch", "it": "Italiano", "nl": "Nederlands", "pl": "Polski",
    "sv": "Svenska", "da": "Dansk", "nb": "Norsk", "fi": "Suomi",
    "cs": "Čeština", "hu": "Magyar", "ro": "Română", "tr": "Türkçe",
    "ru": "Русский", "uk": "Українська", "ja": "日本語", "ko": "한국어",
    "zh": "中文",
}

signal fase_concluida(id: int, estrelas: int)
signal opcoes_mudaram()

var fases := {}          # id (String) -> {"estrelas": int, "tempo": float}
var opcoes := {
    "volume_musica": 0.5,
    "volume_efeitos": 0.8,
    "modo_relaxado": false,
    "marcar_erro_automatico": true,
    "tema_claro": false,
    "alto_contraste": false,
    "mostrar_tempo": true,
    "travar_arraste": true,
    "fundo_animado": true,
    "idioma": "",          # vazio = segue o idioma do sistema
}

func _ready() -> void:
    carregar()
    aplicar_aparencia()

## Repassa as opções de aparência para o estilo, que é quem pinta tudo.
func aplicar_aparencia() -> void:
    Estilo.usar_tema(bool(opcoes["tema_claro"]), bool(opcoes["alto_contraste"]))
    aplicar_idioma()

## Idioma salvo, ou o do sistema quando o jogador nunca escolheu.
func aplicar_idioma() -> void:
    var escolhido := str(opcoes.get("idioma", ""))
    if escolhido == "":
        escolhido = OS.get_locale_language()
    if not escolhido in IDIOMAS:
        escolhido = "en"
    TranslationServer.set_locale(escolhido)

func carregar() -> void:
    if not FileAccess.file_exists(CAMINHO):
        return
    var arquivo := FileAccess.open(CAMINHO, FileAccess.READ)
    if arquivo == null:
        return
    var dados = JSON.parse_string(arquivo.get_as_text())
    arquivo.close()
    if typeof(dados) != TYPE_DICTIONARY:
        return
    fases = dados.get("fases", {})
    for chave in opcoes.keys():
        if dados.get("opcoes", {}).has(chave):
            opcoes[chave] = dados["opcoes"][chave]

func salvar() -> void:
    var arquivo := FileAccess.open(CAMINHO, FileAccess.WRITE)
    if arquivo == null:
        push_error("Não foi possível gravar o progresso")
        return
    arquivo.store_string(JSON.stringify({"fases": fases, "opcoes": opcoes}))
    arquivo.close()

func registrar(id: int, estrelas: int, tempo: float) -> void:
    var chave := str(id)
    var anterior: Dictionary = fases.get(chave, {"estrelas": 0, "tempo": 0.0})
    var melhor_tempo: float = anterior["tempo"]
    if melhor_tempo <= 0.0 or tempo < melhor_tempo:
        melhor_tempo = tempo
    fases[chave] = {
        "estrelas": maxi(int(anterior["estrelas"]), estrelas),
        "tempo": melhor_tempo,
    }
    salvar()
    fase_concluida.emit(id, estrelas)

func resolvida(id: int) -> bool:
    return fases.has(str(id))

func estrelas_de(id: int) -> int:
    return int(fases.get(str(id), {}).get("estrelas", 0))

func tempo_de(id: int) -> float:
    return float(fases.get(str(id), {}).get("tempo", 0.0))

## Dentro de um capítulo o caminho é linear: cada fase abre a seguinte.
## A primeira fase de um capítulo depende do capítulo estar aberto.
func desbloqueada(id: int) -> bool:
    if id <= 1:
        return true
    var indice := Catalogo.capitulo_da_fase(id)
    var do_capitulo: Array = Catalogo.capitulos[indice]["fases"]
    if not do_capitulo.is_empty() and int(do_capitulo[0]) == id:
        return capitulo_aberto(indice)
    return resolvida(id - 1)

func resolvidas_do_capitulo(indice: int) -> int:
    if indice < 0 or indice >= Catalogo.capitulos.size():
        return 0
    var total := 0
    for numero in Catalogo.capitulos[indice]["fases"]:
        if resolvida(int(numero)):
            total += 1
    return total

## Um capítulo abre quando faltam no máximo duas fases do anterior — assim
## uma fase difícil não tranca o jogador, mas ainda exige quase terminar.
func capitulo_aberto(indice: int) -> bool:
    if indice <= 0:
        return true
    var anterior: Array = Catalogo.capitulos[indice - 1]["fases"]
    return resolvidas_do_capitulo(indice - 1) >= maxi(1, anterior.size() - 2)

func total_estrelas() -> int:
    var soma := 0
    for chave in fases:
        soma += int(fases[chave]["estrelas"])
    return soma

func total_resolvidas() -> int:
    return fases.size()

func ajustar(chave: String, valor) -> void:
    opcoes[chave] = valor
    if chave in ["tema_claro", "alto_contraste", "idioma"]:
        aplicar_aparencia()
    salvar()
    opcoes_mudaram.emit()

func apagar_tudo() -> void:
    fases.clear()
    salvar()
