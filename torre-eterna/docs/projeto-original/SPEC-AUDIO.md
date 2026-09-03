> **Documento do projeto original — não descreve o jogo que existe.**
> Este texto de áudio foi escrito para uma implementação em JavaScript/Canvas
> que nunca foi construída; o jogo é feito em Godot 4 e GDScript. Caminhos
> de arquivo, APIs e números aqui são do projeto, não da realidade.
> Leia `docs/projeto-original/LEIA-ANTES.md` antes de usar qualquer coisa
> daqui.

# TORRE ETERNA — Especificação de Áudio Procedural (WebAudio, zero assets)

**Documento normativo v1.0** · PT-BR · alvo: 60 fps com 400+ entidades, mobile incluído
Nomes de eventos alinhados 1:1 com os sinais já declarados em `/home/user/joabcostamd/torre-eterna/scripts/core/event_bus.gd`.
Chaves de configuração alinhadas com `/home/user/joabcostamd/torre-eterna/scripts/core/config.gd` (`vol_master`, `vol_sfx`, `vol_musica`, `mudo`, `qualidade`, `movimento_reduzido`).
Dados musicais lidos de `/home/user/joabcostamd/torre-eterna/data/eras.json` (campo `musica`: `escala`, `bpm`, `timbre`, `camadas`) e `/home/user/joabcostamd/torre-eterna/data/rarities.json` (`raridades[].id`, `elementos`).

---

## 0. Princípios de projeto (as 8 regras que governam tudo abaixo)

1. **Nada toca ao vivo se puder ser assado.** Sons de alta frequência de disparo (tiro, impacto, ouro, cliques) são renderizados uma vez no boot via `OfflineAudioContext` em *N* variantes e tocados como `AudioBufferSourceNode`. Síntese ao vivo fica reservada para eventos raros e expressivos (chefe, prestígio, level up, drops) e para a música.
2. **Um som repetido 40×/s não é um som, é ruído branco.** Todo evento de alta cadência tem *cooldown*, *polifonia máxima*, *coalescência por frame* e compensação de ganho **sublinear** (√n).
3. **Variação obrigatória.** Nenhum som toca duas vezes idêntico: round-robin de variantes + jitter de `playbackRate` + jitter de pan + jitter de ganho.
4. **Escadas de tom = dopamina.** Ouro, crítico e combo sobem em degraus dentro da escala da era vigente. A recompensa é *melódica*, não só volumétrica.
5. **O silêncio é um instrumento.** Prestígio, morte de chefe e drop lendário têm janelas de silêncio absoluto antes do impacto.
6. **Mixagem é alocação de espectro,** não de volume: cada família de som possui uma faixa reservada (§11.3).
7. **Zero cliques.** Nenhuma rampa de ganho menor que 5 ms; nenhum `exponentialRampToValueAtTime` para 0 (usar `1e-4`).
8. **Determinismo auditável.** Toda receita é dado (`receitas.js`), não código imperativo — permite tuning sem recompilar mentalmente, e permite testes automáticos de pico/duração.

---

## 1. Contexto, destravamento e ciclo de vida

### 1.1 Criação

```js
const ctx = new (window.AudioContext || window.webkitAudioContext)({
  latencyHint: 'interactive'      // NUNCA forçar sampleRate: quebra iOS e força resample
});
// ctx.sampleRate lido, não imposto. Esperado: 48000 (desktop) ou 44100 (iOS/alguns Android).
const SR = ctx.sampleRate;
const BASE_LAT = ctx.baseLatency ?? 0.01;   // ~0.005–0.02 s
```

### 1.2 Destravamento (autoplay policy)

Registrar **uma vez**, em `{once:true, capture:true, passive:true}`, nos eventos `pointerdown`, `touchend`, `keydown`, `mousedown`:

```
1. ctx.resume()
2. tocar buffer de 1 frame silencioso (AudioBuffer(1, 1, SR)) → destrava iOS < 17
3. estado = 'pronto' → só então iniciar música e liberar SFX
```

Antes do destravamento, `Audio.tocar()` é **no-op silencioso** (não enfileira; enfileirar gera avalanche de 200 sons no primeiro toque).

### 1.3 Suspensão

| Condição | Ação | Fade |
|---|---|---|
| `document.hidden` por > 20 s | `masterGain → 0` em 250 ms, depois `ctx.suspend()` | 250 ms |
| `visibilitychange → visível` | `ctx.resume()`, ressincronizar relógio musical no **próximo compasso** (nunca "recuperar" o tempo perdido), `masterGain → alvo` | 400 ms |
| `ctx.onstatechange === 'interrupted'` (iOS, chamada telefônica) | marcar `precisaDestravar = true`, reaplicar §1.2 no próximo toque | — |
| Aba oculta < 20 s | manter tocando (idle game: o jogador voltará) | — |

### 1.4 Ambiente `file://`

O jogo roda offline e pode ser aberto por duplo-clique. `Worker` criado por Blob URL **falha em `file://` no Chrome** (origem opaca). Portanto o relógio musical tem dois caminhos (§12.1): Worker (preferencial) e `setTimeout` (fallback), decidido por um `try/catch` no boot.

---

## 2. Topologia de barramentos

```
                                       ┌─ envioCurto ─ ConvolverNode(IR 0.9s) ─ LP 6500 ─ gCurto ─┐
                                       ├─ envioLongo ─ ConvolverNode(IR 2.8s) ─ HP 180 ─ gLongo ──┤
                                       ├─ envioEco  ─ Delay(3/16 do BPM) ⟲ fb 0.32 ─ LP 3200 ────┤
   voz ─ vozGain ─ [pan] ─┬─ busX ─────┴──────────────────────────────────────────────────────────┤
                          │                                                                        │
   bus.tiro     ─ comp ───┤                                                                        │
   bus.impacto  ─ comp ───┤                                                                        │
   bus.ouro     ─ comp ───┼──▶ somaSFX (Gain, -0.0 dB) ──────────────────────────────────────┐    │
   bus.evento   ─────────┤                                                                    │    │
   bus.ui       ─────────┤                                                                    │    │
   bus.ambiente ─────────┘                                                                    │    │
                                                                                              ▼    ▼
   bus.musica ─ musSide (sidechain) ─ musLP (dinâmico) ─ comp ────────────────────────▶ somaGeral (Gain)
                                                                                              │
                                                              masterGain ◀────────────────────┘
                                                                  │
                                    HP 18 Hz (Q .707) ─ LP 17.5 kHz ─ shelfAgudo (acessibilidade)
                                                                  │
                                       COLA: DynamicsCompressor  (thr -14, knee 6, ratio 3, atk .006, rel .18)
                                                                  │
                                       LIMITADOR: DynamicsCompressor (thr -1.2, knee 0, ratio 20, atk .0008, rel .06)
                                                                  │
                                       TETO: WaveShaper (softclip 1.5×, oversample '2x')
                                                                  │
                                       saidaTrim (Gain 0.89)  ─────▶  ctx.destination
```

### 2.1 Ganhos nominais de barramento (dB, pré-fader de usuário)

| Barramento | dB | linear | Compressor |
|---|---:|---:|---|
| `musica` | −6.0 | 0.501 | thr −12, knee 8, ratio 2.5, atk 0.012, rel 0.22 |
| `tiro` | −8.0 | 0.398 | thr −20, knee 3, ratio 6, atk 0.003, rel 0.09 |
| `impacto` | −6.5 | 0.473 | thr −16, knee 4, ratio 4, atk 0.004, rel 0.11 |
| `ouro` | −7.0 | 0.447 | thr −18, knee 4, ratio 5, atk 0.002, rel 0.12 |
| `evento` | −3.0 | 0.708 | — (transparente, é o herói) |
| `ui` | −12.0 | 0.251 | — |
| `ambiente` | −16.0 | 0.158 | — |

`somaSFX` = 0 dB. `saidaTrim` = 0.89 (−1.0 dB) para folga de intersample peaks.
**Alvo de loudness:** ≈ −16 LUFS integrado em jogo normal (onda 20, 12 inimigos); true peak ≤ −1.0 dBTP garantido pelo limitador + softclip.

### 2.2 Curvas de WaveShaper (n = 2048, x = i/(n−1)·2 − 1)

| Nome | Fórmula | Uso |
|---|---|---|
| `tanh(d)` | `Math.tanh(d*x) / Math.tanh(d)` | saturação musical, d ∈ [1.2, 4.0] |
| `softclip` | `x<=-1?-2/3 : x>=1?2/3 : x - x³/3`, ×1.5 | teto final do master |
| `fold(k)` | `Math.sin(k*Math.PI*x/2)` | metal/vazio, k ∈ [1.5, 3] |
| `crush(b)` | `Math.round(x*(2**b-1))/(2**b-1)` | era `depuracao`, b ∈ [4, 6] |
| `assim(d)` | `x>0 ? Math.tanh(d*x)/Math.tanh(d) : Math.tanh(0.6*d*x)/Math.tanh(0.6*d)` | corpo "orgânico", pares harmônicos |

`oversample = '2x'` sempre (o `'4x'` custa ~2× e não é audível aqui).

---

## 3. Primitivas de síntese

### 3.1 Envelope (helper único)

```js
// env(param, t0, {a, pico, d, sus, susDur, r, formaA:'lin'|'exp'})
// a  : ataque (s)     pico: valor de topo
// d  : decaimento (s) sus : nível de sustain (fração do pico, 0..1)
// r  : release (s), implementado como setTargetAtTime(1e-4, t, r/3.2)
```

Regras normativas:
- `param.cancelScheduledValues(t0); param.setValueAtTime(1e-4, t0);`
- Ataque: `linearRampToValueAtTime(pico, t0+a)` (linear evita "chiado" no ataque de 1 ms).
- Decaimento até sustain: `setTargetAtTime(pico*sus, t0+a, d/3.0)` — 3τ ≈ 95 % do trajeto.
- Release: `setTargetAtTime(1e-4, tRel, r/3.2)`; a fonte para em `tRel + r*1.15`.
- **Percussivo** (a maioria dos SFX): `sus = 0`, sem `susDur` → um único `setTargetAtTime(1e-4, t0+a, d/3)`, `stop(t0 + a + d*1.3)`.
- Ataques mínimos por família: percussivo 0.0006 s · tonal 0.003 s · pad 0.35 s · riser 0.8 s.

### 3.2 Formas de onda (PeriodicWave anti-alias)

Não usar `'square'`/`'sawtooth'` nativos acima de 2 kHz de fundamental. Construir `PeriodicWave` com harmônicas limitadas a `K = min(64, floor(0.45*SR / f0))`:

| Timbre (`eras.json`) | `imag[k]` | Observação |
|---|---|---|
| `senoide` | `k==1 ? 1 : 0` | — |
| `triangulo` | k ímpar: `8/(π²k²)·(−1)^((k−1)/2)`; par: 0 | doce, `vidro`/`aurora` |
| `dente` | `2/(πk)` | `pantano` |
| `quadrada` | k ímpar: `4/(πk)`; par: 0 | `sucata`, `fundicao`, `depuracao` |
| `quadrada_suja` | `square[k] · (1 − 0.018k)`, e `imag[3] ×= 1.32` | variante de `sucata` (rádio velho) |
| `orgao` | k ∈ {1,2,3,4,6,8}: `[1, .5, .33, .25, .16, .12]` | pad de `necropole` |
| `metal` | ratios inarmônicos → não é PeriodicWave; ver §3.5 | impacto blindado |

`real[] = 0` em todos (fase cosseno nula). Cachear as waves por `(timbre, faixaK)` em um `Map`; 6 faixas de K bastam: {4, 8, 16, 24, 40, 64}.

### 3.3 Buffers de ruído (gerados no boot, compartilhados)

