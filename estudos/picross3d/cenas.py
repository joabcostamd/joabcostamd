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


def desenhar_pista(img, x, y, z, ox, oy, face, total, grupos, marcado=False):
    if total == 0:
        return
    p0, u, v = voxel.faces_do_cubo(x, y, z, ox, oy)[face]
    m = 0.20
    p0 = (p0[0] + (u[0] + v[0]) * m, p0[1] + (u[1] + v[1]) * m)
    u = (u[0] * (1 - 2 * m), u[1] * (1 - 2 * m))
    v = (v[0] * (1 - 2 * m), v[1] * (1 - 2 * m))
    s = simbolo(grupos)
    if marcado:
        cor = (236, 246, 255, 255) if not s else (255, 214, 150, 255)
        fundo = None if not s else (12, 44, 76, 150)
    else:
        cor = (34, 28, 24, 255) if not s else (150, 40, 34, 255)
        fundo = None if not s else (255, 255, 255, 90)
    voxel.texto_na_face(img, str(total), p0, u, v, 0.74, cor, fundo)


def faces_com_pista(presentes):
    """Quais faces recebem número, e em que ordem desenhar.

    Duas regras que a versão anterior quebrava, sem dar erro nenhum:

    1. Só o cubo MAIS EXTERNO de cada fileira mostra a pista. Antes, todo cubo
       com a face livre mostrava — então uma fileira partida ao meio exibia o
       mesmo número duas vezes, um deles boiando no meio do buraco.
    2. A lista sai na ordem do pintor (fundo -> frente), para o número ser
       pintado junto com o seu cubo. Antes, todo o texto vinha depois de todos
       os cubos, então a pista de um cubo de trás aparecia POR CIMA do cubo da
       frente que deveria escondê-la.
    """
    externo_y, externo_x, externo_z = {}, {}, {}
    for (x, y, z) in presentes:
        if externo_y.get((x, z), -1) < y:
            externo_y[(x, z)] = y
        if externo_x.get((y, z), -1) < x:
            externo_x[(y, z)] = x
        if externo_z.get((x, y), -1) < z:
            externo_z[(x, y)] = z

    saida = []
    for (x, y, z) in sorted(presentes, key=lambda p: p[0] + p[1] + p[2]):
        if externo_y.get((x, z)) == y:
            saida.append((x, y, z, "topo"))
        if externo_x.get((y, z)) == x:
            saida.append((x, y, z, "x+"))
        if externo_z.get((x, y)) == z:
            saida.append((x, y, z, "z+"))
    return saida


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

    pistas_de = {}
    if mostrar_pistas:
        for (x, y, z, face) in faces_com_pista(presentes):
            pistas_de.setdefault((x, y, z), []).append(face)

    for (x, y, z) in voxel.ordem(presentes):
        marcado = (x, y, z) in marcados
        if revelado:
            cor = CHAPEU if y >= 5 else PE
            borda = (56, 30, 28) if y >= 5 else (150, 132, 108)
        elif marcado:
            cor, borda = MARCADA, (28, 62, 96)
        else:
            cor, borda = PEDRA, (108, 94, 76)
        voxel.desenhar_cubo(d, x, y, z, ox, oy, cor, borda)

        # a pista sai JUNTO do seu cubo: o cubo desenhado depois cobre o número
        # de trás, como tem que ser.
        for face in pistas_de.get((x, y, z), ()):
            tabela = {"topo": (PY, (x, z)), "x+": (PX, (y, z)), "z+": (PZ, (x, y))}
            t, g = tabela[face][0][tabela[face][1]]
            desenhar_pista(img, x, y, z, ox, oy, face, t, g, marcado)

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
