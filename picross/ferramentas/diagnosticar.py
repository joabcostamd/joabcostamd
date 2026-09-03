"""Mostra onde a dedução trava num desenho: '?' são as células ambíguas."""
import sys
import solucionador as S
from catalogo_arte import DESENHOS
import arte_cap1, arte_cap2, arte_cap3, arte_cap4, arte_cap5  # noqa: F401
import arte_extra1, arte_extra2, arte_extra3, arte_extra4, arte_extra5  # noqa: F401

alvos = sys.argv[1:]
for d in DESENHOS:
    if alvos and d["nome"] not in alvos:
        continue
    grade = [[1 if c == "#" else 0 for c in l] for l in d["arte"]]
    r = S.analisar(grade)
    if r["valido"]:
        continue
    altura, largura = len(grade), len(grade[0])
    pl = r["pistas_linhas"]
    pc = r["pistas_colunas"]
    res = S.resolver(pl, pc)
    print(f"── {d['nome']} ── travou com {sum(1 for l in res.grade for c in l if c == S.DESCONHECIDA)} células indefinidas")
    for y in range(altura):
        linha = ""
        for x in range(largura):
            c = res.grade[y][x]
            linha += "?" if c == S.DESCONHECIDA else ("#" if c == S.CHEIA else ".")
        print("   " + linha + "   |" + d["arte"][y])
    print()
