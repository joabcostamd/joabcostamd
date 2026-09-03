/**
 * game.js — o orquestrador. Dono do estado, da simulação e de todas as ações.
 *
 * Todo módulo de simulação recebe este objeto como `ctx`.
 */
import { D } from '../core/decimal.js';
import { bus, EV } from '../core/events.js';
import { rng, RNG } from '../core/rng.js';
import { clamp } from '../core/util.js';
import { Storage } from '../core/storage.js';

import { createInitialState } from './state.js';
import { StatEngine } from './statengine.js';
import { recalcular, carregarConteudo, ESPECIAIS_PADRAO } from './modifiers.js';
import { ARENA, limparArena, inimigos, projeteis, coletaveis, reconstruirGrade } from './arena.js';
import { Torre } from './tower.js';
import { DiretorDeOndas } from './waves.js';
import { atualizarStatus, aplicarDano, danoEmArea } from './combat.js';
import { atualizarInimigos, impactoPadrao, dividirInimigo, RAIO_TORRE } from './enemies.js';
import { soltarOuro, atualizarColetaveis, ganharOuro, gastarOuro, ganharMoeda, gastarMoeda, ganharXP, recompensaDeOnda } from './economy.js';
import { usarHabilidade, atualizarHabilidades, autoUsarHabilidades, desbloquearPorProgresso, estadoHabilidade } from './abilities.js';

import * as balance from '../data/balance.js';
import { UPGRADES, UPGRADE_POR_ID, custoUpgrade, custoLote, maxCompravel, upgradeDisponivel } from '../data/upgrades.js';
import { TALENTOS, TALENTO_POR_ID, custoTalento, talentoLiberado } from '../data/talents.js';
import { ARVORES, NO_POR_ID, custoNo, maxCompravelNo, podeAscender, podeColapsar, podeTranscender } from '../data/prestige.js';
import { PRESTIGIO, COMBATE, OFFLINE, LOOT, RARIDADES, RARIDADE_POR_ID } from '../data/balance.js';
import { HABILIDADE_POR_ID, custoMelhoria, NIVEL_MAX_HABILIDADE } from '../data/abilities.js';

export class Jogo {
  constructor() {
    this.state = createInitialState();
    this.stats = new StatEngine();
    this.especiais = ESPECIAIS_PADRAO();
    this.passivas = Object.create(null);
    this.balance = balance;
    this.modificadores = { hpInimigo: 1, velocidadeInimigo: 1, ouro: 1, danoTorre: 1, xp: 1 };

    this.torre = new Torre(this);
    this.diretor = new DiretorDeOndas(this);

    this.fx = null;             // ligado pelo renderizador
    this.audio = null;          // ligado pelo motor de áudio
    this.tempoCongelado = 0;
    this.invulneravel = 0;
    this.filaMisseis = null;
    this.buracoNegro = null;
    this.parasitas = 0;
    this.coletaInstantanea = false;
    this.statsSujos = true;
    this.tempoAutoCompra = 0;
    this.tempoDesdeAutoSave = 0;
    this.fenixUsada = false;
    this.iniciado = false;
    this.pausadoPorModal = false;
  }

  /* =============================================================== boot */
  async iniciar() {
    await carregarConteudo();
    const salvo = Storage.load();
    if (salvo) this.carregarEstado(salvo);
    else {
      this.state.criadoEm = Date.now();
      this.state.ultimoTick = Date.now();
    }
    this.marcarStatsSujos();
    this.recalcularSeNecessario();
    desbloquearPorProgresso(this.state);
    this.sincronizarTorre(true);
    this.diretor.iniciarOnda(this.state.onda);
    this.iniciado = true;
    bus.emit(EV.READY, {});
    return this;
  }

  carregarEstado(salvo) {
    const base = createInitialState();
    // mescla defensiva: campos novos entram, campos velhos somem
    this.state = mesclarEstado(base, salvo);
    if (!this.state.criadoEm) this.state.criadoEm = Date.now();
    bus.emit(EV.LOAD, { state: this.state });
  }

  /* ============================================================ atributos */
  marcarStatsSujos() { this.statsSujos = true; }

  recalcularSeNecessario() {
    if (!this.statsSujos) return;
    const r = recalcular(this.state, this.stats);
    this.especiais = r.especiais;
    this.passivas = r.passivas;
    this.pontosConquista = r.pontosConquista;
    this.statsSujos = false;
    this.sincronizarTorre(false);
  }

