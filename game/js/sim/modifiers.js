/**
 * modifiers.js — junta TODAS as fontes de bônus num StatEngine.
 *
 * Fontes: upgrades · talentos · árvores de prestígio · relíquias · cartas
 *         (+ conjuntos) · buffs temporários · conquistas · era · desafio.
 *
 * Também produz `especiais` (efeitos que não são atributos: onda inicial,
 * slots, desbloqueios) e `passivas` (regras especiais do combate).
 */
import { D } from '../core/decimal.js';
import { StatEngine } from './statengine.js';
import { UPGRADE_POR_ID } from '../data/upgrades.js';
import { TALENTO_POR_ID } from '../data/talents.js';
import { NO_POR_ID, ARVORES } from '../data/prestige.js';
import { RARIDADE_POR_ID, COMBATE, OFFLINE } from '../data/balance.js';

/* Módulos de conteúdo são opcionais no boot (carregados dinamicamente) */
let CARTA_POR_ID = {}, CONJUNTOS = [], valorCarta = null;
let RELIQUIA_POR_ID = {};
let CONQUISTA_POR_ID = {};
let ERA_ATUAL = null;

export async function carregarConteudo() {
  const tent = async (caminho, fn) => { try { fn(await import(caminho)); } catch (e) { console.warn('[dados] opcional ausente:', caminho, e.message); } };
  await Promise.all([
    tent('../data/cards.js', (m) => { CARTA_POR_ID = m.CARTA_POR_ID || {}; CONJUNTOS = m.CONJUNTOS || []; valorCarta = m.valorCarta || null; }),
    tent('../data/relics.js', (m) => { RELIQUIA_POR_ID = m.RELIQUIA_POR_ID || {}; }),
    tent('../data/achievements.js', (m) => { CONQUISTA_POR_ID = m.CONQUISTA_POR_ID || {}; }),
    tent('../data/eras.js', (m) => { ERA_ATUAL = m.ERA_ATUAL || null; }),
  ]);
}

export const ESPECIAIS_PADRAO = () => ({
  ondaInicial: 0,
  slotsCartas: 3,
  pontosTalento: 0,
  offlineHoras: OFFLINE.HORAS_MAX_BASE,
  offlineEficiencia: OFFLINE.EFICIENCIA_BASE,
  comboTeto: COMBATE.COMBO_TETO,
  comboBonus: COMBATE.COMBO_BONUS_POR,
  velocidadeMax: 1,
  ganhoNucleos: 1,
  hpInimigo: 1,
  desbloqueios: new Set(),
});

/** Aplica uma lista de efeitos `n` vezes ao motor de atributos. */
function aplicarEfeitos(engine, efeitos, n, fonte, especiais, passivas) {
  if (!efeitos || n <= 0) return;
  for (const ef of efeitos) {
    if (ef.especial) {
      const v = ef.valor;
      switch (ef.especial) {
        case 'desbloqueio': especiais.desbloqueios.add(v); break;
        case 'hpInimigo': especiais.hpInimigo *= Math.pow(v, n); break;
        case 'ganhoNucleos': especiais.ganhoNucleos *= Math.pow(v, n); break;
        default:
          if (typeof v === 'number') especiais[ef.especial] = (especiais[ef.especial] || 0) + v * n;
      }
      continue;
    }
    if (ef.tipo === 'passiva' || (!ef.stat && ef.chave)) {
      passivas[ef.chave] = (passivas[ef.chave] || 0) + n;
      if (ef.valor !== undefined) passivas[ef.chave + ':valor'] = ef.valor;
      continue;
    }
    if (!ef.stat) continue;
    switch (ef.tipo) {
      case 'flat': engine.addFlat(ef.stat, ef.valor * n, fonte); break;
      case 'pct': engine.addPct(ef.stat, ef.valor * n, fonte); break;
      case 'mult': {
        const total = Math.pow(ef.valor, n);
        if (total > 1e300 || !isFinite(total)) engine.addMultBig(ef.stat, D.of(ef.valor).pow(n), fonte);
        else engine.addMult(ef.stat, total, fonte);
        break;
      }
    }
  }
}

/**
 * Reconstrói o StatEngine a partir do estado.
 * @returns {{stats: StatEngine, especiais: object, passivas: object}}
 */
