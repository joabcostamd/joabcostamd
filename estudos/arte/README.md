# Estudos de arte procedural

Cinco provas visuais, geradas 100% por código — nenhuma imagem de origem.
Servem para escolher o próximo jogo com a imagem na mão, antes de existir jogo.

```bash
cd estudos/arte && python3 poda.py     # e vitral / tinta / geada / constelacao
```

| Arquivo | Técnica | Custo |
|---|---|---|
| `poda.py` | L-system com atração pela luz | 6 s |
| `vitral.py` | Voronoi + Lloyd, luz projetada | 15 s |
| `tinta.py` | advecção por rotacional de ruído + difusão | 15 s |
| `geada.py` | DLA (agregação limitada por difusão) | 52 s |
| `constelacao.py` | campo de estrelas + nebulosa por fBm | 4 s |

Tudo determinístico: a mesma semente dá a mesma imagem.

## O que foi medido (e contrariou o palpite)

**A geada só virou samambaia na terceira tentativa.** As duas primeiras falharam
por motivos opostos, e nenhuma dava erro:

1. Andarilho nascendo em qualquer lugar da tela quase nunca encontra o cristal —
   **114 partículas** agregadas em 5200 passos.
2. Semeando a borda inteira e empurrando as partículas para baixo, a geada cobre
   tudo por igual: **papel de parede**, não cristal.
3. O que funcionou: poucos pontos de nucleação, passeio puro sem queda, e
   nascimento bem acima da frente. A ponta alta intercepta a partícula antes do
   vale — essa **sombra** é o que faz o ramo existir.

**Brilho aditivo estoura em branco.** A primeira folhagem da árvore virou algodão
branco porque somei halos de luz. Massa de cor pede mistura normal (`base.mancha`),
não aditiva (`base.brilho_radial`).
