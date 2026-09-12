# Torre entre Dimensões — documento de design

Data: 2026-09-12 · Leia antes: `../CONCEITO.md` (o que é e o que recusa) · `ARTE.md` (o visual)
Este documento é o **como**.

---

## 1. Os três pilares

Promessas inegociáveis. Toda feature proposta é medida contra elas; o que não servir a nenhuma
é cortado sem discussão.

1. <pilar>
2. <pilar>
3. <pilar>

## 2. <O sistema central>

<como funciona, entrada, regra e saída>

### Os números iniciais

> **Nenhum destes números é decisão ainda.** São o ponto de partida do `./simular.sh`.
> Mexer aqui sem rodar o simulador é opinião.

| grandeza | valor de partida |
|---|---|
| <nome> | <valor> |

## 3. <Conteúdo — itens, armas, peças>

Cada um com o **papel mecânico**, não só o número.

| nome | o que faz | relação com o sistema central |
|---|---|---|
| <nome> | <efeito> | <por que é interessante> |

### Regra de escopo

Coisa nova só entra se **mudar uma decisão** que já existe. O que só aumenta um número é
recusado, por mais barato que seja implementar.

## 4. Progressão

<XP, loja, escolhas por nível, limites, re-sorteio>

## 5. Dificuldade e ritmo

<como escala, e o que o jogador sente em cada trecho da partida>

## 6. O que dá vida ao jogo

O juice especificado aqui, não improvisado no fim. Segue a regra única da identidade mínima.

| onde | o que acontece |
|---|---|
| <ação> | <retorno visual + som + peso> |

---

## Está pronto quando

- [ ] cada sistema tem entrada, regra e saída escritas
- [ ] todo número está marcado como chute ou provado pelo simulador
- [ ] a regra de escopo está escrita e foi aplicada pelo menos uma vez
- [ ] a tabela de juice cobre toda ação que o jogador faz
