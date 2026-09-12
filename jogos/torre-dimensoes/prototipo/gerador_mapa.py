#!/usr/bin/env python3
"""Prova barata: mapa no formato Thronefall — plato em camadas, rampas e pontes.

    python3 gerador_mapa.py [quantidade] [semente-inicial]

CODIGO DESCARTAVEL. Mora em prototipo/ de proposito — nao entra no jogo final.

Terceira versao. As duas anteriores estavam erradas, e o Joab corrigiu as duas:
  v1  mapa de Kingdom Rush: uma entrada a oeste, uma saida a leste
  v2  castelo no meio, mas o terreno era morro espalhado
  v3  (esta) PLATO EM CAMADAS — e o que as telas do jogo mostram

O relevo e quem decide as frentes:
  - plato    area plana elevada, com borda de penhasco que NAO da para subir
  - rampa    o unico jeito de trocar de nivel — corredor obrigatorio
  - ponte    passagem estreita sobre a agua — o estrangulamento mais forte
  - castelo  em cima do plato central

E a descoberta que justifica o ponto fixo, da entrevista do criador do Thronefall:
"da para FORCAR o jogador a construir em posicoes arriscadas, e isso impede
automaticamente que ele feche tres muralhas em volta do spawn."
Por isso o gerador marca pontos EXPOSTOS de proposito.
"""
from __future__ import annotations

import random
import sys
import math
from collections import deque
from pathlib import Path

