"""Auditoria da etapa 1: o solucionador acerta casos de resposta conhecida?"""
import solucionador as S

falhas = 0

def ok(nome, condicao):
    global falhas
    if condicao:
        print(f"  [ok]    {nome}")
    else:
        falhas += 1
        print(f"  [FALHA] {nome}")

# pistas a partir de uma linha
ok("lê pistas de uma linha cheia-vazia-cheia",
   S.pistas_de([S.CHEIA, S.CHEIA, S.VAZIA, S.CHEIA]) == [2, 1])
ok("linha totalmente vazia tem pista [0]",
   S.pistas_de([S.VAZIA] * 4) == [0])

# dedução de linha isolada
ok("bloco de 4 numa linha de 5 força as 3 do meio",
   S.deduzir_linha([4], [S.DESCONHECIDA] * 5) ==
   [S.DESCONHECIDA, S.CHEIA, S.CHEIA, S.CHEIA, S.DESCONHECIDA])
ok("linha cheia por completo é deduzida direto",
   S.deduzir_linha([5], [S.DESCONHECIDA] * 5) == [S.CHEIA] * 5)
ok("pistas impossíveis para o espaço devolvem contradição",
   S.deduzir_linha([3], [S.VAZIA, S.VAZIA, S.VAZIA, S.DESCONHECIDA, S.DESCONHECIDA]) is None)

# desenhos completos
cruz = [
    [0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1],
    [0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0],
]
r = S.analisar(cruz)
ok("resolve uma cruz 5x5 por lógica pura", r["valido"])
ok("as pistas da cruz batem com o desenho", r["pistas_linhas"][2] == [5])

moldura = [
    [1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1],
]
rm = S.analisar(moldura)
ok("resolve uma moldura 6x6", rm["valido"])
ok("moldura 6x6 é mais difícil que a cruz 5x5", rm["dificuldade"] > r["dificuldade"])

# Um desenho que exige chute NÃO pode passar como válido. A diagonal 2x2 é o
# caso clássico: espelhá-la dá outra solução com exatamente as mesmas pistas.
ambiguo = [
    [1, 0],
    [0, 1],
]
ok("reprova desenho ambíguo (a diagonal 2x2 tem duas soluções)",
   not S.analisar(ambiguo)["valido"])

# Padrão alternado denso também é ambíguo — vale registrar, porque afeta o
# desenho das fases: evitar xadrez em áreas grandes.
xadrez = [[(x + y) % 2 for x in range(6)] for y in range(6)]
ok("reprova xadrez 6x6 (alternado denso não fecha por lógica)",
   not S.analisar(xadrez)["valido"])

vazio = [[0] * 5 for _ in range(5)]
ok("grade vazia é resolvida trivialmente", S.analisar(vazio)["valido"])

print()
print("SOLUCIONADOR OK" if falhas == 0 else f"FALHAS: {falhas}")
raise SystemExit(1 if falhas else 0)
