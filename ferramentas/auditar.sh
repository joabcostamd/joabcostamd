#!/usr/bin/env bash
# Coleta de evidencia para a auditoria de AUDITORIA.md.
# Nao da nota: junta fato. A nota e do auditor, e cada nota precisa de um fato daqui.
# Uso: ferramentas/auditar.sh [caminho-do-projeto]
set -uo pipefail

P="${1:-.}"
[ -f "$P/project.godot" ] || { echo "ERRO: $P nao e um projeto Godot (falta project.godot)"; exit 1; }
P="$(cd "$P" && pwd)"
cd "$P"

pg() { sed -n "s|^$1=||p" project.godot | head -1 | tr -d '"'; }
n()  { local c; c=$(eval "$1" 2>/dev/null | wc -l); echo "${c:-0}"; }
EXCL=( -path ./.godot -o -path ./.git -o -path ./capturas -o -path ./docs -o -path ./.github )
fonte() { find . \( "${EXCL[@]}" \) -prune -o -name '*.gd' -print 2>/dev/null; }
conta() { fonte | xargs grep -hoE "$1" 2>/dev/null | wc -l; }
cenas() { find . \( "${EXCL[@]}" \) -prune -o -name '*.tscn' -print 2>/dev/null; }

echo "===AUDITORIA-COLETA==="
echo "projeto: $(pg 'config/name')"
echo "caminho: $P"
echo "data: $(date -u +%Y-%m-%dT%H:%MZ)"
echo

