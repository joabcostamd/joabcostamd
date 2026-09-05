# A REGRA DA CRUZADA — decisão final

## 1. A DECISÃO EM TRÊS LINHAS

Entra a **JANELA DA COLHEITA**, com o parâmetro **janela = 1 turno, colheita conjunta livre** (célula J1, candidato 4).
Ela leva a cruzada da política gulosa de **0,000 para 0,831 por mesa** (100% → 16,9% de mesas sem nenhuma), e encolhe a distância planejadora−gulosa de **1,490 para 0,805 (−46%)**, que é a única métrica que prova que o horizonte 9 encurtou.
Nenhuma combinação com os outros três candidatos melhora isso; três das quatro combinações estouram a guarda de profundidade (m5 80,5% contra teto de 75%).

## 2. A REGRA FINAL, ESCRITA PARA IMPLEMENTAR

> **R17-b (JANELA DA COLHEITA).** Uma linha (fileira, coluna ou diagonal) que recebe sua 5ª carta **não é colhida no ato**: ela entra no estado **MADURA** e permanece na grade, ocupando suas 5 casas, sem receber cartas novas.
> No **posicionamento seguinte do jogador**, todas as linhas maduras são colhidas **num único evento**, junto com qualquer linha que tenha completado nesse mesmo posicionamento.
> **FATOR do evento = (SOMA dos multiplicadores de todas as mãos colhidas no evento) × Tear.** Diagonais pagam 60%. O teto de multiplicador `24 + 4×rodada` fica **REMOVIDO**.

Casos-limite, todos já testados no motor (32 asserções, 0 falhas):
- linha que amadurece no **último** posicionamento da mesa colhe na hora, sem janela;
- **sem restrição** de perpendicularidade na colheita conjunta — 93,8% já são perpendiculares sozinhas, e restringir muda −1% (0,826 → 0,817);
- **sem limite** de "só a primeira madura da mesa" (no-op medido: 0,820 vs 0,826);
- uma linha madura **não volta a pulsar** (o PULSO de 0,35 dispara uma vez por limiar);
- casas vazias mínimas caem de 16/11 para 9/7 — nunca chegou a zero em 11.000 mesas; mão morta continua impossível;
- **a curva de metas é refeita junto: K de 2,17 para 4,40 (+103%).** Sem isso a razão pontos/meta vai a ~1,37 e o jogo se resolve sozinho.

**Texto para o jogador (12 palavras):** *"Linha cheia fica madura um turno. Colhe no próximo, junto com outras."*

## 3. A TABELA

| métrica | banda | BASE | c1 (Tear) | c2 (mat. F=1,5) | c3 (semear S=6) | **c4 = J1** | J1+c2 | as quatro |
|---|---|---|---|---|---|---|---|---|
| K recalibrado (razão→0,79) | — | 2,17 | 1,69 | 3,73 | 3,14 | **4,40** | 8,83 | 6,24 |
| **cruzada/mesa GULOSA** | >0,25 | **0,000** | 0,000 | 0,012 | 0,000 | **0,831** | 0,672 | 0,651 |
| cruzada/mesa PROFUNDA | — | 0,005 | 0,013 | 0,059 | 0,042 | **0,820** | 0,788 | 0,785 |
| cruzada/mesa CAÇADORA b1 | — | 0,144 | 0,140 | 0,151 | 0,311 | **0,857** | 0,741 | 0,732 |
| cruzada/mesa PLANEJADORA | ≥1,0 | 1,490 | 1,402 | 1,430 | 1,438 | **1,636** | 1,637 | 1,594 |
| **distância planej.−gulosa** | encolher | 1,490 | 1,402 | 1,418 | 1,438 | **0,805** | 0,965 | 0,943 |
| % mesas com ZERO (gulosa) | <40% | 100% | 100% | — | 100% | **16,9%** | 32,8% | 34,9% |
| cruzadas por EVENTO | 0,35–0,55 | 0,000 | 0,000 | — | — | **0,710 ✗** | 0,730 ✗ | 0,741 ✗ |
| turnos com recompensa | ≥60% | 64,8% | 64,8% | — | 83,9% | **75,8%** | 81,9% | 96,3% |
| seca mediana / p90 | ≤3 | 2/4 | 2/4 | — | — | **2/3** | 2/3 | **0/1** |
| **guarda m5** | 45–75% | 59,0% | 59,3% | 48,5% | 72,8% | **68,2%** | 72,1% | **80,5 ✗** |
| vitória global | 20–40% | 31,2% | 33,1% | — | — | **36,1%** | 38,1% | 36,0% |
| Tear mediano | ≥4 | 7 | 5 (V3: **1 ✗**) | — | 6 | **7** | 6 | 5 |
| maior evento único | — | 10.260 | 6.840 | 13.680 | 24.235 | **32.600** | 32.600 | 24.235 |
| pico / mediana | — | 15,64× | 11,52× | — | — | **10,03× ↓** | 9,57× | 10,20× |
| turnos segurando 4/5 | >0 | **0,000** | 0,000 | 1,73 | — | **3,52** | 3,74 | 3,25 |
| violações do teto 2/1/2 | 0 | 0 | 0 | 0 | 0 | **0** (44.000 mesas) | 0 | 0 |

