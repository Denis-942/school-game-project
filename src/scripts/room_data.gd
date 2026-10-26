extends RefCounted
class_name RoomData

var name: String = ""
var ip_address: String = Game.default_ip_address
var port: int = Game.default_port
var players: Array[int]
var max_players: int = Game.default_max_players
var is_playing: bool = false
var qna: Array[Dictionary]
var decisions: Dictionary[int, int]


func serialized() -> Dictionary:
	return {
		"name": name,
		"ip_address": ip_address,
		"port": port,
		"players": players.duplicate(),
		"max_players": max_players,
		"is_playing": is_playing,
		"qna": qna,
		"decisions": decisions,
		}

static func deserialized(dict: Dictionary) -> RoomData:
	var data := RoomData.new()
	data.name = dict["name"] as String
	data.ip_address = dict["ip_address"] as String
	data.port = dict["port"] as int
	data.players = dict["players"] as Array[int]
	data.max_players = dict["max_players"] as int
	data.is_playing = dict["is_playing"] as bool
	data.qna = dict["qna"] as Array[Dictionary]
	data.decisions = dict["decisions"] as Dictionary[int, int]
	return data


func copy() -> RoomData:
	var data := RoomData.new()
	data.name = name
	data.ip_address = ip_address
	data.port = port
	data.players = players.duplicate()
	data.max_players = max_players
	data.is_playing = is_playing
	data.qna = qna.duplicate_deep()
	data.decisions = decisions.duplicate()
	return data
