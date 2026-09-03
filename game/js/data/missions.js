/**
 * missions.js — MISSÕES (diárias e semanais) e a TEMPORADA (passe de recompensas).
 *
 * O jogo sorteia um punhado de MODELOS deste arquivo a cada reset e os instancia
 * no save (state.missoes.diarias / .semanais). Nada aqui guarda progresso: são
 * apenas moldes. O contador de cada missão é o DELTA do período — uma missão de
 * "matar 250 inimigos" conta a partir do reset, não desde o início dos tempos.
 *
 * ---------------------------------------------------------------- CAMPOS
 *   id            chave única (prefixo `d_` diária, `s_` semanal)
 *   tipo          'diaria' | 'semanal'
 *   meta          { tipo, chave?, valor }  — `tipo` vem das condições
 *                 rastreáveis do contrato; `chave` só existe em
 *                 upgradeNivel / talentoNivel / inimigoTipo.
 *   escalaComOnda a meta é multiplicada em tempo de execução pelo progresso
 *                 do jogador (ver `metaEscalada`): metas de contagem sobem
 *                 devagar, metas de ouro/dano acompanham a curva exponencial.
 *   semMorrer     true → o progresso ZERA se a torre cair. É a única
 *                 restrição extra que uma missão pode ter.
 *   absoluto      true → conta o total histórico do save, não o delta do
 *                 período (usado em metas de prestígio de longo prazo).
 *   requer        { onda? , ascensoes? , singularidades? } — trava o modelo
 *                 no sorteio até o jogador ter contexto para entendê-lo.
 *   recompensa    { tipo: 'gemas'|'fragmentos'|'ouro'|'pontosTalento'|'stat',
 *                   valor, stat?, tipoEfeito? }
 *                 Em recompensas de `ouro`, `valor` é medido em ONDAS de
 *                 rendimento atual (valor 12 ≈ o ouro de 12 ondas), porque
 *                 um número fixo viraria pó na onda 200.
 *   xpTemporada   XP do passe. Diárias: 30–90. Semanais: 250–900.
 *
 * TOM: o Comando trata a defesa da última torre da galáxia como uma escala de
 * trabalho. As missões são ordens de serviço. Cumpra ou explique.
 */

