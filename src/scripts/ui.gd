# UI
extends Node

# menus
var menus: Array[Control]


@export_subgroup("Main Menu", "main_menu_")
@export var main_menu: Control
@export var main_menu_nickname_line_edit: LineEdit
@export var main_menu_host_button: Button
@export var main_menu_join_button: Button
@export var main_menu_topics_text_edit: TextEdit
@export var main_menu_update_topics_button: Button

@export_subgroup("Host Menu", "host_menu_")
@export var host_menu: Control
@export var host_menu_room_name_line_edit: LineEdit
@export var host_menu_room_max_players_spin_box: SpinBox
@export var host_menu_room_port_spin_box: SpinBox
@export var host_menu_create_room_button: Button

@export_subgroup("Join Menu", "join_menu_")
@export var join_menu: Control
@export var join_menu_room_ip_address_line_edit: LineEdit
@export var join_menu_room_port_spin_box: SpinBox
@export var join_menu_join_button: Button

@export_subgroup("Room Menu", "room_menu_")
@export var room_menu: Control
@export var room_menu_start_button: Button
@export var room_menu_leave_button: Button
@export var room_menu_room_max_players_label: Label
@export var room_menu_room_ip_address_label: Label
@export var room_menu_room_port_label: Label
@export var room_menu_room_player_list_vbox: VBoxContainer
@export_subgroup("Room Menu/Game Elements", "room_menu_game_")
@export var room_menu_game_ui: Control
@export var room_menu_game_argument_text_edit: TextEdit
@export var room_menu_game_decision_option_button: OptionButton
@export var room_menu_game_send_state_button: Button
@export var room_menu_game_arguments_vbox: VBoxContainer
@export var room_menu_game_question_text_edit: TextEdit
@export var room_menu_game_question_receiver_option_button: OptionButton
@export var room_menu_game_question_send_button: Button
@export var room_menu_game_answer_text_edit: TextEdit
@export var room_menu_game_answer_receiver_option_button: OptionButton
@export var room_menu_game_answer_send_button: Button
@export var room_menu_game_questions_and_answers_vbox: VBoxContainer
@export var room_menu_game_role_label: RichTextLabel

@export_subgroup("Back Buttons")
@export var back_buttons: Array[Button]
@export_subgroup("")

@export var error_labels: VBoxContainer


func _ready() -> void:
	menus.append(main_menu)
	menus.append(host_menu)
	menus.append(join_menu)
	menus.append(room_menu)
	for back_button: Button in back_buttons:
		back_button.pressed.connect(show_last_menu)
	Game.room_data_updated.connect(_on_room_data_updated)
	main_menu_host_button.pressed.connect(change_menu.bind(host_menu))
	main_menu_join_button.pressed.connect(change_menu.bind(join_menu))
	host_menu_create_room_button.pressed.connect(func() -> void:
		var port := int(host_menu_room_port_spin_box.value)
		var max_players := int(host_menu_room_max_players_spin_box.value)
		Game.create_room(port, max_players)
		)
	join_menu_join_button.pressed.connect(func() -> void:
		var addr := join_menu_room_ip_address_line_edit.text.strip_edges()
		var port := int(join_menu_room_port_spin_box.value)
		Game.join_room(addr, port)
		)
	room_menu_start_button.pressed.connect(Game.start_game)
	room_menu_leave_button.pressed.connect(Game.leave_room)
	Game.room_created.connect(change_menu.bind(room_menu))
	Game.peer_joined_room.connect(change_menu.bind(room_menu))
	Game.peer_left_room.connect(change_menu.bind(main_menu))
	Game.peer_spawned.connect(func() -> void:
		Game.player.nickname = main_menu_nickname_line_edit.text
		)
	Game.room_creation_failed.connect(func(err: Error) -> void:
		change_menu(main_menu)
		show_error(error_string(err))
		)
	Game.room_joining_failed.connect(func(err: Error) -> void:
		change_menu(main_menu)
		show_error(error_string(err))
		)
	room_menu_game_question_send_button.pressed.connect(func() -> void:
		var sender: int = Game.player.get_multiplayer_authority()
		var receiver: int = room_menu_game_question_receiver_option_button.get_selected_id()
		var text: String = room_menu_game_question_text_edit.text
		Game.send_question(sender, receiver, text)
		)
	room_menu_game_answer_send_button.pressed.connect(func() -> void:
		var sender: int = Game.player.get_multiplayer_authority()
		var receiver: int = room_menu_game_answer_receiver_option_button.get_selected_id()
		var text: String = room_menu_game_answer_text_edit.text
		Game.send_answer(sender, receiver, text)
		)
	
	main_menu_update_topics_button.pressed.connect(func() -> void:
		var s := main_menu_topics_text_edit.text
		var data: Variant = JSON.parse_string(s)
		if data == null or typeof(data) != TYPE_ARRAY:
			show_error("Błąd z parsowaniem JSON'a")
			return
		
		var topics: Array[Topic]
		for t: Dictionary in data:
			topics.append(Topic.deserialized(t))
		
		Game.update_topics(topics)
		)
	
	join_menu_room_ip_address_line_edit.text = Game.get_ipv4_address()
	
	#main_menu_update_topics_button.pressed.connect(func() -> void:
	#	var s: String = main_menu_topics_text_edit.text
	#	#var topics: Array[Topic]
	#	var d: Variant = JSON.parse_string(s)
	#	print(d)
	#	)
	#argument_text_edit.text_changed.connect(func() -> void:
	#	Game.player.argument = argument_text_edit.text
	#	)
	hide_all_menus()
	show_menu(main_menu)


