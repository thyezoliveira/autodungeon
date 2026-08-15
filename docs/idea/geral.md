# 🌟 Ideia Geral do Projeto — Autodungeon

**Autodungeon** é um jogo tático de exploração de masmorras e combate autônomo (*Auto-Battler / Dungeon Crawler*) em 3D, projetado para proporcionar profundidade estratégica sem exigir microgerenciamento mecânico contínuo durante as batalhas.

---

## 🎯 1. Premissa Central

O jogador assume o papel de um **Estrategista / Comandante de Guilda**. No refúgio seguro (Lobby), ele recruta heróis de diferentes raças e classes, programa suas prioridades táticas, equipa armas e define consumíveis. 

Ao enviar a equipe para a masmorra:
1. Os heróis avançam de forma autônoma pelos corredores mantendo formação e coesão tática através de **tethering elástico**.
2. Ao avistar inimigos, o combate inicia no **primeiro golpe aterrissado**.
3. Tanques bloqueiam e geram aggro, atacantes de longo alcance realizam kiting e curandeiros priorizam alvos conforme uma árvore de prioridades configurável.
4. Após vencer o Chefe da arena, os heróis marcham até o Baú Dourado e escapam pelo Portal Mágico para recolher espólios, experiência e métricas de desempenho (MVP).

---

## 🏛️ 2. Pilares Fundamentais de Design

* **1. Autonomia com Agência Estratégica:** O jogador não controla cada movimento individual no calor da batalha, mas suas decisões de composição, prioridades e posicionamento no Lobby determinam a vitória ou o wipe.
* **2. Formação Dinâmica & Coesão de Trio:** Três heróis que se movimentam de forma orgânica, com velocidades distintas ajustadas por mola elástica e papéis bem definidos (Tanque na frente, Suporte no meio, DPS atrás).
* **3. Combate Legível & Telegrafado:** Inimigos e chefes telegrafam grandes ataques no chão (1.5s de aviso), permitindo que o jogador compreenda claramente sucessos e erros da IA.
* **4. Ciclo Gratificante de Recompensa (Os 3 Paths):** A transição suave entre Exploração $\rightarrow$ Marcha até o Baú $\rightarrow$ Extração pelo Portal gera uma sensação contínua de progressão e conquista.

---

## 🔗 Navegação
* [Índice Geral de Documentação](../00_indice.md)
* [Escopo & Pitch do MVP](../01_Pitch_MVP.md)
* [Core Loop do Jogo](01_design_sistemas/core_loop.md)