  /** Ajusta vida/escudo quando os máximos mudam. */
  sincronizarTorre(cheia) {
    const s = this.state;
    const novoMax = this.stats.getD('vidaMax').toNumber();
    const escMax = this.stats.getD('escudoMax').toNumber();
    if (!isFinite(novoMax)) return;
    const fracAntes = s.torre.vidaMax > 0 ? s.torre.vida / s.torre.vidaMax : 1;
    s.torre.vidaMax = novoMax;
    s.torre.escudoMax = escMax;
    s.torre.vida = cheia ? novoMax : Math.min(novoMax, Math.max(s.torre.vida, novoMax * Math.min(1, fracAntes)));
    if (cheia) s.torre.escudo = escMax;
    s.torre.escudo = Math.min(s.torre.escudo, escMax);
    if (s.torre.vida <= 0 && cheia) s.torre.vida = novoMax;
  }

  /* ================================================================ loop */
  atualizar(dt) {
    const s = this.state;
    if (this.pausadoPorModal) return;

    this.recalcularSeNecessario();

    s.stats.tempoTotal += dt;
    s.stats.tempoSessao += dt;
    s.ultimoTick = Date.now();

    // combo esfria
    if (s.combo.atual > 0) {
      s.combo.timer -= dt;
      if (s.combo.timer <= 0) {
        s.combo.atual = 0;
        bus.emit(EV.COMBO_BREAK, {});
        if (this.passivas.sede_de_sangue) this.marcarStatsSujos();
      }
    }

    // buffs temporários
    if (s.buffs.length) {
      let mudou = false;
      for (let i = s.buffs.length - 1; i >= 0; i--) {
        s.buffs[i].restante -= dt;
        if (s.buffs[i].restante <= 0) { s.buffs.splice(i, 1); mudou = true; }
      }
      if (mudou) this.marcarStatsSujos();
    }

    reconstruirGrade();
    atualizarStatus(dt, this);
    atualizarInimigos(dt, this);
    this.torre.atualizar(dt);
    this.torre.atualizarProjeteis(dt);
    atualizarColetaveis(dt, this);
    atualizarHabilidades(dt, this);
    this.diretor.atualizar(dt);

    this.parasitas = 0;
    for (const e of inimigos.active) if (e.grudado) this.parasitas++;

    // automação
    if (s.auto.comprarUpgrades && this.especiais.desbloqueios.has('autoCompra')) {
      this.tempoAutoCompra -= dt;
      if (this.tempoAutoCompra <= 0) {
        this.tempoAutoCompra = balance.AUTO.INTERVALO_AUTOCOMPRA;
        this.autoComprar();
      }
    }
    if (s.auto.usarHabilidades && this.especiais.desbloqueios.has('autoHabilidade')) {
      autoUsarHabilidades(this);
    }
    if (s.prestigio.autoAscender && this.especiais.desbloqueios.has('autoAscensao')) {
      if (s.ondaMaxima >= s.prestigio.autoAscenderOnda && podeAscender(s)) this.ascender(true);
    }

    // amostra para o gráfico de progresso (a cada 30s de jogo)
    this._amostra = (this._amostra || 0) + dt;
    if (this._amostra >= 30) {
      this._amostra = 0;
      s.stats.historicoOndas.push({ t: Math.round(s.stats.tempoTotal), onda: s.onda });
      if (s.stats.historicoOndas.length > 720) s.stats.historicoOndas.shift();
    }

    bus.emit(EV.TICK, { dt });
  }

  /* ========================================================== callbacks */
  soltarOuro(e, valor) {
    let v = valor;
    if (this.state.buffs.some((b) => b.id === 'hab_chuva_ouro_ganhoOuro')) { /* já aplicado via stats */ }
    soltarOuro(e, v, this);
  }
  ganharOuro(v, info) { ganharOuro(v, this, info); if (this.passivas.avareza) ganharXP(D.of(v).mulN(0.05), this); }
  gastarOuro(v) { return gastarOuro(v, this); }
  ganharXP(v) { ganharXP(v, this); }
  ganharMoeda(k, v, info) { ganharMoeda(k, v, this, info); }
  gastarMoeda(k, v) { return gastarMoeda(k, v, this); }
  recompensaDeOnda(onda) {
    recompensaDeOnda(onda, this);
    this.fenixUsada = false;
    if (this.passivas.imortal_pos_onda) this.invulneravel = Math.max(this.invulneravel, 2);
    bus.emit(EV.UI_REFRESH, {});
  }
  dividirInimigo(e) { dividirInimigo(e, this); }
  impactoNaTorre(e) { impactoPadrao(e, this); }

