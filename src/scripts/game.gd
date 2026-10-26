# Autoload Game
extends Node

signal topic_set(topic: Topic)
signal round_started(round_number: int)
signal phase_started(phase: Phase)
signal room_created
signal peer_joined_room
signal peer_left_room
signal peer_spawned
signal room_creation_failed(error: Error)
signal room_joining_failed(error: Error)
#signal info_updated(s: String)
signal room_data_updated(data: RoomData)

signal game_started

@export var player_scene: PackedScene = preload("res://src/scenes/player.tscn")

@onready var player_holder: Node = get_node("/root/Root/Players")

var default_ip_address: String = get_ipv4_address()
var default_max_players: int = 6
var default_port: int = 14000

enum DecisionType {
	POST,
	UNSURE,
	REJECT,
}

enum MessageType {
	QUESTION,
	ANSWER
}

# TODO rename these phases to have proper names
enum Phase {
	PHASE_1,
	PHASE_2,
}

var peer: ENetMultiplayerPeer

var player: Player = null

var _room_data: RoomData = null
var _round: int = 0
var _phase: Phase
var _topics: Array[Topic]


func _ready() -> void:
	#var t := Topic.new()
	#t.type = Topic.Type.REAL
	#t.header = "naglowek"
	#t.text = "sdasdshjadhasdjhhawhewahdash sjadad asdhas hjdhjash hsadhas hjdashjdhj"
	#var arr: Array
	#arr.append(t.serialized())
	#arr.append(t.serialized())
	#arr.append(t.serialized())
	#var s := JSON.stringify(arr)
	#print(s)
	#var t2: Topic = Topic.deserialized(JSON.parse_string(s))
	#print(t2.text)
	
	multiplayer.server_disconnected.connect(func() -> void:
		_room_data = null
		peer_left_room.emit()
		print("disconnected")
		)
	multiplayer.connected_to_server.connect(func() -> void:
		peer_joined_room.emit()
		print("connected")
		)
	#multiplayer.peer_connected.connect(func(id: int) -> void:
	#	peer_peer_joined_room.emit(id)
	#	)
	#multiplayer.peer_disconnected.connect(func(id: int) -> void:
	#	peer_peer_left_room.emit(id)
	#	)

#func _process(delta: float) -> void:
#	if not multiplayer.is_server() or _room_data == null:
#		return
#	_room_update_polling_timer -= delta
#	if _room_update_polling_timer <= 0.0:
#		_update_room_data.rpc(_room_data.serialized())
#		_room_update_polling_timer = _room_update_polling_rate


# INFO fetches the player's ipv4 address, or at least tries to,
# works on my machine so it works I think
func get_ipv4_address() -> String:
	for addr: String in IP.get_local_addresses():
			if ":" in addr \
			or (not addr.begins_with("192.168") \
			and not addr.begins_with("172") \
			and not addr.begins_with("10")):
				continue
			return addr
	return "<no ipv4 address found>"


func create_room(port: int, max_players: int) -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_players)
	if err != OK:
		peer.close()
		room_creation_failed.emit(err)
		return
	_room_data = RoomData.new()
	_room_data.ip_address = get_ipv4_address()
	_room_data.port = port
	_room_data.max_players = max_players
	room_created.emit()
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected_update_room_data, CONNECT_REFERENCE_COUNTED)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_update_room_data, CONNECT_REFERENCE_COUNTED)
	# add a player node for host
	multiplayer.peer_connected.emit(1)
	peer_joined_room.emit()
	return


func join_room(ip_address: String, port: int) -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip_address, port)
	if err != OK:
		peer.close()
		room_joining_failed.emit(err)
		return
	multiplayer.multiplayer_peer = peer
	print(_room_data)
	return

func leave_room() -> void:
	if _room_data == null:
		return
	peer.close()
	return


func start_game() -> void:
	if not multiplayer.is_server():
		return
	_start_game.rpc()
	var m_id: int = _room_data.players.pick_random()
	for player_id: int in _room_data.players:
		if player_id == m_id:
			_assign_role.rpc_id(player_id, Player.Role.MANIPULATOR)
		else:
			_assign_role.rpc_id(player_id, Player.Role.USER)
	
	print(_topics)
	var st: Array[Dictionary]
	for t: Topic in _topics:
		st.append(t.serialized())
	_assign_topics.rpc(st)
	_update_room_data.rpc(_room_data.serialized())

