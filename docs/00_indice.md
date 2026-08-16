# 🗺️ Índice Geral do Game Design & Engenharia (Autodungeon)

Bem-vindo ao índice central de documentação do jogo **Autodungeon**. Este arquivo atua como o mapa interativo de navegação para todas as ideias, sistemas, raças, classes, habilidades, itens, cenários, arquitetura técnica, planejamento, publicação e expansões contínuas (**LiveOps**) do projeto.

---

## 📌 00. Visão Geral & Documentos Mestres
* 📜 [Ideia Geral do Projeto](idea/geral.md) *(Visão de alto nível, premissa central e pilares de design)*
* 🚀 [Escopo & Pitch do MVP](01_Pitch_MVP.md) *(Documento de escopo da primeira versão jogável de teste na engine)*
* 📐 [Método de Organização do GDD](Metodo_Organizacao_GDD.md) *(Diretrizes modulares e convenções de documentação)*
* 🏛️ [Arquitetura Técnica & Engenharia de Software (Godot 4.x)](projeto/00_indice_arquitetura.md) *(Projeto técnico orientado a objetos, nós, FSM, data-driven e sistemas)*
* 📋 [Planejamento do MVP & Gestão de Versões (Godot 4.7+ 3D)](planejamento/00_indice_planejamento.md) *(Marcos M0 a M8, controle de mudanças, Git LFS, SemVer e cronograma)*
* 📱 [Roadmap Comercial & Guia de Publicação Play Store](roadmap_comercial_playstore.md) *(Monetização Freemium, IAP/Ads, compliance Google Play, otimização mobile 3D, Fases 1 a 6 e LiveOps)*

---

## ⚙️ 01. Design de Sistemas
* [Core Loop do Jogo](idea/01_design_sistemas/core_loop.md) *(Lobby com Ferreiro/Mercador, 3-5 encontros por masmorra, Boss e regras de Wipe)*
* [Mecânicas de Movimento & Pathfinding](idea/01_design_sistemas/mecanicas_movimento.md) *(Navegação autônoma em 3 trajetos: Paths 1, 2 e 3, tethering elástico e formação adaptável)*
* [Mecânicas de Combate](idea/01_design_sistemas/mecanicas_combate.md) *(Engajamento por primeiro golpe aterrissado, kiting de ranged, prioridades de cura e regeneração contínua de mana)*
* [Mecânicas de Gerenciamento de Time](idea/01_design_sistemas/mecanicas_gerenciamento_time.md) *(Equipe de 3 heróis, 3 slots de itens, 2 consumíveis e 3 skills ativas com sub-abas)*
* [Mecânicas de Equipamento](idea/01_design_sistemas/mecanicas_equipamento.md) *(Slot 1: Arma 1H/2H/Dual Wield, Slot 2: Armadura Leve/Média/Pesada, Slot 3: Escudo ou Acessório)*
* [Mecânicas de Consumíveis](idea/01_design_sistemas/mecanicas_consumiveis.md) *(2 slots com desbloqueio no Nv 6, cargas por raridade 1x/2x/3-4x/5x, gatilho inato, toque manual e CD individual)*
* [Mecânicas de Progressão de Herói](idea/01_design_sistemas/mecanicas_progressao_heroi.md) *(Level Cap 30, marcos nos Níveis 1, 6 e 15, requisitos de equipamentos e divisão igual de XP)*
* [Cálculos Gerais & Fórmulas](idea/01_design_sistemas/calculos_gerais.md) *(Mitigação linear, críticos por arma, tabela de XP 1-30, status de monstros, drops e fórmula de MVP)*
* [Mecânicas de Inimigos & IA](idea/01_design_sistemas/mecanicas_inimigos.md) *(Packs de 2 a 5 monstros, 9 arquétipos táticos de IA, mecânica de assassino furtivo e auras de elites)*
* [Mecânicas de Chefes & Arenas](idea/01_design_sistemas/mecanicas_bosses.md) *(Arena fechada, loop de telegrafia vermelha, transição de Fase 2 e Golpe Supremo único aos 10% de HP)*
* 🌌 **[Sistema de Expansões, Sinergias & Variedade de Gameplay](idea/01_design_sistemas/sistema_expansoes_e_sinergias.md)** *(Ressonâncias de equipe por raça/classe, afixos de masmorra rotativos, Torre do Infinito, Daily Rifts e Maestria Pós-Cap 30)*