  danoNaTorre(quantidade, fonte, opts = {}) {
    if (this.invulneravel > 0) return 0;
    return this.torre.levarDano(quantidade, fonte, opts);
  }
  curarTorre(v) {
    const s = this.state;
    s.torre.vida = Math.min(s.torre.vidaMax, s.torre.vida + v);
  }
  reviverTorre() {
    const s = this.state;
    s.torre.viva = true;
    s.torre.vida = s.torre.vidaMax;
    s.torre.escudo = s.torre.escudoMax;
    this.invulneravel = 2.5;
    limparInimigosDaTela();
    this.diretor.reiniciarOnda(COMBATE.PENALIDADE_MORTE);
  }
  projetilInimigo(e) {
    const p = projeteis.get();
    const ang = Math.atan2(ARENA.cy - e.y, ARENA.cx - e.x);
    p.ativo = true;
    p.x = e.x; p.y = e.y;
    p.vel = 220;
    p.ang = ang;
    p.vx = Math.cos(ang) * p.vel;
    p.vy = Math.sin(ang) * p.vel;
    p.r = 5;
    p.vida = 6;
    p.cor = '#fb7185';
    p.tipo = 'acido';
    p.origem = 'inimigo';
    p.danoTorre = this.state.torre.vidaMax * 0.02;
  }

  adicionarBuff(b) {
    const s = this.state;
    const existente = s.buffs.find((x) => x.id === b.id);
    if (existente) { existente.restante = Math.max(existente.restante, b.restante); existente.valor = b.valor; }
    else s.buffs.push(b);
    this.marcarStatsSujos();
  }

  tremor(amp, dur) { bus.emit(EV.SHAKE, { amp, dur }); }
  hitstop(ms) { bus.emit(EV.HITSTOP, { ms }); }
  slowmo(escala, ms) { bus.emit(EV.SLOWMO, { escala, ms }); }

  /* ============================================================== ações */
  comprarUpgrade(id, qtd = 1) {
    const s = this.state;
    const def = UPGRADE_POR_ID[id];
    if (!def || !upgradeDisponivel(def, s)) return 0;
    const nivel = s.upgrades[id] || 0;
    if (nivel >= def.max) return 0;

    let n = qtd === 'max' ? maxCompravel(def, nivel, s.moedas.ouro) : Math.min(qtd, def.max - nivel);
    if (n <= 0) return 0;
    const custo = custoLote(def, nivel, n);
    if (!this.gastarOuro(custo)) return 0;

    s.upgrades[id] = nivel + n;
    this.marcarStatsSujos();
    this.recalcularSeNecessario();
    if (def.efeito.some((e) => e.stat === 'vidaMax')) this.sincronizarTorre(false);
    bus.emit(EV.UPGRADE_BUY, { id, def, qtd: n, nivel: s.upgrades[id], custo });
    if (s.upgrades[id] >= def.max) bus.emit(EV.UPGRADE_MAX, { id, def });
    return n;
  }

  autoComprar() {
    const s = this.state;
    const modo = s.auto.comprarUpgradesModo;
    let candidatos = UPGRADES.filter((d) => upgradeDisponivel(d, s) && (s.upgrades[d.id] || 0) < d.max);
    if (!candidatos.length) return;
    if (modo === 'prioridade') candidatos = candidatos.filter((d) => d.destaque).concat(candidatos.filter((d) => !d.destaque));
    let melhor = null, melhorCusto = null;
    for (const d of candidatos) {
      const c = custoUpgrade(d, s.upgrades[d.id] || 0);
      if (c.lte(s.moedas.ouro) && (!melhorCusto || c.lt(melhorCusto))) { melhor = d; melhorCusto = c; }
    }
    if (melhor) this.comprarUpgrade(melhor.id, 1);
  }

  comprarTalento(id) {
    const s = this.state;
    const def = TALENTO_POR_ID[id];
    if (!def || !talentoLiberado(def, s)) return false;
    const nivel = s.talentos[id] || 0;
    if (nivel >= def.max) return false;
    const custo = custoTalento(def, nivel);
    if (s.pontosTalento < custo) return false;
    s.pontosTalento -= custo;
    s.pontosTalentoGastos += custo;
    s.talentos[id] = nivel + 1;
    this.marcarStatsSujos();
    this.recalcularSeNecessario();
    this.sincronizarTorre(false);
    bus.emit(EV.TALENT_BUY, { id, def, nivel: s.talentos[id] });
    return true;
  }

