"""3. TINTA — gotas de cor se difundindo e misturando na água."""
import sys
import numpy as np
sys.path.insert(0, "/home/user/joabcostamd/estudos/arte")
import base
from PIL import Image, ImageFilter

GW, GH = 900, 600  # a simulação roda em grade menor e depois é ampliada


def amostrar(campo, sx, sy):
    """Lê o campo em coordenadas quebradas (bilinear) — é o que faz o giro suave."""
    h, w = campo.shape[:2]
    sx = np.clip(sx, 0, w - 1.001)
    sy = np.clip(sy, 0, h - 1.001)
    x0, y0 = sx.astype(np.int32), sy.astype(np.int32)
    fx, fy = (sx - x0)[:, :, None], (sy - y0)[:, :, None]
    x1, y1 = x0 + 1, y0 + 1
    return (campo[y0, x0] * (1 - fx) * (1 - fy) + campo[y0, x1] * fx * (1 - fy)
            + campo[y1, x0] * (1 - fx) * fy + campo[y1, x1] * fx * fy)


def borrar(campo, raio):
    img = Image.fromarray((np.clip(campo, 0, 1) * 255).astype(np.uint8))
    return np.asarray(img.filter(ImageFilter.GaussianBlur(raio)), dtype=np.float32) / 255.0


def gerar(caminho, semente=3):
    rng = np.random.default_rng(semente)
    agua = np.array([0.96, 0.95, 0.93], dtype=np.float32)
    campo = np.tile(agua, (GH, GW, 1))

    gotas = [
        (0.32, 0.38, (16, 40, 132), 118),   # azul ultramar
        (0.58, 0.34, (172, 24, 46), 112),   # carmim
        (0.46, 0.60, (10, 96, 92), 104),    # verde-veneza
        (0.72, 0.58, (224, 150, 20), 96),   # âmbar
        (0.24, 0.62, (84, 30, 120), 92),    # violeta
        (0.50, 0.46, (248, 246, 240), 62),  # um respiro de água no meio
    ]
    yy, xx = np.mgrid[0:GH, 0:GW].astype(np.float32)
    for (fx, fy, cor, raio) in gotas:
        cx, cy = fx * GW, fy * GH
        r = raio * rng.uniform(0.9, 1.1)
        m = np.clip(1 - np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r, 0, 1) ** 0.6
        campo = campo * (1 - m[:, :, None]) + (np.array(cor, np.float32) / 255)[None, None] * m[:, :, None]

    # campo de velocidade: rotacional do ruído (curl noise) = redemoinho sem fonte
    p = base.ruido((GH, GW), oitavas=5, semente=semente + 9, escala=2)
    vy, vx = np.gradient(p)
    u, v = vy, -vx                       # girar o gradiente 90° dá o rotacional
    n = np.sqrt(u * u + v * v) + 1e-6
    u, v = u / n, v / n

    for passo in range(120):
        forca = 4.2 * (1.0 - 0.55 * passo / 120)
        campo = amostrar(campo, xx - u * forca, yy - v * forca)
        if passo % 3 == 0:
            campo = borrar(campo, 0.8)   # difusão leve: espalha sem lavar a cor

    # fios finos de tinta que ainda não dissolveram
    fio = base.ruido((GH, GW), oitavas=4, semente=semente + 21, escala=26)
    campo *= (0.972 + 0.056 * fio)[:, :, None]

    grande = np.asarray(
        Image.fromarray((np.clip(campo, 0, 1) * 255).astype(np.uint8))
        .resize((base.LARGURA * base.ESCALA, base.ALTURA * base.ESCALA), Image.LANCZOS),
        dtype=np.float32) / 255.0

    H, W = grande.shape[:2]
    gy, gx = np.mgrid[0:H, 0:W]
    r = np.sqrt(((gx - W / 2) / (W / 2)) ** 2 + ((gy - H / 2) / (H / 2)) ** 2)
    grande *= np.clip(1.06 - 0.26 * r ** 2, 0, 1)[:, :, None]
    return base.salvar(grande, caminho)


if __name__ == "__main__":
    print(gerar("/home/user/joabcostamd/estudos/arte/saida/3-tinta.png"))
