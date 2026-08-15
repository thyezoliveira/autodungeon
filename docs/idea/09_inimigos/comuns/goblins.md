# Bestiário: Goblins & Xamãs Tribais — Autodungeon

Este documento define a descrição geral, a tabela de atributos, as habilidades ativas e a rotina tática dos **Goblins**, os primeiros habitantes hostis das masmorras e florestas de **Autodungeon**.

---

## 1. Descrição Geral dos Goblins
* **Origem & Comportamento:** Pequenas criaturas humanoides de pele esverdeada, orelhas pontiagudas e comportamento covarde quando sozinhos, mas extremamente agressivos e perigosos quando agrupados em bandos.
* **Habitat Principal:** Florestas Sombrias, Cavernas de Mineração e Galerias Subterrâneas (Estágio 1 — Níveis 1 a 5).
* **Organização Social:** Liderados por Capitães brutais ou Xamãs idosos que manipulam feitiços rudimentares e totens tribais.

---

## 2. Fichas dos 6 Subtipos de Goblins Comuns

### 🗡️ 1. Goblin Guerreiro (Arquétipo: Bruto / Vanguarda)
* **Papel:** Avança em linha reta contra o herói mais próximo (o Tanque) para travar a linha de frente.
* **Atributos Base (Nível 1):** HP: 120 | Mana: 30 | Defesa: 8 | Dano Físico: 14 | Velocidade: 100%
* **Habilidade Ativa:**
  * *Golpe Poderoso (CD 6s / Custo: 10 MP):* Desfere um golpe frontal causando **140% de Dano Físico**.

### 🏹 2. Goblin Arqueiro (Arquétipo: Atirador Ranged)
* **Papel:** Mantém distância máxima disparando flechas de madeira e realiza recuo tático (kiting) se o time se aproximar.
* **Atributos Base (Nível 1):** HP: 70 | Mana: 40 | Defesa: 3 | Dano Físico: 16 | Velocidade: 110%
* **Habilidade Ativa:**
  * *Tiro Certeiro (CD 5s / Custo: 12 MP):* Dispara uma flecha veloz que causa **130% de Dano Perfurante**.

### 🔥 3. Goblin Mago / Xamã de Fogo (Arquétipo: Conjurador / Controlador)
* **Papel:** Fica abrigado na retaguarda lançando feitiços de calor e queimaduras.
* **Atributos Base (Nível 1):** HP: 65 | Mana: 80 | Defesa: 2 | Dano Mágico: 18 | Velocidade: 95%
* **Habilidade Ativa:**
  * *Orbe Ígneo (CD 6s / Custo: 15 MP):* Conjura uma bola de fogo que causa **150% de Dano Mágico de Fogo** e aplica Queimadura leve por 3s.

### 👥 4. Goblin Ladino (Arquétipo: Assassino Flanqueador)
* **Papel:** Inicia em **Invisibilidade Total**, contorna a vanguarda e move-se diretamente até a retaguarda dos heróis (Mago ou Sacerdote), revelando-se apenas após o primeiro golpe.
* **Atributos Base (Nível 1):** HP: 80 | Mana: 50 | Defesa: 4 | Dano Físico: 20 | Velocidade: 125%
* **Habilidade Ativa:**
  * *Golpe Furtivo (CD 8s / Custo: 15 MP):* Ao atacar pelas costas, causa **200% de Dano Crítico**.

### 💣 5. Goblin Suicida / Bombardeiro (Arquétipo: Kamikaze Explosivo)
* **Papel:** Corre freneticamente em direção ao grupo de heróis carregando um barril de pólvora e se autodestrói.
* **Atributos Base (Nível 1):** HP: 45 | Mana: 0 | Defesa: 0 | Dano Físico: 0 | Velocidade: 140%
* **Habilidade Ativa:**
  * *Detonação de Pólvora (Ao Alcançar Alvo ou Morrer):* Explode em raio de 2 tiles causando **180 de Dano Físico em Área** a todos os heróis próximos.

### 🌿 6. Goblin Curandeiro / Herbalista (Arquétipo: Curandeiro dos Monstros)
* **Papel:** Permanece protegido na linha de trás curando os goblins feridos. É o alvo prioritário para assassinos do time.
* **Atributos Base (Nível 1):** HP: 60 | Mana: 90 | Defesa: 2 | Dano Mágico: 8 | Velocidade: 95%
* **Habilidade Ativa:**
  * *Cura Herbal (CD 5s / Custo: 20 MP):* Lança uma poção tribal no aliado com menor porcentagem de vida, restaurando **60 pontos de HP**.

---

## 3. Fichas dos 3 Subtipos de Elites Goblins (Mini-Chefes)

Os monstros Elites possuem o dobro de vida ($2\times\text{HP}$), $+50\%$ de dano, 2 habilidades ativas e uma **Aura de Combate** que beneficia todo o bando enquanto o Elite estiver vivo.

### 👑 1. Capitão Goblin (Elite Vanguarda)
* **Atributos Base (Nível 1):** HP: 300 | Mana: 80 | Defesa: 18 | Dano Físico: 25 | Velocidade: 105%
* **⭐ Aura de Grupo:** *Aura de Fúria Tribal* — Concede **$+20\%$ de Dano de Ataque** para todos os goblins do grupo.
* **Habilidades Ativas (2 Skills):**
  1. *Grito de Guerra (CD 12s):* Aumenta a velocidade de ataque de todos os aliados em $+20\%$ por 6 segundos.
  2. *Impacto Sísmico (CD 8s):* Bate sua maça pesada no chão causando dano em cone frontal e **Atordoamento (Stun) de 1.5s** no Tanque.

### 🧙 2. Xamã Arquimago Goblin (Elite Conjurador & Buffer)
* **Atributos Base (Nível 1):** HP: 180 | Mana: 160 | Defesa: 8 | Dano Mágico: 30 | Velocidade: 100%
* **⭐ Aura de Grupo:** *Aura Vampírica do Pântano* — Concede **15% de Roubo de Vida (Lifesteal)** em todos os ataques e magias dos goblins do grupo.
* **Habilidades Ativas (2 Skills):**
  1. *Pilar de Fogo (CD 9s):* Erupção vulcânica que atinge uma área circular causando **220% de Dano Mágico de Fogo**.
  2. *Totem de Fortalecimento (CD 15s):* Planta um totem que concede $+15$ de Defesa física e mágica a todos os aliados ao redor.

### 👤 3. Rastreador Sombrio Goblin (Elite Assassino)
* **Atributos Base (Nível 1):** HP: 200 | Mana: 100 | Defesa: 10 | Dano Físico: 32 | Velocidade: 135%
* **⭐ Aura de Grupo:** *Aura de Celeridade das Sombras* — Concede **$+25\%$ de Velocidade de Movimento e Ataque** para todos os goblins do grupo.
* **Habilidades Ativas (2 Skills):**
  1. *Passo das Sombras (CD 10s):* Teleporta-se instantaneamente para as costas do herói mais frágil desferindo um corte crítico.
  2. *Lâminas Venenosas (CD 6s):* Aplica veneno que causa **40 de dano contínuo (DoT)** por segundo durante 4 segundos.
