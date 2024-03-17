class_name Player extends Node

# Class representing the player that owns towers. Used for
# multiplayer purposes.

signal item_stash_changed()
signal horadric_stash_changed()
signal tower_stash_changed()


const STARTING_ELEMENT_COST = 20
const MAX_FOOD_CAP: int = 99
const INITIAL_FOOD_CAP: int = 55
const MAX_GOLD = 999999
# NOTE: the interest gain max value comes from the JASS code
# for original game
const INTEREST_GAIN_MAX: int = 1000
const MAX_KNOWLEDGE_TOMES: int = 999999
const KNOWLEDGE_TOMES_INCOME: int = 8


var _team: Team = Team.new()
var _total_damage: float = 0
var _tower_count_for_starting_roll: int = 6
var _element_level_map: Dictionary = {}
var _food: int = 0
var _food_cap: int = INITIAL_FOOD_CAP
var _income_rate: float = 1.0
var _interest_rate: float = 0.05
var _gold: float = Config.starting_gold()
var _gold_farmed: float = 0
var _tomes: int = Config.starting_tomes()
var _id: int = -1
var _builder: Builder = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@export var _item_stash: ItemContainer
@export var _horadric_stash: ItemContainer
@export var _tower_stash: TowerStash

@onready var _floating_text_container: Node = get_tree().get_root().get_node("GameScene/World/FloatingTextContainer")


#########################
###     Built-in      ###
#########################

func _ready():
	for element in Element.get_list():
		_element_level_map[element] = 0


#########################
###       Public      ###
#########################

func set_seed(player_seed: int):
	_rng.seed = player_seed


func get_rng() -> RandomNumberGenerator:
	return _rng


func get_builder() -> Builder:
	return _builder


func apply_builder_wave_finished_effect():
	_builder.apply_wave_finished_effect(self)


func get_item_stash() -> ItemContainer:
	return _item_stash


func get_horadric_stash() -> ItemContainer:
	return _horadric_stash


func get_tower_stash() -> TowerStash:
	return _tower_stash


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
	return str(_id)


func get_id() -> int:
	return _id


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
	add_gold(amount)

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


func add_gold(amount: float, source_is_income: bool = false):
#	NOTE: gold framed should include only gold gained from
#	creep kills or item/tower effects
	if !source_is_income:
		_gold_farmed += amount

	var new_total: float = _gold + amount
	_set_gold(new_total)


func get_gold() -> float:
	return _gold


func get_gold_farmed() -> float:
	return _gold_farmed


# NOTE: player.modifyIncomeRate in JASS
func modify_income_rate(amount: float):
	_income_rate = _income_rate + amount


# NOTE: player.modifyInterestRate in JASS
func modify_interest_rate(amount: float):
	_interest_rate = _interest_rate + amount


func add_income(level: int):
	var upkeep: int = floori((20 + level * 2) * _income_rate)
	var current_gold: int = floori(_gold)
	var interest: int = floori(min(current_gold * _interest_rate, INTEREST_GAIN_MAX))
	var income: int = upkeep + interest
	var source_is_income: bool = true
	add_gold(income, source_is_income)

	Messages.add_normal("Income: %d upkeep, %d interest." % [upkeep, interest])


func enough_gold_for_tower(tower_id: int) -> bool:
	var cost: float = TowerProperties.get_cost(tower_id)
	var current_gold: float = get_gold()
	var enough_gold: bool = cost <= current_gold

	return enough_gold


func spend_gold(amount: float):
	var new_total: float = _gold - amount
	_set_gold(new_total)


func get_tomes() -> int:
	return _tomes


func add_tomes(amount: int):
	var new_tomes: int = _tomes + amount
	_set_tomes(new_tomes)


func add_tome_income():
	add_tomes(KNOWLEDGE_TOMES_INCOME)


func spend_tomes(amount: int):
	var new_value: int = _tomes - amount
	_set_tomes(new_value)


func enough_tomes_for_tower(tower_id: int) -> bool:
	var tome_cost: int = TowerProperties.get_tome_cost(tower_id)
	var enough_tomes: bool = tome_cost <= _tomes

	return enough_tomes


func enough_food_for_tower(tower_id: int) -> bool:
	if Config.unlimited_food():
		return true
	
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var food_after_add: int = _food + food_cost
	var enough_food: bool = food_after_add <= _food_cap

	return enough_food


func add_food_for_tower(tower_id: int):
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var new_food: int = _food + food_cost

	if new_food > _food_cap and not Config.unlimited_food():
		push_error("Tried to change food above cap.")

		return

	_food = new_food


func remove_food_for_tower(tower_id: int):
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var new_food: int = _food - food_cost
	
	if new_food < 0:
		push_error("Tried to change food below 0.")

		return
	
	_food = new_food


func modify_food_cap(amount: int):
	_food_cap = clampi(_food_cap + amount, 0, MAX_FOOD_CAP)


func get_food() -> int:
	return _food


func get_food_cap() -> int:
	return _food_cap


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
###      Private      ###
#########################

func _set_gold(value: float):
	_gold = clampf(value, 0, MAX_GOLD)


func _set_tomes(value):
	_tomes = clampi(value, 0, MAX_KNOWLEDGE_TOMES)


func _on_item_stash_items_changed():
	item_stash_changed.emit()


func _on_horadric_stash_items_changed():
	horadric_stash_changed.emit()


func _on_tower_stash_changed():
	tower_stash_changed.emit()


#########################
###       Static      ###
#########################

static func make(id: int, builder_id: int) -> Player:
	var player: Player = Globals.player_scene.instantiate()
	var builder: Builder = Builder.create_instance(builder_id)
	player._id = id
	player._builder = builder
	player.add_child(builder)

	builder.apply_to_player(player)

	return player
