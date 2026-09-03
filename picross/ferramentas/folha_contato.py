"""Folha de contato por capítulo — é assim que a arte é auditada de uma vez."""
import json, os, math, sys
from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
dados = json.load(open(os.path.join(RAIZ, "dados", "puzzles.json"), encoding="utf-8"))

COLUNAS = 10
CELULA = 96
PAD = 10
ROTULO = 16

for indice, capitulo in enumerate(dados["capitulos"]):
    ids = [int(i) for i in capitulo["fases"]]
    fases = [f for f in dados["fases"] if f["id"] in ids]
    linhas = math.ceil(len(fases) / COLUNAS)
    img = Image.new("RGB", (COLUNAS * (CELULA + PAD) + PAD,
                            linhas * (CELULA + PAD + ROTULO) + PAD), (18, 21, 31))
    d = ImageDraw.Draw(img)
    for i, f in enumerate(fases):
        cx = PAD + (i % COLUNAS) * (CELULA + PAD)
        cy = PAD + (i // COLUNAS) * (CELULA + PAD + ROTULO)
        px = CELULA / f["lado"]
        cor = f["cor"].lstrip("#")
        rgb = tuple(int(cor[j:j+2], 16) for j in (0, 2, 4))
        d.rectangle([cx, cy, cx + CELULA, cy + CELULA], fill=(28, 33, 48))
        for y, linha in enumerate(f["solucao"]):
            for x, c in enumerate(linha):
                if c == "#":
                    d.rectangle([cx + x * px, cy + y * px,
                                 cx + (x + 1) * px - 1, cy + (y + 1) * px - 1], fill=rgb)
        d.text((cx + 2, cy + CELULA + 2), f"{f['id']}.{f['nome'][:15]}", fill=(175, 185, 205))
    destino = os.path.join(RAIZ, "capturas", "arte_cap%d.png" % (indice + 1))
    img.save(destino)
    print(destino, img.size, len(fases), "fases")
