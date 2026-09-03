> **Documento do projeto original — não descreve o jogo que existe.**
> Este texto de conteúdo foi escrito para uma implementação em JavaScript/Canvas
> que nunca foi construída; o jogo é feito em Godot 4 e GDScript. Caminhos
> de arquivo, APIs e números aqui são do projeto, não da realidade.
> Leia `docs/projeto-original/LEIA-ANTES.md` antes de usar qualquer coisa
> daqui.

# TORRE ETERNA — Bíblia de Conteúdo (PT-BR) v2.0
### Documento de Design de Conteúdo — pronto para virar `data/*.json`

> **Contexto de integração:** o repositório já possui `/home/user/joabcostamd/torre-eterna/data/*.json` com conteúdo substancial. Este documento **reconcilia** o que existe e **especifica numericamente** o que falta. Cada bloco marca `[EXISTE]` (id já presente — não duplicar) ou `[NOVO]` (gerar). Todos os `stat` usados existem em `data/stats.json` (39 defs) salvo quando marcado `⚑ NOVO STAT`. Todos os `tipo` de efeito seguem o padrão do repo: `flat` (soma), `pct` (soma percentual à base), `mult` (multiplicativo composto), `passiva` (flag por `chave`).

---

## 0. RECONCILIAÇÃO — o que existe vs. o que este doc entrega

| Sistema | Pedido | Já existe em `/data` | Este doc adiciona | Total final |
|---|---|---|---|---|
| Conquistas | 60+ | 85 (`achievements.json`) | **+34** | **119** |
| Nós de talento | 40+ | 36 (3 ramos) | **+12 (ramo Engenho) +6 (Raízes)** | **54** |
| Tipos de inimigo | 20 | 22 | **+8** | **30** |
| Afixos de elite | — | 9 | **+6** | **15** |
| Chefes | 10 (mecânica única) | 10 + 2 super (só nome de mecânica) | **spec numérico completo dos 12** | **12** |
| Relíquias | 30 (raridade + efeito) | 26 (sem campo `raridade`) | **raridade dos 26 + 8 novas** | **34** |
| Cartas/módulos | 25 | 30 + 4 conjuntos | **+11 cartas, +3 conjuntos** | **41 / 7** |
| Missões diárias | 20 | 24 diárias + 12 semanais | **+12 diárias, +6 semanais** | **36 / 18** |
| Eventos aleatórios | 15 | 20 | **+8** | **28** |
| Desafios | 10 | 14 | **+8** | **22** |
| Codex/Bestiário | textos | **inexistente** | **`codex.json` completo** | **novo arquivo** |
| Eras/Biomas | nomes | 10 | **+4 eras, +8 climas** | **14 / 8** |
| Habilidades | — | 10 | **+5** | **15** |

**Arquivos a criar/alterar:** `data/codex.json` (novo), `data/weather.json` (novo, ou `climas` dentro de `eras.json`), `data/bosses.json` (novo — extrair e expandir `enemies.json:chefes`), e *patches* aditivos nos 14 arquivos existentes.

---

## 1. ERAS E BIOMAS — 14 eras, 8 climas

### 1.1 Eras existentes `[EXISTE]`

| # | id | Nome PT-BR | Onda | Gancho de identidade |
|---|---|---|---|---|
| 1 | `sucata` | Cinturão de Sucata | 1 | Estacionamento enferrujado; tutorial visual |
| 2 | `pantano` | Pântano Catalítico | 12 | Chuva corrói armadura inimiga (−10% armadura global) |
| 3 | `vidro` | Estepe Vitrificada | 28 | Chão reflete projéteis; +8% alcance |
| 4 | `inverno` | Inverno Sob Encomenda | 48 | Inimigos −12% velocidade, +15% vida |
| 5 | `fundicao` | Fundição Perpétua | 75 | +15% dano de fogo, −10% regeneração da torre |
| 6 | `necropole` | Necrópole Orbital | 110 | Mortos deixam +20% ouro, curandeiros dobram |
| 7 | `depuracao` | Camada de Depuração | 155 | Inimigos "glitcham": 5% de chance de reaparecer 1× |
| 8 | `aurora` | Aurora Terminal | 210 | +20% dano elemental; tempestades a cada 40s |
| 9 | `jardim` | Jardim de Singularidades | 320 | Gravidade puxa ouro para o centro (+coleta) |
| 10 | `nada` | Nada, Bem Cuidado | 500 | Sem cenário. Só a torre. −25% dos efeitos de era |

### 1.2 Eras novas `[NOVO]`

| # | id | Nome PT-BR | `ondaInicio` | Paleta (fundo/acento/perigo) | Modificador de era | Céu / Chão |
|---|---|---|---|---|---|---|
| 11 | `catedral` | **Catedral de Antenas** | 750 | `#0b0f1a` / `#7dd3fc` / `#f472b6` | +25% de alcance; inimigos ganham +1% velocidade por onda dentro da era (teto 60%) | `tipo:"antenas"`, densidade 0.5, vel 3 / `tipo:"laje"`, escala 128, op 0.18 |
| 12 | `mare_calcio` | **Maré de Cálcio** | 1100 | `#12100c` / `#e7d9b8` / `#ef4444` | Inimigos deixam ossos que bloqueiam projéteis por 2s; +40% de ouro | `tipo:"poeira"`, densidade 0.7 / `tipo:"ossario"`, escala 64, op 0.3 |
| 13 | `anel_paradoxo` | **Anel de Paradoxo** | 1600 | `#0d0620` / `#a855f7` / `#22d3ee` | A cada 30s a onda "rebobina" 3s: inimigos voltam à posição anterior, você mantém o dano | `tipo:"anel"`, densidade 0.9, vel 12 / `tipo:"malha"`, escala 32, op 0.4 |
| 14 | `pagina_branca` | **Página em Branco** | 2400 | `#f4f4f0` / `#111111` / `#dc2626` | Inversão total de contraste. Inimigos são vazios brancos com contorno. ×2 fragmentos, ×1,5 vida inimiga | `tipo:"vazio"`, densidade 0 / `tipo:"linhas"`, escala 24, op 0.12 |

**Texto de era (`descricao`) — novas:**

- **Catedral de Antenas:** "Mil torres de transmissão apontadas para um céu que parou de responder há muito tempo. Elas continuam transmitindo. Sua torre entrou na frequência sem querer — e agora enxerga mais longe do que deveria."
- **Maré de Cálcio:** "O que resta quando um continente inteiro é digerido e cuspido. Você não anda sobre o chão; anda sobre o que sobrou de quem chegou antes. O ouro aqui é abundante porque ninguém sobreviveu para gastá-lo."
- **Anel de Paradoxo:** "O tempo aqui não passa: ele circula. Você já matou esse inimigo. Vai matá-lo de novo. A boa notícia é que o dano acumula e a memória do Enxame, não."
- **Página em Branco:** "Alguém apagou o cenário e esqueceu de apagar a guerra. Fundo branco, silhuetas pretas, sangue vermelho — a única cor que o autor não teve coragem de remover."

### 1.3 Climas `[NOVO]` — `data/weather.json`

Rodam sobre a era ativa. Duração 45–90s, intervalo 120s, chance ponderada. Anunciados por *banner* + mudança de paleta em 1,5s.

| id | Nome | Peso | Duração | Efeito numérico | Eras |
|---|---|---|---|---|---|
| `chuva_acida` | Chuva Ácida | 100 | 60s | Inimigos perdem 1,5%/s da vida máxima; ouro −15% | pantano, fundicao |
| `nevoa_seca` | Névoa Seca | 90 | 75s | Alcance da torre −25%, dano +40% | sucata, vidro, mare_calcio |
| `sopro_zero` | Sopro Zero | 80 | 50s | Todos os inimigos −40% velocidade; dano de gelo ×2 | inverno, nada |
| `tempestade_ionica` | Tempestade Iônica | 75 | 45s | Cada tiro tem 20% de saltar em 1 alvo extra; habilidades −50% de recarga | aurora, catedral |
| `mare_de_ouro` | Maré de Ouro | 40 | 40s | ×3 de ouro; dourados aparecem 5× mais | qualquer |
| `pressao_gravitica` | Pressão Gravítica | 60 | 70s | Inimigos +60% de vida, −55% de velocidade; coleta de ouro automática | jardim, anel_paradoxo |
| `apagao` | Apagão | 45 | 55s | A tela escurece 70%; inimigos ficam visíveis só dentro do alcance. Ouro ×2, XP ×2 | necropole, depuracao, nada |
| `erro_de_renderizacao` | Erro de Renderização | 25 | 30s | Sprites piscam entre eras; 10% dos inimigos são de eras futuras (com vida da onda atual, ouro da era deles) | depuracao, anel_paradoxo, pagina_branca |

---

## 2. BESTIÁRIO — 30 tipos de inimigo

### 2.1 Existentes `[EXISTE]` (referência numérica)

`hp`/`ouro`/`vel`/`esc` são multiplicadores sobre a curva base da onda.

| id | Nome | hp | ouro | vel | esc | mov | onda | peso | armadura |
|---|---|---|---|---|---|---|---|---|---|
| `grunhido` | Grunhido | 1 | 1 | 1.0 | 1.0 | direto | 1 | 100 | — |
| `corredor` | Corredor | 0.55 | 0.8 | 1.85 | 0.85 | direto | 3 | 70 | — |
| `enxame` | Enxame | 0.28 | 0.4 | 1.35 | 0.6 | zigue | 4 | 65 | — |
| `bruto` | Bruto | 3.6 | 2.4 | 0.62 | 1.45 | direto | 6 | 55 | 18 |
| `voador` | Voador | 0.8 | 1.2 | 1.5 | 0.9 | zigue | 9 | 60 | — |
| `blindado` | Blindado | 2.1 | 2.0 | 0.8 | 1.2 | direto | 12 | 45 | escudo frac. |
| `saltador` | Saltador | 1.1 | 1.3 | 1.0 | 1.0 | salto | 14 | 45 | — |
| `divisor` | Divisor | 1.6 | 1.1 | 0.9 | 1.25 | direto | 16 | 45 | divide ×2 |
| `espectro` | Espectro | 0.9 | 1.6 | 1.15 | 1.0 | fantasma | 18 | 40 | — |
| `curandeiro` | Curandeiro | 1.3 | 2.2 | 0.85 | 1.05 | apoio | 22 | 32 | cura em raio |
| `atirador` | Atirador | 1.0 | 1.8 | 0.75 | 1.05 | parar_atirar | 25 | 38 | — |
| `bomba` | Bomba Viva | 1.4 | 1.5 | 0.95 | 1.3 | direto | 28 | 36 | explode |
| `teleportador` | Teleportador | 1.2 | 2.0 | 0.7 | 1.0 | teleporte | 30 | 34 | — |
| `sanguessuga` | Sanguessuga | 0.85 | 0.6 | 1.4 | 0.9 | direto | 34 | 28 | drena |
| `refletor` | Refletor | 1.5 | 2.4 | 0.8 | 1.15 | direto | 40 | 26 | reflete |
| `coloso` | Colosso | 8.5 | 6.0 | 0.4 | 2.0 | direto | 45 | 18 | 45 |
| `parasita` | Parasita | 1.1 | 1.9 | 1.25 | 0.95 | direto | 50 | 24 | infecta |
| `casulo` | Casulo | 3.0 | 3.5 | 0.25 | 1.6 | direto | 55 | 20 | eclode |
| `sombra` | Sombra | 1.3 | 2.6 | 1.1 | 1.0 | direto | 60 | 22 | invisível |
| `devorador` | Devorador | 2.2 | 2.8 | 0.9 | 1.3 | direto | 70 | 20 | come ouro |
| `aberracao` | Aberração | 4.0 | 5.0 | 1.0 | 1.5 | errante | 90 | 16 | mutável |
| `ceifeiro` | Ceifeiro | 3.2 | 4.5 | 1.3 | 1.4 | perseguidor | 120 | 14 | executa |

