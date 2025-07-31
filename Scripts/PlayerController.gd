extends RigidBody2D

const movement_speed = 50
const crouch_power = 100
const jump_power = 500

const jump_raycast_distance = 50;

const max_horizontal_velocity = 400;

const velocity_dampen = 0.8;

const max_grapple_distence = 100

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
	if (horizontal_input > 0 and (linear_velocity.x < max_horizontal_velocity)) or (horizontal_input < 0 and (linear_velocity.x > -max_horizontal_velocity)):
		linear_velocity.x += horizontal_input
	elif (horizontal_input == 0):
		linear_velocity.x *= velocity_dampen;
	linear_velocity.y -= vertical_input

	shoot_grapple()

func do_jump_raycast() -> bool:
	var space_state = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var end_position = position
	end_position.y += $PlayerShape.shape.get_size().y
	var query = PhysicsRayQueryParameters2D.create(position, end_position)
	return !space_state.intersect_ray(query).is_empty()

func shoot_grapple():
	# Add manual hook delete button or maybe a time out, probably just make the last one clear when new one maid, or maybe even spawn allow for more then one hook
	if Input.is_action_just_pressed("ShootHook") and not GrappleHookGen.hookExists():
		var direction = get_global_mouse_position().normalized()
		var landedPose = do_grapple_raycast(direction)
		if landedPose.length() >= max_grapple_distence:
			return
		GrappleHookGen.generateHook(self, landedPose)
	elif Input.is_action_just_pressed("DeleteHook"):
		GrappleHookGen.deleteHook()


func do_grapple_raycast(direction) -> Vector2:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.create(position, position + direction * max_grapple_distence)
	query.collide_with_areas = false
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	else:
		return position + direction * max_grapple_distence
