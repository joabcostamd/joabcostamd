"""Valida os 50 desenhos, ordena por dificuldade e grava dados/puzzles.json.

O balanceamento não é opinião: as fases de cada capítulo são ordenadas pela
dificuldade que o solucionador mediu, e o tempo-alvo das 3 estrelas sai da
mesma medida.
"""
import json
import os
import sys

import solucionador as S
from catalogo_arte import DESENHOS
import arte_cap1, arte_cap2, arte_cap3, arte_cap4, arte_cap5  # noqa: F401  (registram os desenhos)

CAPITULOS = [
    (5, "Primeiros traços", "Cinco por cinco. Aprendendo a ler os números."),
    (10, "Objetos", "Coisas do dia a dia, em dez por dez."),
    (15, "Criaturas", "Bichos e figuras, em quinze por quinze."),
    (20, "Cenas", "Vinte por vinte, com mais detalhe."),
    (25, "Obras", "Vinte e cinco por vinte e cinco. O capítulo final."),
]

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def tempo_alvo(lado, dificuldade):
    """Tempo para 3 estrelas: cresce com a área e com a dificuldade medida."""
    return int(round(lado * lado * 1.2 + dificuldade * 2))


def main():
    fases, problemas = [], []

    for d in DESENHOS:
        arte = d["arte"]
        largura, altura = len(arte[0]), len(arte)
        if any(len(l) != largura for l in arte) or largura != altura:
            problemas.append(f"{d['nome']}: grade não é quadrada")
            continue
        grade = [[1 if c == "#" else 0 for c in l] for l in arte]
        r = S.analisar(grade)
        if not r["valido"]:
            problemas.append(f"{d['nome']}: exige chute")
            continue
        fases.append({
            "nome": d["nome"],
            "legenda": d["legenda"],
            "cor": d["cor"],
            "lado": largura,
            "solucao": arte,
            "pistas_linhas": r["pistas_linhas"],
            "pistas_colunas": r["pistas_colunas"],
            "dificuldade": r["dificuldade"],
            "densidade": r["densidade"],
            "tempo_alvo": tempo_alvo(largura, r["dificuldade"]),
        })

    if problemas:
        print("AUDITORIA REPROVOU:")
        for p in problemas:
            print("  -", p)
        return 1

    # Balanceamento: dentro de cada capítulo, da mais fácil para a mais difícil.
    capitulos, numero = [], 1
    for lado, nome, resumo in CAPITULOS:
        do_capitulo = sorted([f for f in fases if f["lado"] == lado],
                             key=lambda f: f["dificuldade"])
        ids = []
        for f in do_capitulo:
            f["id"] = numero
            ids.append(numero)
            numero += 1
        capitulos.append({"nome": nome, "resumo": resumo, "lado": lado, "fases": ids})

    ordenadas = sorted([f for f in fases], key=lambda f: f["id"])

    destino = os.path.join(RAIZ, "dados", "puzzles.json")
    with open(destino, "w", encoding="utf-8") as arquivo:
        json.dump({"versao": 1, "capitulos": capitulos, "fases": ordenadas},
                  arquivo, ensure_ascii=False, indent=1)

    # Relatório de auditoria, versionado junto com o jogo.
    linhas = ["# Auditoria dos puzzles", "",
              f"{len(ordenadas)} fases, todas com solução única alcançável por lógica pura.",
              "", "| # | Fase | Grade | Dificuldade | Densidade | 3 estrelas |",
              "|---|---|---|---|---|---|"]
    for f in ordenadas:
        linhas.append(f"| {f['id']} | {f['nome']} | {f['lado']}×{f['lado']} | "
                      f"{f['dificuldade']:.1f} | {f['densidade']:.0%} | "
                      f"{f['tempo_alvo'] // 60}min{f['tempo_alvo'] % 60:02d} |")
    linhas.append("")
    linhas.append("## Curva de dificuldade por capítulo")
    linhas.append("")
    for c in capitulos:
        difs = [f["dificuldade"] for f in ordenadas if f["id"] in c["fases"]]
        linhas.append(f"- **{c['nome']}** ({c['lado']}×{c['lado']}, {len(difs)} fases): "
                      f"de {min(difs):.0f} a {max(difs):.0f}")
    with open(os.path.join(RAIZ, "AUDITORIA.md"), "w", encoding="utf-8") as arquivo:
        arquivo.write("\n".join(linhas) + "\n")

    print(f"{len(ordenadas)} fases gravadas em dados/puzzles.json")
    for c in capitulos:
        difs = [f["dificuldade"] for f in ordenadas if f["id"] in c["fases"]]
        print(f"  {c['nome']:<20} {c['lado']:>2}x{c['lado']:<2} "
              f"{len(c['fases']):>2} fases   dificuldade {min(difs):.0f} → {max(difs):.0f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