### 2.2 Inimigos novos `[NOVO]` — 8 tipos

| id | Nome PT-BR | hp | ouro | vel | esc | mov | onda | peso | Mecânica única (numérica) |
|---|---|---|---|---|---|---|---|---|---|
| `mimico` | **Mímico** | 1.8 | 8.0 | 0.0→1.6 | 0.7 | `disfarce` | 20 | 22 | Nasce **parecendo uma moeda de ouro no chão** (usa o sprite de coletável). Fica imóvel 4s. Se o jogador coletar (ou o ímã puxar), morde: **12% da vida máxima da torre** e ganha `vel 1.6` por 6s. Se for atingido por um projétil antes, revela-se e **solta 8× de ouro**. `revelaEm: 5s` automático. |
| `escavador` | **Escavador** | 2.4 | 2.6 | 1.05 | 1.15 | `tunel` | 38 | 30 | Anda 2s, **mergulha no chão por 3s (imune e invisível)**, emerge 90px mais perto. Repete. Só pode ser atingido nos 2s de superfície. Emerge sempre a ≥120px da torre (nunca dentro do raio morto). Marca no chão 0,6s antes de emergir (telegrafia). |
| `estandarte` | **Porta-Estandarte** | 2.0 | 3.2 | 0.7 | 1.25 | direto | 42 | 26 | **Aura de 150px**: aliados dentro ganham **+30% de velocidade, +25 de armadura e +15% de vida máxima** (aplicado ao entrar). Aura visível como anel pulsante. Ao morrer, a aura persiste 2s e some. Prioridade de alvo automático: alta. |
| `carapaca` | **Carapaça Voltaica** | 2.6 | 3.0 | 0.75 | 1.3 | direto | 58 | 24 | **Imune a dano de raio** e converte 50% do raio recebido em cura própria. A cada 5s solta um arco elétrico que **atordoa os orbes da torre por 2s** (orbes param de causar dano). Fraqueza: dano de gelo ×1,6. |
| `costureiro` | **Costureiro** | 1.6 | 3.4 | 0.95 | 1.1 | `orbitar` | 66 | 22 | Ao nascer, **costura-se a 2 aliados próximos** com um fio visível de 200px. Enquanto o fio existe, os três **dividem todo o dano recebido igualmente** (dano/3 em cada). Matar o Costureiro rompe todos os fios. Fio arrebenta se a distância passar de 260px. |
| `ampulheta_viva` | **Ampulheta Viva** | 2.2 | 4.0 | 0.55 | 1.35 | direto | 80 | 18 | **Campo de 220px** ao redor de si: dentro dele a torre perde **−45% de cadência** e as habilidades recarregam **60% mais devagar**. Não ataca. Só quer chegar perto. Ao morrer, o campo inverte por 4s: **+80% de cadência**. |
| `semente_vazio` | **Semente do Vazio** | 1.9 | 2.2 | 1.2 | 0.9 | direto | 95 | 20 | Ao morrer, cria um **poço gravitacional de 180px por 3s** que puxa todos os inimigos a 200px/s para o centro. É *bom* para o jogador — o inimigo é uma bomba de agrupamento. 18% de chance de o poço explodir no fim causando **300% do seu dano** em área. |
| `arauto_menor` | **Arauto Menor** | 3.0 | 4.2 | 0.85 | 1.2 | direto | 130 | 16 | A cada 6s abre uma **fissura de 100px** no chão que dura 8s. Dentro da fissura, **a torre recebe +50% de dano** e os inimigos ganham **+35% de velocidade**. Máx. 3 fissuras simultâneas por Arauto. Precursor temático do Arauto do Vazio. |

### 2.3 Afixos de elite `[EXISTE 9 + NOVO 6]`

Elites aparecem a partir da onda 15, chance base **3% + 0,08%/onda** (teto 18%). Elite = `hp ×2,5`, `ouro ×3`, halo colorido + nome exibido.

`[EXISTE]`: `blindado` (−45% dano recebido) · `veloz` (+80% vel) · `vital` (×3 vida, ×1,4 escala) · `regenerativo` (2%/s) · `espinhoso` (devolve dano) · `magnetico` (puxa ouro) · `volatil` (explode) · `fantasmal` (intangível periódico) · `aureo` (5× ouro)

| id `[NOVO]` | Nome | Cor | Efeito numérico |
|---|---|---|---|
| `espelhado` | **Espelhado** | `#e0f2fe` | Devolve **25% do dano não-crítico** ao atacante. Críticos passam inteiros e ignoram o reflexo. |
| `nulificador` | **Nulificador** | `#64748b` | Enquanto vivo, **desativa 1 habilidade aleatória** da barra (ícone riscado). Morre → devolve a habilidade com **50% da recarga já paga**. |
| `gemeo` | **Gêmeo** | `#f472b6` | Nasce **em par**. Enquanto um estiver vivo, o outro **cura 3%/s**. Precisam morrer em ≤4s um do outro, senão o sobrevivente **volta a 60% da vida**. |
| `enraizado` | **Enraizado** | `#65a30d` | Não anda: **atira raízes** a 300px causando 4% da vida máx. da torre a cada 3s. **+120% de vida**, **×4 de ouro**. |
| `ancestral` | **Ancestral** | `#fbbf24` | Tem **as estatísticas da onda +25**. Solta **1 carta garantida** (raridade ≥ raro) ao morrer. Aparece só 1 por onda. |
| `temporal` | **Temporal** | `#22d3ee` | A cada 5s **retrocede 2s**: volta à posição e à vida que tinha. Dano acumulado nesses 2s é desfeito. Contra-jogo: burst > 50% da vida em <2s ignora o retrocesso. |

---

## 3. CHEFES — 12 lutas com mecânica única, numeradas

**Cadência:** chefe a cada **10 ondas**. Índice = `((onda/10 - 1) mod 10)` percorrendo a lista abaixo em ordem. **Super-chefe** nas ondas **múltiplas de 100** (alternando `aniquilador` / `trono_vazio`).
**Vida do chefe:** `hpChefe = hpBase(onda) × 55 × (1 + 0,18 × fases) × (1 + 0,05 × chefesJaMortos^0,7)`
**Ouro:** `ouroChefe = ouroBase(onda) × 40 × ouroMult`
**Drop garantido:** 1 carta (peso deslocado 1 raridade acima) + `fragmentos = 2 + floor(onda/25)`.
**Timer:** 90s. Se não morrer, o chefe **enraivece**: +100% de velocidade, +50% de dano, e a onda seguinte começa com ele ainda vivo.

---

### 3.1 `tita_ferro` — **Titã de Ferro** `[EXISTE — spec numérico NOVO]`
> *Ondas 10, 110, 210… · 3 fases · Armadura 40 · vel 0,55*

| Fase | Limiar | Comportamento |
|---|---|---|
| I | 100–66% | **Marcha**. A cada 8s **invoca 6 `grunhido` + 2 `bruto`** nas bordas. Armadura 40 (reduz dano bruto em 40%). |
| II | 66–33% | **Bate no chão** a cada 6s: onda de choque de 260px, **8% da vida máx. da torre**, telegrafia 1,1s (círculo vermelho). Invocação sobe para 8+3 a cada 7s. |
| III | 33–0% | **Placas caem**: armadura vai a 0, mas ele ganha **+120% de velocidade** e invoca **1 `bruto` a cada 2s**. Corre reto na torre. |

**Contra-jogo:** `perfuracao` e `penetracao` anulam a armadura da fase I–II; guarde a Nova para a fase III.
**Áudio:** motivo em Lá menor, sub-baixo 55Hz pulsado a cada passo.

---

### 3.2 `rainha_enxame` — **Rainha do Enxame** `[EXISTE — spec NOVO]`
> *Ondas 20, 120… · 2 fases · vel 0,7*

| Fase | Limiar | Comportamento |
|---|---|---|
| I | 100–50% | **Postura**: a cada 3s põe **4 `enxame`**. Cada `enxame` vivo dá à Rainha **+2% de dano recebido reduzido** (teto 60%). |
| II | 50–0% | **Ninhada Terminal**: põe **10 `enxame` a cada 2s** por 6s, depois fica **vulnerável (−50% de armadura) por 5s**. Ciclo repete. |

**Regra central (mecânica única):** a Rainha **só pode ser ferida abaixo de 50% se houver ≤12 `enxame` vivos na tela**. O jogo mostra o contador "Ninhada: 14/12" em vermelho.
**Contra-jogo:** `area`, `ricochete`, orbes. Dano de fogo com propagação.

---

### 3.3 `nucleo_instavel` — **Núcleo Instável** `[EXISTE — spec NOVO]`
> *Ondas 30, 130… · 3 fases · vel 0,65*

**Mecânica única — Pulso Crescente:** pulsa a cada `max(1,2s ; 5s − 0,4s × pulsosDados)`. Cada pulso: anel de 200px+30px por pulso, dano **4% + 0,5%/pulso** da vida máx. da torre. Após 12 pulsos, **superpulso**: tela inteira, 30% da vida máx., telegrafia de 2,5s com escurecimento total.
- **Fase II (66%)**: pulsos passam a deixar **poças de calor** (90px, 3%/s) por 6s.
- **Fase III (33%)**: o Núcleo **para de se mover** e pulsa a cada 1,2s fixo. É uma corrida de DPS puro.

**Contra-jogo:** `vidaMax`, `armadura`, `escudoMax`, e o Escudo Absoluto guardado para o superpulso.

---

### 3.4 `arauto_vazio` — **Arauto do Vazio** `[EXISTE — spec NOVO]`
> *Ondas 40, 140… · 3 fases · vel 0,6*

**Mecânica única — Fissuras:** a cada 5s abre **1 fissura de 120px** (dura 10s, máx. 6 simultâneas). Dentro de uma fissura, **a torre recebe +60% de dano** e inimigos ganham **+40% de velocidade**. As fissuras nascem sempre **no caminho mais curto até a torre**.
- **Fase II (70%)**: as fissuras passam a **cuspir 1 `espectro` a cada 4s**.
- **Fase III (35%)**: todas as fissuras ativas **se fundem** em uma zona única que cobre 40% da arena. Dentro dela o Arauto **cura 2%/s**. Fora dela, ele fica **imóvel**.

**Contra-jogo:** empurre o DPS na janela em que ele está fora da zona; `danoVazio` causa +50% nele.

---

### 3.5 `serpente` — **Serpente Ciclônica** `[EXISTE — spec NOVO]`
> *Ondas 50, 150… · 1 fase, 8 segmentos · vel 0,9*

**Mecânica única — Segmentos:** corpo de **8 segmentos**, cada um com `hpChefe/8`. Só a **cabeça** causa dano à torre; segmentos causam **2% da vida máx.** ao raspar. Matar um segmento:
- encurta a serpente (visualmente e em hitbox),
- **+12% de velocidade** para o restante (cumulativo — a última cauda voa),
- solta **`ouroChefe/8`** imediatamente.