| Nome | Duração | Canais | Geração |
|---|---:|---:|---|
| `branco` | 2.0 s | 2 (descorrelacionados) | `Math.random()*2-1` |
| `rosa` | 2.0 s | 2 | filtro de Paul Kellett (abaixo) |
| `marrom` | 1.5 s | 1 | `b = (b + 0.02*w)/1.02; out = b*3.5` |
| `crepitar` | 1.0 s | 1 | `Math.random() < 0.004 ? (rnd*2-1) : 0`, depois LP 1-polo α=0.35 |

**Rosa (Kellett), coeficientes exatos:**
```
b0 = 0.99886*b0 + w*0.0555179
b1 = 0.99332*b1 + w*0.0750759
b2 = 0.96900*b2 + w*0.1538520
b3 = 0.86650*b3 + w*0.3104856
b4 = 0.55000*b4 + w*0.5329522
b5 = -0.7616*b5 - w*0.0168980
out = (b0+b1+b2+b3+b4+b5+b6 + w*0.5362) * 0.11
b6 = w*0.115926
```

Toda leitura de ruído usa **offset aleatório** `rnd()*(dur - trecho)` e `playbackRate ∈ [0.92, 1.09]` → variação infinita a custo zero de memória.

### 3.4 Impulse Responses procedurais (§ para os dois Convolvers)

```js
function fazerIR(dur, decai, preDelay, lpHz, hpHz, taps) {
  // N = ceil(dur*SR); estéreo. Para cada canal c:
  //   cauda: L[i] = (rnd()*2-1) * Math.pow(1 - i/N, decai)
  //   early reflections: para cada tap (t, g) → L[floor((preDelay + t*(1 + c*0.08))*SR)] += g*(rnd()*2-1)
  //   suavização escura: 1-polo LP recursivo com α = exp(-2π*lpHz/SR)
  //   corte grave: 1-polo HP com α = exp(-2π*hpHz/SR)
  //   normalizar por RMS para 0.28
}
```

| IR | dur | decai | preDelay | LP | HP | taps (s, ganho) |
|---|---:|---:|---:|---:|---:|---|
| `curto` (arena) | 0.90 s | 3.2 | 0.008 s | 5200 Hz | 90 Hz | (.0075,.62) (.0121,.48) (.0189,.38) (.0273,.28) (.0331,.20) |
| `longo` (abismo) | 2.80 s | 2.4 | 0.022 s | 3400 Hz | 180 Hz | (.019,.55) (.031,.44) (.047,.36) (.068,.27) (.091,.21) (.119,.15) |

`convolver.normalize = false` — controle explícito pelo ganho de envio (previsível entre navegadores).
**Qualidade baixa:** `longo` é substituído por eco multi-tap (delays 0.075 / 0.113 / 0.167 s, ganhos .42/.30/.21, feedback global .36, LP 2600) — ~40× mais barato.

### 3.5 Modelo de parciais inarmônicos (metal / sino / gongo)

```js
parciais(base, ratios[], decais[], ganhos[], detuneCents[])
// Para cada i: OscillatorNode('sine') a base*ratios[i], detune ±detuneCents[i],
// env percussivo (a=0.0008, d=decais[i]), ganho = ganhos[i] / Math.sqrt(ratios.length)
```

Conjuntos de razões normativos:

| Conjunto | Razões |
|---|---|
| `chapa` (impacto blindado) | 1.00, 1.62, 2.31, 3.07, 4.19 |
| `sino` (crítico, drop) | 1.00, 2.00, 2.40, 3.00, 4.50, 5.33 |
| `gongo` (chefe/prestígio) | 1.00, 2.76, 5.40, 8.93, 13.34 |
| `vidro` (gelo) | 1.00, 1.50, 2.00, 2.67, 3.75 |
| `caos` (vazio/mítico) | 1.00, 1.41, 1.73, 2.24, 2.83, 3.46, 4.12, 5.19, 6.48 |

### 3.6 FM (2 operadores)

```js
fm({fc, fm_, indice:[i0,i1], durIdx, envPortadora})
// mod = Osc(sine, fm_) → modGain(indice) → carrier.frequency
// indice desce exponencialmente de i0 → i1 em durIdx (em Hz de desvio)
// razão r = fm_/fc: 1.0 e 2.0 = tonal; 1.414, 2.5, 3.16 = metálico/inarmônico
```

### 3.7 Conversões

`f(midi) = 440 * 2**((midi-69)/12)` · `lin(dB) = 10**(dB/20)` · `dB(lin) = 20*Math.log10(lin)`
`taxaPorSemitom(st) = 2**(st/12)` (usar `playbackRate`, não `detune`, em `AudioBufferSourceNode` — compatibilidade Safari).

---

## 4. Forno (bake) — pré-renderização no boot

### 4.1 Procedimento

```js
async function assar(receita, variante) {
  const dur = receita.dur + 0.03;                       // 30 ms de cauda de segurança
  const oc  = new OfflineAudioContext(1, Math.ceil(dur*SR), SR);
  montarGrafo(oc, receita, sementeDeterminística(receita.id, variante));
  const buf = await oc.startRendering();
  normalizarPico(buf, lin(receita.picoDbfs));           // varredura + escala in-place
  return buf;
}
```

- Mono sempre (pan é aplicado em tempo real por `StereoPannerNode`).
- **Semente determinística** por `(id, variante)` usando o `RngX` do projeto (`scripts/core/rngx.gd` → porta JS) → o mesmo build soa igual sempre, e os testes de regressão de pico funcionam.
- **Concorrência 4** e fatiamento: no máximo 4 `startRendering()` em voo; entre lotes, `await new Promise(r => requestAnimationFrame(r))` → a tela de carregamento nunca perde frame.
- **Orçamento de boot:** ≤ 140 ms de CPU total em desktop, ≤ 420 ms em mobile de 4 núcleos. Se `performance.now()` acumulado ultrapassar, reduzir `variantes` pela metade e continuar (degradação graciosa, sem travar).

### 4.2 Catálogo assado — durações, variantes, memória

Memória = `dur × variantes × SR × 4 bytes`. Tabela a 48 kHz (192 kB/s):

| id | dur (s) | variantes | s totais | kB |
|---|---:|---:|---:|---:|
| `tiro_leve` | 0.12 | 6 | 0.72 | 138 |
| `tiro_pesado` | 0.26 | 4 | 1.04 | 200 |
| `tiro_laser` | 0.20 | 3 | 0.60 | 115 |
| `impacto` | 0.10 | 8 | 0.80 | 154 |
| `impacto_critico` | 0.28 | 4 | 1.12 | 215 |
| `elem_fogo` | 0.14 | 3 | 0.42 | 81 |
| `elem_gelo` | 0.16 | 3 | 0.48 | 92 |
| `elem_raio` | 0.09 | 4 | 0.36 | 69 |
| `elem_veneno` | 0.18 | 3 | 0.54 | 104 |
| `elem_vazio` | 0.30 | 2 | 0.60 | 115 |
| `morte_pequena` | 0.22 | 6 | 1.32 | 253 |
| `morte_media` | 0.34 | 4 | 1.36 | 261 |
| `morte_blindada` | 0.40 | 3 | 1.20 | 230 |
| `morte_voadora` | 0.26 | 4 | 1.04 | 200 |
| `ouro` | 0.16 | 8 | 1.28 | 246 |
| `ouro_chuva` | 0.30 | 2 | 0.60 | 115 |
| `upgrade` | 0.45 | 3 | 1.35 | 259 |
| `negado` | 0.22 | 1 | 0.22 | 42 |
| `dano_torre` | 0.50 | 3 | 1.50 | 288 |
| `surgir` | 0.18 | 4 | 0.72 | 138 |
| `ui_click` | 0.05 | 3 | 0.15 | 29 |
| `ui_hover` | 0.04 | 2 | 0.08 | 15 |
| `ui_tab` | 0.05 | 2 | 0.10 | 19 |
| `ui_painel` | 0.22 | 2 | 0.44 | 85 |
| `alerta_onda` | 0.30 | 2 | 0.60 | 115 |
| **Total assado** | | | **19.6 s** | **≈ 3.66 MB** |
| IR curto (2 canais) | 0.90 | — | 1.80 | 346 |
| IR longo (2 canais) | 2.80 | — | 5.60 | 1075 |
| Ruídos | — | — | 7.5 | 1440 |
| **TOTAL** | | | | **≈ 6.5 MB** |

**Perfil `qualidade ≤ 1` (média/baixa):** variantes × 0.5 (mín. 2), IR longo desativado, ruído `rosa` mono → **≈ 2.6 MB**.

---

## 5. Especificação som a som — combate

> Convenção: `f: 420→118 / 0.055 exp` = a frequência vai de 420 a 118 Hz em 55 ms, rampa exponencial. `env(a,d,sus,r)` em segundos. `g` = ganho da camada antes da normalização. Pico final em dBFS após normalização.

---

### 5.1 `tiro_leve` — arma padrão (evento `torre_atirou`)

**Intenção:** "thock" seco, sem cauda, que sobrevive a 15/s sem virar mingau.

| Camada | Especificação |
|---|---|
| A — corpo | `PeriodicWave quadrada_suja(K=24)`, `f: 420→118 / 0.055 exp`, `env(0.0010, 0.022, 0, 0.010)`, `g 0.50` |
| B — sub | `sine`, `f: 160→60 / 0.070 exp`, `env(0.0015, 0.030, 0, 0.012)`, `g 0.35` |
| C — tique | `ruido branco` → `BPF f=2400 Q=1.2`, `env(0.0008, 0.012, 0, 0.006)`, `g 0.22` |
| Filtro (A+B) | `lowpass`, `f: 5200→1400 / 0.060 exp`, `Q 0.9` |
| Corte | `highpass 90 Hz Q 0.707` sobre a soma |

`dur 0.12 s` · `pico −9.0 dBFS` · bus `tiro` · envio `curto −26 dB`
**Variação por toque:** `playbackRate ∈ [0.94, 1.07]` (uniforme), `ganho × [0.88, 1.06]`, `pan = clamp(anguloTiro→x, −0.55, 0.55)`
**Bake:** 6 variantes com jitter de `f0` (±6 %) e de `Q` do BPF (±0.3).
**Polifonia 6 · cooldown 28 ms · prioridade 2**

#### 5.1.1 Modo FEIXE (obrigatório para idle)

Quando a cadência ultrapassa **14 tiros/s**, one-shots deixam de funcionar (mascaramento + custo). Fazer *crossfade de 120 ms* para uma voz **contínua** e desligar os one-shots:

| Camada | Especificação |
|---|---|
| Portadora | `sawtooth` (K=32) a `f0 = 92 Hz`, 3 vozes detune `−9 / 0 / +9` cents |
| Ruído | `rosa` → `BPF f=1900 Q=2.4`, `g 0.18` |
| AM | `LFO sine` na taxa de tiro **clampada a [14, 30] Hz**, profundidade 0.55 (ganho 0.45→1.0) |
| Filtro | `lowpass f = 1200 + 2600·min(1, dps/dpsRef)`, `Q 1.4` |
| Envelope | ataque 0.12 s ao entrar, release 0.25 s ao sair |

Ganho do feixe = `lin(-11 dB) × min(1.35, sqrt(tiros_s/14))`. Custo: **1 voz** em vez de 30/s.
A cada 8 tiros ainda dispara um `impacto` real, mantendo a leitura de "acerto".

---

### 5.2 `tiro_pesado` — canhão / morteiro

