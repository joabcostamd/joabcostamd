#!/usr/bin/env bash
# Junta os lotes que os agentes escreveram em /tmp/trad/out/ nos arquivos de
# idioma do jogo, e roda o portao de traducao em cima do resultado.
#
# Roda quantas vezes quiser: cada volta absorve o que ficou pronto desde a
# ultima. E idempotente.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import json, glob, os, collections
RAIZ = os.getcwd()
alvo = {'ui': 'data/i18n/idiomas', 'ct': 'data/i18n/conteudo'}
partes = collections.defaultdict(dict)
for f in sorted(glob.glob('/tmp/trad/out/*__*.json')):
    nome = os.path.basename(f)[:-5]
    lang, lote = nome.split('__')
    tipo = lote.split('_')[0]
    try:
        partes[(lang, tipo)].update(json.load(open(f, encoding='utf-8')))
    except Exception as e:
        print("  ignorado (json invalido): %s — %s" % (nome, e))
if not partes:
    print("nada novo em /tmp/trad/out/")
for (lang, tipo), m in sorted(partes.items()):
    d = os.path.join(RAIZ, alvo[tipo])
    os.makedirs(d, exist_ok=True)
    caminho = os.path.join(d, lang + '.json')
    atual = json.load(open(caminho, encoding='utf-8')) if os.path.exists(caminho) else {}
    antes = len(atual)
    atual.update({k: v for k, v in m.items() if str(v).strip()})
    json.dump(atual, open(caminho, 'w', encoding='utf-8'),
              ensure_ascii=False, indent=0, sort_keys=True)
    print("  %-8s %-3s  %4d -> %4d" % (lang, tipo, antes, len(atual)))
PY
echo
godot --headless --path . -s res://tools/traducoes.gd 2>&1 | grep -E "ERRO|aviso|===STATUS" | head -30
