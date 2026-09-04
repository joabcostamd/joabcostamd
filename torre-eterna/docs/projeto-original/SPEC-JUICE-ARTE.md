> **Documento do projeto original — não descreve o jogo que existe.**
> Este texto de arte e juice foi escrito para uma implementação em JavaScript/Canvas
> que nunca foi construída; o jogo é feito em Godot 4 e GDScript. Caminhos
> de arquivo, APIs e números aqui são do projeto, não da realidade.
> Leia `docs/projeto-original/LEIA-ANTES.md` antes de usar qualquer coisa
> daqui.

# TOWER ZERO — Bíblia de Arte Procedural & Juice
### Documento de Direção Técnica v1.0 — Canvas 2D puro, zero assets

> **Contrato:** tudo aqui é numérico e vira código direto. Nenhum valor é "aproximado". Onde há tabela, ela é literalmente o `const` do módulo. Nomes de funções/variáveis em PT-BR conforme o restante do projeto (`scripts/` já usa `Ux`, `Fmt`, `Big`, `inimigo`, `coletavel`, `projetil`).
> Roster de inimigos alinhado com `data/enemies.json` (22 comuns + 9 elites + 10 chefes + 2 super-chefes).

---

# 1. CONTRATO DE RENDERIZAÇÃO

## 1.1 Espaço lógico e câmera

```js
// render/camera.js
export const MUNDO = { L: 1600, A: 900, cx: 800, cy: 450 };   // unidades de mundo
export const RAIO_ARENA   = 430;   // raio útil onde inimigos andam
export const RAIO_SPAWN   = 512;   // anel de entrada (fora da tela em 16:9)
export const RAIO_MORTE   = 46;    // colisão com a torre
```

Ajuste "cover" com clamp para retrato:

```js
export function ajustar(canvas, dpr){
  const w = canvas.clientWidth, h = canvas.clientHeight;
  const s = Math.max(w / MUNDO.L, h / MUNDO.A);      // cover
  const sMax = Math.min(s, (w/MUNDO.L) * 1.65);      // trava zoom em retrato extremo
  cam.escala = sMax;
  cam.ox = w*0.5 - MUNDO.cx*sMax;
  cam.oy = h*0.5 - MUNDO.cy*sMax;
}
```

**DPR (crítico para mobile 60fps):**

| Condição | `dpr` efetivo |
|---|---|
| Área CSS ≤ 900 000 px² | `min(devicePixelRatio, 2)` |
| 900 001 – 2 100 000 px² | `min(devicePixelRatio, 1.75)` |
| > 2 100 000 px² | `1.25` |
| Qualidade "baixa" (0) | força `1.0` |
| FPS médio < 48 por 3 s | degrada `dpr *= 0.85` (piso 0.9), re-sobe após 8 s estável |

## 1.2 Pilha de canvases (4 camadas)

| # | id | Freq. redesenho | Conteúdo | `alpha` |
|---|---|---|---|---|
| 0 | `cnvFundo` | on-demand (bioma, resize, 4 Hz parallax) | gradiente de céu, grade, decalques, estrelas | `false` |
| 1 | `cnvJogo` | 60 Hz | sombras, ouro, inimigos, torre, projéteis, partículas, números | `true` |
| 2 | `cnvFx` | 60 Hz (só qualidade ≥ 2) | buffer 1/4 para bloom + aberração cromática | `true` |
| 3 | `cnvVeu` | 60 Hz, custo ~0 | vinheta, flashes, letterbox de chefe, transições | `true` |

HUD = **DOM**, nunca canvas (permite acessibilidade nativa, leitores de tela, seleção de texto e `will-change: transform` acelerado).

## 1.3 Ordem de desenho dentro de `cnvJogo`

```
1  decalques do chão (crateras, queimados)     — pool 64, fade 6 s
2  sombras elípticas (todas, blend multiply α .22)
3  campos/AoE no chão (zonas de gelo, fissuras)
4  moedas e coletáveis (chão)
5  inimigos TERRESTRES  (sort por y crescente)
6  base + fuste da torre
7  inimigos VOADORES    (sort por y, +offset de altura)
8  anéis orbitais da torre + satélites
9  projéteis + trilhas   (blend 'lighter')
10 partículas ADITIVAS   (blend 'lighter')
11 partículas NORMAIS    (fumaça, cinzas, blend 'source-over')
12 núcleo pulsante + bloom local da torre
13 barras de vida de elite/chefe
14 números de dano
15 telegrafias de chefe (anéis de aviso, sempre por cima)
```

**Regra de ouro:** *no máximo 3 trocas de `globalCompositeOperation` por frame*. Partículas aditivas e normais vivem em pools separados justamente por isso.

## 1.4 Orçamento de frame (16.67 ms @60fps)

| Bloco | Alvo desktop | Alvo mobile | Teto duro |
|---|---|---|---|
| Simulação (mov/colisão/dano) | 2.2 ms | 3.4 ms | 5.0 ms |
| Inimigos (≤ 320 vivos) | 3.0 ms | 4.0 ms | 6.0 ms |
| Partículas (≤ 4096) | 1.8 ms | 2.2 ms | 3.5 ms |
| Torre + orbitais | 0.8 ms | 0.8 ms | 1.2 ms |
| Números de dano (≤ 90) | 0.7 ms | 0.9 ms | 1.4 ms |
| Pós (bloom + aberração) | 1.6 ms | 0 ms (off) | 2.4 ms |
| HUD (DOM, 12 Hz) | 0.6 ms | 0.8 ms | 1.5 ms |
| **Total** | **10.7 ms** | **12.1 ms** | — |

## 1.5 Escadas de qualidade

```js
export const QUALIDADE = [
  /*0 baixa */ { part:0.30, bloom:0, aberr:0, trilhas:0, sombras:0, orbitais:1, decalques:0, maxInim:140, numeros:0.5 },
  /*1 média */ { part:0.60, bloom:0, aberr:0.5, trilhas:1, sombras:1, orbitais:2, decalques:1, maxInim:220, numeros:0.8 },
  /*2 alta  */ { part:1.00, bloom:1, aberr:1.0, trilhas:1, sombras:1, orbitais:4, decalques:1, maxInim:320, numeros:1.0 },
  /*3 ultra */ { part:1.60, bloom:1, aberr:1.0, trilhas:1, sombras:1, orbitais:4, decalques:1, maxInim:440, numeros:1.0 },
];
```

---

# 2. SISTEMA DE COR

## 2.1 Tokens base (independem de bioma)

```js
export const COR = {
  // interface
  tinta:        '#e6edf6',
  tintaFraca:   '#94a3b8',
  tintaFantasma:'#4b5769',
  painel:       '#0d1220',
  painelAlto:   '#151d31',
  borda:        '#233048',
  bordaViva:    '#3d5580',

  // economia
  ouro:         '#fcd34d',
  ouroEscuro:   '#b45309',
  ouroBrilho:   '#fff7cc',
  fragmento:    '#38bdf8',
  nucleo:       '#a855f7',
  eter:         '#f472b6',

  // estados
  dano:         '#fef3c7',
  critico:      '#fbbf24',
  superCritico: '#f97316',
  execucao:     '#f43f5e',
  cura:         '#86efac',
  veneno:       '#a3e635',
  gelo:         '#67e8f9',
  raio:         '#c4b5fd',
  fogo:         '#fb7185',
  vazio:        '#8b5cf6',
  escudo:       '#7dd3fc',
  perigo:       '#ef4444',
};

export const RARIDADE = ['#94a3b8','#4ade80','#38bdf8','#a855f7','#f59e0b','#f43f5e','#e0f2fe'];
// comum, incomum, raro, épico, lendário, mítico, divino(arco-íris animado)
```

**Divino** não é cor fixa: `hsl((t*70 + i*37) % 360, 92%, 72%)`, ciclo de 5.14 s.

## 2.2 Paleta por Era / Bioma (8 eras)

Cada era é um objeto completo. A transição entre eras é interpolada em **2.4 s** (`easeInOutSine`) sobre todos os canais — nunca há corte seco.

```js
export const ERAS = [
{ id:'planicie', nome:'Planície Cinza', ondas:[1,24], lore:'Onde a torre acordou.',
  ceuTopo:'#0b1220', ceuBase:'#151d2e', horizonte:'#1c2740',
  chao:'#131a2a', chaoAlt:'#182136', grade:'#22304a', gradeAlpha:0.35,
  nevoa:'#2a3category'.replace('category',''), // ver nota
  nevoaCor:'#22304a', nevoaAlpha:0.10,
  acento:'#5eead4', acento2:'#38bdf8',
  luzTorre:'#7dd3fc', ambiente:'#334155',
  particulaAmb:'#3b4a63', ambTipo:'poeira', ambTaxa:2.2,
  vinheta:'#000000', vinhetaBase:0.26, estrelas:0.35 },

{ id:'floresta', nome:'Floresta Corrompida', ondas:[25,74], lore:'A seiva virou ácido.',
  ceuTopo:'#07130d', ceuBase:'#0e2119', horizonte:'#16382a',
  chao:'#0d1c15', chaoAlt:'#12271d', grade:'#1f4433', gradeAlpha:0.30,
  nevoaCor:'#22c55e', nevoaAlpha:0.07,
  acento:'#a3e635', acento2:'#4ade80',
  luzTorre:'#bef264', ambiente:'#166534',
  particulaAmb:'#84cc16', ambTipo:'esporo', ambTaxa:5.0,
  vinheta:'#04140c', vinhetaBase:0.30, estrelas:0.10 },

{ id:'deserto', nome:'Deserto de Escória', ondas:[75,149], lore:'Vidro moído até virar chão.',
  ceuTopo:'#1a1008', ceuBase:'#2e1c0c', horizonte:'#4a2b10',
  chao:'#241708', chaoAlt:'#2d1d0b', grade:'#4a3016', gradeAlpha:0.28,
  nevoaCor:'#f59e0b', nevoaAlpha:0.09,
  acento:'#fbbf24', acento2:'#fb923c',
  luzTorre:'#fde68a', ambiente:'#78350f',
  particulaAmb:'#d97706', ambTipo:'areia', ambTaxa:7.5,
  vinheta:'#180d03', vinhetaBase:0.28, estrelas:0.20 },

{ id:'tundra', nome:'Tundra Vítrea', ondas:[150,299], lore:'O frio guarda o que mata.',
  ceuTopo:'#061423', ceuBase:'#0b2236', horizonte:'#12384f',
  chao:'#0a1c2c', chaoAlt:'#0f2537', grade:'#1e4c63', gradeAlpha:0.40,
  nevoaCor:'#67e8f9', nevoaAlpha:0.12,
  acento:'#67e8f9', acento2:'#e0f2fe',
  luzTorre:'#a5f3fc', ambiente:'#0e7490',
  particulaAmb:'#cffafe', ambTipo:'neve', ambTaxa:9.0,
  vinheta:'#03121d', vinhetaBase:0.24, estrelas:0.55 },

{ id:'abismo', nome:'Abismo Submerso', ondas:[300,499], lore:'Pressão suficiente para dobrar deuses.',
  ceuTopo:'#02060f', ceuBase:'#061024', horizonte:'#0a1c3d',
  chao:'#040c1a', chaoAlt:'#071224', grade:'#123055', gradeAlpha:0.22,
  nevoaCor:'#1d4ed8', nevoaAlpha:0.14,
  acento:'#60a5fa', acento2:'#c084fc',
  luzTorre:'#93c5fd', ambiente:'#1e3a8a',
  particulaAmb:'#38bdf8', ambTipo:'bolha', ambTaxa:3.2,
  vinheta:'#000308', vinhetaBase:0.38, estrelas:0.05 },

{ id:'vulcao', nome:'Núcleo Vulcânico', ondas:[500,799], lore:'O planeta sangrando por dentro.',
  ceuTopo:'#1a0505', ceuBase:'#380a06', horizonte:'#6b1206',
  chao:'#1c0806', chaoAlt:'#280b06', grade:'#7c2d12', gradeAlpha:0.34,
  nevoaCor:'#ef4444', nevoaAlpha:0.13,
  acento:'#fb923c', acento2:'#ef4444',
  luzTorre:'#fdba74', ambiente:'#991b1b',
  particulaAmb:'#f97316', ambTipo:'brasa', ambTaxa:11.0,
  vinheta:'#100201', vinhetaBase:0.34, estrelas:0.0 },

{ id:'orbita', nome:'Órbita Fraturada', ondas:[800,1199], lore:'A gravidade desistiu.',
  ceuTopo:'#04030c', ceuBase:'#0a0820', horizonte:'#171043',
  chao:'#070617', chaoAlt:'#0b0920', grade:'#2e2170', gradeAlpha:0.30,
  nevoaCor:'#8b5cf6', nevoaAlpha:0.10,
  acento:'#c084fc', acento2:'#22d3ee',
  luzTorre:'#ddd6fe', ambiente:'#4c1d95',
  particulaAmb:'#a78bfa', ambTipo:'detrito', ambTaxa:4.0,
  vinheta:'#020108', vinhetaBase:0.30, estrelas:1.0 },

{ id:'vazio', nome:'O Vazio', ondas:[1200,Infinity], lore:'Nada — e o nada olha de volta.',
  ceuTopo:'#000000', ceuBase:'#050208', horizonte:'#0d0418',
  chao:'#030106', chaoAlt:'#06020c', grade:'#2a1046', gradeAlpha:0.18,
  nevoaCor:'#a855f7', nevoaAlpha:0.16,
  acento:'#f472b6', acento2:'#a855f7',
  luzTorre:'#f5d0fe', ambiente:'#3b0764',
  particulaAmb:'#e879f9', ambTipo:'glitch', ambTaxa:2.6,
  vinheta:'#000000', vinhetaBase:0.46, estrelas:0.12 },
];
```

