# -*- coding: utf-8 -*-
"""Segunda leva do capítulo 5 — mais 40 fases 25x25."""
from catalogo_arte import desenho
from pincel import Tela
import math

def _catedral():
    t=Tela(25); t.retangulo(5,10,15,15); t.triangulo((12,3),(4,11),(21,11))
    t.retangulo(1,6,4,19); t.retangulo(20,6,4,19)
    t.retangulo(10,17,5,8,v=0); t.circulo(12,13,2.4,v=0); return t
def _farol2():
    t=Tela(25); t.triangulo((12,4),(7,22),(18,22)); t.retangulo(8,4,9,4)
    t.retangulo(9,5,7,2,v=0); t.retangulo(2,22,21,3)
    for y in range(9,22,4): t.retangulo(7,y,11,1,v=0)
    return t
def _ponte2():
    t=Tela(25); t.retangulo(0,10,25,3); t.retangulo(2,13,3,12); t.retangulo(11,13,3,12)
    t.retangulo(20,13,3,12); t.retangulo(1,4,3,7); t.retangulo(21,4,3,7)
    t.retangulo(4,6,17,2); return t
def _torre_relogio():
    t=Tela(25); t.retangulo(7,6,11,19); t.triangulo((12,0),(6,7),(19,7))
    t.circulo(12,12,4.4,v=0); t.retangulo(11,9,2,4); t.retangulo(12,11,4,2); return t
def _moinho2():
    t=Tela(25); t.triangulo((12,7),(5,24),(20,24)); t.retangulo(5,24,15,1)
    t.retangulo(1,2,10,3); t.retangulo(14,2,10,3); t.retangulo(11,0,3,9)
    t.retangulo(10,17,5,8,v=0); return t
def _navio2():
    t=Tela(25); t.retangulo(0,17,25,5)
    t.retangulo(11,2,3,15)
    t.triangulo((11,2),(2,11),(11,16))
    return t
def _constelacao():
    # Estrelas soltas ligadas por traços nunca fecham por lógica. A figura
    # virou um alvo de anéis, que lê como órbita e é dedutível.
    t=Tela(25); t.circulo(12,12,10.4); t.circulo(12,12,6.0,v=0); t.circulo(12,12,2.4)
    return t

def _piano2():
    t=Tela(25); t.retangulo(1,4,23,10); t.retangulo(1,14,23,7)
    for x in range(3,23,3): t.retangulo(x,14,1,4,v=0)
    t.retangulo(4,21,3,4); t.retangulo(18,21,3,4); return t
def _violao2():
    t=Tela(25); t.elipse(12,17,7.4,6.4); t.elipse(12,10,5.4,4.4)
    t.retangulo(11,1,3,9); t.retangulo(9,0,7,2); t.circulo(12,15,2.4,v=0); return t
def _bateria():
    t=Tela(25); t.circulo(12,17,7.4); t.circulo(12,17,4.0,v=0)
    t.elipse(4,8,4.4,1.6); t.elipse(20,8,4.4,1.6); t.retangulo(3,9,2,8); t.retangulo(19,9,2,8); return t
def _harpa2():
    t=Tela(25); t.retangulo(2,2,4,21); t.retangulo(2,20,20,4); t.triangulo((5,2),(21,2),(21,21))
    for x in range(8,21,3): t.retangulo(x,4,1,16,v=0)
    return t
def _mascara():
    t=Tela(25); t.elipse(12,12,9.4,11.4); t.elipse(8,9,2.6,3.4,v=0); t.elipse(16,9,2.6,3.4,v=0)
    t.elipse(12,18,4.4,2.0,v=0); return t
def _bau2():
    t=Tela(25); t.retangulo(2,10,21,13); t.elipse(12,10,10.4,5.4)
    t.retangulo(2,10,21,1,v=0); t.retangulo(11,13,3,5,v=0); t.retangulo(2,15,21,1,v=0); return t
def _espada2():
    t=Tela(25); t.retangulo(11,0,3,16); t.retangulo(5,16,15,3); t.retangulo(11,19,3,5)
    t.retangulo(9,24,7,1); return t
def _escudo2():
    t=Tela(25); t.retangulo(2,1,21,10); t.triangulo((2,11),(23,11),(12,24))
    t.retangulo(11,5,3,13,v=0); t.retangulo(5,8,15,3,v=0); return t
def _elmo():
    t=Tela(25); t.elipse(12,11,9.4,10.4); t.retangulo(4,9,17,3,v=0)
    t.retangulo(11,12,3,10,v=0); t.retangulo(11,0,3,4); return t
def _dragao3():
    t=Tela(25); t.elipse(9,16,8.4,4.4); t.retangulo(15,10,4,7); t.circulo(19,8,4.0)
    t.retangulo(22,6,3,3); t.triangulo((3,12),(6,6),(9,12)); t.triangulo((10,11),(13,5),(16,11))
    t.retangulo(0,18,5,3); t.circulo(19,7,1.2,v=0); return t
