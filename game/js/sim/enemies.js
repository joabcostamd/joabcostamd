/**
 * enemies.js — spawn, comportamentos de movimento e habilidades dos inimigos.
 */
import { D } from '../core/decimal.js';
import { bus, EV } from '../core/events.js';
import { rng } from '../core/rng.js';
import { TAU, clamp, angleTo } from '../core/util.js';
import { ARENA, inimigos, pontoDeSpawn, consultarArea, coletaveis } from './arena.js';
import { INIMIGO_POR_ID, ELITES, poolDaOnda, chefeDaOnda } from '../data/enemies.js';
import {
  hpDaOnda, ouroDaOnda, xpDaOnda, ONDA,
  MULT_CHEFE, MULT_SUPER_CHEFE, MULT_ELITE, MULT_DOURADO, COMBATE,
} from '../data/balance.js';
import { aplicarDano, matarInimigo, danoEmArea } from './combat.js';

export const RAIO_TORRE = 34;
let proximoId = 1;

/* ------------------------------------------------------------- criação */

export function criarInimigo(def, onda, ctx, opts = {}) {
  const e = inimigos.get();
  const escalaDif = ctx.modificadores || { hpInimigo: 1, velocidadeInimigo: 1, ouro: 1 };

  e.ativo = true;
  e.id = proximoId++;
  e.tipo = def.id;
  e.def = def;
  e.chefe = !!opts.chefe;
  e.superChefe = !!opts.superChefe;
  e.elite = !!opts.elite;
  e.dourado = !!opts.dourado;
  e.eliteMod = opts.eliteMod || null;
  e.dividido = !!opts.dividido;

  const p = opts.pos || pontoDeSpawn(rng);
  e.x = p.x; e.y = p.y;
  e.dirAng = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
  e.ang = e.dirAng;

  // multiplicadores compostos
  let mHp = def.hp ?? 1, mOuro = def.ouro ?? 1, mVel = def.vel ?? 1, mEsc = def.esc ?? 1, mXp = 1;
  if (e.chefe) {
    const M = e.superChefe ? MULT_SUPER_CHEFE : MULT_CHEFE;
    mHp *= M.hp; mOuro *= M.ouro; mXp *= M.xp; mEsc *= M.escala; mVel *= M.vel;
  }
  if (e.elite) {
    const mod = ELITES.find((m) => m.id === e.eliteMod);
    mHp *= (mod?.hp ?? 1) * MULT_ELITE.hp;
    mOuro *= (mod?.ouro ?? 1) * MULT_ELITE.ouro;
    mXp *= MULT_ELITE.xp;
    mEsc *= (mod?.esc ?? 1) * MULT_ELITE.escala;
    mVel *= mod?.vel ?? 1;
  }
  if (e.dourado) { mHp *= MULT_DOURADO.hp; mOuro *= MULT_DOURADO.ouro; mXp *= MULT_DOURADO.xp; mEsc *= MULT_DOURADO.escala; mVel *= MULT_DOURADO.vel; }
  if (opts.hpMult) mHp *= opts.hpMult;
  if (opts.escMult) mEsc *= opts.escMult;

  const hp = hpDaOnda(onda).mulN(mHp * escalaDif.hpInimigo);
  e.hpMax = hp;
  e.hp = hp.clone();
  e.ouro = ouroDaOnda(onda).mulN(mOuro * escalaDif.ouro);
  e.xp = xpDaOnda(onda).mulN(mXp);
  e.armadura = (def.armadura || 0) + (e.chefe ? 25 : 0) + onda * 0.35;
  e.escala = mEsc;
  e.r = 11 * mEsc;
  e.velBase = ONDA.velocidade(onda) * mVel * escalaDif.velocidadeInimigo;
  e.vel = e.velBase;
  e.entrada = 0.35;
  e.t = 0; e.cd = rng.float(0, 1); e.estado = 0; e.fase = 0;
  e.faseAnim = rng.float(0, TAU);

  if (def.escudoFrac) { e.escudoMax = hp.mulN(def.escudoFrac).toNumber(); e.escudo = e.escudoMax; }
  if (e.chefe) { e.faseHp = 1 - 1 / (def.fases || 1); }

  bus.emit(EV.ENEMY_SPAWN, { e });
  if (e.chefe) bus.emit(EV.BOSS_SPAWN, { e });
  return e;
}

