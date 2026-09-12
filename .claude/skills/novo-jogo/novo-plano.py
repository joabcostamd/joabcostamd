#!/usr/bin/env python3
"""Faz nascer a pasta de planejamento de um jogo novo — sem projeto Godot ainda.

    novo-plano.py <slug> "Nome do Jogo"

Cria jogos/<slug>/ com CONCEITO.md e docs/ contendo os 11 modelos em branco.
O projeto Godot so entra depois da fase 1 passar (ver BLOCOS.md).

Funciona de QUALQUER pasta: acha o repositorio sozinho.
"""
from __future__ import annotations

import datetime as dt
import os
import re
import shutil
import sys
from pathlib import Path

MARCA = "PREFERENCIAS-DE-JOAB.md"  # o arquivo que identifica o repositorio
PASTA = "planejamento-jogo-novo"
NA_RAIZ = ("CONCEITO.md",)  # o resto vai para docs/


def achar_repositorio() -> Path | None:
    """Acha a raiz do repositorio a partir de qualquer lugar."""
    # 1. variavel de ambiente, se o Joab quiser fixar
    if (env := os.environ.get("JOGOS_RAIZ")):
        alvo = Path(env).expanduser()
        if (alvo / MARCA).is_file():
            return alvo

    # 2. subindo a partir da pasta atual
    atual = Path.cwd().resolve()
    for pasta in (atual, *atual.parents):
        if (pasta / MARCA).is_file() and (pasta / PASTA).is_dir():
            return pasta

    # 3. os lugares onde ele costuma ficar, nas duas maquinas
    casa = Path.home()
    candidatos = [
        casa / "joabcostamd",
        casa / "Documentos" / "joabcostamd",
        casa / "Documents" / "joabcostamd",
        casa / "dev" / "joabcostamd",
        casa / "projetos" / "joabcostamd",
        Path("/home/user/joabcostamd"),
    ]
    for alvo in candidatos:
        if (alvo / MARCA).is_file():
            return alvo
    return None


def preencher(texto: str, nome: str, slug: str) -> str:
    hoje = dt.date.today().isoformat()
    texto = texto.replace("<NOME DO JOGO>", nome)
    texto = texto.replace("<AAAA-MM-DD>", hoje)
    return texto.replace("<slug>", slug)


def criar(raiz: Path, slug: str, nome: str) -> Path:
    modelos = raiz / PASTA / "modelos"
    if not modelos.is_dir():
        raise SystemExit(f"modelos nao encontrados em {modelos}")

    destino = raiz / "jogos" / slug
    if destino.exists():
        raise SystemExit(f"ja existe: {destino}")

    (destino / "docs").mkdir(parents=True)
    for modelo in sorted(modelos.glob("*.md")):
        alvo = destino / modelo.name if modelo.name in NA_RAIZ else destino / "docs" / modelo.name
        alvo.write_text(
            preencher(modelo.read_text(encoding="utf-8"), nome, slug), encoding="utf-8"
        )

    (destino / "README.md").write_text(
        f"# {nome}\n\n"
        f"**Fase: planejamento.** Nenhuma linha de GDScript antes do plano fechar a fase 2.\n\n"
        f"| | |\n|---|---|\n"
        f"| o que e o jogo | [`CONCEITO.md`](CONCEITO.md) |\n"
        f"| onde paramos | [`docs/PLANO.md`](docs/PLANO.md) |\n"
        f"| a pesquisa | [`docs/PESQUISA.md`](docs/PESQUISA.md) |\n\n"
        f"```bash\n"
        f"python3 {PASTA}/portao-plano.py jogos/{slug}\n"
        f"```\n",
        encoding="utf-8",
    )
    return destino


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print('uso: novo-plano.py <slug> "Nome do Jogo"', file=sys.stderr)
        return 2
    slug = argv[1]
    if not re.fullmatch(r"[a-z0-9-]+", slug):
        print(f"slug so aceita minusculas, numeros e hifen: {slug}", file=sys.stderr)
        return 2
    nome = argv[2] if len(argv) > 2 else slug

    raiz = achar_repositorio()
    if raiz is None:
        print(
            "Nao achei o repositorio dos jogos.\n"
            f"Ele e a pasta que contem {MARCA} e {PASTA}/.\n"
            "Diga onde ele esta, ou rode assim:\n"
            '  JOGOS_RAIZ=/caminho/do/repo novo-plano.py <slug> "Nome"',
            file=sys.stderr,
        )
        return 2

    destino = criar(raiz, slug, nome)
    rel = destino.relative_to(raiz)
    print(f"repositorio: {raiz}")
    print(f"criado: {rel}/  — CONCEITO.md na raiz, 10 documentos em docs/")
    print()
    print("Projeto Godot NAO foi criado de proposito: ele so entra depois da fase 1.")
    print("Proximo passo: bloco B0 do banco de perguntas, e a pesquisa de mercado.")
    print()
    print(f"  python3 {PASTA}/portao-plano.py {rel}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
