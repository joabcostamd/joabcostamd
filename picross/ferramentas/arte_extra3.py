# -*- coding: utf-8 -*-
"""Segunda leva do capítulo 3 — mais 50 fases 15x15."""
from catalogo_arte import desenho
from pincel import Tela

def _cavalo2():
    t=Tela(15); t.elipse(6,10,4.4,3.0); t.retangulo(9,4,3,6); t.circulo(11,3,2.4)
    t.retangulo(3,12,2,3); t.retangulo(8,12,2,3); t.retangulo(0,9,3,1); return t
def _vaca():
    t=Tela(15); t.elipse(7,9,5.4,3.4); t.circulo(12,6,2.4)
    t.circulo(4,8,1.6,v=0); t.circulo(8,10,1.4,v=0); t.retangulo(3,12,2,3); t.retangulo(9,12,2,3); return t
def _cabra():
    t=Tela(15); t.elipse(6,9,4.4,3.0); t.circulo(11,6,2.4); t.retangulo(10,2,1,4); t.retangulo(13,2,1,4)
    t.retangulo(3,11,2,4); t.retangulo(8,11,2,4); return t
def _burro():
    t=Tela(15); t.elipse(6,10,4.6,3.0); t.circulo(11,6,2.4); t.retangulo(10,1,1,5); t.retangulo(12,1,1,5)
    t.retangulo(3,12,2,3); t.retangulo(8,12,2,3); return t
def _lhama():
    t=Tela(15); t.elipse(6,11,4.0,3.0); t.retangulo(8,4,3,7); t.circulo(10,3,2.2)
    t.retangulo(3,13,2,2); t.retangulo(8,13,2,2); return t
def _camelo():
    t=Tela(15); t.elipse(6,10,5.4,2.6); t.circulo(5,7,2.4); t.circulo(9,7,2.4)
    t.retangulo(11,5,3,5); t.circulo(13,4,2.0); t.retangulo(3,12,2,3); t.retangulo(8,12,2,3); return t
def _urso2():
    t=Tela(15); t.circulo(7,9,5.0); t.circulo(3,4,2.2); t.circulo(11,4,2.2)
    t.elipse(7,11,2.6,2.0,v=0); t.circulo(5,8,1.0,v=0); t.circulo(9,8,1.0,v=0); return t
def _koala():
    t=Tela(15); t.circulo(7,9,4.6); t.circulo(2,7,2.8); t.circulo(12,7,2.8)
    t.elipse(7,11,2.0,2.4); t.circulo(5,8,1.0,v=0); t.circulo(9,8,1.0,v=0); return t
def _preguica():
    t=Tela(15); t.elipse(7,9,4.4,4.4); t.retangulo(0,3,15,2)
    t.retangulo(3,5,2,3); t.retangulo(10,5,2,3); t.circulo(5,8,1.2,v=0); t.circulo(9,8,1.2,v=0); return t
def _ourico():
    t=Tela(15); t.elipse(7,10,5.4,3.4); t.circulo(12,10,2.4)
    for x in range(2,12,2): t.triangulo((x,7),(x+2,7),(x+1,3))
    return t
def _lontra():
    t=Tela(15); t.elipse(7,9,5.0,3.4); t.circulo(11,5,2.4); t.retangulo(0,10,4,2)
    t.circulo(10,4,0.9,v=0); return t
def _foca():
    t=Tela(15); t.elipse(7,10,5.4,3.0); t.circulo(11,6,2.6)
    t.triangulo((0,8),(3,11),(0,13)); t.circulo(12,5,0.9,v=0); return t
def _baleia3():
    t=Tela(15); t.elipse(7,9,6.0,3.4); t.triangulo((12,5),(14,3),(12,12))
    t.retangulo(6,3,2,3); t.elipse(7,2,2.6,1.4); return t
def _polvo4():
    t=Tela(15); t.circulo(7,6,4.4)
    for x in (2,5,8,11): t.retangulo(x,10,2,5)
    t.circulo(5,5,1.0,v=0); t.circulo(9,5,1.0,v=0); return t
def _lula():
    t=Tela(15); t.triangulo((7,0),(3,8),(11,8)); t.retangulo(3,8,9,2)
    for x in (3,6,9): t.retangulo(x,10,2,5)
    return t
