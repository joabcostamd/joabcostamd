#!/usr/bin/env python3
"""Testes do portao do plano. Rodam em menos de 1 segundo, sem Godot.

    python3 planejamento-jogo-novo/testes-portao.py
"""
from __future__ import annotations

import importlib.util
import shutil
import sys
import tempfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("portao", AQUI / "portao-plano.py")
portao = importlib.util.module_from_spec(spec)
spec.loader.exec_module(portao)

FALHAS: list[str] = []
PASSOU: list[str] = []


def conferir(nome: str, condicao: bool, detalhe: str = "") -> None:
    if condicao:
        PASSOU.append(nome)
        print(f"  [ok]    {nome}")
    else:
        FALHAS.append(nome)
        print(f"  [FALHA] {nome} {detalhe}")


def montar(docs: dict[str, str]) -> Path:
    raiz = Path(tempfile.mkdtemp(prefix="plano-teste-"))
    (raiz / "docs").mkdir()
    for relativo, texto in docs.items():
        (raiz / relativo).write_text(texto, encoding="utf-8")
    return raiz


def plano(estados: dict[str, str], extra: str = "") -> str:
    linhas = ["# PLANO", "", "| Bloco | Assunto | Estado |", "|---|---|---|"]
    for bloco, marca in estados.items():
        linhas.append(f"| {bloco} | assunto | {marca} |")
    return "\n".join(linhas) + "\n" + extra


TODOS_VERDES = {f"B{n}": "🟢" for n in range(13)}
ATE_FASE_2 = {**{f"B{n}": "🟢" for n in range(10)}, "B10": "🔴", "B11": "🔴", "B12": "🔴"}


def teste_jogo_vazio() -> None:
    raiz = montar({})
    r = portao.conferir(raiz)
    conferir("jogo sem nenhum documento reprova", r["status"] == "FALTA")
    conferir("jogo vazio nao alcanca fase nenhuma", r["fase_alcancada"] == -1, r["fase_alcancada"])
    conferir("jogo vazio nao pode codar", r["pode_codar_o_jogo"] is False)
    conferir("jogo vazio acusa documento faltando", len(r["documentos_faltando"]) > 0)
    shutil.rmtree(raiz)


def teste_fase_por_bloco() -> None:
    raiz = montar({"CONCEITO.md": "# c", "docs/PLANO.md": plano({"B0": "🟢", "B1": "🔴"})})
    r = portao.conferir(raiz)
    conferir("so o B0 fechado da fase 0", r["fase_alcancada"] == 0, r["fase_alcancada"])
    shutil.rmtree(raiz)

    raiz = montar({"CONCEITO.md": "# c", "docs/PLANO.md": plano(ATE_FASE_2)})
    r = portao.conferir(raiz)
    conferir("blocos B0..B9 fechados dao fase 2", r["fase_alcancada"] == 2, r["fase_alcancada"])
    conferir("fase 2 destranca o codigo do jogo", r["pode_codar_o_jogo"] is True, r["bloqueia_codigo"])
    conferir("fase 2 ainda bloqueia arte", len(r["bloqueia_arte"]) > 0)
    conferir("fase 2 ainda bloqueia lancamento", len(r["bloqueia_lancamento"]) > 0)
    shutil.rmtree(raiz)


def teste_nao_pula_fase() -> None:
    pulado = {**TODOS_VERDES, "B2": "🔴"}
    raiz = montar({"CONCEITO.md": "# c", "docs/PLANO.md": plano(pulado)})
    r = portao.conferir(raiz)
    conferir("bloco aberto na fase 1 impede chegar na fase 2", r["fase_alcancada"] == 0, r["fase_alcancada"])
    conferir("bloco aberto que trava bloqueia codigo", any("B2" in x for x in r["bloqueia_codigo"]))
    shutil.rmtree(raiz)


