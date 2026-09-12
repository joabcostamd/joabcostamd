# Banco de perguntas — fases 0 e 1

> O espelho da `AUDITORIA.md`. Cada pergunta aqui evita um item reprovado lá.
>
> **Toda pergunta traz recomendação e explicação.** A pergunta ensina o que estamos
> construindo — não é interrogatório. Regra do `PREFERENCIAS-DE-JOAB.md`.

Versão 1 · 2026-09-12 · Blocos B0, B1, B2, B3 + identidade mínima · **44 perguntas**

---

## Como ler

```
### P-B1-03 · título curto
**N/A se** ... (quando esta pergunta não se aplica ao gênero)

Por que importa, em duas ou três linhas.

| | Opção | Custo e consequência |
**Recomendo X**, porque ...
→ onde a resposta cai · o que ela protege na AUDITORIA
```

**10 perguntas por rodada**, depois um respiro para você decidir se continua.
Resposta "não sei" é válida: vira 🟡 com a minha recomendação e uma data para revisitar.

---

# B0 · Identidade — 12 perguntas

Fase 0. Não depende de nada, e trava tudo. Alvo: 20 minutos.

### P-B0-01 · O jogo em uma frase
Diga o que o **jogador faz**, não o que o jogo é. "É um jogo de terror" não ajuda ninguém;
"você conserta o gerador enquanto alguma coisa te procura" já desenha a tela inteira.

A frase é o teste mais barato que existe: se ela não cabe numa linha que qualquer pessoa
entende, o conceito ainda está embaçado — e conceito embaçado vira escopo que cresce sozinho.

**Recomendo** escrever com o verbo na frente: *"você ___ enquanto ___"*.
→ `CONCEITO.md` · protege A1 A3

### P-B0-02 · Esse jogo já existe?
**Tarefa minha, não sua.** Antes de qualquer decisão, eu busco na Steam e na web se alguém já
lançou isso, com que nome, por quanto, e com que nota.

Vinte minutos aqui já pouparam meses em projeto dos outros. Se existir e for bom, a pergunta
muda: o que o nosso faz melhor? Se existir e for ruim, ótimo — a reclamação dos jogadores vira
a nossa lista de tarefas.

**Recomendo** sempre fazer, mesmo quando a ideia parece original.
→ `PESQUISA.md` · protege A5 A6

### P-B0-03 · Qual gênero, declarado
Gênero não é rótulo de loja: é o **contrato de expectativa**. Quem compra um roguelite espera
morrer e recomeçar; quem compra um puzzle espera pensar sem pressa. Quebrar o contrato sem
querer é o caminho mais rápido para análise negativa.

**Recomendo** escolher um gênero principal e no máximo um secundário. Três gêneros ao mesmo
tempo é escopo triplicado, não jogo inovador.
→ `CONCEITO.md` · protege A2

### P-B0-04 · 2D ou 3D
⚠️ **Decisão cara.** Muda arte, câmera, colisão, desempenho, tamanho do projeto e quanto tempo
cada peça de conteúdo custa.

| | Opção | Custo e consequência |
|---|---|---|
| **A** | 2D | mais barato em tudo. Arte por pixel ou por código. Conteúdo rápido |
| **B** | 3D | mais caro por peça, mas a arte gerada por IA rende mais, e o espaço vira mecânica |

**Recomendo** decidir pelo que a **mecânica** exige, nunca pela aparência. Se o jogo não precisa
de altura nem de volta por trás, 2D entrega o mesmo por um terço do trabalho.
→ `CONCEITO.md` · `PLANO.md` B0 · protege AX4 AX5

### P-B0-05 · Tema e clima
O tema decide paleta, som, nomes e o que o jogador sente. Também decide o que **não** cabe:
num jogo sombrio, confete de vitória destoa.

**Recomendo** escolher um tema que a arte gerada por IA faça bem. Formas sólidas com luz forte
(neon, vitral, silhueta) saem excelentes; realismo texturizado é onde a geração ainda falha.
→ `CONCEITO.md` · `ARTE.md` · protege A3 P1

### P-B0-06 · Qual defeito do gênero este jogo conserta
A pergunta que separa "mais um" de "aquele". Todo gênero tem uma reclamação repetida na análise
dos jogadores. Achar essa reclamação e responder a ela é a forma mais barata de ser diferente.

