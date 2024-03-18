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


#########################
###       Public      ###
#########################

func set_gold(gold: float):
	var text: String = str(gold)
	_gold_status.set_label_text(text)


func set_tomes(tomes: int):
	var text: String = str(tomes)
	_tomes_status.set_label_text(text)


func set_food(food: int, food_cap: int):
	var text: String = "%d/%d" % [food, food_cap]
	_food_status.set_label_text(text)
