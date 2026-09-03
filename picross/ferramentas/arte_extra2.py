# -*- coding: utf-8 -*-
"""Segunda leva do capítulo 2 — mais 40 fases 10x10."""
from catalogo_arte import desenho
from pincel import Tela

def f(fn):
    return fn()

def _tesoura():
    t = Tela(10); t.circulo(2.5, 8, 2.0, cheio=False, espessura=1.2)
    t.circulo(7.5, 8, 2.0, cheio=False, espessura=1.2)
    t.retangulo(4, 0, 2, 7); return t
def _regua():
    t = Tela(10); t.retangulo(0, 3, 10, 4)
    for x in range(1, 10, 2): t.retangulo(x, 3, 1, 2, v=0)
    return t
def _clipe():
    t = Tela(10); t.retangulo(2, 1, 6, 8, cheio=False)
    t.retangulo(4, 3, 2, 6); return t
def _tinteiro():
    t = Tela(10); t.elipse(5, 7, 4.4, 3.0); t.retangulo(3, 3, 4, 4); t.retangulo(4, 0, 2, 3); return t
def _pincel():
    t = Tela(10); t.retangulo(4, 0, 2, 6); t.retangulo(3, 6, 4, 2); t.triangulo((3, 8), (7, 8), (5, 10)); return t
def _paleta():
    t = Tela(10); t.elipse(5, 5, 4.6, 4.2); t.circulo(7, 6, 1.4, v=0)
    for x, y in [(3, 3), (6, 3), (3, 7)]: t.circulo(x, y, 1.0, v=0)
    return t
def _caneca2():
    t = Tela(10); t.retangulo(1, 2, 6, 7); t.circulo(8, 5, 2.0, cheio=False, espessura=1.2); return t
def _torrada():
    t = Tela(10); t.elipse(5, 3, 4.4, 2.6); t.retangulo(1, 3, 8, 6); t.retangulo(3, 5, 4, 3, v=0); return t
def _ovo():
    t = Tela(10); t.elipse(5, 6, 4.4, 4.0); t.elipse(5, 6, 1.8, 1.6, v=0); return t
def _queijo():
    t = Tela(10); t.triangulo((0, 9), (9, 9), (9, 2))
    t.circulo(6, 7, 1.0, v=0); t.circulo(8, 5, 0.9, v=0); return t
def _sanduiche():
    t = Tela(10); t.retangulo(0, 1, 10, 2); t.retangulo(0, 4, 10, 2); t.retangulo(0, 7, 10, 2); return t
def _garfo():
    t = Tela(10); t.retangulo(4, 3, 2, 7)
    for x in (2, 4, 6): t.retangulo(x, 0, 1, 3)
    t.retangulo(2, 3, 6, 1); return t
def _colher():
    t = Tela(10); t.elipse(5, 2, 2.6, 2.2); t.retangulo(4, 4, 2, 6); return t
def _panela():
    t = Tela(10); t.retangulo(1, 3, 8, 6); t.retangulo(0, 2, 10, 1); t.retangulo(4, 0, 2, 2); return t
def _camisa():
    t = Tela(10); t.retangulo(2, 1, 6, 8); t.retangulo(0, 1, 2, 4); t.retangulo(8, 1, 2, 4)
    t.retangulo(4, 1, 2, 2, v=0); return t
def _calca():
    t = Tela(10); t.retangulo(1, 0, 8, 3); t.retangulo(1, 3, 3, 7); t.retangulo(6, 3, 3, 7); return t
def _meia():
    t = Tela(10); t.retangulo(3, 0, 4, 6); t.retangulo(0, 6, 7, 3); return t
def _oculos_sol():
    t = Tela(10); t.elipse(2.5, 5, 2.4, 2.0); t.elipse(7.5, 5, 2.4, 2.0); t.retangulo(4, 4, 2, 1); return t
