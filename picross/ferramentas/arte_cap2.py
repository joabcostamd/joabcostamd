# -*- coding: utf-8 -*-
"""Capítulo 2 — 10x10. Objetos do dia a dia."""
from catalogo_arte import desenho
from pincel import Tela

D = [
 ("Cogumelo", "Cresce onde ninguém vê.", "#d96c6c", ["...####...","..######..",".########.","##########","##########","...####...","...#..#...","...#..#...","..######..","..######.."]),
 ("Fantasma", "Mais tímido que assustador.", "#b8c6e8", ["...####...","..######..",".########.",".##.##.##.",".########.",".########.",".########.",".########.",".########.",".#.#..#.#."]),
 ("Foguete", "Contagem regressiva.", "#e8825f", ["....##....","...####...","...####...","...#..#...","...####...","..######..",".##.##.##.",".##.##.##.","....##....","...#..#..."]),
 ("Gato", "Dorme dezesseis horas por dia.", "#f0b46a", ["##......##","####..####","##########","#.######.#","##.####.##","##########","###.##.###","##########",".########.","..######.."]),
 ("Sorvete", "Derrete se você demorar.", "#f2a6c0", ["..######..",".########.",".########.","..######..","...####...","...####...","....##....","....##....","....##....",".....#...."]),
 ("Guarda-chuva", "Sempre esquecido em algum lugar.", "#6fa8d6", ["....#.....","..#####...",".#######..","#########.","##########","....#.....","....#.....","....#.....","....#..#..","....####.."]),
 ("Âncora", "Segura o que importa.", "#8a9bb0", ["....##....","...#..#...","....##....","..######..","....##....","....##....","#...##...#","#...##...#","##.####.##","..######.."]),
 ("Lâmpada", "A ideia acendeu.", "#f0d264", ["...####...","..######..",".########.",".########.",".########.","..######..","...####...","...#..#...","...####...","....##...."]),
 ("Sino", "Tocou para a próxima fase.", "#e8c15f", ["....##....","...####...","..######..","..######..",".########.",".########.","##########","##########","....##....","....##...."]),
 ("Robô", "Faz o que você mandar.", "#9ad0d6", [".########.",".#.####.#.",".########.",".##.##.##.",".########.","##########","#.######.#","#.######.#","...####...","..##..##.."]),
 ("Bolo", "Alguém fez aniversário.", "#e9a3b8", ["..#..#..#.","..#..#..#.",".########.","##########","#.#.##.#.#","##########","##########","#.#.##.#.#","##########","##########"]),
 ("Cacto", "Resistente e mal-humorado.", "#6fbf73", ["....##....","....##....","#...##....","#...##..#.","##..##..#.",".#####.##.","....####..","....##....","....##....",".########."]),
 ("Coqueiro", "Férias em dez por dez.", "#7cc47f", ["..######..",".########.","##.####.##","....##....","....##....","....##....","....##....","...####...","..######..",".########."]),
 ("Peixe", "Passou nadando.", "#5fbcd3", ["..........","...####..#","..######.#",".#######.#","##.#####.#","##.######.",".#######.#","..######.#","...####..#",".........."]),
 ("Presente", "Não vale espiar antes.", "#d98fb0", ["...#..#...","....##....",".########.",".#..##..#.",".########.",".########.",".#..##..#.",".########.",".#..##..#.",".########."]),
]
for nome, legenda, cor, a in D:
    desenho(nome, legenda, cor, a)

# ─── novos, desenhados com a prancheta ───

def _macã():
    t = Tela(10)
    t.elipse(3.2, 6, 3.2, 3.6).elipse(6.6, 6, 3.2, 3.6)
    t.retangulo(4, 1, 2, 2).ponto(6, 1).ponto(7, 1)
    return t

def _relogio():
    t = Tela(10)
    t.circulo(4.5, 5, 4.4).circulo(4.5, 5, 3.2, v=0)
    t.linha(4, 5, 4, 2, 1).linha(4, 5, 7, 5, 1)
    t.retangulo(3, 0, 4, 1)
    return t

