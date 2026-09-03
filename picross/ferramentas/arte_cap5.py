# -*- coding: utf-8 -*-
"""Capítulo 5 — 25x25. As obras maiores, para quem já domina o jogo."""
from catalogo_arte import desenho
from pincel import Tela


def _mandala():
    t = Tela(25)
    t.circulo(12, 12, 11.6, cheio=False, espessura=2.5)
    t.circulo(12, 12, 6.4, cheio=False, espessura=2.5)
    t.retangulo(10, 0, 5, 25).retangulo(0, 10, 25, 5)
    return t

def _rosa_ventos():
    t = Tela(25)
    t.retangulo(10, 0, 5, 25).retangulo(0, 10, 25, 5)
    t.triangulo((12, 2), (6, 12), (18, 12)).triangulo((12, 22), (6, 12), (18, 12))
    return t

def _vitral():
    t = Tela(25)
    t.circulo(12, 12, 11.4)
    t.retangulo(11, 1, 3, 23, v=0).retangulo(1, 11, 23, 3, v=0)
    t.circulo(12, 12, 4.4, v=0)
    t.circulo(12, 12, 2.0)
    return t

def _lobo():
    t = Tela(25)
    t.triangulo((12, 23), (2, 8), (22, 8))
    t.triangulo((2, 9), (4, 1), (8, 9)).triangulo((22, 9), (20, 1), (16, 9))
    t.circulo(8, 11, 1.6, v=0).circulo(16, 11, 1.6, v=0)
    t.circulo(12, 17, 2.0, v=0)
    return t

def _aguia():
    t = Tela(25)
    t.circulo(12, 7, 4.4)
    t.triangulo((0, 6), (11, 10), (0, 18)).triangulo((24, 6), (13, 10), (24, 18))
    t.retangulo(10, 10, 5, 10)
    t.triangulo((10, 20), (14, 20), (12, 24))
    return t

def _cavalo():
    t = Tela(25)
    t.elipse(11, 14, 8.4, 5.0)
    t.retangulo(15, 5, 5, 8)
    t.circulo(19, 5, 3.4)
    t.retangulo(5, 18, 3, 7).retangulo(14, 18, 3, 7)
    t.retangulo(1, 10, 4, 2)
    return t

def _elefante2():
    t = Tela(25)
    t.elipse(11, 12, 9.0, 7.0)
    t.elipse(3, 11, 4.0, 5.0)
    t.retangulo(17, 12, 4, 11)
    t.retangulo(5, 19, 4, 6).retangulo(12, 19, 4, 6)
    t.circulo(6, 9, 1.6, v=0)
    return t

def _baleia2():
    t = Tela(25)
    t.elipse(11, 14, 10.4, 5.4)
    t.triangulo((20, 9), (24, 5), (21, 18))
    t.retangulo(8, 5, 2, 5)
    t.elipse(9, 3, 3.4, 2.0)
    t.circulo(5, 12, 1.4, v=0)
    return t

def _dragao2():
    t = Tela(25)
    t.elipse(9, 15, 8.0, 4.4)         # corpo
    t.retangulo(15, 9, 4, 7)          # pescoço
    t.circulo(19, 7, 4.0)             # cabeça
    t.retangulo(22, 5, 3, 3)          # focinho
    t.triangulo((4, 11), (7, 5), (10, 11))
    t.retangulo(0, 17, 5, 3)          # cauda
    t.circulo(19, 6, 1.2, v=0)
    return t

def _fenix2():
    t = Tela(25)
    t.circulo(12, 6, 3.4)             # cabeça
    t.retangulo(9, 9, 7, 10)          # corpo
    t.triangulo((0, 4), (9, 11), (0, 16))
    t.triangulo((24, 4), (15, 11), (24, 16))
    t.triangulo((8, 19), (16, 19), (12, 24))
    t.circulo(12, 5, 1.2, v=0)
    return t

def _castelo2():
    t = Tela(25)
    t.retangulo(3, 9, 19, 16)
    t.retangulo(1, 5, 5, 20).retangulo(19, 5, 5, 20)
    t.retangulo(9, 3, 7, 22)
    for x in (1, 3, 9, 11, 13, 19, 21):
        t.retangulo(x, 2, 2, 2)
    t.retangulo(10, 18, 5, 7, v=0)
    t.retangulo(3, 12, 3, 3, v=0).retangulo(19, 12, 3, 3, v=0)
    return t

def _cidade_noite():
    t = Tela(25)
    t.retangulo(1, 10, 5, 15).retangulo(7, 5, 5, 20).retangulo(13, 12, 4, 13)
    t.retangulo(18, 7, 6, 18)
    for x in range(2, 24, 3):
        for y in range(9, 23, 3):
            t.circulo(x, y, 0.9, v=0)
    t.circulo(20, 3, 2.4)
    return t

