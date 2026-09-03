2. **A PURGA é a única ação obrigatória** — 0,35 s a cada 20–40 s, janela perfeita em 92–99 %, automação deliberadamente 40 % pior. Resolve o dilema ativo-vs-idle sem bloquear ninguém, para sempre.

3. **O ÁLBUM DE ECOS registra a carta ao ser VISTA** — 256 bits, bônus permanente imune a todo prestígio. Mata o medo de descartar e transforma cada duplicata em micro-progresso. A melhor razão custo/benefício do documento inteiro.

4. **A RETOMADA** — 8 s de fast-forward a 20× reconstruindo o império com o fantasma da run anterior sendo ultrapassado ao vivo. O reset deixa de ser o anticlímax e vira o clímax.

5. **A CAIXA DA VIGÍLIA** — o loot offline chega **lacrado**, para ser aberto uma carta por vez. Devolve o momento de abrir que o progresso offline normalmente assassina.

6. **A SIMULAÇÃO FANTASMA É O SIMULADOR DE BALANCEAMENTO** — um caminho de código, três usos: progresso offline, preview de prestígio e `tools/sim_balance.mjs` no CI. E o relatório **nomeia a causa da falha**, virando briefing de engenharia.

7. **OS SOFTCAPS DE PERFORMANCE SÃO A ECONOMIA** — o teto de entidades vira Aglomeração (`ouro ×(1+A/100)^0,80`), o teto de cadência vira Modo Feixe. O jogador *persegue* o limite de renderização; 60 fps saem por design.

8. **A ADAPTAÇÃO DO ENXAME** — o mundo desenvolve resistência ao elemento que você mais usa. A build ótima muda sozinha; o jogador nunca chega ao "já resolvi, agora é só esperar". Cinco contra-jogadas, cada uma uma build inteira.

9. **OS AXIOMAS TROCAM REGRA, NÃO NÚMERO** — máximo 4 de 14 ativos. O prestígio muda **como** se joga, não quanto rende. É o que sustenta a hora 40 em diante sem produzir conteúdo novo.

10. **O PANTEÃO DESTRÓI DE VERDADE** — consagrar um conjunto completo apaga aquelas cartas para sempre por um multiplicador eterno. É o único sistema em que você perde algo de verdade, e por isso o único em que a decisão pesa.

11. **O PEREGRINO** — 40× de ouro se matar, lore e um requisito de final se poupar. O jogo nunca diz qual é a certa; só conta, para sempre, e usa a contagem em falas de chefe e no epílogo. A única fonte de culpa jogável do gênero.

12. **A ESTRATIGRAFIA** — cada Transcendência grava permanentemente uma faixa geológica no chão da arena, com glifos para chefes derrotados e Peregrinos poupados. Desenhada uma vez em offscreen, custo zero. **O reset não apaga: sedimenta.** E no Fim Verdadeiro, ela sobe pela tela como um pergaminho.

---

## APÊNDICE C — O que fazer segunda-feira de manhã

Ordem literal das primeiras 10 tarefas, para que a Fase 0 comece sem discussão:

1. Criar `index.html` com a pilha de 4 canvases, `#hud`, `#ui` e as regiões de anúncio para leitor de tela (§13.2).
2. Portar `scripts/core/big.gd` → `js/core/big.js` **na representação `{m,e}`** (§5.2), e escrever `tests/big.test.mjs` com os 10 testes de propriedade **antes** de qualquer outra coisa.
3. Portar `fmt.gd` → `js/core/fmt.js` com a tabela PT-BR de escala curta e o cache por `(m3, e)`.
4. Escrever `js/core/loop.js` com o passo fixo de `1/60`, o acumulador, o teto de 8 passos e o **contrato de determinismo** (§14.2) — este arquivo é a fundação de quatro sistemas e não pode ser refeito depois.
5. Escrever `js/core/storage.js` completo: 3 slots, FNV-1a, escrita atômica, migração versionada e o caminho de `QuotaExceededError` com fallback para IndexedDB (§14.4).
6. Converter `data/*.json` do protótipo para o esquema deste documento, criando os arquivos que faltam (`bosses.json`, `weather.json`, `codex.json`, `axioms.json`, `modules.json`, `juice.json`, `audio.json`) e adicionando o campo `raridade` às 26 relíquias existentes.
7. Escrever `js/data/balance.js` colando o Apêndice A **verbatim**, e ligar o lint que falha se qualquer literal numérico > 1 aparecer em `js/sim/`.
8. Escrever `tools/sim_balance.mjs` reusando `js/sim/fantasma.js` (mesmo que `fantasma.js` ainda seja um esqueleto) e ligar as travas T01–T05 no CI **hoje**, antes de existir um jogo — assim nenhum número entra sem passar.
9. Escrever `js/fx/barramento.js` + `js/fx/escalonador.js` (§12.1) **antes** de escrever o primeiro efeito. Se o juice nascer espalhado dentro do laço de colisão, ele morre na primeira otimização e não volta.
10. Construir o **atlas de glifos** (§12.4) e desenhar o primeiro número de dano com `drawImage`. Nunca chamar `fillText` para texto de combate, nem uma vez, nem "só para testar".

**Portão da semana 1:** um canvas que desenha uma torre procedural respirando no centro, um Grunhido que anda até ela, um tiro com muzzle flash e trilha, um impacto com squash e número por atlas, uma morte com fragmentos e anel de choque, uma moeda que voa em Bézier e faz `tin` em C6, e um save que sobrevive ao reload.

**Se isso for gostoso na semana 1, o jogo existe. Se não for, nada nas outras 27 semanas conserta.**

---

*Fim do GDD Mestre — Torre Eterna v1.0.*
*Este documento é a fonte única da verdade. Toda divergência entre ele e o código é um bug no código.*