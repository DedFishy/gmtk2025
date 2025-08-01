extends HSlider

func _value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(new_value))
