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


# TODO: maybe sort matches by creation time? But that is not available by
# default in nakama. Need to add this data to label.
func update_match_list(match_list: Array):
	var found_matches: bool = !match_list.is_empty()

	_searching_label.visible = !found_matches
	_match_card_grid.visible = found_matches
	
	var card_list: Array = _match_card_grid.get_children()

	for i in range(0, MATCH_CARD_COUNT_MAX):
		var match_: NakamaAPI.ApiMatch
		if i < match_list.size():
			match_ = match_list[i]
		else:
			match_ = null
		
		var match_card: MatchCard = card_list[i]
		
		if match_ != null:
			match_card.load_match(match_)

		match_card.visible = match_ != null
	
	var matches_found: bool = match_list.size() > 0
	
	if matches_found:
		set_state(State.SHOW_MATCHES)
	else:
		set_state(State.NO_MATCHES_FOUND)


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
