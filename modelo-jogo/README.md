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

## Rodar

```bash
./testar.sh          # portão frio + testes, sai != 0 se algo falhar
godot --path .       # abrir no editor (máquina local)
```

## Onde escrever o quê

A lógica que decide alguma coisa vai em `scripts/regras/`, como `static func` pura.
Tela só desenha e chama a regra. Se um comportamento não dá para testar sem abrir o jogo,
ele está no arquivo errado.
