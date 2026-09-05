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

Dentro de qualquer jogo, quatro comandos dão conta do ciclo inteiro:

```bash
./testar.sh      portão frio + suíte           sempre, antes de dizer "pronto"
./simular.sh     balanceamento por Monte Carlo  qualquer pergunta de número
./exportar.sh    executável Linux/Windows/Web   precisa dos templates
./publicar.sh    sobe para o itch.io            precisa de BUTLER_API_KEY
```

---

## 2. O ambiente

| | |
|---|---|
| Engine | **Godot 4.7.2-stable**, binário headless |
| Onde | `~/.local/opt/godot/godot`, com link em `/usr/local/bin/godot` |
| Quem instala | `.claude/scripts/preparar-ambiente.sh`, chamado pelo hook `SessionStart` |
| Se sumir | `bash .claude/scripts/preparar-ambiente.sh` (idempotente, ~15 s) |
| Templates de export | `bash .claude/scripts/preparar-export.sh` — 1,2 GB, **sob demanda**, fora do hook |
| butler (itch.io) | `bash .claude/scripts/preparar-butler.sh` — **bloqueado na nuvem**, use o CI |

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

### O proxy de saída bloqueia dois domínios que importam

Medido nesta sessão: `github.com` passa, mas `kenney.nl` e `broth.itch.zone` levam 403
no CONNECT. Consequência e saída:

| Quero | Na nuvem | Saída |
|---|---|---|
| assets do Kenney | bloqueado | **Actions → Trazer assets** — o runner baixa e commita num branch; a nuvem lê por git |
| publicar no itch | bloqueado | **tag `<slug>-v<versão>`** dispara `publicar-itch.yml`, que instala o butler no runner |
| Godot e templates | passa | os scripts baixam direto |

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

## 3b. Número de jogo vem da simulação

Pergunta de balanceamento — "está difícil?", "quanto de dano?", "o preço está certo?" —
**não se responde por intuição**. O modelo já traz um Monte Carlo determinístico que roda
as **mesmas funções puras** que a tela chama (nunca uma segunda implementação):

```bash
cd jogos/<slug>
./simular.sh              2000 partidas nas fases 1, 3, 5 e 10 (< 1 s)
./simular.sh 500 1 2 3    500 partidas nas fases 1, 2 e 3
```

Três políticas de habilidade — ruim, médio, bom. O balanceamento tem que fechar para as
três: se só o bom passa, está duro; se até o ruim gabarita, está fácil. O simulador
imprime a tabela e **os alertas**, e a mesma semente dá sempre o mesmo resultado.

Os números moram em `scripts/regras/balanceamento.gd`. Mexeu lá, roda `./simular.sh` e
lê os alertas — esse é o ciclo inteiro.

---

## 3c. Assets: consulte o catálogo, nunca invente o nome

`assets/CATALOGO.md` indexa todo sprite, som, modelo e fonte do projeto, com o caminho
`res://` exato. É gerado por `ferramentas/catalogo_assets.py` e regerado a cada
importação de pacote.

**Ache o nome no catálogo antes de escrever o caminho.** Nome inventado não produz erro
nenhum: o jogo abre, o portão passa, e a textura só não aparece.

Trazer um pacote (Kenney ou qualquer CC0):

```bash
.claude/scripts/baixar-assets.sh pixel-platformer jogos/meu/assets/kenney --pixel
```

Na nuvem esse comando falha por bloqueio de rede — use **Actions → Trazer assets**.
Lista de pacotes em `ferramentas/kenney-packs.md`.

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
7. **Número de balanceamento sai de `./simular.sh`**, não de palpite. Se mudou um número
   em `balanceamento.gd` e não rodou o simulador, você não sabe o que fez.
8. **Caminho de asset sai de `assets/CATALOGO.md`**, não de memória.
9. **O kit `agent_verify.gd` é editado só em `ferramentas/`.** As cópias dentro dos projetos
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
│       ├── preparar-export.sh   templates de export (1,2 GB, sob demanda)
│       ├── preparar-butler.sh   cliente do itch.io
│       ├── baixar-assets.sh     traz pacote CC0 e catalogo
│       └── novo-jogo.sh         cria um jogo já verde
├── ferramentas/
│   ├── agent_verify.gd          kit de verificação (cópia canônica)
│   ├── gitattributes-godot      .gitattributes canônico
│   ├── catalogo_assets.py       gera assets/CATALOGO.md
│   ├── kenney-packs.md          quais pacotes trazer e como
│   └── mcp-godot.exemplo.json   config do MCP godot-ai (uso local)
├── modelo-jogo/                 o esqueleto que todo jogo novo copia
├── jogos/                       jogos criados pelo scaffold
├── picross/  kit-puzzle/  prototipo-godot/    jogos existentes
└── .github/workflows/
    ├── godot.yml                CI: portão + suíte em todo push; export na main
    ├── assets.yml               traz assets do Kenney (a mão) e commita
    └── publicar-itch.yml        exporta e publica na tag <slug>-v<versão>
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
simulador/   Monte Carlo determinístico sobre as regras
assets/      sprites, sons, modelos + CATALOGO.md (gerado)
traducoes/   textos.csv
export_presets.cfg   Linux, Windows e Web
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
| exportar, build, executável | `godot-export` → `./exportar.sh` |
| publicar, itch, lançar demo | `publicar-itch` → `./publicar.sh` ou a tag |
| Steam, conquista, ranking | `godot-steam` |
| aprendeu algo que custou tempo | `aprender` |

Skills que exigem o editor aberto **não funcionam na nuvem** (ver seção 2).

---

## 7. Git

- Trabalhe no branch que a tarefa indicar, nunca direto na `main`.
- Commit em português, no imperativo, dizendo **o que mudou para o jogador ou para quem
  desenvolve** — não o nome do arquivo.
- Antes de commitar: `./testar-tudo.sh` verde.
- `git commit --no-verify` é proibido.
