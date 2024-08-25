class_name OnlineMatchListMenu extends PanelContainer


signal join_pressed()
signal cancel_pressed()
signal create_room_pressed()


@export var _no_rooms_found_label: Label
@export var _item_list: ItemList


#########################
###       Public      ###
#########################

func get_selected_match_id() -> String:
	var selected_index_list: Array = _item_list.get_selected_items()
	
	if selected_index_list.is_empty():
		return ""
	
	var selected_index: int = selected_index_list[0]
	var selected_match_id: String = _item_list.get_item_metadata(selected_index)
	
	return selected_match_id


# TODO: maybe sort matches by creation time? But that is not available by
# default in nakama. Need to add this data to label.
func update_match_list(match_list: Array):
	var found_rooms: bool = !match_list.is_empty()
	
	_no_rooms_found_label.visible = !found_rooms
	_item_list.visible = found_rooms
	
	_item_list.clear()
	
	for match_ in match_list:
		var match_display_string: String = _get_match_text(match_)

		var match_is_invalid: bool = match_display_string.is_empty()
		if match_is_invalid:
			continue

		_item_list.add_item(match_display_string)
		
		var item_index: int = _item_list.get_item_count() - 1
		_item_list.set_item_metadata(item_index, match_.match_id)


func _get_match_text(match_: NakamaAPI.ApiMatch) -> String:
	var label_string: String = match_.label

	var parse_result = JSON.parse_string(label_string)
	var parse_failed: bool = parse_result == null
	if parse_failed:
		return ""

	var label_dict: Dictionary = parse_result

	var match_config: RoomConfig = RoomConfig.convert_from_dict(label_dict)

	var host_username: String = label_dict.get("host_username", "UNKNOWN")

	var player_count: int = match_.size
	var difficulty: Difficulty.enm = match_config.get_difficulty()
	var difficulty_string: String = Difficulty.convert_to_string(difficulty).capitalize()
	var game_length: int = match_config.get_game_length()
	var game_length_string: String = str(game_length)
	var game_mode: GameMode.enm = match_config.get_game_mode()
	var game_mode_string: String = GameMode.convert_to_string(game_mode).capitalize()

	var match_age: int = _get_match_age_minutes(label_dict)

	var text: String = "%d/2 players\n %s, %s, %s waves - by %s. Created %d min ago" % [player_count, difficulty_string, game_mode_string, game_length_string, host_username, match_age]

	return text


func _get_match_age_minutes(label_dict: Dictionary) -> int:
	var creation_time: float = label_dict.get("creation_time", -1)

	if creation_time == -1:
		return -1

	var current_time: float = Time.get_unix_time_from_system()
	var age_seconds: float = current_time - creation_time
	var age_minutes: int = ceil(age_seconds / 60.0)

	return age_minutes


#########################
###     Callbacks     ###
#########################

func _on_join_button_pressed():
	join_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()


func _on_create_room_button_pressed():
	create_room_pressed.emit()
