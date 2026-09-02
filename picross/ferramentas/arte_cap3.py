# -*- coding: utf-8 -*-
"""Capítulo 3 — 15x15. Criaturas e figuras maiores."""
from catalogo_arte import desenho
from pincel import Tela

D = [
 ("Caneca", "Café antes de continuar.", "#b08a5a", ["...............","..##########...","..##########.##","..##########.##","..#########..##","..#########..##","..##########.##","..##########.##","..##########...","...########....","...............",".#############.",".#############.","...............","..............."]),
 ("Baleia", "O maior desenho do capítulo.", "#5a9bc4", ["...............","...............","....#######....","..###########..",".#############.","###.###########","###############","###############",".#############.","..###########..","##..#######....","###..######....","####..####.....","...............","..............."]),
 ("Ampulheta maior", "O tempo passa dos dois lados.", "#c9a0dc", ["###############","###############",".#############.","..###########..","...#########...","....#######....",".....#####.....","......###......",".....#####.....","....#######....","...#########...","..###########..",".#############.","###############","###############"]),
 ("Castelo", "Torres, muralha e portão.", "#9aa4b8", ["#.#.#.....#.#.#","###############","#####.....#####","#####.....#####","###############","#.#.#######.#.#","###############","###############","####.#####.####","###############","###############","#####.....#####","#####.###.#####","#####.###.#####","###############"]),
 ("Diamante", "Vale a paciência.", "#7fd1e0", [".......#.......","......###......",".....#####.....","....#######....","...#########...","..###########..",".#############.","###############",".#############.","..###########..","...#########...","....#######....",".....#####.....","......###......",".......#......."]),
 ("Balão", "Solto no ar.", "#e8825f", ["....#######....","...#########...","..###########..",".#############.",".#############.",".#############.",".#############.","..###########..","...#########...","....#######....",".....#####.....","......###......","......###......",".....#####.....","......###......"]),
 ("Caveira", "Sem susto, só ossos.", "#dfe3ea", ["...#########...","..###########..",".#############.","###############","###############","##.###...###.##","#...##...##...#","#...##...##...#","##.###...###.##","###############","#####.###.#####",".####.###.####.","..###########..","..#.#.#.#.#.#..","..###########.."]),
 ("Tartaruga", "Devagar e sempre.", "#6fae72", ["...............",".....#####.....","...#########...","..###########..",".#############.","##.##.###.##.##","###############","##.##.###.##.##",".#############.","..###########..","...#########...","..##.....##.###","..##.....##.###","............###","..............."]),
 ("Sapo", "Espera a mosca passar.", "#7fc46a", ["..###.....###..",".#####...#####.",".##.##...##.##.",".#####...#####.","..#############","###############","###############","##.#########.##","###############",".#############.","..###########..","###.........###","##...........##","#.............#","..............."]),
 ("Peão", "Só anda para frente.", "#c98a4b", ["......###......","......###......","......###......",".....#####.....","....#######....","....#######....",".....#####.....","......###......","......###......",".....#####.....","....#######....","...#########...","..###########..","..###########..",".#############."]),
 ("Chapéu", "De bruxa, claro.", "#8f7ac4", [".......#.......","......###......","......###......",".....#####.....",".....#####.....","....#######....","....#######....","...#########...","...#.......#...","...#########...","..###########..","###############","###############","###############",".#############."]),
 ("Elefante", "Nunca esquece uma fase.", "#94a0ad", ["...............","..#########....",".###########...","###############","###.#######.###","###########..##","###########..##","##########...##","##########..###","#########...###",".########..####",".##..##....####",".##..##....##..",".##..##....##..","..............."]),
 ("Veleiro", "Rumo ao próximo capítulo.", "#6badc4", ["......#........","......##.......","......###......","......####.....","......#####....","......######...","......#######..","......#........","......#........","###############",".#############.","..###########..","...#########...","...............","..............."]),
 ("Estrela", "Cinco pontas certinhas.", "#f0cf5f", [".......#.......",".......#.......","......###......","......###......","#####.###.#####",".#############.","..###########..","...#########...","....#######....","...#########...","..####...####..",".####.....####.","###.........###","##...........##","#.............#"]),
 ("Coração maior", "O de sempre, agora grande.", "#e0526a", ["...............","..####...####..",".######.######.","###############","###############","###############","###############",".#############.",".#############.","..###########..","...#########...","....#######....",".....#####.....","......###......",".......#......."]),
]
for nome, legenda, cor, a in D:
    desenho(nome, legenda, cor, a)

