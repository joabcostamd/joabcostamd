"""Gera uma folha de contato com todos os desenhos, para auditar a arte de uma vez."""
import json, os, math
from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
dados = json.load(open(os.path.join(RAIZ, "dados", "puzzles.json"), encoding="utf-8"))
fases = dados["fases"]

COLUNAS = 10
CELULA_MAX = 110
PADDING = 12
ROTULO = 18
linhas = math.ceil(len(fases) / COLUNAS)
larg = COLUNAS * (CELULA_MAX + PADDING) + PADDING
alt = linhas * (CELULA_MAX + PADDING + ROTULO) + PADDING

img = Image.new("RGB", (larg, alt), (18, 21, 31))
d = ImageDraw.Draw(img)

for i, f in enumerate(fases):
    cx = PADDING + (i % COLUNAS) * (CELULA_MAX + PADDING)
    cy = PADDING + (i // COLUNAS) * (CELULA_MAX + PADDING + ROTULO)
    lado = f["lado"]
    px = CELULA_MAX / lado
    cor = f["cor"].lstrip("#")
    rgb = tuple(int(cor[j:j+2], 16) for j in (0, 2, 4))
    d.rectangle([cx, cy, cx + CELULA_MAX, cy + CELULA_MAX], fill=(28, 33, 48))
    for y, linha in enumerate(f["solucao"]):
        for x, c in enumerate(linha):
            if c == "#":
                d.rectangle([cx + x * px, cy + y * px,
                             cx + (x + 1) * px - 1, cy + (y + 1) * px - 1], fill=rgb)
    d.text((cx + 2, cy + CELULA_MAX + 3), f"{f['id']}. {f['nome']}", fill=(180, 190, 210))

destino = os.path.join(RAIZ, "capturas", "folha_de_arte.png")
img.save(destino)
print("folha:", destino, img.size)