def _relogio_pulso():
    t = Tela(10); t.circulo(5, 5, 3.0); t.circulo(5, 5, 1.4, v=0)
    t.retangulo(4, 0, 2, 2); t.retangulo(4, 8, 2, 2); return t
def _mochila():
    t = Tela(10); t.retangulo(1, 2, 8, 8); t.elipse(5, 2, 4.0, 2.0)
    t.retangulo(3, 6, 4, 2, v=0); return t
def _lapis2():
    t = Tela(10); t.retangulo(4, 0, 2, 7); t.triangulo((4, 7), (6, 7), (5, 10))
    t.retangulo(4, 1, 2, 1, v=0); return t
def _sino3():
    t = Tela(10); t.elipse(5, 5, 3.6, 4.4); t.retangulo(1, 7, 8, 2); t.retangulo(4, 9, 2, 1); return t
def _coracao2():
    t = Tela(10); t.circulo(3, 3, 2.6); t.circulo(7, 3, 2.6); t.triangulo((0, 4), (10, 4), (5, 10)); return t
def _trevo():
    t = Tela(10); t.circulo(3, 3, 2.4); t.circulo(7, 3, 2.4); t.circulo(3, 6, 2.4); t.circulo(7, 6, 2.4)
    t.retangulo(4, 8, 2, 2); return t
def _bandeira2():
    t = Tela(10); t.retangulo(1, 0, 1, 10); t.retangulo(2, 1, 7, 4); return t
def _chave3():
    t = Tela(10); t.circulo(2.5, 2.5, 2.4); t.circulo(2.5, 2.5, 1.0, v=0)
    t.retangulo(2, 4, 2, 6); t.retangulo(4, 7, 2, 1); t.retangulo(4, 9, 2, 1); return t
def _foguete3():
    t = Tela(10); t.elipse(5, 4, 2.4, 4.0); t.triangulo((2, 6), (2, 9), (4, 9))
    t.triangulo((8, 6), (8, 9), (6, 9)); t.retangulo(4, 8, 2, 2); return t
def _telefone():
    t = Tela(10); t.retangulo(2, 0, 6, 10); t.retangulo(3, 1, 4, 6, v=0); return t
def _tv():
    t = Tela(10); t.retangulo(0, 2, 10, 6); t.retangulo(2, 4, 6, 3, v=0)
    t.retangulo(4, 8, 2, 2); t.retangulo(2, 9, 6, 1); return t
def _janela():
    t = Tela(10); t.retangulo(1, 1, 8, 8); t.retangulo(4, 1, 2, 8, v=0); t.retangulo(1, 4, 8, 2, v=0); return t
def _porta():
    t = Tela(10); t.retangulo(2, 0, 6, 10); t.circulo(6, 5, 0.9, v=0); return t
def _cadeado():
    t = Tela(10); t.retangulo(1, 4, 8, 6); t.circulo(5, 4, 3.0, cheio=False, espessura=1.4)
    t.retangulo(1, 4, 8, 6); t.circulo(5, 7, 1.0, v=0); return t
def _sol2():
    t = Tela(10); t.circulo(5, 5, 3.0); t.retangulo(4, 0, 2, 2); t.retangulo(4, 8, 2, 2)
    t.retangulo(0, 4, 2, 2); t.retangulo(8, 4, 2, 2); return t
def _lua2():
    t = Tela(10); t.circulo(4, 5, 4.4); t.circulo(7, 4, 3.6, v=0); return t
def _gota2():
    t = Tela(10); t.circulo(5, 6, 3.4); t.triangulo((2, 6), (8, 6), (5, 0)); return t
def _folha2():
    t = Tela(10); t.elipse(5, 4, 3.4, 3.8); t.retangulo(4, 7, 2, 3); return t
def _flor3():
    t = Tela(10); t.circulo(5, 2, 2.0); t.circulo(2, 5, 2.0); t.circulo(8, 5, 2.0)
    t.circulo(5, 5, 1.6); t.retangulo(4, 7, 2, 3); return t