## 2.3 Fundo procedural (`cnvFundo`)

**Céu:** gradiente linear vertical `ceuTopo → ceuBase` + gradiente radial no centro (`horizonte`, raio `520`, α 0.55) — dá a impressão de que a torre ilumina o mundo.

**Grade de chão (perspectiva falsa):** linhas concêntricas + radiais em torno da torre, não cartesianas — reforça o "centro do mundo":
```js
// 9 anéis concêntricos
for (let i=1;i<=9;i++){
  const r = 58*i + 14*Math.sin(i*1.7);
  ctx.globalAlpha = era.gradeAlpha * (1 - i/11);
  ctx.strokeStyle = era.grade; ctx.lineWidth = i===5 ? 2.0 : 1.0;
  arco(r);
}
// 24 raios
for (let k=0;k<24;k++){
  const a = k*Math.PI/12;
  ctx.globalAlpha = era.gradeAlpha * 0.45;
  linha(cx+Math.cos(a)*70, cy+Math.sin(a)*70, cx+Math.cos(a)*RAIO_SPAWN, cy+Math.sin(a)*RAIO_SPAWN);
}
```

**Estrelas:** `n = floor(180 * era.estrelas)`, posições de `RngX` semeado por `era.id` (determinístico entre sessões), raio 0.6–1.8, α base 0.25–0.85 com cintilação `α * (0.7 + 0.3*sin(t*2.1 + seed*7))`. Redesenho a 4 Hz apenas.

**Parallax:** 3 camadas de silhuetas poligonais no horizonte, offsets `[0.010, 0.022, 0.040] * (traumaShake + driftLento)`. Drift lento: `sin(t*0.06) * 14 px`.

## 2.4 Daltonismo

Matriz aplicada **na definição da cor** (não em pós-processo — muito mais barato). `Cfg.daltonismo ∈ {0,1,2,3}`:

```js
const LMS = {
 protanopia:   [0.567,0.433,0.000, 0.558,0.442,0.000, 0.000,0.242,0.758],
 deuteranopia: [0.625,0.375,0.000, 0.700,0.300,0.000, 0.000,0.300,0.700],
 tritanopia:   [0.950,0.050,0.000, 0.000,0.433,0.567, 0.000,0.475,0.525],
};
```
Além da matriz, **reforço redundante obrigatório**: todo estado que hoje é só cor ganha *forma*:
- Veneno → 3 bolhas orbitando o inimigo.
- Congelado → cristal hexagonal sobreposto + entidade em `α 0.9` com contorno branco.
- Queimando → 2 chamas triangulares no topo.
- Elite → moldura poligonal externa (ver §4.7).
- Crítico → número com **contorno duplo + estrela de 4 pontas** atrás, não apenas cor.

---

# 3. A TORRE — ANATOMIA E EVOLUÇÃO

A torre é desenhada **de baixo para cima em 11 camadas**, todas paramétricas por `T` (estado visual da torre).

## 3.1 Estado visual

```js
export const torreVis = {
  nivel: 0,            // nível somado de upgrades (0..∞)
  tier: 0,             // 0..7, degrau estético
  segmentos: 1,        // 1..9 blocos do fuste
  aneis: 0,            // 0..4 anéis orbitais
  satelites: 0,        // 0..8 orbes
  cristais: 0,         // 0..6 no colar
  emblemas: {asc:0, sing:0, trans:0},
  carga: 0,            // 0..1 — carrega até o próximo tiro
  aquecimento: 0,      // 0..1 — DPS relativo, alimenta o brilho
  ferida: 0,           // 0..1 — 1 - vida/vidaMax
  angCanhao: 0,        // rad, mira suavizada
  recuo: 0,            // 0..1, decai 12/s
  respiro: 0,          // fase da respiração
};
```

## 3.2 Degraus estéticos (tiers) — **o gatilho dopaminérgico visual principal**

| Tier | Nível | Nome | Corpo | Aresta | Emissivo | Núcleo | Muda o quê |
|---|---|---|---|---|---|---|---|
| 0 | 0–9 | Pedra Bruta | `#3f4756` | `#59657a` | `#7dd3fc` | `#bae6fd` | fuste 1 seg., sem anel |
| 1 | 10–24 | Ferro Rúnico | `#4a5568` | `#7c8aa3` | `#67e8f9` | `#cffafe` | +1 seg., runas gravadas, 1 anel |
| 2 | 25–49 | Aço Arcano | `#3b4d6b` | `#8fb3e0` | `#38bdf8` | `#e0f2fe` | +cristais 2, 2 anéis, 2 satélites |
| 3 | 50–99 | Cristal Vivo | `#4c3b6b` | `#b39fe0` | `#a855f7` | `#f3e8ff` | corpo translúcido (α .82), veios |
| 4 | 100–199 | Núcleo Estelar | `#6b3b52` | `#e0a0bb` | `#f472b6` | `#ffe4f0` | anel de plasma, 4 satélites |
| 5 | 200–399 | Forja Solar | `#6b4a1e` | `#f0c674` | `#fbbf24` | `#fff7cc` | chamas nas juntas, 3 anéis |
| 6 | 400–799 | Prisma do Vazio | `#2b1a4d` | `#9d7ce0` | `#8b5cf6` | `#ede9fe` | corpo fraturado, fenda vertical |
| 7 | 800+ | Trono Eterno | `#120a24` | rainbow | rainbow | `#ffffff` | 4 anéis, 8 satélites, coroa flutuante |

Transição de tier **nunca é instantânea**: `tierMix ∈ [0,1]` interpola cores em **1.8 s** e dispara a celebração §8.3.

## 3.3 Camadas de desenho (com números)

```js
export function desenharTorre(ctx, T, t, era){
  const {cx, cy} = MUNDO;
  const pulso = Math.sin(t*2.4);
  const resp  = Math.sin(t*0.9)*1.6;              // respiração ±1.6px
  const cor   = paletaTier(T.tier, T.tierMix, t);

  // ── C0 · SOMBRA -------------------------------------------------------
  ctx.globalAlpha = 0.30;
  elipse(ctx, cx, cy+34, 54, 15, '#000');

  // ── C1 · ANEL DE ALCANCE (só quando UI pede ou 1.2s após upgrade) -----
  if (T.mostrarAlcance > 0){
    ctx.globalAlpha = 0.10 * T.mostrarAlcance;
    ctx.setLineDash([9, 13]); ctx.lineDashOffset = -t*22;
    circulo(ctx, cx, cy, T.alcance, cor.emissivo, 1.5);
    ctx.setLineDash([]);
  }

  // ── C2 · PLATAFORMA (octógono) ---------------------------------------
  poligono(ctx, cx, cy+22, 8, 58, Math.PI/8, cor.corpo, cor.aresta, 2);
  poligono(ctx, cx, cy+18, 8, 48, Math.PI/8, mix(cor.corpo,'#000',0.25), null, 0);

  // ── C3 · FUSTE SEGMENTADO --------------------------------------------
  // altura total = 26 + 15 * segmentos, largura afina 6% por segmento
  let y = cy + 14, w = 34;
  for (let i=0; i<T.segmentos; i++){
    const h = 15, wTopo = w * 0.94;
    trapezio(ctx, cx, y, w, wTopo, h, cor.corpo, cor.aresta);
    // linha emissiva na junta, pisca com o aquecimento
    ctx.globalAlpha = 0.35 + 0.45*T.aquecimento + 0.10*pulso;
    linha(ctx, cx-wTopo/2+3, y-h, cx+wTopo/2-3, y-h, cor.emissivo, 1.4);
    y -= h; w = wTopo;
  }

  // ── C4 · RUNAS (tier ≥ 1): 3 glifos por segmento, seed determinístico -
  if (T.tier >= 1) desenharRunas(ctx, cx, cy, T, cor, t);

  // ── C5 · COLAR DE CRISTAIS (tier ≥ 2) --------------------------------
  for (let i=0;i<T.cristais;i++){
    const a = t*0.6 + i*(Math.PI*2/T.cristais);
    const rx = cx + Math.cos(a)*26, ry = y + 4 + Math.sin(a)*7;
    losango(ctx, rx, ry, 4.5, 8, a, cor.emissivo, 0.85);
  }

  // ── C6 · COROA / CABEÇA ----------------------------------------------
  const topoY = y - 4 + resp;
  poligono(ctx, cx, topoY, 6, 24, t*0.15, cor.corpo, cor.aresta, 2);

  // ── C7 · CANHÃO (aponta para o alvo, com recuo) -----------------------
  const recuoPx = 7 * T.recuo;
  ctx.save(); ctx.translate(cx, topoY); ctx.rotate(T.angCanhao);
  retanguloArred(ctx, 14 - recuoPx, -5, 26, 10, 3, cor.corpo, cor.aresta);
  ctx.globalAlpha = 0.5 + 0.5*T.carga;
  circulo(ctx, 40 - recuoPx, 0, 3 + 3*T.carga, cor.emissivo);
  ctx.restore();

  // ── C8 · NÚCLEO PULSANTE (a "alma" da torre) --------------------------
  const rN = 12 + 1.8*pulso + 4.5*T.carga + 2.2*T.aquecimento;
  gradienteRadial(ctx, cx, topoY, rN*3.2, [
    [0.00, alpha(cor.nucleo, 0.95)],
    [0.28, alpha(cor.emissivo, 0.55)],
    [1.00, alpha(cor.emissivo, 0.00)],
  ]);
  circulo(ctx, cx, topoY, rN, cor.nucleo);
  // anel interno em contra-rotação
  ctx.globalAlpha = 0.7;
  arcoParcial(ctx, cx, topoY, rN+4, -t*1.9, 2.1, cor.emissivo, 1.6);
  arcoParcial(ctx, cx, topoY, rN+7,  t*1.3, 1.4, cor.emissivo, 1.0);

  // ── C9 · ANÉIS ORBITAIS (elipses com tilt) ---------------------------
  desenharAneis(ctx, cx, topoY, T, cor, t);

  // ── C10 · SATÉLITES ---------------------------------------------------
  for (let i=0;i<T.satelites;i++){
    const a = t*0.85 + i*(Math.PI*2/T.satelites);
    const R = 62 + 6*Math.sin(t*1.7 + i);
    const sx = cx + Math.cos(a)*R, sy = topoY + Math.sin(a)*R*0.42;
    circulo(ctx, sx, sy, 4.2, cor.emissivo);
    ctx.globalAlpha = 0.25; circulo(ctx, sx, sy, 9, cor.emissivo);
  }

  // ── C11 · RACHADURAS DE FERIDA ---------------------------------------
  if (T.ferida > 0.35) desenharRachaduras(ctx, cx, cy, T.ferida, t);
}
```

