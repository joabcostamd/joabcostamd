/**
 * balance.js — TODA a matemática do jogo em um lugar só.
 *
 * Nada de números mágicos espalhados pelo código: quem quiser rebalancear
 * mexe aqui e roda `node game/tests/balance-sim.js` para ver o efeito.
 */
import { D } from '../core/decimal.js';

/* ======================================================== ONDAS ======== */
export const ONDA = {
  /** HP de um inimigo comum na onda w. */
  HP_BASE: 10,
  HP_CRESC: 1.152,
  /** Endurecimento polinomial: cria "paredes" que exigem prestígio. */
  HP_POLI_DIV: 55,
  HP_POLI_EXP: 2.35,

  OURO_BASE: 3.2,
  OURO_CRESC: 1.128,

  XP_BASE: 1.6,
  XP_CRESC: 1.09,

  /** Quantos inimigos derrubar para fechar a onda. */
  contagem: (w) => 8 + Math.min(22, Math.floor(w / 3)),

  /** Toda onda múltipla de 10 é chefe; a cada 50, super-chefe. */
  ehChefe: (w) => w % 10 === 0,
  ehSuperChefe: (w) => w % 50 === 0,

  /** Velocidade base dos inimigos cresce devagar (pressão sem injustiça). */
  velocidade: (w) => 26 + Math.min(26, w * 0.16),

  /** Intervalo entre spawns (s) — encurta com a onda, com piso. */
  intervaloSpawn: (w) => Math.max(0.22, 1.15 - Math.log10(w + 1) * 0.28),

  /** Chance de elite (inimigo com modificador). */
  chanceElite: (w) => (w < 8 ? 0 : Math.min(0.28, 0.02 + w * 0.0022)),

  /** Chance de inimigo dourado (jackpot visual + ouro). */
  chanceDourado: (w) => (w < 5 ? 0 : Math.min(0.035, 0.004 + w * 0.00018)),
};

export function hpDaOnda(w) {
  const poli = 1 + Math.pow(Math.max(0, w) / ONDA.HP_POLI_DIV, ONDA.HP_POLI_EXP);
  return D.of(ONDA.HP_BASE).mul(D.of(ONDA.HP_CRESC).pow(w - 1)).mulN(poli);
}
export function ouroDaOnda(w) {
  return D.of(ONDA.OURO_BASE).mul(D.of(ONDA.OURO_CRESC).pow(w - 1));
}
export function xpDaOnda(w) {
  return D.of(ONDA.XP_BASE).mul(D.of(ONDA.XP_CRESC).pow(w - 1));
}

/** Multiplicadores por arquétipo de inimigo. */
export const MULT_CHEFE = { hp: 16, ouro: 22, xp: 18, escala: 2.1, vel: 0.62 };
export const MULT_SUPER_CHEFE = { hp: 70, ouro: 90, xp: 70, escala: 2.9, vel: 0.5 };
export const MULT_ELITE = { hp: 3.4, ouro: 4.2, xp: 3.5, escala: 1.35 };
export const MULT_DOURADO = { hp: 0.9, ouro: 35, xp: 6, escala: 1.15, vel: 1.9 };

/* ==================================================== PROGRESSÃO ======= */
export const NIVEL = {
  /** XP necessário para ir do nível n para n+1. */
  custo: (n) => D.of(12).mul(D.of(1.28).pow(n - 1)).mulN(1 + Math.pow(n / 30, 1.6)),
  pontosPorNivel: (n) => 1 + (n % 5 === 0 ? 1 : 0) + (n % 25 === 0 ? 3 : 0),
  MAX: 500,
};

/* ====================================================== COMBATE ======== */
export const COMBATE = {
  /** Torre base. */
  DANO_BASE: 4,
  CADENCIA_BASE: 1.6,          // tiros/s
  ALCANCE_BASE: 210,           // px
  CRIT_BASE: 0.05,
  CRIT_MULT_BASE: 2.0,
  VEL_PROJETIL: 460,
  VIDA_BASE: 100,
  REGEN_BASE: 0.5,             // hp/s

  /** Redução por armadura: r = a / (a + K). */
  ARMADURA_K: 60,

  /** Combo: cada abate soma; expira em COMBO_JANELA s sem abates. */
  COMBO_JANELA: 2.6,
  COMBO_BONUS_POR: 0.006,      // +0,6% ouro por ponto de combo
  COMBO_TETO: 250,

  /** Overkill vira ouro extra (até 50%). */
  OVERKILL_TETO: 0.5,

  /** Dano do inimigo ao alcançar a torre (fração da vida máxima). */
  DANO_CONTATO_FRAC: 0.055,
  DANO_CONTATO_CHEFE: 0.22,

  /** Invulnerabilidade após levar dano (s). */
  IFRAMES: 0.35,

  /** Tempo parado após a torre cair (s) antes de reiniciar a onda. */
  RESPAWN: 3.0,
  /** Ao morrer, volta X ondas (piso na onda 1). */
  PENALIDADE_MORTE: 1,
};

/** Status elementais: duração, empilhamento e efeito. */
export const ELEMENTOS = {
  fogo:   { cor: '#ff6b35', dot: 0.35, duracao: 3, pilhas: 5, nome: 'Queimadura', nomeEn: 'Burn' },
  gelo:   { cor: '#6bd6ff', lentidao: 0.30, duracao: 2.5, pilhas: 3, nome: 'Congelamento', nomeEn: 'Chill' },
  raio:   { cor: '#ffe45e', corrente: 3, fator: 0.45, nome: 'Corrente', nomeEn: 'Chain' },
  veneno: { cor: '#8cff6b', dot: 0.22, duracao: 6, pilhas: 12, nome: 'Veneno', nomeEn: 'Poison' },
  vazio:  { cor: '#b06bff', ampliacao: 0.18, duracao: 4, pilhas: 4, nome: 'Fissura', nomeEn: 'Rift' },
};

