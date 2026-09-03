/**
 * prestige.js — as três camadas de prestígio e suas árvores permanentes.
 *
 * Camada 1 · ASCENSÃO      → moeda: fragmentos  (reseta ouro/upgrades/onda)
 * Camada 2 · SINGULARIDADE → moeda: núcleos     (reseta também fragmentos e talentos)
 * Camada 3 · TRANSCENDÊNCIA→ moeda: éter        (reseta quase tudo, muda as regras)
 */
import { D } from '../core/decimal.js';
import { PRESTIGIO } from './balance.js';

export const CAMADAS = [
  {
    id: 'ascensao', moeda: 'fragmentos', ordem: 1,
    nome: 'Ascensão', nomeEn: 'Ascension', icone: '💠', cor: '#38bdf8',
    verbo: 'Ascender', verboEn: 'Ascend',
    requisito: `Alcance a onda ${PRESTIGIO.ASC_ONDA_MIN}`,
    resetaTexto: 'Ouro, upgrades, onda atual e nível da torre.',
    mantemTexto: 'Fragmentos, relíquias, cartas, conquistas e estatísticas.',
    lore: 'A torre se desfaz em pó luminoso — e o pó lembra de tudo.',
  },
  {
    id: 'singularidade', moeda: 'nucleos', ordem: 2,
    nome: 'Singularidade', nomeEn: 'Singularity', icone: '🌌', cor: '#a855f7',
    verbo: 'Colapsar', verboEn: 'Collapse',
    requisito: `Onda ${PRESTIGIO.SING_ONDA_MIN} + ${PRESTIGIO.SING_ASC_MIN} Ascensões`,
    resetaTexto: 'Tudo da Ascensão + fragmentos e a árvore de fragmentos.',
    mantemTexto: 'Núcleos, relíquias, cartas, conquistas e codex.',
    lore: 'Você comprime mil torres num único ponto. O ponto pisca.',
  },
  {
    id: 'transcendencia', moeda: 'eter', ordem: 3,
    nome: 'Transcendência', nomeEn: 'Transcendence', icone: '✴️', cor: '#f472b6',
    verbo: 'Transcender', verboEn: 'Transcend',
    requisito: `Onda ${PRESTIGIO.TRANS_ONDA_MIN} + ${PRESTIGIO.TRANS_SING_MIN} Singularidades`,
    resetaTexto: 'Absolutamente tudo, menos éter e conquistas.',
    mantemTexto: 'Éter, conquistas, codex e o direito de rir do começo.',
    lore: 'A torre finalmente entende que ela é o Enxame olhando para si mesmo.',
  },
];

