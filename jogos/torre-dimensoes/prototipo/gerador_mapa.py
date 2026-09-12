#!/usr/bin/env python3
"""Prova barata: mapa no formato Thronefall — castelo no meio, varias frentes.

    python3 gerador_mapa.py [quantidade] [semente-inicial]

CODIGO DESCARTAVEL. Mora em prototipo/ de proposito — nao entra no jogo final.

Corrigido depois que o Joab apontou o erro: a primeira versao fazia mapa de
Kingdom Rush (uma entrada, uma saida). O Thronefall e outra coisa —
  Nordfels:    inimigos de nordeste, leste, sudeste, sul e oeste; tres delas so voadores
  Sturmklamm:  4 pontes ao sul sao as frentes terrestres; morros ao norte, so voador

O metodo:
  1. TERRENO       morros espalhados, que bloqueiam e criam corredores estreitos
  2. FRENTES       3 a 5 pontos de spawn na borda, mais pontos so de voador
  3. CAMINHOS      cada frente desce o campo de distancia ate o castelo
  4. VALIDACAO     toda frente chega? ha pontos de construcao em cada uma? as
                   frentes sao distintas ou viraram um corredor so?
"""
from __future__ import annotations

import random
import sys
from collections import deque
from pathlib import Path

LARG, ALT = 49, 37
CASTELO_RAIO = 2
LONGE = 10**9

GRAMA, MORRO, CAMINHO, PONTO, CASTELO, VOADOR = ".", "^", "#", "o", "C", "v"


def vizinhos(x: int, y: int):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < LARG and 0 <= ny < ALT:
            yield nx, ny


# --- 1. terreno -------------------------------------------------------------


def terreno(rng: random.Random) -> list[list[str]]:
    """Morros em manchas. Sao eles que criam corredor estreito."""
    g = [[GRAMA] * LARG for _ in range(ALT)]
    cx, cy = LARG // 2, ALT // 2
    for _ in range(rng.randint(7, 12)):
        mx, my = rng.randrange(4, LARG - 4), rng.randrange(4, ALT - 4)
        if abs(mx - cx) < 8 and abs(my - cy) < 7:
            continue  # nao enterra o castelo
        raio = rng.randint(2, 5)
        for y in range(max(0, my - raio), min(ALT, my + raio + 1)):
            for x in range(max(0, mx - raio), min(LARG, mx + raio + 1)):
                if (x - mx) ** 2 + ((y - my) * 1.3) ** 2 <= raio * raio:
                    g[y][x] = MORRO
    return g


# --- 2. frentes -------------------------------------------------------------


def frentes(rng: random.Random, g: list[list[str]]) -> tuple[list, list]:
    """Pontos de spawn na borda: alguns terrestres, outros so de voador."""
    borda = []
    for x in range(3, LARG - 3, 2):
        borda += [(x, 0), (x, ALT - 1)]
    for y in range(3, ALT - 3, 2):
        borda += [(0, y), (LARG - 1, y)]
    rng.shuffle(borda)

    terrestres, aereos, usados = [], [], []

    def longe_dos_outros(p, minimo=9):
        return all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= minimo for q in usados)

    for p in borda:
        if len(terrestres) >= rng.randint(3, 5):
            break
        if g[p[1]][p[0]] == GRAMA and longe_dos_outros(p):
            terrestres.append(p)
            usados.append(p)
    for p in borda:
        if len(aereos) >= rng.randint(1, 3):
            break
        if p not in terrestres and longe_dos_outros(p, 7):
            aereos.append(p)
            usados.append(p)
    return terrestres, aereos


# --- 3. caminhos ------------------------------------------------------------


def campo_de_distancia(g: list[list[str]], alvo: tuple[int, int]) -> list[list[int]]:
    """Quantos passos de cada celula livre ate o castelo, contornando morro."""
    d = [[LONGE] * LARG for _ in range(ALT)]
    d[alvo[1]][alvo[0]] = 0
    fila = deque([alvo])
    while fila:
        x, y = fila.popleft()
        for nx, ny in vizinhos(x, y):
            if g[ny][nx] != MORRO and d[ny][nx] == LONGE:
                d[ny][nx] = d[y][x] + 1
                fila.append((nx, ny))
    return d


