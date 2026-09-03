extends RefCounted
class_name Conquistas
## Conquistas derivadas do progresso, sem estado próprio.
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

    lista.append(_nova("primeira", "Primeira imagem", "Revele a sua primeira imagem.", 1, resolvidas))
    lista.append(_nova("dez", "Colecionador", "Revele 10 imagens.", 10, resolvidas))
    lista.append(_nova("cinquenta", "Galeria cheia", "Revele 50 imagens.", 50, resolvidas))
    lista.append(_nova("cem", "Metade do caminho", "Revele 100 imagens.", 100, resolvidas))
    lista.append(_nova("duzentas", "Obra completa", "Revele todas as 200 imagens.", 200, resolvidas))

    lista.append(_nova("estrelas100", "Cem estrelas", "Junte 100 estrelas.", 100, estrelas))
    lista.append(_nova("estrelas300", "Trezentas estrelas", "Junte 300 estrelas.", 300, estrelas))
    lista.append(_nova("estrelas600", "Céu estrelado", "Junte todas as 600 estrelas.", 600, estrelas))

    lista.append(_nova("limpo10", "Mão firme", "Termine 10 fases sem perder vida.", 10, sem_erro))
    lista.append(_nova("perfeito25", "Perfeccionista", "Faça 3 estrelas em 25 fases.", 25, perfeitas))
    lista.append(_nova("perfeito100", "Impecável", "Faça 3 estrelas em 100 fases.", 100, perfeitas))

    for i in Catalogo.capitulos.size():
        var capitulo: Dictionary = Catalogo.capitulos[i]
        lista.append(_nova("cap%d" % i, "Capítulo %d completo" % (i + 1),
            "Resolva todas as fases de %s." % capitulo["nome"],
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