**Anéis orbitais (parâmetros exatos):**

| Anel | Raio X | Raio Y (tilt) | Vel. angular | Largura | α | Traço |
|---|---|---|---|---|---|---|
| 1 | 46 | 15 | +0.55 rad/s | 2.0 | 0.55 | contínuo |
| 2 | 62 | 28 | −0.34 rad/s | 1.6 | 0.42 | `[14, 9]` |
| 3 | 80 | 12 | +0.22 rad/s | 2.4 | 0.35 | `[3, 7]` |
| 4 | 100 | 44 | −0.14 rad/s | 1.2 | 0.28 | contínuo + 3 nós orbitando |

Cada anel tem `tiltFase = i*0.7` e a elipse é redesenhada com `ctx.rotate(sin(t*0.11 + i)*0.18)` — dá vida sem custo.

## 3.4 Rachaduras de ferida

`n = floor(ferida * 9)` rachaduras. Cada uma: polilinha de 5 pontos gerada por `RngX(seedTorre + i)`, do centro para fora, comprimento `18 + 26*ferida`, jitter lateral ±5 px, `strokeStyle` = `#000` (α 0.55) com uma segunda passada em `COR.perigo` α `0.30 + 0.35*sin(t*3.4)` deslocada 1 px — efeito de brasa por dentro.

## 3.5 Estados especiais da torre

| Estado | Efeito visual | Duração |
|---|---|---|
| **Sobrecarga** (habilidade) | núcleo `rN *= 2.1`, anéis aceleram 3×, 18 faíscas/s, aberração +2.5 px | duração da hab. |
| **Escudo ativo** | hexágono de 6 lados, raio 78, `COR.escudo` α 0.18, borda 2 px α 0.6, ondula `r += 3*sin(t*5 + lado)` | enquanto ativo |
| **Congelada** | overlay `#a5f3fc` α 0.35 + 5 cristais hexagonais | debuff |
| **Silenciada** (chefe "O Silêncio") | dessatura torre 70 %, anéis param, núcleo cinza `#475569` | luta |
| **Recarregando** | arco de progresso de 0→2π em `COR.ouro`, raio `rN+11`, largura 3 | cooldown |

---

# 4. INIMIGOS — 22 FORMAS PROCEDURAIS + ELITES + CHEFES

## 4.1 Contrato de desenho

```js
// Tamanho base: r = 10.5 * esc  (esc vem de data/enemies.json)
// Toda função recebe (ctx, e, t) com ctx já transladado para (e.x, e.y)
// e rotacionado para e.ang (direção de marcha). Nada de save/restore extra.
export const FORMAS = { circulo, seta, hexagono, losango, escudo, asa, triangulo,
  fantasma, celula, cruz, canhao, estrela, bolha, verme, prisma, monolito,
  garra, ovo, fumaca, boca, caos, foice, /* chefes: */ tita, rainha, nucleo,
  arauto, serpente, espelho, colmeia, ceifador, silencio, devorador,
  aniquilador, trono };
```

Pré-passo comum a **todos** (feito uma vez, não por forma):

```js
function desenharInimigo(ctx, e, t){
  const r = e.r, f = e.flash;                      // flash 0..1
  ctx.save();
  ctx.translate(e.x, e.y - e.altura);              // altura>0 = voador
  // sombra (feita na camada 2, aqui apenas referência)
  ctx.rotate(e.ang + e.tombo);                     // tombo = inclinação por knockback
  ctx.scale(e.squash.x, e.squash.y);               // squash&stretch
  FORMAS[e.forma](ctx, e, t, r);
  if (f > 0.001){                                  // flash de acerto
    ctx.globalCompositeOperation = 'lighter';
    ctx.globalAlpha = f * 0.85;
    FORMAS[e.forma](ctx, e, t, r, '#ffffff');
    ctx.globalCompositeOperation = 'source-over';
  }
  ctx.restore();
}
```

**Squash & stretch universal (o "juice" que ninguém nota mas todos sentem):**
```
ao levar dano:  squash = {x: 1.22, y: 0.80}  →  volta em 130 ms (easeOutElastic)
ao andar:       squash.y += 0.055 * sin(t*velAnim + seed)   // pisada
ao morrer:      squash = {x: 1.45, y: 0.42}  em 70 ms, depois estoura
velAnim = 6.2 * e.vel
```

## 4.2 As 22 formas — receitas exatas

> Convenção: `r` = raio base. `c1` = `e.cor`, `c2` = `e.cor2`. Contorno sempre `c2` com `lineWidth = max(1.2, r*0.14)`.

**1. `circulo` — Grunhido** `#8b93a7 / #5a6275`
Círculo `r`. Núcleo interno `r*0.42` em `c2`. Um "olho" retangular `r*0.5 × r*0.16` a `x=r*0.3`, em `#e6edf6` α 0.8, que **pisca**: fecha por 90 ms a cada `2.4 + rnd*1.8` s. Anima: `r += 0.4*sin(t*7 + seed)`.

**2. `seta` — Corredor** `#f97362 / #a83c30`
Triângulo isósceles apontando +X: `(r*1.5, 0), (-r*0.8, r*0.85), (-r*0.8, -r*0.85)`. Entalhe traseiro em `c2`: `(-r*0.8,±r*0.85) → (-r*0.35,0)`. **Trilha obrigatória** (§6.5) de 6 pontos, largura `r*0.7 → 0`. Vibra: `ang += 0.09*sin(t*22)`.

**3. `hexagono` — Bruto** `#6b7f9e / #3a4a63`
Hexágono `r` rotação `π/6`. **3 placas de escória**: retângulos `r*0.6 × r*0.34` em `c2` a 120°, com brilho especular `#cbd5e1` α 0.25 no topo. Passo pesado: `y += 1.6*abs(sin(t*3.1))`, e a cada pisada emite 2 partículas de poeira.

**4. `losango` — Enxame** `#a3e635 / #5c7c1a`
Losango `(0,-r*1.25),(r*0.75,0),(0,r*1.25),(-r*0.75,0)`. Centro `#ecfccb` α 0.55. Rotação própria `t*3.4`. Move em zigue: offset perpendicular `sin(t*5.5 + seed)*11`.

**5. `escudo` — Blindado** `#94a3b8 / #475569`
Heráldico: `(0,-r*1.2) → (r*0.95,-r*0.55) → (r*0.8, r*0.5) → (0, r*1.3) → (-r*0.8,r*0.5) → (-r*0.95,-r*0.55)`. **Escudo regenerativo** desenhado por cima: mesmo path escalado 1.22, `strokeStyle #7dd3fc`, `lineWidth 2.4`, α `0.25 + 0.45*(escudo/escudoMax)`; quando quebra → 14 fragmentos poligonais §5.

**6. `asa` — Voador** `#67e8f9 / #0e7490`
Corpo elipse `r*0.7 × r*0.45`. Duas asas: quadráticas `(0,0) → cp(r*0.4, ∓r*1.5) → (−r*0.9, ∓r*0.6)`, **batendo**: `escalaAsaY = 0.35 + 0.65*abs(sin(t*11.5))`. Voadores desenham a **sombra separada no chão** (elipse `r*0.7 × r*0.22`, α `0.28 - altura/300`), altura padrão `26 + 6*sin(t*1.4)`.

**7. `triangulo` — Saltador** `#fbbf24 / #b45309`
Triângulo equilátero `r*1.25`. No ar (`fase salto`): `scale(0.86, 1.24)` + rastro de 3 fantasmas α `[0.28,0.18,0.09]`. Na aterrissagem: anel de choque r 4→34 em 220 ms + shake 0.035 + 6 partículas de poeira.

**8. `fantasma` — Espectro** `#c4b5fd / #6d28d9`
Cabeça: semicírculo `r` superior. Base ondulada: 5 arcos de `r*0.4` com fase `t*4 + i`. `globalAlpha` do corpo oscila `0.42 + 0.28*sin(t*1.7)`. **Atravessa** — desenhado com `globalCompositeOperation='lighter'` quando sobre outro inimigo. 2 olhos ovais `#f5f3ff`.

**9. `celula` — Divisor** `#4ade80 / #15803d`
Círculo `r` com **borda irregular**: 14 vértices `r * (1 + 0.12*sin(i*2.3 + t*1.9))`. Dentro: 3 núcleos menores `r*0.22` orbitando `t*1.1`. Ao morrer, divide em 2: os núcleos "escapam" com `v = 130 px/s` em ±40° e viram os filhos.

**10. `cruz` — Curandeiro** `#86efac / #166534`
Cruz grega, braço `r*0.42` × `r*1.3`. Halo pulsante `r*1.8` α `0.10 + 0.10*sin(t*2.6)`. **Feixe de cura**: para cada aliado curado, curva quadrática com `lineWidth 2`, `strokeStyle #86efac`, `setLineDash([4,6])`, `lineDashOffset = -t*40` — o feixe é a telegrafia: **matar o Curandeiro é a instrução**.

**11. `canhao` — Atirador** `#fb7185 / #9f1239`
Corpo: retângulo arredondado `r*1.5 × r*1.1`, raio 3. Tubo: retângulo `r*1.1 × r*0.38` apontando à torre. **Ao carregar**: círculo na boca do tubo cresce 0→`r*0.4` em 900 ms + linha pontilhada até a torre α `0.15→0.5`. Recuo de 5 px ao disparar.

