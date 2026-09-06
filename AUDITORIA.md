# Auditoria de jogo Godot — checklist estado da arte

Lista de auditoria sênior. Do zero absoluto até o jogo à venda na Steam.
Cada item recebe nota de 0 a 10. `N/A` para o que não se aplica ao gênero.

**Escala:** 0 inexistente · 1-2 quebrado · 3-4 rascunho · 5-6 funciona com falhas ·
7-8 sólido · 9 polido · 10 referência de mercado.

**Fases:** `P` protótipo · `A` alpha · `B` beta · `G` gold/lançamento.

---

## A. Conceito, visão e escopo

- A1 `__/10` — High concept cabe em uma frase que qualquer pessoa entende
- A2 `__/10` — Gênero declarado e coerente com o que o jogo realmente é
- A3 `__/10` — Fantasia do jogador definida ("eu sou um ___ que ___")
- A4 `__/10` — Pilares de design (3 a 5) escritos e usados para decidir
- A5 `__/10` — Proposta única de valor clara contra os concorrentes diretos
- A6 `__/10` — Jogos de referência listados com o que se pega e o que não se pega
- A7 `__/10` — Público-alvo definido (idade, plataforma, hábito, tempo de sessão)
- A8 `__/10` — Escopo negativo escrito: a lista do que o jogo NÃO terá
- A9 `__/10` — Escopo cabe no tempo, no orçamento e no tamanho da equipe
- A10 `__/10` — Risco maior do projeto identificado e mitigado
- A11 `__/10` — Critérios de morte do projeto (kill criteria) definidos
- A12 `__/10` — Prova de diversão feita antes da produção (fun first)
- A13 `__/10` — Vertical slice representativo do jogo final
- A14 `__/10` — Duração alvo da campanha/run declarada e medida
- A15 `__/10` — Plataformas alvo declaradas desde o começo
- A16 `__/10` — Modelo de negócio definido (preço, demo, DLC, F2P)
- A17 `__/10` — Nome do jogo disponível, buscável e registrável
- A18 `__/10` — Marco de "conteúdo completo" separado de "polimento completo"
- A19 `__/10` — Escopo congelado a partir da beta, com processo de exceção
- A20 `__/10` — Visão comunicada igualmente a todos os envolvidos

## B. Documentação de design

- B1 `__/10` — GDD existe, está atualizado e é usado (não é peça de museu)
- B2 `__/10` — Cada mecânica descrita com entrada, regra e saída
- B3 `__/10` — Diagrama do loop principal e dos loops secundários
- B4 `__/10` — Tabelas de números centralizadas em um único lugar
- B5 `__/10` — Glossário de termos do domínio (mesmo nome no código e no texto)
- B6 `__/10` — Decisões de arquitetura registradas (ADR) com motivo
- B7 `__/10` — Especificação por fatia antes de codar (spec-driven)
- B8 `__/10` — Critérios de aceite testáveis por feature
- B9 `__/10` — Backlog priorizado e visível
- B10 `__/10` — Roadmap com marcos datados
- B11 `__/10` — Registro de aprendizados e de erros que custaram tempo
- B12 `__/10` — Documentação de onboarding para alguém novo entrar em 1 dia
- B13 `__/10` — Changelog por versão
- B14 `__/10` — Checklist de release escrito e seguido
- B15 `__/10` — Documentação versionada junto com o código

## C. Estrutura do projeto Godot

- C1 `__/10` — Versão da engine travada, documentada e igual em todas as máquinas
- C2 `__/10` — Renderizador escolhido (Forward+/Mobile/Compatibility) coerente com o alvo
- C3 `__/10` — `project.godot` limpo, sem sobras de experimento
- C4 `__/10` — Cena principal definida e abrindo
- C5 `__/10` — Estrutura de pastas consistente (cenas/scripts/assets/testes)
- C6 `__/10` — Convenção de nomes única para arquivo, nó, classe, sinal e ação
- C7 `__/10` — Arquivos `.uid` versionados no git
- C8 `__/10` — Arquivos `.import` versionados no git
- C9 `__/10` — `.godot/`, `.import/` de cache e builds fora do git
- C10 `__/10` — `.gitattributes` com LFS configurado antes do primeiro binário
- C11 `__/10` — Tamanho do repositório sob controle, sem binário morto no histórico
- C12 `__/10` — Autoloads mínimos, com ordem de carga correta e sem ciclo
- C13 `__/10` — Nenhum autoload que poderia ser um recurso ou uma função pura
- C14 `__/10` — Addons de terceiros auditados, versionados e com licença clara
- C15 `__/10` — GDExtensions compilando para todas as plataformas alvo
- C16 `__/10` — Nenhuma referência `res://` quebrada em cena ou em código
- C17 `__/10` — Nenhum arquivo órfão (asset importado que ninguém usa)
- C18 `__/10` — Resoluções base e modo de esticar (stretch) configurados
- C19 `__/10` — Camadas de física, de render e de canvas nomeadas no projeto
- C20 `__/10` — Input map completo no projeto, não montado por código solto
- C21 `__/10` — Configurações de projeto por plataforma (overrides) revisadas
- C22 `__/10` — Templates de script padronizados
- C23 `__/10` — Projeto abre limpo em máquina nova, sem passo manual escondido
- C24 `__/10` — Portão estrutural automatizado roda e passa (cena, autoload, parse, ref, uid)

## D. Arquitetura de código

- D1 `__/10` — Lógica de regra isolada em funções puras, sem nó e sem estado global
- D2 `__/10` — Camada de apresentação separada da camada de regra
- D3 `__/10` — Acoplamento baixo entre cenas; cena filha não conhece a mãe
- D4 `__/10` — Sinais usados para subir informação, chamadas para descer
- D5 `__/10` — Sem `get_node("../../")` frágil espalhado
- D6 `__/10` — Máquinas de estado explícitas onde há estado (jogador, inimigo, jogo)
- D7 `__/10` — Barramento de eventos com contrato documentado, se existir
- D8 `__/10` — Composição preferida à herança profunda
- D9 `__/10` — Design orientado a dados (Resource/CSV/JSON) para conteúdo
- D10 `__/10` — Injeção de dependência em vez de singleton onde é possível
- D11 `__/10` — Determinismo garantido onde importa (RNG com semente)
- D12 `__/10` — `_process` vs `_physics_process` usados corretamente
- D13 `__/10` — Nada de lógica pesada dentro de `_process` sem necessidade
- D14 `__/10` — Ordem de execução entre sistemas definida, não acidental
- D15 `__/10` — `await`, corrotinas e threads sem condição de corrida
- D16 `__/10` — `queue_free()` usado corretamente; sem acesso a nó liberado
- D17 `__/10` — Sem referência cíclica forte causando vazamento
- D18 `__/10` — Pool de objetos onde há criação/destruição em massa
- D19 `__/10` — Carregamento pesado é assíncrono, não trava o frame
- D20 `__/10` — Camada de plataforma isolada (Steam, salvamento, sistema de arquivos)
- D21 `__/10` — Código de depuração isolado e removível do build final
- D22 `__/10` — Nenhuma dependência circular entre cenas ou scripts
- D23 `__/10` — Arquitetura suporta a próxima feature sem reescrita

## E. Qualidade do código

- E1 `__/10` — Tipagem estática em toda a base (GDScript tipado)
- E2 `__/10` — Zero avisos do compilador e do linter
- E3 `__/10` — Zero erro de parse em qualquer script, compilado do disco
- E4 `__/10` — Funções curtas, com uma responsabilidade
- E5 `__/10` — Sem número mágico solto; constantes nomeadas
- E6 `__/10` — Sem duplicação de lógica em dois lugares
- E7 `__/10` — Nomes em um idioma só, consistentes com o glossário
- E8 `__/10` — Código morto e comentado removido
- E9 `__/10` — TODO/FIXME rastreados no backlog, não abandonados no arquivo
- E10 `__/10` — Comentários explicam o porquê, não o quê
- E11 `__/10` — Tratamento de erro explícito em I/O, rede e parse
- E12 `__/10` — Sem `print` de depuração vazando para o build
- E13 `__/10` — Chamadas de API da engine todas existentes na versão usada
- E14 `__/10` — Formatação automática aplicada por igual
- E15 `__/10` — Revisão de código acontecendo antes do merge
- E16 `__/10` — Complexidade ciclomática sob controle nos pontos críticos
- E17 `__/10` — Sem `class_name` duplicado ou colidindo com a engine

