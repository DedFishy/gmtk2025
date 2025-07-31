extends Node2D

@onready
var area2d = $Area2D
var player
var level

func _ready() -> void:
	player = get_node("/root/Common/Player")
	level = get_node("/root/Common/level")

func _physics_process(delta: float) -> void:
	var player_in_trigger = player in area2d.get_overlapping_bodies()
	if player_in_trigger:
		var next_scene_name = get_meta("NextLevelScene")
		if next_scene_name:
			var scene = load("res://Levels/" + next_scene_name + ".tscn")
			for child in level.get_children():
				level.remove_child(child)
				child.queue_free()
			var scene_node = scene.instantiate()
			level.add_child(scene_node)
			player.position = scene_node.get_node("SpawnPoint").position
