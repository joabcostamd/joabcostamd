# MEGA-PROMPT — PLACARD (roguelike de pôquer em grade, Godot 4.7.2)

## 0. CABEÇALHO DE USO

1. Abra o Claude Code na raiz deste repositório e cole **tudo entre as duas linhas de três tis (`~~~`)**, precedido da palavra **ultracode**.
2. A frota trabalha sozinha: escreve `DESIGN.md` antes de qualquer código, constrói em 12 etapas e roda `placard/testar.sh` ao fim de cada uma.
3. Você **não precisa responder nada** — o prompt proíbe parar para perguntar; toda ambiguidade vira decisão registrada em `AUDITORIA.md`.
4. O escopo é grande e o prompt declara **mínimo inegociável** (Etapas 1–7) e **ordem de sacrifício** (§16.1). Se o tempo acabar, a frota corta na ordem escrita e registra o corte — nunca afrouxa teste, nunca para. Jogável já na Etapa 5.
5. No fim você recebe a pasta `placard/`, três documentos, capturas em `capturas/` e commit na branch `feat/cruzada` (push, se houver remoto).

~~~
# ORDEM DE SERVIÇO — CONSTRUIR "PLACARD"

## 1. MISSÃO

Você vai construir, do zero até pronto-para-jogar, um roguelike deckbuilder de cartas chamado **PLACARD**, em **Godot 4.7.2 / GDScript**, dentro da pasta `placard/` na raiz deste repositório. Baralho francês de 52 cartas, toda pontuação vem de mãos de pôquer, mas a mesa é uma grade 5×5 e **cada carta posicionada pertence ao mesmo tempo à mão da linha e à mão da coluna** (e às diagonais, quando cai nelas). Mesa de 60 a 110 segundos, run de 18 mesas em ~30 minutos, loja entre mesas vendendo selos que grudam em **casas específicas** — a build tem formato, não é uma lista. Viciante sem ser frustrante: nenhuma matemática escondida, nenhuma mão vale zero, nenhum travamento possível, nenhuma derrota sem explicação numérica. Toda arte é desenhada por código e todo áudio é sintetizado por script Python no repositório; nenhum binário é baixado.

**Condição de término, sem negociação:** você só termina quando o jogo estiver **jogável** (abre, joga uma run inteira do tutorial ao fim de run, salva e retoma), **testado** (`placard/testar.sh` sai com código 0 e `placard/testar.sh --completo` sai com código 0 ou registra em `AUDITORIA.md` as bandas não atingidas com valor medido ao lado) e **documentado** (`DESIGN.md`, `README.md`, `AUDITORIA.md` escritos e coerentes com o código), com commit feito. Parar antes é entrega reprovada — **com três exceções nomeadas, todas registradas em `AUDITORIA.md` e nenhuma delas reprovação**: motor ausente (§3.2, modo degradado), templates de export ausentes (§15) e `git push` sem remoto (§20.8).

---

## 2. REGRAS DE ENGAJAMENTO DOS AGENTES

**Proibido perguntar.** Você não faz perguntas ao usuário, em momento nenhum. Toda ambiguidade é resolvida por você com este desempate, nesta ordem: (1) o que este documento diz literalmente; (2) o que não quebra `testar.sh`; (3) o que preserva a legibilidade do tabuleiro; (4) o que é mais simples de testar. Cada decisão vira uma linha em `AUDITORIA.md`: `DECISÃO — <assunto> — <opção> — <critério> — <data>`.

**Fases da frota.** Dentro de cada fase os agentes rodam em paralelo; entre fases há barreira dura.

| Fase | Agentes em paralelo | Barreira de saída |
|---|---|---|
| F0 Reconhecimento | 1 | Motor resolvido e gravado em `AUDITORIA.md` (§3.2); `--doctool` despejado; árvore de pastas e `.gitignore` criados |
| F1 Design | 1 escritor + 1 revisor adversarial | `DESIGN.md` completo, com o pipeline R40, a tabela de opcodes (§8.0), os **contratos congelados** (§14.9) e todas as regras de borda, ANTES de qualquer `.gd` de regra |
| F2 Núcleo | 4 (cartas/mãos, grade/mesa, selos/pipeline, aleatório/serialização) | `nucleo_testes.gd` com **≥ 120 asserções de núcleo** passando (avaliador, grade, colheita, cruzada, Tear, determinismo, fita), 0 travamentos na varredura rápida |
| F3 Ferramentas | 3 (validadores Python, geradores de áudio/ícone, traduções) | `testar.sh` roda as 7 validações Python e sai 0 |
| F4 Apresentação | 4 (tema/carta/grade, HUD/rótulos/prévia, telas, juice/áudio) | `fluxo_testes.gd` cobre 100% das cenas, **retrato e paisagem, idioma pt** |
| F5 Conteúdo | 3 (selos e relíquias, chefes e tabuleiro, coleção/conquistas/estante) | `validar_dados.py` verde; suíte **gerada** par a par verde (§15) |
| F6 Balanceamento | 2 (simulação, relatório) | `relatorio_balanceamento.py --exigir` dentro das bandas **ou** com as bandas não atingidas registradas e medidas |
| F7 Acabamento | 3 (acessibilidade, i18n, export/capturas) | Capturas e exports gerados **ou** pulos registrados; DoD 100% provado ou cortado pela §16.1 |

**Fases × Etapas — quem manda.** As **Etapas** do §16 governam o cronograma e as barreiras; as **Fases** descrevem apenas quem pode trabalhar em paralelo dentro de cada etapa. Mapa obrigatório: **F0→E1, F1→E2, F2→E3–E4, F3→E1+E3, F4→E5–E6, F5→E8, F6→E11, F7→E12.** Em qualquer conflito, manda a Etapa.

**Paralelismo.** Podem rodar juntos: arquivos diferentes em pastas diferentes. Não podem: dois agentes no mesmo `.gd` ou no mesmo `dados/*.json`, nem apresentação antes de o núcleo daquela regra passar em teste. `project.godot`, `testar.sh` e `dados/maos.json` têm dono único por fase.

**Verificação adversarial obrigatória.** Todo entregável é lido por outro agente com a instrução de **tentar reprovar**: número mágico fora de `dados/`, regra duplicada entre núcleo e tela, borda não testada, texto literal na UI, promessa do `DESIGN.md` não cumprida, efeito implementado fora do pipeline da R40. O revisor nunca é o autor. Achado vira **teste antes de virar correção**: primeiro escreve-se o teste que falha, depois corrige-se. Na Etapa 2 o revisor entrega um **parecer escrito** em `AUDITORIA.md` (`REVISÃO F1 — <n> achados — <n> corrigidos — <n> aceitos como dívida com teste`); é o parecer, não a opinião, que abre a barreira.

**Workflows encadeados.** Cada fase produz a entrada literal da seguinte: F1 escreve `DESIGN.md` → F2 implementa só o que está lá → F3 produz validadores que grepam o `DESIGN.md` → F4 consome a **fita de eventos** e nunca recalcula regra → F5 autora JSON validado pelos esquemas de F3 → F6 mede → F7 fecha. Faltando algo da fase anterior, o agente **não improvisa**: registra a lacuna em `AUDITORIA.md`, implementa o mínimo com o padrão declarado aqui e marca a dívida com o teste que a cobre.

**Rodar o jogo é obrigação.** A cada etapa da seção 16 execute, nesta ordem: `"$GODOT_BIN" --headless --path placard --import`, `"$GODOT_BIN" --headless --path placard res://cenas/testes.tscn`, `"$GODOT_BIN" --headless --path placard res://cenas/fluxo.tscn`, `bash placard/testar.sh`. **Uma etapa só acaba quando `testar.sh` sai 0** para as verificações que aquela etapa exige (tabela em §15.2). Não avance com vermelho, não comente teste para passar. Se o teste é difícil, o difícil é o código.

**Fim do trabalho:** `git add`, `git commit` e, havendo remoto, `git push` em `feat/cruzada`, criada a partir da branch atual; **nunca** commit direto na branch padrão. `push` que falha por ausência de remoto ou de credencial vira `PUSH — falhou — <motivo>` em `AUDITORIA.md`, o commit local permanece e o item do DoD conta como cumprido.

---

## 3. RESTRIÇÕES INEGOCIÁVEIS

1. **Motor:** Godot **4.7.2**, **GDScript** apenas. Zero C#, GDExtension, plugin, addon, asset store ou pacote externo.
2. **Resolver o motor antes de exigir versão.** `ferramentas/verificar_godot.py` resolve o binário **nesta ordem** e exporta `GODOT_BIN`: (1) `$GODOT` se definido; (2) `godot`; (3) `godot4`; (4) `~/godot/godot`; (5) `flatpak run org.godotengine.Godot`. **Todo comando do repositório usa `"$GODOT_BIN"`, nunca `godot` literal.** Política de versão: **4.7.x = ideal**; **qualquer 4.x = ACEITÁVEL** — grave `MOTOR — <versão real> — divergente de 4.7.2` em `AUDITORIA.md`, restrinja-se à API estável desde 4.0 e siga; **ausência de Godot = MODO DEGRADADO**: rode só os validadores Python, escreva `DESIGN.md`/`README.md`/`AUDITORIA.md`, deixe o código completo e encerre com a seção `BLOQUEIO EXTERNO — Godot não encontrado — comandos não executados: <lista>`. **Modo degradado com bloqueio registrado NÃO é entrega reprovada.**
3. **Como se confere a API, offline.** Em F0, rode uma vez `"$GODOT_BIN" --doctool /tmp/apidocs` e trate o XML gerado como a **única** fonte de verdade sobre a API da build instalada; toda dúvida se resolve com `grep` nesse diretório, **não de memória e não pela internet**. Antes do primeiro uso, confira **explicitamente** cada um destes suspeitos, que este documento cita de memória: `ThemeDB.fallback_font`; `DisplayServer.tts_speak`; `HashingContext` (SHA-256); `AudioStreamWAV.loop_begin`/`loop_end`/`LOOP_FORWARD` (**loop em frames, não em bytes**); `CPUParticles2D` dentro de árvore de `Control`; `Engine.time_scale`; `PROCESS_MODE_ALWAYS`; `OS.get_cmdline_user_args()`; `DirAccess.rename`; `Time.get_datetime_dict_from_system(true)`; `Input.vibrate_handheld`; `--headless --import`; `--resolution`; a chave completa `rendering/renderer/rendering_method`; e `get_window().content_scale_size` para trocar a base 1280×720 ↔ 720×1280 em tempo de execução. **Cada divergência encontrada vira linha em `AUDITORIA.md`.** API dependente de versão fica isolada atrás de uma função em `scripts/nucleo/constantes.gd` com fallback testado (ex.: `TRANS_SPRING` → `TRANS_BACK`).
4. **Renderer:** `gl_compatibility` em desktop e mobile. Nada de Forward+, nada de `hint_screen_texture` no caminho padrão.
5. **Viewport:** base 1280×720, `stretch/mode=canvas_items`, `stretch/aspect=expand`. Layout **retrato** obrigatório quando `largura/altura < 0,85`: `scripts/ui/layout.gd` troca a base lógica para 720×1280 escrevendo em `get_window().content_scale_size` (**confirme o nome no `--doctool` antes de usar**; não havendo, use a chave de projeto equivalente e registre a decisão), **sem duplicar cena**. Legibilidade provada por comando em §15.4.
6. **Zero asset externo.** Arte = `_draw`, `Control`, `StyleBoxFlat`, `CPUParticles2D` e no máximo um shader de 6 linhas. Áudio = `.wav` PCM mono 22050 Hz 16 bits gerado por `ferramentas/gerar_audio.py` (stdlib `wave`/`struct`/`math`). Ícone e splash por `ferramentas/gerar_icones.py` (`zlib`/`struct`). `gerar_audio.py --verificar` recomputa hashes e falha o build se um `.wav` divergir do script.
7. **Zero rede e zero monetização.** `testar.sh` grepa `HTTPRequest`, `HTTPClient`, `WebSocketPeer`, `UPNP` e falha se aparecerem. **Zero telemetria significa zero rede:** `user://metricas.csv` é arquivo local do jogador, nunca enviado, apagável em `dados.tscn`, e isso fica escrito no `README.md` — o revisor adversarial que reclamar dele recebe esta linha como resposta.
8. **Determinismo por seed.** Mesma seed = mesma run, byte a byte. O núcleo nunca chama `randi()`, `randf()`, `randomize()`; a aleatoriedade de regra vem de um `Aleatorio` injetado com **seis fluxos e cursores independentes**. O save guarda `semente` + `cursores`, **nunca** cartas sorteadas.
9. **Convenções em português:** pastas `cenas/`, `scripts/{autoload,nucleo,telas,ui}/`, `dados/`, `recursos/`, `testes/`, `traducoes/`, `ferramentas/`, `capturas/`. Nomes de arquivo, classe, variável, função e sinal em português. Autoloads: `Avisos`, `Catalogo`, `Progresso`, `Texto`, `Layout`, `Audio`, `Efeitos`, `Ruido`, `Navegacao`.
10. **Tipagem estática 100%.** Toda `func` declara `-> Tipo`; todo parâmetro e variável de classe anotados. Arquivo ≤ 400 linhas (`nucleo/` ≤ 300), função ≤ 40 linhas, aninhamento ≤ 3, parâmetros ≤ 5. Todo `.gd` abre com um `##` de uma linha.
11. **Nenhum número mágico de regra** (fichas, mult, meta, preço, orçamento, total do acervo) fora de `dados/*.json` e `constantes.gd`; **nenhum texto literal** na UI (tudo por `tr()`/`Texto.formatar()`); **nenhuma cor literal** fora de `scripts/ui/tema.gd`. Os três reprovam o build por validador.

---

## 4. A MECÂNICA-NÚCLEO

> **Se um agente ler só esta seção, ele tem de conseguir implementar o coração do jogo.**

### 4.1 A regra em uma frase

> **Cada carta pontua em duas mãos de pôquer — a linha e a coluna onde você a colocar (três, se cair numa diagonal) — e toda linha que chega a 5 cartas pontua na hora e evapora.**

A segunda cláusula é obrigatória na frase de venda: sem ela o jogo é confundido com Poker Squares (1949). O que é novo é a **colheita destrutiva** e a **cruzada**, e os 10 primeiros segundos precisam mostrar as duas. O parêntese é o que torna a grade **assimétrica**: sem ele as 25 casas são mecanicamente idênticas e escolher a casa do selo é cara-ou-coroa.

### 4.2 Regras completas

- **R01 BARALHO** — 52 cartas (Á,2..10,J,Q,K × copas/ouros/paus/espadas), embaralhadas pelo fluxo `baralho` no início de cada mesa. Carta é `int` 0..51 = `naipe*13 + valor`.
- **R02 GRADE** — 5×5, colunas A–E, linhas 1–5. Casa é `int` 0..24 = `linha*5 + coluna`. Conteúdo: `-1` vazia, `-2` lacrada, `0..51` carta.
- **R03 LINHAS PONTUÁVEIS** — 5 horizontais + 5 verticais = **10 integrais**.
- **R03b DIAGONAIS VIVAS** — as **2 diagonais** são linhas pontuáveis **desde o turno 1** e pagam **60% dos pontos** (arredondando para baixo). São **12 linhas vivas**: 5 horizontais, 5 verticais, 2 diagonais. Consequência geográfica, que é a tese do jogo: **C3 pertence a 4 linhas**; as outras **8 casas diagonais** (A1, B2, D4, E5, E1, D2, B4, A5) pertencem a **3**; as **16 restantes** pertencem a **2**. Diagonal fecha, colhe e conta para o Tear como qualquer outra linha; só o pagamento é reduzido. A relíquia **Bússola** e o modificador **Trama** sobem as diagonais para 100%.
- **R04 MÃO** — 5 cartas (6 com Régua ou baralho da Viúva). Depois de cada posicionamento, compra até voltar ao tamanho.
- **R04b PILHAS** — a mesa tem **3 pilhas**: `baralho` (compra), `descarte` (cartas trocadas pela R08) e `colhida` (cartas removidas pela R11, fora da mesa até o fim). **Baralho vazio:** a pilha de descarte é reembaralhada pelo fluxo `baralho` e vira o novo baralho; **a pilha colhida nunca volta**. Identidade de conservação, verdadeira a todo instante e usada como asserção (`_conservacao_das_pilhas`): `N = mão + grade + colhida + baralho + descarte`, com `N` = tamanho do baralho da run (52, ou 40 no Curto, ou 26×2 no Vermelho). **`Outs.contar()` usa denominador `restantes = baralho + descarte`** — as cartas que o jogador ainda pode ver — e esse é o **mesmo** número mostrado no Baralho Aberto, na autópsia, no replay da §4.4 e na política do simulador. Teste `_baralho_curto_nao_esgota`: baralho Curto (40) + mesa Chefe + Régua + Novelo, verifica que a compra nunca falha.
- **R05 FICHAS DA CARTA** — 2 a 10 valem a face; J/Q/K valem 10; Á vale 11.
- **R06 TURNO** — descarte opcional → **posicionamento obrigatório** → compra.
- **R07 POSICIONAR** — 1 carta da mão em 1 casa vazia qualquer; fica fixa ali até ser colhida.
- **R08 DESCARTE** — 2 por Pequena, 3 por Grande e Chefe. Troca de 1 até o tamanho da mão. **Não gasta posicionamento.** As cartas trocadas vão para a pilha `descarte` (R04b).
- **R09 ORÇAMENTO** — **15 / 17 / 19** posicionamentos (Pequena / Grande / Chefe). Bater a meta encerra a mesa na hora, com vitória.
- **R10 DERROTA DE MESA** — esgotar os posicionamentos sem bater a meta gasta 1 vida das 3 e repete a mesa com nova seed. Não encerra a run. **A seed da repetição é derivada, nunca sorteada:** `semente_mesa = mix(semente_run, rodada * 10 + mesa, tentativa)`; `randi()` aqui **reprova a entrega**.
- **R11 COLHEITA IMEDIATA** — linha com 5 cartas é avaliada como mão de pôquer, pontua e as 5 cartas **saem** para a pilha colhida (fora do baralho até o fim da mesa).
- **R12 PONTOS DE UMA LINHA** — `(fichas base da mão + soma das fichas das 5 cartas) × min(teto_do_evento, mult da mão + Tear vigente)`, e o resultado é multiplicado por **0,60 (piso)** se a linha for diagonal sem Bússola/Trama. O `teto_do_evento` é o da §5.1 e vale igualmente para linha simples e para cruzada — não existe segundo teto.
- **R13 TABELA** — seção 5.
- **R14 PISO NUMÉRICO** — **todas** as 5 cartas somam fichas, participem ou não da combinação. Nenhuma colheita vale zero.
- **R14b COLHEITA FINAL (semântica completa)** — ao fim de **toda** mesa (vitória **ou** derrota), avalia-se **cada uma das 12 linhas independentemente**. Linha com **≥ 3 cartas** paga:
  `floor( ( fichas_base da melhor categoria GARANTIDA com as cartas presentes + soma das fichas das cartas presentes ) × ( mult dessa categoria + Tear vigente ) × 0,5 )`
  Regras que fecham a semântica, e que valem literalmente: o piso da R14 **não** se aplica (só as cartas presentes somam, porque não há 5); **uma carta que está numa linha e numa coluna, ambas com ≥ 3, paga nas duas — é intencional**; o Tear **entra** com o valor vigente e **não sobe**; **não há cruzada**, **não há remoção**, **não há cascata**, **não há quebra de Vidro**; diagonal com ≥ 3 paga com o mesmo 0,5 e ainda com o piso de 60% da R03b. Ordem fixa dos eventos na fita: **linhas 1..5, colunas A..E, diagonal principal, diagonal secundária** — um evento `colheita_final` por linha. O selo **Contrapeso** troca o fator 0,5 por **1,0** no seu eixo. Isso troca o apagão do fim por cascata de recompensa e é a rede de segurança central do jogo: implemente-a **antes** de qualquer selo.
