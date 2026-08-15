# 📋 Índice Geral de Planejamento — Autodungeon (Godot 4.7+ 3D)

Este diretório contém o planejamento estratégico, metodológico e de engenharia de software para o desenvolvimento iterativo do **MVP de Autodungeon** em ambiente **3D na Godot Engine 4.7+**, estruturado em marcos com controle rigoroso de configurações, versões e mudanças via **GitHub**.

---

## 🗺️ Mapa de Navegação do Planejamento

```text
📁 docs/planejamento/
│
├── 📄 00_indice_planejamento.md              <- [Você está aqui] Visão Geral e Mapa
├── 📄 01_visao_mvp_e_marcos.md                <- Os 9 Marcos de Desenvolvimento (M0 a M8)
├── 📄 02_gestao_configuracao_e_github.md      <- Git Flow, Git LFS, Conventional Commits e Rollback
├── 📄 03_controle_mudancas_e_rastreabilidade.md <- Processo de Change Requests, Baseline e Changelog
└── 📄 04_cronograma_e_cadencia.md             <- Cronograma por Marcos, Dependências e DoD
```

---

## 🧭 Resumo dos Módulos de Planejamento

| Documento | Foco Principal | Principais Diretrizes |
| :--- | :--- | :--- |
| **[01. Visão do MVP & Marcos](01_visao_mvp_e_marcos.md)** | Definição dos 9 Marcos estratégicos do MVP 3D. | *M0 a M8, entregáveis funcionais, escopo 3D e critérios de aceitação sem divisão de tarefas.* |
| **[02. Gestão de Configuração & GitHub](02_gestao_configuracao_e_github.md)** | Controle de versão, integridade de assets e rollback. | *Trunk-Based / Feature Branches, Git LFS (.glb/.png/.ogg), Conventional Commits, Tags e Revert.* |
| **[03. Controle de Mudanças & Rastreabilidade](03_controle_mudancas_e_rastreabilidade.md)** | Governança de escopo e histórico de evolução. | *Change Request Workflow, SemVer 2.0, CHANGELOG.md e Matriz GDD $\rightarrow$ Arquitetura $\rightarrow$ Marco.* |
| **[04. Cronograma & Cadência](04_cronograma_e_cadencia.md)** | Cronograma iterativo e matriz de dependências. | *Sequenciamento lógico, checkpoints de validação e Definition of Done (DoD).* |

---

## 🔄 Fluxo de Desenvolvimento Iterativo do MVP

```mermaid
graph TD
    M0[M0: Setup Repositório & Baseline 3D] --> M1[M1: Infraestrutura Core & EventBus]
    M1 --> M2[M2: Entidade 3D & Composição]
    M2 --> M3[M3: Navegação 3D & Tethering Trio]
    M3 --> M4[M4: Combate 3D & IA dos Heróis]
    M4 --> M5[M5: Masmorra Graybox 3D & Mobs]
    M5 --> M6[M6: Chefe Rei Goblin & 3 Paths]
    M6 --> M7[M7: HUD 3D/2D & Fluxo de Telas]
    M7 --> M8[M8: Integração, Polimento & Release MVP]

    subgraph Governance [Governança & Qualidade Contínua]
        Git[Controle de Versão GitHub & Git LFS]
        ChangeCtrl[Controle de Mudanças & Baseline]
        Rollback[Estratégia Atômica de Rollback]
    end

    M0 -.-> Governance
    M4 -.-> Governance
    M8 -.-> Governance
```

---

## 🔗 Referências Cruzadas
* [Documento de Escopo & Pitch do MVP](../../01_Pitch_MVP.md)
* [Índice Geral da Arquitetura Técnica](../projeto/00_indice_arquitetura.md)
* [Índice Geral do Game Design (GDD)](../00_indice.md)
