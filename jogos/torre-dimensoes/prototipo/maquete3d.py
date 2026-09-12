#!/usr/bin/env python3
"""Maquete isometrica do mapa — como a cena do Godot vai parecer.

    python3 maquete3d.py [semente]

CODIGO DESCARTAVEL, em prototipo/. Nao entra no jogo.

Mesma ideia do estudos/picross3d: desenhar a cena ANTES de existir engine, para
decidir com a imagem na mao. Aqui cada celula do layout vira um bloco 3D com
face de cima e duas laterais, pintado do fundo para a frente.

Aplica o que foi decidido ate agora:
  D-005  3D minimalista, sem textura                 D-010  4 familias de torre
  D-013  plato em camadas, rampa e ponte             D-014  castelo no meio
  D-015  o LAYOUT e dado; isto aqui e a APRESENTACAO
  ARTE   sombra dura, 4-5 cores saturadas, arvore em cacho, agua com linhas
"""
from __future__ import annotations

import importlib.util
import math
import sys
from pathlib import Path

AQUI = Path(__file__).parent
spec = importlib.util.spec_from_file_location("layout", AQUI / "gerador_mapa.py")
L = importlib.util.module_from_spec(spec)
spec.loader.exec_module(L)

# --- projecao isometrica ----------------------------------------------------
TW, TH, TZ = 24, 12, 13          # largura, altura do losango, altura de um nivel
MARGEM_X, MARGEM_Y = 40, 120


def tela(x: float, y: float, z: float = 0) -> tuple[float, float]:
    return (
        MARGEM_X + (x - y) * TW / 2 + (L.LARG + L.ALT) * TW / 4,
        MARGEM_Y + (x + y) * TH / 2 - z * TZ,
    )


# --- paleta, tirada das telas do jogo ---------------------------------------
TOPO = {0: (104, 168, 92), 1: (124, 186, 100), 2: (146, 202, 112)}
LADO_ESQ = (188, 168, 116)       # rocha iluminada
LADO_DIR = (146, 124, 82)        # rocha na sombra
CAMINHO = (214, 184, 126)
CAMINHO_LADO = (170, 142, 96)
AGUA = (64, 146, 216)
AGUA_LINHA = (126, 190, 238)
PONTE = (150, 108, 66)
RAMPA = (206, 190, 132)
SOMBRA = (44, 62, 52)
CASTELO_PEDRA = (236, 214, 160)
CASTELO_TELHA = (176, 78, 66)
ARVORE_COPA = (52, 118, 70)
ARVORE_COPA2 = (66, 138, 82)
TORRE_BASE = (222, 200, 158)
TORRE_TOPO = {"flecha": (120, 176, 216), "magia": (176, 126, 214),
              "bloqueio": (226, 178, 92), "explosao": (218, 108, 88)}
INIMIGO = (226, 232, 238)
PONTO_LIVRE = (92, 148, 196)
CEU = (150, 206, 232)


def escurecer(c, f):
    return tuple(max(0, int(v * f)) for v in c)


def desenhar(d, base, z, topo, esq, dir_):
    """Um bloco: face de cima e as duas laterais visiveis."""
    x, y = base
    cima = [tela(x, y, z), tela(x + 1, y, z), tela(x + 1, y + 1, z), tela(x, y + 1, z)]
    d.polygon(cima, fill=topo)
    if esq:
        p = [tela(x, y + 1, z), tela(x + 1, y + 1, z),
             tela(x + 1, y + 1, z - 1), tela(x, y + 1, z - 1)]
        d.polygon(p, fill=esq)
    if dir_:
        p = [tela(x + 1, y, z), tela(x + 1, y + 1, z),
             tela(x + 1, y + 1, z - 1), tela(x + 1, y, z - 1)]
        d.polygon(p, fill=dir_)


