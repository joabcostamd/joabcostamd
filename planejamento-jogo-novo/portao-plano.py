#!/usr/bin/env python3
"""Portao do plano — diz se um jogo ja pode virar codigo.

    planejamento-jogo-novo/portao-plano.py jogos/<slug>

Le os documentos de planejamento e imprime um bloco delimitado. O BLOCO e a unica
fonte de verdade — exit code nao conta, igual ao portao frio (agent_verify.gd).

Regra que impede alucinacao: decisao 🟡 (palpite do agente que ninguem confirmou)
em bloco que trava = codigo bloqueado.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

VERSAO_REGUA = "1"

# --- o mapa, espelhado de BLOCOS.md -----------------------------------------

FASES: dict[int, list[str]] = {
    0: ["B0"],
    1: ["B1", "B2", "B3"],
    2: ["B4", "B5", "B6", "B7", "B8", "B9"],
    3: ["B10", "B12"],
    4: ["B11"],
}

NOME_BLOCO = {
    "B0": "Identidade",
    "B1": "Espaco e movimento",
    "B2": "Estrutura da partida",
    "B3": "Acao central",
    "B4": "Progressao na partida",
    "B5": "Meta-progressao",
    "B6": "Conteudo e espaco",
    "B7": "Oposicao",
    "B8": "Telas e fluxo",
    "B9": "Arquitetura e dados",
    "B10": "Apresentacao",
    "B11": "Produto",
    "B12": "Producao de assets por IA",
}

# fase 0-2 tem que estar fechada para o codigo do jogo comecar
FASES_QUE_TRAVAM_CODIGO = (0, 1, 2)
FASE_QUE_TRAVA_ARTE = 3
FASE_QUE_TRAVA_LANCAMENTO = 4

DOCUMENTOS = {
    "CONCEITO.md": "CONCEITO.md",
    "PLANO.md": "docs/PLANO.md",
    "PESQUISA.md": "docs/PESQUISA.md",
    "DESIGN.md": "docs/DESIGN.md",
    "TELAS.md": "docs/TELAS.md",
    "ARTE.md": "docs/ARTE.md",
    "SOM.md": "docs/SOM.md",
    "ARQUITETURA.md": "docs/ARQUITETURA.md",
    "PRODUCAO.md": "docs/PRODUCAO.md",
    "GLOSSARIO.md": "docs/GLOSSARIO.md",
    "DECISOES.md": "docs/DECISOES.md",
}

# documento obrigatorio a partir de cada fase
EXIGIDO_NA_FASE = {
    0: ["CONCEITO.md", "PLANO.md"],
    1: ["PESQUISA.md", "GLOSSARIO.md"],
    2: ["DESIGN.md", "TELAS.md", "ARQUITETURA.md", "DECISOES.md"],
    3: ["ARTE.md", "SOM.md"],
    4: ["PRODUCAO.md"],
}

BURACOS = re.compile(
    r"(<[a-zç][^>\n]{2,}>|\bTODO\b|\bFIXME\b|a definir|lorem ipsum|preencher aqui)",
    re.IGNORECASE,
)

ABERTA, PROPOSTA, FECHADA = "🔴", "🟡", "🟢"

# --- leitura ----------------------------------------------------------------


def ler(jogo: Path) -> dict[str, str]:
    """Devolve {apelido: texto} so dos documentos que existem."""
    achados = {}
    for apelido, relativo in DOCUMENTOS.items():
        caminho = jogo / relativo
        if caminho.is_file():
            achados[apelido] = caminho.read_text(encoding="utf-8", errors="replace")
    return achados


def estado_dos_blocos(plano: str) -> dict[str, str]:
    """Le as linhas de tabela `| B3 | ... | 🟢 |` do PLANO.md."""
    estados: dict[str, str] = {}
    for linha in plano.splitlines():
        achou = re.match(r"\s*\|\s*\*{0,2}(B\d{1,2})\*{0,2}\s*\|", linha)
        if not achou:
            continue
        bloco = achou.group(1)
        if bloco not in NOME_BLOCO:
            continue
        for marca in (FECHADA, PROPOSTA, ABERTA):
            if marca in linha:
                estados[bloco] = marca
                break
    return estados


def decisoes(plano: str) -> list[dict]:
    """Le cabecalhos `### D-014 · B1 · Camera 🟢 👤`."""
    achadas = []
    for linha in plano.splitlines():
        achou = re.match(r"\s*#{2,4}\s*(D-\d{3,})\s*[·|-]\s*(B\d{1,2})\s*[·|-]\s*(.+)", linha)
        if not achou:
            continue
        ident, bloco, resto = achou.groups()
        estado = next((m for m in (FECHADA, PROPOSTA, ABERTA) if m in resto), ABERTA)
        achadas.append(
            {
                "id": ident,
                "bloco": bloco,
                "titulo": re.sub(r"[🔴🟡🟢👤📏🤖]", "", resto).strip(),
                "estado": estado,
                "origem_palpite": "🟡" in resto or "🤖" not in resto and "👤" not in resto and "📏" not in resto,
            }
        )
    return achadas


def fase_alcancada(estados: dict[str, str]) -> int:
    """Maior fase cujos blocos estao todos 🟢, sem pular fase."""
    alcancada = -1
    for numero in sorted(FASES):
        if all(estados.get(b) == FECHADA for b in FASES[numero]):
            alcancada = numero
        else:
            break
    return alcancada


# --- checagens --------------------------------------------------------------


def buracos(docs: dict[str, str]) -> list[str]:
    saida = []
    for apelido, texto in sorted(docs.items()):
        for numero, linha in enumerate(texto.splitlines(), 1):
            achou = BURACOS.search(linha)
            if achou:
                saida.append(f"{DOCUMENTOS[apelido]}:{numero} ainda tem buraco: {achou.group(0)!r}")
    return saida


def escopo_negativo(conceito: str) -> list[str]:
    """Extrai os itens da secao 'O que NAO tem' do CONCEITO.md."""
    corpo = re.split(r"^##\s+O que (?:N[AÃ]O|nao) tem\s*$", conceito, flags=re.M | re.I)
    if len(corpo) < 2:
        return []
    trecho = re.split(r"^##\s", corpo[1], flags=re.M)[0]
    itens = []
    for linha in trecho.splitlines():
        achou = re.match(r"\s*[-*]\s+(.+)", linha)
        if not achou:
            continue
        texto = re.sub(r"\*\*|`|_", "", achou.group(1))
        texto = re.sub(r"^sem\s+", "", texto.strip(), flags=re.I)
        # fica so com o miolo antes de qualquer explicacao
        texto = re.split(r"[.,;:—–(]", texto)[0].strip()
        if 3 <= len(texto) <= 40:
            itens.append(texto)
    return itens


def contradicoes(docs: dict[str, str]) -> list[str]:
    """O que um documento promete e outro desmente."""
    achadas = []
    conceito = docs.get("CONCEITO.md", "")
    for proibido in escopo_negativo(conceito):
        agulha = re.compile(r"\b" + re.escape(proibido) + r"\b", re.I)
        for apelido in ("TELAS.md", "DESIGN.md", "ARQUITETURA.md", "PRODUCAO.md"):
            texto = docs.get(apelido)
            if not texto:
                continue
            for numero, linha in enumerate(texto.splitlines(), 1):
                if agulha.search(linha) and not re.search(r"\bsem\b|\bnao\b|\bnão\b", linha, re.I):
                    achadas.append(
                        f"CONCEITO diz que nao tem {proibido!r}, "
                        f"mas {DOCUMENTOS[apelido]}:{numero} usa isso"
                    )
    return achadas


def sem_prova(docs: dict[str, str]) -> list[str]:
    """Numero ainda marcado como chute, que nao passou pelo simulador."""
    saida = []
    for apelido in ("DESIGN.md", "ARQUITETURA.md"):
        texto = docs.get(apelido)
        if not texto:
            continue
        for numero, linha in enumerate(texto.splitlines(), 1):
            if re.search(r"\bchute\b|a ser corrigid|falta simular", linha, re.I):
                saida.append(f"{DOCUMENTOS[apelido]}:{numero} ainda e chute — rode ./simular.sh")
    return saida


# --- veredito ---------------------------------------------------------------


def conferir(jogo: Path) -> dict:
    docs = ler(jogo)
    plano = docs.get("PLANO.md", "")
    estados = estado_dos_blocos(plano)
    todas = decisoes(plano)
    fase = fase_alcancada(estados)

    def pendentes(fases: tuple[int, ...] | int) -> list[str]:
        numeros = (fases,) if isinstance(fases, int) else fases
        saida = []
        for numero in numeros:
            for bloco in FASES[numero]:
                marca = estados.get(bloco)
                if marca == FECHADA:
                    continue
                rotulo = marca or "ausente"
                saida.append(f"{bloco} {NOME_BLOCO[bloco]} — {rotulo}")
        return saida

    palpites = [
        f"{d['id']} {d['bloco']} {d['titulo']} — 🟡 ninguem confirmou"
        for d in todas
        if d["estado"] == PROPOSTA
        and any(d["bloco"] in FASES[n] for n in FASES_QUE_TRAVAM_CODIGO)
    ]

    faltando_doc = []
    for numero in sorted(EXIGIDO_NA_FASE):
        if numero > max(fase, 0) + 1:
            break
        for apelido in EXIGIDO_NA_FASE[numero]:
            if apelido not in docs:
                faltando_doc.append(f"{DOCUMENTOS[apelido]} nao existe (exigido na fase {numero})")

    bloqueia_codigo = pendentes(FASES_QUE_TRAVAM_CODIGO) + palpites
    contra = contradicoes(docs)
    furos = buracos(docs)

    passou = not (bloqueia_codigo or contra or furos or faltando_doc)

    return {
        "versao_regua": VERSAO_REGUA,
        "jogo": jogo.name,
        "status": "PASS" if passou else "FALTA",
        "fase_alcancada": fase,
        "pode_codar_o_jogo": not bloqueia_codigo,
        "bloqueia_codigo": bloqueia_codigo,
        "bloqueia_arte": pendentes(FASE_QUE_TRAVA_ARTE),
        "bloqueia_lancamento": pendentes(FASE_QUE_TRAVA_LANCAMENTO),
        "contradicoes": contra,
        "buracos": furos,
        "documentos_faltando": faltando_doc,
        "sem_prova": sem_prova(docs),
        "decisoes": {
            "abertas": sum(1 for d in todas if d["estado"] == ABERTA),
            "propostas": sum(1 for d in todas if d["estado"] == PROPOSTA),
            "fechadas": sum(1 for d in todas if d["estado"] == FECHADA),
        },
    }


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("uso: portao-plano.py jogos/<slug>", file=sys.stderr)
        return 2
    jogo = Path(argv[1])
    if not jogo.is_dir():
        print(f"pasta nao encontrada: {jogo}", file=sys.stderr)
        return 2

    veredito = conferir(jogo)
    print("===PLANO-VERIFY===")
    print(json.dumps(veredito, ensure_ascii=False, indent=2))
    print("===FIM-PLANO-VERIFY===")
    return 0 if veredito["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