def _navio():
    t = Tela(25)
    t.triangulo((0, 18), (24, 18), (20, 24)).triangulo((0, 18), (4, 24), (20, 24))
    t.retangulo(11, 1, 2, 17)
    t.triangulo((11, 3), (2, 9), (11, 15))
    t.triangulo((13, 5), (22, 10), (13, 16))
    return t

def _trem2():
    t = Tela(25)
    t.retangulo(2, 8, 21, 10)
    t.retangulo(2, 4, 6, 5)
    t.retangulo(3, 1, 3, 4)
    for x in range(10, 22, 4):
        t.retangulo(x, 10, 3, 4, v=0)
    for x in (5, 11, 17):
        t.circulo(x, 20, 2.6)
    t.retangulo(0, 23, 25, 2)
    return t

def _foguete2():
    t = Tela(25)
    t.elipse(12, 9, 4.4, 8.4)
    t.circulo(12, 6, 2.0, v=0)
    t.triangulo((7, 12), (7, 20), (2, 20)).triangulo((17, 12), (17, 20), (22, 20))
    t.triangulo((9, 18), (15, 18), (12, 24))
    return t

def _lua_astronauta():
    t = Tela(25)
    t.circulo(12, 8, 5.4)
    t.circulo(12, 8, 3.4, v=0)
    t.retangulo(8, 13, 9, 8)
    t.retangulo(3, 14, 5, 3).retangulo(17, 14, 5, 3)
    t.retangulo(8, 21, 3, 4).retangulo(14, 21, 3, 4)
    return t

def _sistema_solar():
    t = Tela(25)
    t.circulo(6, 12, 6.4)             # sol
    t.circulo(17, 12, 4.4)            # planeta
    t.retangulo(11, 11, 12, 3)        # órbita
    t.circulo(17, 12, 4.4)
    t.circulo(15, 10, 1.4, v=0)
    return t

def _violino():
    t = Tela(25)
    t.elipse(12, 18, 6.4, 6.0)
    t.elipse(12, 11, 4.8, 4.4)
    t.retangulo(11, 1, 3, 10)
    t.retangulo(10, 0, 5, 2)
    t.circulo(9, 17, 1.2, v=0).circulo(15, 17, 1.2, v=0)
    return t

def _piano_cauda():
    t = Tela(25)
    t.elipse(12, 12, 11.4, 8.0)
    t.retangulo(1, 12, 22, 5)
    for x in range(3, 22, 3):
        t.retangulo(x, 13, 1, 3, v=0)
    t.retangulo(4, 20, 2, 5).retangulo(18, 20, 2, 5)
    return t

def _harpa():
    t = Tela(25)
    t.retangulo(3, 2, 4, 21)          # coluna
    t.retangulo(3, 20, 19, 4)         # base
    t.triangulo((5, 2), (22, 2), (22, 21))
    for x in range(9, 21, 3):
        t.retangulo(x, 4, 1, 16, v=0)
    return t

def _bule():
    t = Tela(25)
    t.elipse(11, 15, 8.0, 6.4)
    t.retangulo(6, 7, 10, 3)
    t.retangulo(9, 4, 4, 3)
    t.circulo(20, 14, 4.0, cheio=False, espessura=1.6)
    t.triangulo((3, 12), (0, 9), (3, 17))
    return t

def _relogio_bolso():
    t = Tela(25)
    t.circulo(12, 14, 9.4)
    t.circulo(12, 14, 7.0, v=0)
    t.retangulo(11, 8, 2, 6).retangulo(12, 13, 6, 2)
    t.retangulo(10, 2, 5, 3)
    t.retangulo(11, 0, 3, 2)
    return t

def _camera_antiga():
    t = Tela(25)
    t.retangulo(2, 7, 21, 14)
    t.retangulo(8, 3, 8, 4)
    t.circulo(12, 14, 5.4, v=0)
    t.circulo(12, 14, 3.0)
    t.retangulo(4, 9, 3, 3, v=0)
    return t

def _moto():
    t = Tela(25)
    t.circulo(5, 17, 5.4).circulo(5, 17, 2.6, v=0)
    t.circulo(19, 17, 5.4).circulo(19, 17, 2.6, v=0)
    t.retangulo(4, 10, 16, 4)
    t.retangulo(6, 6, 4, 5)
    t.retangulo(15, 7, 6, 3)
    return t

def _carro_classico():
    t = Tela(25)
    t.retangulo(1, 12, 23, 6)
    t.elipse(12, 12, 9.0, 5.4)
    t.retangulo(6, 7, 5, 5, v=0).retangulo(14, 7, 5, 5, v=0)
    t.circulo(6, 19, 3.4).circulo(18, 19, 3.4)
    t.circulo(6, 19, 1.4, v=0).circulo(18, 19, 1.4, v=0)
    return t

