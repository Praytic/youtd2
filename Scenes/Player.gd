class_name Player extends Node

# Class representing the player that owns towers. Used for
# multiplayer purposes. 


signal gold_changed()
signal tomes_changed()
signal food_changed()


const STARTING_ELEMENT_COST = 20


var _team: Team = Team.new()
var _total_damage: float = 0
var _tower_count_for_starting_roll: int = 6
var _element_level_map: Dictionary = {}

@onready var _floating_text_container: Node = get_tree().get_root().get_node("GameScene/World/FloatingTextContainer")


#########################
###     Built-in      ###
#########################

func _ready():
	GoldControl.changed.connect(_on_gold_control_changed)
	KnowledgeTomesManager.changed.connect(_on_tomes_manager_changed)
	FoodManager.changed.connect(_on_food_manager_changed)

	for element in Element.get_list():
		_element_level_map[element] = 0


#########################
###       Public      ###
#########################


func get_tower_count_for_starting_roll() -> int:
	return _tower_count_for_starting_roll


func decrement_tower_count_for_starting_roll():
	_tower_count_for_starting_roll = max(1, _tower_count_for_starting_roll - 1)


func increment_element_level(element: Element.enm):
	_element_level_map[element] += 1


func get_element_level(element: Element.enm) -> int:
	var level: int = _element_level_map[element]
	
	return level


func get_element_level_map() -> Dictionary:
	return _element_level_map


func get_research_cost(element: Element.enm) -> int:
	var level: int = get_element_level(element)
	var cost: int = STARTING_ELEMENT_COST + level

	return cost


# Returns true if have enough tomes to research element.
# Doesn't check whether element is at max level.
func can_afford_research(element: Element.enm) -> bool:
	var cost: int = get_research_cost(element)
	var tome_count: int = get_tomes()
	var can_afford: bool = tome_count >= cost

	return can_afford


# Returns true if player is able to research element. Checks
# whether element is at max level.
func is_able_to_research(element: Element.enm) -> bool:
	var can_afford: bool = can_afford_research(element)
	var current_level: int = get_element_level(element)
	var reached_max_level: bool = current_level == Constants.MAX_ELEMENT_LEVEL
	var is_able: bool = can_afford && !reached_max_level

	return is_able


# TODO: return actual name
func get_player_name() -> String:
	return "Player"


# TODO: return actual score
func get_score() -> int:
	return 0


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


func add_gold(amount: float):
	GoldControl.add_gold(amount)


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


func add_to_total_damage(damage: float):
	_total_damage += damage


func get_total_damage() -> float:
	return _total_damage


#########################
###     Callbacks     ###
#########################

func _on_gold_control_changed():
	gold_changed.emit()


func _on_tomes_manager_changed():
	tomes_changed.emit()


func _on_food_manager_changed():
	food_changed.emit()
