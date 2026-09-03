/**
 * abilities.js — execução das habilidades ativas.
 */
import { D } from '../core/decimal.js';
import { bus, EV } from '../core/events.js';
import { rng } from '../core/rng.js';
import { TAU, angleTo } from '../core/util.js';
import { ARENA, inimigos, projeteis, escolherAlvo } from './arena.js';
import { aplicarDano, danoEmArea } from './combat.js';
import { HABILIDADE_POR_ID, valorHab, cdEfetivo, durEfetiva } from '../data/abilities.js';

export function estadoHabilidade(state, id) {
  return (state.habilidades[id] ||= { desbloqueada: false, nivel: 1, cd: 0, ativaAte: 0, usos: 0 });
}

export function habilidadeDisponivel(state, id) {
  const def = HABILIDADE_POR_ID[id];
  if (!def) return false;
  const h = estadoHabilidade(state, id);
  return h.desbloqueada && h.cd <= 0 && state.torre.viva && !state.silenciado;
}

export function desbloquearPorProgresso(state) {
  const novas = [];
  for (const def of Object.values(HABILIDADE_POR_ID)) {
    const h = estadoHabilidade(state, def.id);
    if (!h.desbloqueada && state.ondaMaximaGlobal >= (def.requer?.onda || 1)) {
      h.desbloqueada = true;
      novas.push(def);
    }
  }
  return novas;
}

/** Executa a habilidade. Retorna true se usou. */
export function usarHabilidade(id, ctx) {
  const state = ctx.state;
  const def = HABILIDADE_POR_ID[id];
  if (!def || !habilidadeDisponivel(state, id)) return false;
  const h = estadoHabilidade(state, id);
  const nivel = h.nivel;
  const cdr = ctx.stats.getN('cdr');
  const dur = durEfetiva(def, nivel, ctx.stats.getN('duracaoHab'));

  h.cd = cdEfetivo(def, nivel, cdr);
  h.cdMax = h.cd;
  h.usos++;
  state.stats.habilidadesUsadas++;

  const danoBase = ctx.stats.getD('dano').mulN(ctx.stats.getN('multiplicador'));

  switch (def.tipo) {
    case 'instantanea': {
      const mult = valorHab(def, 'dano', nivel);
      const dano = danoBase.mulN(mult);
      const act = inimigos.active.slice();
      for (const e of act) if (e.ativo && e.morrendo <= 0) aplicarDano(e, dano, ctx, { crit: true, fonte: 'nova', penetracao: 1 });
      ctx.fx?.nova(ARENA.cx, ARENA.cy, Math.max(ARENA.w, ARENA.h), def.cor);
      ctx.tremor(22, 0.55);
      ctx.hitstop(90);
      break;
    }
    case 'buff': {
      for (const b of def.buffs) {
        let valor;
        if (b.tipo === 'multChave') valor = valorHab(def, b.chave, nivel);
        else if (b.tipo === 'flatChave') valor = valorHab(def, b.chave, nivel);
        else valor = valorHab(def, b.chave, nivel) * (b.escala ?? 1);
        ctx.adicionarBuff({
          id: `hab_${def.id}_${b.stat}`,
          stat: b.stat,
          tipo: b.tipo === 'multChave' ? 'mult' : (b.tipo === 'flatChave' ? 'flat' : b.tipo),
          valor,
          restante: dur,
          fonte: def.nome,
          icone: def.icone,
          cor: def.cor,
        });
      }
      ctx.fx?.aura(ARENA.cx, ARENA.cy, def.cor, dur);
      break;
    }
    case 'congelar': {
      ctx.tempoCongelado = dur;
      for (const e of inimigos.active) if (e.ativo) e.atordoado = Math.max(e.atordoado, dur);
      ctx.fx?.congelarTela(dur, def.cor);
      break;
    }
    case 'invulneravel': {
      ctx.invulneravel = dur;
      ctx.fx?.aura(ARENA.cx, ARENA.cy, def.cor, dur);
      break;
    }
    case 'misseis': {
      const qtd = Math.round(valorHab(def, 'qtd', nivel));
      const mult = valorHab(def, 'dano', nivel);
      ctx.filaMisseis = { restantes: qtd, intervalo: 0.06, cd: 0, dano: danoBase.mulN(mult), cor: def.cor };
      break;
    }
    case 'buraco_negro': {
      ctx.buracoNegro = {
        x: ARENA.cx + rng.float(-60, 60),
        y: ARENA.cy + rng.float(-60, 60),
        restante: dur,
        dano: danoBase.mulN(valorHab(def, 'dano', nivel)),
        raio: 240,
        cor: def.cor,
      };
      break;
    }
    case 'cura': {
      const frac = valorHab(def, 'cura', nivel) / 100;
      const cura = state.torre.vidaMax * frac;
      ctx.curarTorre(cura);
      state.torre.escudo = Math.min(state.torre.vidaMax, state.torre.escudo + cura);
      ctx.fx?.aura(ARENA.cx, ARENA.cy, def.cor, 1.2);
      break;
    }
    case 'julgamento': {
      const mult = valorHab(def, 'dano', nivel);
      const act = inimigos.active.slice();
      for (const e of act) {
        if (!e.ativo || e.morrendo > 0) continue;
        if (e.chefe) aplicarDano(e, danoBase.mulN(mult), ctx, { crit: true, fonte: 'julgamento', penetracao: 1 });
        else aplicarDano(e, e.hp.mulN(10), ctx, { puro: true, fonte: 'julgamento' });
      }
      ctx.fx?.julgamento();
      ctx.tremor(34, 0.9);
      ctx.hitstop(160);
      ctx.slowmo(0.25, 700);
      break;
    }
  }

  bus.emit(EV.ABILITY_USE, { id, def, nivel, dur });
  return true;
}