/** Sorteia e cria um inimigo apropriado para a onda. */
export function spawnDaOnda(onda, ctx) {
  const pool = poolDaOnda(onda);
  if (!pool.length) return null;
  let total = 0;
  for (const d of pool) total += d.peso;
  let r = rng.next() * total;
  let def = pool[pool.length - 1];
  for (const d of pool) { r -= d.peso; if (r <= 0) { def = d; break; } }

  const elite = rng.next() < ONDA.chanceElite(onda);
  const dourado = !elite && rng.next() < ONDA.chanceDourado(onda) * (ctx.stats?.getN('sorte') || 1);
  const opts = {
    elite,
    dourado,
    eliteMod: elite ? rng.pick(ELITES).id : null,
  };

  if (def.grupo) {
    const n = rng.int(def.grupo[0], def.grupo[1]);
    const base = pontoDeSpawn(rng);
    let primeiro = null;
    for (let i = 0; i < n; i++) {
      const ang = rng.angle();
      const rr = rng.float(0, 40);
      const e = criarInimigo(def, onda, ctx, {
        ...opts,
        elite: opts.elite && i === 0,
        pos: { x: base.x + Math.cos(ang) * rr, y: base.y + Math.sin(ang) * rr },
      });
      primeiro ||= e;
    }
    return primeiro;
  }
  return criarInimigo(def, onda, ctx, opts);
}

/** Cria o chefe da onda. */
export function spawnChefe(onda, ctx) {
  const def = chefeDaOnda(onda);
  const superC = ONDA.ehSuperChefe(onda);
  const e = criarInimigo(def, onda, ctx, { chefe: true, superChefe: superC });
  // Serpente: cria os segmentos como inimigos encadeados
  if (def.mecanica === 'segmentos') {
    let anterior = e;
    for (let i = 0; i < (def.segmentos || 6); i++) {
      const seg = criarInimigo(def, onda, ctx, {
        chefe: false, hpMult: 0.16, escMult: 0.55,
        pos: { x: e.x - Math.cos(e.dirAng) * (i + 1) * 26, y: e.y - Math.sin(e.dirAng) * (i + 1) * 26 },
      });
      seg.segmentoDe = anterior;
      seg.tipo = def.id;
      seg.def = def;
      seg.ehSegmento = true;
      anterior = seg;
    }
  }
  return e;
}

/** Divide um inimigo ao morrer. */
export function dividirInimigo(e, ctx) {
  const cfg = e.def?.divide;
  if (!cfg) return;
  for (let i = 0; i < cfg.qtd; i++) {
    const ang = rng.angle();
    const filho = criarInimigo(e.def, ctx.state.onda, ctx, {
      dividido: true,
      hpMult: cfg.hp, escMult: cfg.esc,
      pos: { x: e.x + Math.cos(ang) * 18, y: e.y + Math.sin(ang) * 18 },
    });
    filho.vx = Math.cos(ang) * 60;
    filho.vy = Math.sin(ang) * 60;
  }
}

/* -------------------------------------------------------- movimentação */