**12. `estrela` — Teleportador** `#e879f9 / #86198f`
Estrela de 5 pontas, `rExt = r*1.3`, `rInt = r*0.52`, rotação `t*1.6`. **Pré-teleporte** (400 ms): encolhe para `scale 0.15` com `easeInCubic` + 20 partículas implodindo; **pós**: expande de 1.6→1.0 (`easeOutBack`) + anel roxo r 0→46.

**13. `bolha` — Bomba Viva** `#fb923c / #9a3412`
Círculo `r` com 3 manchas `r*0.25` mais escuras. **Pulsação de perigo acelerando**: `r * (1 + 0.10*sin(t*freq))` onde `freq = 4 + 16*proximidade`. A `< 90 px` da torre: overlay branco piscando (`α = 0.5*(sin(t*22)>0)`) + círculo de raio de explosão desenhado no chão (α 0.18, borda tracejada `COR.perigo`). Explosão = §5 `explosao`.

**14. `verme` — Sanguessuga** `#f472b6 / #9d174d`
6 segmentos de raio `r*(1 - i*0.11)` seguindo trajetória histórica (buffer de 24 posições, amostra a cada 4). Cabeça com 2 mandíbulas triangulares. Ao drenar: linha grossa `#f472b6` α 0.5 até a torre + 4 partículas/s viajando pelo cabo.

**15. `prisma` — Refletor** `#a5f3fc / #0891b2`
Triângulo `r*1.2` com **preenchimento em 3 faixas** (`#a5f3fc`, `#67e8f9`, `#22d3ee`) e brilho especular branco na aresta superior. Ao refletir: flash da face atingida em `#ffffff` 60 ms + projétil espelhado desenhado com trilha invertida.

**16. `monolito` — Colosso** `#78716c / #292524`
Retângulo `r*1.1 × r*2.2` com topo chanfrado. **Textura**: 6 linhas horizontais `c2` α 0.5 em alturas pseudoaleatórias fixas. Anda em passos de 0.8 s: `y` cai 3 px + trauma 0.045 + 4 poeiras. Barra de vida sempre visível (é o primeiro "muro").

**17. `garra` — Parasita** `#c084fc / #6b21a8`
Corpo oval `r*0.8 × r`. 4 garras: quadráticas para fora, abrindo/fechando `ang = ±(0.5 + 0.35*sin(t*3.2))`. Ao grudar na torre: desenhado **sobre** a torre com α 0.9 e a torre ganha `-DPS` visual (núcleo escurece 20 %).

**18. `ovo` — Casulo** `#d9f99d / #4d7c0f`
Oval `r*0.85 × r*1.2`. **Rachaduras progressivas** conforme `hp/hpMax`: 0–3 polilinhas brancas α 0.6 aparecendo em 75 %, 50 %, 25 %. Ao morrer, "choca": 20 partículas verdes + 3 Enxames.

**19. `fumaca` — Sombra** `#475569 / #0f172a`
**Sem contorno.** 5 círculos sobrepostos de raio `r*(0.5..0.9)` em posições que orbitam devagar (`t*0.7`), cada um com gradiente radial `c1 → transparente`. α global `0.55 + 0.2*sin(t*1.1)`. Ganha `+70 %` de alfa quando atingida (revela-se por 400 ms).

**20. `boca` — Devorador** `#dc2626 / #450a0a`
Círculo `r` recortado por uma "boca": arco de abertura `0.5 + 0.55*abs(sin(t*2.2))` rad, preenchido em `#450a0a`. 7 dentes triangulares brancos ao longo do arco. Ao engolir ouro: a boca fecha em 120 ms + `scale 1.18` + partícula dourada sugada.

**21. `caos` — Aberração** `#7c3aed / #2e1065`
Polígono de **11 vértices reamostrados a cada 100 ms**: `r * (0.6 + rnd()*0.8)`. Interpola entre a forma antiga e a nova com `easeInOutSine` — pulsa organicamente. Sobreposto: 2 cópias deslocadas ±2 px em `#ff0055` e `#00ffcc` com `lighter` (aberração cromática *da própria entidade*).

**22. `foice` — Ceifeiro** `#f43f5e / #4c0519`
Cabo: linha `r*2.2` em `c2` largura 3. Lâmina: arco de raio `r*1.1`, ângulo 2.4 rad, espessura variável (`r*0.3` no meio, 0 nas pontas), preenchida em gradiente `c1 → #fff` (fio). **Gira** `t*1.8` e deixa trilha em arco `#f43f5e` α 0.3, 5 amostras.

## 4.3 Sobreposições de ELITE (9 tipos, `data/enemies.json`)

Elite = inimigo comum + **moldura** + **partícula assinatura**. A moldura é sempre: polígono de N lados no raio `r*1.55`, `lineWidth 2`, `setLineDash([5,4])`, `lineDashOffset -t*18`, α `0.55 + 0.25*sin(t*2)`.

| Elite | Cor | Lados | Assinatura visual | Partículas |
|---|---|---|---|---|
| Encouraçado | `#94a3b8` | 6 | 4 placas metálicas orbitando `r*1.4` | faíscas ao ser atingido (dano reduzido) |
| Frenético | `#f87171` | 3 | 3 pós-imagens (α .30/.18/.08, atraso 60/120/180 ms) | streaks vermelhos 8/s |
| Colossal | `#4ade80` | 8 | `r *= 1.6`, contorno 3.2 px | poeira pesada a cada passo |
| Regenerativo | `#34d399` | 5 | cruzes verdes subindo 1.2/s | motas verdes orbitais |
| Espinhoso | `#fb923c` | 7 | 10 espinhos triangulares `r*0.35` radiais | faíscas laranja ao refletir |
| Magnético | `#a78bfa` | 4 | 2 anéis contra-rotativos `r*1.8`/`r*2.2` | linhas de campo (4 arcos) |
| Volátil | `#facc15` | 6 | brilho crescente até 2× ao morrer | brasas 12/s |
| Fantasmal | `#c4b5fd` | 5 | α do corpo 0.55, blur falso (3 cópias offset 1.5 px) | névoa 3/s |
| Áureo | `#fcd34d` | 8 | **cintilação**: 4 estrelinhas de 4 pontas piscando | moedinhas 2/s + som "ka-ching" ao spawnar |

**Regra:** elite Áureo sempre acompanha **zoom punch 1.03** no spawn e um som de sino — é a "carta rara" da run.

## 4.4 CHEFES — construção em anéis concêntricos

Chefes usam **composição em 4 anéis**, não uma forma única:
```
R0 núcleo (10–18 px, pulsante, é a hitbox de "peito")
R1 corpo  (28–52 px, a silhueta assinatura)
R2 armadura/pétalas (6–12 peças girando, 44–80 px)
R3 aura/telegrafia (90–170 px, aparece só nos ataques)
```

| Chefe | Silhueta R1 | R2 | Assinatura de fase |
|---|---|---|---|
| **Titã de Ferro** `#94a3b8/#1e293b` | octógono blindado 48 px | 8 placas retangulares girando −0.3 rad/s | fase↑: placas caem no chão como decalques |
| **Rainha do Enxame** `#a3e635/#3f6212` | abdômen oval 44×58 + 6 patas quadráticas | 6 ovos orbitando 62 px | ao desovar: abdômen infla 1.25× e 6 ovos disparam |
| **Núcleo Instável** `#fb923c/#7c2d12` | esfera 34 px com **fissuras animadas** (8 linhas que abrem) | 3 anéis excêntricos | onda de choque: anel branco r 0→420 em 700 ms, `lineWidth 14→1` |
| **Arauto do Vazio** `#a855f7/#2e1065` | ampulheta 40×64 | 4 losangos em órbita elíptica | fissuras: 3 elipses roxas no chão, telegrafia 1.1 s |
| **Serpente Ciclônica** `#22d3ee/#0e7490` | **8 segmentos** raio 30→14 em spline Catmull-Rom | escamas hex por segmento | corta-se ao perder segmento; cabeça acelera 1.15× por segmento perdido |
| **Guardião Espelhado** `#e0f2fe/#0369a1` | hexágono espelhado com gradiente linear rotativo | 6 espelhos planos girando | ao refletir: face pisca branco 80 ms + projétil clone |
| **Colmeia Ancestral** `#facc15/#78350f` | favo: 7 hexágonos aninhados | escudo hexagonal 96 px, α ∝ escudo | escudo racha em 6 quando quebra |
| **Ceifador de Almas** `#f43f5e/#4c0519` | manto (5 arcos ondulantes) + foice 70 px | 3 crânios orbitando | teleporte: implode/explode + cabo de dreno |
| **O Silêncio** `#334155/#020617` | **buraco**: círculo `#020617` com borda `#334155` e nada dentro | 12 traços radiais que se recolhem | ao silenciar: **todo o mundo dessatura 65 % em 500 ms** |
| **Devorador de Mundos** `#b91c1c/#450a0a` | boca gigante 60 px, 12 dentes, garganta em gradiente | 5 tentáculos quadráticos | engolir: cone de sucção com 30 partículas puxadas |
| **O Aniquilador** (super) `#f43f5e/#1e1b4b` | combina 3 silhuetas por fase, morfando em 900 ms | 12 lâminas | 5 fases, cada uma troca R1 |
| **Trono Vazio** (super) `#8b5cf6/#1e1b4b` | trono geométrico 78 px, **vazio dentro** | 8 pilares orbitando 140 px | fase 5: a arena inteira inverte cores por 3 s |

**Barra de vida de chefe:** DOM, topo da tela, 72 % da largura, altura 18 px, com:
- Segmentação por fases (`n-1` divisórias brancas α 0.6).
- Camada "dano recente" em `#fff` α 0.35 que só desce após 420 ms de atraso (`easeOutQuart`, 500 ms).
- Ao trocar de fase: barra pisca branco, **hitstop 180 ms**, trauma 0.22, zoom punch 1.045.

## 4.5 Telegrafia (regra inegociável)

Todo ataque de chefe tem **3 estágios visuais**:
1. **Aviso** (≥ 700 ms): forma da zona desenhada no chão, `strokeStyle` da cor do chefe, α 0.25, `lineWidth 2`, `setLineDash([8,8])` girando.
2. **Carga** (últimos 300 ms): preenchimento sobe de 0→100 % da zona (α 0.30), borda vira `COR.perigo` e a espessura vai a 4 px, pulso de 6 Hz.
3. **Impacto**: flash branco da zona 70 ms, trauma, partículas, decalque no chão por 6 s.

## 4.6 Barras de vida (inimigo comum)

Só aparecem se `hpMax > 1.8 × hpMédioDaOnda` **ou** elite/chefe. Largura `r*2.4`, altura 3 px, `y = -r-9`. Fundo `#000` α 0.55, preenchimento com cor por faixa: `>60 % #4ade80`, `30–60 % #facc15`, `<30 % #ef4444`. Aparece por 1.6 s após dano e some com fade 250 ms.

## 4.7 Morte — a coreografia (2.5 s de dopamina em 400 ms)

