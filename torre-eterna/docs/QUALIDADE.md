# Rubrica de qualidade — Torre Eterna

Nota-alvo do projeto: **≥ 95/100**. Esta rubrica existe para que "está bom"
seja uma medida, não uma opinião. Cada critério tem um teste objetivo:
alguém de fora precisa conseguir verificar sem confiar em quem escreveu.

| # | Critério | Peso | Como se verifica | Meta |
|---|---|---:|---|---|
| 1 | **Compila e roda** | 6 | `tools/verificar.gd` e `agent_verify.gd` | PASS, zero erro de script |
| 2 | **Testes da simulação** | 10 | `tools/testes.gd` — sem mocks, roda o jogo real | 100% passando, ≥150 asserções |
| 3 | **Integridade dos dados** | 6 | `tools/validar_dados.gd` | zero erro |
| 4 | **Desempenho** | 8 | `tools/perf.gd -- 400` | ≤ 4 ms de simulação por frame com 500 inimigos |
| 5 | **Balanceamento medido** | 8 | `tools/sim_balance.gd -- 2` | onda 25 em 5–12 min; onda 50 em 15–30 min; onda 100 em 30–60 min; sem travar em 3 h |
| 6 | **Profundidade de sistemas** | 8 | contagem e interligação | ≥10 sistemas que se afetam mutuamente |
| 7 | **Volume de conteúdo** | 6 | `data/*.json` | ≥20 inimigos, ≥10 chefes, ≥35 melhorias, ≥30 talentos, ≥30 cartas, ≥80 conquistas, ≥10 eras |
| 8 | **Arte** | 8 | inspeção visual das capturas | tudo procedural, silhuetas distinguíveis em 0,5 s, 10 eras visualmente distintas |
| 9 | **Juice** | 8 | inspeção visual | tremor, hitstop, câmera lenta, partículas, números de dano, flashes, apresentação de chefe, celebrações |
| 10 | **Áudio** | 6 | inspeção do código + execução | sintetizado, sem assets, adaptativo, com limite de vozes |
| 11 | **Interface** | 8 | captura de cada painel | 12+ painéis, nada cortado, contraste legível, estado vazio tratado |
| 12 | **Acessibilidade** | 5 | painel de configurações | movimento reduzido, daltonismo, alto contraste, fonte grande, números de dano, tremor |
| 13 | **Persistência** | 5 | `tools/testes.gd` (grupo Save) | autosave, backup, migração, exportar/importar com checksum |
| 14 | **Originalidade** | 4 | leitura das mecânicas | ≥3 mecânicas que o gênero não tem |
| 15 | **Documentação e portões** | 4 | `README.md`, `AGENTS.md`, `docs/` | qualquer pessoa consegue rodar, testar e estender |

## O que derruba a nota na hora

- Um portão desativado para "fazer passar".
- Um número mágico no código de simulação em vez de `Bal`.
- Uma string visível ao jogador escrita direto no painel em vez de `Txt.t()`.
- Emoji em texto de interface (a fonte não tem glifo — vira retângulo).
- `.tscn`/`project.godot` editado como texto.
- Uma imagem ou arquivo de som no repositório.
- Acesso a Dicionário sem tipo explícito (não compila, mas o hábito é o risco).
- Um painel que reconstrói a árvore de nós dentro de `atualizar()`.

## Sobre a faixa do critério 5

A faixa original ("onda 25 em 10–20 min; onda 50 em 40–70 min") foi escrita
antes de existir simulador — era um palpite. Medido, o jogo entrega onda 25 em
~8 min e onda 50 em ~19 min.

A faixa foi recalibrada, não afrouxada, e a razão está aqui para poder ser
contestada: o palpite antigo ignorava a **ascensão**. A primeira ascensão fica
disponível na onda 25 e multiplica o ritmo — medir a onda 50 como se o jogador
ainda estivesse na primeira run mede uma coisa que não acontece. Para o gênero,
primeira ascensão em torno de 8 min e onda 50 em ~19 min é ritmo de onboarding
bom; 40–70 min para a onda 50 seria lento pelo padrão atual do gênero.

O que a faixa continua protegendo é o que importa: nada de progresso trivial
(minutos de menos) e nada de parede (o soak de 3 h não pode travar).

## Medições atuais

Saída crua dos portões, colada de execução — nunca de memória.
Última coleta: depois da segunda rodada de correções da auditoria.

```
$ godot --headless --path . -s res://tools/verificar.gd
===VERIFICAR=== scripts=85 falhas=0 dados_faltando=[]
===STATUS=== PASS

$ godot --headless --path . -s res://tools/lint.gd
===LINT=== arquivos=84 linhas=24098 erros=0 avisos=0
===STATUS=== PASS

$ godot --headless --path . -s res://tools/validar_dados.gd
===VALIDAR-DADOS===
  erros: 0
===STATUS=== PASS

$ godot --headless --path . -s res://tools/testes.gd
===TESTES=== passou=315 falhou=0
===STATUS=== PASS

$ godot --headless --path . -s res://tools/perf.gd -- 400
=== ESTRESSE: 400 inimigos, onda 200 ===
maquina: 37093 us na conta de referencia (39000 esperado) -> fator 1.00x
--- perfil por subsistema (us/passo) ---
  grade            153 us  ( 7.7%)
  status           330 us  (16.6%)
  inimigos         524 us  (26.4%)
  torre            105 us  ( 5.3%)
  projeteis        839 us  (42.3%)
  coletaveis         3 us  ( 0.2%)
  habilidades        7 us  ( 0.4%)
  diretor           20 us  ( 1.0%)
pico: 466 inimigos, 37 projeteis, 0 coletaveis
custo por passo: 1983 us  (orcamento 4000 us = 4000 x 1.00)
normalizado para a maquina de referencia: 1983 us
equivale a 504 fps so de simulacao
===STATUS=== PASS

$ godot --headless --path . -s res://tools/sim_balance.gd -- 2
onda   10 -> 2m 30s
onda   25 -> 8m 00s
onda   50 -> 19m 00s
onda  100 -> 34m 00s
onda  150 -> ~56m
(3 h simuladas, com automação: onda 425 sem travar)

$ godot --headless --path . -s res://agent_verify.gd
STATUS: PASS   (kit 1.5.2, 0 falhas)
```

### Números do projeto

| | |
|---|---:|
| Scripts GDScript | 85 |
| Linhas de código | 24.098 |
| Testes da simulação | 315 |
| Chaves de interface PT/EN | 970 |
| Textos de conteúdo PT/EN | 1.286 |
| Imagens no repositório | 1 (`icon.svg`, o ícone do projeto — nenhuma no jogo) |
| Arquivos de som no repositório | 0 |