## F. Dados, recursos e conteúdo

- F1 `__/10` — Conteúdo em dados, não em código (inimigos, itens, fases, diálogos)
- F2 `__/10` — Recursos customizados com `class_name` e validação
- F3 `__/10` — Um só lugar para os números de balanceamento
- F4 `__/10` — Planilha/tabela de conteúdo sincronizada com o jogo
- F5 `__/10` — Identificadores estáveis (mudar nome de exibição não quebra save)
- F6 `__/10` — Validação de dados na carga, com erro legível
- F7 `__/10` — Sem recurso duplicado por engano (mesma textura em três lugares)
- F8 `__/10` — Catálogo de assets indexado, com o caminho `res://` exato
- F9 `__/10` — Nenhum caminho de asset escrito de memória
- F10 `__/10` — Conteúdo escalável: adicionar o 50º item não exige tocar em código

## G. Loop de jogo e mecânicas

- G1 `__/10` — Verbo principal identificado e gostoso de executar sozinho
- G2 `__/10` — Loop central (segundos) claro e satisfatório
- G3 `__/10` — Loop médio (minutos) com objetivo e recompensa
- G4 `__/10` — Loop longo (horas) com progressão perceptível
- G5 `__/10` — Tempo até a primeira diversão medido e curto
- G6 `__/10` — Decisões do jogador são significativas, não obrigatórias
- G7 `__/10` — Regras consistentes; a mesma ação dá o mesmo resultado
- G8 `__/10` — Sem estratégia dominante que apaga as outras
- G9 `__/10` — Sem opção inútil que ninguém escolheria
- G10 `__/10` — Profundidade sem complexidade desnecessária
- G11 `__/10` — Sistemas conversam entre si (emergência), não vivem em silos
- G12 `__/10` — Risco e recompensa equilibrados nas escolhas
- G13 `__/10` — Condição de vitória e de derrota claras a todo momento
- G14 `__/10` — Punição por falha proporcional; retomada rápida
- G15 `__/10` — Sem beco sem saída, softlock ou estado invencível
- G16 `__/10` — Exploits conhecidos mapeados e decididos (corrigir ou aceitar)
- G17 `__/10` — Quebra de sequência (sequence break) prevista ou bloqueada
- G18 `__/10` — Rejogabilidade compatível com a promessa do gênero
- G19 `__/10` — Cada mecânica ensinada, usada, complicada e recompensada
- G20 `__/10` — Mecânica sem uso real foi cortada, não escondida
- G21 `__/10` — O jogo é divertido sem áudio, sem VFX e sem história

## H. Progressão, economia e balanceamento

- H1 `__/10` — Curva de poder do jogador desenhada, não improvisada
- H2 `__/10` — Curva de desafio acompanha a curva de poder
- H3 `__/10` — Fontes e ralos de cada moeda mapeados e fechando
- H4 `__/10` — Inflação e deflação testadas em partida longa
- H5 `__/10` — Preços da loja validados por simulação, não por intuição
- H6 `__/10` — Custo de oportunidade real em cada compra
- H7 `__/10` — Recompensa por tempo investido percebida como justa
- H8 `__/10` — Meta-progressão não trivializa a habilidade
- H9 `__/10` — Sem efeito bola de neve que decide a partida cedo demais
- H10 `__/10` — Sem espiral de morte de onde não se recupera
- H11 `__/10` — Simulação Monte Carlo determinística rodando sobre as regras reais
- H12 `__/10` — Simulação usa as MESMAS funções puras do jogo, sem segunda implementação
- H13 `__/10` — Três políticas de habilidade testadas (ruim, médio, bom) e todas fechando
- H14 `__/10` — Alertas do simulador limpos (nada inalcançável, nada trivial)
- H15 `__/10` — Taxa de vitória por fase dentro da faixa alvo
- H16 `__/10` — Duração de partida medida, não estimada
- H17 `__/10` — Sensibilidade testada: mudar 10% em um número não quebra tudo
- H18 `__/10` — Aleatoriedade limitada por piso/teto (sem run impossível)
- H19 `__/10` — Aleatoriedade percebida como justa (pity timer onde couber)
- H20 `__/10` — Todo número alterado foi seguido de nova simulação

## I. Dificuldade, curva e ritmo

- I1 `__/10` — Primeira hora testada com jogador que nunca viu o jogo
- I2 `__/10` — Introdução de conceitos espaçada, um de cada vez
- I3 `__/10` — Picos e vales de tensão desenhados, não planos
- I4 `__/10` — Momento de descanso após pico
- I5 `__/10` — Nenhuma parede de dificuldade acidental
- I6 `__/10` — Dificuldade ajustável, com efeito explicado ao jogador
- I7 `__/10` — Modo fácil não é insultuoso; modo difícil não é injusto
- I8 `__/10` — Assistências opcionais separadas da dificuldade (mira, vida, tempo)
- I9 `__/10` — Morte ensina o que fazer diferente
- I10 `__/10` — Tempo de retomada após falha abaixo de poucos segundos
- I11 `__/10` — Repetição de trecho longo após morte eliminada
- I12 `__/10` — Ritmo do endgame não vira grind vazio
- I13 `__/10` — Onde o jogador desiste está medido (funil de abandono)
- I14 `__/10` — Dificuldade adaptativa, se existir, é invisível e honesta

## J. Level design e conteúdo

- J1 `__/10` — Cada fase tem intenção declarada (o que ensina/testa)
- J2 `__/10` — Layout legível: o jogador sabe para onde ir sem seta
- J3 `__/10` — Marcos visuais e linhas de leitura funcionando
- J4 `__/10` — Sem geometria onde o jogador prende, cai ou sai do mundo
- J5 `__/10` — Limites do mundo intencionais e visíveis
- J6 `__/10` — Colisão bate com o visual (nada invisível bloqueando)
- J7 `__/10` — Checkpoints em intervalos justos
- J8 `__/10` — Segredos e conteúdo opcional recompensam a curiosidade
- J9 `__/10` — Densidade de conteúdo constante, sem trecho vazio
- J10 `__/10` — Reuso de peças não fica óbvio nem cansativo
- J11 `__/10` — Escala coerente com o personagem em todas as áreas
- J12 `__/10` — Navegação e pathfinding validados em todo o mapa
- J13 `__/10` — Iluminação guia o caminho
- J14 `__/10` — Áudio ambiente diferencia as áreas
- J15 `__/10` — Todos os cantos testados por bot ou por playtest
- J16 `__/10` — Quantidade de conteúdo bate com a promessa da loja

## K. Geração procedural (se aplicável)

- K1 `__/10` — Semente controlada e reproduzível
- K2 `__/10` — Toda saída gerada é jogável e completável (validador automático)
- K3 `__/10` — Sem geração degenerada (sala vazia, corredor infinito, ilha isolada)
- K4 `__/10` — Variedade percebida real, não só ruído
- K5 `__/10` — Ritmo garantido mesmo sendo aleatório
- K6 `__/10` — Tempo de geração dentro do orçamento de frame
- K7 `__/10` — Milhares de sementes testadas em lote
- K8 `__/10` — Semente exposta ao jogador (compartilhar/refazer), se fizer sentido
- K9 `__/10` — Conteúdo autoral misturado ao gerado onde aumenta a qualidade

## L. IA de inimigos e NPCs

- L1 `__/10` — Comportamento legível: o jogador entende o que a IA vai fazer
- L2 `__/10` — Telegrafia de ataque clara e com tempo justo
- L3 `__/10` — Estados bem definidos, sem travar em transição
- L4 `__/10` — Pathfinding sem inimigo preso em quina ou em porta
- L5 `__/10` — Percepção (visão/audição) com regras compreensíveis
- L6 `__/10` — Perda de alvo e retorno ao posto funcionam
- L7 `__/10` — Grupos coordenam sem virar muro nem virar fila
- L8 `__/10` — IA não trapaceia de forma perceptível
- L9 `__/10` — Variedade de comportamento entre tipos de inimigo
- L10 `__/10` — Chefes com fases, leitura e contra-jogo
- L11 `__/10` — Custo de CPU da IA medido com o pior número de agentes
- L12 `__/10` — IA de aliado não atrapalha nem morre sozinha
- L13 `__/10` — NPC de serviço (loja, missão) sem estado inconsistente