A cabeça só é atingível quando restam ≤3 segmentos **OU** durante a **Espiral** (a cada 12s ela circunda a torre a 240px por 3s, expondo a cabeça).
**Contra-jogo:** `perfuracao` e `ricochete` cortam múltiplos segmentos por tiro. Cuidado: matar rápido demais gera uma cabeça a 200% de velocidade.

---

### 3.6 `guardiao_espelho` — **Guardião Espelhado** `[EXISTE — spec NOVO]`
> *Ondas 60, 160… · 2 fases · vel 0,6*

**Mecânica única — Reflexão:** devolve **30% do dano não-crítico** recebido à torre. **Críticos passam inteiros e não refletem.**
- **Fase II (50%)**: cria **3 cópias espelhadas** (cada uma com 8% da vida do original) em posições simétricas. Cópias refletem **100%** do dano não-crítico. O original é o que **não pisca** — 1 frame a cada 0,5s revela quem é.
- Se você matar uma cópia com um crítico, ela **não** explode; com não-crítico, explode causando 10% da vida máx. da torre.

**Contra-jogo:** `critChance` ≥ 60% torna a luta trivial; abaixo de 25% ela é letal. É o boss que ensina "crítico não é opcional".

---

### 3.7 `colmeia` — **Colmeia Ancestral** `[EXISTE — spec NOVO]`
> *Ondas 70, 170… · 3 fases · vel 0,45*

**Mecânica única — Escudo Vivo:** escudo = **35% da vida máxima**. Se o Guardião não sofrer dano por **1,5s**, o escudo **regenera 6%/s**. Escudo intacto = imune ao corpo.
- **Fase I**: solta **1 `voador` a cada 3s**.
- **Fase II (66%)**: os `voador` viram **`enxame` em bando de 6**; regeneração do escudo sobe para 9%/s.
- **Fase III (30%)**: o escudo cai para 15% mas **regenera instantaneamente a cada 10s** se você não tiver causado ≥8% da vida dela nesse intervalo.

**Contra-jogo:** DPS **sustentado**, não picos. Cadência > dano por tiro. Melhor boss para builds de metralha.

---

### 3.8 `ceifador_almas` — **Ceifador de Almas** `[EXISTE — spec NOVO]`
> *Ondas 80, 180… · 3 fases · vel 0,8*

**Mecânica única — Dreno:** a cada 9s **teleporta para 40px da torre** (telegrafia: fumaça roxa 0,8s no destino) e **drena por 3s**: **5% da vida máx. da torre por segundo**, curando-se em **200% do drenado**.
- **Interrompível** por qualquer efeito de atordoamento/congelamento, ou por **acumular 12% da vida dele em dano durante o dreno**.
- **Fase II (60%)**: dreno a cada 7s, duração 4s.
- **Fase III (25%)**: dreno **contínuo** enquanto estiver a <120px; ele deixa de teleportar e simplesmente persegue.

**Contra-jogo:** Estase/Buraco Negro/Tempo; `roubodeVida` compensa o dreno; `espinhos` punem a aproximação.

---

### 3.9 `o_silencio` — **O Silêncio** `[EXISTE — spec NOVO]`
> *Ondas 90, 190… · 2 fases · vel 0,7*

**Mecânica única — Silêncio:** enquanto vivo, **todas as habilidades ativas ficam bloqueadas**. A barra fica cinza com um cadeado. Nenhuma exceção — nem relíquias que "resetam recarga".
- **Fase II (45%)**: além do silêncio, **desliga um upgrade elemental aleatório** (fogo/gelo/raio/veneno/vazio) a cada 15s, por 15s.
- Compensação: ele tem **−35% de vida** em relação aos chefes de nível equivalente e **×2,5 de ouro**.
- **Janela de ouro:** ao morrer, **todas as habilidades ficam sem recarga por 20s**.

**Contra-jogo:** build passiva. Este é o boss que valida investimento em estatísticas em vez de botões.

---

### 3.10 `devorador_mundos` — **Devorador de Mundos** `[EXISTE — spec NOVO]`
> *Ondas 100, 200… (quando não é super-chefe) · 4 fases · vel 0,5*

**Mecânica única — Engolir:** enquanto vivo, **todo ouro no chão migra para ele a 160px/s**. Cada moeda engolida o cura em **0,4% da vida máxima** e o deixa **+0,3% maior**.
- **Fase II (75%)**: **arrota** a cada 10s — devolve 30% do ouro engolido em uma explosão de moedas *que também causa 6% da vida máx. da torre*.
- **Fase III (50%)**: passa a engolir **inimigos aliados**, ganhando 2% de vida por inimigo.
- **Fase IV (20%)**: **regurgita tudo**: cria 12 `enxame` + devolve 60% do ouro engolido. Fica **vulnerável (−60% de armadura) por 8s**.

**Contra-jogo:** `coleta` (raio de coleta) e ímã. Ou: deixe-o engolir tudo e mate na fase IV para recuperar em dobro. Decisão real do jogador.

---

### 3.11 `aniquilador` — **O Aniquilador** (super-chefe) `[EXISTE — spec NOVO]`
> *Ondas 100, 300, 500… · 5 fases · vel 0,5 · vida ×3,5 de um chefe normal*

Cada fase **rouba a mecânica de um chefe anterior**, na ordem:

| Fase | Limiar | Mecânica herdada | Ajuste |
|---|---|---|---|
| I | 100–80% | Titã (invocação + onda de choque) | invoca 10 a cada 6s |
| II | 80–60% | Colmeia (escudo regenerativo) | escudo 25%, regen 8%/s |
| III | 60–40% | Espelhado (reflexão 30%) | + 2 cópias |
| IV | 40–20% | **Todas simultâneas** + Silêncio | habilidades bloqueadas; 4 fissuras fixas |
| V | 20–0% | Núcleo (pulso a cada 1s) | pulso 6% da vida máx.; ele não se move |

**Recompensa:** ×8 de ouro, **1 carta lendária garantida**, `fragmentos = 25 + onda/10`, e a conquista `s_aniquilado`.
**Contra-jogo:** guarde **todas** as habilidades para a fase IV, que é onde elas não existem — ou seja, guarde-as para o *fim* da fase III e queime tudo antes do limiar de 40%.

---

### 3.12 `trono_vazio` — **Trono Vazio** (super-chefe) `[EXISTE — spec NOVO]`
> *Ondas 200, 400, 600… · 5 fases · vel 0,42 · vida ×4,2*

**Mecânica única — Ele não anda até a torre. Ele deleta a arena.**
- A cada 20s, **um "setor" da arena (60°) é apagado** — vira `pagina_branca`. Dentro do setor apagado: a torre **não atira** (projéteis somem) e inimigos ficam **imunes**.
- Setores apagados **acumulam**: fase I=1 setor, II=2, III=3, IV=4, V=5 (300° apagados; sobram 60° de tiro).
- Para restaurar um setor: **matar 25 inimigos dentro dele** (contador flutuante no setor).
- **Fase V**: o Trono se senta no centro exato e a torre precisa girar para o único setor vivo. Habilidades **funcionam normalmente** aqui (contraste proposital com o Aniquilador).

**Recompensa:** ×12 de ouro, 1 carta **mítica** com 8% de chance / lendária garantida, `nucleos +1`.

---

## 4. CODEX / BESTIÁRIO — `data/codex.json` `[NOVO — arquivo inteiro]`

### 4.1 Sistema

```
codex: {
  bestiario:  [ { id, ref:"inimigo:<id>", tiers:[{abates, texto, bonus?}] } ],
  chefes:     [ { id, ref:"chefe:<id>", tiers:[{abates, texto, bonus?}] } ],
  eras:       [ { id, ref:"era:<id>", texto } ],
  mecanicas:  [ { id, nome, texto } ],
  cadernos:   [ { id, nome, onda, texto } ]     // fragmentos de lore, drop 1,5%/onda
}
```

**Regra de desbloqueio (bestiário):** `Tier I = 10 abates`, `Tier II = 100`, `Tier III = 1000`.
**Bônus do Tier III (universal):** `+8% de dano contra este tipo de inimigo` (`stat: danoTipo`, `chave: <id>` ⚑ NOVO STAT `danoTipo` — mapa `id→mult`).
**Bônus do Tier III de chefes:** `+5% de dano contra chefes` cada (acumulável, 12 chefes = +60%).
**Completude:** 100% do bestiário → conquista `x_bestiario` + `multiplicador ×1,4`.

### 4.2 Textos do Bestiário (Tier I / II / III)

