extends Node

var scaleFactor = Vector2(2.5, 2.5)
var defaultSpriteSize = Vector2(8, 4)
var spawnOffset = 20
var segments = Array()
func generateHook(startingNode, endingPoint):
	var spriteSize = scaleFactor * defaultSpriteSize
	var dir = (endingPoint - startingNode.position).normalized()
	var startingPose = startingNode.position + (spawnOffset * dir)
	var angle = startingPose.angle_to_point(endingPoint)
	var segmentSize = spriteSize.length() * dir
	var numSegments = int((endingPoint - startingPose).length() / segmentSize.length()) + 1
	
	print(numSegments)
	print(startingPose)
	print(spriteSize)

	for i in range(0, numSegments):
		segments.append(_generateSegment(Vector2(startingPose.x + segmentSize.x * i, startingPose.y + segmentSize.y * i), angle, spriteSize))
		segments[i].name = "Segment" + str(i)
		add_child(segments[i])

		segments[i].gravity_scale = .2
		segments[i].linear_damp = 9.0
		segments[i].angular_damp = 9.0

	
	for i in range(0, numSegments-1):
		var joint = PinJoint2D.new()
		joint.node_a = segments[i].get_path()
		joint.node_b = segments[i+1].get_path()
		joint.position = Vector2((segments[i].position.x + segmentSize.x/2), (segments[i].position.y + segmentSize.y/2))
		joint.rotate(angle)
		add_child(joint)
	
	var startingAnchor = StaticBody2D.new()
	var endingAnchor = StaticBody2D.new()

	startingAnchor.add_child(CollisionShape2D.new())
	endingAnchor.add_child(CollisionShape2D.new())
	startingAnchor.position = startingNode.position
	var endingPose = segments[segments.size()-1].position
	endingAnchor.position = Vector2(endingPose.x + segmentSize.x, endingPose.y + segmentSize.y)
	add_child(startingAnchor)
	add_child(endingAnchor)

	var startingJoint = PinJoint2D.new()
	var endingJoint = PinJoint2D.new()

	startingJoint.node_a = startingAnchor.get_path()
	startingJoint.node_b = segments[0].get_path()

	endingJoint.node_a = startingAnchor.get_path()
	endingJoint.node_b = segments[segments.size()-1].get_path()
	
	startingJoint.position = Vector2(startingNode.position.x + spawnOffset/2.0, startingNode.position.y + spawnOffset/2)
	endingJoint.position = Vector2(endingPose.x + segmentSize.x * 1.1, endingPose.y + segmentSize.y * 1.1)
	
	add_child(startingJoint)
	add_child(endingJoint)


func _generateSegment(position, angle, spriteSize):
	var segment = RigidBody2D.new()
	var sprite = Sprite2D.new()
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	segment.add_child(sprite)
	segment.add_child(collider)

	segment.position = position
	segment.rotate(angle)

	segment.mass = 50
	sprite.texture = preload("res://Assets/Textures/Rope_Placeholder.png")
	sprite.apply_scale(scaleFactor)
	shape.size = spriteSize
	collider.shape = shape
	
	return segment

func deleteHook():
	for i in range(0, segments.size()):
		segments[i].queue_free()
	
