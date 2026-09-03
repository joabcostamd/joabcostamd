"""Troca desenhos em arte.py pelo nome atual, preservando o resto do arquivo."""
import re, sys

def aplicar(trocas, caminho="arte.py"):
    s = open(caminho, encoding="utf-8").read()
    for antigo, novo in trocas.items():
        padrao = re.compile(r'desenho\("' + re.escape(antigo) + r'",.*?\n\]\)', re.S)
        corpo = 'desenho("%s", "%s", "%s", [\n' % (novo["nome"], novo["legenda"], novo["cor"])
        corpo += "".join('    "%s",\n' % l for l in novo["arte"])
        corpo += "])"
        s, n = padrao.subn(lambda m: corpo, s)
        if n != 1:
            print("ERRO: '%s' teve %d substituições" % (antigo, n)); sys.exit(1)
    open(caminho, "w", encoding="utf-8").write(s)
    print("%d desenhos trocados" % len(trocas))
