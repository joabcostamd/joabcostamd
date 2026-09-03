# TORRE ETERNA — Especificação Completa de Economia, Matemática e Balanceamento

> **Status:** todos os números abaixo foram **simulados numericamente** (simulador em `/tmp/claude-0/-home-user-joabcostamd/85265d4c-ecb1-5175-8151-a419aa622793/scratchpad/simG.mjs`, `tabG.mjs`, `tG.mjs`, `full.mjs`) com um comprador guloso ótimo. Os tempos de marco na §13 são saída real do simulador, não estimativa.
>
> **Marcos verificados:** 1º prestígio **onda 259 aos 40,3 min** · 2º prestígio **~5,5–6,1 h** · tempo de onda ~5–6,5 s do início até a onda 190, depois dobra a cada 20–35 ondas.

---

## 0. Resumo executivo — as 9 constantes que governam tudo

| Símbolo | Valor | Significado |
|---|---|---|
| `HG` | **1.118** | crescimento exponencial de HP por onda (+11,8 %/onda) |
| `HPW` | **0.9** | expoente polinomial de HP (`w^0.9`) — molda o começo |
| `ENDC`, `ENDW0` | **4.5e-5**, **90** | "endurecimento": `exp(ENDC·(w−ENDW0)²)` — cria o muro |
| `ALPHA` | **0.50** | ouro por inimigo = `KG · HP^ALPHA` |
| `KG` | **7.5** | coeficiente de ouro |
| `K_dps` | **1.3894** | soma de `ln(m)/ln(g)` das linhas multiplicativas de dano |
| `K_gold` | **0.1991** | idem para a linha de ouro |
| `K_eff` | **1.7348** | `K_dps/(1−K_gold)` — elasticidade DPS/ouro |
| `DPS_BASE` | **12.6** | DPS efetivo da torre nível 0 |

**Invariante de equilíbrio (a equação-mestra):**

```
α_equilíbrio = 1 / K_eff = 0.5764
```

Com `α = 0.50 < 0.5764`, o jogador **fica progressivamente para trás** — é isso que cria a parede e força o prestígio. A margem `1 − K_eff·α = 0.1326` é o "atraso por onda".

---

## 1. Equação-mestra da economia (derivação — leia antes de mexer em qualquer número)

Seja:
- `HP(w) = H0 · h^w · w^p` — HP do inimigo
- `Ouro(w) = kg · HP(w)^α` — ouro por inimigo
- Upgrade multiplicativo *i*: custo `base_i · g_i^n`, efeito `×m_i` por nível

**Passo 1 — quantos níveis o ouro compra.** Custo acumulado de *n* níveis é geométrico, dominado pelo último termo:
```
n_i(G) ≈ ln(G) / ln(g_i)
```
Ou seja, **os níveis crescem linearmente no logaritmo do ouro**.

**Passo 2 — DPS resultante.**
```
DPS ∝ Π m_i^{n_i} = exp( ln G · Σ ln(m_i)/ln(g_i) ) = G^{K_dps}
```
Defina `K_dps = Σ ln(m_i)/ln(g_i)`. **DPS é uma potência do ouro.**

**Passo 3 — realimentação da linha de ouro.** Uma linha "×ouro" com `K_gold = ln(m_ω)/ln(g_ω)` multiplica o próprio ouro:
```
G_ef = G_bruto · G_ef^{K_gold}  ⟹  G_ef = G_bruto^{1/(1−K_gold)}
K_eff = K_dps / (1 − K_gold)
```

**Passo 4 — condição de tempo de onda constante.**
```
T(w) = HP_onda(w) / DPS(w)
ln T(w) = w·ln h − K_eff·α·w·ln h = w·ln h·(1 − K_eff·α)
```
Logo:
- `α = 1/K_eff` → tempo de onda **constante para sempre** (jogo sem muro, ruim)
- `α > 1/K_eff` → **runaway**: ondas ficam cada vez mais rápidas (péssimo, quebra o jogo)
- `α < 1/K_eff` → **muro suave** ✅

**Passo 5 — inclinação da dificuldade.** Com o termo de endurecimento:
```
s(w) = (1 − K_eff·α)·ln(HG) + 2·ENDC·max(0, w − ENDW0)
     = 0.014779 + 9e-5·max(0, w − 90)
```
`s(w)` é a **taxa de crescimento do tempo de onda** e a moeda de troca de todo o jogo:

| onda | `s(w)` | ondas p/ dobrar o tempo | dano necessário p/ **+1 onda** |
|---|---|---|---|
| 100 | 0.01568 | 44,2 | ×1.0158 |
| 150 | 0.02018 | 34,3 | ×1.0204 |
| 200 | 0.02468 | 28,1 | ×1.0250 |
| 250 | 0.02918 | 23,8 | ×1.0296 |
| 300 | 0.03368 | 20,6 | ×1.0343 |
| 400 | 0.04268 | 16,2 | ×1.0436 |
| 500 | 0.05168 | 13,4 | ×1.0530 |
| 700 | 0.06968 | 9,9 | ×1.0722 |
| 1000 | 0.09668 | 7,2 | ×1.1015 |

> **Regra de ouro para todo design futuro:** *"quantas ondas isso me dá?"* = `ln(multiplicador) / s(onda_atual)`.
> Um ×10 de dano na onda 250 dá **+79 ondas**. O mesmo ×10 na onda 700 dá **+33 ondas**. Retornos decrescentes automáticos, sem gambiarra.

---

## 2. Classe `Big` — Decimal mantissa/expoente

### 2.1 Representação

```js
// scripts/core/big.js
// Representação canônica: { m, e }  com  1 ≤ |m| < 10  ou  (m === 0 && e === 0)
// m: Float64 (≈15,95 dígitos significativos)
// e: Float64 inteiro. Seguro até |e| ≤ 2^53. Na prática travamos em ±9e15.
```

**Decisão de arquitetura (crítica para 60 fps):** `Big` é **imutável** e alocado como objeto literal `{m,e}` (não classe com métodos de instância — V8 otimiza melhor e o GC de objetos pequenos monomórficos é barato). Todas as operações são **funções estáticas puras**.

### 2.2 API obrigatória

```js
// --- construção ---
Big.ZERO, Big.ONE, Big.TEN
Big.from(x)                 // number → Big
Big.fromME(m, e)            // normaliza
Big.fromLog10(L)            // 10^L → Big   (o construtor mais usado do jogo)
Big.parse(s)                // "1.2345e678" | "1234" → Big
Big.clone(a)

// --- aritmética ---
Big.add(a,b)  Big.sub(a,b)  Big.mul(a,b)  Big.div(a,b)
Big.mulF(a,f) Big.divF(a,f) Big.addF(a,f)     // f = Float64 nativo (caminho rápido)
Big.neg(a)    Big.abs(a)    Big.recip(a)
Big.pow(a,p)      // p ∈ ℝ
Big.pow10(x)      // = fromLog10
Big.sqrt(a)  Big.cbrt(a)
Big.log10(a) Big.ln(a) Big.logBase(a,b)
Big.exp(a)        // e^a  (só para |a| pequeno; usar fromLog10 no resto)

// --- comparação ---
Big.cmp(a,b)  // -1 | 0 | 1
Big.lt lte gt gte eq neq
Big.max(a,b)  Big.min(a,b)  Big.clamp(a,lo,hi)
Big.isZero(a) Big.isFinite(a) Big.sign(a)

// --- conversão / IO ---
Big.toNumber(a)     // clampa em ±Number.MAX_VALUE; NUNCA usar em hot loop
Big.toLog10(a)      // Float64 — a forma preferida de "medir" um Big
Big.ser(a)          // "m|e"  (string curta para localStorage)
Big.deser(s)
Big.fmt(a, opts)    // ver §3

// --- utilidades de economia (ESSENCIAIS) ---
Big.geomSum(base, g, L, n)   // custo de comprar n níveis a partir do nível L
Big.maxAffordable(base, g, L, ouro)  // quantos níveis dá para comprar
Big.softcap(a, limiar, expo)
```

### 2.3 Algoritmos de referência

```js
const LOG10 = Math.log(10);

function norm(m, e) {
  if (m === 0 || !isFinite(m)) return { m: 0, e: 0 };
  const l = Math.floor(Math.log10(Math.abs(m)));
  if (l !== 0) { m /= Math.pow(10, l); e += l; }
  // correção de borda por erro de ponto flutuante
  if (Math.abs(m) >= 10) { m /= 10; e += 1; }
  else if (Math.abs(m) < 1) { m *= 10; e -= 1; }
  return { m, e };
}

Big.add = (a, b) => {
  if (a.m === 0) return b;
  if (b.m === 0) return a;
  const d = a.e - b.e;
  if (d > 17) return a;          // b é irrelevante (além da precisão do Float64)
  if (d < -17) return b;
  return d >= 0
    ? norm(a.m + b.m * Math.pow(10, -d), a.e)
    : norm(b.m + a.m * Math.pow(10,  d), b.e);
};

Big.mul = (a, b) => norm(a.m * b.m, a.e + b.e);
Big.div = (a, b) => norm(a.m / b.m, a.e - b.e);
Big.log10 = (a) => Math.log10(Math.abs(a.m)) + a.e;
Big.fromLog10 = (L) => { const e = Math.floor(L); return { m: Math.pow(10, L - e), e }; };
Big.pow = (a, p) => Big.fromLog10(Big.log10(a) * p);
Big.sqrt = (a) => Big.fromLog10(Big.log10(a) * 0.5);
```

