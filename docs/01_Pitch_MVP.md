# 🚀 Documento de Escopo & Pitch do MVP — Autodungeon

Este documento define o escopo restrito e cirúrgico para a primeira versão jogável (**MVP — Minimum Viable Product**) de **Autodungeon**, estabelecendo a base mínima funcional para validar a diversão da gameplay antes da expansão para o conteúdo completo.

---

## 🎯 1. Objetivo Central do MVP
Validar a hipótese central do jogo:
> *"Um auto-battler / dungeon crawler de 3 heróis autônomos com marcha fluida, papéis táticos bem definidos (Tank, DPS, Suporte) e chefes com ataques telegrafados proporciona uma experiência gratificante e estratégica sem exigir microgerenciamento constante do jogador."*

---

## 📦 2. O Escopo Mínimo Viável (O que entra no MVP)

```text
+-------------------------------------------------------------------------------+
|                                FLUXO DO MVP                                   |
|                                                                               |
|  [ TELA DE TÍTULO ] ---> [ HUD DE BATALHA ] ---> [ ARENA CHEFE ] ---> [ RESUMO ]
|   (Toque p/ Iniciar)     (3 Heróis no Graybox)   (Boss + Baú + Portal)   (Vitória)
+-------------------------------------------------------------------------------+
```

### 👥 2.1. Trio de Heróis do MVP (3 Personagens)
Para testar a santíssima trindade de combate sem sobrecarregar o desenvolvimento inicial:
1. **Bromm, o Baluarte de Pedra (Tank - Frente):**
   * *Função:* Avança, absorve dano, gera aggro e bloqueia golpes com escudo.
   * *Skills:* *Investida* (inicia combate) e *Postura Defensiva*.
2. **Elysia, a Flecha Fantasma (DPS - Trás):**
   * *Função:* Dispara flechas à distância e recua (kiting) se inimigos se aproximarem.
   * *Skills:* *Tiro Certeiro* e *Chuva de Flechas*.
3. **Irmã Beatrice, a Luz da Alvorada (Suporte - Meio):**
   * *Função:* Monitora a vida dos aliados, prioriza curar o Tanque e salva aliados feridos.
   * *Skills:* *Cura Rápida* e *Escudo de Fé*.

---

### 🗺️ 2.2. Mapa & Cenário do MVP (1 Nível Graybox)
Baseado na planta arquitetônica de [dungeon_graybox.md](idea/07_Mundo_e_Narrativa/Cenarios_e_niveis/dungeon_graybox.md):
* **Sala 0 (Spawn):** Largada segura da equipe e teste da velocidade de marcha em formação.
* **Sala 1 (Encontro Básico):** 2 Goblins Guerreiros + 1 Goblin Arqueiro. Testa engajamento no primeiro golpe e kiting.
* **Corredor de Transição:** Testa curvas do NavMesh e **regeneração contínua de mana**.
* **Sala 2 (Encontro com Mini-Chefe):** 1 Capitão Goblin Elite (com *Aura de Fúria Tribal*) + 1 Goblin Curandeiro. Testa foco do time e queda da aura na morte do capitão.
* **Sala 3 (Arena do Chefe):**
  * Portão tranca ao entrar.
  * **Chefe Rei Goblin:** Ataques normais + Ataque Telegrafado com área vermelha no chão (1.5s de aviso).
  * Ao derrotar o chefe: Spawn do **Baú Dourado** e ativação do **Portal Mágico**.
  * **Marcha dos Paths 2 e 3:** Heróis caminham automaticamente até o baú para coletar espólios e entram no portal para finalizar.

---

### ⚙️ 2.3. Mecânicas de Sistemas no MVP
* **Movimentação:** Marcha autônoma em formação e tethering elástico entre os 3 heróis.
* **Combate Autônomo:** Gatilho de combate no primeiro impacto físico; mira e conjuração de skills com Cooldown (CD).
* **Consumível Básico:** 1 slot ativo com *Poção de Vida Menor* (disparo automático se HP < 30% ou toque manual no HUD).
* **Números de Dano Flutuantes:** Dano no inimigo (Branco), Dano no herói (Vermelho), Cura (Verde) e Bloqueio (Azul).

---

### 🖥️ 2.4. Telas & Interface (UI/UX do MVP)
1. **Tela de Título:** Logo do jogo + Botão "Iniciar Expedição de Teste".
2. **HUD de Batalha:**
   * 3 Retratos dos heróis na parte inferior com barras verticais de HP (esquerda) e MP (direita).
   * Ícones de habilidades mostrando máscara radial de Cooldown (CD).
   * Botão de poção clicável.
   * Cronômetro e contador de itens no topo.
3. **Tela de Vitória / Fim de Masmorra:**
   * Mensagem de "Masmorra Concluída!".
   * Resumo de Ouro e Itens coletados.
   * Botão para reiniciar o teste.

---

## 🚫 3. O que FICA FORA do MVP (Backlog Pós-MVP)
* ❌ Catálogo completo dos 15 heróis e sistema de recrutamento/gacha.
* ❌ Fases 1 a 10 e múltiplos biomas temáticos (Floresta, Criptas, etc.).
* ❌ Telas completas de Ferreiro (aprimoramento de itens) e Loja de Consumíveis.
* ❌ 90 habilidades e 220 equipamentos completos (o MVP usa apenas os itens básicos dos 3 heróis).
* ❌ Sistema de personalização profunda de inventário com 40 slots e filtros complexos.

---

## ✅ 4. Critérios de Sucesso do Teste do MVP
Ao rodar a build do MVP na Godot Engine, o teste será considerado um sucesso se:
1. **Legibilidade:** O jogador entende claramente o que está acontecendo sem precisar pausar a cada segundo.
2. **Coesão:** Os 3 heróis não se separam, não ficam presos nas paredes e mantêm a formação correta.
3. **Sensação de Recompensa:** O momento pós-chefe (caminhar até o baú dourado, ver o brilho dos espólios e entrar no portal) gera satisfação imediata.
4. **Estabilidade de Loop:** O loop completo (Iniciar -> Batalhar -> Coletar -> Finalizar -> Reiniciar) executa sem erros ou travamentos.
