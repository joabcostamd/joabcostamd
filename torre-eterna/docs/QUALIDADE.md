# Rubrica de qualidade — Torre Eterna

Nota-alvo do projeto: **≥ 95/100**.

**Esta rubrica já mentiu, e a correção está aqui.** A versão anterior abria
dizendo que "cada critério tem um teste objetivo". Um crítico independente
mostrou que isso era falso para 59 dos 100 pontos, e que a frase emprestava a
credibilidade dos critérios que rodam de verdade aos que só pedem opinião. Pior:
com a régua vaga, dava para "consertar" um portão redefinindo o que ele precisa
provar — e foi exatamente o que aconteceu com o critério 4, cuja condição difícil
virou informativa em vez de ser cumprida.

Então a tabela agora tem uma coluna a mais, e ela diz a verdade sobre cada linha:

- **PORTÃO** — um comando decide, e ele imprime `===STATUS===`. Reprovável por
  qualquer pessoa, sem confiar em ninguém.
- **MEDIDA** — um comando produz um número, e um humano compara com a meta. O
  número é reproduzível; a comparação é manual.
- **JUÍZO** — não há comando. É opinião informada, e vale o que vale.

A nota vale contra um commit NOMEADO. Nota sobre alvo móvel não é reproduzível
por "alguém de fora", que é justamente o que esta rubrica promete — e durante o
primeiro painel de juízes entraram quatro commits, três dos cinco "piores
defeitos" foram consertados depois de laudados, e a árvore estava suja na hora
da nota. Isso não pode se repetir sem estar dito.

**A saída crua abaixo foi medida em `2b314d0`**, com a árvore limpa e nada mais
rodando na máquina (ver a observação sobre medir desempenho no `AGENTS.md`).

| # | Critério | Peso | Tipo | Como se verifica | Meta |
|---|---|---:|---|---|---|
| 1 | **Compila e roda** | 6 | PORTÃO | `tools/verificar.gd`, `tools/lint.gd`, `agent_verify.gd` | PASS, zero erro de script |
| 2 | **Testes da simulação** | 10 | PORTÃO | `tools/testes.gd` — sem mocks, roda o jogo real | 100% passando, ≥300 asserções, e nenhum bloco pode sumir em silêncio (há piso) |
| 3 | **Integridade dos dados** | 6 | PORTÃO | `tools/validar_dados.gd` | zero erro |
| 4 | **Desempenho** | 8 | PORTÃO | `tools/perf.gd -- 412` | **p90 de `Jogo.simular()` ≤ 4 ms nas DUAS pernas**: 10 min de jogo real, e 160 inimigos vivos segurados (o teto que `Bal.contagem_onda` sabe criar, mais 25%). O estresse de 412 é publicado como folga e não reprova, porque o jogo não produz essa população |
| 5 | **Balanceamento medido** | 8 | PORTÃO | `tools/sim_balance.gd -- 1.2 auto` (72 min de jogo é o mínimo que julga as três faixas; mais que isso não decide nada a mais) | onda 25 em 4–12 min; onda 50 em 11–30 min; onda 100 em 22–60 min (pisos remedidos — ver abaixo); a onda continua subindo no último terço; o catálogo de melhorias não esvazia |
| 6 | **Profundidade de sistemas** | 8 | PORTÃO | `tools/testes.gd` (grupo Sistemas) contra `data/systems.json` | ≥10 elos declarados e ≥10 sistemas distintos, cada elo com a PROVA no código — arquivo e símbolo. Elo que sumir do código reprova; elo que ninguém declarou não conta |
| 7 | **Volume de conteúdo** | 6 | PORTÃO | `tools/validar_dados.gd` (`MINIMOS`) | ≥20 inimigos, ≥10 chefes, ≥35 melhorias, ≥30 talentos, ≥30 cartas, ≥80 conquistas, ≥10 eras |
| 8 | **Arte** | 8 | JUÍZO | capturas + `tools/perf.gd` para custo | tudo procedural, silhuetas distinguíveis em 0,5 s, 10 eras visualmente distintas, a torre muda com a progressão |
| 9 | **Juice** | 8 | JUÍZO | capturas, e o Portão 8 para erro de motor | tremor, hitstop, câmera lenta, partículas, números legíveis, apresentação de chefe sem colisão |
| 10 | **Áudio** | 6 | MEDIDA | `tools/testes.gd` (grupo Áudio) + leitura | sintetizado, sem assets, cada habilidade com som próprio, todo som do catálogo com quem o toque |
| 11 | **Interface** | 8 | JUÍZO | captura de cada painel, em 1,0 e em 1,25 de escala | 12+ painéis, nada inalcançável, contraste legível, estado vazio tratado |
| 12 | **Acessibilidade** | 5 | MEDIDA | `tools/testes.gd` (grupo Acessibilidade) + painel | tremor e movimento reduzido de fato zerando; contraste ≥4,5:1 conferido por teste; daltonismo medido por separação percebida |
| 13 | **Persistência** | 5 | PORTÃO | `tools/testes.gd` (grupo Save) | autosave, rotação de backup, migração, exportar/importar com checksum, e save ilegível nunca tratado como jogador novo |
| 14 | **Originalidade** | 4 | JUÍZO | leitura das mecânicas | ≥3 mecânicas com torque próprio, e o texto do README não pode vender como inédito o que é convenção do gênero |
| 15 | **Documentação e portões** | 4 | PORTÃO | `tools/testes.gd` (grupo doc) + `.github/workflows/` | os números da documentação batem com a medida real, todo caminho citado existe, e o CI roda os oito portões sem afrouxar nenhum |

