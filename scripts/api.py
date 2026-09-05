#!/usr/bin/env python3
"""Confere se um método/propriedade/sinal existe MESMO na API do Godot.

    scripts/api.py CharacterBody2D            # lista tudo da classe
    scripts/api.py CharacterBody2D move_and   # filtra por pedaço do nome
    scripts/api.py --tem Node2D get_position  # responde sim/não

Usa o extension_api.json gerado pelo próprio Godot instalado.
"""
import json, os, subprocess, sys, tempfile
from pathlib import Path

CACHE = Path.home() / ".cache" / "godot-api" / "extension_api.json"


def carregar():
    if not CACHE.exists():
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        godot = os.path.expanduser("~/.local/bin/godot")
        if not os.path.exists(godot):
            godot = "godot"
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run([godot, "--headless", "--dump-extension-api"],
                           cwd=tmp, check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            CACHE.write_bytes((Path(tmp) / "extension_api.json").read_bytes())
    return json.loads(CACHE.read_text())


def membros(dados, nome):
    classes = {c["name"]: c for c in dados["classes"]}
    if nome not in classes:
        parecidos = [n for n in classes if nome.lower() in n.lower()][:8]
        print(f"classe '{nome}' não existe." + (f" Parecidas: {', '.join(parecidos)}" if parecidos else ""))
        sys.exit(1)
    saida, visto = [], set()
    atual = nome
    while atual and atual in classes:
        c = classes[atual]
        for m in c.get("methods", []):
            if m["name"] not in visto:
                visto.add(m["name"])
                args = ", ".join(a["name"] for a in m.get("arguments", []))
                saida.append(("método", f'{m["name"]}({args})', atual))
        for p in c.get("properties", []):
            if p["name"] not in visto:
                visto.add(p["name"]); saida.append(("propriedade", p["name"], atual))
        for s in c.get("signals", []):
            if s["name"] not in visto:
                visto.add(s["name"]); saida.append(("sinal", s["name"], atual))
        atual = c.get("inherits")
    return saida


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__); sys.exit(1)
    so_tem = args[0] == "--tem"
    if so_tem:
        args = args[1:]
    classe = args[0]
    filtro = args[1].lower() if len(args) > 1 else ""
    itens = membros(carregar(), classe)

    if so_tem:
        achou = any(filtro == n.split("(")[0].lower() for _, n, _ in itens)
        print(f"{classe}.{args[1]} → {'EXISTE' if achou else 'NÃO EXISTE'}")
        sys.exit(0 if achou else 1)

    itens = [i for i in itens if filtro in i[1].lower()] if filtro else itens
    if not itens:
        print(f"nada em {classe} com '{filtro}'"); sys.exit(1)
    for tipo, nome, dono in sorted(itens, key=lambda x: x[1]):
        print(f"  {tipo:13} {nome:45} ({dono})")
    print(f"\n{len(itens)} resultado(s)")


if __name__ == "__main__":
    main()
