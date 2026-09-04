# Prompts de arte

Todos os prompts, em linguagem natural, para gerar a arte que o jogo precisa e
que **não pode ser desenhada por código**: logo, capas de loja, cartões
colecionáveis, ícones de loja e material de imprensa.

> **A arte DENTRO do jogo não está aqui, e não deve estar.** Cada inimigo, cada
> ícone, cada partícula e cada céu do jogo é desenhado por código em tempo real.
> Gerar imagem para dentro do jogo quebraria a única restrição que dá a ele a
> cara que tem. O que está aqui é a arte de LOJA — que o jogador vê antes de
> comprar, e que nenhum `_draw()` pode produzir.

## Como usar

1. O nome do jogo já está escrito nos prompts: **ETERNAL TOWER**. Só o
   `{ESTÚDIO}` continua em aberto (ver `docs/NOMES.md`).
2. Cole um prompt por vez. Não junte dois — a IA mistura as composições.
3. Peça sempre a proporção exata; recortar depois estraga o enquadramento.
4. Se o resultado vier com textura, ruído ou pincelada, repita acrescentando:
   *"flat vector, zero texture, zero grain, zero brush strokes"*.

## O bloco de estilo

Cole este parágrafo **no fim de todo prompt**. Ele é a identidade do jogo em
palavras (ver `docs/IDENTIDADE.md`), e sem ele cada imagem sai de um jogo
diferente.

> STYLE: flat vector neon, no texture, no grain, no brush strokes, no
> photographic realism. Background is near-black deep navy (#080b14). All light
> comes from the tower and its projectiles — never from a sun, moon or lamp.
> Every glowing element has three tiers: a thin pure-colour core, a 25-35%
> opacity halo 2-3px around it, and an 8-12% opacity bloom spreading 8-20px.
> Palette: cyan #38bdf8 (the tower, the player), violet #a78bfa (prestige,
> rules), gold #fbbf24 (money), green #4ade80 (gain), red #f87171 (damage).
> At least 60% of the frame is empty dark space. Sharp geometric shapes only —
> circles, triangles, hexagons, arcs. No serif type anywhere. Precise, cold,
> slightly melancholic — an instrument panel of an old machine still running
> long after everyone left.

---

# 1. LOGO

## 1.1 Logo 3D principal (o pedido central)

```
A 3D logotype of the word "ETERNAL TOWER" rendered as glowing neon tubing, floating in
absolute darkness, seen straight on with a very slight low angle.

The letters are wide, geometric and generously spaced — built from perfect
circles and straight lines, like Orbitron. Each letter is a hollow glass tube
filled with cyan light (#38bdf8): a thin brilliant white-cyan core running
inside, a soft cyan halo hugging the glass, and a wide faint cyan bloom
spilling into the dark around it.

The tubing has real dimension — you can see the round cross-section catching a
faint rim of light along its top edge, and a darker underside. Thin dark metal
brackets hold the tubes at the corners, barely visible.

A single violet accent (#a78bfa) glows from behind the logotype, low and wide,
like a second light source hidden behind the letters.

The floor beneath is a black reflective surface: the logo reflects into it,
stretched, dimmer, slightly broken up — a wet-asphalt reflection, not a mirror.

Nothing else in frame. No background objects, no city, no fog volume, no
particles.

Aspect ratio 16:9, the logotype occupying the middle 70% of the width.
Transparent-friendly: keep the background pure black so it can be keyed out.

[COLE O BLOCO DE ESTILO AQUI]
```

## 1.2 Logo com subtítulo

```
Same 3D neon logotype of "ETERNAL TOWER" as before. Below it, in much smaller and
thinner letters, the subtitle "{SUBTÍTULO}" — not neon tubing, but flat pale
grey-blue type (#93a3c4) with generous letter-spacing, as if silk-screened onto
the dark surface behind the neon.

The subtitle is roughly 1/6 the height of the main logotype and centred.

A thin cyan horizontal line, one pixel thick, separates the two — extending
slightly wider than the subtitle on both sides.

Aspect ratio 16:9. Pure black background for keying.

[COLE O BLOCO DE ESTILO AQUI]
```

