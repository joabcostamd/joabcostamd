"""Gera traducoes/textos.csv e registra os locales no project.godot."""
import csv, os, re
from idiomas import IDIOMAS, T

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
destino = os.path.join(RAIZ, "traducoes", "textos.csv")
os.makedirs(os.path.dirname(destino), exist_ok=True)

with open(destino, "w", encoding="utf-8", newline="") as f:
    escritor = csv.writer(f, quoting=csv.QUOTE_ALL)
    escritor.writerow(["keys"] + IDIOMAS)
    for chave in sorted(T):
        escritor.writerow([chave] + list(T[chave]))

# registra os .translation no project.godot
caminho = os.path.join(RAIZ, "project.godot")
projeto = open(caminho, encoding="utf-8").read()
lista = ", ".join('"res://traducoes/textos.%s.translation"' % i for i in IDIOMAS)
bloco = "[internationalization]\n\nlocale/translations=PackedStringArray(%s)\n" % lista
if "[internationalization]" in projeto:
    projeto = re.sub(r"\[internationalization\].*?(?=\n\[|\Z)", bloco, projeto, flags=re.S)
else:
    projeto = projeto.rstrip() + "\n\n" + bloco
open(caminho, "w", encoding="utf-8").write(projeto)

print("%d chaves x %d idiomas gravadas" % (len(T), len(IDIOMAS)))