Cruzadas por tipo de mesa em J1 (gulosa / planejadora): Pequena **0,869 / 1,935** · Grande **0,713 / 1,000** · Chefe **0,912 / 1,976**. O teto aritmético 2/1/2 é atingido na casa decimal e nunca ultrapassado.

## 4. O QUE FOI REPROVADO E POR QUÊ

- **c1 — só a cruzada levanta o Tear: REPROVADO, dial de zero bit.** Gulosa 0,0000 nas 8 variantes. Provado duas vezes: com o mesmo K, gulosa base e V1 escolhem a mesma jogada em **99,96% de 4.815 turnos**; e mesmo com a cruzada já acontecendo (J1+c1) o número é **0,831 contra 0,831**, idêntico à terceira casa. O Tear é fator comum ao turno: muda K, não reordena nada. Custo real: Tear mediano 7→5, e **7→1** em V3/V4, com o maior evento caindo para 1.710.
- **c2 — maturação do 4/5: REPROVADO, inerte e depois anti-cruzada.** Em F=0,08/0,15/0,25 a regra é **exatamente** inerte: 0,0% dos pontos vêm dela, 0,0% de colheitas adiadas. O ponto de virada é F≈1,5 e ali a gulosa faz **0,012** (20× abaixo do critério). Somada a J1 ela **derruba** a cruzada: 0,831 → 0,764 (F=0,75) → **0,672** (F=1,5), com K indo a **8,83**. As duas regras compram a mesma decisão de esperar e competem pelo mesmo turno.
- **c3 — semear mais o tabuleiro: REPROVADO, compra o número com material.** Com semeadura aleatória e material conservado a gulosa fica em **0,000–0,017 para todo S de 3 a 12**. As únicas células acima de 0,25 são S≥8 enviesado, e nelas o jogador pagou **1,00 de 9 braços** — é o falso positivo previsto, medido. Somado a J1 não dá ganho (0,823 vs 0,831) e gasta a guarda (m5 72,8%; com S=3, **75,2% ✗**).
- **janela = 2 turnos: REPROVADA por m5 = 76,3%.** **janela = até o fim: REPROVADA por m5 = 77,8%** e por **1,000 evento por mesa** na planejadora — a mesa inteira vira um clique.
- **Os dois antídotos declarados do próprio c4 falham.** "Só a primeira madura" é no-op (0,820). "Só se a perpendicular já estiver em 4/5" **desliga a regra** (gulosa **0,098**, seg4/5 volta a 0,566): a condição exige o produto do laço como partida do laço.
- **Todas as combinações de 3 e 4 regras: REPROVADAS por m5 80,3% e 80,5%.** O recurso escasso não é a cruzada, é a guarda de profundidade: a base gasta 59,0 dos 75 pontos, a janela consome 9,2 dos 16 restantes, e a terceira regra estoura.

## 5. O QUE ISSO CUSTA

Três preços, todos medidos, nenhum coberto pelas bandas declaradas.

**(a) Reescreve a economia, não só uma regra.** K sobe **+103%** (2,17 → 4,40). A própria falsificação nº 4 do proponente ("a razão sobe menos de +0,10") falhou por **6×** (+0,58). Toda a curva de metas das 6 rodadas volta para a mesa de cálculo.

