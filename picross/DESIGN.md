# Revelar — jogo de Picross (nonogram)

Documento de projeto. Escrito **antes** do código, e mantido junto com ele.

## 1. A ideia em uma frase

Você resolve um quebra-cabeça de lógica com números nas bordas; quando ele
fecha, o desenho escondido se revela colorido e entra na sua galeria.

A recompensa não é uma pontuação — é **a imagem**. Por isso a coleção é o
coração do jogo, e a tela de revelação é a mais importante de todas.

## 2. Regras

Grade de N×N. Cada linha e cada coluna tem uma sequência de números: os
tamanhos dos blocos preenchidos, na ordem, com pelo menos um espaço vazio
entre blocos. O jogador deduz quais células são cheias.

- **Pintar** (botão esquerdo): marca a célula como cheia
- **Marcar X** (botão direito): marca como vazia — é anotação, não afeta a vitória
- Vitória quando todas as células cheias da solução estão pintadas e nenhuma
  célula vazia está pintada

### Erros

Modo padrão: pintar uma célula errada custa uma vida (3 vidas). Isso é o que
mantém a tensão. Modo relaxado (nas opções): erros não custam nada.

## 3. Qualidade dos puzzles — a regra inegociável

Todo puzzle precisa ter **solução única e alcançável por lógica pura**. Um
picross que exige chute é um picross quebrado.

Garantia: um solucionador escrito em Python resolve cada puzzle usando só
dedução por linha/coluna. Se ele resolve sem chutar, o puzzle é válido. Se
não resolve, o desenho é ajustado ou descartado. Nenhum puzzle entra no jogo
sem passar por isso.

A mesma ferramenta mede a dificuldade, e é ela que define a ordem das fases —
dificuldade medida, não chutada.

### Fórmula de dificuldade

Combinação de: tamanho da grade, número de passes de dedução necessários,
quantas células a dedução mais difícil exigiu, e densidade de preenchimento.
O resultado é um número que ordena as 50 fases.

## 4. Conteúdo

200 fases em 5 capítulos, por tamanho crescente:

| Capítulo | Grade | Fases | Tema |
|---|---|---|---|
| 1 — Primeiros traços | 5×5 | 20 | símbolos simples |
| 2 — Objetos | 10×10 | 40 | coisas do dia a dia |
| 3 — Criaturas | 15×15 | 50 | bichos e figuras |
| 4 — Cenas | 20×20 | 50 | lugares, veículos, comida |
| 5 — Obras | 25×25 | 40 | as imagens maiores |

### Como 200 desenhos são feitos

Caractere a caractere não escala. Os desenhos são descritos por formas numa
prancheta (`ferramentas/pincel.py`) — elipses, retângulos, triângulos, linhas
e simetria — e rasterizados para a grade. Um bicho sai em quatro linhas de
código, e a validação de solução única continua igual.

A auditoria da arte é visual: `ferramentas/folha_contato.py` gera uma folha
por capítulo com todos os desenhos lado a lado. É olhando essa folha que se
descobre que um desenho "não lê" — parece outra coisa.

Cada fase tem: nome, desenho, paleta de cores da revelação e uma legenda
curta que aparece na galeria.

## 4b. O que a pesquisa sobre o gênero mostrou

Antes de ampliar o escopo, olhamos o que os picross comerciais oferecem e o
que os jogadores pedem:

- **Volume**: Picross Touch tem 366 fases; Picross Bonbon, 160. As 200 daqui
  ficam na faixa competitiva.
- **Sem chute, solução única** aparece em toda avaliação positiva do gênero —
  é justamente a garantia que o solucionador dá aqui desde o começo.
- **Acessibilidade** é pedida com frequência: tema claro, alto contraste e
  poder desligar animação de fundo. Os três entraram nas opções.
- **Progressão visível** (estrelas, conquistas, estatísticas) é o que sustenta
  sessões longas.
- Para uma eventual publicação, o que costuma ser exigido é: conquistas,
  salvamento em nuvem, tradução e suporte a controle. As conquistas já estão
  implementadas de forma local; as outras três ficam como trabalho futuro,
  registrado abaixo.

## 5. Telas

| Tela | Conteúdo |
|---|---|
| Abertura | logo animado, entra no menu com qualquer tecla |
| Menu | Jogar · Galeria · Opções · Créditos · Sair |
| Capítulos | 4 capítulos com progresso (x/n resolvidas) |
| Fases | grade de cartões: número, nome se resolvida ou "?" se não, estrelas |
| Jogo | grade, pistas, vidas, tempo, desfazer, dica, pausa |
| Pausa | Continuar · Reiniciar · Opções · Sair para o mapa |
| Derrota | acabaram as vidas: Tentar de novo · Sair |
| Revelação | o desenho colorido surgindo, nome, tempo, estrelas, Próxima |
| Galeria | mural das imagens conquistadas; clique amplia com nome e legenda |
| Opções | música, efeitos, modo relaxado, mostrar erros, apagar progresso |
| Conquistas | 16 conquistas com barra de progresso |
| Estatísticas | números do jogador e progresso por capítulo |
| Créditos | ficha técnica |

### Seleção de fases

Com 200 fases, a tela ganhou abas por capítulo, filtros (todas, a resolver,
sem 3 estrelas), rolagem e miniatura da imagem conquistada em cada cartão.

Fluxo: Abertura → Menu → Capítulos → Fases → Jogo → Revelação → Fases.

## 6. Estrelas

- 1 estrela: resolveu
- 2 estrelas: resolveu sem perder vida
- 3 estrelas: resolveu sem perder vida e dentro do tempo-alvo da fase

