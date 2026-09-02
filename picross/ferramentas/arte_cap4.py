# -*- coding: utf-8 -*-
"""Capítulo 4 — 20x20. Cenas com mais detalhe."""
from catalogo_arte import desenho
from pincel import Tela

D = [
 ("Dinossauro", "Grande, antigo e simpático.", "#7fae5f", ["..........########..",".........##########.",".........###..#####.",".........##########.",".........##########.",".........#########..","..........########..","..........#######...","..################..","..################..",".#################..","##################..","##################..",".#################..","..################..","...####.....####....","...###.......###....","...###.......###....","..####.......####...",".#####.......#####.."]),
 ("Farol", "Guia quem está voltando.", "#e0705f", [".......####.........","......######........","......#....#........","......######........",".......####.........",".......####.........","......######........","......#....#........","......#....#........","......######........",".....########.......",".....##....##.......",".....##....##.......",".....########.......","....##########......","....##########......","...############.....","...############.....","..##############....",".################..."]),
 ("Astronauta", "Primeiro a pisar na fase 45.", "#c9d2e0", [".......######.......","......########......",".....##########.....",".....##########.....",".....##########.....","......########......",".......######.......","....############....","...##############...","..################..",".##################.",".##################.",".##################.",".##################.",".####..######..####.",".####..######..####.","......########......","......##....##......","......##....##......",".....####..####....."]),
 ("Lanterna", "Acende no fim do caminho.", "#efc44f", ["....................",".........##.........",".........##.........","....................","......########......",".....##########.....","....############....","...##############...","..################..","..################..","..################..","..################..","...##############...","....############....",".....##########.....","......########......","....................",".........##.........",".........##.........","...................."]),
 ("Coruja", "A última a fechar os olhos.", "#e0a04f", ["..####........####..",".######......######.","####################","####################","###..####..####..###","##....##....##....##","##....##....##....##","###..####..####..###","####################","#######..##..#######","####################","####################",".##################.","..################..","...##############...","....############....",".....##########.....","..####......####....","..####......####....","...................."]),
 ("Torre", "Faz par com o peão.", "#9ad0d6", ["..####..####..####..","..################..","..################..","...##############...","....############....","....############....","....############....","....############....","....############....","....############....","....############....","....############....","....############....","....############....","...##############...","..################..",".##################.",".##################.","....................","...................."]),
 ("Cidade", "Onde o jogo acontece.", "#8f9bb0", ["....................","....................",".......####.........",".......####...###...","..####.####...###...","..####.####...###...","..####.####.######..","..####.####.######..","..#################.","..#################.","..##.###.###.###.##.","..#################.","..##.###.###.###.##.","..#################.","..##.###.###.###.##.","..#################.","..#################.","####################","####################","...................."]),
 ("Polvo", "Oito braços, zero pressa.", "#c96a9b", [".......######.......",".....##########.....","....############....","...##############...","...##############...","...###..####..###...","...##....##....##...","...##....##....##...","...###..####..###...","...##############...","...##############...","....############....",".....##########.....","...##..##..##..##...","..###..##..##..###..","..###..##..##..###..","..###..##..##..###..",".####..##..##..####.",".####..##..##..####.",".####..##..##..####."]),
 ("Trem", "Chegou na última estação.", "#6a8fc4", ["....................","...####.............","...####.............","...####.............","..######............","..######............","..######............","..##################","..##################","..##.##.##.##.##.###","..##################","..##################","..##################","..##################","...####..####..####.","...####..####..####.","....................","....................","....................","...................."]),
 ("Troféu", "Você terminou o jogo.", "#efc44f", ["..################..","..################..",".##################.","###..############..#","###..############..#","###..############..#","###..############..#",".##..############..#","..#..############..#",".....############...","......##########....",".......########.....","........######......","........######......","........######......","......##########....",".....############...","....##############..","...################.","...################."]),
]
for nome, legenda, cor, a in D:
    desenho(nome, legenda, cor, a)

# ─── novos, desenhados com a prancheta ───

