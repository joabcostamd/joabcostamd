/**
 * economy.js — moedas, XP/níveis, coletáveis (ouro no chão) e ímã.
 */
import { D } from '../core/decimal.js';
import { bus, EV } from '../core/events.js';
import { rng } from '../core/rng.js';
import { ARENA, coletaveis } from './arena.js';
import { NIVEL, COMBATE } from '../data/balance.js';
import { RAIO_TORRE } from './enemies.js';

/** Cria moedas físicas no chão que o jogador (ou o ímã) coleta. */
export function soltarOuro(e, valor, ctx) {
  const stats = ctx.stats;
  const total = valor.mul(stats.getN('ganhoOuro'));
  const s = ctx.state;

  // Se a coleta é instantânea (upgrade de ímã total), pula a física
  if (ctx.coletaInstantanea) { ganharOuro(total, ctx, { x: e.x, y: e.y }); return; }

  const n = e.chefe ? 12 : (e.dourado ? 8 : (e.elite ? 4 : 1));
  const parte = total.divN(n);
  for (let i = 0; i < n; i++) {
    const c = coletaveis.get();
    c.ativo = true;
    c.x = e.x + rng.gauss(0, 6);
    c.y = e.y + rng.gauss(0, 6);
    const ang = rng.angle();
    const forca = rng.float(40, 130);
    c.vx = Math.cos(ang) * forca;
    c.vy = Math.sin(ang) * forca;
    c.valor = parte;
    c.tipo = e.dourado ? 'dourado' : 'ouro';
    c.t = 0;
    c.r = e.chefe ? 8 : 6;
    c.escala = 0;
  }
}

export function atualizarColetaveis(dt, ctx) {
  const stats = ctx.stats;
  const raioIma = 70 * stats.getN('coleta');
  const act = coletaveis.active;
  for (let i = act.length - 1; i >= 0; i--) {
    const c = act[i];
    if (!c.ativo) { coletaveis.releaseAt(i); continue; }
    c.t += dt;
    if (c.escala < 1) c.escala = Math.min(1, c.escala + dt * 6);

    const dx = ARENA.cx - c.x, dy = ARENA.cy - c.y;
    const d = Math.hypot(dx, dy);

    if (c.atraido || d < raioIma || c.t > 3.5) {
      c.atraido = true;
      const vel = 260 + c.t * 220;
      c.vx = (dx / (d || 1)) * vel;
      c.vy = (dy / (d || 1)) * vel;
    } else {
      c.vx *= Math.pow(0.05, dt);
      c.vy *= Math.pow(0.05, dt);
    }
    c.x += c.vx * dt;
    c.y += c.vy * dt;

    if (d < RAIO_TORRE + 6) {
      ganharOuro(c.valor, ctx, { x: c.x, y: c.y, tipo: c.tipo });
      coletaveis.releaseAt(i);
    }
  }
}

/* ------------------------------------------------------------- moedas */

export function ganharOuro(valor, ctx, info = {}) {
  const s = ctx.state;
  const v = valor instanceof D ? valor : D.of(valor);
  if (v.lte(0)) return;
  s.moedas.ouro = s.moedas.ouro.add(v);
  s.stats.ouroTotal = s.stats.ouroTotal.add(v);
  if (!info.silencioso) bus.emit(EV.GOLD_GAIN, { valor: v, ...info });
}

export function gastarOuro(valor, ctx) {
  const s = ctx.state;
  const v = valor instanceof D ? valor : D.of(valor);
  if (s.moedas.ouro.lt(v)) return false;
  s.moedas.ouro = s.moedas.ouro.sub(v);
  s.stats.ouroGasto = s.stats.ouroGasto.add(v);
  return true;
}

export function ganharMoeda(chave, valor, ctx, info = {}) {
  const s = ctx.state;
  const v = valor instanceof D ? valor : D.of(valor);
  if (v.lte(0)) return;
  s.moedas[chave] = (s.moedas[chave] || D.of(0)).add(v);
  bus.emit(EV.CURRENCY_GAIN, { chave, valor: v, ...info });
}

export function gastarMoeda(chave, valor, ctx) {
  const s = ctx.state;
  const v = valor instanceof D ? valor : D.of(valor);
  const atual = s.moedas[chave] || D.of(0);
  if (atual.lt(v)) return false;
  s.moedas[chave] = atual.sub(v);
  return true;
}

/* ------------------------------------------------------------- níveis */

export function ganharXP(valor, ctx) {
  const s = ctx.state;
  const v = (valor instanceof D ? valor : D.of(valor)).mul(ctx.stats.getN('ganhoXP'));
  if (v.lte(0)) return;
  s.xp = s.xp.add(v);
  let subiu = 0;
  let guard = 0;
  while (s.nivel < NIVEL.MAX && guard++ < 500) {
    const custo = NIVEL.custo(s.nivel);
    if (s.xp.lt(custo)) break;
    s.xp = s.xp.sub(custo);
    s.nivel++;
    const pontos = NIVEL.pontosPorNivel(s.nivel);
    s.pontosTalento += pontos;
    subiu++;
    bus.emit(EV.LEVEL_UP, { nivel: s.nivel, pontos });
  }
  if (subiu) ctx.marcarStatsSujos();
}

export function xpParaProximo(s) { return NIVEL.custo(s.nivel); }
export function progressoNivel(s) {
  const custo = NIVEL.custo(s.nivel);
  if (custo.isZero()) return 1;
  return Math.min(1, s.xp.div(custo).toNumber());
}

/* ---------------------------------------------------------- recompensas */

/** Bônus por concluir uma onda (ouro + xp extra + moedas especiais). */
export function recompensaDeOnda(onda, ctx) {
  const { ouroDaOnda, xpDaOnda, ONDA, LOOT } = ctx.balance;
  const bonusOuro = ouroDaOnda(onda).mulN(ONDA.ehChefe(onda) ? 26 : 4.5);
  ganharOuro(bonusOuro.mul(ctx.stats.getN('ganhoOuro')), ctx, { fonte: 'onda', bonus: true });
  ganharXP(xpDaOnda(onda).mulN(ONDA.ehChefe(onda) ? 16 : 3), ctx);
  if (ONDA.ehChefe(onda)) {
    ganharMoeda('gemas', ONDA.ehSuperChefe(onda) ? LOOT.GEMAS_SUPER : LOOT.GEMAS_CHEFE, ctx, { fonte: 'chefe' });
  }
}