---

## 🧬 02. Personagens & Raças
* 📜 [Regras Gerais & Arquitetura Extensível de Raças](idea/02_racas/_lista_e_regras.md) *(Estrutura com passiva e habilidade racial de longo cooldown)*
* 🛡️ [Anão](idea/02_racas/anao.md) *(Defesa, Força, Engenharia e Grito da Forja)*
* 🏹 [Elfo](idea/02_racas/elfo.md) *(Inteligência, Velocidade, Regeneração Contínua de Mana e Vento Feérico)*
* ⚖️ [Humano](idea/02_racas/humano.md) *(Equilíbrio, adaptabilidade, versatilidade e Vontade de Sobreviver)*
* 🐉 [Meio-Dragão](idea/02_racas/meio_dragao.md) *(Híbrido Físico/Mágico, Resistência a Queimadura e Sopro Primordial)*
* 👣 [Metadílio](idea/02_racas/metadilio.md) *(Máxima Agilidade/Esquiva, sem slot de botas e Pique de Adrenalina)*
* 🪓 [Orc](idea/02_racas/orc.md) *(Maior HP do jogo, Força Bruta e Fúria Sanguinária com Lifesteal)*
* 🧬 **[Guia de Criação & Catálogo de Novas Raças](idea/02_racas/guia_criacao_novas_racas.md)** *(Framework, template, Power Budget e fichas de expansão: Morto-Vivo, Homem-Fera, Golem, Ínfero e Tritão)*

---

## ⚔️ 03. Classes de Personagens
* 📜 [Lista Geral, Regras & Arquitetura de Classes](idea/03_classes/_lista_e_regras.md) *(Sistema de subclasses desbloqueadas no Nível 15)*
* 🏹 [Arqueiro](idea/03_classes/arqueiro.md) *(Subclasses: Besteiro, Caçador, Pistoleiro)*
* 🔮 [Bruxo](idea/03_classes/bruxo.md) *(Subclasses: Druida, Xamã, Necromante)*
* 🛡️ [Guerreiro](idea/03_classes/guerreiro.md) *(Subclasses: Paladino, Berserker, Baluarte)*
* 🗡️ [Ladino](idea/03_classes/ladino.md) *(Subclasses: Sombra, Bardo, Assassino)*
* ✨ [Mago](idea/03_classes/mago.md) *(Subclasses: Elementalista, Rúnico, Ilusionista)*
* ✝️ [Sacerdote](idea/03_classes/sacerdote.md) *(Subclasses: Clérigo, Inquisidor, Oráculo)*
* ⚔️ **[Guia de Criação & Catálogo de Novas Classes](idea/03_classes/guia_criacao_novas_classes.md)** *(Framework de 15 habilidades por classe e fichas de expansão: Monge, Cavaleiro da Morte, Alquimista e Invocador)*

### 👥 Heróis Únicos Iniciais (15 Fichas)
* **Tanks (4 Heróis):**
  * [Bromm, o Baluarte de Pedra](idea/03_classes/herois_unicos/bromm/bromm.md) *(Anão / Guerreiro - Baluarte)*
  * [Ignis, o Dragão de Ferro](idea/03_classes/herois_unicos/ignis/ignis.md) *(Meio-Dragão / Guerreiro - Paladino)*
  * [Grommash, o Rompe-Montanhas](idea/03_classes/herois_unicos/grommash/grommash.md) *(Orc / Guerreiro - Berserker)*
  * [Sir Alistair, o Escudo de Valória](idea/03_classes/herois_unicos/alistair/alistair.md) *(Humano / Guerreiro - Paladino)*