**Soma geométrica e compra-máxima** (usadas em *toda* tela de upgrade — precisam ser exatas):

```js
// custo total de comprar `n` níveis a partir do nível `L`:
//   base·g^L·(g^n − 1)/(g − 1)
Big.geomSum = (base, g, L, n) =>
  Big.mul(
    Big.fromLog10(Math.log10(base) + L * Math.log10(g)),
    Big.from((Math.pow(g, n) - 1) / (g - 1))
  );

// maior n tal que geomSum ≤ ouro:
//   n = floor( log_g( ouro·(g−1)/(base·g^L) + 1 ) )
Big.maxAffordable = (base, g, L, ouro) => {
  const razao = Big.toNumber(
    Big.div(Big.mulF(ouro, g - 1),
            Big.fromLog10(Math.log10(base) + L * Math.log10(g)))
  );
  if (!(razao > 0)) return 0;
  return Math.max(0, Math.floor(Math.log(razao + 1) / Math.log(g)));
};
```

> ⚠️ `Math.pow(g, n)` estoura em Float64 quando `n·log10(g) > 308`. Para `g = 1.18` isso é `n ≈ 3900` níveis — acima disso, use a forma logarítmica: `geomSumLog = log10(base) + L·log10(g) + n·log10(g) − log10(g−1)`.

### 2.4 REGRA DE PERFORMANCE (não negociável)

Com 300+ entidades a 60 fps, **`Big` não pode entrar no loop por entidade**.

| Grandeza | Tipo | Onde vive |
|---|---|---|
| posição, velocidade, ângulo, timers, partículas, alpha | `Float64` | por entidade |
| **HP do inimigo** | **`Float64` normalizado 0..1** | por entidade (`hpFrac`) |
| HP unitário da onda, dano por tiro, ouro, custos, multiplicadores | `Big` | **1 por onda / 1 por frame** |

**O truque central:** todos os inimigos de uma onda compartilham a mesma escala de HP. Guarde `onda.hpUnidade: Big` uma única vez e represente o HP de cada inimigo como `hpFrac ∈ [0, arquetipoMult]`. Converta o dano **uma vez por frame**:

```js
// 1× por frame, não 1× por inimigo:
const danoFrac = Big.toNumber(Big.div(stats.danoPorTiro, onda.hpUnidade));
// no loop de colisão (Float64 puro):
inimigo.hpFrac -= danoFrac * fatorArmadura * (critou ? critMult : 1);
```

Isso mantém o loop quente 100 % em `Float64` e ainda suporta HP de `1e68`. **Ganho medido esperado: 8–20× no loop de combate.**

### 2.5 Testes de aceitação da `Big`

```
1.  norm: |m| ∈ [1,10) para 10⁶ valores aleatórios em [1e-300, 1e300]
2.  associatividade: |((a+b)+c) − (a+(b+c))| / |a+b+c| < 1e-13
3.  mul/div: |div(mul(a,b),b) − a| / |a| < 1e-14
4.  pow: |pow(a,2) − mul(a,a)| / |a²| < 1e-13
5.  log10/fromLog10: round-trip com erro < 1e-12 para L ∈ [-1e6, 1e6]
6.  add com d > 17 retorna exatamente o maior operando (curto-circuito)
7.  geomSum(base,g,0,1) === base
8.  maxAffordable é o inverso exato de geomSum (fuzz 10⁵ casos: geomSum(n) ≤ ouro < geomSum(n+1))
9.  ser/deser: round-trip bit-a-bit da mantissa (usar toPrecision(17))
10. números além de 1e308: HP da onda 3000 deve ser finito e formatável
```

---

## 3. Formatação numérica PT-BR

```js
const NOMES = ['', ' mil', ' mi', ' bi', ' tri', ' quatri', ' quinti', ' sexti',
               ' septi', ' octi', ' noni', ' deci', ' undeci', ' duodeci'];
// (Brasil usa escala curta: 10⁹ = bilhão)
```

| Faixa | Modo | Exemplo |
|---|---|---|
| `< 1.000` | inteiro ou 1 casa | `847`, `23,5` |
| `1e3 … 1e6` | separador de milhar | `12.480` |
| `1e6 … 1e42` | nome curto, 3 dígitos significativos | `4,73 mi`, `1,29 quinti` |
| `≥ 1e42` | notação científica PT-BR | `3,84×10^68` |
| Modo "engenharia" (opção) | expoente múltiplo de 3 | `384×10^66` |
| Modo "letras" (opção idle) | `aa`,`ab`,`ac`… após `deci` | `1,29aC` |

Configurável em Opções: **Curto (padrão) / Científico / Engenharia / Letras**. Decimal = **vírgula**, milhar = **ponto** (`Intl.NumberFormat('pt-BR')` só para `< 1e6`; acima disso formate à mão para não pagar o custo do `Intl`).

**Nunca reformate no loop de render.** Cache a string por valor arredondado a 3 dígitos + expoente; invalide só quando o par `(m3, e)` muda.

---

## 4. Curvas de inimigo

### 4.1 Fórmulas

```js
// HP de um inimigo COMUM na onda w
hpBase(w) = 6 · 1.118^(w−1) · w^0.9 · exp( 4.5e-5 · max(0, w−90)² )

// quantidade de inimigos comuns
qtd(w) = min( 60, 5 + floor(0.5·w) )

// ouro por inimigo comum (SEM o termo de endurecimento — é o que cria o muro)
ouroBase(w) = 7.5 · ( 6 · 1.118^(w−1) · w^0.9 )^0.50

// XP por inimigo
xpBase(w) = 1.5 · 1.06^(w−1)

// velocidade do inimigo (px/s)
vel(w) = 26 + min(26, 0.16·w)

// intervalo de spawn (s)
spawn(w) = max(0.18, 1.10 − 0.26·ln(w+1)) / velocidadeDeOnda
```

### 4.2 Arquétipos

| Arquétipo | Condição | ×HP | ×Ouro | ×XP | ×Escala | ×Vel | Notas |
|---|---|---|---|---|---|---|---|
| **Comum** | — | 1.0 | 1.0 | 1.0 | 1.00 | 1.00 | |
| **Elite** | `w≥8`, chance `min(0.30, 0.02+0.0024w)` | 3.4 | 4.2 | 3.5 | 1.35 | 1.00 | aura roxa, armadura +8 |
| **Dourado** | `w≥5`, chance `min(0.035, 0.004+0.00018w)` | 0.9 | **35.0** | 6.0 | 1.15 | 1.90 | foge da torre, "pegue-me" |
| **Chefe** | `w % 10 == 0` | **12** | **16** | 14 | 2.10 | 0.62 | barra de HP dedicada, música muda |
| **Super-chefe** | `w % 50 == 0` | **60** | **70** | 55 | 2.90 | 0.50 | ataques especiais, drop garantido |
| **Voador** | `w≥25`, 20 % da leva | 0.75 | 1.1 | 1.0 | 0.85 | 1.45 | ignora terreno, precisa de "Precisão" |
| **Blindado** | `w≥40`, 15 % da leva | 1.6 | 1.4 | 1.2 | 1.10 | 0.80 | armadura +25 → exige Perfuração |
| **Enxame** | `w≥60`, onda `w%7==0` | 0.25 | 0.30 | 0.3 | 0.60 | 1.30 | ×4 na contagem |

```js
hpTotalOnda(w) = qtd(w)·hpBase(w)·(1 + pElite·2.4)
               + (w%10==0 ? 12·hpBase(w) : 0)
               + (w%50==0 ? 60·hpBase(w) : 0)

ouroTotalOnda(w) = qtd(w)·ouroBase(w)·(1 + pElite·3.2)
                 + (w%10==0 ? 16·ouroBase(w) : 0)
                 + (w%50==0 ? 70·ouroBase(w) : 0)
```

### 4.3 Tabela de referência (valores exatos das fórmulas)

