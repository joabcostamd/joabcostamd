# Torre entre Dimensões — direção de arte

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
