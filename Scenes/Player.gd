class_name Player extends Node

# Class representing the player that owns towers. Used for
# multiplayer purposes. 


signal gold_changed()
signal tomes_changed()
signal food_changed()


var _team: Team = Team.new()

@onready var _floating_text_container: Node = get_tree().get_root().get_node("GameScene/FloatingTextContainer")


#########################
###     Built-in      ###
#########################

func _ready():
	GoldControl.changed.connect(_on_gold_control_changed)
	KnowledgeTomesManager.changed.connect(_on_tomes_manager_changed)
	FoodManager.changed.connect(_on_food_manager_changed)


#########################
###       Public      ###
#########################

# TODO: not sure what the point of this f-n is. Leaving as
# is because it's used in original scripts.
# NOTE: Item.getThePlayer() in JASS
func get_the_player() -> Player:
	return self


# NOTE: player.getTeam() in JASS
func get_team() -> Team:
	return _team


# NOTE: player.displayFloatingTextX() in JASS
func display_floating_text_x(text: String, unit: Unit, color: Color, velocity: float, fadepoint: float, time: float):
	var floating_text = Globals.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.duration = time
	floating_text.fadepoint = fadepoint
	floating_text.position = unit.get_visual_position()
	floating_text.velocity = Vector2(0, -velocity)
	_floating_text_container.add_child(floating_text)


# NOTE: player.displayFloatingTextX2() in JASS
func display_floating_text_x_2(text: String, unit: Unit, color: Color, velocity: float, fadepoint: float, time: float, _scale: float, random_offset: float):
	var floating_text = Globals.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.duration = time
	floating_text.fadepoint = fadepoint
	floating_text.position = unit.get_visual_position()
	floating_text.random_offset = random_offset
	floating_text.velocity = Vector2(0, -velocity)
	_floating_text_container.add_child(floating_text)


# NOTE: player.displayFloatingText() in JASS
func display_floating_text(text: String, unit: Unit, color: Color):
	var floating_text = Globals.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.position = unit.get_visual_position()
	_floating_text_container.add_child(floating_text)


# NOTE: player.displaySmallFloatingText() in JASS
func display_small_floating_text(text: String, unit: Unit, color: Color, random_offset: float):
	var floating_text = Globals.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.position = unit.get_visual_position()
	floating_text.random_offset = random_offset
	_floating_text_container.add_child(floating_text)


# TODO: Move to the "owner" class that is returned by
# get_player() when owner class is implemented
# NOTE: player.giveGold() in JASS
func give_gold(amount: float, unit: Unit, show_effect: bool, show_text: bool):
	GoldControl.add_gold(amount)

	if show_effect:
		var effect: int = Effect.create_simple_at_unit("gold effect path", unit)
		Effect.destroy_effect_after_its_over(effect)

	if show_text:
		var text: String
#		NOTE: add 1 significant digit for <1.0 amounts but
#		none for greater amounts because for those amounts
#		it's not important and only adds visual noise.
		var amount_string_digits: int
		if amount < 1.0:
			amount_string_digits = 1
		else:
			amount_string_digits = 0
		var amount_string: String = Utils.format_float(amount, amount_string_digits)

		if amount >= 0:
			text = "+%s" % amount_string
		else:
			text = "-%s" % amount_string

		var color: Color
		if amount >= 0:
			color = Color.GOLD
		else:
			color = Color.RED

		display_floating_text(text, unit, color)


func get_gold() -> float:
	return GoldControl.get_gold()


func get_gold_farmed() -> float:
	return GoldControl.get_gold_farmed()


# NOTE: player.modifyIncomeRate in JASS
func modify_income_rate(amount: float):
	GoldControl.modify_income_rate(amount)


# NOTE: player.modifyInterestRate in JASS
func modify_interest_rate(amount: float):
	GoldControl.modify_interest_rate(amount)


func add_income(level: int):
	GoldControl.add_income(level)


func enough_gold_for_tower(tower_id: int) -> bool:
	return GoldControl.enough_gold_for_tower(tower_id)


func spend_gold(amount: float):
	GoldControl.spend_gold(amount)


func get_tomes() -> int:
	return KnowledgeTomesManager.get_current()


func add_tomes(amount: int):
	KnowledgeTomesManager.add_knowledge_tomes(amount)


func add_tome_income():
	KnowledgeTomesManager.add_income()


func spend_tomes(amount: int):
	KnowledgeTomesManager.spend(amount)


func enough_tomes_for_tower(tower_id: int) -> bool:
	return KnowledgeTomesManager.enough_tomes_for_tower(tower_id)


func enough_food_for_tower(tower_id: int) -> bool:
	return FoodManager.enough_food_for_tower(tower_id)


func add_food_for_tower(tower_id: int):
	FoodManager.add_tower(tower_id)


func remove_food_for_tower(tower_id: int):
	FoodManager.remove_tower(tower_id)


func modify_food_cap(amount: int):
	FoodManager.modify_food_cap(amount)


func get_food() -> int:
	return FoodManager.get_current_food()


func get_food_cap() -> int:
	return FoodManager.get_food_cap()


# NOTE: player.getNumTowers in JASS
func get_num_towers() -> int:
	var tower_list: Array = get_tree().get_nodes_in_group("towers")
	var num_towers: int = tower_list.size()

	return num_towers


#########################
###     Callbacks     ###
#########################

func _on_gold_control_changed():
	gold_changed.emit()


func _on_tomes_manager_changed():
	tomes_changed.emit()


func _on_food_manager_changed():
	food_changed.emit()
