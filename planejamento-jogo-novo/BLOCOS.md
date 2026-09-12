# Os 13 blocos de decisão

> A régua do **começo**. O espelho da `AUDITORIA.md`, que é a régua do **fim**.
> A auditoria pergunta *"você fez isso bem?"*. Aqui a pergunta é *"você já decidiu isso?"*.

Versão 1 · 2026-09-12 · Leia antes: `PREFERENCIAS-DE-JOAB.md`

---

## Como uma decisão vive

Toda decisão do plano tem **um estado** e **uma origem**. As duas coisas aparecem sempre juntas.

### Estado

| | |
|---|---|
| 🔴 **ABERTA** | ninguém decidiu ainda |
| 🟡 **PROPOSTA** | tenho uma recomendação, falta o Joab bater o martelo |
| 🟢 **FECHADA** | decidida, **com o motivo escrito ao lado** |

Decisão 🟢 só reabre com motivo escrito. É o que impede o projeto de andar em círculo.

### Origem — de onde veio o valor

| | |
|---|---|
| 👤 | o Joab decidiu |
| 📏 | saiu de medição: simulador, teste, ou pesquisa com fonte |
| 🤖 | recomendação do agente que o Joab aceitou |
| 🟡 | **palpite do agente que ninguém confirmou** |

> **A regra que impede alucinação:** 🟡 em bloco que trava = **código bloqueado**.
> O agente não constrói em cima do próprio palpite.

---

## O mapa

| # | Bloco | Depende de | Trava | Fase |
|---|---|---|---|---|
| **B0** | Identidade — gênero, tema, plataforma, ambição, ritmo | — | tudo | 0 |
| **B1** | ⚠️ Espaço e movimento — câmera, dimensão, o que o corpo faz | B0 | B2 B3 B6 B7 B9 B10 | 1 |
| **B2** | Estrutura da partida — duração, vitória, derrota, o que vem depois | B1 | B4 B5 B7 B8 | 1 |
| **B3** | Ação central — a coisa que o jogador repete o tempo todo | B1 | B4 B7 B9 B10 | 1 |
| **B4** | Progressão na partida — escolhas, recursos, limites | B2 B3 | B5 B8 | 2 |
| **B5** | Meta-progressão — tem ou não tem; variedade ou poder | B4 | B8 B11 | 2 |
| **B6** | Conteúdo e espaço — mapas, fases, autoral × procedural | B1 | B7 B9 B12 | 2 |
| **B7** | Oposição — inimigos, obstáculos, diretor de dificuldade, chefes | B2 B3 B6 | B9 B12 | 2 |
| **B8** | Telas e fluxo — o grafo completo, não a lista | B2 B4 B5 | B9 B10 | 2 |
| **B9** | ⚠️ Arquitetura e dados — contrato, intenção, determinismo, orçamento | B1 B3 B6 B7 B8 | todo o código | 2 |
| **B10** | Apresentação — arte, som, juice, acessibilidade | B1 B3 B8 | B11 B12 | 3 |
| **B11** | Produto — marcos, Steam, preço, legal, pós-lançamento | B5 B10 | o lançamento | 4 |
| **B12** | ⚠️ Produção de assets por IA — a fábrica de peça 3D e som | B6 B7 B10 | toda a produção de conteúdo | 3 |

**O grafo ordena a entrevista sozinho.** Nada de rodada fixa: cada jogo recebe a sua própria
ordem, calculada a partir de quem depende de quem.

---

## As fases, e o que cada uma destranca

| Fase | Blocos | Destranca | Tempo alvo |
|---|---|---|---|
| **0 · Faísca** | B0 + **PM** (pesquisa de mercado) | conversar a sério | 40 min |
| **1 · Fundação** | B1 B2 B3 + identidade mínima | 🎲 a prova de diversão · 🎨 a prova de asset | 1–2 h |
| **2 · Corpo** | B4 B5 B6 B7 B8 B9 | **o jogo de verdade** | 3–5 h |
| **3 · Pele** | B10 B12 | a arte, o som e a fábrica de assets | 2–3 h |
| **4 · Produto** | B11 | o lançamento | 1 h |

Cada fase tem **teto de tempo**. Estourou, o que sobrou vira 🟡 com data e a fase fecha assim
mesmo — mas 🟡 em bloco que trava continua bloqueando código.

**Não é preciso chegar na fase 4 para começar a codar.** O portão reprova por fase.

---

## Fim da fase 1 — duas provas baratas

Antes de investir nas fases 2, 3 e 4, duas perguntas são respondidas com trabalho jogado fora
de propósito. As duas moram em `prototipo/`, que o portão sempre libera e que **nunca entra no
jogo final**.

### 🎲 Prova de diversão

