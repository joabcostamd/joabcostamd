/**
 * achievements.js — CONQUISTAS.
 *
 * Toda conquista é um contrato simples: uma condição rastreável, um prêmio
 * permanente e uma frase que finge não ligar. Elas nunca resetam — nem na
 * Ascensão, nem na Singularidade, nem na Transcendência. São a única memória
 * honesta que o jogo mantém de você.
 *
 * cond: { tipo, chave?, valor }   -> ver contrato de condições rastreáveis
 * recompensa: { tipo: 'gemas'|'fragmentos'|'ouro'|'pontosTalento'|'stat',
 *               valor, stat?, tipoEfeito?: 'pct'|'mult' }
 * pontos: 5 (trivial) | 10 (rotina) | 25 (mérito) | 50 (obsessão)
 * oculta: true -> aparece como "???" até ser desbloqueada.
 */

export const CATEGORIAS_CONQUISTA = [
  { id: 'progresso', nome: 'Progresso',  nomeEn: 'Progress',   icone: '🚩' },
  { id: 'combate',   nome: 'Combate',    nomeEn: 'Combat',     icone: '⚔️' },
  { id: 'economia',  nome: 'Economia',   nomeEn: 'Economy',    icone: '🪙' },
  { id: 'colecao',   nome: 'Coleção',    nomeEn: 'Collection', icone: '🃏' },
  { id: 'prestigio', nome: 'Prestígio',  nomeEn: 'Prestige',   icone: '💠' },
  { id: 'segredos',  nome: 'Segredos',   nomeEn: 'Secrets',    icone: '🕳️' },
];

