#!/usr/bin/env bash
# Baixa as fontes do jogo. Elas NAO sao versionadas — ver fontes/FONTES.md.
#
# Roda antes de exportar. Sem elas o jogo abre igual, usando a fonte embutida do
# Godot: o que se perde e a identidade e, nos quatro idiomas de escrita CJK mais
# o tailandes, os caracteres viram quadradinhos.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p fontes

G="https://raw.githubusercontent.com/google/fonts/main"
N="https://raw.githubusercontent.com/notofonts/noto-cjk/main/Sans/OTF"

baixar() {
  local destino="fontes/$1" url="$2"
  if [ -s "$destino" ]; then echo "ja existe: $1"; return; fi
  echo "baixando: $1"
  if ! curl -fsSL --retry 4 --retry-delay 2 -o "$destino" "$url"; then
    rm -f "$destino"
    echo "  FALHOU. Baixe a mao e salve como $destino"
    echo "  origem: $url"
    return
  fi
  # Um 403 ou uma pagina de erro chega como arquivo pequeno de texto. Fonte de
  # verdade comeca com a assinatura do formato; conferir aqui evita descobrir o
  # problema so na hora de exportar.
  case "$(head -c 4 "$destino" | xxd -p)" in
    00010000|4f54544f|74727565|74746366) : ;;
    *) rm -f "$destino"; echo "  NAO E FONTE (provavel erro de rede). Baixe a mao." ;;
  esac
}

baixar "Orbitron.ttf"      "$G/ofl/orbitron/Orbitron%5Bwght%5D.ttf"
baixar "Exo2.ttf"          "$G/ofl/exo2/Exo2%5Bwght%5D.ttf"
baixar "Exo2-Italic.ttf"   "$G/ofl/exo2/Exo2-Italic%5Bwght%5D.ttf"
baixar "NotoSansThai.ttf"  "$G/ofl/notosansthai/NotoSansThai%5Bwdth,wght%5D.ttf"
baixar "NotoSansSC.otf"    "$N/SimplifiedChinese/NotoSansCJKsc-Regular.otf"
baixar "NotoSansTC.otf"    "$N/TraditionalChinese/NotoSansCJKtc-Regular.otf"
baixar "NotoSansJP.otf"    "$N/Japanese/NotoSansCJKjp-Regular.otf"
baixar "NotoSansKR.otf"    "$N/Korean/NotoSansCJKkr-Regular.otf"

echo
echo "--- o que ficou em fontes/ ---"
ls -la fontes/*.ttf fontes/*.otf 2>/dev/null || echo "(nenhuma — o jogo vai usar a fonte do motor)"
if command -v sha256sum >/dev/null && ls fontes/*.tt[fc] fontes/*.otf >/dev/null 2>&1; then
  sha256sum fontes/*.ttf fontes/*.otf 2>/dev/null > fontes/SHA256SUMS || true
  echo "SHA-256 gravado em fontes/SHA256SUMS"
fi
