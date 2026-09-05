# Como trabalhar neste repositório

Este é o repositório central do Joab. Ele guarda o **perfil do GitHub** (`README.md`),
os **jogos** e a **infraestrutura que faz um jogo novo nascer pronto** — na nuvem ou na
máquina local.

**Comunicação:** português, linguagem simples, direto ao ponto. Construir > explicar.
Teste tem que ser rápido e automatizado. Travou em loop, para e reporta.

---

## 1. Começar um jogo novo (o caminho de 30 segundos)

```bash
.claude/scripts/novo-jogo.sh <slug> "Nome do Jogo"
```

Isso cria `jogos/<slug>/` a partir de `modelo-jogo/`, planta o portão frio, escreve o
`CONCEITO.md` em branco e **já valida** — o comando só termina em `TUDO VERDE`.

O que vem de graça: 3 autoloads (Progresso/Áudio/Navegação), save com `schema_version` e
mesclagem entre máquinas, tradução pt/en/es, input map com teclado e gamepad, duas telas,
suíte de testes e o portão. Nada de "depois eu arrumo".

**Antes de escrever GDScript, preencha o `CONCEITO.md`** — em especial a seção
"O que NÃO tem". É ela que impede o escopo de crescer sozinho.

---

## 2. O ambiente

| | |
|---|---|
| Engine | **Godot 4.7.2-stable**, binário headless |
| Onde | `~/.local/opt/godot/godot`, com link em `/usr/local/bin/godot` |
| Quem instala | `.claude/scripts/preparar-ambiente.sh`, chamado pelo hook `SessionStart` |
| Se sumir | `bash .claude/scripts/preparar-ambiente.sh` (idempotente, ~15 s) |

A sessão da nuvem é efêmera: o contêiner some depois de um tempo parado. Por isso o hook
reinstala sozinho a cada sessão, e **o que não foi commitado se perde**.

### Nuvem × máquina local — a diferença que mais causa erro

| | Nuvem (aqui) | Máquina local do Joab |
|---|---|---|
| Editor Godot | **não existe** | aberto |
| MCP `godot-ai` (287 tools) | **indisponível** | é o caminho principal |
| Como mexer em `.tscn`/`.tres` | escrever o texto e **provar pelo portão** | tools do MCP contra o editor |
| Screenshot / playtest visual | não dá | `godot-visual-check`, `godot-playtest-loop` |
| Como verificar | `./testar-tudo.sh` | portão + MCP + visual |

**Consequência prática:** na nuvem, toda skill que depende do MCP (`godot-mcp-tools`,
`godot-visual-check`, `godot-playtest-loop`, `godot-visuais`, `godot-particles`…) **não roda**.
O substituto é o portão frio + a suíte headless. Não finja que rodou. Diga que é local.

O que é seguro fazer na nuvem: regras puras, testes, save, tradução, balanceamento por
simulação, documentação, estrutura de projeto, CI, export headless.

---

## 3. Verificar — a única coisa que conta como prova

```bash
./testar-tudo.sh              # todos os projetos
./testar-tudo.sh picross      # só um
cd jogos/<slug> && ./testar.sh
```

O portão imprime um bloco delimitado. **Esse bloco é a única fonte de verdade** — o exit
code do Godot já saiu 0 com erro de parse:

```
===AGENT-VERIFY===
{ "status": "PASS", ... }
===FIM-AGENT-VERIFY===
```

O que ele pega: cena principal inexistente, autoload que não compila, script com erro de
parse (compilando do disco, não do cache), cena que não carrega, referência `res://`
quebrada **dentro de cena e dentro de código**, `.uid` faltando, tradução ausente.

Diagnóstico: `godot --headless --path . -s res://agent_verify.gd -- doctor`.

**Nunca diga "está pronto" sem o bloco `PASS` e o bloco `TESTES PASS` na tela.**

---

## 4. Regras que não se negociam

1. **Conceito antes de código.** Sem `CONCEITO.md`, nenhuma linha de GDScript.
2. **A lógica mora em `scripts/regras/`**, como `static func` pura — sem nó, sem sinal, sem
   estado global. É o que a suíte mede. Se não dá para testar, está no lugar errado.
3. **`.uid` e `.import` vão para o git.** Nunca no `.gitignore`. Sem eles a outra máquina
   abre o projeto quebrado.