| Camada | Especificação |
|---|---|
| Sub | `sine`, `f: 90→38 / 0.120 exp`, `env(0.0020, 0.090, 0, 0.040)`, `g 0.75` |
| Corpo | `triangle`, `f: 220→70 / 0.080 exp`, `env(0.0015, 0.060, 0, 0.030)`, `g 0.40` |
| Sopro | `ruido branco` → `LPF 900 Q 0.7` → `BPF 180 Q 0.7`, `env(0.0020, 0.060, 0.15, 0.080)`, `g 0.50` |
| Saturação | `tanh(2.5)` sobre a soma, `oversample 2x` |

`dur 0.26 s` · `pico −6.0 dBFS` · bus `tiro` · envio `longo −20 dB`
`playbackRate ∈ [0.96, 1.05]` · **polifonia 3 · cooldown 90 ms · prioridade 4**

---

### 5.3 `tiro_laser`

| Camada | Especificação |
|---|---|
| FM | portadora `sine` `f: 1400→620 / 0.180 exp`; modulador `sine` a `fc × 2.5`; índice `900→40 Hz / 0.060 exp` |
| Filtro | `bandpass f: 4200→1800 / 0.090 exp, Q 6` |
| Env | `env(0.0040, 0.050, 0.25, 0.120)`, `g 0.55` |

`dur 0.20 s` · `pico −11.0 dBFS` · bus `tiro` · envio `curto −20 dB` · **polifonia 4 · cooldown 55 ms · prio 3**

---

### 5.4 `impacto` — acerto comum (evento `inimigo_atingido`)

**O som mais tocado do jogo. Deliberadamente pequeno e escuro.**

| Camada | Especificação |
|---|---|
| Corpo | `ruido branco` → `BPF f=1450 Q=2.2`, `env(0.0006, 0.018, 0, 0.008)`, `g 0.40` |
| Clique | `sine`, `f: 320→140 / 0.030 exp`, `env(0.0006, 0.012, 0, 0.006)`, `g 0.28` |

`dur 0.10 s` · `pico −16.0 dBFS` · bus `impacto` · envio `curto −32 dB`

**Modulação por dano (essencial para legibilidade):**
```
r = clamp( (log10(dano) - log10(danoMedianoDaOnda)) , -1.5, +1.5 )
playbackRate = 1.16 * Math.pow(2, -r * 0.22)   // dano alto ⇒ grave ⇒ "pesado"
ganho        = lin(-16) * (0.75 + 0.35*clamp((r+1.5)/3, 0, 1))
```
`pan = clamp((x_inimigo - x_torre)/(larguraTela*0.5) * 0.7, -0.7, 0.7)`
**Polifonia 8 · cooldown 22 ms · prioridade 1 (primeiro a ser roubado)**
**Coalescência:** ≥ 3 pedidos no mesmo frame (16.7 ms) → 1 voz com `ganho × min(2.2, √n)` e `pan` = média ± 0.25.

---

### 5.5 Camadas elementares (somadas ao `impacto`, ganho −4 dB relativo)

Dados de `data/rarities.json → elementos`.

| Elemento | Especificação | dur | pico |
|---|---|---:|---:|
| **fogo** (`#ff6b35`) | `ruido branco` → `HPF 3000 Q .7` → `LPF 7000`, `env(0.0020, 0.050, 0.20, 0.060)` `g .18`; + `BPF 620 Q 3` do mesmo ruído `g .10` (rosnado) | 0.14 | −21 |
| **gelo** (`#6bd6ff`) | `parciais(2100, [1, 1.5, 2], [0.11, 0.08, 0.055], [.12,.09,.06], [±7])` + AM 5 Hz prof. 0.25 | 0.16 | −20 |
| **raio** (`#ffe45e`) | `ruido branco` → 4 `BPF` paralelos em 900/1900/3800/7600 `Q 8`, ganhos aleatórios [.5–1] por toque, `env(0.0004, 0.020, 0, 0.010)`; + `sine 40 Hz` `env(0.0005, 0.020,0,0)` `g .3` (estalo) | 0.09 | −17 |
| **veneno** (`#8cff6b`) | 3 blips `sine` em `f ∈ [300, 700]` aleatório, espaçamento 12–40 ms, cada `env(0.003, 0.035, 0, 0.02)`, tudo por `LPF 1200 Q 1.2` | 0.18 | −23 |
| **vazio** (`#b06bff`) | `sine f: 700→90 / 0.250 exp`, `env(0.060, 0.120, 0.3, 0.10)` (ataque lento = "reverso"); `Delay 0.045 s`, `fb 0.50`, `LPF 800`; `fold(2.0)` | 0.30 | −19 |

**Empilhamento:** no máximo 1 camada elementar por impacto (a do elemento dominante). Cooldown próprio de 60 ms por elemento.

---

### 5.6 `impacto_critico` (evento `inimigo_atingido` com `critico == true`)

**Este é o som que vicia. Ele sobe com o combo.**

| Camada | Especificação |
|---|---|
| FM metálica | portadora `sine 2400`; mod `sine 2400×1.414`; índice `600→20 Hz / 0.090 exp`; `env(0.0010, 0.080, 0, 0.040)` `g 0.55` |
| Sino | `parciais(3140, [1, 1.5, 2], [0.11, 0.08, 0.06], [.30,.22,.16], [0, ±9, ±14])` |
| Corte | `highpass 800 Hz Q .707` |

`dur 0.28 s` · `pico −10.0 dBFS` · bus `impacto` · envio `curto −14 dB`, `eco −24 dB`

**Escada de combo (evento `combo_mudou`):**
```
degrau     = Math.min(24, Math.floor(combo / 4));           // 0..24 semitons
escala     = eraAtual.musica.escala;                        // ex.: [0,3,5,7,10]
semitons   = escala[degrau % escala.length] + 12*Math.floor(degrau/escala.length);
playbackRate = Math.pow(2, Math.min(semitons, 24)/12);
ganho        = lin(-10) * (1 + 0.20*Math.min(1, combo/60));
envioCurto  += Math.min(8, combo/12) dB                     // cauda cresce com o combo
```
`combo_quebrou` → tocar `combo_fim`: `sine 1200→300 / 0.18 exp`, `env(.002,.09,0,.05)`, `−22 dBFS`, `LPF 2000`, sem reverb (seco = frustração).
**Polifonia 4 · cooldown 45 ms · prioridade 5**

---

### 5.7 Mortes (evento `inimigo_morreu`, seleção por classe)

| id | Camadas | dur | pico | prio |
|---|---|---:|---:|---:|
| `morte_pequena` | `ruido branco → LPF f:2400→500/0.16 exp`, `env(.001,.06,0,.03)` `g .45`; + `sine f:180→45/0.14 exp` `env(.001,.05,0,.03)` `g .40` | 0.22 | −13 | 5 |
| `morte_media` | igual + `assim(2.2)`; + `BPF 700 Q 1.6` `g .3`; + `crush(6)` na camada de ruído | 0.34 | −11 | 5 |
| `morte_blindada` | `parciais(340, chapa, [.30,.22,.16,.12,.09], [.34,.26,.20,.15,.11], ±18 c)`; + raspagem `ruido marrom → BPF 1200 Q 2` `env(.002,.10,0,.06)` `g .28`; + `sine 60 Hz` `g .35` | 0.40 | −10 | 6 |
| `morte_voadora` | `ruido branco → HPF 1400`, `env(.001,.05,0,.03)` `g .38`; + assobio `sine f:1400→380/0.20 exp` `g .25`; + `sine f:200→70` `g .22` | 0.26 | −13 | 5 |

Todas com `playbackRate ∈ [0.92, 1.09]`, `pan` pela posição, envio `curto −24 dB`.
**Modulação por tamanho:** `playbackRate ×= clamp(1.25 - 0.30*log10(hpMax/hpMaxBase), 0.62, 1.35)`.

**`overkill` (evento `overkill(e, fracao)`), quando `fracao ≥ 3`:**
camada extra ao vivo — `sine f: 55→30 / 0.35 exp`, `env(.002,.22,0,.12)`, `g 0.60`, `tanh(1.8)`, envio `longo −12 dB`, `+ hitstop de áudio: duck de bus.tiro e bus.impacto em −10 dB por 90 ms`.
Cooldown 250 ms (é um destaque, não um tapete).

---

### 5.8 `surgir` — inimigo nasce (evento `inimigo_surgiu`)

`ruido rosa → BPF f: 300→900 / 0.12 exp, Q 1.8`, `env(0.010, 0.070, 0, 0.05)`, `g 0.30`; + `sine 90 Hz` `g .18`.
`dur 0.18 s` · `pico −26 dBFS` · bus `ambiente` · **polifonia 3 · cooldown 120 ms · prio 0**
**Coalescência agressiva:** com > 4 spawns em 200 ms, tocar 1 vez com `ganho × min(1.8, √n)` e `pan` = centroide.
Silenciado inteiramente quando `nInimigos > 60` (não agrega informação).

---

### 5.9 `dano_torre` (evento `torre_atingida(dano, vida, vida_max)`)

| Camada | Especificação |
|---|---|
| Impacto | `ruido branco → LPF f: 1800→300 / 0.20 exp, Q 1.1`, `env(.0015, .12, 0, .10)`, `g 0.55` |
| Anel metálico | `parciais(165, [1, 2.4, 3.7, 5.1], [.50,.38,.28,.20], [.26,.19,.14,.10], ±12 c)` |
| Sub | `sine f: 78→42 / 0.22 exp`, `env(.002, .12, 0, .08)`, `g 0.50` |

`dur 0.50 s` · `pico −7.0 dBFS` · bus `evento` · envio `longo −14 dB`
`ganho ×= clamp(0.5 + 0.9*(dano/vida_max), 0.5, 1.6)` · `pan` pela direção do agressor
**Cooldown 110 ms · polifonia 2 · prioridade 6**

#### 5.9.1 Estados de perigo (a melhor ferramenta de tensão do jogo)

`hp = vida/vida_max`. Ao cruzar um limiar **para baixo** (histerese de +0.04 para religar):

| hp | Alarme | LPF na música | Detune música | Batimento cardíaco |
|---:|---|---:|---:|---|
| < 0.50 | `square 660 Hz`, 0.18 s on / 0.22 s off, `LPF 2200`, `g .12` | 2400 Hz | −12 cents | 55 Hz, 2 batidas, 1.1 Hz |
| < 0.25 | alterna 660/880 Hz, `g .18` | 1400 Hz | −25 cents | 1.5 Hz |
| < 0.10 | 880 Hz contínuo pulsado 4 Hz, `g .26` | 700 Hz | −45 cents | 2.0 Hz, + `tanh(1.6)` |

Batimento: `sine f: 62→38 / 0.10 exp`, `env(.002,.07,0,.04)`, par de batidas separado por 0.14 s, `g 0.45`, bus `evento`.
Todos os parâmetros transicionam em 0.8 s (`setTargetAtTime`, τ = 0.27).
Acima do limiar: desligar em 1.2 s. Respeita `movimento_reduzido` (mantém o alarme, remove o detune).

---

### 5.10 `torre_caiu` — game over (4.0 s + 1.2 s de silêncio)

Sequência agendada em tempo absoluto a partir de `t0 = ctx.currentTime + 0.02`:

