class_name EventBusSingleton
extends Node

# --- Sinais de Combate e Entidade ---
signal entity_spawned(entity: Node3D)
signal entity_died(entity: Node3D, killer: Node3D)
signal damage_dealt(target: Node3D, source: Node3D, amount: int, is_critical: bool, is_blocked: bool)
signal healing_applied(target: Node3D, healer: Node3D, amount: int)
signal mana_changed(entity: Node3D, current_mana: float, max_mana: float)
signal health_changed(entity: Node3D, current_hp: int, max_hp: int)
signal skill_cast_started(caster: Node3D, skill_data: Resource)
signal skill_cooldown_updated(caster: Node3D, skill_id: String, remaining_ratio: float)

# --- Sinais de Masmorra & Navegação ---
signal combat_triggered(initiator: Node3D, target: Node3D)
signal room_entered(room_index: int, room_name: String)
signal room_cleared(room_index: int)
signal dungeon_path_changed(new_path_state: int)
signal boss_telegraph_started(position: Vector3, radius: float, duration: float)

# --- Sinais de Itens & UI ---
signal potion_consumed(hero: Node3D, potion_data: Resource)
signal loot_collected(item_data: Resource, quantity: int)
signal match_ended(victory: bool, summary_data: Dictionary)
