"""2. VITRAL — Voronoi de vidro colorido, e a luz que atravessa pinta o chão."""
import math, sys
import numpy as np
sys.path.insert(0, "/home/user/joabcostamd/estudos/arte")
import base
from PIL import Image, ImageFilter

# Paleta de catedral: azul e carmim dominam, âmbar pontua, verde é raro.
PALETA = [
    (32, 62, 138), (32, 62, 138), (24, 48, 112), (46, 88, 156),
    (158, 34, 44), (158, 34, 44), (124, 26, 38), (188, 62, 54),
    (214, 152, 46), (232, 186, 84),
    (66, 40, 108), (44, 104, 112), (206, 196, 168),
]


def indice_voronoi(h, w, pts):
    """Para cada pixel: qual semente é a mais perto, e a distância à segunda."""
    idx = np.zeros((h, w), dtype=np.int32)
    d1 = np.full((h, w), 1e18, dtype=np.float32)
    d2 = np.full((h, w), 1e18, dtype=np.float32)
    yy = np.arange(h, dtype=np.float32)[:, None]
    xx = np.arange(w, dtype=np.float32)[None, :]
    for i, (px, py) in enumerate(pts):
        d = (xx - px) ** 2 + (yy - py) ** 2
        menor = d < d1
        d2 = np.where(menor, d1, np.minimum(d2, d))
        idx = np.where(menor, i, idx)
        d1 = np.where(menor, d, d1)
    return idx, np.sqrt(d1), np.sqrt(d2)


def gerar(caminho, semente=5):
    rng = np.random.default_rng(semente)
    t = base.tela((16, 14, 22))
    H, W = t.shape[:2]

    # a janela ocupa o terço superior e o meio; o chão é embaixo
    jx0, jx1 = int(W * 0.20), int(W * 0.80)
    jy0, jy1 = int(H * 0.05), int(H * 0.62)
    jw, jh = jx1 - jx0, jy1 - jy0

    n = 150
    pts = np.stack([rng.uniform(-30, jw + 30, n), rng.uniform(-30, jh + 30, n)], axis=1)
    # relaxa uma vez (Lloyd) para as células ficarem mais parecidas de tamanho
    idx, _, _ = indice_voronoi(jh, jw, pts)
    for i in range(n):
        m = idx == i
        if m.sum() > 8:
            ys, xs = np.nonzero(m)
            pts[i] = (xs.mean(), ys.mean())
    idx, d1, d2 = indice_voronoi(jh, jw, pts)

    cores = np.array([PALETA[rng.integers(0, len(PALETA))] for _ in range(n)],
                     dtype=np.float32) / 255.0
    vidro = cores[idx]

    # textura do vidro: manchas de densidade, como vidro soprado
    tex = base.ruido((jh, jw), oitavas=5, semente=semente + 1, escala=6)
    vidro *= (0.72 + 0.56 * tex)[:, :, None]

    # chumbo entre os cacos: onde a 1ª e a 2ª sementes empatam
    borda = np.clip((d2 - d1) / 9.0, 0, 1)
    vidro *= borda[:, :, None] ** 0.5
    vidro += (1 - borda)[:, :, None] * np.array([0.06, 0.05, 0.07])

    # arco de verdade: ogiva no topo, base reta, com borda macia
    yy, xx = np.mgrid[0:jh, 0:jw].astype(np.float32)
    cx, arco = jw / 2.0, jh * 0.44
    u = (xx - cx) / (jw / 2.0)
    dentro_corpo = (np.abs(u) <= 1.0) & (yy >= arco)
    dentro_arco = (yy < arco) & ((u ** 2 + ((yy - arco) / arco) ** 2) <= 1.0)
    dist = np.where(dentro_arco | dentro_corpo, 1.0, 0.0).astype(np.float32)
    from scipy_livre import suavizar_mascara
    mask = suavizar_mascara(dist)
    vidro *= mask[:, :, None]

    t[jy0:jy1, jx0:jx1] += vidro

    # luz atravessando: o vidro borrado e esticado para baixo, somado como luz
    luz = np.asarray(
        Image.fromarray((np.clip(vidro, 0, 1) * 255).astype(np.uint8))
        .filter(ImageFilter.GaussianBlur(26))
        .resize((jw, H - jy0), Image.BILINEAR), dtype=np.float32) / 255.0
    queda = np.clip(np.linspace(1.0, 0.0, H - jy0), 0, 1)[:, None, None] ** 1.6
    lado = np.clip(1.0 - np.abs(np.linspace(-1, 1, jw)), 0, 1)[None, :, None] ** 0.7
    t[jy0:H, jx0:jx1] += luz * queda * lado * 1.05

    # a poça de luz no chão: elipse macia, sem borda reta
    poca = np.asarray(
        Image.fromarray((np.clip(vidro, 0, 1) * 255).astype(np.uint8))
        .filter(ImageFilter.GaussianBlur(52))
        .resize((int(jw * 1.30), int(H * 0.34)), Image.BILINEAR), dtype=np.float32) / 255.0
    ph, pw = poca.shape[:2]
    py0, px0 = int(H * 0.66), max(0, jx0 - int(jw * 0.15))
    ph, pw = min(ph, H - py0), min(pw, W - px0)
    ey, ex = np.mgrid[0:ph, 0:pw].astype(np.float32)
    elipse = np.clip(1.0 - np.sqrt(((ex - pw / 2) / (pw / 2)) ** 2
                                   + ((ey - ph / 2) / (ph / 2)) ** 2), 0, 1) ** 1.5
    t[py0:py0 + ph, px0:px0 + pw] += poca[:ph, :pw] * elipse[:, :, None] * 1.7

    # poeira suspensa nos raios
    for _ in range(300):
        dx = rng.uniform(jx0, jx1)
        dy = rng.uniform(jy1, H)
        base.brilho_radial(t, dx, dy, rng.uniform(2, 7), (255, 244, 220),
                           rng.uniform(0.05, 0.30))

    yy, xx = np.mgrid[0:H, 0:W]
    r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
    t *= np.clip(1.12 - 0.36 * r ** 2, 0, 1)[:, :, None]
    return base.salvar(t, caminho)


if __name__ == "__main__":
    print(gerar("/home/user/joabcostamd/estudos/arte/saida/2-vitral.png"))
