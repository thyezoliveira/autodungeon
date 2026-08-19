class_name CharacterEntity
extends CharacterBody3D

@export var hero_data: HeroData = null
@export var enemy_data: EnemyData = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) as float

@onready var visuals: Node3D = get_node_or_null("Visuals") as Node3D
@onready var body_collider: CollisionShape3D = get_node_or_null("BodyCollider") as CollisionShape3D
@onready var components: Node3D = get_node_or_null("Components") as Node3D
@onready var state_machine: Node = get_node_or_null("StateMachine")


func _ready() -> void:
	setup_entity_data()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()


func setup_entity_data() -> void:
	if hero_data != null:
		pass
	elif enemy_data != null:
		pass
