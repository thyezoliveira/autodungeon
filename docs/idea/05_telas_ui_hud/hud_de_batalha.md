# HUD de Batalha & Masmorra — Autodungeon

Este documento define o layout, os elementos gráficos e o sistema de feedback visual do HUD (Heads-Up Display) em tempo real durante as expedições em **Autodungeon**.

---

## 1. Visão Geral do Layout em Tela

```
+-------------------------------------------------------------+
| [🎒 Itens: 2 / 7]        [⏱️ 03:15]              [ ⏸️ Menu ] |
|                                                             |
|           [ BARRA DE VIDA DO CHEFE: 100% -> 50% -> 10% ]    |
|                                                             |
|                          ( CENÁRIO )                        |
|                                                             |
|   Hero 1 (Nome)              Hero 2 (Nome)    Hero 3 (Nome) |
|      (250)                       (CRIT 580)        (+120)   |
|     [Branco]                      [Laranja]       [Verde]   |
|                                                             |
+-------------------------------------------------------------+
|    [HERÓI 1]                 [HERÓI 2]            [HERÓI 3] |
| [|] [FOTO] [|]             [|] [FOTO] [|]       [|] [FOTO] [|]
| HP         MP              HP         MP        HP         MP
| [S1] [S2] [S3]             [S1] [S2] [S3]       [S1] [S2] [S3]
|   [C1]   [C2]                [C1]   [C2]          [C1]   [C2]
+-------------------------------------------------------------+
```

---

## 2. Painel dos 3 Heróis (Parte Inferior da Tela)

A base da tela é ocupada pelos painéis táticos dos 3 heróis da equipe ativa:

### 👤 Estrutura Individual de Cada Herói:
1. **Barras Verticais de Recursos:**
   * **Barra de Vida (HP - Esquerda):** Barra vertical verde indicando a integridade física do personagem. Pisca em vermelho quando HP < 25%.
   * **Barra de Mana (MP - Direita):** Barra vertical azul indicando a reserva de mana para lançamento de habilidades.
2. **Retrato do Herói (Centro):**
   * Exibe a ilustração facial do herói e o nível atual.
   * Se o herói for derrotado/incapacitado, o retrato fica acinzentado com o ícone de caveira.
   * **Ícones de Buffs/Debuffs:** Pequenos ícones temporários exibidos logo acima do retrato com contador de tempo em segundos.
3. **3 Ícones de Habilidades Ativas (Skills):**
   * Localizados imediatamente abaixo do retrato.
   * Mostram a máscara de sombreamento radial de **Tempo de Recarga (Cooldown / CD)**.
4. **2 Slots de Consumíveis:**
   * Localizados logo abaixo das habilidades.
   * Exibem o ícone do item, o número de cargas disponíveis (ex: `x2`) e o tempo de recarga individual.
   * **Interação Manual:** O jogador pode tocar no ícone a qualquer momento para forçar o consumo imediato de 1 carga.

---

## 3. Barra Superior & Informações da Masmorra

* **Contador de Espólios do Mapa:** Exibe a quantidade de itens coletados comparada ao total restante na masmorra (`[🎒 Itens: X / Total]`).
* **Cronômetro da Masmorra:** Exibe o tempo decorrido desde o spawn inicial (`[⏱️ MM:SS]`).
* **Botão de Menu/Pausa (`[ ⏸️ ]`):**
  * Abre a Janela Modal de Pausa, congelando a simulação do jogo.
  * Opções: *Continuar*, *Configurações de Áudio/Gráficos* e *Abandonar Masmorra* (com confirmação de perda de progresso).
* **Barra de Vida do Chefe (Boss Bar):**
  * Surge na parte superior central apenas ao entrar na Sala do Chefe.
  * Contém marcadores visuais destacados nas marcas de **50% de HP (Fase 2 / Fúria)** e **10% de HP (Golpe Supremo)**.

---

## 4. Elementos Flutuantes no Cenário (Mundo do Jogo)

### 🏷️ Nomes e Barras de Monstros
* **Nomes dos Heróis:** Flutuam acima da cabeça de cada personagem no cenário para fácil identificação em combate.
* **Barra de Vida dos Monstros Comuns:** Pequena barra horizontal acima da cabeça de cada inimigo, diminuindo conforme recebe dano.

### 💥 Texto de Combate Flutuante (Floating Combat Text)
Números dinâmicos que sobem e desaparecem suavemente com código de cores padronizado:

| Efeito / Ação | Cor do Número | Estilo Visual |
| :--- | :---: | :--- |
| **Dano Físico/Mágico Comum no Inimigo** | **Branco** | Tamanho padrão, sobe verticalmente. |
| **Dano Crítico no Inimigo** | **Laranja** | Fonte ampliada em $+50\%$ com leve tremor de impacto. |
| **Dano Sofrido pelo Herói da Equipe** | **Vermelho** | Sobe acima da cabeça do herói atingido. |
| **Cura Recebida** | **Verde** | Precedido pelo sinal de `+` (ex: `+150`). |
| **Bloqueio de Escudo (100% Físico)** | **Azul Metálico** | Texto descritivo `BLOQUEADO`. |
| **Esquiva Bem-Sucedida** | **Amarelo** | Texto descritivo `ESQUIVA`. |