export const CONQUISTAS = [
  /* ==================================================================== */
  /* PROGRESSO · a escada que todo mundo sobe, reclamando                  */
  /* ==================================================================== */

  { id: 'p_onda10', cat: 'progresso', icone: '🚩', pontos: 5,
    nome: 'Ainda Estou Aqui', nomeEn: 'Still Standing',
    desc: 'Alcance a onda 10. Tecnicamente, você sobreviveu a alguma coisa.',
    descEn: 'Reach wave 10. Technically, you survived something.',
    cond: { tipo: 'onda', valor: 10 },
    recompensa: { tipo: 'gemas', valor: 5 } },

  { id: 'p_onda25', cat: 'progresso', icone: '💠', pontos: 5,
    nome: 'Poeira Pronta', nomeEn: 'Dust Ready',
    desc: 'Alcance a onda 25 — o ponto onde desmontar a torre vira estratégia.',
    descEn: 'Reach wave 25 — where dismantling your tower becomes strategy.',
    cond: { tipo: 'onda', valor: 25 },
    recompensa: { tipo: 'gemas', valor: 15 } },

  { id: 'p_onda50', cat: 'progresso', icone: '🧭', pontos: 10,
    nome: 'Metade do Caminho para Lugar Nenhum', nomeEn: 'Halfway to Nowhere',
    desc: 'Alcance a onda 50. O primeiro super-chefe já viu você chegando.',
    descEn: 'Reach wave 50. The first super-boss already saw you coming.',
    cond: { tipo: 'onda', valor: 50 },
    recompensa: { tipo: 'fragmentos', valor: 15 } },

  { id: 'p_onda100', cat: 'progresso', icone: '💯', pontos: 25,
    nome: 'Três Dígitos', nomeEn: 'Three Digits',
    desc: 'Alcance a onda 100. O contador ficou largo. O Enxame, também.',
    descEn: 'Reach wave 100. The counter got wider. So did the Swarm.',
    cond: { tipo: 'onda', valor: 100 },
    recompensa: { tipo: 'gemas', valor: 60 } },

  { id: 'p_onda200', cat: 'progresso', icone: '👁️', pontos: 25,
    nome: 'O Enxame Ficou Curioso', nomeEn: 'The Swarm Grew Curious',
    desc: 'Alcance a onda 200. Eles pararam de mandar os descartáveis.',
    descEn: 'Reach wave 200. They stopped sending the disposable ones.',
    cond: { tipo: 'onda', valor: 200 },
    recompensa: { tipo: 'stat', stat: 'dano', tipoEfeito: 'pct', valor: 0.12 } },

  { id: 'p_onda500', cat: 'progresso', icone: '🗺️', pontos: 50,
    nome: 'Onde os Mapas Acabam', nomeEn: 'Where the Maps End',
    desc: 'Alcance a onda 500. Daqui em diante o cartógrafo só chutava.',
    descEn: 'Reach wave 500. Past here the cartographer was guessing.',
    cond: { tipo: 'onda', valor: 500 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.3 } },

  { id: 'p_onda1000', cat: 'progresso', icone: '♾️', pontos: 50,
    nome: 'Mil e Uma Noites de Cerco', nomeEn: 'A Thousand and One Sieges',
    desc: 'Alcance a onda 1000. Ninguém escreveu essa história porque ninguém voltou.',
    descEn: 'Reach wave 1000. Nobody wrote this one down; nobody came back.',
    cond: { tipo: 'onda', valor: 1000 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.6 } },

  { id: 'p_nivel10', cat: 'progresso', icone: '📘', pontos: 5,
    nome: 'Curva de Aprendizado', nomeEn: 'Learning Curve',
    desc: 'Chegue ao nível 10. A curva é suave. O resto não.',
    descEn: 'Reach level 10. The curve is gentle. Nothing else is.',
    cond: { tipo: 'nivel', valor: 10 },
    recompensa: { tipo: 'gemas', valor: 8 } },

  { id: 'p_nivel25', cat: 'progresso', icone: '🎖️', pontos: 10,
    nome: 'Veterano de Papel', nomeEn: 'Paper Veteran',
    desc: 'Chegue ao nível 25. Certificado emitido por ninguém em especial.',
    descEn: 'Reach level 25. Certified by no one in particular.',
    cond: { tipo: 'nivel', valor: 25 },
    recompensa: { tipo: 'pontosTalento', valor: 1 } },

  { id: 'p_nivel50', cat: 'progresso', icone: '🩹', pontos: 10,
    nome: 'Cinquenta Cicatrizes', nomeEn: 'Fifty Scars',
    desc: 'Chegue ao nível 50. Cada nível custou alguma coisa que você já esqueceu.',
    descEn: 'Reach level 50. Every level cost something you have already forgotten.',
    cond: { tipo: 'nivel', valor: 50 },
    recompensa: { tipo: 'pontosTalento', valor: 2 } },

  { id: 'p_nivel100', cat: 'progresso', icone: '🧠', pontos: 25,
    nome: 'Nível Cem, Sabedoria Zero', nomeEn: 'Level One Hundred, Wisdom Zero',
    desc: 'Chegue ao nível 100. Experiência não é a mesma coisa que juízo.',
    descEn: 'Reach level 100. Experience is not the same thing as judgment.',
    cond: { tipo: 'nivel', valor: 100 },
    recompensa: { tipo: 'pontosTalento', valor: 4 } },

  { id: 'p_nivel250', cat: 'progresso', icone: '🏛️', pontos: 50,
    nome: 'Arquiteto de Si Mesmo', nomeEn: 'Architect of Itself',
    desc: 'Chegue ao nível 250. A torre já não precisa de você para saber o que fazer.',
    descEn: 'Reach level 250. The tower no longer needs you to know what to do.',
    cond: { tipo: 'nivel', valor: 250 },
    recompensa: { tipo: 'pontosTalento', valor: 8 } },

  { id: 'p_ondas500', cat: 'progresso', icone: '🔁', pontos: 10,
    nome: 'O Turno Nunca Acaba', nomeEn: 'The Shift Never Ends',
    desc: 'Complete 500 ondas somando todas as tentativas. Ninguém te rende.',
    descEn: 'Clear 500 waves across every attempt. Nobody comes to relieve you.',
    cond: { tipo: 'ondasCompletas', valor: 500 },
    recompensa: { tipo: 'gemas', valor: 30 } },

  { id: 'p_ondas5000', cat: 'progresso', icone: '🏭', pontos: 25,
    nome: 'Funcionário do Mês', nomeEn: 'Employee of the Month',
    desc: 'Complete 5.000 ondas no total. O prêmio é continuar trabalhando.',
    descEn: 'Clear 5,000 waves in total. The prize is more work.',
    cond: { tipo: 'ondasCompletas', valor: 5000 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'pct', valor: 0.15 } },

  { id: 'p_tempo1h', cat: 'progresso', icone: '⏱️', pontos: 5,
    nome: 'Sessenta Minutos de Vigília', nomeEn: 'Sixty Minutes of Vigil',
    desc: 'Acumule 1 hora de jogo. A torre não pisca. Você piscou várias vezes.',
    descEn: 'Log one hour of play. The tower never blinks. You did, repeatedly.',
    cond: { tipo: 'tempoTotal', valor: 3600 },
    recompensa: { tipo: 'gemas', valor: 12 } },

  { id: 'p_tempo24h', cat: 'progresso', icone: '🌗', pontos: 25,
    nome: 'Um Dia Inteiro Olhando', nomeEn: 'A Whole Day of Watching',
    desc: 'Acumule 24 horas de jogo. Lá fora também aconteceram coisas.',
    descEn: 'Log 24 hours of play. Things also happened outside.',
    cond: { tipo: 'tempoTotal', valor: 86400 },
    recompensa: { tipo: 'stat', stat: 'ganhoXP', tipoEfeito: 'mult', valor: 1.2 } },

  { id: 'p_morte1', cat: 'progresso', icone: '💀', pontos: 5,
    nome: 'Isso Foi Constrangedor', nomeEn: 'That Was Embarrassing',
    desc: 'Perca a torre pela primeira vez. Acontece. Vai acontecer de novo.',
    descEn: 'Lose the tower once. It happens. It will happen again.',
    cond: { tipo: 'mortes', valor: 1 },
    recompensa: { tipo: 'ouro', valor: 500 } },

  { id: 'p_morte50', cat: 'progresso', icone: '⚰️', pontos: 10,
    nome: 'Reincidente', nomeEn: 'Repeat Offender',
    desc: 'Perca a torre 50 vezes. A reconstrução já tem rotina própria.',
    descEn: 'Lose the tower 50 times. The rebuild crew has a routine now.',
    cond: { tipo: 'mortes', valor: 50 },
    recompensa: { tipo: 'stat', stat: 'vidaMax', tipoEfeito: 'pct', valor: 0.15 } },

  /* ==================================================================== */
  /* COMBATE · números grandes feitos de coisas pequenas                   */
  /* ==================================================================== */

  { id: 'c_mortos100', cat: 'combate', icone: '🎯', pontos: 5,
    nome: 'Cem Grunhidos Depois', nomeEn: 'A Hundred Grunts Later',
    desc: 'Abata 100 inimigos. O Enxame nem terminou de contar a diferença.',
    descEn: 'Kill 100 enemies. The Swarm has not finished noticing.',
    cond: { tipo: 'inimigosMortos', valor: 100 },
    recompensa: { tipo: 'gemas', valor: 5 } },

  { id: 'c_mortos10k', cat: 'combate', icone: '📊', pontos: 10,
    nome: 'Estatística Aceitável', nomeEn: 'Acceptable Statistics',
    desc: 'Abata 10.000 inimigos. Agora você é uma tendência, não um acidente.',
    descEn: 'Kill 10,000 enemies. You are a trend now, not an accident.',
    cond: { tipo: 'inimigosMortos', valor: 10000 },
    recompensa: { tipo: 'gemas', valor: 25 } },

  { id: 'c_mortos1m', cat: 'combate', icone: '🕯️', pontos: 25,
    nome: 'Um Milhão de Nomes Não Ditos', nomeEn: 'A Million Unspoken Names',
    desc: 'Abata 1.000.000 de inimigos. Nenhum deles se apresentou antes.',
    descEn: 'Kill 1,000,000 enemies. None of them introduced themselves.',
    cond: { tipo: 'inimigosMortos', valor: 1e6 },
    recompensa: { tipo: 'stat', stat: 'dano', tipoEfeito: 'pct', valor: 0.15 } },

  { id: 'c_mortos1b', cat: 'combate', icone: '🌑', pontos: 50,
    nome: 'O Censo Desistiu', nomeEn: 'The Census Gave Up',
    desc: 'Abata 1 bilhão de inimigos. Pararam de emitir certidões por lá.',
    descEn: 'Kill one billion enemies. They stopped issuing death certificates.',
    cond: { tipo: 'inimigosMortos', valor: 1e9 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.45 } },

  { id: 'c_chefes10', cat: 'combate', icone: '👑', pontos: 5,
    nome: 'Coleção de Coroas', nomeEn: 'Crown Collection',
    desc: 'Derrote 10 chefes. Todas as coroas serviram. Nenhuma cabeça sobrou.',
    descEn: 'Defeat 10 bosses. Every crown fit. No head survived it.',
    cond: { tipo: 'chefesMortos', valor: 10 },
    recompensa: { tipo: 'gemas', valor: 12 } },

  { id: 'c_chefes100', cat: 'combate', icone: '🪓', pontos: 25,
    nome: 'Decapitação Industrial', nomeEn: 'Industrial Decapitation',
    desc: 'Derrote 100 chefes. Virou linha de produção, com meta e tudo.',
    descEn: 'Defeat 100 bosses. It is an assembly line now, quotas included.',
    cond: { tipo: 'chefesMortos', valor: 100 },
    recompensa: { tipo: 'stat', stat: 'danoChefe', tipoEfeito: 'mult', valor: 1.2 } },

  { id: 'c_chefes1000', cat: 'combate', icone: '🩸', pontos: 50,
    nome: 'Fila de Sucessão', nomeEn: 'Line of Succession',
    desc: 'Derrote 1.000 chefes. O Enxame promove rápido porque perde rápido.',
    descEn: 'Defeat 1,000 bosses. The Swarm promotes fast because it loses fast.',
    cond: { tipo: 'chefesMortos', valor: 1000 },
    recompensa: { tipo: 'stat', stat: 'danoChefe', tipoEfeito: 'mult', valor: 1.5 } },

  { id: 'c_crit1k', cat: 'combate', icone: '💥', pontos: 10,
    nome: 'Ponto Fraco Localizado', nomeEn: 'Weak Point Located',
    desc: 'Cause 1.000 acertos críticos. Todo mundo tem uma costura ruim.',
    descEn: 'Land 1,000 critical hits. Everything has a bad seam somewhere.',
    cond: { tipo: 'criticos', valor: 1000 },
    recompensa: { tipo: 'stat', stat: 'critChance', tipoEfeito: 'pct', valor: 0.2 } },

  { id: 'c_crit100k', cat: 'combate', icone: '✴️', pontos: 25,
    nome: 'Cirurgia sem Anestesia', nomeEn: 'Surgery Without Anesthesia',
    desc: 'Cause 100.000 acertos críticos. Precisão é só crueldade organizada.',
    descEn: 'Land 100,000 critical hits. Precision is just organized cruelty.',
    cond: { tipo: 'criticos', valor: 100000 },
    recompensa: { tipo: 'stat', stat: 'critDano', tipoEfeito: 'pct', valor: 0.2 } },

  { id: 'c_combo50', cat: 'combate', icone: '🎵', pontos: 5,
    nome: 'Ritmo Encontrado', nomeEn: 'Rhythm Found',
    desc: 'Chegue a um combo de 50. A torre está gostando disso mais do que deveria.',
    descEn: 'Hit a 50 combo. The tower is enjoying this more than it should.',
    cond: { tipo: 'comboMaximo', valor: 50 },
    recompensa: { tipo: 'gemas', valor: 10 } },

  { id: 'c_combo200', cat: 'combate', icone: '🥁', pontos: 25,
    nome: 'Metrônomo de Ossos', nomeEn: 'Metronome of Bones',
    desc: 'Chegue a um combo de 200. Cada batida é alguém deixando de existir no tempo certo.',
    descEn: 'Hit a 200 combo. Every beat is someone ceasing on schedule.',
    cond: { tipo: 'comboMaximo', valor: 200 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'pct', valor: 0.18 } },

  { id: 'c_dano1m', cat: 'combate', icone: '❗', pontos: 10,
    nome: 'Aquilo Foi Necessário?', nomeEn: 'Was That Necessary?',
    desc: 'Cause 1.000.000 de dano em um único golpe. Sobrou pouco para identificar.',
    descEn: 'Deal 1,000,000 damage in a single hit. Little was left to identify.',
    cond: { tipo: 'danoMaximo', valor: 1e6 },
    recompensa: { tipo: 'gemas', valor: 35 } },

  { id: 'c_dano1t', cat: 'combate', icone: '☄️', pontos: 50,
    nome: 'Excesso, Devidamente Documentado', nomeEn: 'Excess, Duly Documented',
    desc: 'Cause 1 trilhão de dano em um único golpe. O alvo tinha 400 de vida.',
    descEn: 'Deal one trillion damage in a single hit. The target had 400 HP.',
    cond: { tipo: 'danoMaximo', valor: 1e12 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.35 } },

  { id: 'c_tiros100k', cat: 'combate', icone: '🔩', pontos: 10,
    nome: 'Dedo no Gatilho, Soldado', nomeEn: 'Trigger Finger, Welded',
    desc: 'Dispare 100.000 tiros. O gatilho fundiu com o mecanismo há tempos.',
    descEn: 'Fire 100,000 shots. The trigger fused to the mechanism ages ago.',
    cond: { tipo: 'tiros', valor: 100000 },
    recompensa: { tipo: 'stat', stat: 'cadencia', tipoEfeito: 'pct', valor: 0.08 } },

  { id: 'c_hab100', cat: 'combate', icone: '🔘', pontos: 5,
    nome: 'Botão Favorito', nomeEn: 'Favorite Button',
    desc: 'Use habilidades 100 vezes. Sempre a mesma. Você sabe qual.',
    descEn: 'Use abilities 100 times. Always the same one. You know which.',
    cond: { tipo: 'habilidadesUsadas', valor: 100 },
    recompensa: { tipo: 'stat', stat: 'duracaoHab', tipoEfeito: 'mult', valor: 1.1 } },

  { id: 'c_hab1000', cat: 'combate', icone: '⏳', pontos: 25,
    nome: 'Dependência de Recarga', nomeEn: 'Cooldown Dependency',
    desc: 'Use habilidades 1.000 vezes. Você não joga entre recargas: você espera.',
    descEn: 'Use abilities 1,000 times. You do not play between cooldowns; you wait.',
    cond: { tipo: 'habilidadesUsadas', valor: 1000 },
    recompensa: { tipo: 'fragmentos', valor: 150 } },

  { id: 'c_ceifeiro', cat: 'combate', icone: '🌾', pontos: 25,
    nome: 'Ceifando o Ceifeiro', nomeEn: 'Reaping the Reaper',
    desc: 'Abata 100 Ceifeiros. A ironia foi registrada e ignorada.',
    descEn: 'Kill 100 Reapers. The irony was noted and ignored.',
    cond: { tipo: 'inimigoTipo', chave: 'ceifeiro', valor: 100 },
    recompensa: { tipo: 'stat', stat: 'dano', tipoEfeito: 'pct', valor: 0.1 } },

  { id: 'c_divisor', cat: 'combate', icone: '➗', pontos: 10,
    nome: 'Matemática Ruim', nomeEn: 'Bad Math',
    desc: 'Abata 500 Divisores. Cada solução gerou exatamente dois problemas.',
    descEn: 'Kill 500 Splitters. Each solution produced exactly two problems.',
    cond: { tipo: 'inimigoTipo', chave: 'divisor', valor: 500 },
    recompensa: { tipo: 'ouro', valor: 250000 } },

  { id: 'c_curandeiro', cat: 'combate', icone: '✚', pontos: 10,
    nome: 'Prioridade Máxima', nomeEn: 'Kill Priority',
    desc: 'Abata 250 Curandeiros. Eles desfaziam seu trabalho; você desfez a carreira deles.',
    descEn: 'Kill 250 Menders. They undid your work; you undid their careers.',
    cond: { tipo: 'inimigoTipo', chave: 'curandeiro', valor: 250 },
    recompensa: { tipo: 'gemas', valor: 30 } },

  { id: 'c_espectro', cat: 'combate', icone: '👻', pontos: 10,
    nome: 'Fantasmas Também Sangram', nomeEn: 'Ghosts Bleed Too',
    desc: 'Abata 300 Espectros. Intangível é só uma questão de cronometragem.',
    descEn: 'Kill 300 Wraiths. Intangible is merely a timing problem.',
    cond: { tipo: 'inimigoTipo', chave: 'espectro', valor: 300 },
    recompensa: { tipo: 'gemas', valor: 40 } },

  /* ==================================================================== */
  /* ECONOMIA · o Enxame morre e o mercado agradece                        */
  /* ==================================================================== */

  { id: 'e_ouro1e4', cat: 'economia', icone: '🪙', pontos: 5,
    nome: 'Primeiro Cofre', nomeEn: 'First Vault',
    desc: 'Acumule 10 mil de ouro no total. Cabe numa caixa de sapato.',
    descEn: 'Earn 10 thousand gold in total. It fits in a shoebox.',
    cond: { tipo: 'ouroTotal', valor: 1e4 },
    recompensa: { tipo: 'gemas', valor: 5 } },

  { id: 'e_ouro1e7', cat: 'economia', icone: '💵', pontos: 10,
    nome: 'Liquidez', nomeEn: 'Liquidity',
    desc: 'Acumule 10 milhões de ouro. Você é rico num mundo sem lojas.',
    descEn: 'Earn 10 million gold. You are rich in a world with no shops.',
    cond: { tipo: 'ouroTotal', valor: 1e7 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'pct', valor: 0.1 } },

  { id: 'e_ouro1e12', cat: 'economia', icone: '🏔️', pontos: 25,
    nome: 'Um Trilhão em Cascalho', nomeEn: 'A Trillion in Gravel',
    desc: 'Acumule 1 trilhão de ouro. Só serve para comprar mais canhão.',
    descEn: 'Earn one trillion gold. It only buys more cannon.',
    cond: { tipo: 'ouroTotal', valor: 1e12 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'mult', valor: 1.15 } },

  { id: 'e_ouro1e20', cat: 'economia', icone: '📉', pontos: 50,
    nome: 'A Economia Colapsou e Você Não Notou', nomeEn: 'The Economy Collapsed and You Missed It',
    desc: 'Acumule 1e20 de ouro. A inflação chegou antes do Enxame.',
    descEn: 'Earn 1e20 gold. Inflation got here before the Swarm did.',
    cond: { tipo: 'ouroTotal', valor: 1e20 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'mult', valor: 1.4 } },

  { id: 'e_gasto1e6', cat: 'economia', icone: '🛒', pontos: 5,
    nome: 'Consumidor Compulsivo', nomeEn: 'Compulsive Buyer',
    desc: 'Gaste 1 milhão de ouro. Guardar ouro nunca matou ninguém — nem inimigo.',
    descEn: 'Spend one million gold. Hoarding never killed anything. Including enemies.',
    cond: { tipo: 'ouroGasto', valor: 1e6 },
    recompensa: { tipo: 'gemas', valor: 10 } },

  { id: 'e_gasto1e15', cat: 'economia', icone: '🧾', pontos: 25,
    nome: 'Recibo Longo Demais', nomeEn: 'Receipt Too Long',
    desc: 'Gaste 1 quatrilhão de ouro. A nota fiscal dá duas voltas na torre.',
    descEn: 'Spend one quadrillion gold. The receipt wraps the tower twice.',
    cond: { tipo: 'ouroGasto', valor: 1e15 },
    recompensa: { tipo: 'fragmentos', valor: 200 } },

  { id: 'e_dourado10', cat: 'economia', icone: '✨', pontos: 5,
    nome: 'Farejador de Brilho', nomeEn: 'Glint Sniffer',
    desc: 'Abata 10 inimigos dourados. Eles correm porque sabem o que carregam.',
    descEn: 'Kill 10 golden enemies. They run because they know what they carry.',
    cond: { tipo: 'douradosAbatidos', valor: 10 },
    recompensa: { tipo: 'gemas', valor: 15 } },

  { id: 'e_dourado250', cat: 'economia', icone: '🎰', pontos: 25,
    nome: 'Imposto sobre a Sorte', nomeEn: 'Luck Tax',
    desc: 'Abata 250 inimigos dourados. A casa sempre ganha; hoje a casa é você.',
    descEn: 'Kill 250 golden enemies. The house always wins; today you are the house.',
    cond: { tipo: 'douradosAbatidos', valor: 250 },
    recompensa: { tipo: 'stat', stat: 'sorte', tipoEfeito: 'mult', valor: 1.15 } },

  { id: 'e_juros25', cat: 'economia', icone: '🏦', pontos: 25,
    nome: 'Banqueiro do Apocalipse', nomeEn: 'Banker of the Apocalypse',
    desc: 'Leve o Cofre Rendente ao nível 25. Ouro que trabalha enquanto a torre morre.',
    descEn: 'Take the Interest Vault to level 25. Gold that works while the tower dies.',
    cond: { tipo: 'upgradeNivel', chave: 'juros', valor: 25 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'pct', valor: 0.2 } },

  { id: 'e_dano100', cat: 'economia', icone: '⚔️', pontos: 10,
    nome: 'Cem Canhões de Plasma', nomeEn: 'A Hundred Plasma Cannons',
    desc: 'Leve o Canhão de Plasma ao nível 100. Sutileza nunca foi o plano.',
    descEn: 'Take the Plasma Cannon to level 100. Subtlety was never the plan.',
    cond: { tipo: 'upgradeNivel', chave: 'dano', valor: 100 },
    recompensa: { tipo: 'stat', stat: 'dano', tipoEfeito: 'pct', valor: 0.08 } },

  { id: 'e_dano500', cat: 'economia', icone: '📈', pontos: 50,
    nome: 'Escalada Vertical', nomeEn: 'Vertical Climb',
    desc: 'Leve o Canhão de Plasma ao nível 500. O custo virou piada; o dano não.',
    descEn: 'Take the Plasma Cannon to level 500. The cost became a joke; the damage did not.',
    cond: { tipo: 'upgradeNivel', chave: 'dano', valor: 500 },
    recompensa: { tipo: 'stat', stat: 'dano', tipoEfeito: 'mult', valor: 1.3 } },

  { id: 'e_multishot5', cat: 'economia', icone: '☄️', pontos: 25,
    nome: 'Chuva Coordenada', nomeEn: 'Coordinated Rain',
    desc: 'Leve a Bateria Múltipla ao nível 5. Cinco respostas para a mesma pergunta.',
    descEn: 'Take the Multi Battery to level 5. Five answers to the same question.',
    cond: { tipo: 'upgradeNivel', chave: 'multishot', valor: 5 },
    recompensa: { tipo: 'stat', stat: 'velProjetil', tipoEfeito: 'pct', valor: 0.15 } },

  { id: 'e_forja10', cat: 'economia', icone: '💰', pontos: 25,
    nome: 'Fundição de Lucro', nomeEn: 'Profit Smeltery',
    desc: 'Leve a Forja de Ouro ao nível 10. Cadáver entra, dividendo sai.',
    descEn: 'Take the Goldforge to level 10. Corpses in, dividends out.',
    cond: { tipo: 'upgradeNivel', chave: 'forja_ouro', valor: 10 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'pct', valor: 0.25 } },

  /* ==================================================================== */
  /* COLEÇÃO · cartas, lendas e prateleiras                                */
  /* ==================================================================== */

  { id: 'k_cartas10', cat: 'colecao', icone: '🃏', pontos: 5,
    nome: 'Mão Inicial', nomeEn: 'Opening Hand',
    desc: 'Colete 10 cartas distintas. Ainda dá para carregar tudo no bolso.',
    descEn: 'Collect 10 distinct cards. Still fits in a pocket.',
    cond: { tipo: 'cartas', valor: 10 },
    recompensa: { tipo: 'gemas', valor: 10 } },

  { id: 'k_cartas60', cat: 'colecao', icone: '🗂️', pontos: 25,
    nome: 'Colecionador Doente', nomeEn: 'Unwell Collector',
    desc: 'Colete 60 cartas distintas. Você guarda duplicatas "por precaução".',
    descEn: 'Collect 60 distinct cards. You keep duplicates “just in case”.',
    cond: { tipo: 'cartas', valor: 60 },
    recompensa: { tipo: 'stat', stat: 'chanceDrop', tipoEfeito: 'mult', valor: 1.2 } },

  { id: 'k_cartas150', cat: 'colecao', icone: '🎴', pontos: 50,
    nome: 'Baralho Completo, Sanidade Não', nomeEn: 'Full Deck, Missing Mind',
    desc: 'Colete 150 cartas distintas. Sobrou coleção. Faltou repouso.',
    descEn: 'Collect 150 distinct cards. Plenty of collection. No rest.',
    cond: { tipo: 'cartas', valor: 150 },
    recompensa: { tipo: 'stat', stat: 'sorte', tipoEfeito: 'mult', valor: 1.3 } },

  { id: 'k_lend1', cat: 'colecao', icone: '🌟', pontos: 10,
    nome: 'Amarelo Bonito', nomeEn: 'Pretty Yellow',
    desc: 'Encontre sua primeira carta lendária. A cor sobe a pressão; o efeito, nem tanto.',
    descEn: 'Find your first legendary card. The color spikes your pulse. The effect, less so.',
    cond: { tipo: 'lendarios', valor: 1 },
    recompensa: { tipo: 'gemas', valor: 30 } },

  { id: 'k_lend10', cat: 'colecao', icone: '🏅', pontos: 25,
    nome: 'Padrão Lendário', nomeEn: 'Legendary Standard',
    desc: 'Encontre 10 cartas lendárias. Raridade é só uma questão de paciência estatística.',
    descEn: 'Find 10 legendary cards. Rarity is just statistical patience.',
    cond: { tipo: 'lendarios', valor: 10 },
    recompensa: { tipo: 'stat', stat: 'sorte', tipoEfeito: 'pct', valor: 0.15 } },

  { id: 'k_lend25', cat: 'colecao', icone: '🔆', pontos: 50,
    nome: 'Lendas São Comuns Aqui', nomeEn: 'Legends Are Common Here',
    desc: 'Encontre 25 cartas lendárias. A palavra perdeu o sentido nesta torre.',
    descEn: 'Find 25 legendary cards. The word lost its meaning in this tower.',
    cond: { tipo: 'lendarios', valor: 25 },
    recompensa: { tipo: 'stat', stat: 'chanceDrop', tipoEfeito: 'mult', valor: 1.35 } },

  { id: 'k_relicas5', cat: 'colecao', icone: '🦴', pontos: 10,
    nome: 'Prateleira de Ossos', nomeEn: 'Shelf of Bones',
    desc: 'Adquira 5 relíquias distintas. Cada uma pertenceu a alguém que falhou primeiro.',
    descEn: 'Acquire 5 distinct relics. Each belonged to someone who failed first.',
    cond: { tipo: 'relicas', valor: 5 },
    recompensa: { tipo: 'fragmentos', valor: 50 } },

  { id: 'k_relicas20', cat: 'colecao', icone: '🏺', pontos: 25,
    nome: 'Museu Particular', nomeEn: 'Private Museum',
    desc: 'Adquira 20 relíquias distintas. Entrada franca; ninguém vem.',
    descEn: 'Acquire 20 distinct relics. Free admission; nobody comes.',
    cond: { tipo: 'relicas', valor: 20 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.15 } },

  { id: 'k_relicas40', cat: 'colecao', icone: '🕰️', pontos: 50,
    nome: 'Curador do Fim', nomeEn: 'Curator of the End',
    desc: 'Adquira 40 relíquias distintas. Você catalogou o apocalipse por ordem alfabética.',
    descEn: 'Acquire 40 distinct relics. You alphabetized the apocalypse.',
    cond: { tipo: 'relicas', valor: 40 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.3 } },

  { id: 'k_maestria', cat: 'colecao', icone: '⚔️', pontos: 25,
    nome: 'Maestria Não Basta', nomeEn: 'Mastery Is Not Enough',
    desc: 'Leve Maestria da Fúria ao nível 10. Ainda vai faltar dano. Sempre falta.',
    descEn: 'Take Fury Mastery to level 10. It will still not be enough. It never is.',
    cond: { tipo: 'talentoNivel', chave: 'f_maestria', valor: 10 },
    recompensa: { tipo: 'pontosTalento', valor: 3 } },

  { id: 'k_missoes50', cat: 'colecao', icone: '📋', pontos: 10,
    nome: 'Lista de Tarefas Infinita', nomeEn: 'Infinite To-Do List',
    desc: 'Complete 50 missões. Riscar itens é a única vitória garantida aqui.',
    descEn: 'Complete 50 missions. Crossing items off is the only guaranteed win here.',
    cond: { tipo: 'missoesCompletas', valor: 50 },
    recompensa: { tipo: 'gemas', valor: 50 } },

  { id: 'k_desafios10', cat: 'colecao', icone: '⛓️', pontos: 25,
    nome: 'Masoquismo Estruturado', nomeEn: 'Structured Masochism',
    desc: 'Vença 10 desafios. Regras piores, prêmios melhores, você bem pior.',
    descEn: 'Beat 10 challenges. Worse rules, better prizes, much worse you.',
    cond: { tipo: 'desafiosCompletos', valor: 10 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.12 } },

  /* ==================================================================== */
  /* PRESTÍGIO · desmontar a torre é a jogada mais forte do jogo            */
  /* ==================================================================== */

  { id: 'r_asc1', cat: 'prestigio', icone: '💠', pontos: 5,
    nome: 'A Primeira Poeira', nomeEn: 'The First Dust',
    desc: 'Ascenda pela primeira vez. Doeu menos do que você imaginava.',
    descEn: 'Ascend for the first time. It hurt less than you expected.',
    cond: { tipo: 'ascensoes', valor: 1 },
    recompensa: { tipo: 'gemas', valor: 15 } },

  { id: 'r_asc10', cat: 'prestigio', icone: '🔄', pontos: 10,
    nome: 'Hábito Ruim', nomeEn: 'Bad Habit',
    desc: 'Ascenda 10 vezes. Você já demole a torre antes mesmo de precisar.',
    descEn: 'Ascend 10 times. You demolish the tower before you even need to.',
    cond: { tipo: 'ascensoes', valor: 10 },
    recompensa: { tipo: 'stat', stat: 'ganhoFrag', tipoEfeito: 'pct', valor: 0.1 } },

  { id: 'r_asc50', cat: 'prestigio', icone: '🌀', pontos: 25,
    nome: 'Ciclo Vicioso', nomeEn: 'Vicious Cycle',
    desc: 'Ascenda 50 vezes. Construir virou apenas o intervalo entre duas quedas.',
    descEn: 'Ascend 50 times. Building is just the gap between two collapses.',
    cond: { tipo: 'ascensoes', valor: 50 },
    recompensa: { tipo: 'stat', stat: 'ganhoFrag', tipoEfeito: 'mult', valor: 1.2 } },

  { id: 'r_asc250', cat: 'prestigio', icone: '🪦', pontos: 50,
    nome: 'A Torre Não Aprende', nomeEn: 'The Tower Never Learns',
    desc: 'Ascenda 250 vezes. A poeira lembra de tudo; a torre insiste em esquecer.',
    descEn: 'Ascend 250 times. The dust remembers everything; the tower insists on forgetting.',
    cond: { tipo: 'ascensoes', valor: 250 },
    recompensa: { tipo: 'stat', stat: 'ganhoFrag', tipoEfeito: 'mult', valor: 1.5 } },

  { id: 'r_sing1', cat: 'prestigio', icone: '🌌', pontos: 10,
    nome: 'O Ponto Piscou', nomeEn: 'The Point Blinked',
    desc: 'Colapse pela primeira vez. Mil torres couberam num lugar sem tamanho.',
    descEn: 'Collapse for the first time. A thousand towers fit somewhere with no size.',
    cond: { tipo: 'singularidades', valor: 1 },
    recompensa: { tipo: 'gemas', valor: 75 } },

  { id: 'r_sing5', cat: 'prestigio', icone: '🕳️', pontos: 25,
    nome: 'Colapso Recreativo', nomeEn: 'Recreational Collapse',
    desc: 'Colapse 5 vezes. Já não é desespero; é passatempo.',
    descEn: 'Collapse 5 times. It stopped being desperation; now it is a hobby.',
    cond: { tipo: 'singularidades', valor: 5 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.2 } },

  { id: 'r_sing25', cat: 'prestigio', icone: '🧲', pontos: 50,
    nome: 'Gravidade Pessoal', nomeEn: 'Personal Gravity',
    desc: 'Colapse 25 vezes. Coisas caem na sua direção sem que você peça.',
    descEn: 'Collapse 25 times. Things fall toward you without being asked.',
    cond: { tipo: 'singularidades', valor: 25 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.5 } },

  { id: 'r_trans1', cat: 'prestigio', icone: '✴️', pontos: 25,
    nome: 'Do Outro Lado do Vidro', nomeEn: 'Behind the Glass',
    desc: 'Transcenda pela primeira vez. Agora você sabe quem estava olhando.',
    descEn: 'Transcend for the first time. Now you know who was watching.',
    cond: { tipo: 'transcendencias', valor: 1 },
    recompensa: { tipo: 'gemas', valor: 250 } },

  { id: 'r_trans5', cat: 'prestigio', icone: '🌠', pontos: 50,
    nome: 'Reincidente Cósmico', nomeEn: 'Cosmic Repeat Offender',
    desc: 'Transcenda 5 vezes. Nem o fim do jogo consegue te manter do lado de fora.',
    descEn: 'Transcend 5 times. Not even the ending can keep you outside.',
    cond: { tipo: 'transcendencias', valor: 5 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 2 } },

  { id: 'r_global150', cat: 'prestigio', icone: '📍', pontos: 10,
    nome: 'Limiar do Colapso', nomeEn: 'Collapse Threshold',
    desc: 'Registre a onda 150 no seu recorde global. A Singularidade já está te encarando.',
    descEn: 'Log wave 150 on your all-time record. The Singularity is already staring.',
    cond: { tipo: 'ondaMaximaGlobal', valor: 150 },
    recompensa: { tipo: 'fragmentos', valor: 120 } },

  { id: 'r_global500', cat: 'prestigio', icone: '🔮', pontos: 25,
    nome: 'Marca do Éter', nomeEn: 'Ether Mark',
    desc: 'Registre a onda 500 no seu recorde global. A partir daqui, o jogo muda de regra.',
    descEn: 'Log wave 500 on your all-time record. Past this, the rules change.',
    cond: { tipo: 'ondaMaximaGlobal', valor: 500 },
    recompensa: { tipo: 'gemas', valor: 300 } },

  { id: 'r_global2000', cat: 'prestigio', icone: '🌑', pontos: 50,
    nome: 'Além do Registro', nomeEn: 'Beyond the Record',
    desc: 'Registre a onda 2000 no seu recorde global. Não há mais com quem comparar.',
    descEn: 'Log wave 2000 on your all-time record. There is nobody left to compare with.',
    cond: { tipo: 'ondaMaximaGlobal', valor: 2000 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.7 } },

  /* ==================================================================== */
  /* SEGREDOS · dez coisas que ninguém deveria ter tentado de propósito     */
  /* ==================================================================== */

  { id: 's_666', cat: 'segredos', icone: '🐐', pontos: 25, oculta: true,
    nome: 'Coincidência Infeliz', nomeEn: 'Unfortunate Coincidence',
    desc: 'Chegue à onda 666. Ninguém planejou o número. Ninguém acredita nisso.',
    descEn: 'Reach wave 666. Nobody planned the number. Nobody believes that.',
    cond: { tipo: 'onda', valor: 666 },
    recompensa: { tipo: 'gemas', valor: 166 } },

  { id: 's_mortes100', cat: 'segredos', icone: '🧱', pontos: 25, oculta: true,
    nome: 'Especialista em Fracasso', nomeEn: 'Failure Specialist',
    desc: 'Perca a torre 100 vezes. É preciso um tipo raro de talento para ser tão ruim com tanta constância.',
    descEn: 'Lose the tower 100 times. It takes rare talent to be this bad this consistently.',
    cond: { tipo: 'mortes', valor: 100 },
    recompensa: { tipo: 'stat', stat: 'vidaMax', tipoEfeito: 'mult', valor: 1.25 } },

  { id: 's_tiros7', cat: 'segredos', icone: '7️⃣', pontos: 25, oculta: true,
    nome: 'Sete Setes', nomeEn: 'Seven Sevens',
    desc: 'Dispare exatamente 7.777.777 tiros. Nós contamos. Você, claramente, não.',
    descEn: 'Fire 7,777,777 shots. We counted. You clearly did not.',
    cond: { tipo: 'tiros', valor: 7777777 },
    recompensa: { tipo: 'stat', stat: 'cadencia', tipoEfeito: 'mult', valor: 1.15 } },

  { id: 's_dourados777', cat: 'segredos', icone: '🎲', pontos: 50, oculta: true,
    nome: 'Máquina Caça-Níqueis', nomeEn: 'Slot Machine',
    desc: 'Abata 777 inimigos dourados. Três setes: a torre pagou o prêmio e fugiu da cidade.',
    descEn: 'Kill 777 golden enemies. Triple sevens: the tower paid out and left town.',
    cond: { tipo: 'douradosAbatidos', valor: 777 },
    recompensa: { tipo: 'stat', stat: 'sorte', tipoEfeito: 'mult', valor: 1.5 } },

  { id: 's_tempo100h', cat: 'segredos', icone: '🛏️', pontos: 50, oculta: true,
    nome: 'Vida Útil', nomeEn: 'Shelf Life',
    desc: 'Acumule 100 horas de jogo. A torre está ótima. E você, como está?',
    descEn: 'Log 100 hours of play. The tower is doing great. And you?',
    cond: { tipo: 'tempoTotal', valor: 360000 },
    recompensa: { tipo: 'stat', stat: 'ganhoXP', tipoEfeito: 'mult', valor: 1.5 } },

  { id: 's_combo1000', cat: 'segredos', icone: '⛓️', pontos: 50, oculta: true,
    nome: 'Corrente Ininterrupta', nomeEn: 'Unbroken Chain',
    desc: 'Alcance um combo de 1.000. Mil abates sem uma única pausa para respirar.',
    descEn: 'Reach a 1,000 combo. A thousand kills without one breath in between.',
    cond: { tipo: 'comboMaximo', valor: 1000 },
    recompensa: { tipo: 'stat', stat: 'ganhoOuro', tipoEfeito: 'mult', valor: 1.5 } },

  { id: 's_conquistas75', cat: 'segredos', icone: '🏆', pontos: 50, oculta: true,
    nome: 'Caçador de Troféus', nomeEn: 'Trophy Hunter',
    desc: 'Desbloqueie 75 conquistas — inclusive esta, que se conta sozinha. Não pergunte.',
    descEn: 'Unlock 75 achievements — including this one, which counts itself. Do not ask.',
    cond: { tipo: 'conquistasTotal', valor: 75 },
    recompensa: { tipo: 'stat', stat: 'multiplicador', tipoEfeito: 'mult', valor: 1.25 } },

  { id: 's_silencio13', cat: 'segredos', icone: '🤫', pontos: 50, oculta: true,
    nome: 'Treze Silêncios', nomeEn: 'Thirteen Silences',
    desc: 'Derrote O Silêncio 13 vezes. Ele nunca comentou nada a respeito.',
    descEn: 'Defeat The Silence 13 times. It never commented on any of it.',
    cond: { tipo: 'inimigoTipo', chave: 'o_silencio', valor: 13 },
    recompensa: { tipo: 'fragmentos', valor: 5000 } },

  { id: 's_dado13', cat: 'segredos', icone: '🍀', pontos: 25, oculta: true,
    nome: 'Superstição Aplicada', nomeEn: 'Applied Superstition',
    desc: 'Leve o Dado Viciado ao nível 13. Você não acredita em azar — só está se prevenindo.',
    descEn: 'Take the Loaded Dice to level 13. You do not believe in bad luck; you are just hedging.',
    cond: { tipo: 'upgradeNivel', chave: 'sorte', valor: 13 },
    recompensa: { tipo: 'stat', stat: 'sorte', tipoEfeito: 'pct', valor: 0.13 } },

  { id: 's_hab10k', cat: 'segredos', icone: '🖱️', pontos: 25, oculta: true,
    nome: 'Diagnóstico: Túnel do Carpo', nomeEn: 'Diagnosis: Carpal Tunnel',
    desc: 'Use habilidades 10.000 vezes. O jogo é idle. Alguém devia ter te avisado.',
    descEn: 'Use abilities 10,000 times. This is an idle game. Someone should have mentioned it.',
    cond: { tipo: 'habilidadesUsadas', valor: 10000 },
    recompensa: { tipo: 'stat', stat: 'duracaoHab', tipoEfeito: 'mult', valor: 1.3 } },
];

export const CONQUISTA_POR_ID = Object.fromEntries(CONQUISTAS.map((c) => [c.id, c]));

/** Soma de todos os pontos possíveis — o "100%" da barra de conclusão. */
export const PONTOS_TOTAIS = CONQUISTAS.reduce((s, c) => s + c.pontos, 0);
