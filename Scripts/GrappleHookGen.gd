extends Node

const scaleFactor = Vector2(2.5, 2.5)
const defaultSpriteSize = Vector2(8, 4)
const spawnOffset = 20
const timePerSegment = .025
var segments = Array()
var joints = Array()

var _endingPoint
var ropeLength = Vector2()

func generateHook(startingNode, endingPoint):
	_endingPoint = endingPoint
	var spriteSize = scaleFactor * defaultSpriteSize
	var dir = (endingPoint - startingNode.position).normalized()
	var startingPose = startingNode.position
	var angle = startingPose.angle_to_point(endingPoint)
	var segmentSize = spriteSize.length() * dir
	var numSegments = (int((endingPoint - startingPose).length() / segmentSize.length()) + 1) * 2
	ropeLength = (endingPoint - startingNode.position).length()
	for i in range(0, numSegments):
		segments.append(_generateSegment(Vector2(startingPose.x + segmentSize.x * i * .5, startingPose.y + segmentSize.y * i * .5), angle, spriteSize))
		segments[i].name = "Segment" + str(i)
		add_child(segments[i])
		segments[i].collision_mask = 1 << 1
		segments[i].collision_layer = 1 << 1
		segments[i].gravity_scale = .2
		segments[i].linear_damp = 9.0
		segments[i].angular_damp = 9.0

		var timer = get_tree().create_timer(timePerSegment * i)
		timer.timeout.connect(func():
			if i >= 0 and i < segments.size() and is_instance_valid(segments[i]):
				segments[i].modulate.a = 1
				segments[i].get_child(0).play()
		)

	for i in range(0, numSegments-1):
		var joint = PinJoint2D.new()
		joint.node_a = segments[i].get_path()
		joint.node_b = segments[i+1].get_path()
		joint.position = Vector2((segments[i].position.x + segmentSize.x/2), (segments[i].position.y + segmentSize.y/2))
		joint.bias = 1.0
		joint.softness = .5
		joint.rotate(angle)
		joints.append(joint)
		add_child(joints[i])
	
	var endingAnchor = StaticBody2D.new()

	endingAnchor.add_child(CollisionShape2D.new())
	var endingPose = segments[segments.size()-1].position
	endingAnchor.position = Vector2(endingPose.x + segmentSize.x, endingPose.y + segmentSize.y)
	add_child(endingAnchor)

	var startingJoint = PinJoint2D.new()
	var endingJoint = PinJoint2D.new()
	startingJoint.bias = 1.0
	endingJoint.bias = 1.0
	startingJoint.softness = .5
	endingJoint.softness = .5
	joints.append(startingJoint)
	joints.append(endingJoint)
	startingJoint.node_a = startingNode.get_path()
	startingJoint.node_b = segments[0].get_path()

	endingJoint.node_a = segments[segments.size()-1].get_path()
	endingJoint.node_b = endingAnchor.get_path()
	
	startingJoint.position = Vector2(startingNode.position.x, startingNode.position.y)
	endingJoint.position = Vector2(endingPose.x + segmentSize.x * 1.1, endingPose.y + segmentSize.y * 1.1)
	
	add_child(startingJoint)
	add_child(endingJoint)

func getAverageDistenceBetweenSegments():
	var sum = 0
	var number = 0
	for i in range(0, segments.size()-1):
		sum += segments[i].position.distance_to(segments[i+1].position)
		number+=1
	return sum / number

func getEndPointPose():
	return _endingPoint
	
func _generateSegment(position, angle, spriteSize):
	var segment = RigidBody2D.new()
	var sprite = AnimatedSprite2D.new()
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	segment.add_child(sprite)
	segment.add_child(collider)
	segment.position = position
	segment.rotate(angle)
	segment.z_index = 1

	segment.mass = 50
	sprite.sprite_frames = preload("res://Assets/Textures/Rope.tres")
	sprite.animation = "default"
	sprite.apply_scale(scaleFactor)
	shape.size = spriteSize
	collider.shape = shape
	segment.modulate.a = 0
	return segment

func getFirstSegmentPose() -> Vector2:
	return segments[0].position

func hookExists():
	return segments.size() > 1

func deleteHook():
	for i in range(0, segments.size()):
		segments[i].queue_free()

	for i in range(0, joints.size()):
		joints[i].queue_free()
	segments.clear()
	joints.clear()