def _torre():
    t = Tela(25)
    t.triangulo((12, 0), (2, 24), (22, 24))
    t.triangulo((12, 6), (6, 18), (18, 18), v=0)
    t.retangulo(4, 18, 17, 2)
    t.retangulo(7, 8, 11, 2)
    return t

def _arco():
    t = Tela(25)
    t.retangulo(2, 4, 21, 21)
    t.circulo(12, 16, 7.4, v=0)
    t.retangulo(5, 16, 15, 9, v=0)
    t.retangulo(1, 1, 23, 3)
    return t

def _girassol2():
    t = Tela(25)
    for ang in range(8):
        import math
        a = ang * math.pi / 4
        t.circulo(12 + 7.5 * math.cos(a), 10 + 7.5 * math.sin(a), 3.0)
    t.circulo(12, 10, 5.4)
    t.circulo(12, 10, 3.0, v=0)
    t.retangulo(11, 15, 3, 10)
    t.elipse(6, 20, 4.4, 2.0)
    return t

def _bonsai():
    t = Tela(25)
    t.elipse(12, 7, 10.4, 5.0)
    t.elipse(6, 12, 5.4, 3.0).elipse(18, 12, 5.4, 3.0)
    t.retangulo(11, 10, 3, 9)
    t.retangulo(4, 19, 17, 4)
    t.retangulo(4, 21, 17, 1, v=0)
    return t

def _cacto_flor():
    t = Tela(25)
    t.retangulo(10, 4, 5, 21)
    t.retangulo(3, 10, 4, 8).retangulo(18, 8, 4, 10)
    t.retangulo(3, 14, 8, 4).retangulo(14, 12, 8, 4)
    t.circulo(12, 2, 2.4)
    return t

def _golfinho2():
    t = Tela(25)
    t.elipse(12, 13, 10.4, 5.0)
    t.triangulo((10, 9), (13, 2), (16, 9))
    t.triangulo((1, 12), (0, 5), (6, 13))
    t.retangulo(21, 14, 4, 2)
    t.circulo(6, 11, 1.2, v=0)
    return t

def _tartaruga2():
    t = Tela(25)
    t.elipse(11, 12, 9.4, 6.4)        # casco
    t.circulo(11, 12, 4.0, v=0)
    t.circulo(11, 12, 1.8)
    t.circulo(21, 12, 3.2)            # cabeça de lado
    t.retangulo(4, 19, 5, 4).retangulo(14, 19, 5, 4)
    t.retangulo(4, 3, 5, 3).retangulo(14, 3, 5, 3)
    return t

def _polvo3():
    t = Tela(25)
    t.circulo(12, 9, 7.4)
    for x in (2, 7, 14, 19):
        t.retangulo(x, 15, 4, 10)
    t.circulo(9, 8, 1.6, v=0).circulo(15, 8, 1.6, v=0)
    return t

def _agua_viva2():
    t = Tela(25)
    t.elipse(12, 8, 9.4, 6.4)
    for x in (3, 8, 14, 19):
        t.retangulo(x, 14, 3, 11)
    t.elipse(12, 8, 5.0, 3.0, v=0)
    return t

def _gato_retrato():
    t = Tela(25)
    t.circulo(12, 14, 9.4)
    t.triangulo((2, 12), (5, 1), (11, 9)).triangulo((22, 12), (19, 1), (13, 9))
    t.elipse(8, 12, 2.0, 2.6, v=0).elipse(16, 12, 2.0, 2.6, v=0)
    t.triangulo((10, 16), (14, 16), (12, 19), v=0)
    t.retangulo(0, 17, 6, 1, v=0).retangulo(19, 17, 6, 1, v=0)
    return t

def _coruja2():
    t = Tela(25)
    t.elipse(12, 14, 9.4, 10.0)
    t.circulo(8, 10, 3.4, v=0).circulo(16, 10, 3.4, v=0)
    t.circulo(8, 10, 1.4).circulo(16, 10, 1.4)
    t.triangulo((10, 13), (14, 13), (12, 17))
    t.triangulo((1, 6), (6, 2), (7, 8)).triangulo((23, 6), (18, 2), (17, 8))
    return t

def _labirinto():
    t = Tela(25)
    t.retangulo(0, 0, 25, 25, cheio=False)
    for y in range(3, 23, 4):
        t.retangulo(2, y, 21, 2)
    for y in range(3, 23, 8):
        t.retangulo(21, y, 2, 6, v=0)
    for y in range(7, 23, 8):
        t.retangulo(2, y, 2, 6, v=0)
    return t

