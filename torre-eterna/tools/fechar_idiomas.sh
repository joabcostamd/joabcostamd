#!/usr/bin/env bash
# Absorve os lotes prontos, marca como publicavel quem ficou completo, confere e
# comita. Idempotente: rode quantas vezes quiser.
#
# Existe porque trabalho em segundo plano NAO sobrevive a um reinicio de
# container — o que estava no disco sobreviveu, o que estava so na memoria do
# agente, nao. Cada idioma que fecha vai para o git na hora.
set -euo pipefail
cd "$(dirname "$0")/.."

bash tools/merge_traducoes.sh >/tmp/merge.log 2>&1 || true
grep -E "^  [a-z]" /tmp/merge.log || echo "  (nada novo)"

python3 - <<'PY'
import io, re, json, os
fonte = json.load(open('data/i18n/_fonte.json', encoding='utf-8'))
n_ui, n_ct = len(fonte['interface']), len(fonte['conteudo'])
p = "scripts/core/idiomas.gd"
s = io.open(p, encoding='utf-8').read()
novos = []
for cod in re.findall(r'\{"cod": "([^"]+)"', s):
    if cod in ('pt-BR', 'en'):
        continue
    fu, fc = 'data/i18n/idiomas/%s.json' % cod, 'data/i18n/conteudo/%s.json' % cod
    u = len(json.load(open(fu, encoding='utf-8'))) if os.path.exists(fu) else 0
    c = len(json.load(open(fc, encoding='utf-8'))) if os.path.exists(fc) else 0
    if u >= n_ui and c >= n_ct and ('"cod": "%s"' % cod) in s:
        antes = s
        s = re.sub(r'(\{"cod": "%s",[^}]*?)"pronto": false\}' % re.escape(cod), r'\1"pronto": true}', s)
        if s != antes:
            novos.append(cod)
# es-419 e coberto por es-ES pela cadeia de irmaos
if '"cod": "es-ES",' in s and '"cod": "es-ES", ' in s.replace('"pronto": true', '"pronto": true'):
    if re.search(r'\{"cod": "es-ES",[^}]*"pronto": true\}', s):
        antes = s
        s = re.sub(r'(\{"cod": "es-419",[^}]*?)"pronto": false\}', r'\1"pronto": true}', s)
        if s != antes:
            novos.append('es-419')
io.open(p, 'w', encoding='utf-8').write(s)
print("  idiomas que ficaram prontos agora: %s" % (", ".join(novos) if novos else "nenhum"))
PY

echo
for portao in lint validar_dados traducoes testes; do
  printf "  %-15s " "$portao"
  saida="$(timeout 900 godot --headless --path . -s "res://tools/$portao.gd" 2>&1 || true)"
  if echo "$saida" | grep -q "===STATUS=== PASS"; then echo "PASS"; else
    echo "FAIL"; echo "$saida" | grep -E "ERRO|FALHOU" | head -6; exit 1
  fi
done

# Os contadores da documentacao sao portao: atualiza antes de comitar.
L="$(godot --headless --path . -s res://tools/lint.gd 2>&1 | grep -oP 'linhas=\K[0-9]+')"
sed -i "s/linhas=[0-9]*/linhas=$L/" docs/QUALIDADE.md

cd ..
if git diff --quiet && git diff --cached --quiet; then
  echo; echo "  nada mudou — nada a comitar"; exit 0
fi
PRONTOS="$(grep -c '"pronto": true' torre-eterna/scripts/core/idiomas.gd)"
git add -A
git commit -q -m "chore(i18n): $PRONTOS idiomas publicaveis

Absorvido por tools/fechar_idiomas.sh. Portoes lint, validar_dados, traducoes e
testes verdes. Um idioma so vira publicavel quando a contagem de chaves bate com
a fonte — medicao, nao otimismo.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01KjywRohvpoYfEskZwwMkww"
git push -q -u origin claude/idle-tower-defense-game-pum4s4 2>&1 | tail -1 || true
echo; echo "  comitado e enviado: $PRONTOS idiomas publicaveis"