| Onda | HP comum | Qtd | HP total onda | Ouro/comum | Ouro total onda |
|---:|---:|---:|---:|---:|---:|
| 1 | 6 | 5 | 30 | 18 | 92 |
| 2 | 13 | 6 | 75 | 27 | 169 |
| 3 | 20 | 6 | 121 | 34 | 227 |
| 5 | 40 | 7 | 279 | 47 | 444 |
| 10 | 130 | 10 | 2.999 | 86 | 4.450 |
| 15 | 327 | 12 | 4.454 | 136 | 4.340 |
| 20 | 740 | 15 | 21.804 | 204 | 18.829 |
| 25 | 1.581 | 17 | 32.035 | 298 | 19.265 |
| 30 | 3.254 | 20 | 118.485 | 428 | 64.575 |
| 40 | 12.860 | 25 | 565.319 | 851 | 194.548 |
| 50 | 47.959 | 30 | 5,37e6 | 1.642 | 1,29e6 |
| 60 | 172.407 | 35 | 1,05e7 | 3.114 | 1,57e6 |
| 75 | 1,12e6 | 42 | 6,98e7 | 7.948 | 5,31e6 |
| 90 | 7,05e6 | 50 | 6,37e8 | 19.916 | 2,07e7 |
| 100 | 2,38e7 | 55 | 3,83e9 | 36.476 | 1,12e8 |
| 125 | 4,97e8 | 60 | 5,13e10 | 162.607 | 5,00e8 |
| 150 | 1,06e10 | 60 | 1,86e12 | 711.692 | 5,37e9 |
| 175 | 2,33e11 | 60 | 2,40e13 | 3,08e6 | 2,02e10 |
| 200 | 5,32e12 | 60 | 9,31e14 | 1,32e7 | 2,12e11 |
| 225 | 1,27e14 | 60 | 1,31e16 | 5,60e7 | 7,38e11 |
| 250 | 3,15e15 | 60 | 5,52e17 | 2,37e8 | 7,67e12 |
| 275 | 8,23e16 | 60 | 8,50e18 | 9,96e8 | 2,64e13 |
| 300 | 2,26e18 | 60 | 3,95e20 | 4,18e9 | 2,89e14 |
| 350 | 1,97e21 | 60 | 3,46e23 | 7,28e10 | 1,48e16 |
| 400 | 2,12e24 | 60 | 3,72e26 | 1,26e12 | 2,56e17 |
| 450 | 2,81e27 | 60 | 4,93e29 | 2,15e13 | 4,39e18 |
| 500 | 4,62e30 | 60 | 8,10e32 | 3,67e14 | 7,48e19 |
| 600 | 2,39e37 | 60 | 4,19e39 | 1,05e17 | 2,15e19·10² |
| 700 | 2,96e44 | 60 | 5,19e46 | 2,99e19 | 6,08e21 |
| 800 | 8,87e51 | 60 | 1,55e54 | 8,38e21 | 1,71e24 |
| 900 | 6,43e59 | 60 | 1,13e62 | 2,33e24 | 4,75e26 |
| 1000 | 1,14e68 | 60 | 1,99e70 | 6,47e26 | 1,32e29 |
| 1500 | 1,27e115 | 60 | 2,23e117 | 1,00e39 | 2,04e41 |
| 2000 | 7,59e171 | 60 | 1,33e174 | 1,47e51 | 3,00e53 |
| 3000 | **> 1e308** | 60 | **> 1e308** | 2,93e75 | 5,97e77 |

> **`Big` torna-se obrigatório na onda ~2 800** (HP estoura o Float64). O ouro estoura só na onda ~5 600. Mas use `Big` desde a onda 1 para ouro/dano/HP — a diferença de custo é irrelevante fora do loop quente.

---

## 5. Motor de dano — o que compõe o DPS

```js
danoPorTiro = DANO_BASE
            · Π(multiplicadores de dano)          // Big
            · (1 + critChance·(critMult − 1))     // valor esperado
            · fatorSobrecarga(nInimigos)
            · multHabilidadeAtiva
            · multCombo

tirosPorSegundo = softcap( CADENCIA_BASE · Π(mult cadência), 12, 0.55 )
projeteisPorTiro = round( softcap(1 · Π(mult multitiro), 8, 0.50) )

DPS_nominal = danoPorTiro · tirosPorSegundo · projeteisPorTiro

// aplicado ao inimigo:
danoEfetivo = danoPorTiro · fatorArmadura(armaduraInimigo, perfuracao)
fatorArmadura(a, pen) = 60 / (60 + a·(1 − min(0.95, pen)))
```

**Valores base da torre (nível 0):**

| Stat | Base |
|---|---|
| Dano por tiro | **6,0** |
| Cadência | **1,75 tiros/s** |
| Chance crítica | **5 %** |
| Multiplicador crítico | **2,0×** |
| Projéteis | 1 |
| Alcance | 210 px |
| Velocidade de projétil | 460 px/s |
| Perfuração | 0 |
| Vida da torre | 100 |
| Regeneração | 0,5 HP/s |
| **DPS efetivo (com auto-Fúria)** | **12,6** ← `DPS_BASE` da §0 |

Derivação de `DPS_BASE`: `6,0 × 1,75 × 1,05 (crit) × 1,15 (uptime médio de Fúria automática) = 12,68 ≈ 12,6`.

**DPS necessário por onda (curva-alvo):**

```
T_spawn(w)  = 2.0 + 0.06·qtd(w) + 0.9          // piso: tempo de spawn + gap
T_alvo(w)   = max( T_spawn(w),
                   14.1 · exp( 0.014779·(w−200) + 4.5e-5·((w−90)² − 12100) ) )
DPS_alvo(w) = hpTotalOnda(w) / T_alvo(w)
```
*(Validado: T_alvo(250)=54 s vs simulado 49 s; T_alvo(300)=261 s vs simulado 252 s — erro < 10 %.)*

**Use `DPS_alvo(w)` como teste automático de CI:** o simulador deve entregar DPS dentro de `[0.6×, 1.7×]` de `DPS_alvo(w)` para todo `w ∈ [30, 350]`. Se sair da faixa, o balanceamento quebrou.

---

## 6. Softcaps

```js
// softcap padrão — potência abaixo do limiar, raiz acima
function softcap(x, limiar, expo) {
  return x <= limiar ? x : limiar * Math.pow(x / limiar, expo);
}

// softcap de probabilidade / redução (satura assintoticamente no teto)
function satura(x, teto) {
  return teto * (1 - Math.exp(-x / teto));
}
```

| Stat | Tipo | Parâmetros | Efeito |
|---|---|---|---|
| Cadência (tiros/s) | `softcap` duplo | `(12, 0.55)` → `(30, 0.30)` | 40 tiros/s brutos ⇒ 20,1 reais |
| Multitiro (projéteis) | `softcap` | `(8, 0.50)` | 32 brutos ⇒ 16 reais |
| Velocidade de onda | `softcap` | `(4.0, 0.45)` | ×16 bruto ⇒ ×7,3 real |
| Chance crítica | `satura` | teto `0.85` | 200 % bruto ⇒ 78,9 % |
| Lentidão | `satura` | teto `0.70` | |
| Redução de recarga | `satura` | teto `0.75` | |
| Perfuração | `satura` | teto `0.95` | |
| Armadura do inimigo | `K/(K+a)` | `K = 60` | nunca zera dano |
| Regeneração (% do HP máx/s) | `satura` | teto `0.08` | |
| Ouro por abate | **sem cap** | — | é a linha de crescimento |
| Dano | **sem cap** | — | é a linha de crescimento |

> **Princípio:** as duas linhas que compõem `K_eff` (Dano e Avareza) **nunca** recebem softcap — elas *são* a curva de progressão. Tudo que é "conforto" (cadência, projéteis, crítico) satura, para evitar quebra visual e explosão de entidades.

---

## 7. Upgrades de ouro — 34 upgrades, tabela completa

**Fórmula universal:** `custo(n) = base · cresc^n` (n = nível atual, 0-indexado). Custo acumulado e compra-máxima via `Big.geomSum` / `Big.maxAffordable` (§2.3).

### 7.1 Aba OFENSIVA (10)

| id | Nome | Efeito / nível | base | cresc | máx | n=1 | n=5 | n=10 | n=25 | n=50 | n=100 | acum(25) |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `dano` | **Dano** | ×1.070 dano | 5 | **1.18** | ∞ | 5 | 11 | 26 | 313 | 19.637 | 7,71e7 | 1.713 |
| `cadencia` | **Cadência** | ×1.050 tiros/s | 15 | **1.20** | ∞ | 15 | 37 | 93 | 1.431 | 136.507 | 1,24e9 | 7.080 |
| `critDano` | **Dano Crítico** | ×1.045 mult. crítico | 50 | **1.20** | ∞ | 50 | 124 | 310 | 4.770 | 455.022 | 4,14e9 | 23.599 |
| `critChance` | **Chance Crítica** | +1,2 pp (satura) | 120 | 1.28 | 60 | 120 | 412 | 1.417 | 57.469 | 2,75e7 | — | 204.816 |
| `perfuracao` | **Perfuração** | ×1.040 dano; +1,5 pp pen. | 190 | **1.20** | ∞ | 190 | 473 | 1.176 | 18.125 | 1,73e6 | 1,57e10 | 89.676 |
| `multitiro` | **Multitiro** | ×1.100 projéteis | 1.250 | **1.45** | ∞ | 1.250 | 8.012 | 51.356 | 1,35e7 | 1,46e11 | 1,71e19 | 3,01e7 |
| `alcance` | **Alcance** | +6 px | 80 | 1.22 | 40 | 80 | 216 | 584 | 11.537 | — | — | 52.076 |
| `ricochete` | **Ricochete** | +1 salto/5 níveis; ×1.03 dano do salto | 5.000 | 1.55 | 30 | 5.000 | 44.733 | 400.209 | 2,87e8 | — | — | 5,21e8 |
| `estilhaco` | **Estilhaço** | +8 % raio, +5 % dano em área | 20.000 | 1.40 | 40 | 20.000 | 107.565 | 578.509 | 9,00e7 | — | — | 2,25e8 |
| `sobrecarga` | **Sobrecarga** | ×1.06 dano se >15 inimigos vivos | 100.000 | 1.35 | ∞ | 100.000 | 448.403 | 2,01e6 | 1,81e8 | 3,29e11 | 1,08e18 | 5,18e8 |

