#!/usr/bin/env python3
"""Le o bloco ===PLANO-VERIFY=== e separa DEFEITO de FALTA.

O portao do plano responde "o plano acabou?". Este leitor responde outra
pergunta, que e a que interessa no dia a dia: "o plano esta sao?".

  DEFEITO  contradicao entre documentos · decisao 🟡 travando codigo ·
           decisao 🟢 sem marca de origem · documento exigido que nao existe
  FALTA    buraco por preencher, decisao ainda aberta — progresso normal

Sai com codigo 1 so no DEFEITO.
"""
import json
import re
import sys

DEFEITOS = ("contradicoes", "sem_origem", "documentos_faltando")


def main(argv):
    bruto = open(argv[1], encoding="utf-8").read()
    miolo = re.search(r"===PLANO-VERIFY===(.*?)===FIM-PLANO-VERIFY===", bruto, re.S)
    if not miolo:
        print("  o portao nao imprimiu o bloco delimitado — isso ja e defeito")
        print(bruto[-800:])
        return 1
    r = json.loads(miolo.group(1))
    d = r["decisoes"]
    print(f"  fase alcancada: {r['fase_alcancada']}")
    print(f"  decisoes: {d['fechadas']} fechadas · {d['propostas']} propostas · "
          f"{d['abertas']} abertas")
    print(f"  pode escrever codigo do jogo: {'sim' if r['pode_codar_o_jogo'] else 'ainda nao'}")

    achou = False
    for chave in DEFEITOS:
        for linha in r.get(chave) or []:
            print(f"  DEFEITO [{chave}] {linha}")
            achou = True
    for linha in r.get("bloqueia_codigo") or []:
        if "🟡" in linha:
            print(f"  DEFEITO [palpite] {linha}")
            achou = True

    furos = r.get("buracos") or []
    if furos:
        print(f"  falta preencher: {len(furos)} buraco(s) — normal enquanto o plano anda")
        for linha in furos[:3]:
            print(f"    · {linha}")
        if len(furos) > 3:
            print(f"    · e mais {len(furos) - 3}")
    for linha in r.get("sem_prova") or []:
        print(f"  aviso: {linha}")

    print("  PLANO COM DEFEITO" if achou else "  PLANO SAO")
    return 1 if achou else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
