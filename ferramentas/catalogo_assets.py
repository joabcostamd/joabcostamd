#!/usr/bin/env python3
"""Indexa todo asset de um projeto Godot em assets/CATALOGO.md.

Existe por um motivo só: impedir que alguém (humano ou IA) invente um nome de
sprite que não existe. Antes de referenciar um asset, consulte o catálogo.

    python3 ferramentas/catalogo_assets.py jogos/meu-jogo
"""
import sys, os, collections

EXTS = {
    "imagem": {".png", ".jpg", ".jpeg", ".webp", ".svg"},
    "audio": {".ogg", ".wav", ".mp3"},
    "modelo": {".glb", ".gltf", ".obj", ".fbx"},
    "fonte": {".ttf", ".otf", ".woff2"},
    "dado": {".json", ".csv", ".tres", ".xml"},
}
IGNORAR = {".godot", ".verify", ".git", "build", "__pycache__"}


def tipo_de(ext):
    for t, exts in EXTS.items():
        if ext in exts:
            return t
    return None


def humano(n):
    for u in ("B", "KB", "MB", "GB"):
        if n < 1024 or u == "GB":
            return f"{n:.0f} {u}" if u == "B" else f"{n:.1f} {u}"
        n /= 1024


def main():
    proj = sys.argv[1] if len(sys.argv) > 1 else "."
    base = os.path.join(proj, "assets")
    if not os.path.isdir(base):
        print(f"sem pasta assets/ em {proj} — nada a catalogar")
        return 0

    porpasta = collections.defaultdict(list)
    total_bytes = 0
    for raiz, dirs, arquivos in os.walk(base):
        dirs[:] = [d for d in dirs if d not in IGNORAR]
        for a in sorted(arquivos):
            if a.startswith("."):
                continue
            ext = os.path.splitext(a)[1].lower()
            t = tipo_de(ext)
            if not t:
                continue
            cheio = os.path.join(raiz, a)
            tam = os.path.getsize(cheio)
            total_bytes += tam
            rel = os.path.relpath(cheio, proj).replace(os.sep, "/")
            grupo = os.path.relpath(raiz, base).replace(os.sep, "/")
            porpasta[grupo].append((a, t, tam, "res://" + rel))

    total = sum(len(v) for v in porpasta.values())
    linhas = [
        "# Catálogo de assets",
        "",
        "Gerado por `ferramentas/catalogo_assets.py`. **Não edite à mão.**",
        "",
        "Antes de escrever um caminho de asset no código ou numa cena, ache o nome",
        "aqui. Nome inventado é o defeito mais caro: o jogo abre, não reclama, e a",
        "textura simplesmente não aparece.",
        "",
        f"**{total} arquivos · {humano(total_bytes)}**",
        "",
    ]
    for grupo in sorted(porpasta):
        nome = "assets/" if grupo == "." else f"assets/{grupo}/"
        itens = porpasta[grupo]
        linhas += [f"## {nome} ({len(itens)})", "", "| arquivo | tipo | tamanho | caminho res:// |", "|---|---|---|---|"]
        for a, t, tam, res in itens:
            linhas.append(f"| `{a}` | {t} | {humano(tam)} | `{res}` |")
        linhas.append("")

    saida = os.path.join(base, "CATALOGO.md")
    with open(saida, "w", encoding="utf-8") as f:
        f.write("\n".join(linhas))
    print(f"catálogo: {saida} — {total} assets, {humano(total_bytes)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
