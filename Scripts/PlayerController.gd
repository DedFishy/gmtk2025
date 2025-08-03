extends CharacterBody2D

const crouch_power = 200
const jump_power = 500
const gravity = 1200

const jump_raycast_distance = 50;

const max_horizontal_velocity = 800;

const velocity_dampen = 5;

const max_grapple_distence = 300
const min_grapple_distence = 100
const maxSwingSpeed = 800
const angulerAccelleration = 3
var currentAngleSpeed = 0

var hookLength = 0
var lastSwingPose = Vector2()
var reload_scene = false
var reload_scene_time = .1
var current_reload_scene_time = 0

var walk = Array()
var grappleSFX
var grappleFailSFX
var deathSFX
@onready
var sprite = $PlayerSprite
var airSFX
var airSFXPosition = 0
var camera
var scene_node

var current_level_backup = null

var current_spawn_point = Vector2(0, 0);

func _ready() -> void:
	refresh_spawn_point()
	
	walk.append($Walk1)
	walk.append($Walk2)
	walk.append($Walk3)
	airSFX = $Air
	grappleSFX = $GrappleSFX
	grappleFailSFX = $GrappleFailSFX
	deathSFX = $DeathSFX
	camera = get_node("/root/Common/Camera2D")

func refresh_spawn_point():
	current_spawn_point = global_position

func _input(event):
	if event.is_action_pressed("jump"):
		pass

func _physics_process(delta: float) -> void:
	check_collisions()
	var horizontal_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	var vertical_input = -Input.get_action_strength("crouch") * crouch_power
	var floor_normal = Vector2.UP
	if is_on_floor():
		floor_normal = get_floor_normal()
		var target_rotation = floor_normal.angle() + PI / 2
		rotation = lerp_angle(rotation, target_rotation, 10 * delta)

	var floor_tangent = Vector2(-floor_normal.y, floor_normal.x).normalized()
	
	velocity.y += gravity * delta
	velocity.y -= vertical_input * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y -= jump_power

	if horizontal_input != 0:
		var desired_velocity = floor_tangent * horizontal_input * max_horizontal_velocity
		velocity.x = lerp(velocity.x, desired_velocity.x, 2 * delta)
	else:
		velocity.x *= velocity_dampen * delta
	
	if(horizontal_input != 0 and is_on_floor()):
		if(not (walk[0].playing or walk[1].playing or walk[2].playing)):
			walk[randi_range(0, 2)].play()
	else:
		walk[0].stop()
		walk[1].stop()
		walk[2].stop()

	if not is_on_floor():
		if !airSFX.playing:
			print(airSFXPosition)
			airSFX.play(airSFXPosition)
	else:
		if airSFX.playing:
			airSFXPosition = airSFX.get_playback_position()
			airSFX.stop()
			print(airSFXPosition)
	
	if GrappleHookGen.hookExists():
		var endPoint = GrappleHookGen.getEndPointPose()
		var ropeLength = GrappleHookGen.ropeLength
		if hookLength == 0:
			hookLength = ropeLength
			currentAngleSpeed = velocity.length() / ropeLength
		var poseDelta = position - endPoint
		var dist = poseDelta.length()
		if dist > ropeLength:
			var dir = poseDelta.normalized()
			position = endPoint + dir * ropeLength
		
		var angle = poseDelta.angle()
		var gravityForce = -sin(angle - PI/2) * gravity / ropeLength / 1.5
		currentAngleSpeed = min(currentAngleSpeed + angulerAccelleration * delta, maxSwingSpeed / ropeLength)
		var delta_angle = 0.0
		var canSwing = not is_on_wall() and not is_on_floor() and not is_on_ceiling()
		if canSwing:
			delta_angle = -horizontal_input * currentAngleSpeed * delta
		elif horizontal_input == 0:
			delta_angle += gravityForce * delta
		if canSwing:
			delta_angle += gravityForce * delta
		if not is_on_floor():
			velocity = Vector2()
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
	
	if GrappleHookGen.hookExists():
		sprite.play("swinging")
		face_grapple()
	elif horizontal_input != 0: 
		sprite.play("running")
		sprite.flip_h = horizontal_input < 0;
	else:
		sprite.play("default")
	
	cameraControl(delta)

	if reload_scene:
		var scene_node_2 = get_parent()
		if current_reload_scene_time < reload_scene_time:
			current_reload_scene_time += delta
			scene_node_2.modulate.a = max((reload_scene_time - current_reload_scene_time) / reload_scene_time, 0)
			if(!deathSFX.playing):
				deathSFX.play()
		else:
			GrappleHookGen.deleteHook()
			reload_scene = false
			current_reload_scene_time = 0
			
			global_position = current_spawn_point
			rotation = 0
			camera.global_position = current_spawn_point
			camera.rotation = rotation
			scene_node_2.modulate.a = 1
		
					

func cameraControl(delta):
	camera.position = lerp(camera.position, position, 4 * delta)

	if currentAngleSpeed > 4 or velocity.length() > 50 or velocity.length() == 0:
		camera.rotation = lerp_angle(camera.rotation, rotation, 3 * delta)

func face_grapple():
	var delta = get_physics_process_delta_time()
	var target_pos = GrappleHookGen.getFirstSegmentPose()
	var to_target = (target_pos - global_position)
	var rope_angle = to_target.angle()
	var angle_diff = wrapf(rope_angle - rotation, -PI, PI)

	# If swinging speed is near zero, don't rotate at all
	if currentAngleSpeed < 4:
		return

	# Only rotate if the angle difference is big enough
	if abs(angle_diff) > 0.1:
		rotation = lerp_angle(rotation, rope_angle, 10 * delta)


func check_collisions():
	for i in range(0, get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision:
			var collider = collision.get_collider()
			if not collider: return
			if collider.is_in_group("WorldEdge"):
				reload_scene = true

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
			grappleSFX.play()
		else:
			grappleFailSFX.play()
	if Input.is_action_just_pressed("DeleteHook"):
		GrappleHookGen.deleteHook()

func do_grapple_raycast():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.collision_mask = 1 << 1
	query.from = global_position
	var mousePose = get_global_mouse_position() 
	var delta = (mousePose - global_position)
	var dist = delta.length()
	var dir = delta.normalized()
	query.to = dir * max_grapple_distence + global_position
	query.collide_with_areas = false
	var result = space_state.intersect_ray(query)
	if result:
		if dist < min_grapple_distence or result.is_empty() or result.position.y > position.y: 
			return null
		else: 
			return result.position
	else:
		return null
