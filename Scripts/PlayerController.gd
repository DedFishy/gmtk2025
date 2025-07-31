extends RigidBody2D

const movement_speed = 50
const crouch_power = 100
const jump_power = 500

const jump_raycast_distance = 50;

const max_horizontal_velocity = 400;

const velocity_dampen = 0.8;

func _input(event):
	if event.is_action_pressed("Jump"):
		pass
		
func _physics_process(delta: float) -> void:
	var horizontal_input = (Input.get_action_strength("right") - Input.get_action_strength("left")) * movement_speed
	var vertical_input = -Input.get_action_strength("crouch") * crouch_power
	if Input.is_action_just_pressed("jump"):
		if do_jump_raycast():
			print("Jump")
			vertical_input += Input.get_action_strength("jump") * jump_power
	print(horizontal_input)
	if (horizontal_input > 0 and (linear_velocity.x < max_horizontal_velocity)) or (horizontal_input < 0 and (linear_velocity.x > -max_horizontal_velocity)):
		linear_velocity.x += horizontal_input
	elif (horizontal_input == 0):
		linear_velocity.x *= velocity_dampen;
	linear_velocity.y -= vertical_input

func do_jump_raycast() -> bool:
	var space_state = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var end_position = position
	end_position.y += $PlayerShape.shape.get_size().y
	var query = PhysicsRayQueryParameters2D.create(position, end_position)
	return !space_state.intersect_ray(query).is_empty()

func shoot_grapple():
	pass
	#generateHook(self, position, segmentsPerUnit)
