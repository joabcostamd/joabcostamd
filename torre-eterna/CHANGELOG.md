# Changelog

Todas as mudancas visiveis para quem joga. O mesmo conteudo esta em
`data/changelog.json`, que e o que a tela de novidades do jogo le — os dois sao
conferidos pelo portao de dados, entao nao podem divergir.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e a
numeracao segue [SemVer](https://semver.org/lang/pt-BR/).

## [0.9.0] — 2026-09-04

**O jogo que não acaba**

### Modificado

- O jogo passou a se chamar TOWER ZERO. O nome vem de uma linha só em data/marca.json: tela de título, créditos, executável, pasta de save e página da loja leem de lá.

### Adicionado

- As Cepas: 38 traços em três eixos compõem 58.282 formas de inimigo. A segunda cepa só aparece na onda 60 e a terceira na 200 — o Enxame da hora 200 é feito de coisas que não podiam existir na hora 2.
- Os Éditos: cada Ascensão põe três leis na mesa, e cada lei dá uma coisa e cobra outra. Ascender passou a mudar a física do jogo, e não só a velocidade.
- Modo Repouso: com o jogo aberto e ninguém olhando, a tela cai para 6 quadros por segundo e gasta 2,05× menos processador. A simulação não diminui.
- Contador de formas vistas no Bestiário — sem denominador, de propósito.

### Corrigido

- O brilho das eras somava luz em vez de multiplicar: as eras escuras estavam sendo escurecidas em vez de iluminadas.
- A varredura de layout passou a cobrir telas de celular e a mesa das leis.

## [0.8.0] — 2026-09-03

**Tudo o que o jogo prometia e não fazia**

### Modificado

- Motor subido para Godot 4.7.2.

### Corrigido

- Seis dos nove modificadores de elite só trocavam a cor do inimigo, com a mecânica descrita no bestiário.
- A Adaptação do Enxame era binária: todo elemento usado ia ao teto e ficava. Agora é proporcional ao quanto você usa cada um.
- Um save com o campo de versão adulterado congelava o jogo para sempre na abertura.
- "Movimento reduzido" não desligava o zoom da câmera — justamente o movimento que mais provoca enjoo.