| t (s) | Evento |
|---:|---|
| 0.00 | Música: `playbackRate`/detune −700 cents em 1.6 s (`exponentialRamp`); `musLP` 8000 → 180 Hz em 1.6 s; `bus.musica` −∞ em 1.9 s; parar às 2.1 s |
| 0.00 | Duck: `tiro`, `impacto`, `ouro` → −24 dB (atk 0.02, hold 3.0, rel 1.0) |
| 0.05 | Queda sub: `sine f: 90→22 / 2.0 exp`, `env(.004, 1.4, 0.15, 0.6)`, `g 0.90`, `tanh(1.6)` |
| 0.10 | Estilhaço: `ruido branco → LPF f: 6000→260 / 1.4 exp`, `env(.003, .8, .1, .5)`, `g 0.55`, envio `longo −6 dB` |
| 0.20–2.00 | Escombros: 14 grãos de ruído, dur ∈ [20, 90] ms, `LPF 1200`, ganho decrescente `0.35·(1 − i/14)^1.5`, tempos = 0.2 + 1.8·(i/14)^1.6 + jitter ±40 ms |
| 1.40 | Acorde final: 3 `sawtooth` (K=16) na tríade menor sobre `raizEra − 24 st`, detune `−35, 0, +35` cents, `env(0.25, 0.5, 0.6, 3.5)`, `LPF 1800 Q .8`, `g 0.40`, envio `longo −4 dB` |
| 4.00 | Silêncio absoluto até 5.2 s (nenhum SFX de UI permitido; fila suspensa) |

Pico do bloco −5.0 dBFS. Bus `evento`.

### 5.11 `torre_renasceu`

`t0`: swell reverso — `ruido rosa → BPF f: 200→4000 / 0.9 exp, Q 2`, `env(0.85, 0.05, 0, 0.10)`, `g 0.40`.
`t0+0.90`: fanfarra 3 notas ascendentes da escala da era (graus 0, 2, 4), `triangle+sine`, espaçamento 0.10 s, `env(.004,.12,.4,.5)`, `g 0.5`, envio `curto −12 dB`.
`t0+0.95`: música reinicia com `musLP` abrindo 400 → 6000 Hz em 1.5 s, no BPM anterior, `intensidade` forçada a 0.35 por 4 compassos.
`dur 2.2 s` · pico −8 dBFS.

---

## 6. Especificação som a som — economia e progressão

### 6.1 `ouro` (evento `ouro_ganho` / `moeda_ganha`)

**O prazer repetido. Precisa ser leve, curto, e subir.**

| Camada | Especificação |
|---|---|
| Fundamental | `sine`, `f = 1046.50 Hz (C6)`, `env(0.0020, 0.030, 0.55, 0.050)`, `g 0.32` |
| Quinta | `sine`, `f × 1.5 (1569.8 Hz)`, mesmo env, `g 0.20` |
| Oitava | `sine`, `f × 2`, `env(0.0020, 0.020, 0.30, 0.035)`, `g 0.10` |
| Corpo | `triangle`, `f × 0.5`, `env(0.0015, 0.025, 0, 0.02)`, `g 0.12` |
| Corte | `highpass 400 Hz Q .707` |

`dur 0.16 s` · `pico −14.0 dBFS` · bus `ouro` · envio `curto −28 dB`

**Escada de streak** (reinicia após **900 ms** sem coleta):
```
i        = Math.min(streak, 14);
escala   = eraAtual.musica.escala;
semitons = Math.min(24, escala[i % escala.length] + 12*Math.floor(i/escala.length));
playbackRate = Math.pow(2, semitons/12);
ganho    = lin(-14) * (0.85 + 0.20 * i/14);
pan      = clamp((x_moeda - x_torre)/(w*0.5) * 0.7, -0.7, 0.7);
```
**Polifonia 8 · cooldown 18 ms · prioridade 3**

**`ouro_chuva` — agregação obrigatória.** Se a janela deslizante de 100 ms acumular **≥ 12** coletas, cancelar as vozes individuais e tocar 1× `ouro_chuva`:
> 24 grãos `sine`, dur 18 ms cada, `f` sorteada em [1200, 3600] Hz (distribuição log-uniforme), tempos = `0.26 · (i/24)^0.8 + jitter ±6 ms`, `env(.001,.012,0,.005)`, `g 0.18/√24`, `pan` sorteado em [−0.8, 0.8], envio `curto −16 dB`. `dur 0.30 s`, pico −11 dBFS.
Cooldown de `ouro_chuva`: 260 ms. Enquanto ativo, `ouro` individual fica mudo.

### 6.2 `upgrade` (evento `upgrade_comprado(id, quantidade, nivel)`)

| t (s) | Camada |
|---:|---|
| 0.000 | Mecânica: `ruido branco → BPF 1800 Q 3`, `env(.0008,.030,0,.015)`, `g 0.35` |
| 0.005 | Thump: `sine f: 130→82 / 0.09 exp`, `env(.002,.06,0,.03)`, `g 0.40` |
| 0.030 | Nota 1: `triangle 523.25 Hz (C5)` + `sine` 1 oitava acima a `g×0.4`, `env(.003,.05,.45,.12)`, `g 0.42` |
| 0.100 | Nota 2: `triangle 783.99 Hz (G5)` (quinta justa), idem, `g 0.42` |

`dur 0.45 s` · `pico −10.0 dBFS` · bus `evento` · envio `curto −20 dB`
**Marcos** (ao vivo, sobreposto): `nivel % 10 == 0` → + `Nota 3 = 1046.5 Hz` em t=0.170 e envio `curto −12 dB`; `nivel % 25 == 0` → + oitava a 2093 Hz e `eco −18 dB`; `nivel % 100 == 0` → dispara `nivel_subiu` completo (§6.4).
**Compra múltipla (`quantidade > 1`):** NÃO repetir n vezes. Tocar uma vez com um arpejo de `min(quantidade, 5)` notas ascendendo a escala da era, espaçamento `max(0.035, 0.09 − 0.01·quantidade)` s, e `ganho × min(1.5, 1 + 0.10·log2(quantidade))`.
**Polifonia 2 · cooldown 60 ms · prio 6**

### 6.3 `negado` — compra bloqueada / ouro insuficiente

