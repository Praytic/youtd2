class_name PlayerResourceDisplay extends PanelContainer


# Displays the amounts of player resources.


@export var _lives_status: ResourceStatusPanel
@export var _tomes_status: ResourceStatusPanel
@export var _gold_status: ResourceStatusPanel
@export var _food_status: ResourceStatusPanel


#########################
###     Built-in      ###
#########################

func _process(_delta: float):
	var local_player: Player = PlayerManager.get_local_player()

	if local_player == null:
		return
	
	var local_team: Team = local_player.get_team()
	var portal_lives: String = local_team.get_lives_string()
	_lives_status.set_label_text(portal_lives)

	var gold: int = floori(local_player.get_gold())
	var gold_string: String = TowerDetails.int_format(gold)
	_gold_status.set_label_text(gold_string)

	var tomes: int = local_player.get_tomes()
	var tomes_string: String = str(tomes)
	_tomes_status.set_label_text(tomes_string)

	var food: int = local_player.get_food()
	var food_cap: int = local_player.get_food_cap()
	var food_string: String = "%d/%d" % [food, food_cap]
	_food_status.set_label_text(food_string)
