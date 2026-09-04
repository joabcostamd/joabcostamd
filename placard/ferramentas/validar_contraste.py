#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Valida o contraste dos temas contra a WCAG AA.

Lê `maquete/capturas/paletas.json`, que o Godot exporta a partir de `temas.gd`.
A fonte de verdade continua sendo o GDScript: este arquivo é derivado, e por
isso um tema novo nunca entra sem passar por aqui.

Sai com código 1 se algum par reprovar, para o `testar.sh` interromper.
"""

import json
import os
import sys

# WCAG 2.1: 4,5:1 para texto corrido, 3:1 para texto grande e para elementos
# gráficos (os naipes são gráficos — a forma é a informação, a cor é reforço).
TEXTO = 4.5
GRANDE = 3.0

PARES = [
    ("texto", "fundo", TEXTO, "texto de interface sobre o fundo"),
    ("texto", "painel", TEXTO, "texto sobre painel"),
    ("texto_suave", "painel", GRANDE, "texto secundário sobre painel"),
    ("carta_texto", "carta", TEXTO, "número da carta sobre a carta"),
    ("destaque", "fundo", GRANDE, "recompensa sobre o fundo"),
    ("destaque", "painel", GRANDE, "recompensa sobre painel"),
    ("acento", "painel", GRANDE, "acento sobre painel"),
    ("copas", "carta", GRANDE, "naipe copas sobre a carta"),
    ("ouros", "carta", GRANDE, "naipe ouros sobre a carta"),
    ("paus", "carta", GRANDE, "naipe paus sobre a carta"),
    ("espadas", "carta", GRANDE, "naipe espadas sobre a carta"),
    ("borda", "fundo", 1.6, "borda visível contra o fundo"),
    # O par que faltava quando 96 de 96 passavam e o tabuleiro sumia nos temas
    # claros. Teste que aprova defeito conhecido é pior que teste nenhum.
    #
    # Só a BORDA é exigida, não o preenchimento: a borda é a afordância de
    # "cabe carta aqui", e uma casa com borda forte não precisa de fundo
    # diferente do resto. Exigir os dois reprovava temas escuros que se leem
    # perfeitamente — teste rigoroso demais também é teste errado.
    ("casa_borda", "fundo", GRANDE, "borda da casa: a afordância de cabe-carta-aqui"),
]

## Medidos, mas como aviso: um deles baixo não reprova, porque a borda já
## carrega a informação. Os dois baixos ao mesmo tempo, sim.
AVISOS = [
    ("casa", "fundo", 1.5, "preenchimento da casa quase igual ao fundo"),
]


def canal(v):
    """Linearização sRGB, o passo que quase todo mundo esquece."""
    v = v / 255.0
    return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4


def luminancia(hexa):
    h = hexa.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * canal(r) + 0.7152 * canal(g) + 0.0722 * canal(b)


def razao(a, b):
    la, lb = luminancia(a), luminancia(b)
    claro, escuro = max(la, lb), min(la, lb)
    return (claro + 0.05) / (escuro + 0.05)


def separacao_dos_naipes(tema):
    """Os quatro naipes precisam ser distinguíveis entre si em escala de cinza.

    Se dois naipes têm a mesma luminância, quem não enxerga cor depende só da
    forma — e a forma é a informação principal, então isto é um aviso e não uma
    reprovação. Mas precisa aparecer.
    """
    nomes = ["copas", "ouros", "paus", "espadas"]
    avisos = []
    for i in range(len(nomes)):
        for j in range(i + 1, len(nomes)):
            r = razao(tema[nomes[i]], tema[nomes[j]])
            if r < 1.25:
                avisos.append("%s e %s quase idênticos em cinza (%.2f)"
                              % (nomes[i], nomes[j], r))
    return avisos


def main():
    aqui = os.path.dirname(os.path.abspath(__file__))
    caminho = os.path.join(aqui, "..", "maquete", "capturas", "paletas.json")
    if not os.path.exists(caminho):
        print("paletas.json não existe — rode as capturas antes")
        return 1

    with open(caminho, encoding="utf-8") as f:
        temas = json.load(f)

    reprovas = 0
    total = 0
    for tema in temas:
        linhas = []
        for frente, fundo, minimo, descricao in PARES:
            total += 1
            r = razao(tema[frente], tema[fundo])
            if r < minimo:
                reprovas += 1
                linhas.append("    REPROVA  %-34s %.2f  (mínimo %.1f)"
                              % (descricao, r, minimo))
        for frente, fundo, minimo, descricao in AVISOS:
            if razao(tema[frente], tema[fundo]) < minimo:
                linhas.append("    aviso    %s (%.2f)"
                              % (descricao, razao(tema[frente], tema[fundo])))
        for aviso in separacao_dos_naipes(tema):
            linhas.append("    aviso    " + aviso)

        marca = "ok" if not any("REPROVA" in x for x in linhas) else "FALHA"
        print("  [%s] %-18s %s" % (marca, tema["id"], tema["sensacao"]))
        for linha in linhas:
            print(linha)

    print()
    if reprovas:
        print("CONTRASTE: %d de %d pares reprovaram em %d temas"
              % (reprovas, total, len(temas)))
        return 1
    print("CONTRASTE OK — %d pares em %d temas" % (total, len(temas)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
