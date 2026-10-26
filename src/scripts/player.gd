extends Node
class_name Player

enum Role {
	USER,
	MANIPULATOR,
}

@export var nickname: String
@export var role: Role

@export var _synchronizer: MultiplayerSynchronizer


func _ready() -> void:
	#print(_synchronizer)
	if not is_multiplayer_authority():
		#print("not auth (%d)" % [get_multiplayer_authority()])
		_synchronizer.synchronized.connect(
			Game.request_room_data_update, CONNECT_ONE_SHOT)
		return
	#Game.player = self
	#print(Game.player)