## M. Input e controles

- M1 `__/10` — Latência de input medida e baixa
- M2 `__/10` — Resposta em 1 frame para a ação principal
- M3 `__/10` — Buffer de input nas ações que precisam
- M4 `__/10` — Janelas de perdão (coyote time, input antecipado) calibradas
- M5 `__/10` — Teclado + mouse completos e confortáveis
- M6 `__/10` — Gamepad completo: Xbox, PlayStation, Switch e genéricos
- M7 `__/10` — Troca de dispositivo em tempo real, sem reiniciar
- M8 `__/10` — Ícones de botão mudam conforme o controle conectado
- M9 `__/10` — Conexão/desconexão a quente tratada (pausa e avisa)
- M10 `__/10` — Remapeamento completo de todas as ações
- M11 `__/10` — Detecção de conflito ao remapear
- M12 `__/10` — Restaurar padrão disponível
- M13 `__/10` — Remapeamento persiste no save de configuração
- M14 `__/10` — Zona morta configurável dos analógicos
- M15 `__/10` — Sensibilidade e inversão de eixo por eixo
- M16 `__/10` — Alternativa a segurar botão (toggle) em toda ação de segurar
- M17 `__/10` — Nenhum QTE ou martelar de botão obrigatório sem alternativa
- M18 `__/10` — Vibração implementada, ajustável e desligável
- M19 `__/10` — Menu inteiro navegável só com teclado
- M20 `__/10` — Menu inteiro navegável só com gamepad
- M21 `__/10` — Foco inicial correto em cada tela
- M22 `__/10` — Navegação de foco previsível, sem item inalcançável
- M23 `__/10` — Botão de voltar/cancelar consistente em todas as telas
- M24 `__/10` — Mouse e gamepad convivem sem o cursor sumir ou brigar com o foco
- M25 `__/10` — Captura do mouse liberada ao pausar e ao perder foco da janela
- M26 `__/10` — Steam Input configurado com layout oficial
- M27 `__/10` — Controles de jogo e de menu documentados dentro do jogo

## N. Câmera

- N1 `__/10` — Enquadramento mostra o que o jogador precisa decidir
- N2 `__/10` — Seguimento suave, sem tremor e sem atraso incômodo
- N3 `__/10` — Antecipação (look-ahead) na direção do movimento
- N4 `__/10` — Zona morta evita micro-movimento constante
- N5 `__/10` — Limites de câmera sem mostrar fora do cenário
- N6 `__/10` — Transição entre câmeras/áreas sem corte brusco
- N7 `__/10` — Colisão de câmera 3D sem atravessar parede
- N8 `__/10` — Sem clipping do personagem na câmera próxima
- N9 `__/10` — FOV ajustável (3D) com faixa segura
- N10 `__/10` — Tremor de tela ajustável e desligável
- N11 `__/10` — Balanço de cabeça, motion blur e distorção com toggle
- N12 `__/10` — Suporte a 16:9, 16:10, 21:9 e 4:3 sem cortar informação
- N13 `__/10` — Área segura respeitada nas bordas
- N14 `__/10` — Zoom com limites e sem enjoar
- N15 `__/10` — Câmera nunca perde o jogador de vista

## O. Física e colisão

- O1 `__/10` — Tipo de corpo correto para cada objeto
- O2 `__/10` — Camadas e máscaras nomeadas, documentadas em matriz
- O3 `__/10` — Nenhuma colisão indesejada entre camadas
- O4 `__/10` — Sem tunelamento em alta velocidade (CCD onde precisa)
- O5 `__/10` — Formas primitivas preferidas a malha de colisão
- O6 `__/10` — Escala do mundo coerente (1 unidade = 1 metro no 3D)
- O7 `__/10` — Gravidade, atrito e restituição afinados e centralizados
- O8 `__/10` — Rampas, degraus e plataformas de mão única funcionando
- O9 `__/10` — Sem jitter em contato ou em canto
- O10 `__/10` — Física independente do framerate
- O11 `__/10` — Física determinística onde a simulação exige
- O12 `__/10` — Custo de física medido no pior caso de objetos
- O13 `__/10` — Detecção de área (trigger) sem disparo duplo ou perdido
- O14 `__/10` — Raycast e shapecast usados com máscara certa
- O15 `__/10` — Objetos nunca caem para fora do mundo sem recuperação

## P. Arte 2D

- P1 `__/10` — Direção de arte única e reconhecível
- P2 `__/10` — Paleta definida e respeitada em todo o jogo
- P3 `__/10` — Contraste separa jogador, inimigo, cenário e item coletável
- P4 `__/10` — Silhuetas distinguíveis mesmo em preto
- P5 `__/10` — Resolução base definida e todo asset feito para ela
- P6 `__/10` — Pixel art sem filtro, sem escala fracionada e sem borrão
- P7 `__/10` — Sem sangramento de textura em atlas e tileset
- P8 `__/10` — Configuração de importação padronizada por tipo de asset
- P9 `__/10` — Compressão de textura adequada por plataforma
- P10 `__/10` — Consumo de VRAM medido
- P11 `__/10` — Ordem de desenho (z-index/camadas) organizada e sem briga
- P12 `__/10` — Parallax coerente com a profundidade
- P13 `__/10` — Tileset com transições e cantos completos
- P14 `__/10` — Iluminação 2D e normal maps consistentes, se usados
- P15 `__/10` — Sem asset de rascunho no build final
- P16 `__/10` — Arte de placeholder claramente marcada enquanto existir
- P17 `__/10` — Ícones e HUD legíveis na menor resolução suportada
- P18 `__/10` — Coerência entre arte de UI e arte de jogo

## Q. Arte 3D

- Q1 `__/10` — Contagem de polígonos dentro do orçamento por categoria
- Q2 `__/10` — LOD configurado onde há distância
- Q3 `__/10` — Escala real, transform aplicado, pivô no lugar certo
- Q4 `__/10` — UV sem sobreposição indevida e com densidade de texel uniforme
- Q5 `__/10` — Fluxo PBR correto (albedo sem sombra assada indevida)
- Q6 `__/10` — Normal, roughness, metallic e AO nos canais certos
- Q7 `__/10` — Materiais compartilhados; número de materiais sob controle
- Q8 `__/10` — Atlas de textura reduzindo drawcalls
- Q9 `__/10` — Instancing/MultiMesh para vegetação e repetição
- Q10 `__/10` — Culling por frustum e por oclusão ativos e testados
- Q11 `__/10` — Esqueleto limpo, sem osso inútil, com nomes padronizados
- Q12 `__/10` — Retarget funcionando entre modelos
- Q13 `__/10` — Blend shapes/morph targets nomeados e usados
- Q14 `__/10` — Anexo ao osso sem herdar escala errada
- Q15 `__/10` — Importação com perfil por tipo (personagem, cenário, prop)
- Q16 `__/10` — Materiais externos batendo com o que veio no `.glb`
- Q17 `__/10` — Colisão gerada adequada (não trimesh para tudo)
- Q18 `__/10` — Coerência de estilo entre pacotes de assets diferentes

## R. Iluminação, ambiente e pós-processamento

- R1 `__/10` — Intenção de iluminação por área (humor, leitura, foco)
- R2 `__/10` — Luz direcional, ambiente e pontual equilibradas
- R3 `__/10` — Sombras com resolução, alcance e bias sem artefato
- R4 `__/10` — Cascatas ajustadas para o alcance real da câmera
- R5 `__/10` — Iluminação global escolhida conscientemente (SDFGI, lightmap, VoxelGI)
- R6 `__/10` — Lightmaps assados onde a cena é estática
- R7 `__/10` — Reflection probes cobrindo os ambientes internos
- R8 `__/10` — WorldEnvironment com céu, névoa e tonemapping coerentes
- R9 `__/10` — Exposição e brilho legíveis em monitor escuro e claro
- R10 `__/10` — Bloom, SSAO, SSR e vinheta com custo medido
- R11 `__/10` — Todo pós-processamento agressivo tem toggle
- R12 `__/10` — Sem cintilação (flicker) de sombra ou de luz em movimento
- R13 `__/10` — Luz volumétrica e névoa não escondem informação de jogo
- R14 `__/10` — Modo de brilho com imagem de referência no menu
- R15 `__/10` — Iluminação coerente entre dia/noite e entre cenas