## 1.3 Logo em marca única (ícone quadrado)

```
A square icon: a single glowing cyan tower silhouette, seen straight on,
centred in absolute darkness.

The tower is a narrow vertical shape built from three stacked geometric
sections — a wide hexagonal base, a slender column, and a bright circular core
at the top that is clearly the brightest thing in the image. It reads as an
instrument, not a castle: no bricks, no battlements, no windows.

Three thin arcs of cyan light orbit the core at different radii, suggesting
rotation.

From the bottom edge, four small angular red shapes (#f87171) point inward and
upward toward the tower — small, distant, clearly a threat but not yet close.

Perfectly symmetrical left to right. Square 1:1. Works at 32×32 pixels: no
detail smaller than 1/16 of the frame.

[COLE O BLOCO DE ESTILO AQUI]
```

---

# 2. PEÇAS DA LOJA

> Cada peça tem um trabalho diferente. O que muda de uma para outra não é o
> recorte: é **quanta informação cabe**.

## 2.1 Capsule principal — 616×353

```
A wide key art. The glowing cyan tower stands exactly in the centre, seen from a
slightly elevated angle, on a dark circular arena floor.

Concentric rings of faint cyan light spread out from the tower's base across the
floor. From all four edges of the frame, angular enemy shapes converge inward:
triangles, hexagons and diamonds in muted greys and reds, each with a thin
glowing outline. They are small near the edges and larger as they approach —
maybe fifteen in total, unevenly spaced, clearly in motion.

Three bright cyan projectile streaks leave the tower toward three different
enemies, each ending in a small white flash.

The upper-left third of the frame is deliberately empty dark space, reserved for
the logo.

Deep navy-black background fading to pure black at the corners.

Aspect ratio 616:353. No text in the image.

[COLE O BLOCO DE ESTILO AQUI]
```

## 2.2 Capsule pequena — 462×174

> Esta é lida a 231×87 numa lista. Só a logo cabe.

```
The 3D neon logotype "ETERNAL TOWER" on a near-black background, occupying the left
60% of a wide horizontal frame. On the right, the glowing cyan tower silhouette,
small and simple, with a faint violet glow behind it.

Nothing else. No enemies, no rings, no particles — at half this size they become
noise.

Aspect ratio 462:174.

[COLE O BLOCO DE ESTILO AQUI]
```

## 2.3 Header — 460×215

```
The glowing cyan tower on the right third of the frame, with six angular enemy
shapes approaching from the right edge. The left two-thirds is empty dark space
for the logo.

Two cyan projectile streaks cross the empty space toward the enemies, giving the
emptiness a direction.

Aspect ratio 460:215. No text in the image.

[COLE O BLOCO DE ESTILO AQUI]
```

## 2.4 Hero — 3840×1240

```
An extremely wide cinematic banner. The arena seen from very far away and
slightly above: a small glowing cyan tower at the centre-right, dwarfed by the
darkness around it.

Across the entire width, hundreds of tiny enemy shapes converge from both edges
toward the tower — a tide, not individuals. They are barely more than points of
dim red and grey light near the edges, resolving into recognisable geometric
shapes only in the middle third.

The floor is layered: three or four faint horizontal strata of slightly
different dark tones, like sediment, suggesting eras stacked on top of each
other.

The far left quarter is nearly empty — pure dark — reserved for the logo.

A single thin violet horizon line runs across the upper third.

Aspect ratio 3840:1240. No text.

[COLE O BLOCO DE ESTILO AQUI]
```

## 2.5 Library capsule — 600×900

```
A tall vertical composition. The glowing cyan tower rises from the bottom third
of the frame, seen from below at a dramatic low angle so it fills the vertical
space.

Its core burns bright at the top. Cyan light spills downward along the column.

At the very bottom, small enemy shapes press in from both sides at the tower's
base, tiny by comparison.

The upper third is empty dark space with only a faint violet glow, reserved for
the logo.

Aspect ratio 600:900. No text.

[COLE O BLOCO DE ESTILO AQUI]
```