/* ===================================================== MISSÕES DIÁRIAS ==== */
/** 24 modelos. O jogo sorteia `TEMPORADA.ativasDiarias` por dia, sem repetir. */
export const MISSOES_DIARIAS = [
  { id: 'd_faxina', tipo: 'diaria', icone: '🧹',
    nome: 'Faxina do Perímetro', nomeEn: 'Perimeter Sweep',
    desc: 'Abata {v} inimigos. O chão não se limpa sozinho — ainda.',
    descEn: 'Kill {v} enemies. The ground does not clean itself. Yet.',
    meta: { tipo: 'inimigosMortos', valor: 250 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 12 }, xpTemporada: 40 },

  { id: 'd_cota_grunhidos', tipo: 'diaria', icone: '📋',
    nome: 'Cota de Grunhidos', nomeEn: 'Grunt Quota',
    desc: 'Elimine {v} Grunhidos. O relatório exige o número exato, não a sua opinião.',
    descEn: 'Eliminate {v} Grunts. The report wants the number, not your opinion.',
    meta: { tipo: 'inimigoTipo', chave: 'grunhido', valor: 150 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 10 }, xpTemporada: 35 },

  { id: 'd_multa_velocidade', tipo: 'diaria', icone: '🚦',
    nome: 'Multa por Excesso de Velocidade', nomeEn: 'Speeding Fine',
    desc: 'Pare {v} Corredores. Definitivamente.',
    descEn: 'Stop {v} Runners. Permanently.',
    meta: { tipo: 'inimigoTipo', chave: 'corredor', valor: 70 }, escalaComOnda: true,
    requer: { onda: 3 },
    recompensa: { tipo: 'gemas', valor: 14 }, xpTemporada: 45 },

  { id: 'd_desmonte', tipo: 'diaria', icone: '🔧',
    nome: 'Desmonte Autorizado', nomeEn: 'Authorized Teardown',
    desc: 'Desmonte {v} Brutos. As placas deles são recicláveis; eles, não.',
    descEn: 'Take apart {v} Brutes. Their plating is recyclable. They are not.',
    meta: { tipo: 'inimigoTipo', chave: 'bruto', valor: 45 }, escalaComOnda: true,
    requer: { onda: 6 },
    recompensa: { tipo: 'gemas', valor: 16 }, xpTemporada: 50 },

  { id: 'd_pragas', tipo: 'diaria', icone: '🐜',
    nome: 'Controle de Pragas', nomeEn: 'Pest Control',
    desc: 'Extermine {v} Enxames. Sim, eles voltam. Extermine mesmo assim.',
    descEn: 'Exterminate {v} Swarmlings. Yes, they come back. Do it anyway.',
    meta: { tipo: 'inimigoTipo', chave: 'enxame', valor: 220 }, escalaComOnda: true,
    requer: { onda: 4 },
    recompensa: { tipo: 'gemas', valor: 14 }, xpTemporada: 45 },

  { id: 'd_espaco_aereo', tipo: 'diaria', icone: '🛩️',
    nome: 'Espaço Aéreo Restrito', nomeEn: 'Restricted Airspace',
    desc: 'Derrube {v} Voadores. Ninguém autorizou aquele plano de voo.',
    descEn: 'Down {v} Skimmers. Nobody filed that flight plan.',
    meta: { tipo: 'inimigoTipo', chave: 'voador', valor: 50 }, escalaComOnda: true,
    requer: { onda: 9 },
    recompensa: { tipo: 'gemas', valor: 18 }, xpTemporada: 55 },

  { id: 'd_exorcismo', tipo: 'diaria', icone: '👻',
    nome: 'Exorcismo de Baixo Orçamento', nomeEn: 'Budget Exorcism',
    desc: 'Dissolva {v} Espectros. Sem ritual, sem incenso: só cadência.',
    descEn: 'Dissolve {v} Wraiths. No ritual, no incense, just fire rate.',
    meta: { tipo: 'inimigoTipo', chave: 'espectro', valor: 30 }, escalaComOnda: true,
    requer: { onda: 18 },
    recompensa: { tipo: 'gemas', valor: 22 }, xpTemporada: 60 },

  { id: 'd_plano_saude', tipo: 'diaria', icone: '💉',
    nome: 'Corte no Plano de Saúde', nomeEn: 'Healthcare Cuts',
    desc: 'Silencie {v} Curandeiros antes que desfaçam o seu trabalho.',
    descEn: 'Silence {v} Menders before they undo your work.',
    meta: { tipo: 'inimigoTipo', chave: 'curandeiro', valor: 18 }, escalaComOnda: true,
    requer: { onda: 22 },
    recompensa: { tipo: 'gemas', valor: 24 }, xpTemporada: 65 },

  { id: 'd_diretoria', tipo: 'diaria', icone: '👑',
    nome: 'Reunião de Diretoria', nomeEn: 'Board Meeting',
    desc: 'Encerre {v} chefes. Cada um insistia que era insubstituível.',
    descEn: 'Adjourn {v} bosses. Each insisted they were irreplaceable.',
    meta: { tipo: 'chefesMortos', valor: 5 },
    requer: { onda: 10 },
    recompensa: { tipo: 'gemas', valor: 30 }, xpTemporada: 70 },

  { id: 'd_imposto_brilho', tipo: 'diaria', icone: '✨',
    nome: 'Imposto sobre o Brilho', nomeEn: 'Glitter Tax',
    desc: 'Confisque {v} inimigos dourados. Riqueza ostensiva é uma escolha.',
    descEn: 'Seize {v} golden enemies. Flaunting wealth is a choice.',
    meta: { tipo: 'douradosAbatidos', valor: 10 },
    requer: { onda: 5 },
    recompensa: { tipo: 'gemas', valor: 28 }, xpTemporada: 65 },

  { id: 'd_ouro_parado', tipo: 'diaria', icone: '💸',
    nome: 'Ouro Parado É Ouro Morto', nomeEn: 'Idle Gold Is Dead Gold',
    desc: 'Gaste {v} de ouro em melhorias. O cofre não atira.',
    descEn: 'Spend {v} gold on upgrades. The vault does not shoot.',
    meta: { tipo: 'ouroGasto', valor: 3000 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 15 }, xpTemporada: 45 },

  { id: 'd_fluxo_caixa', tipo: 'diaria', icone: '🪙',
    nome: 'Fluxo de Caixa', nomeEn: 'Cash Flow',
    desc: 'Arrecade {v} de ouro. O Enxame é, tecnicamente, sua folha de pagamento.',
    descEn: 'Collect {v} gold. The Swarm is, technically, your payroll.',
    meta: { tipo: 'ouroTotal', valor: 5000 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 15 }, xpTemporada: 45 },

  { id: 'd_turno_cumprido', tipo: 'diaria', icone: '📆',
    nome: 'Turno Cumprido', nomeEn: 'Shift Completed',
    desc: 'Complete {v} ondas. Nenhuma delas será a última.',
    descEn: 'Complete {v} waves. None of them will be the last.',
    meta: { tipo: 'ondasCompletas', valor: 40 },
    recompensa: { tipo: 'gemas', valor: 20 }, xpTemporada: 50 },

  { id: 'd_ficha_limpa', tipo: 'diaria', icone: '🧾',
    nome: 'Ficha Limpa', nomeEn: 'Clean Record',
    desc: 'Complete {v} ondas seguidas sem a torre cair. Uma queda e a contagem recomeça.',
    descEn: 'Clear {v} waves in a row without the tower falling. One fall and it resets.',
    meta: { tipo: 'ondasCompletas', valor: 15 }, semMorrer: true,
    recompensa: { tipo: 'fragmentos', valor: 8 }, xpTemporada: 75 },

  { id: 'd_linha_montagem', tipo: 'diaria', icone: '⛓️',
    nome: 'Linha de Montagem', nomeEn: 'Assembly Line',
    desc: 'Atinja um combo de {v}. Sem pausa, sem hesitação, sem almoço.',
    descEn: 'Reach a {v} combo. No pause, no hesitation, no lunch.',
    meta: { tipo: 'comboMaximo', valor: 90 },
    requer: { onda: 8 },
    recompensa: { tipo: 'gemas', valor: 25 }, xpTemporada: 60 },

  { id: 'd_dedo_botao', tipo: 'diaria', icone: '🔘',
    nome: 'Dedo no Botão', nomeEn: 'Finger on the Button',
    desc: 'Use habilidades {v} vezes. Elas não foram instaladas de enfeite.',
    descEn: 'Use abilities {v} times. They were not installed for decoration.',
    meta: { tipo: 'habilidadesUsadas', valor: 12 },
    recompensa: { tipo: 'gemas', valor: 18 }, xpTemporada: 50 },

  { id: 'd_anatomia', tipo: 'diaria', icone: '💥',
    nome: 'Anatomia Aplicada', nomeEn: 'Applied Anatomy',
    desc: 'Cause {v} acertos críticos. Todo monstro tem um ponto que pede desculpas.',
    descEn: 'Land {v} critical hits. Every monster has a spot that apologizes.',
    meta: { tipo: 'criticos', valor: 400 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 20 }, xpTemporada: 55 },

  { id: 'd_municao', tipo: 'diaria', icone: '☄️',
    nome: 'Relatório de Munição', nomeEn: 'Ammunition Report',
    desc: 'Dispare {v} projéteis. O almoxarifado quer números, não heroísmo.',
    descEn: 'Fire {v} projectiles. Supply wants figures, not heroism.',
    meta: { tipo: 'tiros', valor: 4000 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 12 }, xpTemporada: 35 },

  { id: 'd_catador', tipo: 'diaria', icone: '🃏',
    nome: 'Catador de Turno', nomeEn: 'Shift Scavenger',
    desc: 'Recolha {v} cartas do campo. Alguém morreu segurando cada uma delas.',
    descEn: 'Recover {v} cards from the field. Someone died holding each one.',
    meta: { tipo: 'cartas', valor: 3 },
    requer: { onda: 10 },
    recompensa: { tipo: 'gemas', valor: 26 }, xpTemporada: 60 },

  { id: 'd_curva_aprendizado', tipo: 'diaria', icone: '📘',
    nome: 'Curva de Aprendizado', nomeEn: 'Learning Curve',
    desc: 'Suba {v} níveis de torre. A curva é gentil hoje; amanhã ela cobra.',
    descEn: 'Gain {v} tower levels. The curve is gentle today. Tomorrow it bills you.',
    meta: { tipo: 'nivel', valor: 3 },
    recompensa: { tipo: 'pontosTalento', valor: 1 }, xpTemporada: 50 },

  { id: 'd_po_conhecido', tipo: 'diaria', icone: '💠',
    nome: 'Pó Conhecido', nomeEn: 'Familiar Dust',
    desc: 'Ascenda {v} vez. Você já sabe como termina. Faça de novo.',
    descEn: 'Ascend {v} time. You know how it ends. Do it again.',
    meta: { tipo: 'ascensoes', valor: 1 },
    requer: { onda: 25 },
    recompensa: { tipo: 'fragmentos', valor: 15 }, xpTemporada: 70 },

  { id: 'd_manutencao_ofensiva', tipo: 'diaria', icone: '⚔️',
    nome: 'Manutenção Ofensiva', nomeEn: 'Offensive Maintenance',
    desc: 'Leve o Canhão de Plasma ao nível {v}. Um canhão sem manutenção vira enfeite caro.',
    descEn: 'Bring the Plasma Cannon to level {v}. An unmaintained cannon is expensive decor.',
    meta: { tipo: 'upgradeNivel', chave: 'dano', valor: 30 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 16 }, xpTemporada: 45 },

  { id: 'd_laudo_estrutural', tipo: 'diaria', icone: '🏗️',
    nome: 'Laudo Estrutural', nomeEn: 'Structural Report',
    desc: 'Leve a Blindagem Estrutural ao nível {v}. O laudo anterior foi assinado por alguém que já não trabalha aqui.',
    descEn: 'Bring Structural Plating to level {v}. The previous report was signed by someone no longer employed.',
    meta: { tipo: 'upgradeNivel', chave: 'vida', valor: 25 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 16 }, xpTemporada: 45 },

  { id: 'd_hora_extra', tipo: 'diaria', icone: '⏱️',
    nome: 'Hora Extra Não Remunerada', nomeEn: 'Unpaid Overtime',
    desc: 'Fique {v} minutos em serviço ativo. O Comando agradece e não paga.',
    descEn: 'Stay {v} minutes on active duty. Command thanks you and pays nothing.',
    meta: { tipo: 'tempoTotal', valor: 1200 },
    recompensa: { tipo: 'gemas', valor: 22 }, xpTemporada: 55 },
];

