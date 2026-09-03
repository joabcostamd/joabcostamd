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
| 5 | **Balanceamento medido** | 8 | `tools/sim_balance.gd -- 2` | onda 25 em 10–20 min; onda 50 em 40–70 min; sem travar |
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

## Medições atuais

Rode e cole a saída crua — esta tabela só vale preenchida por execução, nunca de memória.

```
godot --headless --path . -s res://tools/verificar.gd
godot --headless --path . -s res://tools/validar_dados.gd
godot --headless --path . -s res://tools/testes.gd
godot --headless --path . -s res://tools/perf.gd -- 400
godot --headless --path . -s res://tools/sim_balance.gd -- 2
```
