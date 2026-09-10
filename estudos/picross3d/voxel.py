"""Renderizador isométrico de voxel — desenha o bloco de picross 3D.

Sem engine 3D: cada cubo é três losangos (topo, esquerda, direita) com tons
diferentes, desenhados do fundo para a frente. É o suficiente para provar
como o jogo se parece antes de existir jogo.
"""
import math
from PIL import Image, ImageDraw, ImageFont

LARG, ALT = 1400, 1000
ESC = 2                      # supersampling
TW, TH, TV = 40, 20, 40      # meia-largura, meia-altura do losango, altura do cubo

FONTE = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def fonte(tam):
    return ImageFont.truetype(FONTE, tam * ESC)


def tom(cor, f):
    return tuple(max(0, min(255, int(c * f))) for c in cor)


def projetar(x, y, z, ox, oy):
    """Grade 3D -> tela. y é para cima; x e z abrem em leque."""
    return (ox + (x - z) * TW * ESC,
            oy + (x + z) * TH * ESC - y * TV * ESC)


def desenhar_cubo(d, x, y, z, ox, oy, cor, contorno=(0, 0, 0), alpha=255, largura=2):
    """Um cubo: losango no topo, dois quadriláteros nas laterais."""
    sx, sy = projetar(x, y, z, ox, oy)
    tw, th, tv = TW * ESC, TH * ESC, TV * ESC

    topo = [(sx, sy - th), (sx + tw, sy), (sx, sy + th), (sx - tw, sy)]
    esq = [(sx - tw, sy), (sx, sy + th), (sx, sy + th + tv), (sx - tw, sy + tv)]
    dir_ = [(sx, sy + th), (sx + tw, sy), (sx + tw, sy + tv), (sx, sy + th + tv)]

    c = contorno + (alpha,) if len(contorno) == 3 else contorno
    d.polygon(esq, fill=tom(cor, 0.62) + (alpha,), outline=c, width=largura)
    d.polygon(dir_, fill=tom(cor, 0.82) + (alpha,), outline=c, width=largura)
    d.polygon(topo, fill=tom(cor, 1.00) + (alpha,), outline=c, width=largura)
    return (sx, sy), (topo, esq, dir_)


def ordem(voxels):
    """Pintor: o que está mais longe primeiro. Em isométrica, a soma x+y+z."""
    return sorted(voxels, key=lambda p: (p[0] + p[1] + p[2]))


def tela(fundo=(24, 27, 38)):
    img = Image.new("RGBA", (LARG * ESC, ALT * ESC), fundo + (255,))
    return img, ImageDraw.Draw(img, "RGBA")


def salvar(img, caminho):
    img.convert("RGB").resize((LARG, ALT), Image.LANCZOS).save(caminho)
    return caminho


def texto_centrado(d, xy, txt, f, cor, sombra=(0, 0, 0, 130)):
    x, y = xy
    cx = d.textlength(txt, font=f) / 2
    ch = f.size * 0.62
    if sombra:
        d.text((x - cx + 2 * ESC, y - ch + 2 * ESC), txt, font=f, fill=sombra)
    d.text((x - cx, y - ch), txt, font=f, fill=cor)


def _inv2(a, b, c, d):
    det = a * d - b * c
    return (d / det, -b / det, -c / det, a / det)


def texto_na_face(img, txt, p0, u, v, tam, cor, fundo=None):
    """Escreve o texto DEITADO na face — a face é o paralelogramo p0 + u, p0 + v.

    Sem isso o número flutua chapado por cima do cubo e a maquete não convence.
    """
    S = 128
    tile = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    td = ImageDraw.Draw(tile)
    f = ImageFont.truetype(FONTE, int(S * tam))
    if fundo:
        td.rounded_rectangle([S * 0.13, S * 0.13, S * 0.87, S * 0.87], radius=int(S * 0.16), fill=fundo)
    w = td.textlength(txt, font=f)
    td.text((S / 2 - w / 2, S / 2 - f.size * 0.62), txt, font=f, fill=cor)

    xs = [p0[0], p0[0] + u[0], p0[0] + v[0], p0[0] + u[0] + v[0]]
    ys = [p0[1], p0[1] + u[1], p0[1] + v[1], p0[1] + u[1] + v[1]]
    bx, by = min(xs), min(ys)
    bw, bh = int(max(xs) - bx) + 1, int(max(ys) - by) + 1
    if bw < 2 or bh < 2:
        return
    ia, ib, ic, idd = _inv2(u[0], v[0], u[1], v[1])
    ox, oy = bx - p0[0], by - p0[1]
    coef = (S * ia, S * ib, S * (ia * ox + ib * oy),
            S * ic, S * idd, S * (ic * ox + idd * oy))
    warp = tile.transform((bw, bh), Image.AFFINE, coef, resample=Image.BICUBIC)
    img.alpha_composite(warp, (int(bx), int(by)))


def faces_do_cubo(x, y, z, ox, oy):
    """Devolve (origem, vetor1, vetor2) de cada face visível, para deitar texto."""
    sx, sy = projetar(x, y, z, ox, oy)
    tw, th, tv = TW * ESC, TH * ESC, TV * ESC
    return {
        "topo": ((sx - tw, sy), (tw, -th), (tw, th)),
        "x+": ((sx, sy + th), (tw, -th), (0, tv)),
        "z+": ((sx - tw, sy), (tw, th), (0, tv)),
    }
