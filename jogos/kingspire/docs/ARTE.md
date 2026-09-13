# Kingspire — direção de arte

Data: 2026-09-12

> Nenhuma cor, forma ou brilho entra sem estar nesta página.
> Caminho de asset sai de `../assets/CATALOGO.md`, nunca de memória.

---

## 1. As cinco linhas artísticas

Antes de fechar cor nenhuma, cinco direções distintas foram geradas e comparadas lado a lado.
Em 3D, renderizadas **dentro do Godot**: mesma cena, mesmo enquadramento, mesma peça de teste.

| # | nome | o que promete | custo de produzir | escolhida |
|---|---|---|---|---|
| 1 | <nome> | <promessa> | <custo> | |
| 2 | <nome> | <promessa> | <custo> | |
| 3 | <nome> | <promessa> | <custo> | |
| 4 | <nome> | <promessa> | <custo> | |
| 5 | <nome> | <promessa> | <custo> | ✅ |

**Por que esta:** <motivo>

## 1b. O que aprendi olhando o Thronefall de verdade

O Joab mandou cinco telas do jogo em 2026-09-12. Registro aqui o que **eu vi**, não o que
imaginei — é a referência mais confiável que este documento tem.

### O terreno é platô em camadas, não morro espalhado

Foi o meu erro maior. Não são colinas jogadas pelo mapa: é **relevo em degraus**.

| o que é | como aparece |
|---|---|
| **platô** | área plana elevada, com **borda de penhasco vertical** |
| **rampa** | o único jeito de subir ou descer entre dois platôs — é o corredor obrigatório |
| **ponte** | passagem estreita sobre água ou abismo — o estrangulamento mais forte do jogo |
| **castelo** | fica **em cima de um platô**, no meio do mapa |

É o relevo que decide por onde o inimigo pode vir. A muralha que o jogador constrói **atravessa
o estreitamento**, ela não é terreno.

### A leitura antecipada

Nas telas dá para ver **os inimigos parados em formação na borda**, agrupados, antes de
atacar. O jogador vê de onde vem a próxima onda e tem tempo de se preparar. Isso não é
enfeite — é a informação que torna a decisão possível.

### A arte, ponto a ponto

| elemento | como é |
|---|---|
| **superfície** | face chapada, **zero textura**. Nenhum pixel de detalhe em lugar nenhum |
| **sombra** | dura, longa, quase preta. **É metade da leitura do relevo** — sem ela o platô some |
| **paleta** | 4 a 5 cores muito saturadas, e **cada mapa tem a sua**: verde+azul na costa · areia+tijolo no deserto · rosa+ciano num · azul-noite noutro |
| **árvore** | cacho de formas hexagonais de **uma cor só** — não tem tronco detalhado |
| **água** | azul chapado com **linhas desenhadas por cima**, estilo traço de mão |
| **rocha** | faces brancas e cinzas, silhueta angular, sem meio-tom |
| **construção** | blocos simples com listras e degraus; fazenda é padrão listrado visto de cima |
| **contorno** | escuro e sutil nas bordas, ajuda a separar peça de peça |
| **câmera** | isométrica alta, quase o mapa inteiro na tela |

### O que isso prova para o nosso projeto

**Low-poly bem feito não é modelo pobre — é luz e sombra bem resolvidas.** Nenhuma daquelas
telas tem textura. O que carrega a imagem é: silhueta limpa, cor saturada com função, e sombra
dura. Os três são trabalho de **configuração**, não de desenho à mão — e é exatamente o que a
geração por IA e o Godot fazem bem.

**Consequência direta para o B12:** o contrato de asset não precisa de UV nem de textura. Precisa
de silhueta boa, escala certa e material de cor chapada. Isso derruba muito o custo por peça.

## 2. A tese visual

<a ideia que decide tudo, em duas linhas>

## 3. A paleta — cada cor com uma função

Cor **informa**, não decora. Nenhuma cor faz dois trabalhos.

| papel | cor | hex | onde aparece |
|---|---|---|---|
| vazio | <nome> | `#______` | <onde> |
| você | <nome> | `#______` | <onde> |
| inimigo | <nome> | `#______` | <onde> |
| o que te mata | <nome> | `#______` | <onde> |

### A regra de reserva

> **<cor> significa exatamente uma coisa: <significado>.**

Consequência dura: **nenhum efeito decorativo pode usar <cor>.** Se um dia algo dessa cor
aparecer sem <significado>, a regra morreu e o jogador perde a confiança na tela inteira.

## 4. Prova de daltonismo

Resultado da simulação de dicromacia (protanopia e deuteranopia), pela skill `acessibilidade`:

| par de cores | protanopia | deuteranopia |
|---|---|---|
| <cor A> × <cor B> | <passa / falha> | <passa / falha> |

**Segundo sinal além da cor:** <forma, contorno ou movimento>

## 5. Fonte e interface

Fonte: <nome> · alfabetos: <quais> · licença: <qual> · tamanho mínimo legível: <px>
Tema de UI decidido uma vez, em `<arquivo>` — nenhuma cor solta espalhada pelo código.

## 6. Geometria e estilo

<formas, silhueta, contorno, textura ou ausência dela>

## 7. Onde o acervo entra

| camada | fonte | tratamento |
|---|---|---|
| <o quê> | <gerado / acervo CC0 / código> | <o que muda antes de entrar> |

## 8. Como eu provo que a arte ficou boa

1. **Quadro parado, silhuetas distinguíveis** — legibilidade morre antes do desempenho
2. **ms por quadro com a cena cheia**, nunca com a cena parada
3. **Simulação de daltonismo** gravada acima

---

## Está pronto quando

- [ ] as cinco linhas foram geradas e comparadas antes da escolha
- [ ] toda cor da paleta tem uma função e só uma
- [ ] a prova de daltonismo está preenchida com resultado, não com intenção
- [ ] existe segundo sinal além da cor
