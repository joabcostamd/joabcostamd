# Prompt de transferência para a máquina local

Cole o bloco abaixo numa sessão nova do Claude Code, na sua máquina.
Gerado em 2026-09-05, a partir da branch `claude/game-dev-with-claude-cl67dj`.

---

## PROMPT

Vamos começar um jogo novo: **Esculpir**, um Picross 3D. A pesquisa, as maquetes
e as decisões já estão prontas na nuvem — sua primeira tarefa é trazer tudo para
cá e continuar de onde paramos.

### 1. Traga o material (faça isto primeiro, antes de qualquer decisão)

```bash
cd <onde você guarda o joabcostamd>
git fetch origin claude/game-dev-with-claude-cl67dj
git checkout claude/game-dev-with-claude-cl67dj
```

Leia, nesta ordem, e não pule nenhum:

| Arquivo | Por quê |
|---|---|
| `CLAUDE.md` | as regras do repositório, que continuam valendo |
| `estudos/picross3d/PESQUISA.md` | **o documento mais importante** — regras exatas do gênero, críticas dos concorrentes, e o pipeline do gerador |
| `estudos/picross3d/README.md` | como as maquetes foram feitas e as duas armadilhas medidas |
| `estudos/picross3d/voxel.py` | renderizador isométrico, com a matemática de projeção que já funciona |
| `estudos/picross3d/cenas.py` | cálculo das pistas nos três eixos, e a colocação correta delas |
| `estudos/picross3d/figura.py` | a figura de teste (cogumelo) e por que o gato foi descartado |

Olhe as três maquetes em `estudos/picross3d/saida/`. É a cara aprovada do jogo.

### 2. O jogo, decidido

**Esculpir** — irmão 3D do `picross/` (Revelar) que já existe neste repositório.

Um bloco de cubos esconde uma figura. O jogador quebra os cubos que não fazem
parte dela, deduzindo por números, até a figura aparecer.

**A regra, exata:** cada número na ponta de uma fileira diz quantos cubos daquela
fileira fazem parte da figura.

| Marca | Significa |
|---|---|
| `7` | os cubos estão todos **juntos** |
| `④` círculo | estão em **dois** grupos separados |
| `⑤` quadrado | estão em **três ou mais** grupos |

**Duas ações, e só:** quebrar (destrói; se era da figura, é erro) e marcar
(pinta de azul: "esse fica"). Marcar nunca pune.

**Decidido que NÃO entra na primeira versão:**
- as duas cores do Round 2 (azul reto / laranja curvo) — dobram a carga de regra
- multijogador, mundo aberto, árvore de habilidades
- qualquer figura que precise de chute para ser resolvida

### 3. Os ambientes — o diferencial

O primeiro Picross 3D guardava as figuras em dioramas temáticos. O Round 2 tirou
isso e as resenhas cobraram a falta. O Voxelgram nunca teve. **É a brecha.**

Como o nosso funciona:

1. O ambiente nasce **vazio e visível**, com silhuetas fantasmas nos lugares das
   peças que faltam. O jogador sempre sabe o que falta e onde vai.
2. Cada figura tem **posição fixa** no seu ambiente. Terminar não é ganhar item
   na lista, é ver a cena receber aquilo.
3. O ambiente ganha vida **em camadas**: o porto ganha o barco, depois a gaivota,
   depois a neblina, depois o farol acende. Recompensa contínua, não binária.
4. A última peça é **grande**: três ou quatro puzzles montam uma peça gigante.
5. **O pó não some**: cubo quebrado vira material, que compra dica ou decoração.

Ambientes na ordem: doca, estufa, cozinha, observatório, oficina, jardim de
inverno.

### 4. A ordem de trabalho — não inverta

O erro caro seria abrir o Godot primeiro. A pergunta "esse jogo existe?" se
responde **antes** da engine, em Python puro:

**Fatia 1 — solucionador 3D de linha.** Propagação de restrição linha a linha,
nos três eixos, que **nunca chuta**. Decidir se um nonograma tem solução única é
NP-difícil, mas essa não é a pergunta certa: a pergunta é se um humano resolve
por dedução pura. Se este solucionador resolve, o jogador resolve. Se ele empaca,
a fase exigiria chute e está quebrada. O solucionador 2D em
`picross/ferramentas/solucionador.py` é o ponto de partida, com um eixo a mais.

**Fatia 2 — o solucionador mede a dificuldade.** Enquanto roda, ele conta:
passadas de propagação, a dedução mais difícil que precisou usar, voxels
resolvidos por passada, e onde travou. Ordenar as fases por isso **é** a curva de
dificuldade. Número de jogo vem de medição, nunca de intuição (regra 4).

**Fatia 3 — gerador paramétrico de figuras.** Cada figura é uma função com 3 a 6
parâmetros (cogumelo, xícara, cacto, chave, peixe). Portão de legibilidade,
medido e pesquisado:

- a **silhueta** decide: não reconheceu pelo contorno, simplifique
- nada com menos de 1 cubo de espessura; 2 é seguro
- **3 a 4 cores** por figura, no máximo
- um objeto só, com **uma** característica definidora

Medição nossa que confirmou a regra: o gato falhou porque corpo e cabeça tinham
larguras parecidas e fundiram num blob. O cogumelo funcionou porque chapéu largo
sobre pé fino **é** a silhueta.

**Fatia 4 — a medição que decide tudo.** Gere 200 figuras, rode o solucionador em
cada uma, e responda: quantas passam sem chute? Como a dificuldade se distribui?
Dá para preencher uma curva de 5×5×5 até 12×12×12?