/** Atualiza recargas, mísseis em voo e o buraco negro. */
export function atualizarHabilidades(dt, ctx) {
  const state = ctx.state;
  for (const id in state.habilidades) {
    const h = state.habilidades[id];
    if (h.cd > 0) {
      h.cd -= dt;
      if (h.cd <= 0) { h.cd = 0; bus.emit(EV.ABILITY_READY, { id }); }
    }
  }

  if (ctx.tempoCongelado > 0) ctx.tempoCongelado -= dt;
  if (ctx.invulneravel > 0) ctx.invulneravel -= dt;

  // salva de mísseis
  const f = ctx.filaMisseis;
  if (f && f.restantes > 0) {
    f.cd -= dt;
    while (f.cd <= 0 && f.restantes > 0) {
      f.cd += f.intervalo;
      f.restantes--;
      const alvo = escolherAlvo(ARENA.cx, ARENA.cy, 3000, 'forte');
      if (!alvo) break;
      const p = projeteis.get();
      const ang = rng.angle();
      p.ativo = true;
      p.x = ARENA.cx + Math.cos(ang) * 20;
      p.y = ARENA.cy + Math.sin(ang) * 20;
      p.vel = 520;
      p.ang = ang;
      p.vx = Math.cos(ang) * p.vel;
      p.vy = Math.sin(ang) * p.vel;
      p.dano = f.dano;
      p.crit = true;
      p.alvo = alvo;
      p.area = 60;
      p.r = 6;
      p.vida = 4;
      p.cor = f.cor;
      p.tipo = 'missil';
      p.origem = 'torre';
      p.atingidos = null;
    }
    if (f.restantes <= 0) ctx.filaMisseis = null;
  }

  // buraco negro
  const bn = ctx.buracoNegro;
  if (bn) {
    bn.restante -= dt;
    for (const e of inimigos.active) {
      if (!e.ativo || e.morrendo > 0) continue;
      const dx = bn.x - e.x, dy = bn.y - e.y;
      const d = Math.hypot(dx, dy);
      if (d < bn.raio) {
        const forca = (1 - d / bn.raio) * 260;
        e.x += (dx / (d || 1)) * forca * dt;
        e.y += (dy / (d || 1)) * forca * dt;
      }
    }
    bn.acc = (bn.acc || 0) + dt;
    if (bn.acc >= 0.25) {
      bn.acc -= 0.25;
      danoEmArea(bn.x, bn.y, bn.raio, bn.dano.mulN(0.25), ctx, { crit: false, fonte: 'buraco_negro', penetracao: 0.5 });
    }
    if (bn.restante <= 0) {
      danoEmArea(bn.x, bn.y, bn.raio * 1.3, bn.dano.mulN(3), ctx, { crit: true, fonte: 'buraco_negro' });
      ctx.fx?.explosao(bn.x, bn.y, bn.raio * 1.3, bn.cor);
      ctx.tremor(18, 0.4);
      ctx.buracoNegro = null;
    }
  }
}

/** Escolha da IA para o uso automático. */
export function autoUsarHabilidades(ctx) {
  const state = ctx.state;
  const perigo = state.torre.vidaMax > 0 ? state.torre.vida / state.torre.vidaMax : 1;
  const inimigosVivos = inimigos.count;
  const ordem = [
    ['reparo', () => perigo < 0.4],
    ['escudo_absoluto', () => perigo < 0.25],
    ['julgamento', () => inimigosVivos > 18 || (state.emChefe && perigo < 0.5)],
    ['nova', () => inimigosVivos >= 8],
    ['buraco_negro', () => inimigosVivos >= 10],
    ['misseis', () => state.emChefe || inimigosVivos >= 6],
    ['tempo', () => inimigosVivos >= 12 || perigo < 0.5],
    ['sobrecarga', () => inimigosVivos >= 4 || state.emChefe],
    ['sentinelas', () => inimigosVivos >= 4],
    ['chuva_ouro', () => inimigosVivos >= 6],
  ];
  for (const [id, cond] of ordem) {
    if (habilidadeDisponivel(state, id) && cond()) { usarHabilidade(id, ctx); return true; }
  }
  return false;
}