def _oculos():
    t = Tela(10)
    t.circulo(2.2, 5, 2.4, cheio=False, espessura=1.2)
    t.circulo(7.2, 5, 2.4, cheio=False, espessura=1.2)
    t.linha(4, 4, 5, 4, 1).linha(0, 3, 1, 3, 1).linha(8, 3, 9, 3, 1)
    return t

def _lua():
    t = Tela(10)
    t.circulo(4.6, 5, 4.4)
    t.circulo(7.2, 4.2, 3.6, v=0)
    return t

def _envelope():
    t = Tela(10)
    t.retangulo(0, 2, 10, 6)
    t.linha(0, 2, 4.5, 5, 1, v=0).linha(9, 2, 5, 5, 1, v=0)
    t.linha(1, 3, 4.5, 5.5, 1, v=0).linha(8, 3, 5, 5.5, 1, v=0)
    return t

def _lupa():
    t = Tela(10)
    t.circulo(4, 3.6, 3.4, cheio=False, espessura=1.4)
    t.linha(5.5, 6, 8.5, 9, 2)
    return t

def _garrafa():
    t = Tela(10)
    t.retangulo(4, 0, 2, 3).retangulo(3, 3, 4, 1).retangulo(2, 4, 6, 6)
    return t

def _dado():
    t = Tela(10)
    t.retangulo(0, 0, 10, 10)
    for x, y in [(2, 2), (7, 2), (2, 7), (7, 7), (4.5, 4.5)]:
        t.circulo(x, y, 1.1, v=0)
    return t

def _camera():
    t = Tela(10)
    t.retangulo(3, 0, 4, 2).retangulo(0, 2, 10, 8)
    t.circulo(4.5, 6, 2.6, v=0).circulo(4.5, 6, 1.2)
    return t

def _folha():
    # Sem nervura diagonal: em grade, uma diagonal fina quase sempre aceita
    # duas leituras e o puzzle passa a exigir chute.
    t = Tela(10)
    t.elipse(4.5, 4.5, 4.4, 3.4)
    t.retangulo(4, 7, 2, 3)
    return t

def _cereja():
    t = Tela(10)
    t.circulo(2.4, 7, 2.3).circulo(7.4, 7, 2.3)
    t.linha(2.5, 4, 5, 1, 1).linha(7.5, 4, 5, 1, 1).retangulo(4, 0, 2, 1)
    return t

def _cupcake():
    t = Tela(10)
    t.elipse(4.5, 3, 4.4, 2.6)
    t.triangulo((0.5, 5), (8.5, 5), (5, 9.5))
    t.retangulo(4, 0, 2, 1)
    return t

def _balde():
    t = Tela(10)
    t.triangulo((0, 3), (9, 3), (7, 9)).triangulo((0, 3), (2, 9), (7, 9))
    t.linha(1, 2, 4.5, 0, 1).linha(8, 2, 4.5, 0, 1)
    return t

def _martelo():
    t = Tela(10)
    t.retangulo(1, 0, 8, 3).retangulo(4, 3, 2, 7)
    return t

def _chave2():
    t = Tela(10)
    t.circulo(2.6, 2.6, 2.4, cheio=False, espessura=1.3)
    t.retangulo(4, 4, 2, 6)
    t.retangulo(6, 8, 3, 2)
    return t

def _pipa():
    t = Tela(10)
    t.triangulo((4.5, 0), (0.5, 4), (4.5, 8)).triangulo((4.5, 0), (8.5, 4), (4.5, 8))
    t.linha(4.5, 8, 7, 9.5, 1)
    return t

def _bota():
    t = Tela(10)
    t.retangulo(2, 0, 4, 6).retangulo(2, 6, 8, 3)
    t.retangulo(1, 9, 9, 1)
    return t

def _sino2():
    t = Tela(10)
    t.elipse(4.5, 5, 3.6, 4.2).retangulo(0, 7, 10, 2).retangulo(4, 9, 2, 1)
    t.retangulo(4, 0, 2, 1)
    return t

