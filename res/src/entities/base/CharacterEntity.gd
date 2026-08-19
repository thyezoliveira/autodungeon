class_name CharacterEntity
extends CharacterBody3D

@export var hero_data: HeroData = null
@export var enemy_data: EnemyData = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) as float

@onready var body_collider: CollisionShape3D = get_node_or_null("BodyCollider") as CollisionShape3D
@onready var visuals: Node3D = get_node_or_null("Visuals") as Node3D
@onready var components: Node3D = get_node_or_null("Components") as Node3D
@onready var stats_component: StatsComponent = get_node_or_null("Components/StatsComponent") as StatsComponent
@onready var health_component: HealthComponent = get_node_or_null("Components/HealthComponent") as HealthComponent
@onready var hurtbox: Hurtbox3D = get_node_or_null("Components/Hurtbox3D") as Hurtbox3D
@onready var navigation_agent: NavigationAgent3D = get_node_or_null("Components/NavigationAgent3D") as NavigationAgent3D
@onready var movement_component: MovementComponent = get_node_or_null("Components/MovementComponent") as MovementComponent
@onready var state_machine: StateMachine = get_node_or_null("StateMachine") as StateMachine


func _ready() -> void:
	setup_entity_data()
	_connect_signals()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()


func setup_entity_data() -> void:
	if stats_component == null:
		stats_component = get_node_or_null("Components/StatsComponent") as StatsComponent
	if health_component == null:
		health_component = get_node_or_null("Components/HealthComponent") as HealthComponent
	if hurtbox == null:
		hurtbox = get_node_or_null("Components/Hurtbox3D") as Hurtbox3D
	if navigation_agent == null:
		navigation_agent = get_node_or_null("Components/NavigationAgent3D") as NavigationAgent3D
	if movement_component == null:
		movement_component = get_node_or_null("Components/MovementComponent") as MovementComponent
	if state_machine == null:
		state_machine = get_node_or_null("StateMachine") as StateMachine

	if hero_data != null:
		if stats_component != null:
			stats_component.initialize_from_hero_data(hero_data)
		if health_component != null and stats_component != null:
			health_component.setup(stats_component)
	elif enemy_data != null:
		if stats_component != null:
			stats_component.initialize_from_enemy_data(enemy_data)
		if health_component != null and stats_component != null:
			health_component.setup(stats_component)
	else:
		if health_component != null and stats_component != null:
			health_component.setup(stats_component)

	if hurtbox != null and health_component != null:
		hurtbox.setup(health_component, stats_component, self)


func _connect_signals() -> void:
	if health_component != null and not health_component.died.is_connected(_on_health_died):
		health_component.died.connect(_on_health_died)


func _on_health_died(_killer: Node3D = null) -> void:
	if state_machine != null:
		if state_machine.has_state("DeadState"):
			state_machine.change_state("DeadState")
		elif state_machine.has_state("Dead"):
			state_machine.change_state("Dead")