* **DPS Físico & Mágico (7 Heróis):**
  * [Elysia, a Flecha Fantasma](idea/03_classes/herois_unicos/elysia/elysia.md) *(Elfo / Arqueiro - Caçador)*
  * [Kaelen, o Carrasco das Sombras](idea/03_classes/herois_unicos/kaelen/kaelen.md) *(Humano / Ladino - Assassino)*
  * [Valtrak, a Chama Primordial](idea/03_classes/herois_unicos/valtrak/valtrak.md) *(Meio-Dragão / Mago - Elementalista)*
  * [Pip, o Truque Rápido](idea/03_classes/herois_unicos/pip/pip.md) *(Metadílio / Ladino - Sombra)*
  * [Doran, o Atirador de Elite](idea/03_classes/herois_unicos/doran/doran.md) *(Anão / Arqueiro - Besteiro)*
  * [Morrigan, a Dama dos Corvos](idea/03_classes/herois_unicos/morrigan/morrigan.md) *(Humano / Bruxo - Necromante)*
  * [Zephyr, a Tempestade Viva](idea/03_classes/herois_unicos/zephyr/zephyr.md) *(Elfo / Mago - Rúnico)*
* **Suporte, Cura & Buffs (4 Heróis):**
  * [Irmã Beatrice, a Luz da Alvorada](idea/03_classes/herois_unicos/beatrice/beatrice.md) *(Humano / Sacerdote - Clérigo)*
  * [Faelar, a Voz dos Bosques](idea/03_classes/herois_unicos/faelar/faelar.md) *(Elfo / Bruxo - Druida)*
  * [Milo, o Melodista das Vielas](idea/03_classes/herois_unicos/milo/milo.md) *(Metadílio / Ladino - Bardo)*
  * [Urok, o Conjurador de Sangue](idea/03_classes/herois_unicos/urok/urok.md) *(Orc / Bruxo - Xamã)*

### 👑 Expansões de Heróis Pós-Lançamento (Heróis #16 ao #30+)
* 👑 **[Pipeline de Criação de Novos Heróis Únicos](idea/03_classes/herois_unicos/guia_pipeline_novos_herois.md)** *(Convergência de Raça + Classe + Lore + 3D + Fichas de Valéria, Jin, Zarek, Nyx e Thalassa)*

---

## 🪄 04. Compêndio de Habilidades & Skills
* 🪄 **[Guia de Criação de Novas Skills, Efeitos & Sinergias](idea/04_skills/guia_criacao_novas_skills_e_efeitos.md)** *(Efeitos polimórficos, CC Stun/Freeze/Silence/Taunt, combos elementais e balanceamento)*

### 🏹 Arqueiro
* **Habilidades Base:**
  * [Tiro Certeiro](idea/04_skills/arqueiro/tiro_certeiro.md) | [Chuva de Flechas](idea/04_skills/arqueiro/chuva_de_flechas.md) | [Tiro Envenenado](idea/04_skills/arqueiro/tiro_envenenado.md) | [Salto Evasivo](idea/04_skills/arqueiro/salto_evasivo.md) | [Olho de Falcão](idea/04_skills/arqueiro/olho_de_falcao.md) | [Disparo Rápido](idea/04_skills/arqueiro/disparo_rapido.md)
