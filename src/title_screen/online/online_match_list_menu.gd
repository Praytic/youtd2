@tool
class_name OnlineMatchListMenu extends PanelContainer


# Displays a list of online matches.


enum State {
	SEARCHING,
	NO_MATCHES_FOUND,
	SHOW_MATCHES,
}

# TODO: support showing matches beyond 40 match limit. Add pages.

signal join_pressed(match_id: int)
signal refresh_pressed()
signal cancel_pressed()
signal create_match_pressed()
signal lan_pressed()


const MATCH_CARD_COUNT_MAX: int = 50

@export var _searching_label: Label
@export var _no_matches_found_label: Label
@export var _match_card_grid: GridContainer
@export var _refresh_button: Button


#########################
###     Built-in      ###
#########################

func _ready():
	for i in range(0, MATCH_CARD_COUNT_MAX):
#		var match_id: String = match_.match_id
		var match_card: MatchCard = MatchCard.make()
		match_card.join_pressed.connect(_on_match_card_join_pressed.bind(match_card))
		_match_card_grid.add_child(match_card)
		match_card.hide()
	
	if Engine.is_editor_hint():
		_searching_label.hide()
		
		var card_list: Array = _match_card_grid.get_children()
		for card in card_list:
			card.show()


#########################
###       Public      ###
#########################

func set_state(new_state: OnlineMatchListMenu.State):
	match new_state:
		State.SEARCHING:
			clear_match_list()
			
			_searching_label.show()
			_no_matches_found_label.hide()
			_refresh_button.set_disabled(true)
		State.NO_MATCHES_FOUND:
			clear_match_list()
			
			_searching_label.hide()
			_no_matches_found_label.show()
			_refresh_button.set_disabled(false)
		State.SHOW_MATCHES:
			_searching_label.hide()
			_no_matches_found_label.hide()
			_refresh_button.set_disabled(false)


func clear_match_list():
	var card_list: Array = _match_card_grid.get_children()
	
	for card in card_list:
		card.hide()
		
	_no_matches_found_label.show()


func update_match_list(match_list: Array):
	var found_matches: bool = !match_list.is_empty()

	_searching_label.visible = !found_matches
	_match_card_grid.visible = found_matches
	
	var card_list: Array = _match_card_grid.get_children()

	var free_match_card_list: Array = card_list.duplicate()

#	Load match data into match card UI
	for match_ in match_list:
		var out_of_match_cards: bool = free_match_card_list.is_empty()
		if out_of_match_cards:
			break

		var match_is_valid: bool = _check_match_is_valid(match_)
		if !match_is_valid:
			continue

		var match_card: MatchCard = free_match_card_list.pop_front()
		match_card.load_match(match_)
		match_card.show()

#	Hide unused match cards
	for match_card in free_match_card_list:
		match_card.hide()

	var visible_match_count: int = _get_visible_match_count()
	var matches_found: bool = visible_match_count > 0
	
	if matches_found:
		set_state(State.SHOW_MATCHES)
	else:
		set_state(State.NO_MATCHES_FOUND)


#########################
###      Private      ###
#########################

func _get_visible_match_count() -> int:
	var count: int = 0
	
	var card_list: Array = _match_card_grid.get_children()
	for match_card in card_list:
		if match_card.visible:
			count += 1

	return count


func _check_match_is_valid(match_: NakamaAPI.ApiMatch) -> bool:
	var label_string: String = match_.label
	var parse_result = JSON.parse_string(label_string)
	var parse_failed: bool = parse_result == null
	if parse_failed:
		return false

	var match_label: Dictionary = parse_result

	var match_game_version: String = match_label.get("game_version", "UNKNOWN")
	var local_game_version: String = Config.build_version()
	var match_game_version_is_same: bool = match_game_version == local_game_version
	if !match_game_version_is_same:
		print_verbose("Found invalid match. Match has incompatible version.")

		return false
	
	var player_count: int = match_label.get("player_count", 0)
	var match_has_0_players: bool = player_count == 0
	if match_has_0_players:
		print_verbose("Found invalid match. Match has 0 players.")

		return false
	
	return true


#########################
###     Callbacks     ###
#########################

func _on_match_card_join_pressed(match_card: MatchCard):
	var match_id: String = match_card.get_match_id()
	join_pressed.emit(match_id)


func _on_cancel_button_pressed():
	cancel_pressed.emit()


func _on_create_match_button_pressed():
	create_match_pressed.emit()


func _on_refresh_button_pressed():
	refresh_pressed.emit()


func _on_lan_button_pressed() -> void:
	lan_pressed.emit()