| Inimigo | Tier I (10) | Tier II (100) | Tier III (1000) |
|---|---|---|---|
| **Grunhido** | "Anda. Chega. Morre. Repete no dia seguinte com outro corpo." | "Autópsia: não há órgãos, só cavidades cheias de poeira que se organiza sozinha." | "Descobrimos por que eles vêm em fila: cada um segue o cheiro do que morreu antes. Você construiu a fila." |
| **Corredor** | "Largou a armadura em algum lugar e nunca voltou pra buscar." | "Os ossos das pernas estão trincados. Ele corre com dor. Corre mesmo assim." | "Não corre pra você. Corre *de* algo que vem depois. Nunca vimos o que é." |
| **Enxame** | "Individualmente irrelevante. Some seiscentos e chame de problema." | "Compartilham um único impulso. Se você matar o do meio, os outros hesitam por 0,2s." | "Não são seiscentos indivíduos. São um indivíduo com seiscentos corpos, e ele já te viu." |
| **Bruto** | "Carne fundida a placas de escória. Sem pressa." | "As placas foram parafusadas *por dentro*. Alguém fez isso com ele. Ou ele fez consigo." | "Encontramos uma marca de fábrica sob a placa esquerda. Data de fabricação: depois de hoje." |
| **Voador** | "As asas não deveriam sustentar aquele peso. Sustentam." | "Ele não voa: cai muito devagar, na direção certa, para sempre." | "As asas são feitas de antenas da Catedral. Ele está transmitindo enquanto voa." |
| **Blindado** | "O escudo à frente é honesto. As costas, nem tanto." | "O escudo regenera se você parar. Ele conta os segundos junto com você." | "O escudo é a face de outro inimigo, achatada. Ainda pisca." |
| **Saltador** | "Pula alto o suficiente para passar por cima do seu bom senso." | "No ápice do salto, fica 0,4s parado no ar. Aprenda a contar até 0,4." | "Salta para evitar o chão. O chão, aqui, também é do Enxame." |
| **Divisor** | "Um vira dois. Dois viram quatro. A aritmética é hostil." | "Cada metade tem metade da memória. A quarta geração já esqueceu por que veio." | "Divisão perfeita, sem perda de massa. Isso viola algo. Ninguém sabe o quê." |
| **Espectro** | "Atravessa a matéria. Não atravessa a vontade de te alcançar." | "Está sempre 3cm fora de fase. Projéteis rápidos alcançam a fase certa." | "É um inimigo que morreu numa onda que você ainda não jogou." |
| **Curandeiro** | "Prioridade máxima. Sempre. Sem exceções." | "Cura por transfusão: tira a própria massa e dá aos outros. Encolhe visivelmente." | "Não cura por bondade. Cura porque um corpo que morre cedo demais não gera dados." |
| **Atirador** | "Para, mira, cospe. A pausa é a sua janela." | "A mira é boa. Se ele errasse, o Enxame o descartaria." | "Ele mira na torre. Nunca no operador. Alguém deu essa ordem." |
| **Bomba Viva** | "Anda com pressa e boa vontade. Ambas explosivas." | "O material interno é estável até ouvir um som de metal. Sua torre faz esse som." | "Ele sabe. Anda mesmo assim. Isso é a coisa mais próxima de coragem que catalogamos." |
| **Teleportador** | "Estava ali. Agora está aqui. Não pergunte pelo caminho." | "Salta 180px por vez, sempre para uma posição que ele já ocupou em outra onda." | "Não teleporta: retrocede até uma onda em que já estava mais perto." |
| **Sanguessuga** | "Não quer te matar. Quer te manter vivo e útil." | "Cada gole vira 3 gramas de massa. Um dia isso vira um Colosso." | "É assim que o Enxame fabrica Colossos. Você é a matéria-prima." |
| **Refletor** | "Devolve o que recebe. Críticos, ele não entende." | "A superfície é vidro da Estepe Vitrificada. Ele é feito do seu campo de batalha." | "O reflexo mostra a torre em ruínas. Sempre mostrou. Não é previsão, é lembrança." |
| **Colosso** | "Oito vezes mais tudo. Metade da pressa." | "Feito de 400 corpos comprimidos. Alguns ainda se mexem sob a pele." | "Reconhecemos três rostos. Um deles operou esta torre antes de você." |
| **Parasita** | "Infecta o vizinho e usa o vizinho como escudo." | "A infecção é hereditária: o infectado infecta ao morrer." | "O Parasita não é o inimigo. É o método. O Enxame inteiro já foi parasitado uma vez." |
| **Casulo** | "Lento, gordo e cheio de promessas ruins." | "Dentro há um inimigo de 40 ondas à frente, ainda mole." | "Se você deixar 60 casulos passarem, o Enxame pula uma era inteira. Nunca deixe." |
| **Sombra** | "Você só o vê quando ele decide." | "Invisível fora do alcance da torre. Ou seja: sempre visível quando importa." | "Não é invisível. É *não-desenhado*. Existe uma diferença e ela é aterrorizante." |
| **Devorador** | "Come ouro. Engorda. É literal." | "Cada moeda vira 0,4% de vida. Sua ganância é o orçamento dele." | "Ele come ouro porque o ouro é feito de inimigos mortos. É canibalismo com etapa extra." |
| **Aberração** | "Muda de forma quando você entende a forma anterior." | "Já catalogamos 14 morfologias. Nenhuma se repetiu na mesma onda." | "É uma tentativa do Enxame de desenhar você de memória. Está melhorando." |
| **Ceifeiro** | "Persegue. Não desiste. Executa feridos." | "Ignora inimigos aliados feridos. Só executa o que é seu." | "Carrega a mesma marca de fábrica do Bruto. E a mesma data: depois de hoje." |
| **Mímico** `[NOVO]` | "Uma moeda que morde. Você vai coletar. Todo mundo coleta." | "Imita o brilho com precisão de 0,3%. A diferença é que ele não gira." | "Ele aprendeu a forma da moeda observando você coletar. Aprende observando. Anote isso." |
| **Escavador** `[NOVO]` | "Some no chão e reaparece mais perto. Injusto e eficaz." | "Escava túneis que permanecem. A arena está cada vez mais oca." | "Os túneis formam um desenho. De cima, é o mesmo símbolo gravado na base da sua torre." |
| **Porta-Estandarte** `[NOVO]` | "Não luta. Faz os outros lutarem melhor. Mate primeiro." | "O estandarte é um pedaço de tecido com o número da sua onda atual bordado." | "Cada estandarte tem um número diferente. São contagens. Estão contando você." |
| **Carapaça Voltaica** `[NOVO]` | "Come raio no café da manhã. Congele-a." | "A carapaça é uma bobina viva. Ela se recarrega nos seus próprios tiros." | "Foi construída para caçar orbes. Só existe porque você comprou orbes. Ele adapta." |
| **Costureiro** `[NOVO]` | "Costura três inimigos numa só barra de vida. Corte a agulha." | "O fio é feito de tendão. O nó é um nó de marinheiro humano." | "Ele costura porque o Enxame está se remendando. Está perdendo. Você fez isso." |
| **Ampulheta Viva** `[NOVO]` | "Perto dela, sua torre fica lenta e você fica ansioso." | "Não tem boca, olhos, nem intenção. Só um campo. É um eletrodoméstico hostil." | "O campo não desacelera a torre. Acelera o resto do mundo. Você é que está parado." |
| **Semente do Vazio** `[NOVO]` | "Morre e puxa todo mundo para o mesmo lugar. Obrigado." | "O poço tem 3s de duração e 18% de chance de explodir. Aposte." | "Ela quer morrer perto dos aliados. É sabotagem interna. Alguém, lá dentro, está do seu lado." |
| **Arauto Menor** `[NOVO]` | "Abre buracos onde a realidade fica fina. Não pise." | "As fissuras dele são 8% do tamanho das do Arauto do Vazio. É um estudante." | "Está praticando. Em algum lugar existe um professor. Ele chega na onda 40." |

### 4.3 Codex dos Chefes (texto único por chefe, desbloqueia no 1º abate)

- **Titã de Ferro:** "A primeira coisa que o Enxame construiu quando aprendeu a odiar. Não é a mais forte. É a mais sincera."
- **Rainha do Enxame:** "Ela não comanda a ninhada. A ninhada é o corpo dela, e ela é a parte que ficou grande demais para caber."
- **Núcleo Instável:** "Foi um reator. Depois foi uma bomba. Agora é uma criatura que se lembra de ter sido as duas coisas e não sabe qual delas devia ser."
- **Arauto do Vazio:** "Ele não abre buracos na realidade. Ele aponta para onde os buracos já estavam e a realidade fica constrangida."
- **Serpente Ciclônica:** "Oito segmentos, oito mortes, uma cabeça que assiste. Quando você corta o último anel, ela agradece. Nós ouvimos."
- **Guardião Espelhado:** "Devolve tudo que recebe, menos o que você faz com precisão. É uma lição de moral com formato de boss."
- **Colmeia Ancestral:** "É mais velha que a Rainha. É mais velha que a torre. Ela viu a primeira parede de tijolos e achou graça."
- **Ceifador de Almas:** "Teleporta para cima da torre e bebe. Não é fome. É auditoria: ele está medindo quanto você ainda tem."
- **O Silêncio:** "Enquanto ele existe, suas habilidades não. Não é bloqueio: é esquecimento. Você lembra dos botões quando ele morre."
- **Devorador de Mundos:** "Cada moeda que ele engole vira vida. Ele começou engolindo o troco. Agora engole eras."
- **O Aniquilador:** "Tudo que o Enxame aprendeu, num só corpo — inclusive o que aprendeu com você. Metade das mecânicas dele são suas."
- **Trono Vazio:** "Não ataca a torre. Ataca a ideia de que ela deveria existir. Apagou o cenário. Você continua atirando no branco."

### 4.4 Codex de Mecânicas (tutorial diegético)

| id | Nome | Texto |
|---|---|---|
| `m_combo` | **Cadeia** | "Cada abate em menos de 3s do anterior soma +1. A cada 25 de cadeia, +5% de ouro (teto +200%). A torre não comemora — ela só fica mais eficiente quando não tem tempo de pensar." |
| `m_dourado` | **Dourados** | "1,2% dos inimigos nascem dourados. Valem 25× e fogem da tela em 8s. Correr atrás é instinto. Instinto rende." |
| `m_juros` | **Juros** | "Ouro parado rende 0,12%/s por nível de Juros. Ouro gasto rende 0%. O jogo inteiro é essa tensão." |
| `m_offline` | **Turno Noturno** | "Você não está lá. A torre está. Rende 45% do DPS ativo, teto de 8h (expansível a 26h). Ela não reclama." |
| `m_prestigio` | **Ascensão** | "Você troca tudo por poeira, e a poeira lembra. Fragmentos = `floor(3 × (ondaMax/25)^1,45)`." |
| `m_cartas` | **Cartas** | "Peças que sobraram de torres que não sobraram. 8 equipadas no máximo. Duplicatas viram pó de recarga." |
| `m_reliquia` | **Relíquias** | "Compradas com fragmentos, núcleos, éter ou gemas. Nunca se perdem. São a única memória entre encarnações." |
| `m_elementos` | **Elementos** | "Fogo queima (DoT 8%/s por 4s), Gelo lentifica (−35% por 2s), Raio salta (+2 alvos), Veneno acumula (5 cargas ×3%), Vazio ignora armadura." |
| `m_execucao` | **Execução** | "Abaixo do limiar, o inimigo morre. Não é dano: é uma decisão administrativa." |
| `m_desafio` | **Provações** | "Você pede para o jogo ser pior. O jogo concorda e depois te paga por isso." |

### 4.5 Cadernos do Operador — 25 fragmentos de lore `[NOVO]`
> Drop: 1,5% por onda concluída, sem repetição, ordem fixa. Cada um dá **+1 gema** e **+0,5% de multiplicador global** (25 total = +12,5%).

| # | id | Onda mín. | Texto |
|---|---|---|---|
| 1 | `cad_01` | 1 | "Dia 1. Recebi uma torre, um manual de quatro páginas e nenhuma explicação. Três das páginas são sobre o café." |
| 2 | `cad_02` | 5 | "Dia 3. Descobri que a torre atira sozinha. Passei o dia inteiro descobrindo que eu não preciso estar aqui. Fiquei mesmo assim." |
| 3 | `cad_03` | 10 | "Dia 8. Contei 1.400 corpos. O contador da torre diz 1.398. Vou confiar nela." |
| 4 | `cad_04` | 18 | "Dia 15. Chegou uma caravana. Vendi sucata, comprei uma mola. A mola fez a torre atirar 6% mais rápido. Chorei um pouco." |
| 5 | `cad_05` | 25 | "Dia 22. Ela morreu. Eu também, tecnicamente. Acordei na onda 1 com poeira brilhante nos bolsos e a lembrança inteira." |
| 6 | `cad_06` | 30 | "Dia 24. Segunda vez é mais rápido. Terceira será mais rápida ainda. Isso deveria me assustar." |
| 7 | `cad_07` | 40 | "Dia 31. O Enxame começou a mandar coisas que eu nunca vi. Ele está *respondendo*." |
| 8 | `cad_08` | 48 | "Dia 40. O inverno chegou por encomenda. Alguém encomendou. Não fui eu." |
| 9 | `cad_09` | 60 | "Dia 52. Encontrei uma placa da primeira torre. Número de série 0001. A minha é 4.117." |
| 10 | `cad_10` | 75 | "Dia 66. A Fundição não para. Perguntei a um Bruto o que ela fabrica. Ele não respondeu, mas hesitou. Brutos não hesitam." |
| 11 | `cad_11` | 90 | "Dia 80. As Aberrações estão me desenhando. Vi uma com dois braços e um capacete. Não gostei do capacete." |
| 12 | `cad_12` | 110 | "Dia 95. Necrópole Orbital. Os mortos aqui estão em órbita. Sobem. Não sei para onde." |
| 13 | `cad_13` | 125 | "Dia 104. Descobri que posso pedir para o jogo ser pior. Pedi. Ganhei uma medalha por isso." |
| 14 | `cad_14` | 150 | "Dia 120. Colapsei a torre num ponto. O ponto piscou. Eu pisquei de volta. Achei que era educado." |
| 15 | `cad_15` | 155 | "Dia 126. A Camada de Depuração é onde o mundo guarda os erros. Encontrei três versões minhas. Duas estavam corrompidas." |
| 16 | `cad_16` | 175 | "Dia 140. A terceira versão minha estava bem. Ela me deu um conselho e sumiu. O conselho era: 'não compre juros antes da onda 40'." |
| 17 | `cad_17` | 210 | "Dia 160. Aurora Terminal. É bonito. É a primeira coisa bonita em 160 dias. Perdi uma onda inteira olhando." |
| 18 | `cad_18` | 250 | "Dia 180. O Silêncio veio. Por noventa segundos eu não tinha botões. Percebi que eu nunca precisei deles. Foi humilhante." |
| 19 | `cad_19` | 320 | "Dia 210. Jardim de Singularidades. Cada flor é um colapso. Colhi uma. Não recomendo." |
| 20 | `cad_20` | 400 | "Dia 240. Contei minhas ascensões: 312. Contei minhas mortes: 312. Empate técnico." |
| 21 | `cad_21` | 500 | "Dia 280. Nada, Bem Cuidado. Não há cenário. Só a torre. E ela está limpa — alguém limpa isso." |
| 22 | `cad_22` | 750 | "Dia 330. Catedral de Antenas. Todas apontam pra cima. Nenhuma resposta em 400 anos. Elas continuam. Eu também." |
| 23 | `cad_23` | 1100 | "Dia 400. Maré de Cálcio. Andei sobre 11 milhões de mortos e achei ouro. Isso me define." |
| 24 | `cad_24` | 1600 | "Dia 480. Anel de Paradoxo. Escrevi esta página três vezes. Só uma delas conta. Provavelmente esta." |
| 25 | `cad_25` | 2400 | "Dia ???. Página em Branco. Finalmente entendi: a torre não me defende. Eu é que sou a última coisa que ela ainda protege. O Enxame nunca quis passar por ela. Queria chegar a mim. E eu estou aqui há muito tempo." |