def cavar(g, d, origem, rng) -> list[tuple[int, int]] | None:
    """Do spawn ate o castelo, sempre descendo o campo — com desempate ao acaso."""
    if d[origem[1]][origem[0]] == LONGE:
        return None
    atual, trilha = origem, [origem]
    while d[atual[1]][atual[0]] > 0:
        x, y = atual
        descem = [(nx, ny) for nx, ny in vizinhos(x, y) if d[ny][nx] < d[y][x]]
        if not descem:
            return None
        # prefere continuar na mesma direcao: caminho fica menos serrilhado
        if len(trilha) > 1:
            ax, ay = trilha[-2]
            reto = [p for p in descem if (p[0] - x, p[1] - y) == (x - ax, y - ay)]
            escolhas = reto * 3 + descem if reto else descem
        else:
            escolhas = descem
        atual = rng.choice(escolhas)
        trilha.append(atual)
    return trilha


def engrossar(g, trilha, largura=1):
    for x, y in trilha:
        for dy in range(-largura, largura + 1):
            for dx in range(-largura, largura + 1):
                nx, ny = x + dx, y + dy
                if 0 <= nx < LARG and 0 <= ny < ALT and g[ny][nx] != CASTELO:
                    g[ny][nx] = CAMINHO


def pontos_de_construcao(g, rng, alcance=3):
    """Terreno livre perto do caminho vira ponto de construcao."""
    caminho = {(x, y) for y in range(ALT) for x in range(LARG) if g[y][x] == CAMINHO}
    for y in range(1, ALT - 1, 2):
        for x in range(1, LARG - 1, 2):
            if g[y][x] != GRAMA:
                continue
            perto = any(
                (x + dx, y + dy) in caminho
                for dx in range(-alcance, alcance + 1)
                for dy in range(-alcance, alcance + 1)
            )
            if perto and rng.random() < 0.72:
                g[y][x] = PONTO


def gerar(semente: int):
    rng = random.Random(semente)
    g = terreno(rng)
    cx, cy = LARG // 2, ALT // 2
    for y in range(cy - CASTELO_RAIO, cy + CASTELO_RAIO + 1):
        for x in range(cx - CASTELO_RAIO, cx + CASTELO_RAIO + 1):
            g[y][x] = CASTELO

    terra, ar = frentes(rng, g)
    d = campo_de_distancia(g, (cx, cy))
    trilhas = []
    for origem in terra:
        t = cavar(g, d, origem, rng)
        if t is None:
            continue
        trilhas.append(t)
        engrossar(g, t)
    for x, y in ar:
        g[y][x] = VOADOR
    pontos_de_construcao(g, rng)
    return g, trilhas, terra, ar


# --- 4. validacao -----------------------------------------------------------

MIN_FRENTES = 3
MIN_PONTOS_POR_FRENTE = 4
MIN_COMPRIMENTO = 12


