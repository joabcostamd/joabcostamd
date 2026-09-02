# -*- coding: utf-8 -*-
"""Uma prancheta para desenhar em grade.

Desenhar 150 imagens caractere a caractere não escala e erra fácil. Aqui o
desenho é descrito por formas — elipses, retângulos, triângulos, linhas — e a
prancheta rasteriza. Simetria sai de graça, que é o que mais ajuda em picross.
"""


class Tela:
    def __init__(self, lado):
        self.lado = lado
        self.g = [[0] * lado for _ in range(lado)]

    # ─── primitivas ───

    def ponto(self, x, y, v=1):
        if 0 <= x < self.lado and 0 <= y < self.lado:
            self.g[int(y)][int(x)] = v
        return self

    def retangulo(self, x, y, largura, altura, v=1, cheio=True):
        for j in range(int(y), int(y + altura)):
            for i in range(int(x), int(x + largura)):
                na_borda = (i in (int(x), int(x + largura) - 1)
                            or j in (int(y), int(y + altura) - 1))
                if cheio or na_borda:
                    self.ponto(i, j, v)
        return self

    def elipse(self, cx, cy, rx, ry, v=1, cheio=True, espessura=1.0):
        for j in range(self.lado):
            for i in range(self.lado):
                d = ((i - cx) / max(rx, 0.001)) ** 2 + ((j - cy) / max(ry, 0.001)) ** 2
                if cheio:
                    if d <= 1.0:
                        self.ponto(i, j, v)
                else:
                    interno = (1.0 - espessura / max(rx, ry)) ** 2
                    if interno <= d <= 1.0:
                        self.ponto(i, j, v)
        return self

    def circulo(self, cx, cy, r, v=1, cheio=True, espessura=1.0):
        return self.elipse(cx, cy, r, r, v, cheio, espessura)

    def triangulo(self, p1, p2, p3, v=1):
        def area(a, b, c):
            return abs((b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1]))
        total = area(p1, p2, p3)
        if total == 0:
            return self
        for j in range(self.lado):
            for i in range(self.lado):
                p = (i + 0.5, j + 0.5)
                soma = area(p, p2, p3) + area(p1, p, p3) + area(p1, p2, p)
                if soma <= total + 0.6:
                    self.ponto(i, j, v)
        return self

    def linha(self, x1, y1, x2, y2, espessura=1, v=1):
        passos = int(max(abs(x2 - x1), abs(y2 - y1)) * 2) + 1
        raio = (espessura - 1) / 2.0
        for k in range(passos + 1):
            t = k / passos
            x = x1 + (x2 - x1) * t
            y = y1 + (y2 - y1) * t
            for dj in range(int(-raio), int(raio) + 1):
                for di in range(int(-raio), int(raio) + 1):
                    self.ponto(round(x) + di, round(y) + dj, v)
        return self

    def pixels(self, coordenadas, v=1):
        for x, y in coordenadas:
            self.ponto(x, y, v)
        return self

    # ─── operações ───

    def espelhar(self, eixo="x"):
        """Copia metade sobre a outra. Simetria é o que mais salva desenho em grade."""
        n = self.lado
        for j in range(n):
            for i in range(n // 2):
                if eixo == "x":
                    self.g[j][n - 1 - i] = self.g[j][i]
                else:
                    self.g[n - 1 - j][i] = self.g[j][i]
        return self

    def moldura(self, espessura=1, v=1):
        return self.retangulo(0, 0, self.lado, self.lado, v, cheio=False) \
            if espessura == 1 else self.retangulo(0, 0, self.lado, self.lado, v, False)

    def deslocar(self, dx, dy):
        novo = [[0] * self.lado for _ in range(self.lado)]
        for j in range(self.lado):
            for i in range(self.lado):
                ni, nj = i + dx, j + dy
                if 0 <= ni < self.lado and 0 <= nj < self.lado:
                    novo[nj][ni] = self.g[j][i]
        self.g = novo
        return self

    def densidade(self):
        return sum(sum(l) for l in self.g) / (self.lado ** 2)

    def arte(self):
        return ["".join("#" if c else "." for c in linha) for linha in self.g]
