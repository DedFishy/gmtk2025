extends CharacterBody2D

const crouch_power = 200
const jump_power = 500
const gravity = 1200

const jump_raycast_distance = 50;

const max_horizontal_velocity = 800;

const velocity_dampen = 1;

const max_grapple_distence = 500
const min_grapple_distence = 150
const maxSwingSpeed = 800
const angulerAccelleration = 3
var currentAngleSpeed = 0

var hookLength = 0
var lastSwingPose = Vector2()

func _input(event):
	if event.is_action_pressed("jump"):
		pass

func _physics_process(delta: float) -> void:
	var horizontal_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	var vertical_input = -Input.get_action_strength("crouch") * crouch_power
	var floor_normal = Vector2.UP
	if is_on_floor():
		floor_normal = get_floor_normal()
		var target_rotation = floor_normal.angle() + PI / 2
		rotation = lerp_angle(rotation, target_rotation, 5 * delta)

	var floor_tangent = Vector2(-floor_normal.y, floor_normal.x).normalized()
	
	velocity.y += gravity * delta
	velocity.y -= vertical_input * delta

	if Input.is_action_just_pressed("jump") and do_jump_raycast():
		velocity.y -= jump_power

	if horizontal_input != 0:
		var desired_velocity = floor_tangent * horizontal_input * max_horizontal_velocity
		print(desired_velocity)
		velocity.x = lerp(velocity.x, desired_velocity.x, .5 * delta)
		print(velocity.x)
	else:
		velocity.x *= velocity_dampen * delta
	
	
	if GrappleHookGen.hookExists():
		var endPoint = GrappleHookGen.getEndPointPose()
		var ropeLength = GrappleHookGen.ropeLength
		if hookLength == 0:
			hookLength = ropeLength
			currentAngleSpeed = velocity.length() / ropeLength
		var poseDelta = position - endPoint
		var dist = poseDelta.length()
		velocity = Vector2()
		if dist > ropeLength:
			var dir = poseDelta.normalized()
			position = endPoint + dir * ropeLength
		
		var angle = poseDelta.angle()
		var direction = Vector2(cos(angle), sin(angle)).normalized()
		print(can_swing_to(direction, 1))
		var gravityForce = -sin(angle - PI/2) * gravity / ropeLength / 1.5
		currentAngleSpeed = min(currentAngleSpeed + angulerAccelleration * delta, maxSwingSpeed / ropeLength)
		var delta_angle = 0.0
		var canSwing = can_swing_to(direction, 1)
		if canSwing:
			delta_angle = -horizontal_input * currentAngleSpeed * delta
		elif horizontal_input == 0:
			delta_angle += gravityForce * delta
		if canSwing:
			delta_angle += gravityForce * delta
		angle += delta_angle
		var new_offset = Vector2(cos(angle), sin(angle)) * ropeLength
		lastSwingPose = position
		position = endPoint + new_offset
	elif hookLength != 0:
		var translationalMag = hookLength * currentAngleSpeed
		currentAngleSpeed = 0
		var dir = (position - lastSwingPose).normalized()
		velocity = translationalMag * dir
		hookLength = 0
	move_and_slide()
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
		var landedPose = do_grapple_raycast()
		if(typeof(landedPose) == TYPE_VECTOR2):
			GrappleHookGen.generateHook(self, landedPose)
	elif Input.is_action_just_pressed("DeleteHook"):
		GrappleHookGen.deleteHook()

func do_grapple_raycast():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from = position
	var mousePose = get_global_mouse_position() 
	var delta = (mousePose - position).length()
	query.to = mousePose
	query.collide_with_areas = false
	var result = space_state.intersect_ray(query)
	if result:
		if delta < min_grapple_distence: 
			return null
		else: 
			return result.position
	else:
		return null

func can_swing_to(direction: Vector2, distance: float) -> bool:
	print("testing")
	var test_motion = direction.normalized() * distance
	var testSubject = CharacterBody2D.new()
	var collider = CollisionShape2D.new()
	var body = RectangleShape2D.new()
	body.size = Vector2(32, 32)
	collider.shape = body
	testSubject.add_child(collider)
	testSubject.position = position
	testSubject.velocity = test_motion
	var collision = move_and_collide(testSubject.velocity)
	testSubject.queue_free()
	return collision == null
