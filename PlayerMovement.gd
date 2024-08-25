extends CharacterBody2D

@export var speed = 200
@export var bullet:Node2D
@export var max_ammo = 3
@export var ammo_bar:Node2D
@export var reload_speed = 1.0
@export var fire_rate = 0.2
@export var healthbar:TextureProgressBar
var ammo = 0
var fire_cooldown = 0
var reload_cooldown = 0
var ammo_icons

# Called when the node enters the scene tree for the first time.
func _ready():
	ammo = max_ammo
	ammo_icons = ammo_bar.get_children()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fire_cooldown > 0:
		fire_cooldown = max(fire_cooldown - delta, 0)
		
	if reload_cooldown > 0:
		reload_cooldown = max(reload_cooldown - delta, 0)
	else:
		ammo = min(ammo+1, max_ammo)
		if ammo < max_ammo:
			reload_cooldown = reload_speed
	
	for ai in range(len(ammo_icons)):
		ammo_icons[ai].visible = ai < ammo

func shoot():
	if bullet != null and ammo > 0 and fire_cooldown == 0:
		fire_cooldown = fire_rate
		reload_cooldown = reload_speed
		ammo -= 1
		
		var new_bullet = bullet.duplicate()
		var dir = get_global_mouse_position() - global_position
		new_bullet.fire(global_position, dir.normalized())
		get_tree().root.add_child(new_bullet)


func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	var mouse = get_global_mouse_position()
	get_node("Player").look_at(mouse)
	if Input.is_action_pressed("shoot"):
		shoot()

func _physics_process(delta):
	get_input()
	move_and_slide()
