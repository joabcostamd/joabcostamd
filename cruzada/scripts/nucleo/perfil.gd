extends RefCounted
class_name Perfil
## O que sobrevive entre sessões: temas destravados, tema escolhido e as contas
## que destravam os que faltam.
##
## Gravação atômica — escreve num arquivo temporário, fecha, e só então renomeia.
## Um save cortado no meio por queda de energia não pode virar perfil zerado.

const CAMINHO := "user://cruzada.save"
const VERSAO := 1

var tema := Temas.PADRAO
var quatro_cores := true
var escala_de_cinza := false
var mesas_jogadas := 0
var runs_vencidas := 0
var destravados := {}          ## id do tema -> true
var maior_evento := 0
## A dificuldade escolhida fica no perfil, não na run: quem escolheu Estufa não
## quer reescolher a cada partida.
var desafio: Desafio = Desafio.new()
## id da conquista → true. Uma vez conquistada, nunca some.
var conquistas := {}

func _init() -> void:
    ## Os temas de saída entram sempre, mesmo num save antigo: fundo claro é
    ## afordância de acessibilidade e não pode depender de conquista.
    for i in Temas.total():
        if Temas.liberado_de_saida(i):
            destravados[str(Temas.dados(i)["id"])] = true

func destravado(indice: int) -> bool:
    return destravados.has(str(Temas.dados(indice)["id"]))

func destravar(id: String) -> bool:
    if destravados.has(id):
        return false
    destravados[id] = true
    return true

## Confere as condições de desbloqueio contra o estado da run. Devolve os ids
## que acabaram de abrir, para a tela poder anunciar.
##
## As condições vêm do livro-razão (§3e) e a ordem delas é deliberada: o Neon é o
## último porque é o mais impressionante nos primeiros dez segundos e o mais
## cansativo no minuto vinte. Tema que grita "uau" vale mais como prêmio que
## como padrão.
## As conquistas que acabaram de cair. Junta as marcas da run com as do perfil —
## algumas olham para uma partida, outras para tudo o que já foi jogado.
func conferir_conquistas(run: Run) -> Array[String]:
    var marcas := run.marcas.duplicate()
    marcas["runs_vencidas"] = runs_vencidas
    marcas["maior_evento"] = maxi(maior_evento, int(marcas.get("maior_evento", 0)))
    marcas["mesas_jogadas"] = mesas_jogadas
    var novas := Conquistas.conferir(marcas, conquistas)
    for id in novas:
        conquistas[id] = true
    return novas

func quantas_conquistas() -> int:
    return conquistas.size()

func conferir(run: Run, ultimo_relato := {}) -> Array[String]:
    var novos: Array[String] = []
    if run.venceu and destravar("casino"):
        novos.append("casino")
    if mesas_jogadas >= 25 and destravar("meianoite"):
        novos.append("meianoite")
    if run.categorias_feitas.has(Maos.SEQ_COR) and destravar("veludo"):
        novos.append("veludo")
    ## "Vença no Tabuleiro 3" espera o dial de dificuldade, que ainda não existe.
    ## Até lá a condição é chegar à rodada 6 — o mesmo nicho de "prova que já
    ## sabe jogar", sem inventar um sistema para justificar um prêmio.
    if run.rodada >= Metas.RODADAS and destravar("ameixa"):
        novos.append("ameixa")
    if Run.e_cruzada_do_centro(ultimo_relato) and destravar("neon"):
        novos.append("neon")
    return novos

# ────────────────────────────── gravar e ler ──────────────────────────────

func para_dicionario() -> Dictionary:
    return {
        "versao": VERSAO, "tema": tema, "quatro_cores": quatro_cores,
        "escala_de_cinza": escala_de_cinza, "mesas_jogadas": mesas_jogadas,
        "runs_vencidas": runs_vencidas, "maior_evento": maior_evento,
        "destravados": destravados.keys(), "desafio": desafio.para_dicionario(),
        "conquistas": conquistas.keys(),
    }

func de_dicionario(d: Dictionary) -> void:
    tema = clampi(int(d.get("tema", Temas.PADRAO)), 0, Temas.total() - 1)
    quatro_cores = bool(d.get("quatro_cores", true))
    escala_de_cinza = bool(d.get("escala_de_cinza", false))
    mesas_jogadas = int(d.get("mesas_jogadas", 0))
    runs_vencidas = int(d.get("runs_vencidas", 0))
    maior_evento = int(d.get("maior_evento", 0))
    for id: String in d.get("destravados", []):
        destravados[str(id)] = true
    if typeof(d.get("desafio")) == TYPE_DICTIONARY:
        desafio = Desafio.de_dicionario(d["desafio"])
    for id: String in d.get("conquistas", []):
        conquistas[str(id)] = true

func gravar(caminho := CAMINHO) -> bool:
    var temporario := caminho + ".tmp"
    var f := FileAccess.open(temporario, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(JSON.stringify(para_dicionario(), "  "))
    f.close()
    ## Só renomeia depois de fechar. Renomear é atômico; escrever não é.
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporario),
                                     ProjectSettings.globalize_path(caminho)) == OK

static func ler(caminho := CAMINHO) -> Perfil:
    var p := Perfil.new()
    if not FileAccess.file_exists(caminho):
        return p
    var f := FileAccess.open(caminho, FileAccess.READ)
    if f == null:
        return p
    var texto := f.get_as_text()
    f.close()
    ## `JSON.new().parse()` em vez de `JSON.parse_string()`: o segundo despeja um
    ## erro no console, e save corrompido é caso previsto, não incidente.
    var json := JSON.new()
    if json.parse(texto) != OK or typeof(json.data) != TYPE_DICTIONARY:
        ## Save corrompido nunca trava o jogo: vira perfil zerado e a partida começa.
        push_warning("perfil ilegível em %s — começando do zero" % caminho)
        return p
    p.de_dicionario(json.data)
    return p
