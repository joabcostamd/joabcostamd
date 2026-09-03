extends RefCounted
class_name Conquistas
## Conquistas derivadas do progresso, sem estado próprio.
##
## Os textos vêm de TranslationServer.translate e não de tr(): tr() é método
## de Node, e estas funções são estáticas.
##
## Nada é gravado além do que já existe: cada conquista é uma pergunta feita
## ao progresso. Assim elas nunca ficam dessincronizadas, e apagar o progresso
## apaga as conquistas junto, como o jogador espera.

class Conquista:
    var chave: String
    var nome: String
    var descricao: String
    var meta: int
    var atual: int

    func concluida() -> bool:
        return atual >= meta

    func fracao() -> float:
        return clampf(float(atual) / float(maxi(meta, 1)), 0.0, 1.0)

static func todas() -> Array[Conquista]:
    var lista: Array[Conquista] = []
    var resolvidas := Progresso.total_resolvidas()
    var estrelas := Progresso.total_estrelas()
    var perfeitas := 0
    var sem_erro := 0
    for chave in Progresso.fases:
        var quantas := int(Progresso.fases[chave]["estrelas"])
        if quantas >= 3:
            perfeitas += 1
        if quantas >= 2:
            sem_erro += 1

    var total_fases := Catalogo.fases.size()
    var total_estrelas := total_fases * 3

    var metas_imagens := [[1, "CONQ_N_PRIMEIRA"], [10, "CONQ_N_COLECIONADOR"],
        [50, "CONQ_N_GALERIA"], [int(total_fases / 2.0), "CONQ_N_METADE"],
        [total_fases, "CONQ_N_OBRA"]]
    for meta in metas_imagens:
        lista.append(_nova("img%d" % int(meta[0]), TranslationServer.translate(meta[1]),
            TranslationServer.translate("CONQ_D_REVELE") % int(meta[0]), int(meta[0]), resolvidas))

    var metas_estrelas := [[100, "CONQ_N_CEM"], [300, "CONQ_N_TREZENTAS"],
        [total_estrelas, "CONQ_N_CEU"]]
    for meta in metas_estrelas:
        lista.append(_nova("est%d" % int(meta[0]), TranslationServer.translate(meta[1]),
            TranslationServer.translate("CONQ_D_ESTRELAS") % int(meta[0]), int(meta[0]), estrelas))

    lista.append(_nova("limpo25", TranslationServer.translate("CONQ_N_MAO_FIRME"),
        TranslationServer.translate("CONQ_D_SEM_ERRO") % 25, 25, sem_erro))
    lista.append(_nova("perfeito25", TranslationServer.translate("CONQ_N_PERFEC"),
        TranslationServer.translate("CONQ_D_PERFEITO") % 25, 25, perfeitas))
    lista.append(_nova("perfeito100", TranslationServer.translate("CONQ_N_IMPECAVEL"),
        TranslationServer.translate("CONQ_D_PERFEITO") % 100, 100, perfeitas))

    for i in Catalogo.capitulos.size():
        var capitulo: Dictionary = Catalogo.capitulos[i]
        lista.append(_nova("cap%d" % i, TranslationServer.translate("CONQ_N_CAPITULO") % (i + 1),
            TranslationServer.translate("CONQ_D_CAPITULO") % capitulo["nome"],
            capitulo["fases"].size(), Progresso.resolvidas_do_capitulo(i)))
    return lista

static func concluidas() -> int:
    var total := 0
    for c in todas():
        if c.concluida():
            total += 1
    return total

static func _nova(chave: String, nome: String, descricao: String,
                  meta: int, atual: int) -> Conquista:
    var c := Conquista.new()
    c.chave = chave
    c.nome = nome
    c.descricao = descricao
    c.meta = meta
    c.atual = mini(atual, meta)
    return c
