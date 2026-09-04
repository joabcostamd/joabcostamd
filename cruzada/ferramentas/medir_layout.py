#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Mede os alvos de toque do layout e reprova abaixo do mínimo.

Existe porque uma captura bonita não é medida. Os números de paisagem foram
conferidos por script e os de retrato foram PRESUMIDOS — resultado: casa de
58 px e carta de 59 px, ambas abaixo do mínimo, passando despercebidas.

Espelha a aritmética de `maquete/tela.gd`. Se o layout mudar lá e não aqui, os
números divergem e o teste avisa — que é o ponto.
"""

import sys

RAZAO = 1.4          # carta de baralho: 5:7
PRIMARIO = 64        # peça, casa, carta: onde o dedo trabalha
SECUNDARIO = 44      # botão de menu


def paisagem(largura=1280.0, altura=720.0):
    margem, vao, barra = 24.0, 20.0, 52.0
    rot_fileira, rot_coluna, vao_celula, vao_mao = 108.0, 24.0, 5.0, 12.0

    util = largura - margem * 2
    centro = max(420.0, min(util * 0.41, 560.0))
    topo = margem * 0.5
    alt = altura - (topo + barra + 8.0) - margem * 0.5

    carta_mao = min((centro - vao_mao * 4) / 5, 82.0)
    sobra = alt - rot_coluna - 28.0 - carta_mao * RAZAO
    celula = int(min((centro - rot_fileira - 8.0 - vao_celula * 4) / 5,
                     (sobra - vao_celula * 4) / (5 * RAZAO)))
    usado = celula * RAZAO * 5 + vao_celula * 4 + rot_coluna + 28.0 + carta_mao * RAZAO
    return {
        "nome": "paisagem %dx%d" % (largura, altura),
        "casa": celula, "carta": int(carta_mao),
        "vertical": (usado, alt),
    }


def retrato(largura=360.0, altura=800.0):
    margem, barra_fileira, vao_celula, vao_mao = 8.0, 8.0, 4.0, 4.0
    util = largura - margem * 2
    celula = int((util - barra_fileira - vao_celula * 4) / 5)
    carta_mao = int((util - vao_mao * 4) / 5)
    grade_fim = 154.0 + celula * RAZAO * 5 + vao_celula * 4
    mao_topo = altura - carta_mao * RAZAO - margem
    return {
        "nome": "retrato %dx%d" % (largura, altura),
        "casa": celula, "carta": carta_mao,
        "vertical": (grade_fim + 28.0, mao_topo),
    }


def main():
    falhas = 0
    for medida in (paisagem(), retrato(), paisagem(1920, 1080), retrato(390, 844)):
        print("  %s" % medida["nome"])
        for rotulo, valor in (("casa da grade", medida["casa"]),
                              ("carta da mão", medida["carta"])):
            ok = valor >= PRIMARIO
            falhas += 0 if ok else 1
            print("    %-16s %3d px   %s" % (rotulo, valor,
                  "ok" if ok else "REPROVA (mínimo %d)" % PRIMARIO))
        usado, disponivel = medida["vertical"]
        ok = usado <= disponivel
        falhas += 0 if ok else 1
        print("    %-16s %3.0f de %3.0f   %s" % ("vertical", usado, disponivel,
              "ok" if ok else "REPROVA: estoura em %.0f px" % (usado - disponivel)))

    print()
    if falhas:
        print("LAYOUT: %d medidas reprovaram" % falhas)
        return 1
    print("LAYOUT OK — alvos primários >= %d px em todos os tamanhos" % PRIMARIO)
    return 0


if __name__ == "__main__":
    sys.exit(main())