```
t=0ms     hitstop 18ms (comum) / 70ms (elite) / 180ms (chefe-fase)
t=0ms     squash {1.45, 0.42}
t=0ms     flash branco full-body α 1.0
t=40ms    estouro: N fragmentos poligonais (N = 5 + floor(r*0.6), máx 22)
          velocidade 90–260 px/s radial + gravidade 320 px/s²
t=40ms    anel de choque r 0→(r*3.4) em 260ms, lineWidth 5→0.5, α 0.75→0
t=60ms    moedas: M = ceil(log10(ouro)+1) coletáveis, arco balístico
t=60ms    número de ouro "+X" sobe do ponto de morte
t=90ms    decalque de mancha no chão (só qualidade≥1), α 0.35, fade 6s
t=120ms   partículas secundárias: 3 fumaças (não-aditivas) subindo 30px/s
```

---

# 5. SISTEMA DE PARTÍCULAS

## 5.1 Arquitetura — Structure of Arrays + free-list

```js
// fx/particulas.js
const CAP = 4096;                        // 8192 em ultra
const P = {
  x:new Float32Array(CAP), y:new Float32Array(CAP),
  vx:new Float32Array(CAP), vy:new Float32Array(CAP),
  ax:new Float32Array(CAP), ay:new Float32Array(CAP),   // aceleração (gravidade/drag alvo)
  vida:new Float32Array(CAP), vidaMax:new Float32Array(CAP),
  t0:new Float32Array(CAP), t1:new Float32Array(CAP),   // tamanho inicial/final
  rot:new Float32Array(CAP), vrot:new Float32Array(CAP),
  r:new Uint8Array(CAP), g:new Uint8Array(CAP), b:new Uint8Array(CAP),
  a0:new Float32Array(CAP), a1:new Float32Array(CAP),
  tipo:new Uint8Array(CAP), blend:new Uint8Array(CAP),  // 0=source-over 1=lighter
  arrasto:new Float32Array(CAP), semente:new Float32Array(CAP),
};
let vivos = 0;                            // partículas 0..vivos-1 estão ativas
```

**Swap-remove** ao morrer (`P.x[i] = P.x[--vivos]` para todos os campos) — zero alocação, zero GC, cache-friendly. Emissão além de `CAP`: **substitui a partícula mais velha do tipo mais barato** (prioridade: poeira < fumaça < faísca < fragmento < anel < número).

## 5.2 Loop de atualização (integração semi-implícita, dt fixo)

```js
export function atualizar(dt){
  for (let i=0;i<vivos;i++){
    P.vx[i] = (P.vx[i] + P.ax[i]*dt) * Math.pow(P.arrasto[i], dt*60);
    P.vy[i] = (P.vy[i] + P.ay[i]*dt) * Math.pow(P.arrasto[i], dt*60);
    P.x[i] += P.vx[i]*dt;  P.y[i] += P.vy[i]*dt;
    P.rot[i] += P.vrot[i]*dt;
    if ((P.vida[i] -= dt) <= 0) remover(i--);
  }
}
```
`dt` é **fixo em 1/60** com acumulador; hitstop faz `dt = 0` para a simulação mas `dt = 1/60 * 0.15` para partículas (elas continuam, em câmera lenta — é isso que faz o hitstop "sentir bom" em vez de travado).

## 5.3 Catálogo de 18 tipos (parâmetros literais)

| # | Tipo | Forma | Vida (s) | Tam 0→1 | Vel (px/s) | Arrasto | Grav (px/s²) | α 0→1 | Blend | Curva de α |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `faisca` | linha 4:1 na direção de `v` | 0.28–0.46 | 2.6→0.4 | 180–420 | 0.90 | 240 | 1.0→0 | lighter | `1-t²` |
| 1 | `poeira` | círculo | 0.55–0.95 | 3.0→7.5 | 20–70 | 0.86 | −18 | 0.45→0 | normal | `sin(πt)` |
| 2 | `fumaca` | círculo com gradiente | 1.1–1.9 | 6→22 | 12–40 | 0.93 | −34 | 0.30→0 | normal | `sin(πt)^0.7` |
| 3 | `icor` (sangue de vazio) | círculo | 0.5–0.8 | 3.2→1.0 | 90–240 | 0.88 | 420 | 0.85→0 | normal | `1-t^3` |
| 4 | `fragmento` | polígono 3–5 lados | 0.65–1.25 | `r*0.28` fixo | 90–260 | 0.91 | 320 | 1→0 | normal | `1-t^4` |
| 5 | `anel` | arco, `lineWidth` interpolada | 0.22–0.34 | 0→`R` | — | — | — | 0.8→0 | lighter | `(1-t)^1.6` |
| 6 | `brilho` | círculo radial gradient | 0.18–0.30 | 8→26 | 0 | — | 0 | 0.9→0 | lighter | `(1-t)^2` |
| 7 | `moeda` | disco + brilho especular | 0.9 (voo) | 5 fixo | balístico | 1.0 | 900 | 1→1 | normal | — |
| 8 | `streak` | quad esticado por `v` | 0.16–0.26 | `len=|v|*0.06` | herda | 0.82 | 0 | 0.75→0 | lighter | `1-t` |
| 9 | `plasma` | 2 círculos concêntricos | 0.35–0.60 | 5→0 | 60–180 | 0.94 | 0 | 1→0 | lighter | `1-t²` |
| 10 | `cinza` | quad 2×2 rotativo | 2.5–4.5 | 1.8 fixo | 8–24 | 0.98 | −6 + vento | 0.5→0 | normal | `sin(πt)` |
| 11 | `neve` | círculo 1.2–2.4 | 6–11 | fixo | 10–26 | 0.99 | 14 | 0.7 const | normal | fade nos 15 % finais |
| 12 | `esporo` | círculo + halo | 3–6 | 1.5→3 | 6–20 | 0.99 | −10 | 0.5→0 | lighter | `sin(πt)` |
| 13 | `bolha` | anel (só contorno) | 2.5–5 | 2→5 | 4–14 | 0.99 | −40 | 0.4→0 | normal | `sin(πt)` |
| 14 | `brasa` | círculo `#f97316`→`#7c2d12` | 1.2–2.4 | 2.2→0.6 | 20–60 | 0.97 | −55 | 0.9→0 | lighter | `1-t²` |
| 15 | `detrito` | polígono 4 lados | 8–16 | 2–6 | 6–18 | 1.0 | 0 | 0.35 const | normal | fade extremos |
| 16 | `glitch` | retângulo `w=8..40, h=1..3` | 0.10–0.22 | fixo | 0 | — | 0 | 0.7→0 | lighter | passo (liga/desliga a 20 Hz) |
| 17 | `confete` | quad rotativo bicolor | 1.6–3.0 | 4×7 | 120–320 | 0.93 | 380 | 1→0 | normal | `1-t^5` |

## 5.4 Emissores (assinatura única, tudo em um lugar)

```js
export function emitir(tipo, x, y, n, opts = {}) {…}

// ── Presets prontos, chamados pelo jogo ──────────────────────────────
export const FX = {
  acerto      : (x,y,ang,cor)   => emitir(0,x,y, 3, {ang, arco:0.9, cor}),
  critico     : (x,y,ang,cor)   => { emitir(0,x,y, 9, {ang, arco:1.4, vel:[260,520], cor});
                                     emitir(6,x,y, 1, {tam:[10,34], cor:'#fbbf24'}); },
  morte       : (x,y,r,cor)     => { emitir(4,x,y, Math.min(22, 5+(r*0.6)|0), {cor});
                                     emitir(3,x,y, 6, {cor});
                                     anelChoque(x,y, r*3.4, 0.26, cor);
                                     emitir(2,x,y, 3, {cor:'#1e293b'}); },
  explosao    : (x,y,R,cor)     => { emitir(0,x,y, 26, {vel:[200,560], cor});
                                     emitir(2,x,y, 8,  {tam:[10,34]});
                                     anelChoque(x,y, R, 0.34, cor, 14);
                                     anelChoque(x,y, R*0.6, 0.20, '#fff', 6); },
  ouro        : (x,y,qtd)       => emitirMoedas(x,y, Math.min(9, 1+Math.log10(qtd+1)|0)),
  upgradeOk   : (x,y,cor)       => { emitir(0,x,y, 14, {arco:6.28, vel:[90,240], cor});
                                     emitir(6,x,y, 1,  {tam:[6,40], cor}); },
  prestigio   : (x,y)           => { emitir(17,x,y,140,{vel:[180,620]});
                                     for(let k=0;k<5;k++) anelChoque(x,y, 120+k*90, 0.8+k*0.12, RARIDADE[k+2], 10-k); },
};
```

## 5.5 Desenho em lote (1 path por combinação tipo+blend)

```js
export function desenhar(ctx){
  // Passo 1: blend 'lighter' (faísca, anel, brilho, streak, plasma, brasa, esporo, glitch)
  ctx.globalCompositeOperation = 'lighter';
  desenharFaixa(ctx, i => P.blend[i]===1);
  // Passo 2: blend normal
  ctx.globalCompositeOperation = 'source-over';
  desenharFaixa(ctx, i => P.blend[i]===0);
}
```
Dentro de `desenharFaixa`, agrupa por `tipo` e usa **um único `Path2D` acumulado por cor arredondada a 5 bits por canal** (≈ 32 768 buckets, na prática 6–14 por frame). Isso corta as chamadas de `fill()` de ~2000 para ~12.

---

# 6. JUICE — CATÁLOGO EXAUSTIVO COM PARÂMETROS

## 6.1 Screen shake (modelo de trauma — Squirrel Eiserloh)

```js
export const abalo = { trauma:0, x:0, y:0, ang:0, semente:Math.random()*1e4 };

const MAX_DESLOC = 22;      // px de mundo
const MAX_ANG    = 0.035;   // rad
const FREQ       = 26.0;    // Hz do ruído
const DECAI      = 3.15;    // 1/s exponencial

export function abalar(qtd){ abalo.trauma = Math.min(1, abalo.trauma + qtd * Cfg.abaloEscala); }

export function atualizarAbalo(dt, t){
  abalo.trauma *= Math.exp(-DECAI*dt);
  if (abalo.trauma < 0.002) { abalo.trauma = 0; abalo.x = abalo.y = abalo.ang = 0; return; }
  const s = abalo.trauma * abalo.trauma;                    // quadrático = "sente" melhor
  abalo.x   = MAX_DESLOC * s * ruido1D(t*FREQ + 0.0);
  abalo.y   = MAX_DESLOC * s * ruido1D(t*FREQ + 137.3);
  abalo.ang = MAX_ANG    * s * ruido1D(t*FREQ + 971.1);
}
```
`ruido1D` = Perlin 1D de 256 valores pré-computados (interpolação `smoothstep`), **nunca `Math.random()`** — random puro gera chiado feio, Perlin gera "soco".

**Tabela de trauma (valores finais, já balanceados):**

| Evento | Trauma | Cap acumulado/frame |
|---|---|---|
| Acerto normal | 0.012 | 0.05 |
| Crítico | 0.045 | 0.12 |
| Mega-crítico (≥10×) | 0.10 | — |
| Morte de comum | 0.020 | 0.08 |
| Morte de elite | 0.095 | — |
| Explosão (Bomba/AoE) | 0.14 | — |
| Colosso pisando | 0.045 | — |
| Torre atingida | 0.18 | — |
| Torre perto de morrer (< 15 % vida) | 0.05/s contínuo | — |
| Onda de choque de chefe | 0.28 | — |
| Troca de fase de chefe | 0.22 | — |
| Morte de chefe | 0.40 | — |
| Ascensão / Prestígio | 0.45 | — |
| Novo tier de torre | 0.30 | — |