def _xadrez_grande():
    # Xadrez de verdade é sempre ambíguo: com as mesmas pistas, o padrão
    # invertido também vale. Molduras concêntricas dão o mesmo ar gráfico
    # e fecham por lógica.
    t = Tela(25)
    t.retangulo(0, 0, 25, 25)
    t.retangulo(5, 5, 15, 15, v=0)
    t.retangulo(9, 9, 7, 7)
    return t

def _coracao_final():
    t = Tela(25)
    t.circulo(7, 9, 6.8).circulo(17, 9, 6.8)
    t.triangulo((1, 11), (23, 11), (12, 24))
    return t

def _trofeu2():
    t = Tela(25)
    t.elipse(12, 8, 8.4, 7.0)
    t.retangulo(3, 1, 18, 7)
    t.circulo(2, 7, 3.4, cheio=False, espessura=1.4)
    t.circulo(22, 7, 3.4, cheio=False, espessura=1.4)
    t.retangulo(10, 14, 5, 5)
    t.retangulo(5, 19, 15, 3)
    t.retangulo(3, 22, 19, 3)
    return t

NOVOS = [
 ("Mandala", "Comece pelo centro.", "#c9a0dc", _mandala()),
 ("Rosa dos ventos", "Todos os caminhos.", "#e8c15f", _rosa_ventos()),
 ("Vitral", "Luz atravessando.", "#7fd1e0", _vitral()),
 ("Lobo", "Uiva para a lua.", "#9aa4b8", _lobo()),
 ("Águia", "Enxerga de longe.", "#b08a5a", _aguia()),
 ("Cavalo", "A galope.", "#c98a5f", _cavalo()),
 ("Elefante", "Memória boa.", "#94a0ad", _elefante2()),
 ("Baleia", "Soprou água.", "#5a9bc4", _baleia2()),
 ("Dragão", "Guardião do tesouro.", "#e0655f", _dragao2()),
 ("Fênix", "Renasce sempre.", "#e06a4f", _fenix2()),
 ("Fortaleza", "Muralhas altas.", "#9aa4b8", _castelo2()),
 ("Cidade à noite", "Janelas acesas.", "#8f9bb0", _cidade_noite()),
 ("Navio", "Velas cheias.", "#6badc4", _navio()),
 ("Locomotiva", "A todo vapor.", "#6a8fc4", _trem2()),
 ("Nave", "Contagem final.", "#c9d2e0", _foguete2()),
 ("Na Lua", "Um pequeno passo.", "#dfe3ea", _lua_astronauta()),
 ("Sistema solar", "Tudo gira.", "#efc44f", _sistema_solar()),
 ("Violino", "Arco no ar.", "#c98a4b", _violino()),
 ("Piano de cauda", "Concerto inteiro.", "#e8ecf5", _piano_cauda()),
 ("Harpa", "Cordas ao vento.", "#e8c15f", _harpa()),
 ("Bule", "Chá servido.", "#c9a86a", _bule()),
 ("Relógio de bolso", "Herança de família.", "#e8c15f", _relogio_bolso()),
 ("Câmera antiga", "Filme de verdade.", "#8f9bb0", _camera_antiga()),
 ("Motocicleta", "Estrada aberta.", "#e0655f", _moto()),
 ("Carro clássico", "Ainda pega na primeira.", "#6fbcd6", _carro_classico()),
 ("Torre", "Vista de toda a cidade.", "#c9b8a8", _torre()),
 ("Arco", "Passagem antiga.", "#c9b8a8", _arco()),
 ("Girassol", "Segue o sol o dia todo.", "#efc44f", _girassol2()),
 ("Bonsai", "Anos de paciência.", "#7cc47f", _bonsai()),
 ("Cacto florido", "Floresceu no deserto.", "#6fbf73", _cacto_flor()),
 ("Golfinho", "Salto perfeito.", "#6fbcd6", _golfinho2()),
 ("Tartaruga marinha", "Atravessa oceanos.", "#6fae72", _tartaruga2()),
 ("Polvo", "Oito braços enormes.", "#c96a9b", _polvo3()),
 ("Água-viva", "Translúcida.", "#c9a0dc", _agua_viva2()),
 ("Retrato de gato", "Olhando fixo.", "#f0b46a", _gato_retrato()),
 ("Coruja", "Sábia e silenciosa.", "#b08a5a", _coruja2()),
 ("Labirinto", "Encontre a saída.", "#8fa0b8", _labirinto()),
 ("Molduras", "Uma dentro da outra.", "#dfe3ea", _xadrez_grande()),
 ("Coração", "O maior de todos.", "#e0526a", _coracao_final()),
 ("Troféu", "Você terminou o jogo.", "#efc44f", _trofeu2()),
]
for nome, legenda, cor, tela in NOVOS:
    desenho(nome, legenda, cor, tela)