def _cesta():
    t = Tela(10); t.triangulo((0, 4), (9, 4), (7, 9)); t.triangulo((0, 4), (2, 9), (7, 9))
    t.circulo(4.5, 3, 3.4, cheio=False, espessura=1.2); return t
def _bola():
    t = Tela(10); t.circulo(5, 5, 4.4); t.retangulo(0, 4, 10, 2, v=0); t.retangulo(4, 0, 2, 10, v=0); return t
def _pinguim3():
    t = Tela(10); t.elipse(5, 6, 3.4, 4.0); t.elipse(5, 7, 1.8, 2.6, v=0)
    t.circulo(5, 2, 2.2); t.retangulo(2, 9, 2, 1); t.retangulo(6, 9, 2, 1); return t

D = [
 ("Tesoura","Corta reto.","#9aa4b8",_tesoura()), ("Régua","Mede tudo.","#e8c15f",_regua()),
 ("Clipe","Segura as folhas.","#8fa0b8",_clipe()), ("Tinteiro","Tinta fresca.","#6a8fc4",_tinteiro()),
 ("Pincel","Molhado de tinta.","#c98a5f",_pincel()), ("Paleta","Cores à mão.","#e8a05f",_paleta()),
 ("Caneca","Fumegando.","#b08a5a",_caneca2()), ("Torrada","Ainda quente.","#e8c15f",_torrada()),
 ("Ovo","Frito na hora.","#e8ecf5",_ovo()), ("Queijo","Com buracos.","#efc44f",_queijo()),
 ("Sanduíche","Três camadas.","#c98a5f",_sanduiche()), ("Garfo","Três dentes.","#c9d2e0",_garfo()),
 ("Colher","Para a sopa.","#c9d2e0",_colher()), ("Panela","No fogo.","#8f9bb0",_panela()),
 ("Camisa","Passada e dobrada.","#6fbcd6",_camisa()), ("Calça","Pronta para vestir.","#6a8fc4",_calca()),
 ("Meia","Uma só, claro.","#e8a8b8",_meia()), ("Óculos de sol","Verão chegando.","#8f7ac4",_oculos_sol()),
 ("Relógio de pulso","No horário.","#9aa4b8",_relogio_pulso()), ("Mochila","Cheia de livros.","#7cc47f",_mochila()),
 ("Lápis","Ponta afiada.","#efc44f",_lapis2()), ("Sineta","Chamou alguém.","#e8c15f",_sino3()),
 ("Coração","Bate forte.","#e0526a",_coracao2()), ("Trevo","Quatro folhas.","#7cc47f",_trevo()),
 ("Bandeira","No mastro.","#e07f7f",_bandeira2()), ("Chave","Da porta certa.","#d4b483",_chave3()),
 ("Foguetinho","Pronto pra subir.","#e8825f",_foguete3()), ("Telefone","Tocando.","#8fa0b8",_telefone()),
 ("Televisão","Ligada.","#9aa4b8",_tv()), ("Janela","Vista da rua.","#6fbcd6",_janela()),
 ("Porta","Aberta ou fechada.","#c98a5f",_porta()), ("Cadeado","Bem trancado.","#e8c15f",_cadeado()),
 ("Sol","Do meio-dia.","#efc44f",_sol2()), ("Lua","Minguante.","#e8dfa8",_lua2()),
 ("Gota","Prestes a cair.","#5fb0c4",_gota2()), ("Folha","Do outono.","#7cc47f",_folha2()),
 ("Florzinha","Três pétalas.","#e07fa8",_flor3()), ("Cesta","Do piquenique.","#c9a86a",_cesta()),
 ("Bola","Rolando.","#e8ecf5",_bola()), ("Pinguim","Pequeno e sério.","#8fa0b8",_pinguim3()),
]
for nome, legenda, cor, tela in D:
    desenho(nome, legenda, cor, tela)