**Direcional:** para impactos com direção conhecida, 60 % do abalo é `ang`-alinhado: `abalo.x += cos(ang)*qtd*14`.

## 6.2 Hitstop (congelamento de impacto)

```js
export const parada = { ms:0 };
const CAP_PARADA = 240;      // ms — nunca mais que isso acumulado

export function congelar(ms){ parada.ms = Math.min(CAP_PARADA, parada.ms + ms * Cfg.paradaEscala); }
```

| Evento | ms | Escala de tempo durante |
|---|---|---|
| Acerto normal | 0 | — |
| Crítico | 26 | 0.00 sim / 0.15 fx |
| Mega-crítico | 55 | 0.00 / 0.15 |
| Morte de comum | 12 | 0.00 / 0.20 |
| Morte de elite | 70 | 0.00 / 0.12 |
| Explosão grande | 45 | 0.00 / 0.18 |
| Torre atingida | 90 | 0.00 / 0.10 |
| Fase de chefe | 180 | 0.00 / 0.08 |
| Morte de chefe | 300 | rampa 0→1 em 300 ms `easeInCubic` |
| Morte de super-chefe | 420 | idem + slow-mo §6.10 |

**Regra de ouro:** com > 60 inimigos vivos, `paradaEscala *= 0.45` — senão o jogo vira slideshow numa horda.

## 6.3 Números de dano

```js
// fx/numeros.js  — pool fixo de 128
const NUM = { texto:[], x:[], y:[], vy:[], vida:[], escala:[], cor:[], tipo:[], contorno:[], mesclas:[] };
```

**Tipos e estilos:**

| Tipo | Fonte | Tam base | Cor | Contorno | Extra |
|---|---|---|---|---|---|
| normal | `800 {s}px "Inter", system-ui` | 15 | `#fef3c7` | `#000` 3 px α .55 | — |
| crítico | `900 {s}px` | 22 | `#fbbf24` | `#7c2d12` 3.5 px | estrela 4 pontas atrás, α .35 |
| mega-crítico | `900 {s}px` itálico | 30 | `#f97316` | duplo: `#000` 5 px + `#fff` 1.5 px | tremor 4 px por 120 ms + `!` |
| dot/veneno | `700 {s}px` | 12 | `#a3e635` | `#000` 2 px | sobe mais devagar |
| gelo | `700` | 12 | `#67e8f9` | — | 3 flocos ao redor |
| execução | `900` | 26 | `#f43f5e` | `#450a0a` 4 px | texto "EXECUTADO" pequeno acima |
| ouro | `800` | 14 | `#fcd34d` | `#78350f` 2.5 px | prefixo "+", ícone moeda 6 px |
| cura | `800` | 14 | `#86efac` | — | prefixo "+" |
| bloqueado | `700` | 12 | `#94a3b8` | — | texto "BLOQ" |

**Escala por magnitude** (o número gigante *parece* gigante):
```js
const mag = Math.max(0, Math.log10(dano + 1) - Math.log10(danoMedioRecente + 1));
const s   = tamBase * (1 + Math.min(0.85, mag * 0.34));
```

**Curva de movimento (o coração):**
```
0–90 ms    : escala 0 → 1.25   easeOutBack(c1=2.2)      | y estático | α 0→1 em 40 ms
90–170 ms  : escala 1.25 → 1.0 easeOutQuad
0–720 ms   : y -= 46 * easeOutQuart(t)                   | x += jitter*sin(t*7)  (jitter ±9 px)
430–720 ms : α 1 → 0  (linear no último 40 % da vida)
crítico    : +rotação inicial ±0.14 rad → 0 (easeOutBack), +tremor 4 px decaindo em 120 ms
```

**Coalescência (evita spam):** se um novo número aparece a < 26 px e < 110 ms do anterior **no mesmo alvo**, ele **funde**: soma o valor, reinicia a fase de pop com `escala += 0.12` (teto 1.9) e mostra sufixo `×2`, `×3`… em `#fff` α 0.8, 60 % do tamanho.

**Densidade adaptativa:** número só nasce se `NUM.vivos < 90 * QUALIDADE[q].numeros`. Acima disso, agrega em um único número por inimigo a cada 200 ms. `Cfg.numeros_dano` (0 todos / 1 só críticos / 2 nenhum) é respeitado.

## 6.4 Flashes

| Flash | Onde | Cor | α pico | Duração | Curva |
|---|---|---|---|---|---|
| Acerto em inimigo | entidade | `#ffffff` | 0.85 | 90 ms | `(1-t)^2` |
| Crítico em inimigo | entidade | `#fde68a` | 1.0 | 130 ms | `(1-t)^1.5` |
| Escudo quebrado | entidade | `#7dd3fc` | 0.9 | 180 ms | `(1-t)^2` |
| Torre atingida | tela inteira | `#ef4444` | 0.22 | 160 ms | `(1-t)^3` |
| Boss spawn | tela inteira | cor do chefe | 0.30 | 380 ms | `sin(πt)` |
| Fase de chefe | tela inteira | `#ffffff` | 0.35 | 120 ms | `(1-t)^2` |
| Upgrade comprado | botão | cor da raridade | 0.55 | 220 ms | `(1-t)^2` |
| Prestígio | tela inteira | `#ffffff` | 0.95 | 620 ms | `sin(πt)^0.5` |
| Nova era | tela inteira | acento da era | 0.40 | 900 ms | `sin(πt)` |

**Limite de segurança (obrigatório, WCAG 2.3.1):** no máximo **3 flashes de tela ≥ α 0.20 por segundo**. Contador global; excedentes são reduzidos a α 0.10. Com `Cfg.reduzirMovimento`, **todo** flash de tela cai para α ≤ 0.12 e duração ×1.6.

## 6.5 Trilhas (ribbons)

```js
// Buffer circular por entidade: 16 pontos, amostra a cada 16 ms
function desenharTrilha(ctx, pts, corA, corB, larguraMax){
  for (let i=1;i<pts.length;i++){
    const t = i/pts.length;
    ctx.globalAlpha = (1-t) * 0.7;
    ctx.lineWidth = larguraMax * (1-t);
    ctx.strokeStyle = mixHex(corA, corB, t);
    ctx.lineCap = 'round';
    linha(ctx, pts[i-1].x, pts[i-1].y, pts[i].x, pts[i].y);
  }
}
```

| Entidade | Pontos | Largura máx | Cores | Blend |
|---|---|---|---|---|
| Projétil básico | 8 | 3.5 | `#fde68a → #f59e0b` | lighter |
| Projétil perfurante | 12 | 5.0 | `#67e8f9 → #0e7490` | lighter |
| Projétil de vazio | 14 | 6.0 | `#c084fc → #2e1065` | lighter |
| Ricochete | 10 | 4.0 | `#a3e635 → #365314` | lighter |
| Corredor (inimigo) | 6 | `r*0.7` | `#f97362 → transparente` | normal |
| Ceifeiro (arco) | 5 | `r*0.5` | `#f43f5e → transparente` | lighter |
| Moeda voando | 5 | 2.5 | `#fcd34d → transparente` | lighter |
| Elite Frenético | 3 (pós-imagens, não ribbon) | — | silhueta α .30/.18/.08 | normal |

## 6.6 Aberração cromática

Só qualidade ≥ 1. Aplicada em `cnvFx` (o buffer já renderizado), **não por entidade**:

```js
export function aberracao(ctxDest, buffer, px){
  if (px < 0.4) { ctxDest.drawImage(buffer,0,0); return; }
  ctxDest.globalCompositeOperation = 'lighter';
  // canal R deslocado, canal B deslocado ao contrário, G no lugar
  desenharCanal(ctxDest, buffer, -px, 0, 'rgba(255,0,0,1)');
  desenharCanal(ctxDest, buffer,  0,  0, 'rgba(0,255,0,1)');
  desenharCanal(ctxDest, buffer, +px, 0, 'rgba(0,0,255,1)');
}
```
`desenharCanal` usa um canvas de máscara com `globalCompositeOperation='multiply'` (custo: 3 `drawImage` em buffer 1/2 resolução — ~0.7 ms).

**Fórmula de intensidade:**
```js
px = (0.35                                  // linha de base sempre presente (sutil)
    + 5.2 * abalo.trauma                    // acompanha o soco
    + 1.6 * chefeVivo                       // pressão de chefe
    + 2.4 * (vida < 0.25 ? 1 : 0)           // quase morrendo
    + 3.8 * pulsoPrestigio                  // 0..1
    ) * QUALIDADE[q].aberr * Cfg.aberrEscala;
px = Math.min(px, 9.0);
```

## 6.7 Vinheta

Gradiente radial em `cnvVeu`, recriado só quando muda de era ou resize:
```
inner: 0.42 * min(w,h)   → rgba(cor, 0)
outer: 0.78 * hipotenusa → rgba(cor, alphaFinal)
```
```js
alphaFinal = era.vinhetaBase                        // 0.24 … 0.46
  + 0.34 * Math.max(0, 1 - vida/0.30)               // vida baixa
  + 0.16 * chefeVivo
  + 0.10 * Math.sin(t*1.6) * (vida < 0.30 ? 1 : 0); // batimento cardíaco
```
Com vida < 30 %, a vinheta ganha **tinta vermelha**: interpola `era.vinheta → #7f1d1d` em `(1 - vida/0.30)` e pulsa a **1.6 Hz** (batimento). Abaixo de 12 %, 2.6 Hz.

## 6.8 Bloom falso (barato e bonito)

```js
export function bloom(ctxDest, cena, forca){
  // 1. downsample para 1/4
  bctx.clearRect(0,0,bw,bh);
  bctx.drawImage(cena, 0,0, bw,bh);
  // 2. threshold: mantém só o que é claro — via 'color-dodge' contra cinza
  bctx.globalCompositeOperation = 'color-dodge';
  bctx.fillStyle = 'rgb(184,184,184)';        // limiar ≈ 0.72
  bctx.fillRect(0,0,bw,bh);
  bctx.globalCompositeOperation = 'source-over';
  // 3. blur: ctx.filter se suportado, senão 4 drawImage deslocados
  if (SUPORTA_FILTER){ b2ctx.filter = 'blur(7px)'; b2ctx.drawImage(bcnv,0,0); b2ctx.filter='none'; }
  else quadBlur(b2ctx, bcnv, 2.5);
  // 4. composita aditivo
  ctxDest.globalCompositeOperation = 'lighter';
  ctxDest.globalAlpha = 0.55 * forca;
  ctxDest.drawImage(b2cnv, 0,0, W,H);
  ctxDest.globalAlpha = 1; ctxDest.globalCompositeOperation = 'source-over';
}
```
`forca = 0.75 + 0.35*aquecimentoTorre + 0.6*pulsoPrestigio`, teto 1.8. Buffer sempre `1/4` da resolução (ou `1/6` se `dpr < 1.5`).

## 6.9 Zoom punch

```js
export const zoom = { alvo:1, atual:1, mola:0 };
export function socar(qtd, dur=260){ zoom.mola = Math.max(zoom.mola, qtd); zoom.dur = dur; }
// atual = 1 + mola * (1 - easeOutExpo(t/dur));  mola decai a 0
```

