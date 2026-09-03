# Pendências — Torre Eterna

Lista consolidada do que falta, com a prova de cada item. Vem de três fontes,
todas rodadas sobre o código de verdade:

- **Painel de juízes** (6 lentes + 6 céticos adversariais, snapshot congelado) — nota **51/100**
- **Painel anterior** (mesma estrutura, commit anterior) — nota **55,9/100**
- **Auditoria de experiência** (5 lentes: juice, QoL, engajamento, áudio, primeiros 10 min) — **61 achados**

Nada aqui é opinião solta: cada item tem arquivo:linha ou saída de comando.
Itens sem prova foram descartados pelos próprios céticos e não entraram.

> **Regra desta lista:** um item só sai daqui quando existe um teste que
> reprova se ele voltar. Corrigir sem trancar foi exatamente como a Adaptação
> do Enxame ficou morta por meses com a suíte verde.

---

## 1. Portões que não medem o que dizem medir — ✅ FECHADO

Era o diagnóstico central do painel. Todos os sete itens foram resolvidos, e
cada um tem prova de que o portão **morde** (o defeito foi reintroduzido e a
suíte reprovou):

| # | O que era | Como ficou |
|---|---|---|
| 1.1 | Critério 6 provava _string_: um auditor cortou dois elos, pôs o nome num comentário, e a suíte fechou verde | Prova em código sem comentários **+ exige chamador**. Função declarada e nunca chamada deixou de contar como elo |
| 1.2 | Passiva contava se o nome aparecesse em qualquer lugar — até num rótulo de UI | Exige leitura real (`pas.has/get/[]` ou `_tem_passiva`) |
| 1.3 | Piso global de 250 contra 371 reais: 121 de folga, mais que qualquer grupo | Piso **por grupo**, derivado da contagem medida. Perder um bloco reprova nomeando o bloco |
| 1.4 | Quatro pontos escreviam `Engine.time_scale`: a câmera lenta terminando **matava a Retomada** | Três fatores, um dono. Teste prova que a briga acabou e que ninguém mais escreve no relógio |
| 1.5 | `soak` sem semente — o único portão longo com veredito era loteria | Semente fixa; duas execuções dão saída idêntica |
| 1.6 | `verificar.gd` escrevia FAIL e saía 0 quando faltava dado | Veredito e código de saída concordam, cobrado por teste em todas as ferramentas |
| 1.7 | Critério 12 prometia "separação percebida medida" sem instrumento nenhum | Instrumento em CIELAB (ΔE 76). **Desmentiu o comentário do shader**: a média piora nos três modos; o filtro troca média por pior caso, e é o pior caso que importa |

## 2. Promessas que o jogo faz e não cumpre

| # | Pendência | Prova |
|---|---|---|
| 2.1 | **`autoPurga` custa 120 fragmentos e não tem interruptor.** `p["auto"]` nasce `false` e nenhum ponto da árvore escreve nele. É a compra mais cara do começo da árvore entregando nada. | `scripts/sim/mecanicas.gd`, `data/prestige.json` |
| 2.2 | **`sinergia` é decorativa em 12 das 30 cartas** — só existe como rótulo colorido na UI, zero efeito na simulação. | `scripts/ui/panel_cartas.gd` |
| 2.3 | **`semMorrer` não tem leitor.** Duas missões anunciam a regra ao jogador e pagam 8 pontos de talento de graça. | `data/missions.json` |
| 2.4 | **Os 2 super-chefes são o mesmo chefe com duas peles** — `mecanica`, `fases` e `invoca` idênticos, um único braço no código. A dica de um deles cita mecânica que a luta não tem. | `data/enemies.json`, `scripts/sim/game.gd` |
| 2.5 | **`cuspir` e `ondaMax` declarados e não implementados.** | `data/enemies.json` |
| 2.6 | **`salvamento_travado`**: trava de mão única, sem ouvinte e sem destravar. | `scripts/core/save_system.gd` |
| 2.7 | **O Peregrino não é escolha.** Poupar rende nada, não há cessar-fogo nem filtro de mira que o exclua — a decisão que o README vende não existe. | `scripts/sim/arena.gd` |
| 2.8 | **Adaptação não afeta Gelo e Vazio**, mas o HUD mostra −62% para os cinco elementos. | `scripts/sim/combat.gd` |