Caixa cinza: retângulos que andam, a ação central, e o simulador medindo o critério que mata
o projeto. Sem arte, sem menu, sem som.

> **Segurar esse botão é uma decisão interessante?**

Se a resposta for não, o que muda é o **design** — e arte feita antes disso seria trabalho
jogado fora de verdade.

### 🎨 Prova de asset

**Um** modelo 3D e **um** som, gerados de ponta a ponta pelo caminho que o jogo inteiro vai
usar, e passando pelo portão de asset do B12.

> **A fábrica produz mesmo a peça que o `ARTE.md` promete?**

Descobrir que o caminho não entrega o estilo prometido custa uma hora agora, e custa quarenta
peças refeitas no mês 3.

---

## A identidade mínima — fechada na fase 1

`PREFERENCIAS-DE-JOAB.md` manda polir toda fatia na mesma passada. Para isso, a identidade
precisa existir **antes da primeira fatia**. Mas identidade completa é cara e a prova de
diversão ainda nem aconteceu.

A saída: dois níveis.

| | Quando | O que é |
|---|---|---|
| **Mínima** | fase 1 | 5 cores com função · 1 fonte · 3 sons (confirmar, cancelar, erro) · 1 regra de juice · 1 transição |
| **Completa** | fase 3 (B10 + B12) | todos os assets, música, VFX, animação, pós-processamento |

A mínima é **decisão, não asset**: custa uma hora, cabe numa página, e não se joga fora nem
se o design mudar inteiro.

---

## Como o portão usa este arquivo

O `portao-plano.py` lê o `docs/PLANO.md` do jogo e responde três coisas:

1. **Qual fase o plano alcançou** — a maior fase cujos blocos estão todos 🟢
2. **O que bloqueia código** — bloco 🔴 ou 🟡 que trava, com o nome da decisão que falta
3. **O que bloqueia lançamento** — o resto

Saída em bloco delimitado, igual ao portão frio:

```
===PLANO-VERIFY===
{ "fase_alcancada": 1, "status": "FALTA", ... }
===FIM-PLANO-VERIFY===
```

**O bloco é a única fonte de verdade.** Exit code não conta.

---

## O que cada bloco decide

### B0 · Identidade
Gênero · tema · dimensão (2D/3D) · plataforma alvo · modelo de negócio · ambição · ritmo de
trabalho · nome (disponível, buscável, registrável) · o que o jogo **não** tem, com o motivo de
cada recusa · e o critério que mata o projeto.

### PM · Pesquisa de mercado ⚠️ *etapa obrigatória da fase 0*

Roda entre a frase e o resto do B0, e alimenta tudo que vem depois. **Nada dela sai da cabeça:
toda afirmação tem fonte, e opinião vem marcada como opinião.** O trabalho é do agente — o Joab
não precisa saber nada do mercado.

O `PESQUISA.md` só fecha com estas nove seções:

| | |
|---|---|
| 1 | **Esse jogo já existe?** — Steam e web: nome, preço, nota |
| 2 | **Os números do gênero** — tamanho, vendas, preço, saturação, com fonte e data |
| 3 | **3 a 5 referências**, cada uma em três colunas: o que copiar · o que o público reclama (de análise negativa real) · o que a gente corrige |
| 4 | ⚠️ **As mecânicas que FUNCIONARAM** — onde funcionou e **por quê**. O "por quê" é o que se reaproveita |
| 5 | ⚠️ **As mecânicas que FRACASSARAM** — e o motivo. Viram quase de graça a lista "o que o jogo não tem" |
| 6 | **A crítica repetida do gênero** — os defeitos estruturais que ele carrega. Escolher **uma** para atacar de frente |
| 7 | **Preço, duração e conteúdo dos comparáveis** — daqui sai o nosso preço e o nosso volume mínimo |
| 8 | ⚠️ **O contraponto medido** — pesquisa de fora conferida contra o que já medimos aqui. Quando discordam, a nossa medição ganha e o contraponto fica escrito |
| 9 | **Onde isso deixa o nosso jogo** — a decisão que a pesquisa destravou. Pesquisa que não muda decisão nenhuma foi leitura, não pesquisa |

Regra fixa: **toda referência termina em "conclusão para o nosso jogo"**, nunca em resumo solto.

### B1 · Espaço e movimento ⚠️ *a decisão mais cara de mudar depois*
Câmera (fixa, isométrica, terceira pessoa, orbital) · perspectiva ou ortográfica · o jogador
pula? · tem esquiva? · arena fechada ou mapa aberto · o terreno afeta o movimento?

Determina level design, arte, orçamento de desempenho, esquema de controle e até o trailer.

### B2 · Estrutura da partida
Duração · condição de vitória · o que acontece ao morrer e em quanto tempo se recomeça · tem
pausa entre ondas? · o que se perde e o que se guarda.

