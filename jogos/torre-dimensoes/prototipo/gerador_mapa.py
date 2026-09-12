#!/usr/bin/env python3
"""Prova barata: mapa de tower defense gerado a partir de pecas desenhadas a mao.

    python3 gerador_mapa.py [quantidade] [semente-inicial]

CODIGO DESCARTAVEL. Mora em prototipo/ de proposito — nao entra no jogo final.
Existe para responder UMA pergunta: da para gerar mapa infinito legivel e valido?

O metodo, em tres passos:
  1. PECAS DESENHADAS A MAO  — 9 blocos 7x7 escritos em texto, logo abaixo
  2. MONTAGEM POR MAQUINA    — um passeio da entrada ate a saida escolhe as pecas
  3. VALIDACAO ANTES DE ENTREGAR — reprovou, joga fora e gera outro

A semente e o mapa: mesma semente, mesmo mapa, sempre.
"""
from __future__ import annotations

import random
import sys
from pathlib import Path

# --- 1. as pecas, desenhadas a mao ------------------------------------------
# '#' caminho por onde o inimigo anda · 'o' ponto de construcao · '.' grama
# As aberturas ficam sempre no meio da borda (indice 3), para as pecas encaixarem.

PECAS: dict[str, tuple[str, ...]] = {
    # leste-oeste
    "reta": (
        ".......",
        "..o.o..",
        ".......",
        "#######",
        ".......",
        "..o.o..",
        ".......",
    ),
    "reta_rica": (
        "..o.o..",
        ".......",
        ".o.o.o.",
        "#######",
        ".o.o.o.",
        ".......",
        "..o.o..",
    ),
    # norte-sul
    "vertical": (
        ".o.#.o.",
        "...#...",
        ".o.#.o.",
        "...#...",
        ".o.#.o.",
        "...#...",
        ".o.#.o.",
    ),
    "vertical_rica": (
        "oo.#.oo",
        ".o.#.o.",
        "oo.#.oo",
        "...#...",
        "oo.#.oo",
        ".o.#.o.",
        "oo.#.oo",
    ),
    # curvas
    "oeste_sul": (
        ".......",
        "..o.o..",
        ".......",
        "####...",
        "...#...",
        ".o.#.o.",
        "...#...",
    ),
    "oeste_norte": (
        "...#...",
        ".o.#.o.",
        "...#...",
        "####...",
        ".......",
        "..o.o..",
        ".......",
    ),
    "norte_leste": (
        "...#...",
        ".o.#.o.",
        "...#...",
        "...####",
        ".......",
        "..o.o..",
        ".......",
    ),
    "sul_leste": (
        ".......",
        "..o.o..",
        ".......",
        "...####",
        "...#...",
        ".o.#.o.",
        "...#...",
    ),
    # sem caminho: so terreno de construcao
    "campo": (
        ".o.o.o.",
        ".......",
        "o.o.o.o",
        ".......",
        ".o.o.o.",
        ".......",
        "o.o.o.o",
    ),
}

LADO = 7

# (de onde entra, para onde sai) -> pecas que servem. Mais de uma = variedade.
ENCAIXE: dict[tuple[str, str], list[str]] = {
    ("O", "L"): ["reta", "reta_rica"],
    ("L", "O"): ["reta", "reta_rica"],
    ("N", "S"): ["vertical", "vertical_rica"],
    ("S", "N"): ["vertical", "vertical_rica"],
    ("O", "S"): ["oeste_sul"],
    ("S", "O"): ["oeste_sul"],
    ("O", "N"): ["oeste_norte"],
    ("N", "O"): ["oeste_norte"],
    ("N", "L"): ["norte_leste"],
    ("L", "N"): ["norte_leste"],
    ("S", "L"): ["sul_leste"],
    ("L", "S"): ["sul_leste"],
}

PASSO = {"N": (0, -1), "S": (0, 1), "L": (1, 0), "O": (-1, 0)}
OPOSTO = {"N": "S", "S": "N", "L": "O", "O": "L"}


# --- 2. montagem por maquina ------------------------------------------------