## 2.6 Library hero — 3840×1240 e Page background

```
Same as the Hero banner, but with the tower moved to the far left and the
composition mirrored: the tide of enemies flows from right to left. The centre
and right are near-empty dark space.

This one will sit behind UI elements, so nothing important may fall in the
central 40% of the frame.

Aspect ratio 3840:1240. No text.

[COLE O BLOCO DE ESTILO AQUI]
```

---

# 3. CARTÕES COLECIONÁVEIS

> Tema: **as torres que falharam antes de você.** Todas na mesma proporção
> vertical (300×450 para o cartão; peça em 2:3).

Prompt base — troque só o parágrafo do meio:

```
A trading card illustration, vertical 2:3. A single tower silhouette centred in
absolute darkness, seen straight on. Behind it, a faint circular halo of light.
The bottom fifth of the frame is a dark floor that catches a broken reflection.

{DESCRIÇÃO ESPECÍFICA}

No text, no border, no frame — just the illustration.

[COLE O BLOCO DE ESTILO AQUI]
```

| # | Nome | `{DESCRIÇÃO ESPECÍFICA}` |
|---|---|---|
| 1 | TORRE-0 | *The tower is perfect and unmarked: clean geometry, pure cyan light, every edge sharp. It is the newest thing that has ever existed. The halo behind it is a complete, unbroken circle.* |
| 2 | A Que Contou | *The tower is surrounded by faint floating numerals and tally marks it seems to be projecting itself — thousands of them, in dim cyan, spiralling outward. The tower's core is dim, almost spent. It counted until it stopped.* |
| 3 | A Que Cavou | *The tower is buried to its midpoint in layered rock. Four or five clearly distinct horizontal strata of different dark tones surround it, each a slightly different hue. Only the upper half glows.* |
| 4 | A Que Ardeu | *The tower is warped and partly melted, its geometry sagging on one side. Orange light (#fb923c) glows from within the cracks instead of cyan. Small embers drift upward.* |
| 5 | A Que Esperou | *The tower is intact but covered in a fine grey film of dust. Its light is very dim — barely a suggestion of cyan. It is still aiming at something we cannot see.* |
| 6 | A Que Poupou | *The tower has a single deep crack running down its length. Beside it, a small pale figure walks past, untouched and unhurried, leaving a faint white trail. The tower is not firing at it.* |
| 7 | A Que Se Partiu | *The tower is split cleanly into two vertical halves that have drifted apart. Each half glows violet (#a78bfa) and is aiming at the other. Between them, a small black sphere.* |
| 8 | A Última | *The tower is only an outline — hollow, with the dark visible through it. Behind it, hundreds of small enemy shapes have arranged themselves into exactly the same tower silhouette, larger, filling the frame.* |

## 3.1 Emoticons (cada um 18×18 e 54×54)

```
A tiny icon, square, on a transparent background. Extremely simple: readable at
18 by 18 pixels. Flat vector, thick strokes, glowing neon on nothing.

{DESCRIÇÃO}

No background, no frame, no gradient beyond a simple glow.
```

| Emoticon | `{DESCRIÇÃO}` |
|---|---|
| `:purga:` | *A golden circle (#fbbf24) with a bright white core, ringed by a thin golden arc that is almost complete but leaves a small gap.* |
| `:onda:` | *Three cyan arrows (#38bdf8) pointing inward toward a single point at the centre, arranged at 120 degrees from each other.* |
| `:peregrino:` | *A small pale figure outline (#e6ecf7), walking, with a faint white trail behind it. No weapon, no aggression.* |
| `:eter:` | *A violet crystal (#a78bfa), six-sided, with a bright core and a soft glow.* |
| `:torre:` | *The cyan tower silhouette, simplified to three stacked shapes and a bright dot at the top.* |

## 3.2 Planos de fundo (1920×1080, e a versão 616×353)

```
A wide desktop wallpaper, 16:9. An empty landscape with no characters and no
tower — only the world.

{DESCRIÇÃO DA ERA}

The bottom third is ground, the top two-thirds is sky. A single thin horizon
line separates them. Deep, calm, and very dark: this will sit behind icons and
text.

[COLE O BLOCO DE ESTILO AQUI]
```

| Era | `{DESCRIÇÃO DA ERA}` |
|---|---|
| Sucata | *A field of angular metal debris in cold greys, half-buried, catching thin cyan rim light. The sky is starless and almost black, with a faint blue-grey gradient near the horizon.* |
| Pântano de Ferro | *Still black water reflecting a dim green-tinted sky (#4ade80 at very low opacity). Rusted geometric shapes break the surface. Slow ripples.* |
| Deserto de Vidro | *A flat plain of fractured glass shards catching and splitting cyan light into thin prismatic lines. The sky is pale violet at the horizon, black above.* |
| Necrópole | *Tall dark monoliths in silhouette, arranged in rows receding into fog. A cold violet glow (#a78bfa) rises from between them.* |
| O Nada | *Almost entirely empty. A single horizon line and one faint point of white light at the exact centre. 95% of the frame is pure darkness.* |

## 3.3 Distintivos (5 níveis, 1:1)

```
A circular badge emblem on transparent background, 1:1, ornate but geometric.

{DESCRIÇÃO}

Flat vector neon, no texture, no metal shading, no photographic gloss.
```

| Nível | `{DESCRIÇÃO}` |
|---|---|
| 1 — Fragmento | *A single cyan shard inside a thin circular ring.* |
| 2 — Núcleo | *A violet sphere inside two concentric rings.* |
| 3 — Éter | *A rose-coloured (#fb7185) six-pointed star inside three rings.* |
| 4 — Peregrino | *A pale walking figure inside a broken ring — one segment of the ring is missing.* |
| 5 — A Torre Que Lembra | *The cyan tower silhouette inside a complete double ring, with eight small tower silhouettes arranged around the outer ring, each dimmer than the last.* |

---

# 4. CAPTURAS DE TELA

> **Não gere estas.** As capturas têm que ser o jogo de verdade — a Steam
> considera arte gerada apresentada como captura de tela uma violação, e o
> jogador percebe. O jogo já tem a ferramenta:
>
> ```bash
> xvfb-run -a --server-args="-screen 0 1920x1080x24" godot --path . \
>   --resolution 1920x1080 -- --shot=6 --onda=45 --saida=/tmp/tela.png
> ```
>
> Cinco capturas mínimas, e sugiro estas seis:
> 1. Arena cheia na onda ~200, com uma Purga na faixa dourada
> 2. A mesa das leis (Éditos) aberta, com as três opções
> 3. O painel de Melhorias com um marco a um passo de ser atingido
> 4. O Bestiário mostrando o contador de formas vistas
> 5. Um chefe com o banner cinematográfico
> 6. A árvore de prestígio da Transcendência

---

# 5. ÍCONES DE APLICATIVO

```
Same as the square icon (1.3), delivered at:
  - 256×256 PNG with transparency (Windows .ico source)
  - 1024×1024 PNG (macOS .icns source)
  - 512×512 PNG (Android adaptive icon foreground, with 25% safe padding
    on all sides — the launcher will crop it into a circle or a squircle)
```

---

# 6. MATERIAL DE IMPRENSA

## 6.1 Imagem de anúncio (1200×630, para redes)

```
The 3D neon logotype "ETERNAL TOWER" on the left half. On the right half, the tower
under attack from a dense tide of enemies. A single line of empty dark space
between them.

The composition must survive being cropped to a square from the centre — keep
the logo and the tower both within the central 60% of the width.

Aspect ratio 1200:630.

[COLE O BLOCO DE ESTILO AQUI]
```

## 6.2 Retrato do estúdio (800×800)

```
A minimal studio mark for "{ESTÚDIO}": {IDEIA DA MARCA}, in flat vector,
glowing faintly in cyan on near-black. Extremely simple — it must read at
64×64. No text.
```

> `{IDEIA DA MARCA}`: para **Estrato Games**, *"four horizontal layers of
> slightly different dark tones stacked like sediment, with a single thin cyan
> line running vertically through all of them"*.