# ─── novos, desenhados com a prancheta ───

def _coelho():
    t = Tela(15)
    t.elipse(7, 10, 4.6, 4.2)
    t.elipse(7, 5.5, 3.4, 3.0)
    t.elipse(5, 2, 1.2, 2.4).elipse(9, 2, 1.2, 2.4)
    t.ponto(6, 5, 0).ponto(8, 5, 0)
    return t

def _urso():
    t = Tela(15)
    t.circulo(7, 9, 5.2)
    t.circulo(3, 3.5, 2.2).circulo(11, 3.5, 2.2)
    t.circulo(4, 7.5, 1.1, v=0).circulo(10, 7.5, 1.1, v=0)
    t.retangulo(6, 10, 3, 2, v=0)
    return t

def _porco():
    t = Tela(15)
    t.elipse(7, 8.5, 6.2, 5.0)
    t.triangulo((2, 5), (4, 1), (6, 5)).triangulo((12, 5), (10, 1), (8, 5))
    t.elipse(7, 10, 2.4, 1.6, v=0)
    t.ponto(5, 7, 0).ponto(9, 7, 0)
    return t

def _ovelha():
    t = Tela(15)
    t.circulo(4, 7, 3.4).circulo(10, 7, 3.4).circulo(7, 5, 3.4).circulo(7, 9, 3.6)
    t.elipse(7, 11.5, 2.2, 2.2)
    t.ponto(6, 11, 0).ponto(8, 11, 0)
    return t

def _galinha():
    t = Tela(15)
    t.elipse(7, 9, 5.0, 4.4)
    t.circulo(9.5, 4, 2.4)
    t.retangulo(9, 1, 2, 2)
    t.triangulo((12, 4), (14, 3), (12, 5))
    return t

def _pato():
    t = Tela(15)
    t.elipse(6.5, 9.5, 5.4, 3.6)
    t.circulo(10, 5, 2.6)
    t.retangulo(12, 4, 3, 2)
    t.ponto(10, 4, 0)
    return t

def _golfinho():
    t = Tela(15)
    t.elipse(7, 7.5, 6.4, 3.2)
    t.triangulo((6, 5), (8, 1), (10, 5))
    t.triangulo((1, 7), (0, 3), (4, 7))
    t.retangulo(12, 8, 3, 1)
    return t

def _tubarao():
    t = Tela(15)
    t.elipse(7, 9, 6.4, 3.4)
    t.triangulo((5, 6), (7, 1), (9, 6))
    t.triangulo((0, 5), (0, 13), (4, 9))
    t.retangulo(6, 11, 3, 2)
    t.circulo(11, 8, 1.0, v=0)
    return t

def _caranguejo():
    t = Tela(15)
    t.elipse(7, 8, 5.4, 3.4)
    t.circulo(2.5, 5, 2.2).circulo(11.5, 5, 2.2)
    t.retangulo(1, 11, 3, 1).retangulo(11, 11, 3, 1)
    t.ponto(5, 7, 0).ponto(9, 7, 0)
    return t

def _cavalo_marinho():
    t = Tela(15)
    t.circulo(8, 4, 2.8)              # cabeça
    t.retangulo(10, 3, 4, 2)          # focinho
    t.elipse(7, 9, 3.0, 4.4)          # tronco
    t.retangulo(5, 12, 3, 3)          # cauda enrolada
    t.retangulo(3, 12, 2, 2)
    t.ponto(8, 3, 0)
    return t