| Evento | Escala extra | Duração | Curva |
|---|---|---|---|
| Mega-crítico | +0.020 | 200 ms | `easeOutExpo` |
| Morte de elite | +0.026 | 240 ms | `easeOutExpo` |
| Elite Áureo spawna | +0.030 | 300 ms | `easeOutBack` |
| Explosão grande | +0.034 | 280 ms | `easeOutExpo` |
| Chefe entra | **−0.080** (zoom out) → volta | 900 ms | `easeInOutSine` |
| Fase de chefe | +0.045 | 320 ms | `easeOutExpo` |
| Chefe morre | +0.070 então −0.05 | 1100 ms | dupla |
| Nova era | −0.12 → 1.0 | 1600 ms | `easeInOutSine` |
| Prestígio | 1.0 → 0.55 → 1.35 → 1.0 | 2400 ms | keyframes |
| Novo tier de torre | +0.055 | 420 ms | `easeOutBack` |

**Regra:** zoom punch **sempre** centrado na torre, **exceto** morte de chefe (centrado no chefe, com lerp de volta em 700 ms).

## 6.10 Slow-motion

```js
export const tempoJogo = { escala:1, alvo:1, taxa:8.0 };
// escala = Ux.approach(escala, alvo, dt, taxa)
```

| Gatilho | Escala | Entrada | Sustentação | Saída | Áudio |
|---|---|---|---|---|---|
| Chefe entra na arena | 0.42 | 140 ms | 800 ms | 500 ms | pitch 0.82, filtro LP 900 Hz |
| Chefe a < 8 % de vida (uma vez) | 0.30 | 100 ms | 900 ms | 600 ms | pitch 0.75 |
| Golpe final no chefe | 0.18 | 60 ms | 550 ms | 900 ms | pitch 0.6 + reverb |
| Torre a < 5 % de vida | 0.55 | 200 ms | contínuo | 400 ms | LP 1400 Hz |
| Prestígio (implosão) | 0.25 | 180 ms | 1200 ms | 1000 ms | pitch 0.7 → 1.4 |
| Habilidade "Tempo Fraturado" | 0.35 | 80 ms | duração | 350 ms | pitch 0.8 |

Durante slow-mo, as **partículas rodam em `escala^0.65`** (ficam relativamente mais rápidas → sensação cinematográfica, não de lag) e o **bloom sobe ×1.3**.

## 6.11 Sacudida de UI e micro-feedbacks

| Elemento | Gatilho | Animação |
|---|---|---|
| Contador de ouro | ganho | escala 1→1.14→1 em 180 ms (`easeOutBack`), cor `#fff`→`#fcd34d` |
| Contador de ouro | gasto | escala 1→0.92→1 em 140 ms, flash `#f43f5e` α 0.4 |
| Contador de ouro | número rolando | interpolação `easeOutExpo` 350 ms, **nunca salto seco** |
| Botão de upgrade acessível | ouro ≥ custo | borda `#4ade80`, pulso α 0.4→0.8 a 1.2 Hz |
| Botão inacessível | clique | shake horizontal ±5 px, 3 ciclos, 260 ms + som "nope" |
| Barra de onda | progresso | preenchimento `easeOutQuart`, cabeça com brilho de 12 px |
| Aba com novidade | desbloqueio | ponto `#f43f5e` 6 px pulsando + bounce da aba (±3 px, 2 ciclos) |
| Ícone de habilidade | pronta | anel completo + brilho + escala 1.08 pulsando a 0.8 Hz |
| Toast | entrada | slide-in 180 ms `easeOutBack` do topo + escala 0.9→1 |

---

# 7. TRANSIÇÕES DE TELA

## 7.1 Banner de onda (a cada onda)

```
0–140 ms   : barra horizontal (altura 46px, y=22%) desliza da esquerda,
             largura 0→100% (easeOutQuint), cor: painelAlto + borda acento 2px
140–200 ms : texto "ONDA 47" aparece, letter-spacing 18px→2px (easeOutQuart), α 0→1
200–1100ms : sustenta; subtítulo em 11px (ex.: "3 elites detectados")
1100–1350  : barra encolhe para a direita (easeInQuint), texto some antes (α em 120ms)
```
**Onda múltipla de 5:** cor da borda vira `#38bdf8`. **De 10:** `#a855f7` + 20 confetes. **Onda de chefe:** ver 7.2.

## 7.2 Entrada de chefe (o momento mais importante do jogo)

```
t=0      : música corta para stinger (2 notas descendentes), timeScale → 0.42
t=0      : letterbox: 2 barras pretas descem/sobem para 11% da altura cada (280ms, easeOutQuint)
t=120ms  : vinheta +0.16, aberração +1.6px
t=200ms  : nome do chefe entra da direita, 42px 900, cor do chefe,
           com sombra 0 4px 24px cor@0.6; subtítulo (lore) em 13px abaixo, atraso 120ms
t=400ms  : silhueta do chefe se materializa: 30 partículas convergindo + α 0→1 (600ms)
t=700ms  : anel de aviso no chão: r 0→220, lineWidth 6→2, cor do chefe
t=1100ms : FLASH branco α 0.30 (120ms) + trauma 0.28 + zoom out −0.08
t=1250ms : letterbox recolhe (320ms), timeScale volta a 1.0 (500ms)
t=1400ms : barra de vida do chefe desce do topo (easeOutBack, 380ms)
```

## 7.3 Mudança de Era (a cada bioma novo)

```
0–300ms   : timeScale 0.6; todas as cores do fundo começam a interpolar
0–900ms   : "cortina hexagonal": 90 hexágonos (raio 74) preenchem a tela em
            ordem de distância ao centro + ruído, cada um com pop de 160ms
            (escala 0→1, easeOutBack). Cor: acento da era NOVA.
900–1200  : tela 100% coberta; texto "ERA III — DESERTO DE ESCÓRIA" + lore
1200–2100 : hexágonos somem na ordem inversa (escala 1→0, easeInBack, 140ms cada)
            revelando o novo bioma já montado
2100–2400 : zoom de −0.12 volta a 1.0; timeScale 1.0
```
Custo: 90 hexágonos = 1 `Path2D` reconstruído por frame — ~0.4 ms. Aceitável por ser evento raro.

## 7.4 Prestígio / Ascensão (o clímax)

```
FASE 1 — IMPLOSÃO (0–1400ms), timeScale 0.25
  0ms     : todos os inimigos param, viram silhuetas brancas e são SUGADOS
            para a torre com aceleração 900px/s² (fica lindo)
  0–600   : anéis orbitais aceleram: 0.55 → 9.0 rad/s (easeInCubic)
  200ms   : núcleo cresce rN 12 → 64 (easeInExpo), aberração 0→9px
  600ms   : vinheta 0.26 → 0.85, bloom força 0.75 → 1.8
  1100ms  : a torre inteira encolhe para escala 0.02 em 300ms (easeInQuint)

FASE 2 — DETONAÇÃO (1400–2200ms)
  1400ms  : FLASH BRANCO α 0.95, 620ms, sin(πt)^0.5
  1400ms  : trauma 0.45 ; 5 anéis de choque (r 120,210,300,390,480)
  1400ms  : 140 confetes nas cores de raridade + 60 fragmentos
  1450ms  : todo o HUD faz fade-out (200ms)
  1700ms  : contador de moeda de prestígio aparece no centro, 64px,
            rolando 0 → valor final em 900ms (easeOutExpo) com tick sonoro
            a cada 40ms (pitch subindo 1.0 → 1.6)

FASE 3 — RENASCIMENTO (2200–3600ms)
  2200ms  : arena redesenhada vazia; torre reaparece em escala 0 → 1
            (easeOutElastic, 900ms) já com o novo emblema
  2600ms  : anéis reacendem um a um (200ms de intervalo)
  3000ms  : HUD volta com stagger de 40ms por elemento
  3400ms  : toast "ASCENSÃO #7 — +42% dano permanente"
  3600ms  : timeScale 1.0
```

## 7.5 Retorno de offline

```
0ms     : overlay escuro α 0.7 (fade 220ms)
200ms   : card central (escala 0.9→1, easeOutBack)
          "VOCÊ ESTEVE FORA POR 6h 12min"
400ms   : linhas de ganho aparecem em stagger de 90ms:
          ouro / ondas / kills / itens — cada uma com número rolando (600ms)
1200ms  : botão "COLETAR" pulsa; ao clicar → 40 moedas voam para o HUD
          com atraso escalonado de 18ms e trilha dourada
```

---

# 8. FEEDBACK DE COMPRA DE UPGRADE

## 8.1 Anatomia do botão (DOM, mas com regras de animação de canvas)

```
[ícone 34px] NOME DO UPGRADE          Nv. 27
             efeito atual → próximo    [ 1.24e6 ⬤ ]
[───────── barra de próximo marco ─────────]
```

## 8.2 Sequência de compra (total: 420 ms)

| t (ms) | Efeito |
|---|---|
| 0 | `scale(0.94)` em 55 ms (`easeOutQuad`) — o "afundar" |
| 55 | `scale(1.06)` em 110 ms (`easeOutBack c1=3.0`) — o "estalo" |
| 55 | flash da cor de raridade α 0.55 → 0, 220 ms |
| 55 | 14 partículas `faisca` da cor da raridade saindo das bordas do botão |
| 60 | som: onda quadrada 660 Hz → 990 Hz em 70 ms + click branco 8 ms |
| 70 | número do nível: `+1` sobe 22 px em 500 ms, α 1→0, cor `#4ade80` |
| 70 | contador de ouro faz `scale 0.92` e rola para o novo valor (350 ms) |
| 80 | novo custo aparece com `blur(4px)→0` + α 0→1 em 180 ms |
| 90 | texto de efeito faz **odômetro**: dígitos rolam verticalmente, 260 ms |
| 165 | `scale(1.0)` em 90 ms |
| 165 | torre reage: pulso de `carga 0→1→0` em 300 ms + brilho no anel |
| 200 | se cruzar marco (10/25/50/100) → §8.3 |

**Compra múltipla (10×/100×/MAX):** a sequência **não** repete 100 vezes. Executa uma vez com intensidade escalada: `escalaFlash = min(1.6, 0.55 * (1 + log10(n)))`, partículas `14 * min(3, 1+log10(n))`, e o `+1` vira `+N` com fonte `min(30, 16 + 4*log10(n))px`.

## 8.3 Marco de upgrade (a cada 10/25/50/100 níveis)

```
0ms   : botão inteiro ganha borda dourada 3px, α 0→1 em 120ms
60ms  : "placa" gira em Y (scaleX 1→0→1, 340ms) revelando o novo bônus de marco
120ms : 22 partículas `fragmento` douradas + 1 `brilho` grande
180ms : anel de choque dourado saindo do botão (r 0→180, 300ms)
200ms : toast "MARCO Nv.50 — Dano ×2" com ícone
240ms : trauma 0.06 (leve), som: acorde maior (3 osciladores, 0.35s)
```

## 8.4 Estados do botão