/* ==================================================== MISSÕES SEMANAIS ==== */
/** 12 modelos. Metas grandes, recompensas que mudam uma corrida inteira. */
export const MISSOES_SEMANAIS = [
  { id: 's_censo', tipo: 'semanal', icone: '💀',
    nome: 'Censo Reduzido', nomeEn: 'Reduced Census',
    desc: 'Abata {v} inimigos nesta semana. A demografia do Enxame é problema deles.',
    descEn: 'Kill {v} enemies this week. Swarm demographics are their problem.',
    meta: { tipo: 'inimigosMortos', valor: 12000 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 180 }, xpTemporada: 400 },

  { id: 's_temporada_coroas', tipo: 'semanal', icone: '👑',
    nome: 'Temporada de Coroas', nomeEn: 'Crown Season',
    desc: 'Derrube {v} chefes. Cada coroa vale mais vazia.',
    descEn: 'Fell {v} bosses. Every crown is worth more empty.',
    meta: { tipo: 'chefesMortos', valor: 40 },
    requer: { onda: 10 },
    recompensa: { tipo: 'gemas', valor: 220 }, xpTemporada: 450 },

  { id: 's_marca_dagua', tipo: 'semanal', icone: '🌊',
    nome: 'Marca d’Água', nomeEn: 'High-Water Mark',
    desc: 'Alcance a onda {v}. Depois olhe para trás e sinta nada.',
    descEn: 'Reach wave {v}. Then look back and feel nothing.',
    meta: { tipo: 'onda', valor: 120 }, escalaComOnda: true,
    recompensa: { tipo: 'fragmentos', valor: 120 }, xpTemporada: 500 },

  { id: 's_ciclo_domestico', tipo: 'semanal', icone: '♻️',
    nome: 'Ciclo Doméstico', nomeEn: 'Domestic Cycle',
    desc: 'Ascenda {v} vezes. Lavar, desmontar, repetir.',
    descEn: 'Ascend {v} times. Wash, dismantle, repeat.',
    meta: { tipo: 'ascensoes', valor: 12 },
    requer: { onda: 25 },
    recompensa: { tipo: 'fragmentos', valor: 250 }, xpTemporada: 480 },

  { id: 's_ponto_sem_retorno', tipo: 'semanal', icone: '🌌',
    nome: 'Ponto Sem Retorno', nomeEn: 'Point of No Return',
    desc: 'Realize {v} Singularidade. Amasse mil torres até caberem numa cabeça de alfinete.',
    descEn: 'Perform {v} Singularity. Crush a thousand towers into a pinhead.',
    meta: { tipo: 'singularidades', valor: 1 },
    requer: { ascensoes: 8 },
    recompensa: { tipo: 'stat', stat: 'ganhoFrag', tipoEfeito: 'mult', valor: 1.2 }, xpTemporada: 900 },

  { id: 's_arquivo_morto', tipo: 'semanal', icone: '🗃️',
    nome: 'Arquivo Morto', nomeEn: 'Dead Archive',
    desc: 'Recolha {v} cartas. O arquivo cresce; ninguém lê o arquivo.',
    descEn: 'Recover {v} cards. The archive grows; nobody reads the archive.',
    meta: { tipo: 'cartas', valor: 25 },
    requer: { onda: 10 },
    recompensa: { tipo: 'gemas', valor: 200 }, xpTemporada: 420 },

  { id: 's_achado_dourado', tipo: 'semanal', icone: '🌠',
    nome: 'Achado Dourado', nomeEn: 'Golden Find',
    desc: 'Obtenha {v} cartas lendárias. A sorte é um recurso; minere-a.',
    descEn: 'Obtain {v} legendary cards. Luck is a resource. Mine it.',
    meta: { tipo: 'lendarios', valor: 2 },
    requer: { onda: 30 },
    recompensa: { tipo: 'stat', stat: 'chanceDrop', tipoEfeito: 'mult', valor: 1.15 }, xpTemporada: 700 },

  { id: 's_orcamento', tipo: 'semanal', icone: '🏦',
    nome: 'Orçamento Executado', nomeEn: 'Budget Executed',
    desc: 'Gaste {v} de ouro. Verba não usada é verba cortada no próximo ciclo.',
    descEn: 'Spend {v} gold. Unused budget is budget cut next cycle.',
    meta: { tipo: 'ouroGasto', valor: 90000 }, escalaComOnda: true,
    recompensa: { tipo: 'gemas', valor: 160 }, xpTemporada: 380 },

  { id: 's_sem_cafe', tipo: 'semanal', icone: '⛓️',
    nome: 'Sem Pausa Para o Café', nomeEn: 'No Coffee Break',
    desc: 'Atinja um combo de {v}. Respirar conta como interrupção.',
    descEn: 'Reach a {v} combo. Breathing counts as an interruption.',
    meta: { tipo: 'comboMaximo', valor: 220 },
    requer: { onda: 20 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'mult', valor: 1.12 }, xpTemporada: 520 },

  { id: 's_painel_intensivo', tipo: 'semanal', icone: '🎛️',
    nome: 'Uso Intensivo do Painel', nomeEn: 'Heavy Console Use',
    desc: 'Acione habilidades {v} vezes. O painel foi feito para desgastar.',
    descEn: 'Trigger abilities {v} times. The console was built to wear out.',
    meta: { tipo: 'habilidadesUsadas', valor: 120 },
    recompensa: { tipo: 'stat', stat: 'cdr', tipoEfeito: 'pct', valor: 0.05 }, xpTemporada: 440 },

  { id: 's_sessenta_intactas', tipo: 'semanal', icone: '🛡️',
    nome: 'Sessenta Sem Um Arranhão', nomeEn: 'Sixty Without a Scratch',
    desc: 'Complete {v} ondas consecutivas sem cair. A contagem é implacável e você também deveria ser.',
    descEn: 'Clear {v} consecutive waves without falling. The count is merciless; be likewise.',
    meta: { tipo: 'ondasCompletas', valor: 60 }, semMorrer: true,
    requer: { onda: 30 },
    recompensa: { tipo: 'pontosTalento', valor: 8 }, xpTemporada: 750 },

  { id: 's_provacoes', tipo: 'semanal', icone: '🏆',
    nome: 'Provações Voluntárias', nomeEn: 'Voluntary Trials',
    desc: 'Conclua {v} desafios. Ninguém pediu. Esse é o ponto.',
    descEn: 'Finish {v} challenges. Nobody asked. That is the point.',
    meta: { tipo: 'desafiosCompletos', valor: 3 },
    requer: { singularidades: 1 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.1 }, xpTemporada: 800 },
];