  redistribuirTalentos(custoGemas = 50) {
    const s = this.state;
    if (!this.gastarMoeda('gemas', custoGemas)) return false;
    s.pontosTalento += s.pontosTalentoGastos;
    s.pontosTalentoGastos = 0;
    s.talentos = {};
    this.marcarStatsSujos();
    this.recalcularSeNecessario();
    return true;
  }

  comprarNoPrestigio(id, qtd = 1) {
    const s = this.state;
    const def = NO_POR_ID[id];
    if (!def) return 0;
    const camada = ARVORES.fragmentos.includes(def) ? 'fragmentos' : (ARVORES.nucleos.includes(def) ? 'nucleos' : 'eter');
    const tabela = camada === 'fragmentos' ? s.prestigio.arvoreFragmentos
      : camada === 'nucleos' ? s.prestigio.arvoreNucleos : s.prestigio.arvoreEter;
    const nivel = tabela[id] || 0;
    if (nivel >= def.max) return 0;
    const n = qtd === 'max' ? maxCompravelNo(def, nivel, s.moedas[camada]) : Math.min(qtd, def.max - nivel);
    if (n <= 0) return 0;
    const custo = D.geometricSum(def.base, def.cresc, nivel, n);
    if (!this.gastarMoeda(camada, custo)) return 0;
    tabela[id] = nivel + n;
    this.marcarStatsSujos();
    this.recalcularSeNecessario();
    this.sincronizarTorre(false);
    bus.emit(EV.UPGRADE_BUY, { id, def, qtd: n, prestigio: true, camada });
    return n;
  }

  usarHabilidade(id) { return usarHabilidade(id, this); }

  melhorarHabilidade(id) {
    const s = this.state;
    const def = HABILIDADE_POR_ID[id];
    const h = estadoHabilidade(s, id);
    if (!def || !h.desbloqueada || h.nivel >= NIVEL_MAX_HABILIDADE) return false;
    const custo = custoMelhoria(def, h.nivel);
    if (!this.gastarMoeda('gemas', custo)) return false;
    h.nivel++;
    bus.emit(EV.UI_REFRESH, {});
    return true;
  }

  definirModoMira(modo) { this.torre.modoMira = modo; }

  alternarFarm(onda) {
    const s = this.state;
    if (!this.especiais.desbloqueios.has('modoFarm')) return false;
    s.modoFarm = !s.modoFarm;
    if (s.modoFarm) s.ondaFarm = onda ?? s.onda;
    return s.modoFarm;
  }

  /* =========================================================== prestígio */
  previewAscensao() {
    const s = this.state;
    return PRESTIGIO.fragmentos(s.ondaMaxima, this.stats.getN('ganhoFrag'));
  }
  previewSingularidade() {
    const s = this.state;
    return PRESTIGIO.nucleos(s.ondaMaximaGlobal, s.prestigio.ascensoes, this.especiais.ganhoNucleos);
  }
  previewTranscendencia() {
    const s = this.state;
    return PRESTIGIO.eter(s.ondaMaximaGlobal, s.prestigio.singularidades);
  }

  ascender(auto = false) {
    const s = this.state;
    if (!podeAscender(s)) return false;
    const ganho = this.previewAscensao();
    s.moedas.fragmentos = s.moedas.fragmentos.add(ganho);
    s.prestigio.ascensoes++;
    s.prestigio.ascensaoUltimaOnda = s.ondaMaxima;
    s.prestigio.melhorAscensao = Math.max(s.prestigio.melhorAscensao, s.ondaMaxima);
    this._resetarRun();
    bus.emit(EV.PRESTIGE, { camada: 'ascensao', ganho, auto });
    return true;
  }

  colapsar() {
    const s = this.state;
    if (!podeColapsar(s)) return false;
    const ganho = this.previewSingularidade();
    s.moedas.nucleos = s.moedas.nucleos.add(ganho);
    s.prestigio.singularidades++;
    s.moedas.fragmentos = D.of(0);
    s.prestigio.arvoreFragmentos = {};
    s.prestigio.ascensoes = 0;
    s.talentos = {};
    s.pontosTalentoGastos = 0;
    this._resetarRun();
    bus.emit(EV.PRESTIGE, { camada: 'singularidade', ganho });
    return true;
  }