**As 5 linhas em negrito são as que compõem `K_dps`:**

| linha | `ln(m)/ln(g)` |
|---|---:|
| dano | 0.4088 |
| cadencia | 0.2676 |
| critDano | 0.2414 |
| perfuracao | 0.2151 |
| multitiro | 0.2565 |
| **`K_dps`** | **1.3894** |

### 7.2 Aba DEFENSIVA (8)

| id | Nome | Efeito / nível | base | cresc | máx | n=1 | n=5 | n=10 | n=25 | acum(25) |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `vida` | **Vida da Torre** | ×1.12 HP máx | 25 | 1.19 | ∞ | 25 | 60 | 142 | 1.935 | 10.051 |
| `regen` | **Regeneração** | ×1.08 regen, +0,6 HP/s | 200 | 1.24 | ∞ | 200 | 586 | 1.719 | 43.308 | 179.618 |
| `armadura` | **Armadura** | +2 armadura | 500 | 1.26 | 100 | 500 | 1.588 | 5.043 | 161.523 | 619.318 |
| `escudo` | **Escudo** | +1 carga/10 níveis; ×1.05 recarga | 3.000 | 1.30 | 50 | 3.000 | 11.139 | 41.358 | 2,12e6 | 7,05e6 |
| `espinhos` | **Espinhos** | reflete 4 %, ×1.05 | 1.500 | 1.28 | ∞ | 1.500 | 5.154 | 17.709 | 718.357 | 2,56e6 |
| `choque` | **Onda de Choque** | +3 % empurrão ao ser atingido | 8.000 | 1.32 | 40 | 8.000 | 32.060 | 128.478 | 8,27e6 | 2,58e7 |
| `lentidao` | **Campo de Lentidão** | −1,5 % vel. inimiga (satura 70 %) | 12.000 | 1.34 | 40 | 12.000 | 51.845 | 223.990 | 1,81e7 | 5,31e7 |
| `ressurgir` | **Ressurgir** | −4 % tempo de respawn | 50.000 | 1.45 | 20 | 50.000 | 320.487 | 2,05e6 | 5,41e8 | 1,20e9 |

**Curva de dano de contato (define a pressão defensiva):**
```
danoContato(w) = 0.055 · vidaMaxTorre       (comum)
                 0.22  · vidaMaxTorre       (chefe)
iframes = 0.35 s ; respawn = 3.0 s ; penalidade de morte = −1 onda
```
Isso torna a defesa **auto-escalável**: o dano é % da vida máxima, então `vida` compra sobrevivência a inimigos vazando, não a HP absoluto. Um jogador que ignora a aba defensiva morre por volta da onda 45 (mede-se: 18 vazamentos consecutivos).

### 7.3 Aba ECONOMIA (7)

| id | Nome | Efeito / nível | base | cresc | máx | n=1 | n=5 | n=10 | n=25 | acum(25) |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `avareza` | **Avareza** | ×1.060 ouro por abate | 30 | **1.34** | ∞ | 30 | 130 | 560 | 45.159 | 132.731 |
| `ouroChefe` | **Tributo de Chefe** | ×1.10 ouro de chefes | 2.000 | 1.30 | ∞ | 2.000 | 7.426 | 27.572 | 1,41e6 | 4,70e6 |
| `ima` | **Ímã** | +12 % raio de coleta | 150 | 1.25 | 40 | 150 | 458 | 1.397 | 39.705 | 158.219 |
| `juros` | **Juros do Cofre** | +0,4 % do ouro em caixa por onda (cap 5 %) | 10.000 | 1.60 | 12 | 10.000 | 104.858 | 1,10e6 | — | 2,11e9 |
| `sorte` | **Sorte Dourada** | +0,05 pp chance de Dourado | 5.000 | 1.42 | 30 | 5.000 | 28.868 | 166.668 | 3,21e7 | 7,64e7 |
| `overkill` | **Overkill** | +2 % do dano excedente vira ouro (cap 50 %) | 40.000 | 1.38 | 25 | 40.000 | 200.196 | 1,00e6 | 1,26e8 | 3,30e8 |
| `pilhagem` | **Pilhagem de Elite** | ×1.08 ouro de Elites | 6.000 | 1.36 | ∞ | 6.000 | 27.916 | 129.879 | 1,31e7 | 3,63e7 |

`K_gold = ln(1.06)/ln(1.34) = **0.1991**` (só `avareza` entra na equação-mestra; as demais são bônus condicionais que não realimentam de forma composta).

> ⚠️ **`avareza` é o parâmetro mais perigoso do jogo.** Se `K_gold` passar de ~0.42, `K_eff` ultrapassa `1/α = 2.0` e o jogo entra em **runaway** (ondas ficam infinitamente rápidas). Trave em CI: `assert(K_dps/(1−K_gold) < 1/ALPHA − 0.15)`.

### 7.4 Aba UTILIDADE / RITMO (9)

| id | Nome | Efeito / nível | base | cresc | máx | n=1 | n=5 | n=10 | n=25 | acum(25) |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `velOnda` | **Velocidade de Onda** | ×1.05 taxa de spawn (softcap ×4) | 400 | 1.28 | 60 | 400 | 1.374 | 4.722 | 191.562 | 682.721 |
| `combo` | **Combo** | +0,15 % dano por acerto (teto 250) | 1.000 | 1.30 | 40 | 1.000 | 3.713 | 13.786 | 705.641 | 2,35e6 |
| `xp` | **Maestria (XP)** | ×1.05 XP | 300 | 1.26 | ∞ | 300 | 953 | 3.026 | 96.914 | 371.591 |
| `cdHab` | **Recarga de Habilidade** | −1,5 % recarga (satura 75 %) | 2.500 | 1.33 | 40 | 2.500 | 10.404 | 43.297 | 3,12e6 | 9,45e6 |
| `durHab` | **Duração de Habilidade** | ×1.04 duração | 4.000 | 1.33 | 40 | 4.000 | 16.646 | 69.275 | 4,99e6 | 1,51e7 |
| `ondaBonus` | **Bônus de Onda** | +15 % do ouro da onda ao completá-la, ×1.05 | 900 | 1.31 | ∞ | 900 | 3.472 | 13.395 | 769.175 | 2,48e6 |
| `critAcum` | **Fúria Acumulada** | +2 % dano por segundo sem crítico (reseta ao critar) | 30.000 | 1.37 | 25 | 30.000 | 144.785 | 698.758 | 7,85e7 | 2,12e8 |
| `precisao` | **Precisão** | +2,5 % dano contra Voadores; +1 alvo aéreo | 700 | 1.24 | 50 | 700 | 2.052 | 6.016 | 151.579 | 628.664 |
| `velProj` | **Velocidade de Projétil** | +18 px/s | 600 | 1.27 | 30 | 600 | 1.982 | 6.549 | 236.181 | 872.521 |

**Total: 34 upgrades de ouro.**

### 7.5 Habilidades ativas (dopamina de curto prazo — segundos)

| Habilidade | Efeito | Duração | Recarga | Multiplicador médio |
|---|---|---:|---:|---:|
| **Fúria** | ×5 dano | 12 s | 90 s | ×1,53 |
| **Sobrecarga do Núcleo** | +200 % cadência | 10 s | 100 s | ×1,20 |
| **Chuva de Ouro** | ×4 ouro | 15 s | 150 s | ×1,30 (ouro) |
| **Zero Absoluto** | congela tudo | 6 s | 120 s | defensiva |
| **Nova** | dano em área = 25× DPS instantâneo | — | 60 s | ×1,42 |
| **Distorção Temporal** | ×3 velocidade do jogo | 8 s | 180 s | ×1,13 (tempo) |

> Os multiplicadores médios já estão embutidos em `DPS_BASE = 12.6` (fator ×1,15 conservador, assumindo só Fúria em auto-cast). Se você habilitar auto-cast de todas por padrão, **suba `hpBase` H0 de 6 → 12** para compensar, ou o jogo dessa 44 ondas de graça.

---

## 8. Progressão temporal — RUN 1 (sem prestígio), saída do simulador