def _carro():
    t = Tela(20)
    t.retangulo(1, 9, 18, 5)
    t.triangulo((4, 9), (7, 4), (13, 4)).triangulo((13, 4), (16, 9), (7, 9))
    t.retangulo(6, 5, 3, 4, v=0).retangulo(11, 5, 3, 4, v=0)
    t.circulo(5, 15, 2.6).circulo(15, 15, 2.6)
    return t

def _onibus():
    t = Tela(20)
    t.retangulo(1, 3, 18, 12)
    for x in (3, 7, 11, 15):
        t.retangulo(x, 5, 3, 4, v=0)
    t.circulo(5, 16, 2.4).circulo(15, 16, 2.4)
    return t

def _bicicleta():
    # Aros finos com quadro em diagonal aceitavam duas leituras. Rodas cheias
    # com miolo vazado e quadro reto resolvem, e ainda leem melhor de longe.
    t = Tela(20)
    t.circulo(4.5, 13, 5.0).circulo(4.5, 13, 2.4, v=0)
    t.circulo(15.5, 13, 5.0).circulo(15.5, 13, 2.4, v=0)
    t.retangulo(4, 7, 12, 3)
    t.retangulo(6, 3, 4, 4)
    return t

def _aviao():
    t = Tela(20)
    t.elipse(10, 8, 3.0, 7.4)
    t.triangulo((1, 12), (10, 6), (19, 12))
    t.triangulo((6, 18), (10, 14), (14, 18))
    return t

def _helicoptero():
    t = Tela(20)
    t.elipse(9, 11, 6.4, 4.0)
    t.retangulo(1, 2, 18, 2)
    t.retangulo(9, 4, 2, 3)
    t.retangulo(15, 10, 4, 2)
    t.circulo(6, 11, 2.2, v=0)
    return t

def _submarino():
    t = Tela(20)
    t.elipse(9, 11, 8.0, 4.0)
    t.retangulo(7, 4, 4, 4)
    t.retangulo(8, 1, 1, 3)
    for x in (5, 9, 13):
        t.circulo(x, 11, 1.3, v=0)
    return t

def _balao_ar():
    t = Tela(20)
    t.circulo(10, 7, 6.8)
    t.triangulo((4, 9), (16, 9), (10, 14))
    t.retangulo(8, 15, 5, 4)
    t.retangulo(9, 14, 3, 1)
    return t

def _moinho():
    t = Tela(20)
    t.triangulo((10, 6), (3, 19), (17, 19))
    t.retangulo(3, 19, 14, 1)
    t.retangulo(1, 1, 8, 3).retangulo(11, 1, 8, 3)
    t.retangulo(8, 0, 4, 6)
    t.retangulo(8, 13, 4, 6, v=0)
    return t

def _ponte():
    t = Tela(20)
    t.retangulo(0, 7, 20, 3)
    t.retangulo(2, 10, 4, 10).retangulo(9, 10, 3, 10).retangulo(15, 10, 4, 10)
    return t

def _igreja():
    t = Tela(20)
    t.retangulo(4, 8, 12, 12)
    t.triangulo((10, 2), (3, 9), (17, 9))
    t.retangulo(9, 0, 2, 4).retangulo(8, 1, 4, 1)
    t.retangulo(8, 14, 4, 6, v=0)
    return t

def _piramide():
    t = Tela(20)
    t.triangulo((10, 1), (0, 17), (19, 17))
    t.retangulo(0, 17, 20, 3)
    t.linha(10, 1, 10, 17, 1, v=0)
    return t

def _iglu():
    t = Tela(20)
    t.circulo(10, 13, 8.4)
    t.retangulo(0, 14, 20, 6, v=0)
    t.circulo(10, 13, 8.4)
    t.retangulo(8, 15, 4, 5, v=0)
    t.retangulo(0, 19, 20, 1)
    return t

def _tenda():
    t = Tela(20)
    t.triangulo((10, 1), (1, 17), (19, 17))
    t.triangulo((10, 5), (7, 17), (13, 17), v=0)
    t.retangulo(0, 17, 20, 2)
    return t

