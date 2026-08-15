# Método de Organização: GDD Modular 2.0

A transição de um GDD 1.0 (geralmente um documento monolítico e contínuo) para um GDD 2.0 focado em um Produto Mínimo Viável (MVP) exige uma arquitetura **modular**. O objetivo deste método é usar arquivos Markdown (.md) distribuídos em uma hierarquia de pastas lógica. Isso facilita a manutenção, a busca por informações, o versionamento (Git) e a colaboração.

## 1. Princípios do Método

1. **Modularidade:** Cada sistema, personagem ou conceito complexo ganha seu próprio arquivo.
2. **Interconectividade:** Use links relativos do Markdown para conectar os arquivos (ex: "Veja os detalhes de cálculo em `[Cálculos de Dano](idea/01_design_sistemas/calculos_gerais.md)`").
3. **Escalabilidade:** A estrutura deve suportar a adição de novos conteúdos sem desorganizar o que já existe.
4. **Padronização:** Use templates consistentes para tipos de documentos semelhantes (ex: todo personagem tem o mesmo cabeçalho de atributos).

---

## 2. Estrutura de Diretórios Recomendada

Abaixo está a proposta de hierarquia de pastas. Crie este esqueleto na raiz do seu projeto ou em uma pasta dedicada chamada `docs` ou `gdd`.

```text
📁 GDD_2.0/
│
├── 📄 00_GDD_Master.md            <- O ponto de entrada. Resumo executivo, visão do jogo, pilares e links para tudo.
├── 📄 01_Pitch_e_MVP.md           <- Definição estrita do que entra no MVP (escopo) vs o que fica para depois.
│
├── 📁 1_Design_de_Sistemas/       <- Mecânicas e regras do jogo.
│   ├── 📄 core_loop.md            <- O ciclo principal do jogo.
│   ├── 📄 mecanicas_movimento.md
│   ├── 📄 mecanicas_combate.md
│   └── 📄 calculos_e_efeitos.md   <- Fórmulas matemáticas, status de efeitos (poison, stun, etc).
│
├── 📁 2_Personagens_e_Classes/    <- Tudo que envolve as entidades controláveis.
│   ├── 📄 visao_geral_classes.md
│   ├── 📁 Classes/
│   │   ├── 📄 guerreiro.md
│   │   └── 📄 mago.md
│   └── 📁 Personagens_Unicos/     <- Se houver personagens com lore específica.
│       └── 📄 protagonista.md
│
├── 📁 3_Habilidades_e_Skills/     <- Árvores de habilidades, magias e ações.
│   ├── 📄 lista_magias_fogo.md
│   └── 📄 arvore_habilidades_passivas.md
│
├── 📁 4_Equipamentos_e_Itens/     <- Economia e loot do jogo.
│   ├── 📄 armas_melee.md
│   ├── 📄 armaduras.md
│   └── 📄 consumiveis.md
│
├── 📁 5_Mundo_e_Narrativa/        <- A "Bíblia" do universo do jogo.
│   ├── 📄 lore_principal.md       <- História do mundo, facções.
│   ├── 📄 plot_MVP.md             <- A história contida apenas na versão MVP.
│   └── 📁 Cenarios_e_Levels/
│       ├── 📄 floresta_sombria.md <- Descrição de bioma, inimigos que aparecem, props.
│       └── 📄 dungeon_tutorial.md <- Level design focado no MVP.
│
├── 📁 6_Inimigos_e_NPCs/          <- Ameaças e interações.
│   ├── 📄 bestiario_mvp.md
│   └── 📄 npcs_mercadores.md
│
├── 📁 7_UI_e_Menus/               <- Interface e Experiência do Usuário (HUD).
│   ├── 📄 fluxo_de_telas.md       <- Como o jogador navega do Menu Principal até o jogo.
│   ├── 📄 hud_gameplay.md         <- O que fica na tela (vida, mana, minimapa).
│   └── 📄 inventario_ui.md        <- Layout e funcionamento do inventário.
│
└── 📁 8_Audio_e_Atmosfera/        <- Direção de arte sonora e visual.
    ├── 📄 trilha_sonora.md        <- Referências de músicas para cada cenário.
    └── 📄 efeitos_sonoros_sfx.md  <- Lista de sons necessários (passos, espadadas, UI clicks).
```

---

## 3. Padrões de Arquivos (Templates)

Para não se perder, todo arquivo deve seguir um esqueleto padrão de acordo com a sua categoria.

### Exemplo de Template para `[Classe].md`
```markdown
# Classe: [Nome da Classe]

## 1. Visão Geral
* **Descrição Curta:** (Ex: Tank focado em dano físico e controle de grupo).
* **Papel no MVP:** Qual a importância desta classe no escopo inicial?

## 2. Atributos Base
* HP Inicial: X
* Velocidade: Y

## 3. Lista de Skills
| Nome da Skill | Tipo | Custo | Dano Base | Descrição |
|---------------|------|-------|-----------|-----------|
| Investida     | Ativa| 10 SP | 25 Físico | Avança 3 tiles e causa stun. |

## 4. Notas de Balanceamento (Cálculos)
* *Referência:* [Veja as fórmulas de dano físico](idea/01_design_sistemas/calculos_gerais.md)
```

### Exemplo de Template para `[Mecânica].md`
```markdown
# Mecânica: [Nome da Mecânica]

## 1. Descrição
Como a mecânica funciona do ponto de vista do jogador.

## 2. Regras e Lógica
Condições para a mecânica acontecer (Ex: Para realizar um bloqueio, o jogador deve ter stamina > 0).

## 3. Interação com outros sistemas
Como isso afeta os [Cálculos de Dano](idea/01_design_sistemas/calculos_gerais.md) ou a [HUD de Gameplay](idea/05_telas_ui_hud/hud_de_batalha.md).
```

---

## 4. Melhores Práticas para o Método Modular

1. **O Documento Mestre (`00_GDD_Master.md`):** Ele nunca deve conter as regras em si, mas sim ser um grande **Índice Interativo**. Se você quiser saber sobre o combate, o Master deve ter um link direcionando para a pasta de sistemas.
2. **Corte do MVP:** Tenha marcadores ou tags visuais (ex: `[MVP]` ou `[PÓS-MVP]`) nos títulos ou tópicos dentro dos arquivos. Se você pensar em uma skill incrível, mas que é complexa demais para agora, anote-a, mas marque como `[PÓS-MVP]`.
3. **Tags e Referências Cruzadas:** Como você dividirá tudo, é essencial lincar os arquivos. No Obsidian ou no VS Code (usando extensões de Markdown), os links facilitam navegar como se fosse uma Wiki local.
4. **Glossário Centralizado:** Se o seu jogo cria termos novos (ex: "Aura de Ether"), crie um arquivo `glossario.md` na raiz e linque essas palavras para lá.

## 5. Próximos Passos (Como começar hoje)

1. Crie a estrutura de pastas sugerida acima.
2. Escreva o `00_GDD_Master.md` importando o resumo do seu GDD 1.0.
3. Defina o escopo estrito no arquivo `01_Pitch_e_MVP.md` (o que é o mínimo para o jogo ser divertido?).
4. Comece a "quebrar" seu GDD 1.0, movendo o conteúdo de combate para `mecanicas_combate.md`, as classes para a pasta de `Classes`, e assim por diante.