| Onda | Tempo acumulado | Δt da onda | DPS do jogador | HP da onda | Ouro da onda |
|---:|---:|---:|---:|---:|---:|
| 1 | 3,2 s | 3,2 s | 23 | 30 | 92 |
| 2 | 6,5 s | 3,3 s | 31 | 75 | 169 |
| 3 | 10,4 s | 3,8 s | 41 | 121 | 227 |
| 5 | 20,1 s | 4,9 s | 69 | 279 | 444 |
| 10 | **53,4 s** | 9,8 s | 339 | 2.999 | 4.450 |
| 15 | 1,3 min | 5,3 s | 1.001 | 4.454 | 4.340 |
| 20 | 1,8 min | 6,8 s | 3.722 | 21.804 | 18.829 |
| 25 | 2,1 min | 4,0 s | 10.410 | 32.035 | 19.265 |
| 30 | 2,5 min | 5,0 s | 28.806 | 118.485 | 64.575 |
| 40 | 3,2 min | 4,4 s | 189.427 | 565.319 | 194.548 |
| 50 | **4,0 min** | 5,4 s | 1,20e6 | 5,37e6 | 1,29e6 |
| 60 | 4,8 min | 5,0 s | 5,30e6 | 1,05e7 | 1,57e6 |
| 75 | 6,1 min | 5,4 s | 4,39e7 | 6,98e7 | 5,31e6 |
| 100 | **8,5 min** | 6,2 s | 1,36e9 | 3,83e9 | 1,12e8 |
| 125 | 11,2 min | 6,5 s | 2,65e10 | 5,13e10 | 5,00e8 |
| 150 | 13,9 min | 6,5 s | 4,52e11 | 1,86e12 | 5,37e9 |
| 175 | 16,6 min | 6,5 s | 5,21e12 | 2,40e13 | 2,02e10 |
| 200 | **19,7 min** | 14,1 s | 7,08e13 | 9,31e14 | 2,12e11 |
| 225 | 24,8 min | 16,5 s | 8,40e14 | 1,31e16 | 7,38e11 |
| 250 | 34,9 min | 49,3 s | 1,14e16 | 5,52e17 | 7,67e12 |
| **259** | **40,3 min** | ~52 s | 3,1e16 | 1,6e18 | 1,2e13 | ← **ponto ótimo de 1º prestígio** |
| 275 | 54,8 min | 1,1 min | 1,29e17 | 8,50e18 | 2,64e13 |
| 300 | 1,68 h | 4,2 min | 1,57e18 | 3,95e20 | 2,89e14 |
| 350 | 7,80 h | ~25 min | 2,3e20 | 3,46e23 | 4,0e16 | ← muro duro sem prestígio |

**Leitura de design:**
- Ondas **1–190**: ritmo de 4–7 s, limitado pelo *spawn*, não pelo DPS → sensação de poder crescente, "estou destruindo tudo". É a fase de dopamina pura.
- Ondas **190–260**: o tempo por onda sobe de 7 s → 55 s. O jogador percebe atrito. Aqui a UI deve destacar o botão de Reconstrução.
- Ondas **260+**: parede exponencial. Cada onda custa o dobro a cada ~23.

---

## 9. Camada 1 de prestígio — **Reconstrução** → **Éter** (ETR)

### 9.1 Regras

| | |
|---|---|
| **Desbloqueio** | alcançar a **onda 100** (≈ 8,5 min na primeira run) |
| **Fórmula de ganho** | `Éter = floor( 2 · 1.018^(Wmax − 100) · bonusEco )`, `Wmax ≥ 100` |
| **Reseta** | ouro, todos os 34 upgrades de ouro, onda atual, vida da torre |
| **Mantém** | Éter e upgrades de Éter, Maestria/talentos, conquistas, estatísticas, recordes, coleções |
| **Confirmação** | mostra `+X Éter` e `X/hora` em tempo real; alerta "abaixo do seu melhor Éter/h" |

**Por que exponencial e não polinomial:** com ganho polinomial (`W^k`), o ótimo de `Éter/tempo` colapsa para *runs curtíssimas* (spam de reset). Foi verificado no simulador — o jogo degenerava em resets de 1,8 min. Com base exponencial `1.018^W`, o ótimo é **finito e bem definido** (a taxa de ganho cresce a 1,8 %/onda contra `s(w)` = 1,5→3,4 %/onda do custo), e se move lentamente para frente a cada era. Anti-spam matemático, sem cooldowns artificiais.

### 9.2 Tabela de ganho de Éter

| Onda | Éter | | Onda | Éter |
|---:|---:|---|---:|---:|
| 100 | 2 | | 375 | 270 |
| 120 | 2 | | 400 | 422 |
| 150 | 4 | | 450 | 1.029 |
| 175 | 7 | | 500 | 2.512 |
| 200 | 11 | | 600 | 14.959 |
| 225 | 18 | | 700 | 89.062 |
| 250 | 29 | | 800 | 530.242 |
| **259** | **34** | | 900 | 3,16e6 |
| 275 | 45 | | 1000 | 1,88e7 |
| 300 | 70 | | 1200 | 6,66e8 |
| 325 | 110 | | 1500 | 1,40e11 |
| 350 | 172 | | 2000 | 8,68e14 |

### 9.3 Upgrades de Éter (12)

| id | Nome | Efeito / nível | base | cresc | máx | n=1 | n=3 | n=5 | n=10 | n=15 | n=20 | acum(10) |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `ressonancia` | **Ressonância** | ×1.15 dano | 1 | 1.60 | ∞ | 1 | 3 | 7 | 69 | 721 | 7.556 | 182 |
| `cobica` | **Cobiça** | ×1.12 todo o ouro | 2 | 1.70 | ∞ | 2 | 6 | 17 | 238 | 3.368 | 47.815 | 573 |
| `impulso` | **Impulso** | ×1.10 cadência | 3 | 1.80 | ∞ | 3 | 10 | 32 | 596 | 11.245 | 212.471 | 1.335 |
| `fundacao` | **Fundação** | ×1.20 HP e regen da torre | 2 | 1.65 | ∞ | 2 | 6 | 15 | 182 | 2.218 | 27.116 | 457 |
| `pressagio` | **Presságio** | +0,5 pp chance crítica base | 4 | 1.75 | 40 | 4 | 13 | 38 | 616 | 10.107 | 165.876 | 1.431 |
| `alvorada` | **Alvorada** | inicia a run 10 ondas adiante | 5 | 2.10 | 40 | 5 | 23 | 98 | 3.972 | 162.196 | 6,62e6 | 7.577 |
| `fervor` | **Fervor** | ×1.08 velocidade de onda | 6 | 1.90 | 30 | 6 | 22 | 79 | 1.937 | 47.941 | 1,19e6 | 4.081 |
| `compressao` | **Compressão** | −2 % custo de todos os upgrades de ouro (cap −50 %) | 8 | 2.00 | 25 | 8 | 32 | 128 | 4.096 | 131.072 | 4,19e6 | 8.184 |
| `eco` | **Eco do Éter** | ×1.06 ganho de Éter | 10 | 2.30 | ∞ | 10 | 53 | 280 | 18.012 | 1,16e6 | 7,46e7 | 31.859 |
| `persistencia` | **Persistência** | +6 pp eficiência offline, +1 h de teto | 12 | 2.20 | 12 | 12 | 59 | 282 | 14.488 | — | — | 26.550 |
| `automacao` | **Automação** | libera 1 linha de auto-compra | **8** | **2.00** | 6 | 8 | 32 | 128 | — | — | — | 504 (total) |
| `prontidao` | **Prontidão** | inicia com 5 %/nível do ouro total da run anterior | **20** | **2.00** | 10 | 20 | 80 | 320 | 10.240 | — | — | 20.460 (total) |

**Ordem de desbloqueio recomendada (tutorial dirigido):** `ressonancia` → `cobica` → `automacao(1)` → `alvorada` → `impulso` → `eco` → resto.

`Alvorada` é o que torna as re-runs rápidas: a onda inicial é `min(1 + 10·nível, floor(0.6·melhorOnda))`. O jogador nunca reclimba do zero.

**Contribuição de Éter ao DPS:**
```
multDPS_éter ≈ 1.15^ressonancia · 1.10^impulso
multOuro_éter ≈ 1.12^cobica
⟹ DPS_total ∝ E^(0.2974 + 0.1621) · (E^0.2136)^K_eff ≈ E^0.83
```

### 9.4 Loop de prestígio simulado (jogo ótimo, com compra gulosa)