def _guitarra():
    t = Tela(20)
    t.elipse(9, 14, 6.0, 5.4)
    t.elipse(9, 8, 4.4, 4.0)
    t.retangulo(8, 0, 3, 8)
    t.retangulo(6, 0, 7, 2)
    t.circulo(9, 12, 2.0, v=0)
    return t

def _piano():
    t = Tela(20)
    t.retangulo(1, 3, 18, 6)
    t.retangulo(1, 9, 18, 5)
    for x in range(3, 18, 3):
        t.retangulo(x, 9, 1, 3, v=0)
    t.retangulo(3, 14, 2, 5).retangulo(15, 14, 2, 5)
    return t

def _microfone():
    t = Tela(20)
    t.elipse(10, 6, 4.0, 5.4)
    t.retangulo(9, 12, 2, 5)
    t.retangulo(6, 17, 8, 2)
    t.retangulo(6, 4, 8, 1, v=0).retangulo(6, 7, 8, 1, v=0)
    return t

def _pizza():
    t = Tela(20)
    t.triangulo((10, 1), (2, 18), (18, 18))
    for x, y in [(9, 8), (6, 13), (13, 13), (10, 16)]:
        t.circulo(x, y, 1.4, v=0)
    return t

def _hamburguer():
    t = Tela(20)
    t.elipse(10, 6, 8.4, 4.4)
    t.retangulo(2, 9, 16, 2)
    t.retangulo(1, 11, 18, 3)
    t.retangulo(2, 14, 16, 4)
    t.retangulo(2, 12, 16, 1, v=0)
    return t

def _cafe():
    t = Tela(20)
    t.retangulo(3, 7, 11, 10)
    t.circulo(15, 11, 3.4, cheio=False, espessura=1.6)
    t.retangulo(1, 17, 17, 2)
    t.retangulo(6, 2, 1, 4).retangulo(10, 2, 1, 4)
    return t

def _taca_vinho():
    t = Tela(20)
    t.elipse(10, 6, 5.4, 5.0)
    t.retangulo(9, 11, 2, 6)
    t.retangulo(5, 17, 10, 2)
    t.retangulo(6, 3, 8, 2, v=0)
    return t

def _telescopio():
    t = Tela(20)
    t.retangulo(2, 6, 12, 5)          # tubo
    t.retangulo(13, 4, 5, 9)          # boca, mais larga
    t.retangulo(8, 11, 3, 6)          # coluna
    t.triangulo((3, 19), (16, 19), (9.5, 15))
    return t

def _planeta():
    t = Tela(20)
    t.circulo(10, 8, 6.4)
    t.retangulo(0, 12, 20, 3)
    t.circulo(10, 8, 6.4)
    t.circulo(7, 5, 1.6, v=0)
    return t

def _estrela_cadente():
    t = Tela(20)
    t.triangulo((14, 1), (10, 8), (18, 8))
    t.triangulo((14, 13), (10, 6), (18, 6))
    t.retangulo(0, 12, 9, 3)
    t.retangulo(2, 16, 7, 2)
    return t

def _chuva():
    # A nuvem feita de três círculos era a parte ambígua, não as gotas.
    t = Tela(20)
    t.elipse(10, 6, 8.4, 4.0)
    t.retangulo(3, 6, 14, 3)
    t.retangulo(4, 12, 2, 8).retangulo(9, 12, 2, 8).retangulo(14, 12, 2, 8)
    return t

def _guarda_sol():
    t = Tela(20)
    t.circulo(10, 9, 8.4)
    t.retangulo(0, 10, 20, 10, v=0)
    t.retangulo(9, 9, 2, 11)
    t.retangulo(6, 18, 4, 1)
    return t

def _palmeira():
    t = Tela(20)
    t.retangulo(9, 6, 3, 14)
    t.elipse(4, 5, 5.0, 2.0).elipse(16, 5, 5.0, 2.0)
    t.elipse(10, 2, 4.0, 2.2)
    return t