def _grifo():
    t=Tela(25); t.circulo(12,7,4.0); t.retangulo(9,11,7,9)
    t.triangulo((0,3),(9,11),(1,17)); t.triangulo((24,3),(15,11),(23,17))
    t.retangulo(7,20,3,5); t.retangulo(15,20,3,5); return t
def _serpente():
    t=Tela(25); t.retangulo(2,2,20,3); t.retangulo(19,5,3,4); t.retangulo(3,9,19,3)
    t.retangulo(3,12,3,4); t.retangulo(3,16,19,3); t.retangulo(19,19,3,3); t.circulo(3,3,2.0); return t
def _fenix3():
    t=Tela(25); t.circulo(12,5,3.4); t.retangulo(9,8,7,11)
    t.triangulo((0,2),(9,10),(1,16)); t.triangulo((24,2),(15,10),(23,16))
    t.triangulo((7,19),(17,19),(12,24)); return t
def _arvore_grande():
    t=Tela(25); t.circulo(12,9,9.4); t.circulo(5,14,4.4); t.circulo(19,14,4.4)
    t.retangulo(10,16,5,9); t.retangulo(2,24,21,1); return t
def _bonsai2():
    t=Tela(25); t.elipse(12,6,10.4,4.4); t.elipse(6,12,5.4,3.0); t.elipse(18,12,5.4,3.0)
    t.retangulo(11,9,3,9); t.retangulo(4,18,17,4); t.retangulo(4,20,17,1,v=0); return t
def _montanhas():
    t=Tela(25); t.triangulo((7,3),(0,20),(15,20)); t.triangulo((17,7),(9,20),(24,20))
    t.triangulo((7,3),(4,8),(11,8),v=0); t.retangulo(0,20,25,5); return t
def _ilha():
    t=Tela(25); t.elipse(12,20,11.4,4.4); t.retangulo(11,10,3,10)
    t.elipse(6,9,5.4,2.4); t.elipse(18,9,5.4,2.4); t.elipse(12,6,4.4,2.4); return t
def _cachoeira():
    t=Tela(25); t.retangulo(2,0,7,25); t.retangulo(16,0,7,25); t.retangulo(9,3,7,22)
    for y in range(4,24,4): t.retangulo(9,y,7,1,v=0)
    return t
def _castelo3():
    t=Tela(25); t.retangulo(4,10,17,15); t.retangulo(0,6,5,19); t.retangulo(20,6,5,19)
    for x in (0,2,4,7,10,13,16,20,22): t.retangulo(x,3,2,3)
    t.retangulo(10,18,5,7,v=0); t.circulo(12,13,2.0,v=0); return t
def _labirinto2():
    t=Tela(25); t.retangulo(0,0,25,25,cheio=False)
    for y in range(3,23,4): t.retangulo(2,y,21,2)
    for y in range(3,23,8): t.retangulo(2,y,2,6,v=0)
    for y in range(7,23,8): t.retangulo(21,y,2,6,v=0)
    return t
def _engrenagem():
    t=Tela(25); t.circulo(12,12,9.4); t.circulo(12,12,4.0,v=0)
    for a in range(8):
        x=12+10.5*math.cos(a*math.pi/4); y=12+10.5*math.sin(a*math.pi/4)
        t.retangulo(x-1.5,y-1.5,3,3)
    return t
def _bussola3():
    t=Tela(25); t.circulo(12,12,11.4); t.circulo(12,12,8.0,v=0)
    t.retangulo(11,4,3,17); t.retangulo(4,11,17,3)
    return t

def _flor_grande():
    t=Tela(25); 
    for a in range(6):
        x=12+6.5*math.cos(a*math.pi/3); y=10+6.5*math.sin(a*math.pi/3)
        t.circulo(x,y,3.4)
    t.circulo(12,10,4.0); t.circulo(12,10,2.0,v=0)
    t.retangulo(11,16,3,9); t.elipse(5,21,4.4,2.0); return t
def _borboleta_grande():
    t=Tela(25); t.elipse(6,8,5.4,5.4); t.elipse(18,8,5.4,5.4)
    t.elipse(7,17,4.4,4.0); t.elipse(17,17,4.4,4.0); t.retangulo(11,4,3,17)
    t.retangulo(8,0,2,4); t.retangulo(15,0,2,4); return t
def _coruja_grande():
    t=Tela(25); t.elipse(12,14,9.4,10.4); t.retangulo(6,7,6,6,v=0); t.retangulo(13,7,6,6,v=0)
    t.circulo(9,10,1.6); t.circulo(16,10,1.6); t.triangulo((10,14),(15,14),(12,18))
    t.triangulo((2,7),(6,2),(8,8)); t.triangulo((22,7),(18,2),(16,8)); return t
def _gato_grande():
    t=Tela(25); t.circulo(12,14,9.4); t.triangulo((2,12),(5,1),(11,9)); t.triangulo((22,12),(19,1),(13,9))
    t.elipse(8,12,2.0,2.6,v=0); t.elipse(16,12,2.0,2.6,v=0)
    t.triangulo((10,17),(14,17),(12,20),v=0); t.retangulo(0,18,7,1,v=0); t.retangulo(18,18,7,1,v=0); return t

