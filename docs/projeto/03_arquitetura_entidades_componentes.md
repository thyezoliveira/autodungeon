# 🧩 03. Arquitetura de Entidades & Componentes

Este documento define a arquitetura orientada a componentes baseada em nós (**Node-Based Component Pattern**) para todas as criaturas e personagens (Heróis, Monstros Comuns, Elites e Chefes) em **Autodungeon**.

---

## 🌳 1. A Cena Base `CharacterEntity`

Na Godot Engine 4, em vez de herança múltipla, estruturamos uma cena raiz `CharacterEntity.tscn` derivada de `CharacterBody2D`, composta por nós especializados:

```text
CharacterEntity (CharacterBody2D)
├── CollisionShape2D               <- Colisão física com o mundo e outras entidades
├── VisualRoot (Node2D)            <- Agrupador visual para rotação/espelhamento
│   ├── Sprite (AnimatedSprite2D)  <- Animações (Idle, Walk, Attack, Cast, Hurt, Die)
│   ├── AnimationPlayer            <- Controle de timelines e gatilhos de ataque
│   └── Shadow (Sprite2D)          <- Sombra projetada no chão
├── NavigationAgent2D              <- Agente de pathfinding conectado ao NavigationServer2D
├── StatsComponent (Node)          <- Gestor de atributos, bônus e modificadores
├── HealthComponent (Node)         <- Gestor de vida, mana, escudos e regeneração contínua
├── MovementComponent (Node)       <- Controle de velocidade, steering e navegação
├── HitboxComponent (Area2D)       <- Emissor de dano/ataque físico e projéteis
├── HurtboxComponent (Area2D)      <- Receptor de dano, bloqueio e esquiva
├── SkillHolderComponent (Node)    <- Gestor dos 3 slots de habilidades e cooldowns
├── EquipmentComponent (Node)      <- Gestor dos 3 slots de itens e 2 consumíveis
├── AIControllerComponent (Node)   <- Cérebro autônomo e avaliador de alvos
└── StateMachine (Node)            <- Máquina de estados (Idle, March, Combat, Dead)
```

---

## 💻 2. Especificação e Código dos Componentes

### 2.1. `CharacterEntity.gd` (Nó Raiz)
Atua como o orquestrador central, conectando os nós filhos e expondo métodos de alto nível:

```gdscript
class_name CharacterEntity
extends CharacterBody2D

# Identificação e Facção
enum Faction { PLAYER_HERO, ENEMY_MOB, ENEMY_BOSS, NEUTRAL }
@export var faction: Faction = Faction.PLAYER_HERO
@export var entity_name: String = "Hero"

# Referências aos Componentes Filhos
@onready var stats: StatsComponent = $StatsComponent
@onready var health: HealthComponent = $HealthComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var skills: SkillHolderComponent = $SkillHolderComponent
@onready var equipment: EquipmentComponent = $EquipmentComponent
@onready var ai: AIControllerComponent = $AIControllerComponent
@onready var fsm: StateMachine = $StateMachine
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_player: AnimationPlayer = $VisualRoot/AnimationPlayer

func _ready() -> void:
    # Injeção de dependência e inicialização encadeada
    stats.setup()
    health.setup(stats)
    movement.setup(self, nav_agent, stats)
    hurtbox.setup(health, stats)
    skills.setup(self, stats, health)
    equipment.setup(stats)
    ai.setup(self, skills, movement, stats)
    fsm.setup(self)

    # Conexão de sinais vitais
    health.died.connect(_on_died)

func _on_died() -> void:
    fsm.change_state("Dead")
    set_physics_process(false)
    collision_layer = 0
    collision_mask = 0
```

---

### 2.2. `StatsComponent.gd` (Gestão de Atributos)
Armazena e calcula atributos base, modificadores percentuais e planos:

```gdscript
class_name StatsComponent
extends Node

signal stat_modified(stat_name: String, new_value: float)

@export var base_data: HeroData # ou EnemyData (Resource)

# Dicionários de atributos
var _base_stats: Dictionary = {}
var _modifiers_flat: Dictionary = {}
var _modifiers_percent: Dictionary = {}

func setup() -> void:
    if base_data:
        _base_stats = base_data.get_initial_stats()

func get_stat(stat_name: String) -> float:
    var base: float = _base_stats.get(stat_name, 0.0)
    var flat: float = _modifiers_flat.get(stat_name, 0.0)
    var pct: float = _modifiers_percent.get(stat_name, 0.0)
    return (base + flat) * (1.0 + pct)

func add_flat_modifier(stat_name: String, amount: float) -> void:
    _modifiers_flat[stat_name] = _modifiers_flat.get(stat_name, 0.0) + amount
    stat_modified.emit(stat_name, get_stat(stat_name))

func add_percent_modifier(stat_name: String, percent: float) -> void:
    _modifiers_percent[stat_name] = _modifiers_percent.get(stat_name, 0.0) + percent
    stat_modified.emit(stat_name, get_stat(stat_name))
```

---

### 2.3. `HealthComponent.gd` (Vida, Mana e Regeneração Contínua)
Gerencia pontos de vida, recursos de mana, escudos absorventes e a regra de **regeneração contínua de mana fora de combate** (5% a cada 2s):

