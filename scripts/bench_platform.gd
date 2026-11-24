extends AnimatableBody2D

@export var hover_speed: float = 2.0
@export var hover_distance: float = 12.0

var start_y: float = 0.0
var time_passed: float = 0.0

func _ready():
	start_y = position.y
	time_passed = randf_range(0.0, 5.0)

func _physics_process(delta):
	time_passed += delta * hover_speed
	position.y = start_y + sin(time_passed) * hover_distance