/* ============================ ÁRVORE DE FRAGMENTOS ==================== */
export const ARVORE_FRAGMENTOS = [
  { id: 'af_dano', nome: 'Memória de Guerra', nomeEn: 'War Memory', icone: '⚔️', pos: [0, 0],
    desc: '×1,4 de dano por nível — para sempre.', base: 1, cresc: 1.55, max: Infinity,
    efeito: [{ stat: 'multiplicador', tipo: 'mult', valor: 1.4 }] },
  { id: 'af_ouro', nome: 'Memória de Ouro', nomeEn: 'Gold Memory', icone: '🪙', pos: [1, 0],
    desc: '×1,35 de ouro por nível.', base: 1, cresc: 1.5, max: Infinity,
    efeito: [{ stat: 'ganhoOuro', tipo: 'mult', valor: 1.35 }] },
  { id: 'af_vida', nome: 'Memória de Pedra', nomeEn: 'Stone Memory', icone: '❤️', pos: [2, 0],
    desc: '×1,3 de vida máxima por nível.', base: 1, cresc: 1.5, max: Infinity,
    efeito: [{ stat: 'vidaMax', tipo: 'mult', valor: 1.3 }] },

  { id: 'af_inicio', nome: 'Ponto de Partida', nomeEn: 'Head Start', icone: '🚩', pos: [0, 1],
    desc: 'Começa {v} ondas à frente.', base: 3, cresc: 1.9, max: 40,
    efeito: [{ especial: 'ondaInicial', valor: 2 }] },
  { id: 'af_xp', nome: 'Sabedoria', nomeEn: 'Wisdom', icone: '📘', pos: [1, 1],
    desc: '×1,25 de XP por nível.', base: 2, cresc: 1.45, max: 40,
    efeito: [{ stat: 'ganhoXP', tipo: 'mult', valor: 1.25 }] },
  { id: 'af_crit', nome: 'Instinto Assassino', nomeEn: 'Killer Instinct', icone: '💥', pos: [2, 1],
    desc: '+2% de chance crítica e +15% de dano crítico por nível.', base: 3, cresc: 1.5, max: 25,
    efeito: [{ stat: 'critChance', tipo: 'flat', valor: 0.02 }, { stat: 'critDano', tipo: 'flat', valor: 0.15 }] },

  { id: 'af_frag', nome: 'Cristalização', nomeEn: 'Crystallization', icone: '💠', pos: [0, 2],
    desc: '×1,22 de fragmentos ganhos por nível.', base: 6, cresc: 1.75, max: 30,
    efeito: [{ stat: 'ganhoFrag', tipo: 'mult', valor: 1.22 }] },
  { id: 'af_drop', nome: 'Faro de Tesouro', nomeEn: 'Treasure Sense', icone: '🍀', pos: [1, 2],
    desc: '×1,2 de chance de drop e sorte por nível.', base: 5, cresc: 1.65, max: 25,
    efeito: [{ stat: 'chanceDrop', tipo: 'mult', valor: 1.2 }, { stat: 'sorte', tipo: 'mult', valor: 1.1 }] },
  { id: 'af_slots', nome: 'Matriz Expandida', nomeEn: 'Expanded Matrix', icone: '🃏', pos: [2, 2],
    desc: '+1 slot de carta.', base: 25, cresc: 6, max: 4,
    efeito: [{ especial: 'slotsCartas', valor: 1 }] },

  { id: 'af_offline', nome: 'Vigília', nomeEn: 'Vigil', icone: '🌙', pos: [0, 3],
    desc: '+2h de teto de progresso offline e +6% de eficiência.', base: 8, cresc: 1.6, max: 22,
    efeito: [{ especial: 'offlineHoras', valor: 2 }, { especial: 'offlineEficiencia', valor: 0.06 }] },
  { id: 'af_orbe', nome: 'Sentinela Eterna', nomeEn: 'Eternal Sentinel', icone: '🔮', pos: [1, 3],
    desc: '+1 orbe inicial por nível.', base: 30, cresc: 3.4, max: 6,
    efeito: [{ stat: 'orbes', tipo: 'flat', valor: 1 }] },
  { id: 'af_regen', nome: 'Coração de Aço', nomeEn: 'Steel Heart', icone: '💚', pos: [2, 3],
    desc: '×1,4 de regeneração e +12 de armadura por nível.', base: 6, cresc: 1.55, max: 30,
    efeito: [{ stat: 'regen', tipo: 'mult', valor: 1.4 }, { stat: 'armadura', tipo: 'flat', valor: 12 }] },

  { id: 'af_auto_compra', nome: 'Servo Automático', nomeEn: 'Auto Servitor', icone: '🤖', pos: [0, 4],
    desc: 'Desbloqueia a compra automática de upgrades.', base: 40, cresc: 1, max: 1,
    efeito: [{ especial: 'desbloqueio', valor: 'autoCompra' }] },
  { id: 'af_auto_hab', nome: 'Piloto Tático', nomeEn: 'Tactical Pilot', icone: '🎛️', pos: [1, 4],
    desc: 'Desbloqueia o uso automático de habilidades.', base: 60, cresc: 1, max: 1,
    efeito: [{ especial: 'desbloqueio', valor: 'autoHabilidade' }] },
  { id: 'af_farm', nome: 'Campo de Treino', nomeEn: 'Training Grounds', icone: '🎯', pos: [2, 4],
    desc: 'Permite travar a onda para farmar (modo Farm).', base: 35, cresc: 1, max: 1,
    efeito: [{ especial: 'desbloqueio', valor: 'modoFarm' }] },

  { id: 'af_velocidade', nome: 'Aceleração', nomeEn: 'Acceleration', icone: '⏩', pos: [0, 5],
    desc: '+8% de velocidade do jogo por nível.', base: 80, cresc: 2.1, max: 10,
    efeito: [{ stat: 'velocidade', tipo: 'pct', valor: 0.08 }] },
  { id: 'af_combo', nome: 'Metrônomo', nomeEn: 'Metronome', icone: '🎵', pos: [1, 5],
    desc: '+40 de teto de combo e +20% de bônus de combo por nível.', base: 45, cresc: 1.8, max: 10,
    efeito: [{ especial: 'comboTeto', valor: 40 }, { especial: 'comboBonus', valor: 0.2 }] },
  { id: 'af_talento', nome: 'Iluminação', nomeEn: 'Enlightenment', icone: '🧠', pos: [2, 5],
    desc: '+3 pontos de talento iniciais por nível.', base: 55, cresc: 2.0, max: 15,
    efeito: [{ especial: 'pontosTalento', valor: 3 }] },
];

