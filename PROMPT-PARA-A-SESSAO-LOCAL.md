# Prompt para abrir a sessão local do Kingspire

Copie **tudo o que está entre as linhas** abaixo e cole como primeira mensagem
numa sessão do Claude Code aberta na pasta onde você quer o jogo.

---

Você vai migrar um projeto de jogo que foi planejado inteiro numa sessão na nuvem.
Nada de código de jogo existe ainda — e isso é de propósito. O que existe é o **plano**,
e ele é bom: 16 decisões fechadas, cada uma com motivo escrito e dono.

## O que é o jogo

**Kingspire** — tower defense 3D entre dimensões, em Godot 4.7.2. Um castelo no meio do
mapa, várias frentes de ataque ao mesmo tempo, noites que só começam quando o jogador
decide. As mecânicas do **Thronefall** com as torres do **Kingdom Rush**.

## Passo 1 — trazer o conteúdo

Todo o material está no repositório `joabcostamd/joabcostamd`, no branch
`claude/game-planning-ecosystem-bdtvwk`, dentro da pasta `migracao-kingspire/`.

```bash
git clone --depth 1 -b claude/game-planning-ecosystem-bdtvwk \
  https://github.com/joabcostamd/joabcostamd.git /tmp/origem-kingspire

mkdir -p game-kingspire
cp -r /tmp/origem-kingspire/migracao-kingspire/. game-kingspire/
cd game-kingspire
```

## Passo 2 — criar o repositório e subir

O repositório `joabcostamd/game-kingspire` **ainda não existe** — a sessão da nuvem não
tinha permissão para criar. Crie **privado**, sem README, sem .gitignore, sem licença.

```bash
gh repo create joabcostamd/game-kingspire --private --description \
  "Kingspire — tower defense 3D entre dimensões. Um castelo, várias frentes, noites que você escolhe começar."

git init -b main
git add -A
git commit -m "Nascer o repositorio do Kingspire com o plano inteiro"
git remote add origin https://github.com/joabcostamd/game-kingspire.git
git push -u origin main
```

## Passo 3 — provar que veio inteiro

```bash
./testar.sh
```

Tem que sair assim, e **só isso conta como prova**:

```
TODOS OS TESTES PASSARAM (44/44)
  fase alcancada: -1
  decisoes: 16 fechadas · 0 propostas · 1 abertas
  PLANO SAO
  todas as combinacoes acima de 60% de aprovacao
TUDO VERDE
```

Se sair diferente disso, pare e diga o que saiu. Não conserte por cima.

## Passo 4 — ler antes de agir

Nesta ordem, e sem pular:

1. **`PREFERENCIAS-DE-JOAB.md`** — manda em como falar, trabalhar, testar e entregar.
   Vale em toda sessão, sem ninguém pedir. Em conflito, ele ganha de qualquer outro arquivo.
2. **`CLAUDE.md`** — como este repositório funciona, e as 9 regras que não se negociam.
3. **`docs/PLANO.md`** — as 16 decisões fechadas, com estado e origem.
4. **`docs/DECISOES.md`** — o histórico do que mudou de ideia, e por quê.

## O que já está decidido (não pergunte de novo)

| | |
|---|---|
| Modelo | mecânicas do Thronefall + torres do Kingdom Rush |
| Partida | 10 a 15 minutos |
| Personagem | **tem** herói jogável (o Thronefall tem — não repita esse erro) |
| Torres | 4 famílias × 3 caminhos de evolução |
| Compra | livre, sem sorteio de carta |
| Inimigos | 15 tipos, 5 manias — manias **só** com mutadores |
| Mapas | 15 à mão para a campanha, gerados para o modo sem fim |
| Castelo | 4 arranjos: meio, embaixo da tela, canto e escada |
| Noite | começa quando o jogador quiser; nas dificuldades altas esse tempo encolhe |
| Mapa | duas camadas: o layout é dado puro, o 3D é só apresentação |
| Nome | **KINGSPIRE**, escolhido pelo Joab depois de checar 38 nomes |

## Onde paramos, e o que vem agora

**A próxima tarefa é a arte, e ela ficou esperando esta máquina de propósito** — porque
aqui o editor do Godot abre e o MCP `godot-ai` funciona, e na nuvem não.

A tarefa é: **gerar 5 direções de arte distintas do mesmo mapa, renderizadas dentro do
Godot**, para o Joab escolher olhando em vez de imaginando. Se nenhuma prestar, gere mais
cinco. Isso não é opcional — está escrito em `PREFERENCIAS-DE-JOAB.md`, seção 6.

O esboço das 5, já pensado, para você partir dele e não do zero:

| | Direção | O que muda |
|---|---|---|
| 1 | **Dia limpo** | cores saturadas, céu claro, sombra dura preta — a referência Thronefall |
| 2 | **Fim de tarde** | sol baixo, tinta laranja, sombra longa e arroxeada |
| 3 | **Tinta e papel** | contorno escuro em cada bloco, cores chapadas, dessaturado |
| 4 | **Noite de vigília** | tudo escuro, só o caminho e o castelo brilhando |
| 5 | **Névoa fria** | dessaturado, profundidade por neblina, paleta fria |

Comece rodando `python3 prototipo/maquete3d.py arranjos` para ver o mapa que vai servir
de base — é o arranjo **escada**, com o castelo no alto da tela.

**Antes de escrever GDScript**, lembre que o `./testar.sh` ainda diz `pode escrever codigo
do jogo: ainda nao`. Falta fechar a **D-004 — a leitura do tema dimensional**, a última
decisão aberta da fundação. Pergunte ao Joab, com opções e recomendação, antes de gerar
arte que dependa do tema.

## Duas armadilhas medidas, para não repetir

1. **Nunca minimize a janela do Godot.** `editor_screenshot(source="game")` devolve
   `stale_frame: true` com a janela minimizada. Mande para a segunda tela ou para fora da
   área visível — nunca minimizada.
2. **Nunca escreva um método do Godot que você não leu nesta sessão.** Confira antes:
   `python3 planejamento/api.py --tem CharacterBody3D move_and_slide`. Sai com código 1
   quando não existe. API inventada é o erro número 1 de IA em Godot: o parser aceita, o
   portão passa, e quebra só em runtime.

---

Depois que o repositório subir e o `./testar.sh` sair verde, pode apagar a pasta
`migracao-kingspire/` do repositório `joabcostamd/joabcostamd` — ela só existe para
atravessar a ponte.