const MOVIMENTOS = {
  direto(e, dt) {
    const ang = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
    e.dirAng = ang;
    e.x += Math.cos(ang) * e.vel * dt;
    e.y += Math.sin(ang) * e.vel * dt;
  },
  zigue(e, dt) {
    const ang = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
    e.dirAng = ang;
    const lateral = Math.sin(e.t * 4.2 + e.faseAnim) * 52;
    e.x += (Math.cos(ang) * e.vel + Math.cos(ang + Math.PI / 2) * lateral) * dt;
    e.y += (Math.sin(ang) * e.vel + Math.sin(ang + Math.PI / 2) * lateral) * dt;
  },
  salto(e, dt) {
    e.cd -= dt;
    if (e.estado === 0) {
      if (e.cd <= 0) { e.estado = 1; e.cd = 0.55; }
    } else {
      const ang = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
      e.dirAng = ang;
      const boost = 3.2;
      e.x += Math.cos(ang) * e.vel * boost * dt;
      e.y += Math.sin(ang) * e.vel * boost * dt;
      e.alturaSalto = Math.sin((1 - e.cd / 0.55) * Math.PI) * 22;
      if (e.cd <= 0) { e.estado = 0; e.cd = 0.9; e.alturaSalto = 0; }
    }
  },
  teleporte(e, dt) {
    e.cd -= dt;
    MOVIMENTOS.direto(e, dt * 0.45);
    if (e.cd <= 0) {
      e.cd = 2.4;
      const ang = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
      const d = Math.hypot(ARENA.cx - e.x, ARENA.cy - e.y);
      const salto = Math.min(150, d - RAIO_TORRE - e.r - 10);
      if (salto > 20) {
        e.piscou = 0.3;
        e.x += Math.cos(ang) * salto;
        e.y += Math.sin(ang) * salto;
      }
    }
  },
  fantasma(e, dt) {
    e.cd -= dt;
    if (e.cd <= 0) { e.intangivel = e.intangivel > 0 ? 0 : 1.1; e.cd = e.intangivel > 0 ? 1.1 : 2.0; }
    if (e.intangivel > 0) e.intangivel -= dt;
    MOVIMENTOS.direto(e, dt);
  },
  parar_atirar(e, dt, ctx) {
    const d = Math.hypot(ARENA.cx - e.x, ARENA.cy - e.y);
    const alcance = e.def.alcance || 250;
    if (d > alcance) MOVIMENTOS.direto(e, dt);
    else {
      e.cd -= dt;
      e.dirAng = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
      if (e.cd <= 0) { e.cd = 2.2; ctx.projetilInimigo?.(e); }
    }
  },
  errante(e, dt) {
    e.vagueio = (e.vagueio || 0) + dt;
    const ang = angleTo(e.x, e.y, ARENA.cx, ARENA.cy) + Math.sin(e.vagueio * 1.7 + e.faseAnim) * 0.9;
    e.dirAng = ang;
    e.x += Math.cos(ang) * e.vel * dt;
    e.y += Math.sin(ang) * e.vel * dt;
  },
  perseguidor(e, dt) {
    const d = Math.hypot(ARENA.cx - e.x, ARENA.cy - e.y);
    const aceler = clamp(1 + (400 - d) / 300, 1, 2.6);
    const ang = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
    e.dirAng = ang;
    e.x += Math.cos(ang) * e.vel * aceler * dt;
    e.y += Math.sin(ang) * e.vel * aceler * dt;
  },
  orbital(e, dt) {
    const ang = angleTo(ARENA.cx, ARENA.cy, e.x, e.y);
    const d = Math.hypot(ARENA.cx - e.x, ARENA.cy - e.y);
    const novoAng = ang + (e.vel / Math.max(60, d)) * dt * 1.4;
    const novoD = Math.max(RAIO_TORRE, d - e.vel * dt * 0.45);
    e.x = ARENA.cx + Math.cos(novoAng) * novoD;
    e.y = ARENA.cy + Math.sin(novoAng) * novoD;
    e.dirAng = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
  },
  estatico(e) { e.dirAng = angleTo(e.x, e.y, ARENA.cx, ARENA.cy); },
};

/* --------------------------------------------------------- habilidades */