| Run | Onda de reset | Duração da run | **Tempo acumulado** | Éter ganho | Éter total | ×DPS de Éter | Onda inicial |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 259 | 40,3 min | **40,6 min** | 34 | 34 | ×1,00 | 1 |
| 2 | 296 | 40,5 min | 1,36 h | 66 | 100 | ×1,92 | 11 |
| 3 | 317 | 44,2 min | 2,10 h | 96 | 196 | ×2,80 | 31 |
| 4 | 338 | 48,0 min | 2,90 h | 148 | 344 | ×3,54 | 31 |
| 5 | 347 | 47,2 min | 3,70 h | 184 | 528 | ×5,15 | 41 |
| 6 | 348 | 39,8 min | 4,37 h | 187 | 715 | ×5,67 | 51 |
| 7 | 358 | 36,2 min | 4,98 h | 224 | 939 | ×6,52 | 51 |
| 8 | 362 | 33,6 min | **5,54 h** | 255 | **1.194** | ×8,24 | 51 | ← **Ascensão liberada** |
| 9 | 362 | 33,8 min | 6,11 h | 255 | 1.449 | ×8,24 | 61 |
| 10 | 367 | 31,0 min | 6,63 h | 279 | 1.730 | ×9,07 | 61 |
| 12 | 374 | 29,1 min | 7,61 h | 335 | 2.360 | ×10,4 | 61 |
| 15 | 379 | 28,3 min | 9,04 h | 366 | 3.400 | ×13,2 | 71 |
| 18 | 382 | 26,8 min | 10,38 h | 386 | 4.590 | ×13,2 | 81 |

**Diagnóstico:** o ganho por run satura em torno da onda 380 (~+2 ondas por run após a run 15). Esse é o **sinal de projeto** de que a Camada 2 precisa existir e estar disponível — e ela está, desde as 5,5 h.

---

## 10. Camada 2 de prestígio — **Ascensão** → **Relíquias** (REL)

### 10.1 Regras

| | |
|---|---|
| **Desbloqueio** | **onda 350** **e** **1 000 Éter acumulado na era** → atingido em **~5,5 h** |
| **Fórmula** | `Relíquias = floor( 1.030^(Wmax_da_era − 350) · bonusCronos )` |
| **Reseta** | tudo da Camada 1 **+ Éter + upgrades de Éter + Maestria** |
| **Mantém** | Relíquias, upgrades de Relíquia, conquistas, desafios, coleções, estatísticas globais |

`1.030` por onda ⇒ **Relíquias dobram a cada 23,4 ondas**, o que casa exatamente com `s(350) ≈ 0.0342` (o custo de +1 onda). Relação de projeto: `ln(1.030) = 0.0296 ≈ 0.87·s(350)` — ligeiramente abaixo, mantendo o ótimo de reset finito.

### 10.2 Tabela

| Onda máx. da era | Relíquias | | Onda | Relíquias |
|---:|---:|---|---:|---:|
| 350 | 1 | | 600 | 1.619 |
| 375 | 2 | | 700 | 31.119 |
| 400 | 4 | | 800 | 598.068 |
| 425 | 9 | | 900 | 1,15e7 |
| 450 | 19 | | 1000 | 2,21e8 |
| 500 | 84 | | 1200 | 8,16e10 |
| 550 | 369 | | 1500 | 5,79e14 |

### 10.3 Upgrades de Relíquia (10)

| id | Nome | Efeito / nível | base | cresc | máx |
|---|---|---|---:|---:|---:|
| `heranca` | **Herança** | ×2,0 dano | 1 | 2.2 | ∞ |
| `fortuna` | **Fortuna** | ×1,8 ouro | 1 | 2.4 | ∞ |
| `cronos` | **Cronos** | ×1,5 ganho de Éter | 2 | 2.6 | ∞ |
| `vanguarda` | **Vanguarda** | +50 ondas iniciais | 3 | 3.0 | 20 |
| `estilhacoEterno` | **Estilhaço Eterno** | desbloqueia 1 elemento (fogo→gelo→raio→veneno→vazio) | 5 | **3.0** | 5 |
| `legado` | **Legado** | ×1,25 a **todos** os multiplicadores de Éter | 8 | 3.2 | ∞ |
| `torreGemea` | **Torre Gêmea** | +1 torre auxiliar (35 % do DPS, alvo independente) | 20 | 5.0 | 4 |
| `prisma` | **Prisma** | ×1,4 dano por elemento desbloqueado | 12 | 2.8 | ∞ |
| `vigilia` | **Vigília** | +15 pp eficiência offline, +6 h de teto (até 48 h) | 6 | 2.5 | 8 |
| `catalisador` | **Catalisador** | −8 % custo de todos os upgrades de Éter (cap −60 %) | 10 | 2.7 | 10 |

**Elementos** (o "juice" de médio prazo — desbloqueados só aqui):

| Elemento | Efeito | Duração | Pilhas |
|---|---|---:|---:|
| **Fogo** | DoT 35 % do dano/s | 3,0 s | 5 |
| **Gelo** | −30 % velocidade | 2,5 s | 3 |
| **Raio** | corrente em 3 alvos, 45 % do dano | — | — |
| **Veneno** | DoT 22 %/s, ignora armadura | 6,0 s | 12 |
| **Vazio** | +18 % dano recebido (amplificação) | 4,0 s | 4 |

Com os 5 elementos + `prisma` n=10: `1.4^(10·5)`… não — `prisma` é ×1.4 **por elemento**, ou seja `1.4^(nElementos)` por nível: `nível·nElementos` no expoente. Trave: `multPrisma = 1.4^(nivel · nElementosDesbloqueados)`, teto de nível 25.

### 10.4 Efeito esperado

Após a 1ª Ascensão com ~5 Relíquias: `heranca(2) · fortuna(1) · cronos(1)` ⇒ ×4 dano, ×1,8 ouro, ×1,5 Éter. Traduzindo: `ΔW = ln(4·1.8^1.735)/s(350) = ln(11.4)/0.0342 = **+71 ondas**` na primeira run da nova era. A era 2 chega à onda ~430 na primeira run (contra 259 da era 1) — **o salto de poder é imediatamente visível**, que é o ponto.

---

## 11. Camada 3 — **Eternidade** → **Fragmentos de Eternidade** (FRG)

| | |
|---|---|
| **Desbloqueio** | **onda 800** **e** **200 Relíquias** |
| **Fórmula** | `Fragmentos = floor( 1.012^(Wmax − 800) )` |
| **Reseta** | absolutamente tudo, exceto Fragmentos, conquistas e coleções |
| **Tempo-alvo** | **~3–4 dias** de jogo ativo + offline |

| Onda | Fragmentos |
|---:|---:|
| 800 | 1 |
| 900 | 3 |
| 1000 | 10 |
| 1200 | 118 |
| 1500 | 4.230 |
| 2000 | 1,65e6 |

**Upgrades de Fragmento (8) — cada um é uma mecânica nova, não só um número:**

| id | Nome | Efeito | base | cresc | máx |
|---|---|---|---:|---:|---:|
| `eternidade` | **Eternidade** | ×5 dano | 1 | 3.0 | ∞ |
| `abundancia` | **Abundância** | ×3 ouro | 1 | 3.2 | ∞ |
| `ampliacao` | **Ampliação** | ×2 ganho de Relíquias | 2 | 3.5 | ∞ |
| `cartas` | **Cartas** | desbloqueia o sistema de Cartas (24 cartas, 5 raridades, slots ×5) | 3 | — | 1 |
| `desafios` | **Desafios** | desbloqueia 8 Desafios (modificadores extremos, recompensas permanentes) | 5 | — | 1 |
| `distorcao` | **Sobrecarga Temporal** | ×1,5 velocidade global do jogo | 10 | 4.0 | 5 |
| `oraculo` | **Oráculo** | auto-prestígio configurável (onda-alvo, Éter-alvo, tempo-alvo) | 8 | — | 1 |
| `singularidade` | **Singularidade** | +1 torre orbital autônoma (DPS = 60 % do total, alvo aleatório) | 25 | 6.0 | 3 |

**Cartas** (sistema de RNG dopaminérgico de longo prazo): 24 cartas, raridades `Comum 60 % / Rara 25 % / Épica 10 % / Lendária 4 % / Mítica 1 %`. Multiplicador por raridade: `[×1.15, ×1.4, ×2.0, ×3.5, ×8.0]`. Custo de pacote: `100 · 1.9^n` Fragmentos. Cartas duplicadas viram "pó" (`3^raridade`) para *upgrade* de nível (`×1.08` por nível de carta, máx 20).

---

## 12. Progresso offline

### 12.1 Fórmulas

```js
const CAP_BASE_H     = 4;                                     // horas
const CAP_H          = min(48, CAP_BASE_H
                             + 1·persistencia_nivel           // Éter, máx 12
                             + 6·vigilia_nivel);              // Relíquia, máx 8

const t_off = min(agora − ultimoSave, CAP_H·3600);

const eficiencia = min(1.25, 0.40
                            + 0.06·persistencia_nivel         // até 1.00
                            + 0.15·(vigilia_nivel>0 ? 1 : 0)  // até 1.25
                       );

// taxa medida nas ÚLTIMAS 5 ONDAS antes de sair (não recalcular — armazenar no save)
const ouroOffline = taxaOuroPorSeg · t_off · eficiencia;

// avanço de ondas
const ondasEstimadas = floor( t_off · eficiencia / dtMedioUltimas5 );
const ondasPermitidas = min( ondasEstimadas, max(0, melhorOndaDaEra − ondaAtual) );
const ondasExcedentes = ondasEstimadas − ondasPermitidas;
// excedente vira ouro a 60 %:
ouroOffline += ondasExcedentes · ouroTotalOnda(melhorOndaDaEra) · 0.60 · eficiencia;

// Éter offline: SEMPRE 0 (o prestígio exige presença — é o gancho de retorno)
```