def teste_palpite_bloqueia() -> None:
    com_palpite = plano(
        ATE_FASE_2,
        "\n### D-014 · B1 · Camera do jogo 🟡 🤖\nValor: top-down fixa\n",
    )
    raiz = montar({"CONCEITO.md": "# c", "docs/PLANO.md": com_palpite})
    r = portao.conferir(raiz)
    conferir("decisao 🟡 em bloco que trava bloqueia o codigo", r["pode_codar_o_jogo"] is False)
    conferir("o palpite aparece nomeado", any("D-014" in x for x in r["bloqueia_codigo"]))
    conferir("conta a decisao como proposta", r["decisoes"]["propostas"] == 1, r["decisoes"])
    shutil.rmtree(raiz)

    confirmada = plano(ATE_FASE_2, "\n### D-014 · B1 · Camera do jogo 🟢 👤\nValor: top-down\n")
    raiz = montar({"CONCEITO.md": "# c", "docs/PLANO.md": confirmada})
    r = portao.conferir(raiz)
    conferir("a mesma decisao 🟢 libera o codigo", r["pode_codar_o_jogo"] is True, r["bloqueia_codigo"])
    shutil.rmtree(raiz)


def teste_contradicao() -> None:
    conceito = (
        "# Jogo\n\n## O que NAO tem\n\n"
        "- sem multijogador\n- sem mundo aberto\n\n## Fim\n"
    )
    telas = "# TELAS\n\n| Tela | Conteudo |\n|---|---|\n| Sala | lobby de multijogador |\n"
    raiz = montar({"CONCEITO.md": conceito, "docs/PLANO.md": plano(ATE_FASE_2), "docs/TELAS.md": telas})
    r = portao.conferir(raiz)
    conferir("pega o que o CONCEITO recusa e outro doc usa", len(r["contradicoes"]) == 1, r["contradicoes"])
    conferir("a contradicao nomeia o arquivo e a linha", "TELAS.md:5" in r["contradicoes"][0], r["contradicoes"])
    shutil.rmtree(raiz)

    limpo = "# TELAS\n\n| Tela | Conteudo |\n|---|---|\n| Menu | jogar e sair |\n"
    raiz = montar({"CONCEITO.md": conceito, "docs/PLANO.md": plano(ATE_FASE_2), "docs/TELAS.md": limpo})
    r = portao.conferir(raiz)
    conferir("documento coerente nao vira contradicao", r["contradicoes"] == [], r["contradicoes"])
    shutil.rmtree(raiz)


def teste_buraco() -> None:
    raiz = montar(
        {
            "CONCEITO.md": "# Jogo\n\n## Loop\n<descreva o loop aqui>\n",
            "docs/PLANO.md": plano(ATE_FASE_2),
        }
    )
    r = portao.conferir(raiz)
    conferir("acha placeholder deixado no documento", len(r["buracos"]) == 1, r["buracos"])
    conferir("buraco reprova o plano", r["status"] == "FALTA")
    shutil.rmtree(raiz)


def teste_sem_prova() -> None:
    design = "# DESIGN\n\n| calor | 22/s |\n\nEstes numeros sao chute honesto.\n"
    raiz = montar({"CONCEITO.md": "# c", "docs/PLANO.md": plano(ATE_FASE_2), "docs/DESIGN.md": design})
    r = portao.conferir(raiz)
    conferir("avisa numero que ainda nao passou pelo simulador", len(r["sem_prova"]) == 1, r["sem_prova"])
    shutil.rmtree(raiz)


def teste_bloco_delimitado() -> None:
    import io
    import contextlib

    raiz = montar({"CONCEITO.md": "# c", "docs/PLANO.md": plano({"B0": "🟢"})})
    buffer = io.StringIO()
    with contextlib.redirect_stdout(buffer):
        portao.main(["portao-plano.py", str(raiz)])
    saida = buffer.getvalue()
    conferir("imprime o bloco delimitado de abertura", "===PLANO-VERIFY===" in saida)
    conferir("imprime o bloco delimitado de fim", "===FIM-PLANO-VERIFY===" in saida)
    import json

    miolo = saida.split("===PLANO-VERIFY===")[1].split("===FIM-PLANO-VERIFY===")[0]
    conferir("o miolo do bloco e JSON valido", isinstance(json.loads(miolo), dict))
    shutil.rmtree(raiz)


for teste in (
    teste_jogo_vazio,
    teste_fase_por_bloco,
    teste_nao_pula_fase,
    teste_palpite_bloqueia,
    teste_contradicao,
    teste_buraco,
    teste_sem_prova,
    teste_bloco_delimitado,
):
    teste()

total = len(PASSOU) + len(FALHAS)
if FALHAS:
    print(f"\nFALHARAM {len(FALHAS)} de {total}")
    sys.exit(1)
print(f"\nTODOS OS TESTES PASSARAM ({len(PASSOU)}/{total})")