**(b) A cruzada deixa de ser exceção e vira o modo normal de colher.** Eventos por mesa caem de **2,21 para 1,17**; cruzadas por evento vão a **0,710** (banda saudável 0,35–0,55). Dos eventos gulosos, só **29,0% ainda são de uma linha só** (base: 100%); 51,9% são de duas, 18,2% de três, 0,85% de quatro. E a explosão relativa encolhe: pico/mediana de **15,64× para 10,03×**. O jogador vê números maiores e sente menos diferença entre um turno comum e o clímax.

**(c) Planejar deixa de pagar — e este é o preço mais caro.** Na base, jogar para a cruz **dobra a vitória**: planejadora 62,7% contra 31,2% da gulosa, razão pontos/meta 1,126 contra 0,800. Com a janela e o K recalibrado, a planejadora cai para **30,7% de vitória contra 36,1% da gulosa** e razão **0,665 contra 0,800**. Perseguir a cruzada de propósito passa a ser **pior** que jogar guloso. A regra socializa o clímax e taxa quem tem perícia. Nenhuma das outras três regras corrige isso; c2 piora.

**Mais um conceito na tela:** o estado MADURA (5 cartas cheias que não somem) precisa de sinal visual próprio, e o jogo passa a ter dois estados de linha em vez de um.

## 6. O QUE AINDA NÃO SABEMOS

A simulação mede frequência, não emoção. Ela não sabe se o jogador **grita** quando duas linhas colhem juntas — 0,831 por mesa é a taxa, não o impacto. Não sabe se a linha madura é legível: se o jogador não entender que aquelas 5 cartas somem no próximo clique, o turno de espera vira confusão em vez de suspense. Não sabe se **1,17 evento por mesa** grande é mais gostoso que 2,21 pequenos, nem se ver a cruzada 0,83 vez por mesa a torna banal em dez horas. E não mediu loja, selos, níveis de mão ou modificadores de mesa (`null` em todas as bancadas). Só playtest humano responde.

## 7. VEREDITO

**Sim, o jogo mantém o nome CRUZADA — mas o nome muda de sentido, e é preciso dizer isso em voz alta.**

> **Superado depois.** O jogo passou a se chamar **PLACARD**; CRUZADA ficou sendo
> só o nome da jogada, que é o que esta seção de fato resolveu. O motivo da troca
> está em `placard/NOME.md`: CRUZADA significa *guerra santa* em três línguas
> latinas e nada nas outras, e o título precisava ser universal. A decisão de
> sentido registrada abaixo continua valendo inteira.

Sem a janela o nome era falso: **0,000 cruzada em 100% das mesas** da política gulosa, em 30.944 turnos e em cinco bancadas independentes. Com a janela, 83,1% das mesas têm pelo menos uma cruzada mesmo para o jogador distraído, e o teto aritmético 2/1/2 é atingido por quem planeja. A cruzada existe.

O que ela deixou de ser é o **clímax**. Com 0,710 cruzada por evento, a cruzada dupla é agora o **verbo** do jogo, não o seu ponto alto. Fingir o contrário é mentir para o jogador na primeira hora. A resposta não é frear a regra (os dois freios foram medidos e não existem): é **mover o clímax um degrau acima**, para a escada que já está nas regras e que nenhuma bancada tinha nomeado — **DUPLA (9 posicionamentos, 2×) · TRIPLA (13, 3×) · CRUZ TOTAL (17, 4×)**. A TRIPLA é 18,2% dos eventos gulosos e a TOTAL, 0,85%: essas duas são raras de verdade. E a CRUZ TOTAL cabe **exatamente** numa mesa Grande — 17 células, 17 posicionamentos — com 88,2% de sucesso e **85,4% de vitória**. É o melhor jogo do PLACARD e não tem nome na tela. Dê nome.

**Uma condição, sem a qual a decisão se anula:** fixar a leitura como **SOMA dos mults × Tear**, com o teto `24+4×rodada` **removido**. Sob PRODUTO o teto morderia **57,5%** das cruzadas e **78,5% das TOTAIS**, e a escada 2×/3×/4× colapsaria em silêncio.

**E uma dívida:** o preço (c) — planejar deixar de pagar — é o que eu recomendaria resolver antes de fechar a versão. Não estoura banda nenhuma, mas troca "recompensa quem enxerga longe" por "recompensa quem clica bem". Alvo da próxima bancada: devolver retorno ao planejamento **sem** aumentar o prêmio da cruzada (já provado inerte em 4×, 20× e 100×).