## S. Shaders e materiais

- S1 `__/10` — Shaders compilam em todos os renderizadores alvo
- S2 `__/10` — Custo de shader medido (sem shader caro em tela cheia)
- S3 `__/10` — Pré-aquecimento de shader evita engasgo no primeiro uso
- S4 `__/10` — Parâmetros por instância usados corretamente
- S5 `__/10` — Efeitos de dano/flash/contorno funcionando em todos os sprites
- S6 `__/10` — Shader não quebra com escala, flip ou atlas
- S7 `__/10` — Fallback visual quando o recurso não é suportado
- S8 `__/10` — Nenhum shader dependendo de comportamento não documentado
- S9 `__/10` — Materiais nomeados e reaproveitados, não duplicados

## T. Partículas e VFX

- T1 `__/10` — Todo evento importante tem efeito visual
- T2 `__/10` — Efeitos legíveis, sem esconder o gameplay
- T3 `__/10` — Quantidade de partículas com teto e com orçamento
- T4 `__/10` — GPU particles onde vale; CPU onde precisa de lógica
- T5 `__/10` — Efeitos limpam a si mesmos (sem acúmulo de nó)
- T6 `__/10` — Efeitos escalam com a qualidade escolhida nas opções
- T7 `__/10` — VFX combinam com o estilo de arte
- T8 `__/10` — Sem flash forte ou estroboscópico sem opção de desligar
- T9 `__/10` — Trilhas, impactos, poeira e rastros no lugar certo
- T10 `__/10` — Efeito de tela cheia (sangue, chuva) com toggle

## U. Animação

- U1 `__/10` — Todo estado do personagem tem animação
- U2 `__/10` — Transições sem estalo, com blend adequado
- U3 `__/10` — Antecipação, exagero e continuidade presentes
- U4 `__/10` — Animação interrompível quando o jogador precisa reagir
- U5 `__/10` — Cancelamento de ação com regra clara
- U6 `__/10` — Eventos de animação disparando som e dano no frame certo
- U7 `__/10` — Sincronia entre pé e chão (sem deslizar)
- U8 `__/10` — Variações de idle para não parecer boneco
- U9 `__/10` — Animação de UI com easing, não linear
- U10 `__/10` — Duração das animações não atrasa a resposta ao jogador
- U11 `__/10` — Animação independente de framerate
- U12 `__/10` — Cutscenes puláveis, sempre
- U13 `__/10` — Cutscene não quebra se o jogador chegar de forma inesperada
- U14 `__/10` — IK/ragdoll estáveis, sem explosão de membro
- U15 `__/10` — Root motion coerente com a colisão
- U16 `__/10` — Custo de animação medido com muitos personagens em tela

## V. Game feel / juice

- V1 `__/10` — Cada ação responde com som, imagem e movimento
- V2 `__/10` — Impacto com hit stop / congelamento curto
- V3 `__/10` — Tremor de tela proporcional e nunca gratuito
- V4 `__/10` — Recuo, empurrão e reação de acerto perceptíveis
- V5 `__/10` — Esmagar e esticar (squash & stretch) onde combina
- V6 `__/10` — Números e feedback de dano legíveis
- V7 `__/10` — Transição de cena com identidade, não corte seco
- V8 `__/10` — Estados de hover, foco e clique em toda UI
- V9 `__/10` — Movimento com aceleração e desaceleração desenhadas
- V10 `__/10` — Câmera reage aos momentos fortes
- V11 `__/10` — Feedback de erro tão claro quanto o de acerto
- V12 `__/10` — Recompensa celebrada (som, luz, partícula, texto)
- V13 `__/10` — Menu tem vida (nada é estático demais)
- V14 `__/10` — Nada de juice atrapalhando a leitura ou a performance
- V15 `__/10` — Intensidade de todo o juice configurável
- V16 `__/10` — Comparação antes/depois medida, não só sentida

## W. Áudio — design sonoro

- W1 `__/10` — Identidade sonora definida (paleta de sons)
- W2 `__/10` — Toda ação do jogador tem retorno sonoro
- W3 `__/10` — Todo evento importante do mundo tem som
- W4 `__/10` — Variação de pitch e de amostra evitando fadiga por repetição
- W5 `__/10` — Camadas de som (ataque, impacto, cauda) em vez de som único
- W6 `__/10` — Som de UI distinto do som de jogo
- W7 `__/10` — Ambiente sonoro por área, com loop imperceptível
- W8 `__/10` — Passos por tipo de superfície
- W9 `__/10` — Som comunica informação que a tela não mostra
- W10 `__/10` — Nenhum som irritante em repetição alta
- W11 `__/10` — Silêncio usado de propósito
- W12 `__/10` — Nenhum som placeholder no build final

## X. Áudio — música

- X1 `__/10` — Tema principal memorável
- X2 `__/10` — Música combina com o gênero e com o ritmo do jogo
- X3 `__/10` — Loops sem clique e sem emenda audível
- X4 `__/10` — Camadas adaptativas reagindo ao estado do jogo
- X5 `__/10` — Transições entre faixas suaves (crossfade, stinger, compasso)
- X6 `__/10` — Música de menu, de jogo, de tensão, de vitória e de derrota
- X7 `__/10` — Duração suficiente para não cansar na sessão média
- X8 `__/10` — Volume relativo correto contra os efeitos
- X9 `__/10` — Licença clara de toda faixa, inclusive para trailer e streaming
- X10 `__/10` — Faixa liberada para streamers (política de DMCA declarada)

## Y. Áudio — mixagem e implementação

- Y1 `__/10` — Buses separados: Master, Música, SFX, UI, Voz, Ambiente
- Y2 `__/10` — Slider independente por bus, persistido no save de config
- Y3 `__/10` — Sliders em curva logarítmica (percepção correta de volume)
- Y4 `__/10` — Nível de loudness medido (alvo de LUFS) e headroom preservado
- Y5 `__/10` — Sem clipping em nenhum pico
- Y6 `__/10` — Compressão/limitador no master sem esmagar dinâmica
- Y7 `__/10` — Ducking da música quando entra voz ou evento crítico
- Y8 `__/10` — Reverb e filtro por ambiente
- Y9 `__/10` — Áudio posicional com atenuação e oclusão coerentes
- Y10 `__/10` — Limite de vozes simultâneas e prioridade definidos
- Y11 `__/10` — Streaming para música, amostra na memória para SFX curto
- Y12 `__/10` — Formatos e taxas escolhidos por peso e qualidade
- Y13 `__/10` — Latência de áudio aceitável
- Y14 `__/10` — Áudio pausa/silencia ao perder foco da janela (opcional configurável)
- Y15 `__/10` — Áudio não estoura ao pausar, ao trocar de cena ou ao sair
- Y16 `__/10` — Mixagem conferida em fone, em caixa de som e em notebook ruim
- Y17 `__/10` — Saída mono funcional (acessibilidade e caixa única)
- Y18 `__/10` — Troca de dispositivo de áudio em tempo real sem travar

## Z. UI — sistema e arquitetura visual