Contagem honesta: **61 dos 100 pontos** são decididos por um comando que imprime
PASS/FAIL (critérios 1, 2, 3, 4, 5, 6, 7, 13, 15). **11 pontos** são medida com
comparação manual (10 e 12). **28 pontos** são juízo (8, 9, 11, 14) — e enquanto
forem, a nota deles vale o que vale a pessoa que avalia.

Estes três números são somados da própria tabela acima pelo grupo `doc` da
suíte, e a soma tem que fechar em 100. Eles já estiveram errados — diziam
59/11/30 num documento cuja tese é honestidade — e a aritmética de um documento
sobre honestidade é exatamente o tipo de coisa que ninguém confere duas vezes.

Quando esta rubrica foi reescrita, o critério 6 ainda era juízo. Ele virou
portão porque `data/systems.json` passou a declarar cada elo com a prova, e
escrever essa lista já achou três provas erradas — que é exatamente o serviço
que um portão presta e a prosa não.

## Sobre medir FPS neste ambiente

Um crítico ligou o contador de FPS do próprio jogo sob Xvfb e mediu 35 fps com
24 inimigos e 39 fps com 1 — quase o mesmo número com carga muito diferente. A
observação está certa e a conclusão precisa da peça que falta: o ambiente não
tem GPU. O Godot cai no **llvmpipe**, o rasterizador por software do Mesa, que
desenha cada pixel na CPU. Custo praticamente fixo com a população é a
assinatura de estar limitado por preenchimento de tela, não pela simulação.

Por isso o contrato de desempenho deste projeto é o **custo do passo de
simulação**, que não depende de GPU e é medido pelo critério 4 nas duas pernas.
FPS medido sob llvmpipe não diz nada sobre a máquina de quem joga — nem a favor
nem contra. Quem quiser um número de FPS honesto precisa rodar numa máquina com
GPU de verdade; aqui, o que dá para afirmar é quanto custa a simulação.

## O que derruba a nota na hora

- Um portão desativado para "fazer passar".
- Um número mágico no código de simulação em vez de `Bal`.
- Uma string visível ao jogador escrita direto no código em vez de `Txt.t()`.
  Cobrado pelo linter desde que ele passou a procurar texto em português solto,
  e não só chave inexistente — a regra antiga não via essa classe, e por ela
  passaram onze frases que apareciam em português no jogo em inglês.
- Emoji em texto de interface (a fonte não tem glifo — vira retângulo). O linter
  pergunta à fonte, em `scripts/` e `tools/`. Os campos `icone` de `data/*.json`
  guardam emoji e são inertes: nenhum painel os manda para o renderizador, e há
  teste provando isso — se alguém ligar, o teste reprova.
- `.tscn`/`project.godot` editado como texto.
- Uma imagem ou arquivo de som no repositório.
- Acesso a Dicionário sem tipo explícito (não compila, mas o hábito é o risco).
- Um painel que reconstrói a árvore de nós dentro de `atualizar()`.

## Sobre a faixa do critério 5 — segunda recalibração, e por quê

Os pisos foram remedidos uma segunda vez, e a razão tem que ficar escrita
porque mexer em régua é exatamente o que um crítico independente me pegou
fazendo no critério 4.

