# ⚔️ Lista Geral de Classes & Arquitetura Extensível — Autodungeon

Este documento lista as 6 classes base e suas 18 subclasses do lançamento inicial, além de detalhar o framework de expansão que permite adicionar novas classes e culminar em novos heróis pós-lançamento da Google Play Store.

---

## 📜 1. As 6 Classes Base & 18 Subclasses do Lançamento

Cada classe possui **6 Habilidades Base** e **3 Subclasses** (desbloqueadas no Nível 15, com 3 habilidades exclusivas cada), totalizando um repertório de **15 Habilidades por Classe**:

1. **[Arqueiro](arqueiro.md):** Especialista em combate à distância, tiros precisos e kiting.
   * *Subclasses:* Besteiro, Caçador, Pistoleiro.
2. **[Bruxo](bruxo.md):** Magias de drenagem, controle sombrio, maldições e pactos da natureza.
   * *Subclasses:* Druida, Xamã, Necromante.
3. **[Guerreiro](guerreiro.md):** Vanguarda de combate corpo a corpo, armaduras pesadas e controle de aggro.
   * *Subclasses:* Paladino, Berserker, Baluarte.
4. **[Ladino](ladino.md):** Mestre em ataques críticos, adagas duplas, venenos, utilidade musical e furtividade.
   * *Subclasses:* Sombra, Bardo, Assassino.
5. **[Mago](mago.md):** Destruição elemental massiva, controle de campo e feitiçaria arcana.
   * *Subclasses:* Elementalista, Rúnico, Ilusionista.
6. **[Sacerdote](sacerdote.md):** Suporte primário, cura de emergência, bênçãos divinas e julgamento.
   * *Subclasses:* Clérigo, Inquisidor, Oráculo.

---

## 🌌 2. Expansões de Classes Pós-Lançamento (LiveOps)

O sistema de classes é orientado a dados (`ClassData.tres`). Novas classes são adicionadas via pacotes de expansão sem modificar os sistemas de combate consolidados:

* **[Guia Completo de Criação de Novas Classes](guia_criacao_novas_classes.md)** *(Template, regras de 15 habilidades e catálogo das expansões: Monge, Cavaleiro da Morte, Alquimista e Invocador)*.
* **[Guia de Criação de Novas Skills & Efeitos](../04_skills/guia_criacao_novas_skills_e_efeitos.md)** *(Efeitos polimórficos, CC e combos elementais)*.
* **[Pipeline de Criação de Novos Heróis Únicos](herois_unicos/guia_pipeline_novos_herois.md)** *(A convergência de Raça + Classe + Lore nos Heróis #16 ao #30+)*.