- Z1 `__/10` — Tema central (Theme) único; nada estilizado à mão por nó
- Z2 `__/10` — Componentes reaproveitáveis (botão, slider, painel, aba, lista)
- Z3 `__/10` — Estados completos: normal, hover, pressionado, desabilitado, foco
- Z4 `__/10` — Foco sempre visível e com contraste suficiente
- Z5 `__/10` — Hierarquia visual clara (o que é mais importante parece mais importante)
- Z6 `__/10` — Tipografia limitada (1 a 2 famílias) e consistente
- Z7 `__/10` — Tamanho mínimo de fonte legível em TV e em Deck
- Z8 `__/10` — Contraste de texto e de ícone adequado
- Z9 `__/10` — Espaçamento, alinhamento e grade consistentes
- Z10 `__/10` — Ancoragem e containers corretos (nada posicionado em pixel fixo)
- Z11 `__/10` — Layout íntegro em 16:9, 16:10, 21:9, 32:9 e 4:3
- Z12 `__/10` — Layout íntegro de 1280×720 até 4K
- Z13 `__/10` — Escala de UI configurável
- Z14 `__/10` — Área segura respeitada
- Z15 `__/10` — Texto nunca cortado, estourado ou sobreposto em nenhum idioma
- Z16 `__/10` — Ícones acompanhados de texto ou de tooltip
- Z17 `__/10` — Sem texto dentro de imagem (impede tradução)
- Z18 `__/10` — Nada de lorem ipsum, "Botão 2" ou placeholder no build
- Z19 `__/10` — UI não bloqueia o gameplay atrás dela sem necessidade
- Z20 `__/10` — Animação de UI rápida, com opção de reduzir

## AA. Telas obrigatórias e fluxo

- AA1 `__/10` — Aviso de saúde/epilepsia antes do jogo
- AA2 `__/10` — Splash de estúdio/publisher/engine com skip
- AA3 `__/10` — Menu principal com todas as entradas necessárias
- AA4 `__/10` — Novo jogo, com aviso ao sobrescrever save
- AA5 `__/10` — Continuar, sempre apontando para o save certo
- AA6 `__/10` — Seleção de save com data, tempo jogado e progresso
- AA7 `__/10` — Apagar save com confirmação dupla
- AA8 `__/10` — Tela de opções completa e acessível também do menu de pausa
- AA9 `__/10` — Tela de controles com todos os comandos
- AA10 `__/10` — Menu de pausa com retomar, opções, reiniciar e sair
- AA11 `__/10` — Pausa realmente pausa (som, física, timers)
- AA12 `__/10` — Confirmação antes de sair do jogo e de abandonar partida
- AA13 `__/10` — Tela de derrota com retomada rápida
- AA14 `__/10` — Tela de vitória / fim de jogo
- AA15 `__/10` — Créditos completos, puláveis e roláveis
- AA16 `__/10` — Créditos incluem todos os assets, fontes e licenças de terceiros
- AA17 `__/10` — Tela de carregamento com sinal de progresso
- AA18 `__/10` — Tela de conquistas / estatísticas
- AA19 `__/10` — Inventário, mapa, diário e loja, se o gênero pedir
- AA20 `__/10` — Tutorial ou ajuda acessível a qualquer momento
- AA21 `__/10` — Versão do build visível em algum canto
- AA22 `__/10` — Nenhuma tela sem saída; voltar funciona em todas
- AA23 `__/10` — Fluxo completo percorrido só com gamepad, do boot ao desligar
- AA24 `__/10` — Transições entre telas sem piscar preto nem estourar som
- AA25 `__/10` — Primeiro boot: o jogador chega ao jogo sem se perder

## AB. UX e onboarding

- AB1 `__/10` — Tutorial integrado ao jogo, não parede de texto
- AB2 `__/10` — Ensina fazendo, não lendo
- AB3 `__/10` — Tutorial pulável e reconsultável
- AB4 `__/10` — Dicas contextuais no momento da necessidade
- AB5 `__/10` — Objetivo atual sempre visível ou consultável
- AB6 `__/10` — Feedback imediato para toda ação do jogador
- AB7 `__/10` — Mensagens de erro em linguagem humana
- AB8 `__/10` — Ações destrutivas exigem confirmação; o resto é reversível
- AB9 `__/10` — Nada de tempo de espera sem indicação do que está acontecendo
- AB10 `__/10` — Termos do jogo consistentes entre UI, tutorial e loja
- AB11 `__/10` — Padrões de mercado respeitados (Esc pausa, WASD anda)
- AB12 `__/10` — Quantidade de cliques até jogar minimizada
- AB13 `__/10` — Retorno ao jogo depois de dias: o jogador lembra onde estava
- AB14 `__/10` — Nada essencial escondido em submenu de terceiro nível
- AB15 `__/10` — Teste de usabilidade feito com pessoa observada em silêncio

## AC. Menu de configurações

**Vídeo**
- AC1 `__/10` — Resolução com a lista real do monitor
- AC2 `__/10` — Modo de janela: tela cheia, sem borda e janela
- AC3 `__/10` — Escolha de monitor em setup multi-tela
- AC4 `__/10` — VSync e limite de FPS
- AC5 `__/10` — Presets de qualidade + ajuste individual
- AC6 `__/10` — Sombras, antialiasing, escala de render e upscaling (FSR)
- AC7 `__/10` — Brilho/gamma com imagem de referência
- AC8 `__/10` — HDR, se suportado
- AC9 `__/10` — Aplicar com confirmação e reversão automática por tempo
- AC10 `__/10` — Mudança aplicada sem reiniciar sempre que possível

**Áudio**
- AC11 `__/10` — Volume master e por bus
- AC12 `__/10` — Dispositivo de saída
- AC13 `__/10` — Mono/estéreo e faixa dinâmica

**Jogabilidade**
- AC14 `__/10` — Dificuldade e assistências separadas
- AC15 `__/10` — Autosave, velocidade de texto e pular cutscenes
- AC16 `__/10` — Unidades, HUD ligável/desligável por elemento
- AC17 `__/10` — Câmera: FOV, sensibilidade, inversão, efeitos

**Controles**
- AC18 `__/10` — Remapeamento completo, presets e restaurar padrão
- AC19 `__/10` — Vibração e zona morta

**Geral**
- AC20 `__/10` — Idioma com troca em tempo real
- AC21 `__/10` — Restaurar padrão por seção e global
- AC22 `__/10` — Configurações persistem e sobrevivem a atualização do jogo
- AC23 `__/10` — Config separada do save de progresso
- AC24 `__/10` — Nenhuma opção que não faz nada
- AC25 `__/10` — Toda opção explicada em uma linha

## AD. Acessibilidade

**Visual**
- AD1 `__/10` — Legendas em todo diálogo, ligadas por padrão
- AD2 `__/10` — Tamanho, cor, opacidade e fundo da legenda configuráveis
- AD3 `__/10` — Nome de quem fala na legenda
- AD4 `__/10` — Legendas descritivas de efeito sonoro (closed captions)
- AD5 `__/10` — Escala de texto global até 200% sem quebrar layout
- AD6 `__/10` — Fonte legível; opção de fonte para dislexia
- AD7 `__/10` — Contraste mínimo atendido em texto e em elemento de interface
- AD8 `__/10` — Nenhuma informação transmitida só por cor
- AD9 `__/10` — Modos de daltonismo (protanopia, deuteranopia, tritanopia)
- AD10 `__/10` — Modo de alto contraste / realce de inimigo e de item
- AD11 `__/10` — Tamanho de mira, de cursor e de marcador ajustável
- AD12 `__/10` — Leitor de tela ou narração de menus
- AD13 `__/10` — Suporte a zoom/lupa onde faz sentido

**Motora**
- AD14 `__/10` — Remapeamento total já contemplado e sem exceção
- AD15 `__/10` — Alternativa a segurar botão em 100% dos casos
- AD16 `__/10` — Sem martelar botão obrigatório; alternativa por toque único
- AD17 `__/10` — Sem combinação simultânea obrigatória de muitos botões
- AD18 `__/10` — Jogável com uma mão em alguma configuração
- AD19 `__/10` — Mira assistida / trava de alvo opcional e graduada
- AD20 `__/10` — Velocidade do jogo ajustável ou pausa a qualquer momento
- AD21 `__/10` — Limites de tempo removíveis ou estendíveis
- AD22 `__/10` — Auto-caminhar, auto-completar e pular seção difícil

**Cognitiva**
- AD23 `__/10` — Objetivo sempre recuperável; sem depender da memória
- AD24 `__/10` — Linguagem simples e frases curtas
- AD25 `__/10` — Dicas persistentes opcionais
- AD26 `__/10` — Modo história / dificuldade mínima disponível
- AD27 `__/10` — Ritmo de texto controlado pelo jogador
- AD28 `__/10` — Complexidade de HUD reduzível

