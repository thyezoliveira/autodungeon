# 🧬 Lista Geral de Raças & Arquitetura Extensível — Autodungeon

Este documento lista as 6 raças base do lançamento inicial e estabelece a conexão com o framework de expansões que permite adicionar novas raças pós-lançamento da Google Play Store.

---

## 📜 1. As 6 Raças Base do Lançamento

Cada raça possui modificadores de atributos, 1 Habilidade Passiva Inata, 1 Habilidade Ativa Racial (longo CD) e regras de afinidade com classes:

1. **[Anão](anao.md):** Estatura baixa, corpos robustos e grande afinidade com forjas e mineração. Bônus em Defesa Física, Força e Engenharia. Habilidade ativa: *Grito da Forja*. Afinidade: Guerreiro e Ladino.
2. **[Elfo](elfo.md):** Altos, esguios e conectados à natureza. Bônus em Inteligência, Agilidade e regeneração contínua de mana. Habilidade ativa: *Vento Feérico*. Afinidade: Mago, Bruxo, Sacerdote e Arqueiro.
3. **[Humano](humano.md):** A raça mais versátil e equilibrada do jogo. Sem penalidades de atributos e com bônus de adaptação rápida. Habilidade ativa: *Vontade de Sobreviver*. Afinidade balanceada com todas as classes.
4. **[Meio-Dragão](meio_dragao.md):** Humanoides escamados com traços dracônicos e alta resistência elemental a fogo. Habilidade ativa: *Sopro Primordial*. Afinidade: Guerreiro, Mago e Bruxo.
5. **[Metadílio](metadilio.md):** Povo pequeno, pacífico e extremamente ágil. Não equipam botas de armadura, compensando com a maior velocidade base e esquiva do jogo. Habilidade ativa: *Pique de Adrenalina*. Afinidade: Ladino e Sacerdote.
6. **[Orc](orc.md):** Maior reserva de HP base do jogo, força bruta implacável e postura intimidatória. Habilidade ativa: *Fúria Sanguinária*. Afinidade: Guerreiro e Bruxo (Xamã).

---

## 🌌 2. Expansões de Raças Pós-Lançamento (LiveOps)

O sistema de raças é data-driven e desacoplado através do recurso `RaceData.tres`. Novas raças podem ser introduzidas nas atualizações de temporada sem modificar o código central da engine:

* **[Guia Completo de Criação de Novas Raças](guia_criacao_novas_racas.md)** *(Template, Power Budget, pipeline e catálogo das expansões: Morto-Vivo, Homem-Fera, Golem, Ínfero e Tritão)*.
* **[Sistema de Sinergias & Ressonâncias](../01_design_sistemas/sistema_expansoes_e_sinergias.md)** *(Bônus ao combinar heróis de mesma raça no trio)*.