- **R15 CRUZADA** — se **um** posicionamento fecha 2+ linhas, elas resolvem no **mesmo evento**: `pontos = (soma das fichas de todas as mãos) × min(teto_do_evento, soma de TODOS os mults + Tear vigente)`. A carta do cruzamento soma fichas em todas. **Todas as mãos somam mult integral — não existe redução por 3ª ou 4ª mão.** Diagonal participante entra com fichas e mult integrais no evento, e só a **parcela** correspondente a ela sofre o piso de 60% (o núcleo devolve `pontos` e `pontos_diagonal_reduzidos` na fita, para a tela não recalcular nada). **Teto do mult do evento:** `teto_do_evento = 24 + 4 × rodada` (28 na rodada 1, 48 na rodada 6; no Infinito, `24 + 4 × min(rodada, 12)`).
- **R15b QUANDO O TETO MORDE, ELE APARECE** — a prévia e a estampa mostram `×52 → ×48 (teto)` em dourado esmaecido, e o Receituário mostra permanentemente `mult da run: 31 / teto 48`. **Teto invisível é matemática escondida e reprova pelo item 16 da §19.** O simulador mede: o teto pode morder em no máximo **8% dos eventos**; acima disso, **suba o teto, nunca corte selos**.
- **R16 RESOLUÇÃO ATÔMICA** — todas as linhas fechadas pelo mesmo posicionamento são avaliadas **antes** de qualquer remoção; a ordem entre elas nunca importa para o total.
- **R17 CUSTO ESPACIAL** — colher esvazia 5 casas e reduz em 1 carta cada linha perpendicular. Pontuar sempre desmancha algo; a cruzada é a única colheita sem sobra pela metade.
- **R18 SEQUÊNCIA** — vale Á-2-3-4-5 (Ás valendo 1 na ordem, 11 em fichas) e 10-J-Q-K-Á. **Não** vale Q-K-Á-2-3, nem com curinga.
- **R19 INVARIANTE ANTI-TRAVAMENTO** — imposto pelo **gerador**: a qualquer momento, **≥ 5 linhas vivas alcançáveis** (das 12) e **≥ 1 casa vazia numa linha viva**. `Tabuleiro.gerar()` recusa combinação de modificador × grau × baralho que viole isso; checado a cada posicionamento e, se quebrar, a linha viva mais cheia é colhida na hora.
- **R19b JOGADA LEGAL GARANTIDA (anti-mão-morta)** — a cada início de turno o núcleo chama `Mesa.jogada_legal_existe()`, que procura pelo menos um par (carta da mão, casa vazia) legal. **Não existindo**, concede um **DESCARTE DE EMERGÊNCIA gratuito** (não conta no orçamento de descartes), avisa com `Nenhuma casa aceita essa mão. Toma uma troca.` e repete a verificação; após **3 emergências no mesmo turno**, a linha viva mais cheia é colhida na hora. Teste `_nunca_mao_morta`: varredura de **16 modificadores × 8 baralhos × 9 graus × 30 seeds**, falhando em qualquer turno sem jogada legal.
- **R20 RUN** — **6 rodadas × 3 mesas = 18 mesas**. As 6 rodadas formam 3 atos (Fio, Trama, Tear), usados para divulgação progressiva e checkpoints do Infinito.
- **R21 METAS** — `pequena(n) = arredonda(450 × 1,42^(n-1))`; `grande(n) = arredonda(pequena(n) × 1,50)`; `chefe(n) = arredonda(pequena(n) × 2,30)` — sempre a partir do valor **já arredondado** de `pequena(n)`, com arredondamento meio-para-cima. A tabela materializada está na §6.2 e `validar_dados.py` **recomputa a curva pela fórmula e reprova se qualquer célula divergir**.
- **R22/R23 DINHEIRO E LOJA** — seção 6.
- **R24 NÍVEL DE MÃO** — sobe fichas base e mult de uma categoria; variante de eixo mais barata ("Flush em coluna") só vale quando a mão fecha naquele eixo.
- **R25/R26/R27 SELOS E RELÍQUIAS** — seção 8.
- **R28 MODIFICADORES DE MESA** — mexem **preferencialmente** em geometria e leitura, e **nunca escondem informação**. São permitidas **exceções numéricas explícitas, e só estas quatro**: **Vidraça**, **Furada**, **Tear Quente** e **Espelhada**. Modificador numérico novo, fora dessa lista, **reprova o build** (`validar_dados.py` cruza `eixo_de_efeito` com esta lista).
- **R29 DIÁRIO** — seed do dia derivada offline; mesmas 18 mesas, modificadores e loja para todos; placar local e replay verificável.
- **R30 ESTUFA** — `+4` posicionamentos por mesa, 5 descartes, metas `×0,70`, Voltar ilimitado, **derrota não existe** (repete de graça), rodapé com a melhor colheita da mão, coleção desbloqueia normalmente. Não é versão "de mentira".
- **R31 MESA** (padrão) — 15/17/19 posicionamentos, 2/3/3 descartes, **3 vidas** e a **Fiança**.
- **R32 TABULEIRO 0–8** — **preset** monotônico que escreve nos três sliders da §7.1, 1 degrau por vitória, reversível, nunca obrigatório. **Não soma com os sliders: escreve neles.**
- **R33** — nenhuma conquista base exige Tabuleiro > 1; nenhuma opção de dificuldade é irreversível entre runs.
- **R34 DETERMINISMO** — 6 fluxos com cursores independentes: `baralho`, `loja`, `chefe`, `selo`, `semeadura`, `ajuda`; cada um semeado por `semente * 1000003 + hash(nome_do_fluxo)`.
- **R35 VOLTAR ATRÁS** — botão discreto por **1,5 s durante a animação de colheita**. **Nunca após cruzada.** Fora dessa janela, desfaz o último posicionamento que não fechou linha. Nunca destacado, nunca sugerido, nunca no caminho natural do dedo. **Determinismo:** `Mesa` guarda um instantâneo dos **seis** cursores antes de cada posicionamento; `voltar_atras()` **restaura os seis**, não só `baralho`. Sem isso o teste `_determinismo_com_voltar` é impossível de passar.
- **R36 ESTADO** — grade e mão em `PackedInt32Array`; avaliador O(5) por contagem de valores e naipes, sem alocação; tudo em GDScript puro em `scripts/nucleo/`.
- **R37 PRÉVIA FANTASMA** — ao pairar/arrastar sobre uma casa, o núcleo roda `Mesa.simular(indice_mao, casa) -> Array`: **o pipeline completo da R40 em modo seco**, sem mutar estado, devolvendo **a MESMA fita** que o posicionamento real devolveria. A prévia **lê a fita**; ela **nunca reimplementa cálculo**. Custo ≤ 0,05 ms. **Zero matemática escondida.** Asserção obrigatória `_previa_igual_ao_resultado` (§15).
- **R38 ARTE E ÁUDIO 100% POR CÓDIGO.**
- **R39 O TEAR** — inteiro da mesa: começa em 0, **+1 por linha colhida** (diagonal inclusive), teto 8, **zera entre mesas**. Entra **uma vez por evento de colheita**, somado ao mult total, inclusive na cruzada. O Tear **vigente antes do evento** é o que conta; só depois ele sobe. Nunca desce. É o único número que sobe a mesa inteira: sempre na tela, contando alto, subindo um semitom por degrau.
- **R40 ORDEM DE RESOLUÇÃO (pipeline único)** — `empurrões → preenchimento → valor efetivo (Espelho) → naipe efetivo (Ímã) → reduções de mesa (Molhada) → multiplicadores de casa (Brasa) → detecção de fechamento → avaliação de TODAS as linhas fechadas → soma de mults e aplicação do teto → pontuação → remoção → Âncoras → quebras (Vidro)`. **Nenhum selo é implementado fora deste pipeline**; a única forma de um item existir é um `opcode` da §8.0 declarando em que fase ele entra.
- **R41 META FORA DE ALCANCE** — provado que nem a melhor sequência restante fecha a meta, o jogo declara "A meta saiu do alcance. Agora é pelo recorde", converte o resto em desafio de pontuação com pagamento proporcional e oferece "Encerrar agora" (dispara a R14b).
- **R42 SEMEADURA** — toda mesa **Pequena** nasce com **3 cartas semeadas** pelo fluxo `semeadura`, para o primeiro posicionamento nunca ser decisão vazia numa grade simétrica.
- **R43 CASCATA** — existe e é **limitada a 1 nível**, e as fontes são **exatamente estas três**: um **EMPURRÃO** (modificador Esteira), um **PREENCHIMENTO** (Ofício Semear, modificador Muda) ou uma mudança de **VALOR/NAIPE EFETIVO** (Espelho, Ímã) que faça outra linha atingir 5 cartas. Ela resolve como evento **separado**, com o Tear **já atualizado**, e **não** entra na soma de mults da cruzada que a causou. Cascata de 2º nível é proibida: a segunda linha só fecha no posicionamento seguinte. **Remoção nunca gera cascata — remover cartas só esvazia linhas.**

### 4.3 O loop de turno

1. **Leitura (1–3 s).** As 12 linhas vivas exibem dois campos e nada mais: fração `n/5` e categoria — **garantida** sem `?`, **alcançável** com `?`. `4/5 PAR` é posse; `4/5 FLUS?` é promessa. As diagonais usam o mesmo badge com moldura tracejada e o sufixo `60%`.
2. **Intenção.** Ao pegar uma carta, as casas vazias ganham halo **verde** (melhora linha, coluna ou diagonal), **amarelo** (neutro) ou **vermelho** (mata um 4/5 já formado), e as 5 melhores recebem anel numerado **ordenado por delta de pontos**. Isso colapsa ~85 jogadas legais em 5–8 candidatas honestas sem esconder nenhuma. **As assistências são desligáveis** (§10), e as bandas da §7.4 são medidas também com elas desligadas.
3. **Prévia fantasma.** Painéis LINHA e COLUNA (e DIAGONAL, quando houver), cada um com as 5 cartas em miniatura, categoria e `fichas × mult = pontos`. Fechando, o cabeçalho vira `COLHE` e um terceiro bloco lista o que sai das perpendiculares. Tudo vem da fita de `Mesa.simular()`.
4. **Posicionamento, colheita e desmoronamento** seguem a linha do tempo da §11: **pagamento inteiro primeiro, desmoronamento depois**, com o rótulo perpendicular se **reescrevendo como proposta** ("Flush 4/5 → Trinca 3/5, precisa de 2 damas"), nunca como decremento seco.
5. **Compra.** Escada de sinal: out comum = **silêncio**; out que leva uma linha a 4/5 = pulso e `ping_out`; out que fecha cruzada = pulso triplo, as duas linhas acendem e o som ganha a quinta.

**Alvo de ritmo: 2–6 s por turno.** É **meta de design**, medida em `user://metricas.csv` quando houver sessão humana — **não** é banda de aceite do build, porque a frota não tem jogadores. O que o `--exigir` mede no lugar está na §7.4 (**candidatas honestas**). Os três mitigadores (halo tricolor, prévia fantasma, ordenação por delta) entram no **primeiro** jogável.

### 4.4 Replay de exemplo (números reais — implemente como asserção `_replay_rodada4_rachada`)

**Como este teste é montado.** `_replay_rodada4_rachada` **não é um replay semeado**; é um **teste de fixture**. Monte o estado com `Mesa.de_estado()` a partir de `testes/fixtures/rodada4_rachada.json` e afirme **apenas** o turno 16. As compras narradas abaixo (8♣, 3♣, A♥, 2♥, 9♦) são **ilustração de texto e não são asserções** — nenhuma seed as reproduz, e tentar arrancá-las de uma seed é perda de tempo.

Rodada 4, mesa Chefe **Rachada** (as 4 quinas nascem lacradas, então linhas 1 e 5, colunas A e E **e as duas diagonais** nunca fecham — por isso este replay não menciona diagonal). Meta **2.962**. Orçamento 19. Pontos **1.180**. Posicionamentos **13/19**. Descartes 1/3. **TEAR 1** (uma colheita simples até aqui). Na rodada 2 o jogador colou o selo **Ímã** ($7) em **C3** (a carta ali conta como qualquer naipe).

```
      A     B     C     D     E
  1  [X]    .    10♥    .    [X]
  2   .     .     7♥    .     .
  3   Q♥   Q♠    ( )   Q♦    9♠
  4   .     .     6♥    .     .
  5  [X]    .     8♥    .    [X]
```

**INVARIANTE DO REPLAY, confira antes de escrever qualquer número:** `posicionamentos usados − 5 × (linhas colhidas) = cartas na grade`. Aqui: `13 − 5 × 1 = 8` ✔ (as 8 cartas do diagrama). **Se você mudar qualquer número desta seção, refaça esta conta antes de escrever o teste.**

LINHA 3 = `Q♥ Q♠ __ Q♦ 9♠`; COLUNA C = `10♥ 7♥ __ 6♥ 8♥`. Uma única carta maximiza as duas: um **9** (o Ímã converte o naipe). O 9♠ já está em E3, então os outs são 9♥, 9♦, 9♣ = **3 entre as 34 restantes**, isto é `52 − 5 (mão) − 8 (grade) − 5 (colhidas) = 34` = `baralho + descarte` pela R04b — **8,8%**.

**Turno 14 — mão K♣, 4♦, 2♠, J♦, 5♥.** A tentação: 5♥ em C3 fecharia LINHA 3 = Trinca, fichas `30 + (10+10+5+10+9) = 74`, mult 3; e COLUNA C = Flush, fichas `35 + (10+7+5+6+8) = 71`, mult 4. Cruzada com Tear 1: `(74+71) × (3+4+1) = 145 × 8 = 1.160`, levando a 2.340/2.962. Mas sobrariam **5 posicionamentos**, o tabuleiro ficaria **vazio** e faltariam **622 pontos** de uma linha do zero com 5 cartas forçadas — com Tear 2, Carta Alta paga ~150 e Par ~200; só trinca, flush ou cruzada de sorte pagam 622. **Ele recusa** e guarda o 5♥ como plano B. **Ação:** descarte 2/3 (saem K♣, 4♦, 2♠; entram 8♣, 3♣, A♥ — sem 9); posiciona **J♦ em B5** (linha 5 nunca fecha aqui: lixeira grátis que alimenta a coluna B); compra 2♥.

**Turno 15 —** queima o último descarte (saem 8♣, 3♣, A♥; entram 4♠, Q♣, K♠). Nada. Posiciona **2♥ em D1** (linha 1 nunca fecha; alimenta a coluna D). **Compra do turno: 9♦.**

**Estado da fixture (o que `rodada4_rachada.json` contém, e o que o teste carrega):** `grade[25]` com as 4 quinas em `-2`, as 8 cartas do diagrama **mais** J♦ em B5 e 2♥ em D1; `mao = [9♦]`; `tear = 1`; `pontos = 1180`; `meta = 2962`; `rodada = 4`; `posic_usados = 15`; `descartes_usados = 3`; `selos = [{id: "ima", alvo: C3}]`. Invariante: `15 − 5 × 1 = 10` cartas na grade ✔.

**Turno 16 — 9♦ em C3.** O Ímã converte o naipe.
- LINHA 3 = `Q♥ Q♠ 9♦ Q♦ 9♠` → **FULL HOUSE**. Fichas `40 + (10+10+9+10+9) = 88`. Mult **4**.
- COLUNA C = `10♥ 7♥ 9♦(copas) 6♥ 8♥` → 6-7-8-9-10 do mesmo naipe = **SEQUÊNCIA DE COR**. Fichas `100 + (10+7+9+6+8) = 140`. Mult **8**.
- **CRUZADA** = `(88 + 140) × min(40, 4 + 8 + Tear 1) = 228 × 13 = 2.964`. O teto da rodada 4 é `24 + 4×4 = 40`; 13 passa longe, o teto **não** morde.

Total **1.180 + 2.964 = 4.144 / 2.962**: mesa vencida no posicionamento **16**, com **3 sobrando**; o Tear vai a **3**; a colheita final não acha linha com 3+ (as duas remanescentes, coluna B e coluna D, ficam com 2 cada após a remoção); recompensa `$5 + $3 + $1 = $9`.

**As asserções obrigatórias do teste, e só elas:** um evento `linha_fechou` FULL com `fichas_base=40`, `fichas_cartas=48`, `mult=4`; um `linha_fechou` SEQ_COR com `fichas_base=100`, `fichas_cartas=40`, `mult=8`; um `cruzada` com `fichas=228`, `mult=13`, `pontos=2964`; `pontos` total `4144`; `meta_batida` presente; **nenhum** `colheita_final` com linha de 3+; e o índice de todo `removeu`/`reproposta` **maior** que o do `pontos`.

O replay prova que a decisão central é **onde**, e que um selo comprado duas rodadas antes decide a partida pela **casa** em que foi colado.

### 4.5 O que diferencia do Balatro

1. **A mesa existe:** a coordenada é o dado mais importante do estado; a mesma carta em C3 e em A1 produz jogos diferentes.
2. **Cada carta pertence a duas mãos ao mesmo tempo, e 9 casas pertencem a três ou quatro** (R03b): nenhuma escolha é local, e **as casas não são intercambiáveis** — C3 vale por 4 linhas, A1 por 3, B1 por 2.
3. **O compromisso é distribuído no tempo:** você compromete uma mão ao longo de 5 turnos, com compras entre eles. Pôquer de saque de verdade.
4. **Pontuar custa território:** colher arranca 1 carta de 5 linhas, então existe a decisão "não quero fechar essa linha ainda".
5. **Metade dos modificadores é geográfica**, e isso é **medido**: `validar_dados.py` reprova o build se `eixo_de_efeito = numerico` passar de 40% de qualquer categoria (§8). A build tem formato, e o formato é mostrado (minimapa no rodapé, mapa de calor, artefato exportável), não afirmado.
6. **A dificuldade mexe majoritariamente na geometria:** dos 9 graus do Tabuleiro, dois mexem em número puro (grau 3 e grau 8) e estão declarados como tal na §7.1 — o resto é geometria.

---

## 5. MÃOS DE PÔQUER E PONTUAÇÃO

### 5.1 Tabela canônica (`dados/maos.json`, único lugar onde estes números existem)

| Chave | Enum | Nome na tela | Rótulo | Fichas base | Mult |
|---|---|---|---|---|---|
| `alta` | 0 | Carta Alta | `ALTA` | 5 | 1 |
| `par` | 1 | Par | `PAR` | 10 | 2 |
| `dois_pares` | 2 | Dois Pares | `2PAR` | 20 | 2 |
| `trinca` | 3 | Trinca | `TRIN` | 30 | 3 |
| `sequencia` | 4 | Sequência | `SEQU` | 30 | 4 |
| `flush` | 5 | Flush | `FLUS` | 35 | 4 |
| `full` | 6 | Full House | `FULL` | 40 | 4 |
| `quadra` | 7 | Quadra | `QUAD` | 60 | 7 |
| `seq_cor` | 8 | Sequência de Cor | `SEQC` | 100 | 8 |
| `real` | 9 | Sequência Real | `REAL` | 120 | 10 |
| `quina` | 10 | Quina | `QUIN` | 140 | 12 |

**A coluna `Enum` é normativa.** `Categorias` vive em `constantes.gd` **nesta ordem exata**: `ALTA=0, PAR=1, DOIS_PARES=2, TRINCA=3, SEQUENCIA=4, FLUSH=5, FULL=6, QUADRA=7, SEQ_COR=8, REAL=9, QUINA=10`. **Maior `int` = melhor categoria**, e é essa comparação — e nenhuma outra — que decide "a melhor categoria **garantida**" de uma linha incompleta, na R14b, nos rótulos e na política do simulador. Dois agentes escolhendo ordens diferentes é o defeito mais caro possível aqui.

**Fórmula de um evento:** `pontos = (Σ fichas base + Σ fichas das cartas) × min(teto_do_evento, Σ mults + Tear vigente)`, com `teto_do_evento = 24 + 4 × rodada` (R15). É a **mesma** fórmula para linha simples e para cruzada: a linha simples é a cruzada de uma mão só. Não existe outro teto no jogo.

**Nível de mão:** cada compra soma `+ max(fichas_base_do_nível_0 × 0,35 ; 8)` às fichas base e `+1` ao mult. **O passo usa SEMPRE as fichas base do nível 0, nunca as do nível atual** (não é composto): Full House sobe de 14 em 14, Sequência de Cor de 35 em 35, Par de 8 em 8 (piso). "Nível N" significa **N compras acima do nível base**. Os dois passos são `passo_fichas` e `passo_mult` em `dados/maos.json` — nunca constantes no código.

**Rota da Quina:** cinco valores iguais só existem via o selo **Espelho** (copia o valor da casa vizinha) sobre uma linha que já tem quadra, ou via a Carta de Ofício **Sósia**. Sem a rota desbloqueada, a Quina aparece **esmaecida a 45% com cadeado** — categoria inalcançável nunca é exibida como disponível. Teste construtivo obrigatório `_quina_pela_rota_do_espelho`; se falhar, a categoria sai da tabela.

### 5.2 Contrato do avaliador

```gdscript
## Avalia 5 posições de uma linha e escreve o resultado em `saida`. Zero alocação.
static func avaliar(cartas: PackedInt32Array, mascara_ima: int, saida: Avaliacao) -> void
```

`cartas`: 5 posições, `-1` = vazia. `mascara_ima`: bits das casas que contam como naipe curinga. `saida`: `Avaliacao` **pré-alocada e reutilizada** com `categoria: int` (o enum da 5.1), `fichas_base: int`, `fichas_cartas: int`, `mult: int`, `mascara_participantes: int`, `completa: bool`. Buffers `_valores` (13) e `_naipes` (4) são `static var` reciclados: o hover roda isso a cada movimento do dedo e não pode gerar lixo. Com `k` casas Ímã testa-se só os naipes **presentes**, `4^k` passadas; **`k` é limitado a 2 por regra** (`pode_colar()` recusa o 3º Ímã na mesma linha ou coluna): teto de 80 operações, ~0,01 ms.

**48 asserções nomeadas obrigatórias**, incluindo: Á-2-3-4-5 é sequência com Ás valendo 1 na ordem e 11 em fichas; 10-J-Q-K-Á é Sequência Real; Q-K-Á-2-3 **não** é sequência nem com curinga; Flush ignora valor e Sequência ignora naipe; Full House versus Dois Pares no mesmo conjunto; Quadra com 5ª alta; Ímã formando Flush **e** Sequência de Cor com a mesma carta; **dois** Ímãs na mesma linha; linha incompleta devolve `completa = false` e a melhor categoria **garantida** pela ordem do enum.

`Rotulos.para_linha()` devolve exatamente **dois** campos: `garantida` e `alcancavel` (esta com `?`); coincidindo, mostra-se **uma só**. `Outs.contar(mesa, linha)` devolve `{cartas_que_servem: int, restantes: int, total: int}` com `restantes = baralho + descarte` pela R04b, e é o **mesmo** cálculo do Baralho Aberto, da autópsia, do replay e da política do simulador. **Uma definição, quatro consumidores** — divergência aqui é falha de teste, não detalhe.

---

## 6. ESTRUTURA DA RUN, FASES E ECONOMIA

### 6.1 Duração (é requisito, não estimativa) — orçamento refeito com os números da §11

| Mesa | Turnos × 4,2 s | Animação (§11) | Total | Alvo |
|---|---|---|---|---|
| Pequena | 15 × 4,2 = 63 s | 3 colheitas × 1,34 + 1,5 cruzadas × 2,62 + cauda 1,5 = **9,4 s** | **72 s** | **66–84 s** |
| Grande | 17 × 4,2 = 71 s | 4 × 1,34 + 2 × 2,62 + 1,5 = **12,1 s** | **83 s** | **76–96 s** |
| Chefe | 19 × 4,2 = 80 s | 5 × 1,34 + 2,5 × 2,62 + 1,5 = **14,7 s** | **94 s** | **86–110 s** |

Rodada = `72 + 83 + 94 = 249 s` + 3 recompensas × 16 s = **297 s ≈ 5,0 min**. Run = **30 min (banda 26–36)**. `relatorio_balanceamento.py --exigir` **falha** se a mediana passar de **38 min**.

**Fator de animação:** os tempos acima são a **1,0×**. O padrão de fábrica é **1,25×** (não 1,0×): os tempos da §11 existem para o primeiro impacto, e quem joga dez horas usa Turbo. As bandas de duração são medidas nos **dois** fatores, 1,0× e 2,5× (turbo), e as duas medições vão para o `AUDITORIA.md`.

### 6.2 Curva de metas (recomputada pela fórmula da R21 — `validar_dados.py` refaz a conta e reprova divergência)

| Rodada | Pequena | Grande | Chefe |
|---|---|---|---|
| 1 | 450 | 675 | 1.035 |
| 2 | 639 | 959 | 1.470 |
| 3 | 907 | 1.361 | 2.086 |
| 4 | 1.288 | 1.932 | **2.962** |
| 5 | 1.830 | 2.745 | 4.209 |
| 6 | 2.598 | 3.897 | **5.975** |

Escalada 450 → 5.975 = **13,3×** contra poder aditivo (`+3 mult`, `+2 mult`, `×2 fichas de uma casa`) mais a alavanca semi-multiplicativa do Tear. Curva `1,6^n` em 8 rodadas está **proibida**: torna o jogo matematicamente impossível a partir da rodada 6.

