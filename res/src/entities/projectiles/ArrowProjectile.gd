class_name ArrowProjectile
extends Node3D

## Projétil Físico de Flecha (M5.2)
## Desloca-se em velocidade constante (~14.0 m/s) com colisor Hitbox3D na camada Enemy_Hitboxes (layer 6 / bit 32),
## colidindo contra Hero_Hurtboxes (layer 5 / bit 16), com tempo de vida útil de 3s ou despawn ao impacto.

signal hit_target(target: Node3D)
signal lifetime_expired()

@export var speed: float = 14.0
@export var lifetime: float = 3.0
@export var damage: int = 7
@export var source_entity: Node3D = null
@export var hitbox: Hitbox3D = null

var direction: Vector3 = Vector3.FORWARD
var _elapsed_time: float = 0.0
var _has_hit: bool = false


func _ready() -> void:
	_resolve_hitbox()
	_update_hitbox_properties()


func _physics_process(delta: float) -> void:
	if _has_hit:
		return

	_elapsed_time += delta
	if _elapsed_time >= lifetime:
		lifetime_expired.emit()
		queue_free()
		return

	if direction.length_squared() > 0.0001:
		global_position += direction * speed * delta


func setup(dmg: int = 7, spd: float = 14.0, src: Node3D = null, life: float = 3.0) -> void:
	damage = dmg
	speed = spd
	source_entity = src
	lifetime = life
	_resolve_hitbox()
	_update_hitbox_properties()


func launch(dir: Vector3) -> void:
	if dir.length_squared() > 0.0001:
		direction = dir.normalized()
		_orient_to_direction(direction)


func _resolve_hitbox() -> void:
	if hitbox == null:
		hitbox = get_node_or_null("Hitbox3D") as Hitbox3D
	if hitbox != null:
		if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.connect(_on_hitbox_area_entered)
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)


func _update_hitbox_properties() -> void:
	if hitbox != null:
		hitbox.damage = damage
		hitbox.is_physical = true
		hitbox.source_entity = source_entity


func _on_hitbox_area_entered(area: Area3D) -> void:
	if _has_hit:
		return

	if area is Hurtbox3D:
		var hurtbox: Hurtbox3D = area as Hurtbox3D
		if hitbox != null and hitbox._is_same_entity(hurtbox):
			return
		_has_hit = true
		hit_target.emit(hurtbox)
		queue_free()


func _on_hitbox_body_entered(body: Node3D) -> void:
	if _has_hit:
		return
	if body == source_entity:
		return
	# Se colidir com o cenário / paredes (StaticBody3D)
	if body is StaticBody3D or (body is CharacterBody3D and body != source_entity):
		_has_hit = true
		hit_target.emit(body)
		queue_free()


func _orient_to_direction(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(dir.x, dir.z)
	rotation.y = target_yaw
	var pitch: float = -asin(clampf(dir.y, -1.0, 1.0))
	rotation.x = pitch
