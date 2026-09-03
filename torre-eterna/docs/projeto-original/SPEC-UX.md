> **Documento do projeto original — não descreve o jogo que existe.**
> Este texto de UX foi escrito para uma implementação em JavaScript/Canvas
> que nunca foi construída; o jogo é feito em Godot 4 e GDScript. Caminhos
> de arquivo, APIs e números aqui são do projeto, não da realidade.
> Leia `docs/projeto-original/LEIA-ANTES.md` antes de usar qualquer coisa
> daqui.

# ARQUITETURA DE INFORMAÇÃO E UX/UI — "TORRE ETERNA"

> Documento de direção de UX/UI. Vocabulário alinhado ao `data/*.json` já existente no repositório (7 categorias de upgrade / 39 upgrades, 36 talentos em 3 ramos, 85 conquistas, 14 desafios, 10 habilidades, 10 eras, 6 raridades, 3 camadas de prestígio, 6 moedas). Todos os valores são normativos: se um número aparece aqui, é o número a codificar.

---

## 0. PRINCÍPIOS DIRETORES

| # | Princípio | Regra operacional |
|---|---|---|
| P1 | **A torre nunca some** | Nenhum painel, modal ou toast pode cobrir o círculo de raio `alcance + 40px` centrado na torre. Em desktop o painel empurra o centro lógico da câmera; em mobile o bottom-sheet ocupa no máx. 78% da altura e a torre é reposicionada para 26% da altura da tela. |
| P2 | **O jogo nunca pausa por UI** | Painéis, abas e tooltips são não-modais. Só 4 coisas escurecem e pausam: relatório offline, confirmação de prestígio, confirmação de reset, e a pausa explícita do jogador. |
| P3 | **Uma decisão por vez visível** | O HUD mostra no máximo **1 chamada à ação primária** por vez (badge dourado). Prioridade: Prestígio disponível > Pontos de talento > Upgrade barato disponível > Missão coletável. |
| P4 | **Zero surpresa numérica** | Todo botão de compra mostra custo *e* efeito *e* delta resultante antes do clique. Nada de "compre para descobrir". |
| P5 | **Layout estável** | Números usam `tabular-nums` e largura mínima reservada. Nenhum elemento do HUD muda de tamanho por mudança de valor. Reflow do HUD só em resize/rotação. |
| P6 | **Orçamento de atenção** | Máx. 3 toasts simultâneos, máx. 1 banner, máx. 1 modal. Fila com prioridade e coalescência. |
| P7 | **Progressive disclosure** | Nada é mostrado antes de ser relevante. Ver §6.3 (tabela de desbloqueio de UI). |
| P8 | **Tudo alcançável com 1 polegar** | Em retrato, toda ação recorrente fica abaixo de 62% da altura da tela (zona do polegar). |

---

## 1. STACK DE UI E CAMADAS

### 1.1 Divisão Canvas vs DOM

| Elemento | Onde | Motivo |
|---|---|---|
| Arena, torre, inimigos, projéteis, partículas, números de dano flutuantes, anel de vida da torre, indicadores de spawn | **Canvas 2D** (`#arena`) | Centenas de entidades; DOM mataria o frame budget. |
| HUD (moedas, onda, vitais, habilidades, buffs, dock) | **DOM** (`#hud`) | Texto acessível, leitores de tela, seleção, i18n. |
| Painéis, modais, tooltips, toasts, onboarding | **DOM** (`#ui`) | Scroll nativo, foco, teclado. |
| Ícones | **SVG inline gerado em JS** (`Icone.*`) + fallback emoji | Sem assets externos; nítido em qualquer DPR. |

**Regra dura:** nenhum elemento DOM é criado/destruído no loop de jogo. Tudo é pool + `hidden` + `transform`.

### 1.2 Camadas (z-index)

```js
export const Z = {
  arena:        0,   // canvas principal
  arenaOverlay: 10,  // canvas de overlay (setas de spawn fora da tela, telegrafia de chefe)
  hud:          20,  // HUD permanente
  dock:         30,  // barra de navegação inferior + barra de habilidades
  fab:          35,  // botão flutuante contextual (Prestigiar / Coletar)
  scrimPanel:   40,  // escurecimento leve (só mobile, alpha .45)
  panel:        50,  // gaveta/bottom-sheet
  tooltip:      60,
  toast:        70,
  scrimModal:   80,  // alpha .72 + blur 6px
  modal:        90,
  spotlight:   100,  // onboarding (recorte + halo)
  debug:       110,
};
```

### 1.3 Esqueleto DOM

```html
<div id="app" data-bp="xl" data-orient="paisagem" data-tema="escuro">
  <canvas id="arena"></canvas>
  <canvas id="arena-overlay" aria-hidden="true"></canvas>

  <div id="hud" role="region" aria-label="Painel de status">
    <header id="hud-topo">
      <div id="moedas" role="list"></div>
      <div id="onda-bloco"></div>
      <div id="controles-topo"></div>
    </header>
    <aside id="vitais"></aside>
    <aside id="rastreador"></aside>       <!-- missão ativa / próximo marco -->
    <div id="buffs" role="list"></div>
    <nav id="barra-habilidades" aria-label="Habilidades"></nav>
    <nav id="dock" aria-label="Menus"></nav>
    <button id="fab" hidden></button>
  </div>

  <div id="ui">
    <div id="scrim-painel" hidden></div>
    <section id="painel" role="dialog" aria-modal="false" hidden></section>
    <div id="scrim-modal" hidden></div>
    <section id="modal" role="dialog" aria-modal="true" hidden></section>
    <div id="tooltip" role="tooltip" hidden></div>
    <div id="toasts" aria-live="polite" aria-relevant="additions"></div>
    <div id="anuncio-sr" class="sr-only" aria-live="polite"></div>
    <div id="anuncio-sr-urgente" class="sr-only" aria-live="assertive"></div>
    <div id="onboarding" hidden></div>
  </div>
</div>
```

---

## 2. DESIGN TOKENS (completos, prontos para colar)

### 2.1 Cor

```css
:root{
  /* superfícies */
  --c-fundo:#080b14; --c-fundo2:#0e1424;
  --c-painel:#121a2e; --c-painel2:#18223c; --c-painel3:#1e2a49;
  --c-borda:#243356; --c-borda-forte:#3b5a9e;
  --c-vidro: color-mix(in srgb, #121a2e 82%, transparent);

  /* texto (contraste medido sobre --c-painel #121a2e) */
  --c-txt:#e6ecf7;    /* 14.1:1  AAA */
  --c-txt2:#93a3c4;   /*  6.2:1  AA  */
  --c-txt3:#5f6f92;   /*  2.9:1  — SÓ para bordas/ícones decorativos, NUNCA texto informativo */
  --c-txt3-a11y:#8393b6; /* substituto no modo alto contraste: 4.6:1 */

  /* semântica */
  --c-acento:#38bdf8; --c-acento2:#a78bfa;
  --c-ok:#4ade80; --c-alerta:#fb923c; --c-perigo:#f87171; --c-rosa:#f472b6;

  /* moedas (idênticas a ui_kit.gd) */
  --c-ouro:#fbbf24; --c-gemas:#f472b6; --c-frag:#38bdf8;
  --c-nucleos:#a855f7; --c-eter:#fb7185; --c-poeira:#94a3b8;

  /* raridades */
  --r-comum:#9aa5b1; --r-incomum:#4ade80; --r-raro:#38bdf8;
  --r-epico:#c084fc; --r-lendario:#fbbf24; --r-mitico:#fb7185;

  /* estado de compra */
  --c-pode:#4ade80;        /* pode comprar */
  --c-pode-bg: color-mix(in srgb,#4ade80 12%, transparent);
  --c-quase:#fbbf24;       /* ≥60% do custo */
  --c-nao:#5f6f92;         /* longe */
  --c-max:#a78bfa;         /* nível máximo */
}
```

**Cor da era** (`data/eras.json → paleta`) tinge **apenas o canvas** e uma faixa de 2px no topo do HUD. O chrome da UI **nunca** muda de cor por era — evita perda de legibilidade e re-aprendizado.

### 2.2 Tipografia

```css
:root{
  --f-ui: system-ui,-apple-system,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;
  --f-num: ui-monospace,"SF Mono","Cascadia Mono","Roboto Mono",Menlo,monospace;

  --t-xs:11px;   --lh-xs:14px;   /* rodapés, unidades */
  --t-sm:12.5px; --lh-sm:16px;   /* legendas, custo secundário */
  --t-md:14px;   --lh-md:19px;   /* corpo padrão */
  --t-lg:16px;   --lh-lg:22px;   /* títulos de linha */
  --t-xl:20px;   --lh-xl:26px;   /* títulos de painel */
  --t-2xl:26px;  --lh-2xl:32px;  /* moeda principal */
  --t-3xl:34px;  --lh-3xl:40px;  /* preview de prestígio */
  --t-4xl:46px;  --lh-4xl:50px;  /* número de onda em transição */
}
.num{font-family:var(--f-num);font-variant-numeric:tabular-nums;letter-spacing:-.01em}
```

Escala global: `--escala` ∈ {0.85, 0.925, 1.0, 1.1, 1.25, 1.5} (config "Tamanho da interface"). Aplicada como `font-size` no `#app` com todos os tokens em `em` derivados — exceto alvos de toque, que têm piso absoluto de 44px.

### 2.3 Espaço, raio, elevação, movimento

```css
:root{
  --e0:2px; --e1:4px; --e2:6px; --e3:8px; --e4:12px; --e5:16px;
  --e6:20px; --e7:24px; --e8:32px; --e9:40px; --e10:48px;

  --r-chip:6px; --r-card:10px; --r-painel:14px; --r-pill:999px;

  --sombra-1:0 1px 2px rgba(0,0,0,.35);
  --sombra-2:0 4px 14px rgba(0,0,0,.45);
  --sombra-3:0 12px 40px rgba(0,0,0,.6);
  --glow-ouro:0 0 0 1px #fbbf24, 0 0 14px -2px rgba(251,191,36,.55);
  --glow-ok:0 0 0 1px #4ade80, 0 0 12px -2px rgba(74,222,128,.45);

  --d-micro:110ms;  /* hover, press */
  --d-rapido:180ms; /* toast, tooltip */
  --d-normal:240ms; /* painel mobile */
  --d-lento:320ms;  /* modal, prestígio */
  --ease-saida:cubic-bezier(.4,0,1,1);
  --ease-entrada:cubic-bezier(.16,1,.3,1);
  --ease-mola:cubic-bezier(.34,1.56,.64,1);
}
@media (prefers-reduced-motion:reduce){
  :root{--d-micro:0ms;--d-rapido:80ms;--d-normal:80ms;--d-lento:80ms;
        --ease-mola:linear;--ease-entrada:linear}
}
```