export const MISSOES = [...MISSOES_DIARIAS, ...MISSOES_SEMANAIS];
export const MISSAO_POR_ID = Object.fromEntries(MISSOES.map((m) => [m.id, m]));

/* ============================================================ TEMPORADA === */
/** Metadados do ciclo corrente. `id` gira ao virar a temporada. */
export const TEMPORADA = {
  id: 1,
  nome: 'Ciclo I — Protocolo Vigília',
  nomeEn: 'Cycle I — Vigil Protocol',
  icone: '🌙',
  duracaoDias: 35,
  niveisMax: 40,
  ativasDiarias: 4,
  ativasSemanais: 3,
  rerollsBase: 1,
  lore: 'O Comando dividiu a eternidade em ciclos de trinta e cinco dias. Não porque a eternidade coopere, mas porque planilhas precisam de linhas.',
  loreEn: 'Command split eternity into thirty-five-day cycles. Not because eternity cooperates, but because spreadsheets need rows.',
};

/**
 * Trilha de 40 níveis. `destaque` marca o patamar que o jogador conta para os
 * amigos: a cada 5 níveis vem um bônus PERMANENTE de atributo em vez de moeda.
 */
export const RECOMPENSAS_TEMPORADA = [
  { nivel: 1,  destaque: false, icone: '🎫', nome: 'Crachá Provisório',        nomeEn: 'Provisional Badge',    recompensa: { tipo: 'gemas', valor: 15 } },
  { nivel: 2,  destaque: false, icone: '💰', nome: 'Adiantamento',             nomeEn: 'Advance Pay',          recompensa: { tipo: 'ouro', valor: 8 } },
  { nivel: 3,  destaque: false, icone: '💎', nome: 'Caixa de Peças',           nomeEn: 'Parts Crate',          recompensa: { tipo: 'gemas', valor: 20 } },
  { nivel: 4,  destaque: false, icone: '💠', nome: 'Estilhaço Homologado',     nomeEn: 'Certified Shard',      recompensa: { tipo: 'fragmentos', valor: 5 } },
  { nivel: 5,  destaque: true,  icone: '🏅', nome: 'Selo do Turno',            nomeEn: 'Shift Seal',           recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'mult', valor: 1.03 } },

  { nivel: 6,  destaque: false, icone: '💎', nome: 'Ração de Gemas',           nomeEn: 'Gem Ration',           recompensa: { tipo: 'gemas', valor: 25 } },
  { nivel: 7,  destaque: false, icone: '💵', nome: 'Bônus de Risco',           nomeEn: 'Hazard Pay',           recompensa: { tipo: 'ouro', valor: 12 } },
  { nivel: 8,  destaque: false, icone: '📚', nome: 'Curso Obrigatório',        nomeEn: 'Mandatory Training',   recompensa: { tipo: 'pontosTalento', valor: 2 } },
  { nivel: 9,  destaque: false, icone: '💎', nome: 'Reposição de Estoque',     nomeEn: 'Restock',              recompensa: { tipo: 'gemas', valor: 30 } },
  { nivel: 10, destaque: true,  icone: '⚔️', nome: 'Marca de Guerra',          nomeEn: 'War Mark',             recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.05 } },

  { nivel: 11, destaque: false, icone: '💠', nome: 'Lote de Estilhaços',       nomeEn: 'Shard Lot',            recompensa: { tipo: 'fragmentos', valor: 12 } },
  { nivel: 12, destaque: false, icone: '💎', nome: 'Vale-Combustível',         nomeEn: 'Fuel Voucher',         recompensa: { tipo: 'gemas', valor: 35 } },
  { nivel: 13, destaque: false, icone: '💰', nome: 'Repasse Trimestral',       nomeEn: 'Quarterly Payout',     recompensa: { tipo: 'ouro', valor: 18 } },
  { nivel: 14, destaque: false, icone: '💎', nome: 'Prêmio de Assiduidade',    nomeEn: 'Attendance Prize',     recompensa: { tipo: 'gemas', valor: 40 } },
  { nivel: 15, destaque: true,  icone: '🍀', nome: 'Faro Calibrado',           nomeEn: 'Calibrated Nose',      recompensa: { tipo: 'stat', stat: 'chanceDrop', tipoEfeito: 'mult', valor: 1.1 } },

  { nivel: 16, destaque: false, icone: '🧠', nome: 'Seminário Avançado',       nomeEn: 'Advanced Seminar',     recompensa: { tipo: 'pontosTalento', valor: 3 } },
  { nivel: 17, destaque: false, icone: '💎', nome: 'Verba Discricionária',     nomeEn: 'Discretionary Funds',  recompensa: { tipo: 'gemas', valor: 45 } },
  { nivel: 18, destaque: false, icone: '💠', nome: 'Herança de Colega',        nomeEn: 'Colleague’s Estate', recompensa: { tipo: 'fragmentos', valor: 25 } },
  { nivel: 19, destaque: false, icone: '💰', nome: 'Décimo Terceiro',          nomeEn: 'Year-End Bonus',       recompensa: { tipo: 'ouro', valor: 24 } },
  { nivel: 20, destaque: true,  icone: '🌟', nome: 'Insígnia de Meia-Torre',   nomeEn: 'Half-Tower Insignia',  recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.08 } },

  { nivel: 21, destaque: false, icone: '💎', nome: 'Fundo de Emergência',      nomeEn: 'Emergency Fund',       recompensa: { tipo: 'gemas', valor: 55 } },
  { nivel: 22, destaque: false, icone: '💰', nome: 'Dividendos do Enxame',     nomeEn: 'Swarm Dividends',      recompensa: { tipo: 'ouro', valor: 30 } },
  { nivel: 23, destaque: false, icone: '🧠', nome: 'Licença Para Pensar',      nomeEn: 'License to Think',     recompensa: { tipo: 'pontosTalento', valor: 4 } },
  { nivel: 24, destaque: false, icone: '💎', nome: 'Comissão de Abate',        nomeEn: 'Kill Commission',      recompensa: { tipo: 'gemas', valor: 60 } },
  { nivel: 25, destaque: true,  icone: '💠', nome: 'Rendimento Cristalino',    nomeEn: 'Crystalline Yield',    recompensa: { tipo: 'stat', stat: 'ganhoFrag', tipoEfeito: 'mult', valor: 1.15 } },

  { nivel: 26, destaque: false, icone: '💠', nome: 'Espólio Homologado',       nomeEn: 'Certified Spoils',     recompensa: { tipo: 'fragmentos', valor: 60 } },
  { nivel: 27, destaque: false, icone: '💎', nome: 'Reajuste Anual',           nomeEn: 'Annual Raise',         recompensa: { tipo: 'gemas', valor: 70 } },
  { nivel: 28, destaque: false, icone: '💰', nome: 'Restituição',              nomeEn: 'Refund',               recompensa: { tipo: 'ouro', valor: 38 } },
  { nivel: 29, destaque: false, icone: '💎', nome: 'Cota Extraordinária',      nomeEn: 'Extraordinary Quota',  recompensa: { tipo: 'gemas', valor: 80 } },
  { nivel: 30, destaque: true,  icone: '🎲', nome: 'Sorte Institucional',      nomeEn: 'Institutional Luck',   recompensa: { tipo: 'stat', stat: 'sorte', tipoEfeito: 'mult', valor: 1.12 } },

  { nivel: 31, destaque: false, icone: '🧠', nome: 'Doutorado de Campo',       nomeEn: 'Field Doctorate',      recompensa: { tipo: 'pontosTalento', valor: 5 } },
  { nivel: 32, destaque: false, icone: '💎', nome: 'Pacote Executivo',         nomeEn: 'Executive Package',    recompensa: { tipo: 'gemas', valor: 90 } },
  { nivel: 33, destaque: false, icone: '💠', nome: 'Reserva Estratégica',      nomeEn: 'Strategic Reserve',    recompensa: { tipo: 'fragmentos', valor: 120 } },
  { nivel: 34, destaque: false, icone: '💰', nome: 'Lucro Não Declarado',      nomeEn: 'Undeclared Profit',    recompensa: { tipo: 'ouro', valor: 48 } },
  { nivel: 35, destaque: true,  icone: '✴️', nome: 'Manual dos Pontos Frágeis', nomeEn: 'Manual of Weak Points', recompensa: { tipo: 'stat', stat: 'critDano', tipoEfeito: 'pct', valor: 0.25 } },

  { nivel: 36, destaque: false, icone: '💎', nome: 'Aposentadoria Antecipada', nomeEn: 'Early Retirement',     recompensa: { tipo: 'gemas', valor: 100 } },
  { nivel: 37, destaque: false, icone: '💰', nome: 'Espólio do Turno Anterior', nomeEn: 'Previous Shift’s Estate', recompensa: { tipo: 'ouro', valor: 60 } },
  { nivel: 38, destaque: false, icone: '🧠', nome: 'Cátedra',                  nomeEn: 'Tenure',               recompensa: { tipo: 'pontosTalento', valor: 6 } },
  { nivel: 39, destaque: false, icone: '💎', nome: 'Última Remessa',           nomeEn: 'Final Shipment',       recompensa: { tipo: 'gemas', valor: 120 } },
  { nivel: 40, destaque: true,  icone: '👑', nome: 'Coroa do Ciclo',           nomeEn: 'Crown of the Cycle',   recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.25 } },
];