export function recalcular(state, engine = new StatEngine()) {
  engine.reset();
  engine._bigMult = null;
  const especiais = ESPECIAIS_PADRAO();
  const passivas = Object.create(null);

  /* ---------------------------------------------------------- upgrades */
  for (const id in state.upgrades) {
    const n = state.upgrades[id];
    const def = UPGRADE_POR_ID[id];
    if (def && n > 0) aplicarEfeitos(engine, def.efeito, n, def.nome, especiais, passivas);
  }

  /* ---------------------------------------------------------- talentos */
  for (const id in state.talentos) {
    const n = state.talentos[id];
    const def = TALENTO_POR_ID[id];
    if (def && n > 0) aplicarEfeitos(engine, def.efeito, n, def.nome, especiais, passivas);
  }

  /* ------------------------------------------------ árvores de prestígio */
  const arvores = [
    [state.prestigio.arvoreFragmentos, 'fragmentos'],
    [state.prestigio.arvoreNucleos, 'nucleos'],
    [state.prestigio.arvoreEter, 'eter'],
  ];
  for (const [tabela] of arvores) {
    for (const id in tabela) {
      const n = tabela[id];
      const def = NO_POR_ID[id];
      if (def && n > 0) aplicarEfeitos(engine, def.efeito, n, def.nome, especiais, passivas);
    }
  }

  /* --------------------------------------------------------- relíquias */
  for (const id in state.relicas) {
    const n = state.relicas[id]?.nivel ?? state.relicas[id];
    const def = RELIQUIA_POR_ID[id];
    if (def && n > 0) aplicarEfeitos(engine, def.efeito, n, def.nome, especiais, passivas);
  }

  /* ------------------------------------------------------------ cartas */
  const equipadas = [];
  for (const uid of state.cartas.equipadas) {
    if (!uid) continue;
    const inst = state.cartas.inventario.find((c) => c.uid === uid);
    if (!inst) continue;
    const def = CARTA_POR_ID[inst.id];
    if (!def) continue;
    equipadas.push(def);
    const rar = RARIDADE_POR_ID[inst.raridade] || RARIDADE_POR_ID.comum;
    const escalaNivel = 1 + 0.25 * ((inst.nivel || 1) - 1);
    for (const ef of def.efeito || []) {
      if (ef.especial) { aplicarEfeitos(engine, [ef], 1, def.nome, especiais, passivas); continue; }
      const v = ef.valor * rar.mult * escalaNivel;
      if (ef.tipo === 'mult') engine.addMult(ef.stat, 1 + (v - 1), def.nome);
      else if (ef.tipo === 'pct') engine.addPct(ef.stat, v, def.nome);
      else engine.addFlat(ef.stat, v, def.nome);
    }
  }
  // bônus de conjunto (todas as cartas do conjunto equipadas)
  for (const conj of CONJUNTOS) {
    if (!conj?.cartas?.length) continue;
    const completo = conj.cartas.every((id) => equipadas.some((d) => d.id === id));
    if (completo) aplicarEfeitos(engine, conj.bonus, 1, `Conjunto ${conj.nome}`, especiais, passivas);
  }

  /* -------------------------------------------------------- conquistas */
  let pontosConquista = 0;
  for (const id in state.conquistas) {
    const def = CONQUISTA_POR_ID[id];
    if (!def) continue;
    pontosConquista += def.pontos || 5;
    const r = def.recompensa;
    if (r?.tipo === 'stat' && r.stat) {
      if (r.tipoEfeito === 'mult') engine.addMult(r.stat, r.valor, def.nome);
      else engine.addPct(r.stat, r.valor, def.nome);
    }
  }
  // bônus global por pontos de conquista: +0,5% de dano e ouro a cada 10 pontos
  if (pontosConquista > 0) {
    const b = (pontosConquista / 10) * 0.005;
    engine.addPct('multiplicador', b, 'Conquistas');
    engine.addPct('ganhoOuro', b, 'Conquistas');
  }

  /* --------------------------------------------------------------- era */
  if (ERA_ATUAL) {
    const era = ERA_ATUAL(state.onda);
    if (era?.regra?.mod) {
      for (const k in era.regra.mod) {
        const v = era.regra.mod[k];
        if (k in especiais && typeof v === 'number') especiais[k] *= v;
      }
    }
  }

  /* ------------------------------------------------------------ buffs */
  for (const b of state.buffs) {
    if (b.restante <= 0) continue;
    if (b.tipo === 'mult') engine.addMult(b.stat, b.valor, b.fonte);
    else if (b.tipo === 'pct') engine.addPct(b.stat, b.valor, b.fonte);
    else engine.addFlat(b.stat, b.valor, b.fonte);
  }

  /* --------------------------------------------------- passivas ativas */
  if (passivas.sede_de_sangue && state.combo.atual > 0) {
    const pilhas = Math.min(25, state.combo.atual);
    engine.addPct('dano', 0.02 * pilhas, 'Sede de Sangue');
  }
  if (passivas.ultima_chama) {
    const frac = state.torre.vidaMax > 0 ? state.torre.vida / state.torre.vidaMax : 1;
    if (frac < 0.3) engine.addMult('multiplicador', 2, 'Última Chama');
  }
  if (passivas.combo_estendido) especiais.comboBonus *= 1 + 0.5 * passivas.combo_estendido;
  if (passivas.midas) engine.addMult('sorte', 2, 'Toque de Midas');
  if (passivas.juros_dobrados) engine.addMult('jurosOuro', 2, 'Juros Compostos');

  /* --------------------------------------------------------- desafio */
  if (state.desafios.ativo?.mods) {
    const m = state.desafios.ativo.mods;
    if (m.cadencia && m.cadencia !== 1) engine.addMult('cadencia', m.cadencia, 'Desafio');
    if (m.semCritico) engine.addMult('critChance', 0, 'Desafio');
    if (m.semRegen) engine.addMult('regen', 0, 'Desafio');
    if (m.semOrbes) engine.addMult('orbes', 0, 'Desafio');
  }

  engine.dirty = true;
  engine.compute();

  // limites derivados
  especiais.slotsCartas = Math.min(8, especiais.slotsCartas);
  especiais.offlineHoras = Math.min(OFFLINE.HORAS_MAX_TETO, especiais.offlineHoras);
  especiais.offlineEficiencia = Math.min(1, especiais.offlineEficiencia);
  if (passivas.offlinePerfeito || especiais.desbloqueios.has('offlinePerfeito')) {
    especiais.offlineEficiencia = 1;
    especiais.offlineHoras = 9999;
  }

  return { stats: engine, especiais, passivas, pontosConquista };
}
