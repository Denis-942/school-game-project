extends Resource
class_name Topic

enum Type {
	FAKE = 0,
	REAL = 1,
}

@export var type: Type = Type.FAKE
@export var header: String
@export var text: String


func is_fake() -> bool:
	return type == Type.FAKE

func is_real() -> bool:
	return type == Type.REAL


func serialized() -> Dictionary:
	return {
		"type": type,
		"header": header,
		"text": text,
	}

static func deserialized(dict: Dictionary) -> Topic:
	var topic := Topic.new()
	topic.type = dict["type"] as Type
	topic.header = dict["header"] as String
	topic.text = dict["text"] as String
	return topic
