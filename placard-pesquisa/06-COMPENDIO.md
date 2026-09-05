# O COMPÊNDIO — especificação de implementação

Rodada 5 · CRUZ · Godot 4.7.2 · base lógica 1280×720 (paisagem) e 720×1280 (retrato)

> **Antes de tudo, o que eu li.** `DECISOES.md` inteiro, `02-NUCLEO-POLIDO.md`,
> `sonda/nucleo.gd`, `sonda/mesa.gd`, `sonda/mesa2.gd` (fórmulas reais de pontuação, pulso e
> colheita final) e as §9, §9.1, §9.2, §15.4 do `PROMPT-JOGO-DE-CARTAS.md` (wireframe da
> partida, tabela de controles, matriz de legibilidade).
>
> **Três coisas que essa leitura mudou nesta proposta, e que uma proposta escrita de memória
> teria errado:**
>
> 1. **A tabela de mãos já está permanente na tela em paisagem.** Região
>    `Receituário 0,64,300,532`, com as 11 categorias no nível atual da run, colapsável pela
>    tecla `R`. Um Compêndio que abra na tabela de mãos em paisagem é uma segunda cópia de um
>    painel que o jogador já está olhando. **Em retrato ela não existe** (o layout de
>    720×1280 não tem a coluna esquerda). Logo: a consulta nº 1 do Compêndio é uma consulta
>    **de retrato**, e em paisagem a consulta nº 1 é outra (§3).
> 2. **`receituario` já é uma ação de input e `R` já está ocupado.** Também já estão ocupados
>    `1`–`6`, setas/`WASD`, `Enter`/`Espaço`, `Shift`, `X`, `Ctrl+Z`, `F`, `T`, `Esc`, `Tab`;
>    e no gamepad LB/RB, D-pad, stick esq., A, Y, X, LT+B, clique do stick dir., RT, Start.
>    O atalho do Compêndio tem de sair do que sobrou (§1).
> 3. **`CRUZ` é proibida como rótulo** pela §12 do documento ("nunca em botão, menu ou
>    tooltip; só estampa de clímax"). Nenhuma aba, nenhum botão e nenhum tooltip do Compêndio
>    pode se chamar CRUZ. A escada aparece como **DUPLA · TRIPLA · CRUZ TOTAL**.

---

## 0. A tese: por que manuais viram cemitério, e o que fazemos diferente

Um manual dentro do jogo morre por três causas, e as três têm conserto de engenharia:

| Causa da morte | O conserto aqui |
|---|---|
| **Ele tira o jogador do jogo.** Troca de cena, escurece tudo, perde a carta selecionada. Abrir custa o raciocínio, então ninguém abre. | O Compêndio é uma **folha lateral**, não uma tela. Não troca de cena, não pausa, **não limpa a seleção**, e em paisagem **deixa a grade inteira visível e clicável** (§2). |
| **Ele obriga a procurar.** O jogador tem uma dúvida específica e recebe um índice de 40 verbetes. | Ele **abre já na resposta**: escada de contexto determinística de 6 degraus (§4), e qualquer elemento da tela é um link para o seu próprio verbete (§4.2). |
| **Ele só serve uma vez.** Depois de aprender as regras, o botão vira decoração e some da consciência do jogador. | O segundo uso é **A CONTA**, o extrato do último evento — e ela é relevante em **75,8% dos turnos** (medido), não em 3 turnos da run inteira (§9). |

**Critério que reprova este recurso**, escrito antes de implementar, no espírito do projeto:
se a mediana de tempo aberto for **< 1,5 s com a aba não trocada**, ele está sendo aberto por
acidente; se **> 25% das aberturas terminarem numa aba diferente da aba de entrada**, a escada
de contexto do §4 está errada e o número diz qual degrau tirar. A instrumentação está no §10.

---

## 1. ONDE FICA O BOTÃO, E O QUE O ABRE

### 1.1 Nome

| Onde | Texto |
|---|---|
| Rótulo visível / tooltip / leitor de tela | **REGRAS** |
| Nome no código, na cena e no save | `compendio` / `cenas/compendio.tscn` |

Isto atende o critério (b) do usuário — *nomes autoexplicativos e diretos* — aplicado ao
próprio recurso. "Compêndio" é bonito e não é autoexplicativo; um jogador com uma dúvida
procura **REGRAS**. O nome poético fica no código, onde só nós lemos.

### 1.2 Ícone

`scripts/ui/icone.gd`, grade 24×24, traço 2 px, `PackedVector2Array` estática, legível a 16 px
(mesma regra dos outros 32 ícones): **uma mini-grade 3×3 com um `?` ocupando a casa central.**
Ela cita o logotipo (duas cartas cruzes) sem repeti-lo, e diz "grade + dúvida" em um glifo.
Em 16 px descarta as linhas da grade e sobra só o `?` dentro de um quadrado — igual à regra
já escrita para o `icone.png`.

### 1.3 Paisagem — 1280×720

Encaixe no HUD superior (`0,0,1280,64`), imediatamente à esquerda da pausa, respeitando o
gap 8 e a margem 8 já usados no resto do HUD:

```
| ...  $12   POSIC. 8/19   DESCARTES 1/3   ●●○ |  [ ? ]  [ ⏸ ]  |
                                                 ^        ^
                                       1168,8,48,48   1224,8,48,48
```

| Elemento | x, y, w, h |
|---|---|
| **Botão REGRAS** | **1168, 8, 48, 48** |
| Pausa (já existente) | 1224, 8, 48, 48 |

48×48 lógicos é o padrão do HUD (a pausa já é 48) e passa o mínimo de toque de 44×44 da §9.
Não é alvo primário — os alvos primários (casa, carta, botão de ação) continuam ≥ 64.

### 1.4 Retrato — 720×1280 lógicos, exibidos em 360×800

**A conversão importa e é onde quase toda especificação de retrato erra:** a base lógica é
720×1280 e a tela é 360×800, então **2 px lógicos = 1 px de tela**. Um botão de 48 lógicos
vira 24 px de tela — **metade do mínimo de toque**. Em retrato o botão tem de ser **96×96
lógicos** para valer os 48 de tela.

Segundo erro comum: pôr o botão no topo. O HUD de retrato fica em `y = 0..150`, a 640 px
lógicos do polegar num aparelho de 1280 lógicos de altura. O jogador joga com uma mão; a mão
de cartas está no rodapé (`720×210` em `y = 1070`). **O botão vai para a zona do polegar.**

| Elemento | x, y, w, h (lógico) | Equivalente em 360×800 |
|---|---|---|
| **Botão REGRAS** | **604, 952, 96, 96** | 302, 476, 48, 48 |
| (folga até a mão em `y=1070`) | 22 px lógicos | 11 px |

Ele fica ancorado ao canto inferior-direito (`anchor_right = anchor_bottom = 1.0`,
`offset` negativo), **não** em posição absoluta — a §9 proíbe pixel absoluto no `.tscn`.

**Regra de ocultação:** enquanto a **gaveta de prévia** estiver subida (ela sobe 340 px no
toque-e-segure), o botão some com fade de 0,08 s e volta ao fechar a gaveta. Dois alvos
sobrepostos no polegar é friccão, e a gaveta é a resposta a uma pergunta parecida.

### 1.5 Atalhos

| Ação | Teclado | Gamepad | Toque |
|---|---|---|---|
| **Abrir/fechar REGRAS** | **`?`** (`Shift`+`/`) · alias **`F1`** · alias **`H`** | **Select / Back / View** | botão do §1.3 / §1.4 |
| **Abrir REGRAS já no verbete deste elemento** | `Shift`+clique-direito, ou `Alt`+`Enter` com o elemento focado | **`Y` segurado 0,4 s** sobre o elemento focado | **toque longo 0,4 s** |
| Fechar | `Esc` · `?` de novo | B · Select de novo | tocar fora / arrastar para baixo |

`?`, `F1` e `H` são as três teclas que sobraram e as três que jogador procura. **Select/Back**
é o único botão livre do gamepad e é semanticamente o botão de "info" em praticamente todo
jogo de console. Nova ação em `project.godot`: **`regras`** (ao lado de `receituario`,
`pausa`, `baralho_aberto`), remapeável em `controles.tscn` como todas as outras.

**Conflito resolvido de propósito:** o toque longo de 0,2 s já abre a *prévia detalhada*. O do
Compêndio é **0,4 s no mesmo gesto**, com um degrau visível: aos 0,2 s a prévia aparece; se o
dedo continuar até 0,4 s, a prévia recolhe e o Compêndio abre no verbete daquele elemento,
com um pulso de 40 ms de háptica marcando a passagem do degrau. Um gesto, dois níveis de
profundidade, zero botão novo na tela.

---

## 2. COMO ELE ABRE SEM QUEBRAR O RACIOCÍNIO

O cenário que rege este parágrafo: o jogador está com a carta 3 selecionada, o cursor na casa
C3, contando se fecha a linha ou não. **Abrir REGRAS não pode custar nada disso.**

### 2.1 Sete garantias, cada uma com a linha de código que a cumpre

| Garantia | Implementação |
|---|---|
| **Não troca de cena.** | `CanvasLayer` de camada **70** instanciado dentro de `partida.tscn`. **Nunca** passa por `Navegacao.ir()`. `pausa` fica na 80 e continua por cima. |
| **Não pausa o jogo.** | O jogo é por turnos: não há nada rodando para pausar. `process_mode = PROCESS_MODE_INHERIT`. Uma animação de colheita em curso **continua e termina** por trás da folha. |
| **Não perde a seleção da carta.** | O Compêndio **não toca** em `Partida.carta_selecionada` nem em `Partida.cursor_grade`. Asserção em `fluxo_testes.gd`: abrir e fechar com carta selecionada deixa os dois valores idênticos. |
| **Não perde o foco.** | Ao abrir: `_foco_anterior = get_viewport().gui_get_focus_owner()`. Ao fechar: `if is_instance_valid(_foco_anterior): _foco_anterior.grab_focus()`. |
| **Não esconde o tabuleiro.** | Em paisagem a folha ocupa **760, 0, 520, 720** — a grade (`414..866`) fica visível; só os 106 px de sobreposição sobre a borda direita da grade são compensados deslizando a grade **80 px para a esquerda** com um `Tween` de 0,12 s (`x: 414 → 334`), o que também revela o Receituário inteiro. Nada é coberto. Ao fechar, volta. |
| **Não é modal.** | Com a folha aberta em paisagem, **grade e mão continuam clicáveis**. Selecionar outra carta ou mover o cursor **atualiza a faixa AGORA ao vivo** (§4). O Compêndio vira um segundo monitor, não uma parede. |
| **Não custa turno.** | Abrir, ler e fechar não consome posicionamento, descarte, tempo nem nada. Funciona também na `loja`, no `mapa`, no `postmortem` e na `pausa` — **um botão, um atalho, o jogo inteiro.** |

### 2.2 Retrato é diferente, e por quê

Em 720×1280 não há 520 px de sobra na horizontal. A folha vira **folha de baixo**:
ocupa `0, 486, 720, 794` (62% da altura), deixando visíveis o HUD e as **três primeiras
linhas da grade**. Arrastável: puxar para cima chega a 100% de altura; puxar para baixo fecha.
Nesse modo a grade **não** é clicável (o dedo está na folha), então a faixa AGORA congela no
estado em que estava ao abrir e ganha um carimbo `estado de quando você abriu` — mentir sobre
o estado ao vivo seria pior que congelar.

### 2.3 Animação

Abrir: `x: 1280 → 760` (paisagem) / `y: 1280 → 486` (retrato), `Tween` 0,12 s,
`TRANS_CUBIC`/`EASE_OUT` — o mesmo tempo do fade de navegação, para o jogo ter um só ritmo.
Fundo: **não escurece a grade**; escurece só as bordas em 25%, com `draw_rect` de um retângulo
com `Color(0,0,0,0.25)` que exclui o retângulo da grade. Com **"reduzir movimento"** ligado,
o `Tween` vira corte seco.

---

## 3. A ORGANIZAÇÃO — quais abas, em que ordem, e por quê

### 3.1 As 4 dúvidas que respondem por ~90% das consultas

Derivadas da **frequência com que cada situação ocorre no jogo medido**, não de opinião:

| # | A dúvida, na voz do jogador | Frequência medida da situação que a gera |
|---|---|---|
| **1** | *"Ganhei pontos e não fechei nada. Por quê?"* | O **PULSO** paga em 3/5 e 4/5 e é o que levou os turnos pagos de 14,3% para 65,1%. Ele é a **maior parte** dos 75,8% de turnos que pagam algo — e é a única recompensa do jogo que acontece **sem nada visível sair da mesa**. É a dúvida mais frequente do jogo, com folga. |
| **2** | *"Quanto vale essa mão?"* | Toda prévia ambígua. **Em paisagem o Receituário já responde** (0,64,300,532); **em retrato não existe resposta na tela**. |
| **3** | *"Se eu colher, o que eu perco?"* | O **DESMANCHE** (§7). Ocorre em 100% das colheitas, e são 1,17 eventos por mesa — raro e caríssimo. É a regra mais difícil do jogo e a habilidade central que **nenhuma bancada conseguiu ensinar** (`DECISOES.md` §7). |
| **4** | *"Essa linha está cheia e não colheu. Bug?"* | A **JANELA DA COLHEITA**. Acontece em toda linha que enche — e é contraintuitiva por construção: a regra que fez a cruz existir (0,000 → 0,831) é a mesma que faz a linha "travar" na tela. Sem explicação, lê-se como defeito. |

As dúvidas 1 e 4 **não existem em nenhum outro jogo de pôquer** — são invenções deste jogo.
São exatamente as que ninguém vai deduzir sozinho.

### 3.2 As abas

Cinco, sempre as mesmas, sempre na mesma ordem, sempre no mesmo lugar. **A ordem não muda com
o contexto** — o contexto muda a *aba de entrada* e a *rolagem*, nunca o mapa (§4.3).

| # | Aba | O que tem dentro | Responde |
|---|---|---|---|
| **1** | **A CONTA** | O extrato do último evento (§9) + a fórmula viva + PULSO + o piso das fichas + **como pontuam as linhas incompletas** (§5.4) + colheita final 50% | dúvida **1** |
| **2** | **MÃOS** | A tabela das 11 categorias com os valores reais da run (§5) | dúvida **2** |
| **3** | **A MESA** | Geometria: 12 linhas vivas, diagonais a 60%, **o DESMANCHE** com o diagrama (§7), a **JANELA**, e a escada **DUPLA · TRIPLA · CRUZ TOTAL** | dúvidas **3** e **4** |
| **4** | **PEÇAS** | TEAR, AVESSO, e os selos/relíquias/ofícios **desta run**; abaixo, o que ainda não foi encontrado, em silhueta (§6) | — |
| **5** | **ATALHOS** | Tabela de controles + os **3 níveis de Assistência**, ligáveis dali mesmo | — |

**Por que A CONTA vem antes de MÃOS**, contrariando o instinto: em paisagem a tabela de mãos
já está na tela o tempo todo, então quem abre o Compêndio em paisagem **não está perguntando
quanto vale uma trinca** — está perguntando de onde vieram aqueles pontos. E em retrato, quem
quer a tabela chega nela pela faixa AGORA (§4.1) ou por um toque, sem custo. A ordem é a
ordem da pergunta que sobra depois que a tela já respondeu o que sabia responder.

**Por que não existe aba "TUTORIAL" nem "COMO JOGAR":** o tutorial de 60 s já é obrigatório na
primeira execução e refazível em Opções → Jogo. Duplicá-lo aqui seria o cemitério clássico.
O que existe é um item de **uma linha** no rodapé da folha: `refazer o tutorial de 60 s →`.

### 3.3 Busca

Campo de 1 linha no topo da folha, `placeholder: "procurar regra, mão ou peça"`.
Não é um buscador de texto livre: é **filtro sobre uma lista fixa de verbetes** (≈ 60), por
prefixo e por **apelido** — `tabela` acha MÃOS, `coringa` acha AVESSO, `multiplicador` acha
TEAR, `sumiu` e `perdi` acham DESMANCHE, `travou` e `não colheu` acham JANELA, `60%` acha
DIAGONAIS. Os apelidos são o mecanismo real: **o jogador procura com a palavra errada**, e a
tabela de apelidos é o que transforma a palavra errada em resposta certa. Vive em
`traducoes/textos.csv` como qualquer outra string, coluna `apelidos` separada por `|`.

### 3.4 Wireframe — paisagem, 1280×720

```
 grade deslizada para x=334          folha: 760,0,520,720
┌──────────────┬───────────────────┬─────────────────────────────────────────┐
│ Receituário  │   G R A D E       │  REGRAS                            [×]  │ 0
│ (permanente) │   5×5 visível     │  ┌───────────────────────────────────┐  │
│              │   e CLICÁVEL      │  │ 🔍 procurar regra, mão ou peça    │  │ 56
│  ALTA  5 ×1  │                   │  └───────────────────────────────────┘  │
│  PAR  10 ×2  │  ┌─┬─┬─┬─┬─┐      │  ╔═══════════════════════════════════╗  │ 100
│  2PAR 20 ×2  │  ├─┼─┼─┼─┼─┤      │  ║ AGORA                             ║  │
│  TRIN 30 ×3  │  ├─┼─█─┼─┤ │ ←C3  │  ║ Linha 3 está MADURA.              ║  │
│  SEQ  30 ×4  │  ├─┼─┼─┼─┼─┤      │  ║ Colhe no seu próximo             ║  │
│  COR  35 ×4  │  └─┴─┴─┴─┴─┘      │  ║ posicionamento: Trinca, 603 pts.  ║  │
│  FULL 40 ×4  │                   │  ║ Ela leva 1 carta de cada coluna.  ║  │
│  QUAD 60 ×7  │  rótulos 4/5 …    │  ║        [ver o que sai ▸]          ║  │ 236
│  SQCR100 ×8  │                   │  ╚═══════════════════════════════════╝  │
│  REAL 120×10 │                   │  ┌─────┬─────┬──────┬──────┬────────┐  │ 260
│  QUINA ▒▒▒▒  │                   │  │CONTA│MÃOS │MESA●│PEÇAS │ATALHOS │  │ 300
│              │                   │  ├─────┴─────┴──────┴──────┴────────┤  │
│ mult da run  │                   │  │                                   │  │
│   31 / 48    │                   │  │   (conteúdo da aba, rolável,      │  │
│              │  ┌────┐┌────┐     │  │    foco por teclado/gamepad)      │  │
│ Baralho      │  │mão ││mão │     │  │                                   │  │
│ Aberto ♠7♥5… │  └────┘└────┘     │  │                                   │  │
│              │                   │  ├───────────────────────────────────┤  │
│              │                   │  │ refazer o tutorial de 60 s     ▸ │  │ 684
└──────────────┴───────────────────┴─────────────────────────────────────────┘ 720
0             300                 760                                     1280
```

O ponto do desenho: **a grade continua ali, inteira, e continua clicável.** Clicar numa carta
da mão com a folha aberta muda a faixa AGORA sem fechar nada.

### 3.5 Wireframe — retrato, 720×1280 lógicos (360×800 de tela)

```
┌──────────────────────────────────────┐ 0
│ HUD: PONTOS · meta · TEAR ×5   [⏸]  │
├──────────────────────────────────────┤ 150
│  ┌───┬───┬───┬───┬───┐               │
│  │   │   │   │   │   │  ← 3 primeiras│
│  ├───┼───┼───┼───┼───┤    linhas da  │
│  │   │ █ │   │   │   │    grade      │
│  ├───┼───┼───┼───┼───┤    seguem     │
│  │   │   │   │   │   │    visíveis   │
├══════════════════════════════════════┤ 486  ← alça: arrasta ↑ 100% / ↓ fecha
│  ▂▂▂▂▂▂  (alça 120×8)                │
│  REGRAS                         [×]  │
│  ┌────────────────────────────────┐  │
│  │ 🔍 procurar                     │  │
│  └────────────────────────────────┘  │
│  ╔════════════════════════════════╗  │
│  ║ AGORA · você segura ♥K         ║  │
│  ║ linha 3 → COR  35+48 = 83      ║  │
│  ║ coluna C → PAR  10+31 = 41     ║  │
│  ╚════════════════════════════════╝  │
│  ┌─────┬─────┬─────┬─────┬────────┐  │
│  │CONTA│MÃOS●│MESA │PEÇAS│ATALHOS │  │
│  ├─────┴─────┴─────┴─────┴────────┤  │
│  │                                 │  │
│  │  conteúdo rolável               │  │
│  │                                 │  │
└──┴─────────────────────────────────┴──┘ 1280
```

---

## 4. CONTEXTUAL — o Compêndio abre já na resposta

### 4.1 A faixa AGORA

Uma faixa de altura variável (mín. 96 lógicos), **acima das abas**, presente em todas elas.
Ela não é uma aba: é a resposta calculada para o estado exato da mesa neste instante.
Tem no máximo **3 linhas de texto e 1 botão**, e o botão sempre leva ao verbete completo.

### 4.2 A escada de contexto — determinística, 6 degraus, primeiro que casar vence

```gdscript
func _entrada_contextual(p: Partida, origem: Control) -> Entrada:
    # 1. abriu A PARTIR de um elemento (toque longo 0,4 s / Shift+dir. / Y segurado)
    if origem != null and origem.has_meta("verbete"):
        return Entrada.new(origem.get_meta("verbete"))          # o elemento sempre vence

    # 2. há linha MADURA esperando (a Janela) — maior aposta em jogo, menos entendida
    var mad := p.mesa.linhas_maduras()
    if not mad.is_empty():
        return Entrada.new("mesa/janela", {"linhas": mad, "com_minha_mesa": true})

    # 3. há carta selecionada na mão
    if p.carta_selecionada >= 0:
        if p.mesa.eh_avesso(p.carta_selecionada):
            return Entrada.new("pecas/avesso")
        return Entrada.new("maos", {"destacar": p.previa_categorias()})  # linha E coluna

    # 4. algo pontuou nos últimos 2 posicionamentos
    if p.mesa.turnos_desde_ultimo_ganho() <= 2:
        return Entrada.new("conta/extrato", {"evento": p.mesa.ultimo_evento()})

    # 5. primeira mesa da run, primeiros 3 posicionamentos
    if p.run.rodada == 1 and p.mesa.posic_usados < 3:
        return Entrada.new("mesa/duas_maos")     # "cada carta pontua duas vezes"

    # 6. nada a dizer
    return Entrada.new("conta")
```

**Por que a MADURA vem antes da carta selecionada** (degrau 2 antes do 3): a linha madura é um
estado com **prazo** — ela colhe no próximo posicionamento, e o jogador que não entendeu isso
está prestes a tomar uma decisão irreversível sem saber o preço. A carta selecionada é uma
pergunta reversível: ele pode simplesmente selecionar outra. **O degrau mais urgente ganha do
degrau mais frequente.**

**Por que o degrau 1 é absoluto:** se o jogador apontou para uma coisa, ele já disse o que
quer. Nenhuma heurística nossa é mais informada que o dedo dele.

### 4.3 A regra que impede o contexto de virar caos

> **A entrada contextual é sempre uma aba + uma rolagem + um destaque. Nunca uma interface
> diferente.**

As 5 abas ficam sempre nos mesmos 5 lugares, com as mesmas larguras, na mesma ordem. Contexto
que rearranja o mapa destrói a memória muscular e obriga o jogador a reler a tela toda vez —
que é exatamente o custo que estamos tentando eliminar. O que o contexto faz é: **acender a
aba certa, rolar até a linha certa, e pintar um halo de 2 px nela.**

### 4.4 Tudo é link (`meta("verbete")`)

Todo `Control` do jogo carrega `set_meta("verbete", "<id>")`, e o toque longo de 0,4 s /
`Shift`+clique-direito / `Y` segurado abre o Compêndio ali. Mapa mínimo:

| Elemento | verbete |
|---|---|
| Carta na mão | `maos` (destaque na categoria da prévia) |
| Carta na mão que é Avesso | `pecas/avesso` |
| Casa da grade (vazia) | `mesa/duas_maos` |
| Casa da grade nas 9 diagonais | `mesa/diagonais` |
| Rótulo de linha em 3/5 ou 4/5 | `conta/pulso` |
| Rótulo de linha em 5/5 (madura) | `mesa/janela` |
| `TEAR ×N` no HUD | `pecas/tear` |
| `POSIC. 8/19` | `mesa/orcamento` |
| Barra de meta / Mínimo Dourado | `conta/meta` |
| Selo numa casa | `pecas/selo/<id>` |
| Qualquer NOME PRÓPRIO em qualquer texto do jogo | o verbete daquele nome |

A última linha é a que resolve o item **(b) do usuário** sem alongar nome nenhum: **TEAR,
PULSO, AVESSO, DESMANCHE, JANELA — todo nome próprio, em qualquer texto de qualquer tela
(loja, mapa, descrição de selo, estampa de colheita), é tocável e abre a sua definição.**
O nome pode ser curto e evocativo porque a definição está sempre a um toque dele. É assim
que se tem nome bonito **e** nome autoexplicativo ao mesmo tempo.

---

## 5. A TABELA DE MÃOS — a consulta que tem de ser lida de relance

### 5.1 Os valores reais, lidos do código (`nucleo.gd`)

```
CAT_BASE := [5, 10, 20, 30, 30, 35, 40, 60, 100, 120, 140]
CAT_MULT := [1,  2,  2,  3,  4,  4,  4,  7,   8,  10,  12]
```

Fichas da carta (`fichas_carta`): **Ás = 11 · 2 a 9 = o próprio valor · 10, J, Q, K = 10**.
Nível de mão: `base += max(round(base × 0,35), 8)` e `mult += 1` por nível
(`mesa.gd: base_de/mult_de`).

### 5.2 A linha da tabela

Cinco campos, sempre nesta ordem, alinhados em colunas fixas. O campo que o jogador de
verdade quer é o **último**, e por isso ele é o maior e o único em dourado:

```
 ✓×3  TRINCA        três iguais        40 + 27 ×  9  =  603
 └─┬  └────┬──────  └──────┬─────────  └───┬──┘  └┬┘    └─┬─┘
   │       │               │               │      │       │
   │       │               │               │      │   PONTOS AGORA, no seu Tear,
   │       │               │               │      │   com fichas médias da sua mesa
   │       │               │               │      └── mult da mão + TEAR (4 + 5)
   │       │               │               └── base do seu nível + fichas das 5 cartas
   │       │               └── a definição em 3 palavras
   │       └── o nome
   └── já fez nesta run, 3 vezes
```

**O último campo é a invenção que faz a tabela ser lida de relance.** Nenhuma tabela de
pôquer de outro jogo mostra "quanto isto me daria agora". Aqui ela mostra, porque o Tear e o
nível de mão são estado vivo da run — e uma tabela que mostra `30 ×3` quando o Tear está em 5
está **mentindo por omissão** sobre o número que interessa.

- **Fichas usadas na conta:** as fichas médias reais **da sua mesa atual** (soma das fichas
  das cartas na grade e na mão ÷ nº de cartas × 5), não uma constante. Marcador `≈` antes do
  total, para não prometer exatidão. Recalculado **só** quando `pontos`, `tear`, `niveis_mao`
  ou a mão mudam — nunca por quadro (mesma disciplina do Mínimo Dourado, §9.1).
- **Ordenação:** a ordem normativa da §5.1, de cima para baixo, **fixa**. Ordenar por "pontos
  agora" mudaria a ordem entre mesas e destruiria a memória de posição.
- **Destaque:** a categoria da prévia da linha acende em contorno; a da coluna, em
  preenchimento fraco. **As duas ao mesmo tempo**, porque a frase que dá nome ao jogo é
  "cada carta pontua duas vezes" e a tabela é o lugar mais barato de repetir isso.

### 5.3 "Já consegui nesta run"

| Estado | Marca | Fonte |
|---|---|---|
| Feita nesta run | `✓×N` em dourado, N = vezes | **novo campo no save:** `run.maos_feitas: Array[int]` (11 posições) |
| Nunca nesta run, mas já na vida | `✓` cinza vazado | `perfil.maos_feitas` — **já existe**, é o que dispara o colapso do Receituário às 8 categorias (§9.2) |
| Nunca vista | silhueta (§6) | ausência nas duas |

Custo de implementação: **um array de 11 inteiros no bloco `run` do save**, incrementado em
`posicionar()` e em `colheita_final()`. O array de perfil já existe.

### 5.4 A resposta ao item (d) do usuário — **linhas que não formam mão completa**

Esta é uma pergunta que o jogo responde em três lugares diferentes e em nenhum deles com
clareza. No Compêndio ela é **um bloco só, na aba A CONTA**, com os três casos e as três
fórmulas reais lidas de `mesa.gd` e `mesa2.gd`:

```
LINHA INCOMPLETA — os três jeitos de ela pagar

1) PULSO, ao chegar a 3/5 e a 4/5              (mesa2.gd: valor_pulso)
   (base da categoria parcial + fichas) × (mult + TEAR) × 0,35
   duas vezes por linha, no máximo. Diagonal: × 0,60 por cima.

2) COLHEITA FINAL, ao acabar a mesa            (mesa.gd: colheita_final)
   toda linha com 3 ou 4 cartas paga
   (base parcial + fichas) × (mult + TEAR) × 0,50
   Diagonal: × 0,60 por cima.  Linha com 0, 1 ou 2 cartas paga ZERO.

3) NUNCA de outro jeito. Linha incompleta não colhe e não some do tabuleiro.

O QUE CONTA NUMA MÃO PARCIAL                   (nucleo.gd: avaliar_parcial)
   Só o que já está decidido pelos valores: CARTA ALTA, PAR, DOIS PARES,
   TRINCA e QUADRA.
   SEQUÊNCIA, COR, FULL, SEQUÊNCIA DE COR, REAL e QUINA **não valem em linha
   parcial** — 4 cartas do mesmo naipe ainda não são uma Cor, e o jogo não paga
   por promessa. Elas só existem no fechamento em 5/5.

O PISO                                          (mesa.gd: ganho)
   As fichas das 5 cartas entram na conta mesmo quando elas não combinam em nada.
   Cinco cartas soltas ainda são CARTA ALTA (base 5) + as fichas delas.
   NENHUMA COLHEITA VALE ZERO.
```

Esse bloco é o único texto do jogo que responde "por que a minha linha de 4 cartas do mesmo
naipe pagou tão pouco?" — uma pergunta que **vai** ser feita, porque a Cor tem mult 4 e a
expectativa do jogador é de que 4/5 dela valha alguma coisa parecida.

---

## 6. O QUE AINDA NÃO FOI DESBLOQUEADO — silhueta, cadeado, ou nada

**Três estados, e a diferença entre eles é uma só pergunta: o jogador já viu isto?**

| Estado | Quando | Como aparece | Por quê |
|---|---|---|---|
| **CONHECIDO** | já possuiu / já fez / já colheu | tudo visível | — |
| **VISTO** | apareceu na loja, num chefe, na mesa de um inimigo, ou foi **feito por outro jogador do save** — mas nunca foi dele | **silhueta**: nome legível, ícone em preenchimento chapado da cor da raridade, efeito substituído por `— você viu este selo 2× e ainda não o teve —` | Ele **já sabe que existe**. Esconder o nome de algo que ele viu não é anti-spoiler, é fazê-lo achar que perdeu a memória. A silhueta transforma "eu vi aquilo" em "eu quero aquilo". |
| **DESCONHECIDO** | nunca cruzou o caminho dele | **nada individual** — só um contador no rodapé da seção: `+ 14 peças que você ainda não encontrou` | Um cadeado por item é uma lista de tudo que falta: isso é **spoiler de quantidade e de estrutura**, e vira lista de tarefas. Um número só é curiosidade. |

**Sem cadeados. Nunca.** Um cadeado promete que existe uma chave, e neste jogo não existe: os
itens vêm por sorteio de loja. O ícone de cadeado ensinaria uma mecânica que o jogo não tem.

**A tabela de mãos usa a mesma escada.** `QUINA` (cinco iguais, base 140, mult 12) é
inalcançável com um baralho de 52 e só existe com baralhos/selos que dupliquem cartas: ela
fica em **silhueta permanente** — barra `▒▒▒▒` no lugar dos números e o texto
`existe. você ainda não viu.` — até a primeira vez que o jogador a vir. **É a melhor peça de
curiosidade dirigida do jogo inteiro**, porque está na tabela que ele já olha em todo turno,
na última linha, com o maior número, apagada. Ela faz a pergunta sozinha.

---

## 7. O DESMANCHE — a regra mais difícil, e o diagrama que a ensina

### 7.1 O nome, primeiro

A regra **não tem nome hoje**, e regra sem nome não pode ser procurada, nem tocada, nem citada
por um jogador para outro. Proponho: **DESMANCHE**.

> **DESMANCHE — colher uma linha esvazia as cinco perpendiculares.**

Palavra portuguesa, comum, autoexplicativa, e do mesmo campo semântico do TEAR (tecer /
desmanchar) — o jogo já tem uma metáfora têxtil e ela estava sendo usada pela metade.

### 7.2 Por que texto não ensina isto

"A colheita remove as 5 cartas da linha, e cada uma delas pertencia também a uma coluna" é
uma frase **correta e inútil**. Ela pede que o jogador construa um modelo espacial 5×5 na
cabeça a partir de prosa. Ninguém faz isso no meio de um turno. **Geometria se ensina com
geometria.**

### 7.3 O diagrama — três quadros, desenhados em `_draw`

Control de **440×300** lógicos (paisagem) / **640×420** (retrato), `_draw` puro, sem textura,
sem asset, sem dependência. Loop de 3 quadros, 1,1 s cada, com pausa de 0,4 s no quadro 3.

```
QUADRO 1 — "ela está cheia"          QUADRO 2 — "colhe"        QUADRO 3 — "e o resto cai"

   A  B  C  D  E                      A  B  C  D  E              A  B  C  D  E
  ┌──┬──┬──┬──┬──┐                   ┌──┬──┬──┬──┬──┐           ┌──┬──┬──┬──┬──┐
1 │  │██│  │██│  │                 1 │  │██│  │██│  │         1 │  │██│  │██│  │
  ├──┼──┼──┼──┼──┤                   ├──┼──┼──┼──┼──┤           ├──┼──┼──┼──┼──┤
2 │██│██│  │██│  │                 2 │██│██│  │██│  │         2 │██│██│  │██│  │
  ├══╪══╪══╪══╪══┤ ← linha 3 CHEIA   ├──┼──┼──┼──┼──┤           ├──┼──┼──┼──┼──┤
3 ║██│██│██│██│██║  (5/5, dourada)  3 ║↑↑│↑↑│↑↑│↑↑│↑↑║        3 │· │· │· │· │· │ ← VAZIA
  ├══╪══╪══╪══╪══┤                   ├──┼──┼──┼──┼──┤           ├──┼──┼──┼──┼──┤
4 │  │██│  │██│  │                 4 │  │██│  │██│  │         4 │  │██│  │██│  │
  ├──┼──┼──┼──┼──┤                   ├──┼──┼──┼──┼──┤           ├──┼──┼──┼──┼──┤
5 │██│  │  │██│  │                 5 │██│  │  │██│  │         5 │██│  │  │██│  │
  └──┴──┴──┴──┴──┘                   └──┴──┴──┴──┴──┘           └──┴──┴──┴──┴──┘
   3  4  1  5  1  ← frações das       (as 5 cartas sobem,        2  3  0  4  0
  /5 /5 /5 /5 /5    colunas            fio dourado saindo        ▼1 ▼1 ▼1 ▼1 ▼1
                                       de cada coluna)           ↑ setas VERMELHAS
                                                                   + hachura na casa
   TRINCA · 603 pts                                             "603 ganhos.
                                                                 5 colunas um passo atrás.
                                                                 A coluna D era 5/5.
                                                                 Agora é 4/5."
```

**As três decisões visuais que fazem o diagrama funcionar:**

1. **O número da fração da coluna aparece embaixo de cada coluna, nos quadros 1 e 3.** A
   destruição não é vista nas cartas que somem — é vista nos **números que caem**. `3 4 1 5 1`
   virando `2 3 0 4 0` é a regra inteira, sem uma palavra.
2. **A coluna D é 5/5 no quadro 1 de propósito.** O caso didático é a coluna que **estava
   prestes a fechar e não vai mais**. Se todas as colunas estivessem em 1/5, a regra pareceria
   inofensiva — e ela não é.
3. **O quadro 3 fica 0,4 s a mais.** É o quadro que ensina; os outros dois são a preparação.

### 7.4 O botão que torna o diagrama irrespondível: `[ com a minha mesa ]`

Um `CheckButton` embaixo do diagrama. Ligado, os mesmos três quadros são desenhados
**com o estado real da grade do jogador e com a linha madura de verdade** — as frações
verdadeiras, as cartas verdadeiras, o número de pontos verdadeiro que `Mesa.simular()`
devolve. Deixa de ser uma ilustração e vira **a previsão do próximo posicionamento dele**.

É a mesma informação da **Assistência nível 2** (`DECISOES.md` §3b: "fecha a linha 3 por 340
E derruba a coluna C de 4/5 para 3/5"), que é o **único mecanismo já encontrado que ensina a
recusa** — agora em forma de geometria em vez de frase. As duas formas juntas, no mesmo dado,
por dois canais diferentes. Quando a escada de contexto entra pelo degrau 2 (linha madura),
este botão já vem **ligado**.

### 7.5 Esqueleto do `_draw` (GDScript, Godot 4)

```gdscript
extends Control
class_name DiagramaDesmanche

const CEL := 40.0
const GAP := 4.0
const OURO   := Color("#D9A441")
const VERM   := Color("#C0504D")
const PAPEL  := Color("#E8E2D4")
const FUNDO  := Color("#1A2026")

var quadro := 0                   # 0, 1, 2
var t := 0.0                      # 0..1 dentro do quadro
var minha_mesa := false
var _grade: PackedInt32Array      # 25, -1 = vazia
var _linha_alvo := 2              # índice 0..11 da linha que colhe
var _frac_antes := PackedInt32Array()
var _frac_depois := PackedInt32Array()
var _pts := 0
var _cat := ""

func _ready() -> void:
    custom_minimum_size = Vector2(440, 300)
    _montar(false)
    var tw := create_tween().set_loops()
    for q in 3:
        tw.tween_method(func(v): quadro = q; t = v; queue_redraw(), \
                        0.0, 1.0, 1.1 if q < 2 else 1.5)

func _montar(real: bool) -> void:
    # real == false -> caso didático fixo (coluna D em 5/5); true -> le de Partida.mesa
    ...

func _pos(col: int, lin: int) -> Vector2:
    return Vector2(col * (CEL + GAP), lin * (CEL + GAP)) + Vector2(24, 8)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), FUNDO)
    var lin_alvo := _linha_alvo          # 0..4 = horizontais
    for c in 25:
        var col := c % 5
        var lin := c / 5
        var r := Rect2(_pos(col, lin), Vector2(CEL, CEL))
        var na_alvo := (lin == lin_alvo)
        var cheia := _grade[c] >= 0

        # QUADRO 3: a linha alvo esta vazia
        if quadro == 2 and na_alvo:
            _casa_vazia(r)
            continue

        if not cheia:
            _casa_vazia(r); continue

        var cor := PAPEL
        var desl := Vector2.ZERO
        if na_alvo:
            cor = OURO
            if quadro == 1:                     # sobe e some
                desl = Vector2(0, -CEL * 1.6 * ease(t, 0.4))
        draw_rect(Rect2(r.position + desl, r.size), cor)
        draw_rect(Rect2(r.position + desl, r.size), FUNDO, false, 1.5)

    # fios dourados saindo de cada coluna, so no quadro 2
    if quadro == 1:
        for col in 5:
            var p0 := _pos(col, lin_alvo) + Vector2(CEL * 0.5, 0)
            draw_line(p0, p0 + Vector2(0, -CEL * 1.8 * t), OURO, 2.0)

    # as fracoes das colunas: a regra inteira mora aqui
    var y := _pos(0, 5).y + 10.0
    var f := (_frac_depois if quadro == 2 else _frac_antes)
    for col in 5:
        var x := _pos(col, 0).x
        var cor_f := VERM if (quadro == 2 and _frac_depois[col] < _frac_antes[col]) else PAPEL
        draw_string(ThemeDB.fallback_font, Vector2(x + 8, y), \
                    "%d/5" % f[col], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cor_f)
        if quadro == 2 and _frac_depois[col] < _frac_antes[col]:
            _seta_baixo(Vector2(x + CEL * 0.5, y + 8), VERM)   # forma, nao so cor
            _hachura(Rect2(_pos(col, lin_alvo), Vector2(CEL, CEL)), VERM)
```

**Notas de acessibilidade embutidas no `_draw`, não coladas depois:**
`_seta_baixo` e `_hachura` existem porque **a queda não pode ser comunicada só por cor** —
com daltonismo ou alto contraste, a seta e a hachura carregam a informação sozinhas.
Com **"reduzir movimento"** ligado, o `Tween` não roda: os três quadros são desenhados
**lado a lado**, estáticos, com `1 · 2 · 3` numerados, na mesma altura.

### 7.6 Onde mais este diagrama aparece

Ele é um `PackedScene` de 6 KB e não depende de nada: **use nos quatro lugares**, o mesmo nó.
(1) Compêndio → A MESA → DESMANCHE. (2) Passo 4 do tutorial ("Colher desmancha o resto" —
hoje só tem animação, e a animação passa). (3) `postmortem`, ao lado do maior evento da mesa.
(4) Assistência nível 2, como o ícone de 40×40 ao lado da frase. **Um diagrama, quatro
contextos** — é assim que uma regra difícil deixa de ser difícil.

---

## 8. ACESSIBILIDADE

| Exigência | Como se cumpre |
|---|---|
| **Sem mouse, teclado** | `Tab` cicla busca → abas → conteúdo → rodapé. `←`/`→` trocam de aba com foco nas abas; `Q`/`E` trocam de aba de qualquer lugar. `↑`/`↓` rolam. `Enter` expande a linha focada. `Esc` fecha e devolve o foco (§2.1). `fluxo_testes.gd` prova ciclo de foco fechado e `grab_focus` inicial na busca. |
| **Sem mouse, gamepad** | LB/RB trocam de aba (**dentro do Compêndio** — fora dele são "escolher carta", e trocar de função com a folha aberta é legítimo porque a mão não está em jogo). D-pad rola. A expande. B fecha. Select fecha. |
| **360×800** | Nada com altura fixa. Toda linha é `HBoxContainer` dentro de `VBoxContainer` com `custom_minimum_size.y = 0`. Abaixo de **420 px lógicos** de largura útil, a tabela de mãos vira **cartões empilhados de 1 coluna** (nome em cima, `base + fichas × mult = pts` embaixo), nunca rolagem horizontal. Alvos ≥ **88 lógicos** = 44 de tela. |
| **Fonte aumentada (+8)** | A folha rola; o conteúdo nunca. Nenhum `Label` com `clip_text`; `autowrap_mode = AUTOWRAP_WORD_SMART` em todo texto corrido. As abas passam de texto para **só ícone** quando a soma das larguras dos 5 rótulos passa de 88% da largura da folha. |
| **Matriz de legibilidade (§15.4)** | `compendio.tscn` entra na matriz obrigatória: **360×800, 720×1280 e 1280×720 × 3 idiomas × escala {100%, 150%} × fonte {+0, +8}**. Duas asserções novas: `compendio_nao_cobre_grade` (em paisagem, o retângulo da folha não intersecta o retângulo da grade deslizada) e `compendio_devolve_foco`. |
| **Alto contraste** | Paleta trocada por tokens do tema; o diagrama do §7 mantém seta + hachura (forma antes de cor). Contraste 7:1. |
| **Leitor de tela** | `DisplayServer.tts_speak` na linha focada, com o texto **já formatado em português** (`"trinca, três iguais, quarenta mais vinte e sete, vezes nove, seiscentos e três pontos"`) — número lido por `Texto.numero_pt()`, não pelo TTS cru. Confirmar `tts_speak` no `--doctool` antes do uso, como manda a §3.2. |
| **Sem cor como único canal** | ✓ dourado vs. ✓ cinza vs. silhueta diferem também em **preenchimento** (cheio / vazado / barra `▒`). |

---

## 9. O SEGUNDO USO — **A CONTA**, o extrato do último evento

Das três opções levantadas (glossário ao toque, histórico da mesa, a conta da última
pontuação), a resposta é **a conta**, e ela absorve as outras duas.

### 9.1 Por que a conta, e não as outras

| Critério | Glossário | Histórico | **A CONTA** |
|---|---|---|---|
| Com que frequência o estado que a torna útil existe? | quando aparece um termo novo — raro depois da rodada 2 | fim de mesa | **75,8% dos turnos pagam algo** (medido) |
| Ela ensina a habilidade central do jogo? | não | não | **sim** — é o único lugar onde o preço perpendicular aparece *depois* do fato |
| Ela some da consciência do jogador? | sim, em ~20 min | sim | **não** — é consultada em toda mesa |

E o glossário não é descartado: ele existe, mas **não como aba** — ele é o §4.4 (todo nome
próprio é tocável). Glossário bom é o que você nunca precisa procurar. O histórico também
não é descartado: é a **lista rolável** dentro de A CONTA (§9.2).

### 9.2 O que A CONTA mostra

```
╔══════════════════════════════════════════════════════════╗
║ A CONTA · último evento · posicionamento 11              ║
╠══════════════════════════════════════════════════════════╣
║  ♥K em C3 fechou DUAS linhas.                            ║
║                                                          ║
║  linha 3     TRINCA     base 40 + fichas 27 = 67         ║
║  coluna C    COR        base 35 + fichas 48 = 83         ║
║                                       ────────           ║
║  mult:  3 (trinca) + 4 (cor) + 5 (TEAR)  =  ×12          ║
║                                                          ║
║      67 × 12  =    804                                   ║
║      83 × 12  =    996                                   ║
║                    ────                                  ║
║                   1.800                                  ║
║                                                          ║
║  ▸ DUPLA — dois multiplicadores somaram.  [o que é ▸]    ║
╠══════════════════════════════════════════════════════════╣
║  E O QUE SAIU DA MESA                                    ║
║      [ diagrama do DESMANCHE, com a sua mesa ]           ║
║  10 cartas colhidas. As 8 perpendiculares recuaram:      ║
║      col. A 3/5→2/5   col. B 4/5→3/5   lin. 1 2/5→1/5 …  ║
║  ▸ 2 cartas prensadas num AVESSO: ♥K / ♠9   [ver ▸]      ║
╠══════════════════════════════════════════════════════════╣
║  ESTA MESA (rolável)                                     ║
║   pos. 11  ●● 1.800   DUPLA · trinca + cor               ║
║   pos.  9  ○     124   pulso · coluna D 4/5              ║
║   pos.  8  ○      61   pulso · linha 2 3/5               ║
║   pos.  6  ●     340   colheita · linha 5 · dois pares   ║
║   …                                                      ║
╚══════════════════════════════════════════════════════════╝
```

**Três coisas que essa tela faz e nenhuma outra tela do jogo faz:**

1. **Mostra a soma dos mults acontecendo** — `3 + 4 + 5 = ×12`. A escada (DUPLA/TRIPLA/CRUZ
   TOTAL) é aritmética invisível durante a animação; aqui ela é a linha do meio, em texto.
2. **Mostra o preço, depois do fato.** A Assistência nível 2 mostra o preço **antes**
   (`derruba a coluna C de 4/5 para 3/5`); A CONTA mostra o mesmo dado **depois**, ao lado
   dos pontos ganhos. Antes + depois é um circuito de feedback fechado — e "ensinar a recusa"
   é o problema aberto que seis bancadas não resolveram (`DECISOES.md` §7).
3. **Nomeia os pulsos.** Os `○` da lista são a resposta visual à dúvida nº 1 (§3.1): o jogador
   vê que os 124 pontos que "vieram do nada" têm nome, linha e motivo.

### 9.3 O que A CONTA **não** é, e por quê

Ela **não é uma alavanca de balanceamento**. Nada aqui muda um número do jogo. Registro isso
explicitamente porque a dívida aberta desta rodada — *planejar deixou de pagar* (planejadora
30,7% × gulosa 36,1%) — **não se conserta com UI**, e o `DECISOES.md` §3 já enterrou a via
econômica em ×4, ×20 e ×100 (com a ressalva, correta, de que aquele teste precisa ser refeito
agora que a cruz ocorre 0,831/mesa). **Não é tarefa desta especificação.**

O que A CONTA faz pela dívida é **fornecer o instrumento**: com o `metricas.csv` do §10, a
próxima bancada consegue perguntar, pela primeira vez, se o jogador que abre A CONTA passa a
**recusar** fechar linhas em 4/5 com mais frequência que o jogador que não abre. Isso é uma
pergunta mensurável, e ela não existia antes deste painel. **Hipótese, não resultado.**

---

## 10. INSTRUMENTAÇÃO — como saber se este recurso não virou cemitério

Uma linha em `user://metricas.csv` por abertura:

```
compendio,<t_ms>,<cena>,<gatilho>,<aba_entrada>,<aba_final>,<ms_aberto>,<verbete_final>,<mudou_jogada>
```

`gatilho ∈ {botao, tecla, gamepad, toque_longo, link_de_texto}` ·
`mudou_jogada` = a carta selecionada ou a casa do cursor mudou entre abrir e fechar.

**Critérios de reprovação, registrados agora, antes de existir código:**

| Sintoma | Número que reprova | O que ele diz |
|---|---|---|
| Ninguém abre | **< 30%** dos jogadores abrem alguma vez na mesa 1 | o ponto de entrada está errado (§1), não o conteúdo |
| Abre por acidente | mediana de `ms_aberto` **< 1.500** com `aba_final == aba_entrada` | o botão/atalho está no caminho de outra coisa |
| O contexto erra | **> 25%** das aberturas terminam em aba ≠ aba de entrada | a escada do §4.2 está na ordem errada; o `aba_final` diz qual degrau subir |
| Vira cemitério | aberturas por mesa caem **> 80%** entre a rodada 1 e a rodada 4 | o segundo uso (§9) falhou; A CONTA não está sendo consultada |
| Vira muleta | `mudou_jogada` **> 60%** | não é um problema de UI, é sinal de que a prévia da partida está incompleta |

Nenhum desses números é conhecido. Estão aqui **em branco de propósito**, para serem
preenchidos por medição — e não por mim.

---

## 11. RESUMO DE IMPLEMENTAÇÃO

| Arquivo | O que é | Tamanho estimado |
|---|---|---|
| `cenas/compendio.tscn` | `CanvasLayer` 70, folha + busca + faixa AGORA + 5 abas | — |
| `scripts/ui/compendio.gd` | abrir/fechar, foco, escada de contexto (§4.2), instrumentação | ~260 linhas |
| `scripts/ui/compendio_maos.gd` | a tabela viva (§5), lê `Mesa` e `run.maos_feitas` | ~120 |
| `scripts/ui/diagrama_desmanche.gd` | `_draw` do §7.5, usado em 4 lugares | ~180 |
| `scripts/ui/compendio_conta.gd` | o extrato do §9, lê a fita de `Mesa.simular()` | ~140 |
| `dados/verbetes.json` | ≈ 60 verbetes: `id`, `titulo`, `corpo`, `apelidos[]`, `estado` | dados |
| `traducoes/textos.csv` | colunas `pt`, `en`, `es` + nova coluna `apelidos` | dados |
| `project.godot` | ação nova **`regras`** | 1 linha |
| save, bloco `run` | campo novo `maos_feitas: Array[int]` (11) | 1 linha |
| `fluxo_testes.gd` | `compendio_nao_cobre_grade`, `compendio_devolve_foco`, matriz §15.4 | ~40 |

**Etapa sugerida:** entra na **Etapa 6** (retrato e legibilidade), junto do Receituário
colapsável — porque é lá que o layout de retrato nasce e é em retrato que o Compêndio é
indispensável. O `diagrama_desmanche.gd` pode entrar na **Etapa 5** (primeiro jogável), já
que o passo 4 do tutorial precisa dele.