/* ===================================================== PRESTÍGIO ======= */
export const PRESTIGIO = {
  /* --- Camada 1: Ascensão (fragmentos) --- */
  ASC_ONDA_MIN: 25,
  ASC_EXP: 0.055,
  /** fragmentos ganhos ao ascender com pico `w`. */
  fragmentos(w, bonus = 1) {
    if (w < PRESTIGIO.ASC_ONDA_MIN) return D.of(0);
    return D.pow10((w - PRESTIGIO.ASC_ONDA_MIN + 1) * PRESTIGIO.ASC_EXP).mulN(bonus).floor();
  },

  /* --- Camada 2: Singularidade (núcleos) --- */
  SING_ONDA_MIN: 150,
  SING_ASC_MIN: 8,
  SING_EXP: 0.021,
  nucleos(wGlobal, ascensoes, bonus = 1) {
    if (wGlobal < PRESTIGIO.SING_ONDA_MIN) return D.of(0);
    const base = D.pow10((wGlobal - PRESTIGIO.SING_ONDA_MIN + 1) * PRESTIGIO.SING_EXP);
    return base.mulN(1 + Math.log10(1 + ascensoes) * 0.6).mulN(bonus).floor();
  },

  /* --- Camada 3: Transcendência (éter) --- */
  TRANS_ONDA_MIN: 500,
  TRANS_SING_MIN: 5,
  TRANS_EXP: 0.008,
  eter(wGlobal, singularidades, bonus = 1) {
    if (wGlobal < PRESTIGIO.TRANS_ONDA_MIN) return D.of(0);
    return D.pow10((wGlobal - PRESTIGIO.TRANS_ONDA_MIN + 1) * PRESTIGIO.TRANS_EXP)
      .mulN(1 + singularidades * 0.15).mulN(bonus).floor();
  },
};

/* ======================================================= OFFLINE ======= */
export const OFFLINE = {
  /** Eficiência do progresso offline (fração do rendimento ativo). */
  EFICIENCIA_BASE: 0.45,
  /** Teto de horas acumuladas (aumenta com relíquias). */
  HORAS_MAX_BASE: 4,
  HORAS_MAX_TETO: 48,
  /** Abaixo disso nem mostra o relatório. */
  MIN_SEGUNDOS: 30,
};

/* ========================================================== LOOT ======= */
export const RARIDADES = [
  { id: 'comum',     nome: 'Comum',     nomeEn: 'Common',    cor: '#9aa5b1', peso: 1000, mult: 1.0,  brilho: 0 },
  { id: 'incomum',   nome: 'Incomum',   nomeEn: 'Uncommon',  cor: '#4ade80', peso: 380,  mult: 1.45, brilho: 0.2 },
  { id: 'raro',      nome: 'Raro',      nomeEn: 'Rare',      cor: '#38bdf8', peso: 120,  mult: 2.1,  brilho: 0.45 },
  { id: 'epico',     nome: 'Épico',     nomeEn: 'Epic',      cor: '#c084fc', peso: 34,   mult: 3.2,  brilho: 0.7 },
  { id: 'lendario',  nome: 'Lendário',  nomeEn: 'Legendary', cor: '#fbbf24', peso: 7,    mult: 5.0,  brilho: 1.0 },
  { id: 'mitico',    nome: 'Mítico',    nomeEn: 'Mythic',    cor: '#fb7185', peso: 1,    mult: 8.0,  brilho: 1.4 },
];
export const RARIDADE_POR_ID = Object.fromEntries(RARIDADES.map((r) => [r.id, r]));

export const LOOT = {
  /** Chance base de carta por abate normal. */
  CHANCE_CARTA: 0.0075,
  CHANCE_CARTA_CHEFE: 1.0,
  CHANCE_CARTA_ELITE: 0.07,
  /** Pity: a cada falha em lendário+, soma-se este valor à chance. */
  PITY_PASSO: 0.0009,
  /** Gemas por chefe. */
  GEMAS_CHEFE: 3,
  GEMAS_SUPER: 25,
  /** Poeira ao reciclar por raridade. */
  POEIRA: { comum: 5, incomum: 14, raro: 45, epico: 160, lendario: 600, mitico: 2400 },
};

/* ================================================== AUTOMAÇÃO ========= */
export const AUTO = {
  /** Velocidade máxima do turbo por camada de prestígio. */
  VELOCIDADE_MAX: (nucleos) => Math.min(6, 1 + Math.floor(Math.log10(1 + nucleos) * 2)),
  INTERVALO_AUTOCOMPRA: 0.35,
};

/* =================================================== DIFICULDADE ====== */
/** Modificadores globais de desafio aplicados sobre inimigos/torre. */
export const DESAFIO_MODS = {
  hpInimigo: 1, velocidadeInimigo: 1, danoTorre: 1, ouro: 1, semHabilidades: false,
};

/* ================================================== TEMPOS-ALVO ======= */
/** Metas de ritmo usadas pelo simulador de balanceamento (tests/balance-sim.js). */
export const METAS = {
  primeiraAscensao: 40 * 60,      // ~40 min
  primeiraSingularidade: 6 * 3600,
  primeiraTranscendencia: 40 * 3600,
  segundosPorOndaInicio: 12,
  segundosPorOndaMeio: 35,
};
