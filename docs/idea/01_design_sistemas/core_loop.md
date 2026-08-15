# Core Loop do Jogo (Ciclo Principal)

O ciclo de gameplay do jogo é dividido em 4 fases distintas. O jogador é inteiramente ativo na Fase 1 (Preparação) e atua como um "Espectador/Comandante" durante a Fase 2 e 3, culminando na Fase 4 (Recompensas).

## Fase 1: O Lobby (Saguão Principal & Serviços)
Este é o refúgio seguro do jogador e o centro de comando. Aqui ocorre toda a jogabilidade ativa:
* **Gerenciamento de Equipe:** Escolher os 3 heróis da equipe ativa a partir da coleção, combinando raças e classes de acordo com a sinergia tática desejada.
* **Equipamentos e Skills:** Equipar armas, armaduras e escudos/acessórios, definir os 2 consumíveis e selecionar 3 das 6 habilidades ativas da classe (ou 9 habilidades ao liberar a subclasse no Nível 15).
* **Ferreiro & Aprimoramento:** Gastar o Ouro obtido nas masmorras para melhorar o poder dos equipamentos e transferir atributos.
* **Mercador de Suprimentos:** Comprar consumíveis (poções, comidas e bombas) e equipamentos rotativos da loja.
* **Programação Tática & Formação:** Definir as prioridades de cura/suporte e a ordem de marcha da equipe (Frente, Meio, Trás).
* **Iniciar Missão:** Escolher qual masmorra/dungeon enfrentar.

## Fase 2: A Masmorra (Exploração Automática & Cadência)
Ao entrar na missão, o controle direto é removido:
* **Câmera e Movimento:** A câmera acompanha a equipe que se desloca automaticamente pelos corredores através de pathfinding autônomo.
* **Cadência de Encontros (3 a 5 Packs):** Ao longo do trajeto (Path 1), o time enfrenta em média **3 a 5 grupos de monstros** (ex: 2 packs normais → 1 pack com Mini-Chefe/Elite → 1 pack normal → Sala do Chefe Final), durando em torno de 4 a 5 minutos.
* **Combate Automático Coordenado:** O engajamento se inicia no primeiro golpe desferido por qualquer lado. Os heróis executam suas táticas pré-programadas de forma autônoma.
* **Regeneração de Recursos:** Entre os combates, enquanto a equipe caminha, a Mana se regenera gradualmente a uma taxa fixa contínua (5% a cada 2s).
* **Morte Parcial & Derrota Total (Wipe):**
  * *Morte Parcial:* Se um herói morrer em combate, ele permanece caído no chão até o fim da masmorra (a menos que seja revivido por habilidades de Sacerdote ou consumíveis especiais de ressurreição). Os sobreviventes continuam a travessia.
  * *Derrota Total (Wipe):* Se os 3 heróis caírem, a expedição falha imediatamente, resultando na perda total dos itens e do XP daquela masmorra e no retorno forçado ao Lobby.
* **Pausa e Abandono:** O jogador pode pausar o jogo a qualquer momento e optar por desistir da masmorra, o que também resulta na renúncia dos itens e do XP acumulado na tentativa.

## Fase 3: O Chefe da Masmorra (Boss Room & Extração)
O caminho da masmorra obrigatoriamente leva à sala fechada do Chefe:
* **Combate Árduo em Fases:** O boss testa a estratégia e a sobrevivência do time com ataques telegrafados, culminando em seu Golpe Supremo caso atinja 10% de HP.
* **Recompensa Física:** Ao vencer o chefe, o grupo anda automaticamente até o Baú do Tesouro Dourado no fundo da sala (garantindo ouro massivo e itens de alta raridade).
* **O Portal de Extração:** Após abrir o baú, o portal mágico se acende, permitindo que a equipe escape com segurança.

## Fase 4: O Resumo da Partida
Ao cruzar o portal, o jogo pausa e exibe uma tela de sumário detalhada antes de voltar ao Lobby:
* **Espólios (Loot Conquistado):** Lista de todos os itens e do ouro conquistados nos monstros e no baú do chefe salvos no inventário.
* **Experiência (XP Dividido):** O total de XP ganho é dividido igualmente entre os heróis que terminaram a masmorra vivos.
* **Mini-Ranking de Desempenho (MVP):** Destaque visual do herói MVP da partida com base na fórmula de pontuação de combate.
* **Estatísticas de Batalha (Metrics):**
  * *Dano Causado* e *DPS Médio*.
  * *Dano Recebido / Mitigado* (mostrando a eficiência dos tanques e escudos).
  * *Cura Realizada* (eficácia do suporte).
