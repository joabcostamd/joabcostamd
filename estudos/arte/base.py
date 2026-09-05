"""Ferramentas comuns dos estudos de arte procedural.

Tudo é gerado por código: nenhuma imagem de origem, nenhum asset.
Renderiza em escala maior e reduz no fim — é o que dá a borda macia.
"""
import numpy as np
from PIL import Image

LARGURA, ALTURA = 1200, 800
ESCALA = 3  # supersampling


def tela(cor=(0, 0, 0)):
    """Uma tela em ponto flutuante, no tamanho ampliado."""
    t = np.zeros((ALTURA * ESCALA, LARGURA * ESCALA, 3), dtype=np.float32)
    t[:, :] = np.array(cor, dtype=np.float32) / 255.0
    return t


def salvar(t, caminho):
    """Reduz para o tamanho final e grava."""
    img = Image.fromarray((np.clip(t, 0, 1) * 255).astype(np.uint8))
    img = img.resize((LARGURA, ALTURA), Image.LANCZOS)
    img.save(caminho)
    return conferir(np.asarray(img, dtype=np.float32) / 255.0, caminho)


def conferir(a, caminho):
    """O que eu consigo medir sem enxergar: a imagem não é chapada nem estourada."""
    desvio = float(a.std())
    brilho = float(a.mean())
    cheio = float((a.max(axis=2) > 0.06).mean())
    return {
        "arquivo": caminho.split("/")[-1],
        "desvio": round(desvio, 4),
        "brilho": round(brilho, 4),
        "area_pintada": round(cheio, 3),
        "ok": desvio > 0.03 and 0.02 < brilho < 0.92,
    }


def gradiente_vertical(t, topo, base):
    """Céu: cor no topo derretendo na cor de baixo."""
    h = t.shape[0]
    p = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    topo = np.array(topo, dtype=np.float32) / 255.0
    base = np.array(base, dtype=np.float32) / 255.0
    t[:, :] = (topo[None, :] * (1 - p) + base[None, :] * p)[:, None, :]
    return t


def ruido(forma, oitavas=5, semente=0, escala=4.0):
    """Ruído fractal (fBm) montado só com numpy: soma de camadas cada vez mais finas."""
    rng = np.random.default_rng(semente)
    h, w = forma
    saida = np.zeros(forma, dtype=np.float32)
    amp, total = 1.0, 0.0
    for o in range(oitavas):
        lado = max(2, int(escala * (2 ** o)))
        grosso = rng.random((lado, lado)).astype(np.float32)
        camada = np.asarray(
            Image.fromarray((grosso * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC),
            dtype=np.float32,
        ) / 255.0
        saida += camada * amp
        total += amp
        amp *= 0.5
    return saida / total


def brilho_radial(t, cx, cy, raio, cor, forca=1.0):
    """Halo de luz somado por cima (aditivo, como luz de verdade)."""
    h, w = t.shape[:2]
    y0, y1 = max(0, int(cy - raio)), min(h, int(cy + raio))
    x0, x1 = max(0, int(cx - raio)), min(w, int(cx + raio))
    if y1 <= y0 or x1 <= x0:
        return t
    yy, xx = np.mgrid[y0:y1, x0:x1]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / raio
    queda = np.clip(1.0 - d, 0, 1) ** 2.2
    cor = np.array(cor, dtype=np.float32) / 255.0
    t[y0:y1, x0:x1] += queda[:, :, None] * cor[None, None, :] * forca
    return t


def mancha(t, cx, cy, raio, cor, alfa=1.0, achatada=1.0):
    """Borrão com mistura normal (não aditiva) — para massa de cor que não estoura."""
    h, w = t.shape[:2]
    ry = raio * achatada
    y0, y1 = max(0, int(cy - ry)), min(h, int(cy + ry))
    x0, x1 = max(0, int(cx - raio)), min(w, int(cx + raio))
    if y1 <= y0 or x1 <= x0:
        return t
    yy, xx = np.mgrid[y0:y1, x0:x1]
    d = np.sqrt(((xx - cx) / raio) ** 2 + ((yy - cy) / ry) ** 2)
    m = np.clip(1.0 - d, 0, 1) ** 1.5 * alfa
    cor = np.array(cor, dtype=np.float32) / 255.0
    reg = t[y0:y1, x0:x1]
    t[y0:y1, x0:x1] = reg * (1 - m[:, :, None]) + cor[None, None, :] * m[:, :, None]
    return t