def arvore(d, x, y, z, rng):
    """Cacho de formas de uma cor so, como nas telas."""
    cx, cy = tela(x + 0.5, y + 0.5, z)
    # sombra dura, projetada para a direita e para baixo
    d.ellipse([cx - 5 + 13, cy + 2, cx + 9 + 13, cy + 9], fill=SOMBRA)
    for i in range(4):
        r = rng.uniform(4.5, 7)
        ox = rng.uniform(-4, 4)
        oy = rng.uniform(-16, -6)
        cor = ARVORE_COPA if i % 2 else ARVORE_COPA2
        d.ellipse([cx + ox - r, cy + oy - r * 0.85, cx + ox + r, cy + oy + r * 0.85], fill=cor)


def torre(d, x, y, z, tipo):
    cx, cy = tela(x + 0.5, y + 0.5, z)
    d.ellipse([cx - 4 + 14, cy + 1, cx + 10 + 14, cy + 8], fill=SOMBRA)
    for i, alt in enumerate((0, 6, 11)):
        w = 8 - i * 1.6
        d.polygon([(cx - w, cy - alt), (cx, cy - alt - w * 0.5),
                   (cx + w, cy - alt), (cx, cy - alt + w * 0.5)], fill=TORRE_BASE)
        d.polygon([(cx - w, cy - alt), (cx, cy - alt + w * 0.5),
                   (cx, cy - alt - 5 + w * 0.5), (cx - w, cy - alt - 5)],
                  fill=escurecer(TORRE_BASE, 0.78))
        d.polygon([(cx + w, cy - alt), (cx, cy - alt + w * 0.5),
                   (cx, cy - alt - 5 + w * 0.5), (cx + w, cy - alt - 5)],
                  fill=escurecer(TORRE_BASE, 0.6))
    d.ellipse([cx - 5, cy - 22, cx + 5, cy - 13], fill=TORRE_TOPO[tipo])


def castelo(d, cx_g, cy_g, z):
    cx, cy = tela(cx_g, cy_g, z)
    d.ellipse([cx - 30 + 22, cy - 2, cx + 34 + 22, cy + 22], fill=SOMBRA)
    for (ox, oy, alt, w) in ((-10, -4, 0, 13), (10, 4, 0, 13), (0, 0, 6, 17),
                             (-14, 6, 10, 7), (14, -6, 10, 7), (0, -10, 16, 9)):
        bx, by = cx + ox, cy + oy - alt
        d.polygon([(bx - w, by), (bx, by - w * 0.5), (bx + w, by), (bx, by + w * 0.5)],
                  fill=CASTELO_PEDRA)
        d.polygon([(bx - w, by), (bx, by + w * 0.5), (bx, by - alt - 6 + w * 0.5),
                   (bx - w, by - alt - 6)], fill=escurecer(CASTELO_PEDRA, 0.76))
        d.polygon([(bx + w, by), (bx, by + w * 0.5), (bx, by - alt - 6 + w * 0.5),
                   (bx + w, by - alt - 6)], fill=escurecer(CASTELO_PEDRA, 0.58))
    tx, ty = cx, cy - 30
    d.polygon([(tx - 11, ty + 6), (tx, ty - 9), (tx + 11, ty + 6), (tx, ty + 13)],
              fill=CASTELO_TELHA)