Exemplo medido no seu `overclock`: a queixa nº 1 de bullet heaven é *"o jogador só anda"* —
e o Clock nasceu como resposta direta a isso.

**Recomendo** fazer depois da P-B0-02, porque a resposta sai da pesquisa, não da cabeça.
→ `CONCEITO.md` · `PESQUISA.md` · protege A5

### P-B0-07 · Para quem, e por quanto tempo por sessão
Sessão de 5 minutos e sessão de 2 horas produzem jogos diferentes: salvamento, ritmo, tamanho
de fase, tela de pausa, tudo muda.

**Recomendo** declarar em minutos, não em adjetivo. "Sessão curta" não decide nada;
"10 a 20 minutos" decide o tamanho da fase.
→ `CONCEITO.md` · protege A7 A14 BA7

### P-B0-08 · Plataforma alvo e como se vende
Steam já está decidido nas suas preferências. Falta: **só PC, ou também Steam Deck?**

Steam Deck não é detalhe: muda tamanho mínimo de fonte, alvo de toque, e obriga o jogo inteiro
a ser jogável só com controle.

| | Opção | Custo e consequência |
|---|---|---|
| **A** | PC, e o Deck funciona por acaso | zero agora, retrabalho depois |
| **B** | PC + Deck desde o começo | fonte maior e controle em tudo, custa pouco se for desde já |

**Recomendo B.** O verificado do Deck é selo de venda, e enxertar depois é caro.
→ `PRODUCAO.md` · protege A15 A16 AM1

### P-B0-09 · Ambição e ritmo
Quantas horas por semana, e o jogo é para vender ou para aprender? Isso não é papo motivacional:
é o número que transforma escopo em conta. 18 módulos a 3 h cada são 54 horas — cabe ou não cabe
no seu calendário.

**Recomendo** declarar horas por semana e uma data alvo folgada. Prazo apertado não acelera nada,
só antecipa o corte de escopo para o pior momento.
→ `PRODUCAO.md` · protege A9 BB3

### P-B0-10 · O nome
Precisa ser **buscável** (se o nome for uma palavra comum, seu jogo some no Google), **livre**
(marca registrada por outro é problema jurídico) e **disponível** na Steam.

**Recomendo** nome de código agora e nome comercial depois da fase 1 — mas a busca de
disponibilidade eu faço já, porque descobrir tarde custa o trailer inteiro.
→ `CONCEITO.md` · `PRODUCAO.md` · protege A17

### P-B0-11 · O que o jogo NÃO tem ⚠️
**A seção mais importante do projeto.** É ela que impede o escopo de crescer sozinho.

Cada item vem com o motivo da recusa, não só o nome. "Sem multijogador" é fraco;
"sem multijogador, porque sincronizar 300 inimigos dobraria a arquitetura e o jogo é sobre
decisão solitária" é uma parede.

**Recomendo** listar pelo menos 6 recusas, e incluir as tentações típicas do gênero.
→ `CONCEITO.md` · protege A8 A19

### P-B0-12 · O que mata este projeto
Qual é a hipótese que, se for falsa, torna o jogo sem razão de existir? E como a gente mede isso
**barato**, antes de investir meses?

No `overclock`, é o critério 1: se o Clock não for uma decisão interessante, o jogo vira um
bullet heaven comum e perde o motivo.

**Recomendo** escolher um critério só, mensurável, e medir na prova de diversão do fim da fase 1.
→ `CONCEITO.md` · protege A11 A12

---

# B1 · Espaço e movimento — 10 perguntas

⚠️ **A decisão mais cara de mudar depois.** Determina level design, arte, orçamento de
desempenho, esquema de controle e até o enquadramento do trailer. Depende de B0. Trava B2, B3,
B6, B7, B9 e B10.

### P-B1-01 · Qual câmera
**N/A se** o jogo for de tabuleiro ou grade fixa vista de frente.

| | Opção | Custo e consequência |
|---|---|---|
| **A** | Topo fixa | mais barata. Leitura perfeita da horda. Perde drama |
| **B** | Isométrica | boa leitura + profundidade. Level design em diagonal confunde no começo |
| **C** | Terceira pessoa atrás | imersiva. Esconde o que vem atrás — ruim para horda |
| **D** | Orbital, o jogador gira | liberdade. Desorienta: o jogador perde a referência |

