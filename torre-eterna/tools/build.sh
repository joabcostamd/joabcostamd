#!/usr/bin/env bash
# Constroi as builds de release.
#
# Faz, nesta ordem, o que NAO pode ser esquecido antes de subir para uma loja:
#   1. baixa as fontes (elas nao sao versionadas)
#   2. roda os portoes — build vermelha nao vira loja
#   3. exporta cada plataforma pedida
#
# Uso:
#   bash tools/build.sh                 # todas as plataformas
#   bash tools/build.sh Linux           # so uma
#   bash tools/build.sh --sem-portoes   # pula a checagem (para iterar rapido)
set -euo pipefail
cd "$(dirname "$0")/.."
RAIZ="$(pwd)"
SAIDA="$RAIZ/../build"

PORTOES=1
ALVOS=()
for a in "$@"; do
  case "$a" in
    --sem-portoes) PORTOES=0 ;;
    *) ALVOS+=("$a") ;;
  esac
done
if [ ${#ALVOS[@]} -eq 0 ]; then
  ALVOS=("Windows Desktop" "Linux" "macOS")
fi

echo "=== 1/3 fontes ==="
bash tools/baixar_fontes.sh || true
if ! ls fontes/*.ttf >/dev/null 2>&1; then
  echo
  echo "AVISO: nenhuma fonte em fontes/."
  echo "A build vai sair com a letra padrao do motor, e chines, japones,"
  echo "coreano e tailandes vao aparecer como quadradinhos."
  echo
fi

if [ "$PORTOES" = "1" ]; then
  echo "=== 2/3 portoes ==="
  # `===STATUS=== PASS` e o contrato deste projeto, e nao o codigo de saida:
  # varias ferramentas do Godot terminam em 0 mesmo tendo reprovado.
  falhou=0
  for portao in verificar lint validar_dados traducoes testes; do
    printf "  %-16s " "$portao"
    saida="$(timeout 900 godot --headless --path . -s "res://tools/$portao.gd" 2>&1 || true)"
    if echo "$saida" | grep -q "===STATUS=== PASS"; then
      echo "PASS"
    else
      echo "FAIL"
      echo "$saida" | grep -E "ERRO|FALHOU" | head -10
      falhou=1
    fi
  done
  if [ "$falhou" = "1" ]; then
    echo
    echo "Portao reprovado. Build cancelada."
    echo "Para ignorar (nao faca isso para uma loja): --sem-portoes"
    exit 1
  fi
else
  echo "=== 2/3 portoes PULADOS ==="
fi

echo "=== 3/3 exportando ==="
VERSAO="$(grep -oP 'config/version="\K[^"]+' project.godot || echo "0.0.0")"
echo "  versao $VERSAO"
mkdir -p "$SAIDA"
for alvo in "${ALVOS[@]}"; do
  printf "  %-18s " "$alvo"
  if timeout 900 godot --headless --path . --export-release "$alvo" >/tmp/export.log 2>&1; then
    echo "ok"
  else
    echo "FALHOU"
    tail -4 /tmp/export.log | sed 's/^/      /'
  fi
done

echo
echo "--- saida em $SAIDA ---"
ls -la "$SAIDA"/*/* 2>/dev/null || echo "(vazio — provavelmente faltam os templates de exportacao do Godot)"