**Só depois disso o Godot entra.**

### 5. Cuidados de 3D — leia antes de abrir o editor

Este projeto tem armadilhas que o 2D não tem. Nenhuma delas dá erro: o jogo roda
e vai mal.

**Um MeshInstance3D por cubo mata o FPS.** 729 cubos são 729 draw calls. Use
`MultiMeshInstance3D` com transformação por instância e cor em custom data.
Quebrar um cubo é remover a instância e reescrever o buffer, não apagar um nó.
Meça com o profiler antes de acreditar que está rápido.

**Com MultiMesh não existe colisor por instância**, então raycast de física não
acha o cubo que o dedo tocou. Use travessia de voxel por matemática (DDA /
Amanatides-Woo) a partir do raio da câmera. É mais rápido e mais exato que
espalhar 729 colisores.

**Os números são o gargalo escondido.** 729 cubos × 3 faces seriam 2187 rótulos.
A regra já corta isso: **só o cubo mais externo de cada fileira mostra a pista**,
o que dá no máximo 3 × 81 = 243. Ainda assim, `Label3D` é caro — use quads num
MultiMesh com atlas de dígitos e deslocamento de UV por instância.

**Escala e origem, decididas agora e nunca mais:** 1 voxel = 1 unidade, origem no
canto da grade, centro do cubo em `(x + 0.5, y + 0.5, z + 0.5)`. Mudar isso
depois quebra câmera, picking e save de uma vez.

**Câmera livre desorienta.** Girando à vontade, o jogador perde qual face está
lendo — o Picross 3D do DS sofria disso. Use giro com encaixe de 90° e transição
suave, mais um indicador de eixo permanente na tela.

**A crítica nº 1 do gênero é mira imprecisa com punição dura.** Em 3D o cubo que
você quer está atrás de outro. Nossa correção: gestos distintos (arrastar quebra,
tocar marca) e **desfazer que custa estrela, não vida**. Erro vira preço, não
castigo.

**Determinismo:** toda figura vem de semente explícita. `RandomNumberGenerator`
com `seed` setada, nunca `randi()` global. Mesma semente, mesma figura, sempre —
e isso vira teste.

**O que o headless NÃO mede em 3D.** Godot headless não renderiza. Provável sem
tela: solucionador, gerador, dificuldade, save, regra, todas as fases vencíveis.
Só na sua máquina com o MCP: material, luz, câmera, escala aparente, game feel.
Nunca afirme nada visual sem screenshot.

### 6. Como nascer certo

Use a skill **`novo-jogo`** e siga a ordem dela — vários passos são
irreversíveis depois do primeiro commit (LFS antes do primeiro asset,
`.gitattributes`, `.uid` e `.import` fora do `.gitignore`, `locales/` desde o
começo). Nome do repositório: `game-esculpir`.

Antes disso, escreva o `CONCEITO.md` com a seção "o que NÃO tem" — a lista da
seção 2 acima já é o começo dela.

Copie `estudos/picross3d/` inteiro para o projeto novo, em `ferramentas/`: o
renderizador isométrico serve para gerar folha de contato das figuras sem abrir
o editor, e os testes já existem.

### 7. As skills, por tarefa

| Tarefa | Skill |
|---|---|
| nascer o projeto | `novo-jogo` |
| começar qualquer fatia | `godot-spec-driven` |
| **antes de escrever API que você não leu** | `godot-api-guard` |
| cena 3D, luz, câmera | `godot-3d`, `godot-camera` |
| provar que funciona rodando | `godot-playtest-loop` |
| olhar se ficou bom | `godot-visual-check` |
| dificuldade e balanceamento | `simular-partidas` |
| suíte de testes | `godot-testing` |
| save com schema_version | `godot-save-system` |
| tradução desde o começo | `godot-localization` |

### 8. As regras que não mudam

1. **Nunca invente API do Godot.** É o erro nº 1 de IA nesta engine e ele não
   avisa. Confirme antes com `godot-api-guard` ou com `scripts/api.py`.
2. **Prova antes de afirmar.** "Deve funcionar" não é resultado.
3. **Bug vira teste antes da correção.** Escreve o teste, vê falhar, conserta.
4. **Número de jogo vem de medição**, nunca de intuição.
5. **Travou em loop? Pare e reporte.** Duas tentativas na mesma parede já basta.
6. Código, arquivos, commits e testes **em português**. Resposta curta.

### 9. Comece por aqui

Leia o `PESQUISA.md`, confirme comigo o nome **Esculpir** e o tamanho da primeira
grade, escreva o `CONCEITO.md`, e então ataque a **Fatia 1** (o solucionador).
Não abra o Godot antes da Fatia 4 estar medida.

---

## O que já está pronto e testado na nuvem

| Item | Onde | Estado |
|---|---|---|
| Pesquisa do gênero, com fontes | `estudos/picross3d/PESQUISA.md` | completa |
| Renderizador isométrico de voxel | `estudos/picross3d/voxel.py` | funciona |
| Cálculo de pistas nos 3 eixos | `estudos/picross3d/cenas.py` | 7/7 testes |
| Três maquetes de tela | `estudos/picross3d/saida/` | aprovadas |
| Godot 4.7.2 automático na nuvem | `.claude/hooks/session-start.sh` | 3 s |
| Portão anti-API-inventada | `scripts/api.py` | 1036 classes |
| Suíte de todos os jogos | `scripts/testar-tudo.sh` | 133 verificações |

Commits: `13de160` até `e735d47`, na branch `claude/game-dev-with-claude-cl67dj`
(PR #3).