---

## 5. ÁRVORE DE TALENTOS — 54 nós

### 5.1 Ramos existentes `[EXISTE]` — 36 nós

`furia` ⚔️ (12 nós) · `bastiao` 🛡️ (12) · `fortuna` 🪙 (12). Estrutura: tier 0–6, `pos [coluna, tier]`, chave em tier 5, maestria em tier 6 (`max 20`, `multiplicador ×1,25`/nv).

### 5.2 Ramo novo: **ENGENHO** `[NOVO]` — `id: engenho`, cor `#22d3ee`, ícone ⚙️
> *"A torre pensa. Você só assina embaixo."* — desbloqueia na **onda 15** (junto com orbes).

| id | Nome | tier | pos | max | custo | requer | Efeito numérico |
|---|---|---|---|---|---|---|---|
| `g_rolamento` | **Rolamento Fino** | 0 | [0,0] | 10 | 1 | — | `velOrbe pct +0,08`/nv |
| `g_ignicao` | **Ignição Auxiliar** | 0 | [1,0] | 10 | 1 | — | `danoFogo flat +0,02` e `danoRaio flat +0,02`/nv |
| `g_orbe` | **Satélite Adicional** | 1 | [0,1] | 4 | 3 | `g_rolamento` | `orbes flat +1`/nv |
| `g_condutor` | **Condutor Frio** | 1 | [1,1] | 10 | 1 | `g_ignicao` | `danoGelo flat +0,02` e `danoVeneno flat +0,02`/nv |
| `g_giroscopio` | **Giroscópio Calibrado** | 2 | [0,2] | 12 | 2 | `g_orbe` | `danoOrbe pct +0,12`/nv |
| `g_supressor` | **Supressor de Placa** | 2 | [1,2] | 10 | 2 | `g_condutor` | `penetracao flat +0,02`/nv |
| `g_autoloader` | **Alimentador Automático** | 3 | [0,3] | 1 | 5 | `g_giroscopio` | `passiva: auto_compra_barato` — compra sozinho o upgrade mais barato a cada 3s se houver ouro sobrando (>120% do custo) |
| `g_prisma` | **Prisma de Bancada** | 3 | [1,3] | 6 | 3 | `g_supressor` | `danoFogo/Gelo/Raio/Veneno/Vazio flat +0,03` cada/nv |
| `g_enxame_orbital` | **Enxame Orbital** | 4 | [0,4] | 5 | 3 | `g_autoloader` | Orbes ganham `ricochete flat +1`/nv e `area flat +6`/nv |
| `g_telemetria` | **Telemetria** | 4 | [1,4] | 10 | 2 | `g_prisma` | `alcance pct +0,03` e `velProjetil pct +0,06`/nv |
| `g_singularidade_local` | **Singularidade Local** ★ | 5 | [0.5,5] | 1 | 5 | `g_enxame_orbital`, `g_telemetria` | `passiva: orbes_gravitacionais` — cada orbe puxa inimigos a **120px/s** dentro de 100px |
| `g_maestria` | **Maestria do Engenho** | 6 | [0.5,6] | 20 | 3 | `g_singularidade_local` | `multiplicador mult ×1,25`/nv |

### 5.3 Nós de **Raiz** (convergência entre ramos) `[NOVO]` — 6 nós
> Painel central, requerem nós-chave de **dois ramos diferentes**. `max 1`, `custo 8`, cada um é uma reviravolta de build.

| id | Nome | Requer | Efeito numérico |
|---|---|---|---|
| `r_forja_viva` | **Forja Viva** | `f_ultima` + `b_imortal` | Enquanto abaixo de 30% de vida, você **não morre por 6s** e ganha `+150% de dano`. Recarrega a cada onda. |
| `r_avareza_armada` | **Avareza Armada** | `o_avareza` + `f_ultima` | `dano mult ×(1 + log10(ouroAtual)/22)` — a build "dinheiro é dano". Teto ×4. |
| `r_bastiao_dourado` | **Bastião Dourado** | `b_imortal` + `o_avareza` | Converte **12% do ouro ganho em escudo** (teto: 300% da vida máx.). Escudo não decai. |
| `r_orquestra` | **Orquestra** | `g_singularidade_local` + `f_ultima` | Cada orbe dispara junto com a torre: `+1 projétil por orbe`, com `35%` do dano base. |
| `r_relojoaria` | **Relojoaria** | `g_singularidade_local` + `o_avareza` | Habilidades recarregam **1s por 8 abates**. `cdr flat +0,15`. |
| `r_casulo_ferro` | **Casulo de Ferro** | `g_singularidade_local` + `b_imortal` | `armadura mult ×2`, `regen mult ×3`, `cadencia mult ×0,7`. A build tanque real. |

**Economia de pontos:** 1 ponto/nível de torre + conquistas + missões. Custo total dos 54 nós ≈ **412 pontos**; jogador médio tem ~150 em uma corrida madura → **especialização forçada**. `an_talento` e `af_talento` (prestígio) devolvem pontos ao resetar.

---

## 6. CONQUISTAS — 119 total (85 existentes + 34 novas)

### 6.1 Categorias
`[EXISTE]`: `progresso` 🚩 · `combate` ⚔️ · `economia` 🪙 · `colecao` 🃏 · `prestigio` 💠 · `segredos` 🕳️
`[NOVO]`: **`codex` 📖** (Codex — "Ler é uma forma de matar") · **`provacao` 🩸** (Provação — desafios, eventos, climas)

### 6.2 Novos contadores necessários `⚑`
`elitesMortos`, `eventosResolvidos`, `codexTierIII`, `chefeTipo` (mapa id→abates), `ondasSemDano`, `desafioTipo`, `relicaNivel`, `climasVistos`, `conjuntoAtivo`, `cadernosLidos`, `mimicosRevelados`, `carrasSemMorrer`, `ouroOffline`, `tempoSemComprar`

### 6.3 As 34 conquistas novas `[NOVO]`

| id | Cat | Pts | Nome | Condição | Recompensa |
|---|---|---|---|---|---|
| `c_elites100` | combate | 10 | **Currículo de Elite** | `elitesMortos ≥ 100` | `gemas 30` |
| `c_elites2500` | combate | 25 | **Departamento de Recursos Humanos** | `elitesMortos ≥ 2500` | `stat danoTipo:elite mult 1,25` |
| `c_ancestral` | combate | 25 | **Respeito aos Mais Velhos** | `elitesMortos(ancestral) ≥ 50` | `stat chanceDrop mult 1,2` |
| `c_mimico` | segredos | 10 | **Não Era Uma Moeda** | `mimicosRevelados ≥ 25` (mortos antes de morder) | `stat coleta pct 0,25` |
| `c_ampulheta` | combate | 10 | **Contra o Relógio** | `inimigoTipo:ampulheta_viva ≥ 150` | `stat cdr flat 0,04` |
| `c_costureiro` | combate | 10 | **Corte Limpo** | `inimigoTipo:costureiro ≥ 200` | `stat perfuracao flat 1` |
| `c_semente` | combate | 5 | **Jardinagem Tática** | `inimigoTipo:semente_vazio ≥ 100` | `gemas 20` |
| `c_escavador` | combate | 10 | **Superfície Segura** | `inimigoTipo:escavador ≥ 300` | `stat velProjetil pct 0,12` |
| `c_intacto10` | combate | 10 | **Sem Um Arranhão** | `ondasSemDano ≥ 10` (consecutivas) | `stat vidaMax pct 0,2` |
| `c_intacto60` | combate | 50 | **Turno Impecável** | `ondasSemDano ≥ 60` (consecutivas) | `stat multiplicador mult 1,3` |
| `c_titã` | combate | 25 | **Ferro-Velho Autorizado** | `chefeTipo:tita_ferro ≥ 50` | `stat penetracao flat 0,08` |
| `c_silencio_passivo` | combate | 50 | **Ganhei Sem Botões** | Matar `o_silencio` sem usar nenhuma habilidade na onda | `stat multiplicador mult 1,2` |
| `c_espelho_crit` | combate | 25 | **Só Com Precisão** | Matar `guardiao_espelho` sem causar 1 único dano não-crítico | `stat critDano flat 0,8` |
| `c_serpente_1tiro` | segredos | 50 | **Corte Transversal** | Matar ≥5 segmentos da Serpente com **um único projétil** | `stat perfuracao flat 3` |
| `c_devorador_faminto` | combate | 25 | **Dieta Forçada** | Matar `devorador_mundos` com ele tendo engolido **0 moedas** | `stat coleta mult 1,5` |
| `c_aniquilador` | prestigio | 50 | **Aniquilei o Aniquilador** | `chefeTipo:aniquilador ≥ 1` | `nucleos 2` |
| `c_trono` | prestigio | 50 | **Cadeira Vaga** | `chefeTipo:trono_vazio ≥ 1` | `eter 1` |
| `x_codex25` | codex | 5 | **Leitor Casual** | `codexTierIII ≥ 5` | `gemas 20` |
| `x_codex50` | codex | 25 | **Naturalista de Campo** | `codexTierIII ≥ 15` | `stat multiplicador mult 1,1` |
| `x_bestiario` | codex | 50 | **Bestiário Completo** | `codexTierIII ≥ 30` (todos) | `stat multiplicador mult 1,4` |
| `x_cadernos` | codex | 25 | **A História Toda** | `cadernosLidos ≥ 25` | `stat ganhoXP mult 1,5` |
| `x_chefes_codex` | codex | 25 | **Dossiê de Coroas** | Codex de **todos os 12 chefes** desbloqueado | `stat danoChefe mult 1,4` |
| `x_eras` | codex | 10 | **Turismo Apocalíptico** | Visitar as **14 eras** | `gemas 120` |
| `x_climas` | codex | 10 | **Meteorologista Amador** | `climasVistos ≥ 8` (todos) | `stat sorte pct 0,12` |
| `v_evento10` | provacao | 5 | **Diplomata Relutante** | `eventosResolvidos ≥ 10` | `gemas 15` |
| `v_evento200` | provacao | 25 | **Todo Mundo Quer Algo** | `eventosResolvidos ≥ 200` | `stat sorte mult 1,25` |
| `v_desafio_dif5` | provacao | 50 | **Purgatório Concluído** | `desafioTipo:purgatorio` completo | `stat multiplicador mult 1,5` |
| `v_desafios_todos` | provacao | 50 | **Provação Integral** | Completar os **22 desafios** | `nucleos 5` + `stat multiplicador mult 1,6` |
| `v_semcomprar` | provacao | 25 | **Voto de Imobilidade** | Chegar à onda 60 sem comprar nenhum upgrade na corrida | `pontosTalento 5` |
| `v_conjunto3` | colecao | 25 | **Sinergia Confirmada** | Ter **3 conjuntos de cartas ativos** ao mesmo tempo | `stat multiplicador mult 1,18` |
| `v_reliquia_max` | colecao | 25 | **Estante Cheia** | `relicaNivel(qualquer) = max` em 5 relíquias com teto | `fragmentos 3000` |
| `e_offline1e9` | economia | 25 | **Trabalhou Enquanto Eu Dormia** | `ouroOffline ≥ 1e9` | `stat multiplicador mult 1,15` (aplicado só ao offline) |
| `s_pagina` | segredos | 50 | **Fim da Página** | Alcançar a onda **2400** | `eter 3` |
| `s_2222` | segredos | 25 | **Simetria Suspeita** | Alcançar exatamente a onda **2222** e Ascender nela | `gemas 2222` |

