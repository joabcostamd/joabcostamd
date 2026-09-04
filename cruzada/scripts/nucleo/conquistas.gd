extends RefCounted
class_name Conquistas
## As conquistas. Dados, e uma conta por linha.
##
## Elas existem para nomear o que o jogo já faz e o jogador ainda não notou. Uma
## conquista boa ensina uma regra: *A cruz total* diz que quatro linhas podem
## colher juntas, e quem a lê descobre um jogo que estava lá o tempo todo.
##
## Nenhuma delas pede grind. Não há "jogue 500 mesas" — contagem alta sem decisão
## nova é trabalho, não conquista, e o CRUZADA já mede quantas mesas foram
## jogadas para desbloquear tema.

## Onde a conta olha. Uma conquista por linha, e a linha diz o que ela mede.
enum {
    PERFIL,      ## acumulado entre runs: mesas, runs vencidas, maior colheita
    RUN,         ## o que aconteceu numa run: rodada alcançada, quase lá, build
    EVENTO,      ## o que uma colheita fez: grau, categoria, pontos
}

const LISTA: Array[Dictionary] = [
    # ── o loop, aprendido ──
    {"id": "primeira_colheita", "nome": "A primeira linha", "onde": EVENTO,
     "como": "colha uma linha", "chave": "colheitas", "alvo": 1},
    {"id": "dupla", "nome": "Cruzada", "onde": EVENTO,
     "como": "colha duas linhas de uma vez", "chave": "linhas_no_evento", "alvo": 2},
    {"id": "tripla", "nome": "Tripla", "onde": EVENTO,
     "como": "colha três linhas de uma vez", "chave": "linhas_no_evento", "alvo": 3},
    {"id": "cruz_total", "nome": "A cruz total", "onde": EVENTO,
     "como": "colha quatro linhas de uma vez", "chave": "linhas_no_evento", "alvo": 4},
    {"id": "cruz_do_centro", "nome": "O centro do tabuleiro", "onde": EVENTO,
     "como": "colha as quatro linhas que passam por C3",
     "chave": "cruzada_do_centro", "alvo": 1},

    # ── as mãos ──
    {"id": "quadra", "nome": "Quatro iguais", "onde": EVENTO,
     "como": "colha uma Quadra", "chave": "cat_7", "alvo": 1},
    {"id": "seq_cor", "nome": "Sequência de Cor", "onde": EVENTO,
     "como": "colha uma Sequência de Cor", "chave": "cat_8", "alvo": 1},
    {"id": "real", "nome": "Sequência Real", "onde": EVENTO,
     "como": "colha uma Sequência Real", "chave": "cat_9", "alvo": 1},
    {"id": "quina", "nome": "Cinco iguais", "onde": EVENTO,
     "como": "colha uma Quina — cinco cartas de mesmo valor",
     "chave": "cat_10", "alvo": 1},

    # ── o tamanho da coisa ──
    {"id": "tear_cheio", "nome": "O Tear no teto", "onde": RUN,
     "como": "leve o Tear ao teto numa mesa", "chave": "tear_maximo", "alvo": 8},
    {"id": "dez_mil", "nome": "Cinco dígitos", "onde": PERFIL,
     "como": "faça uma colheita de 10.000 pontos", "chave": "maior_evento",
     "alvo": 10000},
    {"id": "cem_mil", "nome": "Seis dígitos", "onde": PERFIL,
     "como": "faça uma colheita de 100.000 pontos", "chave": "maior_evento",
     "alvo": 100000},
    {"id": "dobro_da_meta", "nome": "Com folga", "onde": RUN,
     "como": "termine uma mesa com o dobro da meta", "chave": "razao_maxima",
     "alvo": 200},

    # ── a build ──
    {"id": "seis_selos", "nome": "O mapa", "onde": RUN,
     "como": "chegue a seis selos colados numa run", "chave": "selos", "alvo": 6},
    {"id": "doze_selos", "nome": "O bordado", "onde": RUN,
     "como": "chegue a doze selos colados numa run", "chave": "selos", "alvo": 12},
    {"id": "colecionador", "nome": "Cinco relíquias", "onde": RUN,
     "como": "carregue cinco relíquias na mesma run", "chave": "reliquias", "alvo": 5},
    {"id": "nivel_cinco", "nome": "Especialista", "onde": RUN,
     "como": "leve uma mão ao nível 5", "chave": "nivel_maximo", "alvo": 5},

    # ── a run ──
    {"id": "primeira_run", "nome": "As dezoito mesas", "onde": PERFIL,
     "como": "vença uma run inteira", "chave": "runs_vencidas", "alvo": 1},
    {"id": "sem_perder", "nome": "Sem gastar vida", "onde": RUN,
     "como": "vença uma run com as três vidas intactas", "chave": "run_limpa",
     "alvo": 1},
    {"id": "quase_la", "nome": "Por um fio", "onde": RUN,
     "como": "seja salvo pelo Quase lá", "chave": "quase_la", "alvo": 1},
    {"id": "fianca", "nome": "A dívida paga", "onde": RUN,
     "como": "receba uma colheita dobrada pela Fiança", "chave": "fianca_pagou",
     "alvo": 1},
    # ── a travessia: depois da rodada 6 o jogo não acaba ──
    {"id": "travessia", "nome": "A travessia", "onde": RUN,
     "como": "siga depois da rodada 6 e vença a rodada 7",
     "chave": "rodada_mais_funda", "alvo": 7},
    {"id": "travessia_10", "nome": "Rodada 10", "onde": RUN,
     "como": "chegue à rodada 10 da travessia", "chave": "rodada_mais_funda",
     "alvo": 10},
    {"id": "travessia_15", "nome": "Rodada 15", "onde": RUN,
     "como": "chegue à rodada 15 — a meta já passou de um milhão",
     "chave": "rodada_mais_funda", "alvo": 15},

    {"id": "tabuleiro_4", "nome": "Tabuleiro 4", "onde": RUN,
     "como": "vença uma run no Tabuleiro 4 ou acima", "chave": "run_no_grau",
     "alvo": 4},
    {"id": "tabuleiro_8", "nome": "Tabuleiro 8", "onde": RUN,
     "como": "vença uma run no Tabuleiro 8", "chave": "run_no_grau", "alvo": 8},
]

static func total() -> int:
    return LISTA.size()

static func achar(id: String) -> Dictionary:
    for c in LISTA:
        if str(c["id"]) == id:
            return c
    return {}

## Confere as marcas contra a lista e devolve os ids que acabaram de cair.
##
## `marcas` é um dicionário achatado: cada conquista sabe qual chave ler e qual
## valor exige. Assim a conta é uma linha só e não há um `if` por conquista.
static func conferir(marcas: Dictionary, ja_tem: Dictionary) -> Array[String]:
    var novas: Array[String] = []
    for c in LISTA:
        var id := str(c["id"])
        if ja_tem.has(id):
            continue
        if int(marcas.get(str(c["chave"]), 0)) >= int(c["alvo"]):
            novas.append(id)
    return novas