**Auditiva**
- AD29 `__/10` — Nenhuma informação crítica só por som
- AD30 `__/10` — Indicador visual de direção de som (dano, passo, alerta)
- AD31 `__/10` — Volumes independentes já contemplados
- AD32 `__/10` — Saída mono disponível

**Fotossensibilidade e enjoo**
- AD33 `__/10` — Nenhum flash acima de 3 por segundo sem opção de desligar
- AD34 `__/10` — Aviso de epilepsia no início
- AD35 `__/10` — Redução de movimento: tremor, motion blur, balanço, parallax
- AD36 `__/10` — Vinheta de conforto e FOV amplo onde há movimento intenso

**Processo**
- AD37 `__/10` — Seção de acessibilidade própria no menu, não espalhada
- AD38 `__/10` — Recursos de acessibilidade testados com quem precisa deles
- AD39 `__/10` — Recursos declarados na página da loja (tags de acessibilidade)
- AD40 `__/10` — Conformidade avaliada (XAG, WCAG 2.2 aplicável, EN 301 549/EAA)
- AD41 `__/10` — Aviso de conteúdo sensível antes da exposição

## AE. Localização

- AE1 `__/10` — Nenhuma string de interface escrita direto no código ou na cena
- AE2 `__/10` — Arquivo de tradução único, versionado e com chave estável
- AE3 `__/10` — Idiomas alvo definidos por mercado, não por acaso
- AE4 `__/10` — Nenhuma chave faltando em nenhum idioma (verificado por teste)
- AE5 `__/10` — Plural, gênero e concordância tratados pelo sistema
- AE6 `__/10` — Placeholders com ordem livre (não concatenação de pedaços)
- AE7 `__/10` — Layout aguenta texto 30-40% mais longo
- AE8 `__/10` — Fonte com todos os glifos necessários (acentos, cirílico, CJK)
- AE9 `__/10` — Suporte a RTL se houver árabe/hebraico
- AE10 `__/10` — Número, data, hora e moeda formatados por locale
- AE11 `__/10` — Idioma detectado do sistema no primeiro boot
- AE12 `__/10` — Troca de idioma em tempo real, sem reiniciar
- AE13 `__/10` — Imagens com texto substituídas por versão localizada ou por texto
- AE14 `__/10` — Termos-chave consistentes entre tradução, dublagem e loja
- AE15 `__/10` — Revisão por falante nativo (não só máquina)
- AE16 `__/10` — LQA feito no jogo rodando, não na planilha
- AE17 `__/10` — Conquistas, descrição da loja e material de marketing traduzidos
- AE18 `__/10` — Dublagem, se houver, sincronizada e com legenda correspondente

## AF. Save, persistência e nuvem

- AF1 `__/10` — Salva em `user://`, nunca dentro do projeto
- AF2 `__/10` — Versão de esquema (`schema_version`) gravada no arquivo
- AF3 `__/10` — Migração de versão antiga testada
- AF4 `__/10` — Escrita atômica (temporário + renomear), sem corromper por queda
- AF5 `__/10` — Backup do save anterior
- AF6 `__/10` — Save corrompido detectado e recuperado sem travar o jogo
- AF7 `__/10` — Autosave frequente e com indicador visível
- AF8 `__/10` — Perda máxima de progresso declarada e aceitável
- AF9 `__/10` — Nunca salva durante ação crítica de forma insegura
- AF10 `__/10` — Múltiplos slots, se o gênero pedir
- AF11 `__/10` — Progresso separado de configuração
- AF12 `__/10` — Tamanho e tempo de gravação medidos
- AF13 `__/10` — Steam Cloud configurado com padrões de arquivo corretos
- AF14 `__/10` — Conflito entre duas máquinas resolvido de forma previsível
- AF15 `__/10` — Save sobrevive a atualização do jogo
- AF16 `__/10` — Apagar/reiniciar progresso disponível ao jogador
- AF17 `__/10` — Sem dado pessoal desnecessário no save
- AF18 `__/10` — Save não é fonte de exploit trivial (ou é assumido de propósito)

## AG. Performance

- AG1 `__/10` — FPS alvo definido por plataforma e cumprido
- AG2 `__/10` — Frame time estável; 1% low e 0.1% low medidos
- AG3 `__/10` — Sem engasgo por compilação de shader (pré-aquecimento feito)
- AG4 `__/10` — Sem engasgo por carga de recurso em tempo de jogo
- AG5 `__/10` — Sem pico de coleta de lixo / alocação por frame
- AG6 `__/10` — Tempo de boot até o menu medido e curto
- AG7 `__/10` — Tempo de carga entre cenas medido e curto
- AG8 `__/10` — Carregamento assíncrono com feedback
- AG9 `__/10` — Uso de RAM e de VRAM medidos no pior caso
- AG10 `__/10` — Sem vazamento de memória em sessão longa
- AG11 `__/10` — Drawcalls e vértices dentro do orçamento
- AG12 `__/10` — Número de nós ativos sob controle
- AG13 `__/10` — `_process` desligado no que está parado
- AG14 `__/10` — Profiling real feito (CPU, GPU, física, script)
- AG15 `__/10` — Gargalo identificado por medição, não por palpite
- AG16 `__/10` — Testado na máquina mínima declarada
- AG17 `__/10` — Testado no Steam Deck com meta de FPS e de bateria
- AG18 `__/10` — Escalabilidade real entre os presets de qualidade
- AG19 `__/10` — Tamanho do build e tempo de instalação aceitáveis
- AG20 `__/10` — Comportamento térmico e consumo em portátil verificados
- AG21 `__/10` — Sem regressão de performance entre versões (medição comparada)

## AH. Estabilidade, erros e diagnóstico

- AH1 `__/10` — Zero crash conhecido em caminho normal
- AH2 `__/10` — Zero erro no console durante uma sessão completa
- AH3 `__/10` — Sessão longa (horas) sem degradação
- AH4 `__/10` — Alt-tab, minimizar, trocar resolução e suspender sem quebrar
- AH5 `__/10` — Desconectar controle, fone ou monitor no meio do jogo é tratado
- AH6 `__/10` — Disco cheio, sem permissão e caminho estranho tratados
- AH7 `__/10` — Log de runtime gravado e localizável pelo jogador
- AH8 `__/10` — Relatório de crash coletado (com consentimento)
- AH9 `__/10` — Falha degrada com elegância; não fecha sem explicação
- AH10 `__/10` — Bugs rastreados com severidade e reprodução
- AH11 `__/10` — Nenhum bug bloqueador ou de perda de progresso em aberto
- AH12 `__/10` — Modo de depuração inacessível por acidente no build final

## AI. Testes automatizados e verificação

- AI1 `__/10` — Suíte automatizada existe e roda por comando único
- AI2 `__/10` — Suíte roda em menos de 15 segundos
- AI3 `__/10` — Toda regra pura coberta por teste
- AI4 `__/10` — Testes determinísticos, sem falha intermitente
- AI5 `__/10` — Todo bug corrigido virou teste ANTES da correção
- AI6 `__/10` — Portão estrutural cobrindo cena, autoload, parse, `res://`, `.uid`
- AI7 `__/10` — Veredito do portão é bloco delimitado e legível por máquina
- AI8 `__/10` — Teste de save: gravar, ler, migrar versão antiga
- AI9 `__/10` — Teste de tradução: nenhuma chave faltando
- AI10 `__/10` — Teste de dados: todo item/inimigo/fase carrega e valida
- AI11 `__/10` — Teste de balanceamento por simulação em lote
- AI12 `__/10` — Smoke test do executável exportado
- AI13 `__/10` — Bot de playtest percorrendo o jogo sem intervenção
- AI14 `__/10` — CI rodando em todo push, verde antes do merge
- AI15 `__/10` — Build reproduzível a partir de um commit limpo
- AI16 `__/10` — Nenhum teste desligado, pulado ou comentado
- AI17 `__/10` — Cobertura conhecida e crescendo, não estagnada
- AI18 `__/10` — Verificação visual (screenshot) onde a resposta é visual

## AJ. Playtest, dados e telemetria