def _agua_viva():
    t = Tela(15)
    t.elipse(7, 5, 5.4, 4.0)
    for x in (3, 6, 9, 12):
        t.retangulo(x, 9, 1, 5)
    return t

def _joaninha():
    t = Tela(15)
    t.circulo(7, 9, 5.6)
    t.circulo(7, 3, 3.0)              # cabeça separada, para ler como bicho
    t.retangulo(7, 5, 1, 9, v=0)
    for x, y in [(4, 8), (10, 8), (4, 12), (10, 12)]:
        t.circulo(x, y, 1.2, v=0)
    return t

def _aranha():
    t = Tela(15)
    t.circulo(7, 9, 4.0).circulo(7, 4, 2.4)
    for y in (5, 8, 11):
        t.retangulo(0, y, 3, 1).retangulo(12, y, 3, 1)
        t.retangulo(0, y - 1, 1, 2).retangulo(14, y - 1, 1, 2)
    return t

def _cobra():
    t = Tela(15)
    t.retangulo(1, 2, 13, 3)
    t.retangulo(11, 5, 3, 3)
    t.retangulo(1, 8, 13, 3)
    t.retangulo(1, 11, 3, 2)
    t.retangulo(1, 13, 13, 2)
    return t

def _lagarto():
    t = Tela(15)
    t.elipse(7, 8, 4.4, 2.2)          # corpo
    t.circulo(11.5, 7, 2.4)           # cabeça
    t.retangulo(0, 8, 4, 2)           # cauda
    t.retangulo(4, 4, 2, 4).retangulo(8, 4, 2, 4)
    t.retangulo(4, 10, 2, 4).retangulo(8, 10, 2, 4)
    t.ponto(12, 6, 0)
    return t

def _rato():
    t = Tela(15)
    t.elipse(7, 9, 4.6, 3.8)
    t.circulo(4, 5, 2.6).circulo(10, 5, 2.6)
    t.circulo(7, 7, 2.6)
    t.retangulo(12, 11, 3, 1)
    return t

def _esquilo():
    t = Tela(15)
    t.elipse(5, 10, 3.4, 4.4)
    t.circulo(5, 5, 3.0)
    t.elipse(11, 8, 3.4, 5.0)
    t.elipse(11, 8, 1.6, 3.0, v=0)
    t.ponto(4, 4, 0)
    return t

def _panda():
    t = Tela(15)
    t.circulo(7, 8, 5.4)
    t.circulo(3, 3, 2.4).circulo(11, 3, 2.4)
    t.circulo(4.5, 7, 1.8, v=0).circulo(9.5, 7, 1.8, v=0)
    t.circulo(7, 10, 1.2, v=0)
    return t

def _macaco():
    t = Tela(15)
    t.circulo(7, 8, 5.0)
    t.circulo(1.5, 8, 2.2).circulo(12.5, 8, 2.2)
    t.elipse(7, 10, 3.4, 2.4, v=0)
    t.retangulo(5, 5, 2, 2, v=0).retangulo(8, 5, 2, 2, v=0)
    return t

def _girafa():
    t = Tela(15)
    t.retangulo(6, 3, 3, 8)
    t.elipse(4, 12, 4.4, 2.6)
    t.circulo(8, 2, 2.2)
    t.retangulo(7, 0, 1, 2).retangulo(9, 0, 1, 2)
    return t

def _zebra():
    t = Tela(15)
    t.elipse(6, 9, 5.4, 3.4)
    t.circulo(12, 5, 2.6)
    t.retangulo(10, 6, 3, 3)
    t.retangulo(2, 12, 2, 3).retangulo(8, 12, 2, 3)
    t.retangulo(4, 6, 1, 7, v=0).retangulo(7, 6, 1, 7, v=0)
    t.ponto(13, 4, 0)
    return t