**Prova obrigatória, derivável linha a linha da §5.1 (escreva como teste `_teto_rodada6`):**
- **Full House nível 3** = fichas base `40 + 3×14 = 82`, mult `4+3 = 7`; cartas `Q-Q-Q-9-9 = 10+10+10+9+9 = 48` → **fichas 130**.
- **Sequência de Cor nível 2** = fichas base `100 + 2×35 = 170`, mult `8+2 = 10`; cartas `6-7-8-9-10 = 40` → **fichas 210**.
- **Cruzada com Tear 4:** `(130 + 210) × min(48; 7 + 10 + 4) = 340 × 21 = 7.140 ≥ 5.975` ✔ (o teto da rodada 6 é 48; não morde).
- **As mesmas mãos separadas, mesmo Tear 4:** `130 × 11 + 210 × 14 = 1.430 + 2.940 = 4.370`.
- **Razão `7.140 / 4.370 = 1,63`, dentro da banda 1,6–2,2** ✔.

Fora da banda, o único dial permitido é a tabela da 5.1.

### 6.3 Economia

| Fonte | Valor |
|---|---|
| Vitória Pequena / Grande / Chefe | $3 / $4 / $5 |
| Posicionamento não usado | $1 cada, teto $4 |
| Juros | $1 a cada $5 guardados, teto $4 |
| **Derrota paga** | $1 a cada 20% da meta atingida, teto $4 (juros continuam) |

Renda mediana ~**$8,3/mesa**, ~**$140/run**, com **17 lojas**.

| Item | Preço |
|---|---|
| Nível de mão / nível de eixo | $4 / $3 |
| Selo de casa comum / raro / épico | $5 / $7 / $9 |
| Selo de eixo / relíquia global | $6 / $8 |
| Rerrolagem | $1, +$1 por rerrolagem na mesma loja |
| Vender selo colado | 50%, arredondando para baixo (100% se a casa foi lacrada) |

**Piso da tese "a build é um mapa"**, capaz de reprovar o build: **≥ 6 selos colados na rodada 4** e **≥ 9 na rodada 6**. Alavancas nesta ordem: juros → preço do selo comum → dinheiro do chefe.

**Teto global de devolução de posicionamentos:** **nenhuma combinação pode devolver mais de 4 posicionamentos por mesa**; o excedente vira **$1 cada**, mostrado como moeda voando. Teste `_teto_de_posicionamentos_devolvidos`. Sem isso, Sirga + Faminta soma +10 a +14 posicionamentos — mais que o modo Estufa inteiro concede.

### 6.4 Recompensa entre fases

Mesa vencida abre 3 beats de ~5 s: (1) **pagamento**, com os posicionamentos não usados voando como moedas numa cauda de 1,5 s; (2) **Cartela**, 1 de 3 grátis (após Pequena: selos de casa; Grande: níveis de mão; Chefe: relíquias ou selos de eixo), as recusadas somem; (3) **Loja**, 3 vagas (2 de selo/relíquia, 1 de nível), "Seguir" sempre visível. Selo comprado abre um seletor: a grade 5×5 em miniatura, com **as 9 casas diagonais marcadas com um traço fino** (a informação que torna a escolha uma decisão), e o jogador clica a casa ou o eixo.

**O chefe é anunciado antes da loja.** O `mapa` mostra o **chefe da rodada**, sua `fala` e seu **`counter_play`** desde a rodada anterior, para que a compra seja uma **resposta** e não um chute. Chefe sem `counter_play` declarado e testado **reprova o build**.

**Divulgação progressiva rígida (regra de build):** rodada 1 só vende **nível de mão**; **selo de casa** entra na 2; **selo de eixo** na 3; **relíquia** na 4. **A primeira mesa da rodada 1 não sorteia modificador** (a divulgação progressiva vale também para a geometria: modificadores começam na segunda mesa da rodada 1). Cada objeto se apresenta em **até 6 palavras**, ancorado no próprio objeto. **Zero modal no loop de turno.**

**Encruzilhadas** (após o Chefe das rodadas 2 e 4, 1 de 2 sorteadas de 6, todas sem downside oculto): *Tecelã* (−$6, cola um selo de casa onde quiser); *Aposta do Fio* (próxima mesa paga dobrado; perdendo, não gasta vida); *Desmanche* (descole um selo e receba o preço cheio); *Enxerto* (+2 posicionamentos em toda Pequena); *Gaveta* (+1 descarte); *Bênção do Tear* (Tear começa em 1).

---

## 7. DIFICULDADE E ANTI-FRUSTRAÇÃO

### 7.1 Camadas opcionais — **um único modelo de dificuldade**

| Modo | Posicionamentos | Descartes | Metas | Derrota |
|---|---|---|---|---|
| **Estufa** | +4 por mesa | 5 | ×0,70 | não existe; repete grátis, Voltar ilimitado, rodapé com a melhor colheita |
| **Mesa** (padrão) | 15/17/19 | 2/3/3 | ×1,00 | 3 vidas + Fiança |

**Existe um único modelo de dificuldade: os três sliders.** Configurações → Desafio expõe **Orçamento** (−3 a +6 posicionamentos), **Geometria** (0–8) e **Metas** (×0,70 a ×1,25). O **dial Tabuleiro 0–8 é apenas um PRESET que escreve valores nos três sliders — eles não somam.** `dados/tabuleiro.json` guarda os **9 presets**, uma linha por grau, com os três valores. A varredura de travamento percorre os **9 presets**, nunca o produto cartesiano de dial × sliders.

| Grau (= slider Geometria) | Mudança exata | Eixo |
|---|---|---|
| 1 | −1 posicionamento em toda mesa | geométrico |
| 2 | 2 casas aleatórias lacram por mesa (fluxo `chefe`) | geométrico |
| 3 | Colunas pagam −1 mult | **numérico declarado** |
| 4 | Cartas colhidas não voltam ao baralho da mesa seguinte | geométrico |
| 5 | A loja perde a vaga 2 | geométrico |
| 6 | Cruzada só soma mults se as mãos forem de categorias diferentes | geométrico |
| 7 | Uma linha morre permanentemente por rodada (respeitado o invariante R19) | geométrico |
| 8 | Metas ×1,25 | **numérico declarado** |

Toda combinação de sliders é legal; a coleção base **nunca** exige Geometria > 1. Um degrau de preset por vitória, reversível, nunca obrigatório.

### 7.2 Rede de segurança (cada item é código, não intenção)

| Dispositivo | Regra exata |
|---|---|
| **Colheita final** | R14b, com a semântica completa escrita lá: linha com ≥ 3 cartas paga 50% no fim de toda mesa |
| **Fiança** | 3 luzes. Acende 1 ao **perder uma mesa**, ao a **R41 declarar meta fora de alcance**, ou ao um **4/5 valendo > 300 pontos previstos ser demolido por uma colheita que o jogador NÃO escolheu** (Maré, Gulosa, cascata, empurrão). **Nunca acende por demolição que o próprio posicionamento do jogador causou. Máximo 1 luz por mesa.** Com as 3 acesas, a próxima colheita paga **+100%** e as luzes zeram. As luzes **persistem entre mesas** e **zeram entre runs** |
| **Vidas** | 3 por run no modo Mesa; perder gasta 1 e repete com a seed derivada da R10 |
| **Segunda mão** (catraca) | Repetir a mesma mesa concede **+1 posicionamento cumulativo por tentativa (teto +3)** e mantém os Ofícios não usados. A frase é `Mesma mesa, mais uma carta na manga.` **Nunca reduz a meta** — o jogador recebe ferramenta, não desconto |
| **Quase lá** | Derrota com ≥ 80% da meta **devolve a vida** e paga o dinheiro cheio |
| **Retentativa barata** | "Repetir mesa" em 1 clique, sem confirmação; "Nova run com esta seed" ao lado; e **"Reiniciar mesa" também dentro da pausa**, não só no postmortem |
| **Meta fora de alcance** | R41 + botão "Encerrar agora" |
| **Janela de arrependimento** | R35, sem modal |
| **Autópsia com porcentagem** | Toda derrota imprime a conta real: "a carta que fechava a cruzada em C3 era qualquer 9 — 3 em 34 (8,8%), e você tinha 6 compras" |
| **"A cruzada que estava na mesa"** | Roda ao fim de **TODA** mesa, **vitória inclusive**. Busca **exaustiva** sobre o estado final cruzando **as 5 cartas da mão com as casas vazias** (≈ 5 × 17 = **85 candidatas**, 2 a 4 avaliações O(5) cada), uma vez, fora do loop. A melhor cruzada que existia e **não** foi feita vira **carimbo fantasma** (cinza, contorno tracejado) na célula correspondente da Matriz, com a coordenada e a carta. **O jogador coleciona os quase-acertos**, e completar a célula de verdade substitui o fantasma. O nome é literal |
| **Aviso de demolição** | Só quando mata perpendicular em 4/5 valendo > 300 pontos. **Nunca em cruzada** |
| **Separação temporal estrita** | Pagamento e voo de fichas terminam **antes** de qualquer atualização perpendicular. Prêmio e perda nunca no mesmo quadro |
| **Descarga nomeada** | Quando nenhuma jogada é boa, a linha-lixeira é destacada como "Descarga · ~55 pts" |
| **Sem relógio** | Nenhum timer em nenhum modo; a pressão é orçamentária |

**Justificativa da Fiança, a escrever no `DESIGN.md`:** a R17 demole 4/5 **por design** em toda colheita; premiar isso transformaria a autossabotagem na estratégia ótima — por isso a Fiança só acende em perda que o jogador **não** escolheu, e no máximo uma vez por mesa.

### 7.3 Compras Assistidas (ajuda dinâmica invisível)

Roda em Estufa e Mesa; **desligada** no Diário, no Infinito e em Geometria ≥ 3; interruptor neutro em Configurações. **Gatilho:** déficit `D = pontos / meta` com ≤ 40% dos posicionamentos restantes, agindo só se `D < 0,45`. **Ação única:** enviesa a **compra**, jamais pontuação, meta ou loja — **se a carta sorteada não levar nenhuma linha viva a 4/5 nem melhorar a categoria GARANTIDA de nenhuma linha viva**, sorteia **uma vez** de novo no fluxo `ajuda` (o cursor avança 2 e isso é gravado, para o replay reproduzir). **Proibições:** nunca age nos 3 primeiros posicionamentos nem em duas mesas seguidas já vencidas; **pode dar a carta que fecha cruzada no máximo 1× por run** (negar sistematicamente o melhor resultado a quem está perdendo é punição invisível, exatamente o oposto do que esta seção promete). **Tetos: 2 por mesa, 6 por run**, expostos ao teste. `testar.sh` falha se a política gulosa vencer mais de **8 pontos percentuais** acima dela mesma com a ajuda desligada.

### 7.4 Bandas de aceite (10.000 runs, política gulosa) — e o que fazer quando não fecham

**Bandas medidas pelo `--exigir`:**