- AJ1 `__/10` — Playtest com pessoas de fora feito e repetido
- AJ2 `__/10` — Sessão observada em silêncio, sem o dev explicando
- AJ3 `__/10` — Roteiro de perguntas padronizado
- AJ4 `__/10` — Achados registrados e priorizados, não esquecidos
- AJ5 `__/10` — Playtest com quem nunca jogou o gênero
- AJ6 `__/10` — Telemetria mínima: onde morre, onde para, onde desiste
- AJ7 `__/10` — Telemetria com consentimento e política clara
- AJ8 `__/10` — Métricas de retenção acompanhadas na demo
- AJ9 `__/10` — Funil do primeiro boot até a primeira vitória medido
- AJ10 `__/10` — Feedback da comunidade canalizado em um lugar só
- AJ11 `__/10` — Decisão de design mudou por causa de dado real, pelo menos uma vez

## AK. Build, exportação e plataformas

- AK1 `__/10` — Presets de exportação por plataforma configurados
- AK2 `__/10` — Windows, Linux, macOS e Web conforme o alvo
- AK3 `__/10` — Ícone do executável e da janela em todas as resoluções
- AK4 `__/10` — Splash e nome da janela corretos
- AK5 `__/10` — Metadados do executável (empresa, versão, copyright)
- AK6 `__/10` — Versionamento semântico aplicado e visível no jogo
- AK7 `__/10` — Assinatura de código no Windows
- AK8 `__/10` — Notarização no macOS
- AK9 `__/10` — Build não é sinalizado por antivírus
- AK10 `__/10` — Filtros de exportação excluindo teste, doc e asset cru
- AK11 `__/10` — Build instala e roda em máquina limpa, sem dependência oculta
- AK12 `__/10` — Roda sem privilégio de administrador
- AK13 `__/10` — Roda offline
- AK14 `__/10` — Roda em caminho com espaço, acento e usuário não-ASCII
- AK15 `__/10` — Desinstalação limpa; atualização preserva save
- AK16 `__/10` — Build de demo separado e com escopo definido
- AK17 `__/10` — Requisitos mínimos e recomendados verificados de fato
- AK18 `__/10` — Tamanho do download otimizado
- AK19 `__/10` — Build Web com carregamento e áudio funcionando, se aplicável
- AK20 `__/10` — Processo de build automatizado, não manual

## AL. Steam / Steamworks

- AL1 `__/10` — App ID criado, depots e branches organizados
- AL2 `__/10` — Upload automatizado por script/CI
- AL3 `__/10` — Branch de teste (beta) com senha para revisores
- AL4 `__/10` — SDK integrado sem quebrar o build sem Steam
- AL5 `__/10` — Overlay funcionando (Shift+Tab não quebra o jogo)
- AL6 `__/10` — Conquistas desenhadas: nem triviais demais nem impossíveis
- AL7 `__/10` — Ícones de conquista nos dois estados e nos tamanhos certos
- AL8 `__/10` — Conquistas disparam de forma confiável e não retroativa por engano
- AL9 `__/10` — Estatísticas configuradas e coerentes com as conquistas
- AL10 `__/10` — Placar de líderes com proteção mínima contra fraude
- AL11 `__/10` — Steam Cloud com quota e padrões de arquivo corretos
- AL12 `__/10` — Steam Input com layout oficial por tipo de controle
- AL13 `__/10` — Rich Presence, se fizer sentido
- AL14 `__/10` — Capturas de tela pelo botão da Steam funcionando
- AL15 `__/10` — Family Sharing e modo offline testados
- AL16 `__/10` — Workshop / mods, se prometido
- AL17 `__/10` — Cartas colecionáveis e pontos, se aplicável
- AL18 `__/10` — Build passa na revisão da Valve sem pendência
- AL19 `__/10` — Chaves de imprensa e de revisor geradas e testadas
- AL20 `__/10` — Data de lançamento, preço e regiões configurados

## AM. Steam Deck e compatibilidade

- AM1 `__/10` — Roda via Proton ou nativo sem passo manual
- AM2 `__/10` — Sem lançador externo antes do jogo
- AM3 `__/10` — Resolução padrão 1280×800 (16:10) suportada nativamente
- AM4 `__/10` — Texto legível na tela de 7 polegadas
- AM5 `__/10` — 100% jogável só com o controle do Deck
- AM6 `__/10` — Teclado virtual aparece em todo campo de texto
- AM7 `__/10` — Ícones de botão corretos no Deck
- AM8 `__/10` — FPS alvo estável dentro do envelope de energia
- AM9 `__/10` — Consumo de bateria e temperatura aceitáveis
- AM10 `__/10` — Suspender e retomar sem quebrar
- AM11 `__/10` — Sem aviso de compatibilidade pendente no painel
- AM12 `__/10` — Testado também em Linux desktop e em hardware fraco

## AN. Página da loja e marketing

- AN1 `__/10` — Capsule art nos tamanhos exigidos, legível em miniatura
- AN2 `__/10` — Nome do jogo legível na menor capsule
- AN3 `__/10` — Trailer com gameplay nos primeiros segundos
- AN4 `__/10` — Trailer com legendas e sem depender de áudio
- AN5 `__/10` — GIFs e screenshots mostrando o jogo real, não conceito
- AN6 `__/10` — Descrição curta que explica o jogo em uma frase
- AN7 `__/10` — Descrição longa com os pilares e o loop
- AN8 `__/10` — Tags e gêneros corretos, sem tag oportunista
- AN9 `__/10` — Recursos declarados (single player, conquistas, nuvem, controle)
- AN10 `__/10` — Idiomas suportados listados corretamente (interface, legenda, áudio)
- AN11 `__/10` — Requisitos de sistema honestos
- AN12 `__/10` — Aviso de conteúdo e classificação etária configurados
- AN13 `__/10` — Uso de IA generativa declarado, se houver
- AN14 `__/10` — Demo publicada e apontada da página
- AN15 `__/10` — Página no ar bem antes do lançamento, acumulando wishlist
- AN16 `__/10` — Press kit com logo, screenshots, trailer, fato-folha e contato
- AN17 `__/10` — Presença mantida (devlog, redes, comunidade)
- AN18 `__/10` — Plano de lançamento com data, evento e divulgação
- AN19 `__/10` — Página traduzida nos idiomas suportados
- AN20 `__/10` — Preço comparável ao mercado e com regionalização coerente

## AO. Legal, licenças e conformidade

- AO1 `__/10` — Licença de todo asset rastreada em planilha
- AO2 `__/10` — Atribuições exigidas presentes nos créditos
- AO3 `__/10` — Fontes com licença comercial
- AO4 `__/10` — Música e sons com direito para jogo, trailer e streaming
- AO5 `__/10` — Nada de asset com licença duvidosa ou origem desconhecida
- AO6 `__/10` — Licenças de bibliotecas e da engine cumpridas (avisos incluídos)
- AO7 `__/10` — Nome e marca sem conflito registrado
- AO8 `__/10` — EULA e política de privacidade, se houver coleta de dado
- AO9 `__/10` — Conformidade com GDPR e LGPD onde aplicável
- AO10 `__/10` — Consentimento explícito para telemetria
- AO11 `__/10` — Classificação etária obtida (IARC/ESRB/PEGI/USK/ClassInd)
- AO12 `__/10` — Contratos com colaboradores e terceirizados assinados
- AO13 `__/10` — Direitos sobre o código e sobre a arte claros
- AO14 `__/10` — Regras de acessibilidade legalmente exigidas atendidas no mercado alvo

## AP. Segurança e integridade

- AP1 `__/10` — Nenhuma chave, token ou senha no repositório
- AP2 `__/10` — Segredos do CI em cofre, não em arquivo
- AP3 `__/10` — Dependências sem vulnerabilidade conhecida
- AP4 `__/10` — Parse de arquivo externo (save, mod, replay) sem execução de código
- AP5 `__/10` — Entrada de rede validada, se houver
- AP6 `__/10` — Placar e conquistas com proteção proporcional ao risco
- AP7 `__/10` — Dado do jogador armazenado com o mínimo necessário
- AP8 `__/10` — Comunicação externa por HTTPS com verificação de certificado
- AP9 `__/10` — Mods isolados, se suportados

## AQ. Rede e multijogador (se aplicável)