* **Subclasses:**
  * **Besteiro:** [Tiro Perfurante](idea/04_skills/arqueiro/besteiro/tiro_perfurante.md) | [Recarga Tática](idea/04_skills/arqueiro/besteiro/recarga_tatica.md) | [Foco Fatal](idea/04_skills/arqueiro/besteiro/foco_fatal.md)
  * **Caçador:** [Invocar Companheiro](idea/04_skills/arqueiro/cacador/invocar_companheiro.md) | [Mira Telescópica](idea/04_skills/arqueiro/cacador/mira_telescopica.md) | [Armadilha de Espinhos](idea/04_skills/arqueiro/cacador/armadilha_de_espinhos.md)
  * **Pistoleiro:** [Rajada Dupla](idea/04_skills/arqueiro/pistoleiro/rajada_dupla.md) | [Tiro à Queima-Roupa](idea/04_skills/arqueiro/pistoleiro/tiro_a_queima_roupa.md) | [Dança de Chumbo](idea/04_skills/arqueiro/pistoleiro/danca_de_chumbo.md)

### 🔮 Bruxo
* **Habilidades Base:**
  * [Esfera de Energia](idea/04_skills/bruxo/esfera_de_energia.md) | [Raízes Aprisionadoras](idea/04_skills/bruxo/raizes_aprisionadoras.md) | [Pacto de Sangue](idea/04_skills/bruxo/pacto_de_sangue.md) | [Drenar Vida](idea/04_skills/bruxo/drenar_vida.md) | [Aura de Decadência](idea/04_skills/bruxo/aura_de_decadencia.md) | [Invocar Espírito](idea/04_skills/bruxo/invocar_espirito.md)
* **Subclasses:**
  * **Druida:** [Florescimento](idea/04_skills/bruxo/druida/florescimento.md) | [Pele de Casca](idea/04_skills/bruxo/druida/pele_de_casca.md) | [Enxame de Insetos](idea/04_skills/bruxo/druida/enxame_de_insetos.md)
  * **Xamã:** [Totem da Força](idea/04_skills/bruxo/xama/totem_da_forca.md) | [Corrente de Raios](idea/04_skills/bruxo/xama/corrente_de_raios.md) | [Sede de Sangue](idea/04_skills/bruxo/xama/sede_de_sangue.md)
  * **Necromante:** [Erguer Esqueletos](idea/04_skills/bruxo/necromante/erguer_esqueletos.md) | [Explosão de Cadáver](idea/04_skills/bruxo/necromante/explosao_de_cadaver.md) | [Maldição do Enfraquecimento](idea/04_skills/bruxo/necromante/maldicao_do_enfraquecimento.md)

### 🛡️ Guerreiro
* **Habilidades Base:**
  * [Golpe Fendido](idea/04_skills/guerreiro/golpe_fendido.md) | [Grito de Guerra](idea/04_skills/guerreiro/grito_de_guerra.md) | [Investida](idea/04_skills/guerreiro/investida.md) | [Pele de Aço](idea/04_skills/guerreiro/pele_de_aco.md) | [Corte Giratório](idea/04_skills/guerreiro/corte_giratorio.md) | [Postura Defensiva](idea/04_skills/guerreiro/postura_defensiva.md)
* **Subclasses:**
  * **Paladino:** [Aura de Devoção](idea/04_skills/guerreiro/paladino/aura_de_devocao.md) | [Golpe Sagrado](idea/04_skills/guerreiro/paladino/golpe_sagrado.md) | [Mão da Cura](idea/04_skills/guerreiro/paladino/mao_da_cura.md)
  * **Berserker:** [Fúria Cega](idea/04_skills/guerreiro/berserker/furia_cega.md) | [Corte Brutal](idea/04_skills/guerreiro/berserker/corte_brutal.md) | [Grito de Sangue](idea/04_skills/guerreiro/berserker/grito_de_sangue.md)
  * **Baluarte:** [Muralha Intransponível](idea/04_skills/guerreiro/baluarte/muralha_intransponivel.md) | [Levantar Escudo](idea/04_skills/guerreiro/baluarte/levantar_escudo.md) | [Soco com Escudo](idea/04_skills/guerreiro/baluarte/soco_com_escudo.md)