/* ============================= ÁRVORE DE NÚCLEOS ====================== */
export const ARVORE_NUCLEOS = [
  { id: 'an_dano', nome: 'Colapso Ofensivo', nomeEn: 'Offensive Collapse', icone: '🌋', pos: [0, 0],
    desc: '×3 de dano por nível.', base: 1, cresc: 2.2, max: Infinity,
    efeito: [{ stat: 'multiplicador', tipo: 'mult', valor: 3 }] },
  { id: 'an_ouro', nome: 'Colapso Econômico', nomeEn: 'Economic Collapse', icone: '💎', pos: [1, 0],
    desc: '×2,6 de ouro por nível.', base: 1, cresc: 2.1, max: Infinity,
    efeito: [{ stat: 'ganhoOuro', tipo: 'mult', valor: 2.6 }] },
  { id: 'an_frag', nome: 'Fonte de Estilhaços', nomeEn: 'Shard Fountain', icone: '💠', pos: [2, 0],
    desc: '×2,2 de fragmentos por nível.', base: 2, cresc: 2.4, max: 25,
    efeito: [{ stat: 'ganhoFrag', tipo: 'mult', valor: 2.2 }] },

  { id: 'an_onda', nome: 'Salto Quântico', nomeEn: 'Quantum Leap', icone: '🚀', pos: [0, 1],
    desc: 'Começa +10 ondas à frente por nível.', base: 3, cresc: 2.0, max: 25,
    efeito: [{ especial: 'ondaInicial', valor: 10 }] },
  { id: 'an_turbo', nome: 'Motor Singular', nomeEn: 'Singular Engine', icone: '⏩', pos: [1, 1],
    desc: '+1 no limite de velocidade do jogo.', base: 5, cresc: 3.0, max: 5,
    efeito: [{ especial: 'velocidadeMax', valor: 1 }] },
  { id: 'an_auto_asc', nome: 'Ciclo Eterno', nomeEn: 'Eternal Cycle', icone: '♻️', pos: [2, 1],
    desc: 'Desbloqueia a Ascensão automática.', base: 8, cresc: 1, max: 1,
    efeito: [{ especial: 'desbloqueio', valor: 'autoAscensao' }] },

  { id: 'an_lendario', nome: 'Sorte Cósmica', nomeEn: 'Cosmic Luck', icone: '🌠', pos: [0, 2],
    desc: '×1,8 de sorte e chance de raridade alta por nível.', base: 4, cresc: 2.2, max: 20,
    efeito: [{ stat: 'sorte', tipo: 'mult', valor: 1.8 }, { stat: 'chanceDrop', tipo: 'mult', valor: 1.4 }] },
  { id: 'an_slot', nome: 'Matriz Singular', nomeEn: 'Singular Matrix', icone: '🃏', pos: [1, 2],
    desc: '+1 slot de carta por nível.', base: 12, cresc: 5, max: 3,
    efeito: [{ especial: 'slotsCartas', valor: 1 }] },
  { id: 'an_talento', nome: 'Mente Coletiva', nomeEn: 'Hive Mind', icone: '🧠', pos: [2, 2],
    desc: '+15 pontos de talento iniciais por nível.', base: 6, cresc: 2.3, max: 20,
    efeito: [{ especial: 'pontosTalento', valor: 15 }] },

  { id: 'an_desafios', nome: 'Provações', nomeEn: 'Trials', icone: '🏆', pos: [0, 3],
    desc: 'Desbloqueia os Desafios (modificadores com recompensas permanentes).', base: 10, cresc: 1, max: 1,
    efeito: [{ especial: 'desbloqueio', valor: 'desafios' }] },
  { id: 'an_offline', nome: 'Sonho Longo', nomeEn: 'Long Dream', icone: '🌙', pos: [1, 3],
    desc: '+8h de teto offline e +10% de eficiência por nível.', base: 6, cresc: 2.0, max: 12,
    efeito: [{ especial: 'offlineHoras', valor: 8 }, { especial: 'offlineEficiencia', valor: 0.1 }] },
  { id: 'an_nucleo', nome: 'Ressonância', nomeEn: 'Resonance', icone: '🌌', pos: [2, 3],
    desc: '×1,5 de núcleos ganhos por nível.', base: 15, cresc: 3.2, max: 15,
    efeito: [{ especial: 'ganhoNucleos', valor: 1.5 }] },
];