LARG, ALT = 53, 39
LONGE = 10**9
CENTRO = (LARG // 2, ALT // 2)

# Onde o castelo fica e que forma o terreno toma. So numeros.
ARRANJOS = {
    "centro": {"pos": (0.50, 0.50), "forma": "platos",
               "rotulo": "castelo no meio"},
    "sul":    {"pos": (0.72, 0.74), "forma": "platos",
               "rotulo": "castelo embaixo da tela"},
    "escada": {"pos": (0.22, 0.24), "forma": "terracos",
               "rotulo": "escada, castelo la em cima"},
    "canto":  {"pos": (0.22, 0.76), "forma": "platos",
               "rotulo": "castelo no canto"},
}


class Mapa:
    def __init__(self):
        self.nivel = [[0] * LARG for _ in range(ALT)]      # 0 baixo · 1 medio · 2 alto
        self.agua = [[False] * LARG for _ in range(ALT)]
        self.rampa = [[False] * LARG for _ in range(ALT)]
        self.ponte = [[False] * LARG for _ in range(ALT)]
        self.caminho = [[False] * LARG for _ in range(ALT)]
        self.ponto = [[False] * LARG for _ in range(ALT)]
        self.exposto = [[False] * LARG for _ in range(ALT)]
        self.castelo = [[False] * LARG for _ in range(ALT)]

    def dentro(self, x, y):
        return 0 <= x < LARG and 0 <= y < ALT

    def passa(self, a, b) -> bool:
        """Da para ir de a ate b a pe?"""
        (x, y), (nx, ny) = a, b
        if not self.dentro(nx, ny):
            return False
        if self.agua[ny][nx] and not self.ponte[ny][nx]:
            return False
        if self.agua[y][x] and not self.ponte[y][x]:
            return False
        salto = abs(self.nivel[ny][nx] - self.nivel[y][x])
        if salto == 0:
            return True
        passagem = (self.rampa[y][x] or self.rampa[ny][nx]
                    or self.ponte[y][x] or self.ponte[ny][nx])
        if salto == 1 and passagem:
            return True
        return False  # penhasco

    def vizinhos(self, x, y):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if self.dentro(x + dx, y + dy):
                yield x + dx, y + dy


# --- 1. relevo --------------------------------------------------------------


def mancha(m: Mapa, cx, cy, raio, nivel, rng):
    """Plato de contorno irregular, para nao parecer circulo de computador."""
    for y in range(max(0, cy - raio - 2), min(ALT, cy + raio + 3)):
        for x in range(max(0, cx - raio - 3), min(LARG, cx + raio + 4)):
            d = ((x - cx) / 1.35) ** 2 + (y - cy) ** 2
            ruido = rng.uniform(-0.22, 0.22) * raio * raio
            if d + ruido <= raio * raio:
                m.nivel[y][x] = max(m.nivel[y][x], nivel)


# Cada dimensao puxa o relevo para um lado. So numeros — a roupa vem na maquete.
PERFIL = {
    "floresta":  {"platos": (3, 4), "raio": (5, 8), "rio": 0.65, "rio_larg": (2, 3)},
    "montanha":  {"platos": (5, 7), "raio": (4, 6), "rio": 0.25, "rio_larg": (1, 2)},
    "rio":       {"platos": (1, 2), "raio": (5, 7), "rio": 1.00, "rio_larg": (3, 5)},
    "deserto":   {"platos": (2, 4), "raio": (6, 9), "rio": 0.00, "rio_larg": (1, 1)},
    "vazio":     {"platos": (4, 6), "raio": (3, 6), "rio": 0.45, "rio_larg": (2, 4)},
}


def relevo(m: Mapa, rng, perfil=None, alvo=None):
    pf = perfil or PERFIL["floresta"]
    cx, cy = alvo or CENTRO
    mancha(m, cx, cy, rng.randint(6, 8), 2, rng)          # plato do castelo
    for _ in range(rng.randint(*pf["platos"])):            # platos medios em volta
        ang = rng.uniform(0, 6.283)
        dist = rng.randint(11, 17)
        mx = int(cx + dist * 1.3 * math.cos(ang))
        my = int(cy + dist * math.sin(ang))
        if 5 < mx < LARG - 5 and 4 < my < ALT - 4:
            mancha(m, mx, my, rng.randint(*pf["raio"]), 1, rng)
    mancha(m, cx, cy, rng.randint(9, 11), max(1, 1), rng)  # saia media no castelo
    mancha(m, cx, cy, rng.randint(6, 8), 2, rng)           # redesenha o topo por cima


def terracos(m: Mapa, rng, alvo, faixas=3):
    """Escada: o terreno sobe em degraus ate o castelo no alto da TELA.

    A camera e isometrica, entao o que fica no alto da tela e x+y pequeno.
    Por isso o corte dos degraus acompanha x+y — assim, na tela, os andares
    saem empilhados um em cima do outro, como uma arquibancada.

    O unico jeito de subir e a rampa de cada degrau. Quem vem la de baixo
    sobe todos eles, um atras do outro.
    """
    cx, cy = alvo
    smax = LARG + ALT - 2
    fases = [rng.uniform(0, 6.283) for _ in range(faixas - 1)]
    for y in range(ALT):
        for x in range(LARG):
            s_cel = x + y
            nivel = 0
            for i in range(faixas - 1, 0, -1):
                base = smax * ((faixas - i) / faixas)   # nivel alto = x+y pequeno
                ondula = math.sin((x - y) * 0.11 + fases[i - 1]) * 3.2
                if s_cel < base + ondula:
                    nivel = i
                    break
            m.nivel[y][x] = nivel
    mancha(m, cx, cy, 7, faixas - 1, rng)         # o topo do castelo, arredondado


def rampas_terraco(m: Mapa, rng, faixas=3):
    """Tres rampas por degrau, espalhadas. Fora delas o degrau e penhasco."""
    for alvo in range(faixas - 1, 0, -1):
        bordas = [(x, y) for y in range(2, ALT - 2) for x in range(2, LARG - 2)
                  if m.nivel[y][x] == alvo and not m.agua[y][x]
                  and any(m.nivel[ny][nx] == alvo - 1 for nx, ny in m.vizinhos(x, y))]
        rng.shuffle(bordas)
        postas = []
        for (x, y) in bordas:
            if len(postas) >= 3:
                break
            if any(abs(x - px) + abs(y - py) < 14 for px, py in postas):
                continue
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    if m.dentro(x + dx, y + dy) and not m.agua[y + dy][x + dx]:
                        m.rampa[y + dy][x + dx] = True
            postas.append((x, y))


def rio(m: Mapa, rng, perfil=None):
    """Um rio atravessando, com 2 a 4 pontes. Sao os estrangulamentos fortes."""
    pf = perfil or PERFIL["floresta"]
    if rng.random() > pf["rio"]:
        return
    vertical = rng.random() < 0.5
    pos = rng.randrange(8, (ALT if vertical else LARG) - 8)
    largura = rng.randint(*pf["rio_larg"])
    for t in range(LARG if vertical else ALT):
        pos += rng.choice((-1, 0, 0, 1))
        for w in range(-largura, largura + 1):
            x, y = (t, pos + w) if vertical else (pos + w, t)
            if m.dentro(x, y) and m.nivel[y][x] < 2:
                m.agua[y][x] = True
                m.nivel[y][x] = 0
    # pontes
    candidatas = [(x, y) for y in range(2, ALT - 2) for x in range(2, LARG - 2) if m.agua[y][x]]
    rng.shuffle(candidatas)
    postas = []
    for (x, y) in candidatas:
        if len(postas) >= rng.randint(2, 4):
            break
        if any(abs(x - px) + abs(y - py) < 10 for px, py in postas):
            continue
        for w in range(-largura - 2, largura + 3):
            bx, by = (x, y + w) if vertical else (x + w, y)
            if m.dentro(bx, by) and m.agua[by][bx]:
                m.ponte[by][bx] = True
        postas.append((x, y))


def rampas(m: Mapa, rng):
    """Onde muda de nivel, abre passagem so em alguns pontos. O resto e penhasco."""
    for alvo in (2, 1):
        bordas = []
        for y in range(1, ALT - 1):
            for x in range(1, LARG - 1):
                if m.nivel[y][x] != alvo or m.agua[y][x]:
                    continue
                if any(m.nivel[ny][nx] == alvo - 1 for nx, ny in m.vizinhos(x, y)):
                    bordas.append((x, y))
        rng.shuffle(bordas)
        postas = []
        for (x, y) in bordas:
            if len(postas) >= rng.randint(3, 5):
                break
            if any(abs(x - px) + abs(y - py) < 9 for px, py in postas):
                continue
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if m.dentro(x + dx, y + dy) and not m.agua[y + dy][x + dx]:
                        m.rampa[y + dy][x + dx] = True
            postas.append((x, y))


# --- 2. frentes e caminhos --------------------------------------------------


def campo(m: Mapa, alvo) -> list[list[int]]:
    d = [[LONGE] * LARG for _ in range(ALT)]
    d[alvo[1]][alvo[0]] = 0
    fila = deque([alvo])
    while fila:
        x, y = fila.popleft()
        for nx, ny in m.vizinhos(x, y):
            if d[ny][nx] == LONGE and m.passa((x, y), (nx, ny)):
                d[ny][nx] = d[y][x] + 1
                fila.append((nx, ny))
    return d


def frentes(m: Mapa, d, rng, minimo_passos=18):
    """De onde o inimigo entra. Tres regras, nessa ordem:

    1. nasce na parte BAIXA do mapa (nivel 0) — ninguem aparece no topo do plato
    2. fica a pelo menos `minimo_passos` de caminhada do castelo, senao a frente
       nasce colada e nao da tempo de defender
    3. as entradas ficam espalhadas; se o castelo esta num canto e nao cabe
       espalhar tanto, aperta o espacamento ate conseguir 3 frentes
    """
    borda = [(x, y) for y in range(ALT) for x in range(LARG)
             if (x in (0, LARG - 1) or y in (0, ALT - 1)) and d[y][x] < LONGE]
    baixa = [p for p in borda if m.nivel[p[1]][p[0]] == 0]
    if len(baixa) >= 12:
        borda = baixa
    longe = [p for p in borda if d[p[1]][p[0]] >= minimo_passos]
    if len(longe) >= 8:
        borda = longe
    rng.shuffle(borda)
    quantas = rng.randint(3, 5)
    escolhidas = []
    for espaco in (16, 13, 10, 7):
        escolhidas = []
        for p in borda:
            if len(escolhidas) >= quantas:
                break
            if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= espaco for q in escolhidas):
                escolhidas.append(p)
        if len(escolhidas) >= 3:
            break
    return escolhidas