  transcender() {
    const s = this.state;
    if (!podeTranscender(s)) return false;
    const ganho = this.previewTranscendencia();
    const conquistas = s.conquistas;
    const codex = s.codex;
    const eter = s.moedas.eter.add(ganho);
    const arvoreEter = s.prestigio.arvoreEter;
    const transc = s.prestigio.transcendencias + 1;
    const statsAntigos = s.stats;
    const ondaGlobal = s.ondaMaximaGlobal;

    this.state = createInitialState();
    const n = this.state;
    n.criadoEm = s.criadoEm;
    n.moedas.eter = eter;
    n.prestigio.arvoreEter = arvoreEter;
    n.prestigio.transcendencias = transc;
    n.conquistas = conquistas;
    n.codex = codex;
    n.stats = statsAntigos;
    n.ondaMaximaGlobal = ondaGlobal;
    this._resetarRun();
    bus.emit(EV.PRESTIGE, { camada: 'transcendencia', ganho });
    return true;
  }

  _resetarRun() {
    const s = this.state;
    s.moedas.ouro = D.of(0);
    s.upgrades = {};
    s.nivel = 1;
    s.xp = D.of(0);
    s.pontosTalento = s.pontosTalentoGastos + (this.especiais.pontosTalento || 0);
    s.buffs = [];
    s.combo = { atual: 0, melhor: 0, timer: 0 };
    s.ondaMaxima = 1;
    s.modoFarm = false;
    limparArena();
    this.torre = new Torre(this);
    this.diretor = new DiretorDeOndas(this);
    this.marcarStatsSujos();
    this.recalcularSeNecessario();

    const inicio = Math.max(1, 1 + Math.floor(this.especiais.ondaInicial || 0));
    s.onda = inicio;
    s.ondaMaxima = inicio;
    if (inicio > s.ondaMaximaGlobal) s.ondaMaximaGlobal = inicio;
    s.pontosTalento = Math.max(s.pontosTalento, this.especiais.pontosTalento || 0);
    this.sincronizarTorre(true);
    this.diretor.iniciarOnda(inicio);
    this.fenixUsada = false;
    this.invulneravel = 3;
    bus.emit(EV.UI_REFRESH, { full: true });
  }

  /* ============================================================== save */
  salvar() {
    this.state.ultimoSalvo = Date.now();
    this.state.ultimoTick = Date.now();
    return Storage.save(this.state);
  }
  exportar() { return Storage.exportString(this.state); }
  importar(texto) {
    const novo = Storage.importString(texto);
    this.carregarEstado(novo);
    this.marcarStatsSujos();
    this.recalcularSeNecessario();
    limparArena();
    this.torre = new Torre(this);
    this.diretor = new DiretorDeOndas(this);
    this.sincronizarTorre(true);
    this.diretor.iniciarOnda(this.state.onda);
    bus.emit(EV.UI_REFRESH, { full: true });
    return true;
  }
  apagarTudo() {
    Storage.wipe();
    this.state = createInitialState();
    this.state.criadoEm = Date.now();
    this.marcarStatsSujos();
    this.recalcularSeNecessario();
    limparArena();
    this.torre = new Torre(this);
    this.diretor = new DiretorDeOndas(this);
    this.sincronizarTorre(true);
    this.diretor.iniciarOnda(1);
    bus.emit(EV.UI_REFRESH, { full: true });
  }
}

function limparInimigosDaTela() {
  for (let i = inimigos.active.length - 1; i >= 0; i--) inimigos.releaseAt(i);
  for (let i = projeteis.active.length - 1; i >= 0; i--) projeteis.releaseAt(i);
}

/** Mescla o save no estado padrão, preservando estruturas conhecidas. */
function mesclarEstado(base, salvo) {
  const out = base;
  for (const k of Object.keys(base)) {
    const v = salvo[k];
    if (v === undefined || v === null) continue;
    const b = base[k];
    if (b instanceof D) { out[k] = v instanceof D ? v : D.of(v); }
    else if (Array.isArray(b)) out[k] = Array.isArray(v) ? v : b;
    else if (b && typeof b === 'object' && !(b instanceof Set) && !(b instanceof Map)) {
      out[k] = mesclarEstado(b, typeof v === 'object' && v ? v : {});
    } else if (typeof b === typeof v || b === null) out[k] = v;
    else out[k] = v;
  }
  // chaves extras (ex.: upgrades novos) devem sobreviver
  for (const k of Object.keys(salvo)) if (!(k in out)) out[k] = salvo[k];
  return out;
}

export const jogo = new Jogo();
