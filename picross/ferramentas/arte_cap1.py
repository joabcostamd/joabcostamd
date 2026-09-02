# -*- coding: utf-8 -*-
"""Capítulo 1 — 5x5. Formas simples: é onde se aprende a ler os números."""
from catalogo_arte import desenho

D = [
 ("Coroa", "Para quem chegou até aqui.", "#e8c15f", ["#.#.#","#####","#####",".###.","#####"]),
 ("Olho", "Olha só quem apareceu.", "#6ab0d6", [".###.","#####","##.##","#####",".###."]),
 ("Copo", "Cheio até a borda.", "#6fbcd6", ["#####",".###.",".###.",".###.","#####"]),
 ("Ampulheta", "O tempo começa a contar.", "#c9a0dc", ["#####",".###.","..#..",".###.","#####"]),
 ("Cruz", "Simples e direta.", "#6aa9e3", ["..#..","..#..","#####","..#..","..#.."]),
 ("Gota", "Caiu bem no meio.", "#5fb0c4", ["..#..",".###.","#####","#####",".###."]),
 ("Coração", "Onde tudo começa.", "#e35d6a", [".#.#.","#####","#####",".###.","..#.."]),
 ("Casa", "Um teto e uma porta.", "#e0a458", ["..#..",".###.","#####","#...#","#.#.#"]),
 ("Árvore", "Pequena, mas já é uma árvore.", "#69c17a", ["..#..",".###.","#####","..#..","..#.."]),
 ("Losango", "Quatro lados iguais.", "#7fd1b9", ["..#..",".###.","#####",".###.","..#.."]),
 # novos
 ("Taça", "Um brinde ao começo.", "#d6a0c4", ["#...#","#####","#####",".###.","#####"]),
 ("Bandeira", "Território marcado.", "#e07f7f", ["####.","####.","####.","#....","#...."]),
 ("Escada", "Um degrau de cada vez.", "#9ab0d6", ["....#","...##","..###",".####","#####"]),
 ("Anel", "Redondo e vazio no meio.", "#e8c15f", [".###.","#...#","#...#","#...#","#####"]),
 ("Livro", "Aberto na página certa.", "#c98a5f", ["##.##","#####","#####","#####","##.##"]),
 ("Nuvem", "Passou por cima.", "#a8bcd6", [".....",".###.","#####","#####","....."]),
 ("Sino", "Toca no fim da fase.", "#e8c15f", ["..#..",".###.",".###.","#####","..#.."]),
 ("Vela", "Acesa até o fim.", "#efc44f", ["..#..","..#..",".###.",".###.","#####"]),
 ("Chave", "Abre a próxima porta.", "#d4b483", [".###.",".#.#.",".###.","..#..","..##."]),
 ("Xis", "Marca o lugar.", "#e0655f", ["##.##","#####","..#..","#####","##.##"]),
]
for nome, legenda, cor, arte in D:
    desenho(nome, legenda, cor, arte)
