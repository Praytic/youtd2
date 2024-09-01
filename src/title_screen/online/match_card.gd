@tool
class_name MatchCard extends PanelContainer


signal join_pressed()

var _match_id: String = ""

@export var _match_info_label: RichTextLabel
@export var _player_count_label: RichTextLabel


#########################
###       Public      ###
#########################

func load_match(match_: NakamaAPI.ApiMatch):
	_match_id = match_.match_id
	
	var match_info_text: String = _get_match_info_text(match_)
	var player_count_text: String = _get_player_count_text(match_)
	
	_match_info_label.clear()
	_match_info_label.append_text(match_info_text)
	_player_count_label.clear()
	_player_count_label.append_text(player_count_text)


func get_match_id() -> String:
	return _match_id


#########################
###      Private      ###
#########################

func _get_match_info_text(match_: NakamaAPI.ApiMatch) -> String:
	var label_string: String = match_.label

	var parse_result = JSON.parse_string(label_string)
	var parse_failed: bool = parse_result == null
	if parse_failed:
		return ""

	var label_dict: Dictionary = parse_result

	var match_config: MatchConfig = MatchConfig.convert_from_dict(label_dict)

	var host_username: String = label_dict.get("host_username", "UNKNOWN")

	var difficulty: Difficulty.enm = match_config.get_difficulty()
	var difficulty_string: String = Difficulty.convert_to_colored_string(difficulty)
	var game_length: int = match_config.get_game_length()
	var game_length_string: String = str(game_length)
	var game_mode: GameMode.enm = match_config.get_game_mode()
	var game_mode_string: String = GameMode.convert_to_long_display_string(game_mode).capitalize()

	var text: String = "" \
	+ "%s\n" % difficulty_string \
	+ "%s waves\n" % game_length_string \
	+ "%s\n" % game_mode_string \
	+ " \n" \
	+ "[color=ROYAL_BLUE]Host: %s[/color]" % host_username \
	+ ""

	return text


func _get_player_count_text(match_: NakamaAPI.ApiMatch) -> String:
	var player_count: int = match_.size
	var text: String = "%d/2" % player_count
	
	return text


#########################
###     Callbacks     ###
#########################

func _on_join_button_pressed():
	join_pressed.emit()


#########################
###       Static      ###
#########################

static func make() -> MatchCard:
	var scene: PackedScene = preload("res://src/title_screen/online/match_card.tscn")
	var card: MatchCard = scene.instantiate()
	
	return card