---

## 3. MAPA DE TELAS

```
BOOT (≤400ms, logo procedural + barra)
  └─ JOGO  ← 98% do tempo aqui
      ├─ HUD permanente
      ├─ GAVETA/SHEET (não-modal, 12 painéis)
      │    Upgrades · Habilidades · Talentos · Cartas · Relíquias
      │    Prestígio · Desafios · Missões · Conquistas · Codex · Estatísticas · Config
      ├─ MODAIS (4)
      │    Relatório Offline · Confirmar Prestígio · Confirmar Reset · Evento Narrativo
      ├─ OVERLAYS
      │    Onboarding (spotlight) · Pausa · Transição de Era · Derrota
      └─ TOASTS / BANNERS / TICKER
```

Não existe "tela de menu principal". O jogo abre direto no loop. Save/load fica em Config.

---

## 4. HUD PERMANENTE — ESPECIFICAÇÃO POSICIONAL

Medidas base para viewport **1280×800** (XL). Fatores de outros breakpoints em §14.

### 4.1 Faixa superior (`#hud-topo`, altura 52px, `padding: 10px 14px`)

**Esquerda — cluster de moedas (`#moedas`)**

Chip de moeda: `h 32px`, `padding 0 10px`, `gap 6px`, `radius var(--r-pill)`, `bg color-mix(in srgb, var(--c-painel) 88%, #000)`, `border 1px var(--c-borda)`.
Ícone 17px na cor da moeda. Valor `--t-md` `.num` na cor da moeda. Largura mínima reservada: `min-width: 7ch`.

* Ordem fixa: `ouro, gemas, fragmentos, nucleos, eter, poeira`.
* **Revelação progressiva:** cada chip aparece na primeira vez que a moeda > 0 (animação `scale .8→1` + `translateY(-6px)`, 220ms `--ease-mola`), e a partir daí é permanente.
* **Taxa por segundo:** sob o valor do ouro, linha de `--t-xs` em `--c-txt2`: `+1,24 mi/s`. Média móvel de 3s, atualizada 4Hz. Some se |taxa| < 0.001.
* **Pulso de ganho:** ao receber ouro, o chip faz `filter: brightness(1.35)` por 90ms. Coalescido a no máx. 6 pulsos/s.
* **Overflow XS/S:** exibe ouro + gemas + a moeda de prestígio mais alta; o resto colapsa num chip `+3` que abre um popover 200×auto.

**Centro — bloco de onda (`#onda-bloco`, largura 260px)**

```
┌────────────────────────────────┐
│  ONDA 147          ⚡ x2        │  ← --t-lg bold, .num ; multiplicador de velocidade
│  ▓▓▓▓▓▓▓▓▓░░░░░░  18/30        │  ← barra 240×6, radius 3, --t-xs à direita
│  Necrópole Orbital             │  ← --t-xs, --c-txt2, cor de acento da era
└────────────────────────────────┘
```

* Barra de onda: preenchimento com gradiente `acento → acento2`, transição `width var(--d-micro) linear`.
* **Marco a cada 10 ondas:** tick vertical de 2px na barra; ao cruzar, flash branco 120ms.
* **Modo chefe:** o bloco expande para 520px e vira a barra de chefe (§4.6).

**Direita — controles (`#controles-topo`)**

Botões-ícone 36×36 (alvo real 44×44 via `::before`), gap 6:
`⏩ velocidade` (cicla x1→x2→x3→x0.5, long-press abre seletor) · `⏸ pausa` · `⚙ config` · `⛶ tela cheia` (oculto em mobile) · `📶 FPS` (só se debug ligado).

### 4.2 Vitais (`#vitais`, ancorado top-left sob as moedas, largura 210px)

```
❤ 4,21 mi / 5,00 mi        ← --t-sm .num
▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░        ← barra 210×10, r5
🛡 1,10 mi                  ← só se escudoMax>0
▓▓▓▓▓▓▓▓░░░░░░░░░░░        ← barra 210×6, cor --c-acento, sobreposta com 2px de gap
Nível 34   ▓▓▓▓▓▓░░░  62%   ← XP: barra 210×4, cor --c-acento2
DPS 8,4 mi/s   ⚔ x1,00     ← --t-sm; multiplicador de combo à direita
```

* **Vida:** cor interpola verde→laranja→vermelho em 60%/30%. Abaixo de 25%, borda externa do canvas pulsa vermelho (0.9Hz) — desativável em "Reduzir movimento".
* **Dano recebido:** camada "fantasma" branca a 35% de alpha que decai para o valor real em 380ms (`--ease-saida`). Leitura imediata do quanto levou.
* **Regeneração:** micro-seta ▲ verde à direita quando `regen > 0`.
* **Anel na torre (canvas):** duplicata do HP como arco no raio `torre.r + 14`, espessura 5px. É a leitura primária; o HUD é a leitura precisa. Em "Modo minimalista" o HUD de vitais colapsa e só o anel resta.
* **Atualização:** barras a 30Hz (via `transform: scaleX()`, nunca `width` em elemento com filhos), texto a 8Hz.

### 4.3 Rastreador (`#rastreador`, top-right sob os controles, largura 240px, colapsável)

Mostra **1 objetivo** por vez, escolhido por prioridade:
1. Missão diária ativa mais próxima de completar (%)
2. Próximo desbloqueio de UI ("Orbes em 3 ondas")
3. Próxima conquista a ≥70%
4. Próxima era ("Estepe Vitrificada — onda 28")

Linha 1: ícone 16 + nome `--t-sm`. Linha 2: barra 240×4 + `--t-xs` `247/500`.
Clique → abre o painel correspondente na entrada certa. Colapsa para uma pílula de 32×32 com clique. Estado persistido.

### 4.4 Buffs (`#buffs`, acima da barra de habilidades, centralizado)

Chip de buff: 34×34, raio 8, borda 1px na cor do efeito, ícone 18, contador `--t-xs` no canto inferior direito, e **anel de progresso** (`conic-gradient`) mostrando tempo restante. Empilhamento (`x3`) como badge superior direito. Máx. 10 visíveis; excedente vira `+N`.
Ordem: debuffs primeiro (borda vermelha), depois buffs por tempo restante crescente.
Nos últimos 3s: piscar 2Hz. Ao expirar: `scale 1→1.25→0` em 200ms.

### 4.5 Barra de habilidades (`#barra-habilidades`, ancorada ao rodapé, acima do dock)

10 slots (`data/abilities.json`), **revelados um a um** conforme `requer.onda`.

Slot: **56×56** desktop / **50×50** mobile, gap 8, raio 12.
* Ícone 26px na cor da habilidade.
* Tecla no canto superior esquerdo (`--t-xs`, `--c-txt3`) — oculta em touch.
* **Cooldown:** máscara `conic-gradient(from 0deg, transparent {p}%, rgba(8,11,20,.78) 0)`, 60fps via variável CSS `--p` escrita 1×/frame (sem layout). Texto do tempo restante `--t-sm .num` centralizado quando > 3s.
* **Pronta:** borda 2px na cor da habilidade + `--glow-*` pulsando a 0.6Hz + micro-partícula no canvas na primeira vez que fica pronta.
* **Sem custo/nível 0:** slot em silhueta 30% de opacidade com cadeado; tooltip diz o requisito exato.
* **Ativação:** flash branco 80ms, `scale 1→0.88→1` 160ms, ripple do ponto de toque.
* **Fila:** clicar em habilidade em cooldown com <2s restantes agenda a ativação (borda tracejada animada). Fila máx. 1.
* **Auto-cast:** ao desbloquear ("Protocolo Automático", onda 60), cada slot ganha um toggle ⟳ 14×14 no canto inferior esquerdo. Ligado = borda pontilhada permanente.

### 4.6 Barra de chefe (substitui `#onda-bloco` durante chefe)

```
        ☠  CEIFEIRA DE ÓRBITA          [Elite]
   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░  62,4%
   1,84 bi / 2,95 bi            ⏱ 0:47
```
Largura 520 (desktop) / 92vw (mobile), altura 46. Barra 10px com segmentação a cada 25% (marcas de 2px).
Ao entrar: banner desce do topo (`translateY(-100%)→0`, 320ms), som grave, vinheta vermelha nas bordas do canvas (alpha 0.18).
Marcos de HP (75/50/25%) disparam flash + shake 2px.

### 4.7 Dock de navegação (`#dock`)

Desktop: ancorado ao rodapé, centralizado, altura 64, `background: var(--c-vidro)`, `backdrop-filter: blur(10px)`, borda superior 1px.
Botão de dock: **64×56** (desktop) / **56×52** (mobile). Ícone 22, rótulo `--t-xs` (oculto em XS).

Ordem canônica (esquerda → direita), com revelação progressiva:

| # | Painel | Ícone | Tecla | Desbloqueio |
|---|---|---|---|---|
| 1 | Upgrades | ⚔️ | `U` | sempre |
| 2 | Habilidades | ✨ | `H` | onda 1 (após 1ª habilidade) |
| 3 | Talentos | 🌳 | `T` | nível 5 da torre |
| 4 | Cartas | 🃏 | `C` | 1ª carta obtida |
| 5 | Relíquias | 🏺 | `R` | 1ª Ascensão |
| 6 | Prestígio | 💠 | `P` | onda 20 (visível "bloqueado" a partir da 15) |
| 7 | Missões | 📋 | `M` | onda 8 |
| 8 | Desafios | 🎯 | `D` | 1ª Ascensão |
| 9 | Conquistas | 🏆 | `K` | onda 10 |
| 10 | Codex | 📖 | `L` | onda 5 |
| 11 | Estatísticas | 📊 | `X` | onda 15 |
| 12 | Config | ⚙️ | `O` | sempre (fica no topo direito, não no dock) |

Com >7 itens visíveis em telas estreitas, os últimos colapsam em **"⋯ Mais"** que abre uma grade 3×N.

