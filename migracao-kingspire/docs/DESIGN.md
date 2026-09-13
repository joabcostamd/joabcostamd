# Kingspire — documento de design

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

### Por que os pontos de construção são fixos — e não é só simplicidade

Descoberta da pesquisa, na entrevista do criador do Thronefall:

> *"Não deixar o jogador decidir o que construir e onde abriu possibilidades incríveis de level
> design, porque dá para **forçar o jogador a construir em posições arriscadas** — o que gera
> decisões muito mais interessantes. E isso impede automaticamente que ele construa três
> muralhas em volta do ponto de spawn."*

Duas consequências que valem ouro:

1. **O ponto fixo é ferramenta de design, não limitação.** Colocar um ponto de construção numa
   posição exposta é uma decisão do mapa, e obriga o jogador a escolher entre defender aquele
   ponto ou abrir mão dele.
2. **Mata o defeito clássico do maze TD por construção.** O jogador não consegue cercar o spawn
   nem desenhar labirinto — o mapa não deixa. Sem precisar de regra extra nem de aviso.

### O terreno é que define as frentes

Dos mapas reais: *Durststein* tem áreas abertas com rampas e pontos altos para unidade de
alcance; *Sturmklamm* tem corredores estreitos e caminhos subindo o morro onde fica o castelo,
com **quatro pontes ao sul** sendo as quatro frentes terrestres.

A regra que sai daí: **ponte e rampa são os estrangulamentos**, e o jogador decide se fortifica
a ponte ou deixa o inimigo atravessar para um campo aberto onde as torres somam fogo.

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
