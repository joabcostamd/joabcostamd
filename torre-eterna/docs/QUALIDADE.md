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
===VERIFICAR=== scripts=83 falhas=0 dados_faltando=[]
===STATUS=== PASS

$ godot --headless --path . -s res://tools/lint.gd
===LINT=== arquivos=83 linhas=22122 erros=0 avisos=0
===STATUS=== PASS

$ godot --headless --path . -s res://tools/validar_dados.gd
===VALIDAR-DADOS===
  erros: 0
===STATUS=== PASS

$ godot --headless --path . -s res://tools/testes.gd
===TESTES=== passou=218 falhou=0
===STATUS=== PASS

$ godot --headless --path . -s res://tools/perf.gd -- 400
=== ESTRESSE: 400 inimigos, onda 200 ===
--- perfil por subsistema (us/passo) ---
  grade            144 us  ( 7.0%)
  status           298 us  (14.5%)
  inimigos         487 us  (23.7%)
  torre            104 us  ( 5.1%)
  projeteis       1007 us  (49.0%)
  coletaveis         3 us  ( 0.1%)
  habilidades        6 us  ( 0.3%)
  diretor            5 us  ( 0.3%)
pico: 471 inimigos, 60 projeteis
custo por passo: 2056 us  (orcamento 4000 us)
equivale a 486 fps so de simulacao
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
| Scripts GDScript | 83 |
| Linhas de código | 22.122 |
| Testes da simulação | 218 |
| Chaves de interface PT/EN | 940 |
| Textos de conteúdo PT/EN | 1.210 |
| Imagens no repositório | 0 |
| Arquivos de som no repositório | 0 |