def _vulcao():
    t = Tela(20)
    t.triangulo((10, 5), (0, 19), (19, 19))
    t.retangulo(7, 4, 6, 2, v=0)
    t.retangulo(8, 0, 4, 4)
    t.retangulo(5, 6, 3, 2).retangulo(12, 6, 3, 2)
    return t

def _montanha():
    t = Tela(20)
    t.triangulo((7, 2), (0, 18), (14, 18))
    t.triangulo((14, 6), (8, 18), (19, 18))
    t.triangulo((7, 2), (4, 7), (10, 7), v=0)
    t.retangulo(0, 18, 20, 2)
    return t

def _bau():
    t = Tela(20)
    t.retangulo(2, 8, 16, 10)
    t.elipse(10, 8, 8.0, 4.0)
    t.retangulo(2, 8, 16, 1, v=0)
    t.retangulo(9, 10, 2, 4, v=0)
    t.retangulo(2, 12, 16, 1, v=0)
    return t

def _bussola():
    t = Tela(20)
    t.circulo(10, 10, 8.6, cheio=False, espessura=2.2)
    t.retangulo(9, 3, 2, 14).retangulo(3, 9, 14, 2)
    return t

def _espada():
    t = Tela(20)
    t.retangulo(9, 0, 2, 13)
    t.retangulo(5, 13, 10, 2)
    t.retangulo(9, 15, 2, 4)
    t.retangulo(8, 19, 4, 1)
    return t

def _escudo():
    t = Tela(20)
    t.retangulo(2, 1, 16, 8)
    t.triangulo((2, 9), (18, 9), (10, 19))
    t.retangulo(9, 4, 2, 10, v=0)
    t.retangulo(4, 6, 12, 2, v=0)
    return t

def _coroa2():
    t = Tela(20)
    t.triangulo((2, 12), (5, 2), (8, 12))
    t.triangulo((7, 12), (10, 0), (13, 12))
    t.triangulo((12, 12), (15, 2), (18, 12))
    t.retangulo(2, 12, 16, 5)
    t.retangulo(2, 14, 16, 1, v=0)
    return t

def _relogio_areia():
    t = Tela(20)
    t.retangulo(2, 0, 16, 3).retangulo(2, 17, 16, 3)
    t.triangulo((3, 3), (17, 3), (10, 10))
    t.triangulo((3, 17), (17, 17), (10, 10))
    t.retangulo(9, 8, 2, 4)
    return t

def _lampada2():
    t = Tela(20)
    t.circulo(10, 7, 6.4)
    t.retangulo(7, 13, 6, 3)
    t.retangulo(8, 16, 4, 4)
    t.retangulo(7, 14, 6, 1, v=0)
    t.retangulo(8, 18, 4, 1, v=0)
    t.retangulo(9, 0, 2, 2).retangulo(1, 5, 2, 2).retangulo(17, 5, 2, 2)
    return t

def _arvore2():
    t = Tela(20)
    t.circulo(10, 7, 7.4)
    t.retangulo(8, 13, 4, 7)
    t.circulo(5, 11, 3.4).circulo(15, 11, 3.4)
    return t

def _pinheiro():
    t = Tela(20)
    t.triangulo((10, 0), (5, 7), (15, 7))
    t.triangulo((10, 4), (3, 12), (17, 12))
    t.triangulo((10, 9), (1, 17), (19, 17))
    t.retangulo(9, 17, 3, 3)
    return t

def _flor2():
    t = Tela(20)
    for cx, cy in [(10, 4), (10, 12), (5, 8), (15, 8)]:
        t.circulo(cx, cy, 3.4)
    t.circulo(10, 8, 2.4, v=0)
    t.retangulo(9, 13, 2, 7)
    t.elipse(5, 17, 3.4, 1.6)
    return t

def _peixe_grande():
    t = Tela(20)
    t.elipse(8, 10, 7.4, 5.0)
    t.triangulo((15, 4), (19, 4), (15, 16))
    return t