def validar(g, trilhas, terra, ar) -> tuple[bool, dict]:
    caminho = {(x, y) for y in range(ALT) for x in range(LARG) if g[y][x] == CAMINHO}
    pontos = [(x, y) for y in range(ALT) for x in range(LARG) if g[y][x] == PONTO]

    # cada frente tem pontos de construcao proprios ao alcance?
    por_frente = []
    for t in trilhas:
        celulas = set(t)
        perto = sum(
            1 for (px, py) in pontos
            if any(abs(px - tx) <= 3 and abs(py - ty) <= 3 for tx, ty in celulas)
        )
        por_frente.append(perto)

    # as frentes sao distintas, ou viraram um corredor so?
    partilha = 0.0
    if len(trilhas) >= 2:
        maior = 0.0
        for i in range(len(trilhas)):
            for j in range(i + 1, len(trilhas)):
                a, b = set(trilhas[i]), set(trilhas[j])
                maior = max(maior, len(a & b) / min(len(a), len(b)))
        partilha = maior

    medidas = {
        "frentes_terrestres": len(trilhas),
        "pontos_so_de_voador": len(ar),
        "celulas_de_caminho": len(caminho),
        "pontos_de_construcao": len(pontos),
        "pontos_por_frente": por_frente,
        "maior_trecho_partilhado": round(partilha, 2),
        "menor_frente": min((len(t) for t in trilhas), default=0),
    }
    motivos = []
    if len(trilhas) < MIN_FRENTES:
        motivos.append(f"so {len(trilhas)} frentes chegam ao castelo, minimo {MIN_FRENTES}")
    if len(trilhas) != len(terra):
        motivos.append(f"{len(terra) - len(trilhas)} frente(s) nao alcancam o castelo")
    if por_frente and min(por_frente) < MIN_PONTOS_POR_FRENTE:
        motivos.append(f"uma frente tem so {min(por_frente)} pontos de construcao")
    if medidas["menor_frente"] < MIN_COMPRIMENTO:
        motivos.append(f"frente curta demais: {medidas['menor_frente']} celulas")
    if partilha > 0.75:
        motivos.append(f"as frentes se fundem em um corredor so ({partilha:.0%} partilhado)")
    if not ar:
        motivos.append("nenhum ponto so de voador")
    medidas["motivos"] = motivos
    return (not motivos), medidas


# --- render -----------------------------------------------------------------

CORES = {
    GRAMA: (74, 124, 89),
    MORRO: (58, 74, 64),
    CAMINHO: (196, 164, 110),
    PONTO: (110, 160, 200),
    CASTELO: (232, 206, 122),
    VOADOR: (206, 108, 140),
}
CELULA = 13


def render(g, caminho_png: Path, titulo: str) -> None:
    from PIL import Image, ImageDraw

    img = Image.new("RGB", (LARG * CELULA, ALT * CELULA + 26), (26, 32, 28))
    d = ImageDraw.Draw(img)
    for y in range(ALT):
        for x in range(LARG):
            c = g[y][x]
            x0, y0 = x * CELULA, y * CELULA + 26
            d.rectangle([x0, y0, x0 + CELULA - 1, y0 + CELULA - 1], fill=CORES[c])
            if c == PONTO:
                d.rectangle([x0 + 3, y0 + 3, x0 + CELULA - 4, y0 + CELULA - 4], outline=(235, 243, 255))
            elif c == VOADOR:
                d.ellipse([x0 + 2, y0 + 2, x0 + CELULA - 3, y0 + CELULA - 3], outline=(255, 225, 235))
    d.text((6, 7), titulo, fill=(226, 233, 227))
    img.save(caminho_png)


def main(argv: list[str]) -> int:
    quantos = int(argv[1]) if len(argv) > 1 else 5
    primeira = int(argv[2]) if len(argv) > 2 else 1
    saida = Path(__file__).parent / "saida"
    saida.mkdir(exist_ok=True)
    for antigo in saida.glob("mapa-*.png"):
        antigo.unlink()

    aprov = repro = 0
    print(f"{'semente':>8}  {'veredito':<10} {'frentes':>8} {'voador':>7} {'pontos':>7} {'partilha':>9}  motivo")
    print("-" * 92)
    for i in range(quantos):
        s = primeira + i
        g, trilhas, terra, ar = gerar(s)
        passou, m = validar(g, trilhas, terra, ar)
        print(
            f"{s:>8}  {'APROVADO' if passou else 'REPROVADO':<10} "
            f"{m['frentes_terrestres']:>8} {m['pontos_so_de_voador']:>7} "
            f"{m['pontos_de_construcao']:>7} {m['maior_trecho_partilhado']:>9}  "
            f"{'' if passou else m['motivos'][0]}"
        )
        render(g, saida / f"mapa-{s}.png", f"semente {s} · {'APROVADO' if passou else 'REPROVADO'}")
        aprov += passou
        repro += not passou
    print("-" * 92)
    print(f"{aprov} aprovados · {repro} reprovados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
