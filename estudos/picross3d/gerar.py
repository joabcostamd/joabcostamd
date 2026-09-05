"""Gera as três maquetes do Picross 3D."""
import sys, random
sys.path.insert(0, "/home/user/joabcostamd/estudos/picross3d")
import cenas, figura

N, FIG = 9, figura.cogumelo()
TODOS = {(x, y, z) for x in range(N) for y in range(N) for z in range(N)}
SAIDA = "/home/user/joabcostamd/estudos/picross3d/saida"

# 1 — o bloco intacto
cenas.cena(f"{SAIDA}/1-inicio.png", TODOS, set(),
           titulo="O BLOCO INTACTO",
           legenda="729 cubos. Os números dizem quantos, naquela fileira, fazem parte da figura.")

# 2 — meio da dedução: o jogador já quebrou parte e marcou parte
rng = random.Random(4)
sobra, marcados = set(), set()
for p in TODOS:
    x, y, z = p
    if p in FIG:
        sobra.add(p)
        # marca de azul o que ele já deduziu que fica (a parte de fora, mais fácil)
        if y >= 5 or rng.random() < 0.45:
            marcados.add(p)
    else:
        # já quebrou o entulho de cima e das quinas — o miolo ainda resiste
        facil = y >= 6 or (x + z) >= 13 or (x + z) <= 3
        if facil or rng.random() < 0.52:
            continue
        sobra.add(p)
cenas.cena(f"{SAIDA}/2-meio.png", sobra, marcados,
           titulo="NO MEIO DA DEDUÇÃO",
           legenda="Azul = deduzido que fica. Cinza = ainda em dúvida. O resto virou pó.")

# 3 — revelada
cenas.cena(f"{SAIDA}/3-revelada.png", FIG, set(), revelado=True,
           titulo="A FIGURA REVELADA",
           legenda="O último cubo caiu. 121 de 729 sobreviveram.",
           mostrar_pistas=False)
print("três cenas geradas")
