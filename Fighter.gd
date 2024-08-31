extends Node

@export var character:Node2D
@export var ammo_bar:Node2D
@export var health_bar:TextureProgressBar

func aim_at(pos:Vector2):
	character.look_at(pos)

func quit():
	queue_free()

func set_ammo(ammo:int):
	var ammo_icons = ammo_bar.get_children()
	for ai in range(len(ammo_icons)):
		ammo_icons[ai].visible = ai < ammo