**Recomendo A ou B** para qualquer jogo com muitos inimigos na tela. A regra é: o jogador nunca
pode morrer por algo que a câmera escondeu.
→ `PLANO.md` B1 · `ARTE.md` · protege N1 N2 N4

### P-B1-02 · Perspectiva ou ortográfica
**N/A se** 2D puro.

Perspectiva dá profundidade e drama. Ortográfica dá leitura exata — o que está longe tem o mesmo
tamanho do que está perto, e o jogador julga distância sem erro.

**Recomendo ortográfica** em jogo de estratégia, defesa de torre e puzzle; **perspectiva** em
ação e exploração.
→ `PLANO.md` B1 · protege N3 AX4

### P-B1-03 · O jogador pula?
**N/A se** grade fixa, tabuleiro, ou o jogador não tem corpo no mundo.

Verticalidade muda level design, câmera, colisão e trailer. O *Megabonk* vendeu 1,3 milhão
apostando exatamente nisso; o *Vampire Survivors* nunca pulou e vendeu mais ainda. Ou seja:
não existe resposta certa, existe resposta coerente.

| | Opção | Custo e consequência |
|---|---|---|
| **A** | Não pula, chão plano | barato. Level design vira layout, não relevo |
| **B** | Pula | ~+30% no level design e na colisão |
| **C** | Pula, escala e voa | ~+60%. Vira outro jogo, com outra câmera |

**Recomendo A**, a menos que o mapa seja o diferencial do jogo.
→ `PLANO.md` B1 · `ARQUITETURA.md` · protege O3 J7

### P-B1-04 · Tem esquiva ou avanço rápido?
Esquiva muda a curva de habilidade: dá ao jogador bom uma saída que o ruim não encontra. Também
muda o balanceamento inteiro, porque dano evitável e dano inevitável são coisas diferentes.

**Recomendo ter**, com recarga curta. É a ferramenta mais barata para fazer habilidade importar —
e sem ela, morrer parece injusto.
→ `PLANO.md` B1 · `DESIGN.md` · protege V3 I4

### P-B1-05 · Arena fechada ou mapa para explorar
| | Opção | Custo e consequência |
|---|---|---|
| **A** | Arena fechada | barata, legível, e o combate é o assunto |
| **B** | Mapa aberto | exploração vira conteúdo, mas exige orientação, marcos e mapa |

**Recomendo A** quando a ação central for o assunto do jogo; **B** só quando achar coisas for
tão divertido quanto usar as coisas.
→ `PLANO.md` B1 · `DESIGN.md` · protege J1 J4

### P-B1-06 · O terreno participa da mecânica?
Altura, rampa, buraco, parede que bloqueia tiro. É o que transforma posição em decisão — e é
apontado como o defeito histórico e não resolvido do gênero de horda.

**Recomendo** pelo menos **uma** regra de terreno (por exemplo: altura dá alcance). Uma regra
rende muito e custa pouco; cinco regras viram simulação.
→ `PLANO.md` B1 · `DESIGN.md` · protege J2 J7

### P-B1-07 · Quem controla a câmera
O jogador gira à vontade, ou a câmera é travada? Câmera livre desorienta — foi o defeito do
Picross 3D no DS, e está anotado na sua própria pesquisa.

**Recomendo** giro com **encaixe de 90°** e transição suave, mais um indicador de direção fixo
na tela. Dá liberdade sem perder a referência.
→ `PLANO.md` B1 · protege N5 AB11

### P-B1-08 · A escala do mundo ⚠️
**Decidida agora e nunca mais.** Quanto vale 1 unidade? Onde fica a origem de uma peça?

Mudar isso depois quebra câmera, colisão, tamanho de asset e save — tudo de uma vez. No estudo
do Picross 3D já ficou escrito: *1 voxel = 1 unidade, origem no canto, centro do cubo em
(x+0.5, y+0.5, z+0.5)*.

**Recomendo** 1 unidade = 1 metro em 3D, e declarar o tamanho do jogador em unidades. Toda peça
de arte nasce medida contra isso.
→ `ARQUITETURA.md` · `ARTE.md` · protege AX5 Q2

