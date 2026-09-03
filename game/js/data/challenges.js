/**
 * challenges.js — DESAFIOS: runs com as regras trocadas.
 *
 * Um desafio é uma partida separada (não conta para o save principal) em que
 * um punhado de modificadores reescreve o combate. Fechar o objetivo devolve
 * uma recompensa PERMANENTE que soma com todas as outras — o jogador nunca
 * perde nada por tentar, só tempo e dignidade.
 *
 * Desbloqueado pelo nó 'an_desafios' (Provações) da árvore de núcleos.
 *
 * mods — como cada chave é lida pela simulação:
 *   hpInimigo         multiplica a vida de TODO inimigo (chefes inclusos)
 *   velocidadeInimigo multiplica a velocidade de deslocamento deles
 *   danoTorre         multiplica o dano final da torre (depois de tudo)
 *   ouro / xp         multiplicam o ouro e a experiência ganhos
 *   cadencia          multiplica os tiros por segundo
 *   semHabilidades    os botões de habilidade ficam trancados
 *   semUpgrades       a loja de upgrades fica fechada (o ouro cai mesmo assim)
 *   semOrbes          orbes zerados, inclusive os de carta e habilidade
 *   semCritico        chance crítica zerada (o dano crítico vira decoração)
 *   semRegen          regeneração zerada; escudo continua funcionando
 *   vidaFixa          > 0 trava a vida máxima da torre nesse valor exato
 *   ondaMax           > 0 encerra a run ao completar essa onda
 *   densidade         multiplica a quantidade de inimigos por spawn
 *   ondaAuto          > 0: a onda avança sozinha a cada N segundos, matando
 *                     você ou não — os sobreviventes ficam no mapa
 */

/** Estado neutro: qualquer chave ausente em `mods` assume este valor. */
export const MODS_PADRAO = {
  hpInimigo: 1,
  velocidadeInimigo: 1,
  danoTorre: 1,
  ouro: 1,
  xp: 1,
  cadencia: 1,
  semHabilidades: false,
  semUpgrades: false,
  semOrbes: false,
  semCritico: false,
  semRegen: false,
  vidaFixa: 0,
  ondaMax: 0,
  /* extensões usadas pelos desafios de multidão e de ritmo */
  densidade: 1,
  ondaAuto: 0,
};

