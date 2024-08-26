extends Node

@export var character:Node2D
@export var ammo_bar:Node2D
@export var health_bar:TextureProgressBar

func aim_at(pos:Vector2):
	character.look_at(pos)

func quit():
	queue_free()
