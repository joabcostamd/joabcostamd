"""Testes da colocação das pistas. Escritos ANTES da correção, para pegarem o defeito."""
import sys
sys.path.insert(0, "/home/user/joabcostamd/estudos/picross3d")
import cenas

falhas = []


def checa(nome, cond):
    print(f"  [{'ok' if cond else 'FALHA'}]  {nome}")
    if not cond:
        falhas.append(nome)


# Uma coluna partida ao meio: cubos em y=0,1 e y=5,6, com buraco entre eles.
coluna = {(0, 0, 0), (0, 1, 0), (0, 5, 0), (0, 6, 0)}
faces = cenas.faces_com_pista(coluna)

topo = [f for f in faces if f[3] == "topo"]
checa("coluna partida mostra a pista do topo UMA vez só", len(topo) == 1)
checa("e ela fica no cubo mais alto que sobrou", topo and topo[0][:3] == (0, 6, 0))

# Mesma checagem nos outros dois eixos.
linha_x = {(0, 0, 0), (1, 0, 0), (5, 0, 0), (6, 0, 0)}
fx = [f for f in cenas.faces_com_pista(linha_x) if f[3] == "x+"]
checa("fileira partida em x mostra a pista uma vez", len(fx) == 1)
checa("e no cubo de maior x", fx and fx[0][:3] == (6, 0, 0))

linha_z = {(0, 0, 0), (0, 0, 1), (0, 0, 5), (0, 0, 6)}
fz = [f for f in cenas.faces_com_pista(linha_z) if f[3] == "z+"]
checa("fileira partida em z mostra a pista uma vez", len(fz) == 1)
checa("e no cubo de maior z", fz and fz[0][:3] == (0, 0, 6))

# As pistas têm que sair na MESMA ordem de pintura dos cubos, senão o número
# de um cubo de trás aparece por cima do cubo da frente.
bloco = {(x, y, z) for x in range(3) for y in range(3) for z in range(3)}
seq = cenas.faces_com_pista(bloco)
prof = [x + y + z for (x, y, z, _) in seq]
checa("as pistas saem na ordem do pintor (fundo -> frente)", prof == sorted(prof))

print(f"\n{'TODAS PASSARAM' if not falhas else str(len(falhas)) + ' FALHA(S)'} — {len(falhas)} de 7")
sys.exit(1 if falhas else 0)