echo "## C/AX — projeto e decisoes estruturais"
echo "- engine_features: $(sed -n 's|^config/features=PackedStringArray(||p' project.godot | tr -d '")' | head -1)"
echo "- renderer: $(pg 'renderer/rendering_method')"
echo "- cena_principal: $(pg 'run/main_scene')"
MS=$(pg 'run/main_scene'); echo "- cena_principal_existe: $([ -f "${MS#res://}" ] && echo sim || echo NAO)"
echo "- viewport: $(pg 'window/size/viewport_width')x$(pg 'window/size/viewport_height') stretch=$(pg 'window/stretch/mode')"
echo "- autoloads: $(sed -n '/^\[autoload\]/,/^\[/p' project.godot | grep -c '^[A-Za-z]')"
sed -n '/^\[autoload\]/,/^\[/p' project.godot | grep '^[A-Za-z]' | sed 's/^/  - /'
echo "- gitattributes: $([ -f .gitattributes ] || [ -f ../.gitattributes ] && echo sim || echo NAO)"
echo "- lfs_ativo: $(grep -qs 'filter=lfs' .gitattributes ../.gitattributes && echo sim || echo nao)"
echo "- gitignore_vaza_uid: $(grep -qsE '^\s*\*?\.uid' .gitignore ../.gitignore && echo ERRO || echo ok)"
echo "- gitignore_vaza_import: $(grep -qsE '^\s*\*?\.import' .gitignore ../.gitignore && echo ERRO || echo ok)"
echo "- godot_ignorado: $(grep -qs '\.godot' .gitignore ../.gitignore && echo sim || echo NAO)"
echo

echo "## contagem"
echo "- cenas: $(cenas | wc -l)"
echo "- scripts: $(fonte | wc -l)"
echo "- linhas_gdscript: $(fonte | xargs cat 2>/dev/null | wc -l)"
echo "- recursos_tres: $(find . \( "${EXCL[@]}" \) -prune -o -name '*.tres' -print | wc -l)"
echo "- imagens: $(find . \( "${EXCL[@]}" \) -prune -o \( -name '*.png' -o -name '*.jpg' -o -name '*.svg' -o -name '*.webp' \) -print | wc -l)"
echo "- audio: $(find . \( "${EXCL[@]}" \) -prune -o \( -name '*.ogg' -o -name '*.wav' -o -name '*.mp3' \) -print | wc -l)"
echo "- modelos_3d: $(find . \( -name '*.glb' -o -name '*.gltf' -o -name '*.fbx' \) -not -path './.godot/*' | wc -l)"
echo "- fontes: $(find . \( -name '*.ttf' -o -name '*.otf' \) -not -path './.godot/*' | wc -l)"
echo "- maior_arquivo: $(find . -type f -not -path './.godot/*' -not -path './.git/*' -printf '%s %p\n' 2>/dev/null | sort -rn | head -1 | awk '{printf "%.1f MB  %s", $1/1048576, $2}')"
echo "- uid_faltando: $(fonte | while read -r f; do [ -f "$f.uid" ] || echo "$f"; done | wc -l)"
fonte | while read -r f; do [ -f "$f.uid" ] || echo "  ! sem .uid: $f"; done | head -10
ASSETS=$(find . \( "${EXCL[@]}" \) -prune -o \( -name '*.png' -o -name '*.ogg' -o -name '*.wav' -o -name '*.ttf' -o -name '*.glb' \) -print 2>/dev/null)
echo "- import_faltando: $(echo "$ASSETS" | while read -r f; do [ -n "$f" ] && [ ! -f "$f.import" ] && echo "$f"; done | wc -l)"
echo "$ASSETS" | while read -r f; do [ -n "$f" ] && [ ! -f "$f.import" ] && echo "  ! sem .import: $f"; done | head -8
echo

echo "## D/E — codigo"
echo "- func_sem_tipo_retorno: $(fonte | xargs grep -hE '^\s*(static )?func .*\)\s*:' 2>/dev/null | grep -vc '\->')"
echo "- print_de_depuracao: $(conta '(^|[^_a-z])print[s]?\(')"
echo "- todo_fixme: $(conta 'TODO|FIXME|HACK|XXX')"
echo "- get_node_relativo: $(conta '\.\./')"
echo "- arquivos_acima_400_linhas: $(fonte | xargs wc -l 2>/dev/null | awk '$1>400 && $2!="total"' | wc -l)"
fonte | xargs wc -l 2>/dev/null | awk '$1>400 && $2!="total" {print "  ! "$1" linhas: "$2}' | head -5
echo "- regras_puras: $([ -d scripts/regras ] && find scripts/regras -name '*.gd' | wc -l || echo 0)"
echo

echo "## M — input"
IN=$(sed -n '/^\[input\]/,/^\[[a-z]/p' project.godot | grep -c '^[a-z_]*=' )
echo "- acoes_input_map: $IN"
echo "- acoes_com_gamepad: $(sed -n '/^\[input\]/,/^\[[a-z]/p' project.godot | grep -c 'JoypadButton\|JoypadMotion')"
echo "- acoes_com_teclado: $(sed -n '/^\[input\]/,/^\[[a-z]/p' project.godot | grep -c 'InputEventKey')"
echo "- deadzone_configurada: $(grep -c 'deadzone' project.godot)"
echo "- remapeamento_no_codigo: $(fonte | xargs grep -lc 'InputMap\.' 2>/dev/null | wc -l) arquivo(s)"
echo

echo "## AE — traducao"
echo "- locales_no_projeto: $(sed -n 's|.*locale/translations=PackedStringArray(||p' project.godot | tr ',' '\n' | wc -l)"
CSV=$(find . -name '*.csv' -path '*raduc*' -o -name '*.csv' -path '*ocale*' 2>/dev/null | head -1)
if [ -n "$CSV" ]; then
  echo "- csv: $CSV"
  echo "- idiomas_no_csv: $(head -1 "$CSV" | awk -F',' '{print NF-1}')"
  echo "- chaves: $(( $(wc -l < "$CSV") - 1 ))"
  echo "- celulas_vazias: $(tail -n +2 "$CSV" | grep -c ',,\|,$')"
else
  echo "- csv: NAO ENCONTRADO"
fi
echo "- texto_fixo_em_cena: $(cenas | xargs grep -h '^text = "' 2>/dev/null | grep -vc '^text = "[A-Z_]*"')"
cenas | xargs grep -Hn '^text = "' 2>/dev/null | grep -v '"[A-Z_]*"' | head -8 | sed 's/^/  ! /'
echo

echo "## AF — save"
echo "- usa_user_path: $(fonte | xargs grep -lc 'user://' 2>/dev/null | wc -l) arquivo(s)"
echo "- schema_version: $(fonte | xargs grep -l 'schema_version\|versao_schema' 2>/dev/null | wc -l) arquivo(s)"
echo "- escrita_atomica: $(fonte | xargs grep -lc 'rename\|\.tmp' 2>/dev/null | wc -l) arquivo(s)"
echo "- backup_de_save: $(fonte | xargs grep -lc 'backup\|\.bak' 2>/dev/null | wc -l) arquivo(s)"
echo

echo "## Y — audio"
echo "- bus_layout: $(find . -name '*bus_layout*' -not -path './.godot/*' | head -1 || echo NAO)"
BL=$(find . -name '*bus_layout*' -not -path './.godot/*' | head -1)
[ -n "$BL" ] && echo "- buses: $(grep -c '^bus/' "$BL" 2>/dev/null || echo '?')"
echo "- set_bus_volume: $(fonte | xargs grep -lc 'set_bus_volume' 2>/dev/null | wc -l) arquivo(s)"
echo

echo "## AA/AC/AD — telas, opcoes e acessibilidade"
echo "- cenas encontradas:"
cenas | sed 's|^\./||' | sort | sed 's/^/  - /'
for t in menu pausa opcoes:config creditos derrota:gameover vitoria carregando:loading; do
  k="${t%%:*}"; a="${t##*:}"
  echo "- tela_$k: $(cenas | grep -icE "$k|$a") cena(s)"
done
for g in "resolucao:resolution|set_window|window_mode" "volume:set_bus_volume|volume_db|AudioServer" "idioma:set_locale|TranslationServer" "legenda:subtitle|closed_caption|mostrar_legenda|legenda_ativa" "escala_fonte:font_size|escala_texto|text_scale" "daltonismo:daltonismo|colorblind|color_blind" "tremor:shake|tremor" "vibracao:vibrat|rumble" "reduzir_movimento:reduzir_movimento|reduce_motion|motion_reduc" "remapear:action_erase_events|action_add_event"; do
  k="${g%%:*}"; pat="${g#*:}"
  echo "- opcao_$k: $( { fonte; cenas; } | xargs grep -lE "$pat" 2>/dev/null | wc -l) arquivo(s)"
done
echo

echo "## AI — testes e simulacao"
echo "- testar.sh: $([ -f testar.sh ] && echo sim || echo NAO)"
echo "- casos_de_teste: $([ -d testes ] && find testes -name '*.gd' | wc -l || echo 0)"
echo "- agent_verify: $([ -f agent_verify.gd ] && echo sim || echo NAO)"
echo "- simulador: $([ -d simulador ] && echo sim || echo NAO)"
echo "- simular.sh: $([ -f simular.sh ] && echo sim || echo NAO)"
echo

echo "## AK/AL/BB — build e loja"
echo "- export_presets: $([ -f export_presets.cfg ] && echo sim || echo NAO)"
[ -f export_presets.cfg ] && grep '^name=' export_presets.cfg | sed 's/^name=/  - preset: /'
echo "- exportar.sh: $([ -f exportar.sh ] && echo sim || echo NAO)"
echo "- publicar.sh: $([ -f publicar.sh ] && echo sim || echo NAO)"
echo "- icone: $(pg 'config/icon')"
echo "- versao_declarada: $(grep -c 'config/version' project.godot)"
echo "- steam: $(fonte | xargs grep -lc 'Steam' 2>/dev/null | wc -l) arquivo(s)"
echo

echo "## A/B/F — design e assets"
for d in CONCEITO.md DESIGN.md GDD.md README.md CHANGELOG.md LICENSE; do
  echo "- $d: $([ -f "$d" ] && echo "sim ($(wc -l < "$d") linhas)" || echo NAO)"
done
echo "- secao_o_que_nao_tem: $(grep -lis 'o que n.o tem\|fora de escopo' CONCEITO.md DESIGN.md 2>/dev/null | wc -l)"
echo "- catalogo_de_assets: $(find . -name 'CATALOGO.md' -not -path './.godot/*' | head -1 || echo NAO)"
echo "- licencas_de_asset: $(find . -iname 'LICEN*' -o -iname '*CREDIT*' -o -iname '*ATRIBUI*' 2>/dev/null | grep -v '\.godot' | wc -l) arquivo(s)"
echo
echo "===FIM-AUDITORIA-COLETA==="