def cavar(m: Mapa, d, origem, rng):
    atual, trilha = origem, [origem]
    while d[atual[1]][atual[0]] > 0:
        x, y = atual
        descem = [(nx, ny) for nx, ny in m.vizinhos(x, y)
                  if m.passa((x, y), (nx, ny)) and d[ny][nx] < d[y][x]]
        if not descem:
            return None
        if len(trilha) > 1:
            ax, ay = trilha[-2]
            reto = [p for p in descem if (p[0] - x, p[1] - y) == (x - ax, y - ay)]
            descem = reto * 4 + descem if reto else descem
        atual = rng.choice(descem)
        trilha.append(atual)
        if len(trilha) > LARG * ALT:
            return None
    return trilha


def pintar(m: Mapa, trilha):
    for x, y in trilha:
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if m.dentro(x + dx, y + dy) and not m.castelo[y + dy][x + dx]:
                    if not m.agua[y + dy][x + dx] or m.ponte[y + dy][x + dx]:
                        m.caminho[y + dy][x + dx] = True


def pontos(m: Mapa, rng, alcance=4, alvo=None):
    """Ponto de construcao perto do caminho. Alguns EXPOSTOS de proposito."""
    trilha = {(x, y) for y in range(ALT) for x in range(LARG) if m.caminho[y][x]}
    for y in range(1, ALT - 1, 2):
        for x in range(1, LARG - 1, 2):
            if m.caminho[y][x] or m.agua[y][x] or m.castelo[y][x]:
                continue
            dist = min((abs(x - tx) + abs(y - ty) for tx, ty in trilha), default=99)
            if dist > alcance or rng.random() > 0.7:
                continue
            m.ponto[y][x] = True
            # exposto: colado no caminho e longe do castelo
            ax, ay = alvo or CENTRO
            if dist <= 2 and abs(x - ax) + abs(y - ay) > 14:
                m.exposto[y][x] = True