@rpc("authority", "call_local")
func _start_game() -> void:
	_room_data.is_playing = true
	game_started.emit()
	#print(_topics)
	#_assign_topics.rpc(_topics)
	#_start_round.rpc(_round + 1)
	#_start_phase.rpc(_phase + 1)

@rpc("authority", "call_local")
func _start_round(round_number: int) -> void:
	_round = round_number
	round_started.emit(_round)

@rpc("authority", "call_local")
func _start_phase(phase: Phase) -> void:
	_phase = phase
	phase_started.emit(_phase)


func _on_server_disconnected() -> void:
	leave_room()


func _spawn_player(id: int) -> void:
	#if _room_data.players.has(id) and _room_data.players[id] == null:
	#	return
	if get_player(id) != null:
		return
	var p := player_scene.instantiate()
	p.name = str(id)
	p.set_multiplayer_authority(id)
	#_room_data.players[id] = p
	player_holder.add_child(p)
	
	if id == multiplayer.get_unique_id():
		player = p
		peer_spawned.emit()


func _on_peer_connected_update_room_data(id: int) -> void:
	if not multiplayer.is_server():
		return
	_room_data.players.append(id)
	_update_room_data.rpc(_room_data.serialized())

func _on_peer_disconnected_update_room_data(id: int) -> void:
	if not multiplayer.is_server():
		return
	_room_data.players.erase(id)
	_update_room_data.rpc(_room_data.serialized())

@rpc("authority", "call_local")
func _update_room_data(data: Dictionary) -> void:
	_room_data = RoomData.deserialized(data)
	for id: int in _room_data.players:
		_spawn_player(id)
	
	# remove player nodes for those who have left
	for p: Player in get_players():
		if p.get_multiplayer_authority() not in _room_data.players:
			p.queue_free()
	
	#var st: Array[Dictionary]
	#for t: Topic in _topics:
	#	st.append(t.serialized())
	#_assign_topics.rpc(st)
	room_data_updated.emit(_room_data)

# I could just make it into a single function but it looks prettier this way
func request_room_data_update() -> void:
	_handle_room_data_update_request.rpc_id(1)
@rpc("any_peer", "call_local")
func _handle_room_data_update_request() -> void:
	_update_room_data.rpc(_room_data.serialized())


func get_player(id: int) -> Player:
	for p: Player in player_holder.get_children():
		if p.get_multiplayer_authority() == id:
			return p
	return null

func get_players() -> Array[Player]:
	return player_holder.get_children() as Array[Player]

@rpc("authority", "call_local")
func _add_question(sender_id: int, receiver_id: int, text: String) -> void:
	if not multiplayer.is_server():
		#print("not server")
		return
	_room_data.qna.append({
		"type": MessageType.QUESTION,
		"sender_id": sender_id,
		"receiver_id": receiver_id,
		"text": text
	})
	#print("called")
	_update_room_data.rpc(_room_data.serialized())

func send_question(sender_id: int, receiver_id: int, text: String) -> void:
	_handle_send_question.rpc_id(1, sender_id, receiver_id, text)

@rpc("any_peer", "call_local")
func _handle_send_question(sender_id: int, receiver_id: int, text: String) -> void:
	_add_question.rpc(sender_id, receiver_id, text)


@rpc("authority", "call_local")
func _add_answer(sender_id: int, receiver_id: int, text: String) -> void:
	if not multiplayer.is_server():
		#print("not server")
		return
	_room_data.qna.append({
		"type": MessageType.ANSWER,
		"sender_id": sender_id,
		"receiver_id": receiver_id,
		"text": text
	})
	#print("called")
	_update_room_data.rpc(_room_data.serialized())

func send_answer(sender_id: int, receiver_id: int, text: String) -> void:
	_handle_send_answer.rpc_id(1, sender_id, receiver_id, text)

@rpc("any_peer", "call_local")
func _handle_send_answer(sender_id: int, receiver_id: int, text: String) -> void:
	_add_answer.rpc(sender_id, receiver_id, text)


@rpc("authority", "call_local")
func _assign_role(role: Player.Role) -> void:
	player.role = role

func update_topics(topics: Array[Topic]) -> void:
	_topics = topics
	print(_topics)

@rpc("any_peer", "call_local")
func _assign_topics(arr: Array[Dictionary]) -> void:
	_topics.clear()
	for serialized_topic: Dictionary in arr:
		_topics.append(Topic.deserialized(serialized_topic))
	print("%d: " % player.get_multiplayer_authority(), _topics)

@rpc("authority", "call_local")
func _set_topic(topic_index: int) -> void:
	topic_set.emit(_topics[topic_index])
