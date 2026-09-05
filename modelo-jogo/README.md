# modelo-jogo — o esqueleto

Não mexa aqui para fazer um jogo. **Copie**:

```bash
.claude/scripts/novo-jogo.sh <slug> "Nome do Jogo"
```

Mexa aqui quando quiser que **todo jogo futuro** ganhe algo.

## O que já vem pronto

| | |
|---|---|
| Autoloads | `Progresso` (save), `Audio` (música + pool de 8 vozes), `Navegacao` (troca de tela com pilha) |
| Regras puras | `scripts/regras/pontuacao.gd`, `scripts/regras/save.gd` — `static func`, sem nó |
| Save | `schema_version` desde o dia 1, `migrar()` e `mesclar()` entre duas máquinas |
| Tradução | `traducoes/textos.csv` em pt/en/es, nenhuma string solta no código |
| Input | `acao_confirmar` e `acao_voltar`, teclado **e** gamepad |
| Telas | `menu.tscn` e `jogo.tscn` funcionando |
| Testes | micro-suíte `Mini`, 21 verificações, roda headless e no editor (F6 em `cenas/testes.tscn`) |
| Portão | `agent_verify.gd` |
| Balanceamento | Monte Carlo determinístico em `simulador/`, 3 políticas de habilidade, 24.000 partidas em 0,4 s |
| Export | `export_presets.cfg` pronto para Linux, Windows e Web |
| Publicação | `publicar.sh` sobe os três canais para o itch.io |
| Assets | `assets/CATALOGO.md` indexa tudo, para ninguém inventar caminho |

## Rodar

```bash
./testar.sh          # portão frio + testes, sai != 0 se algo falhar
./simular.sh         # balanceamento: 2000 partidas × 3 habilidades × 4 fases
./exportar.sh        # Linux, Windows e Web (roda o portão antes)
./publicar.sh        # sobe para o itch.io (ITCH_ALVO + BUTLER_API_KEY)
godot --path .       # abrir no editor (máquina local)
```

Antes do primeiro `./exportar.sh`: `bash ../../.claude/scripts/preparar-export.sh`
(1,2 GB de templates, baixa uma vez).

## Balancear

Os números vivem em `scripts/regras/balanceamento.gd`. Mude um, rode `./simular.sh`,
leia os alertas. Foi assim que a curva de dificuldade padrão saiu: com o passo de 450
por fase, nem o jogador bom fechava a fase 10 — o simulador acusou, o passo virou 55.

## Onde escrever o quê

A lógica que decide alguma coisa vai em `scripts/regras/`, como `static func` pura.
Tela só desenha e chama a regra. Se um comportamento não dá para testar sem abrir o jogo,
ele está no arquivo errado.
