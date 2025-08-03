extends Node2D
var current_level_node = Node2D.new()

func get_scene():
	if current_level_node != null:
		return current_level_node
	else:
		var node = Node2D.new()
		return node