Os pisos anteriores saíram de medições feitas com um agente que **só comprava
melhoria com ouro**. `comprar_talento`, `comprar_no`, `comprar_reliquia` e
`Saque.equipar` não tinham um único chamador fora de `scripts/ui/`: nenhuma
execução sem tela usava metade dos sistemas de poder do jogo. Aquele número
media um jogador com uma mão amarrada nas costas. Com o agente jogando inteiro,
a mesma build chega à onda 100 em 29m38 em vez de "mais de 30 min" — **o jogo
não ficou mais generoso; a medição é que estava errada**.

E os pisos novos ficam abaixo da medida com folga, de propósito: piso encostado
no número medido faz o portão virar cara ou coroa. Aconteceu — duas execuções
seguidas do mesmo código deram onda 50 em 14m55 e 15m07, uma reprovando e a
outra passando. Por isso o simulador agora roda com **semente fixa**
(`SEMENTE` em `tools/suites/sim_balance.gd`), e todo sorteio da simulação passa
pelo `RngX` do jogo — há regra de linter proibindo `randf()`/`shuffle()` global
dentro de `scripts/sim`. Trocar a semente muda o que o portão mede, então ela é
parte do contrato.

O que o piso protege continua igual: uma mudança que dobre a velocidade de
progressão reprova. Os tetos não foram tocados.

## Sobre a faixa do critério 5 (primeira recalibração)

A faixa original ("onda 25 em 10–20 min; onda 50 em 40–70 min") foi escrita
antes de existir simulador — era um palpite. Medido, o jogo entrega onda 25 em
~8 min e onda 50 em ~19 min.

A faixa foi recalibrada, não afrouxada, e a razão está aqui para poder ser
contestada: o palpite antigo ignorava a **ascensão**. A primeira ascensão fica
disponível na onda 25 e multiplica o ritmo — medir a onda 50 como se o jogador
ainda estivesse na primeira run mede uma coisa que não acontece. Para o gênero,
primeira ascensão em torno de 8 min e onda 50 em ~19 min é ritmo de onboarding
bom; 40–70 min para a onda 50 seria lento pelo padrão atual do gênero.

O que a faixa continua protegendo é o que importa: nada de progresso trivial
(minutos de menos) e nada de parede (o soak de 3 h não pode travar).

## Medições atuais

Saída crua dos portões, colada de execução — nunca de memória.
Motor: **Godot 4.7.2**. O projeto rodava em 4.4.1 até esta coleta — não por
escolha, mas porque era o binário que veio na imagem do container. Subir de
versão pagou sozinho: além de ~15% de folga a mais no p90, expôs um defeito
real no save (ver `scripts/core/save_system.gd`, `_tem_nao_finito`).
Última coleta: depois da segunda rodada de correções da auditoria.

