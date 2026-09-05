# -*- coding: utf-8 -*-
"""Segunda leva do capítulo 4 — mais 50 fases 20x20."""
from catalogo_arte import desenho
from pincel import Tela

def _skate():
    t=Tela(20); t.elipse(10,8,9.4,2.4); t.circulo(5,13,2.6); t.circulo(15,13,2.6)
    t.retangulo(4,10,3,2); t.retangulo(13,10,3,2); return t
def _patins():
    t=Tela(20); t.retangulo(4,2,8,8); t.retangulo(2,10,15,3)
    for x in (4,8,12): t.circulo(x,16,2.4)
    return t
def _raquete():
    t=Tela(20); t.elipse(10,7,7.4,6.4); t.elipse(10,7,5.0,4.2,v=0)
    for x in (7,10,13): t.retangulo(x,3,1,9)
    t.retangulo(9,13,3,7); return t
def _bola_futebol():
    t=Tela(20); t.circulo(10,10,8.4)
    for cx,cy in [(10,5),(5,11),(15,11),(10,16)]: t.circulo(cx,cy,2.0,v=0)
    t.circulo(10,10,2.4,v=0); return t
def _cesta_basquete():
    t=Tela(20); t.retangulo(3,1,14,7); t.retangulo(7,4,6,4,v=0)
    t.retangulo(6,8,9,2); t.triangulo((6,10),(15,10),(10,16)); return t
def _halteres():
    t=Tela(20); t.retangulo(1,6,4,8); t.retangulo(15,6,4,8); t.retangulo(5,9,10,3); return t
def _medalha():
    t=Tela(20); t.circulo(10,13,5.6); t.circulo(10,13,2.4,v=0)
    t.retangulo(6,0,3,8); t.retangulo(11,0,3,8); return t
def _cronometro():
    t=Tela(20); t.circulo(10,12,7.4); t.circulo(10,12,5.0,v=0)
    t.retangulo(9,7,2,5); t.retangulo(8,2,5,3); t.retangulo(9,0,3,2); return t
def _tambor():
    t=Tela(20); t.elipse(10,6,8.4,3.0); t.retangulo(2,6,17,9); t.elipse(10,15,8.4,3.0)
    t.retangulo(2,9,17,2,v=0); return t
def _saxofone():
    t=Tela(20); t.retangulo(8,1,3,10); t.elipse(9,15,5.4,4.4); t.elipse(9,15,2.6,2.4,v=0)
    for y in (3,6,9): t.retangulo(11,y,2,1)
    return t
def _trompete():
    t=Tela(20); t.retangulo(1,8,13,4); t.retangulo(14,5,5,10)
    t.retangulo(4,5,2,3); t.retangulo(8,5,2,3); return t
def _nota_musical():
    t=Tela(20); t.elipse(5,15,4.0,3.4); t.retangulo(8,2,3,13); t.retangulo(11,2,7,3)
    t.elipse(15,15,4.0,3.4); t.retangulo(15,2,3,13); return t
def _disco():
    t=Tela(20); t.circulo(10,10,9.4); t.circulo(10,10,3.0,v=0); t.circulo(10,10,1.0)
    t.circulo(10,10,6.4,cheio=False,espessura=1.0); return t
def _radio():
    t=Tela(20); t.retangulo(1,5,18,12); t.circulo(6,11,3.4,v=0)
    t.retangulo(12,8,5,2,v=0); t.retangulo(12,12,5,2,v=0); t.retangulo(3,1,2,4); return t
def _microscopio():
    t=Tela(20); t.retangulo(8,1,4,8); t.retangulo(6,9,8,3); t.retangulo(2,16,16,3)
    t.triangulo((6,16),(14,16),(10,12)); return t
def _balao_quimica():
    t=Tela(20); t.retangulo(8,1,4,6); t.triangulo((10,6),(2,18),(18,18))
    t.retangulo(4,14,12,4,v=0); t.triangulo((10,6),(2,18),(18,18)); t.retangulo(3,13,14,1,v=0); return t