### P-B1-09 · Velocidade e sensação do movimento
Quanto tempo o jogador leva para atravessar a tela? Ele derrapa ou para seco? Tem aceleração?

Isso é **game feel**, e game feel não é polimento do fim: é o que separa o jogo bom do
esquecível — está na sua pesquisa, sobre o *Death Must Die*.

**Recomendo** definir em segundos ("atravessa a arena em 4 s") e ajustar na prova de diversão,
com o jogo na mão.
→ `DESIGN.md` · protege V1 V2 M5

### P-B1-10 · Colisão por física ou por matemática
**N/A se** 2D de grade.

Física da engine é fácil de começar e cara de escalar. Matemática (distância, caixa, travessia
de voxel) é mais trabalho no começo e aguenta milhares de objetos.

**Recomendo** física para o jogador e para poucos personagens importantes; **matemática** para
horda, projétil e tudo que existe aos milhares. É o padrão híbrido que a sua pesquisa já
recomendou — com a ressalva medida: **meça antes de converter.**
→ `ARQUITETURA.md` · protege O1 O5 AG2

---

# B2 · Estrutura da partida — 7 perguntas

Depende de B1. Trava B4, B5, B7 e B8.

### P-B2-01 · Quanto dura uma partida
Número em minutos, não adjetivo. Ele decide tamanho de fase, ritmo da dificuldade, quantos
inimigos cabem, e se o jogador consegue jogar "só mais uma".

Referências medidas: *Megabonk* 10 min · *Vampire Survivors* e *Brotato* 20 min.

**Recomendo** casar com a P-B0-07 (tempo de sessão). Partida de 20 min numa sessão de 15 é
frustração garantida.
→ `CONCEITO.md` · `DESIGN.md` · protege A14 I1

### P-B2-02 · Como se vence
Sobreviver ao relógio · matar o chefe · cumprir o objetivo · nunca vence (infinito com placar).

**Recomendo** uma condição só, visível o tempo todo na tela. Duas condições competindo confundem
o jogador e dobram o balanceamento.
→ `DESIGN.md` · protege G2 AA14

### P-B2-03 · Como se perde
Vida zero · tempo esgotado · deixar passar N inimigos · erro que acumula.

**Recomendo** que a derrota seja **legível**: o jogador precisa saber o que estava perdendo
antes de perder. Barra que esvazia devagar ensina; morte súbita frustra.
→ `DESIGN.md` · `TELAS.md` · protege G3 AB6

### P-B2-04 · Ao morrer, quanto tempo até a próxima partida
Em segundos, do fim ao começo. É a medida mais subestimada do gênero: 3 segundos criam o vício
do "só mais uma"; 20 segundos fazem o jogador fechar o jogo.

**Recomendo** menos de 5 segundos, com um botão só — e nada de animação longa de derrota.
→ `TELAS.md` · `DESIGN.md` · protege AA13 V6

### P-B2-05 · Tem respiro entre as fases?
Pausa entre ondas para pensar, gastar recurso e escolher — o modelo do *Brotato*.

É a solução mais simples e testada para a queixa nº 1 do gênero: *"não há decisão a tomar"*.
Custa pouco e muda muito.

| | Opção | Custo e consequência |
|---|---|---|
| **A** | Fluxo contínuo | tenso, mas a decisão tem que estar dentro da ação |
| **B** | Pausa entre ondas | dá agência de graça. Quebra o ritmo se for longa demais |

**Recomendo B** para jogo de ondas, com a pausa curta e pulável.
→ `DESIGN.md` · `TELAS.md` · protege G5 I6

### P-B2-06 · O que se perde e o que se guarda ao morrer
Perde tudo · guarda moeda · guarda progresso de desbloqueio · guarda a fase alcançada.

**Recomendo** guardar **variedade** (coisas novas para experimentar) e nunca **poder** que
resolva a partida sozinho — senão a habilidade deixa de importar e o jogo se joga sozinho no
mês 2.
→ `DESIGN.md` · `ARQUITETURA.md` (define o save) · protege H4 H7

### P-B2-07 · E se o jogador fechar o jogo no meio? ⚠️
A ponta solta clássica. O jogador está no minuto 18 de uma partida de 20, fecha a janela, e
volta amanhã. O que acontece?

