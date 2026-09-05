# Picross 3D — maquetes

Três telas do jogo, desenhadas por código antes de existir jogo. Isométrica em
Python (PIL), sem engine 3D: cada cubo é três losangos com tons diferentes,
pintados do fundo para a frente.

```bash
cd estudos/picross3d && python3 gerar.py
```

| Arquivo | O que mostra |
|---|---|
| `saida/1-inicio.png` | bloco 9×9×9 intacto, com as pistas nas três faces visíveis |
| `saida/2-meio.png` | meio da dedução: marcado, em dúvida, e o que já virou pó |
| `saida/3-revelada.png` | a figura que estava escondida |

## A regra que as pistas seguem

Cada número está na ponta de uma fileira e diz **quantos cubos daquela fileira
fazem parte da figura**. O símbolo diz como estão distribuídos:

| Marca | Significa |
|---|---|
| só o número | os cubos estão todos juntos |
| número em círculo | estão em **dois** grupos separados |
| número em quadrado | estão em **três ou mais** grupos |

É a regra do Picross 3D, e é o que torna a dedução possível sem chutar.

## Decisões medidas

**Gato foi tentado e descartado.** Em isométrica, corpo e cabeça de larguras
parecidas se fundem num blob irreconhecível. Silhueta forte vence detalhe — o
cogumelo (chapéu largo sobre pé fino) lê de longe.

**Número chapado por cima do cubo não convence.** As pistas são deformadas para
o plano da face por transformação afim (`voxel.texto_na_face`). Sem isso a
maquete parece diagrama, não jogo.
