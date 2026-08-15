# Cálculos Gerais & Fórmulas Matemáticas — Autodungeon

Este documento reúne todas as fórmulas matemáticas, tabelas de progressão, cálculos de combate, status de monstros e algoritmos de recompensa de **Autodungeon**.

---

## 1. Fórmulas de Combate & Mitigação

### 💥 Cálculo de Dano Final (Ataque vs Defesa)
O jogo utiliza um sistema de **Mitigação Linear com Teto de Proteção**:

$$\text{Dano Final} = \text{Dano de Ataque} \times \left(1 - \frac{\min(\text{Defesa}, 80)}{100}\right)$$

* **Defesa Máxima Efetiva (Cap):** 80 pontos (garantindo que o herói ou monstro nunca reduza mais que 80% do dano).
* **Dano Mínimo:** Todo ataque que acerte causa no mínimo **1 ponto de dano**.
* **Defesa Mágica vs Física:** Ataques físicos são mitigados pela Defesa Física; magias e feitiços são mitigados pela Defesa Mágica.

### 🎯 Acerto Crítico, Esquiva e Bloqueio
* **Chance de Crítico:** $\text{Crítico \%} = \text{Crítico Base Racial} + \text{Bônus de Equipamentos/Passivas}$.
* **Multiplicadores de Dano Crítico por Tipo de Arma:**
  * *Adagas:* **200% (2.0x)** de dano.
  * *Arcos e Armas de Longo Alcance:* **175% (1.75x)** de dano.
  * *Espadas, Machados, Maças e Cajados:* **150% (1.5x)** de dano.
* **Esquiva:** Se a chance de Esquiva for ativada no golpe, o dano recebido é **0 (Zero)**.
* **Bloqueio de Escudo:** Se a chance de Bloqueio for ativada no golpe físico, o dano recebido é **0 (Zero — Bloqueio Total)**.

---

## 2. Fórmulas de Buffs, Debuffs e Efeitos

* **Buffs e Debuffs Percentuais:**
  $$\text{Atributo Modificado} = \text{Atributo Base} \times (1 \pm \text{Valor \%})$$
* **Dano Contínuo (DoT — Veneno e Sangramento):**
  $$\text{Dano por Segundo (DPS DoT)} = \text{Ataque do Conjurador} \times \%_{\text{efeito}}$$
  *(Aplicado a cada 1 segundo durante a duração total do status).*
* **Regeneração Contínua de Recursos (Fora de Combate):**
  $$\text{Regeneração de Mana} = \text{Mana Máxima} \times 0.05 \text{ a cada 2 segundos}$$
  *(Ativa automaticamente durante a marcha no pathfinding entre encontros).*

---

## 3. Escala de Progressão de XP (Níveis 1 ao 30)

O XP total obtido nas masmorras é dividido igualmente entre os heróis vivos. A tabela abaixo dita o XP necessário para avançar em cada nível:

| Faixa de Nível | Fase do Jogo | XP Necessário por Nível | Marco Desbloqueado |
| :---: | :--- | :--- | :--- |
| **Nível 1–5** | Aprendizagem | 100 → 500 XP | Acesso ao 1º Consumível & 6 Skills Base |
| **Nível 6** | Transição Inicial | 700 XP | **Desbloqueio do 2º Slot de Consumível (20% Cap)** |
| **Nível 7–10** | Consolidação | 900 → 1.500 XP | Equipamentos Médios |
| **Nível 11–14** | Intermediário | 1.800 → 2.800 XP | Armaduras Avançadas |
| **Nível 15** | Especialização | 3.500 XP | **Desbloqueio da Subclasse (50% Cap)** |
| **Nível 16–20** | Avançado | 4.000 → 6.000 XP | Armas Raras de 2 Mãos e Dual Wield |
| **Nível 21–25** | Mestre | 7.000 → 10.000 XP | Equipamentos Épicos |
| **Nível 26–30** | Fim de Jogo (Endgame) | 11.500 → 15.000 XP | **Level Cap 30 & Itens Lendários** |

---

## 4. Escala de Status e Dano dos Monstros

Os atributos dos monstros escalam com base no Nível da Masmorra ($N$):

* **Monstro Comum:**
  * $\text{HP} = \text{HP}_{\text{base}} \times (1 + 0.5 \times (N - 1))$
  * $\text{Ataque} = \text{Ataque}_{\text{base}} \times (1 + 0.3 \times (N - 1))$
  * $\text{Defesa} = \text{Defesa}_{\text{base}} + (2 \times (N - 1))$
* **Monstro Elite:** $2\times\text{HP}$ e $+50\%$ de Dano em relação ao mob comum.
* **Chefe da Masmorra (Boss):** $6\times\text{HP}$ a $10\times\text{HP}$, $+100\%$ de Dano e habilidades em área (AoE).

---

## 5. Taxas de Drop e Recompensas

### 👾 Drops de Monstros Comuns do Caminho
* **Chance de Drop por Monstro:** 20% de chance total ao morrer:
  * 70% Ouro e Consumíveis Comuns (Cinza).
  * 25% Equipamentos Comuns (Nível da Masmorra).
  * 5% Equipamentos Raros (Azul).

### 👑 Recompensa do Baú do Chefe (Final da Masmorra)
Ao derrotar o Boss e abrir o baú, o jogador recebe garantidamente:
1. **Ouro Massivo:** Escala com o nível da masmorra ($50 \times N$ de Ouro).
2. **2 a 3 Equipamentos de Alta Raridade:**
   * 60% Chance de Raro (Azul).
   * 30% Chance de Épico (Roxo).
   * 10% Chance de Lendário (Laranja — itens com efeitos duplos).

---

## 6. Métricas de Partida e Cálculo do MVP

Ao cruzar o Portal de Saída, o jogo calcula o relatório de final de partida:

* **Tempo de Travessia:** Cronômetro total desde a entrada até a saída.
* **DPS Médio do Herói:** $\text{DPS} = \frac{\text{Dano Total Causado}}{\text{Tempo de Combate}}$.
* **Pontuação de Desempenho (Score MVP):**
  $$\text{Pontuação} = \text{Dano Causado} + (\text{Dano Mitigado/Bloqueado} \times 0.8) + (\text{Cura Realizada} \times 1.2)$$
  * O herói com a maior pontuação recebe o destaque de **MVP da Partida** no sumário.