def _atomo():
    # Duas elipses cruzes ficavam ambíguas nas pontas; uma órbita
    # circular com o elétron destacado lê melhor e fecha por lógica.
    t=Tela(20); t.circulo(10,10,4.0)
    t.circulo(10,10,9.4,cheio=False,espessura=2.4)
    t.circulo(3,3,2.0); return t
def _dna():
    t=Tela(20); 
    for y in range(0,20,4):
        t.retangulo(4,y,12,1)
    t.retangulo(2,0,3,20); t.retangulo(15,0,3,20); return t
def _lupa2():
    t=Tela(20); t.circulo(8,7,6.4,cheio=False,espessura=2.4); t.retangulo(11,11,3,3)
    t.retangulo(13,13,5,5); return t
def _globo():
    t=Tela(20); t.circulo(10,8,7.4); t.circulo(4,6,2.0,v=0); t.circulo(13,10,2.6,v=0)
    t.retangulo(9,15,3,3); t.retangulo(5,18,11,2); return t
def _mapa():
    t=Tela(20); t.retangulo(1,3,18,14); t.retangulo(7,3,1,14,v=0); t.retangulo(13,3,1,14,v=0)
    t.circulo(4,8,1.4,v=0); t.circulo(16,12,1.4,v=0); return t
def _mala2():
    t=Tela(20); t.retangulo(1,5,18,13); t.retangulo(8,1,4,4); t.retangulo(9,2,2,3,v=0)
    t.retangulo(1,9,18,2,v=0); return t
def _passaporte():
    t=Tela(20); t.retangulo(3,1,14,18); t.circulo(10,7,3.4,v=0)
    t.retangulo(6,13,9,2,v=0); t.retangulo(6,16,9,1,v=0); return t
def _bussola2():
    t=Tela(20); t.circulo(10,10,8.6,cheio=False,espessura=2.0)
    t.triangulo((10,3),(7,10),(13,10)); t.retangulo(9,10,3,7); return t
def _ancora2():
    t=Tela(20); t.circulo(10,3,2.4,cheio=False,espessura=1.2); t.retangulo(9,5,3,12)
    t.retangulo(5,7,10,2); t.triangulo((1,11),(4,17),(10,17)); t.triangulo((18,11),(15,17),(10,17)); return t
def _salva_vidas():
    t=Tela(20); t.circulo(10,10,8.4); t.circulo(10,10,4.0,v=0)
    for x,y in [(10,2),(2,10),(18,10),(10,18)]: t.circulo(x,y,2.2,v=0)
    return t
def _concha2():
    t=Tela(20); t.circulo(10,13,8.4); t.retangulo(0,14,20,6,v=0); t.circulo(10,13,8.4)
    for x in (4,7,10,13,16): t.retangulo(x,5,1,9,v=0)
    return t
def _pegada():
    t=Tela(20); t.elipse(10,13,5.0,5.4)
    for x,y in [(4,5),(8,3),(12,3),(16,5)]: t.circulo(x,y,2.0)
    return t
def _pinheiro2():
    t=Tela(20); t.triangulo((10,0),(4,8),(16,8)); t.triangulo((10,5),(2,14),(18,14))
    t.retangulo(8,14,4,6); return t
def _cogumelo2():
    t=Tela(20); t.elipse(10,7,8.4,5.4); t.retangulo(7,11,6,9)
    for x,y in [(6,5),(13,6),(10,9)]: t.circulo(x,y,1.6,v=0)
    return t
def _cacto2():
    t=Tela(20); t.retangulo(8,3,5,17); t.retangulo(2,8,4,7); t.retangulo(2,8,11,3)
    t.retangulo(15,6,4,8); t.retangulo(11,6,8,3); return t
def _girassol3():
    t=Tela(20); t.circulo(10,7,4.4)
    for a in range(8):
        import math
        x=10+6.5*math.cos(a*math.pi/4); y=7+6.5*math.sin(a*math.pi/4)
        t.circulo(x,y,2.0)
    t.circulo(10,7,2.4,v=0); t.retangulo(9,12,3,8); return t
