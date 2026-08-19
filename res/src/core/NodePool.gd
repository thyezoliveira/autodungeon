class_name NodePool
extends Node

@export var prefab_scene: PackedScene = null
@export var initial_pool_size: int = 20
@export var max_pool_size: int = 50

var _available_nodes: Array[Node] = []
var _active_nodes: Array[Node] = []


func _ready() -> void:
	if prefab_scene != null and initial_pool_size > 0:
		_populate_pool(initial_pool_size)


func initialize(prefab: PackedScene, initial_size: int = 20, max_size: int = 50) -> void:
	clear_pool()
	prefab_scene = prefab
	initial_pool_size = initial_size
	max_pool_size = max_size
	if prefab_scene != null and initial_pool_size > 0:
		_populate_pool(initial_pool_size)


func acquire_node() -> Node:
	var node: Node = null

	if _available_nodes.size() > 0:
		node = _available_nodes.pop_back()
	elif get_total_count() < max_pool_size:
		node = _create_instance()
		if node == null:
			return null
	else:
		push_warning("NodePool: Maximum pool size (%d) reached. No nodes available." % max_pool_size)
		return null

	_active_nodes.append(node)
	_activate_node(node)
	return node


func release_node(node_instance: Node) -> void:
	if node_instance == null:
		push_warning("NodePool: Attempted to release a null node.")
		return

	var active_index: int = _active_nodes.find(node_instance)
	if active_index == -1:
		push_warning("NodePool: Attempted to release a node not found in the active pool.")
		return

	_active_nodes.remove_at(active_index)

	# If node was reparented during its active lifecycle, reparent back to this pool node
	if is_inside_tree() and is_instance_valid(node_instance) and node_instance.get_parent() != self:
		if node_instance.get_parent() != null:
			node_instance.get_parent().remove_child(node_instance)
		add_child(node_instance)

	_deactivate_node(node_instance)
	_available_nodes.append(node_instance)


func get_available_count() -> int:
	return _available_nodes.size()


func get_active_count() -> int:
	return _active_nodes.size()


func get_total_count() -> int:
	return _available_nodes.size() + _active_nodes.size()


func clear_pool() -> void:
	for node in _available_nodes:
		if is_instance_valid(node):
			node.queue_free()
	for node in _active_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_available_nodes.clear()
	_active_nodes.clear()


func _populate_pool(count: int) -> void:
	var to_create: int = mini(count, max_pool_size - get_total_count())
	for i in range(to_create):
		var node: Node = _create_instance()
		if node != null:
			_available_nodes.append(node)


func _create_instance() -> Node:
	if prefab_scene == null:
		push_error("NodePool: Cannot create instance, prefab_scene is null.")
		return null

	var node: Node = prefab_scene.instantiate()
	add_child(node)
	_set_node_inactive_state(node)
	return node


func _set_node_inactive_state(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	elif node is Node3D:
		(node as Node3D).visible = false


func _activate_node(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	if node is CanvasItem:
		(node as CanvasItem).visible = true
	elif node is Node3D:
		(node as Node3D).visible = true

	if node.has_method("on_pool_acquire"):
		node.call("on_pool_acquire")


func _deactivate_node(node: Node) -> void:
	_set_node_inactive_state(node)
	if node.has_method("on_pool_release"):
		node.call("on_pool_release")
