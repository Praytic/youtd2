extends Control

# This HUD is shown when the game starts and blocks input to
# the normal HUD. Once the player chooses all of the
# settings, this hud gets hidden and the game starts.


enum Tab {
	PLAYER_MODE,
	GAME_LENGTH,
	DISTRIBUTION,
	DIFFICULTY,
	BUILDER,
	TUTORIAL_QUESTION,
}


@export var _tab_container: TabContainer


#########################
###     Built-in      ###
#########################

func _ready():
	_tab_container.current_tab = Tab.PLAYER_MODE


#########################
###     Callbacks     ###
#########################

func _on_submenu_finished():
	var is_last_tab: bool = _tab_container.current_tab == Tab.TUTORIAL_QUESTION
	
	if is_last_tab:
		hide()
	else:
		var next_tab: Tab = (_tab_container.current_tab + 1) as Tab
		_tab_container.current_tab = next_tab