def passeio(largura: int, altura: int, rng: random.Random) -> list[tuple[int, int]] | None:
    """Passeio da borda oeste ate a borda leste, sem se cruzar."""
    comeco = (0, rng.randrange(altura))
    caminho = [comeco]
    visitados = {comeco}
    for _ in range(largura * altura * 4):
        x, y = caminho[-1]
        if x == largura - 1:
            return caminho
        # anda mais para leste que para os lados, senao vira novelo
        opcoes = ["L", "L", "L", "N", "S"]
        rng.shuffle(opcoes)
        andou = False
        for direcao in opcoes:
            dx, dy = PASSO[direcao]
            nx, ny = x + dx, y + dy
            if not (0 <= nx < largura and 0 <= ny < altura):
                continue
            if (nx, ny) in visitados:
                continue
            caminho.append((nx, ny))
            visitados.add((nx, ny))
            andou = True
            break
        if not andou:
            return None  # empacou: quem chamou tenta outra semente
    return None


def montar(largura: int, altura: int, rng: random.Random) -> tuple[list[list[str]], list] | None:
    caminho = passeio(largura, altura, rng)
    if caminho is None:
        return None

    escolhidas = [["campo"] * largura for _ in range(altura)]
    for i, (x, y) in enumerate(caminho):
        # de onde entrou
        if i == 0:
            entra = "O"
        else:
            ax, ay = caminho[i - 1]
            entra = OPOSTO[direcao_entre((x, y), (ax, ay))]
            entra = direcao_entre((x, y), (ax, ay))
        # para onde sai
        if i == len(caminho) - 1:
            sai = "L"
        else:
            px, py = caminho[i + 1]
            sai = direcao_entre((x, y), (px, py))
        candidatas = ENCAIXE.get((entra, sai))
        if not candidatas:
            return None
        escolhidas[y][x] = rng.choice(candidatas)
    return escolhidas, caminho


def direcao_entre(de: tuple[int, int], para: tuple[int, int]) -> str:
    dx, dy = para[0] - de[0], para[1] - de[1]
    for nome, (px, py) in PASSO.items():
        if (px, py) == (dx, dy):
            return nome
    raise ValueError(f"nao sao vizinhos: {de} {para}")


def desenhar(escolhidas: list[list[str]]) -> list[list[str]]:
    """Junta as pecas numa grade de celulas."""
    altura, largura = len(escolhidas), len(escolhidas[0])
    grade = [["."] * (largura * LADO) for _ in range(altura * LADO)]
    for py in range(altura):
        for px in range(largura):
            peca = PECAS[escolhidas[py][px]]
            for ly in range(LADO):
                for lx in range(LADO):
                    grade[py * LADO + ly][px * LADO + lx] = peca[ly][lx]
    return grade


# --- 3. validacao: reprova antes de entregar --------------------------------

MIN_PONTOS = 14      # pontos de construcao ao alcance do caminho
MIN_COMPRIMENTO = 40  # celulas de caminho
MAX_COMPRIMENTO = 160
ALCANCE = 2           # quao perto um ponto precisa estar do caminho para servir


