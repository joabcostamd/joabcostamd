/**
 * arena.js — o campo de batalha: pools de inimigos, projéteis, orbes, coletáveis
 * e uma grade espacial para consultas em área.
 *
 * Nada aqui é persistido: a arena é reconstruída a cada carregamento.
 */
import { Pool } from '../core/pool.js';
import { D } from '../core/decimal.js';
import { TAU } from '../core/util.js';

export const ARENA = { w: 1280, h: 720, cx: 640, cy: 360, raio: 640 };

/** Redimensiona a arena mantendo a torre no centro. */
export function resizeArena(w, h) {
  ARENA.w = w; ARENA.h = h;
  ARENA.cx = w / 2; ARENA.cy = h / 2;
  ARENA.raio = Math.hypot(w, h) / 2;
}

/* ------------------------------------------------------------- inimigos */

function novoInimigo() {
  return {
    ativo: false, id: 0, tipo: 'grunhido', def: null,
    x: 0, y: 0, vx: 0, vy: 0, ang: 0, dirAng: 0,
    r: 12, escala: 1,
    hp: D.of(1), hpMax: D.of(1), armadura: 0,
    vel: 30, velBase: 30,
    ouro: D.of(1), xp: D.of(1),
    chefe: false, superChefe: false, elite: false, dourado: false, eliteMod: null,
    fase: 0, faseHp: 0,
    // status
    queimadura: 0, queimaduraDano: D.of(0), veneno: 0, venenoDano: D.of(0),
    gelo: 0, geloForca: 0, fissura: 0, fissuraForca: 0, atordoado: 0,
    marcado: 0,
    // escudo próprio (inimigo blindado)
    escudo: 0, escudoMax: 0,
    // comportamento
    t: 0, faseAnim: 0, cd: 0, estado: 0, alvoX: 0, alvoY: 0,
    // visual
    flash: 0, hitAcc: 0, morrendo: 0, entrada: 0,
    _celula: -1,
  };
}
function limparInimigo(e) {
  e.ativo = false; e.chefe = false; e.superChefe = false; e.elite = false; e.dourado = false;
  e.eliteMod = null; e.def = null;
  e.queimadura = 0; e.veneno = 0; e.gelo = 0; e.fissura = 0; e.atordoado = 0; e.marcado = 0;
  e.escudo = 0; e.escudoMax = 0; e.flash = 0; e.hitAcc = 0; e.morrendo = 0; e.entrada = 0;
  e.t = 0; e.cd = 0; e.estado = 0; e.fase = 0;
}

/* ------------------------------------------------------------ projéteis */

function novoProjetil() {
  return {
    ativo: false, x: 0, y: 0, vx: 0, vy: 0, ang: 0,
    dano: D.of(1), crit: false, alvo: null, vel: 400,
    r: 4, vida: 3, perfuracao: 0, ricochete: 0, area: 0,
    elemento: null, cor: '#7dd3fc', tipo: 'bala',
    trilha: [], t: 0, atingidos: null, origem: 'torre',
  };
}
function limparProjetil(p) {
  p.ativo = false; p.alvo = null; p.trilha.length = 0; p.atingidos = null;
  p.perfuracao = 0; p.ricochete = 0; p.area = 0; p.elemento = null; p.crit = false;
}

/* ----------------------------------------------------------- coletáveis */

function novoColetavel() {
  return { ativo: false, x: 0, y: 0, vx: 0, vy: 0, valor: D.of(0), tipo: 'ouro', t: 0, r: 6, atraido: false, escala: 1 };
}
function limparColetavel(c) { c.ativo = false; c.atraido = false; c.t = 0; c.escala = 1; }

/* ----------------------------------------------------------------- pools */

export const inimigos = new Pool(novoInimigo, limparInimigo, 96, 600);
export const projeteis = new Pool(novoProjetil, limparProjetil, 128, 900);
export const coletaveis = new Pool(novoColetavel, limparColetavel, 64, 400);

/* --------------------------------------------------------- grade espacial */

const CELULA = 72;
class Grade {
  constructor() { this.cells = new Map(); }
  limpar() { this.cells.clear(); }
  _key(cx, cy) { return cx * 4096 + cy; }
  inserir(e) {
    const cx = Math.floor(e.x / CELULA), cy = Math.floor(e.y / CELULA);
    const k = this._key(cx, cy);
    let arr = this.cells.get(k);
    if (!arr) { arr = []; this.cells.set(k, arr); }
    arr.push(e);
  }
  /** Todos os inimigos num raio (aproximado por células). */
  consultar(x, y, raio, saida) {
    saida.length = 0;
    const c0x = Math.floor((x - raio) / CELULA), c1x = Math.floor((x + raio) / CELULA);
    const c0y = Math.floor((y - raio) / CELULA), c1y = Math.floor((y + raio) / CELULA);
    const r2 = raio * raio;
    for (let cx = c0x; cx <= c1x; cx++) {
      for (let cy = c0y; cy <= c1y; cy++) {
        const arr = this.cells.get(this._key(cx, cy));
        if (!arr) continue;
        for (let i = 0; i < arr.length; i++) {
          const e = arr[i];
          const dx = e.x - x, dy = e.y - y;
          if (dx * dx + dy * dy <= r2 + e.r * e.r) saida.push(e);
        }
      }
    }
    return saida;
  }
}
export const grade = new Grade();
const _buffer = [];

export function reconstruirGrade() {
  grade.limpar();
  const act = inimigos.active;
  for (let i = 0; i < act.length; i++) {
    const e = act[i];
    if (e.ativo && e.morrendo <= 0) grade.inserir(e);
  }
}

export function consultarArea(x, y, raio) {
  return grade.consultar(x, y, raio, _buffer);
}

/* ------------------------------------------------------------ seleção */

/**
 * Escolhe alvo segundo a estratégia.
 * @param {'proximo'|'longe'|'forte'|'fraco'|'chefe'|'avancado'} modo
 */
export function escolherAlvo(cx, cy, alcance, modo = 'proximo', excluir = null) {
  const act = inimigos.active;
  let melhor = null, melhorScore = -Infinity;
  const a2 = alcance * alcance;
  for (let i = 0; i < act.length; i++) {
    const e = act[i];
    if (!e.ativo || e.morrendo > 0) continue;
    if (excluir && excluir.has(e)) continue;
    const dx = e.x - cx, dy = e.y - cy;
    const d2 = dx * dx + dy * dy;
    if (d2 > a2) continue;
    let score;
    switch (modo) {
      case 'longe': score = d2; break;
      case 'forte': score = e.hp.log10(); break;
      case 'fraco': score = -e.hp.log10(); break;
      case 'chefe': score = (e.chefe ? 1e6 : 0) + (e.elite ? 1e3 : 0) - d2 * 1e-4; break;
      case 'avancado': score = -d2; break;   // mais perto da torre = mais avançado
      case 'proximo':
      default: score = -d2; break;
    }
    if (score > melhorScore) { melhorScore = score; melhor = e; }
  }
  return melhor;
}

export function limparArena() {
  inimigos.releaseAll();
  projeteis.releaseAll();
  coletaveis.releaseAll();
  grade.limpar();
}

/** Ponto aleatório na borda da arena (spawn). */
export function pontoDeSpawn(rnd, margem = 40) {
  const ang = rnd.angle();
  const raio = Math.max(ARENA.w, ARENA.h) * 0.62 + margem;
  return { x: ARENA.cx + Math.cos(ang) * raio, y: ARENA.cy + Math.sin(ang) * raio, ang: ang + Math.PI };
}

export { TAU };
