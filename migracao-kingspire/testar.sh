#!/usr/bin/env bash
# O portao deste repositorio.
#   ./testar.sh
#
# Enquanto o jogo estiver na fase de PLANO, ele roda:
#   1. os testes do proprio portao (ele mente se ninguem testar)
#   2. o portao do plano sobre os documentos deste jogo
#   3. o validador do gerador de mapa do prototipo
#
# Quando o projeto Godot nascer (fase 1), este script tambem chama o
# agent_verify e a suite headless. Ate la, plano e prova.
set -uo pipefail
cd "$(dirname "$0")"
FALHOU=0

echo "════════ testes do portao ════════"
python3 planejamento/testes-portao.py || FALHOU=1

echo
echo "════════ portao do plano ════════"
# O portao do plano responde "o plano ACABOU?". Aqui a pergunta e outra:
# "o plano esta SAO?". Buraco por preencher e progresso normal; o que reprova
# e defeito — contradicao, palpite amarelo travando codigo, decisao verde sem
# dono, documento exigido que nao existe.
python3 planejamento/portao-plano.py . > /tmp/plano-verify.txt 2>&1 || true
python3 planejamento/ler-plano.py /tmp/plano-verify.txt || FALHOU=1

echo
echo "════════ gerador de mapa ════════"
python3 - <<'PY' || FALHOU=1
import sys, importlib.util
from pathlib import Path
spec = importlib.util.spec_from_file_location("g", Path("prototipo/gerador_mapa.py"))
G = importlib.util.module_from_spec(spec); spec.loader.exec_module(G)
ruim = []
for arranjo in G.ARRANJOS:
    for bioma in G.PERFIL:
        ok = sum(G.validar(*G.gerar(s, bioma, arranjo))[0] for s in range(1, 21))
        print(f"  {arranjo:<8} {bioma:<9} {ok:>2}/20 aprovados")
        if ok < 12:
            ruim.append(f"{arranjo}/{bioma} so {ok}/20")
if ruim:
    print("\nREPROVADO — combinacao com aprovacao baixa demais:")
    for r in ruim: print("  " + r)
    sys.exit(1)
print("\n  todas as combinacoes acima de 60% de aprovacao")
PY

echo
if [ "$FALHOU" -eq 0 ]; then
  echo "TUDO VERDE"
else
  echo "ALGO REPROVOU — leia acima"
fi
exit "$FALHOU"