- AQ1 `__/10` — Modelo de rede escolhido conscientemente (autoritativo, P2P, lockstep)
- AQ2 `__/10` — Predição e reconciliação implementadas
- AQ3 `__/10` — Compensação de lag e interpolação
- AQ4 `__/10` — Comportamento testado com latência, perda de pacote e jitter
- AQ5 `__/10` — Desconexão, reconexão e host migration tratadas
- AQ6 `__/10` — Sincronia de estado sem divergência ao longo do tempo
- AQ7 `__/10` — Anti-cheat proporcional ao jogo
- AQ8 `__/10` — Matchmaking, lobby, convite e Steam friends funcionando
- AQ9 `__/10` — Tela dividida / cooperativo local, se prometido
- AQ10 `__/10` — Uso de banda e custo de servidor medidos
- AQ11 `__/10` — Moderação, denúncia e bloqueio se houver interação entre jogadores
- AQ12 `__/10` — Plano de fim de vida do serviço declarado

## AR. Pós-lançamento e monetização

- AR1 `__/10` — Plano de patch do dia 1 e de correções rápidas
- AR2 `__/10` — Canal de suporte e de bug visível ao jogador
- AR3 `__/10` — Processo de hotfix ensaiado antes do lançamento
- AR4 `__/10` — Roadmap público, se prometido, é cumprível
- AR5 `__/10` — DLC / conteúdo extra planejado sem canibalizar o jogo base
- AR6 `__/10` — Nenhuma prática abusiva de monetização
- AR7 `__/10` — Compras, se houver, claras quanto ao valor real
- AR8 `__/10` — Taxa de reembolso e nota de análises acompanhadas
- AR9 `__/10` — Resposta às análises e à comunidade planejada
- AR10 `__/10` — Backup e continuidade caso a equipe pare

## AS. Processo, git e produção

- AS1 `__/10` — Nunca se trabalha direto na branch principal
- AS2 `__/10` — Commits pequenos, descritivos, no imperativo
- AS3 `__/10` — Mensagem de commit diz o que mudou para o jogador ou para quem desenvolve
- AS4 `__/10` — Pull request com revisão antes do merge
- AS5 `__/10` — CI verde é condição para merge; sem `--no-verify`
- AS6 `__/10` — Histórico limpo, sem binário gigante nem segredo
- AS7 `__/10` — Backup em mais de um lugar
- AS8 `__/10` — Sincronia entre máquinas com protocolo definido
- AS9 `__/10` — Ambiente reproduzível por script (engine, templates, ferramentas)
- AS10 `__/10` — Tempo estimado vs tempo real acompanhado
- AS11 `__/10` — Marcos com definição de pronto explícita
- AS12 `__/10` — Fator ônibus maior que 1 (nada só na cabeça de uma pessoa)
- AS13 `__/10` — Aprendizados registrados para não repetir erro caro
- AS14 `__/10` — Nada declarado "pronto" sem evidência automatizada na tela

---

## AT. Rubrica final — pesos e nota mínima por fase

Nota mínima exigida (média do bloco) para o projeto poder passar de fase.
`—` = não avaliado ainda nessa fase.

| Bloco | Peso | P | A | B | G |
|---|---|---|---|---|---|
| A Conceito e escopo | 5 | 7 | 8 | 9 | 9 |
| B Documentação de design | 3 | 5 | 7 | 8 | 8 |
| C Estrutura do projeto | 5 | 6 | 8 | 9 | 10 |
| D Arquitetura de código | 5 | 5 | 7 | 8 | 9 |
| E Qualidade do código | 4 | 4 | 6 | 8 | 9 |
| F Dados e conteúdo | 3 | 4 | 7 | 8 | 9 |
| G Loop e mecânicas | 10 | 7 | 8 | 9 | 9 |
| H Progressão e balanceamento | 7 | 3 | 6 | 8 | 9 |
| I Dificuldade e ritmo | 6 | 3 | 6 | 8 | 9 |
| J Level design e conteúdo | 6 | 3 | 6 | 9 | 9 |
| K Geração procedural | 3 | 3 | 6 | 8 | 9 |
| L IA de inimigos | 4 | 3 | 6 | 8 | 9 |
| M Input e controles | 7 | 6 | 8 | 9 | 10 |
| N Câmera | 4 | 5 | 7 | 9 | 9 |
| O Física e colisão | 5 | 5 | 7 | 9 | 9 |
| P Arte 2D | 5 | 2 | 5 | 8 | 9 |
| Q Arte 3D | 5 | 2 | 5 | 8 | 9 |
| R Iluminação e ambiente | 4 | 1 | 4 | 8 | 9 |
| S Shaders e materiais | 3 | 1 | 4 | 8 | 9 |
| T Partículas e VFX | 3 | 1 | 4 | 8 | 9 |
| U Animação | 5 | 2 | 5 | 8 | 9 |
| V Game feel / juice | 7 | 4 | 6 | 9 | 10 |
| W Áudio — design sonoro | 4 | 1 | 5 | 8 | 9 |
| X Áudio — música | 3 | 1 | 4 | 8 | 9 |
| Y Áudio — mixagem | 4 | 1 | 5 | 8 | 9 |
| Z UI — sistema visual | 5 | 3 | 6 | 9 | 9 |
| AA Telas e fluxo | 6 | 2 | 6 | 9 | 10 |
| AB UX e onboarding | 6 | 2 | 6 | 9 | 9 |
| AC Menu de configurações | 5 | 1 | 5 | 9 | 10 |
| AD Acessibilidade | 7 | 1 | 4 | 8 | 9 |
| AE Localização | 4 | 1 | 4 | 8 | 9 |
| AF Save e nuvem | 5 | 2 | 7 | 9 | 10 |
| AG Performance | 6 | 3 | 6 | 8 | 9 |
| AH Estabilidade | 8 | 4 | 7 | 9 | 10 |
| AI Testes e verificação | 7 | 5 | 8 | 9 | 10 |
| AJ Playtest e telemetria | 5 | 3 | 6 | 8 | 9 |
| AK Build e exportação | 5 | 1 | 5 | 8 | 10 |
| AL Steam / Steamworks | 5 | — | 2 | 7 | 10 |
| AM Steam Deck | 4 | — | 2 | 7 | 9 |
| AN Loja e marketing | 5 | — | 3 | 7 | 9 |
| AO Legal e licenças | 6 | 2 | 6 | 9 | 10 |
| AP Segurança | 4 | 3 | 6 | 8 | 9 |
| AQ Rede e multijogador | 4 | 2 | 6 | 8 | 9 |
| AR Pós-lançamento | 4 | — | 2 | 6 | 9 |
| AS Processo e git | 5 | 6 | 8 | 9 | 9 |

## AU. Itens de reprovação automática (qualquer nota abaixo reprova o gold)

- AU1 — Crash reproduzível em caminho normal
- AU2 — Perda de progresso do jogador
- AU3 — Softlock sem saída
- AU4 — Save que não migra entre versões
- AU5 — Asset sem licença comprovada
- AU6 — Segredo commitado no repositório
- AU7 — Jogo não completável só com gamepad
- AU8 — Flash estroboscópico sem opção de desligar
- AU9 — Texto ilegível na resolução mínima suportada
- AU10 — Placeholder visível no build final
- AU11 — Erro no console durante sessão normal
- AU12 — Portão estrutural ou suíte de testes vermelhos
- AU13 — Opção do menu que não faz nada
- AU14 — Tela sem botão de voltar
- AU15 — Requisitos de sistema não verificados em máquina real

## AV. Cálculo da nota final

- AV1 — Nota do bloco = média das notas dos itens aplicáveis (`N/A` fora da conta)
- AV2 — Nota final = soma de (nota do bloco × peso) ÷ soma dos pesos
- AV3 — Qualquer bloco abaixo do mínimo da fase reprova a fase, mesmo com média alta
- AV4 — Qualquer item da lista AU reprova o gold, com nota qualquer
- AV5 — Veredito: < 5 não vendável · 5-6,9 alpha · 7-7,9 beta · 8-8,9 lançável · ≥ 9 polido
- AV6 — Toda nota exige evidência anexada (medição, screenshot, log, bloco do portão)
- AV7 — Nota sem evidência conta como zero
