#!/usr/bin/env bash
# Prepara uma máquina limpa para rodar o PLACARD e a suíte inteira.
#
# Idempotente: rodar de novo não quebra nada. Só instala o que falta.
set -euo pipefail

VERSAO="4.7.2"
DESTINO="${GODOT_DIR:-$HOME/godot}"
ZIP="Godot_v${VERSAO}-stable_linux.x86_64"
URL="https://github.com/godotengine/godot/releases/download/${VERSAO}-stable/${ZIP}.zip"

msg() { printf '\n\033[1m── %s\033[0m\n' "$1"; }

if command -v godot >/dev/null 2>&1 && godot --version 2>/dev/null | grep -q "^${VERSAO}"; then
    msg "Godot ${VERSAO} já está no PATH"
else
    msg "Baixando Godot ${VERSAO}"
    mkdir -p "$DESTINO"
    curl -fsSL "$URL" -o "/tmp/${ZIP}.zip"
    unzip -oq "/tmp/${ZIP}.zip" -d "$DESTINO"
    chmod +x "${DESTINO}/${ZIP}"
    if [ -w /usr/local/bin ]; then
        ln -sf "${DESTINO}/${ZIP}" /usr/local/bin/godot
    else
        sudo ln -sf "${DESTINO}/${ZIP}" /usr/local/bin/godot
    fi
    rm -f "/tmp/${ZIP}.zip"
fi

# xvfb: os testes que RENDERIZAM precisam de tela. Sem ele, as capturas não saem
# e a medição de texto do TextServer devolve zero — a suíte passa mentindo.
if ! command -v xvfb-run >/dev/null 2>&1; then
    msg "Instalando xvfb"
    if command -v apt-get >/dev/null 2>&1; then
        (sudo apt-get update -qq && sudo apt-get install -y -qq xvfb) \
            || (apt-get update -qq && apt-get install -y -qq xvfb)
    else
        echo "AVISO: instale o xvfb pela sua distro — sem ele, nada de capturas."
    fi
fi

command -v python3 >/dev/null 2>&1 || { echo "ERRO: python3 é obrigatório."; exit 1; }

# uv: só o Godot AI precisa dele (o servidor MCP roda por uvx). Não é requisito
# para jogar nem para rodar a suíte, então falha aqui não derruba o setup.
if [ "${COM_GODOT_AI:-1}" = "1" ] && ! command -v uv >/dev/null 2>&1; then
    msg "Instalando uv (para o Godot AI)"
    curl -fsSL https://astral.sh/uv/install.sh | sh || \
        echo "AVISO: uv não instalou. O jogo e a suíte funcionam sem ele; só o Godot AI não."
fi

msg "Pronto"
godot --version
python3 --version
echo
echo "  cd cruzada && ./testar.sh        # a suíte inteira"
echo "  cd cruzada && godot --path . res://cenas/jogo.tscn   # jogar"
echo
echo "Godot AI (IA dentro do editor, opcional): ver a seção no CLAUDE.md."