### 12.2 Justificativa dos números

- **40 % base** é deliberadamente baixo: o jogo é ~2,5× mais rápido em foreground, então o jogador ativo sempre ganha, mas quem some por 8 h ainda volta com progresso real.
- **Teto de 4 h** no início ensina o hábito de "checar 3–4 vezes por dia"; 48 h no endgame respeita quem joga de forma casual.
- **Ondas offline nunca quebram o recorde:** impede que o jogador "durma" para atravessar a parede — a parede tem que ser vencida com upgrades.
- **Sem Éter offline** garante que o loop de prestígio (o mais dopaminérgico) só acontece com o jogador presente.

### 12.3 Impulso de Retorno (o "presente de boas-vindas")

```js
duracaoImpulso = clamp(60 · (t_off / 14400), 15, 300);  // 15 s … 5 min
efeito = { velocidadeJogo: ×2, ouro: ×2 }
```
Tela de retorno: contagem animada do ouro ganho, ondas avançadas, e um botão grande **"COLETAR"** com partículas. Regra de UX: a tela de retorno **nunca** mostra "você ganhou 0" — se `t_off < 60 s`, pula a tela.

### 12.4 Tabela de referência de offline

| Tempo ausente | Eficiência (base) | Ouro recebido | Ondas avançadas | Impulso |
|---|---:|---|---:|---:|
| 10 min | 40 % | 4 min de jogo ativo | ~+35 | 15 s |
| 1 h | 40 % | 24 min | ~+210 | 15 s |
| 4 h (teto base) | 40 % | 1,6 h | limitado pelo recorde | 60 s |
| 8 h (com Persistência 4) | 64 % | 5,1 h | limitado pelo recorde | 2 min |
| 16 h (Persistência 12) | 100 % | 16 h | limitado pelo recorde | 4 min |
| 48 h (Vigília 8) | 125 % | 60 h | limitado pelo recorde | 5 min |

---

## 13. Marcos temporais — tabela-mestra

| Marco | Tempo-alvo | Onda | Verificado no simulador |
|---|---:|---:|---|
| Primeiro upgrade comprado | 3 s | 1 | ✅ 92 de ouro na onda 1, custo 5 |
| Primeiro chefe | 53 s | 10 | ✅ |
| Primeira habilidade (Fúria) | ~2 min | 20 | design |
| Primeiro Elite | ~1,3 min | 15 | ✅ |
| Aba Defensiva liberada | ~2,5 min | 30 | design |
| Primeiro super-chefe | 4,0 min | 50 | ✅ |
| Aba Economia liberada | ~4 min | 50 | design |
| **Reconstrução (Éter) desbloqueada** | **8,5 min** | **100** | ✅ |
| Aba Utilidade liberada | 8,5 min | 100 | design |
| Jogador sente o primeiro atrito | ~20 min | 200 | ✅ Δt salta 6,5 s → 14 s |
| **1º PRESTÍGIO** | **40,3 min** | **259** | ✅ ótimo de Éter/h |
| 2ª run (mais rápida, mais longe) | 1,36 h | 296 | ✅ |
| Auto-compra liberada (Automação 1) | ~1,4 h | — | ✅ 8 Éter |
| 5ª run | 3,70 h | 347 | ✅ |
| **2º PRESTÍGIO (Ascensão / Relíquias)** | **5,5 h** | **362** | ✅ 1.194 Éter |
| Primeiro elemento (Fogo) | ~7 h | — | 5 Relíquias |
| Todos os 5 elementos | ~2 dias | ~600 | projeção |
| Torre Gêmea | ~2,5 dias | ~700 | projeção |
| **3º PRESTÍGIO (Eternidade / Fragmentos)** | **~3,5 dias** | **800** | projeção |
| Sistema de Cartas | ~5 dias | — | 3 FRG |
| Desafios | ~7 dias | — | 5 FRG |
| Onda 1 000 | ~2 semanas | 1 000 | projeção |
| Onda 2 000 (`Big` obrigatório) | ~3 meses | 2 000 | projeção |

**Sessões de jogo por dia (design de retenção):**
- **Micro (30 s)**: coletar offline, gastar ouro, ver 3–5 ondas
- **Curta (5 min)**: subir 20–40 ondas, usar habilidades, comprar um marco
- **Média (40 min)**: uma run completa até o prestígio ← **o ritmo-alvo**
- **Longa (2–4 h)**: 4–6 runs + uma Ascensão

---

## 14. Bloco de constantes — pronto para colar

