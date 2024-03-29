class_name BottomMenuBar extends PanelContainer


@export var _tomes_status: ResourceStatusPanel
@export var _gold_status: ResourceStatusPanel
@export var _food_status: ResourceStatusPanel


#########################
###     Built-in      ###
#########################

func _ready():
	HighlightUI.register_target("tomes_status", _tomes_status)
	HighlightUI.register_target("gold_status", _gold_status)
	_tomes_status.mouse_entered.connect(func(): EventBus.player_performed_tutorial_advance_action.emit("mouse_over_tomes"))
	_gold_status.mouse_entered.connect(func(): EventBus.player_performed_tutorial_advance_action.emit("mouse_over_gold"))


func _process(_delta: float):
	var local_player: Player = PlayerManager.get_local_player()

	if local_player == null:
		return

	var gold: float = local_player.get_gold()
	var gold_string: String = str(floori(gold))
	_gold_status.set_label_text(gold_string)

	var tomes: int = local_player.get_tomes()
	var tomes_string: String = str(tomes)
	_tomes_status.set_label_text(tomes_string)

	var food: int = local_player.get_food()
	var food_cap: int = local_player.get_food_cap()
	var food_string: String = "%d/%d" % [food, food_cap]
	_food_status.set_label_text(food_string)