### B3 · Ação central
A ação que se repete o tempo todo · mira automática ou manual · como o alvo é escolhido ·
existe habilidade ativa · como o resultado é comunicado sem poluir a tela.

### B4 · Progressão na partida
XP e nível · loja entre ondas · quantas opções por escolha · re-sorteio · banimento · limite
de itens equipados · evolução e fusão · baús e santuários.

### B5 · Meta-progressão
Tem ou não tem · destrava **variedade** ou concede **poder permanente** · quantos personagens ·
o quanto eles diferem de verdade.

### B6 · Conteúdo e espaço
Autoral, procedural ou híbrido · quantos mapas no lançamento · como o terreno participa da
mecânica · como o jogador se orienta · **quantas peças de conteúdo, em número** (é o que o B12
vai ter que produzir).

### B7 · Oposição
Quantos tipos e qual o **papel mecânico** de cada um · como a dificuldade escala · chefes ·
orçamento: quantos vivos ao mesmo tempo no pior caso.

### B8 · Telas e fluxo
A lista completa **e o grafo**: entradas, saídas, o que Esc faz, o que o botão B do controle
faz, qual estado sobra ao voltar · primeiro boot × jogador que volta depois de dias · nenhuma
tela sem saída · fluxo inteiro percorrível só com controle.

### B9 · Arquitetura e dados ⚠️
Fronteira regra pura × apresentação · **contrato de dados** (save, conteúdo, fase, inimigo,
item) · `schema_version` e migração · **camada de intenção** (teclado e teste escrevem nas
mesmas variáveis) · determinismo por semente · máquina de estados do jogo · onde mora o tempo
(o que pausa, o que não pausa) · barramento de eventos × chamada direta · número de ajuste ×
dado de conteúdo · orçamento de ms por sistema · co-op algum dia? mods algum dia?

### B10 · Apresentação

**Primeiro passo, obrigatório: as 5 linhas artísticas.** Antes de fechar qualquer cor, o agente
gera **pelo menos 5 direções distintas** e mostra as cinco lado a lado. Em jogo 3D elas nascem
**dentro do Godot**, renderizadas de verdade — mesma cena, mesmo enquadramento, mesma peça de
teste, para a comparação ser justa. Cada linha traz nome curto, o que promete e quanto custa
produzir. Nenhuma prestou? Gera mais cinco. Só depois da escolha a identidade fecha.

Depois da escolha: paleta em tabela papel → cor → hex → onde aparece, nenhuma cor com dois trabalhos · reserva de
cor com consequência dura · fonte e glifos · tema de UI decidido uma vez · geometria e estilo ·
pós-processamento · som que informa e o equivalente visual dele · música em camadas · buses ·
juice · acessibilidade (daltonismo provado por simulação, contraste, forma além de cor, redução
de movimento, modo assistido).

### B11 · Produto
Marcos com prova medida de fim · riscos · o que roda na nuvem × só no local · custo em horas
por feature · **lista de corte pré-declarada** · App ID da Steam (US$ 100, dias de espera) ·
assinatura de código · página da loja no ar cedo · preço · classificação etária · política de
privacidade · conquistas e estatísticas (definem o que o save conta) · telemetria · tutorial ·
playtest com gente · pós-lançamento.

### B12 · Produção de assets por IA ⚠️
O bloco que faz a fábrica existir. Decide:

- **A divisão**: o que o Blender gera por script · o que a IA gera · o que vem do acervo CC0 ·
  o que é feito por código (shader, procedural)
- **Contrato por família de peça**: escala, origem, contagem de polígonos, conjunto de
  materiais, UV, convenção de nome
- **Portão de asset**: reprova escala ≠ 1, material vazio, malha sem UV, peso fora do orçamento
  — **antes** de a peça entrar no jogo
- **Receita de consistência** ⚠️ — o risco nº 1 da arte gerada: cada peça sai boa sozinha e o
  conjunto parece colcha de retalhos. Mesma paleta, mesmo orçamento de polígono, mesmo conjunto
  de materiais, mesma luz de referência
- **Folha de contato em lote** — todas as peças lado a lado numa imagem, para auditar de olho
  em dez segundos
- **Contrato de som**: formato, taxa, volume, laço fechado, sem silêncio nas pontas
- **Portão de som**: reprova laço aberto, pico estourado, duração fora da faixa
- **Custo por peça em minutos** — para o escopo virar conta, não vontade
- **Origem e licença** de cada peça, rastreadas desde o nascimento

---

## Regra de escopo, válida em todo bloco

> Coisa nova só entra se **mudar uma decisão** que já existe.
> O que só aumenta um número é recusado, por mais barato que seja implementar.

É assim que a lista fica em 18 em vez de 800.
