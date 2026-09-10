"""A figura escondida dentro do bloco.

Gato foi tentado e descartado: em isométrica, corpo e cabeça da mesma largura
se fundem num blob. Silhueta forte vence detalhe — cogumelo lê de longe.
"""
import math

LARGURA, ALTURA, PROF = 9, 9, 9   # x, y, z


def cogumelo():
    f = set()
    cx, cz = 4, 4

    # pé: coluna com uma leve barriga
    for y in range(0, 5):
        r = 1.15 + (0.5 if y == 0 else 0.0)
        for x in range(LARGURA):
            for z in range(PROF):
                if math.hypot(x - cx, z - cz) <= r:
                    f.add((x, y, z))

    # chapéu: cúpula que abre e fecha
    for i, y in enumerate(range(5, 9)):
        r = 4.05 - i * 1.02
        for x in range(LARGURA):
            for z in range(PROF):
                if math.hypot(x - cx, z - cz) <= r:
                    f.add((x, y, z))
    return f


def anel_chapeu():
    """As bordas do chapéu — usadas só para pintar a figura revelada."""
    return {(x, y, z) for (x, y, z) in cogumelo() if y >= 5}


if __name__ == "__main__":
    import sys
    sys.path.insert(0, "/home/user/joabcostamd/estudos/picross3d")
    import voxel
    fig = cogumelo()
    img, d = voxel.tela()
    ox, oy = int(voxel.LARG * 0.50 * voxel.ESC), int(voxel.ALT * 0.60 * voxel.ESC)
    for (x, y, z) in voxel.ordem(fig):
        cor = (206, 74, 68) if y >= 5 else (232, 216, 190)
        voxel.desenhar_cubo(d, x, y, z, ox, oy, cor, (46, 28, 26))
    print(len(fig), "voxels de", voxel.LARG and 9 * 9 * 9)
    print(voxel.salvar(img, "/tmp/claude-0/-home-user-joabcostamd/311bf898-5005-5e46-881c-9575fcf46fcf/scratchpad/figura.png"))