func change_menu(menu: Control) -> void:
	hide_menu(menus.back())
	show_menu(menu)

func show_last_menu() -> void:
	hide_menu(menus.back())
	show_menu(menus[menus.size() - 2])

func show_menu(menu: Control) -> void:
	menu.show()
	menus.erase(menu)
	menus.append(menu)

func hide_menu(menu: Control) -> void:
	menu.hide()

func hide_all_menus() -> void:
	for menu: Control in menus:
		hide_menu(menu)


# why is this function so long
func _on_room_data_updated(data: RoomData) -> void:
	room_menu_start_button.visible = multiplayer.is_server() and not data.is_playing
	room_menu_room_max_players_label.text = "Maksymalna ilość graczy: %d" % data.max_players
	room_menu_room_ip_address_label.text = "Adres IP (IPv4) (może być błędny): %s" % data.ip_address
	room_menu_room_port_label.text = "Port: %d" % data.port
	for child: Node in room_menu_room_player_list_vbox.get_children():
		child.queue_free()
	
	for id: int in data.players:
		var label := Label.new()
		label.text = "[%d] %s" % [
			id, Game.get_player(id).nickname]
		room_menu_room_player_list_vbox.add_child(label)
	
	room_menu_game_ui.visible = data.is_playing
	
	room_menu_game_question_receiver_option_button.clear()
	for id: int in data.players:
		if id == Game.player.get_multiplayer_authority():
			continue
		var text: String = Game.get_player(id).nickname
		room_menu_game_question_receiver_option_button.add_item(text, id)
	
	room_menu_game_answer_receiver_option_button.clear()
	for id: int in data.players:
		if id == Game.player.get_multiplayer_authority():
			continue
		var text: String = Game.get_player(id).nickname
		room_menu_game_answer_receiver_option_button.add_item(text, id)
	
	# clear children
	for child in room_menu_game_questions_and_answers_vbox.get_children():
		child.queue_free()
	
	# add question labels
	for qna_dict: Dictionary in data.qna:
		var label := Label.new()
		var type: Game.MessageType = qna_dict["type"]
		var sender: Player = Game.get_player(qna_dict["sender_id"])
		var receiver: Player = Game.get_player(qna_dict["receiver_id"])
		var text: String = qna_dict["text"]
		if type == Game.MessageType.QUESTION:
			label.text = "[%s] pyta [%s]:\n%s" % [
				sender.nickname, receiver.nickname, text]
		elif type == Game.MessageType.ANSWER:
			label.text = "[%s] odpowiada [%s]:\n%s" % [
				sender.nickname, receiver.nickname, text]
		room_menu_game_questions_and_answers_vbox.add_child(label)
	
	match Game.player.role:
		Player.Role.USER:
			room_menu_game_role_label.text = "Jesteś [color=light_blue]Użytkownikiem[/color]"
		Player.Role.MANIPULATOR:
			room_menu_game_role_label.text = "Jesteś [color=red]Manipulatorem[/color]"


func show_error(error: String) -> void:
	var label := Label.new()
	label.text = "Error: %s" % error
	label.add_theme_color_override("font_color", Color.TOMATO)
	error_labels.add_child(label)
	await get_tree().create_timer(3.0).timeout
	label.queue_free()