def _tigre():
    t = Tela(15)
    t.circulo(7, 8, 5.6)
    t.triangulo((2, 4), (4, 0), (6, 4)).triangulo((12, 4), (10, 0), (8, 4))
    for y in (5, 8, 11):
        t.retangulo(1, y, 2, 1, v=0).retangulo(12, y, 2, 1, v=0)
    t.ponto(5, 7, 0).ponto(9, 7, 0)
    return t

def _dragao():
    t = Tela(15)
    t.elipse(6, 10, 5.0, 3.0)
    t.circulo(11, 6, 3.0)
    t.retangulo(8, 7, 3, 3)
    t.triangulo((3, 7), (5, 3), (7, 7))
    t.retangulo(0, 11, 4, 2)
    t.ponto(11, 5, 0)
    return t

def _unicornio():
    t = Tela(15)
    t.elipse(6, 9, 5.2, 3.4)
    t.circulo(10.5, 5, 2.6)
    t.triangulo((10, 2), (11.5, 0), (12, 3))
    t.retangulo(3, 11, 2, 4).retangulo(8, 11, 2, 4)
    return t

def _passaro2():
    t = Tela(15)
    t.elipse(7, 9, 4.4, 3.0)
    t.circulo(10.5, 6, 2.2)
    t.triangulo((2, 3), (7, 8), (2, 9))
    t.retangulo(13, 5, 2, 2)
    t.ponto(11, 5, 0)
    return t

def _peixe2():
    t = Tela(15)
    t.elipse(6, 8, 5.0, 3.4)
    t.triangulo((10, 5), (14, 3), (10, 13))
    t.circulo(3, 7, 1.0, v=0)
    return t

def _estrela_mar():
    t = Tela(15)
    t.triangulo((7, 0), (3, 8), (11, 8))
    t.triangulo((0, 6), (14, 6), (7, 14))
    return t

def _formiga():
    t = Tela(15)
    t.circulo(3, 8, 2.6).circulo(7.5, 8, 2.2).circulo(12, 8, 3.0)
    t.retangulo(1, 4, 1, 3).retangulo(4, 4, 1, 3)
    for x in (5, 8, 11):
        t.retangulo(x, 11, 1, 4)
    t.ponto(2, 7, 0)
    return t

def _caracol():
    t = Tela(15)
    t.circulo(8, 7, 5.4, cheio=False, espessura=2.0)
    t.circulo(8, 7, 2.4)
    t.retangulo(0, 11, 8, 2)
    t.retangulo(1, 8, 1, 3)
    return t

def _morcego():
    t = Tela(15)
    t.circulo(7, 7, 2.8)
    t.triangulo((0, 4), (5, 6), (0, 11)).triangulo((14, 4), (9, 6), (14, 11))
    t.triangulo((5, 3), (6, 5), (7, 3)).triangulo((9, 3), (8, 5), (7, 3))
    return t

def _sapo2():
    t = Tela(15)
    t.elipse(7, 9, 6.0, 4.0)
    t.circulo(4, 4, 2.4).circulo(10, 4, 2.4)
    t.ponto(4, 4, 0).ponto(10, 4, 0)
    t.retangulo(0, 11, 3, 2).retangulo(12, 11, 3, 2)
    return t

def _polvo2():
    t = Tela(15)
    t.circulo(7, 6, 4.6)
    for x in (2, 5, 9, 12):
        t.retangulo(x, 10, 2, 5)
    t.ponto(5, 5, 0).ponto(9, 5, 0)
    return t

def _pinguim2():
    t = Tela(15)
    t.elipse(7, 9, 4.4, 5.4)
    t.circulo(7, 4, 3.0)
    t.elipse(7, 10, 2.4, 3.6, v=0)
    t.retangulo(6, 4, 3, 2, v=0)
    t.retangulo(7, 4, 1, 1)
    t.retangulo(3, 13, 3, 2).retangulo(9, 13, 3, 2)
    return t