export const DESAFIOS = [
  /* ============================================ DIFICULDADE 1 — entrada */
  {
    id: 'ferrugem',
    nome: 'Ferrugem no Gatilho', nomeEn: 'Rust in the Trigger',
    icone: '🐌', cor: '#a16207', dificuldade: 1,
    desc: 'A torre atira a cada ~3 segundos, mas cada tiro causa 5× de dano. Errar o alvo custa caro; não errar custa paciência.',
    descEn: 'The tower fires once every ~3 seconds, but each shot hits for 5×. Missing is expensive; not missing is slow.',
    mods: { cadencia: 0.3, danoTorre: 5, ondaMax: 40 },
    objetivo: { onda: 40 },
    recompensa: [
      { stat: 'dano', tipo: 'pct', valor: 0.15 },
      { stat: 'perfuracao', tipo: 'flat', valor: 1 },
    ],
    requer: { nucleos: 10, ascensoes: 8, onda: 150 },
    lore: 'O mecanismo emperrou há trezentos ciclos. A torre aprendeu a compensar mirando melhor.',
    loreEn: 'The mechanism seized three hundred cycles ago. The tower learned to compensate by aiming better.',
  },

  {
    id: 'metralha',
    nome: 'Metralha', nomeEn: 'Grapeshot',
    icone: '🎇', cor: '#fbbf24', dificuldade: 1,
    desc: '6× de cadência e 10% do dano. A soma é pior, o barulho é melhor. Efeitos por acerto agradecem.',
    descEn: '6× fire rate at 10% damage. The math is worse, the noise is better. On-hit effects say thanks.',
    mods: { cadencia: 6, danoTorre: 0.1, ondaMax: 40 },
    objetivo: { onda: 40 },
    recompensa: [
      { stat: 'cadencia', tipo: 'pct', valor: 0.15 },
      { stat: 'velProjetil', tipo: 'pct', valor: 0.25 },
    ],
    requer: { nucleos: 10, ascensoes: 8, onda: 150 },
    lore: 'Alguém removeu o limitador de disparo e escreveu "provisório" com fita adesiva. Isso foi há doze eras.',
    loreEn: 'Someone removed the rate limiter and taped a note reading "temporary" over the hole. Twelve eras ago.',
  },

  /* ============================================= DIFICULDADE 2 — hábito */
  {
    id: 'enxame',
    nome: 'Maré de Quitina', nomeEn: 'Chitin Tide',
    icone: '🦗', cor: '#a3e635', dificuldade: 2,
    desc: '5× mais inimigos, cada um com 1/5 da vida e 30% do ouro. Dano em área deixa de ser luxo e vira requisito.',
    descEn: '5× more enemies, each at 1/5 health and 30% gold. Splash damage stops being a luxury and becomes rent.',
    mods: { densidade: 5, hpInimigo: 0.2, ouro: 0.3, ondaMax: 50 },
    objetivo: { onda: 50 },
    recompensa: [
      { stat: 'area', tipo: 'flat', valor: 18 },
      { especial: 'comboTeto', valor: 60 },
    ],
    requer: { nucleos: 12, ascensoes: 10, onda: 170 },
    lore: 'O Enxame não descobriu uma tática nova. Só parou de segurar a fila.',
    loreEn: 'The Swarm did not invent a new tactic. It simply stopped holding the queue.',
  },

  {
    id: 'pobreza',
    nome: 'Voto de Pobreza', nomeEn: 'Vow of Poverty',
    icone: '🥣', cor: '#94a3b8', dificuldade: 2,
    desc: 'Os inimigos não soltam nem uma moeda. Em troca, 2,5× de XP: você sobe de nível e joga com talentos, não com a loja.',
    descEn: 'Enemies drop not a single coin. In exchange, 2.5× XP: you win with talents, not with the shop.',
    mods: { ouro: 0, xp: 2.5, ondaMax: 45 },
    objetivo: { onda: 45 },
    recompensa: [
      { stat: 'ganhoOuro', tipo: 'mult', valor: 1.35 },
      { stat: 'jurosOuro', tipo: 'flat', valor: 0.015 },
    ],
    requer: { nucleos: 14, ascensoes: 12, onda: 180 },
    lore: 'Eles continuam morrendo. Só pararam de pagar por isso — o que, convenhamos, é o comportamento mais racional que já tiveram.',
    loreEn: 'They keep dying. They just stopped paying for it, which is the most rational thing they have ever done.',
  },

  {
    id: 'apneia',
    nome: 'Apneia', nomeEn: 'Apnea',
    icone: '💔', cor: '#ef4444', dificuldade: 2,
    desc: 'Regeneração zerada e inimigos 45% mais rápidos. Cada ponto de vida perdido é perdido de verdade. Escudo ainda recarrega.',
    descEn: 'No regeneration, and enemies move 45% faster. Every point of health lost stays lost. Shields still recharge.',
    mods: { semRegen: true, velocidadeInimigo: 1.45, ouro: 1.25, ondaMax: 55 },
    objetivo: { onda: 55 },
    recompensa: [
      { stat: 'regen', tipo: 'mult', valor: 1.6 },
      { stat: 'escudoMax', tipo: 'flat', valor: 120 },
    ],
    requer: { nucleos: 16, ascensoes: 12, onda: 200 },
    lore: 'A torre não cicatriza aqui. Ela apenas contabiliza.',
    loreEn: 'The tower does not heal here. It merely keeps accounts.',
  },

  /* ============================================ DIFICULDADE 3 — aposta */
  {
    id: 'vidro',
    nome: 'Vidro Temperado', nomeEn: 'Tempered Glass',
    icone: '🪟', cor: '#67e8f9', dificuldade: 3,
    desc: 'Vida máxima travada em 1. Dano ×20. Um único inimigo encostando encerra a run — e existem trinta e nove por onda.',
    descEn: 'Max health locked at 1. Damage ×20. One enemy touching you ends the run, and there are thirty-nine per wave.',
    mods: { vidaFixa: 1, danoTorre: 20, semRegen: true, ondaMax: 60 },
    objetivo: { onda: 60 },
    recompensa: [
      { stat: 'critDano', tipo: 'flat', valor: 0.6 },
      { stat: 'multiplicador', tipo: 'mult', valor: 1.2 },
    ],
    requer: { nucleos: 20, ascensoes: 15, onda: 220 },
    lore: 'O manual de segurança desta configuração tem uma linha: "não seja tocado". O resto das páginas está em branco.',
    loreEn: 'The safety manual for this loadout has one line: "do not get touched." The rest of the pages are blank.',
  },

  {
    id: 'silencio',
    nome: 'Protocolo Silêncio', nomeEn: 'Silence Protocol',
    icone: '🤫', cor: '#64748b', dificuldade: 3,
    desc: 'Nenhuma habilidade ativa e inimigos com 60% mais vida. Sem botões para apertar: ou a build se sustenta sozinha, ou não se sustenta.',
    descEn: 'No active abilities, and enemies carry 60% more health. No buttons to press: the build holds on its own or not at all.',
    mods: { semHabilidades: true, hpInimigo: 1.6, ondaMax: 70 },
    objetivo: { onda: 70 },
    recompensa: [
      { stat: 'cdr', tipo: 'flat', valor: 0.1 },
      { stat: 'duracaoHab', tipo: 'mult', valor: 1.25 },
    ],
    requer: { nucleos: 22, ascensoes: 16, onda: 240 },
    lore: 'O Silêncio não veio em pessoa desta vez. Mandou o procedimento por escrito, o que é pior.',
    loreEn: 'The Silence did not attend in person. It sent the procedure in writing, which is worse.',
  },

  {
    id: 'azar',
    nome: 'Lei dos Grandes Números', nomeEn: 'Law of Large Numbers',
    icone: '🎲', cor: '#a78bfa', dificuldade: 3,
    desc: 'Chance crítica zerada e inimigos com 2,2× de vida. Nada de picos de sorte: só dano médio, repetido até o fim.',
    descEn: 'Crit chance zeroed, enemy health at 2.2×. No lucky spikes — just average damage, repeated to the end.',
    mods: { semCritico: true, hpInimigo: 2.2, ouro: 1.3, ondaMax: 75 },
    objetivo: { onda: 75 },
    recompensa: [
      { stat: 'critChance', tipo: 'flat', valor: 0.05 },
      { stat: 'critDano', tipo: 'flat', valor: 0.4 },
    ],
    requer: { nucleos: 25, ascensoes: 18, onda: 260 },
    lore: 'Retiraram o acaso da equação para ver o que sobrava. Sobrou aritmética, e a aritmética não gosta de você.',
    loreEn: 'They removed chance from the equation to see what was left. Arithmetic was left, and arithmetic dislikes you.',
  },

  {
    id: 'orbita',
    nome: 'Órbita Vazia', nomeEn: 'Empty Orbit',
    icone: '🌑', cor: '#8b5cf6', dificuldade: 3,
    desc: 'Todos os orbes desligados — cartas e habilidades inclusas — e inimigos 50% mais rápidos com 30% mais vida.',
    descEn: 'Every orb offline, cards and abilities included, with enemies 50% faster and 30% tougher.',
    mods: { semOrbes: true, velocidadeInimigo: 1.5, hpInimigo: 1.3, ondaMax: 70 },
    objetivo: { onda: 70 },
    recompensa: [
      { stat: 'orbes', tipo: 'flat', valor: 1 },
      { stat: 'danoOrbe', tipo: 'mult', valor: 1.4 },
    ],
    requer: { nucleos: 25, ascensoes: 18, onda: 260 },
    lore: 'As sentinelas foram recolhidas para manutenção. Ninguém disse quando voltam, e o Enxame leu o comunicado.',
    loreEn: 'The sentinels were pulled for maintenance. Nobody said when they return, and the Swarm read the memo.',
  },

  /* =========================================== DIFICULDADE 4 — provação */
  {
    id: 'doutrina',
    nome: 'Doutrina do Zero', nomeEn: 'Zero Doctrine',
    icone: '🧾', cor: '#22d3ee', dificuldade: 4,
    desc: 'A loja de upgrades fica fechada a run inteira. O ouro continua caindo, sem nada para comprar. 3× de XP para compensar.',
    descEn: 'The upgrade shop stays shut for the whole run. Gold keeps dropping with nothing to buy. 3× XP as consolation.',
    mods: { semUpgrades: true, xp: 3, ouro: 0.8, ondaMax: 60 },
    objetivo: { onda: 60 },
    recompensa: [
      { especial: 'pontosTalento', valor: 6 },
      { stat: 'ganhoXP', tipo: 'mult', valor: 1.3 },
    ],
    requer: { nucleos: 30, ascensoes: 22, onda: 300 },
    lore: 'A pilha de moedas cresce ao pé da torre a run inteira, intocada. É o único monumento que o Enxame respeita.',
    loreEn: 'The coin pile grows untouched at the tower\'s foot all run. It is the only monument the Swarm respects.',
  },

  {
    id: 'hipervelocidade',
    nome: 'Velocidade Terminal', nomeEn: 'Terminal Velocity',
    icone: '🏎️', cor: '#f97316', dificuldade: 4,
    desc: 'Inimigos com 2,4× de velocidade e metade da vida. A janela de tiro encolhe: alcance e velocidade de projétil viram estatísticas de sobrevivência.',
    descEn: 'Enemies at 2.4× speed with half the health. Your firing window shrinks — range and projectile speed become survival stats.',
    mods: { velocidadeInimigo: 2.4, hpInimigo: 0.5, ouro: 1.4, ondaMax: 90 },
    objetivo: { onda: 90 },
    recompensa: [
      { stat: 'alcance', tipo: 'pct', valor: 0.2 },
      { stat: 'velProjetil', tipo: 'mult', valor: 1.5 },
    ],
    requer: { nucleos: 34, ascensoes: 25, onda: 330 },
    lore: 'Alguém explicou ao Enxame o conceito de aceleração. O Enxame agradeceu e foi praticar.',
    loreEn: 'Someone explained acceleration to the Swarm. The Swarm said thank you and went to practice.',
  },

  {
    id: 'muralha',
    nome: 'Muralha de Carne', nomeEn: 'Wall of Meat',
    icone: '🧱', cor: '#78716c', dificuldade: 4,
    desc: 'Inimigos com 14× de vida, 45% mais lentos e 4× de ouro. Dano bruto não resolve: traga penetração, execução e paciência.',
    descEn: 'Enemies at 14× health, 45% slower, dropping 4× gold. Raw damage will not do it: bring pen, execute and patience.',
    mods: { hpInimigo: 14, velocidadeInimigo: 0.55, ouro: 4, ondaMax: 85 },
    objetivo: { onda: 85 },
    recompensa: [
      { stat: 'penetracao', tipo: 'flat', valor: 0.12 },
      { stat: 'execucao', tipo: 'flat', valor: 0.05 },
    ],
    requer: { nucleos: 38, ascensoes: 28, onda: 360 },
    lore: 'Eles pararam de tentar chegar rápido. Agora só tentam chegar — e a diferença entre as duas coisas te custa uma hora.',
    loreEn: 'They stopped trying to arrive quickly. Now they merely try to arrive, and the difference costs you an hour.',
  },

  /* ============================================ DIFICULDADE 5 — o topo */
  {
    id: 'esteira',
    nome: 'A Esteira', nomeEn: 'The Conveyor',
    icone: '⏱️', cor: '#38bdf8', dificuldade: 5,
    desc: 'A onda avança sozinha a cada 10 segundos, você tendo limpado ou não. Os atrasados ficam no mapa e se acumulam. 1,6× de ouro.',
    descEn: 'The wave advances every 10 seconds whether you cleared it or not. Stragglers stay on the map and pile up. 1.6× gold.',
    mods: { ondaAuto: 10, ouro: 1.6, xp: 1.4, ondaMax: 120 },
    objetivo: { onda: 120 },
    recompensa: [
      { especial: 'ondaInicial', valor: 15 },
      { stat: 'velocidade', tipo: 'pct', valor: 0.1 },
    ],
    requer: { nucleos: 45, ascensoes: 32, onda: 420 },
    lore: 'A linha de produção do Enxame nunca teve botão de pausa. Tinha um botão, mas era para acelerar.',
    loreEn: 'The Swarm\'s production line never had a pause button. It had one button, and it made things faster.',
  },

  {
    id: 'purgatorio',
    nome: 'Purgatório', nomeEn: 'Purgatory',
    icone: '⛓️', cor: '#f43f5e', dificuldade: 5,
    desc: 'Vida travada em 1, sem habilidades, sem críticos, sem orbes, sem regeneração. Inimigos com 2,5× de vida, seu dano ×10. Onda 150 ou nada.',
    descEn: 'Health locked at 1. No abilities, no crits, no orbs, no regen. Enemies at 2.5× health, your damage ×10. Wave 150 or nothing.',
    mods: {
      vidaFixa: 1, semHabilidades: true, semCritico: true, semOrbes: true, semRegen: true,
      hpInimigo: 2.5, danoTorre: 10, ouro: 0.6, ondaMax: 150,
    },
    objetivo: { onda: 150 },
    recompensa: [
      { especial: 'slotsCartas', valor: 1 },
      { stat: 'multiplicador', tipo: 'mult', valor: 2 },
      { stat: 'ganhoFrag', tipo: 'mult', valor: 1.25 },
    ],
    requer: { nucleos: 60, ascensoes: 40, onda: 500 },
    lore: 'Tiraram tudo da torre menos o cano e a teimosia. O Enxame veio conferir qual dos dois cede primeiro.',
    loreEn: 'They stripped the tower down to the barrel and the stubbornness. The Swarm came to see which gives out first.',
  },
];

