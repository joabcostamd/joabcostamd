"""Resolve nonogramas por dedução pura e mede a dificuldade.

Uma célula tem três estados: DESCONHECIDA, CHEIA, VAZIA. A dedução nunca
chuta: uma célula só é marcada quando *todas* as maneiras válidas de encaixar
as pistas naquela linha concordam sobre ela.

Consequência importante: se a dedução consegue completar a grade, a solução é
necessariamente única. É essa propriedade que usamos como selo de qualidade.
"""

from functools import lru_cache

DESCONHECIDA, CHEIA, VAZIA = 0, 1, 2


def pistas_de(linha):
    """Blocos de células cheias, na ordem. É o número que aparece na borda."""
    blocos, atual = [], 0
    for celula in linha:
        if celula == CHEIA:
            atual += 1
        elif atual:
            blocos.append(atual)
            atual = 0
    if atual:
        blocos.append(atual)
    return blocos or [0]


@lru_cache(maxsize=None)
def _arranjos(pistas, estado):
    """Todos os preenchimentos válidos da linha compatíveis com o que já se sabe."""
    n = len(estado)
    if not pistas or pistas == (0,):
        if all(c != CHEIA for c in estado):
            return ((VAZIA,) * n,)
        return ()

    bloco, resto = pistas[0], pistas[1:]
    minimo_resto = sum(resto) + len(resto)
    saida = []
    for inicio in range(n - minimo_resto - bloco + 1):
        # espaços vazios antes do bloco
        if any(estado[i] == CHEIA for i in range(inicio)):
            break  # deixaria uma célula cheia de fora: nem adianta empurrar mais
        if any(estado[i] == VAZIA for i in range(inicio, inicio + bloco)):
            continue
        fim = inicio + bloco
        if fim < n:
            if estado[fim] == CHEIA:
                continue
            cauda = _arranjos(resto, estado[fim + 1:])
            prefixo = (VAZIA,) * inicio + (CHEIA,) * bloco + (VAZIA,)
        else:
            if resto:
                continue
            cauda = ((),)
            prefixo = (VAZIA,) * inicio + (CHEIA,) * bloco
        for sufixo in cauda:
            saida.append(prefixo + sufixo)
    return tuple(saida)


def deduzir_linha(pistas, estado):
    """Devolve a linha com as células que *todos* os arranjos concordam."""
    arranjos = _arranjos(tuple(pistas), tuple(estado))
    if not arranjos:
        return None  # contradição: a linha não fecha com o que já foi marcado
    resultado = list(arranjos[0])
    for arranjo in arranjos[1:]:
        for i, valor in enumerate(arranjo):
            if resultado[i] != valor:
                resultado[i] = DESCONHECIDA
        if all(c == DESCONHECIDA for c in resultado):
            break
    return resultado


class Resultado:
    def __init__(self, resolvido, rodadas, grade, deducoes_por_rodada):
        self.resolvido = resolvido
        self.rodadas = rodadas
        self.grade = grade
        self.deducoes_por_rodada = deducoes_por_rodada


def resolver(pistas_linhas, pistas_colunas, limite_rodadas=200):
    """Resolve só por dedução. `resolvido=True` significa: solução única e sem chute."""
    altura, largura = len(pistas_linhas), len(pistas_colunas)
    grade = [[DESCONHECIDA] * largura for _ in range(altura)]
    rodadas, historico = 0, []

    while rodadas < limite_rodadas:
        rodadas += 1
        mudancas = 0

        for y in range(altura):
            nova = deduzir_linha(pistas_linhas[y], grade[y])
            if nova is None:
                return Resultado(False, rodadas, grade, historico)
            for x in range(largura):
                if grade[y][x] == DESCONHECIDA and nova[x] != DESCONHECIDA:
                    grade[y][x] = nova[x]
                    mudancas += 1

        for x in range(largura):
            coluna = [grade[y][x] for y in range(altura)]
            nova = deduzir_linha(pistas_colunas[x], coluna)
            if nova is None:
                return Resultado(False, rodadas, grade, historico)
            for y in range(altura):
                if grade[y][x] == DESCONHECIDA and nova[y] != DESCONHECIDA:
                    grade[y][x] = nova[y]
                    mudancas += 1

        historico.append(mudancas)
        if mudancas == 0:
            break

    completo = all(c != DESCONHECIDA for linha in grade for c in linha)
    return Resultado(completo, rodadas, grade, historico)


def analisar(solucao):
    """Valida um desenho e devolve suas métricas. `solucao`: matriz de 0/1."""
    altura, largura = len(solucao), len(solucao[0])
    grade = [[CHEIA if v else VAZIA for v in linha] for linha in solucao]
    pistas_linhas = [pistas_de(linha) for linha in grade]
    pistas_colunas = [pistas_de([grade[y][x] for y in range(altura)]) for x in range(largura)]

    resultado = resolver(pistas_linhas, pistas_colunas)
    confere = resultado.grade == grade

    cheias = sum(sum(linha) for linha in solucao)
    densidade = cheias / (altura * largura)
    # Dificuldade: tamanho pesa, rodadas de dedução pesam mais, e densidade
    # equilibrada (perto de 50%) é mais difícil que uma grade quase vazia.
    equilibrio = 1.0 - min(1.0, abs(densidade - 0.5) * 2)
    dificuldade = largura * 1.6 + resultado.rodadas * 5.0 + equilibrio * 12.0

    return {
        "valido": resultado.resolvido and confere,
        "rodadas": resultado.rodadas,
        "densidade": round(densidade, 3),
        "dificuldade": round(dificuldade, 1),
        "pistas_linhas": pistas_linhas,
        "pistas_colunas": pistas_colunas,
        "cheias": cheias,
    }
