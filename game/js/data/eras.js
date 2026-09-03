/**
 * eras.js — as dez paisagens que a torre atravessa sem sair do lugar.
 *
 * A torre nunca anda. O mundo é que apodrece ao redor dela: a cada faixa de
 * ondas o céu troca de matéria, o chão troca de geometria e a trilha troca de
 * escala. Nada aqui é imagem — TUDO é desenhado por procedimento no canvas 2D,
 * então cada era é literalmente um punhado de números que o renderizador lê.
 *
 * ------------------------------------------------------------------ FORMATO
 * {
 *   id, nome, nomeEn, ondaInicio,
 *   descricao, descricaoEn,      // duas frases: o que é, e a piada seca
 *
 *   paleta: {
 *     fundo,    // cor do gradiente de fundo (topo)   — SEMPRE escura
 *     fundo2,   // cor do gradiente de fundo (base)
 *     nevoa,    // névoa/atmosfera desenhada sobre o fundo
 *     grade,    // linhas do piso e da moldura da arena
 *     acento,   // cor-tema: torre, projéteis, UI viva
 *     acento2,  // cor secundária: brilhos, partículas, orbes
 *     inimigo,  // tinta base do bestiário nesta era (contraste ALTO com fundo)
 *     perigo,   // avisos, dano, telegrafia de chefe
 *     texto,    // números flutuantes e HUD sobre a arena
 *   },
 *
 *   ceu: { tipo, densidade, velocidade, cor }
 *     tipo ∈ estrelas | nuvens | chuva | cinzas | aurora | vazio | fogo | neve | codigo | nada
 *     densidade  0..1  → quantidade de partículas por 100k px² de tela
 *     velocidade      → px/s de deriva vertical (negativo sobe)
 *
 *   chao: { tipo, escala, opacidade }
 *     tipo ∈ grade | hexagonos | ondas | cristais | circuito | organico | ruinas | nada
 *     escala     → lado da célula em px
 *     opacidade  0..1
 *
 *   ambiente: { vinheta, brilho, saturacao, tremorFundo }
 *     vinheta      0..1  → escurecimento das bordas
 *     brilho       0..1  → intensidade do bloom aditivo
 *     saturacao    0..2  → multiplicador de croma do pós-processo
 *     tremorFundo  0..1  → amplitude do tremor ambiente, em px
 *
 *   musica: { escala, bpm, timbre, camadas }
 *     escala  → graus da escala em semitons a partir da tônica
 *     timbre ∈ senoide | quadrada | dente | triangulo
 *     camadas → quantas vozes o gerador empilha (1 = só baixo)
 *
 *   regra?: { texto, textoEn, mod }
 *     `mod` é MULTIPLICATIVO sobre os "especiais" (ver sim/modifiers.js):
 *     hpInimigo, comboTeto, comboBonus, velocidadeMax, ganhoNucleos,
 *     offlineHoras, offlineEficiencia. Chave desconhecida é ignorada em
 *     silêncio, então mantenha o texto honesto com os números.
 * }
 *
 * Regra de arte: fundo sempre escuro, `inimigo` sempre em complemento de
 * `fundo`. Se você não enxerga o Grunhido a três metros do monitor, a paleta
 * está errada — não os seus olhos.
 */