const HABILIDADES = {
  curar(e, dt, ctx) {
    e.cd -= dt;
    if (e.cd > 0) return;
    e.cd = 2.0;
    const raio = e.def.raio || 130;
    const alvos = consultarArea(e.x, e.y, raio).slice();
    let curou = 0;
    for (const a of alvos) {
      if (a === e || a.morrendo > 0) continue;
      const cura = a.hpMax.mulN(0.06);
      a.hp = a.hp.add(cura).min(a.hpMax);
      curou++;
    }
    if (curou) ctx.fx?.pulso(e.x, e.y, raio, '#86efac');
  },
  cuspir(e, dt, ctx) { /* disparo tratado em parar_atirar */ },
  explodir(e, dt, ctx) { /* tratado na morte */ },
  roubar_ouro(e, dt, ctx) {
    e.cd -= dt;
    if (e.cd > 0) return;
    e.cd = 1.6;
    const perto = consultarArea(e.x, e.y, 90);
    // rouba coletáveis próximos
    const act = coletaveis.active;
    for (let i = act.length - 1; i >= 0; i--) {
      const c = act[i];
      if (!c.ativo) continue;
      if (Math.hypot(c.x - e.x, c.y - e.y) < 70) {
        e.ouro = e.ouro.add(c.valor);
        coletaveis.releaseAt(i);
        ctx.fx?.faisca(c.x, c.y, '#f472b6');
      }
    }
  },
  refletir() {},
  grudar(e, dt, ctx) {
    if (e.grudado) {
      e.cd -= dt;
      if (e.cd <= 0) { e.cd = 1.0; ctx.danoNaTorre(ctx.state.torre.vidaMax * 0.012, e, { drenar: true }); }
    }
  },
  chocar(e, dt, ctx) {
    e.cd -= dt;
    if (e.cd > 0) return;
    e.cd = 4.5;
    const def = INIMIGO_POR_ID.enxame;
    if (!def) return;
    for (let i = 0; i < 3; i++) {
      const ang = rng.angle();
      criarInimigo(def, ctx.state.onda, ctx, { pos: { x: e.x + Math.cos(ang) * 20, y: e.y + Math.sin(ang) * 20 } });
    }
    ctx.fx?.pulso(e.x, e.y, 50, '#d9f99d');
  },
  devorar(e, dt, ctx) {
    const act = coletaveis.active;
    for (let i = act.length - 1; i >= 0; i--) {
      const c = act[i];
      if (!c.ativo) continue;
      if (Math.hypot(c.x - e.x, c.y - e.y) < 55) {
        e.hp = e.hp.add(e.hpMax.mulN(0.05)).min(e.hpMax.mulN(2));
        e.escala = Math.min(3, e.escala * 1.03);
        e.r = 11 * e.escala;
        coletaveis.releaseAt(i);
        ctx.fx?.faisca(c.x, c.y, '#dc2626');
      }
    }
  },
  mutar(e, dt, ctx) {
    e.cd -= dt;
    if (e.cd > 0) return;
    e.cd = 3.0;
    e.mutacao = (e.mutacao || 0) + 1;
    e.armadura = e.mutacao % 2 === 0 ? (e.def.armadura || 0) + 60 : 0;
    e.vel = e.mutacao % 2 === 0 ? e.velBase * 0.6 : e.velBase * 1.6;
    ctx.fx?.pulso(e.x, e.y, 40, '#7c3aed');
  },
  ceifar(e, dt, ctx) {
    e.cd -= dt;
    if (e.cd > 0) return;
    e.cd = 5.0;
    const d = Math.hypot(ARENA.cx - e.x, ARENA.cy - e.y);
    if (d < 300 && d > 80) {
      const ang = angleTo(e.x, e.y, ARENA.cx, ARENA.cy);
      e.x += Math.cos(ang) * 120;
      e.y += Math.sin(ang) * 120;
      e.piscou = 0.3;
      ctx.fx?.pulso(e.x, e.y, 60, '#f43f5e');
    }
  },
};

/* ------------------------------------------------------------ update */

