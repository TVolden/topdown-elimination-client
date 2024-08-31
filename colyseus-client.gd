extends Node2D

const colyseus = preload("res://addons/godot_colyseus/lib/colyseus.gd")
const Soldier = preload('res://Player.tscn')
const Missile = preload("res://bullet.tscn")

class Player extends colyseus.Schema:
	static func define_fields():
		return [
			colyseus.Field.new("x", colyseus.NUMBER),
			colyseus.Field.new("y", colyseus.NUMBER),
			colyseus.Field.new("speed", colyseus.NUMBER),
			colyseus.Field.new("f_x", colyseus.NUMBER),
			colyseus.Field.new("f_y", colyseus.NUMBER),
			colyseus.Field.new("ammo", colyseus.NUMBER),
		]
	
	var node
	
	func _to_string():
		return str("(",self.x,",",self.y,")")

class Bullet extends colyseus.Schema:
	static func define_fields():
		return [
			colyseus.Field.new("x", colyseus.NUMBER),
			colyseus.Field.new("y", colyseus.NUMBER),
			colyseus.Field.new("dir_x", colyseus.NUMBER),
			colyseus.Field.new("dir_y", colyseus.NUMBER),
			colyseus.Field.new("speed", colyseus.NUMBER),
		]
	
	var node
	
	func _to_string():
		return str("(",self.x,",",self.y,")")

class RoomState extends colyseus.Schema:
	static func define_fields():
		return [
			colyseus.Field.new("players", colyseus.MAP, Player),
			colyseus.Field.new("bullets", colyseus.MAP, Bullet),
		]
var room:colyseus.Room

# Called when the node enters the scene tree for the first time.
func _ready():
	var client = colyseus.Client.new("ws://localhost:2567")
	var promise = client.join_or_create(RoomState, "my_room")
	await promise.completed
	if promise.get_state() == promise.State.Failed:
		print("Failed")
		return
	room = promise.get_data()
	var state: RoomState = room.get_state()
	
	state.listen('players:add').on(Callable(self, "_on_players_add"))
	state.listen('players:remove_at').on(Callable(self, "_on_players_leave"))
	state.listen('bullets:add').on(Callable(self, "_on_bullets_add"))
	state.listen('bullets:remove_at').on(Callable(self, "_on_bullets_removed"))
	room.on_state_change.on(Callable(self, "_on_state"))
	room.on_message("hello").on(Callable(self, "_on_message"))
	self.room = room

func _on_bullets_add(_target, value, _key):
	print("Shoot!")
	var bullet = Missile.instantiate()
	bullet.position = Vector2(value.x, value.y)
	var dir = Vector2(value.dir_x, value.dir_y)
	bullet.look_at(bullet.position - dir.orthogonal())
	bullet.visible = true
	add_child(bullet)
	value.node = bullet
	value.listen(":change").on(Callable(self, "_on_bullet"))

func _on_bullet(target):
	var bullet = target.node
	bullet.position = Vector2(target.x, target.y)

func _on_bullets_removed(_target, value, _key):
	print("bullet removed")
	value.node.remove()

func _on_players_leave(_target, value, _key):
	print("Player left")
	value.node.quit()

func _on_players_add(_target, value, _key):
	print("Player added")
	var soldier = Soldier.instantiate()
	soldier.position = Vector2(value.x, value.y)
	add_child(soldier)
	value.node = soldier
	value.listen(":change").on(Callable(self, "_on_player"))

func _on_player(target):
	var soldier = target.node
	soldier.position = Vector2(target.x, target.y)
	soldier.aim_at(Vector2(target.f_x, target.f_y))
	soldier.set_ammo(target.ammo)

func _on_state(_state):
	pass
	
func _on_message(data):
	print("Message:", data)
	
func _physics_process(_delta):
	if room != null:
		var input_direction = Input.get_vector("left", "right", "up", "down")
		if !input_direction.is_zero_approx():
			room.send("move", {x=input_direction.x, y=input_direction.y})
		if Input.is_action_pressed("shoot"):
			room.send("shoot")
		var mouse = get_global_mouse_position()
		room.send("aim", {x=mouse.x, y=mouse.y})
