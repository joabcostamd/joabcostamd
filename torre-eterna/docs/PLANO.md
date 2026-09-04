# PLANO DE DESENVOLVIMENTO — Torre Eterna

Documento de execução. O que foi feito, por que foi feito nessa ordem, e o que
vem depois. Cada fase termina num **portão verificável**, não numa sensação.

---

## Como este projeto foi construído

A ordem não foi "features primeiro". Foi:

1. **Primeiro a matemática**, porque um incremental que erra número não tem
   conserto depois. `Big` (números em log10) nasceu com 20 testes antes de
   existir uma torre.
2. **Depois o simulador**, porque balanceamento sem medição é chute. O
   `sim_balance.gd` roda o jogo real headless e diz em quanto tempo o jogador
   chega em cada onda. Ele encontrou dois erros de design que nenhuma
   quantidade de "jogar um pouco" teria encontrado.
3. **Só então a tela**, porque juice em cima de simulação errada é maquiagem.
4. **Portões desde o começo**, porque conserto é barato no dia e caro na semana.

---

## Fases

### Fase 0 · Fundação matemática ✅
| Entrega | Portão |
|---|---|
| `Big`: números em log10, alocação zero, alcance além de 1e308 | 20 testes de propriedade |
| `Fmt`: 6 notações, PT-BR e EN, escala longa | teste de ida e volta em 15 magnitudes |
| `Ux`, `RngX`, `Bus`, `SaveSys`, `Cfg` | compila e roda headless |

**Decisão que definiu tudo:** guardar valores gigantes como o **logaritmo** em
vez de mantissa/expoente. Multiplicar vira somar (exato), nada é alocado, e a
precisão relativa fica em ~1e-14 mesmo em 1e500. O custo é que soma exige
log-sum-exp e número negativo não existe — o jogo foi desenhado para não
precisar de nenhum dos dois.

### Fase 1 · Simulação ✅
| Entrega | Portão |
|---|---|
| Estado canônico serializável, com mesclagem de saves antigos | testes de roundtrip |
| Motor de atributos: flat + pct + mult, com multiplicadores gigantes | teste de agregação |
| Arena com pooling e grade espacial | `perf.gd` com 500 inimigos |
| Combate: crítico, armadura, perfuração, ricochete, área, execução, elementos | testes de dano |
| Diretor de ondas, economia, níveis, saque, prestígio, offline | 1013 testes |

**Erro achado pelo simulador nº 1:** a onda travava para sempre se um inimigo
alcançasse a torre — a condição de vitória contava abates, não inimigos
resolvidos. Uma partida de 3h ficou 2h45 parada na onda 29.

**Erro achado pelo simulador nº 2:** comprar vida não aumentava a
sobrevivência, porque o dano de contato era uma fração da vida MÁXIMA da
torre. Toda a linha defensiva do jogo era decorativa.

### Fase 2 · Conteúdo ✅
23 inimigos · 38 cepas · 10 chefes · 2 super-chefes · 39 melhorias · 36
talentos · 30 cartas · 4 conjuntos · 26 relíquias · 85 conquistas · 36 missões
· 40 níveis de temporada · 20 eventos · 14 desafios · 10 eras · 40 entradas de
lore · 10 habilidades.

Tudo em `data/*.json`, validado por `validar_dados.gd` contra o que o motor
realmente entende: atributo existente, condição rastreável, referência
cruzada resolvida, cor hex válida, curva de custo crescente.

### Fase 3 · Apresentação ✅
| Entrega | Portão |
|---|---|
| Arte procedural: 34 silhuetas de inimigo, torre em camadas, 10 fundos de era | inspeção visual por captura |
| Ícones vetoriais (a fonte padrão não tem emoji) | linter proíbe emoji em interface |
| Partículas, números de dano, tremor, hitstop, câmera lenta, flash | inspeção visual |
| Áudio sintetizado: 37 efeitos + música adaptativa por era | teste prova que nenhum som é silêncio |
| 12 painéis + HUD + título + pausa + Fim Verdadeiro | captura de cada painel |

### Fase 4 · Identidade ✅
As mecânicas que separam este jogo de um clone: **A Purga**, **Álbum de
Ecos**, **Adaptação do Enxame**, **O Peregrino**, **O Panteão**, **A
Retomada**, **Aglomeração**, **Caixa da Vigília**. Ver `README.md`.

### Fase 5 · Portões ✅
`verificar` · `lint` · `validar_dados` · `testes` (1013) · `perf` · `soak` ·
`agent_verify` — todos por linha de comando, todos no CI.

---

## O que viria depois

Em ordem de retorno sobre esforço, se o projeto continuar:

1. **Exportação web (HTML5)** — o jogo já usa `gl_compatibility` justamente
   para isso. Falta o preset de exportação e um teste de tamanho do pacote.
2. **Toque e retrato** — a interface é toda código, então a adaptação é
   reposicionar contêineres, não redesenhar. Alvos de toque já têm 44 px+.
3. **Os Axiomas** — regras que a Transcendência troca (não números: regras).
   O GDD tem 14 desenhados; o motor já tem o gancho (`especiais`/`passivas`).
4. **Estratigrafia na arena** — hoje ela aparece só no Fim Verdadeiro. Desenhar
   as faixas no chão da partida, uma por Transcendência, com glifos dos chefes
   derrotados. Custo: um `SubViewport` desenhado uma vez por reset.
5. **Fantasma da run anterior** — a Retomada já compara com a onda alvo;
   falta desenhar o rastro da run passada sendo ultrapassado.
6. **Tradução completa da interface** — a camada `Txt` existe e o validador
   já cobra par PT/EN; falta passar os 12 painéis por ela.
7. **Placar local de melhores runs** — o save já guarda o histórico.

---

## O que NÃO entra

- Compra com dinheiro real, energia, espera artificial.
- Assets externos. Se não dá para desenhar ou sintetizar, não entra.
- Segunda torre. O jogo é sobre uma torre; posicionamento é outro gênero.
- Multiplayer.