export function atualizarInimigos(dt, ctx) {
  const act = inimigos.active;
  const s = ctx.state;
  const raioContato = RAIO_TORRE;

  for (let i = act.length - 1; i >= 0; i--) {
    const e = act[i];
    if (!e.ativo) { inimigos.releaseAt(i); continue; }

    if (e.morrendo > 0) {
      e.morrendo -= dt;
      if (e.morrendo <= 0) inimigos.releaseAt(i);
      continue;
    }

    e.t += dt;
    if (e.entrada > 0) e.entrada -= dt;
    if (e.piscou > 0) e.piscou -= dt;

    // velocidade efetiva (gelo / atordoamento / elite)
    let vel = e.velBase;
    if (e.gelo > 0) vel *= (1 - e.geloForca);
    if (e.atordoado > 0) vel = 0;
    if (ctx.tempoCongelado > 0) vel = 0;
    e.vel = vel;

    // elite regenerativo
    if (e.eliteMod === 'regenerativo' && e.hp.lt(e.hpMax)) {
      e.hp = e.hp.add(e.hpMax.mulN(0.02 * dt)).min(e.hpMax);
    }
    // escudo de blindado volta devagar
    if (e.escudoMax > 0 && e.escudo < e.escudoMax && e.semDanoT > 2.5) {
      e.escudo = Math.min(e.escudoMax, e.escudo + e.escudoMax * 0.25 * dt);
    }
    e.semDanoT = e.flash > 0 ? 0 : (e.semDanoT || 0) + dt;

    if (!e.grudado && vel > 0) {
      const mov = MOVIMENTOS[e.def?.mov || 'direto'] || MOVIMENTOS.direto;
      mov(e, dt, ctx);
      // impulso residual (divisão, empurrão)
      if (e.vx || e.vy) {
        e.x += e.vx * dt; e.y += e.vy * dt;
        e.vx *= Math.pow(0.02, dt); e.vy *= Math.pow(0.02, dt);
        if (Math.abs(e.vx) < 1) e.vx = 0;
        if (Math.abs(e.vy) < 1) e.vy = 0;
      }
    }

    const hab = HABILIDADES[e.def?.hab];
    if (hab) hab(e, dt, ctx);
    if (e.chefe) ctx.atualizarChefe?.(e, dt);

    e.ang = e.dirAng;

    // contato com a torre
    const dx = ARENA.cx - e.x, dy = ARENA.cy - e.y;
    const d = Math.hypot(dx, dy);
    if (d <= raioContato + e.r * 0.7) {
      if (e.def?.hab === 'grudar' && !e.grudado) {
        e.grudado = true;
        e.anguloGrude = angleTo(ARENA.cx, ARENA.cy, e.x, e.y);
        e.x = ARENA.cx + Math.cos(e.anguloGrude) * (raioContato + e.r * 0.5);
        e.y = ARENA.cy + Math.sin(e.anguloGrude) * (raioContato + e.r * 0.5);
      } else if (!e.grudado) {
        ctx.impactoNaTorre(e);
        continue;
      }
    }
  }
}

/** O inimigo alcançou a torre: dano e (normalmente) morte. */
export function impactoPadrao(e, ctx) {
  const s = ctx.state;
  const fracDano = e.chefe ? COMBATE.DANO_CONTATO_CHEFE : COMBATE.DANO_CONTATO_FRAC;
  const dano = s.torre.vidaMax * fracDano * (e.escala > 1 ? Math.sqrt(e.escala) : 1);
  ctx.danoNaTorre(dano, e);
  bus.emit(EV.ENEMY_REACH, { e, dano });

  // espinhos da torre
  const espinhos = ctx.stats.getN('espinhos');
  if (espinhos > 0) {
    aplicarDano(e, ctx.stats.getD('dano').mulN(espinhos * 6), ctx, { puro: true, fonte: 'espinhos' });
  }
  // bomba viva explode
  if (e.def?.hab === 'explodir') {
    ctx.fx?.explosao(e.x, e.y, e.def.raio || 110, '#fb923c');
  }
  // some sem dar recompensa (não é abate)
  if (!e.chefe) { e.morrendo = 0.2; e.hp = D.of(0); }
  s.combo.atual = 0;
  bus.emit(EV.COMBO_BREAK, {});
}

export { MOVIMENTOS, HABILIDADES };
