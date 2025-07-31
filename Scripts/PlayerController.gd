extends RigidBody2D

const crouch_power = 100
const jump_power = 500
const gravity = 1200

const jump_raycast_distance = 50;

const max_horizontal_velocity = 400;

const velocity_dampen = 0.8;

const max_grapple_distence = 100

func _input(event):
	if event.is_action_pressed("Jump"):
		pass
		

func _physics_process(delta: float) -> void:
	var horizontal_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	var vertical_input = -Input.get_action_strength("crouch") * crouch_power
	var floor_normal = 0
	
	var is_on_floor = do_jump_raycast()
	if is_on_floor:
		floor_normal = get_collision_tile_at_position(is_on_floor) * PI
		var target_rotation = floor_normal + PI / 2
		rotation = lerp_angle(rotation, target_rotation, 0.1)
		print(rad_to_deg(target_rotation))

	var floor_tangent = Vector2.RIGHT.rotated(floor_normal)
	
		
	linear_velocity.y += gravity * delta

	linear_velocity.y -= vertical_input * delta

	if Input.is_action_just_pressed("jump") and is_on_floor:
		linear_velocity.y -= jump_power

	if horizontal_input != 0:
		var desired_velocity = floor_tangent * horizontal_input * max_horizontal_velocity
		print(desired_velocity)
		linear_velocity.x = lerp(linear_velocity.x, desired_velocity.x, .5)
	else:
		linear_velocity.x *= velocity_dampen


	shoot_grapple()

func do_jump_raycast():
	var space_state = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var end_position = position
	end_position.y += $PlayerShape.shape.get_size().y
	var query = PhysicsRayQueryParameters2D.create(position, end_position)
	var query_result = space_state.intersect_ray(query);
	if query_result.is_empty(): return null
	return query_result.get(query_result.keys()[0])

func get_collision_tile_at_position(position: Vector2) -> float:
	var tile_layer = get_tree().get_current_scene().get_node("CollidingLayer")
	var tile_coord = tile_layer.local_to_map(tile_layer.to_local(position))
	var tile_slope_rad = tile_layer.get_cell_tile_data(tile_coord).get_custom_data("SlopeRadians")
	return tile_slope_rad

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
