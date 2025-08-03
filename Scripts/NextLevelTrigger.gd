extends Node2D

@onready
var area2d = $Area2D
var player
var level
var camera
var background

func _ready() -> void:
	player = get_node("/root/Common/Player")
	level = get_node("/root/Common/level")
	camera = get_node("/root/Common/Camera2D")
	background = camera.get_child(0)
	

func _physics_process(delta: float) -> void:
	var player_in_trigger = player in area2d.get_overlapping_bodies()
	if player_in_trigger:
		var next_scene_name = get_meta("NextLevelScene")
		if next_scene_name:
			if next_scene_name == "end": 
				print("END")
				SaveDataManager.store_game(player.get_elapsed_time_msec(), player.deaths)
				get_tree().change_scene_to_file("res://end.tscn")
				return
			background.texture = load("res://Assets/Textures/Bg/" + next_scene_name + ".png")
			var scene = load("res://Levels/" + next_scene_name + ".tscn")
			for child in level.get_children():
				level.remove_child(child)
				child.queue_free()
			var scene_node = scene.instantiate()
			CurrentLevel.current_level_node = scene_node
			level.add_child(scene_node)
			player.position = scene_node.get_node("SpawnPoint").position
			player.refresh_spawn_point()
