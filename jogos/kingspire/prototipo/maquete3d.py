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


# --- as dimensoes: mesma geometria, outra roupa -----------------------------
# Prova da D-015: trocar o visual inteiro nao toca numa linha do layout.
BIOMAS = {
    "floresta": {
        "nome": "FLORESTA",
        "topo": {0: (104, 168, 92), 1: (124, 186, 100), 2: (146, 202, 112)},
        "rocha": ((188, 168, 116), (146, 124, 82)),
        "caminho": (214, 184, 126), "agua": (64, 146, 216), "linha": (126, 190, 238),
        "ceu": (150, 206, 232), "deco": "arvore", "densidade": 0.11,
        "copa": ((52, 118, 70), (66, 138, 82)),
    },
    "montanha": {
        "nome": "MONTANHA",
        "topo": {0: (118, 132, 118), 1: (158, 168, 158), 2: (232, 238, 240)},
        "rocha": ((166, 170, 178), (108, 114, 124)),
        "caminho": (186, 178, 162), "agua": (108, 170, 208), "linha": (176, 216, 240),
        "ceu": (186, 206, 222), "deco": "pinheiro", "densidade": 0.07,
        "copa": ((38, 82, 62), (48, 100, 74)),
    },
    "rio": {
        "nome": "RIO",
        "topo": {0: (96, 178, 108), 1: (118, 196, 118), 2: (142, 210, 130)},
        "rocha": ((180, 172, 130), (136, 128, 92)),
        "caminho": (208, 190, 138), "agua": (48, 154, 226), "linha": (140, 206, 244),
        "ceu": (160, 214, 238), "deco": "junco", "densidade": 0.13,
        "copa": ((64, 146, 90), (86, 168, 104)),
    },
    "deserto": {
        "nome": "DESERTO",
        "topo": {0: (214, 172, 116), 1: (226, 188, 134), 2: (238, 206, 156)},
        "rocha": ((196, 124, 92), (150, 88, 66)),
        "caminho": (236, 214, 172), "agua": (86, 176, 190), "linha": (150, 214, 222),
        "ceu": (238, 204, 158), "deco": "cacto", "densidade": 0.06,
        "copa": ((92, 140, 84), (108, 158, 96)),
    },
    "vazio": {
        "nome": "O VAZIO",
        "topo": {0: (68, 56, 104), 1: (88, 72, 130), 2: (112, 92, 158)},
        "rocha": ((146, 120, 186), (92, 74, 126)),
        "caminho": (168, 146, 206), "agua": (74, 208, 208), "linha": (150, 240, 238),
        "ceu": (44, 36, 72), "deco": "cristal", "densidade": 0.10,
        "copa": ((104, 240, 232), (146, 200, 250)),
    },
}


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


def arvore(d, x, y, z, rng, B):
    """A decoracao muda com a dimensao. A geometria por baixo e a mesma."""
    cx, cy = tela(x + 0.5, y + 0.5, z)
    c1, c2 = B["copa"]
    tipo = B["deco"]
    d.ellipse([cx - 5 + 13, cy + 2, cx + 9 + 13, cy + 9], fill=SOMBRA)

    if tipo == "arvore":
        for i in range(4):
            r = rng.uniform(4.5, 7)
            ox, oy = rng.uniform(-4, 4), rng.uniform(-16, -6)
            d.ellipse([cx + ox - r, cy + oy - r * .85, cx + ox + r, cy + oy + r * .85],
                      fill=c1 if i % 2 else c2)
    elif tipo == "pinheiro":
        d.polygon([(cx - 1.5, cy), (cx + 1.5, cy), (cx + 1.5, cy - 6), (cx - 1.5, cy - 6)],
                  fill=(96, 72, 54))
        for i, (w, h) in enumerate(((7, 6), (5.5, 12), (4, 17))):
            d.polygon([(cx - w, cy - h + 3), (cx, cy - h - 5), (cx + w, cy - h + 3)],
                      fill=c1 if i % 2 else c2)
    elif tipo == "junco":
        for i in range(5):
            ox = rng.uniform(-5, 5)
            h = rng.uniform(7, 13)
            d.line([(cx + ox, cy), (cx + ox + rng.uniform(-2, 2), cy - h)],
                   fill=c1 if i % 2 else c2, width=2)
    elif tipo == "cacto":
        d.polygon([(cx - 2.5, cy), (cx + 2.5, cy), (cx + 2.5, cy - 14), (cx - 2.5, cy - 14)],
                  fill=c1)
        d.polygon([(cx + 2.5, cy - 8), (cx + 7, cy - 8), (cx + 7, cy - 13), (cx + 5, cy - 13),
                   (cx + 5, cy - 10), (cx + 2.5, cy - 10)], fill=c2)
    elif tipo == "cristal":
        for i in range(3):
            ox = rng.uniform(-4, 4)
            h = rng.uniform(9, 18)
            w = rng.uniform(2, 3.5)
            d.polygon([(cx + ox - w, cy), (cx + ox, cy - h), (cx + ox + w, cy),
                       (cx + ox, cy + 2)], fill=c1 if i % 2 else c2)


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


