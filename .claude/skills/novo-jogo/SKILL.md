---
name: novo-jogo
description: "Use quando o pedido for começar um jogo — 'jogo novo', 'quero fazer um jogo', 'tive uma ideia de jogo', 'e se eu fizesse um jogo de', 'vamos criar um jogo', 'começar projeto de jogo' — e também para CONTINUAR o planejamento de um jogo que já existe ('onde paramos', 'continuar o plano', 'o que falta decidir'). Conduz a entrevista de arquitetura em blocos, faz a pesquisa de mercado, escreve os 11 documentos e roda o portão que impede código nascer sem plano. Funciona de qualquer pasta."
---

# novo-jogo — o jogo nasce decidido, não improvisado

> **Leia primeiro:** `PREFERENCIAS-DE-JOAB.md` do repositório. Ele manda em como falar,
> trabalhar, testar e entregar, e ganha desta skill em caso de conflito.

O problema que esta skill resolve: arquitetura decidida **durante** a implementação é
arquitetura decidida com pressa. O custo aparece três meses depois, quando mudar a câmera
significa refazer o level design e mudar o formato dos dados significa refazer o save.

---

## Antes da primeira pergunta

1. **Classifique o pedido:**

| o pedido é | faça |
|---|---|
| ideia solta no meio de outra conversa | **uma** pergunta: *"isso virou ideia de jogo. Quer que eu comece o desenho, ou é só conversa?"* |
| `/novo-jogo` digitado | comece direto — ele já quis |
| jogo que já existe | modo **continuar**: leia o `docs/PLANO.md` e retome de onde parou |

2. **Leia** `planejamento-jogo-novo/BLOCOS.md` — os 13 blocos, o grafo e as fases.
3. **Nunca pergunte** nada que já esteja no `PREFERENCIAS-DE-JOAB.md`.

---

## O ciclo

```
1. PASTA        novo-plano.py cria jogos/<slug>/ com os 11 modelos    (sem Godot ainda)
2. ENTREVISTA   blocos na ordem do grafo, 10 perguntas por rodada
3. PORTÃO       portao-plano.py diz a fase alcançada e o que falta
4. PROVAS       🎲 diversão + 🎨 asset, em prototipo/
5. GODOT        só agora o projeto nasce, e o código começa
```

### 1. A pasta

```bash
python3 planejamento-jogo-novo/novo-plano.py <slug> "Nome do Jogo"
```

Cria `jogos/<slug>/` com `CONCEITO.md` e `docs/` contendo os 11 documentos em branco.
**Acha o repositório sozinho**, de qualquer pasta. **Não cria o projeto Godot** — de propósito.

### 2. A entrevista

- Ordem: pelo **grafo de dependência** do `BLOCOS.md`, nunca por rodada fixa.
- Fonte: `planejamento-jogo-novo/PERGUNTAS.md`.
- **10 perguntas por rodada**, depois um respiro.
- **Toda pergunta propõe**: 2 a 4 caminhos com custo e consequência, mais a sua recomendação.
  Perguntar seco produz resposta pobre — o Joab é o diretor, não o técnico.
- "Não sei" é resposta válida → 🟡 com a sua recomendação e uma data.
- Cobertura **máxima**. Quantidade não é problema; especificação mal feita é.

**A pesquisa de mercado (bloco PM) é trabalho seu, não dele.** Assim que a frase e o gênero
existirem, pare e faça as 9 seções do `PESQUISA.md` — com fonte por afirmação, as mecânicas que
funcionaram, as que fracassaram, e o contraponto contra o que já medimos aqui.

### 3. O portão

```bash
python3 planejamento-jogo-novo/portao-plano.py jogos/<slug>
```

O bloco `===PLANO-VERIFY===` é a **única fonte de verdade**. Exit code não conta.

### 4. As duas provas

Fim da fase 1, as duas em `prototipo/` — pasta que o portão libera e que **nunca** entra no
jogo final:

- 🎲 **diversão** — caixa cinza medindo o critério que mata o projeto
- 🎨 **asset** — um modelo e um som, de ponta a ponta, pelo caminho definitivo

### 5. O projeto Godot

Só depois das duas provas:

```bash
.claude/scripts/novo-jogo.sh <slug> "Nome do Jogo"
```

---

## As regras que não se negociam

1. **Nenhuma linha de GDScript antes da fase 2 fechar.** Exceto `prototipo/`.
2. **Decisão 🟢 precisa de motivo escrito e marca de origem** (👤 📏 🤖). Sem origem, o portão
   pergunta "quem decidiu?" e bloqueia.
3. **🟡 em bloco que trava = código bloqueado.** É o que impede construir em cima de palpite.
4. **Número de jogo sai de medição**, nunca de intuição.
5. **Toda fatia sai polida na mesma passada** — som, retorno visual, juice, transição,
   acessibilidade. Nunca "entrego agora e polimos depois".
6. **Arte: sempre 5 linhas artísticas** renderizadas dentro do Godot antes de escolher uma.
   Nenhuma prestou? Gere mais cinco.
7. **O plano serve a outra IA também.** Nada de "como combinamos": todo documento se explica
   sozinho.

## Anti-padrões

- ❌ Começar a entrevista sem ler o `PREFERENCIAS-DE-JOAB.md`.
- ❌ Perguntar seco, sem propor caminhos. Resposta pobre é culpa da pergunta.
- ❌ Criar o projeto Godot antes das duas provas.
- ❌ Escrever documento em formato improvisado — os modelos existem e o portão lê exatamente eles.
- ❌ Pular a pesquisa de mercado porque "a ideia é original".
- ❌ Dizer que o plano fechou sem o bloco `PLANO-VERIFY` na tela.

## Se o repositório não for achado

O `novo-plano.py` procura pela pasta que contém `PREFERENCIAS-DE-JOAB.md`. Se não achar:

```bash
JOGOS_RAIZ=/caminho/do/repo python3 novo-plano.py <slug> "Nome"
```

## O que mora aqui dentro

Cópias plantadas por `ferramentas/plantar-novo-jogo.sh`, para a skill funcionar fora do
repositório. **Os canônicos vivem em `planejamento-jogo-novo/`** — nunca edite estas cópias.