## 3. Economia e ritmo (o mais caro de consertar, e o que mais decide)

| # | Pendência | Prova |
|---|---|---|
| 3.1 | **O ritmo é ditado pelo spawner, não pelo poder.** Passada a onda ~50, comprar dano não encurta nada dentro de uma run: medido a ~490 ondas/hora, quase uma reta, com 21 ordens de grandeza de dano sobrando. | `tools/duracao.gd` (medição), `scripts/sim/waves.gd` |
| 3.2 | **O catálogo de melhorias esvazia** (as 33 com teto ficam no máximo). O portão mede a onda FINAL em vez de QUANDO esvaziou, então não pega. | `tools/suites/sim_balance.gd` |
| 3.3 | **Camadas 2 e 3 fora de alcance prático.** Medido com prestígio ligado: nível 500 (máximo) em **5 h**, conquistas travam em **58/85**, e a Singularidade (8 ascensões) **não chegou em 7 h** — o jogador tinha 5 e desacelerando. A Transcendência pede 5 singularidades. | `tools/duracao.gd` |
| 3.4 | **39 melhorias uniformes** — quase todas "+X%", sem decisão de build. | `data/upgrades.json` |
| 3.5 | **Nada mata a torre hoje**, e morrer limpa a tela de graça: não há estado de derrota real. | `scripts/sim/game.gd` |
| 3.6 | **A Retomada é corrida impossível de ganhar**: 10 s reais × 6 = 60 s de jogo, contra 16–18 s por onda. Termina por relógio, não por progresso. | `scripts/sim/mecanicas.gd` |

## 4. Experiência do jogador (juice, QoL, engajamento)

| # | Pendência | Prova |
|---|---|---|
| 4.1 | **Painel de Melhorias** (o mais aberto do jogo): sem aba "Tudo" (7 cliques para achar o que dá para comprar), esquece a aba a cada abertura, ×10/×25 travam em vez de degradar, e o botão diz o custo e **nunca o ganho**. | `scripts/ui/panel_upgrades.gd` |
| 4.2 | **O HUD só acende dois botões** (talentos e melhorias). Missão pronta, nível de temporada, carta nova e prestígio disponível são invisíveis — e coletar missão é a **única** porta de XP da temporada. | `scripts/ui/hud.gd` |
| 4.3 | **Rodapé com 12 glifos idênticos e sem rótulo no segundo 0**, cinco deles vazios na onda 1. O jogo já sabe fazer certo (Farm e Infinito só aparecem quando existem) e não aplica aos doze. | `scripts/ui/hud.gd` |
| 4.4 | **Idioma fixo em `pt`** — não existe um `OS.get_locale` no repositório, com 1.027 chaves em inglês prontas. | `scripts/core/config.gd` |
| 4.5 | **Ascender pesa menos na tela que uma Purga**, e o banner mostra o identificador cru. | `scripts/sim/game.gd` |
| 4.6 | **As 10 Eras nunca dizem o nome.** `Bus.era_mudou` tem um único ouvinte: o pintor de fundo. Cada era traz `regra.texto` escrito e revisado, nunca mostrado. | `scripts/sim/waves.gd` |
| 4.7 | **Álbum de Ecos sem placar.** A palavra "album" não aparece uma vez em `scripts/ui/`. Paga bônus permanente e o jogador não vê. | `scripts/ui/` |
| 4.8 | **Fim de sessão braçal**: falta "Coletar tudo (N)" e "Reciclar duplicadas (N)" — os dois critérios já existem prontos no código. | `scripts/ui/panel_missoes.gd`, `scripts/sim/loot.gd` |
| 4.9 | **Navegação por teclado inexistente**: 296 controles interativos, 11 focáveis, nenhum `Button`. | `scripts/ui/ui_kit.gd` |
| 4.10 | **Contraste WCAG cobre 3 de ~18 cores de texto**, e há reprovação viva não detectada. | `tools/suites/testes.gd` |