**Estados do botão de dock:**
* `normal`: ícone `--c-txt2`.
* `hover/focus`: ícone `--c-txt`, fundo `--c-painel2`, `translateY(-2px)`.
* `ativo` (painel aberto): fundo `--c-painel3`, barra superior 3px na cor de acento do painel, ícone 100%.
* `badge`: ver §8.
* `novo` (nunca aberto e recém-desbloqueado): pastilha `NOVO` `--t-xs` e brilho suave 1.2Hz até o primeiro clique.

### 4.8 FAB contextual (`#fab`)

Botão flutuante 56×56 (mobile: 64×64), canto inferior direito, 16px das bordas, acima do dock.
Aparece **só** quando há uma ação de alto valor: `Prestigiar disponível` (💠, dourado, pulsa) ou `Coletar recompensas` (🎁). Sai de cena depois de executado. Máx. 1 por vez. Nunca aparece durante um chefe.

---

## 5. SISTEMA DE PAINÉIS

### 5.1 Comportamento por breakpoint

| Breakpoint | Forma | Medidas | Efeito no canvas |
|---|---|---|---|
| ≥1280 (XL/XXL) | **Gaveta lateral direita**, não-modal | `width: clamp(400px, 32vw, 520px)`, altura `calc(100vh - 20px)`, top 10, right 10, `--r-painel` | Centro lógico desloca `-largura/2` em 260ms `--ease-entrada` |
| 900–1279 (L) | Gaveta direita | `width: 380px` | idem |
| 600–899 (M / paisagem de celular) | Gaveta direita **sobreposta**, scrim 0.35 | `width: 340px` | Sem deslocamento; torre fica visível à esquerda |
| <600 (S/XS) | **Bottom sheet** com arraste | `height: 78svh`, cantos superiores `--r-painel`, alça 40×4 | Torre reposiciona para 26% da altura |

**Sheet mobile — gestos:**
* Arrastar a alça ou o header: acompanha o dedo 1:1.
* Soltar acima de 55% da altura → 78svh (aberto). Entre 55% e 22% → snap para 45svh (meio). Abaixo de 22% ou velocidade > 900px/s para baixo → fecha.
* Swipe horizontal no header troca de aba interna (não fecha).
* `overscroll-behavior: contain` no corpo; puxar o corpo já no topo arrasta o sheet.

### 5.2 Anatomia do painel

```
┌──────────────────────────────────────────┐
│ ⚔️  UPGRADES              🪙 12,4 bi  ✕ │ header 56px, sticky
├──────────────────────────────────────────┤
│ [Ataque²][Elemental][Defesa][Orbes][…]   │ abas 44px, scroll-x, snap
├──────────────────────────────────────────┤
│ 🔍 filtrar   [x1][x10][x25][Máx] [⇅][☰] │ barra de ferramentas 42px, sticky
├──────────────────────────────────────────┤
│                                          │
│   corpo rolável                          │ scroll-y, padding 10 12 88 12
│                                          │
├──────────────────────────────────────────┤
│  Comprar tudo que dá  ·  Δ +18,4% DPS    │ rodapé de ação 64px, sticky bottom
└──────────────────────────────────────────┘
```

* **Header:** ícone 22 + título `--t-xl` + a **moeda relevante do painel** (só ela — evita ruído) + botão fechar 40×40. `position: sticky; top: 0; backdrop-filter: blur(8px)`.
* **Abas:** altura 44, `padding 0 14`, `--t-md`. Ativa: texto `--c-txt`, sublinhado 3px na cor da categoria. Inativa: `--c-txt2`. Badge sobrescrito com contagem de compráveis. Rolagem horizontal com `scroll-snap-type: x proximity` e gradiente de 24px nas bordas indicando conteúdo cortado.
* **Rodapé de ação:** só existe em painéis com ação em massa. Sempre mostra o **efeito agregado** da ação.

### 5.3 Transições

| Contexto | Entrada | Saída |
|---|---|---|
| Gaveta desktop | `translateX(24px) + opacity 0 → 1`, 220ms `--ease-entrada` | 160ms `--ease-saida` |
| Sheet mobile | `translateY(100%) → 0`, 260ms `--ease-entrada` | 200ms |
| Troca entre painéis (dock) | Crossfade de corpo 120ms; header e abas fazem *morph* (título com fade + slide 8px) — a moldura **não** re-anima | — |
| Troca de aba interna | Corpo desliza 16px na direção do movimento + fade, 140ms | — |

### 5.4 Foco e teclado

* Ao abrir: foco vai para o header (`tabindex="-1"`), leitor anuncia `"Upgrades, painel. Aba Ataque, 1 de 7."`.
* `Esc` fecha e devolve o foco ao botão do dock que o abriu.
* Gaveta desktop **não** aprisiona foco (é não-modal); `Tab` sai para o HUD.
* Sheet mobile e modais **aprisionam** foco.
* `←`/`→` no header trocam abas; `Home`/`End` vão à primeira/última.

---

## 6. PAINEL DE UPGRADES — COMO MOSTRAR 39 SEM POLUIR

O problema: 39 upgrades em 7 categorias, cada um com nome, ícone, descrição, nível, custo, efeito atual, efeito próximo, e estado. Solução em 4 camadas.

### 6.1 Camada 1 — Categorização (7 abas)

Cada aba tem 4–7 upgrades. **Nunca mais de 8 linhas numa aba.** Uma tela de 700px de corpo mostra ~10 linhas de 64px: **zero scroll dentro de uma aba** no desktop. Isso é o principal antídoto contra poluição.

Aba extra **"Tudo"** (primeira posição, opcional em Config): lista achatada, agrupada por cabeçalhos de categoria sticky. Para veteranos que querem varrer.

Categorias bloqueadas (`Elemental` onda 20, `Orbes` 15, `Forja` 45) aparecem como aba fantasma com cadeado e a onda exata. Nunca escondidas — ver o futuro é motivação.

### 6.2 Camada 2 — Anatomia da linha (2 densidades)

**Densidade "Confortável" (padrão), altura 68px:**