### 🗡️ Ladino
* **Habilidades Base:**
  * [Ataque Furtivo](idea/04_skills/ladino/ataque_furtivo.md) | [Lançar Facas](idea/04_skills/ladino/lancar_facas.md) | [Reflexos Rápidos](idea/04_skills/ladino/reflexos_rapidos.md) | [Passo das Sombras](idea/04_skills/ladino/passo_das_sombras.md) | [Veneno Paralisante](idea/04_skills/ladino/veneno_paralisante.md) | [Cortina de Fumaça](idea/04_skills/ladino/cortina_de_fumaca.md)
* **Subclasses:**
  * **Sombra:** [Passo Furtivo](idea/04_skills/ladino/sombra/passo_furtivo.md) | [Facada nas Costas](idea/04_skills/ladino/sombra/facada_nas_costas.md) | [Manto de Sombras](idea/04_skills/ladino/sombra/manto_de_sombras.md)
  * **Bardo:** [Canção da Celeridade](idea/04_skills/ladino/bardo/cancao_da_celeridade.md) | [Dissonância](idea/04_skills/ladino/bardo/dissonancia.md) | [Acordes Curativos](idea/04_skills/ladino/bardo/acordes_curativos.md)
  * **Assassino:** [Veneno Letal](idea/04_skills/ladino/assassino/veneno_letal.md) | [Degolar](idea/04_skills/ladino/assassino/degolar.md) | [Lâminas Sangrentas](idea/04_skills/ladino/assassino/laminas_sangrentas.md)

### ✨ Mago
* **Habilidades Base:**
  * [Míssil Mágico](idea/04_skills/mago/missil_magico.md) | [Bola de Fogo](idea/04_skills/mago/bola_de_fogo.md) | [Nova de Gelo](idea/04_skills/mago/nova_de_gelo.md) | [Intelecto Arcano](idea/04_skills/mago/intelecto_arcano.md) | [Escudo de Mana](idea/04_skills/mago/escudo_de_mana.md) | [Chuva de Meteoros](idea/04_skills/mago/chuva_de_meteoros.md)
* **Subclasses:**
  * **Elementalista:** [Pilar de Fogo](idea/04_skills/mago/elementalista/pilar_de_fogo.md) | [Raio Congelante](idea/04_skills/mago/elementalista/raio_congelante.md) | [Tempestade de Raios](idea/04_skills/mago/elementalista/tempestade_de_raios.md)
  * **Rúnico:** [Selo Explosivo](idea/04_skills/mago/runico/selo_explosivo.md) | [Barreira de Proteção](idea/04_skills/mago/runico/barreira_de_protecao.md) | [Sobrecarga Arcana](idea/04_skills/mago/runico/sobrecarga_arcana.md)
  * **Ilusionista:** [Clone Espelhado](idea/04_skills/mago/ilusionista/clone_espelhado.md) | [Confusão Mental](idea/04_skills/mago/ilusionista/confusao_mental.md) | [Distração Ilusória](idea/04_skills/mago/ilusionista/distracao_ilusoria.md)

### ✝️ Sacerdote
* **Habilidades Base:**
  * [Cura Rápida](idea/04_skills/sacerdote/cura_rapida.md) | [Luz Punitiva](idea/04_skills/sacerdote/luz_punitiva.md) | [Proteção Divina](idea/04_skills/sacerdote/protecao_divina.md) | [Aura Sagrada](idea/04_skills/sacerdote/aura_sagrada.md) | [Purificar](idea/04_skills/sacerdote/purificar.md) | [Círculo de Cura](idea/04_skills/sacerdote/circulo_de_cura.md)