```gdscript
class_name HealthComponent
extends Node

signal health_changed(current: int, max_val: int)
signal mana_changed(current: int, max_val: int)
signal died()

var max_hp: int = 100
var current_hp: int = 100
var max_mana: int = 100
var current_mana: int = 100
var shield: int = 0
var is_in_combat: bool = false

var _mana_regen_timer: float = 0.0
const MANA_REGEN_INTERVAL: float = 2.0
const MANA_REGEN_PERCENT: float = 0.05

func setup(stats: StatsComponent) -> void:
    max_hp = int(stats.get_stat("max_hp"))
    current_hp = max_hp
    max_mana = int(stats.get_stat("max_mana"))
    current_mana = max_mana

func _physics_process(delta: float) -> void:
    # Regeneração contínua de mana fora de combate (Pathfinding e Marcha)
    if not is_in_combat and current_hp > 0 and current_mana < max_mana:
        _mana_regen_timer += delta
        if _mana_regen_timer >= MANA_REGEN_INTERVAL:
            _mana_regen_timer = 0.0
            var regen_amount: int = int(round(float(max_mana) * MANA_REGEN_PERCENT))
            restore_mana(regen_amount)

func apply_damage(raw_amount: int) -> int:
    if current_hp <= 0:
        return 0
    
    var remaining: int = raw_amount
    if shield > 0:
        if shield >= remaining:
            shield -= remaining
            remaining = 0
        else:
            remaining -= shield
            shield = 0
            
    current_hp = maxi(0, current_hp - remaining)
    health_changed.emit(current_hp, max_hp)
    
    if current_hp == 0:
        died.emit()
    return remaining

func heal(amount: int) -> void:
    if current_hp <= 0:
        return
    current_hp = mini(max_hp, current_hp + amount)
    health_changed.emit(current_hp, max_hp)

func consume_mana(amount: int) -> bool:
    if current_mana >= amount:
        current_mana -= amount
        mana_changed.emit(current_mana, max_mana)
        return true
    return false

func restore_mana(amount: int) -> void:
    current_mana = mini(max_mana, current_mana + amount)
    mana_changed.emit(current_mana, max_mana)
```

---

### 2.4. `HurtboxComponent.gd` & `HitboxComponent.gd` (Combate Espacial)
Responsáveis pela detecção de áreas físicas, cálculo de esquiva e mitigação de dano:

```gdscript
# HurtboxComponent.gd
class_name HurtboxComponent
extends Area2D

signal damage_received(amount: int, is_crit: bool, is_blocked: bool, is_dodged: bool)

var _health: HealthComponent
var _stats: StatsComponent

func setup(health: HealthComponent, stats: StatsComponent) -> void:
    _health = health
    _stats = stats

func receive_hit(hit_data: HitData) -> void:
    if _health.current_hp <= 0:
        return

    # 1. Checagem de Esquiva
    var dodge_chance: float = _stats.get_stat("dodge_chance")
    if randf() < dodge_chance:
        damage_received.emit(0, false, false, true) # Dodged
        EventBus.entity_dodged.emit(owner)
        return

    # 2. Checagem de Bloqueio de Escudo (Apenas Físico)
    if hit_data.damage_type == HitData.DamageType.PHYSICAL:
        var block_chance: float = _stats.get_stat("block_chance")
        if randf() < block_chance:
            damage_received.emit(0, false, true, false) # Blocked (0 Dano)
            EventBus.entity_blocked.emit(owner)
            return

    # 3. Mitigação Linear (Cap de 80)
    var defense: float = _stats.get_stat("armor") if hit_data.damage_type == HitData.DamageType.PHYSICAL else _stats.get_stat("magic_resist")
    var capped_def: float = minf(defense, 80.0)
    var mitigation: float = 1.0 - (capped_def / 100.0)
    var final_damage: int = maxi(1, int(round(float(hit_data.amount) * mitigation)))

    var applied: int = _health.apply_damage(final_damage)
    damage_received.emit(applied, hit_data.is_crit, false, false)
    EventBus.entity_damaged.emit(owner, applied, hit_data.damage_type, hit_data.is_crit)
```

---

## 📡 3. Protocolo de Comunicação e Injeção de Dependências

Para evitar acoplamento rígido, a comunicação segue estritamente o fluxo:

```mermaid
graph TD
    subgraph Entity_Root [CharacterEntity]
        Setup[func _ready() -> chama .setup() nos nós filhos]
    end

    subgraph Internal_Signals [Comunicação Interna - Sinais Locais]
        Hurtbox[HurtboxComponent] -->|damage_received| RootAnim[Tocar Animação Hurt]
        Health[HealthComponent] -->|died| StateDead[FSM: Mudar p/ Estado Dead]
        Stats[StatsComponent] -->|stat_modified| Health[Recalcular Max HP]
    end

    subgraph External_Signals [Comunicação Externa - EventBus Global]
        Health -->|died| EventBusDead[EventBus.entity_died]
        Hurtbox -->|damage_received| EventBusDmg[EventBus.entity_damaged]
        EventBusDmg --> FloatingText[Object Pooler de Dano Flutuante]
        EventBusDmg --> HUD[Battle HUD: Atualizar Barras]
    end
```

---

## 🔗 Próximos Passos
* Continue para: **[04. Máquinas de Estados & IA](04_maquina_estados_e_ia.md)**
* Voltar ao: **[Índice Geral](00_indice_arquitetura.md)**