export const DESAFIO_POR_ID = Object.fromEntries(DESAFIOS.map((d) => [d.id, d]));

/* ======================================================= UTILIDADES ======= */

/** Rótulos das cinco faixas de dificuldade (para a UI e para o codex). */
export const NIVEIS_DIFICULDADE = [
  { nivel: 1, nome: 'Incômodo',   nomeEn: 'Nuisance',  cor: '#4ade80' },
  { nivel: 2, nome: 'Sério',      nomeEn: 'Serious',   cor: '#38bdf8' },
  { nivel: 3, nome: 'Cruel',      nomeEn: 'Cruel',     cor: '#c084fc' },
  { nivel: 4, nome: 'Provação',   nomeEn: 'Ordeal',    cor: '#fbbf24' },
  { nivel: 5, nome: 'Impiedoso',  nomeEn: 'Merciless', cor: '#f43f5e' },
];

/** `mods` completo do desafio: o padrão neutro com as trocas por cima. */
export function modsDoDesafio(def) {
  return { ...MODS_PADRAO, ...(def && def.mods ? def.mods : null) };
}

/** O desafio já está liberado neste save? */
export function desafioDisponivel(def, state) {
  const r = def.requer;
  if (!r) return true;
  if (r.nucleos && Number(state.prestigio?.nucleosTotal ?? state.prestigio?.nucleos ?? 0) < r.nucleos) return false;
  if (r.ascensoes && (state.prestigio?.ascensoes || 0) < r.ascensoes) return false;
  if (r.onda && (state.ondaMaximaGlobal || 0) < r.onda) return false;
  return true;
}

/** Todas as recompensas já conquistadas, achatadas em uma lista de efeitos. */
export function bonusDeDesafios(completos) {
  const out = [];
  if (!completos) return out;
  for (const d of DESAFIOS) {
    if (completos[d.id]) out.push(...d.recompensa);
  }
  return out;
}
