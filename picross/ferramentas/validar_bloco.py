"""Auditoria de um bloco de desenhos: forma correta e solução única."""
import sys
import solucionador as S
from catalogo_arte import DESENHOS
import arte_cap1, arte_cap2, arte_cap3, arte_cap4, arte_cap5  # noqa: F401

problemas = 0
for i, d in enumerate(DESENHOS):
    arte = d["arte"]
    altura = len(arte)
    larguras = {len(l) for l in arte}
    if len(larguras) != 1:
        print(f"  [FORMA] {d['nome']}: linhas de larguras diferentes {larguras}")
        problemas += 1
        continue
    largura = larguras.pop()
    invalidos = {c for l in arte for c in l} - {"#", "."}
    if invalidos:
        print(f"  [FORMA] {d['nome']}: caracteres inválidos {invalidos}")
        problemas += 1
        continue
    grade = [[1 if c == "#" else 0 for c in l] for l in arte]
    r = S.analisar(grade)
    marca = "ok   " if r["valido"] else "CHUTE"
    print(f"  [{marca}] {i+1:2d}. {d['nome']:<12} {largura}x{altura}"
          f"  dif {r['dificuldade']:5.1f}  densidade {r['densidade']:.2f}"
          f"  rodadas {r['rodadas']}")
    if not r["valido"]:
        problemas += 1

print()
print(f"{len(DESENHOS)} desenhos, {problemas} com problema")
sys.exit(1 if problemas else 0)