```
$ godot --headless --path . -s res://tools/verificar.gd
===VERIFICAR=== scripts=87 falhas=0 dados_faltando=[]
===STATUS=== PASS

$ godot --headless --path . -s res://tools/lint.gd
===LINT=== arquivos=87 linhas=31147 erros=0 avisos=0
===STATUS=== PASS

$ godot --headless --path . -s res://tools/validar_dados.gd
===VALIDAR-DADOS===
  erros: 0
  avisos: 4
    aviso: cartas/gatilho_cego: multiplicador ZERO anula o atributo (confirme que é intencional)
    aviso: cartas/espelho_enxame: multiplicador ZERO anula o atributo (confirme que é intencional)
    aviso: cartas/espelho_enxame: multiplicador ZERO anula o atributo (confirme que é intencional)
    aviso: cartas/espelho_enxame: multiplicador ZERO anula o atributo (confirme que é intencional)
===STATUS=== PASS

$ godot --headless --path . -s res://tools/testes.gd
===TESTES=== passou=637 falhou=0
===STATUS=== PASS

$ godot --headless --path . -s res://tools/perf.gd -- 412
=== DESEMPENHO ===
projeteis/s: 27.6 | orbes: 10 | elementos ativos: sim
maquina: 39882 us na conta de referencia (39000 esperado) -> fator 1.02x

--- PORTAO: 10 min de jogo real (onda 204 ao fim, automacao ligada) ---
  vivos medios 12 | pico de projeteis 349
  media   1094 | p50   1206 | p90   1957 | p99   2725 | pior   5529  (us)
  523 fps no p90
  normalizado p90: 1914 us  (orcamento 4090 us = 4000 x 1.02)

--- PORTAO 2: 160 inimigos vivos SEGURADOS (teto do jogo + 25%) ---
  vivos medios 181 | pico de projeteis 234
  media   2936 | p50   2771 | p90   3792 | p99   5783 | pior   7996  (us)
  270 fps no p90
  lotacao da grade: 16 na celula mais cheia | 3.9 por celula ocupada | 49 celulas
  nos 10% mais caros vs o resto -> mortes 0.1/0.0 | projeteis 166/144 | vivos 180/182
  normalizado p90: 3708 us  (orcamento 4090 us)

--- FOLGA (nao reprova): 412 vivos, alem do que o jogo cria ---
  vivos medios 443 | pico de projeteis 226
  media   6702 | p50   6506 | p90   8245 | p99  10464 | pior  13152  (us)
  124 fps no p90
  lotacao da grade: 24 na celula mais cheia | 7.7 por celula ocupada | 60 celulas
  nos 10% mais caros vs o resto -> mortes 0.0/0.1 | projeteis 197/163 | vivos 438/445

--- perfil por subsistema a 160 vivos (us/passo, SUBCONJUNTO de simular()) ---
  grade            170 us
  status           297 us
  inimigos         372 us
  torre            327 us
  projeteis       2764 us
  coletaveis        67 us
  habilidades       80 us
  diretor           40 us
  (soma 4117 us; o resto de simular() — eventos, automacao, conquistas,
   missoes, autosave — esta na media acima, nao aqui)
recalculos de atributos: 3668

--- rotinas periodicas (medidas DEPOIS das pernas; ver comentario) ---
  autocompra        743 us por chamada | a cada 0.35s |     35 us/passo amortizado
  conquistas        142 us por chamada | a cada 0.50s |      5 us/passo amortizado
  missoes             5 us por chamada | a cada 0.50s |      0 us/passo amortizado
  auto_habilidade       17 us por chamada | a cada 0.25s |      1 us/passo amortizado
  soma amortizada: 41 us/passo (mas o pico cai TODO num passo so)

--- POR DENTRO de simular(), na perna segurada (us/passo, 600 passos) ---
  recalcular                 10 us
  combo_buffs                 6 us
  mecanicas                  15 us
  subsistemas              3160 us
  eventos                     7 us
  parasitas                  16 us
  automacao                  63 us
  conquistas_missoes         11 us
  autosave                    2 us
  soma: 3290 us/passo (isto SIM cobre simular() inteiro)
  recalculo         556 us por chamada | 0.06 por passo |     33 us/passo
===STATUS=== PASS

$ godot --headless --path . -s res://tools/sim_balance.gd -- 1.2 auto
=== MARCOS (tempo para chegar) ===
  onda   10 -> 3m 03s
  onda   25 -> 7m 51s
  onda   50 -> 15m 44s
  onda   75 -> 23m 00s
  onda  100 -> 30m 29s
  onda  150 -> 44m 21s
  onda  200 -> 57m 05s

=== RESUMO ===
onda maxima: 262
mortes: 0 | inimigos mortos: 9859 | chefes: 26
ouro total: 7,51e45 | dano max: 3,48e39
cartas: 167 | conquistas: 44
fragmentos se ascender agora: 12,3 T
pico de entidades: 25 inimigos, 264 projeteis
desempenho: 109219 ms para 259200 passos (421.37 us/passo, 40x tempo real)
recalculos de atributos: 10683
melhorias no teto: 7 de 33 com teto (onda 262)
===STATUS=== PASS

$ godot --headless --path . -s res://tools/soak.gd
=== PICOS ===
inimigos 34 · projeteis 52 · coletaveis 62 · buffs 4 · inventario 65
onda maxima 55 · ascensoes 7 · checagens 720

=== SOAK === falhas=0
===STATUS=== PASS

$ godot --headless --path . -s res://agent_verify.gd
STATUS: PASS   (3418 ms)
```

### Números do projeto

| | |
|---|---:|
| Scripts GDScript | 87 |
| Linhas de código | 27.155 |
| Testes da simulação | 637 |
| Chaves de interface PT/EN | 1.058 |
| Textos de conteúdo PT/EN | 1.286 |
| Imagens no repositório | 1 (`icon.svg`, o ícone do projeto — nenhuma no jogo) |
| Arquivos de som no repositório | 0 |
