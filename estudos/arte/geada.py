"""4. GEADA — cristal crescendo por agregação (DLA), a matemática do floco real."""
import sys
import numpy as np
sys.path.insert(0, "/home/user/joabcostamd/estudos/arte")
import base
from PIL import Image, ImageFilter

GW, GH = 760, 500


def crescer_dla(rng, alvo=26000):
    """Cristal por agregação (DLA): partícula vaga ao acaso e gruda ao encostar.

    Duas medições que corrigiram o modelo:
      · nascendo em qualquer lugar da tela, o andarilho quase nunca acha o
        cristal — 114 partículas em 5200 passos. Tem que nascer perto da frente.
      · semeando a borda inteira, a geada cobre tudo por igual e vira papel de
        parede. Geada de verdade nasce de POUCOS pontos de nucleação.
    """
    ocupado = np.zeros((GH, GW), dtype=bool)
    idade = np.zeros((GH, GW), dtype=np.float32)
    for f in (0.22, 0.52, 0.79):
        ocupado[GH - 1, int(GW * f)] = True
        idade[GH - 1, int(GW * f)] = 1.0

    n = 3000
    topo = GH - 1

    def nascer(k):
        # nasce bem ACIMA da frente: chegando de longe, a ponta alta intercepta
        # a partícula antes do vale. Essa sombra é o que faz o ramo existir.
        y = np.clip(rng.integers(max(0, topo - 90), max(1, topo - 30), k), 0, GH - 1)
        return rng.integers(0, GW, k), y

    wx, wy = nascer(n)
    grudados, passo = 0, 0
    while grudados < alvo and passo < 420000:
        passo += 1
        wx = np.clip(wx + rng.integers(-1, 2, n), 0, GW - 1)
        # puxão para baixo: a frente de geada está abaixo, o andarilho desce até ela
        wy = np.clip(wy + rng.integers(-1, 2, n), 0, GH - 1)
        # quem sobe demais é reposto, senão vagueia para sempre longe do cristal
        perdido = wy < topo - 150
        if perdido.any():
            px_, py_ = nascer(int(perdido.sum()))
            wx[perdido], wy[perdido] = px_, py_

        viz = np.zeros(n, dtype=bool)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            viz |= ocupado[np.clip(wy + dy, 0, GH - 1), np.clip(wx + dx, 0, GW - 1)]
        if not viz.any():
            continue
        vy, vx = wy[viz], wx[viz]
        novos = ~ocupado[vy, vx]                 # só conta célula que ainda estava vazia
        ocupado[vy, vx] = True
        idade[vy[novos], vx[novos]] = 1.0 + grudados / alvo * 6.0
        grudados += int(novos.sum())
        linhas = np.nonzero(ocupado.any(axis=1))[0]
        if len(linhas):
            topo = int(linhas.min())
        k = int(viz.sum())
        wx[viz], wy[viz] = nascer(k)
    return ocupado, idade, grudados


def gerar(caminho, semente=13):
    rng = np.random.default_rng(semente)
    ocupado, idade, n = crescer_dla(rng)
    cobertura = ocupado.mean()
    print(f"  {n} partículas · {cobertura:.1%} do vidro coberto")

    t = base.tela()
    base.gradiente_vertical(t, (8, 14, 30), (16, 30, 52))
    H, W = t.shape[:2]

    # vidro do fundo: manchas de embaçado
    emb = base.ruido((H // 6, W // 6), oitavas=4, semente=semente + 3, escala=3)
    emb = np.asarray(Image.fromarray((emb * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC),
                     dtype=np.float32) / 255.0
    t += (emb[:, :, None] - 0.5) * 0.05

    # a luz da rua atrás do vidro
    base.brilho_radial(t, W * 0.80, H * 0.24, W * 0.30, (90, 130, 190), 0.30)
    base.brilho_radial(t, W * 0.80, H * 0.24, W * 0.06, (200, 224, 255), 0.55)

    cristal = np.asarray(
        Image.fromarray((ocupado * 255).astype(np.uint8)).resize((W, H), Image.BILINEAR),
        dtype=np.float32) / 255.0
    novo = np.asarray(
        Image.fromarray((np.clip(idade / 7.0, 0, 1) * 255).astype(np.uint8)).resize((W, H), Image.BILINEAR),
        dtype=np.float32) / 255.0

    halo = np.asarray(
        Image.fromarray((cristal * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(16)),
        dtype=np.float32) / 255.0
    t += halo[:, :, None] * np.array([0.30, 0.52, 0.78]) * 1.5   # brilho gelado ao redor

    # o cristal: azulado na base, quase branco nas pontas novas
    cor = (np.array([0.52, 0.74, 0.94])[None, None, :] * (1 - novo[:, :, None])
           + np.array([0.94, 0.98, 1.00])[None, None, :] * novo[:, :, None])
    m = np.clip(cristal * 1.7, 0, 1)[:, :, None]
    t = t * (1 - m) + cor * m

    yy, xx = np.mgrid[0:H, 0:W]
    r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
    t *= np.clip(1.10 - 0.34 * r ** 2, 0, 1)[:, :, None]
    return base.salvar(t, caminho)


if __name__ == "__main__":
    print(gerar("/home/user/joabcostamd/estudos/arte/saida/4-geada.png"))