export const ERAS = [
  /* ============================================================ 01 ===== */
  {
    id: 'sucata',
    nome: 'Cinturão de Sucata',
    nomeEn: 'The Scrap Belt',
    ondaInicio: 1,
    descricao: 'Onde a civilização terminou de enferrujar sem avisar ninguém. A torre foi erguida sobre um estacionamento; a placa de "vaga reservada" ainda está lá.',
    descricaoEn: 'Where civilization finished rusting without telling anyone. The tower was raised on a parking lot; the "reserved space" sign is still bolted down.',
    paleta: {
      fundo: '#151013', fundo2: '#241a15', nevoa: '#3a2a1e', grade: '#4a3527',
      acento: '#e8873a', acento2: '#f2c14e', inimigo: '#9fb4c7',
      perigo: '#ff5c47', texto: '#f2e6d8',
    },
    ceu: { tipo: 'nuvens', densidade: 0.35, velocidade: 6, cor: '#5c4231' },
    chao: { tipo: 'ruinas', escala: 96, opacidade: 0.22 },
    ambiente: { vinheta: 0.34, brilho: 0.18, saturacao: 0.82, tremorFundo: 0.0 },
    musica: { escala: [0, 3, 5, 7, 10], bpm: 76, timbre: 'quadrada', camadas: 2 },
  },

  /* ============================================================ 02 ===== */
  {
    id: 'pantano',
    nome: 'Pântano Catalítico',
    nomeEn: 'Catalytic Marsh',
    ondaInicio: 12,
    descricao: 'Um lago de refrigerante industrial que aprendeu a digerir. A chuva daqui abre buracos na armadura do inimigo — e economiza munição sua.',
    descricaoEn: 'A lake of industrial coolant that learned to digest. The rain here eats holes in enemy plating, which saves you ammunition.',
    paleta: {
      fundo: '#0a1410', fundo2: '#10231a', nevoa: '#1d3b28', grade: '#2b5638',
      acento: '#8cff5a', acento2: '#37d6a0', inimigo: '#ff6fae',
      perigo: '#d4ff3b', texto: '#dff5e4',
    },
    ceu: { tipo: 'chuva', densidade: 0.62, velocidade: 340, cor: '#7bffb0' },
    chao: { tipo: 'organico', escala: 74, opacidade: 0.3 },
    ambiente: { vinheta: 0.38, brilho: 0.3, saturacao: 1.08, tremorFundo: 0.05 },
    musica: { escala: [0, 2, 3, 7, 8], bpm: 84, timbre: 'dente', camadas: 2 },
    regra: {
      texto: 'Chuva Ácida: o pântano faz parte do trabalho. Inimigos chegam com 8% menos vida e cada ponto de combo rende 15% mais.',
      textoEn: 'Acid Rain: the marsh does part of the job. Enemies arrive with 8% less HP and each combo point pays 15% more.',
      mod: { hpInimigo: 0.92, comboBonus: 1.15 },
    },
  },

  /* ============================================================ 03 ===== */
  {
    id: 'vidro',
    nome: 'Estepe Vitrificada',
    nomeEn: 'Glass Steppe',
    ondaInicio: 28,
    descricao: 'Uma arma antiga transformou trezentos quilômetros de deserto em vidro liso. Nada agarra o chão aqui, e o que corre não sabe mais parar.',
    descricaoEn: 'An old weapon turned three hundred kilometres of desert into smooth glass. Nothing grips the ground here, and whatever runs no longer knows how to stop.',
    paleta: {
      fundo: '#120e18', fundo2: '#1f1726', nevoa: '#3a2b45', grade: '#5a3f5e',
      acento: '#ffb84d', acento2: '#7fd8ff', inimigo: '#ff7a5c',
      perigo: '#ff3d6e', texto: '#f6e9d2',
    },
    ceu: { tipo: 'cinzas', densidade: 0.44, velocidade: 22, cor: '#c9a06a' },
    chao: { tipo: 'hexagonos', escala: 112, opacidade: 0.26 },
    ambiente: { vinheta: 0.32, brilho: 0.42, saturacao: 0.95, tremorFundo: 0.02 },
    musica: { escala: [0, 2, 4, 7, 9], bpm: 92, timbre: 'triangulo', camadas: 3 },
    regra: {
      texto: 'Piso Espelhado: nada aqui desacelera. O teto de combo sobe 30%.',
      textoEn: 'Mirror Floor: nothing slows down here. Combo ceiling rises 30%.',
      mod: { comboTeto: 1.3 },
    },
  },

  /* ============================================================ 04 ===== */
  {
    id: 'inverno',
    nome: 'Inverno Sob Encomenda',
    nomeEn: 'Winter On Demand',
    ondaInicio: 48,
    descricao: 'Um terraformador foi ligado para baixar dois graus e nunca recebeu ordem de parar. O gelo engrossa a carapaça do Enxame, mas conserva bem o que você deixa rendendo.',
    descricaoEn: 'A terraformer was switched on to drop two degrees and never got the order to stop. The ice thickens the Swarm\'s shell, but it preserves whatever you leave running.',
    paleta: {
      fundo: '#070d16', fundo2: '#0e1a2b', nevoa: '#1b3149', grade: '#2c4a68',
      acento: '#7fe3ff', acento2: '#c9f2ff', inimigo: '#ff8a4c',
      perigo: '#ff4d6d', texto: '#e6f4ff',
    },
    ceu: { tipo: 'neve', densidade: 0.7, velocidade: 46, cor: '#dff2ff' },
    chao: { tipo: 'ondas', escala: 128, opacidade: 0.2 },
    ambiente: { vinheta: 0.4, brilho: 0.26, saturacao: 0.88, tremorFundo: 0.0 },
    musica: { escala: [0, 2, 3, 5, 7, 10], bpm: 68, timbre: 'senoide', camadas: 3 },
    regra: {
      texto: 'Conservação: +12% de vida inimiga, mas o frio guarda o seu progresso — +25% de eficiência offline.',
      textoEn: 'Preservation: +12% enemy HP, but the cold keeps your progress — +25% offline efficiency.',
      mod: { hpInimigo: 1.12, offlineEficiencia: 1.25 },
    },
  },

  /* ============================================================ 05 ===== */
  {
    id: 'fundicao',
    nome: 'Fundição Perpétua',
    nomeEn: 'Perpetual Foundry',
    ondaInicio: 75,
    descricao: 'A fábrica que fabrica o Enxame, funcionando há séculos sem supervisor. O turno nunca vira, então ninguém aqui sabe o que é "devagar".',
    descricaoEn: 'The factory that manufactures the Swarm, running for centuries with no supervisor. The shift never ends, so nothing here knows the word "slow".',
    paleta: {
      fundo: '#140806', fundo2: '#26100a', nevoa: '#43170e', grade: '#6b2411',
      acento: '#ff7a18', acento2: '#ffd447', inimigo: '#5ad2ff',
      perigo: '#ff2d2d', texto: '#ffe9d6',
    },
    ceu: { tipo: 'fogo', densidade: 0.55, velocidade: -70, cor: '#ff9d3c' },
    chao: { tipo: 'grade', escala: 64, opacidade: 0.34 },
    ambiente: { vinheta: 0.46, brilho: 0.62, saturacao: 1.18, tremorFundo: 0.18 },
    musica: { escala: [0, 1, 4, 5, 7, 8, 11], bpm: 128, timbre: 'quadrada', camadas: 4 },
    regra: {
      texto: 'Linha de Montagem: +18% de vida inimiga, e a esteira aceita adiantamento — +50% no teto de turbo.',
      textoEn: 'Assembly Line: +18% enemy HP, and the belt accepts overtime — +50% turbo cap.',
      mod: { hpInimigo: 1.18, velocidadeMax: 1.5 },
    },
  },

  /* ============================================================ 06 ===== */
  {
    id: 'necropole',
    nome: 'Necrópole Orbital',
    nomeEn: 'Orbital Necropolis',
    ondaInicio: 110,
    descricao: 'O chão acabou. A torre flutua num cemitério de satélites que ainda transmitem para uma frota que não existe mais. O vácuo é silencioso, o que só piora.',
    descricaoEn: 'The ground ran out. The tower floats in a graveyard of satellites still broadcasting to a fleet that no longer exists. The vacuum is silent, which only makes it worse.',
    paleta: {
      fundo: '#05060d', fundo2: '#0b0f1d', nevoa: '#161c33', grade: '#28304f',
      acento: '#8f7bff', acento2: '#4fd1c5', inimigo: '#ffd166',
      perigo: '#ff5470', texto: '#dfe3f5',
    },
    ceu: { tipo: 'estrelas', densidade: 0.8, velocidade: 3, cor: '#cfd6ff' },
    chao: { tipo: 'ruinas', escala: 160, opacidade: 0.16 },
    ambiente: { vinheta: 0.5, brilho: 0.34, saturacao: 0.9, tremorFundo: 0.0 },
    musica: { escala: [0, 3, 5, 6, 10], bpm: 58, timbre: 'senoide', camadas: 3 },
    regra: {
      texto: 'Órbita Morta: +10% de vida inimiga, mas os destroços são densos — +15% de núcleos ao colapsar.',
      textoEn: 'Dead Orbit: +10% enemy HP, but the debris runs dense — +15% cores on collapse.',
      mod: { hpInimigo: 1.1, ganhoNucleos: 1.15 },
    },
  },

  /* ============================================================ 07 ===== */
  {
    id: 'depuracao',
    nome: 'Camada de Depuração',
    nomeEn: 'The Debug Layer',
    ondaInicio: 155,
    descricao: 'A realidade esqueceu de desligar o modo de desenvolvedor e agora imprime a própria fonte no céu. Achamos o contador de combo lá no meio e mexemos nele.',
    descricaoEn: 'Reality forgot to turn off developer mode and now prints its own source across the sky. We found the combo counter in there and edited it.',
    paleta: {
      fundo: '#040a07', fundo2: '#08150e', nevoa: '#0f2718', grade: '#17402a',
      acento: '#3dff9e', acento2: '#00e5ff', inimigo: '#ff4fd8',
      perigo: '#ff2f4a', texto: '#c9ffdf',
    },
    ceu: { tipo: 'codigo', densidade: 0.75, velocidade: 190, cor: '#3dff9e' },
    chao: { tipo: 'circuito', escala: 88, opacidade: 0.3 },
    ambiente: { vinheta: 0.3, brilho: 0.5, saturacao: 1.25, tremorFundo: 0.08 },
    musica: { escala: [0, 2, 4, 6, 8, 10], bpm: 140, timbre: 'quadrada', camadas: 4 },
    regra: {
      texto: 'Variável Exposta: +50% no teto de combo e +25% no bônus por ponto. Ninguém vai auditar isso.',
      textoEn: 'Exposed Variable: +50% combo ceiling and +25% bonus per point. Nobody is auditing this.',
      mod: { comboTeto: 1.5, comboBonus: 1.25 },
    },
  },

  /* ============================================================ 08 ===== */
  {
    id: 'aurora',
    nome: 'Aurora Terminal',
    nomeEn: 'Terminal Aurora',
    ondaInicio: 210,
    descricao: 'A entropia virou espetáculo: faixas de luz que são o universo perdendo calor em cores caras. É lindo, e cada faixa deixa o Enxame um pouco mais difícil de matar.',
    descricaoEn: 'Entropy turned into a light show: ribbons of the universe shedding heat in expensive colours. It is beautiful, and every ribbon makes the Swarm harder to kill.',
    paleta: {
      fundo: '#080512', fundo2: '#120a26', nevoa: '#241340', grade: '#3a1f63',
      acento: '#ff5ad2', acento2: '#5affd0', inimigo: '#ffe066',
      perigo: '#ff2e63', texto: '#f0e4ff',
    },
    ceu: { tipo: 'aurora', densidade: 0.5, velocidade: 14, cor: '#8a5cff' },
    chao: { tipo: 'ondas', escala: 150, opacidade: 0.24 },
    ambiente: { vinheta: 0.42, brilho: 0.7, saturacao: 1.35, tremorFundo: 0.06 },
    musica: { escala: [0, 2, 4, 7, 11], bpm: 100, timbre: 'triangulo', camadas: 5 },
    regra: {
      texto: 'Calor Perdido: +25% de vida inimiga; em compensação, o colapso rende +20% de núcleos.',
      textoEn: 'Waste Heat: +25% enemy HP; in exchange, collapsing yields +20% cores.',
      mod: { hpInimigo: 1.25, ganhoNucleos: 1.2 },
    },
  },

  /* ============================================================ 09 ===== */
  {
    id: 'jardim',
    nome: 'Jardim de Singularidades',
    nomeEn: 'Singularity Garden',
    ondaInicio: 320,
    descricao: 'Alguém plantou buracos negros em fileiras bem espaçadas e foi embora. Eles amadureceram: a luz cai em curva e o tempo aqui rende juros.',
    descricaoEn: 'Someone planted black holes in neat rows and walked away. They ripened: light falls in an arc and time here earns interest.',
    paleta: {
      fundo: '#03030a', fundo2: '#0a0518', nevoa: '#170a2e', grade: '#2a1150',
      acento: '#b06bff', acento2: '#ff9edb', inimigo: '#7cffd4',
      perigo: '#ff3860', texto: '#e8dcff',
    },
    ceu: { tipo: 'vazio', densidade: 0.28, velocidade: -8, cor: '#6b34c9' },
    chao: { tipo: 'cristais', escala: 104, opacidade: 0.28 },
    ambiente: { vinheta: 0.58, brilho: 0.55, saturacao: 1.12, tremorFundo: 0.22 },
    musica: { escala: [0, 1, 3, 7, 8], bpm: 46, timbre: 'senoide', camadas: 5 },
    regra: {
      texto: 'Maré Gravitacional: +40% de vida inimiga, +35% de núcleos e +50% no teto de horas offline. O tempo aqui é elástico.',
      textoEn: 'Gravity Tide: +40% enemy HP, +35% cores and +50% offline hour cap. Time stretches here.',
      mod: { hpInimigo: 1.4, ganhoNucleos: 1.35, offlineHoras: 1.5 },
    },
  },

  /* ============================================================ 10 ===== */
  {
    id: 'nada',
    nome: 'Nada, Bem Cuidado',
    nomeEn: 'Well-Kept Nothing',
    ondaInicio: 500,
    descricao: 'O fim da realidade não é escuro nem vazio: é arrumado. Alguém varreu tudo o que existia, empilhou no canto e deixou a torre acesa como luz de corredor.',
    descricaoEn: 'The end of reality is neither dark nor empty: it is tidy. Someone swept up everything that existed, stacked it in the corner, and left the tower on like a hallway light.',
    paleta: {
      fundo: '#000000', fundo2: '#050507', nevoa: '#0c0c10', grade: '#161620',
      acento: '#ffffff', acento2: '#9aa0b5', inimigo: '#ff3b30',
      perigo: '#ff0033', texto: '#ffffff',
    },
    ceu: { tipo: 'nada', densidade: 0, velocidade: 0, cor: '#000000' },
    chao: { tipo: 'nada', escala: 0, opacidade: 0 },
    ambiente: { vinheta: 0.72, brilho: 0.9, saturacao: 0.55, tremorFundo: 0.3 },
    musica: { escala: [0, 5, 7], bpm: 33, timbre: 'senoide', camadas: 2 },
    regra: {
      texto: 'Última Página: +60% de vida inimiga, +60% de núcleos e o dobro de teto de combo. Não há mais o que economizar.',
      textoEn: 'Last Page: +60% enemy HP, +60% cores and double combo ceiling. There is nothing left to save for.',
      mod: { hpInimigo: 1.6, ganhoNucleos: 1.6, comboTeto: 2 },
    },
  },
];