/**
 * XP necessário para ir do nível `n-1` ao nível `n` da temporada.
 * Curva suave: linear no começo, levemente polinomial no fim, arredondada
 * a múltiplos de 5 para não parecer saída de uma planilha. Um ciclo inteiro
 * (40 níveis) custa ~23k de XP — alcançável fazendo as diárias e sobrando
 * folga para dois dias de esquecimento.
 */
export const XP_TEMPORADA_POR_NIVEL = (n) => {
  const bruto = Number(n);
  const k = Number.isFinite(bruto) ? Math.max(0, Math.floor(bruto) - 1) : 0;
  return Math.round((60 + 14 * k + 0.9 * Math.pow(k, 1.8)) / 5) * 5;
};

/** XP acumulado do nível 1 até `n` (inclusive). */
export function xpTemporadaAcumulado(n) {
  const alvo = Number.isFinite(Number(n)) ? Math.floor(Number(n)) : 0;
  let total = 0;
  for (let i = 1; i <= alvo; i++) total += XP_TEMPORADA_POR_NIVEL(i);
  return total;
}

/** Nível de temporada correspondente a um total de XP (0 = nem começou). */
export function nivelTemporadaPorXP(xp) {
  // Save corrompido, campo ausente ou NaN não podem valer o passe inteiro:
  // sem esta normalização, `NaN < custo` é sempre falso e o laço entrega o teto.
  const bruto = Number(xp);
  let restante = Number.isFinite(bruto) ? Math.max(0, bruto) : 0;
  let nivel = 0;
  while (nivel < TEMPORADA.niveisMax) {
    const custo = XP_TEMPORADA_POR_NIVEL(nivel + 1);
    if (restante < custo) break;
    restante -= custo;
    nivel++;
  }
  return { nivel, restante, proximo: nivel >= TEMPORADA.niveisMax ? 0 : XP_TEMPORADA_POR_NIVEL(nivel + 1) };
}