def inimigos(d, x, y, z, n, rng):
    """Tropa parada em formacao na borda, esperando a noite."""
    for i in range(n):
        ox = (i % 3) * 0.34 - 0.34
        oy = (i // 3) * 0.34 - 0.2
        cx, cy = tela(x + 0.5 + ox, y + 0.5 + oy, z)
        d.ellipse([cx - 2 + 4, cy + 1, cx + 3 + 4, cy + 4], fill=SOMBRA)
        d.ellipse([cx - 2.4, cy - 9, cx + 2.4, cy - 2], fill=INIMIGO)
        d.polygon([(cx - 2.6, cy - 3), (cx + 2.6, cy - 3), (cx + 1.8, cy + 1.5),
                   (cx - 1.8, cy + 1.5)], fill=escurecer(INIMIGO, 0.82))


def render(semente: int, destino: Path):
    import random
    from PIL import Image, ImageDraw

    m, trilhas, origens = L.gerar(semente)
    ok, med = L.validar(m, trilhas, origens)
    rng = random.Random(semente * 7919)

    larg = int(MARGEM_X * 2 + (L.LARG + L.ALT) * TW / 2)
    alt = int(MARGEM_Y + (L.LARG + L.ALT) * TH / 2 + 90)
    img = Image.new("RGB", (larg, alt), CEU)
    d = ImageDraw.Draw(img)

    # tipos de torre espalhados pelos pontos, so para a maquete
    tipos = list(TORRE_TOPO)
    pontos = [(x, y) for y in range(L.ALT) for x in range(L.LARG) if m.ponto[y][x]]
    com_torre = {p: tipos[(p[0] * 3 + p[1]) % 4] for i, p in enumerate(pontos) if i % 3 == 0}

    cx_g, cy_g = L.CENTRO

    # pintor: do fundo para a frente
    for soma in range(L.LARG + L.ALT):
        for x in range(L.LARG):
            y = soma - x
            if not (0 <= y < L.ALT):
                continue
            z = m.nivel[y][x]
            if m.agua[y][x] and not m.ponte[y][x]:
                desenhar(d, (x, y), 0, AGUA, escurecer(AGUA, 0.8), escurecer(AGUA, 0.65))
                if (x + y) % 4 == 0:
                    a, b = tela(x + 0.15, y + 0.5, 0), tela(x + 0.85, y + 0.5, 0)
                    d.line([a, b], fill=AGUA_LINHA, width=2)
                continue
            if m.ponte[y][x]:
                desenhar(d, (x, y), 0, PONTE, escurecer(PONTE, 0.78), escurecer(PONTE, 0.6))
                continue
            if m.castelo[y][x]:
                desenhar(d, (x, y), z, escurecer(TOPO[z], 1.04), LADO_ESQ, LADO_DIR)
                continue
            if m.caminho[y][x]:
                topo, esq, dir_ = CAMINHO, CAMINHO_LADO, escurecer(CAMINHO_LADO, 0.78)
            elif m.rampa[y][x]:
                topo, esq, dir_ = RAMPA, LADO_ESQ, LADO_DIR
            else:
                topo, esq, dir_ = TOPO[z], LADO_ESQ, LADO_DIR

            # sombra dura do degrau acima, como nas telas do jogo
            if y > 0 and m.nivel[y - 1][x] > z:
                topo = escurecer(topo, 0.62)
            desenhar(d, (x, y), z, topo, esq, dir_)

            if (x, y) in com_torre:
                torre(d, x, y, z, com_torre[(x, y)])
            elif m.ponto[y][x]:
                px, py = tela(x + 0.5, y + 0.5, z)
                d.polygon([(px - 6, py), (px, py - 3), (px + 6, py), (px, py + 3)],
                          fill=None, outline=PONTO_LIVRE, width=2)
            elif (not m.caminho[y][x] and not m.rampa[y][x]
                  and rng.random() < 0.09 and abs(x - cx_g) + abs(y - cy_g) > 9):
                arvore(d, x, y, z, rng)

            if abs(x - cx_g) <= 0 and abs(y - cy_g) <= 0:
                pass

    castelo(d, cx_g, cy_g, m.nivel[cy_g][cx_g])

    # tropas esperando nas frentes
    for (ox, oy) in origens:
        if m.nivel[oy][ox] is not None:
            inimigos(d, ox, oy, m.nivel[oy][ox], rng.randint(4, 9), rng)

    # legenda
    d.rectangle([0, 0, larg, 34], fill=(28, 40, 36))
    d.text((14, 12), f"TORRE ENTRE DIMENSOES · maquete · semente {semente} · "
                     f"{med['frentes']} frentes · {med['pontos']} pontos de construcao · "
                     f"{'APROVADO' if ok else 'REPROVADO'}", fill=(228, 238, 230))
    img.save(destino)
    return ok, med


def main(argv):
    sementes = [int(a) for a in argv[1:]] or [3, 7, 10]
    saida = AQUI / "saida"
    saida.mkdir(exist_ok=True)
    for s in sementes:
        ok, med = render(s, saida / f"maquete-{s}.png")
        print(f"  semente {s:>3} · {med['frentes']} frentes · {med['pontos']} pontos · "
              f"{'APROVADO' if ok else 'REPROVADO'}")
    print(f"imagens em {saida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