def _rosa():
    t=Tela(20); t.circulo(10,6,5.4); t.circulo(10,6,3.0,v=0); t.circulo(10,6,1.2)
    t.retangulo(9,11,3,9); t.elipse(4,15,4.0,1.8); t.elipse(16,17,4.0,1.8); return t
def _folhas():
    t=Tela(20); t.elipse(6,6,4.4,3.0); t.elipse(14,10,4.4,3.0); t.elipse(7,15,4.4,3.0)
    t.retangulo(9,2,2,17); return t
def _pote():
    t=Tela(20); t.retangulo(3,6,14,13); t.retangulo(2,3,16,3); t.retangulo(6,9,8,6,v=0); return t
def _regador():
    t=Tela(20); t.retangulo(4,7,10,11); t.retangulo(6,4,4,3); t.triangulo((14,8),(19,4),(19,10))
    t.circulo(3,10,2.6,cheio=False,espessura=1.2); return t
def _casa2():
    t=Tela(20); t.triangulo((10,1),(1,9),(19,9)); t.retangulo(3,9,14,11)
    t.retangulo(8,14,4,6,v=0); t.retangulo(4,11,3,3,v=0); t.retangulo(13,11,3,3,v=0)
    t.retangulo(14,2,2,4); return t
def _predio():
    t=Tela(20); t.retangulo(3,2,14,18)
    for y in range(4,18,4):
        for x in range(5,16,4): t.retangulo(x,y,2,2,v=0)
    return t
def _fabrica():
    t=Tela(20); t.retangulo(1,10,18,10); t.retangulo(3,4,3,6); t.retangulo(8,2,3,8)
    t.retangulo(13,6,3,4); t.retangulo(5,14,4,6,v=0); return t
def _celeiro():
    t=Tela(20); t.triangulo((10,1),(2,7),(18,7)); t.retangulo(2,7,16,13)
    t.retangulo(8,12,4,8,v=0); t.retangulo(9,7,2,13,v=0); return t
def _poco():
    t=Tela(20); t.retangulo(4,11,12,9); t.retangulo(4,13,12,2,v=0)
    t.triangulo((10,1),(3,7),(17,7)); t.retangulo(9,7,2,4); return t
def _lampiao():
    t=Tela(20); t.retangulo(6,5,8,10); t.retangulo(8,7,4,6,v=0)
    t.triangulo((10,1),(5,5),(15,5)); t.retangulo(5,15,10,3); t.retangulo(9,0,2,2); return t
def _chave_grande():
    t=Tela(20); t.circulo(5,5,4.4); t.circulo(5,5,1.8,v=0); t.retangulo(4,9,3,11)
    t.retangulo(7,14,4,2); t.retangulo(7,18,4,2); return t
def _pergaminho():
    t=Tela(20); t.retangulo(2,3,16,14); t.elipse(2,10,2.4,7.4); t.elipse(18,10,2.4,7.4)
    for y in (6,9,12): t.retangulo(6,y,9,1,v=0)
    return t
def _pena():
    t=Tela(20); t.elipse(9,8,4.4,7.4); t.retangulo(8,8,2,12); t.retangulo(9,1,2,6); return t
def _tinta():
    t=Tela(20); t.elipse(10,14,7.4,5.4); t.retangulo(6,8,8,6); t.retangulo(7,5,6,3)
    t.retangulo(8,9,4,4,v=0); return t
def _ampulheta3():
    t=Tela(20); t.retangulo(3,0,14,3); t.retangulo(3,17,14,3)
    t.triangulo((4,3),(16,3),(10,10)); t.triangulo((4,17),(16,17),(10,10)); t.retangulo(9,8,3,4); return t
def _espelho():
    t=Tela(20); t.elipse(10,8,6.4,7.4); t.elipse(10,8,4.0,5.0,v=0)
    t.retangulo(9,15,3,5); t.retangulo(6,19,8,1); return t
def _coroa3():
    t=Tela(20); t.triangulo((3,13),(6,3),(9,13)); t.triangulo((10,13),(13,3),(16,13))
    t.triangulo((6,13),(10,1),(14,13)); t.retangulo(2,13,16,5); t.retangulo(2,15,16,1,v=0); return t