def _cao():
    t = Tela(15)
    t.circulo(7, 8, 4.8)
    t.elipse(2, 7, 2.0, 3.6).elipse(12, 7, 2.0, 3.6)
    t.circulo(7, 10, 1.6, v=0)
    t.ponto(5, 6, 0).ponto(9, 6, 0)
    return t

def _raposa():
    t = Tela(15)
    t.circulo(7, 9, 4.6)
    t.triangulo((1, 8), (3, 1), (7, 7)).triangulo((13, 8), (11, 1), (7, 7))
    t.triangulo((5, 11), (9, 11), (7, 14))
    t.circulo(5, 8, 1.0, v=0).circulo(9, 8, 1.0, v=0)
    return t

NOVOS = [
 ("Coelho", "Orelhas em pé.", "#d6c4b8", _coelho()),
 ("Urso", "Grande e calmo.", "#a87f5f", _urso()),
 ("Porco", "Focinho redondo.", "#e8a8b8", _porco()),
 ("Ovelha", "Conte antes de dormir.", "#dfe3ea", _ovelha()),
 ("Galinha", "Acordou cedo.", "#e8c15f", _galinha()),
 ("Pato", "Foi nadar.", "#efc44f", _pato()),
 ("Golfinho", "Saltou fora d'água.", "#6fbcd6", _golfinho()),
 ("Tubarão", "Melhor não chegar perto.", "#8fa0b8", _tubarao()),
 ("Caranguejo", "Anda de lado.", "#e0655f", _caranguejo()),
 ("Cavalo-marinho", "Nada em pé.", "#e8a86a", _cavalo_marinho()),
 ("Água-viva", "Flutua sem pressa.", "#c9a0dc", _agua_viva()),
 ("Joaninha", "Dá sorte.", "#e0526a", _joaninha()),
 ("Aranha", "Oito pernas.", "#8f9bb0", _aranha()),
 ("Cobra", "Sinuosa.", "#7cc47f", _cobra()),
 ("Lagarto", "Toma sol na pedra.", "#8fc46a", _lagarto()),
 ("Rato", "Correu para o buraco.", "#b0b8c4", _rato()),
 ("Esquilo", "Guardou para depois.", "#c98a5f", _esquilo()),
 ("Panda", "Só quer bambu.", "#e8ecf5", _panda()),
 ("Macaco", "Aprontou de novo.", "#b08a5a", _macaco()),
 ("Girafa", "Vê tudo de cima.", "#e8c15f", _girafa()),
 ("Zebra", "Listras que ninguém repete.", "#dfe3ea", _zebra()),
 ("Tigre", "Silencioso.", "#e8a05f", _tigre()),
 ("Dragão", "Solta fogo.", "#e0655f", _dragao()),
 ("Unicórnio", "Existe sim.", "#e8b8e0", _unicornio()),
 ("Andorinha", "Anuncia o verão.", "#6badc4", _passaro2()),
 ("Peixinho", "Deu uma volta.", "#5fbcd3", _peixe2()),
 ("Estrela-do-mar", "Ficou na areia.", "#e8a05f", _estrela_mar()),
 ("Formiga", "Carrega o dobro do peso.", "#8f7a5f", _formiga()),
 ("Caracol", "Leva a casa junto.", "#c9a86a", _caracol()),
 ("Morcego", "Dorme de cabeça para baixo.", "#8f7ac4", _morcego()),
 ("Rã", "Salta longe.", "#7fc46a", _sapo2()),
 ("Polvo pequeno", "Oito braços menores.", "#c96a9b", _polvo2()),
 ("Pinguim", "De terno completo.", "#8fa0b8", _pinguim2()),
 ("Cachorro", "Melhor amigo.", "#c98a5f", _cao()),
 ("Raposa", "Esperta.", "#e8825f", _raposa()),
]
for nome, legenda, cor, tela in NOVOS:
    desenho(nome, legenda, cor, tela)
