#!/usr/bin/env bash
# Suíte do CRUZADA. O núcleo primeiro: é o mais rápido e o que mais quebra.
set -e
cd "$(dirname "$0")"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "MODO DEGRADADO — Godot não encontrado no PATH; rodando só os validadores"
  python3 ferramentas/medir_layout.py
  python3 ferramentas/validar_contraste.py
  exit 0
fi

limpar() { grep -vE "^(WARNING|OpenGL|libpulse|   at:)" | grep -v "^$"; }

echo "── núcleo: cartas, mãos, grade, metas, acaso ──"
"$GODOT" --headless --import >/dev/null 2>&1 || true
"$GODOT" --headless --script res://testes/nucleo.gd 2>&1 | limpar

echo
echo "── mesa: turno, janela, parcela, tear, avesso, fecho ──"
"$GODOT" --headless --script res://testes/mesa.gd 2>&1 | limpar

echo
echo "── desafio: as três réguas, o dial, a geometria e a rede ──"
"$GODOT" --headless --script res://testes/desafio.gd 2>&1 | limpar

echo
echo "── loja: níveis, selos, relíquias, dinheiro e a rodada 6 ──"
"$GODOT" --headless --script res://testes/loja.gd 2>&1 | limpar

echo
echo "── run: as 18 mesas, as 3 vidas, o perfil e os desbloqueios ──"
"$GODOT" --headless --script res://testes/run.gd 2>&1 | limpar

echo
echo "── fluxo: menu, partida, run inteira, fecho ──"
# Roda como cena: o `_ready` das telas só acontece depois que o laço principal
# começa, e sob `--script` o teste mediria um jogo que ainda não nasceu.
"$GODOT" --headless res://testes/fluxo.tscn 2>&1 | limpar

echo
echo "── aferição contra as bandas da bancada ──"
# O motor precisa REPRODUZIR o protótipo que produziu os números do DESIGN §9.
# Sem isto, "portamos o núcleo" seria uma afirmação sem prova.
"$GODOT" --headless --script res://ferramentas/aferir.gd -- "${AFERIR_SEMENTES:-12}" 2>&1 | limpar

echo
echo "── capturas da maquete (8 temas × 3 modos) ──"
# Captura exige display: em --headless o renderizador é nulo e não desenha nada.
if command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a "$GODOT" --resolution 1280x720 res://maquete/capturas.tscn
  echo
  echo "── escala tipográfica e algarismos ──"
  # Exige display: o TextServer não mede texto sob --headless puro.
  xvfb-run -a "$GODOT" --resolution 640x480 res://maquete/tipografia.tscn 2>/dev/null | limpar
else
  echo "CAPTURAS — puladas — xvfb ausente"
fi

echo
echo "── alvos de toque em todos os tamanhos ──"
python3 ferramentas/medir_layout.py

echo
echo "── contraste WCAG AA em todos os temas ──"
python3 ferramentas/validar_contraste.py