def _diamante():
    t = Tela(10)
    t.triangulo((0, 3), (9, 3), (4.5, 9.5)).retangulo(1, 0, 8, 3)
    return t

def _raio():
    t = Tela(10)
    t.retangulo(4, 0, 4, 4).retangulo(2, 4, 6, 2).retangulo(3, 6, 3, 4)
    return t

def _casinha():
    t = Tela(10)
    t.triangulo((4.5, 0), (0, 4), (9, 4)).retangulo(1, 4, 8, 6)
    t.retangulo(4, 7, 2, 3, v=0).retangulo(2, 5, 2, 2, v=0)
    return t

def _barco2():
    t = Tela(10)
    t.triangulo((5, 0), (5, 6), (1, 6)).triangulo((6, 1), (6, 6), (9, 6))
    t.triangulo((0, 7), (9.5, 7), (7, 9.5)).triangulo((0, 7), (2, 9.5), (7, 9.5))
    return t

def _chapeu2():
    t = Tela(10)
    t.retangulo(2, 0, 6, 6).retangulo(0, 6, 10, 2)
    t.retangulo(2, 4, 6, 1, v=0)
    return t

def _fone():
    t = Tela(10)
    t.circulo(4.5, 5, 4.6, cheio=False, espessura=1.6)
    t.retangulo(0, 5, 3, 5).retangulo(7, 5, 3, 5)
    t.retangulo(0, 9, 10, 1, v=0)
    return t

def _presente2():
    t = Tela(10)
    t.retangulo(0, 2, 10, 8).retangulo(4, 2, 2, 8, v=0)
    t.retangulo(0, 4, 10, 1, v=0)
    t.circulo(3, 1, 1.4).circulo(7, 1, 1.4)
    return t

NOVOS = [
 ("Maçã", "Uma por dia.", "#e05a5a", _macã()),
 ("Relógio", "O tempo não para.", "#9ab0d6", _relogio()),
 ("Óculos", "Agora dá para ver.", "#7fbcd6", _oculos()),
 ("Lua", "Fase crescente.", "#e8dfa8", _lua()),
 ("Envelope", "Chegou carta.", "#d6c4a8", _envelope()),
 ("Lupa", "Procure com calma.", "#8fa8c4", _lupa()),
 ("Garrafa", "Bem gelada.", "#6fc4a8", _garrafa()),
 ("Dado", "Aqui não vale sorte.", "#e8ecf5", _dado()),
 ("Câmera", "Registra o momento.", "#8f9bb0", _camera()),
 ("Folha", "Caiu no outono.", "#7cc47f", _folha()),
 ("Cereja", "Duas de uma vez.", "#e0526a", _cereja()),
 ("Cupcake", "Merecido.", "#f2a6c0", _cupcake()),
 ("Balde", "Cheio de água.", "#6fa8d6", _balde()),
 ("Martelo", "Para os pregos difíceis.", "#c98a5f", _martelo()),
 ("Chave inglesa", "Aperta o que estiver solto.", "#9aa4b8", _chave2()),
 ("Pipa", "Voa alto.", "#e8825f", _pipa()),
 ("Bota", "Pronta para a lama.", "#a87f5f", _bota()),
 ("Sineta", "Alguém chamou.", "#e8c15f", _sino2()),
 ("Diamante", "Raro e paciente.", "#7fd1e0", _diamante()),
 ("Relâmpago", "Rápido demais.", "#efc44f", _raio()),
 ("Chalé", "Aconchegante.", "#c98a5f", _casinha()),
 ("Veleiro", "Vento a favor.", "#6badc4", _barco2()),
 ("Cartola", "Truque de mágica.", "#8f7ac4", _chapeu2()),
 ("Fone", "Só o som do jogo.", "#9ad0d6", _fone()),
 ("Embrulho", "Não espie.", "#d98fb0", _presente2()),
]
for nome, legenda, cor, tela in NOVOS:
    desenho(nome, legenda, cor, tela)