No `picross` isso foi tratado: *"sair no meio de um 25×25 e perder o trabalho seria o pior
defeito possível aqui"*. O andamento é guardado e volta idêntico.

**Recomendo** guardar a partida em andamento desde o dia 1 — porque isso muda o **contrato do
save**, e enxertar depois é migração.
→ `ARQUITETURA.md` · protege AF3 BA6

---

# B3 · Ação central — 8 perguntas

Depende de B1. Trava B4, B7, B9 e B10. **É o coração: a coisa que o jogador faz mil vezes.**

### P-B3-01 · Qual é a ação que se repete
Em uma frase, com verbo. "Mirar e atirar" · "colocar peça e esperar" · "quebrar cubo e deduzir".

Se essa ação não for gostosa sozinha, nenhuma quantidade de conteúdo salva o jogo. É por isso
que ela é provada em caixa cinza, antes de tudo.

**Recomendo** escolher **uma** ação central. As outras são apoio.
→ `CONCEITO.md` · `DESIGN.md` · protege G1 G4

### P-B3-02 · Automática ou manual
| | Opção | Custo e consequência |
|---|---|---|
| **A** | Automática (o jogo age por você) | o contrato do bullet heaven. A decisão migra para posição e build |
| **B** | Manual (mira, tempo, precisão) | habilidade importa mais. Cansa em sessão longa |
| **C** | Mista: base automática + um botão que importa | melhor dos dois, mais trabalho de equilíbrio |

**Recomendo C** quando o gênero for automático: um botão que sempre cobra caro devolve a decisão
sem quebrar o contrato. Foi assim que o Clock do `overclock` nasceu.
→ `DESIGN.md` · protege G5 M4

### P-B3-03 · Como o alvo é escolhido
**N/A se** a ação não tem alvo.

Mais próximo · direção do movimento · maior ameaça · menor vida · aleatório.

**Recomendo** uma regra só, e **visível**: o jogador precisa conseguir prever quem vai ser
atingido. Regra invisível vira sensação de sorte.
→ `DESIGN.md` · protege G6 AB6

### P-B3-04 · Existe habilidade ativa com recarga?
É o que dá ao jogador algo para fazer no momento crítico. Sem ela, momento crítico vira
espectador.

**Recomendo** no máximo duas, com recarga visível na tela. Quatro habilidades viram teclado de
avião e o jogador esquece que existem.
→ `DESIGN.md` · `TELAS.md` · protege G7 Z4

### P-B3-05 · Como o resultado é comunicado
O jogador precisa saber, sem ler, que acertou, que causou dano, e que o inimigo está quase
morrendo.

**Recomendo** três canais ao mesmo tempo: som curto, piscada de cor, e movimento (recuo ou
tremor). E **sem número gigante flutuando** — legibilidade vence espetáculo.
→ `DESIGN.md` · `ARTE.md` · `SOM.md` · protege V4 P6

### P-B3-06 · Qual erro o jogador pode cometer
Se não dá para errar, não dá para acertar. Nomeie o erro: mirar mal, ficar parado, gastar
recurso na hora errada, aquecer demais.

**Recomendo** um erro central, punido de forma **legível e recuperável** — punição que tira a
partida inteira ensina medo, não habilidade.
→ `DESIGN.md` · protege G8 I4

### P-B3-07 · Janela de perdão
Quantos milissegundos de tolerância: pulo apertado tarde demais, esquiva no último quadro, tiro
que sai um instante depois.

Isso é invisível e é metade da sensação de que "o jogo responde". O seu `prototipo-godot` já
tem *coyote time* e buffer de pulo implementados — é o mesmo princípio.

**Recomendo** começar generoso e apertar depois. Jogo que parece injusto perde o jogador nos
primeiros 10 minutos, e ninguém reclama de um jogo que perdoa.
→ `DESIGN.md` · protege V3 M6

### P-B3-08 · O que o jogador faz quando não está fazendo a ação central
Andar? Esperar? Escolher? Se a resposta for "nada", existe tempo morto — e tempo morto é onde
o jogador fecha o jogo.

**Recomendo** garantir que sempre exista uma decisão pequena disponível: para onde ir, o que
pegar, quando gastar.
→ `DESIGN.md` · protege G5 I6

---

# Identidade mínima — 7 perguntas