def render(semente: int, destino: Path, bioma: str = "floresta", arranjo: str = "centro"):
    import random
    from PIL import Image, ImageDraw

    B = BIOMAS[bioma]
    m, trilhas, origens = L.gerar(semente, bioma, arranjo)
    ok, med = L.validar(m, trilhas, origens)
    rng = random.Random(semente * 7919)

    larg = int(MARGEM_X * 2 + (L.LARG + L.ALT) * TW / 2)
    alt = int(MARGEM_Y + (L.LARG + L.ALT) * TH / 2 + 90)
    img = Image.new("RGB", (larg, alt), B["ceu"])
    d = ImageDraw.Draw(img)

    # tipos de torre espalhados pelos pontos, so para a maquete
    tipos = list(TORRE_TOPO)
    pontos = [(x, y) for y in range(L.ALT) for x in range(L.LARG) if m.ponto[y][x]]
    com_torre = {p: tipos[(p[0] * 3 + p[1]) % 4] for i, p in enumerate(pontos) if i % 3 == 0}

    cx_g, cy_g = m.castelo_pos

    # pintor: do fundo para a frente
    for soma in range(L.LARG + L.ALT):
        for x in range(L.LARG):
            y = soma - x
            if not (0 <= y < L.ALT):
                continue
            z = m.nivel[y][x]
            if m.agua[y][x] and not m.ponte[y][x]:
                desenhar(d, (x, y), 0, B["agua"], escurecer(B["agua"], .8), escurecer(B["agua"], .65))
                if (x + y) % 4 == 0:
                    a, b = tela(x + 0.15, y + 0.5, 0), tela(x + 0.85, y + 0.5, 0)
                    d.line([a, b], fill=B["linha"], width=2)
                continue
            if m.ponte[y][x]:
                desenhar(d, (x, y), 0, PONTE, escurecer(PONTE, 0.78), escurecer(PONTE, 0.6))
                continue
            if m.castelo[y][x]:
                desenhar(d, (x, y), z, escurecer(B["topo"][z], 1.04), B["rocha"][0], B["rocha"][1])
                continue
            if m.caminho[y][x]:
                topo, esq, dir_ = B["caminho"], escurecer(B["caminho"], .8), escurecer(B["caminho"], .62)
            elif m.rampa[y][x]:
                topo, esq, dir_ = escurecer(B["caminho"], 1.04), B["rocha"][0], B["rocha"][1]
            else:
                topo, esq, dir_ = B["topo"][z], B["rocha"][0], B["rocha"][1]

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
                  and rng.random() < B["densidade"] and abs(x - cx_g) + abs(y - cy_g) > 9):
                arvore(d, x, y, z, rng, B)

            if abs(x - cx_g) <= 0 and abs(y - cy_g) <= 0:
                pass

    castelo(d, cx_g, cy_g, m.nivel[cy_g][cx_g])

    # tropas esperando nas frentes
    for (ox, oy) in origens:
        if m.nivel[oy][ox] is not None:
            inimigos(d, ox, oy, m.nivel[oy][ox], rng.randint(4, 9), rng)

    # legenda
    d.rectangle([0, 0, larg, 34], fill=(28, 40, 36))
    d.text((14, 12), f"{B['nome']} · {L.ARRANJOS[arranjo]['rotulo']} · semente {semente} · "
                     f"{med['frentes']} frentes · {med['pontos']} pontos de construcao · "
                     f"{'APROVADO' if ok else 'REPROVADO'}", fill=(228, 238, 230))
    img.save(destino)
    return ok, med


def primeira_boa(bioma, arranjo, comeco=1, limite=60):
    """Anda nas sementes ate uma passar no validador. E o que o jogo vai fazer."""
    for s in range(comeco, comeco + limite):
        m, t, o = L.gerar(s, bioma, arranjo)
        if L.validar(m, t, o)[0]:
            return s
    return comeco


def main(argv):
    alvo = argv[1] if len(argv) > 1 else "dimensoes"
    saida = AQUI / "saida"
    saida.mkdir(exist_ok=True)

    if alvo == "arranjos":                       # onde o castelo fica
        for antiga in saida.glob("arranjo-*.png"):
            antiga.unlink()
        print("MESMO BIOMA, QUATRO LUGARES PARA O CASTELO\n")
        for arranjo in L.ARRANJOS:
            s = primeira_boa("floresta", arranjo)
            ok, med = render(s, saida / f"arranjo-{arranjo}.png", "floresta", arranjo)
            print(f"  {L.ARRANJOS[arranjo]['rotulo']:<28} semente {s:>2} · "
                  f"{med['frentes']} frentes · {med['pontos']:>3} pontos · "
                  f"{'APROVADO' if ok else 'REPROVADO: ' + med['motivos'][0]}")
    else:                                        # mesma semente, cinco dimensoes
        semente = int(argv[2]) if len(argv) > 2 else 3
        for antiga in saida.glob("dimensao-*.png"):
            antiga.unlink()
        print(f"MESMA SEMENTE ({semente}), CINCO DIMENSOES — so a roupa muda\n")
        for bioma in BIOMAS:
            ok, med = render(semente, saida / f"dimensao-{bioma}.png", bioma)
            print(f"  {BIOMAS[bioma]['nome']:<10} {med['frentes']} frentes · "
                  f"{med['pontos']:>3} pontos · "
                  f"{'APROVADO' if ok else 'REPROVADO: ' + med['motivos'][0]}")
    print(f"\nimagens em {saida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