O tempo-alvo é calculado a partir da dificuldade medida, não escolhido no olho.

## 7. Arquitetura

```
ferramentas/          Python — autoria e validação (não entra no jogo)
  arte.py             os desenhos, em texto
  solucionador.py     resolve, prova unicidade e mede dificuldade
  construir.py        gera dados/puzzles.json + relatório de auditoria
dados/puzzles.json    conteúdo final consumido pelo jogo
scripts/nucleo/       regra do jogo, sem interface: Puzzle, Partida
scripts/autoload/     Progresso (save), Audio, Navegacao (troca de telas)
scripts/telas/        uma classe por tela
testes/              suíte headless
```

O núcleo (`Puzzle`, `Partida`) não conhece nós nem desenho — pelo mesmo motivo
do kit de puzzle: assim dá para testar tudo sem abrir janela.

## 7b. Aparência

Quatro paletas: escura, clara, e as duas versões de alto contraste. Todas as
cores saem de `Estilo`, que troca a paleta inteira em tempo de execução — não
há cor fixa espalhada pelo código (foi um bug real: os botões desabilitados
continuavam escuros no tema claro).

Cada capítulo tinge o brilho do fundo com um tom próprio, em opacidade muito
baixa: dá identidade sem competir com a leitura da grade.

## 7c. O que ficou de fora, de propósito

Registrado para não parecer esquecimento:

- **Salvamento em nuvem e conquistas de plataforma**: as conquistas existem no
  jogo; ligá-las a uma loja exige o SDK dela.
- **Tradução**: os textos estão em português, escritos direto nas telas. Uma
  publicação internacional pediria uma tabela de textos.
- **Controle e navegação por teclado nos menus**: hoje o jogo é de mouse e
  teclado na partida; os menus ainda não têm foco navegável completo.

## 8. Áudio

Sem arquivos de áudio no repositório: os efeitos são sintetizados por código
na inicialização (clique, marca, erro, vitória). Fica leve e versionável.

## 9. Persistência

`user://progresso.save` — JSON com: fases resolvidas, estrelas, melhor tempo,
imagens da galeria, e as opções. Salva ao concluir fase e ao mudar opção.

## 10. Ordem de trabalho e auditoria

Cada etapa só fecha depois de auditada:

| Etapa | Como é auditada |
|---|---|
| 1. Solucionador | testes com puzzles de resposta conhecida |
| 2. Os 50 desenhos | todos validados: solução única e sem chute |
| 3. Núcleo do jogo | suíte headless de regras |
| 4. Telas | captura de tela de cada uma, conferida |
| 5. Fluxo completo | partida simulada do menu à galeria |
| 6. Final | suíte inteira + capturas + revisão do código |
| 7. Juice | testes que travam fundo, partículas e botões equipados |

### O que dá vida ao jogo

| Onde | O que acontece |
|---|---|
| Botões | crescem ao passar o mouse, afundam ao apertar, com um som curto |
| Célula pintada | nasce maior e assenta, solta faíscas e sobe meio tom no som |
| Sequência de acertos | cada acerto seguido é mais agudo que o anterior |
| Erro | a grade treme, a tela pisca em vermelho e as vidas pulsam |
| Linha ou coluna fechada | uma onda de faíscas percorre a linha, com som próprio |
| Vitória | clarão dourado e confete |
| Revelação | a imagem se forma na diagonal, clarão, confete e as estrelas caem uma a uma |
| Fundo | brilho suave que respira, poeira flutuando e vinheta nas bordas |

## 11. Decisões tomadas durante a produção

Registradas aqui porque mudaram o projeto:

- **A interface é montada por código**, não por cenas desenhadas no editor.
  Cada tela é um `Control` com um script; o visual todo sai de `Estilo`.
  Vantagem: um só lugar define a aparência, e as telas aparecem inteiras no
  diff. Custo: o layout não é editável arrastando no editor.
- **Padrão alternado denso é proibido nos desenhos.** Um xadrez grande sempre
  aceita duas leituras. Descoberto ao validar o primeiro bloco de arte.
- **Erro pinta a célula como vazia.** É o comportamento clássico do gênero e
  mantém a condição de vitória simples: venceu quem pintou todas as cheias.
- **Capítulo abre faltando duas fases do anterior**, para que uma fase difícil
  não tranque o jogador. A regra de desbloqueio das fases teve de ser alinhada
  a isso: a primeira fase de um capítulo depende do capítulo, não da fase
  anterior. Um teste trava esse contrato.
- **Música sintetizada** entrou depois: havia controle de volume nas opções
  sem música nenhuma por trás.
- **A resposta ao toque é automática.** Um nó auxiliar em cada tela equipa
  todo botão que aparece — inclusive os criados depois, como os da pausa.
  Ele é um nó, e não uma conexão solta de sinal, para morrer junto com a tela.
- **Controles dentro de CanvasLayer não herdam o tamanho da tela.** Sem um pai
  Control, os anchors não têm a que se ancorar e o nó fica com tamanho zero.
  O fundo e a camada de partículas copiam o tamanho do viewport.
- **A animação de entrada não mexe na posição.** Containers só posicionam os
  filhos no fim do quadro; animar a posição a partir do valor lido antes disso
  atira o conteúdo para o canto da tela.
- **Só a célula pintada por engano fica vermelha.** Na primeira versão, marcar
  X sobre uma célula cheia acendia vermelho — e como marcar X não custa nada,
  dava para descobrir o desenho inteiro sem punição. A partida agora guarda
  quais células o jogador errou ao pintar, e só essas ganham cor.