/* ============================== ÁRVORE DE ÉTER ======================== */
export const ARVORE_ETER = [
  { id: 'ae_dano', nome: 'Verbo Primordial', nomeEn: 'Primordial Word', icone: '✴️', pos: [0, 0],
    desc: '×12 de dano por nível.', base: 1, cresc: 2.6, max: Infinity,
    efeito: [{ stat: 'multiplicador', tipo: 'mult', valor: 12 }] },
  { id: 'ae_tudo', nome: 'Abundância', nomeEn: 'Abundance', icone: '🌊', pos: [1, 0],
    desc: '×6 em ouro, XP e fragmentos por nível.', base: 1, cresc: 2.5, max: Infinity,
    efeito: [{ stat: 'ganhoOuro', tipo: 'mult', valor: 6 }, { stat: 'ganhoXP', tipo: 'mult', valor: 6 }, { stat: 'ganhoFrag', tipo: 'mult', valor: 6 }] },
  { id: 'ae_realidade', nome: 'Reescrita', nomeEn: 'Rewrite', icone: '📝', pos: [2, 0],
    desc: 'Inimigos têm −12% de vida por nível (multiplicativo).', base: 2, cresc: 3.0, max: 12,
    efeito: [{ especial: 'hpInimigo', valor: 0.88 }] },

  { id: 'ae_eternidade', nome: 'Eternidade', nomeEn: 'Eternity', icone: '♾️', pos: [0, 1],
    desc: 'Progresso offline 100% eficiente e sem teto de tempo.', base: 5, cresc: 1, max: 1,
    efeito: [{ especial: 'desbloqueio', valor: 'offlinePerfeito' }] },
  { id: 'ae_onipresenca', nome: 'Onipresença', nomeEn: 'Omnipresence', icone: '🌐', pos: [1, 1],
    desc: 'Começa +60 ondas à frente por nível.', base: 3, cresc: 2.4, max: 20,
    efeito: [{ especial: 'ondaInicial', valor: 60 }] },
  { id: 'ae_infinito', nome: 'Vazio Infinito', nomeEn: 'Infinite Void', icone: '🕳️', pos: [2, 1],
    desc: 'Desbloqueia o Modo Infinito e o Bestiário Verdadeiro.', base: 12, cresc: 1, max: 1,
    efeito: [{ especial: 'desbloqueio', valor: 'modoInfinito' }] },
];

export const ARVORES = {
  fragmentos: ARVORE_FRAGMENTOS,
  nucleos: ARVORE_NUCLEOS,
  eter: ARVORE_ETER,
};
export const NO_POR_ID = Object.fromEntries(
  [...ARVORE_FRAGMENTOS, ...ARVORE_NUCLEOS, ...ARVORE_ETER].map((n) => [n.id, n])
);

export function custoNo(def, nivel) {
  return D.of(def.base).mul(D.of(def.cresc).pow(nivel));
}
export function maxCompravelNo(def, nivel, moeda) {
  const teto = def.max === Infinity ? 1e6 : def.max - nivel;
  if (teto <= 0) return 0;
  if (def.cresc === 1) return Math.min(teto, Math.floor(moeda.div(def.base).toNumber()) || 0);
  return Math.min(teto, D.maxAffordableGeometric(moeda, def.base, def.cresc, nivel));
}

/** Estado de disponibilidade das camadas. */
export function podeAscender(s) { return s.ondaMaxima >= PRESTIGIO.ASC_ONDA_MIN; }
export function podeColapsar(s) {
  return s.ondaMaximaGlobal >= PRESTIGIO.SING_ONDA_MIN && s.prestigio.ascensoes >= PRESTIGIO.SING_ASC_MIN;
}
export function podeTranscender(s) {
  return s.ondaMaximaGlobal >= PRESTIGIO.TRANS_ONDA_MIN && s.prestigio.singularidades >= PRESTIGIO.TRANS_SING_MIN;
}