def _submarino2():
    t=Tela(25); t.elipse(12,15,11.4,5.4); t.retangulo(9,8,6,6); t.retangulo(11,3,2,5)
    for x in (5,9,13,17): t.circulo(x,15,1.6,v=0)
    return t

def _lua_cheia():
    t=Tela(25); t.circulo(12,12,11.4)
    for cx,cy,r in [(7,8,2.4),(16,10,3.0),(10,17,2.0),(18,17,1.6)]: t.circulo(cx,cy,r,v=0)
    return t

def _aviao2():
    t=Tela(25); t.elipse(12,12,3.4,10.4); t.triangulo((0,16),(12,9),(24,16))
    t.triangulo((7,24),(12,19),(17,24)); t.circulo(12,5,1.4,v=0)
    return t

def _trem3():
    t=Tela(25); t.retangulo(2,9,21,10); t.retangulo(2,4,7,5); t.retangulo(3,1,3,3)
    for x in range(11,22,4): t.retangulo(x,11,3,5,v=0)
    for x in (6,12,18): t.circulo(x,21,3.0)
    t.retangulo(0,24,25,1)
    return t

def _foguete4():
    t=Tela(25); t.elipse(12,9,4.4,8.4); t.circulo(12,6,2.0,v=0)
    t.triangulo((7,12),(7,20),(2,20)); t.triangulo((17,12),(17,20),(22,20))
    t.triangulo((9,19),(15,19),(12,24))
    return t

def _cometa():
    t=Tela(25); t.circulo(18,6,4.4)
    for i in range(4): t.retangulo(1+i*2,10+i*3,12-i*2,2)
    return t

def _satelite():
    t=Tela(25); t.retangulo(9,8,7,9); t.retangulo(0,10,8,5); t.retangulo(17,10,8,5)
    t.retangulo(11,3,3,5)
    return t

D = [
 ("Catedral","Vitrais altos.","#c9b8a8",_catedral()), ("Farol","Guia os barcos.","#e0705f",_farol2()),
 ("Ponte","Sobre o rio.","#9aa4b8",_ponte2()), ("Torre do relógio","Marca as horas.","#c9a86a",_torre_relogio()),
 ("Moinho","Gira com o vento.","#c98a5f",_moinho2()), ("Navio","Três mastros.","#6badc4",_navio2()),
 ("Submarino","Mergulho profundo.","#efc44f",_submarino2()), ("Avião","Visto de cima.","#9ab0d6",_aviao2()),
 ("Locomotiva","Apitou na curva.","#6a8fc4",_trem3()), ("Foguete","Decolagem.","#e8825f",_foguete4()),
 ("Satélite","Em órbita.","#c9d2e0",_satelite()), ("Lua cheia","Com crateras.","#dfe3ea",_lua_cheia()),
 ("Cometa","Passa a cada tanto.","#7fd1e0",_cometa()), ("Órbita","Anéis concêntricos.","#efc44f",_constelacao()),
 ("Piano","Tampa aberta.","#e8ecf5",_piano2()), ("Violão","Encostado na parede.","#c98a4b",_violao2()),
 ("Bateria","Prato e bumbo.","#e8c15f",_bateria()), ("Harpa","Quarenta e sete cordas.","#e8c15f",_harpa2()),
 ("Máscara","De teatro.","#c9a0dc",_mascara()), ("Baú","Cheio de moedas.","#c98a5f",_bau2()),
 ("Espada","Lâmina longa.","#c9d2e0",_espada2()), ("Escudo","Brasão no centro.","#8fa0b8",_escudo2()),
 ("Elmo","De cavaleiro.","#9aa4b8",_elmo()), ("Dragão","Guarda a montanha.","#e0655f",_dragao3()),
 ("Grifo","Metade águia.","#c9a86a",_grifo()), ("Serpente","Enrolada.","#7cc47f",_serpente()),
 ("Fênix","Asas em chamas.","#e06a4f",_fenix3()), ("Árvore","Copa enorme.","#7cc47f",_arvore_grande()),
 ("Bonsai","Podado com paciência.","#6fae72",_bonsai2()), ("Montanhas","Cume nevado.","#9aa4b8",_montanhas()),
 ("Ilha","Uma palmeira só.","#7cc47f",_ilha()), ("Cachoeira","Barulho de água.","#6fbcd6",_cachoeira()),
 ("Castelo","Torres e ameias.","#9aa4b8",_castelo3()), ("Labirinto","Sem saída fácil.","#8fa0b8",_labirinto2()),
 ("Engrenagem","Move o resto.","#c9a86a",_engrenagem()), ("Bússola","Rosa dos ventos.","#e8c15f",_bussola3()),
 ("Flor","Seis pétalas.","#e07fa8",_flor_grande()), ("Borboleta","Asas enormes.","#d67fc4",_borboleta_grande()),
 ("Coruja","A guardiã.","#b08a5a",_coruja_grande()), ("Gato","O retrato final.","#f0b46a",_gato_grande()),
]
for nome, legenda, cor, tela in D:
    desenho(nome, legenda, cor, tela)