**Sistema de pontos:** total ≈ **2.480 pts**. Marcos de pontuação → `stat multiplicador`:
`250 pts → ×1,1` · `600 → ×1,2` · `1.000 → ×1,3` · `1.500 → ×1,5` · `2.000 → ×1,8` · `2.400 → ×2,2`

---

## 7. RELÍQUIAS — 34, com raridade e efeito

### 7.1 Raridade atribuída às 26 existentes `[PATCH — adicionar campo `raridade`]`

| id | Raridade | Moeda | base / cresc / max | Efeito por nível |
|---|---|---|---|---|
| `manual_recruta` | comum | fragmentos | 30 / 1,40 / 30 | +2 pontos de talento iniciais |
| `caderno_ultimo_engenheiro` | comum | fragmentos | 28 / 1,42 / 40 | ×1,3 XP |
| `dizimo_coveiro` | incomum | fragmentos | 25 / 1,55 / ∞ | ×1,45 ouro |
| `coracao_primeira_torre` | raro | fragmentos | 30 / 1,60 / ∞ | ×1,5 multiplicador |
| `lente_vigia_cego` | incomum | fragmentos | 40 / 1,40 / 40 | +1,5% crit, +25% dano crít. |
| `costela_aco_morto` | incomum | fragmentos | 35 / 1,45 / 30 | ×1,35 vida, +20 armadura |
| `gatilho_homem_morto` | incomum | fragmentos | 45 / 1,50 / 30 | +6% cadência |
| `cripta_estase` | raro | fragmentos | 50 / 1,50 / 20 | +3h offline, +4% eficiência |
| `testamento_dourado` | raro | fragmentos | 90 / 1,70 / 10 | herda 8% do ouro ao Ascender |
| `bocarra_recicladora` | raro | fragmentos | 120 / — / 1 | reciclagem automática |
| `sino_recomeco` | épico | fragmentos | 300 / — / 1 | habilidades sem recarga a cada onda |
| `prisma_faminto` | raro | gemas | 60 / 1,50 / 25 | +2% de cada elemento |
| `relogio_turno_noite` | incomum | gemas | 40 / 1,60 / 10 | +6% eficiência offline |
| `dado_viciado` | incomum | gemas | 35 / 1,75 / 8 | +1 rerroll diário |
| `coroa_rei_fundido` | raro | gemas | 90 / 1,55 / 25 | ×1,25 dano em chefe, +1% execução |
| `ovo_sentinela` | raro | gemas | 120 / 2,10 / 8 | +1 orbe, ×1,35 dano de orbe |
| `coleira_dourada` | épico | gemas | 80 / 2,40 / 3 | dourados 2× e soltam gema |
| `vela_segundo_folego` | épico | gemas | 150 / 3,00 / 4 | +1 renascimento por onda |
| `mao_extra` | épico | gemas | 200 / 3,50 / 3 | +1 slot de carta |
| `contrato_recompra` | lendário | gemas | 220 / 3,20 / 3 | mantém ouro e onda ao cair |
| `cinto_operador` | épico | núcleos | 8 / 4,00 / 3 | +1 slot de habilidade |
| `coro_estilhacos` | épico | núcleos | 6 / 3,00 / 3 | salva circular de 12 a cada 5º tiro |
| `regra_riscada` | lendário | núcleos | 4 / 2,20 / 12 | −4% vida inimiga (mult.) |
| `ampulheta_rachada` | lendário | núcleos | 5 / — / 1 | combo nunca expira por tempo |
| `estilhaco_primeiro_colapso` | lendário | núcleos | 3 / 1,90 / ∞ | ×2 dano, ×1,6 fragmentos |
| `espelho_operador` | mítico | núcleos | 25 / — / 1 | duplica a relíquia mais cara |

### 7.2 Relíquias novas `[NOVO]` — 8

| id | Nome PT-BR | Raridade | Moeda | base/cresc/max | Efeito por nível | Lore |
|---|---|---|---|---|---|---|
| `agulha_norte_falso` | **Agulha do Norte Falso** | incomum | fragmentos | 55 / 1,48 / 25 | `velProjetil pct +0,08` e `ricochete flat +0,2` (trunca) | "Aponta sempre para o lado errado. Depois de mil ondas, o lado errado virou o certo." |
| `tambor_de_guerra` | **Tambor de Guerra** | raro | fragmentos | 65 / 1,50 / 20 | `cadencia pct +0,05`; a cada **20 abates**, 1 disparo instantâneo extra | "O couro é de algo grande. O ritmo é de algo maior. A torre bate junto sem perceber." |
| `veia_de_ouro` | **Veia de Ouro** | raro | fragmentos | 80 / 1,62 / 25 | `ganhoOuro pct +0,06` e `+2%` de chance de dourado | "Uma faixa de metal que atravessa a rocha e não termina. Cortamos até onde deu. Continua." |
| `lente_dos_dez_mil` | **Lente dos Dez Mil** | épico | gemas | 100 / 1,60 / 20 | `critChance flat +0,004`, `critDano flat +0,12`; **5% de supercrítico** (crítico do crítico, ×2) | "Polida por dez mil mãos ao longo de dez mil dias. Cada mão levou um pouco da própria vista embora." |
| `chave_do_turno` | **Chave do Turno** | épico | gemas | 130 / 1,90 / 6 | `+1` missão diária ativa; `+10%` de XP de temporada | "Abre o armário do turno anterior. Dentro há um café frio e um bilhete que diz 'não confie no relógio'." |
| `selo_do_arauto` | **Selo do Arauto** | lendário | núcleos | 4 / 2,40 / 10 | Chefes nascem com `−6% de vida` e soltam `+25% de ouro` | "Um selo diplomático do Vazio. O Enxame respeita papelada. Ninguém sabe por quê." |
| `caixa_preta` | **Caixa-Preta do Operador** | lendário | núcleos | 10 / 2,80 / 5 | Ao Ascender, mantém `10%` dos níveis de upgrade comprados | "Sobreviveu a 4.116 quedas de torre. Grava tudo. Nunca ninguém teve estômago de ouvir." |
| `coracao_do_enxame` | **Coração do Enxame** | mítico | éter | 2 / 2,00 / ∞ | `multiplicador mult ×3`; `ganhoEter mult ×1,5` ⚑ | "Você o arrancou. Ele continua batendo, e agora bate no mesmo ritmo que a sua torre. Sempre bateu." |

---

## 8. CARTAS / MÓDULOS DA TORRE — 41 cartas, 7 conjuntos

### 8.1 As 30 existentes `[EXISTE]`
Listadas em `data/cards.json` com `raridadeMin` e `efeito` — todas válidas. Curva de raridade: 8 comuns, 7 incomuns, 6 raras, 5 épicas, 3 lendárias, 1 mítica.

### 8.2 11 cartas novas `[NOVO]`

| id | Nome PT-BR | Raridade | Efeito | Sabor |
|---|---|---|---|---|
| `bico_estreito` | **Bico Estreito** | comum | `perfuracao flat +1`, `dano pct −0,04` | "Fura mais. Machuca menos. Alguém achou que valia a pena." |
| `capacitor_umido` | **Capacitor Úmido** | comum | `danoRaio flat +0,05` | "Não devia funcionar molhado. Funciona melhor molhado. Não mexa." |
| `saco_de_lastro` | **Saco de Lastro** | incomum | `area flat +10`, `dano pct +0,12`, `velProjetil pct −0,08` | "Peso extra no cano. O projétil sai com raiva e sem pressa." |
| `agulheiro` | **Agulheiro** | incomum | `critChance flat +0,03`, `perfuracao flat +1` | "Um estojo de agulhas cirúrgicas usado como munição. O cirurgião não reclamou." |
| `chip_de_mira` | **Chip de Mira** | incomum | `alcance pct +0,12`, `velProjetil pct +0,15` | "Recuperado de um drone civil. Ele mirava em rostos. Agora mira em coisas sem rosto. É um upgrade moral." |
| `retentor_termico` | **Retentor Térmico** | raro | `danoFogo flat +0,08`, `danoGelo flat +0,08`, `cadencia pct −0,05` | "Segura o calor e o frio no mesmo cano. O cano tem opinião sobre isso." |
| `contador_geiger` | **Contador Geiger** | raro | `danoVeneno flat +0,09`, `execucao flat +0,03` | "Estala quando um inimigo está prestes a morrer. Você aprende a gostar do som." |
| `bobina_de_recuo` | **Bobina de Recuo** | épico | `cadencia pct +0,45`, `alcance pct −0,2`, `dano pct −0,1` | "Dispara tão rápido que o alcance não acompanha. Deixe-os chegar perto. Eles vão gostar menos." |
| `arquivo_do_censo` | **Arquivo do Censo** | épico | `ganhoXP mult ×1,5`, `ganhoFrag pct +0,2`, `ganhoOuro pct −0,15` | "Cada morte vira uma linha. Cada linha vira um nível. Cada nível vira uma linha nova." |
| `nucleo_gemeo` | **Núcleo Gêmeo** | lendário | `projeteis flat +2`, `dano mult ×0,6`, `cadencia mult ×1,25` | "Duas torres foram fundidas em uma. Nenhuma das duas concordou." |
| `ultimo_prego` | **Último Prego** | mítico | `execucao flat +0,15`, `danoChefe mult ×3`, `dano mult ×2`, `vidaMax mult ×0,35` | "Serve para uma coisa só, e serve muito bem. Depois disso, não serve para nada — inclusive para você." |

### 8.3 Conjuntos

`[EXISTE]`: `forja_negra` 🌋 · `litania_zero` ❄️ · `sindicato_poeira` 🪙 · `concilio_esferas` 🔮