| Estado | Visual |
|---|---|
| Comprável | borda `#4ade80` α 0.55, custo em `#fcd34d`, hover eleva 2 px + sombra |
| Comprável (novo!) | + badge `#f43f5e` pulsando + glow externo 8 px |
| Caro | opacidade 0.55, custo em `#f87171`, borda `#233048` |
| Máximo | fundo `#1a2e1a`, texto "MÁXIMO", ícone ✓ verde, sem hover |
| Bloqueado | opacidade 0.30, ícone de cadeado, texto do requisito |
| Prestes a desbloquear (≥ 80 % do req.) | barra de progresso na base, `#38bdf8` |

---

# 9. CELEBRAÇÃO DE MARCOS

## 9.1 Tabela mestra de celebrações

| Marco | Intensidade | Confetes | Trauma | Zoom | Slow-mo | Som | Toast |
|---|---|---|---|---|---|---|---|
| Onda ×5 | 1 | 0 | 0.02 | — | — | tick agudo | não |
| Onda ×10 | 2 | 20 | 0.05 | +0.015 | — | acorde 2 notas | sim, 2 s |
| Onda ×25 | 3 | 45 | 0.10 | +0.030 | — | acorde 3 notas | sim, 3 s |
| Onda ×100 | 5 | 140 | 0.24 | +0.060 | 0.5 / 400 ms | fanfarra 5 notas | sim, 4 s + banner |
| Primeira morte de chefe | 5 | 160 | 0.40 | ver 6.9 | 0.18 / 550 ms | fanfarra + reverb | banner grande |
| Novo tier de torre | 4 | 90 | 0.30 | +0.055 | 0.6 / 300 ms | glissando ascendente | banner + morph 1.8 s |
| Nova era | 5 | 120 | 0.20 | −0.12 | 0.6 / 900 ms | pad + coro sintetizado | tela cheia (§7.3) |
| Conquista comum | 2 | 16 | 0.04 | — | — | ding | toast 2.5 s |
| Conquista rara | 4 | 70 | 0.14 | +0.025 | — | ding + arpejo | toast 4 s + brilho |
| Prestígio | 6 | 140 | 0.45 | ver 7.4 | 0.25 / 1200 ms | sequência completa | tela cheia |
| Carta/Relíquia lendária | 5 | 100 | 0.18 | +0.040 | 0.4 / 500 ms | sino + coro | card reveal §9.3 |

## 9.2 Confete — parâmetros exatos

```js
function confete(n, cores){
  for (let i=0;i<n;i++){
    const a = -Math.PI/2 + (Math.random()-0.5) * 2.2;     // cone para cima, ±63°
    const v = 180 + Math.random()*440;
    emitir(17, MUNDO.cx + (Math.random()-0.5)*160, MUNDO.cy - 40, 1, {
      vx: Math.cos(a)*v, vy: Math.sin(a)*v,
      ay: 380, arrasto: 0.93,
      vrot: (Math.random()-0.5)*14,
      vida: 1.6 + Math.random()*1.4,
      cor: cores[(Math.random()*cores.length)|0],
      largura: 4, altura: 7,
    });
  }
}
```
Cada confete é um quad que **gira em 3D falso**: `scaleX = |cos(rot)|` — quando passa por zero, some por um frame. Isso é o que vende o papel virando.

## 9.3 Revelação de carta/relíquia

```
0ms    : fundo escurece α 0.82 (260ms), timeScale 0.4
260ms  : carta aparece de costas, escala 0→1 (easeOutBack, 420ms),
         inclinada -8° e flutuando (sin(t*1.2)*4px)
700ms  : carta gira em Y: scaleX 1 → 0 (280ms, easeInQuad)
980ms  : troca para a frente + FLASH da cor da raridade (α por raridade:
         comum .2 / raro .45 / épico .6 / lendário .85 / mítico 1.0)
980ms  : partículas: 10*(raridade+1) fragmentos da cor
980ms  : scaleX 0 → 1 (300ms, easeOutQuad) com overshoot 1.06
1280ms : nome (letter-spacing 14→2px, 300ms) + descrição (α 0→1, atraso 150ms)
1280ms : lendário+ : anel rotativo em volta da carta + 3 raios de luz varrendo
1600ms : botão "PEGAR" pulsa; ao clicar, carta voa para o inventário (500ms)
```
**Sensação de raridade:** o tempo de "costas" antes de virar é `600 + 180*raridade` ms — quanto mais raro, mais a espera; e nas raridades ≥ épico, a carta **treme** (±2 px, 8 Hz) nos últimos 300 ms antes de virar. Esse é o pico dopaminérgico.

---

# 10. ÁUDIO REATIVO À ARTE (ganchos visuais ↔ WebAudio)

Não é escopo de arte, mas o juice quebra sem isso. Cada efeito visual acima **exige** o par sonoro:

| Visual | Som (síntese) |
|---|---|
| Faísca de acerto | ruído branco 12 ms, HP 3 kHz, gain 0.06, pitch varia ±8 % |
| Crítico | 2 osc quadrada 880/1320 Hz, decay 90 ms, + ruído 6 ms |
| Morte | ruído 60 ms, LP varrendo 4 k→300 Hz |
| Moeda | senoide 1200→1800 Hz em 40 ms + harmônico, gain 0.05 |
| Compra | quadrada 660→990 Hz, 70 ms |
| Marco | tríade maior, 3 osc triangulares, 350 ms, ADSR (5/60/0.5/280) |
| Chefe | 2 osc dente-de-serra 55/82.5 Hz + LFO 5 Hz na frequência de corte |
| Slow-mo | `playbackRate` do bus 0.75 + `BiquadFilter` LP 900 Hz |
| Prestígio | glissando 110→1760 Hz, 1.2 s, + reverb por convolução gerada (ruído decaído) |

**Ducking:** durante hitstop > 60 ms, o bus de música cai −6 dB e volta em 300 ms.

---

# 11. ACESSIBILIDADE E MODOS REDUZIDOS

```js
export const Cfg = {
  reduzirMovimento: false,   // respeita prefers-reduced-motion por padrão
  abaloEscala: 1.0,          // 0 … 1.5, slider
  paradaEscala: 1.0,         // 0 … 1.5
  flashEscala: 1.0,          // 0 … 1.0
  aberrEscala: 1.0,          // 0 … 1.0
  numeros_dano: 0,           // 0 todos · 1 só críticos · 2 nenhum
  daltonismo: 0,
  altoContraste: false,
  fonteGrande: false,
};
```

**Modo `reduzirMovimento` (perfil completo):**
- `abaloEscala = 0`, `zoom punch = 0`, `aberrEscala = 0.15`.
- Slow-mo mantido (não causa desconforto vestibular), mas transições de tela viram **cross-fade de 250 ms**.
- Partículas ×0.4; confetes viram um único anel expandindo.
- Números de dano param de subir — aparecem, seguram 400 ms e somem.
- Flashes de tela ≤ α 0.12.
- Parallax e drift desligados.

**Modo `altoContraste`:**
- Todo inimigo ganha contorno `#ffffff` 2 px e o fundo perde 45 % de saturação.
- Projéteis viram `#ffff00`, área de perigo vira `#ff0000` com hachura diagonal.
- Vinheta reduzida a 0.10.

**Alvo de toque (mobile):** todo elemento interativo ≥ **44 × 44 px CSS**, com área de hit expandida em 8 px. Botões de compra têm **auto-repeat**: segurar 400 ms começa a comprar a 8 Hz, acelerando para 20 Hz após 1.2 s, com feedback háptico (`navigator.vibrate([8])`) a cada 5 compras.

---

# 12. BIBLIOTECA DE CURVAS (o que já existe em `Ux`, portado para JS)

```js
export const E = {
  linear:      t => t,
  outQuad:     t => 1-(1-t)*(1-t),
  outCubic:    t => 1-Math.pow(1-t,3),
  outQuart:    t => 1-Math.pow(1-t,4),
  outQuint:    t => 1-Math.pow(1-t,5),
  inCubic:     t => t*t*t,
  inQuint:     t => t*t*t*t*t,
  inExpo:      t => t<=0?0:Math.pow(2,10*t-10),
  outExpo:     t => t>=1?1:1-Math.pow(2,-10*t),
  inOutSine:   t => -(Math.cos(Math.PI*t)-1)/2,
  outBack:     (t,c1=1.70158)=>{const c3=c1+1;return 1+c3*Math.pow(t-1,3)+c1*Math.pow(t-1,2);},
  inBack:      (t,c1=1.70158)=>{const c3=c1+1;return c3*t*t*t-c1*t*t;},
  outElastic:  t => t<=0?0:t>=1?1:Math.pow(2,-10*t)*Math.sin((t*10-0.75)*(Math.PI*2/3))+1,
  outBounce:   t => {const n=7.5625,d=2.75;
                     if(t<1/d)return n*t*t;
                     if(t<2/d){t-=1.5/d;return n*t*t+.75;}
                     if(t<2.5/d){t-=2.25/d;return n*t*t+.9375;}
                     t-=2.625/d;return n*t*t+.984375;},
  // aproximação independente de framerate — usar SEMPRE em vez de lerp cru
  aprox: (a,b,dt,taxa) => a + (b-a)*(1-Math.exp(-taxa*dt)),
};
```

**Regra que salva o jogo em 144 Hz e em 30 Hz:** nenhuma interpolação usa `lerp(a,b,0.1)`. Toda suavização usa `E.aprox(a, b, dt, taxa)`. Taxas padrão: câmera 9.0, mira do canhão 14.0, cor de era 0.6, barra de vida 7.0, HUD 12.0.

---

# 13. CHECKLIST DE IMPLEMENTAÇÃO (ordem sugerida)

1. `render/camera.js` + pilha de 4 canvases + DPR adaptativo + loop com `dt` fixo.
2. `arte/paleta.js` — ERAS, COR, RARIDADE, interpolação de era, matriz de daltonismo.
3. `arte/primitivas.js` — `poligono`, `losango`, `trapezio`, `arcoParcial`, `retanguloArred`, `gradienteRadial`, `elipse`, `mixHex`, `alpha`.
4. `fx/particulas.js` — SoA, pool, 18 tipos, desenho em lote.
5. `arte/torre.js` — 11 camadas + tiers + estados.
6. `arte/inimigos.js` — tabela `FORMAS` com as 22 + overlays de elite + 12 chefes.
7. `fx/juice.js` — trauma, hitstop, zoom, slow-mo, flashes, vinheta.
8. `fx/numeros.js` — pool, coalescência, curvas.
9. `fx/pos.js` — bloom, aberração (só qualidade ≥ 1).
10. `arte/transicoes.js` — banner, chefe, era, prestígio, offline.
11. `ui/feedback.js` — compra, marcos, celebrações, cartas.
12. `perf/adaptativo.js` — monitor de FPS, degradação automática, contadores de teto.

**Critério de aceite visual:** com 320 inimigos, 2 elites, 1 chefe, 3800 partículas e 70 números simultâneos, o frame time deve ficar ≤ 13 ms em um Chrome desktop de 2021 e ≤ 15 ms em um Pixel 6. Se ultrapassar, a degradação do §1.5 entra sozinha — e o jogador não deve perceber, porque a **ordem de sacrifício** é: bloom → aberração → decalques → densidade de partículas → trilhas → sombras → contagem de inimigos. Nunca sacrificar: hitstop, screen shake, números de dano e flashes de acerto — esses **são** o jogo.