/** Índice por id, para saves e para o codex. */
export const ERA_POR_ID = Object.fromEntries(ERAS.map((e) => [e.id, e]));

/** Ondas de virada, na ordem — usado pelo HUD ("próxima era em N ondas"). */
export const LIMIARES_ERA = ERAS.map((e) => e.ondaInicio);

/**
 * Índice da era de uma onda. Fora da faixa cai na primeira/última —
 * o mundo não tem era 11, ele só continua acabando.
 */
export const ERA_POR_ONDA = (onda) => {
  const w = Number.isFinite(onda) ? onda : 1;
  let i = 0;
  for (let k = ERAS.length - 1; k >= 0; k--) {
    if (w >= ERAS[k].ondaInicio) { i = k; break; }
  }
  return i;
};

/** A era em si. É esta função que sim/modifiers.js importa. */
export const ERA_ATUAL = (onda) => ERAS[ERA_POR_ONDA(onda)];

/** Próxima era, ou null se já estamos no fim de tudo. */
export const PROXIMA_ERA = (onda) => ERAS[ERA_POR_ONDA(onda) + 1] || null;

/** Quantas ondas faltam para a virada (Infinity na última era). */
export function ondasParaProximaEra(onda) {
  const prox = PROXIMA_ERA(onda);
  if (!prox) return Infinity;
  return Math.max(0, prox.ondaInicio - (Number.isFinite(onda) ? onda : 1));
}

/** Progresso 0..1 dentro da era atual, para o crossfade de paleta. */
export function progressoNaEra(onda) {
  const i = ERA_POR_ONDA(onda);
  const prox = ERAS[i + 1];
  if (!prox) return 1;
  const w = Number.isFinite(onda) ? onda : 1;
  const span = prox.ondaInicio - ERAS[i].ondaInicio;
  return span > 0 ? Math.min(1, Math.max(0, (w - ERAS[i].ondaInicio) / span)) : 1;
}
