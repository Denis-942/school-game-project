extends Resource
class_name Topic


@export var header: String
@export var text: String



func serialized() -> Dictionary:
	return {
		"header": header,
		"text": text,
	}

static func deserialized(dict: Dictionary) -> Topic:
	var topic := Topic.new()
	topic.header = dict["header"] as String
	topic.text = dict["text"] as String
	return topic
