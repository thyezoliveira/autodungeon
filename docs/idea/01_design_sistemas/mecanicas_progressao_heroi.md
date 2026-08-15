# Mecânicas de Progressão de Herói — Autodungeon

Este documento define as regras de ganho e divisão de Experiência (XP), o limite máximo de nível (**Level Cap 30**), marcos de desbloqueio de sistemas e a mecânica de requisitos de nível para equipamentos em **Autodungeon**.

---

## 1. Visão Geral da Progressão e Filosofia de Nível
* **Level Cap Máximo:** Todos os heróis podem evoluir do **Nível 1 até o Nível 30**.
* **Poder Centralizado nos Equipamentos:** Subir de nível não infla atributos vitais automaticamente. A subida de nível serve fundamentalmente como **requisito de acesso e permissão** para empunhar e vestir equipamentos de níveis superiores, além de desbloquear slots e subclasses.
* **Divisão de Experiência (XP):** Todo o XP obtido ao abater grupos de monstros e chefes na masmorra é **dividido igualmente entre os heróis vivos** da equipe ao final de cada combate.

---

## 2. Linha do Tempo de Marcos de Nível (Milestones 1–30)

```mermaid
graph LR
    Lv1[Nível 1: Início] -->|6 Skills Base + 1 Consumível| Lv6[Nível 6: 20% Cap]
    Lv6 -->|Desbloqueia 2º Consumível| Lv15[Nível 15: 50% Cap]
    Lv15 -->|Desbloqueia Subclasse| Lv30[Nível 30: Level Cap]
    Lv30 --> EndGame[Equipamentos de Poder Máximo]
```

### 📌 Marcos Principais:
1. **Nível 1 (Recrutamento Inicial):**
   * O herói inicia com equipamento básico de Nível 1.
   * Acesso imediato às **6 habilidades da classe base** (podendo equipar 3 no Lobby).
   * Acesso ao **1º Slot de Consumível**.
2. **Nível 6 (20% do Level Cap):**
   * Desbloqueio automático do **2º Slot de Consumível**, permitindo carregar duas poções/itens para a masmorra.
3. **Nível 15 (50% do Level Cap):**
   * Desbloqueio da **Subclasse** do herói.
   * As 3 habilidades da subclasse são adicionadas ao repertório, totalizando um pool de **9 habilidades** para selecionar as 3 ativas equipadas.
4. **Nível 30 (Level Cap Máximo):**
   * Nível máximo de progressão do herói.
   * Habilita o uso dos equipamentos mais raros e poderosos de fim de jogo.

---

## 3. Requisitos de Nível para Equipamentos

Todos os itens equipáveis (Armas, Armaduras, Escudos e Acessórios) possuem um **Nível Mínimo Requerido** para serem vestidos:

* **Regra de Bloqueio:** Um herói de nível inferior ao nível do item não pode equipá-lo em hipótese alguma (o item fica destacado em vermelho no inventário com a indicação do nível necessário).
* **Progressão de Drops:**
  * Durante as explorações em masmorras mais difíceis, o jogador pode encontrar itens de nível superior ao nível atual de seus heróis (ex: um herói Nível 3 dropa uma espada Nível 5).
  * O item é guardado na bolsa e poderá ser equipado assim que o herói acumular o XP necessário para alcançar o nível exigido.
* **Escala de Poder:** Quanto maior o nível exigido pelo item, maiores serão seus atributos base (Dano de ataque, Defesa física/mágica, Taxa de Bloqueio e bônus de acessórios).