```
┌──────────────────────────────────────────────────────────────┐
│ ┌────┐  Canhão de Plasma                        Nv 247       │
│ │ ⚔️ │  Dano  1,84 mi → 1,92 mi   (+4,3%)   ┌──────────────┐ │
│ └────┘  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░         │ 🪙 8,42 mi   │ │
│                                             │    x10       │ │
│                                             └──────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

Medidas:
* Ícone: quadro 44×44, raio 10, `background: color-mix(in srgb, var(--cor-categoria) 14%, transparent)`, borda 1px `color-mix(..., 32%)`, glifo 22px.
* Nome: `--t-lg`, peso 600, `--c-txt`. Truncado com `text-overflow: ellipsis` (nunca quebra em 2 linhas).
* Nível: `--t-sm .num`, `--c-txt2`, canto superior direito. Se `max > 0`: `247/150` e, no máximo, pastilha `MÁX` em `--c-max`.
* Linha de efeito: `--t-sm`. Formato **`Stat  atual → próximo  (Δ%)`**. O `→` em `--c-txt3`, o valor futuro em `--c-ok`. Este é o coração do design: o jogador vê o ganho antes de gastar.
* Barra de progresso do nível (só se `max > 0`): 100% da largura útil, 3px, cor da categoria a 60%.
* Botão de compra: largura 128 (desktop) / 104 (mobile), altura 48, raio 10. Duas linhas: custo `--t-md .num` + quantidade `--t-xs`.

**Densidade "Compacta", altura 48px:** ícone 32, nome + custo na mesma linha, efeito só no tooltip, botão 88×40. Ativável em Config; automática quando `altura do corpo / nº de itens < 56px`.

**Densidade "Grade" (≥1400px de painel ou modo tablet paisagem):** cards 2 colunas, 168×120.

### 6.3 Camada 3 — Estados visuais (a linguagem de "posso comprar")

| Estado | Condição | Botão | Linha | Redundância não-cromática |
|---|---|---|---|---|
| **Compra recomendada** | pode comprar **e** é o melhor Δstat/custo da aba | fundo `--c-ouro` a 16%, borda 1px `--c-ouro`, texto `--c-ouro`, `--glow-ouro` | borda esquerda 3px dourada | Estrela ⭐ 12px antes do custo |
| **Pode comprar** | `ouro ≥ custo` | fundo `--c-pode-bg`, borda `--c-pode`, texto `--c-pode` | fundo `color-mix(#4ade80 4%, transparent)` | Ponto ● 6px verde à esquerda do custo |
| **Quase lá** | `ouro/custo ∈ [0.60, 1)` | fundo transparente, borda `--c-quase` 1px tracejada, texto `--c-quase`, **barra de progresso fina de 2px no rodapé do botão** com `ouro/custo` | — | Barra de 2px é o sinal (não é cor) |
| **Longe** | `ouro/custo < 0.60` | borda `--c-borda`, texto `--c-nao`, `opacity .78` | — | — |
| **Máximo** | `nivel === max` | botão vira pastilha `MÁX` roxa, não clicável, `cursor: default` | ícone ganha anel roxo | Texto "MÁX" |
| **Bloqueado** | requisito não atendido | botão vira 🔒 + requisito `--t-xs` | linha a `opacity .5`, ícone dessaturado (`filter: grayscale(1)`) | Cadeado |

**Regra de acessibilidade:** cor **nunca** é o único portador de "posso comprar". A tríade é **cor + símbolo (●/⭐/🔒/MÁX) + barra de progresso**. Em "Modo daltônico", os símbolos aumentam para 9px e ficam sempre visíveis.

**Ordenação do "melhor valor":** para cada upgrade comprável na aba, calcula-se `eficiencia = ΔDPSprojetado / custo` (ou `Δsobrevivência/custo` para a aba Defesa, `ΔOuro/s/custo` para Economia). Recalculado a 2Hz e só quando o painel está aberto. Cache invalidado por compra ou mudança de ouro > 5%.

### 6.4 Camada 4 — Ferramentas de redução

**Barra de ferramentas (42px):**
* **Busca** (`/` para focar): filtra por nome, stat afetado e descrição. Debounce 120ms. Mostra `3 de 39`.
* **Seletor de lote:** `[x1][x10][x25][Máx]` — pílulas de 44×32, segmentadas. Estado global persistido. Ver §7.
* **Ordenar** ⇅: `Padrão` (ordem do JSON) · `Mais barato` · `Melhor valor` · `Nível` · `Nome`.
* **Filtro rápido** ☰ (menu): `[ ] Só compráveis` · `[ ] Esconder maximizados` · `[ ] Esconder bloqueados` · densidade.
* **Fixar (pin):** long-press/click-direito numa linha a fixa no topo de "Tudo". Máx. 5 fixados. Ideal para o jogador que só liga para 3 upgrades.

**Rodapé de ação:** `Comprar tudo que dá` — compra em ordem de melhor valor até o ouro acabar ou 200 compras (proteção de frame). Mostra o agregado: `28 compras · 🪙 11,9 bi · Δ +18,4% DPS`. Após executar: toast com o resumo e botão `Desfazer` por 5s (rollback do estado, apenas para esta ação).

**Autocompra (desbloqueia na 1ª Ascensão):** toggle ⟳ por linha (14×14, canto do botão) e mestre no rodapé. Regra: compra quando `ouro ≥ custo × reservaMultiplicador`, com `reserva ∈ {1×, 1.5×, 2×, 5×, 10×}` configurável — impede que o auto consuma o ouro guardado para um upgrade caro. Executa 1×/s no tick de simulação, não no de render. Linhas com auto ligado ganham borda pontilhada permanente e ficam no fim da ordenação "Melhor valor" (já resolvidas).

---

## 7. COMPRA EM LOTE — ESPECIFICAÇÃO MATEMÁTICA E DE UI

### 7.1 Modos

`x1` · `x10` · `x25` · `Máx` · (opcional em Config: `x100`, `Próx`)

**`Próx`** = compra até o próximo **marco**: nível múltiplo de 25, ou o nível que desbloqueia um bônus, ou o `max`. Rótulo dinâmico: `Próx (18)`.

### 7.2 Fórmulas (custo geométrico, `base` e `cresc` do JSON)

```js
// custo de UM nível partindo do nível n (0-indexed)
const custoN = (u, n) => u.base * Math.pow(u.cresc, n);

// custo total de k níveis a partir de n  (soma de PG)
const custoLote = (u, n, k) =>
  u.cresc === 1
    ? u.base * k
    : u.base * Math.pow(u.cresc, n) * (Math.pow(u.cresc, k) - 1) / (u.cresc - 1);

// quantos níveis o ouro G compra a partir de n  (inversa)
const maxCompravel = (u, n, G) => {
  if (u.cresc === 1) return Math.floor(G / u.base);
  const r = G * (u.cresc - 1) / (u.base * Math.pow(u.cresc, n)) + 1;
  return r <= 1 ? 0 : Math.floor(Math.log(r) / Math.log(u.cresc));
};
```

Com Decimal próprio: usar `log10` para evitar overflow. Clampar por `u.max` quando `max > 0`. **Nunca** iterar comprando 1 a 1 para calcular `Máx` — é O(n) e trava em números grandes.

### 7.3 Comportamento de UI do lote

* Quando o modo é `x10`/`x25` e o jogador **não** pode pagar o lote inteiro, o botão mostra o **maior lote pagável** com o número riscado: `~~x25~~ x14` e fica no estado "pode comprar". Isso elimina o botão morto. Configurável: `Lote estrito` (não compra parcial) para quem prefere precisão.
* No modo `Máx`, o botão exibe `Máx (312)`. Se `0`, mostra o custo de 1 e entra em "quase lá"/"longe".
* **Auto-repetição por pressão longa:** após 400ms de pressão, repete a `x1` a 8/s; após 1500ms acelera para 20/s; solta e para. Cada repetição dispara som com pitch subindo (+2 semitons, teto de +12) — feedback de escada. Em modos de lote, o long-press faz repetição do lote a 4/s.
* **Teclas:** `Shift+1/2/3/4` alterna o modo de lote globalmente. `Shift+clique` = `Máx` pontual. `Alt+clique` = `x1` pontual.
* **Animação de compra:** botão `scale 1→0.94→1` 140ms; o nível incrementa com *rolling counter* (cada dígito rola verticalmente, 180ms escalonado 20ms por dígito); ícone emite 3 partículas na cor da categoria; o chip de ouro no HUD pisca vermelho suave por 90ms (custo) enquanto o valor decresce em 200ms com easing.
* **Proteção contra compra acidental:** ações irreversíveis (Prestígio, gasto de gemas, reset) **nunca** têm auto-repetição e sempre exigem confirmação (§11, §16).

---

## 8. NOTIFICAÇÕES, BADGES E FILA DE ATENÇÃO

### 8.1 Taxonomia

| Tipo | Onde | Duração | Interrompe? | Exemplos |
|---|---|---|---|---|
| **Toast** | topo-centro (desktop) / acima do dock (mobile) | 2600ms | não | conquista, carta obtida, missão completa, nível de talento |
| **Ticker** | linha de 20px sob o bloco de onda | 1400ms, fila de 1 | não | "+4 pontos de talento", "Marco: onda 150" |
| **Banner** | faixa full-width abaixo do topo, 44px | até dispensar | não | "Prestígio disponível", "Desafio ativo: Purgatório" |
| **Modal** | centro, com scrim | até ação | **sim** | offline, prestígio, reset, evento narrativo |
| **Badge** | sobre botão do dock/aba | persistente | não | contagem de ações disponíveis |
| **Floating text** | canvas, sobre o mundo | 700ms | não | dano, ouro, crítico, "ONDA 150!" |

### 8.2 Toast — especificação

* Tamanho: `min 280 × 52`, máx. `380` de largura. Raio 10. `--sombra-2`.
* Estrutura: `[ícone 28] [título --t-md bold / subtítulo --t-sm --c-txt2] [ação opcional]`.
* Cor da borda esquerda (4px) por tipo: conquista `--c-ouro`, item `cor da raridade`, missão `--c-ok`, aviso `--c-alerta`, erro `--c-perigo`.
* **Empilhamento:** máx. **3**. O 4º empurra o mais antigo com saída de 140ms. Gap 8.
* Entrada: `translateY(-12px) + opacity 0 → 1`, 180ms `--ease-entrada`. Saída: `opacity → 0 + scale .96`, 140ms.
* Barra de progresso de 2px no rodapé consumindo a duração. Hover/foco pausa o timer.
* **Coalescência (crítico para não virar spam):** toasts do mesmo `tipo+id` dentro de 3s viram um só com contador `×4`. Toasts de raridade `comum` de cartas **não** aparecem — vão só para o ticker, agregados a cada 10s: `+7 cartas comuns`.
* **Fila com prioridade:** `mitico(100) > lendario(90) > conquista(80) > desafio(70) > missao(60) > epico(55) > sistema(50) > resto(10)`. Se a fila > 8, descarta os de prioridade < 40.
* Toast de raridade ≥ épico ganha 12 partículas no canvas atrás dele e um som distinto por raridade (arpejo de 3, 4, 5 notas para raro/épico/lendário; acorde + sub-bass para mítico).

### 8.3 Badges — regra anti-poluição

Um badge só aparece se a informação for **acionável agora** e **nova**.

```js
// numérico (verde): quantidade de coisas compráveis/coletáveis
badge = { tipo:'num', valor: n }   // n>0, exibe min(n,9) e "9+" acima
// ponto (dourado): novidade não vista, sem contagem
badge = { tipo:'ponto' }
// exclamação (vermelho): ação com prazo (evento, missão expirando <10min)
badge = { tipo:'alerta' }
```

| Painel | Regra do badge |
|---|---|
| Upgrades | nº de upgrades compráveis **agora**, com teto de 9+. Suprimido se `Autocompra mestre` estiver ligada (senão fica sempre em 9+ e vira ruído). |
| Habilidades | nº de habilidades melhoráveis com o ouro atual |
| Talentos | nº de pontos de talento não gastos (o mais importante do jogo — sempre visível) |
| Cartas | nº de cartas novas não vistas (ponto dourado se ≥1) |
| Relíquias | nº de relíquias compráveis com fragmentos |
| Prestígio | **ponto dourado** quando o ganho ≥ 1.5× o total atual de fragmentos, ou primeiro desbloqueio |
| Missões | nº de missões prontas para coletar; alerta se alguma expira em <10min |
| Conquistas | nº de conquistas com recompensa não coletada |
| Codex | ponto dourado se há entrada nova (inimigo/era/lore) |
| Estatísticas | nunca tem badge |
| Config | ponto dourado apenas 1× após update com novas opções |

Badge: círculo 18×18 (`--t-xs`, peso 700), offset `top:-4px; right:-4px`. Ponto: 8×8. Aparecem com `scale 0→1.2→1` 200ms `--ease-mola`.

**Debounce global:** badges recalculam a 2Hz, nunca por frame.

### 8.4 Região de anúncio para leitor de tela

`#anuncio-sr` (polite) recebe **no máximo 1 mensagem a cada 5s**, com coalescência. Nunca recebe mudanças de ouro/DPS. Recebe: mudança de onda (a cada 10 ondas), conquista, item ≥ raro, missão completa, prestígio disponível.
`#anuncio-sr-urgente` (assertive): vida < 25%, chefe apareceu, derrota, desafio falhou. Máx. 1 a cada 8s.

---

## 9. TOOLTIPS

### 9.1 Acionamento

| Entrada | Delay de abertura | Delay de fechamento |
|---|---|---|
| Mouse hover | **380ms** (120ms se outro tooltip foi aberto há <500ms — "modo de varredura") | 90ms |
| Foco por teclado | **0ms** | imediato ao blur |
| Toque longo | **300ms** + vibração `navigator.vibrate(8)` | fecha ao soltar, ou fica preso se o toque durou >900ms (então fecha em qualquer toque fora) |
| Ícone ⓘ (mobile) | clique = abre preso | clique fora / ✕ |

Em touch, **todo** elemento com tooltip essencial tem um afford visível: o próprio elemento é clicável para abrir detalhes, ou tem um ⓘ de 20×20 no canto.

### 9.2 Posicionamento

Preferência: `topo` → `direita` → `esquerda` → `baixo`. Flip automático com 8px de margem da viewport. Seta de 8px apontando à âncora. Largura `min 220, max 340`. Em telas < 600px, o tooltip vira uma **folha inferior** de largura total, altura automática, com botão de fechar — nada de tooltips espremidos.

### 9.3 Conteúdo (template por tipo)

**Upgrade:**
```
⚔️  Canhão de Plasma                    Nv 247/∞
────────────────────────────────────────────────
Aumenta o dano base de cada projétil.

Efeito por nível     +2,4 de dano
Atual                +592,8 de dano
Após x10             +616,8  (+4,05%)

DPS estimado         8,42 mi/s → 8,78 mi/s   (+4,3%)
Custo (x10)          🪙 84,2 mi
Custo do próximo     🪙 7,91 mi
Eficiência           1,04 mi DPS por 🪙 bi     ⭐ melhor da aba
────────────────────────────────────────────────
Clique: comprar · Shift: máximo · Botão direito: fixar
```

**Stat (no painel de estatísticas / vitais):** mostra a **decomposição completa da fórmula**:
```
Dano                          1,84 mi
────────────────────────────────────
Base                          4
+ Upgrades (plano)            +592,8
× Talentos                    ×2,84
× Cartas (7 equipadas)        ×4,10
× Relíquias                   ×18,7
× Prestígio (fragmentos)      ×31,2
× Buff: Sobrecarga            ×1,45
= Total                       1,84 mi
```
Essa tela é obrigatória para o público-alvo (Melvor/AD). Cada linha é clicável e leva à fonte.

**Carta / Relíquia:** nome na cor da raridade + pips de raridade + efeitos + lore em itálico `--c-txt2` (`data/*.json → lore`).

**Habilidade:** efeito com valores no nível atual **e** no próximo, CD atual (com `cdr` aplicado), duração, custo de melhoria.

**Regra:** todo tooltip é gerado por um **único componente** `Tooltip.render(spec)`; cada painel só fornece o `spec`. Zero HTML duplicado.

---

## 10. ONBOARDING NÃO-INTRUSIVO

Nada de tutorial de 10 telas. **Onboarding por beats disparados por evento**, cada um dispensável, todos puláveis em Config → "Pular tutorial".

| # | Gatilho | Forma | Conteúdo | Bloqueia? |
|---|---|---|---|---|
| 1 | 0s | Ticker | "A torre atira sozinha. Fique de olho." | não |
| 2 | 1º ouro dropado | Spotlight no chip de ouro, 2.5s | "Ouro. Inimigos deixam ao morrer." | não |
| 3 | 25 de ouro acumulado | Spotlight no dock → Upgrades + seta pulsante; halo dourado | "Gaste. Nada aqui recompensa avareza." | **pausa a UI até abrir** (mas o jogo continua) |
| 4 | Painel de upgrades aberto | Halo na 1ª linha comprável | "Compre. O número da direita é o que você ganha." | não |
| 5 | Após 1ª compra | Toast + confete | "Feito. Faça de novo umas mil vezes." | não |
| 6 | Onda 3 | Spotlight na barra de habilidades | "Tecla 1. Use quando apertar." | não |
| 7 | Nível 5 da torre | Badge no dock Talentos + banner | "Pontos de talento. Eles não se gastam sozinhos." | não |
| 8 | Onda 10 (1º chefe) | Banner de chefe + slow-motion 0.4× por 800ms | — | não |
| 9 | Primeira derrota | Modal de derrota (§18) | Explica que perder é normal e o que se mantém | sim |
| 10 | Onda 15 | Banner | "Prestígio à vista. Onda 20." + botão "Ver" | não |
| 11 | Onda 20 | FAB dourado + banner + painel de prestígio abre **em modo preview** (não executa) | Explica o loop de reset | não |
| 12 | 1ª Ascensão concluída | Confete + tour de 3 spotlights (Relíquias, Desafios, Autocompra) | — | não |
| 13 | Volta após >30min offline | Modal offline (§12) | — | sim |

**Spotlight:** overlay `rgba(8,11,20,.78)` com recorte via `clip-path` (retângulo de raio 12 com 8px de folga em volta do alvo) + anel `2px --c-ouro` pulsando 1.2Hz + balão de texto de 260px posicionado no lado com mais espaço + botão `Entendi` (44px) e `Pular tutorial`. Clique no recorte executa a ação real.
Em `prefers-reduced-motion`, o anel não pulsa (fica estático, 2.5px).

Estado persistido em `save.tutorial = { beat: 7, pulado: false, vistos: Set }`. Reexecutável em Config → "Rever tutorial".

---

## 11. MODAL DE PROGRESSO OFFLINE

### 11.1 Regras

* Dispara se `agora - ultimoSalvamento ≥ 60s` (abaixo disso, aplica silenciosamente).
* Eficiência offline: `min(1, 0.35 + bônus)` — base 35%, elevável por talentos/relíquias até 100%.
* Teto de tempo: base **4h**, elevável até **24h** (upgrades de "Núcleo de Espera").
* Se `tempo > teto`, mostra explicitamente `Limite atingido: 4h de 11h32min` com CTA para o upgrade que aumenta o teto — conversão de frustração em objetivo.

### 11.2 Layout (modal 440×auto, máx. 92vw / 86svh)

```
┌────────────────────────────────────────────┐
│              🌙                            │
│      VOCÊ ESTEVE FORA                      │
│        11h 32min                           │  --t-3xl .num
│   (creditadas 4h 00min · limite)           │  --t-sm --c-alerta
├────────────────────────────────────────────┤
│  🪙  Ouro           +2,84 tri              │  linhas 44px, entram
│  ⚔️  Inimigos       +18.400                │  escalonadas 60ms
│  🌊  Ondas          +7   (147 → 154)       │
│  💠  Fragmentos     +1,2 mi                │
│  🃏  Cartas         3 novas  [ver]         │
│  🏆  Conquistas     2 desbloqueadas        │
├────────────────────────────────────────────┤
│  Eficiência offline  35%   ▓▓▓░░░░░░░      │
│  ↑ Aumente em: Talentos › Fortuna › Vigília│
├────────────────────────────────────────────┤
│  [ Coletar ]        [ Coletar ×2  📺/💎 ]  │
└────────────────────────────────────────────┘
```

* **Animação:** cada linha entra com `translateX(-10px)+fade` 200ms, escalonada em 60ms; o número faz *count-up* de 0 ao valor em 700ms com easing `outExpo`. Som de moeda por linha (pitch subindo). Total ≈ 1.2s — nunca mais que isso.
* **`Coletar ×2`:** custo em gemas (padrão 25 💎) ou grátis 1×/dia. Botão só existe se houver gemas suficientes ou o grátis disponível. Nunca é o botão primário visualmente (é secundário com borda dourada).
* `Esc` / clique no scrim = Coletar (nunca perde recompensa).
* **Pular a animação:** qualquer clique durante o count-up completa tudo instantaneamente.
* Se o ganho for irrisório (< 0.5% do patrimônio), não abre modal — só um toast.

---

## 12. TELA DE PRESTÍGIO

3 camadas (`data/prestige.json`): **Ascensão** (💠 fragmentos, onda 25), **Singularidade** (🌌 núcleos, onda 150 + 8 Ascensões), **Transcendência** (✴️ éter, onda 500 + 5 Singularidades).

### 12.1 Estrutura do painel

Abas superiores = camadas. Camadas não desbloqueadas mostram o requisito com progresso (`8/8 Ascensões ✓ · Onda 147/150`).

```
┌───────────────────────────────────────────────┐
│ 💠 ASCENSÃO                            💠 84,2k│
├───────────────────────────────────────────────┤
│                                               │
│            ┌───────────────┐                  │
│            │      💠       │  anel de energia │
│            │   +12,4 mil   │  --t-3xl, dourado│
│            │  fragmentos   │                  │
│            └───────────────┘                  │
│        84,2 mil  →  96,6 mil   (+14,7%)       │
│                                               │
│   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░  onda 147/160 │
│   +1 fragmento a cada onda a partir daqui:    │
│   próxima onda vale +38 · onda 160 vale +52   │
├───────────────────────────────────────────────┤
│  PERDE                    MANTÉM              │
│  🪙 Ouro (2,4 qa)         💠 Fragmentos       │
│  ⚔️ Upgrades (1.284 nv)   🏺 Relíquias        │
│  🌊 Onda (147 → 1)        🃏 Cartas           │
│  🗼 Nível da torre (34)   🏆 Conquistas       │
│                           📊 Estatísticas     │
│                           🌳 Talentos         │
├───────────────────────────────────────────────┤
│  Bônus permanente após: dano ×31,2 → ×34,8    │
│  Tempo estimado p/ voltar à onda 147: ~6 min  │
├───────────────────────────────────────────────┤
│         [  ASCENDER  ]     (segurar 1,2s)     │
└───────────────────────────────────────────────┘
```

### 12.2 Regras de UX específicas

* **Preview sempre visível e sempre atualizado** (2Hz). Nunca "clique para ver quanto ganha".
* **Delta relativo** é o número emocional: `+14,7%` do total. Quando `< 5%`, aparece em `--c-alerta` com o aviso: *"Ganho pequeno. Considere avançar mais ondas."* — o jogo desaconselha ativamente prestígios ruins. Quando `≥ 100%`, o número vira dourado com brilho e o FAB aparece no HUD.
* **"Próxima onda vale +X"**: transforma "quando prestigiar?" numa decisão informada. Mostra também o **ponto ótimo estimado** (onda em que o ganho/minuto é maximizado), com um marcador ▲ na barra.
* **Tempo estimado de retorno**: calculado com o histórico das últimas 3 corridas (ondas/min médio ajustado pelo novo multiplicador). Se não houver histórico, esconde a linha.
* **Segurar para confirmar:** o botão primário exige `pointerdown` sustentado por **1200ms**, com anel de progresso preenchendo em volta e um som crescente. Soltar antes cancela com um "clunk". Alternativa acessível: teclado `Enter` no botão abre um `confirm` modal com "Ascender"/"Cancelar" (nunca exigir sustentação para teclado/leitor de tela).
* **Cerimônia de reset (1.4s, pulável):** flash branco 120ms → torre se desfaz em partículas subindo → tela escurece → fragmentos voam para o chip do HUD com *count-up* → nova torre se monta → toast `Ascensão #9 · 💠 +12,4 mil`. Em `prefers-reduced-motion`: corte seco + toast.
* **Loja de fragmentos** (relíquias) fica no painel **Relíquias**, não aqui. Este painel é só a decisão de resetar. Após ascender, o jogo abre automaticamente Relíquias com badge — o gasto imediato é o pico de dopamina.

---

## 13. DEMAIS PAINÉIS (especificação condensada)

### 13.1 Habilidades (`H`)
Lista de 10 cards de 84px: ícone 40, nome, descrição interpolada com os valores **do nível atual**, `CD 40s → 36s`, barra de nível, botão de melhoria (usa o mesmo componente de lote de §7, mas em **gemas** ou ouro conforme o design). Toggle de auto-cast. Filtro: `Todas / Desbloqueadas / Melhoráveis`.

### 13.2 Talentos (`T`)
Árvore em canvas dedicado (não DOM) com 3 ramos (Fúria 🔴 / Bastião 🔵 / Fortuna 🟡), 36 nós, tiers 0..N.
* Layout: colunas por ramo em desktop (3 colunas de 1/3), abas por ramo em mobile.
* Nó: hexágono 56px (48 mobile). Estados: `bloqueado` (cinza 25%), `disponível` (borda na cor do ramo, pulsando se há pontos), `parcial` (`3/10` com anel), `máximo` (preenchido + brilho).
* Linhas de dependência: 2px, cor do ramo a 30%; acesa a 100% quando o pré-requisito está satisfeito.
* Pan/zoom: arraste + roda (`0.6×`–`1.6×`), pinça em touch. Botão "centralizar".
* Header mostra `Pontos: 7` grande e dourado + `Redistribuir` (custo em gemas, confirmação).
* Clique = +1 ponto; `Shift+clique` = máximo possível; long-press = tooltip.

### 13.3 Cartas (`C`)
Duas seções: **Equipadas** (grade de slots, N slots desbloqueáveis) e **Coleção** (grade de 96×132 com scroll virtualizado).
* Carta: moldura na cor da raridade, `forma` do JSON desenhada em SVG procedural, ícone, nome, efeitos, `Nv 3/5` (duplicatas fundem).
* Pips de raridade (1–6 pontos) no rodapé — redundância não-cromática obrigatória.
* Filtros: raridade, stat afetado, `[ ] só não equipadas`, ordenar por poder.
* Arrastar-e-soltar para equipar (desktop) / tocar carta → "Equipar em..." (mobile).
* Abrir pacote: animação de 1.1s com carta virando; raridade ≥ épico ganha flash de tela + shake 3px + som dedicado. **Pulável com toque.** Em rajada (10 pacotes), mostra grade de resultados de uma vez com as raras destacadas.

### 13.4 Relíquias (`R`)
Lista tipo upgrade, moeda = fragmentos/núcleos/éter (aba por moeda). Mesmo componente de linha de §6.2 com o botão de lote. Lore em itálico no tooltip. Marcador `×1,5 por nível` explícito. Ordenação padrão: melhor valor.

### 13.5 Desafios (`D`)
Grade de 14 cards 160×190. Cada card: ícone, nome, dificuldade (1–5 estrelas), modificadores em pílulas (`cadência 0,3×`, `dano 5×`, `onda máx 40`), objetivo, recompensa permanente, estado (`Não tentado` / `Melhor: onda 31/40` / `✓ Concluído`).
Iniciar = modal de confirmação (reseta a corrida). Durante um desafio: **banner permanente** no topo com o nome, o objetivo e `Abandonar`; a moldura do canvas ganha borda de 2px na cor do desafio.

### 13.6 Missões (`M`)
Abas `Diárias` / `Semanais` / `Temporada`.
Linha de missão 64px: ícone, nome, descrição com `{v}` interpolado, barra de progresso, recompensa, botão `Coletar` (verde, pulsa quando pronto).
Header: contador regressivo para o reset (`Renova em 07:42:11`, atualizado 1Hz) e `Coletar tudo`.
Passe de temporada: trilha horizontal com 50 níveis, marcadores a cada 5, barra de XP, scroll-snap, botão "ir para o próximo não coletado".

### 13.7 Conquistas (`K`)
85 conquistas em 6 categorias (Progresso, Combate, Economia, Coleção, Prestígio, Segredos).
* Header: `47/85 · 55%` + barra + total de bônus concedido (`+18,4% de ouro`).
* Abas por categoria com `12/18`.
* Item: 72px, ícone 40 (dessaturado se bloqueado), nome, descrição, recompensa, barra de progresso quando mensurável, data de desbloqueio `--t-xs`.
* **Segredos:** nome e descrição ocultos (`???` + `▓▓▓▓▓▓`) até desbloquear. Mostrar só a contagem.
* Virtualização obrigatória (`>60` itens): janela de 20 itens com `content-visibility: auto` + `contain-intrinsic-size: 0 72px`.
* Filtro `[ ] esconder desbloqueadas`, busca.

### 13.8 Codex (`L`)
Bestiário (inimigos com `lore`), Eras (com `descricao` e a paleta), Moedas, Glossário de stats, Changelog.
Bestiário: card por inimigo com o **desenho procedural real** renderizado num mini-canvas de 64×64, stats relativos (HP, velocidade, ouro como barras 0–100 normalizadas), contagem de mortes, lore. Entradas bloqueadas em silhueta preta.

### 13.9 Estatísticas (`X`)
Abas: `Corrida atual` · `Total` · `Recordes` · `Detalhamento`.

* **Corrida atual:** tempo, onda, pico de DPS, ouro ganho/gasto, mortes por tipo, dano por fonte (torre/orbes/habilidades/veneno) como barra empilhada de 100%.
* **Total:** todos os acumulados de sempre, tempo de jogo, nº de prestígios por camada, moedas ganhas.
* **Recordes:** maior onda, maior DPS, maior ouro/s, corrida mais rápida à onda 100, maior crítico.
* **Detalhamento (a aba mais importante):** para cada um dos 39 stats de `data/stats.json`, a decomposição multiplicativa completa (§9.3). Agrupado por família (Ofensivo / Elemental / Defensivo / Orbes / Econômico / Utilitário). Cada fonte é clicável.
* **Gráficos:** sparklines desenhadas em canvas 240×48 (ouro/s e DPS nos últimos 5 min, buffer circular de 300 amostras a 1Hz). Sem biblioteca. Eixo Y logarítmico, rótulo do máximo.
* `Copiar resumo` (para colar em fórum/Discord) gera um bloco de texto formatado.

---

## 14. CONFIGURAÇÕES — MAPA COMPLETO

Painel com 7 seções (abas laterais em desktop ≥900, acordeão em mobile).

### 14.1 Áudio
| Controle | Tipo | Faixa / Padrão |
|---|---|---|
| Volume mestre | slider | 0–100, padrão **70** |
| Música | slider | 0–100, **50** |
| Efeitos | slider | 0–100, **80** |
| Interface (cliques) | slider | 0–100, **60** |
| Silenciar em segundo plano | toggle | **ligado** |
| Reduzir sons repetidos | toggle | **ligado** (limita mesmo SFX a 8/s, com voice-stealing) |
| Compressão dinâmica | toggle | **ligado** (evita clipping com centenas de sons) |
| Testar áudio | botão | toca sequência de referência |

Cada slider tem entrada numérica ao lado (`--t-sm .num`, 3ch) e é operável por teclado (`←/→` 1, `Shift` 10, `Home/End`).

### 14.2 Gráficos
| Controle | Opções | Padrão |
|---|---|---|
| Qualidade | Baixa / Média / Alta / Automática | **Automática** |
| Limite de partículas | 0 / 200 / 600 / 1500 / 4000 | **1500** |
| Números de dano | Nenhum / Só críticos / Agregados / Todos | **Agregados** |
| Rastro de projéteis | off / curto / longo | curto |
| Tremor de tela | 0–150% | 100% |
| Flashes e brilhos | 0–150% | 100% |
| Névoa/vinheta de era | toggle | ligado |
| Limite de FPS | 30 / 60 / 120 / ilimitado | **60** |
| Escala de renderização | 50–100% | 100% (auto-reduz para 75% se FPS<45 por 5s, com aviso) |
| Mostrar FPS e entidades | toggle | desligado |

**Qualidade "Automática":** monitora o frame time (média de 120 frames). Se `>20ms` por 3s → desce um degrau; se `<11ms` por 15s → sobe. Nunca oscila mais de 1×/15s. Notifica via ticker a primeira vez.

### 14.3 Interface
Tamanho da interface (0.85–1.5) · Densidade (Confortável/Compacta/Automática) · Posição do painel (Direita/Esquerda) · Modo canhoto (espelha dock e FAB) · Modo minimalista (esconde vitais e rastreador) · Mostrar taxa de ouro/s · Confirmar compras acima de X% do patrimônio (0/25/50/100%) · Modo de lote padrão · Lote estrito · Tela cheia automática.

### 14.4 Números e idioma
| Controle | Opções |
|---|---|
| Formato | **Curto PT-BR** (1,23 mi) / **Curto EN** (1.23M) / **Científico** (1,23e6) / **Engenharia** (1,23×10⁶) / **Notação de letras** (1,23aa) / **Misto** (curto até e15, científico acima) |
| Casas decimais | 0 / 1 / **2** / 3 |
| Separador | **Vírgula decimal + ponto de milhar (pt-BR)** / Ponto decimal (en-US) |
| Cortar zeros à direita | toggle, ligado |
| Limiar de científico | e9 / e15 / **e33** / nunca |
| Idioma | **Português (Brasil)** / English — os JSON já têm `nomeEn`/`descEn`/`loreEn` |

**Sufixos PT-BR (padrão):** `mil, mi, bi, tri, qa, qi, sx, sp, oc, no, de, ud, dd, td, qad, qid, sxd, spd, ocd, nod, vg` — depois disso, muda para científico automaticamente. Tabela como constante exportada, não hard-coded em cada chamada.

### 14.5 Acessibilidade
Ver §16 para a especificação completa. Controles: Reduzir movimento (Auto/Sempre/Nunca) · Alto contraste · Modo daltônico (Nenhum/Protanopia/Deuteranopia/Tritanopia/Monocromático) · Aumentar tamanho dos alvos de toque (44→56px) · Sublinhar links e ações · Texto de legenda para sons importantes · Modo narrado (verbosidade do leitor: Mínima/Normal/Detalhada) · Desligar tremor · Desligar flashes (garante < 3 flashes/s) · Sem limite de tempo em confirmações (converte "segurar 1,2s" em modal de 2 botões).

### 14.6 Dados
* `Salvar agora` (mostra `Último salvamento: há 12s`).
* `Exportar save` → gera string Base64 de `JSON.stringify(save)` comprimida (LZ simples próprio) com prefixo `TE1:` e checksum CRC32 de 8 hex. Exibida numa `<textarea readonly>` de 6 linhas + botão `Copiar` + botão `Baixar .txt` (via `Blob` + `<a download>`).
* `Importar save` → `<textarea>` + validação (prefixo, checksum, versão). Erros específicos: `Checksum inválido`, `Versão futura (2.1 > 1.4)`, `Formato irreconhecível`. **Sempre** faz backup automático do save atual antes de importar (`save_backup_auto`).
* `Backups automáticos`: mantém 3 rotativos (a cada 10 min) + 1 "pré-prestígio" + 1 "pré-importação". Lista com data e botão `Restaurar`.
* `Salvamento automático`: 15s / 30s / **60s** / manual.
* `Uso de armazenamento`: mostra `48,2 KB de ~5 MB`.
* **`Apagar tudo`**: dupla confirmação — modal 1 explica o que se perde; modal 2 exige digitar `APAGAR` num campo de texto. Botão vermelho, desabilitado até o texto bater.

### 14.7 Sobre
Versão, créditos, tempo total de jogo, atalhos de teclado (tabela completa), link para o changelog no Codex.

---

## 15. ATALHOS DE TECLADO

| Tecla | Ação | Contexto |
|---|---|---|
| `1`–`9`, `0` | Ativar habilidade 1–10 | jogo |
| `U T C R P M D K L X` | Abrir/fechar Upgrades, Talentos, Cartas, Relíquias, Prestígio, Missões, Desafios, Conquistas, Codex, Estatísticas | global |
| `H` | Habilidades | global |
| `O` ou `Esc` (com nada aberto) | Configurações | global |
| `Esc` | Fechar painel/modal/tooltip (um nível por vez) | global |
| `Tab` / `Shift+Tab` | Navegação de foco padrão | global |
| `←` `→` | Trocar aba dentro do painel | painel |
| `↑` `↓` | Navegar itens da lista | painel |
| `Enter` / `Espaço` | Ativar item focado | painel |
| `Shift+1..4` | Modo de lote x1 / x10 / x25 / Máx | global |
| `Shift+clique` | Comprar máximo (pontual) | listas |
| `Alt+clique` | Comprar 1 (pontual) | listas |
| `A` | Comprar tudo que dá (na aba atual) | painel de compras |
| `Ctrl+A` | Alternar autocompra mestre | global |
| `Espaço` | Pausar / retomar | jogo (sem painel aberto) |
| `+` / `-` | Aumentar / diminuir velocidade | jogo |
| `S` | Salvar agora | global |
| `F` | Tela cheia | global |
| `/` | Focar busca do painel aberto | painel |
| `?` ou `F1` | Sobreposição de atalhos | global |
| `` ` `` | Painel de debug (só em build dev) | global |

**Regras:** nenhum atalho dispara quando o foco está em `input`/`textarea` (exceto `Esc`). Todo atalho é remapeável em Config → Interface → Atalhos (tabela editável, detecção de conflito). A sobreposição `?` mostra a tabela real (gerada do mapa, nunca duplicada em texto).

---

## 16. LAYOUT RESPONSIVO

### 16.1 Breakpoints

```js
export const BP = [
  { id:'xs', max: 379 },  // celular estreito
  { id:'s',  max: 599 },  // celular retrato
  { id:'m',  max: 899 },  // celular paisagem / tablet pequeno retrato
  { id:'l',  max: 1279 }, // tablet paisagem / laptop
  { id:'xl', max: 1679 },
  { id:'xxl',max: Infinity },
];
```
Escrito em `#app[data-bp]` e `#app[data-orient="retrato|paisagem"]`. Usa `ResizeObserver` no `#app` (não `window`), debounce 100ms. Também `data-touch="1"` via `matchMedia('(pointer:coarse)')`.

Unidades: **`svh`/`dvh`**, nunca `vh` puro (barra de endereço do mobile). `env(safe-area-inset-*)` aplicado ao dock, ao FAB e ao topo.

### 16.2 Celular retrato (S/XS — 390×844 de referência)

```
┌─────────────────────┐  0    safe-area-top
│ 🪙 2,4M  💎 84  +2  │  44   moedas (compactas, 3 visíveis)
│ ONDA 147   ▓▓▓░ x2  │  40   onda (linha única)
│ ❤▓▓▓▓▓▓░  🛡▓▓░     │  22   vitais reduzidos a 2 barras
├─────────────────────┤
│                     │
│         🗼          │  torre em 42% da altura
│      (arena)        │
│                     │
├─────────────────────┤
│  [buffs · · · ]     │  38
│ [1][2][3][4][5][6]  │  58   habilidades (scroll-x, snap)
│ ⚔️ ✨ 🌳 🃏 📋 ⋯   │  60   dock (6 + "mais")
└─────────────────────┘  safe-area-bottom
```
* Arena útil: `100svh - 106 (topo) - 156 (rodapé)` ≈ 582px.
* Painel = bottom sheet 78svh; a torre sobe para 26% da altura enquanto aberto (transição 240ms).
* Habilidades: fileira rolável com `scroll-snap`, 6 visíveis, indicador de página em pontinhos de 4px.
* Rastreador vira uma pílula de 32px flutuante no canto superior direito.
* Tooltips viram folhas inferiores.
* **Zona do polegar:** dock, habilidades e FAB estão todos abaixo de 62% da altura. O botão de compra numa linha de painel fica sempre à **direita** (destro) ou à **esquerda** (modo canhoto).

### 16.3 Celular paisagem (M — 844×390)

Espaço vertical crítico (390px). Layout de **colunas**:
* Faixa superior comprimida para 36px (moedas + onda numa linha só).
* Vitais migram para a **esquerda vertical** (barras rotacionadas 90°, 8×160).
* Habilidades vão para a **coluna direita** vertical, 2 colunas × 5, slots de 44px.
* Dock vira **rail esquerdo** vertical de 56px de largura, ícones sem rótulo.
* Painel: gaveta direita de 340px sobreposta com scrim 0.35.
* Arena útil ≈ 690×330 — a torre reposiciona para o centro dessa área.

### 16.4 Tablet (L)
Dock inferior com rótulos, gaveta de 380px, densidade confortável, habilidades 52px. Painel pode ficar **fixado** (`pin`) — botão 📌 no header — e então o canvas trabalha permanentemente com a largura reduzida.

### 16.5 Desktop (XL/XXL)
Gaveta 400–520px. Em ≥1680, permite **duas gavetas** lado a lado (ex.: Upgrades + Estatísticas) — botão `⧉` no header abre em painel secundário. Largura máxima do conjunto de UI: 1040px; arena nunca fica com menos de 640px de largura.

### 16.6 Regras universais
* Nenhum texto abaixo de 11px em nenhum breakpoint.
* Nenhum alvo interativo abaixo de 44×44 CSS px (48 com "alvos grandes").
* Espaço mínimo de 8px entre alvos adjacentes.
* Rotação preserva estado: painel aberto, aba, posição de scroll (salvos em `sessionStorage`).
* `touch-action: manipulation` em tudo (elimina o delay de 300ms); `none` só na árvore de talentos (pan/zoom próprio).
* Nenhum `hover:` sem `@media (hover:hover)`.

---

## 17. ACESSIBILIDADE

### 17.1 Contraste (valores medidos, WCAG 2.2)

| Par | Ratio | Nível |
|---|---|---|
| `--c-txt #e6ecf7` sobre `--c-painel #121a2e` | 14.1:1 | AAA |
| `--c-txt2 #93a3c4` sobre `--c-painel` | 6.2:1 | AA |
| `--c-txt3 #5f6f92` sobre `--c-painel` | 2.9:1 | **falha** → só decorativo; substituído por `#8393b6` (4.6:1) em Alto Contraste |
| `--c-ouro #fbbf24` sobre `--c-painel` | 9.8:1 | AAA |
| `--c-ok #4ade80` sobre `--c-painel` | 9.1:1 | AAA |
| `--c-perigo #f87171` sobre `--c-painel` | 6.4:1 | AA |
| `--c-acento #38bdf8` sobre `--c-painel` | 7.6:1 | AAA |
| `--c-borda #243356` sobre `--c-painel` | 1.5:1 | decorativo — bordas informativas usam `--c-borda-forte #3b5a9e` (2.6:1) + 2px, e em Alto Contraste `#5b81d6` (4.9:1) |

Componentes de UI (bordas de botão, indicadores de estado): mínimo **3:1** contra o fundo adjacente. Foco: **anel de 3px `#ffffff` + halo externo de 1px `#000`**, sempre ≥3:1 contra qualquer fundo, `outline-offset: 2px`, via `:focus-visible`.

**Modo Alto Contraste:** substitui a paleta de superfícies por `#000814 / #0b1526 / #17233d`, elimina transparências e blur, engrossa bordas para 2px, sobe `--c-txt2` para `#b9c6e0`, e adiciona fundo sólido atrás de qualquer texto sobre o canvas.

### 17.2 Daltonismo

Três paletas alternativas, aplicadas por sobrescrita de tokens em `#app[data-cvd="deuteranopia"]` etc. Ajustes centrais:

| Semântica | Padrão | Protan/Deuteran | Tritan |
|---|---|---|---|
| Pode comprar | `#4ade80` | `#38bdf8` (azul) | `#4ade80` |
| Não pode / perigo | `#f87171` | `#f0a83c` (âmbar) | `#f87171` |
| Ouro | `#fbbf24` | `#fbbf24` | `#f0a8c0` |
| Raro | `#38bdf8` | `#38bdf8` | `#8b9cf0` |
| Lendário | `#fbbf24` | `#ffffff`+glow | `#fbbf24` |

**Mas o mecanismo real é a redundância, não a paleta.** Regras obrigatórias:
1. Todo estado de compra tem símbolo (● / ⭐ / 🔒 / MÁX) além da cor.
2. Toda raridade tem **pips** (1–6 pontos) e **forma de moldura** distinta além da cor.
3. Toda barra crítica (vida) tem um marcador de limiar em 25% e o valor numérico ao lado.
4. Inimigos no canvas têm **silhuetas distintas** (`forma` no JSON: círculo, seta, hexágono...) — cor nunca é o único diferenciador de tipo.
5. Chefes têm contorno branco de 2px e ícone ☠ acima, além da cor.
6. Modo Monocromático: tudo em escala de cinza + os símbolos e formas carregam 100% da informação. Serve como teste de validação do design.

### 17.3 Movimento

`prefers-reduced-motion: reduce` (ou o toggle "Sempre") aplica:
* `--d-*` reduzidos (§2.3); nenhuma animação com `ease-mola`.
* Tremor de tela = 0. Flashes de tela = fade suave de 200ms sem pico.
* Partículas em 25% do orçamento; sem rastros; sem parallax de fundo.
* Números flutuantes: sem arco nem rotação — sobem 12px em linha reta e somem.
* Barras de progresso: transição linear de 100ms, sem "elástico".
* Cerimônias (prestígio, abrir pacote, transição de era): substituídas por corte + toast.
* Nada pisca acima de 3Hz — **e nunca mais de 3 flashes por segundo em nenhuma configuração** (proteção contra fotossensibilidade, verificada no modo Alta Qualidade também).
* Auto-scroll e carrosséis: nenhum é automático em nenhum modo.

### 17.4 Leitores de tela

* Landmarks: `role="region"` no HUD, `role="dialog"` nos painéis, `role="navigation"` no dock, `role="tooltip"`.
* Canvas: `aria-hidden="true"` + um resumo textual paralelo atualizado a 0.2Hz em `#anuncio-sr` **apenas** no "Modo narrado: Detalhada": `"Onda 147. 23 inimigos. Torre com 84% de vida."`
* Barras: `role="progressbar"` com `aria-valuenow/min/max/valuetext` — `valuetext` usa o número formatado ("4,21 milhões de 5 milhões").
* Botões de compra: `aria-label` completo — `"Comprar Canhão de Plasma, 10 níveis, custo 84,2 milhões de ouro, aumenta o dano em 4,3 por cento. Disponível."` Estado indisponível: `aria-disabled="true"` (não `disabled`, para permanecer focável e legível) + `"Faltam 12,4 milhões."`
* Abas: `role="tablist"/"tab"/"tabpanel"` com `aria-selected` e `aria-controls`.
* Badges: `aria-label="3 upgrades disponíveis"` no botão pai; o badge em si é `aria-hidden`.
* Toasts: contêiner `aria-live="polite"`, cada toast com texto completo; toasts puramente decorativos (cartas comuns) são `aria-hidden`.
* Modais: `aria-modal="true"`, foco preso, `aria-labelledby` no título, `Esc` fecha.
* Ordem de tabulação: moedas → onda → controles → vitais → habilidades → dock → painel. `skip link` invisível "Ir para os menus" como primeiro elemento focável.
* Emoji nunca é o único conteúdo de um elemento: sempre acompanhado de texto ou `aria-label`; emojis decorativos recebem `aria-hidden="true"` + `role="img"` quando informativos.

### 17.5 Outros
* Zoom do navegador até 200% sem perda de funcionalidade nem scroll horizontal.
* `prefers-contrast: more` ativa Alto Contraste automaticamente.
* Nenhum limite de tempo obrigatório: "segurar para confirmar" tem alternativa de 2 botões; eventos com timer podem ser pausados em Config → Acessibilidade → "Sem limite de tempo".
* Toda informação transmitida por som tem equivalente visual (opção "Legendas de áudio": pílula discreta no canto com `♪ Chefe se aproximando`).

---

## 18. FEEDBACK, JUICE E ORÇAMENTOS

### 18.1 Números flutuantes (canvas, pool de 384)
| Tipo | Fonte | Cor | Movimento | Duração |
|---|---|---|---|---|
| Dano normal | 13px | `#e6ecf7` a 78% | sobe 26px, arco ±6px | 620ms |
| Crítico | 19px bold | `#fbbf24` | sobe 34px, `scale 1.4→1` | 760ms |
| Ouro | 14px | `#fbbf24` | sobe 22px | 700ms |
| Dano recebido | 16px | `#f87171` | desce 14px | 700ms |
| Cura | 14px | `#4ade80` | sobe 18px | 640ms |

**Agregação (padrão):** dano no mesmo inimigo dentro de 220ms soma num único número que cresce (`scale` +4% por acúmulo, teto 1.6). Sem isso, 300 inimigos = ilegível. Modo "Todos" desativa a agregação (só para PCs fortes). Teto duro: **60 números vivos**; ao estourar, os mais antigos são reciclados.

### 18.2 Tremor de tela (orçamento)
`shake(intensidade, ms)` — soma vetorial com **teto de 6px de amplitude** e decaimento exponencial (τ=90ms). Fontes: tiro (0.4px), crítico (0.8px), morte de elite (2px), chefe leva marco (3px), habilidade Nova (4px), derrota (6px). Escalado por `Config.tremor` e zerado em Reduzir Movimento.

### 18.3 Combo
Contador junto à torre: `x1,00` crescendo `+0,02` por abate, decaindo `-0,35/s` após 2s sem abate. Cor sobe `--c-txt2 → --c-ouro → --c-rosa` em 2×/5×/10×. Marcos (2/5/10/25×) disparam flash de escala, som ascendente e ticker. Multiplica o ouro.

### 18.4 Orçamento de performance da UI (60fps = 16,6ms)
| Item | Budget |
|---|---|
| Simulação + render do canvas | ≤ 11ms |
| Atualização do HUD | ≤ 1,2ms (a 8Hz, ou seja, ~0,15ms/frame amortizado) |
| Painel aberto (recálculo de lista) | ≤ 2ms, a 2Hz, com *dirty flags* |
| Layout/paint do DOM | ≤ 1ms — proibido ler `offsetWidth`/`getBoundingClientRect` no loop |

**Regras duras:**
1. Nenhum `innerHTML` no loop. Listas usam pool de linhas reutilizadas com `dataset.id`.
2. Toda atualização de texto passa por um cache: `if (el._v === novo) return; el._v = novo; el.textContent = novo;`
3. Animações só em `transform` e `opacity`. `will-change` aplicado **apenas** enquanto anima e removido no `transitionend`.
4. Painel fechado = zero trabalho (listener desregistrado, `hidden`, `content-visibility: hidden`).
5. `requestAnimationFrame` único, com relógio de simulação em passo fixo (16,667ms) e acumulador; UI atualiza em ticks derivados (8Hz/2Hz), nunca por frame.
6. Aba em segundo plano: `document.hidden` → simulação vira "modo offline acelerado" (passos grandes), UI para 100%.

---

## 19. ESTADOS DE BORDA

| Situação | Tratamento |
|---|---|
| **Derrota da torre** | Modal 400×auto: `A TORRE CAIU` + onda alcançada + o que se mantém (tudo, menos a onda) + `Recomeçar da onda X` (X = 90% do recorde, arredondado para múltiplo de 5) e `Recomeçar do início`. Sem punição real. Confete cinza, som grave, slow-mo 0.3× por 1s. |
| **Save corrompido** | Modal de erro com a mensagem exata, botão `Restaurar backup (há 8 min)`, `Exportar o save corrompido` (para suporte) e `Começar do zero`. Nunca apaga sozinho. |
| **localStorage cheio/bloqueado** | Banner permanente vermelho: `Não foi possível salvar. O progresso pode ser perdido.` + `Exportar agora`. Detecta via try/catch no primeiro save. |
| **Save de versão futura** | Bloqueia importação, oferece exportar. |
| **Lista vazia** (busca sem resultado, coleção vazia) | Estado vazio ilustrado: glifo procedural 64px em `--c-txt3`, título `--t-md`, subtítulo com a ação (`Limpar filtros`). Nunca uma área branca sem explicação. |
| **Painel bloqueado** (jogador chegou por atalho) | Mostra a tela de requisito, não um erro: ícone grande, `Desbloqueia na onda 20`, barra de progresso `147/20 ✓` ou `12/20`. |
| **Primeiro frame / boot** | Tela de 400ms máx.: torre desenhada procedural + barra de 200×3. Se demorar > 1,5s, mostra o passo atual (`Carregando dados...`). |
| **Redução automática de qualidade** | Ticker único: `Qualidade reduzida para manter 60fps. [Ajustar]` — só na primeira vez por sessão. |
| **Número absurdo** | Acima de `e308` (limite de float), o Decimal próprio assume; a UI nunca mostra `Infinity` nem `NaN` — fallback para `∞` com tooltip explicativo é bug, deve ser corrigido na camada de dados. |

---

## 20. CHECKLIST DE ACEITAÇÃO (o que valida ≥95/100)

**Layout e responsividade**
- [ ] 6 breakpoints testados; retrato e paisagem; nenhum scroll horizontal em nenhum
- [ ] A torre nunca é coberta por UI em nenhum estado
- [ ] Rotação preserva painel, aba e scroll
- [ ] `safe-area-inset` respeitado em notch e barra de gestos
- [ ] Zoom de 200% funcional

**Densidade de informação**
- [ ] Nenhuma aba de upgrade exige scroll em desktop
- [ ] Todo botão de compra mostra custo + efeito + delta antes do clique
- [ ] Busca, ordenação, filtros e fixação funcionam em todas as listas longas
- [ ] Listas com >60 itens são virtualizadas e rolam a 60fps

**Estados**
- [ ] Os 6 estados de compra são distinguíveis em escala de cinza
- [ ] Badges nunca aparecem para algo não acionável
- [ ] Máx. 3 toasts, 1 banner, 1 modal simultâneos

**Compra em lote**
- [ ] `Máx` é calculado por logaritmo, não por iteração
- [ ] Lote parcial mostra o número real comprável
- [ ] Auto-repetição por pressão longa com escada de pitch

**Acessibilidade**
- [ ] Jogo completável usando **apenas teclado**
- [ ] Todos os pares de texto passam 4.5:1 (3:1 para ≥19px)
- [ ] `prefers-reduced-motion` remove 100% do tremor e dos flashes
- [ ] Modo monocromático mantém toda a informação legível
- [ ] Leitor de tela anuncia progresso sem inundar (≤1 msg/5s)
- [ ] Nenhum piscar acima de 3Hz em nenhuma configuração

**Performance**
- [ ] 60fps com 400 inimigos + 300 projéteis + painel aberto
- [ ] HUD custa <1,5ms por atualização
- [ ] Zero `innerHTML` e zero leitura de layout dentro do `rAF`
- [ ] Aba em segundo plano não consome CPU de render

**Dopamina**
- [ ] Toda compra tem: som com pitch, contador rolante, partícula e flash de moeda
- [ ] Toda raridade ≥ épico tem cerimônia distinta e pulável
- [ ] Preview de prestígio sempre visível e sempre honesto (inclusive desaconselhando)
- [ ] Modal offline conclui a animação em ≤1,2s e é pulável com um toque