def gerar(semente: int, bioma: str = "floresta", arranjo: str = "centro"):
    rng = random.Random(semente)
    pf = PERFIL.get(bioma, PERFIL["floresta"])
    ar = ARRANJOS.get(arranjo, ARRANJOS["centro"])
    m = Mapa()
    m.bioma, m.arranjo = bioma, arranjo
    cx = max(6, min(LARG - 7, int(LARG * ar["pos"][0])))
    cy = max(5, min(ALT - 6, int(ALT * ar["pos"][1])))
    m.castelo_pos = (cx, cy)

    escada = ar["forma"] == "terracos"
    if escada:
        terracos(m, rng, (cx, cy))
    else:
        relevo(m, rng, pf, (cx, cy))
    rio(m, rng, pf)
    if escada:
        rampas_terraco(m, rng)
    else:
        rampas(m, rng)
    for y in range(cy - 2, cy + 3):
        for x in range(cx - 3, cx + 4):
            m.castelo[y][x] = True
            m.agua[y][x] = False

    d = campo(m, (cx, cy))
    origens = frentes(m, d, rng)
    trilhas = []
    for o in origens:
        t = cavar(m, d, o, rng)
        if t:
            trilhas.append(t)
            pintar(m, t)
    pontos(m, rng, alvo=(cx, cy))
    return m, trilhas, origens


# --- 3. validacao -----------------------------------------------------------


def validar(m: Mapa, trilhas, origens):
    pts = [(x, y) for y in range(ALT) for x in range(LARG) if m.ponto[y][x]]
    expostos = sum(1 for y in range(ALT) for x in range(LARG) if m.exposto[y][x])

    por_frente, com_estrangulamento = [], 0
    for t in trilhas:
        cel = set(t)
        por_frente.append(sum(1 for (px, py) in pts
                              if any(abs(px - tx) <= 4 and abs(py - ty) <= 4 for tx, ty in cel)))
        if any(m.rampa[y][x] or m.ponte[y][x] for x, y in t):
            com_estrangulamento += 1

    partilha = 0.0
    for i in range(len(trilhas)):
        for j in range(i + 1, len(trilhas)):
            a, b = set(trilhas[i]), set(trilhas[j])
            partilha = max(partilha, len(a & b) / min(len(a), len(b)))

    med = {
        "frentes": len(trilhas),
        "frentes_com_estrangulamento": com_estrangulamento,
        "pontos": len(pts),
        "pontos_expostos": expostos,
        "menor_frente": min((len(t) for t in trilhas), default=0),
        "partilha": round(partilha, 2),
    }
    motivos = []
    if len(trilhas) < 3:
        motivos.append(f"so {len(trilhas)} frentes chegam ao castelo, minimo 3")
    if len(trilhas) != len(origens):
        motivos.append(f"{len(origens) - len(trilhas)} frente(s) nao alcancam o castelo")
    if por_frente and min(por_frente) < 4:
        motivos.append(f"uma frente tem so {min(por_frente)} pontos de construcao")
    if med["menor_frente"] < 14:
        motivos.append(f"frente curta demais: {med['menor_frente']} celulas")
    if partilha > 0.75:
        motivos.append(f"as frentes viram um corredor so ({partilha:.0%} partilhado)")
    if com_estrangulamento < max(2, len(trilhas) - 1):
        motivos.append(f"so {com_estrangulamento} frentes passam por rampa ou ponte")
    if expostos < 2:
        motivos.append(f"so {expostos} pontos de construcao expostos, minimo 2")
    med["motivos"] = motivos
    return (not motivos), med


