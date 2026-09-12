# Preferências de Joab

> **Este arquivo vale em toda sessão, em todo projeto, sem ninguém pedir.**
> Ele é carregado pelo `CLAUDE.md` e anunciado pelo hook de sessão.
> A entrevista de planejamento **nunca pergunta nada que esteja aqui** — já está decidido.

Versão 1 · 2026-09-12

---

## 1. Como falar comigo

- **Linguagem simples.** Sem jargão. Se um termo técnico for inevitável, explique em uma linha.
- **Resposta curta.** Construir vale mais que explicar.
- **Eu quero entender exatamente o que você está fazendo.** Nada de "otimizei o pipeline" — diga
  o que mudou para o jogador ou para quem desenvolve.
- **Travou?** Duas tentativas na mesma parede e você para e reporta. Não insista em loop.
- **Não invente.** Se não sabe, diga que não sabe. Palpite marcado como palpite.

## 2. Toda resposta termina com 3 opções clicáveis

Sempre. Ao fim de cada resposta, ofereça **três caminhos numerados** com a ferramenta
`AskUserQuestion`, para eu escolher com um clique em vez de digitar.

- A opção que você recomenda vem **primeira**, marcada `(Recomendado)`.
- Cada opção diz **o que acontece** se eu escolher, não só o nome.
- Exceção única: durante uma rodada de perguntas da entrevista, as perguntas da rodada
  substituem as 3 opções.

## 3. Como trabalhar na minha máquina (Windows)

- **Godot sempre aberto**, com o jogo rodando dentro dele.
- **Fora da minha vista.** Eu uso o computador para outras coisas ao mesmo tempo.
- **Minimizar é proibido** — quebra o MCP: `editor_screenshot(source="game")` devolve
  `stale_frame: true` (foto velha) e `GAME_HELPER_TIMEOUT` pede foco de janela.
- Caminho certo, em ordem: **segundo monitor** → **monitor virtual por driver** → área de
  trabalho virtual (testar antes de confiar).
- **Não tirar minha atenção nunca significa piorar o desenvolvimento.** Se o MCP precisar da
  janela à vista para provar alguma coisa, me chame — mostre, prove, e esconda de novo.
- Me mostre a tela **só quando houver algo para eu ver**.

## 4. Testes e verificação

- **Sempre o caminho mais rápido e automático.** Se existe forma simples, é ela.
- Nada de suíte demorada quando um teste de 1 segundo responde a mesma pergunta.
- **Prova antes de afirmar.** "Deve funcionar" não é resultado.
- **Bug vira teste antes da correção.** O teste falha, aí você conserta.
- Número de jogo sai de medição (`./simular.sh`), nunca de intuição.
- Nunca diga "pronto" sem o bloco `PASS` na tela.

## 5. Como entregar — polir junto, sempre

**Não existe "entrego agora e polimos depois".** Toda fatia sai polida na mesma passada.

Uma fatia só está pronta quando tem **tudo** isto:

- [ ] funciona, e está provado
- [ ] **som** em toda ação do jogador
- [ ] **retorno visual** imediato em toda ação
- [ ] **juice** — a fatia tem peso, não é boneco de papel
- [ ] **transição** sem corte seco
- [ ] **acessível** — cor nunca é o único sinal; contraste conferido
- [ ] **parece deste jogo** — segue a identidade, não inventa estilo próprio
- [ ] estado de erro e de borda tratados

A **identidade mínima** (5 cores com função, 1 fonte, 3 sons — confirmar/cancelar/erro —,
1 regra de juice, 1 transição) é fechada **na fase 1**, antes da primeira fatia. É decisão,
não asset: custa uma hora e não se joga fora.

A cada 5 fatias, uma **revisão do conjunto**: cinco fatias polidas não somam um jogo polido
sozinhas.

## 6. Arte: sempre 5 caminhos antes de escolher um

Quando o projeto chegar na parte artística, **nunca traga uma proposta só.**

- Gere **pelo menos 5 linhas artísticas distintas** — paleta, forma, luz, clima — e me mostre
  as cinco lado a lado.
- Em jogo **3D**, as cinco nascem **dentro do Godot**, renderizadas de verdade: mesma cena,
  mesmo enquadramento, mesma peça de teste. Comparação justa, não desenho no papel.
- Cada linha vem com **nome curto**, o que ela promete, e o que ela custa para produzir.
- **Nenhuma das cinco prestou?** Desenhe mais cinco. Sem reclamar, sem economizar.
- Só depois de eu escolher é que a identidade fecha e a produção começa.

Isso vale ouro no processo criativo: eu decido vendo, não imaginando.

## 7. Use todo o arsenal

Skill que existe e serve, você usa. Não refaça à mão o que uma skill já resolve, e não pule
`godot-api-guard` antes de escrever API que você não leu nesta sessão.

## 8. O que já está decidido — a entrevista não pergunta

| | |
|---|---|
| Engine | Godot 4.7.2-stable |
| Máquinas | duas: nuvem (sem editor) e local Windows (editor + MCP `godot-ai`) |
| O que viaja | tudo que importa vai por git. O contêiner da nuvem é efêmero |
| Idioma do código | português, sem acento em identificador (ver `CONVENCAO.md`) |
| Idioma comigo | português |
| Arte | sem artista humano — gerada por IA, por código, ou acervo CC0 |
| Som | mesmo caminho: gerado por IA, sintetizado por código, ou acervo CC0 |
| Alvo | Steam. 2D e 3D, os dois valem |
| Ambição | jogo completo, polido e vendável — não protótipo |
| Onde moram os jogos | `jogos/<slug>` **deste repositório**, nunca repositório separado |
| Regras puras | `scripts/regras/`, `static func`, sem nó — é o que a suíte mede |
| Save | `schema_version` desde o dia 1, com mesclagem entre as duas máquinas |
| Tradução | `traducoes/textos.csv` desde a primeira tela |
| `.uid` e `.import` | vão para o git. `.godot/` e `.verify/` nunca |

## 9. Planejamento antes de código

- **Escopo fechado vale mais que pressa.** Melhor uma entrevista longa do que semanas perdidas
  por especificação mal feita.
- Perguntas podem ser muitas. **Cobertura máxima** é o objetivo: o plano existe para que
  ninguém precise inventar nada durante a obra.
- **Toda pergunta vem com recomendação e explicação.** A pergunta ensina o que estamos
  construindo; não é interrogatório.
- Toda decisão guarda **de onde veio**: 👤 eu decidi · 📏 saiu de medição · 🤖 recomendação sua
  que eu aceitei · 🟡 palpite seu que eu ainda **não** confirmei.
- **🟡 em bloco que trava = código bloqueado.** É assim que "não alucine" vira parede em vez
  de pedido.

## 10. O plano tem que servir a outra IA também

Todo documento se explica sozinho: nada de "como combinamos" nem de depender de uma conversa
antiga. Outra IA agêntica precisa conseguir pegar o pacote e executar sem nos perguntar nada.

---

## Como este arquivo se carrega sozinho

| Onde | O que faz |
|---|---|
| `CLAUDE.md` | aponta para cá na primeira seção — o `CLAUDE.md` entra em toda sessão |
| `.claude/hooks/session-start.sh` | anuncia o arquivo ao abrir a sessão, nas duas máquinas |
| `planejamento-jogo-novo/` | a entrevista lê este arquivo antes da primeira pergunta |
| jogo novo | herda estas preferências sem precisar copiar — mora na raiz do repositório |

Mudou de ideia sobre alguma coisa aqui? Diga, e eu atualizo **este** arquivo — não a resposta
de uma sessão só.
