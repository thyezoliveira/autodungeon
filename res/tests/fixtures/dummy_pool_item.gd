class_name DummyPoolItem
extends Node3D

var acquire_count: int = 0
var release_count: int = 0


func on_pool_acquire() -> void:
	acquire_count += 1


func on_pool_release() -> void:
	release_count += 1