| id `[NOVO]` | Nome | Cartas | Bônus de conjunto |
|---|---|---|---|
| `arsenal_prototipo` | **Arsenal Protótipo** | `bico_estreito`, `agulheiro`, `nucleo_gemeo` | `perfuracao flat +3`, `projeteis flat +1`, `multiplicador mult ×1,3` |
| `oficina_ruido` | **Oficina do Ruído** | `capacitor_umido`, `bobina_de_recuo`, `metronomo_sangue` | `cadencia pct +0,25`, `roubodeVida flat +0,04`, `multiplicador mult ×1,22` |
| `protocolo_censo` | **Protocolo do Censo** | `arquivo_do_censo`, `dossie_carrasco`, `ultimo_prego` | `execucao flat +0,08`, `danoChefe mult ×1,6`, `ganhoFrag mult ×1,4` |

**Regras de módulo (recap para código):** 8 slots (base 3, +1 a cada `mao_extra`, +1 pelo desafio `purgatorio`, +1 por `af_slots`). Duplicatas: 3 iguais → **fusão** (+1 nível, efeito ×1,25). Reciclagem: carta → `pó = 5 × mult(raridade)`; 100 pó = 1 pacote.

---

## 9. MISSÕES — 36 diárias, 18 semanais

### 9.1 Diárias existentes `[EXISTE]` — 24 (`d_*`)
Cobrem: abates gerais, 7 tipos de inimigo, chefes, dourados, ouro ganho/gasto, ondas, combo, habilidades, críticos, tiros, cartas, nível, ascensões, upgrades, tempo.

### 9.2 12 diárias novas `[NOVO]`

| id | Ícone | Nome PT-BR | Meta | Recompensa | XP temp. | Requer |
|---|---|---|---|---|---|---|
| `d_ferro_velho` | 🔩 | **Sucateamento Compulsório** | `inimigoTipo:blindado ≥ 40` | `gemas 18` | 50 | onda 12 |
| `d_altitude` | 🪂 | **Controle de Altitude** | `inimigoTipo:saltador ≥ 35` | `gemas 18` | 50 | onda 14 |
| `d_realocacao` | 🌀 | **Realocação Involuntária** | `inimigoTipo:teleportador ≥ 25` | `gemas 22` | 60 | onda 30 |
| `d_desarme` | 🧨 | **Esquadrão Antibombas** | `inimigoTipo:bomba ≥ 30` | `gemas 22` | 60 | onda 28 |
| `d_quarentena` | ☣️ | **Quarentena Aplicada** | `inimigoTipo:parasita ≥ 25` | `gemas 26` | 65 | onda 50 |
| `d_luz_acesa` | 🔦 | **Deixe a Luz Acesa** | `inimigoTipo:sombra ≥ 20` | `gemas 28` | 70 | onda 60 |
| `d_demolicao` | 🏗️ | **Ordem de Demolição** | `inimigoTipo:coloso ≥ 8` | `gemas 30` | 75 | onda 45 |
| `d_promocoes` | 🎖️ | **Corte de Promoções** | `elitesMortos ≥ 20` ⚑ | `gemas 26` | 65 | onda 15 |
| `d_intacto` | 🪞 | **Nem Um Arranhão** | `ondasSemDano ≥ 5` ⚑ | `fragmentos 20` | 90 | onda 20 |
| `d_diplomacia` | 🤝 | **Diplomacia de Campo** | `eventosResolvidos ≥ 3` ⚑ | `gemas 20` | 55 | onda 5 |
| `d_provacao` | 🩸 | **Provação Voluntária** | `desafiosCompletos ≥ 1` (na sessão) | `pontosTalento 2` | 100 | onda 150 |
| `d_leitura` | 📖 | **Leitura Obrigatória** | `codexTierIII ≥ 1` (novo no dia) ⚑ | `gemas 24` | 60 | onda 10 |

**Escala:** `valorFinal = valorBase × (1 + 0,04 × ondaMaximaGlobal^0,72)` quando `escalaComOnda: true`.
**Rotação:** 4 diárias ativas (5 com `chave_do_turno` nv1+), sorteadas por peso entre as elegíveis, reset às 00:00 local, 1 rerroll grátis + 1 por nível de `dado_viciado`.

### 9.3 6 semanais novas `[NOVO]`

| id | Nome | Meta | Recompensa |
|---|---|---|---|
| `s_curadoria` | **Curadoria** | `codexTierIII ≥ 6` na semana | `stat multiplicador mult ×1,08` |
| `s_gabinete` | **Gabinete de Crise** | `eventosResolvidos ≥ 25` | `gemas 200` |
| `s_promocao_massa` | **Promoção em Massa** | `elitesMortos ≥ 400` | `stat danoTipo:elite mult ×1,15` |
| `s_dobro_ou_nada` | **Dobro ou Nada** | Completar 2 desafios de dificuldade ≥4 | `nucleos 1` |
| `s_maratona` | **Maratona** | `ondasCompletas ≥ 400` | `fragmentos 800` |
| `s_ficha_perfeita` | **Ficha Perfeita** | `ondasSemDano ≥ 30` acumuladas | `pontosTalento 12` |

### 9.4 Passe de Temporada `[EXISTE]` — 40 níveis
Já definido. **Patch sugerido:** níveis destaque (5, 10, 15, 20, 25, 30, 35, 40) devem entregar, nesta ordem: `carta épica garantida`, `mao_extra +1 slot temporário`, `fragmentos 500`, `relíquia exclusiva da temporada`, `pontosTalento 10`, `nucleos 1`, `carta lendária garantida`, `stat multiplicador mult ×1,25 permanente`.
**XP:** `xpNecessario(n) = 200 + 85 × n^1,25`. Total 40 níveis ≈ 21.400 XP ≈ 18 dias de diárias completas.

### 9.5 Sequência de login `[EXISTE]` — 7 dias, `multXP` de 1,0 a 1,4. Sem alterações.

---

## 10. EVENTOS ALEATÓRIOS — 28 (20 existentes + 8 novos)

**Disparo:** ao concluir uma onda múltipla de 5, chance de `18% + 0,4%/onda` (teto 40%). Máx. 1 evento a cada 3 ondas. O jogo **pausa** e mostra um cartão com 2–3 escolhas.

### 10.1 Existentes `[EXISTE]` — 20 (`caravana_sucata` … `trono_vazio`)

### 10.2 8 eventos novos `[NOVO]`

---

**1. `feira_dos_ossos` — Feira dos Ossos** 💀 · peso 62 · requer onda 20
> *"Montaram uma feira sobre a linha de frente enquanto você recarregava. Barracas de lona esticadas em fêmures, tudo à venda, nada com preço afixado. A vendedora principal cobra em memória: ela quer saber quantos você matou, e o número precisa ser verdadeiro."*

| Escolha | Resultado | Risco |
|---|---|---|
| "Dizer o número verdadeiro." | `fragmentos +30` | — |
| "Inflacionar o número." | `ouro ×4` (4 ondas de renda) | 45% → `dano 15% da vida máx.` |
| "Comprar um osso avulso e ir embora." | `carta ×1` (raridade ≥ incomum) | 20% → `nada` |

---

**2. `inspetor_qualidade` — Inspetor de Qualidade** 📋 · peso 58 · requer onda 25
> *"Um homem de prancheta desce de lugar nenhum e começa a medir a sua torre. Mede o cano, mede o alcance, mede o tempo entre disparos. Não diz para quem trabalha. Assina o laudo com uma caneta que não tem tinta e mesmo assim escreve."*

| Escolha | Resultado | Risco |
|---|---|---|
| "Aceitar a auditoria completa." | `buff: cadencia +40% e dano +40% por 3 ondas` | 30% → `buff: ganhoOuro −50% por 3 ondas` |
| "Subornar o inspetor." | `−30% do ouro atual`, `buff: multiplicador ×1,5 por 5 ondas` | — |
| "Expulsá-lo do perímetro." | `xp ×3` (uma onda) | 55% → próximo chefe vem com **+25% de vida** |

---

**3. `queda_de_satelite` — Queda de Satélite** 🛰️ · peso 54 · requer onda 35
> *"Algo velho e caro cai a duzentos metros e continua transmitindo depois do impacto. A caixa está quente, a antena está torta e o sinal repete a mesma sequência de nove números. Você reconhece a sequência: é o número de ondas que você já sobreviveu, contado ao contrário."*

| Escolha | Resultado | Risco |
|---|---|---|
| "Canibalizar a eletrônica." | `stat: alcance pct +0,12` **permanente na corrida** | — |
| "Responder ao sinal." | `carta ×2` + `gemas 40` | 40% → invoca **1 chefe extra** na próxima onda |
| "Enterrar a caixa e seguir." | `cura: 40% da vida máx.` + `fragmentos 15` | — |

---

**4. `contrabandista_gemas` — Contrabandista de Gemas** 💎 · peso 50 · requer onda 40
> *"Ela abre o casaco e o casaco tem mais bolsos do que o casaco comporta. Cada bolso brilha em uma cor. Diz que aceita ouro, aceita sucata, aceita promessa — e que promessa é a que rende mais juros para o lado dela."*

| Escolha | Resultado | Risco |
|---|---|---|
| "Pagar em ouro (−60% do total)." | `gemas 90` | — |
| "Pagar em promessa." | `gemas 200` | 50% → nas próximas 5 ondas, `ganhoOuro ×0,4` |
| "Vender gemas para ela." | `−40 gemas`, `ouro ×10` (10 ondas de renda) | — |

---

**5. `estagiario_enxame` — Estagiário do Enxame** 🐛 · peso 46 · requer onda 55
> *"Um Grunhido para a três metros da torre, levanta as duas mãos que não deveria ter e espera. Não ataca. Tem uma etiqueta colada no peito com um nome escrito à mão. O nome é o seu, com um erro de grafia."*

| Escolha | Resultado | Risco |
|---|---|---|
| "Aceitar a deserção." | `passiva por 10 ondas: 1 aliado que causa 25% do seu dano` ⚑ `entidade aliada` | 15% → ele **explode** por `20% da vida máx.` |
| "Interrogar." | Revela o próximo chefe e concede `danoChefe mult ×2` contra ele | — |
| "Atirar, como sempre." | `ouro ×6` + `combo +50` | 25% → `−1 slot de carta pela onda` |

---

**6. `linha_direta` — Linha Direta** ☎️ · peso 44 · requer onda 70
> *"O rádio da torre, que nunca funcionou, funciona. Do outro lado, alguém com a sua voz pergunta em que onda você está. Você responde. Há uma pausa longa demais. A voz diz: 'ainda dá tempo de parar' — e ri, porque sabe que não dá."*

| Escolha | Resultado | Risco |
|---|---|---|
| "Perguntar como sair daqui." | `caderno do Operador ×1` (fragmento de lore garantido) | — |
| "Pedir instruções táticas." | `buff: critChance +25% e critDano +100% por 4 ondas` | — |
| "Desligar." | `cura total` + `escudo = 100% da vida máx.` | — |

---

**7. `pacto_do_relogio` — Pacto do Relógio** ⏳ · peso 40 · requer onda 90
> *"Uma engrenagem do tamanho de uma casa aflora do chão e para exatamente quando você olha. Há um mostrador nela, e o mostrador tem uma agulha só. A agulha aponta para você. Existe um encaixe vazio no centro, do tamanho exato do seu próprio tempo."*

| Escolha | Resultado | Risco |
|---|---|---|
| "Adiantar o relógio (+15 ondas instantâneas)." | `onda +15`, ouro e XP das ondas puladas creditados a 60% | 35% → a onda 16 seguinte vem com **densidade ×3** |
| "Atrasar o relógio (−5 ondas)." | `cura total`, `fragmentos ×2 pelas próximas 10 ondas` | — |
| "Colocar a mão no encaixe." | `stat: cdr flat +0,2` **permanente na corrida** | 50% → `duracaoHab ×0,6` pelo resto da corrida |