def _sino4():
    t=Tela(20); t.elipse(10,10,7.4,8.4); t.retangulo(2,14,16,3); t.retangulo(8,17,4,3)
    t.retangulo(9,0,3,3); return t

D = [
 ("Skate","Rodando na pista.","#e0655f",_skate()), ("Patins","Quatro rodas.","#6fbcd6",_patins()),
 ("Raquete","Saque forte.","#e8c15f",_raquete()), ("Bola de futebol","Gol!","#e8ecf5",_bola_futebol()),
 ("Cesta","Três pontos.","#e8825f",_cesta_basquete()), ("Halteres","Mais uma série.","#8f9bb0",_halteres()),
 ("Medalha","Primeiro lugar.","#efc44f",_medalha()), ("Cronômetro","Marcou o tempo.","#9aa4b8",_cronometro()),
 ("Tambor","Marca o ritmo.","#c98a5f",_tambor()), ("Saxofone","Sopro grave.","#e8c15f",_saxofone()),
 ("Trompete","Anuncia a entrada.","#efc44f",_trompete()), ("Nota musical","Duas colcheias.","#9b8bd6",_nota_musical()),
 ("Disco","Girando no toca-discos.","#8f9bb0",_disco()), ("Rádio","Sintonizado.","#c98a5f",_radio()),
 ("Microscópio","Olha bem de perto.","#9aa4b8",_microscopio()), ("Frasco","Experimento em curso.","#7fd1e0",_balao_quimica()),
 ("Átomo","Tudo é feito disso.","#6fbcd6",_atomo()), ("Hélice dupla","O código da vida.","#7cc47f",_dna()),
 ("Lupa","Detalhe ampliado.","#8fa8c4",_lupa2()), ("Globo","O mundo todo.","#6fa8d6",_globo()),
 ("Mapa","Dobrado no bolso.","#c9a86a",_mapa()), ("Mala","Pronta para embarcar.","#a87f5f",_mala2()),
 ("Passaporte","Carimbado.","#5a9bc4",_passaporte()), ("Bússola","Sempre ao norte.","#e8c15f",_bussola2()),
 ("Âncora","Fundeada.","#8a9bb0",_ancora2()), ("Boia","Salva-vidas.","#e0655f",_salva_vidas()),
 ("Concha","Achada na areia.","#e8dfa8",_concha2()), ("Pegada","Alguém passou por aqui.","#8f7a5f",_pegada()),
 ("Pinheiro","Coberto de neve.","#6fae72",_pinheiro2()), ("Cogumelo","Com pintas.","#d96c6c",_cogumelo2()),
 ("Cacto","Braços abertos.","#6fbf73",_cacto2()), ("Girassol","Sempre virado ao sol.","#efc44f",_girassol3()),
 ("Rosa","Com espinhos.","#e0526a",_rosa()), ("Ramo","Três folhas.","#7cc47f",_folhas()),
 ("Vaso","Na janela.","#c98a5f",_pote()), ("Regador","Hora de molhar.","#6fbcd6",_regador()),
 ("Casa","Com chaminé.","#e0a458",_casa2()), ("Prédio","Muitas janelas.","#8f9bb0",_predio()),
 ("Fábrica","Turno da manhã.","#9aa4b8",_fabrica()), ("Celeiro","No campo.","#c9524b",_celeiro()),
 ("Poço","Água fresca.","#8fa0b8",_poco()), ("Lampião","Luz na varanda.","#efc44f",_lampiao()),
 ("Chave antiga","Abre o portão.","#d4b483",_chave_grande()), ("Pergaminho","Texto antigo.","#c9a86a",_pergaminho()),
 ("Pena","De escrever.","#dfe3ea",_pena()), ("Tinteiro","Quase vazio.","#6a8fc4",_tinta()),
 ("Ampulheta","A areia desce.","#c9a0dc",_ampulheta3()), ("Espelho","Quem é o mais belo?","#7fd1e0",_espelho()),
 ("Coroa","De três pontas.","#efc44f",_coroa3()), ("Sino","Badalando.","#e8c15f",_sino4()),
]
for nome, legenda, cor, tela in D:
    desenho(nome, legenda, cor, tela)