## 5. Áudio

| # | Pendência | Prova |
|---|---|---|
| 5.1 | **Purga perfeita e Purga estourada fazem o mesmo som** — a qualidade (0,18 a 1,0) é calculada e descartada. | `scripts/sim/mecanicas.gd` |
| 5.2 | **Escada do combo é microtonal** e briga com a trilha (linear na razão, não em semitons). | `scripts/audio/audio_engine.gd` |
| 5.3 | **`_rng` da música é ressemeado a cada passo** — a variação que deveria existir não acontece. | `scripts/audio/music.gd` |
| 5.4 | **Nove efeitos são o mesmo patch de triângulo transposto** (compra, nível, carta, missão, conquista…). Diferenciar por excitação, não por transposição. | `scripts/audio/sfx.gd` |
| 5.5 | **"Eu machuquei" e "eu apanhei" são a mesma receita** transposta. | `scripts/audio/sfx.gd` |
| 5.6 | **Um WAV por nome**: impacto/tiro/morte viram britadeira. Faltam variantes de ruído em rodízio. | `scripts/audio/audio_engine.gd` |
| 5.7 | **A trilha não sabe da Purga** nem distingue 5% de vida de 100%. | `scripts/audio/music.gd` |
| 5.8 | **Sinos que não são sinos**: `ouro` e `moeda` usam razões FM inteiras (timbre de órgão, não de metal). | `scripts/audio/sfx.gd` |

## 6. Documentação que não bate com o código

| # | Pendência | Prova |
|---|---|---|
| 6.1 | **`QUALIDADE.md` publica saída "colada de execução — nunca de memória" que foi editada à mão.** Pelo menos quatro blocos: `validar_dados` sem os 4 avisos, `perf` sem a perna de folga, `sim_balance` sem a tabela, e uma linha (`STATUS: PASS (kit 1.5.2, 0 falhas)`) que **nenhum caminho de código emite**. Num documento cuja tese é honestidade. | `docs/QUALIDADE.md`, `agent_verify.gd` |
| 6.2 | **Badge do README anuncia 195 testes**; o portão mede 370. É a primeira tela do documento. | `README.md` |
| 6.3 | **"Contagem honesta" erra a própria soma**: 61/11/28, não 59/11/30. | `docs/QUALIDADE.md` |
| 6.4 | **`docs/PLANO.md` está fora do portão de doc** e apodreceu em quatro números. | `docs/PLANO.md` |

---

## Já resolvido nesta rodada

Para não repetir trabalho — cada um com teste que reprova se voltar:

- **Adaptação do Enxame nunca funcionou em partida nenhuma** (`has` vs `is_empty`); o teste passava porque escrevia o estado à mão antes de medir
- **Panteão e Modo Farm sem porta no jogo** — e `t_alcancavel` agora cobra chamador para todo sistema
- **3 de 9 modificadores de elite eram só cor**, com descrições prometendo mecânica exata
- **Save só recusava número quebrado por acidente do motor 4.4** — no 4.7 viraria perda silenciosa de progresso
- **Juice inteiro andava em tempo de jogo** (chefe congelava 3,2 s; turbo apagava o feedback)
- **`overkill`, morte de chefe, virada de fase, combo perdido e outros eventos eram mudos** — `t_nada_mudo` impede que voltem a ser
- **Inimigo não reagia ao golpe**; **janela dourada da Purga era silenciosa**; **Purga sem carga não dava retorno**
- **Shift "comprar máximo" era anunciado e não existia**
- **HUD mentia**: barra de vida verde a 5%, sem "faltam N", chefe sem aviso
- **Dano contínuo entupia o canal do impacto** (~6.000 emissões/s)
- **Motor subido para Godot 4.7.2** (~15% mais rápido), CI verde nele
- **Desempenho**: busca de alvo varria todos os inimigos ignorando a grade; laço de projéteis pagava 6 chamadas por projétil por quadro