---

**8. `museu_ambulante` — Museu Ambulante** 🏛️ · peso 36 · requer onda 130
> *"Um prédio inteiro caminha até você sobre oito pernas de andaime e para de lado, como um cavalo educado. As vitrines exibem torres. Torres que caíram. A vitrine do fim está vazia, limpa, com um cartão datilografado e um espaço reservado para a placa."*

| Escolha | Resultado | Risco |
|---|---|---|
| "Doar uma carta ao acervo." | `−1 carta equipada` → `relíquia: +1 nível grátis na mais cara` | — |
| "Comprar uma peça do acervo." | `−80% do ouro`, `carta lendária garantida` | — |
| "Ler o cartão da vitrine vazia." | `codex: cad_25 desbloqueado`, `stat multiplicador mult ×1,2` permanente na corrida | 30% → `o_silencio` aparece na próxima onda além do chefe programado |

---

## 11. DESAFIOS — 22 (14 existentes + 8 novos)

**Regra:** cada desafio é uma corrida separada com `mods` aplicados. Concluir dá recompensa **permanente e global**. Reconclusão não repete a recompensa, mas conta para `desafiosCompletos`.

### 11.1 Existentes `[EXISTE]` — 14
`ferrugem` (dif 1) · `metralha` (1) · `enxame` (2) · `pobreza` (2) · `apneia` (2) · `vidro` (3) · `silencio` (3) · `azar` (3) · `orbita` (3) · `doutrina` (4) · `hipervelocidade` (4) · `muralha` (4) · `esteira` (5) · `purgatorio` (5)

### 11.2 Novos modificadores necessários `⚑` (adicionar a `modsPadrao`)
`semElemental: false` · `semCartas: false` · `tipoUnico: ""` (id do único inimigo que aparece) · `decaimentoOuro: 0` (%/s de perda) · `alcance: 1` · `chanceElite: 1` · `cdChefe: 10` (ondas entre chefes) · `semColeta: false` (ouro só automático) · `visao: 1` (raio de visibilidade)

### 11.3 8 desafios novos `[NOVO]`

| id | Nome PT-BR | Dif | Mods | Objetivo | Recompensa | Requisito |
|---|---|---|---|---|---|---|
| `curto_circuito` | **Curto-Circuito** | 2 | `semElemental: true`, `cadencia: 2`, `hpInimigo: 1.4`, `ondaMax: 50` | onda 50 | `danoRaio flat +0,1`, `ricochete flat +2` | onda 60 |
| `feira_livre` | **Feira Livre** | 3 | `ouro: 8`, `hpInimigo: 3`, `densidade: 1.6`, `ondaMax: 60` | onda 60 | `ganhoOuro mult ×1,5`, `coleta pct +0,3` | onda 100 |
| `gravidade_dobrada` | **Gravidade Dobrada** | 3 | `velocidadeInimigo: 0.35`, `densidade: 3.5`, `hpInimigo: 2.2`, `semColeta: true`, `ondaMax: 70` | onda 70 | `area flat +25`, `coleta mult ×2` | onda 120 |
| `imposto_progressivo` | **Imposto Progressivo** | 4 | `decaimentoOuro: 0.02` (2%/s), `ouro: 3`, `xp: 2`, `ondaMax: 80` | onda 80 | `jurosOuro flat +0,01`, `ganhoOuro mult ×1,3` | onda 150 |
| `insonia` | **Insônia** | 4 | `ondaAuto: 6`, `semRegen: true`, `danoTorre: 0.6`, `ouro: 1.8`, `ondaMax: 100` | onda 100 | `regen mult ×2`, `velocidade pct +0,15` | onda 180 |
| `monocultura` | **Monocultura** | 4 | `tipoUnico: "divisor"`, `densidade: 2.5`, `hpInimigo: 1.8`, `ouro: 1.5`, `ondaMax: 90` | onda 90 | `perfuracao flat +2`, `ricochete flat +2` | onda 200 |
| `sala_de_espelhos` | **Sala de Espelhos** | 5 | `chanceElite: 8`, `cdChefe: 5`, `hpInimigo: 1.3`, `ouro: 2.5`, `ondaMax: 130` | onda 130 | `danoChefe mult ×1,6`, `especial: slotsHabilidade +1` | onda 350 |
| `mao_vazia` | **Mão Vazia** | 5 | `semCartas: true`, `semHabilidades: true`, `semUpgrades: true`, `xp: 5`, `ouro: 0.5`, `ondaMax: 100` | onda 100 | `especial: pontosTalento +20`, `multiplicador mult ×2,5` | onda 500 + 3 Singularidades |

**Desafios Infinitos (endgame):** após completar os 22, cada desafio ganha **Tiers II–X**. Tier N multiplica `hpInimigo` por `1,8^N` e `ondaMax` por `1,25^N`; recompensa: `multiplicador mult ×(1 + 0,05N)` cumulativo. Teto: Tier X = `multiplicador ×1,5` por desafio (22 × = ×1,5^22 na composição multiplicativa — ajustar para aditivo se quebrar a curva).

---

## 12. HABILIDADES — 15 (10 existentes + 5 novas)

### 12.1 Existentes `[EXISTE]`
`nova` 💥 · `sobrecarga` ⚡ · `tempo` ⏱️ · `chuva_ouro` 🪙 · `escudo_absoluto` 🛡️ · `sentinelas` 🗼 · `misseis` 🚀 · `buraco_negro` 🕳️ · `reparo` 🔧 · `julgamento` ⚖️

### 12.2 5 novas `[NOVO]`

| id | Nome | Ícone | Tecla | CD | Dur | Requer | Efeito (escala `[base, /nível]`) | Custo base |
|---|---|---|---|---|---|---|---|---|
| `martelo_orbital` | **Martelo Orbital** | 🔨 | 6 | 50s | 0 | onda 35 | Meteoro no maior aglomerado: `dano [850, 220]%` em raio de **220px**, atordoa 1,5s. Telegrafia 0,8s. | 30 |
| `estase` | **Estase** | 🧊 | 7 | 65s | 5s | onda 45 | **Congela todos** por `[4, 0.35]s`; congelados recebem `+[40, 8]%` de dano. Chefes: 40% da duração. | 40 |
| `dividendos` | **Dividendos** | 📈 | 8 | 75s | 12s | onda 60 | Converte `[18, 3]%` do ouro atual em `multiplicador` temporário: `×(1 + ouroConvertido^0,22 / 40)`. O ouro **não é gasto** — é "penhorado" e volta ao fim. | 55 |
| `eco` | **Eco** | 🔁 | 9 | 90s | 0 | onda 90 | Repete a **última habilidade usada** com `[60, 6]%` de eficácia e sem consumir a recarga dela. Não pode ecoar a si mesmo. | 70 |
| `estandarte_torre` | **Estandarte da Torre** | 🚩 | 0 | 80s | 15s | onda 120 | Finca uma bandeira. Dentro de **280px**: `dano +[45, 9]%`, `cadencia +[30, 6]%`, e inimigos que entram levam `[8,2]%` da vida máx./s. A torre pode estar fora do raio (o estandarte é fincado no cursor/toque). | 65 |

**Slots:** 3 base + `cinto_operador` (até 3) + `sala_de_espelhos` (1) = **7 máx.** de 15 → escolha real.

---

## 13. FÓRMULAS DE BALANCEAMENTO (referência para o código)

```
// Curva de onda
hpBase(w)     = 10 · 1.118^w · (1 + floor(w/50) · 0.30)
ouroBase(w)   = 3  · 1.086^w
xpBase(w)     = 5  · 1.070^w
inimigosNaOnda(w) = min(140, floor(6 + w·0.9 + (w/25)^1.6)) · densidade
intervaloSpawn(w) = max(0.06, 0.9 · 0.985^w)

// Chefe
ondaChefe(w)  = (w mod 10 == 0)
superChefe(w) = (w mod 100 == 0)
hpChefe       = hpBase(w) · 55 · (1 + 0.18·fases) · (1 + 0.05·chefesMortos^0.7)

// Combo
comboMult     = 1 + min(2.0, floor(combo/25) · 0.05)   // teto +200%
comboExpira   = 3.0s (∞ com ampulheta_rachada)

// Dourado
chanceDourado = 0.012 · (1 + sorte) · coleiraMult
valorDourado  = ouroBase(w) · 25

// Prestígio
fragmentos    = floor(3 · (ondaMax/25)^1.45 · ganhoFrag)
nucleos       = floor((ondaMax/150)^1.25 · ascensoesNaCorrida^0.35)
eter          = floor((ondaMax/500)^1.1 · singularidades^0.5)

// Offline
ouroOffline   = dpsMedio · 0.45 · min(t, tetoOffline) · eficiencia
tetoOffline   = 8h + 3h·cripta_estase.nivel                  // até 26h
eficiencia    = 1 + 0.04·cripta_estase.nv + 0.06·relogio_turno_noite.nv

// Custo de upgrade
custo(n)      = base · cresc^n          // cresc típico 1.07–1.15
// Compra em massa: soma de PG, com botão ×1 / ×10 / ×MAX / "próximo marco"

// Raridade de carta (peso base, ver rarities.json)
pesoAjustado  = peso · (1 + sorte)^(indiceRaridade·0.6)
```

**Ritmo de dopamina alvo:**
- **2–4s** → abate + moeda + som + partícula + número flutuante
- **20–40s** → subida de nível OU compra de upgrade OU carta
- **60–90s** → chefe, evento ou clima
- **8–20min** → Ascensão (loop médio)
- **3–8h** → Singularidade
- **2–5 dias** → Transcendência

---

## 14. ENTREGÁVEIS — arquivos e patches

| Arquivo | Ação | Conteúdo |
|---|---|---|
| `data/codex.json` | **criar** | §4 completo: `bestiario` (30×3 tiers), `chefes` (12), `eras` (14), `mecanicas` (10), `cadernos` (25) |
| `data/weather.json` | **criar** | §1.3 — 8 climas |
| `data/bosses.json` | **criar** | §3 — 12 chefes com `fases[]`, `habilidades[]` (cd, telegrafia, dano, raio), `contraJogo`, `recompensa` |
| `data/enemies.json` | patch | +8 inimigos (§2.2), +6 elites (§2.3) |
| `data/eras.json` | patch | +4 eras (§1.2) |
| `data/talents.json` | patch | +1 ramo `engenho`, +12 nós, +6 raízes (§5) |
| `data/achievements.json` | patch | +2 categorias, +34 conquistas (§6.3) |
| `data/relics.json` | patch | campo `raridade` em 26, +8 relíquias (§7.2) |
| `data/cards.json` | patch | +11 cartas, +3 conjuntos (§8) |
| `data/missions.json` | patch | +12 diárias, +6 semanais (§9) |
| `data/events.json` | patch | +8 eventos (§10.2) |
| `data/challenges.json` | patch | +9 mods padrão, +8 desafios (§11) |
| `data/abilities.json` | patch | +5 habilidades (§12.2) |
| `data/stats.json` | patch | ⚑ novos: `danoTipo` (mapa), `ganhoEter` |
| contadores de save | patch | ⚑ `elitesMortos`, `eventosResolvidos`, `codexTierIII`, `chefeTipo{}`, `ondasSemDano`, `desafioTipo{}`, `relicaNivel{}`, `climasVistos`, `conjuntoAtivo`, `cadernosLidos`, `mimicosRevelados`, `ouroOffline`, `tempoSemComprar` |