def validar(grade: list[list[str]]) -> tuple[bool, dict]:
    altura, largura = len(grade), len(grade[0])
    caminho = {(x, y) for y in range(altura) for x in range(largura) if grade[y][x] == "#"}

    entradas = [(0, y) for y in range(altura) if grade[y][0] == "#"]
    saidas = [(largura - 1, y) for y in range(altura) if grade[y][largura - 1] == "#"]

    # o inimigo consegue ir da entrada ate a saida?
    alcancadas: set[tuple[int, int]] = set()
    fila = list(entradas)
    alcancadas.update(fila)
    while fila:
        x, y = fila.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            vizinho = (x + dx, y + dy)
            if vizinho in caminho and vizinho not in alcancadas:
                alcancadas.add(vizinho)
                fila.append(vizinho)
    chega = bool(saidas) and any(s in alcancadas for s in saidas)

    # quantos pontos de construcao ficam ao alcance do caminho?
    uteis = 0
    for y in range(altura):
        for x in range(largura):
            if grade[y][x] != "o":
                continue
            perto = any(
                (x + dx, y + dy) in caminho
                for dx in range(-ALCANCE, ALCANCE + 1)
                for dy in range(-ALCANCE, ALCANCE + 1)
            )
            uteis += 1 if perto else 0

    medidas = {
        "tem_entrada": bool(entradas),
        "tem_saida": bool(saidas),
        "inimigo_chega_ao_fim": chega,
        "comprimento_do_caminho": len(alcancadas),
        "pontos_uteis": uteis,
    }
    motivos = []
    if not entradas:
        motivos.append("sem entrada na borda oeste")
    if not saidas:
        motivos.append("sem saida na borda leste")
    if not chega:
        motivos.append("o caminho nao liga a entrada a saida")
    if not (MIN_COMPRIMENTO <= len(alcancadas) <= MAX_COMPRIMENTO):
        motivos.append(f"caminho de {len(alcancadas)} celulas fora da faixa {MIN_COMPRIMENTO}-{MAX_COMPRIMENTO}")
    if uteis < MIN_PONTOS:
        motivos.append(f"so {uteis} pontos de construcao uteis, minimo {MIN_PONTOS}")
    medidas["motivos"] = motivos
    return (not motivos), medidas


# --- render -----------------------------------------------------------------

CORES = {
    ".": (74, 124, 89),    # grama
    "#": (196, 164, 110),  # caminho de terra
    "o": (110, 160, 200),  # ponto de construcao
}
CELULA = 14


def render(grade: list[list[str]], caminho_png: Path, titulo: str) -> None:
    from PIL import Image, ImageDraw

    altura, largura = len(grade), len(grade[0])
    img = Image.new("RGB", (largura * CELULA, altura * CELULA + 26), (28, 34, 30))
    d = ImageDraw.Draw(img)
    for y in range(altura):
        for x in range(largura):
            cor = CORES[grade[y][x]]
            x0, y0 = x * CELULA, y * CELULA + 26
            d.rectangle([x0, y0, x0 + CELULA - 1, y0 + CELULA - 1], fill=cor)
            if grade[y][x] == "o":
                d.rectangle([x0 + 3, y0 + 3, x0 + CELULA - 4, y0 + CELULA - 4], outline=(230, 240, 255))
    d.text((6, 7), titulo, fill=(225, 232, 226))
    img.save(caminho_png)


# --- principal --------------------------------------------------------------


def gerar_um(semente: int, largura: int = 6, altura: int = 4):
    rng = random.Random(semente)
    for _ in range(200):  # tenta ate sair um montavel
        montado = montar(largura, altura, rng)
        if montado is None:
            continue
        escolhidas, _ = montado
        grade = desenhar(escolhidas)
        passou, medidas = validar(grade)
        return grade, passou, medidas
    return None, False, {"motivos": ["nao consegui montar"]}


def main(argv: list[str]) -> int:
    quantos = int(argv[1]) if len(argv) > 1 else 5
    primeira = int(argv[2]) if len(argv) > 2 else 1
    saida = Path(__file__).parent / "saida"
    saida.mkdir(exist_ok=True)

    aprovados = reprovados = 0
    print(f"{'semente':>8}  {'veredito':<9} {'caminho':>8} {'pontos':>7}  motivo")
    print("-" * 72)
    for i in range(quantos):
        semente = primeira + i
        grade, passou, m = gerar_um(semente)
        if grade is None:
            print(f"{semente:>8}  {'FALHOU':<9} {'-':>8} {'-':>7}  nao montou")
            reprovados += 1
            continue
        veredito = "APROVADO" if passou else "REPROVADO"
        motivo = "" if passou else m["motivos"][0]
        print(
            f"{semente:>8}  {veredito:<9} {m['comprimento_do_caminho']:>8} "
            f"{m['pontos_uteis']:>7}  {motivo}"
        )
        render(grade, saida / f"mapa-{semente}.png", f"semente {semente} · {veredito}")
        aprovados += 1 if passou else 0
        reprovados += 0 if passou else 1

    print("-" * 72)
    print(f"{aprovados} aprovados · {reprovados} reprovados · imagens em {saida.relative_to(Path.cwd())}/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