4. **`.godot/` e `.verify/` nunca vão para o git.**
5. **`.gitattributes` antes do primeiro asset.** LFS depois que o binário entrou no
   histórico custa reescrever tudo. O modelo canônico é `ferramentas/gitattributes-godot`,
   com o bloco LFS comentado — descomente antes de trazer png/glb/ogg grande.
6. **Bug vira teste antes da correção.** O teste falha, aí você conserta.
7. **O kit `agent_verify.gd` é editado só em `ferramentas/`.** As cópias dentro dos projetos
   são plantadas por `testar-tudo.sh` — editar uma cópia faz as máquinas divergirem.

---

## 5. Estrutura

```
.
├── CLAUDE.md                    este arquivo
├── PORTFOLIO.md                 o que existe e em que estado
├── CONVENCAO.md                 nomes e vocabulário
├── README.md                    perfil público do GitHub (não é doc de projeto)
├── testar-tudo.sh               portão + suíte de todos os projetos
├── .claude/
│   ├── settings.json            hook de sessão e permissões
│   ├── hooks/session-start.sh   prepara o Godot ao abrir a sessão
│   └── scripts/
│       ├── preparar-ambiente.sh instala o Godot 4.7.2
│       └── novo-jogo.sh         cria um jogo já verde
├── ferramentas/
│   ├── agent_verify.gd          kit de verificação (cópia canônica)
│   ├── gitattributes-godot      .gitattributes canônico
│   └── mcp-godot.exemplo.json   config do MCP godot-ai (uso local)
├── modelo-jogo/                 o esqueleto que todo jogo novo copia
├── jogos/                       jogos criados pelo scaffold
├── picross/  kit-puzzle/  prototipo-godot/    jogos existentes
└── .github/workflows/godot.yml  CI: portão + suíte em todo push
```

Dentro de um jogo:

```
cenas/       .tscn
scripts/
  regras/    static func puras — a lógica testável
  autoload/  Progresso, Audio, Navegacao
  telas/     um script por tela
  ui/        componentes reaproveitáveis
testes/
  casos/     um .gd por área, estende Mini
  suite.gd   roda todos os casos
assets/      sprites, sons, modelos
traducoes/   textos.csv
```

---

## 6. Qual skill usar

O pedido decide. Roteador curto (as skills completas estão no escopo de usuário):

| O pedido fala de… | Skill |
|---|---|
| jogo novo, começar projeto | `novo-jogo`, `godot-project-scaffold` |
| ideia, mecânica, loop, pilares | `game-design-conceito` → `game-design-document` |
| "vamos implementar X", tarefa nova | `godot-spec-driven` |
| bug, "não funciona", travou | `systematic-debugging`, `godot-runtime-debug` |
| API do Godot que você não leu hoje | `godot-api-guard` **antes de escrever** |
| teste, suíte, cobertura | `godot-testing`, `test-driven-development` |
| "está difícil?", dano, preço, economia | `simular-partidas`, `godot-balance-sim` |
| física, colisão, CharacterBody | `godot-fisica` |
| HUD, menu, interface | `godot-ui-hud` |
| som, música, SFX | `godot-audio`, `godot-audio-procedural`, `musica-autoral` |
| sprite, atlas, pixel art | `importar-assets-2d`, `kenney-assets` |
| modelo 3D, .glb, esqueleto | `importar-assets-3d`, `blender-3d-art-director` |
| cenário 3D, level design | `nivel-3d`, `godot-3d` |
| juice, polimento, "sem graça" | `godot-game-feel` |
| tradução, idioma | `godot-localization` |
| save, checkpoint | `godot-save-system` |
| exportar, build, Steam, itch | `godot-export`, `godot-steam`, `publicar-itch` |
| aprendeu algo que custou tempo | `aprender` |

Skills que exigem o editor aberto **não funcionam na nuvem** (ver seção 2).

---

## 7. Git

- Trabalhe no branch que a tarefa indicar, nunca direto na `main`.
- Commit em português, no imperativo, dizendo **o que mudou para o jogador ou para quem
  desenvolve** — não o nome do arquivo.
- Antes de commitar: `./testar-tudo.sh` verde.
- `git commit --no-verify` é proibido.
