"""Maquetes do Picross 3D: início, meio da dedução, e figura revelada."""
import sys
sys.path.insert(0, "/home/user/joabcostamd/estudos/picross3d")
import voxel, figura
from PIL import Image, ImageDraw, ImageFont

N = 9
FIG = figura.cogumelo()
E = voxel.ESC

PEDRA = (196, 178, 152)      # bloco por quebrar
MARCADA = (86, 150, 206)     # marcada como "faz parte"
CHAPEU = (206, 74, 68)
PE = (236, 222, 198)


def pistas(eixo):
    """Para cada linha do eixo: quantos voxels da figura, e em quantos grupos.

    É a regra do Picross 3D: o número diz o total; o símbolo diz se estão
    juntos (nada), em dois grupos (círculo) ou em três ou mais (quadrado).
    """
    d = {}
    for a in range(N):
        for b in range(N):
            linha = []
            for c in range(N):
                p = (c, a, b) if eixo == "x" else ((a, c, b) if eixo == "y" else (a, b, c))
                linha.append(p in FIG)
            total = sum(linha)
            grupos, dentro = 0, False
            for v in linha:
                if v and not dentro:
                    grupos += 1
                dentro = v
            d[(a, b)] = (total, grupos)
    return d


PX, PY, PZ = pistas("x"), pistas("y"), pistas("z")


def simbolo(grupos):
    return "" if grupos <= 1 else ("o" if grupos == 2 else "[]")


def desenhar_pista(img, x, y, z, ox, oy, face, total, grupos):
    if total == 0:
        return
    p0, u, v = voxel.faces_do_cubo(x, y, z, ox, oy)[face]
    m = 0.20
    p0 = (p0[0] + (u[0] + v[0]) * m, p0[1] + (u[1] + v[1]) * m)
    u = (u[0] * (1 - 2 * m), u[1] * (1 - 2 * m))
    v = (v[0] * (1 - 2 * m), v[1] * (1 - 2 * m))
    s = simbolo(grupos)
    cor = (34, 28, 24, 255) if not s else (150, 40, 34, 255)
    fundo = None if not s else ((255, 255, 255, 90))
    voxel.texto_na_face(img, str(total), p0, u, v, 0.74, cor, fundo)


def cena(caminho, presentes, marcados, revelado=False, titulo="", legenda="",
         mostrar_pistas=True):
    img, d = voxel.tela((26, 29, 42))
    ox, oy = int(voxel.LARG * 0.50 * E), int(voxel.ALT * 0.522 * E)

    # chão de referência: a sombra do bloco
    sombra = []
    for x in range(N):
        for z in range(N):
            sombra.append((x, -1, z))
    for (x, y, z) in voxel.ordem(sombra):
        voxel.desenhar_cubo(d, x, y, z, ox, oy, (34, 38, 54), (30, 33, 48), largura=1)

    for (x, y, z) in voxel.ordem(presentes):
        if revelado:
            cor = CHAPEU if y >= 5 else PE
            borda = (56, 30, 28) if y >= 5 else (150, 132, 108)
        elif (x, y, z) in marcados:
            cor, borda = MARCADA, (28, 62, 96)
        else:
            cor, borda = PEDRA, (108, 94, 76)
        voxel.desenhar_cubo(d, x, y, z, ox, oy, cor, borda)

    if mostrar_pistas:
        vis = set(presentes)
        for (x, y, z) in presentes:
            if (x, y, z) in marcados:
                continue
            if (x, y + 1, z) not in vis:
                t, g = PY[(x, z)]
                desenhar_pista(img, x, y, z, ox, oy, "topo", t, g)
            if (x + 1, y, z) not in vis:
                t, g = PX[(y, z)]
                desenhar_pista(img, x, y, z, ox, oy, "x+", t, g)
            if (x, y, z + 1) not in vis:
                t, g = PZ[(x, y)]
                desenhar_pista(img, x, y, z, ox, oy, "z+", t, g)

    hud(img, d, titulo, legenda, presentes, marcados, revelado)
    return voxel.salvar(img, caminho)


def hud(img, d, titulo, legenda, presentes, marcados, revelado):
    f_g = voxel.fonte(30)
    f_m = voxel.fonte(17)
    f_p = voxel.fonte(13)
    W, H = voxel.LARG * E, voxel.ALT * E

    d.rectangle([0, 0, W, 84 * E], fill=(18, 20, 30, 235))
    d.text((44 * E, 26 * E), titulo, font=f_g, fill=(238, 232, 220, 255))
    d.text((44 * E, 60 * E), legenda, font=f_p, fill=(150, 158, 178, 255))

    restam = len(presentes) - len(FIG) if not revelado else 0
    for i, (rot, val) in enumerate([("FASE", "3-07"), ("POR QUEBRAR", str(max(0, restam))),
                                    ("ERROS", "1 / 5"), ("TEMPO", "04:12")]):
        x = W - (4 - i) * 150 * E
        d.text((x, 24 * E), rot, font=f_p, fill=(120, 130, 152, 255))
        d.text((x, 46 * E), val, font=f_m, fill=(232, 228, 218, 255))

    # ferramentas
    d.rounded_rectangle([44 * E, H - 104 * E, 300 * E, H - 40 * E], radius=12 * E,
                        fill=(30, 34, 48, 235), outline=(72, 80, 100, 255), width=2 * E)
    d.rounded_rectangle([56 * E, H - 94 * E, 158 * E, H - 50 * E], radius=8 * E,
                        fill=(196, 92, 68, 255))
    d.text((74 * E, H - 82 * E), "QUEBRAR", font=f_p, fill=(255, 244, 236, 255))
    d.text((186 * E, H - 82 * E), "MARCAR", font=f_p, fill=(140, 178, 214, 255))