/* ================================================== SEQUÊNCIA DIÁRIA ====== */
/**
 * Bônus por dias consecutivos com pelo menos uma missão concluída.
 * `multXP` multiplica o XP de temporada de TODAS as missões enquanto a
 * sequência estiver viva. Perder um dia devolve o jogador ao dia 1 —
 * o Comando não reconhece atestados.
 */
export const SEQUENCIA_DIARIA = [
  { dia: 1, icone: '🚪', destaque: false, multXP: 1.0,
    nome: 'Você Voltou', nomeEn: 'You Came Back',
    desc: 'Ninguém apostava nisso. Os registros foram atualizados.',
    descEn: 'Nobody was betting on it. The records have been updated.',
    recompensa: { tipo: 'gemas', valor: 5 }, xpTemporada: 20 },

  { dia: 2, icone: '🔁', destaque: false, multXP: 1.05,
    nome: 'Hábito em Formação', nomeEn: 'Habit Forming',
    desc: 'Dois dias seguidos já é padrão estatístico. Quase.',
    descEn: 'Two days running is nearly a statistical pattern.',
    recompensa: { tipo: 'gemas', valor: 8 }, xpTemporada: 30 },

  { dia: 3, icone: '📈', destaque: false, multXP: 1.1,
    nome: 'Padrão Detectado', nomeEn: 'Pattern Detected',
    desc: 'O Enxame também percebeu. Ele ajusta a escala amanhã.',
    descEn: 'The Swarm noticed too. It rescales tomorrow.',
    recompensa: { tipo: 'gemas', valor: 12 }, xpTemporada: 45 },

  { dia: 4, icone: '🧷', destaque: false, multXP: 1.15,
    nome: 'Assiduidade Suspeita', nomeEn: 'Suspicious Attendance',
    desc: 'O Comando abriu um processo para entender sua motivação.',
    descEn: 'Command opened a case to understand your motivation.',
    recompensa: { tipo: 'fragmentos', valor: 10 }, xpTemporada: 60 },

  { dia: 5, icone: '👁️', destaque: false, multXP: 1.22,
    nome: 'O Enxame Notou', nomeEn: 'The Swarm Noticed',
    desc: 'Cinco dias. Alguma coisa lá fora aprendeu o seu horário.',
    descEn: 'Five days. Something out there learned your schedule.',
    recompensa: { tipo: 'gemas', valor: 25 }, xpTemporada: 80 },

  { dia: 6, icone: '🎖️', destaque: false, multXP: 1.3,
    nome: 'Turno Modelo', nomeEn: 'Model Shift',
    desc: 'Sua ficha foi impressa e pendurada. A parede era de metal.',
    descEn: 'Your record was printed and pinned up. The wall was metal.',
    recompensa: { tipo: 'pontosTalento', valor: 2 }, xpTemporada: 110 },

  { dia: 7, icone: '🌒', destaque: true, multXP: 1.4,
    nome: 'Semana Inteira, Sem Desculpas', nomeEn: 'Full Week, No Excuses',
    desc: 'Sete dias sem falhar. O bônus se mantém enquanto a sequência viver.',
    descEn: 'Seven days unbroken. The bonus holds while the streak does.',
    recompensa: { tipo: 'gemas', valor: 60 }, xpTemporada: 160 },
];