Fase 1, junto com a prova de diversão. **É decisão, não asset**: custa uma hora, cabe numa
página, e não se joga fora nem se o design mudar inteiro.

Existe porque o `PREFERENCIAS-DE-JOAB.md` manda **polir toda fatia na mesma passada** — e para
isso a identidade precisa existir antes da primeira fatia.

### P-IM-01 · As 5 linhas artísticas ⚠️
**Antes de escolher cor nenhuma**, eu gero **pelo menos 5 direções artísticas distintas** e
mostro as cinco lado a lado. Em 3D elas nascem **dentro do Godot**, renderizadas de verdade:
mesma cena, mesmo enquadramento, mesma peça de teste, para a comparação ser justa.

Cada linha vem com nome curto, o que promete, e quanto custa produzir.

**Nenhuma das cinco prestou?** Gero mais cinco. É a regra da seção 6 das suas preferências.
→ `ARTE.md` · protege P1 Q1 R1

### P-IM-02 · As 5 cores, cada uma com uma função
Cor **informa**, não decora. Toda cor da tela tem um trabalho, e nenhuma cor faz dois.

Modelo que já funcionou no `overclock`: vazio · você · seu dano · inimigo · o que te mata.

**Recomendo** reservar **uma faixa inteira do espectro para perigo**, com consequência dura
escrita: nenhum efeito decorativo pode usar aquela cor. Se um dia algo daquela cor aparecer sem
machucar, o jogador perde a confiança na tela inteira.
→ `ARTE.md` · protege P4 AD3

### P-IM-03 · A prova de daltonismo
Toda cor que **informa** passa por simulação de dicromacia antes de virar decisão — protanopia e
deuteranopia. A skill `acessibilidade` faz isso e grava o resultado.

**Recomendo** fazer agora, com 5 cores, e não no fim, com 50. E ter sempre um segundo sinal além
da cor: forma, contorno, ou movimento.
→ `ARTE.md` · protege AD1 AD2 AD4

### P-IM-04 · Uma fonte, e quais alfabetos
A fonte precisa dos glifos dos idiomas que o jogo vai ter. Fonte sem cirílico mata um idioma
na véspera do lançamento.

No `picross` isso foi resolvido com subsetting: 21 MB viraram 188 KB.

**Recomendo** uma fonte só, com licença comercial livre, e declarar os idiomas agora — mesmo que
a tradução venha depois.
→ `ARTE.md` · `PRODUCAO.md` · protege AE2 Z6

### P-IM-05 · Os três sons que aparecem em toda tela
Confirmar · cancelar · erro. São os sons que o jogador mais vai ouvir no jogo inteiro, e são os
que dão unidade sonora a telas feitas em semanas diferentes.

**Recomendo** sintetizar por código (como no `picross`, que não tem um arquivo de áudio no
repositório) ou tirar do acervo CC0 — e decidir os três **agora**, não por tela.
→ `SOM.md` · protege W1 Y3

### P-IM-06 · Uma regra de juice
A única regra de "peso" que vale para tudo desde a primeira fatia. Exemplos: *toda ação bem
sucedida solta uma partícula e sobe meio tom no som* · *todo acerto empurra o alvo 4 pixels*.

**Recomendo** escolher uma que sirva para qualquer coisa, e aplicá-la em toda fatia. Cinco
regras de juice viram inconsistência; uma vira identidade.
→ `ARTE.md` · `SOM.md` · protege V1 V5

### P-IM-07 · Uma transição entre telas
Como uma tela vira a outra: fundido, corte com som, deslize, íris. Uma só, usada em todo lugar.

**Recomendo** decidir agora porque transição improvisada é o que mais denuncia jogo amador —
e porque o `agent_verify` não pega isso, só o olho pega.
→ `TELAS.md` · `ARTE.md` · protege AA24 Z2

---

## Depois destas 44

Passou a fase 1 → as duas provas baratas:

- 🎲 **prova de diversão** — caixa cinza em `prototipo/`, medindo o critério da P-B0-12
- 🎨 **prova de asset** — um modelo e um som, de ponta a ponta, pelo caminho definitivo

Passaram as duas → fase 2: B4, B5, B6, B7, B8, B9. **Esse banco ainda não existe** e é o
próximo a ser escrito.
