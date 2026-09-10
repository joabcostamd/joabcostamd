"""1. PODA — árvore por L-system que cresce em direção à luz.

Estética: silhueta escura e elegante sobre fundo de cor chapada, com flores
nas pontas. O galho é a linha; a flor é o prêmio.
"""
import math, sys
import numpy as np
sys.path.insert(0, "/home/user/joabcostamd/estudos/arte")
import base

LUZ = (0.74, 0.22)


def traco(t, x0, y0, x1, y1, espessura, cor):
    h, w = t.shape[:2]
    r = espessura * 0.5 + 2
    xa, ya = max(0, int(min(x0, x1) - r)), max(0, int(min(y0, y1) - r))
    xb, yb = min(w, int(max(x0, x1) + r)), min(h, int(max(y0, y1) + r))
    if xb <= xa or yb <= ya:
        return
    yy, xx = np.mgrid[ya:yb, xa:xb]
    dx, dy = x1 - x0, y1 - y0
    L2 = dx * dx + dy * dy
    p = 0.0 if L2 == 0 else np.clip(((xx - x0) * dx + (yy - y0) * dy) / L2, 0, 1)
    d = np.sqrt((xx - (x0 + p * dx)) ** 2 + (yy - (y0 + p * dy)) ** 2)
    m = np.clip((espessura * 0.5 - d) / 2.0 + 0.5, 0, 1)
    cor = np.array(cor, dtype=np.float32) / 255.0
    reg = t[ya:yb, xa:xb]
    t[ya:yb, xa:xb] = reg * (1 - m[:, :, None]) + cor[None, None, :] * m[:, :, None]


def crescer(t, x, y, ang, comp, esp, prof, rng, pontas):
    if prof <= 0 or comp < 5:
        pontas.append((x, y, ang))
        return
    alvo = math.atan2(LUZ[1] * t.shape[0] - y, LUZ[0] * t.shape[1] - x)
    dif = (alvo - ang + math.pi) % (2 * math.pi) - math.pi
    ang += dif * 0.045          # atração fraca: os galhos ainda se espalham

    px, py = x, y
    curva = rng.normal(0, 0.055)
    for i in range(4):
        ang += curva
        nx, ny = px + math.cos(ang) * comp / 4, py + math.sin(ang) * comp / 4
        traco(t, px, py, nx, ny, max(1.4, esp * (1 - 0.22 * i / 4)), (26, 20, 26))
        px, py = nx, ny

    n = 2 if rng.random() < 0.72 else 3
    for k in range(n):
        desvio = rng.normal(0, 0.13) + (k - (n - 1) / 2) * rng.uniform(0.46, 0.78)
        crescer(t, px, py, ang + desvio,
                comp * rng.uniform(0.62, 0.84),   # comprimento variado = copa irregular
                esp * 0.70, prof - 1, rng, pontas)


def gerar(caminho, semente=11):
    rng = np.random.default_rng(semente)
    t = base.tela()
    base.gradiente_vertical(t, (24, 58, 74), (232, 176, 132))
    H, W = t.shape[:2]

    # sol: disco limpo, sem lavar a cena
    base.brilho_radial(t, LUZ[0] * W, LUZ[1] * H, W * 0.30, (255, 214, 158), 0.30)
    base.mancha(t, LUZ[0] * W, LUZ[1] * H, W * 0.035, (255, 246, 220), 0.95)

    pontas = []
    crescer(t, W * 0.42, H * 1.03, -math.pi / 2 - 0.05, H * 0.145, 40, 11, rng, pontas)

    # flores nas pontas — mais quentes e maiores perto da luz
    for (x, y, ang) in pontas:
        d = math.hypot(x - LUZ[0] * W, y - LUZ[1] * H) / W
        calor = max(0.0, min(1.0, 1.3 - d * 1.7))
        if rng.random() > 0.22 + 0.72 * calor:
            continue
        for _ in range(rng.integers(2, 5)):
            fx, fy = x + rng.normal(0, 13), y + rng.normal(0, 13)
            cor = (int(np.clip(228 + 24 * calor, 0, 255)),
                   int(np.clip(126 + 74 * calor, 0, 255)),
                   int(np.clip(146 + 40 * calor, 0, 255)))
            base.mancha(t, fx, fy, rng.uniform(4.5, 9.5), cor, alfa=rng.uniform(0.65, 1.0))
        if calor > 0.55:
            base.brilho_radial(t, x, y, 22, (255, 214, 190), 0.16 * calor)

    # pétalas caindo
    for _ in range(120):
        px, py = rng.uniform(0, W), rng.uniform(H * 0.25, H)
        base.mancha(t, px, py, rng.uniform(2.5, 5.5), (236, 152, 162), rng.uniform(0.2, 0.6))

    yy, xx = np.mgrid[0:H, 0:W]
    r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
    t *= np.clip(1.10 - 0.30 * r ** 2, 0, 1)[:, :, None]
    print(f"  {len(pontas)} pontas de galho")
    return base.salvar(t, caminho)


if __name__ == "__main__":
    print(gerar("/home/user/joabcostamd/estudos/arte/saida/1-poda.png"))