/** Entrada da sequência para `dias` consecutivos (satura no dia 7). */
export function bonusSequencia(dias) {
  const i = Math.min(SEQUENCIA_DIARIA.length, Math.max(1, Math.floor(dias || 1))) - 1;
  return SEQUENCIA_DIARIA[i];
}

/* ======================================================= UTILIDADES ======= */
/** Metas que acompanham curvas exponenciais (ouro/dano) em vez de contagem. */
const METAS_EXPONENCIAIS = ['ouroTotal', 'ouroGasto', 'danoMaximo'];

/**
 * Meta efetiva da missão para o progresso atual do jogador.
 * - metas de contagem crescem devagar (polinomial): faxina continua faxina;
 * - metas de ouro/dano acompanham a curva de rendimento da onda;
 * - metas de onda somam sobre o recorde, sempre pedindo um passo à frente.
 */
export function metaEscalada(missao, ondaMaximaGlobal = 1) {
  const base = missao.meta.valor;
  if (!missao.escalaComOnda) return base;
  const w = Math.max(1, ondaMaximaGlobal);
  if (missao.meta.tipo === 'onda' || missao.meta.tipo === 'ondaMaximaGlobal') {
    return Math.max(base, Math.ceil(w * 1.08 + 5));
  }
  if (METAS_EXPONENCIAIS.indexOf(missao.meta.tipo) >= 0) {
    return Math.ceil(base * Math.pow(1.128, w - 1));
  }
  return Math.ceil(base * (1 + Math.pow(w / 12, 1.35)));
}

/** O modelo está liberado para o sorteio neste save? */
export function missaoDisponivel(def, state) {
  const r = def.requer;
  if (!r) return true;
  if (r.onda && (state.ondaMaximaGlobal || 0) < r.onda) return false;
  if (r.ascensoes && (state.prestigio?.ascensoes || 0) < r.ascensoes) return false;
  if (r.singularidades && (state.prestigio?.singularidades || 0) < r.singularidades) return false;
  return true;
}

/** Modelos elegíveis de um tipo, prontos para o sorteio do reset. */
export function poolDeMissoes(tipo, state) {
  const lista = tipo === 'semanal' ? MISSOES_SEMANAIS : MISSOES_DIARIAS;
  return lista.filter((m) => missaoDisponivel(m, state));
}