```js
// scripts/data/balance.js
export const BAL = Object.freeze({
  // ================================================== ONDAS =====
  HP_BASE: 6, HP_CRESC: 1.118, HP_POLI_EXP: 0.9,
  END_C: 4.5e-5, END_W0: 90,           // endurecimento exp(C·(w−W0)²)
  OURO_K: 7.5, OURO_ALPHA: 0.50,
  XP_BASE: 1.5, XP_CRESC: 1.06,
  QTD_BASE: 5, QTD_INCL: 0.5, QTD_MAX: 60,
  CHEFE_A_CADA: 10, SUPER_A_CADA: 50,
  SPAWN_A: 2.0, SPAWN_POR_INIMIGO: 0.06, GAP_ONDA: 0.9,
  SKIP_LIMIAR: 0.08, SKIP_DT: 0.30,    // onda instantânea quando dominada

  ARQ: {
    comum:  { hp: 1.0,  ouro: 1.0,  xp: 1.0, esc: 1.00, vel: 1.00 },
    elite:  { hp: 3.4,  ouro: 4.2,  xp: 3.5, esc: 1.35, vel: 1.00, armadura: 8 },
    dourado:{ hp: 0.9,  ouro: 35.0, xp: 6.0, esc: 1.15, vel: 1.90 },
    chefe:  { hp: 12.0, ouro: 16.0, xp: 14.0,esc: 2.10, vel: 0.62 },
    super:  { hp: 60.0, ouro: 70.0, xp: 55.0,esc: 2.90, vel: 0.50 },
    voador: { hp: 0.75, ouro: 1.1,  xp: 1.0, esc: 0.85, vel: 1.45 },
    blind:  { hp: 1.6,  ouro: 1.4,  xp: 1.2, esc: 1.10, vel: 0.80, armadura: 25 },
    enxame: { hp: 0.25, ouro: 0.30, xp: 0.3, esc: 0.60, vel: 1.30 },
  },
  P_ELITE:   (w) => w < 8 ? 0 : Math.min(0.30,  0.020 + 0.00240 * w),
  P_DOURADO: (w) => w < 5 ? 0 : Math.min(0.035, 0.004 + 0.00018 * w),

  // ================================================ COMBATE =====
  DANO_BASE: 6.0, CADENCIA_BASE: 1.75, CRIT_BASE: 0.05, CRIT_MULT_BASE: 2.0,
  ALCANCE_BASE: 210, VEL_PROJETIL: 460, VIDA_BASE: 100, REGEN_BASE: 0.5,
  ARMADURA_K: 60, RAIO_TORRE: 34,
  DANO_CONTATO: 0.055, DANO_CONTATO_CHEFE: 0.22, IFRAMES: 0.35, RESPAWN: 3.0,
  COMBO_JANELA: 2.6, COMBO_TETO: 250,

  // ================================================ SOFTCAPS ====
  SC: {
    cadencia:   [[12, 0.55], [30, 0.30]],
    multitiro:  [[8, 0.50]],
    velOnda:    [[4.0, 0.45]],
    critChance: { satura: 0.85 },
    lentidao:   { satura: 0.70 },
    recarga:    { satura: 0.75 },
    perfuracao: { satura: 0.95 },
    regenPct:   { satura: 0.08 },
  },

  // ============================================= UPGRADES OURO ==
  // [base, cresc, maxNivel(0=∞), multPorNivel, categoria]
  UP: {
    dano:       [5,      1.18, 0,   1.070, 'dps'],
    cadencia:   [15,     1.20, 0,   1.050, 'dps'],
    critDano:   [50,     1.20, 0,   1.045, 'dps'],
    critChance: [120,    1.28, 60,  0.012, 'add'],
    perfuracao: [190,    1.20, 0,   1.040, 'dps'],
    multitiro:  [1250,   1.45, 0,   1.100, 'dps'],
    alcance:    [80,     1.22, 40,  6,     'add'],
    ricochete:  [5000,   1.55, 30,  1.030, 'esp'],
    estilhaco:  [20000,  1.40, 40,  1.050, 'esp'],
    sobrecarga: [100000, 1.35, 0,   1.060, 'cond'],
    vida:       [25,     1.19, 0,   1.120, 'def'],
    regen:      [200,    1.24, 0,   1.080, 'def'],
    armadura:   [500,    1.26, 100, 2,     'add'],
    escudo:     [3000,   1.30, 50,  1.050, 'def'],
    espinhos:   [1500,   1.28, 0,   1.050, 'def'],
    choque:     [8000,   1.32, 40,  0.030, 'add'],
    lentidao:   [12000,  1.34, 40,  0.015, 'add'],
    ressurgir:  [50000,  1.45, 20,  0.040, 'add'],
    avareza:    [30,     1.34, 0,   1.060, 'gold'],
    ouroChefe:  [2000,   1.30, 0,   1.100, 'gold2'],
    ima:        [150,    1.25, 40,  1.120, 'qol'],
    juros:      [10000,  1.60, 12,  0.004, 'add'],
    sorte:      [5000,   1.42, 30,  0.0005,'add'],
    overkill:   [40000,  1.38, 25,  0.020, 'add'],
    pilhagem:   [6000,   1.36, 0,   1.080, 'gold2'],
    velOnda:    [400,    1.28, 60,  1.050, 'ritmo'],
    combo:      [1000,   1.30, 40,  0.0015,'add'],
    xp:         [300,    1.26, 0,   1.050, 'xp'],
    cdHab:      [2500,   1.33, 40,  0.015, 'add'],
    durHab:     [4000,   1.33, 40,  1.040, 'hab'],
    ondaBonus:  [900,    1.31, 0,   1.050, 'gold2'],
    critAcum:   [30000,  1.37, 25,  0.020, 'add'],
    precisao:   [700,    1.24, 50,  0.025, 'add'],
    velProj:    [600,    1.27, 30,  18,    'add'],
  },

  // ================================================= PRESTÍGIO ==
  ETER:  { ondaMin: 100, base: 2,  taxa: 1.018 },
  RELIQ: { ondaMin: 350, eterMin: 1000, base: 1, taxa: 1.030 },
  FRAG:  { ondaMin: 800, reliqMin: 200, base: 1, taxa: 1.012 },

  UP_ETER: {
    ressonancia: [1,  1.60, 0,  1.15], cobica:      [2,  1.70, 0,  1.12],
    impulso:     [3,  1.80, 0,  1.10], fundacao:    [2,  1.65, 0,  1.20],
    pressagio:   [4,  1.75, 40, 0.005],alvorada:    [5,  2.10, 40, 10],
    fervor:      [6,  1.90, 30, 1.08], compressao:  [8,  2.00, 25, 0.02],
    eco:         [10, 2.30, 0,  1.06], persistencia:[12, 2.20, 12, 0.06],
    automacao:   [8,  2.00, 6,  1],    prontidao:   [20, 2.00, 10, 0.05],
  },
  UP_RELIQ: {
    heranca:[1,2.2,0,2.0], fortuna:[1,2.4,0,1.8], cronos:[2,2.6,0,1.5],
    vanguarda:[3,3.0,20,50], estilhacoEterno:[5,3.0,5,1], legado:[8,3.2,0,1.25],
    torreGemea:[20,5.0,4,0.35], prisma:[12,2.8,25,1.4],
    vigilia:[6,2.5,8,0.15], catalisador:[10,2.7,10,0.08],
  },
  UP_FRAG: {
    eternidade:[1,3.0,0,5], abundancia:[1,3.2,0,3], ampliacao:[2,3.5,0,2],
    cartas:[3,1,1,1], desafios:[5,1,1,1], distorcao:[10,4.0,5,1.5],
    oraculo:[8,1,1,1], singularidade:[25,6.0,3,0.60],
  },

  // =================================================== OFFLINE ==
  OFF: { capBaseH: 4, capMaxH: 48, efBase: 0.40, efPorPersist: 0.06,
         efVigilia: 0.15, efMax: 1.25, excedente: 0.60,
         impulsoMin: 15, impulsoMax: 300, impulsoRef: 14400 },
});

// --------- funções derivadas (puras, testáveis) ---------
export const hpBase = (w) =>
  BAL.HP_BASE * Math.pow(BAL.HP_CRESC, w - 1) * Math.pow(w, BAL.HP_POLI_EXP)
  * Math.exp(BAL.END_C * Math.pow(Math.max(0, w - BAL.END_W0), 2));

export const ouroBase = (w) =>
  BAL.OURO_K * Math.pow(
    BAL.HP_BASE * Math.pow(BAL.HP_CRESC, w - 1) * Math.pow(w, BAL.HP_POLI_EXP),
    BAL.OURO_ALPHA);

export const qtdOnda = (w) =>
  Math.min(BAL.QTD_MAX, BAL.QTD_BASE + Math.floor(BAL.QTD_INCL * w));

export const inclinacao = (w) =>            // s(w) — o "câmbio" do jogo
  0.014779 + 2 * BAL.END_C * Math.max(0, w - BAL.END_W0);

export const ondasPorMult = (mult, w) => Math.log(mult) / inclinacao(w);

export const ganhoEter = (wMax, bonus = 1) =>
  wMax < BAL.ETER.ondaMin ? 0
  : Math.floor(BAL.ETER.base * Math.pow(BAL.ETER.taxa, wMax - BAL.ETER.ondaMin) * bonus);

export const softcap = (x, lim, exp) => x <= lim ? x : lim * Math.pow(x / lim, exp);
export const satura  = (x, teto) => teto * (1 - Math.exp(-x / teto));
export const fatorArmadura = (a, pen) => 60 / (60 + a * (1 - Math.min(0.95, pen)));
```

---

## 15. Testes automáticos de balanceamento (rodar em CI)

Crie `tools/sim_balance.mjs` — replica do simulador usado aqui — e trave estas invariantes:

```
T01  K_dps    === 1.3894 ± 0.02
T02  K_gold   === 0.1991 ± 0.01
T03  K_eff·ALPHA < 0.95            // sem runaway (atual: 0.8674)
T04  K_eff·ALPHA > 0.75            // sem parede instantânea
T05  inclinacao(w) crescente e monotônica em w ∈ [90, 5000]
T06  Δt da onda ∈ [3 s, 12 s] para todo w ∈ [1, 190]      (fase de fluxo)
T07  Δt da onda ∈ [12 s, 90 s] para todo w ∈ [200, 265]   (fase de atrito)
T08  DPS_simulado / DPS_alvo(w) ∈ [0.6, 1.7] para w ∈ [30, 350]
T09  tempo até onda 100  ∈ [7 min, 11 min]        (medido: 8,5 min)
T10  tempo até 1º prestígio ótimo ∈ [33 min, 50 min]  (medido: 40,3 min)
T11  onda do 1º prestígio ótimo ∈ [230, 290]      (medido: 259)
T12  tempo até Ascensão ∈ [4,5 h, 8 h]            (medido: 5,5 h)
T13  nenhuma run ótima tem duração < 8 min        (anti-spam de prestígio)
T14  ganhoEter é estritamente crescente em wMax
T15  ganho por run cresce por ≥ 12 runs consecutivas (loop não morre cedo)
T16  ordem de custo: para todo upgrade, custo(n+1) > custo(n)
T17  nenhum upgrade fica "morto": em algum ponto de uma run ótima,
     cada upgrade de ouro é comprado ao menos 3 vezes
T18  Big: HP da onda 3000 é finito e formatável
T19  maxAffordable(base,g,L,ouro) é o inverso exato de geomSum (fuzz 1e5)
T20  save/load round-trip preserva DPS com erro relativo < 1e-12
```

**T17 é o teste mais importante para "sensação de jogo":** se um upgrade nunca é comprado pelo comprador guloso ótimo, ele é lixo visual — ajuste `base` ou `cresc` até que entre na rotação.

---

## 16. Notas finais de implementação

1. **Ordem de aplicação dos multiplicadores** (fixa, para o save ser determinístico):
   `base → upgrades de ouro → Maestria/talentos → Éter → Relíquias → Fragmentos → Cartas → habilidades ativas → combo → softcaps`. Softcaps **por último**, sempre.

2. **Auto-compra** deve usar exatamente o mesmo critério guloso do simulador: `valor = peso_da_linha · ln(multiplicador) / custo`, com `peso = K_dps` para linhas de ouro e `1` para linhas de dano. É comprovadamente quase-ótimo e é *o mesmo código* do balanceador — o jogo e o simulador nunca divergem.

3. **`Big` nunca entra no loop de entidades.** Ver §2.4. Isso é o que garante os 60 fps com 300 inimigos.

4. **Um único arquivo de verdade.** Todos os números desta especificação vivem em `scripts/data/balance.js`. Nenhum número mágico em qualquer outro arquivo — o CI deve falhar se encontrar literais numéricos > 1 em `scripts/sim/`.

5. **Se você precisar deixar o jogo mais fácil ou mais difícil globalmente**, mexa em **`OURO_K` (7.5) apenas**. Cada ×2 em `OURO_K` acelera o jogo em `ln(2)·K_eff / s(w)` ondas — ~77 ondas na onda 100, ~41 na onda 250. Não mexa em `ALPHA`, `HP_CRESC` nem nos `cresc` dos upgrades sem refazer a simulação completa: eles alteram a *forma* da curva, não o *deslocamento*.