def _camarao():
    t=Tela(15); t.elipse(6,8,5.0,3.0); t.circulo(11,7,2.4); t.retangulo(13,5,2,2)
    for x in (3,6,9): t.retangulo(x,11,1,3)
    return t
def _concha():
    t=Tela(15); t.circulo(7,10,6.4)
    for x in (3,7,11): t.retangulo(x,4,1,10,v=0)
    t.retangulo(0,12,15,3,v=0); return t
def _peixe3():
    t=Tela(15); t.elipse(7,8,5.4,3.4); t.triangulo((11,4),(14,2),(11,12))
    t.retangulo(5,3,3,2); t.circulo(4,7,1.0,v=0); return t
def _arraia():
    t=Tela(15); t.triangulo((7,2),(0,11),(14,11)); t.retangulo(6,11,3,4)
    t.circulo(5,7,1.0,v=0); t.circulo(9,7,1.0,v=0); return t
def _enguia():
    t=Tela(15); t.retangulo(1,2,12,3); t.retangulo(10,5,3,2); t.retangulo(2,7,11,3)
    t.retangulo(2,10,3,2); t.retangulo(2,12,11,3); return t
def _libelula():
    t=Tela(15); t.retangulo(7,2,2,11); t.circulo(8,2,2.0)
    t.elipse(3,5,3.4,1.4); t.elipse(12,5,3.4,1.4); t.elipse(4,8,2.6,1.2); t.elipse(11,8,2.6,1.2); return t
def _grilo():
    t=Tela(15); t.elipse(7,8,4.4,2.6); t.circulo(11,7,2.2)
    t.triangulo((3,10),(7,10),(4,14)); t.retangulo(12,3,1,4); return t
def _besouro():
    t=Tela(15); t.elipse(7,9,4.4,4.4); t.retangulo(7,5,1,9,v=0); t.circulo(7,3,2.2)
    t.retangulo(1,7,3,1); t.retangulo(11,7,3,1); t.retangulo(1,11,3,1); t.retangulo(11,11,3,1); return t
def _borboleta3():
    t=Tela(15); t.elipse(4,5,3.4,3.0); t.elipse(11,5,3.4,3.0)
    t.elipse(4,11,2.6,2.4); t.elipse(11,11,2.6,2.4); t.retangulo(7,3,2,10); return t
def _mariposa():
    t=Tela(15); t.triangulo((7,4),(0,10),(7,12)); t.triangulo((8,4),(15,10),(8,12))
    t.retangulo(7,3,2,9); t.retangulo(5,0,1,3); t.retangulo(9,0,1,3); return t
def _minhoca():
    t=Tela(15); t.retangulo(2,2,11,3); t.retangulo(10,5,3,3); t.retangulo(2,8,11,3)
    t.retangulo(2,11,3,2); t.retangulo(2,13,11,2); return t
def _passarinho():
    t=Tela(15); t.circulo(7,8,4.0); t.circulo(11,5,2.4); t.retangulo(13,4,2,1)
    t.triangulo((2,6),(6,9),(2,11)); t.retangulo(6,12,2,3); return t
def _coruja3():
    t=Tela(15); t.elipse(7,9,4.8,5.2)
    t.retangulo(4,4,3,3,v=0); t.retangulo(8,4,3,3,v=0)
    t.retangulo(6,9,3,2); return t
def _tucano():
    t=Tela(15); t.elipse(6,9,4.0,4.0); t.circulo(9,5,2.4); t.retangulo(11,4,4,3)
    t.circulo(9,4,0.9,v=0); return t
def _flamingo():
    t=Tela(15); t.elipse(6,8,4.0,2.6); t.retangulo(8,3,2,5); t.circulo(10,2,2.0)
    t.retangulo(12,1,2,2); t.retangulo(5,10,2,5); return t
def _pavao():
    t=Tela(15); t.elipse(7,11,3.0,3.4); t.circulo(7,6,2.0)
    for x,y in [(2,6),(4,3),(7,2),(10,3),(12,6)]: t.circulo(x,y,1.6)
    return t
def _galo():
    t=Tela(15); t.elipse(6,10,4.0,3.4); t.circulo(9,6,2.4); t.retangulo(9,2,2,4)
    t.retangulo(11,7,3,1); t.retangulo(2,7,3,2); return t
def _peru():
    t=Tela(15); t.elipse(6,10,3.6,3.6); t.circulo(9,7,2.4)
    t.elipse(4,3,5.4,2.4); t.retangulo(11,7,2,1); return t