1. Vitória por mesa **≥ 60% (Mesa)** e **≥ 90% (Estufa)** em toda rodada.
2. Mediana de cruzadas por mesa **1,5–2,5**.
3. Razão cruzada ÷ duas linhas simples **1,6×–2,2×**.
4. Despejo puro **< 25%**. **Definição, para a banda não ser interpretável:** *despejo puro* = posicionamento que não fecha nenhuma linha **e** não melhora a categoria **garantida** de nenhuma linha viva **e** não leva nenhuma linha viva de 3/5 a 4/5.
5. **Candidatas honestas** (a proxy que substitui "turno mediano ≤ 6 s", que mede humano e a frota não tem): número de casas com halo verde ou amarelo cujo delta de pontos está a **≤ 20% do melhor**. Banda: **mediana entre 5 e 8 por turno**.
6. Pulso audível da compra **≤ 35%** das compras.
7. **Banda da profundidade** — `politica.gd` implementa três políticas: `anel1` (sempre a jogada de maior delta imediato, isto é, o anel #1 da UI), `gulosa` (a padrão, com desconto de dano perpendicular) e `aleatoria`. **Exigência: em 10.000 runs, `gulosa` vence pelo menos 12 pontos percentuais mais mesas que `anel1`.** Se `anel1` chegar a menos de 4 pontos de `gulosa`, **o jogo está resolvido pela UI e o build REPROVA** — e a correção permitida é **aumentar o peso do custo espacial (R17)**, nunca esconder os anéis. As bandas 1–6 rodam também com as assistências **desligadas**.
8. **Detector de conteúdo morto e dominante** — nenhum item comprável pode ser adquirido em **< 3%** das runs em que apareceu na loja (morto) nem em **> 45%** (dominante); `--exigir` reprova **e nomeia o item**.
9. **Fianças completadas por run:** mediana **0,6–1,4**; acima de 2, o dispositivo virou motor e a regra da §7.2 está mal implementada.
10. **Acionamento da ajuda** em mesas com `D < 0,45`: **0,5–2,0 por mesa**; abaixo de 0,2 o dispositivo é letra morta e o build reprova.
11. **O teto do mult morde em ≤ 8% dos eventos.**
12. **Travamentos = 0** na varredura da §15.3.

**Algoritmo e válvula (isto é o que impede o laço infinito da Etapa 11).** `relatorio_balanceamento.py --exigir` roda `--ajustar` em no máximo **12 iterações de descida coordenada** sobre esta lista **fechada**, nesta ordem, com faixa e passo:

`juros_teto` [2..6, passo 1] → `preco_selo_comum` [4..7, passo 1] → `dinheiro_chefe` [4..7, passo 1] → `passo_fichas` da 5.1 [0,25..0,45, passo 0,05] → `passo_mult` [1..2, passo 1] → base da curva de metas [1,36..1,46, passo 0,02].

Após 12 iterações sem convergir, **grave a melhor configuração e as métricas medidas** em `AUDITORIA.md` sob `BALANCEAMENTO — bandas não atingidas — <lista com valor medido × banda>`, rode com `--tolerancia 15%` e **SIGA**. **Bandas não atingidas com registro NÃO reprovam a entrega; bandas não medidas reprovam.**

---

## 8. CONTEÚDO

**Escopo em lotes, e o lote é barreira.** **Lote 0** (mínimo jogável, Etapa 6): 8 selos de casa, 3 de eixo, 4 relíquias, 4 modificadores de mesa. **Lote 1** (obrigatório para o DoD): os 14 selos de casa, 8 de eixo, 7 relíquias, 6 chefes, 5 Fardos, 22 Cartas de Ofício, 8 baralhos, 16 modificadores e 12 motores listados abaixo. **Lote 2** (só depois de a mesa padrão passar em todas as bandas da 7.4, e **primeiro item da ordem de sacrifício da §16.1**): completar 32 selos de casa, 16 de eixo, 18 relíquias, 10 Fardos — raridade Comum 48% / Raro 38% / Épico 14%.

**Template obrigatório de todo item** (`dados/selos.json`, `reliquias.json`, `fardos.json`, `oficios.json`, `chefes.json`, `modificadores.json`) — **15 campos, enumerados aqui porque `validar_dados.py` conta:**

`{ id, nome, familia, raridade, custo, alvo (casa|linha|coluna|diagonal|global), efeito_txt (≤6 palavras, chave i18n), opcode (da §8.0), params, eixo_de_efeito (geometrico|numerico), icone, borda (casos-limite por escrito), sinergia, desbloqueio, testes }`

**Item sem `borda` escrita não é implementado** — `validar_dados.py` reprova o build. A cobertura par a par é **gerada**, não escrita à mão (§15.5).

**Cota de geometria, medida:** `eixo_de_efeito = geometrico` significa **mudar o que uma linha PODE virar** (naipe, valor, adjacência, permanência, condição de fechamento, quem participa); `numerico` significa **somar fichas, mult ou %**. `validar_dados.py` **reprova o build se `numerico` passar de 40% de qualquer categoria** (selos de casa, selos de eixo, relíquias, Ofícios, modificadores). É essa regra, e não uma promessa de texto, que sustenta o item 5 da §4.5.

### 8.0 Vocabulário fechado de opcodes (sem isto, cada agente inventa uma máquina virtual diferente)

`scripts/nucleo/selos.gd` é **um único `match`** mapeando `opcode` → fase da R40. **Nenhum item entra em `dados/*.json` com opcode fora desta lista**; para um efeito novo, primeiro **adicione o opcode aqui e ao interpretador**, depois autore o item. **Efeito em script solto reprova o build.**

| Opcode | Fase da R40 | Params | Usado por |
|---|---|---|---|
| `VALOR_EFETIVO_COPIA` | valor efetivo | `{direcao}` | Espelho |
| `NAIPE_CURINGA` | naipe efetivo | — | Ímã |
| `FICHAS_MUL` | multiplicadores de casa | `{fator}` | Brasa |
| `FICHAS_MUL_COND` | multiplicadores de casa | `{cond, fator, fator_inverso}` | Xadrez |
| `FICHAS_ADD` | multiplicadores de casa | `{n}` | genérico |
| `FICHAS_ADD_POR_COLHEITA` | multiplicadores de casa | `{n}` | Raiz |
| `MULT_ADD` | avaliação | `{n}` | Vidro, Trilho de Ouro |
| `MULT_ADD_POR_SELO_NO_EIXO` | avaliação | `{n}` | Bordado |
| `MULT_ADD_SE_CRUZADA` | avaliação | `{n}` | Nó de Ouro |
| `BONUS_PCT_SE` | pontuação | `{cond ∈ (naipe_unico, sequencia), pct}` | Vinco, Fita Métrica |
| `TEAR_ADD` | pontuação | `{n, limite_por_mesa}` | Fole, Nó Cego |
| `TEAR_TETO` / `TEAR_INICIAL` | início de mesa | `{n}` | Balança, Tear Quente, Do Tear |
| `DINHEIRO_ADD` | pontuação | `{n}` | Sino |
| `NAO_REMOVE` | remoção | — | Âncora |
| `NAO_EMPURRA` | empurrões | — | Bigorna |
| `VOLTA_PARA_MAO` | remoção | — | Alçapão |
| `DEVOLVE_POSIC` | pontuação | `{n, max_por_mesa}` | Sirga, Faminta |
| `REVELA_OUTS` | leitura (não pontua) | `{escopo}` | Lupa |
| `QUEBRA_APOS` | quebras | `{n}` | Vidro, Vidraça |
| `CONTA_EM_DIAGONAIS` | detecção de fechamento | — | Carimbo |
| `DIAGONAIS_INTEGRAIS` | pontuação | — | Bússola, Trama |
| `DIAGONAIS_OFF` | detecção de fechamento | — | Cega |
| `GUARDA_FICHAS` | pontuação | — | Cofre |
| `ACEITA_DA_PILHA` | preenchimento | `{n}` | Lançadeira |
| `IGNORA_DEMOLICAO` | remoção | `{n}` | Muralha |
| `PAGA_FINAL_INTEGRAL` | colheita final | — | Contrapeso |
| `LACRAR_CASAS` | início de mesa | `{lista ou n_aleatorio}` | Rachada, Furada, grau 2 |
| `EIXO_MORTO` | início de mesa | `{eixos}` | Torta, grau 7 |
| `EMPURRAR` | empurrões | `{direcao}` | Esteira |
| `QUEIMAR_ANTIGA` | início de turno | `{a_cada}` | Gulosa |
| `COLHER_MAIS_VAZIA` | início de turno | `{a_cada}` | Maré |
| `SEMEAR` | preenchimento | `{n}` | Muda, Ofício Semear |
| `META_MUL` | início de mesa | `{fator}` | Furada, grau 8 |
| `ORCAMENTO_ADD` | início de mesa | `{n}` | Furada, grau 1, Estufa |
| `CILINDRO` | detecção de fechamento | `{eixos}` | Fita |
| `CATEGORIA_ESPELHADA` | detecção de fechamento | `{eixos}` | Espelhada |
| `MOVE_CARTA` / `DESTROI_CARTA` / `DEVOLVE_CARTA` | fora do turno | `{n}` | Guindaste, Tesoura, Descosturar |

### 8.1 Selos de casa

| Nome | Rar. | $ | Efeito | Eixo |
|---|---|---|---|---|
| Brasa | C | 5 | Fichas da carta desta casa ×2 | numérico |
| Vidro | C | 5 | +2 mult nas duas mãos; quebra em 3 colheitas | numérico |
| Bigorna | C | 5 | A carta aqui não é empurrada nem queimada | geométrico |
| Fole | C | 5 | +1 no Tear quando esta casa colhe (1×/mesa) | geométrico |
| Lupa | C | 5 | Mostra os outs da linha e da coluna | geométrico |
| Sino | C | 5 | +$1 quando esta casa participa de colheita | numérico |
| Alçapão | C | 5 | Ao colher, esta carta volta para a mão | geométrico |
| Ímã | R | 7 | A carta aqui conta como qualquer naipe | geométrico |
| Espelho | R | 7 | Copia o valor da carta vizinha | geométrico |
| Raiz | R | 7 | +5 fichas por colheita já feita na mesa | numérico |
| Bordado | R | 7 | +1 mult por selo colado no mesmo eixo | numérico |
| Âncora | E | 9 | A carta não sai na colheita | geométrico |
| Carimbo | E | 9 | **A carta aqui conta nas 2 diagonais mesmo fora delas** | geométrico |
| Nó de Ouro | E | 9 | Cruzada que passa aqui soma +4 no mult | numérico |

6 numéricos em 14 = **43%** — acima da cota de 40%, então **um dos seis vira geométrico no Lote 1**: reescreva **Raiz** como `+5 fichas por colheita já feita **nesta linha ou coluna**` e marque-a `geometrico` (o efeito passa a depender de onde a casa está), ou corte-a do Lote 1. `validar_dados.py` decide, não a opinião.

### 8.2 Selos de eixo

| Nome | Rar. | $ | Efeito | Eixo |
|---|---|---|---|---|
| Trilho de Ouro | R | 6 | +3 mult neste eixo | numérico |
| Cofre | R | 6 | Guarda fichas e paga dobrado na colheita seguinte | geométrico |
| Lançadeira | R | 6 | 1×/mesa, aceita carta da pilha colhida como 5ª | geométrico |
| Muralha | R | 6 | 1×/mesa, ignora uma demolição perpendicular | geométrico |
| Contrapeso | R | 6 | Na colheita final paga 100%, não 50% | geométrico |
| Vinco | C | 6 | +25% se fechar com naipe único | numérico |
| Fita Métrica | C | 6 | +25% se fechar com sequência | numérico |
| Sirga | C | 6 | **Colher aqui devolve 2 posicionamentos, no máximo 2× por mesa** | geométrico |

**Corte declarado:** o selo **Funil** ("coluna fecha com 4 e a 5ª é curinga") **não existe** — contradiz a frase única e derruba a prova de fechamento. A Lançadeira ocupa o nicho mantendo as 5 cartas. Registre o corte no `DESIGN.md`.

### 8.2b Motores (`dados/motores.json`) — o que troca "lista de bônus somados" por descoberta

Declare **no mínimo 12** combinações de **2 itens** que formam um motor nomeado, cada uma com: `nome` (≤3 palavras), `pecas` (2 ids), `laco` (a frase que descreve o loop que ela cria), `rodada_viavel` (quando o dinheiro permite), `teto` (o maior evento que ela produz) e `teste` (uma seed em que ela dispara). **≥ 8 dos 12 precisam ser geográficos** — dependerem de **ONDE** as peças estão coladas, não só de possuí-las.

| Motor | Peças | Laço | Geográfico |
|---|---|---|---|
| **Forja** | Brasa + Trilho de Ouro (mesmo eixo) | a casa dobrada paga num eixo que já vale +3 mult | sim |
| **Espelho d'Água** | Espelho + Ímã (adjacentes) | valor copiado e naipe livre na mesma dupla: quadra e flush pela mesma carta | sim |
| **Bordado Fechado** | Bordado + 3 selos no mesmo eixo | cada selo novo do eixo sobe o mult de todos | sim |
| **Cofre Ancorado** | Cofre (eixo) + Âncora (casa desse eixo) | a âncora garante a segunda colheita, e ela vem dobrada | sim |
| **Sino de Ouro** | Sino + Nó de Ouro (mesma casa) | toda cruzada que passa ali paga +4 mult e $1 | sim |
| **Cruz do Carimbo** | Carimbo + Bússola | a casa passa a contar em 4 linhas, todas integrais | sim |
| **Lançadeira Vidrada** | Lançadeira + Vidro (mesmo eixo) | a 5ª carta vem da pilha antes de o Vidro quebrar | sim |
| **Sirga Faminta** | Sirga + Ofício Semear (no eixo da Sirga) | colher devolve posicionamento que o Semear já gastou | sim |
| **Muralha do Tear** | Muralha + Fole (mesmo eixo) | o eixo sobrevive à demolição e sobe o Tear de novo | sim |
| **Contrapeso Cheio** | Contrapeso + Alçapão | a linha guardada paga 100% no fim, com a carta de volta na mão | sim |
| **Fole e Balança** | Fole + Balança | o Tear sobe 2 por colheita e o teto sobe junto | não |
| **Raiz Profunda** | Raiz + Dedal | a primeira colheita já vale +50% e alimenta as seguintes | não |

**Quando as duas peças estão em jogo e o motor dispara pela primeira vez numa mesa**, o nome aparece por **900 ms em moldura de cobre, sem modal**, e é carimbado numa aba nova da Coleção (`Motores`, 12+ células).

### 8.3 Relíquias globais

| Nome | Rar. | $ | Efeito | Eixo |
|---|---|---|---|---|
| Bússola | E | 8 | **As diagonais pagam 100%** | geométrico |
| Régua | R | 8 | Mão de 6 cartas | geométrico |
| Guindaste | R | 8 | 1×/mesa, move uma carta posicionada | geométrico |
| Balança | R | 8 | A cada 2 colheitas, +1 no Tear e no teto | numérico |
| Tesoura | R | 8 | 1×/mesa, destrói uma carta posicionada | geométrico |
| Novelo | C | 8 | +1 descarte; descarte troca até 4 | geométrico |
| Dedal | C | 8 | Primeira colheita da mesa paga +50% | numérico |

**Corte declarado:** a relíquia **Nível** **não existe** — a contagem de cartas restantes é **grátis e permanente** no HUD (Baralho Aberto: 4 contadores de naipe + histograma de 13 valores). Vender legibilidade é proibido.

### 8.4 Regras de borda já resolvidas (copie para o `DESIGN.md` e teste uma a uma)

- **Espelho** copia o valor do vizinho **à esquerda**; na coluna A, ou com o vizinho esquerdo vazio, copia o **da direita**; ambos vazios, vale o próprio valor. **No eixo perpendicular (coluna e diagonais) o Espelho carrega o valor copiado** — é a mesma carta, com o mesmo valor efetivo, em todas as linhas de que participa. Uma frase, um teste (`_espelho_carrega_valor_na_coluna`).
- **Máximo 2 Ímãs por eixo** (`pode_colar()` recusa o 3º); o avaliador testa só os naipes presentes.
- **Âncora:** máx. 1 por linha e 1 por coluna. **A linha que colheu com uma âncora fica em 1/5 e NÃO pode fechar de novo no mesmo turno**; a âncora conta normalmente para os fechamentos seguintes. Em **cruzada**, a carta ancorada fica e conta para as duas linhas seguintes. Duas Âncoras na mesma linha são proibidas pelo gerador (motor degenerado). Teste `_ancora_nao_faz_renda_infinita`: 200 turnos com âncora em linha e coluna, verificando que nenhuma linha colhe duas vezes no mesmo posicionamento.
- **Vidro** que participa de duas colheitas no mesmo evento conta **1** quebra.
- **Cofre** não pago até o fim paga em dobro na **colheita final**. Em cruzada, Cofre e Lançadeira somam **fichas** ao evento, **nunca mult**.
- **Brasa + Molhada:** metade primeiro, ×2 depois.
- **Selo em casa lacrada pelo chefe:** inerte, e a loja devolve **100%**.
- **Carimbo numa casa que já é diagonal:** não duplica — a carta conta **uma vez** em cada uma das 2 diagonais, e `mascara_participantes` é a prova.
- **Diagonal + Contrapeso:** o eixo do Contrapeso pode ser uma diagonal; nesse caso a colheita final paga `1,0 × 0,60`, não `1,0`.

---
### 8.5 Cartas de Ofício (consumíveis) — 22 itens, 2 slots

Fontes: 1 das 3 opções da Cartela pós-Pequena, e **toda colheita de Quadra ou melhor concede 1**. Uso grátis, fora do turno, nunca gasta posicionamento.

| Família | Cartas |
|---|---|
| **Agulhas** | Descosturar (devolve 1 carta da grade à mão) · Transplante (troca 2 cartas posicionadas) · Semear (preenche 2 casas com o topo do baralho) · Lacre (lacra 1 casa até o fim da mesa e paga $2) |
| **Linhas** | Sósia (copia uma carta da mão sobre outra) · Peneira (descarta a mão e compra 5 sem gastar descarte) · Chamado (puxa a carta do valor declarado mais próxima) · Tingir (muda o naipe de 1 carta da mão) |
| **Nós** | Nó Cego (+3 no Tear agora) · Cruz de Sal (+4 no mult da próxima cruzada) · Contra-Nó (cancela o modificador desta mesa) · **Marcar** (declara a categoria de uma linha; cumprindo aquela categoria ou acima, a colheita paga +50%; falhando, **nada acontece** — sem punição) |

**Estouro dos 2 slots, resolvido:** Ofício ganho com os dois slots cheios abre, **ao fim da animação de colheita e fora do loop de turno**, uma escolha de **3 s sem modal** na faixa do rodapé: **usar agora**, **trocar por um dos dois**, ou **converter em $2**. Sem resposta em 3 s, converte em $2 automaticamente e a moeda voa. **Nada é perdido em silêncio** — perda invisível de recompensa reprova pela §8.11.

As 10 restantes até 22 são de sua autoria, no mesmo template, nas mesmas famílias, respeitando a cota de geometria da §8. Se o simulador medir a mediana de candidatas honestas fora da banda com **Marcar** em uso, corte-a e registre o corte.

### 8.6 Baralhos iniciais (8) — **todo baralho carrega `rota`**

`validar_dados.py` **reprova baralho sem `rota`** (a sequência de decisões que garante o desbloqueio) e sem um teste que o alcança em ≤ 20 seeds. Condições circulares ou dependentes de sorte pura estão proibidas — foi por isso que duas mudaram.

| Baralho | Mudança | Desbloqueio |
|---|---|---|
| Da Casa | 52 cartas, padrão | inicial |
| Curto | Sem 2, 3 e 4 (40 cartas): mais fichas, menos sequências | vencer 1 Chefe |
| Torto | 2 curingas de naipe; −1 descarte | **3 flushes numa run** |
| Do Tear | Tear começa em 2, teto 10; metas ×1,05 | Tear 6 numa mesa |
| Marcado | Nasce com Brasa em C3; loja +$1 | 8 selos numa run |
| Vermelho | Só copas e ouros (26 valores ×2); metas ×1,15 | 1 Sequência de Cor |
| Da Bússola | Diagonais pagam 100%; 2 casas lacradas | **6 cruzadas numa run** |
| Da Viúva | Mão de 6; −2 posicionamentos por mesa | vencer uma run |

Cada baralho guarda **recorde próprio** (melhor run, melhor mesa, maior cruzada) e placar próprio no Infinito.

### 8.7 Modificadores de mesa (16, sendo 4 no Lote 0)

**REGRA DE SANIDADE DE MODIFICADOR — nenhum modificador pode:** (a) impedir uma linha de chegar a 5 cartas; (b) tornar uma casa vazia **ilegal** para alguma carta da mão; (c) derrubar as linhas vivas abaixo do piso da R19. `validar_dados.py` **reprova** o modificador que violar qualquer uma das três, e a varredura da R19b prova em execução.

| Nome | Regra | Eixo |
|---|---|---|
| **Rachada** L0 | As 4 quinas nascem lacradas | geométrico |
| **Torta** L0 | Só as 5 horizontais pontuam | geométrico |
| **Molhada** L0 | Cartas nas 16 casas de borda valem metade das fichas | geométrico |
| **Gulosa** L0 | A cada 3 posicionamentos a carta **mais antiga** queima | geométrico |
| Esteira | Cada posicionamento empurra a carta à direita uma casa | geométrico |
| Espelhada | Linhas 1 e 5 só pontuam na mesma categoria | **numérico declarado** |
| Fita | Colunas A e E são **a mesma coluna** (cilindro) | geométrico |
| Trama | As 2 diagonais pagam 100%; as colunas pagam 80% | geométrico |
| Cega | As 2 diagonais não pontuam nesta mesa | geométrico |
| **Furada** | A casa **C3 nasce lacrada**: a linha 3, a coluna C e as 2 diagonais morrem. 8 linhas vivas, orçamento −3, meta ×0,80 | **numérico declarado** |
| Tear Quente | O Tear começa em 3 e não tem teto | **numérico declarado** |
| Faminta | Cada colheita devolve 1 posicionamento (teto global da §6.3) | geométrico |
| Vidraça | Coluna C ganha +2 mult, quebra após 2 colheitas | **numérico declarado** |
| Xadrez | Casa escura com carta vermelha e casa clara com carta preta valem **fichas ×1,5**; o inverso vale **×0,6**. **Nenhuma casa é ilegal** | geométrico |
| Maré | A cada 5 posicionamentos a linha viva **mais vazia** é colhida | geométrico |
| Muda | A mesa nasce com 5 cartas semeadas pela seed | geométrico |

**Cortes e renomeações declarados, com o motivo:** **Enxuta** ("grade 4×4") **não existe** — numa grade 4×4 nenhuma linha chega a 5 cartas, nenhuma colheita acontece e a mesa é invencível; **Furada** ocupa o nicho de "menos espaço, meta menor" sem quebrar o fechamento. **Xadrez** deixou de tornar casas ilegais (mão inteiramente de uma cor + só casas da cor errada + descartes esgotados = zero jogadas legais contra a R06, que obriga a posicionar) e passou a ser um multiplicador de fichas. O modificador antes chamado **Ímã** virou **Esteira**: o **selo** Ímã é referenciado pelo nome na R40, na §5.2, na §8.4 e no replay da §4.4, então quem muda de nome é o modificador — dois itens com o mesmo `id` reprovam em `validar_dados.py`, e renomear o selo em silêncio quebraria quatro referências cruzadas. **Costura** e **Nó** sumiram por redundância: com a R03b as diagonais já são vivas, então o nicho passou a ser **Trama** (sobe) e **Cega** (desliga).

**Empates são resolvidos por regra, nunca por ordem de iteração de dicionário** (que quebraria o determinismo): "mais antiga" = **menor índice de posicionamento**; "mais vazia" = **menos cartas**, desempatado pelo **menor índice de linha** na ordem canônica `linhas 1..5, colunas A..E, diagonal principal, diagonal secundária`.

**Pequena e Grande sorteiam 1 dos 16 modificadores** (a primeira mesa da rodada 1 não sorteia nenhum, §6.4). **A mesa Chefe não sorteia modificador: ela usa o chefe da rodada (§8.7b).** No Infinito, máximo 2 por mesa, e o gerador **proíbe** pares que derrubem as linhas vivas abaixo do piso da R19.

### 8.7b Os seis chefes (`dados/chefes.json`)

Um por rodada, **em ordem fixa**, **exclusivos da terceira mesa** — nunca sorteados em Pequena ou Grande. Em Balatro o Boss Blind **é** a identidade do ante; aqui a rodada precisa da mesma assinatura. Cada chefe tem `id`, `nome`, `regra` (geométrica, nunca número puro), `fala` (≤ 6 palavras, mostrada 1,2 s antes da mesa, **nunca modal**), `icone` (silhueta 24×24), `counter_play` (a frase que diz o que fazer contra ele, exibida no `mapa` **desde a rodada anterior**) e `teste` (uma seed que o vence, encontrada pelo simulador e gravada no JSON).

| # | Nome | Regra | Fala | Counter-play |
|---|---|---|---|---|
| 1 | **A Tesoura** | A cada 4 posicionamentos, a linha viva mais cheia perde a carta mais antiga | "Nada aqui dura muito." | "Feche cedo. Não acumule 4/5." |
| 2 | **O Prumo** | As colunas não pontuam até a primeira colheita horizontal | "Primeiro a linha. Depois a coluna." | "Abra com uma horizontal barata." |
| 3 | **A Ourela** | As colunas A e E só pontuam se fecharem com naipe único | "As beiras cobram caro." | "Guarde naipe puro para as beiradas." |
| 4 | **A Lançadeira Quebrada** | Cada colheita devolve 1 carta colhida ao topo do baralho: o baralho não afina | "Nada sai desta mesa." | "Conte com repetição: par e trinca." |
| 5 | **O Espelho Torto** | Ao colher a linha `n`, a linha `6−n` perde a carta mais nova | "Toda colheita tem eco." | "Colha de fora para dentro." |
| 6 | **O Tear Preso** | O Tear só sobe em cruzada; colheita simples não o move | "Só cruz levanta o tear." | "Monte duas linhas antes de fechar uma." |

**Antipadrão:** chefe sem `counter_play` declarado e testado **reprova a entrega** (§19).

### 8.8 Fardos do Infinito (bônus + ônus, 1 de 3 a cada 3 rodadas)

Tear de Chumbo (teto do Tear vira 16 / só sobe em cruzada) · Casa Queimada (+6 mult global / 1 casa lacra por rodada) · Mão Larga (mão de 7 / −2 posicionamentos) · Naipe Único (Flush paga ×2 / Sequência de Cor não existe) · Faca de Dois Gumes (cruzada +30% / linha simples −20%).

### 8.9 Coleção, Estante e conquistas

**O total do acervo é CALCULADO, nunca escrito.** `Catalogo.total_fichas()` soma o que existe em `dados/*.json` em tempo de execução; **número de acervo escrito no código ou na UI reprova o build** (`validar_estilo.py` o trata como número mágico). Com só o Lote 1 o acervo é menor e a tela de coleção continua correta — que é exatamente o caminho mais provável depois da §16.1. O cabeçalho mostra `Descoberto: 137/<total> (51%) · 62 em Mesa`.

**Matriz de Cruzadas:** grade simétrica **11×11** (categoria da linha × da coluna), carimbo espelhado nas duas células com coordenada, carta e pontos ("9♦ em C3 — 2.964"). São 66 pares únicos; os 11 com Quina entram quando a rota é desbloqueada. Célula vazia pode conter o **carimbo fantasma** da §7.2.

**Marca de modo, para a Estufa não tornar a Mesa inútil:** cada célula da Matriz e cada conquista guarda **o modo em que foi conquistada**; carimbo feito em **Mesa** tem borda dourada, em **Estufa** tem borda de linha simples. **Nenhum conteúdo é exclusivo de modo algum — a diferença é só a marca.** Isso preserva integralmente a promessa de que a dificuldade é opcional e ainda assim dá motivo para subir.

**Regra da Estante (`scripts/nucleo/estante.gd`):** o menu mostra sempre **exatamente 3 cartões** de desbloqueio, com barra e condição em ≤ 8 palavras, ordenados por proximidade. **Invariante testável: 1 dos 3 sempre ≥ 60% concluído e ≥ 1 concluível em 2 runs medianas.** Sem oferta no pool, injeta-se um alvo raso da reserva. Quebrar isso reprova o `testar.sh`.

**Novelos, com a conta fechada:** +1 por mesa vencida (teto 12/run), +3 por run terminada (vitória **ou** derrota), +5 pelo Diário; **24 Novelos revelam qualquer silhueta à escolha**. Uma run vencida rende **15**, logo o caminho de consolo entrega ~**0,6 revelação por run**. **Cadência-alvo de DESBLOQUEIOS (todas as fontes, naturais + Novelos): 2,4 por run nas runs 1–10; 1,3 nas 11–25; 0,8 nas 26–60** — os outros ~1,8 vêm de condições naturais. Teste `_acervo_esgota_em_60_runs`: simula 60 runs com a política gulosa e **falha se o acervo fechar antes de 45 ou depois de 80**.

**Três estados de ficha:** *Silhueta* (forma escurecida + família + raridade + pista de 3 palavras), *Vista* (cinza), *Possuída* (texto completo, borda e uso: "colado 14× · 3 cruzadas"). Nenhuma silhueta é 100% misteriosa.

**Conquistas — predicados, não roteiros.** Conquista é um **predicado sobre `Progresso.estatisticas`**, escrito em `dados/conquistas.json` como `{campo, operador, valor}`. **O teste não joga a run:** injeta estatísticas sintéticas e verifica que o predicado dispara e que a tela de coleção a mostra. O campo `rota` passa a ser **texto de dica em ≤ 8 palavras**, não sequência determinística de decisões. **12 conquistas (a família Progressão) são obrigatórias e vêm com a condição escrita abaixo; as outras 36 são Lote 2, cortáveis pela §16.1.**

| Conquista | Predicado |
|---|---|
| Primeiro Fio | `mesas_vencidas >= 1` |
| Tecelã Aprendiz | `runs_vencidas >= 1` |
| Meia Trama | `mesas_vencidas >= 18` |
| Tear Completo | `tear_maximo >= 8` |
| Fio de Prata | `pontos_max_mesa >= 10000` |
| Fio de Ouro | `maior_cruzada_pontos >= 5000` |
| Tear de Ouro | `runs_vencidas >= 5` |
| Casa Cheia de Casas | `casas_com_selo_distintas >= 25` |
| Mapa Vivo | `max_selos_numa_run >= 9` |
| Feira Livre | `compras_na_loja >= 100` |
| Todo Mundo Volta | `runs_iniciadas >= 10` |
| Estante Aberta | `itens_descobertos >= 30` |

As 36 do Lote 2 (Maestria 16, Curiosidade 12, Piadas 8) reaproveitam os nomes já batizados — Cruz de Ferro, Cruz de Ouro, Nó Perfeito, Avarento, C3 Sagrado, Nunca no Centro, Cabeça de Bagre, Insônia do Tear, Guarda-Chuva, Arrependido e as demais — cada uma com seu predicado escrito no mesmo formato.

**34 estatísticas rastreadas** em `Progresso.estatisticas`, e os 12 predicados acima só podem usar campos desta lista: runs iniciadas/vencidas, vitória % por baralho e por Tabuleiro, tempo jogado, mesas vencidas, pontuação máxima de mesa e de run, maior cruzada (coordenada + carta), Tear máximo, colheitas por categoria, **mão favorita** (mais colhida), **mão traidora** (mais perdida em 4/5), mediana de cruzadas, 25 contadores por casa, casas com selo distintas, máximo de selos numa run, compras na loja, itens descobertos, dinheiro, descartes, Fianças, Novelos, motores disparados, turno mediano, sequência do Diário.

### 8.10 Diário, Infinito e Zen

**Diário, sem servidor:** `data = ano*10000 + mes*100 + dia` em **UTC** (`Time.get_datetime_dict_from_system(true)`) e `semente_dia = fnv1a64("PLACARD-D1|" + str(data))` — FNV-1a 64 bits (offset `0xcbf29ce484222325`, primo `0x100000001b3`), com estouro natural do inteiro do GDScript, em `scripts/nucleo/semente.gd`, com **teste de vetor conhecido**. Dela saem os 6 fluxos por `mix(semente_dia, indice_do_fluxo)`. 1 tentativa oficial por dia (baralho e Tabuleiro fixos, Compras Assistidas desligadas) + **Treino ilimitado** na mesma seed, sem registro. Placar local em `user://placard_diario.json` (90 dias) com selo **"Limpo"** se a oficial veio antes de qualquer treino. **Replay:** base32 de `data + versão de regras + lista de (carta, casa)`; colar o código reproduz a partida e o jogo confere o hash final.

**Infinito** (desbloqueado na 1ª vitória): rodadas 7+ com `meta(r) = 5.975 × 1,42^(r-6) × (1 + 0,06 × (r-6))` — superlinearidade leve que mata a run entre as rodadas **12 e 18**. O `teto_do_evento` continua `24 + 4 × min(rodada, 12)`. O **Tear decai 50% entre mesas em vez de zerar**. Cada rodada sorteia +1 modificador (máx. 2 por mesa) e, a cada 3 rodadas, 1 de 3 Fardos permanentes. Perder congela e registra a **Marca d'Água** ("rodada 13 · 4,1M"); acima de 1e6, notação compacta. **Zen:** sem meta nem derrota, um recorde só — a maior cruzada da sua vida, exibida no menu.

### 8.11 Economia de recompensa psicológica (alvos medidos)

| Evento | Cadência-alvo | Aceite no simulador |
|---|---|---|
| Ping de out que leva a 4/5 | 1 a cada 25–40 s | **15–26%** das compras (falha > 45%) |
| Colheita | 1 a cada ~19 s | 3–5 por mesa |
| Cruzada | 1–2 por mesa | mediana 1,5–2,5 |
| Carimbo novo na Matriz | 2,8 por run | ≥ 1 em 90% das runs |
| Conquista | 1 a cada 1,6 run (runs 1–20) | ≥ 30 nas 40 primeiras runs |

**Marcos celebrados** (moldura dourada + acorde, 1,2 s, **nunca modal**): 1ª cruzada, 1ª quadra, Tear 5, 10.000 pontos numa mesa, recorde batido, **motor novo disparado**, 100% de uma aba.

**Regra do último gole:** toda run encerrada, vencida ou perdida — **inclusive abandonada pela pausa** —, dispara nesta ordem: colheita final em cascata → Novelos → carimbos novos (fantasmas incluídos) → recorde que subiu → cartão do próximo desbloqueio em X% → "De novo / Mesma seed". Sem carimbo, conquista nem recorde, concede-se o **Fio de Consolo**: +5 Novelos e uma silhueta revelada à escolha. **É asserção:** `fim_de_run.gd` falha em teste se a tela renderizar sem ao menos um item positivo.

---

## 9. TELAS E UX

Base 1280×720, `canvas_items`/`expand`. Toda tela é `Control` com âncoras — **nunca** posição absoluta em pixel no `.tscn` (os números abaixo são o layout resolvido em 720p). Toque mínimo 44×44 lógicos; alvo primário (casa, carta, botão) ≥ 64 px no menor lado. Fontes: 12 micro, 15 rótulo, 18 corpo, 24 H3, 32 H2, 48 H1, 72 logotipo. Contraste ≥ 4,5:1 (≥ 3:1 acima de 24 px), 7:1 em alto contraste.

**Cenas:** `abertura` (splash 1,6 s, logo em `_draw`) · `menu` · `modos` (3 cartões + 3 sliders + campo de seed) · **`partida`** · `loja` · `mapa` (trilha das 18 mesas + chefe da rodada com `counter_play` + painel com os selos posicionados numa grade 5×5) · `colecao` (abas Selos, Motores, Ofícios, Baralhos, Mesas, Matriz, Conquistas) · `conquistas` · `estatisticas` (mapa de calor 5×5, gráfico por rodada, barras por categoria, tudo em `_draw`) · `diario` · `opcoes` (6 abas) · `controles` · `creditos` · `pausa` (overlay em `CanvasLayer` 80, **nunca troca de cena**) · `postmortem` · `fim_de_run` · `tutorial` · `dados` · `testes` · `fluxo` · `simulacao` · `capturas`.

**Grafo de navegação** (`Navegacao.ir(nome, params)`: fade-out 0,12 s → `change_scene_to_file` → fade-in 0,12 s, pilha `historico`, `voltar()`; `Esc` volta um nível e na `partida` abre `pausa`):

```
abertura → tutorial (1ª execução, SEM passar pelo menu) → partida (run 1, sem clique)
abertura → menu (com save)
menu → modos → partida
menu → {diario → partida, colecao, conquistas, estatisticas, opcoes, creditos, dados}
partida ⇄ pausa (overlay)
pausa → {partida, opcoes, mapa, reiniciar_mesa (mesma seed, 1 clique, sem confirmação),
          abandonar_run (confirmar → fim_de_run), menu(confirmar)}
partida → postmortem → {loja (vitória), mapa (derrota com vida), fim_de_run (sem vida)}
loja → mapa → partida            fim_de_run → {modos (nova run), menu}
opcoes → controles → opcoes      qualquer tela → voltar() → tela anterior
```

**Abandonar run DEVE passar pelo `fim_de_run`** e disparar a regra do último gole: encerrar sem colheita final, sem Novelos e sem carimbo é o único caminho do jogo que termina em nada, e a §8.11 proíbe isso.

**Regra dura: nenhuma tela é beco sem saída.** `fluxo.tscn` percorre o grafo headless e falha se alguma cena não instancia, não tem foco inicial ou não responde a `ui_cancel`.

**Wireframe da partida (1280×720):**

| Região | x, y, w, h | Conteúdo |
|---|---|---|
| HUD superior | 0,0,1280,64 | Esq.: `PONTOS 1.180` (44 px) + barra de meta 320×14 com marcas em 25/50/75%; sob ela o **Mínimo Dourado** (§9.1). Centro: **TEAR ×3** (64 px). Dir.: `$12`, `POSIC. 8/19`, `DESCARTES 1/3`, 3 luzes de **Fiança**, pausa 48×48 |
| Receituário (esq.) | 0,64,300,532 | As 11 categorias fixas com `fichas × mult` **no nível atual da run**; a da prévia acende. Rodapé fixo: `mult da run: 31 / teto 48` (R15b). Abaixo, **Baralho Aberto** grátis: 4 contadores de naipe + histograma de 13 valores. **Colapsável** (§9.2) |
| Grade | 414,68,452,492 | 25 casas de **84×92**, gap 8 (`5×84+4×8 = 452`; `5×92+4×8 = 492`). Vazia = pontilhado; lacrada = hachura; com selo = ícone 20×20 na quina + moldura colorida; **as 9 casas diagonais levam um traço fino de 1 px no canto**, que é como a assimetria da R03b fica visível sem texto |
| Rótulos de linha | 874,68,102,492 | Badge 102×92: fração `4/5`, categoria **garantida** em texto e **alcançável** com `?` menor abaixo. Preenchimento por eixo (naipe = anel, valor = barra) |
| Rótulos de coluna | 414,560,452,36 | Idem, 84×36, colapsado (fração + sigilo) |
| **Rótulos de diagonal** | 874,560,102,36 | 2 badges de 48×36, gap 6, moldura tracejada e sufixo `60%` (ou `100%` com Bússola/Trama) |
| Prévia fantasma | 980,64,300,532 | Painéis **LINHA**, **COLUNA** e, quando houver, **DIAGONAL**, com 5 cartas em miniatura, categoria e `fichas × mult = pontos`, tudo lido da fita de `Mesa.simular()`. Fechando, o cabeçalho vira `COLHE` e um bloco lista o que sai das perpendiculares. Sem carta na mão, mostra a **Galeria de Cruzadas** da run; sem jogada boa, a **descarga nomeada** |
| **Minimapa da build** | 8,600,112,112 | Grade 5×5 de 20×20 px mostrando **só as casas com selo**, na cor da raridade. É o único lugar onde a forma da build está visível **durante** o jogo — sem ele a tese "a build tem formato" só existe entre as mesas |
| Trocar | 136,624,160,56 | `TROCAR ATÉ 3` |
| Mão | 408,600,464,116 | 5 cartas 80×112, gap 16 (`5×80+4×16 = 464`, centro em 640); até 3 **pontinhos de out** por carta (a cor diz se leva alguma linha a 4/5) |
| Voltar / Turbo | 1104,626,120,44 · 1232,626,44,44 | `VOLTAR` (cinza, discreto) e `TURBO` |

### 9.1 O Mínimo Dourado

Texto de 14 px em dourado sob a barra de meta: `faltam 1.892 — uma cruzada de Flush, ou duas trincas`. **Algoritmo, com custo limitado:** `Receita.para_deficit(deficit, tear, nivel_de_mao, rodada)` percorre a tabela da §5.1 **de cima para baixo** e devolve **no máximo duas** receitas — a menor cruzada de duas categorias que fecha o déficit e a menor repetição de uma categoria só —, montadas com fichas médias de 45 por mão. Custo: ≤ 121 avaliações aritméticas, **recalculado só quando `pontos` ou `tear` mudam**, nunca por quadro. Chaves i18n: `partida_minimo_cruzada` (`faltam %d — uma cruzada de %s`), `partida_minimo_repeticao` (`ou %d %s`), `partida_minimo_fora` (usa a frase da R41). **Sem receita possível, a R41 assume** — o campo nunca fica vazio nem mente.

### 9.2 O Receituário colapsa quando já ensinou

Depois que o jogador colhe **8 categorias distintas** (gravado no perfil), o Receituário colapsa por padrão para uma faixa de **120 px** (só a categoria da prévia, o `mult da run / teto` e o Baralho Aberto), devolvendo **180 px de largura**: a grade recentra em `x = 504` e os **rótulos de linha passam de 102 a 150 px**, ganhando a categoria por extenso em vez do rótulo de 4 letras. As casas **não** mudam de tamanho — a altura disponível continua 492 px e `5×104+4×8 = 552` não caberia. Alternável por clique e pela tecla `R`, estado salvo.

**Retrato (720×1280):** `layout.gd` troca a base lógica para 720×1280 (§3.5). HUD 0–150; grade 700×760 em (10,190); rótulos como barras de 24 px à direita e abaixo (forma + fração, sem texto), com as 2 diagonais como cantos triangulares da moldura da grade; minimapa da build 64×64 no canto do HUD; mão 720×210 no rodapé; prévia vira **gaveta** que sobe 340 px no toque-e-segure (0,2 s); **modo foco** amplia linha+coluna da casa tocada a 1,35× e escurece o resto a 35%.

**Tutorial (≤ 60 s):** `tutorial.tscn` é a `partida` com grade 3×3, baralho fixo por seed e trilhos; máximo **12 palavras na tela** por passo.

| Passo | Restrição | Texto (≤6 palavras) | Dur. |
|---|---|---|---|
| 1 | 1 carta na mão, 1 casa legal piscando | "Coloque a carta." | 5 s |
| 2 | 2ª e 3ª cartas, mesma linha | "Cada carta vale na linha e na coluna." | 12 s |
| 3 | A 3ª fecha a linha | — (a animação fala) | 6 s |
| 4 | A colheita arranca 1 carta de cada coluna | "Colher desmancha o resto." | 6 s |
| 5 | Duas casas legais, uma é cruzamento | "Feche as duas de uma vez." | 15 s |
| 6 | Cruzada: câmera lenta, `×2 + ×4 = ×6` | "CRUZADA." | 6 s |
| 7 | Meta batida, garantida por seed | "Sua mesa. Próxima é 5×5." | 4 s |

Nos 10 primeiros segundos o jogador já viu **uma colheita destruindo uma perpendicular** e caminha para a **cruzada**. Pulável a qualquer momento, refazível em Opções → Jogo.

**Controles** (tudo navegável sem mouse; `fluxo.tscn` prova `grab_focus` inicial e ciclo de foco fechado):

| Ação | Teclado | Gamepad | Toque |
|---|---|---|---|
| Escolher carta | `1`–`6` | LB/RB | tocar carta |
| Mover na grade | setas / `WASD` | D-pad / stick esq. | — |
| Posicionar | `Enter`/`Espaço` | A | arrastar-soltar ou 2 toques |
| Prévia detalhada | `Shift` (segurar) | Y (segurar) | toque longo 0,2 s |
| Descartar | `X` | X | botão |
| Voltar atrás | `Ctrl+Z` | LT+B | botão discreto |
| Modo foco | `F` | clique stick dir. | pinça |
| Colapsar Receituário | `R` | — | clique no cabeçalho |
| Turbo | `T` | RT | botão |
| Pausa | `Esc` | Start | botão |
| Pular animação | qualquer | qualquer | qualquer toque |

O cursor de grade "gruda" na casa mais promissora ao entrar; `Tab` alterna grade/mão/botões; remapeamento completo em `controles.tscn`.

**Save (`user://cruzada.save`):** JSON UTF-8, gravação **atômica** (escreve `.tmp`, `flush`, fecha, `DirAccess.rename`, mantém `.bak`). Ao carregar: principal → `.bak` → save novo; **nunca trava** (falha vira perfil zerado com aviso). Blocos: `versao`, `quando`, `perfil`, `opcoes`, `colecao`, `conquistas`, `estatisticas`, `diario`, `run`. Em `run`: `seed`, `modo`, `dificuldade {orcamento, geometria, metas}`, `rodada`, `mesa`, `tentativa`, `vidas`, `fianca`, `dinheiro`, `niveis_mao`, `selos [{id, alvo}]`, `reliquias`, `oficios`, `mesa_atual {grade[25], mao[], pontos, tear, posic_usados, descartes_usados, cursores{baralho,loja,chefe,selo,semeadura,ajuda}, historico}`. **Retomar run interrompida é obrigatório:** salva-se após cada posicionamento, cada compra e cada troca de tela (throttle 1 s, nunca no meio de animação); como o save guarda `seed` + `cursores` e **nunca** cartas sorteadas, o estado é reconstruído exato e o replay do Diário fica verificável. `versao` dispara migração encadeada em `migracao.gd`, cada passo com teste que carrega um save de `testes/saves/`. Chave desconhecida é preservada; ausente recebe padrão. `dados.tscn` oferece Exportar, Importar (validação + confirmação dupla), Apagar (digitando `APAGAR`) e apagar `user://metricas.csv`.

**i18n, com a armadilha desarmada:** fonte é **pt-BR**, zero literal na UI. Chaves em `snake_case` com prefixo de tela (`menu_jogar`, `partida_faltam_n`, `selo_brasa_desc`); plural e gênero por **chaves separadas**, nunca por concatenação. `gerar_traducoes.py` lê `traducoes/textos.csv` (`chave,curto,pt,en,es`) e escreve os três `.translation`. **Até a Etapa 10, `--verificar` falha apenas por chave usada e ausente na coluna `pt`; as colunas `en` e `es` podem conter `@PENDENTE` sem reprovar. A partir da Etapa 10, `@PENDENTE` reprova.** A regra de **130% de comprimento aplica-se somente às chaves com a flag `curto`** (botões, badges, rótulos de linha), nunca a texto corrido. Sem isso, cada string nova adicionada em qualquer etapa quebraria o build até ser traduzida em duas línguas. Idiomas mínimos: pt, en, es.

**Primeira sessão, cronometrada:** 0,0 s abre em `abertura`, o logo se desenha como grade que fecha uma cruz; 1,6 s **sem save vai direto ao `tutorial`** (o jogador não clica em nada); 2,0 s uma carta na mão, uma casa piscando, quatro palavras; 5 s primeira carta posta; 11 s primeira **colheita**; 30 s primeira **cruzada** com `×2 + ×4 = ×6`; **45 s `MESA VENCIDA`; 46 s a grade 3×3 se abre em 5×5 com a mesma animação e a run 1 começa SEM CLIQUE** — sem menu, sem tela de modos (baralho Da Casa, Geometria 0, seed do relógio). **O menu só existe se o jogador apertar `Esc`.** A primeira vez que ele vê o menu é quando ele decide vê-lo. **A distância entre abrir o jogo e posicionar a primeira carta é um clique ou nenhum.**

---

## 10. CONFIGURAÇÕES E ACESSIBILIDADE

**Áudio:** Master / Música / Efeitos (0–100, passo 5, com ▶ que toca a colheita de amostra), Silenciar em segundo plano, Ducking na cruzada.
**Vídeo:** Janela / Tela cheia / Sem borda, resolução, Escala de UI 80–150% (passo 10), Limite de FPS (30/60/120/sem), VSync (on/off/adaptativo), Fundo animado.
**Jogo:** Velocidade de animação 0,5×–3× (**padrão 1,25×**) + **Turbo** (2,5×, tecla `T`), **Assistências de posicionamento: completas / só halo / nenhuma (padrão completas)**, Autoconfirmar posicionamento (clique único vs. arrastar), Mostrar dicas (realce da melhor jogada, **sem penalidade**, ligado por padrão na Estufa), Mostrar probabilidades (outs em %), Janela de arrependimento (0 / 1,5 / 3 s), Aviso de demolição, Rodapé "melhor colheita disponível", Compras Assistidas, **Vibração (celular): desligada / leve / forte**, Refazer tutorial.
**Acessibilidade:** Daltonismo — naipes por **forma sólida + símbolo + letra**, paleta **Quatro Cores como padrão** (♥ vermelho, ♦ **azul**, ♣ verde, ♠ preto-azulado) com variantes Protan/Deutan/Tritan e marcador redundante opcional (1–4 pontinhos de 2,5 px, ou inicial `C/O/P/E` em 11 px); Alto contraste (contorno 1,5 px em todos os pips, halos com **hachura** além da cor: verde ↗, amarelo pontilhado, vermelho ↘); Reduzir movimento (corta câmera lenta, zoom e tremor, **mantém o pagamento**, e **desliga a vibração junto**); Reduzir flashes (nada acima de **3 Hz**, alpha máx. 0,08); Fonte maior (+2/+4/+8 px, testada sem estourar caixa pelo comando da §15.4); Leitor de tela básico (`DisplayServer.tts_speak` **se existir na build conferida em F0**, senão faixa rolante); Descrever jogada ao focar ("C3 vazia, linha 3 trinca 4 de 5, coluna C flush 4 de 5, diagonal 2 de 5"); Tempo sem limite (declarativo: não há timer em modo algum).
**Idioma:** lista com nome nativo. **Dados:** exportar / importar / apagar.

**Háptica:** `Input.vibrate_handheld`, **no máximo 60 ms**, disparada só em **posicionar (10 ms)**, **colher (25 ms)** e **cruzar (55 ms)**; segue Reduzir movimento. A linha correspondente entra na tabela de `Efeitos.responder`, para `teste_juice.gd` cobrir o trio **visual + sonoro + háptico**.

**Princípio verificável:** acessibilidade **remove movimento, jamais informação ou recompensa**; o som fica integral nos dois modos, e pagamento, escada de notas e contagem **nunca** são cortados.

---

## 11. BÍBLIA DO JUICE

**Regra de ouro:** resposta em **menos de 100 ms**, visual **e** sonora — primeiro quadro ≤ 33 ms, ataque do som ≤ 50 ms. `Efeitos.responder(acao, no)` é o **único** ponto de entrada, e `testes/teste_juice.gd` varre a tabela de ações e **falha** se alguma não registrar par visual + sonoro (e o trio com háptica, nas três ações da §10). Ações cobertas: hover em carta, hover em casa, selecionar, arrastar sobre casa, soltar inválido, posicionar, colher, cruzar, comprar, descartar, voltar atrás, comprar na loja, grudar selo, rerrolar, motor disparado, botão/aba/slider, pausa, tecla sem efeito.

| Evento | Propriedade | Duração | Curva | Overshoot | Cascata |
|---|---|---|---|---|---|
| Carta entra na mão | `scale` 0,6→1,08→1,0 | 140+80 ms | QUAD OUT → SINE IN_OUT | 8% | 40 ms/carta |
| Flip da compra | `scale.x` 1→0→1 | 90+110 ms | QUAD IN / OUT | — | — |
| Carta selecionada | `y` −18, `scale` 1,06 | 120 ms | BACK OUT | nativo | — |
| Halo das casas | `modulate.a` | 90 ms | SINE OUT | — | **8 ms/casa** |
| Voo da carta jogada | `global_position` | 160 ms | QUINT OUT | — | — |
| Assentamento | `scale` 1,12→1,0 | 90 ms | BACK OUT | 12% | — |
| Empurrão das vizinhas | offset 3 px ida/volta | 120 ms | ELASTIC OUT | — | 20 ms |
| **Carta pontuada** | `y` −14, `scale` 1,18→1,0 | 110 ms | BACK OUT | 18% | **110 ms/carta** |
| Ficha voando | Bézier de 3 pontos | 260 ms | CUBIC IN_OUT | — | 40 ms |
| Contagem de pontos | valor inteiro | `clamp(0,25 + R·1,2; 0,25; 1,4)` s | EXPO OUT | — | — |
| Tear +1 | `scale` 1→1,35→1,0 | 90+160 ms | QUINT OUT | 35% | — |
| Reagrupamento perpendicular | `position` das restantes | 400 ms | CUBIC IN_OUT | — | 30 ms |

Godot não parametriza o overshoot de `TRANS_BACK`: onde ele precisa ser controlado, use **duas etapas**. Rotações e jitter usam o `RandomNumberGenerator` **próprio do `Efeitos`**: juice nunca move cursor de RNG da run.

**Sequência de pontuação — linha simples, 1.340 ms** (t desde a soltura):

| t (ms) | Visual | Áudio |
|---|---|---|
| 0 | assentamento + empurrão | `assentar` |
| 60 | trilho acende esquerda→direita, 36 ms/casa | `acender` |
| 240 | nome da mão estampa (1,4→1,0 em 120 ms) | `nome_mao`, zoom 1,02 |
| 300–850 | **cartas pulam uma a uma, 110 ms cada**, cuspindo fichas | graus **0,1,2,3,4** da escala |
| 560 | multiplicador incha 1→1,5→1,0; se o teto morder, `×52 → ×48 (teto)` em dourado esmaecido | `mult` |
| 620–1.020 | fichas em arco, contador sobe (EXPO OUT) | `contagem` |
| 900 | **TEAR +1**, contando alto | `tear`, pitch `2^(tear/12)` |
| 1.020 | impacto do tier | `impacto_T{n}`, shake/hitstop |
| **1.100** | **fronteira: pagamento encerrado** | — |
| 1.100–1.500 | cartas evaporam; perpendiculares reagrupam e o rótulo se **reescreve como proposta** | `reproposicao` (ascendente) |
| 1.100–2.600 | botão **VOLTAR ATRÁS** visível | — |

**CRUZADA — 2.620 ms:** igual até 240 ms; as duas linhas acendem em cruz (240–420); **hitstop 90 ms** em 420; `time_scale` cai a **0,35 por 600 ms** e volta em 180 ms; as 9 cartas pontuam em **duas escadas paralelas** (mão A nos graus 0–4, mão B nos 5–9) e a **carta do cruzamento toca as duas notas mais a quinta** — a assinatura sonora do jogo; em 1.500 os mults colidem estampando `×4 + ×8 = ×12` (2,0→1,0, 260 ms, BACK OUT); em 1.700 explosão em cruz, zoom-punch 1,06 e chuva de fichas; fronteira em 2.100. Cruzada com diagonal acrescenta uma terceira escada nos graus 10–14 e a estampa vira `×4 + ×8 + ×4 = ×16`.

**Escalonamento por magnitude** — limiar **sempre relativo**: `R = pontos_do_evento / meta_da_mesa` (limiar absoluto satura na rodada 3 e vira cataclismo permanente).

| Tier | R | Shake | Hitstop | Zoom | `time_scale` | Flash α | Partículas |
|---|---|---|---|---|---|---|---|
| T0 Sussurro | < 0,04 | 0 | 0 | — | 1,0 | 0 | 8 |
| T1 Brilho | 0,04–0,12 | 2 px | 0 | 1,015 | 1,0 | 0,05 | 24 |
| T2 Impacto | 0,12–0,30 | 5 px | 60 ms | 1,03 | 1,0 | 0,10 | 70 |
| T3 Estouro | 0,30–0,60 | 9 px | 110 ms | 1,05 | 0,55 / 380 ms | 0,16 | 160 |
| T4 Cataclismo | ≥ 0,60 | 14 px | 160 ms | 1,08 | 0,35 / 600 ms | 0,22 | 320 + chuva 1,2 s |

**Elevadores:** toda cruzada sobe um tier (mín. T2); cruzada de 3+ linhas = T4; **a colheita que CRUZA A META recebe no mínimo T3, qualquer que seja o tamanho**; Tear ≥ 5 soma +40% de partículas sem mudar tier. Vencida a mesa, **cauda de 1,5 s**: cada posicionamento não usado voa como moeda (delay 90 ms) subindo um grau da escala. **O fim nunca é apagão.**

**VFX.** *Screenshake* (`scripts/ui/tremor.gd`): trauma, `offset = max_px · trauma² · ruido(t·22 Hz)`, rotação máx. 0,6°, decaimento 1,8/s, teto 1,0, no `Control` raiz `Palco` com pivô central — **sem `Camera2D`, sem shader**. *Hitstop:* proibido `Engine.time_scale = 0`; `Efeitos.congelar(ms)` mede tempo **não escalado** por `Time.get_ticks_msec()` num nó `PROCESS_MODE_ALWAYS`, e a escada de notas é agendada por tempo real, nunca por tween. *Zoom-punch:* `Palco.scale` 1,0→tier em 70 ms (QUINT OUT), volta em 260 ms. *Flash:* `ColorRect` branco em `CanvasLayer` 90, 40 ms / 120 ms. *Falso-cromático* (padrão): pontos e nome da mão desenhados 3×, offset (+2,0) vermelho e (−2,0) ciano, aditivo, decaindo em 220 ms. *Partículas:* `CPUParticles2D` sempre, textura `ImageTexture` 16×16 radial gerada no `_ready`; `queue_free` em partícula é **proibido** (pools).

**Turbo:** `Efeitos.fator = velocidade_animacao (0,5–3,0) × (turbo ? 2,5 : 1,0)`; todas as durações e agendamentos são divididos pelo fator. Turbo **não** toca em regra, RNG, pontuação nem música. **Pisos inegociáveis:** clímax da cruzada ≥ 380 ms; contagem de pontos ≥ 120 ms; a escada toca **todas** as notas, sobrepostas se preciso; hitstop cai a 40%, nunca a 0; a cauda de recompensa cai a 600 ms, nunca some. Toque durante animação = turbo momentâneo daquele beat; duplo toque chama `pular_tudo()`. As métricas de turno registram o fator usado, para a mediana não ser mascarada por aceleração visual.

---

## 12. ÁUDIO E MÚSICA

`ferramentas/gerar_audio.py` → `recursos/audio/*.wav` (PCM mono, 22050 Hz, 16 bits, stdlib `wave`). Cada som é função pura `(t) → amostra`, ADSR linear, soft-clip `tanh`, fade final de 3 ms contra estalo. `--verificar` recomputa hashes e reprova o build. **Não existe síntese-espelho em GDScript:** sob `--headless` o autoload `Audio` roda em **modo mudo** e `teste_juice.gd` verifica o **registro** do par visual+sonoro, não a amostra — reimplementar o gerador numa segunda linguagem é regra duplicada, que o revisor adversarial tem mandato de reprovar.

| Som | Onda | Frequência | ADSR (ms) | Dur. | Ganho |
|---|---|---|---|---|---|
| `clique` | quadrada 25% | 880 Hz | 2/8/–/35 | 45 ms | −10 dB |
| `hover` | seno | 1320 Hz | 1/6/–/11 | 18 ms | −18 dB |
| `pegar` | triangular | 520→660 glide | 3/12/20/25 | 60 ms | −12 dB |
| `encaixe` | seno + 5% ruído | 990 Hz | 1/5/–/12 | 18 ms | −16 dB |
| `assentar` | ruído p-baixa + seno | 180 Hz | 1/10/–/50 | 68 ms | −8 dB |
| `descarte` | ruído com sweep | 2200→300 Hz | 5/40/60/155 | 260 ms | −12 dB |
| `compra` | triangular | 990 Hz | 2/10/–/28 | 40 ms | −14 dB |
| `ping_out` | seno + 5ª | 1320+1980 Hz | 2/18/–/70 | 90 ms | −10 dB |
| `nota_ficha` | seno + parciais 2f (−12 dB) e 3f (−20 dB) | 220 Hz base | 2/25/40/120 | 190 ms | −8 dB |
| `mult` | dente-de-serra p-baixa | 110 Hz | 4/30/80/90 | 210 ms | −9 dB |
| `tear` | sino, 3 parciais inarmônicos | 440 Hz base | 1/20/–/300 | 320 ms | −9 dB |
| `meta` | arpejo maior 4 notas | A–C#–E–A | 3/40/–/300 | 620 ms | −6 dB |
| `cruzada` | arpejo 8 notas + coral | A3→A5 | 5/60/200/400 | 1,25 s | −4 dB |
| `motor` | tríade menor + quinta | A–C–E–E | 3/30/–/180 | 260 ms | −11 dB |
| `compra_loja` | tríade maior | C–E–G | 3/25/–/120 | 180 ms | −10 dB |
| `erro_suave` | 2 senos | 320+240 Hz | 6/40/–/95 | 140 ms | −16 dB |
| `vitoria` | pad + arpejo I–IV–V–I | Am→A | — | 2,4 s | −5 dB |
| `derrota` | 3 notas descendentes, sem dissonância | A–F–D | — | 1,6 s | −9 dB |

**Escada ascendente (obrigatória):** lá menor pentatônica, semitons a partir de A3 (220 Hz): `[0,3,5,7,10,12,15,17,19,22]`. **Um único** `nota_ficha.wav` com `pitch_scale = 2^(semitons/12)` — afinação exata, repositório pequeno. Linha simples: cartas 1→5 nos graus 0–4. Cruzada: mão A nos graus 0–4, mão B nos 5–9, carta do cruzamento tocando as duas notas mais a quinta. **Tear:** `pitch_scale = 2^(min(tear,12)/12)`; acima de 12 mantém a oitava e soma uma quinta. É o único som que **sobe pela mesa inteira**: o turno 20 soa objetivamente mais agudo que o turno 1. Toda repetição leva `pitch_scale ±3%` e cooldown de 40 ms; `Audio` **recusa** o mesmo som no mesmo pitch duas vezes em 60 ms, e em teste isso é falha.

**Escada de sinal da compra (anti-habituação), com os tetos alinhados à §7.4:** out comum (≤ 3/5), ~55% das compras → pontinho na carta, **silêncio**; out que leva a 4/5, **≤ 26%** → pulsa 1×, rótulo pisca, `ping_out`; out que fecha cruzada, **≤ 6%** → pulsa 3×, as duas linhas acendem, `ping_out` + quinta + brilho dourado. Soma **32%**, dentro do teto de 35% da §7.4. **Se o simulador medir acima de 32%, o dial permitido é elevar o limiar de 4/5 para "4/5 com categoria garantida ≥ Trinca" — nunca silenciar a cruzada.**

**Barramentos:** `Master → {Musica, Efeitos, IU}`, `AudioEffectLimiter` no Master (−1 dB), pool de 16 `AudioStreamPlayer` com roubo do mais antigo. Ducking da `Musica` em −8 dB por tween de `volume_db` (ataque 120 ms, sustentação 600 ms, retorno 900 ms) em cruzada, vitória e derrota — **tween, não sidechain**.

**Música em camadas, com o orçamento fechado:** BPM **84**, **Lá menor**, 4/4, Am–F–C–G (um acorde por compasso). `22050 × 60 / 84 = 15750` amostras por tempo; **4 compassos = 16 tempos = 252.000 amostras exatas** (11,43 s), com `LOOP_FORWARD`, `loop_begin = 0`, `loop_end = 252000` — **em frames, não em bytes; confirme o campo no `--doctool` (§3.3)** — sem emenda e sem crossfade. **Conta do orçamento, que precisa fechar:** `252.000 × 2 bytes × 6 camadas = 3.024.000 B ≈ 2,88 MiB ≤ 4,5 MB` ✔ (o loop de 8 compassos daria 5,77 MiB e estouraria o próprio teto, por isso são 4). Camadas: `base` (pad de 3 dentes-de-serra ±6 cents, sempre, −14 dB); `pulso` (sub-seno nos tempos 1 e 3, sempre, −12 dB); `arpejo` (colcheias pentatônicas, em meta ≥ 25%, −16 dB); `contratempo` (plucks, ≥ 55%, −17 dB); `tambor` (bumbo 60 Hz + chimbal 6 kHz, ≥ 80% **ou** ≤ 5 posicionamentos, −13 dB); `coral` (oitava acima com vibrato 4 Hz, só em chefe, −15 dB). Todas tocam desde o primeiro quadro **em fase**, mixadas só por `volume_db`, entrada/saída em 1 compasso (2,857 s) ou 400 ms quando abrupta. **As variantes de menu, loja e chefe são geradas do MESMO material em tempo de execução** — `pitch_scale` e mixagem de camadas —, **nunca arquivos novos**: menu = `base`+`pulso` a −4 dB; loja = as mesmas com `pitch_scale` de +3 semitons (Dó maior relativo); chefe = as mesmas com o `coral` ativo. Orçamento de `recursos/audio/musica/`: **≤ 4,5 MB**, verificado por `gerar_audio.py --verificar`.

---

## 13. IDENTIDADE VISUAL

**Nome: PLACARD** — a palavra traz **CARD** escrita dentro dela, e a leitura do nome é a mecânica: *place a card*. Três sílabas, sete letras, sem acento; cabe em título, pasta (`placard/`) e executável.

> **O nome mudou depois deste briefing.** A escolha original era **CRUZADA**, pela razão de que nomeava a jogada. Ela caiu porque significa *guerra santa* em três línguas latinas e nada nas outras, e o título tinha que ser universal sem tradução. A jogada continua se chamando cruzada. Os dezoito nomes testados e o motivo de cada queda estão em `placard/NOME.md`.
 Subtítulo fixo: **"Cada carta pontua duas vezes."** O nome **nunca é traduzido**. **TEAR é rótulo permanente e discreto do HUD; PLACARD nunca é rótulo** — só aparece como **estampa de clímax**, no máximo uma vez por evento, e **nunca** em botão, menu ou tooltip. (A regra antiga, "as duas palavras nunca aparecem na mesma tela", era impossível: o HUD mostra TEAR o tempo todo e a §11 estampa PLACARD por cima dele.)

**Estética: feltro e papel.** Fundo fosco, casas rebaixadas, cartas como papel elevado; tudo `StyleBoxFlat` + `_draw` + um shader.

| Token | Escuro (padrão) | Claro |
|---|---|---|
| `fundo` / `fundo_prof` | `#0F1418` / `#070A0C` | `#E8E4DA` / `#D6D1C4` |
| `superficie` / `superficie_2` | `#1A2228` / `#232D34` | `#FBF9F4` / `#FFFFFF` |
| `traco` | `#2C3941` | `#C3BCAC` |
| `texto` / `texto_fraco` | `#EAF0F2` / `#9BAAB2` | `#1B2126` / `#4E5A61` |
| `papel` / `verso` | `#F4EFE6` / `#17323A` | `#FFFFFF` / `#2A5560` |
| `dourado` / `dourado_claro` | `#F0B429` / `#FFD666` | `#8A6100` (texto) / `#C9931A` |
| `alerta` / `bom` / `neutro` | `#E8735E` / `#5BD6A0` / `#E4C55B` | `#B23A2A` / `#17794A` / `#8A6100` |

**Naipes — Quatro Cores é o padrão:** copas `#C62F2F`, ouros `#1A5FB4`, paus `#17794A`, espadas `#1A1F24`. Contrastes sobre `papel` (`#F4EFE6`), **recalculados pela fórmula WCAG 2.1**: **4,76 / 5,49 / 4,74 / 14,49**. Clássico disponível em Opções; no tema claro, ouros vira `#14508F`.

**Os valores desta tabela são indicativos e não são a fonte de verdade:** `validar_contraste.py` **recomputa todos pela fórmula WCAG 2.1 e REESCREVE a tabela do `DESIGN.md` com os valores medidos**. Divergência entre o documento e o medido é **falha de build**, não erro de arredondamento. (Os 16,2 que circulavam antes para espadas eram um erro de conta; o valor real é ~14,5.)

**Contraste é critério de aceite:** texto < 24 px ≥ 4,5:1; ≥ 24 px (ou ≥ 19 px negrito) ≥ 3:1; halos, bordas de estado e ícones funcionais ≥ 3:1. `validar_contraste.py` lê `dados/paleta.json`, recalcula os pares de `dados/pares_contraste.json` e **retorna 1** se algum falhar.

**A carta, por código — a geometria que realmente fecha.**

| Uso | Casa | Carta desenhada | Proporção | Detalhes |
|---|---|---|---|---|
| Mão | — | **104×146** | **0,712** | raio 8, borda 2,0, rank 26 px, pip 22×25 |
| Grade | **84×92** | **76×84** (inset 4 px em volta) | **0,905** | raio 6, borda 1,5, rank 18 px, pip 15×18 |
| Miniatura | — | **42×59** | **0,712** | prévia e Matriz |

**A proporção 0,712 vale só para a mão e a miniatura.** A carta da grade é **deliberadamente mais quadrada**, e está escrito aqui para ninguém "consertar" depois: a grade 5×5 com gap 8 ocupa `5×92+4×8 = 492` px de altura, e uma carta na proporção do baralho com 84 px de largura teria **118 px de altura** — não cabe, nem crescendo a região. Asserção obrigatória `_carta_cabe_na_casa` em `fluxo_testes.gd`: o retângulo da carta desenhada está **contido** no retângulo da casa, em paisagem e em retrato.

Sombra por `StyleBoxFlat` (`shadow_size 6`, offset `(0,3)`, preto a 0,32), nunca desenhada à mão. Área de pips = retângulo interno com margem **18%** na largura e **14%** na altura; três colunas `L=0,18 · C=0,50 · R=0,82` e treliça vertical de 13 passos `t = k/12`:

```
A  : (C,6)×1,9        2 : (C,0)(C,12)          3 : (C,0)(C,6)(C,12)
4  : (L,0)(R,0)(L,12)(R,12)                    5 : 4 + (C,6)
6  : (L,0)(R,0)(L,6)(R,6)(L,12)(R,12)          7 : 6 + (C,3)
8  : 7 + (C,9)
9  : (L,0)(R,0)(L,4)(R,4)(L,8)(R,8)(L,12)(R,12) + (C,6)
10 : as oito do 9 + (C,2)(C,10)
```

**Regra obrigatória: todo pip com `k > 6` é desenhado rotacionado 180°** — isso, e nada mais, produz o layout correto do baralho francês. **Naipes:** `scripts/ui/naipes.gd` gera **uma vez no `_ready`** quatro `PackedVector2Array` normalizados em caixa 1×1, reusados via `Transform2D` — ouros losango de 4 vértices, espadas 24 pontos, copas coração paramétrico em 28 amostras, paus três círculos de 12 lados + haste; `draw_colored_polygon`, contorno 1,5 px só em Alto Contraste. **J/Q/K são monograma, não ilustração:** brasão losangular (62% da largura, 46% da altura) preenchido com o naipe a 8% de alpha, letra **V/D/R** em 34 px, sigilo acima (coroa de 3 pontas, tiara com 3 pontos, flâmula triangular) e um pip a 60% abaixo — ~20 linhas de `_draw`. **Estados** (tween 0,10 s ease_out): hover `y −6, escala 1,04`; selecionada `y −14, contorno 2 px dourado`; jogada `sem sombra, borda 1 px traco`; desabilitada `alpha 0,45`; out `contorno 2 px pulsando 1,1 Hz`; fantasma `alpha 0,35, tracejado 2 px (8/6)`.

**Tipografia, sem baixar fonte:** a UI usa a fonte embutida do Godot (`ThemeDB.fallback_font` — **confirme o nome no `--doctool` da §3.3**); o logotipo é polígono em `scripts/ui/logotipo.gd`. **Números tabulares sem arquivo de fonte:** `Tipografia.desenhar_numero()` desenha dígito a dígito com avanço **fixo** `0,58 × tamanho`, ignorando o avanço natural — pontuação, meta, fichas, mult, dinheiro e TEAR ficam de largura constante e o contador nunca treme ao subir. Milhar com ponto (`2.964`); multiplicação `×` (U+00D7), nunca `x`. Mínimo 12 px; entrelinha 1,35; linha máxima de 46 caracteres; nunca itálico abaixo de 18 px.

**Fundo vivo (≤ 0,8 ms/quadro):** gradiente radial por shader de 6 linhas com centro oscilando ±3% em seno de 40 s; 28 pontos de poeira num único `_draw` com arrays pré-alocados (raio 1,5–3,0 px, alpha 0,05–0,12, deriva 6–12 px/s com wrap); **vinheta reativa** com `alpha = lerp(0,10; 0,34; tensao)`, `tensao = 0,55·(1 − pontos/meta) + 0,45·(1 − posicionamentos_restantes/orcamento)`, suavizada em 0,6 s. Ao cruzar a meta, lavagem dourada a 12% por 0,9 s; na cruzada, durante a câmera lenta a poeira **congela** e a vinheta cai a 0,04.

**Ícones:** `scripts/ui/icone.gd`, grade 24×24, traço 2 px, cor única do tema, cada um uma `PackedVector2Array` estática, **legível a 16 px**; lote mínimo de 32. **Nenhum item entra em `dados/*.json` sem ícone.** `gerar_icones.py` emite `recursos/icone.png` em 1024/256/128/64/32/16 (fundo `#0F1418`, cantos arredondados 22%, duas cartas `papel` cruzadas em 90°, cruz `dourado` no encontro; ≤ 64 px descarta pips e mantém só as barras + a cruz) e `recursos/splash.png` 1280×720.

**Atrativo da tela de título:** o fundo do menu roda um loop de 6 s que **joga sozinho** — 8 cartas caem na grade, uma linha colhe e arranca visivelmente uma carta de cada perpendicular, e a nona fecha uma cruzada `×4 + ×8 = ×12`.

**Cartão de partida — uma vez por run, não por mesa.** Ao fim da **run** (e sob demanda, por um botão no `postmortem`), um `SubViewport` 1080×1080 desenha o mapa da grade com os selos colados, a frase (`Flush L2 → Trinca CB → CRUZADA L3×CC ×13`), o nome sorteado e a seed, e grava PNG em `capturas/`. Léxico: 12 substantivos (Tear, Cruz, Nó, Trama, Ponto, Fio, Ourela, Malha, Costura, Laço, Urdume, Tecido) × 6 materiais (Palha, Cobre, Bronze, Prata, Ouro, Diamante) = **72 nomes**. **Gerá-lo 18 vezes por run, dentro do orçamento de 16,6 ms/quadro e do teto de 260 nós de `partida.tscn`, está proibido** — foi por isso que virou um por run.

**Voz e tom:** PT-BR, 2ª pessoa, **máximo 6 palavras** em qualquer texto do loop de turno, imperativo nos botões, um só ponto de exclamação por tela, humor seco. Proibido: "errado", "falhou", "você perdeu porque", emoji, gíria datada, tutorial em modal. **A derrota fala de carta e de casa, nunca do jogador.** Redação a implementar: `Colocar` · `Trocar até 3` · `Voltar atrás` · `Isso desmancha seu Flush 4/5.` · `Cruzada! ×4 + ×8 = ×12` · `Duas mãos, uma carta.` · `Faltam 877. Só Quadra ou Sequência de Cor pagam isso.` · `A meta saiu do alcance. Agora é pelo recorde.` · `Você levou 71% da meta. Toma $3.` · `A carta era qualquer 9. Restavam 3 em 34 — 8,8%.` · `Não foi burrice. Foi 8,8%.` · `Você fechou a coluna cedo demais. Acontece.` · `Descarga · ~55 pts` · `Terceira luz acesa. A próxima colheita paga dobrado.` · `Mesma mesa, mais uma carta na manga.` · `Nenhuma casa aceita essa mão. Toma uma troca.` · `A casa lembra de você: C3 · 7 colheitas · 2 cruzadas.` · `Tear de Prata.` · `Difícil aqui não é número. É outro tabuleiro.` · `Mais uma? A mesa já está limpa.`

---

## 14. ARQUITETURA TÉCNICA

```
placard/
├─ project.godot  export_presets.cfg  testar.sh  .gitignore
├─ DESIGN.md  README.md  AUDITORIA.md
├─ cenas/     abertura menu modos partida loja mapa colecao conquistas estatisticas
│             diario opcoes controles creditos pausa postmortem fim_de_run tutorial
│             dados + testes.tscn fluxo.tscn simulacao.tscn capturas.tscn
├─ scripts/
│  ├─ autoload/ avisos catalogo progresso texto layout audio efeitos ruido navegacao
│  ├─ nucleo/   constantes cartas maos avaliacao grade mesa run economia loja selos
│  │            chefes tabuleiro aleatorio semente fita outs rotulos receita postmortem
│  │            estante politica motores serializacao migracao
│  ├─ telas/    um .gd por cena, mesmo nome
│  └─ ui/       tema tipografia naipes icone logotipo carta_visual casa_visual
│               grade_visual rotulo_linha painel_previa contador barra_meta tear_hud
│               fichas_voadoras tremor botao cartao_loja minigrade minimapa layout
├─ dados/      maos.json selos.json reliquias.json fardos.json oficios.json chefes.json
│              modificadores.json motores.json tabuleiro.json rodadas.json grades.json
│              baralhos.json conquistas.json paleta.json pares_contraste.json
├─ recursos/   tema.tres paleta.tres curvas.tres sombreadores/*.gdshader audio/*.wav
├─ testes/     nucleo_testes.gd fluxo_testes.gd teste_juice.gd simulacao.gd
│              demonstracao.gd captura.gd apoio.gd saves/save_v1..v3.json
│              fixtures/rodada4_rachada.json
├─ traducoes/  textos.csv textos.{pt,en,es}.translation
├─ ferramentas/ verificar_godot.py validar_camadas.py validar_estilo.py validar_dados.py
│               validar_contraste.py gerar_traducoes.py gerar_audio.py gerar_icones.py
│               construir.py relatorio_balanceamento.py capturas.py
└─ capturas/   .gdignore + PNGs gerados
```

**Esquema dos três JSON que ninguém descreveu** (os outros seguem o template de 15 campos da §8): **`grades.json`** = os moldes iniciais de casa lacrada por modificador e por grau, `{id, lacradas: [int], semeadas: int}`; **`rodadas.json`** = as 6 rodadas com `{n, ato, meta_pequena, meta_grande, meta_chefe, chefe_id, vagas_de_loja, o_que_a_loja_vende}` — é a materialização da §6.2 e da divulgação progressiva, e `validar_dados.py` recomputa as metas pela R21; **`tabuleiro.json`** = os **9 presets** do dial, `{grau, orcamento, geometria, metas, mutacoes: [id]}` (§7.1).

**`.gitignore`, literalmente** (é barreira de saída de F0 e não pode ser "um nome de arquivo"):

```
construidos/
.godot/
.import/
__pycache__/
*.pyc
*.tmp
*.bak
capturas/*.csv
```

**`capturas/*.png` SÃO versionados** (entregável §20.5); `capturas/.gdignore` existe para o motor não importar os PNGs; `capturas/*.csv` (balanceamento, sensação) fica fora do git por ser regenerável e volumoso.

**`ferramentas/capturas.py`** — não é redundante com `capturas.tscn`, e existe para o "legível" não ser opinião: **valida os PNGs gerados** (dimensões esperadas, não-uniformidade — reprova imagem de cor única, que é o sintoma de captura headless vazia —, e presença de pixels do `dourado` do tema) usando **`zlib` e `struct` da stdlib, sem Pillow**. Sai 0 se não houver PNG (capturas puladas não reprovam, §15.4).

**A muralha: núcleo × apresentação.** **Nada em `scripts/nucleo/` estende `Node`** — tudo é `RefCounted`, `Resource` ou `static`; o núcleo não conhece cena, `Tween`, `AudioStream`, `Input`, `Time`, tradução nem `await`. Uma mesa inteira roda síncrona, sem janela, em **menos de 4 ms**.

| Proibido em `scripts/nucleo/` | Proibido em `scripts/telas/` e `scripts/ui/` |
|---|---|
| `extends Node`, `get_node`, `get_tree`, `add_child`, `queue_free` | qualquer aritmética de pontuação, mult, fichas ou meta |
| `Tween`, `Timer`, `AnimationPlayer`, `await`, `_process` | `RandomNumberGenerator`, `randi`, `randf` |
| `randi()`, `randf()`, `randomize()`, `Time.get_ticks_*` | escrever em `Mesa`/`Run` fora dos métodos públicos |
| `tr()`, `print()` (só `Avisos` e `testes/` imprimem) | ler `dados/*.json` direto (só via `Catalogo`) |

`validar_camadas.py` verifica isso e **falha o build**. A apresentação faz três coisas: chama um método público do núcleo, consome a **fita de eventos** e desenha o estado. **Nenhuma tela recalcula pontuação para exibir.**

### 14.9 Contratos congelados (entregável de F1 — **F2 não começa antes disto existir**)

Esta lista vai **literalmente** para o `DESIGN.md`. Nenhum agente altera assinatura congelada sem registrar `DECISÃO` em `AUDITORIA.md`. Sem ela, os 4 agentes paralelos de F2 inventam quatro interfaces diferentes para a mesma coisa.

```gdscript
# nucleo/maos.gd
static func avaliar(cartas: PackedInt32Array, mascara_ima: int, saida: Avaliacao) -> void

# nucleo/mesa.gd            (RefCounted; toda devolução é a fita de eventos)
func posicionar(indice_mao: int, casa: int) -> Array
func simular(indice_mao: int, casa: int) -> Array      # pipeline seco, não muta estado
func descartar(indices: PackedInt32Array) -> Array
func comprar() -> Array
func voltar_atras() -> Array                            # restaura os SEIS cursores (R35)
func colheita_final() -> Array                          # R14b
func jogada_legal_existe() -> bool                      # R19b
func estado() -> Dictionary
static func de_estado(e: Dictionary) -> Mesa            # construtor de teste (§4.4)

# nucleo/run.gd
func avancar(resultado: int) -> Array

# nucleo/loja.gd
static func gerar(rng: Aleatorio, rodada: int) -> Array[Dictionary]

# nucleo/selos.gd           (instância ligada a uma Mesa)
func pode_colar(id: StringName, alvo: int) -> String     # "" ou o motivo da recusa

# nucleo/tabuleiro.gd
static func gerar(rng: Aleatorio, grau: int, modificador: StringName) -> GradeRes

# nucleo/outs.gd
static func contar(mesa: Mesa, linha: int) -> Dictionary # {cartas_que_servem, restantes, total}

# nucleo/receita.gd
static func para_deficit(deficit: int, tear: int, niveis: Dictionary, rodada: int) -> Array

# nucleo/estado.gd
static func assinatura(r: Run) -> String                 # SHA-256 via HashingContext

# nucleo/politica.gd
static func escolher(mesa: Mesa, modo: StringName) -> Vector2i   # (indice_mao, casa)

# nucleo/serializacao.gd
static func salvar(r: Run) -> String
static func carregar(s: String) -> Run

# nucleo/motores.gd
static func detectar(mesa: Mesa) -> Array[StringName]
```

**A fita de eventos.** O núcleo **não tem sinais**: todo método público devolve `Array[Dictionary]` ordenado. `Mesa.posicionar()` emite, **nesta ordem fixa** (a mesma da R40): `empurrou` → `assentou` → `linha_fechou` (uma por linha, com a `Avaliacao` copiada) → `cruzada` (se ≥ 2) → `tear_subiu` → `pontos` → `motor` → `removeu` → `reproposta` (uma por perpendicular) → `quebrou` → `ancorou` → `comprou` → `meta_batida` / `mesa_encerrada`. `colheita_final()` emite `colheita_final` por linha na ordem canônica da R14b. Essa ordem é a **prova executável** de "pagar antes de machucar": `_fita_paga_antes_de_doer()` varre 5.000 fitas e falha se o índice de qualquer `removeu`/`reproposta` for menor que o do `pontos` correspondente. `Efeitos.tocar_fita()` transforma a fita numa linha do tempo com as durações da §11; o turbo divide durações; o headless descarta. **Mesma regra, três consumidores** — e um quarto, a prévia da R37, que consome a fita de `simular()`.

**Autoloads (uma responsabilidade cada).** `Avisos` (fila de mensagens não fatais, log em `user://cruzada.log`; não desenha, não decide fluxo, não trava) · `Catalogo` (lê `dados/*.json` uma vez no `_ready`, valida, converte em `Resource` tipado e expõe `total_fichas()`, teto de 18 ms; não guarda estado de run, não sorteia) · `Progresso` (perfil, opções, coleção, conquistas, save/load atômico, migração; não sabe regra) · `Texto` (formatação, número em pt-BR, plural por chave) · `Layout` (`retrato: bool`, escala de fonte, sinal `mudou_orientacao`) · `Audio` (3 barramentos, pool de 16, ducking, **modo mudo sob headless**) · `Efeitos` (`fator`, tremor, hitstop, háptica, pools, `tocar_fita`; **não altera estado do núcleo**) · `Ruido` (**única** fonte de aleatoriedade não determinística: jitter, fundo, variação de tom; **nunca** entra em regra) · `Navegacao` (grafo, `ir`, `voltar`, fade, pilha). Ordem importa: `Avisos` primeiro, `Navegacao` último. **Não existe autoload de RNG de regra.**

**Dados.** Carta é `int` 0..51, nunca objeto — grade e mão viram `PackedInt32Array` sem alocação. O resto é `Resource` com `class_name` (`MaoRes`, `SeloRes`, `ReliquiaRes`, `ChefeRes`, `MutacaoRes`, `MotorRes`, `RodadaRes`, `GradeRes`, `ConquistaRes`), autorado em JSON com `"versao": 1` e convertido no boot, com `_validar() -> String` por classe. O **estado da run** é JSON puro (`serializacao.gd`), **nunca** `ResourceSaver`.

```gdscript
class_name Aleatorio extends RefCounted
func _init(semente: int) -> void                        # 6 RandomNumberGenerator
func inteiro(fluxo: StringName, ate: int) -> int        # incrementa cursores[fluxo]
func rebobinar(fluxo: StringName, passos: int) -> void  # re-semeia e reconsome
func instantaneo() -> Dictionary                        # {semente, cursores}
```

**`project.godot`:** `config/name="PLACARD"`; `run/main_scene="res://cenas/abertura.tscn"`; `config/features=PackedStringArray("4.7","GL Compatibility")` (ajustado à versão real, §3.2); autoloads na ordem acima; `viewport_width=1280`, `viewport_height=720`, `stretch/mode="canvas_items"`, `stretch/aspect="expand"`, `handheld/orientation="sensor"`; **`rendering/renderer/rendering_method="gl_compatibility"`** e a chave `.mobile` correspondente — **a chave é essa, com o prefixo `rendering/` completo; confirme no `--doctool`**; `anti_aliasing/quality/msaa_2d=1`; `locale/translations` com os três `.translation`. Ações: `posicionar`, `cancelar`, `cima|baixo|esquerda|direita`, `carta_1..carta_6`, `descartar`, `voltar_atras`, `turbo`, `foco`, `receituario`, `pausa`, `baralho_aberto`.

**Desempenho.** Alvo 60 fps em GL Compatibility com vídeo integrado modesto. Orçamento por quadro (16,6 ms): núcleo 0,2 ms mediana / 1,0 ms teto; prévia fantasma ≤ 0,05 ms; UI ≤ 4 ms. `partida.tscn` ≤ **260 nós**. Carta é **um** `Control` com `_draw`, sem sub-nós de textura. Pools no `_ready`: 24 fichas voadoras, 12 emissores, 6 rótulos flutuantes. **Nenhum script de carta tem `_process`** — um único diretor avança a fita. `Contador` só escreve `text` quando o inteiro muda. Rótulos ficam em cache invalidado **apenas** em posicionar/colher: **nunca reavaliar 25 casas por quadro.** `nucleo_testes` mede 10.000 posicionamentos e falha se a média passar de **0,3 ms** — **este é o número que orçamenta toda a §15**; `fluxo_testes` falha se a contagem de nós de qualquer tela passar do teto declarado.

---

## 15. TESTES E VALIDAÇÃO

**Sem framework externo.** `testes/apoio.gd` fornece `_ok(nome, condicao)`, `_igual`, `_quase`, contador e `quit(1)` em falha. Nada mais.

### 15.1 Os arquivos de teste

| Arquivo | Cena | Cobre | Alvo |
|---|---|---|---|
| `nucleo_testes.gd` | `testes.tscn` | avaliador (48), grade e colheita (30), cruzada, Tear e teto (22), colheita final R14b (10), chefes × grau (54), economia e loja (18), determinismo (12), save e migração (10), fita (6), replay da 4.4, prévia = resultado, anti-mão-morta, âncora, pilhas | **≥ 220 asserções nomeadas, < 25 s** |
| **suíte gerada** | `testes.tscn` | pares de itens (§15.5) | **≥ 1.000 asserções geradas** |
| `fluxo_testes.gd` | `fluxo.tscn` | instancia **cada** cena com parâmetros válidos e inválidos, navega o grafo, alterna retrato/paisagem e os 3 idiomas, `_carta_cabe_na_casa`, confere que nenhum `Control` estoura o pai e que nenhuma tela vaza nó; com `-- --matriz-layout`, roda a matriz de legibilidade (§15.4) | **100% das cenas, < 30 s** |
| `teste_juice.gd` | `testes.tscn` | trio visual+sonoro+háptico por ação, tween não registrado em `pulaveis`, som repetido em < 60 ms, prêmio/perda no mesmo quadro | 0 falhas |
| `simulacao.gd` | `simulacao.tscn` | balanceamento e varredura; `capturas/balanceamento.csv` | bandas da 7.4 |
| `demonstracao.gd` | `simulacao.tscn` | joga 20 mesas gravando `capturas/sensacao.csv` (§16 Etapa 11b) | — |
| `captura.gd` | `capturas.tscn` | gera os PNGs | — |

**≥ 220 asserções nomeadas escritas à mão é PISO, não meta** — só o avaliador exige 48 e os chefes × grau 54. Um número-alvo baixo autoriza a frota a parar cedo; a suíte gerada existe justamente para que o número grande não seja escrito à mão.

**Asserções que valem por si e não podem faltar:**
- `_fita_paga_antes_de_doer` — 5.000 fitas, nenhum `removeu`/`reproposta` antes do `pontos`.
- **`_previa_igual_ao_resultado`** — **o teste mais importante da suíte**: 5.000 posicionamentos com layouts aleatórios de selos, comparando o campo `pontos` da fita de `simular()` com o da fita real, falhando em **qualquer divergência de 1 ponto**. Sem ele, todo selo com efeito de pipeline (Vidro, Cofre, Fole, Sino, Alçapão, Âncora, Raiz, Bordado) faz o jogo mentir na tela e derruba o item 4 da §18.
- `_replay_rodada4_rachada` — a fixture da §4.4.
- `_teto_rodada6` — a prova da §6.2.
- `_nunca_mao_morta`, `_ancora_nao_faz_renda_infinita`, `_conservacao_das_pilhas`, `_baralho_curto_nao_esgota`, `_teto_de_posicionamentos_devolvidos`, `_quina_pela_rota_do_espelho`, `_estante_tres_cartoes`, `_fim_de_run_tem_item_positivo`, `_acervo_esgota_em_60_runs`, `_carta_cabe_na_casa`, `_desempenho_nucleo`, `_teto_de_nos`, `_save_atomico`, `_migracao_v1_v2_v3`, `_determinismo_com_voltar`.

**Determinismo:** 200 seeds × run completa gerando `Estado.assinatura()` (SHA-256 via `HashingContext` sobre grade + mão + pontos + dinheiro + cursores); roda de novo com **20 "Voltar atrás" inseridos no meio** e as assinaturas finais têm de bater **byte a byte** — o que só funciona com a restauração dos seis cursores da R35.

**Simulador é GDScript rodando o mesmo núcleo** (`--runs`, `--seed0`, `--tabuleiro`, `--modo`, `--politica`, `--assistencias`, `--rapido`, `--varredura-travamento` por `OS.get_cmdline_user_args()`). **Regra nunca é reimplementada em Python** — Python só agrega o CSV. `politica.gd` traz **três** políticas: `gulosa` (padrão: `delta_pontos + 0,6·delta_outs − 0,8·dano_perpendicular`), `anel1` (só `delta_pontos`) e `aleatoria` (o piso). A comparação entre as três é a banda 7 da §7.4.

### 15.2 O `testar.sh` cresce com as etapas — "verde" é determinístico

`testar.sh` abre com `set -euo pipefail` e **`cd "$(dirname "$0")"`** (obrigatório: o §2 o invoca da raiz do repositório como `bash placard/testar.sh`; sem isso todos os caminhos relativos quebram). **Dois modos:**

- **`testar.sh`** — rápido, **alvo ≤ 3 min**, sem simulação de balanceamento pesada. É a barreira das **Etapas 1–10**.
- **`testar.sh --completo`** — inclui `--runs=10000`, a varredura de travamento e `relatorio_balanceamento.py --exigir` integral. **Alvo ≤ 30 min.** É barreira só das **Etapas 11 e 12** e do DoD.

| Etapa | O que `testar.sh` roda (cumulativo) |
|---|---|
| E1 | `verificar_godot.py` + `validar_estilo.py` |
| E2 | + nada novo (a barreira é o parecer do revisor, §2) |
| E3 | + `testes.tscn` |
| E4 | + `validar_camadas.py` |
| E5 | + `fluxo.tscn` |
| E6 | + `fluxo.tscn -- --matriz-layout` |
| E7 | + `validar_contraste.py` |
| E8 | + `validar_dados.py` + suíte gerada |
| E9 | + `gerar_audio.py --verificar` + `teste_juice.gd` |
| E10 | + `gerar_traducoes.py --verificar` (com `@PENDENTE` proibido a partir daqui) |
| E11 | + `simulacao.tscn --runs=300 --rapido` (rápido) e o `--completo` uma vez |
| E11b/E12 | tudo |

O bloco abaixo é a **forma final** do script, na Etapa 12; nas etapas anteriores ele contém só as linhas que a tabela acima exige.

```bash
#!/usr/bin/env bash
# Suíte do PLACARD. Sem argumento: modo rápido (barreira das Etapas 1-10).
# Com --completo: balanceamento integral e varredura (Etapas 11-12 e DoD).
set -euo pipefail
cd "$(dirname "$0")"

GODOT_BIN="$(python3 ferramentas/verificar_godot.py --resolver || true)"

python3 ferramentas/validar_estilo.py
python3 ferramentas/validar_camadas.py
python3 ferramentas/validar_dados.py
python3 ferramentas/validar_contraste.py
python3 ferramentas/gerar_traducoes.py --verificar
python3 ferramentas/gerar_audio.py --verificar
python3 ferramentas/capturas.py
if grep -rnE "HTTPRequest|HTTPClient|WebSocketPeer|UPNP" scripts/; then exit 1; fi

if [ -z "$GODOT_BIN" ]; then
  echo "MODO DEGRADADO — Godot ausente; veja BLOQUEIO EXTERNO em AUDITORIA.md"
  exit 0
fi

"$GODOT_BIN" --headless --import >/dev/null 2>&1 || true
"$GODOT_BIN" --headless res://cenas/testes.tscn
"$GODOT_BIN" --headless res://cenas/fluxo.tscn
"$GODOT_BIN" --headless res://cenas/fluxo.tscn -- --matriz-layout

if [ "${1:-}" = "--completo" ]; then
  "$GODOT_BIN" --headless res://cenas/simulacao.tscn -- --runs=10000
  "$GODOT_BIN" --headless res://cenas/simulacao.tscn -- --varredura-travamento
  python3 ferramentas/relatorio_balanceamento.py --exigir
else
  "$GODOT_BIN" --headless res://cenas/simulacao.tscn -- --runs=300 --rapido
  python3 ferramentas/relatorio_balanceamento.py --exigir --amostra
fi
```

**Por que não "~90 s":** pela métrica do próprio §14 (0,3 ms por posicionamento) e pela §6.1 (18 mesas × ~16 posicionamentos), **2.000 runs = ~576.000 posicionamentos ≈ 172 s só de núcleo** — a suíte com `--runs=2000` **nunca** caberia em 90 s. O modo rápido roda 300 runs (~26 s) e o pesado fica no `--completo`.

**Validadores Python:** `verificar_godot.py` (**resolve** o binário, imprime a versão real, grava em `AUDITORIA.md`, `--resolver` imprime só o caminho e **sai 0 mesmo sem motor**) · `validar_camadas.py` · `validar_estilo.py` (tipagem 100%, limites de tamanho, proibidos `TODO`/`FIXME`/`HACK`/`XXX`, código comentado, `print(` fora de `Avisos`/`testes/`, `pass` órfão, `.gd` de núcleo sem `class_name`, literal de texto na UI, número mágico de regra fora de `dados/`, **total de acervo escrito**, `Color(` fora de `tema.gd`) · `validar_dados.py` (esquema, **15 campos**, ids únicos entre TODOS os arquivos, referências cruzadas, **curva de metas recomputada pela R21**, cota de geometria ≤ 40% numérico, opcode dentro da §8.0, ícone obrigatório, campo `borda`, `rota` nos baralhos, predicado nas conquistas, `counter_play` nos chefes, regra de sanidade dos modificadores) · `validar_contraste.py` (recomputa e **reescreve** a tabela do `DESIGN.md`) · `gerar_traducoes.py --verificar` · `gerar_audio.py --verificar` (hashes + orçamento de 4,5 MB) · `capturas.py`.

### 15.3 Varredura de travamento — dimensionada para caber

`--varredura-travamento` percorre **16 modificadores × 8 baralhos × 9 presets de Tabuleiro × 30 seeds = 34.560 combinações**, e em cada uma avalia **uma mesa com 40 posicionamentos gulosos** — não a run inteira. Motivo: travamento é propriedade da **mesa**, não da run, e `34.560 × 40 × 0,3 ms ≈ 7 min` cabe no `--completo`, ao passo que 34.560 runs completas levariam ~50 min por iteração de ajuste. Acrescente os **Fardos existentes × 30 seeds** no Infinito. Falha em: qualquer turno sem jogada legal (R19b), qualquer momento com < 5 linhas vivas (R19), qualquer exceção, qualquer laço acima de 2× o orçamento.

### 15.4 "Legível" vira um comando

A barreira da Etapa 6 **não é uma imagem julgada por humano**; é:

```
"$GODOT_BIN" --headless --path placard res://cenas/fluxo.tscn -- --matriz-layout
```

que instancia **toda tela** em **360×800, 720×1280 e 1280×720 × 3 idiomas × escala de UI {100%, 150%} × fonte {+0, +8}** e **FALHA** se: algum `Control` ultrapassar o retângulo do pai; algum texto do loop de turno ficar abaixo de **12 px lógicos**; algum alvo primário ficar abaixo de **64 px** no menor lado; algum rótulo de linha ficar sem os dois campos; ou a carta da grade não couber na casa. **Esse comando é a definição operacional de "legível".** A checagem de estouro roda sob `xvfb-run` **quando disponível**, porque em `--headless` as métricas de fonte podem vir zeradas — e o resultado dos dois modos vai para o `AUDITORIA.md`.

**Capturas:** `--headless` usa renderizador nulo e não desenha nada — captura exige display virtual: `xvfb-run -a "$GODOT_BIN" --resolution 1280x720 --path placard res://cenas/capturas.tscn`, gerando `capturas/{menu,modos,partida,partida_retrato,previa,colheita,cruzada,motor,loja,mapa,colecao,postmortem,fim_de_run,opcoes,alto_contraste,en,es}.png`, e uma segunda passada em `--resolution 360x800` para `capturas/partida_360x800.png`. **Se `xvfb-run` não existir, registre `CAPTURAS — puladas — xvfb ausente` em `AUDITORIA.md` e siga; capturas nunca bloqueiam etapa.**

### 15.5 Pares de itens: cobertura **gerada**, borda **escrita**

"Todos os pares de selos testados" escrito à mão são 406 testes no Lote 1 e 2.850 no Lote 2, cada um com expectativa numérica autorada. **Não se escreve isso; gera-se.** `nucleo_testes.gd` enumera **os pares de itens que podem coexistir na mesma casa ou eixo** (o conjunto pequeno, não o produto cartesiano) e, para cada par, roda **3 seeds de mesa completa** afirmando **5 propriedades**:

(a) nenhum travamento; (b) pontos ≥ 0 e finitos; (c) **a prévia bate com o resultado**; (d) o invariante da R19 se mantém; (e) a fita paga antes de doer.

O campo `borda` continua **obrigatório e escrito à mão** — é ele que documenta o caso-limite. A **cobertura** é gerada.

### 15.6 Export — condicional, porque templates não podem ser baixados

Exports exigem **export templates (~1 GB)** que **NÃO podem ser baixados** sob o §3.6 e o item 19 da §19. `construir.py` **detecta** os templates em `~/.local/share/godot/export_templates/<versão>/`; **existindo**, gera os três presets; **não existindo**, grava `EXPORT — pulado — templates ausentes` em `AUDITORIA.md` e **sai 0**. Os três presets ficam versionados em `export_presets.cfg` de qualquer jeito, e `construir.py --validar-presets` **lê o `.cfg` sem exportar**: `Linux/X11 x86_64`, `Windows Desktop x86_64` (sem `rcedit`, ícone embutido desligado e isso declarado no `README.md`) e `Web` (Compatibility obrigatório, threads desligadas, `.wasm` + `.pck` gzip ≤ 25 MB). Havendo build, `construir.py --verificar-web` serve por `python3 -m http.server` e confere, e o script falha se a saída sumir ou variar mais de 30% de tamanho versus o build anterior.

**Não existe item de DoD mandando a build exportada rodar `--headless res://cenas/testes.tscn`:** rodar cena arbitrária por linha de comando é recurso de **editor**, não de template de export. Quem prova a suíte é o motor, não o binário exportado.

---

## 16. PLANO DE EXECUÇÃO EM ETAPAS

Cada etapa termina com o jogo em **estado jogável** e `testar.sh` verde **para as verificações daquela etapa** (tabela da §15.2). Não avance com vermelho.

| # | Entrega | Verificação de saída |
|---|---|---|
| **1** | Esqueleto: `project.godot`, árvore, `.gitignore` literal, `constantes.gd` com o enum `Categorias`, `apoio.gd`, `testar.sh` mínimo, `verificar_godot.py`, despejo do `--doctool` | Motor resolvido e gravado em `AUDITORIA.md`; `testar.sh` sai 0 (ou modo degradado registrado) |
| **2** | `DESIGN.md` completo **antes de qualquer regra**: as 48 regras, o pipeline R40, a tabela de opcodes da §8.0, os **contratos congelados da §14.9**, todas as bordas, os cortes (Funil, Nível, Enxuta, curva `1,6^n`, redução da cruzada) e as bandas de aceite | Parecer escrito do revisor adversarial em `AUDITORIA.md`: `REVISÃO F1 — <n> achados — <n> corrigidos — <n> dívidas com teste` |
| **3** | Núcleo de pontuação: `cartas`, `maos`, `avaliacao`, `outs`, `rotulos`, `receita` | 48 asserções do avaliador + `_quina_pela_rota_do_espelho` |
| **4** | Núcleo de mesa: `grade`, `mesa`, `aleatorio`, `fita`, colheita, **cruzada com teto visível**, Tear, **colheita final R14b**, **diagonais R03b**, invariante R19 e R19b | Replay 4.4 dá **4.144 pontos**; `_fita_paga_antes_de_doer`, `_previa_igual_ao_resultado` e `_nunca_mao_morta` verdes; 0 travamentos em 300 seeds |
| **5** | **Primeiro jogável**: `partida.tscn` com grade, mão, prévia fantasma vinda de `simular()`, halo tricolor + ordenação por delta, rótulos de 2 campos (12 linhas), HUD com Tear e Mínimo Dourado, minimapa da build, colheita animada | Uma mesa completa jogável; `capturas/partida.png` |
| **6** | Retrato e legibilidade: `layout.gd`, arranjo 720×1280, modo foco, gaveta de prévia, Receituário colapsável; Lote 0 de conteúdo | **`fluxo.tscn -- --matriz-layout` sai 0** — a barreira da primeira semana é esse comando, não uma imagem |
| **7** | Run completa: `run`, `economia`, `loja`, `mapa` (com chefe + counter-play), `postmortem`, `fim_de_run`, save/load atômico e retomada, pausa com reiniciar e abandonar | Run de 18 mesas do tutorial ao fim de run; fecha e retoma no mesmo ponto |
| **8** | Conteúdo Lote 1: selos, eixos, relíquias, **6 chefes**, **12 motores**, ofícios, baralhos, 16 modificadores, os 9 presets de Tabuleiro, encruzilhadas | `validar_dados.py` verde (15 campos, cota de geometria, opcodes, `counter_play`, `rota`); **suíte gerada par a par verde** |
| **9** | Juice, áudio e háptica: `gerar_audio.py`, `Efeitos`, `Audio`, sequência quadro a quadro, tiers, música em camadas, turbo | `teste_juice.gd` verde; nenhum silêncio na tabela de ações |
| **10** | Telas restantes, tutorial, coleção (com Motores), conquistas, estatísticas, diário, opções, controles, i18n em 3 idiomas | `fluxo.tscn` cobre 100% das cenas em 2 orientações × 3 idiomas; `@PENDENTE` passa a reprovar |
| **11** | Balanceamento: `simulacao.gd`, as 3 políticas, `relatorio_balanceamento.py --exigir`, ajuste pelos 6 dials da §7.4 em **≤ 12 iterações** | `testar.sh --completo` sai 0 **ou** `AUDITORIA.md` traz `BALANCEAMENTO — bandas não atingidas` com valor medido × banda |
| **11b** | **Prova de diversão** (§16.2) | Nenhum trecho de 25 s sem evento T2+ em mesa mediana; `SENSACAO.md` escrito |
| **12** | Acabamento: acessibilidade completa, exports (ou pulo registrado), capturas (ou pulo registrado), `README.md`, `AUDITORIA.md`, DoD, commit e push | `testar.sh --completo` do zero; DoD 100% com a prova de cada linha ou o corte registrado |

### 16.1 Mínimo inegociável e ordem de sacrifício

O escopo deste documento é maior do que qualquer janela de tempo garante. **Isto não autoriza afrouxar teste; autoriza cortar escopo, na ordem escrita, com registro.**

**MÍNIMO INEGOCIÁVEL = Etapas 1 a 7** (núcleo completo, primeiro jogável, retrato legível, run inteira com loja, save e retomada). **Abaixo disso, nada é cortado.**

Acima disso, se o tempo apertar, corte **NESTA ORDEM**, registrando cada corte em `AUDITORIA.md` sob `CORTE POR ESCOPO — <item> — <motivo> — <data>`:

1. Lote 2 inteiro (76 modificadores, 36 conquistas).
2. Fardos e modo Infinito.
3. Diário e replay base32.
4. Conquistas além das 12 da Progressão.
5. Ofícios além dos 12 nomeados.
6. Idiomas além de `pt`.
7. Modificadores de mesa além dos 4 do Lote 0 (os 6 chefes **não** são cortáveis: sem eles a rodada não tem identidade).
8. Baralhos além de 3.
9. Exports.

**Entrega com cortes registrados e `testar.sh` verde é APROVADA. Entrega sem o mínimo, ou com teste afrouxado, é reprovada.**

### 16.2 Etapa 11b — Prova de diversão (o processo criativo, não só a engenharia)

`demonstracao.gd` joga **20 mesas sozinho** gravando `capturas/sensacao.csv` com, por turno: tempo, número de jogadas competitivas, `delta do anel #1 − delta da jogada escolhida`, e segundos desde o último evento com Tier ≥ T2. Um **agente revisor** escreve `SENSACAO.md` respondendo **por escrito**:

1. Qual foi o turno mais longo sem nenhum evento T2+ e por quê.
2. Quais itens a política nunca comprou em 10.000 runs (cruzando com o detector de conteúdo morto da §7.4).
3. Em que rodada o anel #1 passa a ser sempre certo (cruzando com a banda da profundidade).
4. Quantos segundos de uma mesa mediana são animação, a 1,0× e a 2,5×.
5. Quais dos 12 motores nunca dispararam.

Cada resposta vira **ou** um ajuste nos dials declarados da §7.4, **ou** uma dívida registrada em `AUDITORIA.md` com o teste que a cobre. **Barreira de saída: nenhum trecho de 25 s sem evento T2+ em mesa mediana.**

---

## 17. DEFINIÇÃO DE PRONTO (DoD)

Cada linha precisa da prova executável ao lado. "Está bom" não é prova. **Todo comando desta tabela precisa ter sido EXECUTADO uma vez, com a saída colada em `AUDITORIA.md`; comando que nunca rodou não conta como prova.** Itens cortados pela §16.1 são marcados `CORTADO — <motivo>` e isso é aceito.

| # | Item | Comando ou asserção que prova |
|---|---|---|
| 1 | Motor resolvido, versão conferida e não presumida | `python3 placard/ferramentas/verificar_godot.py` → imprime binário e versão reais |
| 2 | API conferida na build instalada, não de memória | `ls /tmp/apidocs` não vazio + seção `API CONFERIDA` em `AUDITORIA.md` com os 15 suspeitos da §3.3 |
| 3 | Suíte rápida verde | `bash placard/testar.sh; echo $?` → `0` |
| 4 | Suíte completa verde (ou bandas registradas) | `bash placard/testar.sh --completo; echo $?` → `0` |
| 5 | ≥ 220 asserções nomeadas + suíte gerada ≥ 1.000 | `"$GODOT_BIN" --headless --path placard res://cenas/testes.tscn` → contagem impressa |
| 6 | 100% das cenas instanciam, navegam e voltam | `"$GODOT_BIN" --headless --path placard res://cenas/fluxo.tscn` |
| 7 | Determinismo com 20 "Voltar" (seis cursores) | asserção `_determinismo_com_voltar` |
| 8 | Zero travamento em 16 mod × 8 baralhos × 9 presets × 30 seeds | `"$GODOT_BIN" --headless --path placard res://cenas/simulacao.tscn -- --varredura-travamento` |
| 9 | Nunca existe mão morta (R19b) | asserção `_nunca_mao_morta` |
| 10 | **A prévia nunca mente** | asserção `_previa_igual_ao_resultado` (5.000 posicionamentos, divergência de 1 ponto reprova) |
| 11 | O jogo não se resolve sozinho pela UI | banda 7 da §7.4: `gulosa` ≥ `anel1` + 12 p.p.; < 4 p.p. reprova |
| 12 | Nenhum item morto (< 3%) nem dominante (> 45%) | `python3 placard/ferramentas/relatorio_balanceamento.py --exigir` nomeia o item |
| 13 | Bandas de balanceamento da §7.4 | `relatorio_balanceamento.py --exigir` → 0, ou `BALANCEAMENTO — bandas não atingidas` com valor medido |
| 14 | Curva de metas idêntica à fórmula da R21 | `python3 placard/ferramentas/validar_dados.py` (recomputa e compara) |
| 15 | Núcleo não conhece apresentação | `python3 placard/ferramentas/validar_camadas.py` |
| 16 | Tipagem 100%, zero número mágico, zero literal de UI, zero `TODO` | `python3 placard/ferramentas/validar_estilo.py` |
| 17 | Todo item de dado com os **15 campos** (`id, nome, familia, raridade, custo, alvo, efeito_txt, opcode, params, eixo_de_efeito, icone, borda, sinergia, desbloqueio, testes`), opcode da §8.0 e cota de geometria ≤ 40% numérico | `python3 placard/ferramentas/validar_dados.py` |
| 18 | Contraste dentro dos limiares nos 2 temas, com a tabela reescrita pelo medido | `python3 placard/ferramentas/validar_contraste.py` |
| 19 | 3 idiomas sem chave órfã nem estouro de caixa | `python3 placard/ferramentas/gerar_traducoes.py --verificar` |
| 20 | Todo `.wav` reproduzível pelo script que o gera, e a música ≤ 4,5 MB | `python3 placard/ferramentas/gerar_audio.py --verificar` |
| 21 | Zero rede, zero telemetria | `grep -rnE "HTTPRequest\|HTTPClient\|WebSocketPeer\|UPNP" placard/scripts/` **está errado** — com `-E`, `\|` é pipe literal e o item passaria vazio para sempre. Use: `! grep -rnE "HTTPRequest|HTTPClient|WebSocketPeer|UPNP" placard/scripts/` |
| 22 | Legibilidade em 3 tamanhos × 3 idiomas × 2 escalas × 2 fontes | `"$GODOT_BIN" --headless --path placard res://cenas/fluxo.tscn -- --matriz-layout` |
| 23 | 18 capturas geradas e validadas (ou pulo registrado) | `xvfb-run -a "$GODOT_BIN" --resolution 1280x720 --path placard res://cenas/capturas.tscn` + `python3 placard/ferramentas/capturas.py` |
| 24 | Presets de export válidos; builds geradas ou pulo registrado | `python3 placard/ferramentas/construir.py --validar-presets` e `python3 placard/ferramentas/construir.py --todos` → 0 (gerando **ou** registrando `EXPORT — pulado`) |
| 25 | Save sobrevive a corte de energia e a migração | `_save_atomico` e `_migracao_v1_v2_v3` |
| 26 | 10.000 posicionamentos < 0,3 ms de média; `partida` ≤ 260 nós | `_desempenho_nucleo` e `_teto_de_nos` |
| 27 | Invariante da Estante, "último gole" e acervo derivado | `_estante_tres_cartoes`, `_fim_de_run_tem_item_positivo`, `_acervo_esgota_em_60_runs` |
| 28 | Prova de diversão feita | `capturas/sensacao.csv` existe e `SENSACAO.md` responde às 5 perguntas da §16.2 |
| 29 | `DESIGN.md`, `README.md`, `AUDITORIA.md` escritos e coerentes | `validar_dados.py` e `validar_contraste.py` grepam o `DESIGN.md` e reprovam divergência de tabela; o revisor adversarial assina o parecer |
| 30 | Commit feito (push, havendo remoto) | `git log --oneline -1` com `git status` limpo; sem remoto, `PUSH — falhou — <motivo>` em `AUDITORIA.md` |

---

## 18. CRITÉRIOS DE ACEITE DE JOGABILIDADE

Cada cenário vira um roteiro em `fluxo_testes.gd` ou uma captura conferida.

1. **Abro o jogo pela primeira vez e em 15 s já pontuei uma mão** — sem save, `abertura` vai direto ao tutorial; primeira carta ~5 s, primeira colheita ~11 s, zero cliques de menu.
2. **Em 60 s entendi a regra sem ler nada** — vi uma colheita **arrancar** carta de cada perpendicular e uma cruzada somar mults, com ≤ 12 palavras na tela por passo. Aos 46 s a grade abre em 5×5 e a run começa **sem clique**: o menu só aparece se eu apertar `Esc`.
3. **Clico em Jogar e a mesa acaba em menos de 110 s**, sem timer e sem bloqueio de entrada acima de 250 ms.
4. **Nunca sou surpreendido por um número** — antes de soltar vejo categoria, fichas, mult, pontos exatos de linha, coluna e diagonal, o que será destruído, e **o teto quando ele morde** (`×52 → ×48`).
5. **Nenhuma colheita vale zero** — a linha mais lixo paga ~50 pontos e, no fim da mesa, toda linha com 3+ ainda paga metade, pela semântica escrita na R14b.
6. **Nunca fico sem jogada** — nenhuma combinação modificador × baralho × Tabuleiro trava; não havendo par legal, a R19b me dá uma troca de graça; quando nada é bom, a descarga aparece nomeada.
7. **Perco e entendo por quê** — carta, casa, delta em pontos e porcentagem real ("3 em 34 — 8,8%"), dizendo se foi azar ou erro.
8. **Perco e não fico sem nada** — dinheiro proporcional, uma Fiança acesa (só por perda que eu não escolhi), Novelos, um carimbo fantasma da cruzada que estava na mesa e, ao repetir, **+1 posicionamento**.
9. **Fecho no meio de uma mesa e volto exatamente onde parei**, com a mesma grade, mão e baralho.
10. **Mesma seed = mesma run**, inclusive usando "Voltar atrás" no meio.
11. **Faço uma cruzada e o jogo para para olhar** — câmera lenta, duas (ou três) escadas de notas, `×4 + ×8 = ×12`, e **nenhum modal antes**.
12. **Ganho com Carta Alta acidental e o fim ainda é festa** — a colheita que cruza a meta recebe no mínimo T3 e os posicionamentos não usados voam como moedas.
13. **Compro um selo e a casa importa** — C3 vale por 4 linhas, A1 por 3, B1 por 2; o seletor mostra as diagonais, o minimapa mostra a forma durante o jogo e o fim de run exporta o mapa como imagem.
14. **Descubro um motor sem ninguém me contar** — duas peças que eu comprei por motivos separados disparam juntas, o nome aparece 900 ms em moldura de cobre e vira célula na Coleção.
15. **Jogo em pé, no celular** — em 360×800 os rótulos continuam legíveis como barras simbólicas, o toque longo abre a prévia e a cruzada vibra 55 ms.
16. **Sou daltônico e jogo normalmente** — cor, forma e letra, Quatro Cores por padrão, halos com hachura no alto contraste.
17. **Ligo "reduzir movimento" e não perco recompensa** — some a câmera lenta, permanecem pagamento, escada e contagem.
18. **Desligo as assistências e o jogo continua justo** — sem halo e sem anéis as bandas da §7.4 continuam válidas, porque foram medidas assim também.
19. **Subo a dificuldade porque quero** — um degrau por vitória, reversível, e nenhuma conquista base exige passar do Tabuleiro 1; o que muda ao subir é a **marca** no carimbo, não o conteúdo disponível.
20. **Termino a run e recebo um artefato** — 3 estatísticas, 1 caminho, mapa de calor, frase da mesa, carimbos novos da Matriz e os fantasmas dos quase-acertos; nunca um julgamento.

---

## 19. ANTIPADRÕES PROIBIDOS (reprovam a entrega)

1. Perguntar ao usuário, ou pausar esperando resposta.
2. Presumir API do Godot de memória em vez de conferir o `--doctool` da build instalada.
3. Regra de jogo em script de tela, ou aritmética de pontuação fora de `scripts/nucleo/`.
4. Número mágico de regra fora de `dados/`/`constantes.gd`; total de acervo escrito à mão; texto literal na UI; cor literal fora de `tema.gd`.
5. `randi()`/`randf()`/`randomize()` no núcleo — inclusive na seed de repetição de mesa (R10) — ou RNG de regra exposto como autoload.
6. Prêmio e perda no mesmo quadro — qualquer casa que esvazie antes do fim do voo das fichas.
7. Modal no loop de turno, aviso de demolição antes de cruzada, ou mais de 6 palavras num balão do loop.
8. Animação acima de 150 ms que não pode ser pulada ou não registrada em `Efeitos.pulaveis`.
9. Som repetido no mesmo pitch em menos de 60 ms; ação sem trio visual+sonoro+háptico; pulso audível em mais de 35% das compras.
10. Flash acima de 3 Hz; shake sem opção de desligar; acessibilidade que remove informação ou recompensa em vez de movimento.
11. Item de conteúdo sem `borda`, sem ícone, sem `opcode` da §8.0 ou com opcode inventado; **efeito implementado em script solto, fora do pipeline da R40**; chefe sem `counter_play` testado; baralho sem `rota`.
12. Categoria inalcançável exibida como disponível (Quina sem rota tem de vir com cadeado).
13. Selo ou regra que contradiga a frase única — foi por isso que o Funil foi cortado; não o traga de volta.
14. Vender legibilidade: contagem de outs, prévia, teto do mult ou tabela de mãos atrás de compra.
15. Curva de metas geométrica agressiva (`1,6^n` em 8 rodadas) contra poder aditivo; ou tabela de metas divergente da fórmula da R21.
16. **Prévia que reimplementa cálculo** em vez de ler a fita de `Mesa.simular()`; teto do mult que morde sem aparecer.
17. Modificador que torne uma casa ilegal, impeça uma linha de chegar a 5 ou derrube as linhas vivas abaixo do piso da R19.
18. `Engine.time_scale = 0` para hitstop; `queue_free` em partícula; `_process` em script de carta; reavaliar 25 casas por quadro; gerar cartão de partida a cada mesa.
19. Baixar qualquer binário — fonte, som, textura, ícone, plugin, **export template**.
20. Comentar, pular ou afrouxar teste para o build passar. O teste é o contrato. **Cortar escopo pela §16.1 com registro é permitido; afrouxar teste, nunca.**
21. Deixar tela sem saída, sem foco inicial ou sem resposta a `ui_cancel`; pausa sem "reiniciar mesa" e sem "abandonar run"; run abandonada que não passa pelo `fim_de_run`.
22. Terminar sem commit ou sem os três documentos. (Falha de `push` por ausência de remoto **não** é antipadrão — é linha de `AUDITORIA.md`.)

---

## 20. ENTREGÁVEIS FINAIS

1. **`placard/`** — o jogo completo, rodando com `"$GODOT_BIN" --path placard res://cenas/abertura.tscn`.
2. **`placard/DESIGN.md`** — escrito **antes** do código e atualizado ao fim: as 48 regras, o pipeline R40, a **tabela de opcodes da §8.0**, os **contratos congelados da §14.9**, todas as regras de borda por selo e por par de selos, os cortes declarados (Funil, relíquia Nível, modificador Enxuta, curva `1,6^n`, redução 60/35 da cruzada) **com o motivo**, as bandas de aceite, a prova numérica da razão da cruzada (**1,63**), a semântica completa da R14b e a prova do invariante anti-travamento.
3. **`cruzada/README.md`** — o jogo em 5 linhas, como rodar, como testar (`bash testar.sh` e `bash testar.sh --completo`), como exportar, o que existe (Lotes 0 e 1) e o que **não** existe (Lote 2, itens cortados pela §16.1, limitação do preset Windows, ausência de rede, `metricas.csv` local e apagável).
4. **`cruzada/AUDITORIA.md`** — motor resolvido e versão real; seção `API CONFERIDA` com os 15 suspeitos da §3.3; tabela de **decisões** tomadas sem perguntar, com critério e data; tabela do **DoD** com os 30 itens, o comando executado e a saída colada; relatório de balanceamento com as métricas medidas (e as bandas não atingidas, se houver); `CORTE POR ESCOPO` para cada item cortado pela §16.1; `EXPORT — pulado`, `CAPTURAS — puladas`, `PUSH — falhou` e `BLOQUEIO EXTERNO`, quando aplicáveis; dívidas conhecidas, cada uma com o teste que a cobre.
5. **`cruzada/capturas/`** — as 18 capturas (17 em 1280×720 + `partida_360x800.png`), versionadas, mais um cartão de partida de exemplo. `balanceamento.csv` e `sensacao.csv` são gerados e ficam fora do git.
6. **`cruzada/SENSACAO.md`** — as 5 respostas da Etapa 11b.
7. **`placard/testar.sh`** saindo com código **0** numa execução limpa, do zero, nos dois modos.
8. **Três presets de export versionados** em `export_presets.cfg`, com as builds em `construidos/` (fora do git) quando os templates existirem.
9. **Commit** em `feat/cruzada`, criada a partir da branch atual — **nunca** commit direto na branch padrão. `push` quando houver remoto; falhando, `PUSH — falhou — <motivo>` em `AUDITORIA.md` e o item conta como cumprido. Mensagem descrevendo o entregue, os cortes da §16.1 e o resultado dos dois modos do `testar.sh`.

**Comece agora pela Etapa 1. Não pare até a Etapa 12 estar fechada e o DoD 100% provado ou explicitamente cortado pela §16.1.**
~~~
