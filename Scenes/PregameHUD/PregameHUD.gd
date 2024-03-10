extends Control

# This HUD is shown when the game starts and blocks input to
# the normal HUD. Once the player chooses all of the
# settings, this hud gets hidden and the game starts.


enum Tab {
	PLAYER_MODE,
	COOP_ROOM,
	GAME_LENGTH,
	DISTRIBUTION,
	DIFFICULTY,
	BUILDER,
	TUTORIAL_QUESTION,
}


@export var _tab_container: TabContainer
@export var _room_id_container: Container


#########################
###     Built-in      ###
#########################

func _ready():
	_tab_container.current_tab = Tab.PLAYER_MODE
	Network.room_id_changed.connect(_on_room_id_changed)


#########################
###     Callbacks     ###
#########################

func _on_submenu_finished():
	var is_last_tab: bool = _tab_container.current_tab == Tab.TUTORIAL_QUESTION
	
	if is_last_tab:
		hide()
	else:
		var next_tab: Tab = (_tab_container.current_tab + 1) as Tab
		var next_tab_control: PregameTab = _tab_container.get_tab_control(next_tab)
		while next_tab_control != null && !next_tab_control.meets_condition():
			next_tab += 1
			next_tab_control = _tab_container.get_tab_control(next_tab)
		_tab_container.current_tab = next_tab


func _on_room_id_changed():
	_room_id_container.get_node("TextEdit").text = str(Network.get_room_id())
	_room_id_container.visible = true
