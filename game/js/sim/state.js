/**
 * state.js — O estado canônico do jogo (serializável).
 *
 * Regras:
 *  - Tudo que precisa persistir mora aqui.
 *  - Moedas e valores gigantes são `D` (decimal.js).
 *  - Nada de funções, DOM ou referências circulares.
 *  - Entidades voláteis (inimigos, projéteis, partículas) NÃO ficam aqui.
 */
import { D } from '../core/decimal.js';
import { SAVE_VERSION } from '../core/storage.js';

export const SLOTS_CARTAS_BASE = 3;

export function createInitialState() {
  return {
    version: SAVE_VERSION,
    criadoEm: 0,            // preenchido no boot (Date.now)
    ultimoSalvo: 0,
    ultimoTick: 0,

    /* ------------------------------------------------------------ moedas */
    moedas: {
      ouro: D.of(0),
      gemas: D.of(0),
      fragmentos: D.of(0),      // prestígio 1 — Ascensão
      nucleos: D.of(0),         // prestígio 2 — Singularidade
      eter: D.of(0),            // prestígio 3 — Transcendência
      poeira: D.of(0),          // reciclagem de cartas/relíquias
    },

    /* --------------------------------------------------------- progresso */
    onda: 1,
    ondaMaxima: 1,
    ondaMaximaGlobal: 1,        // sobrevive a todos os prestígios
    inimigosMortosOnda: 0,
    inimigosNecessarios: 10,
    emChefe: false,
    tempoNaOnda: 0,
    modoFarm: false,            // trava a onda para farmar
    ondaFarm: 1,

    nivel: 1,
    xp: D.of(0),
    pontosTalento: 0,
    pontosTalentoGastos: 0,

    /* -------------------------------------------------------------- torre */
    torre: {
      vida: 100,
      vidaMax: 100,
      escudo: 0,
      escudoMax: 0,
      viva: true,
      tempoMorta: 0,
    },

    /* ------------------------------------------------------------ upgrades
       { [id]: nivel }  — o custo é derivado, não guardado. */
    upgrades: {},

    /* ------------------------------------------------------------ talentos
       { [id]: nivel } */
    talentos: {},

    /* -------------------------------------------------------------- cartas
       inventario: [{ id, raridade, nivel, rolagens: {stat: valor}, uid }]
       equipadas: [uid|null, ...] */
    cartas: { inventario: [], equipadas: [null, null, null], slots: SLOTS_CARTAS_BASE, novas: [] },

    /* ------------------------------------------------------------ relíquias
       { [id]: { nivel } } — permanentes, sobrevivem à Ascensão */
    relicas: {},

    /* --------------------------------------------------------- habilidades
       { [id]: { desbloqueada, nivel, cooldownRestante, ativaAte } } */
    habilidades: {},

    /* -------------------------------------------------------------- meta */
    conquistas: {},             // { [id]: timestamp }
    conquistasVistas: [],
    codex: { inimigos: {}, chefes: {}, lore: {} },  // { [id]: contagem }
    missoes: { diarias: [], semanais: [], ultimoReset: 0, ultimoResetSemanal: 0, sequenciaDiaria: 0 },
    desafios: { ativo: null, completos: {}, tentativas: {} },
    eventos: { ativo: null, historico: [], proximoEm: 180 },
    temporada: { id: 0, xp: 0, nivel: 0, recompensasColetadas: [] },

    /* -------------------------------------------------------- prestígios */
    prestigio: {
      ascensoes: 0,
      ascensaoUltimaOnda: 0,
      melhorAscensao: 0,
      singularidades: 0,
      transcendencias: 0,
      arvoreFragmentos: {},     // upgrades comprados com fragmentos
      arvoreNucleos: {},
      arvoreEter: {},
      autoAscender: false,
      autoAscenderOnda: 0,
    },

    /* ----------------------------------------------------------- eras */
    era: 0,
    erasVistas: [0],

    /* -------------------------------------------------------- automação */
    auto: {
      comprarUpgrades: false,
      comprarUpgradesModo: 'barato',   // 'barato' | 'prioridade'
      usarHabilidades: false,
      equiparCartas: false,
      reciclarLixo: false,
      prosseguirOnda: true,
      velocidade: 1,                   // turbo comprável
    },

    /* ------------------------------------------------------ estatísticas */
    stats: {
      tempoTotal: 0,
      tempoSessao: 0,
      tempoOffline: 0,
      inimigosMortos: 0,
      chefesMortos: 0,
      danoTotal: D.of(0),
      danoMaximo: D.of(0),
      ouroTotal: D.of(0),
      ouroGasto: D.of(0),
      criticos: 0,
      tiros: 0,
      mortes: 0,
      comboMaximo: 0,
      ondasCompletas: 0,
      cartasObtidas: 0,
      lendariosObtidos: 0,
      habilidadesUsadas: 0,
      douradosAbatidos: 0,
      porInimigo: {},
      historicoOndas: [],       // amostras {t, onda} para o gráfico
    },

    /* ------------------------------------------------------- desbloqueios */
    desbloqueios: {},           // { [chave]: true }
    tutorial: { passo: 0, completo: false, dicasVistas: [] },
    novidades: {},              // badges de "novo" por painel

    /* ---------------------------------------------------------- efêmero
       (persistido mas recalculado/limpo no boot) */
    buffs: [],                  // [{ id, stat, tipo, valor, restante, fonte }]
    combo: { atual: 0, melhor: 0, timer: 0 },
    pity: { lendaria: 0, dourado: 0 },
    rngSeed: 0,
  };
}

/** Configurações — persistidas separadamente, sobrevivem a reset de jogo. */
export function createDefaultSettings() {
  return {
    locale: 'pt',
    notacao: 'mista',
    decimais: 2,
    volumeMaster: 0.7,
    volumeSfx: 0.8,
    volumeMusica: 0.45,
    mudo: false,
    qualidade: 'alta',            // 'baixa' | 'media' | 'alta' | 'ultra'
    particulas: 1,                // multiplicador 0..1.5
    tremor: 1,                    // screen shake 0..1.5
    flashes: true,
    numerosDeDano: 'todos',       // 'todos' | 'criticos' | 'nenhum'
    movimentoReduzido: false,
    daltonismo: 'nenhum',         // 'nenhum'|'protanopia'|'deuteranopia'|'tritanopia'
    altoContraste: false,
    fonteGrande: false,
    mostrarFPS: false,
    autosaveSegundos: 20,
    confirmarPrestigio: true,
    vibracao: true,
    tema: 'escuro',
    dicasFlutuantes: true,
    modoRapidoUI: false,
  };
}