# --- render -----------------------------------------------------------------

CELULA = 12
COR_NIVEL = [(86, 138, 96), (108, 162, 110), (136, 186, 124)]
COR_AGUA = (72, 148, 214)
COR_PONTE = (168, 132, 88)
COR_RAMPA = (188, 172, 116)
COR_CAMINHO = (204, 172, 116)
COR_PONTO = (96, 152, 200)
COR_EXPOSTO = (214, 110, 96)
COR_CASTELO = (238, 208, 118)


def render(m: Mapa, destino: Path, titulo: str):
    from PIL import Image, ImageDraw

    img = Image.new("RGB", (LARG * CELULA, ALT * CELULA + 26), (24, 30, 26))
    d = ImageDraw.Draw(img)
    for y in range(ALT):
        for x in range(LARG):
            if m.castelo[y][x]:
                cor = COR_CASTELO
            elif m.ponte[y][x]:
                cor = COR_PONTE
            elif m.agua[y][x]:
                cor = COR_AGUA
            elif m.caminho[y][x]:
                cor = COR_CAMINHO
            elif m.rampa[y][x]:
                cor = COR_RAMPA
            else:
                cor = COR_NIVEL[m.nivel[y][x]]
            x0, y0 = x * CELULA, y * CELULA + 26
            d.rectangle([x0, y0, x0 + CELULA - 1, y0 + CELULA - 1], fill=cor)
            # sombra dura na borda de penhasco, como nas telas do jogo
            if m.dentro(x, y - 1) and m.nivel[y - 1][x] > m.nivel[y][x] and not m.agua[y][x]:
                d.rectangle([x0, y0, x0 + CELULA - 1, y0 + 2], fill=(38, 48, 40))
            if m.ponto[y][x]:
                c = COR_EXPOSTO if m.exposto[y][x] else COR_PONTO
                d.rectangle([x0 + 2, y0 + 2, x0 + CELULA - 3, y0 + CELULA - 3],
                            fill=c, outline=(240, 246, 250))
    d.text((6, 7), titulo, fill=(228, 234, 228))
    img.save(destino)


def main(argv):
    quantos = int(argv[1]) if len(argv) > 1 else 6
    primeira = int(argv[2]) if len(argv) > 2 else 1
    saida = Path(__file__).parent / "saida"
    saida.mkdir(exist_ok=True)
    for antigo in saida.glob("mapa-*.png"):
        antigo.unlink()

    aprov = 0
    print(f"{'semente':>8} {'veredito':<10} {'frentes':>8} {'c/estrang':>10} {'pontos':>7} {'expostos':>9} {'partilha':>9}  motivo")
    print("-" * 104)
    for i in range(quantos):
        s = primeira + i
        m, trilhas, origens = gerar(s)
        ok, med = validar(m, trilhas, origens)
        print(f"{s:>8} {'APROVADO' if ok else 'REPROVADO':<10} {med['frentes']:>8} "
              f"{med['frentes_com_estrangulamento']:>10} {med['pontos']:>7} "
              f"{med['pontos_expostos']:>9} {med['partilha']:>9}  {'' if ok else med['motivos'][0]}")
        render(m, saida / f"mapa-{s}.png", f"semente {s} · {'APROVADO' if ok else 'REPROVADO'}")
        aprov += ok
    print("-" * 104)
    print(f"{aprov} aprovados · {quantos - aprov} reprovados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