def _cisne():
    t=Tela(15); t.elipse(6,11,5.0,2.8); t.retangulo(9,5,3,6); t.circulo(10,4,2.2)
    t.retangulo(12,3,3,2); return t
def _pombo():
    t=Tela(15); t.elipse(6,9,4.4,3.0); t.circulo(10,6,2.2); t.retangulo(12,5,2,1)
    t.triangulo((2,7),(6,9),(2,11)); return t
def _gaivota():
    t=Tela(15); t.elipse(7,9,3.4,2.4); t.circulo(10,7,1.8)
    t.triangulo((0,4),(7,8),(1,10)); t.triangulo((14,4),(7,8),(13,10)); return t
def _dinossauro2():
    t=Tela(15); t.elipse(6,9,5.0,3.0); t.circulo(11,6,2.6); t.retangulo(0,10,4,2)
    t.retangulo(4,11,2,4); t.retangulo(8,11,2,4); t.circulo(12,5,0.9,v=0); return t
def _lobo2():
    t=Tela(15); t.triangulo((7,14),(2,6),(12,6))
    t.triangulo((2,7),(3,2),(6,7)); t.triangulo((12,7),(11,2),(8,7))
    t.circulo(5,8,1.0,v=0); t.circulo(9,8,1.0,v=0); return t
def _gato2():
    t=Tela(15); t.circulo(7,9,4.6); t.triangulo((2,7),(4,2),(7,7)); t.triangulo((12,7),(10,2),(7,7))
    t.elipse(5,8,1.2,1.6,v=0); t.elipse(9,8,1.2,1.6,v=0); t.retangulo(6,11,3,1,v=0); return t
def _hamster():
    t=Tela(15); t.elipse(7,9,4.6,3.6); t.circulo(3,6,1.8); t.circulo(11,6,1.8)
    t.circulo(5,8,1.0,v=0); t.circulo(9,8,1.0,v=0); return t
def _tatu():
    t=Tela(15); t.elipse(7,9,5.4,3.4); t.circulo(12,8,2.2)
    t.retangulo(4,6,1,7,v=0); t.retangulo(7,6,1,7,v=0); return t
def _macaco2():
    t=Tela(15); t.circulo(7,7,4.0); t.circulo(2,7,2.0); t.circulo(12,7,2.0)
    t.elipse(7,9,2.4,1.8,v=0); t.elipse(7,13,3.4,2.0); return t
def _panda2():
    t=Tela(15); t.circulo(7,9,5.0); t.circulo(3,4,2.2); t.circulo(11,4,2.2)
    t.elipse(5,8,1.6,2.0,v=0); t.elipse(9,8,1.6,2.0,v=0); t.circulo(7,11,1.2,v=0); return t
def _raposa2():
    t=Tela(15); t.elipse(7,10,5.0,3.4); t.circulo(11,6,2.6)
    t.retangulo(9,2,2,4); t.retangulo(12,2,2,4); t.retangulo(0,11,4,2); return t
def _esquilo2():
    t=Tela(15); t.elipse(4.5,10,3.0,4.0); t.circulo(4.5,5,2.6); t.elipse(11,8,3.4,5.4)
    t.elipse(11,8,1.4,3.0,v=0); return t
def _abelha2():
    t=Tela(15); t.elipse(7,9,4.4,3.4)
    for y in (7,10): t.retangulo(3,y,9,1,v=0)
    t.elipse(3,5,2.6,1.6); t.elipse(11,5,2.6,1.6); t.retangulo(5,2,1,2); t.retangulo(9,2,1,2); return t
def _formiga2():
    t=Tela(15); t.circulo(3,8,2.2); t.circulo(7,8,1.8); t.circulo(11.5,8,2.8)
    for x in (5,8,11): t.retangulo(x,10,1,4)
    t.retangulo(1,4,1,3); t.retangulo(4,4,1,3); return t
def _caracol2():
    t=Tela(15); t.circulo(9,8,5.4); t.circulo(9,8,3.0,v=0); t.circulo(9,8,1.2)
    t.retangulo(0,11,9,3); t.retangulo(1,8,1,3); t.retangulo(3,8,1,3); return t
def _sapo3():
    t=Tela(15); t.elipse(7,10,5.4,3.4); t.circulo(4,5,2.4); t.circulo(10,5,2.4)
    t.circulo(4,5,1.0,v=0); t.circulo(10,5,1.0,v=0); t.retangulo(0,12,3,2); t.retangulo(12,12,3,2); return t
