extends CharacterBody2D

@export var speed = 400
@export var max_range = 300

var org_pos
# Called when the node enters the scene tree for the first time.
func _ready():
	org_pos = position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_and_slide()
	if (org_pos - position).length() > max_range:
		queue_free()

func fire(pos, direction):
	position = pos
	look_at(pos - direction.orthogonal())
	velocity = direction * speed
	visible = true