* **Subclasses:**
  * **Clérigo:** [Cura Maior](idea/04_skills/sacerdote/clerigo/cura_maior.md) | [Escudo de Fé](idea/04_skills/sacerdote/clerigo/escudo_de_fe.md) | [Ressurreição Menor](idea/04_skills/sacerdote/clerigo/ressurreicao_menor.md)
  * **Inquisidor:** [Punição Divina](idea/04_skills/sacerdote/inquisidor/punicao_divina.md) | [Chamas Purificadoras](idea/04_skills/sacerdote/inquisidor/chamas_purificadoras.md) | [Martelo da Justiça](idea/04_skills/sacerdote/inquisidor/martelo_da_justica.md)
  * **Oráculo:** [Aura de Premonição](idea/04_skills/sacerdote/oraculo/aura_de_premonicao.md) | [Selo do Destino](idea/04_skills/sacerdote/oraculo/selo_do_destino.md) | [Julgamento Adiado](idea/04_skills/sacerdote/oraculo/julgamento_adiado.md)

---

## 🖥️ 05. Telas & Interface (UI/UX)
* [Telas, Fluxo de Navegação & UI](idea/05_telas_ui_hud/telas_e_fluxo.md) *(Splash Screen, Tela de Título, Lobby, Gerenciamento de Time com Drag & Drop de skills, Inventário com descarte e Mapa de Estágios 1-10)*
* [HUD de Batalha & Masmorra](idea/05_telas_ui_hud/hud_de_batalha.md) *(Painéis dos 3 heróis com barras verticais de HP/MP, skills com CD, consumíveis clicáveis, contador de itens, cronômetro e texto de dano flutuante)*

---

## 🎒 06. Itens & Equipamentos
* **Armas & Escudos (Slot 1 & Slot 3):**
  * [Espadas & Lâminas](idea/06_itens/armas_espadas.md) *(20 espadas de 1H e 2H do Nv 1 ao 30 com crítico 1.5x)*
  * [Adagas & Dual Wield](idea/06_itens/armas_adagas.md) *(20 adagas de 1H e empunhadura dupla com crítico 2.0x)*
  * [Arcos & Bestas](idea/06_itens/armas_arcos.md) *(20 arcos e bestas 2H com alcance e crítico 1.75x)*
  * [Cajados & Cetros](idea/06_itens/armas_cajados.md) *(20 cajados 2H e cetros 1H com dano elemental e poder mágico)*
  * [Escudos & Bloqueio](idea/06_itens/armas_escudos.md) *(20 escudos Pequenos, Grandes e Falanges com bloqueio total de 15% a 65%)*
* **Armaduras de Corpo (Slot 2):**
  * [Armaduras Leves (Túnicas & Roupões)](idea/06_itens/armadura_tunica.md) *(20 armaduras leves com alta defesa mágica e mana)*
  * [Armaduras Médias (Couro & Placas)](idea/06_itens/armaduras_couro.md) *(20 armaduras médias com equilíbrio físico/mágico)*
  * [Armaduras Pesadas (Placas & Grevas)](idea/06_itens/armaduras_pesadas.md) *(20 armaduras pesadas com máxima defesa física e penalidade de velocidade)*
* **Acessórios & Consumíveis (Slot 3 & Slots de Consumíveis):**
  * [Acessórios Diversos](idea/06_itens/acessorios.md) *(20 anéis, amuletos, orbes, livros com double cast e grimórios com lifesteal)*
  * [Consumíveis & Bugigangas de Batalha](idea/06_itens/consumiveis_pocoes.md) *(40 consumíveis com gatilhos inatos, poções, bombas AoE, comidas e lendários de duplo efeito)*

---

## 🗺️ 07. Mundo, Cenários & Níveis
* [Nível de Testes Graybox & Blueprint](idea/07_Mundo_e_Narrativa/Cenarios_e_niveis/dungeon_graybox.md) *(Métricas 2D/3D Top-Down, 4 estágios de validação de mecânicas e blueprint modular para fases 1 a 10)*

---

## 👾 09. Bestiário & Inimigos
* [Goblins & Xamãs Tribais](idea/09_inimigos/comuns/goblins.md) *(6 subtipos comuns: Guerreiro, Arqueiro, Mago, Ladino, Suicida, Curandeiro + 3 Elites com auras de combate)*