def _tartaruga3():
    t=Tela(15); t.elipse(7,9,5.4,3.6); t.circulo(7,9,2.4,v=0); t.circulo(12,8,2.2)
    t.retangulo(2,12,3,3); t.retangulo(9,12,3,3); return t

D = [
 ("Cavalo","A galope.","#c98a5f",_cavalo2()), ("Vaca","No pasto.","#e8ecf5",_vaca()),
 ("Cabra","Escala qualquer coisa.","#d6c4b8",_cabra()), ("Burro","Teimoso.","#9aa4b8",_burro()),
 ("Lhama","Olhar julgador.","#e8dfa8",_lhama()), ("Camelo","Duas corcovas.","#e8c15f",_camelo()),
 ("Urso","Procurando mel.","#a87f5f",_urso2()), ("Coala","Sempre no eucalipto.","#b0b8c4",_koala()),
 ("Preguiça","Sem pressa nenhuma.","#c9a86a",_preguica()), ("Ouriço","Espinhos em pé.","#8f7a5f",_ourico()),
 ("Lontra","Nada de costas.","#a87f5f",_lontra()), ("Foca","Toma sol na pedra.","#9aa4b8",_foca()),
 ("Baleia","Sopro alto.","#5a9bc4",_baleia3()), ("Polvo","Curioso.","#c96a9b",_polvo4()),
 ("Lula","Rápida na fuga.","#e8a8b8",_lula()), ("Camarão","Pequeno e ágil.","#e8825f",_camarao()),
 ("Concha","Ouça o mar.","#e8dfa8",_concha()), ("Peixe","Escamas brilhando.","#5fbcd3",_peixe3()),
 ("Arraia","Plana e silenciosa.","#8fa0b8",_arraia()), ("Enguia","Serpenteia.","#6fae72",_enguia()),
 ("Libélula","Asas de vidro.","#7fd1e0",_libelula()), ("Grilo","Canta à noite.","#7cc47f",_grilo()),
 ("Besouro","Casco duro.","#8f7ac4",_besouro()), ("Borboleta","Recém-saída do casulo.","#d67fc4",_borboleta3()),
 ("Mariposa","Atraída pela luz.","#c9a86a",_mariposa()), ("Minhoca","Faz bem à terra.","#e8a8b8",_minhoca()),
 ("Passarinho","Cantou de manhã.","#6fbcd6",_passarinho()), ("Coruja","Olhos enormes.","#b08a5a",_coruja3()),
 ("Tucano","Bico enorme.","#efc44f",_tucano()), ("Flamingo","Numa perna só.","#e8a8c4",_flamingo()),
 ("Pavão","Abriu a cauda.","#5fbcd3",_pavao()), ("Galo","Acorda todo mundo.","#e0655f",_galo()),
 ("Peru","Todo enfeitado.","#b08a5a",_peru()), ("Cisne","Pescoço em curva.","#e8ecf5",_cisne()),
 ("Pombo","Da praça.","#9aa4b8",_pombo()), ("Gaivota","Sobre o mar.","#dfe3ea",_gaivota()),
 ("Dinossauro","Pequeno, para variar.","#7fae5f",_dinossauro2()), ("Lobo","Olhar fixo.","#8fa0b8",_lobo2()),
 ("Gato","Fingindo indiferença.","#f0b46a",_gato2()), ("Hamster","Bochechas cheias.","#e8c15f",_hamster()),
 ("Tatu","Blindado.","#c9a86a",_tatu()), ("Macaco","Pendurado.","#b08a5a",_macaco2()),
 ("Panda","Comendo bambu.","#e8ecf5",_panda2()), ("Raposa","Rabo enorme.","#e8825f",_raposa2()),
 ("Esquilo","Escondeu tudo.","#c98a5f",_esquilo2()), ("Abelha","Listrada.","#e8c15f",_abelha2()),
 ("Formiga","Sempre em fila.","#8f7a5f",_formiga2()), ("Caracol","Casa nas costas.","#c9a86a",_caracol2()),
 ("Sapo","Olhos saltados.","#7fc46a",_sapo3()), ("Tartaruga","Casco redondo.","#6fae72",_tartaruga3()),
]
for nome, legenda, cor, tela in D:
    desenho(nome, legenda, cor, tela)