| Camada | Especificação |
|---|---|
| Dissonância | `square` (K=8) 138.59 Hz (C#3) **+** `square` 146.83 Hz (D3) — segunda menor, batimento de 8.2 Hz natural, `env(.002,.05,.45,.06)`, `g 0.30` cada |
| Tremolo | AM `sine 22 Hz`, profundidade 0.50 |
| Deslize final | ambas caem para `×0.84` (−3 st) entre t=0.10 e t=0.20 (`exp`) |
| Filtro | `lowpass 900 Hz Q 1.0` (abafado = "não") |

`dur 0.22 s` · `pico −16.0 dBFS` · bus `ui` · **sem reverb** (seco = negação)
**Polifonia 1 (retriggering substitui) · cooldown 220 ms · prio 4**
Nunca aumenta de volume com repetição; ao 3.º "negado" em 2 s, atenua −4 dB (evita punir o jogador impaciente).

### 6.4 `nivel_subiu` (evento `nivel_subiu(nivel, pontos)`)

| t (s) | Camada |
|---:|---|
| 0.00 | Duck `musica` −4 dB (atk .02, hold .40, rel .30) |
| 0.00 | Sub: `sine f: 96→70 / 0.20`, `env(.003,.10,0,.08)`, `g 0.45` |
| 0.00 / 0.09 / 0.18 / 0.27 | Arpejo 4 notas: graus `[0, 2, 4, 7]` da escala da era + 24 st (registro brilhante), timbre `triangle` + `sine` (mix 0.7/0.3), cada `env(.003, .07, .40, .50)`, `g 0.40` |
| 0.10 | Cintilância: `parciais(2093, [1, 1.4983, 2.0], [0.9, 0.75, 0.6], [.16,.12,.09], ±11 c)`, ataque 0.030 s, envio `curto −10 dB` |

`dur 1.40 s` · `pico −8.0 dBFS` · bus `evento` · envio `curto −10 dB`, `eco −20 dB`
**Polifonia 1 · cooldown 400 ms · prio 7**

### 6.5 `carta_caiu` — drop, escalado por raridade (`data/rarities.json`)

Raiz `R` = tônica da era + 12 st (registro médio-agudo). Graus em semitons **absolutos** (não da escala) para garantir consonância universal.

| Raridade | Notas (st sobre R) | Vozes / timbre | dur | Envio curto | Extras obrigatórios |
|---|---|---|---:|---:|---|
| `comum` `#9aa5b1` | `[0]` | 1 × `sine` | 0.35 s | −30 dB | — · pico −20 dBFS |
| `incomum` `#4ade80` | `[0, 7]` | 2 × `triangle` | 0.55 s | −24 dB | 1 cintilância `sine 3136 Hz` d 0.4 s · pico −17 |
| `raro` `#38bdf8` | `[0, 4, 7]` | 3 × `triangle`+`sine` | 0.90 s | −18 dB | `parciais(2637, sino, decai×0.6)`; `eco 1/8 fb .30 −20 dB` · pico −14 |
| `epico` `#c084fc` | `[0, 4, 7, 11]` | 4 × `saw` (K=24) → `LPF f: 600→5200/0.6 exp, Q 1.2` | 1.60 s | −12 dB | **riser 0.50 s antes** (`ruido rosa → BPF 300→6000, g 0→.4`); duck `musica` −5 dB/1.2 s · pico −11 |
| `lendario` `#fbbf24` | `[0, 4, 7, 11, 14]` + oitava | 6 (4 saw + 2 sine) | 2.80 s | −8 dB | **silêncio 120 ms antes** (duck total −40 dB); `parciais(R·2, sino, [2.4,1.9,1.5,1.2,0.9,0.7], ±14 c)`; duck `musica` −10 dB/1.6 s; **música pausa 1 compasso**; `eco 3/16 fb .38 −12 dB` · pico −7 |
| `mitico` `#fb7185` | `[0, 5, 7, 12, 17, 19]` (quartal) | 9 (6 saw detune ±7/±14/±21 c + 3 sine) | 4.20 s | −5 dB | **silêncio 200 ms**; sub `sine 33 Hz` `env(.05,2.0,.4,1.5)` `g .7`; **swell reverso 0.80 s** (ataque 0.75 s no pad); coro: 8 saw sobre a tríade, `LPF 400→6000/2.0`; duck geral −14 dB/2.4 s; **música muda para modo lídio (grau 4 elevado) por 8 compassos** · pico −4 |

Todos ao vivo (não assados). Bus `evento`. Prioridade: comum 3 · incomum 4 · raro 6 · épico 8 · lendário 9 · mítico 10.
**Cooldown:** 150 ms (comum/incomum), 400 ms (raro), 900 ms (épico+). Épico+ nunca é roubado.

### 6.6 `alerta_onda` (evento `onda_iniciou(onda, eh_chefe)`)

| Caso | Especificação |
|---|---|
| Normal | 2 blips: `square (K=12)` 880 Hz e 1174.66 Hz, dur 0.07 s cada, espaçamento 0.11 s, `LPF 3000 Q .8`, `env(.002,.030,.35,.04)`, `g .35` · `dur 0.30 s` · pico −20 dBFS |
| `onda % 5 == 0` | 3 blips ascendentes 880 / 1174.66 / 1567.98 Hz, espaçamento 0.09 s · pico −18 |
| `onda % 25 == 0` | acima + trompa grave `saw 87.31 Hz` (F2), 3 vozes detune ±10 c, `LPF 500→1400/0.4`, `env(.02,.25,.5,.35)`, dur 0.60 s, envio `longo −16 dB` · pico −14 |
| `eh_chefe` | não toca; dispara `chefe_surgiu` (§7.1) |

Bus `ui` (normal) / `evento` (marcos). **Polifonia 1 · cooldown 500 ms · prio 7**

### 6.7 `onda_limpa(onda, tempo)`

Sem SFX dedicado: a **música** executa a cadência de vitória (§12.7). Se `tempo < tempoRecorde`, adicionar sino: `parciais(1568, [1,2,2.4], [.7,.5,.4], [.22,.15,.10])`, `−16 dBFS`, envio `curto −14 dB`.

### 6.8 `conquista_desbloqueada` / `missao_concluida`

Fanfarra curta: 3 notas `[0, 4, 7]` sobre `R`, `triangle`, espaçamento 0.075 s, `env(.003,.06,.4,.35)`, `g .38`, + cintilância `sine 3136/4186 Hz` d 0.5 s `g .10`.
`dur 0.80 s` · pico −12 dBFS · bus `evento` · envio `curto −14 dB` · duck `musica` −3 dB/0.5 s.
**Fila:** conquistas simultâneas são espaçadas 0.42 s e transpostas +2 graus da escala a cada uma (máx +12 st) — cria a "escada de conquistas".

---

## 7. Especificação som a som — chefes e prestígio

### 7.1 `chefe_surgiu` — 2.60 s

Todos os tempos relativos a `t0 = ctx.currentTime + 0.02`.

| t (s) | Camada |
|---:|---|
| 0.00 | Duck `musica` −9 dB, `tiro` −6 dB, `impacto` −4 dB (atk .05, hold 2.0, rel .60) |
| 0.00 | Riser sub: `sine f: 30→55 / 2.20 lin`, `env(0.60, 0.0, 1.0, 0.25)`, `g 0.55` |
| 0.00 | Riser ruído: `rosa → BPF f: 200→5000 / 2.20 exp, Q 3`, ganho `0 → 0.50` linear em 2.2 s |
| 0.00 | Trompa A: 3 × `saw (K=32)` a 58.27 Hz (Bb1), detune `−9/0/+9` c, `LPF f: 420→1800 / 0.80 exp, Q 1.1`, `env(.020, .12, .70, .25)`, dur 0.55 s, `g 0.55` |
| 0.75 | Trompa B: idem, `f × 1.5` (87.4 Hz), dur 0.90 s, `g 0.60` |
| 2.20 | Gongo: `parciais(92, gongo, [3.5, 2.8, 2.2, 1.7, 1.2], [.34,.24,.18,.13,.09], ±20 c)` + `ruido branco → LPF 4000→400/0.5` `g .40`; envio `longo −3 dB`, `tanh(1.5)` |
| 2.20 | Música: `intensidade` forçada a ≥ 0.85, progressão trocada para `D` (estática), meio-tempo na bateria |

Pico −4.0 dBFS · bus `evento` · **prioridade 9, nunca roubado**

### 7.2 `chefe_fase(e, fase)` — transição de fase

`t0`: duck geral −12 dB por 0.35 s; `parciais(146.83, gongo, [1.6,1.2,.9,.7,.5], [.30,.20,.15,.10,.07])`; + `ruido → BPF 900→2600/0.4 Q 4` `g .35`; + sub `sine 41→28/0.5` `g .5`.
`dur 1.6 s` · pico −7 dBFS · música: sobe 1 camada e transpõe +2 st por fase (máx +6).

### 7.3 `chefe_morreu` — 4.5 s, o clímax

| t (s) | Camada |
|---:|---|
| 0.000 | **Hitstop de áudio:** todos os buses exceto `evento` → −18 dB em 15 ms, hold 180 ms, volta em 350 ms |
| 0.020 | Queda sub: `sine f: 120→28 / 1.60 exp`, `env(.004, 1.20, 0.10, 2.20)`, `g 0.90`, `tanh(1.8)` |
| 0.050 | Explosão: `ruido branco → LPF f: 6000→300 / 1.20 exp, Q .9`, `env(.003, .45, .12, .90)`, `g 0.70`, envio `longo −6 dB` |
| 0.100 | Estilhaço metálico: `parciais(210, caos, decais ∈ [0.9, 2.4] lineares decrescentes, ganhos .30·(1/√i), ±20 c)` |
| 0.350 / 0.530 / 0.710 | Stinger descendente: 3 notas `saw+sub` nos graus `[4, 2, 0]` da escala da era em `raizEra − 12 st`, cada `env(.006,.14,.45,.50)`, `LPF 2200 Q 1`, `g 0.50` |
| 1.100 → 1.870 | Arpejo de recompensa: 8 notas ascendendo a pentatônica da era, espaçamento 0.11 s, `triangle`, `env(.003,.06,.35,.25)`, `g 0.38`, `eco 3/16 fb 0.35 −14 dB` |
| 2.200 | Pad coral: 6 × `saw` na tríade da tônica, detune `±7/±14/±21` c, `env(0.60, 0.40, 0.75, 1.20)`, `LPF f: 1800→4200 / 1.4`, `g 0.42`, envio `longo −8 dB` |
| 0.000 | Música: cadência de vitória (§12.7) + **break de 2 compassos** (bateria sai, pad faz swell), reentrada com fill |

Pico −3.0 dBFS · bus `evento` · **prioridade 10**

### 7.4 `prestigio_feito(camada, ganho_log)` — 6.0 s, o momento de ascensão

| t (s) | Fase |
|---:|---|
| **0.00 – 2.30** | **Ascensão.** (a) Riser de ruído: `rosa → BPF f: 120→9000 / 2.30 exp, Q 2.5`, ganho `0 → 0.65` linear. (b) **Shepard**: 3 × `saw (K=40)`, voz *i* começa em `raizEra · 2^i` (i = 0,1,2) e faz glissando **+12 st em 2.30 s** (`exponentialRamp`), com janela de amplitude cosseno levantado `w(p) = 0.5·(1 − cos(2π·((p + i/3) mod 1)))`, `p = t/2.30`, `g 0.30` cada; `LPF f: 800→7000 / 2.30`. (c) Sub pedal `sine 32.7 Hz` `g 0.35` constante. |
| **2.30 – 2.50** | **VAZIO.** Todos os buses → −60 dB em 5 ms; música **para** (não fade). 200 ms de silêncio absoluto. Nenhum SFX aceito nesta janela (fila descartada, não bufferizada). |
| **2.50** | **Impacto.** (a) `sine f: 65→32 / 1.20 exp`, `env(.004, 0.9, 0.15, 1.6)`, `g 1.00`, `tanh(2.0)`. (b) `ruido branco → LPF f: 8000→200 / 0.90 exp`, `env(.003,.35,.10,.80)`, `g 0.75`, envio `longo −4 dB`. (c) `parciais(130.81, gongo, [4.0, 3.2, 2.5, 1.9, 1.4], [.34,.24,.17,.12,.08], ±22 c)`. Buses voltam de −60 dB ao normal em 40 ms. |
| **2.90 – 6.00** | **Nova era.** Pad de 8 × `saw`, progressão **I – V – vi – IV** da *nova* tonalidade, 0.80 s por acorde; detune `±11` c em 3 cópias com delays de 12 / 17 / 23 ms (coro); `LPF f: 300→5000 / 2.00 exp, Q 0.9`; `env(0.35, 0.20, 0.85, 1.10)` por acorde; `g 0.45`; envio `longo −10 dB`. |
| **3.10** | Música reinicia: nova tonalidade (`raiz += [0,+5,+2,+7,+4,+9,+11,+3][camada % 8]`), BPM da era, `intensidade` iniciada em 0.20 e liberada em 4 compassos. |

Pico −2.5 dBFS · bus `evento` · **prioridade 10, imune a tudo**
Escala com a camada: `camada ≥ 2` → +2 vozes no Shepard e IR longo com `decai −0.3`; `camada ≥ 5` → silêncio da fase 2 vai a 320 ms.

### 7.5 `era_mudou(indice, era)`

Transição musical, sem SFX próprio além de: swell `ruido rosa → BPF 400→3000 / 1.2` `g .3` + `parciais(novaRaiz·4, sino, [1.8,1.4,1.0], [.2,.14,.10])`, `−12 dBFS`, envio `longo −8 dB`. A troca musical ocorre na próxima **fronteira de frase (4 compassos)** com crossfade de 4 compassos (§12.6).

---

## 8. Habilidades (evento `habilidade_usada(id, nivel)`)

Ganho base −8 dBFS, bus `evento`, prioridade 7, cooldown 120 ms, polifonia 3.
`nivel` modula: `ganho ×= 1 + 0.04·min(nivel,10)`; `envioCurto += min(6, nivel*0.6) dB`; `playbackRate ×= 1 − 0.012·min(nivel,8)` (mais grave = mais forte).

| id | Especificação | dur |
|---|---|---:|
| `hab_explosao` | `sine f: 70→30 / 1.1 exp` `env(.004,.55,.1,.5)` `g .85`; `ruido → LPF f: 5000→400 / 0.9` `env(.003,.30,.1,.6)` `g .65`; `tanh(2.2)`; envio `longo −8 dB` | 1.10 |
| `hab_gelo` | `parciais(1046, vidro, [1.4,1.1,.85,.65,.5], [.20,.15,.11,.08,.06], ±9 c)` com ataque 0.012; `ruido → HPF 6000` `env(.02,.35,.2,.4)` `g .30`; **música: `musLP` cai a 1800 Hz por 0.8 s e volta em 0.6 s**; `pitch` do pad −20 cents por 0.9 s | 1.40 |
| `hab_raio` | 6 estalos: `ruido → BPF 3000 Q 12`, `env(.0004,.014,0,.008)`, tempos aleatórios em [0, 120] ms, `g .5·(1 − i/6)`; + 3 × `sine 60 Hz` `env(.001,.05,0,.03)` `g .45` nos estalos 0/2/4; envio `curto −18 dB` | 0.45 |
| `hab_tempo` | Música: `playbackRate` **0.72** em 0.40 s (`setTargetAtTime` τ=0.13) e volta em 0.50 s; `musLP` 1200 Hz no vale; + `sine f: 900→300 / 0.7 exp` `env(.01,.35,.2,.3)` `g .40`; + `ruido reverso` (ataque 0.5 s) `g .25`. **Desativa o bend se `movimento_reduzido`** (mantém só o LPF) | 1.20 |
| `hab_cura` | Pad ascendente: 4 × `sine` nos graus `[0,4,7,12]`, `env(0.20,0.15,0.8,0.9)`, `LPF 700→4000/1.0`, `g .40`; + cintilância `parciais(3136, sino, ×0.5)`; envio `longo −12 dB` | 1.60 |
| `hab_pronta` (`habilidade_pronta`) | 2 blips `sine` 1568 / 2093 Hz, dur 0.05 s, espaçamento 0.08 s, `env(.002,.025,.3,.03)`, `g .28`, bus `ui`, pico −24 dBFS, **cooldown 400 ms**, coalescência: > 2 no mesmo frame → só o primeiro | 0.16 |

---

## 9. Interface (bus `ui`, nunca duckado exceto no vazio do prestígio)

| id | Especificação | dur | pico | cd | poli |
|---|---|---:|---:|---:|---:|
| `ui_click` | `ruido → BPF 4200 Q 5` `env(.0004,.006,0,.004)` `g .14`; + `sine 1046.5` `env(.001,.014,0,.008)` `g .10` | 0.05 | −26 | 30 ms | 3 |
| `ui_hover` | `sine 1760` `env(.001,.012,0,.008)` `g .08`; `HPF 900` | 0.04 | −34 | 60 ms | 2 |
| `ui_tab` | `square (K=8) 1568` `env(.001,.020,.2,.012)` `g .12`, `LPF 5000` | 0.05 | −28 | 50 ms | 2 |
| `ui_toggle_on` | blips `sine` 880 → 1318.5, 0.03 s cada, esp. 0.05 s | 0.11 | −26 | 80 ms | 2 |
| `ui_toggle_off` | idem invertido: 1318.5 → 880 | 0.11 | −27 | 80 ms | 2 |
| `ui_painel_abrir` | `ruido rosa → BPF f: 400→2600 / 0.18 exp, Q 1.6` `env(.010,.09,.2,.06)` `g .28`; + `triangle 300 Hz` `g .10` | 0.22 | −24 | 120 ms | 1 |
| `ui_painel_fechar` | idem com `f: 2600→400` e `env(.006,.10,0,.05)` | 0.22 | −26 | 120 ms | 1 |
| `ui_slider` | `sine 2200` `env(.0006,.006,0,.003)` `g .06` — 1 tique por passo de 5 % | 0.010 | −38 | 25 ms | 2 |
| `ui_toast` (`aviso`) | `info`: `sine 1318` 0.05 s, −30 · `bom`: 2 notas 1046→1568, −26 · `ruim`: `square 220+233` (2ª menor) 0.14 s `LPF 1200`, −24 · `epico`: usa `carta_caiu:raro` | var. | var. | 200 ms | 1 |
| `ui_tutorial` (`tutorial_passo`) | `sine 784 → 1046`, 2 notas 0.06 s, −30 dBFS | 0.15 | −30 | 500 ms | 1 |

**Regra de anti-fadiga de UI:** ao arrastar um slider, o tique é emitido apenas em cruzamentos de 5 %; ao rolar listas, `ui_hover` é suprimido enquanto `|velocidadeScroll| > 200 px/s`.

---

## 10. Mapeamento de eventos (`Bus` → áudio)

Assinaturas idênticas às de `scripts/core/event_bus.gd`.

| Sinal | Som | Observações |
|---|---|---|
| `torre_atirou(angulo, quantidade)` | `tiro_leve` × min(quantidade, 3) com pan por `angulo`, esp. 12 ms; ou `feixe` se cadência ≥ 14/s | Cadência medida em janela de 500 ms |
| `inimigo_atingido(e, dano_log, critico, elemento)` | `impacto` (+ `elem_*`) e, se `critico`, `impacto_critico` | `dano_log` → `playbackRate` (§5.4) |
| `inimigo_morreu(e, ouro_log)` | `morte_<classe>` | agenda `ouro` no impacto do coletável, não aqui |
| `inimigo_surgiu(e)` | `surgir` | mudo se `nInimigos > 60` |
| `inimigo_chegou(e, dano)` | `dano_torre` | |
| `chefe_surgiu(e)` / `chefe_fase` / `chefe_morreu` | §7.1 / §7.2 / §7.3 | |
| `overkill(e, fracao)` | camada de overkill se `fracao ≥ 3` | |
| `combo_mudou(valor)` | atualiza a escada do crítico | sem som próprio |
| `combo_quebrou()` | `combo_fim` | |
| `torre_atingida(dano, vida, vida_max)` | `dano_torre` + estados de perigo (§5.9.1) | |
| `torre_caiu()` / `torre_renasceu()` | §5.10 / §5.11 | |
| `ouro_ganho(valor_log, fonte)` / `moeda_ganha` | `ouro` com escada; `ouro_chuva` se ≥ 12/100 ms | `fonte == 'offline'` ⇒ tocar 1× `ouro_chuva` |
| `upgrade_comprado(id, quantidade, nivel)` | `upgrade` (+ marcos) | |
| `talento_comprado(id, nivel)` | `upgrade` com `playbackRate ×1.12` e envio `curto −14 dB` | |
| `carta_caiu(instancia)` | `carta_caiu:<raridade>` (§6.5) | |
| `carta_equipada(uid, slot)` | `ui_toggle_on` + `parciais(1568, sino, ×0.4)` −22 dBFS | |
| `onda_iniciou(onda, eh_chefe)` | `alerta_onda` ou `chefe_surgiu` | |
| `onda_limpa(onda, tempo)` | cadência musical (§12.7) | |
| `onda_falhou(onda)` | `negado` grave (`playbackRate 0.7`) + duck −6 dB/0.6 s | |
| `nivel_subiu(nivel, pontos)` | §6.4 | |
| `conquista_desbloqueada` / `missao_concluida` | §6.8 | fila de 0.42 s |
| `prestigio_feito(camada, ganho_log)` | §7.4 | |
| `era_mudou(indice, era)` | §7.5 + troca musical | |
| `desafio_iniciado/concluido` | `alerta_onda` marco / fanfarra §6.8 | |
| `evento_sorteado(evento)` | `parciais(880, sino)` −18 dBFS + duck −4 dB | |
| `desbloqueio(chave)` | `carta_caiu:raro` | |
| `habilidade_usada(id, nivel)` / `habilidade_pronta(id)` | §8 | |
| `nivel_subiu`, `celebracao(tipo, dados)` | `tipo` mapeia direto para o id de som | |
| `painel_aberto(nome)` / `tela_mudou(nome)` | `ui_painel_abrir` | |
| `config_mudou(chave, valor)` | reaplicar mixagem se `chave ∈ {vol_*, mudo, qualidade}`; tocar `ui_slider` | |
| `jogo_salvo(bytes)` | `ui_click` a −40 dBFS (quase subliminar) | apenas se `dicas == true` |
| `relatorio_offline(dados)` | `ouro_chuva` + `nivel_subiu` se houve level | |
| `hitstop_pedido(ms)` | duck `tiro`+`impacto` em −10 dB por `ms` | acopla áudio ao juice visual |
| `camera_lenta(escala, ms)` | música `playbackRate = escala` por `ms` (ignorado se `movimento_reduzido`) | |

---

## 11. Mixagem

### 11.1 Volumes do usuário → ganho

Mapeamento **em dB** (perceptualmente linear), não linear puro:

```js
function volParaGanho(x /* 0..1 */) {
  if (x <= 0.001) return 0;                 // mudo real
  const dB = -48 * (1 - x);                  // x=1 → 0 dB · x=0.5 → -24 dB · x=0.1 → -43.2 dB
  return Math.pow(10, dB/20);
}
```
- `vol_master` (0.75 padrão) → `masterGain`
- `vol_sfx` (0.85) → `somaSFX`
- `vol_musica` (0.45) → `bus.musica`
- `vol_ui` (novo, 0.70) → `bus.ui`
- `mudo` → `masterGain` para 0 com rampa de **30 ms** (nunca `setValueAtTime`).
Toda mudança usa `setTargetAtTime(alvo, now, 0.012)` — sem cliques ao arrastar o slider.

### 11.2 Tabela de ducking

| Gatilho | Alvos | dB | atk (s) | hold (s) | rel (s) |
|---|---|---:|---:|---:|---:|
| Kick da música (sidechain) | `musica.pad`, `.arpejo`, `.lead` | −5.2 (→0.55) | 0.012 | 0 | 0.055 (τ) |
| `chefe_surgiu` | `musica`/`tiro`/`impacto` | −9 / −6 / −4 | 0.050 | 2.00 | 0.60 |
| `chefe_fase` | todos exceto `evento` | −12 | 0.020 | 0.35 | 0.40 |
| `chefe_morreu` | todos exceto `evento` | −18 | 0.015 | 0.20 | 0.35 |
| `prestigio` fase 2 | **todos** | −60 | 0.005 | 0.20 | 0.040 |
| `nivel_subiu` | `musica` | −4 | 0.020 | 0.40 | 0.30 |
| `carta_caiu:epico` | `musica` | −5 | 0.020 | 1.20 | 0.50 |
| `carta_caiu:lendario` | `musica`, `tiro` | −10 | 0.020 | 1.60 | 0.55 |
| `carta_caiu:mitico` | todos exceto `evento` | −14 | 0.020 | 2.40 | 0.70 |
| `overkill` | `tiro`, `impacto` | −10 | 0.008 | 0.09 | 0.12 |
| `hitstop_pedido(ms)` | `tiro`, `impacto` | −10 | 0.006 | ms/1000 | 0.10 |
| `torre_caiu` | `tiro`, `impacto`, `ouro` | −24 | 0.020 | 3.00 | 1.00 |
| `alerta_onda` marco | `musica` | −3 | 0.030 | 0.50 | 0.35 |

Implementação: cada bus tem um `GainNode` **de duck** em série com o de volume. Ducks concorrentes tomam o **mínimo** (mais agressivo vence), com uma pilha por bus e reavaliação a cada mudança.

### 11.3 Plano espectral (evita mascaramento)

| Faixa | Ocupantes exclusivos | Regra |
|---|---|---|
| 18–45 Hz | sub de chefe, prestígio, game over | Tudo o mais leva `HPF 30 Hz` |
| 45–120 Hz | kick, `tiro_pesado`, `dano_torre` | Kick sidechaina o baixo |
| 120–400 Hz | baixo musical, corpo dos inimigos | Pad leva `HPF 220 Hz` |
| 400–1200 Hz | pad, mortes | — |
| 1.2–4 kHz | **impactos, ouro, arpejo** (banda de ação) | **Notch dinâmico:** quando a taxa de impactos > 6/s, o arpejo recebe `peaking f=2200, Q=1.4, gain = −4·min(1, (taxa−6)/10) dB`, τ=0.25 s |
| 4–12 kHz | críticos, hats, UI, brilho | UI tem prioridade; hats recuam −3 dB quando `ui` está ativo |
| > 12 kHz | ar/cintilância apenas | `LPF 17.5 kHz` no master |

### 11.4 Panorâmica

`StereoPannerNode` (não `PannerNode` — 3× mais barato).
`pan = clamp((x_mundo − x_torre) / (largura/2) × 0.70, −0.70, 0.70)`. Nunca ±1.0 (fadiga em fone).
`bus.ui` sempre `pan = 0`. `evento` sempre `pan = 0`. Música: pad e lead espalhados por delays de 12/17/23 ms (Haas), não por pan.
**Modo mono** (acessibilidade): `ChannelMergerNode` + ganho `0.7071` antes do master.

---

## 12. Música adaptativa procedural

### 12.1 Relógio (lookahead scheduler)

```
INTERVALO_TICK   = 25 ms   (worker ou setTimeout)
JANELA_AGENDA    = 0.120 s (agendar tudo que cair até currentTime + 0.120)
```
A cada tick: `while (proximoEventoTempo < ctx.currentTime + 0.120) { agendar(); avancar(); }`.
**Nada** depende do timer para soar — todo `start()`/`setValueAtTime` recebe tempo absoluto.

Worker inline (Blob), com fallback:
```js
let relogio;
try {
  const src = "let id=null;onmessage=e=>{if(e.data==='ini'){id=setInterval(()=>postMessage('t'),25)}else{clearInterval(id)}}";
  relogio = new Worker(URL.createObjectURL(new Blob([src], {type:'text/javascript'})));
} catch { relogio = null; }   // file:// → cair para setTimeout(25)
```
Justificativa: `setTimeout` em aba oculta é limitado a 1000 ms; o Worker mantém 25 ms na maioria dos navegadores. Como suspendemos o áudio após 20 s ocultos, a divergência é irrelevante — mas o Worker evita gagueira nos primeiros 20 s.

### 12.2 Grade

- Compasso 4/4; subdivisão mínima **1/16**; `duracaoSemicolcheia = 60 / bpm / 4` s.
- 1 compasso = 16 passos · 1 frase = 4 compassos (64 passos) · 1 seção = 8 compassos (128 passos).
- **Swing:** `s = (bpm >= 120) ? 0 : 0.08`. Passos ímpares de 1/16 atrasam `s · duracaoSemicolcheia`.
- Contador global `passo` monotônico; `compasso = floor(passo/16)`.

### 12.3 Tonalidade e escala por era (de `data/eras.json`)

| Era | onda | raiz MIDI | Hz | escala (`musica.escala`) | bpm | timbre | camadas máx |
|---|---:|---:|---:|---|---:|---|---:|
| `sucata` | 1 | 45 (A2) | 110.00 | 0,3,5,7,10 (menor pent.) | 76 | quadrada | 2 |
| `pantano` | 12 | 43 (G2) | 98.00 | 0,2,3,7,8 (frígia def.) | 84 | dente | 2 |
| `vidro` | 28 | 50 (D3) | 146.83 | 0,2,4,7,9 (maior pent.) | 92 | triangulo | 3 |
| `inverno` | 48 | 48 (C3) | 130.81 | 0,2,3,5,7,10 (dórica hex.) | 68 | senoide | 3 |
| `fundicao` | 75 | 41 (F2) | 87.31 | 0,1,4,5,7,8,11 (dupla harm.) | 128 | quadrada | 4 |
| `necropole` | 110 | 40 (E2) | 82.41 | 0,3,5,6,10 (blues) | 58 | senoide | 3 |
| `depuracao` | 155 | 46 (A#2) | 116.54 | 0,2,4,6,8,10 (tons inteiros) | 140 | quadrada | 4 |
| `aurora` | 210 | 52 (E3) | 164.81 | 0,2,4,7,11 (lídia pent.) | 100 | triangulo | 5 |
| `jardim` | 320 | 45 (A2) | 110.00 | 0,1,3,7,8 (in sen japonesa) | 46 | senoide | 5 |
| `nada` | 500 | 36 (C2) | 65.41 | 0,5,7 (quartal) | 33 | senoide | 2 |

**Transposição por prestígio:** `raiz += [0, +5, +2, +7, +4, +9, +11, +3][camadaPrestigio % 8]` semitons (ciclo de quintas embaralhado — mantém tudo fresco por 8 corridas).

### 12.4 Harmonia

Acorde = 3 graus da escala empilhados a cada 2 posições no array (`[g, g+2, g+4]` mod tamanho, com +12 st a cada volta). Isso é **seguro em qualquer escala** (inclusive pentatônicas), gerando tríades ou empilhamentos quartais idiomáticos.

Progressões (índices de grau na escala, 1 acorde por compasso):

| id | Sequência | Caráter | Eras |
|---|---|---|---|
| `A` | `[0, 4, 3, 2]` | épica, resolutiva | sucata, inverno, jardim |
| `B` | `[0, 2, 3, 0]` | motora | fundicao |
| `C` | `[0, 3, 4, 2]` | melancólica | vidro |
| `D` | `[0, 0, 1, 0]` | estática, tensa | pantano, necropole, nada, **todo chefe** |
| `E` | `[0, 1, 2, 3]` | ascendente, alienígena | depuracao, aurora |

Uma progressão dura 4 compassos = 1 frase. A cada 4 frases (32 compassos), sorteio ponderado da próxima progressão dentro do conjunto permitido da era: 65 % a mesma, 35 % uma alternativa.

### 12.5 Camadas (ativação por intensidade)

```js
intensidade_alvo =
    0.25 * Math.min(1, nInimigos/40)
  + 0.30 * Math.min(1, dpsRecebido/(hpMax*0.125))
  + 0.25 * (1 - hpTorre/hpMax)
  + 0.20 * (chefeAtivo ? 1 : 0);
// suavização independente de fps: I += (alvo - I) * (1 - Math.exp(-0.8*dt))
// chefe força: I = Math.max(I, 0.85)
```

| # | Camada | Entra em | Sai em | Ganho | Especificação |
|---:|---|---:|---:|---:|---|
| 1 | `pad` | 0.00 | — | −18 dBFS | 3 × `PeriodicWave(timbreEra, K=24)` na tríade, detune `−8/0/+8` c, `env(0.45, 0.30, 0.85, 0.90)`, semibreve; `LPF f = 300 + 3200·I Hz, Q 0.7`; `HPF 220`; envio `longo −14 dB` |
| 2 | `baixo` | 0.08 | 0.04 | −12 dBFS | `sine` (fund.) + `triangle` (×2) na tônica do acorde, oitava `raiz−12`; padrão por bpm: <80 → semínimas em 1,3; 80–119 → 1,2.5,3,4; ≥120 → colcheias; `env(.004, .10, .60, .12)`, comprimento 0.9 do passo; sidechain do kick |
| 3 | `arpejo` | 0.30 | 0.24 | −20 dBFS | 1/16, padrão **up-down** sobre `[acorde ∪ 2 notas de passagem da escala]`, 8 posições; timbre da era, `env(.002,.035,.25,.06)`; `LPF f = 900 + 4500·I, Q 1.3`; `eco 3/16 fb 0.28 −16 dB`; notch dinâmico (§11.3) |
| 4 | `percussao` | 0.45 | 0.38 | −22 dBFS | **kick**: `sine f: 120→45 / 0.06 exp`, `env(.001,.075,0,.03)`, `g .8` — passos 0 e 8 (+ passo 14 se I>0.70). **caixa**: `ruido → BPF 1900 Q 1.2` `g .5` + `triangle 190` `g .25`, `env(.001,.09,0,.04)` — passos 4 e 12. **chimbal**: `ruido → HPF 7000` `env(.0005,.022,0,.012)`, `g .30` — a cada 2 passos (a cada 1 se I>0.75), velocidade 0.6 nos passos ímpares |
| 5 | `lead` | 0.62 | 0.55 | −16 dBFS | Melodia por passeio aleatório semeado (§12.5.1) |
| 6 | `tensao` | 0.82 | 0.74 | −26 dBFS | Cluster sustentado: `raiz`, `raiz+6` (trítono), `raiz+13` (9ª menor), 2 `saw` cada detune ±6 c, `env(0.5,0.3,0.9,0.8)`, `LPF 1600`; + pulso `ruido → BPF 3000 Q 8` em cada semínima, `g .18` |

Limite superior de camadas = `era.musica.camadas` **e** `qualidade` (baixa → máx 3, média → 4, alta/ultra → 6).
Crossfade de entrada/saída = **1 compasso**, sempre alinhado à barra, `setTargetAtTime` com τ = duraçãoCompasso/3.

#### 12.5.1 Gerador de melodia (`lead`)

```
PRNG semeado com (idEra, indiceFrase, camadaPrestigio) → coerente e reprodutível.
Estado: grau atual g (índice na escala, faixa [0, 2*tam]).
Passo:  Δ ∈ {-2,-1,0,+1,+2} com pesos [0.08, 0.22, 0.18, 0.30, 0.22]
        (viés ascendente = sensação de progresso)
Restrições:
  - nos passos 0 e 8 do compasso, forçar g para o grau de acorde mais próximo
  - se |g - gInicial| > 7, inverter o sinal do próximo Δ (evita fuga de registro)
  - a cada 8 compassos, re-semear e voltar a gInicial (forma)
Ritmo: comprimentos sorteados de [4, 2, 2, 3, 8] passos de 1/16
       com pesos [0.25, 0.30, 0.20, 0.10, 0.15]
Timbre: PeriodicWave(timbreEra, K=32) + sine 1 oitava acima a 0.3
Env: (0.006, 0.08, 0.55, 0.22); LPF f = 1400 + 3600·I, Q 1.1; eco 3/16 −18 dB
```

#### 12.5.2 Fills

No último compasso de cada seção de 8, se `I ≥ 0.45`: rufo de caixa em 1/16 com velocidade rampando `0.30 → 1.00` linear e o corpo `triangle` subindo `+5 st` ao longo do compasso; kick suprimido nos 4 últimos passos; retomada no downbeat com kick + prato (`ruido → HPF 4000`, `env(.001, .8, 0, .4)`, `g .35`, envio `longo −10 dB`).

### 12.6 Transições

| Situação | Momento | Método |
|---|---|---|
| Camada entra/sai | próxima barra | crossfade 1 compasso |
| Progressão muda | próxima frase (4 compassos) | imediato na barra |
| Chefe aparece | próxima barra | progressão → `D`; bateria em meio-tempo (kick só no passo 0 e 8, caixa só no 8); + stab de metais no passo 0 de cada compasso (`3 × saw` na tônica, `env(.008,.09,.3,.15)`, `LPF 900→2600/0.15`, `g .35`) |
| Era muda | próxima **frase** | crossfade de **4 compassos**: era antiga com `musLP` 5000→800 Hz e ganho −∞; era nova com `musLP` 400→(normal) e ganho de −∞ ao alvo; ambas as grades tocam simultaneamente (o BPM da nova assume no compasso 3 via `setTargetAtTime` na duração do passo) |
| Prestígio | imediato (§7.4) | parada seca em t=2.30, reinício em t=3.10 |
| Aba volta do oculto | próxima barra | ressincronizar `passo` para o próximo múltiplo de 16 |

### 12.7 Cadência de vitória (`onda_limpa`)

No compasso seguinte, substituir a progressão por **ii – V – I** (graus `[1, 4, 0]` da escala, 2 semínimas / 2 semínimas / 1 compasso), com:
- camada `sino` temporária: `parciais(raiz·8, sino, [0.7,0.5,0.4,0.3], [.16,.11,.08,.06])` na tônica de cada acorde;
- `pad` com `LPF` +1200 Hz por 2 compassos;
- `lead` silenciado durante a cadência (deixa respirar).
Depois volta à progressão vigente.
**`chefe_morreu`:** cadência + **break de 2 compassos** (só pad, com swell `env(0.9, ...)`), reentrada com fill completo.

### 12.8 Orçamento de vozes musicais

Máximo **24 vozes simultâneas** na música. Contagem típica: pad 3, baixo 2, arpejo 2 (nota + eco), percussão 3, lead 2, tensão 6 → 18. Agendamento **de 1 passo à frente apenas**; qualquer nota já agendada além da janela é cancelada em transições (`cancelScheduledValues` + `stop`).

---

## 13. Gerenciamento de vozes e performance

### 13.1 Orçamento

| `qualidade` | Vozes SFX | Vozes música | Convolvers | Ruído | Variantes |
|---|---:|---:|---|---|---|
| 0 baixa | 12 | 10 | nenhum (eco multi-tap) | rosa mono | ×0.5 |
| 1 média | 20 | 16 | só `curto` | rosa mono | ×0.5 |
| 2 alta | 32 | 24 | `curto` + `longo` | estéreo | ×1.0 |
| 3 ultra | 48 | 24 | `curto` + `longo` (IR longo 3.6 s) | estéreo | ×1.0 |

**Auto-perfil mobile:** se `navigator.hardwareConcurrency <= 4` **ou** `matchMedia('(pointer: coarse)').matches` → limitar `qualidade` de áudio a 1 no primeiro boot (o usuário pode subir).

### 13.2 Pesos de custo (unidades relativas, para o orçamento)

| Nó | Peso |
|---|---:|
| `GainNode` | 1 |
| `AudioBufferSourceNode` | 2 |
| `StereoPannerNode` | 2 |
| `BiquadFilterNode` | 3 |
| `OscillatorNode` | 4 |
| `DelayNode` | 3 |
| `WaveShaperNode` (2x) | 8 |
| `DynamicsCompressorNode` | 25 |
| `ConvolverNode` | **300 × duraçãoIR(s)** |

Fixo: 2 convolvers (270 + 840) + 4 compressores de bus + 2 do master (150) + filtros master (9) ≈ **1270**.
Voz assada: 2+1+2 = **5**. Voz ao vivo média: 4 osc + 3 biquad + 3 gain = **28**.
Música (18 vozes × ~9) ≈ **162**.
**Teto operacional:** ultra 3600 · alta 3000 · média 1500 · baixa 700. Ao ultrapassar, ativar as políticas de §13.4.

### 13.3 Pool e ciclo de vida

- `OscillatorNode` e `AudioBufferSourceNode` são *one-shot* por especificação — sempre novos. São baratos (alocação em pool de renderização do navegador); **não** tentar reciclá-los.
- **Reciclar** `GainNode`, `BiquadFilterNode`, `StereoPannerNode` e `WaveShaperNode` em pools por tipo (tamanho inicial: 48 gain, 24 biquad, 32 panner, 4 shaper). Ao devolver: `disconnect()`, `param.cancelScheduledValues(0)`, `param.value = padrão`.
- Toda voz registra `src.onended = () => liberar(voz)`. Adicionalmente, um **varredor** roda a cada 1.0 s e força a liberação de qualquer voz com `tFim + 0.25 < ctx.currentTime` (protege contra `onended` perdido em Safari).
- `ConvolverNode`, compressores e delays são **singletons**, nunca por voz.

### 13.4 Roubo de vozes (voice stealing)

```
tocar(chave, opts):
  1. se ctx não destravado → return
  2. se agora - ultimoToque[chave] < cooldown[chave] → return
  3. se contagem[chave] >= polifonia[chave]:
        roubar a voz mais antiga DESSA chave
  4. se vozesAtivas >= MAX_VOZES:
        alvo = voz mais antiga com prioridade <= prio(chave)
        se alvo existe → roubar
        senão se prio(chave) >= 8 → roubar a mais antiga, qualquer prioridade
        senão → DESCARTAR (não enfileirar)
  5. coalescer: se contadorFrame[chave] >= 3 → não criar voz;
        aplicar ganho *= min(2.2, sqrt(n)) e pan = média ± 0.25 na voz existente
  6. criar voz
```
Roubo = `gain.setTargetAtTime(1e-4, now, 0.004)` + `stop(now + 0.020)` — **nunca** `stop()` imediato (clique).

### 13.5 Prioridades (0 = descartável, 10 = sagrado)

| prio | Sons |
|---:|---|
| 0 | `ui_hover`, `surgir` |
| 1 | `impacto`, `elem_*` |
| 2 | `tiro_leve` |
| 3 | `ouro`, `tiro_laser`, `carta_caiu:comum` |
| 4 | `tiro_pesado`, `negado`, `carta_caiu:incomum` |
| 5 | `impacto_critico`, `morte_*` |
| 6 | `dano_torre`, `upgrade`, `carta_caiu:raro`, `morte_blindada` |
| 7 | `nivel_subiu`, `alerta_onda`, `hab_*`, `conquista` |
| 8 | `carta_caiu:epico`, `overkill` |
| 9 | `chefe_surgiu`, `chefe_fase`, `carta_caiu:lendario` |
| 10 | `chefe_morreu`, `prestigio_feito`, `torre_caiu`, `carta_caiu:mitico` |

### 13.6 Instrumentação

- Amostrar `AudioContext.renderCapacity` (quando disponível, Chrome) a 2 Hz; **alvo < 0.50**, alarme em 0.70 → derrubar 1 nível de `qualidade` de áudio automaticamente (com aviso via `Bus.toast`).
- Fallback universal: medir `performance.now()` do laço do agendador; se a média móvel (32 amostras) > 2.5 ms, degradar.
- Expor no painel de debug (`mostrar_fps`): `vozesAtivas / MAX`, `pesoTotal / teto`, `roubos/s`, `descartes/s`, `renderCapacity`, `ctx.state`, memória de buffers (MB).
- **Teste de estresse obrigatório:** 300 inimigos, 25 tiros/s, chefe ativo, música em I=0.95 → `renderCapacity < 0.55` em desktop de 2020 e `< 0.75` em mobile mediano.

---

## 14. Acessibilidade

| Ajuste | Chave | Efeito no áudio |
|---|---|---|
| Volume master / SFX / música / UI | `vol_master`, `vol_sfx`, `vol_musica`, `vol_ui` | §11.1, rampa 12 ms |
| Mudo | `mudo` | `masterGain → 0` em 30 ms; `ctx` **não** é suspenso (retomada instantânea) |
| Reduzir agudos | `audio_agudos_suaves` (novo) | `highshelf f=5000, gain=−6 dB, Q=0.7` no master — para hiperacusia/zumbido |
| Mono | `audio_mono` (novo) | merge estéreo → mono, ×0.7071 |
| Movimento reduzido | `movimento_reduzido` | desativa bends de pitch/tempo (`hab_tempo`, detune de perigo, bend do game over); mantém volumes e filtros |
| Faixa dinâmica reduzida | `audio_comprimido` (novo) | master glue vai a `ratio 6, thr −22`; ducks reduzidos a 40 % — para ambientes ruidosos/alto-falante de celular |
| Pistas sonoras distintas | `audio_descritivo` (novo) | cada classe de inimigo ganha `playbackRate` fixo e distinto no `surgir` (pequena 1.30, média 1.00, blindada 0.78, voadora 1.55, chefe 0.62); ping de radar `sine 1568 Hz`, 40 ms, 1×/s, panorâmico na direção do chefe |
| Vibração | `vibracao` | `navigator.vibrate` espelhando: impacto 8 ms · crítico [12] · morte de chefe [40,30,90] · prestígio [60,40,60,40,160] · negado [25,40,25] |

**Regra de fadiga (normativa):** nenhum som pode manter conteúdo acima de 4 kHz a mais de −12 dBFS por mais de 0.9 s contínuos. O único conteúdo contínuo permitido é o alarme de perigo, que é pulsado (duty ≤ 50 %).
**Regra fotossensível-análoga:** nada pulsa entre 3 e 12 Hz com profundidade > 0.6, exceto o alarme (fora dessa faixa por projeto: 2.5 Hz e 4 Hz).

---

## 15. API pública e arquivos

### 15.1 Estrutura

```
js/audio/contexto.js      — criação, destravamento, suspensão, estado
js/audio/barramentos.js   — grafo da §2, ducking, volumes
js/audio/primitivas.js    — env, PeriodicWave, ruído, FM, parciais, curvas
js/audio/ir.js            — geração de IR e eco multi-tap
js/audio/receitas.js      — TODAS as receitas como dado puro (§15.3)
js/audio/forno.js         — bake OfflineAudioContext + normalização
js/audio/vozes.js         — pool, prioridade, roubo, coalescência
js/audio/musica.js        — relógio, harmonia, camadas, transições
js/audio/relogio.js       — Worker inline + fallback
js/audio/index.js         — API + assinaturas do Bus
```

### 15.2 API

```js
await Audio.iniciar({ qualidade, cfg });     // cria ctx, assa, monta grafo
Audio.destravar();                            // chamado no 1º gesto
Audio.tocar(chave, {
  ganho = 1, tom = 0 /* semitons */, pan = 0, atraso = 0,
  prio, variante, envioCurto, envioLongo, dados
});
Audio.pararChave(chave, fade = 0.05);
Audio.duck(alvos[], dB, atk, hold, rel);
Audio.setVolume(qual, 0..1);
Audio.aplicarConfig(cfg);                     // reage a config_mudou
Audio.musica.iniciar() / .parar(fade)
Audio.musica.definirEra(idEra, { imediato = false })
Audio.musica.definirIntensidade(0..1)
Audio.musica.chefe(bool)
Audio.musica.cadenciaVitoria({ break: 0 })
Audio.musica.transpor(semitons)
Audio.diag()                                  // métricas da §13.6
```

### 15.3 Formato de receita (dado, não código)

```js
export const RECEITAS = {
  tiro_leve: {
    id: 'tiro_leve', dur: 0.12, picoDbfs: -9, variantes: 6,
    bus: 'tiro', prio: 2, poli: 6, cooldown: 0.028,
    envio: { curto: -26 },
    taxa: [0.94, 1.07], jitterGanho: [0.88, 1.06],
    camadas: [
      { tipo:'osc', onda:'quadrada_suja', K:24,
        f:[420,118,'exp',0.055], env:[0.0010,0.022,0,0.010], g:0.50, para:'A' },
      { tipo:'osc', onda:'senoide',
        f:[160,60,'exp',0.070],  env:[0.0015,0.030,0,0.012], g:0.35, para:'A' },
      { tipo:'ruido', cor:'branco',
        filtros:[{modo:'bandpass', f:2400, Q:1.2}],
        env:[0.0008,0.012,0,0.006], g:0.22, para:'S' },
      { tipo:'barramento', nome:'A',
        filtros:[{modo:'lowpass', f:[5200,1400,'exp',0.060], Q:0.9}], para:'S' },
      { tipo:'barramento', nome:'S',
        filtros:[{modo:'highpass', f:90, Q:0.707}], para:'out' },
    ],
    jitterBake: { f0: 0.06, Q: 0.30 }
  },
  // ...
};
```
O montador (`montarGrafo`) interpreta 6 tipos de nó: `osc`, `ruido`, `parciais`, `fm`, `barramento` (filtros/shaper/ganho), `sequencia` (lista de sub-receitas com `t` relativo). Isso cobre 100 % das receitas deste documento.

---

## 16. Validação e testes automáticos

| Teste | Critério de aceite |
|---|---|
| `pico` | Todo buffer assado tem `max(|x|) ∈ [0.98, 1.02] × lin(picoDbfs)` |
| `dc` | `|média(buffer)| < 0.002` (sem offset DC) |
| `clique` | `|x[0]| < 0.01` e `|x[N-1]| < 0.01` |
| `duracao` | `duração real ≤ receita.dur + 0.04` |
| `memoria` | soma dos buffers ≤ 4.0 MB (alta) / 2.8 MB (média) |
| `boot` | tempo de `Audio.iniciar()` ≤ 200 ms (desktop) / 550 ms (mobile) |
| `estresse` | 60 s com 25 tiros/s + 40 impactos/s + 20 ouros/s: `descartes/s < 5 % dos pedidos`, `vozesAtivas ≤ MAX`, zero vazamento (`vozesAtivas` volta a 0 em 3 s após parar) |
| `vazamento` | após 10 min de jogo, `pesoTotal` volta ao baseline ±5 % |
| `limitador` | true peak medido na saída ≤ −0.9 dBTP (oversample 4× offline) |
| `silencio_prestigio` | nenhuma amostra > 1e-3 na janela 2.30–2.50 s do prestígio (render offline) |
| `determinismo` | mesma semente ⇒ buffers byte-idênticos entre execuções |

---

## 17. Apêndice — ponte para o protótipo Godot deste repositório

O stub `/home/user/joabcostamd/torre-eterna/scripts/audio/audio_engine.gd` e `/home/user/joabcostamd/torre-eterna/audio_bus_layout.tres` (buses `Master`, `SFX`, `Musica`) podem hospedar a mesma especificação sem alterações de valores:

- **Buses:** acrescentar `Tiro`, `Impacto`, `Ouro`, `Evento`, `UI`, `Ambiente` com `send = SFX`, e os `volume_db` da tabela §2.1. Adicionar `AudioEffectCompressor` por bus com os mesmos parâmetros (Godot usa `threshold` em dB, `ratio`, `attack_us`, `release_ms`), `AudioEffectLimiter` no `Master` (`ceiling_db = -1.2`, `threshold_db = -1.2`), e `AudioEffectReverb`/`AudioEffectDelay` nos buses de envio.
- **Síntese:** `AudioStreamGenerator` (`mix_rate = 48000`, `buffer_length = 0.06`) + `AudioStreamGeneratorPlayback.push_buffer()` implementando as mesmas camadas; o "forno" da §4 vira `AudioStreamWAV` gerado em `_ready()` e reutilizado por `AudioStreamPlayer` em pool.
- **Eventos:** os nomes da §10 já correspondem exatamente aos sinais de `Bus`; a assinatura é `Bus.inimigo_atingido.connect(_on_atingido)` etc.
- **Config:** `Cfg.aplicar()` já ajusta `Master`, `SFX` e `Musica` via `linear_to_db()`; basta estender `_vol_bus()` para os novos buses e adicionar as chaves `vol_ui`, `audio_agudos_suaves`, `audio_mono`, `audio_comprimido`, `audio_descritivo` a `Cfg.PADRAO`.
- **Música:** o agendador da §12.1 vira um `Timer` de 25 ms com o mesmo `lookahead` de 0.12 s sobre `AudioServer.get_time_to_next_mix() + get_output_latency()`.