def _borboleta2():
    t = Tela(20)
    t.elipse(5, 6, 4.4, 4.0).elipse(15, 6, 4.4, 4.0)
    t.elipse(6, 14, 3.6, 3.4).elipse(14, 14, 3.6, 3.4)
    t.retangulo(9, 3, 2, 14)
    t.retangulo(7, 0, 1, 3).retangulo(12, 0, 1, 3)
    return t

NOVOS = [
 ("Carro", "Pronto para sair.", "#e0655f", _carro()),
 ("Ônibus", "Passa na hora.", "#efc44f", _onibus()),
 ("Bicicleta", "Duas rodas bastam.", "#6fbcd6", _bicicleta()),
 ("Avião", "Visto de cima.", "#9ab0d6", _aviao()),
 ("Helicóptero", "Pousa em qualquer lugar.", "#8fa0b8", _helicoptero()),
 ("Submarino", "Lá no fundo.", "#efc44f", _submarino()),
 ("Balão", "Sobe devagar.", "#e0705f", _balao_ar()),
 ("Moinho", "Roda com o vento.", "#c98a5f", _moinho()),
 ("Ponte", "Liga os dois lados.", "#9aa4b8", _ponte()),
 ("Igreja", "Sino no alto.", "#c9b8a8", _igreja()),
 ("Pirâmide", "Muito mais antiga que você.", "#e8c15f", _piramide()),
 ("Iglu", "Quentinho por dentro.", "#dfe3ea", _iglu()),
 ("Barraca", "Fim de semana no mato.", "#7cc47f", _tenda()),
 ("Guitarra", "Ligada no amplificador.", "#e0655f", _guitarra()),
 ("Piano", "Oitenta e oito teclas.", "#e8ecf5", _piano()),
 ("Microfone", "Testando, um, dois.", "#9ad0d6", _microfone()),
 ("Pizza", "Fatia inteira.", "#e8a05f", _pizza()),
 ("Hambúrguer", "Com tudo dentro.", "#c98a5f", _hamburguer()),
 ("Café", "Antes de tudo.", "#b08a5a", _cafe()),
 ("Taça de vinho", "Para comemorar.", "#c9527a", _taca_vinho()),
 ("Telescópio", "Aponta para cima.", "#8f9bb0", _telescopio()),
 ("Planeta", "Com anel e tudo.", "#c9a0dc", _planeta()),
 ("Estrela cadente", "Faça um pedido.", "#efc44f", _estrela_cadente()),
 ("Chuva", "Melhor levar guarda-chuva.", "#6fa8d6", _chuva()),
 ("Guarda-sol", "Sombra na areia.", "#e8825f", _guarda_sol()),
 ("Palmeira", "Praia à vista.", "#7cc47f", _palmeira()),
 ("Vulcão", "Melhor sair de perto.", "#e0655f", _vulcao()),
 ("Montanha", "Neve no topo.", "#9aa4b8", _montanha()),
 ("Baú", "O que será que tem?", "#c98a5f", _bau()),
 ("Bússola", "Aponta o norte.", "#e8c15f", _bussola()),
 ("Espada", "Lâmina reta.", "#c9d2e0", _espada()),
 ("Escudo", "Aguenta o golpe.", "#8fa0b8", _escudo()),
 ("Coroa real", "Pesada de verdade.", "#efc44f", _coroa2()),
 ("Ampulheta grande", "Areia caindo.", "#c9a0dc", _relogio_areia()),
 ("Lâmpada grande", "Ideia enorme.", "#f0d264", _lampada2()),
 ("Carvalho", "Cresceu por décadas.", "#7cc47f", _arvore2()),
 ("Pinheiro", "Sempre verde.", "#6fae72", _pinheiro()),
 ("Margarida", "Colhida no campo.", "#e8ecf5", _flor2()),
 ("Peixe grande", "O que quase escapou.", "#5fbcd3", _peixe_grande()),
 ("Borboleta", "Asas abertas.", "#d67fc4", _borboleta2()),
]
for nome, legenda, cor, tela in NOVOS:
    desenho(nome, legenda, cor, tela)
