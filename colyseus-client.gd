extends Node2D

const colyseus = preload("res://addons/godot_colyseus/lib/colyseus.gd")
const Char = preload('res://Player.tscn')

class Player extends colyseus.Schema:
	static func define_fields():
		return [
			colyseus.Field.new("x", colyseus.NUMBER),
			colyseus.Field.new("y", colyseus.NUMBER)
		]
	
	var node
	
	func _to_string():
		return str("(",self.x,",",self.y,")")

class RoomState extends colyseus.Schema:
	static func define_fields():
		return [
			colyseus.Field.new("players", colyseus.MAP, Player),
		]
var room:colyseus.Room

# Called when the node enters the scene tree for the first time.
func _ready():
	var client = colyseus.Client.new("ws://localhost:2567")
	var promise = client.join_or_create(RoomState, "state_handler")
	await promise
	if promise.get_state() == promise.State.Failed:
		print("Failed")
		return
	var room: colyseus.Room = promise.get_data()
	var state: RoomState = room.get_state()
	
	state.listen('players:add').on(Callable(self, "_on_players_add"))
	room.on_state_change.on(Callable(self, "_on_state"))
	room.on_message("hello").on(Callable(self, "_on_message"))
	self.room = room

func _on_players_add(target, value, key):
	print("Player added")
	var char = Char.instantiate()
	char.position = Vector2(value.x, value.y)
	add_child(char)
	value.node = char
	value.listen(":change").on(Callable(self, "_on_player"))

func _on_player(target):
	print("Change ", target)
	var char = target.node
	char.position = Vector2(target.x, target.y)

func _on_state(state):
	print("State changed")
	
func _on_message(data):
	print("Message:", data)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	room.send("move", input_direction)
