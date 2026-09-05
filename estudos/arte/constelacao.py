"""5. CONSTELAÇÃO — céu gerado, e a figura escondida que se acende ao ser ligada."""
import math, sys
import numpy as np
sys.path.insert(0, "/home/user/joabcostamd/estudos/arte")
import base
from PIL import Image


def linha_brilhante(t, x0, y0, x1, y1, cor, forca=1.0):
    """O traço entre duas estrelas: fino, aceso, com halo."""
    n = int(math.hypot(x1 - x0, y1 - y0) / 6) + 2
    for i in range(n):
        p = i / (n - 1)
        base.brilho_radial(t, x0 + (x1 - x0) * p, y0 + (y1 - y0) * p, 16, cor, 0.10 * forca)
        base.brilho_radial(t, x0 + (x1 - x0) * p, y0 + (y1 - y0) * p, 3.4, (255, 255, 255), 0.34 * forca)


def gerar(caminho, semente=17):
    rng = np.random.default_rng(semente)
    t = base.tela()
    base.gradiente_vertical(t, (6, 8, 26), (24, 18, 44))
    H, W = t.shape[:2]

    # nebulosa: ruído colorido, quase transparente
    for (cor, sem, forca) in (((70, 40, 130), 1, 0.34), ((22, 70, 120), 2, 0.28),
                              ((120, 46, 84), 3, 0.16)):
        n = base.ruido((H // 10, W // 10), oitavas=5, semente=semente + sem, escala=2)
        n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC),
                       dtype=np.float32) / 255.0
        n = np.clip((n - 0.46) * 2.6, 0, 1) ** 1.7
        t += n[:, :, None] * (np.array(cor, np.float32) / 255.0) * forca

    # o campo de estrelas: muitas fracas, poucas fortes
    for _ in range(1900):
        x, y = rng.uniform(0, W), rng.uniform(0, H)
        b = rng.random() ** 3.4
        r = 1.6 + b * 7
        tom = (255, int(238 + 17 * rng.random()), int(214 + 41 * rng.random()))
        base.brilho_radial(t, x, y, r, tom, 0.35 + b * 0.8)
        if b > 0.72:
            base.brilho_radial(t, x, y, r * 7, tom, 0.20 * b)

    # a figura escondida: um caçador de ombros largos
    figura = [(0.34, 0.20), (0.46, 0.16), (0.57, 0.22),
              (0.45, 0.34), (0.45, 0.48),
              (0.33, 0.42), (0.58, 0.44),
              (0.36, 0.66), (0.55, 0.68),
              (0.31, 0.82), (0.60, 0.84)]
    ligacoes = [(0, 1), (1, 2), (1, 3), (3, 4), (3, 5), (3, 6),
                (4, 7), (4, 8), (7, 9), (8, 10)]

    pts = [(0.10 + p[0] * 0.80) * W for p in figura], [(0.08 + p[1] * 0.80) * H for p in figura]
    pts = list(zip(pts[0], pts[1]))

    # as ligações já feitas acendem; as estrelas da figura são as mais brilhantes
    for (a, b) in ligacoes:
        linha_brilhante(t, pts[a][0], pts[a][1], pts[b][0], pts[b][1], (150, 196, 255), 1.0)
    for (x, y) in pts:
        base.brilho_radial(t, x, y, 62, (120, 172, 255), 0.30)
        base.brilho_radial(t, x, y, 16, (208, 232, 255), 0.85)
        base.brilho_radial(t, x, y, 5, (255, 255, 255), 1.0)

    # uma estrela cadente
    for i in range(70):
        p = i / 70
        base.brilho_radial(t, W * 0.80 + p * W * 0.16, H * 0.12 + p * H * 0.10,
                           2.6 + 3 * (1 - p), (255, 246, 224), 0.55 * (1 - p) ** 1.6)

    yy, xx = np.mgrid[0:H, 0:W]
    r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
    t *= np.clip(1.10 - 0.34 * r ** 2, 0, 1)[:, :, None]
    return base.salvar(t, caminho)


if __name__ == "__main__":
    print(gerar("/home/user/joabcostamd/estudos/arte/saida/5-constelacao.png"))
