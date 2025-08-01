extends Label

var min_font_size = 64
var max_font_size = 225
var target_font_size = min_font_size
var time_between_resizes = 1
var current_time = 0

func _process(delta: float) -> void:
	if label_settings == null:
		label_settings = LabelSettings.new()

	var container_width = get_parent().size.x
	var container_height = get_parent().size.y
	
	var font_size = clamp(pow((container_width * container_height), 1.0/3.0), min_font_size, max_font_size)
	print(font_size)
	if(font_size != target_font_size and time_between_resizes < current_time):
		label_settings.font_size = target_font_size
		current_time = 0
	else: 
		current_time += delta
