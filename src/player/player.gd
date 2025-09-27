class_name Player extends Node

# Class representing the player that owns towers. Used for
# multiplayer purposes. Create players using
# Team.create_player().

signal wave_finished(level: int)
signal wave_spawned(level: int)
signal element_level_changed(element: Element.enm)
signal generated_waves()
signal selected_builder()
signal voted_ready()
signal roll_was_disabled()
signal rolled_starting_towers()
signal game_lose()


const STARTING_ELEMENT_COST = 20
const MAX_FOOD_CAP: int = 300
const INITIAL_FOOD_CAP: int = 55
const MAX_GOLD = 999999
# NOTE: the interest gain max value comes from the JASS code
# for original game
const INTEREST_GAIN_MAX: int = 1000
const MAX_KNOWLEDGE_TOMES: int = 999999
const KNOWLEDGE_TOMES_INCOME: int = 8
const INITIAL_TOWER_ROLL_COUNT: int = 6
const INITIAL_GOLD: int = 70
const INITIAL_TOMES: int = 90

const PLAYER_COLOR_MAP: Dictionary = {
	0: Color.RED,
	1: Color.ROYAL_BLUE,
	2: Color.ORANGE,
	3: Color.PURPLE,
	4: Color.GREEN,
	5: Color.CYAN,
	6: Color.BROWN,
	7: Color.PINK,
}


var _team: Team = null
var _total_damage: float = 0
var _tower_count_for_starting_roll: int = INITIAL_TOWER_ROLL_COUNT
var _element_level_map: Dictionary = {}
var _max_element_level_bonus: int = 0
var _max_tower_level_bonus: int = 0
var _food: int = 0
var _food_cap: int = INITIAL_FOOD_CAP
var _income_rate: float = 1.0
var _interest_rate: float = 0.05
var _gold: float = INITIAL_GOLD
var _gold_farmed: float = 0
var _tomes: int = INITIAL_TOMES
var _id: int = -1
var _peer_id: int = -1
var _user_id: String = ""
var _builder: Builder = null
var _have_placeholder_builder: bool = true
var _score: float = 0.0
var _is_ready: bool = false
var _focus_target_effect_id: int = 0
var _builder_wisdom_multiplier: float = 1.0
var _wisdom_modifier: Modifier = Modifier.new()
var _selected_unit: Unit = null
var _autooil: AutoOil = AutoOil.new()
var _player_name: String = "Player"
var _chat_ignored: bool = false

@export var _item_stash: ItemContainer
@export var _horadric_stash: ItemContainer
@export var _tower_stash: TowerStash
@export var _wave_spawner: WaveSpawner

@onready var _floating_text_container: Node = get_tree().get_root().get_node("GameScene/World/FloatingTextContainer")


#########################
###     Built-in      ###
#########################

func _ready():
	_wave_spawner.set_player(self)
	
	for element in Element.get_list():
		_element_level_map[element] = 0

	_gold += Config.cheat_gold()
	_tomes += Config.cheat_tomes()
	_food_cap += Config.cheat_food_cap()
	
	_item_stash.set_player(self)
	_horadric_stash.set_player(self)

	_player_name = _determine_player_name()


#########################
###       Public      ###
#########################

func set_chat_ignored(value: bool):
	_chat_ignored = value


func get_chat_ignored() -> bool:
	return _chat_ignored


func get_autooil_status() -> String:
	return _autooil.get_status()


func get_autooil_tower(oil_id: int) -> Tower:
	return _autooil.get_tower(oil_id)


func transfer_autooils(prev_tower: Tower, new_tower: Tower):
	_autooil.transfer_autooils(prev_tower, new_tower)


func set_autooil_for_tower(type: String, tower: Tower):
	_autooil.set_tower(type, tower)


func clear_autooil_for_tower(tower: Tower):
	_autooil.clear_for_tower(tower)


func clear_all_autooil():
	_autooil.clear_all()


# NOTE: destroy prev effect so that there's only one arrow
# up at a time
func create_focus_target_effect(target: Unit):
	Effect.destroy_effect(_focus_target_effect_id)
	var effect: int = Effect.create_simple_at_unit_attached("res://src/effects/target_arrow.tscn", target, Unit.BodyPart.HEAD)
	Effect.set_lifetime(effect, 2.0)
	_focus_target_effect_id = effect


func vote_ready():
	if _is_ready:
		return

	_is_ready = true
	var player_name: String = get_player_name_with_color()
	Messages.add_normal(null, tr("MESSAGE_PLAYER_IS_READY").format({PLAYER_NAME = player_name}))
	voted_ready.emit()


func is_ready() -> bool:
	return _is_ready


func generate_waves():
	_wave_spawner.generate_waves()
	generated_waves.emit()


func start_wave(level: int):
	_wave_spawner.start_wave(level)


# NOTE: wave is considered in progress if it's spawning
# creeps or about to start spawning creeps. If it has
# finished spawning creeps but creeps are still alive, the
# wave is considered to not be in progress.
# NOTE: include PENDING state to handle edge case of
# multiplayer and 1 creep Boss waves.
func wave_is_in_progress() -> bool:
	var current_level: int = _team.get_level()
	var current_wave: Wave = _wave_spawner.get_wave(current_level)

	if current_wave == null:
		return false

	var current_wave_state: Wave.State = current_wave.state
	var is_in_progress: bool = current_wave_state == Wave.State.PENDING || current_wave_state == Wave.State.SPAWNING 

	return is_in_progress


func current_wave_is_finished() -> bool:
	return _wave_spawner.current_wave_is_finished()


func set_builder(builder_id: int):
	if !_have_placeholder_builder:
		push_error("Player already has a builder. set_builder() should only be called once.")

		return

	if _builder != null:
		remove_child(_builder)
		_builder.queue_free()

	var builder: Builder = Builder.create_instance(builder_id)
	_builder = builder
	add_child(builder)

	builder.apply_to_player(self)

	_have_placeholder_builder = false

	selected_builder.emit()


func get_builder() -> Builder:
	return _builder


func get_item_stash() -> ItemContainer:
	return _item_stash


func get_horadric_stash() -> ItemContainer:
	return _horadric_stash


func get_tower_stash() -> TowerStash:
	return _tower_stash


func get_tower_count_for_starting_roll() -> int:
	return _tower_count_for_starting_roll


func research_element(element: Element.enm):
	var research_cost: int = get_research_cost(element)
	spend_tomes(research_cost)
	
	_element_level_map[element] += 1
	element_level_changed.emit()


func get_element_level(element: Element.enm) -> int:
	var level: int = _element_level_map[element]
	
	return level


func get_element_level_map() -> Dictionary:
	return _element_level_map

func get_max_element_level_bonus() -> int:
	return _max_element_level_bonus

func get_max_element_level() -> int:
	return Constants.MAX_ELEMENT_LEVEL + get_max_element_level_bonus()

func get_max_tower_level_bonus() -> int:
	return _max_tower_level_bonus

func get_max_tower_level() -> int:
	return Constants.MAX_LEVEL + get_max_tower_level_bonus()

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
	var reached_max_level: bool = current_level == get_max_element_level()
	var is_able: bool = can_afford && !reached_max_level

	return is_able


func get_player_name() -> String:
	return _player_name


func get_color() -> Color:
	var player_color: Color = PLAYER_COLOR_MAP.get(_id, Color.WHITE)

	return player_color


func get_player_name_with_color() -> String:
	var player_color: Color = get_color()
	var player_name_with_color: String = Utils.get_colored_string(Utils.escape_bbcode(_player_name), player_color)

	return player_name_with_color


func get_id() -> int:
	return _id


func get_peer_id() -> int:
	return _peer_id


func get_user_id() -> String:
	return _user_id


func get_score() -> float:
	return _score


func add_score(amount: float):
	_score += amount


# NOTE: player.getTeam() in JASS
func get_team() -> Team:
	return _team


# NOTE: player.displayFloatingTextX() in JASS
func display_floating_text_x(text: String, unit: Unit, color: Color, velocity: float, fadepoint: float, time: float):
	if self != PlayerManager.get_local_player():
		return
	
	var floating_text = Preloads.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.duration = time
	floating_text.fadepoint = fadepoint
	floating_text.position = unit.get_visual_position()
	floating_text.velocity = Vector2(0, -velocity)
	_floating_text_container.add_child(floating_text)


# NOTE: player.displayFloatingTextX2() in JASS
func display_floating_text_x_2(text: String, unit: Unit, color: Color, velocity: float, fadepoint: float, time: float, _scale: float, random_offset: float):
	if self != PlayerManager.get_local_player():
		return

	var floating_text = Preloads.floating_text_scene.instantiate()
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
	if self != PlayerManager.get_local_player():
		return

	var floating_text = Preloads.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.position = unit.get_visual_position()
	_floating_text_container.add_child(floating_text)


# NOTE: player.displaySmallFloatingText() in JASS
func display_small_floating_text(text: String, unit: Unit, color: Color, random_offset: float):
	if self != PlayerManager.get_local_player():
		return

	var floating_text = Preloads.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.position = unit.get_visual_position()
	floating_text.random_offset = random_offset
	_floating_text_container.add_child(floating_text)


func display_floating_text_at_pos(text: String, pos_wc3: Vector2, color: Color):
	if self != PlayerManager.get_local_player():
		return

	var pos_canvas: Vector2 = VectorUtils.wc3_to_canvas(Vector3(pos_wc3.x, pos_wc3.y, 0))

	var floating_text = Preloads.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.position = pos_canvas
	_floating_text_container.add_child(floating_text)


# NOTE: player.giveGold() in JASS
func give_gold(amount: float, unit: Unit, show_effect: bool, show_text: bool):
	add_gold(amount)

	if show_effect:
		Effect.create_simple_at_unit("res://src/effects/gold_credit.tscn", unit)

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


func spend_tomes(amount: int):
	var new_value: int = _tomes - amount
	_set_tomes(new_value)


func enough_tomes_for_tower(tower_id: int) -> bool:
	var tome_cost: int = TowerProperties.get_tome_cost(tower_id)
	var enough_tomes: bool = tome_cost <= _tomes

	return enough_tomes


func enough_food_for_tower(tower_id: int, preceding_tower_id: int = -1) -> bool:
	var preceding_food_cost: int
	if preceding_tower_id != -1:
		preceding_food_cost = TowerProperties.get_food_cost(preceding_tower_id)
	else:
		preceding_food_cost = 0

	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var food_after_add: int = _food + food_cost - preceding_food_cost
	var enough_food: bool = food_after_add <= _food_cap

	return enough_food


func add_food_for_tower(tower_id: int):
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var new_food: int = _food + food_cost

	if new_food > _food_cap:
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


func get_next_5_waves() -> Array[Wave]:
	var wave_list: Array[Wave] = []
	var current_level: int = get_team().get_level()

	for level in range(current_level, current_level + 6):
		var wave: Wave = _wave_spawner.get_wave(level)

		if wave != null:
			wave_list.append(wave)

	return wave_list


func disable_rolling():
	roll_was_disabled.emit()


# Sets the multiplier for all wisdom upgrade effects. This
# multiplier comes from some builders and for most it is
# simply x1.0.
func set_builder_wisdom_multiplier(value: float):
	_builder_wisdom_multiplier = value


func get_builder_wisdom_multiplier() -> float:
	return _builder_wisdom_multiplier


func set_wisdom_modifier(value: Modifier):
	_wisdom_modifier = value


func get_wisdom_modifier() -> Modifier:
	return _wisdom_modifier


# NOTE: this functionality is split between here and
# SelectUnit class at the moment. Need to figure out how to
# factor it properly, to have correct syncing in multiplayer
# and without sacrificing responsiveness.
# 
# NOTE: this f-n should be called only by ActionSelectUnit
func set_selected_unit(new_selected_unit: Unit):
	var old_selected_unit: Unit = _selected_unit

	if old_selected_unit != null:
		old_selected_unit.tree_exited.disconnect(_on_selected_unit_tree_exited)

	if new_selected_unit != null && !new_selected_unit.tree_exited.is_connected(_on_selected_unit_tree_exited):
		new_selected_unit.tree_exited.connect(_on_selected_unit_tree_exited.bind(new_selected_unit))

	_selected_unit = new_selected_unit


func get_selected_unit() -> Unit:
	return _selected_unit


func roll_starting_towers():
	if _tower_count_for_starting_roll == 0:
		push_error("Cannot roll starting towers because remaining count is 0. Make sure to verify conditions before you call this function.")

		return

	_tower_stash.clear()

	var rolled_towers: Array[int] = TowerDistribution.generate_random_towers_with_count(self, _tower_count_for_starting_roll)
	_tower_stash.add_towers(rolled_towers)
	_add_message_about_rolled_towers(rolled_towers)
	
	_tower_count_for_starting_roll = max(0, _tower_count_for_starting_roll - 1)

	var can_roll_again: bool = _tower_count_for_starting_roll > 0

	if can_roll_again:
		Messages.add_normal(self, tr("MESSAGE_REROLLS_REMAINING").format({REROLL_COUNT = _tower_count_for_starting_roll}))
	else:
		disable_rolling()

	rolled_starting_towers.emit()


func emit_game_lose_signal():
	game_lose.emit()


#########################
###      Private      ###
#########################

func _set_gold(value: float):
	_gold = clampf(value, 0, MAX_GOLD)


func _set_tomes(value):
	_tomes = clampi(value, 0, MAX_KNOWLEDGE_TOMES)


func _add_message_about_rolled_towers(rolled_towers: Array[int]):
	Messages.add_normal(self, tr("MESSAGE_NEW_TOWERS"))

#	Sort tower list by element to group messages for same
#	element together
	rolled_towers.sort_custom(func(a, b): 
		var element_a: int = TowerProperties.get_element(a)
		var element_b: int = TowerProperties.get_element(b)
		return element_a < element_b)

	for tower in rolled_towers:
		var element: Element.enm = TowerProperties.get_element(tower)
		var element_string: String = Element.convert_to_colored_string(element)
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower)
		var rarity_color: Color = Rarity.get_color(rarity)
		var tower_name: String = TowerProperties.get_display_name(tower)
		var tower_name_colored: String = Utils.get_colored_string(tower_name, rarity_color)
		var message: String = "    %s: %s" % [element_string, tower_name_colored]

		Messages.add_normal(self, message)


# NOTE: can't use PlayerManager.get_local_player() in here
# because this f-n is called during the process of creating
# players.
func _determine_player_name() -> String:
	var connection_type: Globals.ConnectionType = Globals.get_connect_type()
	var player_is_local: bool = _peer_id == multiplayer.get_unique_id()

	var player_name: String
	if player_is_local:
		player_name = Settings.get_setting(Settings.PLAYER_NAME)
	else:
		match connection_type:
			Globals.ConnectionType.ENET:
				player_name = Globals.get_player_name_from_peer_id(_peer_id)
			Globals.ConnectionType.NAKAMA:
				player_name = NakamaConnection.get_display_name_of_user(_user_id)

	return player_name


#########################
###     Callbacks     ###
#########################


func _on_wave_spawner_wave_finished(level: int):
	var upkeep: int = floori((20 + level * 2) * _income_rate)
	var current_gold: int = floori(_gold)
	var interest: int = floori(min(current_gold * _interest_rate, INTEREST_GAIN_MAX))
	var income: int = upkeep + interest
	var source_is_income: bool = true
	add_gold(income, source_is_income)

	add_tomes(KNOWLEDGE_TOMES_INCOME)

	_builder.apply_wave_finished_effect(self)

	Messages.add_normal(self, tr("MESSAGE_LEVEL_COMPLETED").format({LEVEL = level}))
	Messages.add_normal(self, tr("MESSAGE_INCOME").format({UPKEEP = upkeep, INTEREST = interest}))

	var game_mode_is_random: bool = Globals.game_mode_is_random()
	if game_mode_is_random:
		var rolled_towers: Array[int] = TowerDistribution.roll_towers(self)
		_tower_stash.add_towers(rolled_towers)
		_add_message_about_rolled_towers(rolled_towers)

#	Warn players if they have too many unspent knowledge
#	tomes.
#	NOTE: stop these warnings are a certain wave level is
#	reached because after a certain point player would have
#	research 2 elements to the max and these warnings would
#	become annoying.
	var current_tomes: int = get_tomes()
	var too_many_tomes: bool = current_tomes >= Constants.TOMES_WARNING_THRESHOLD
	var tome_warnings_are_stopped: bool = level >= Constants.WAVE_LEVEL_AFTER_WHICH_TOME_WARNINGS_STOP
	if too_many_tomes && !tome_warnings_are_stopped:
		Messages.add_normal(self, tr("MESSAGE_UNSPENT_TOMES").format({TOME_COUNT = current_tomes}))

	wave_finished.emit(level)


func _on_wave_spawner_wave_spawned(level: int):
	wave_spawned.emit(level)


# NOTE: Need this slot because "mouse_exited" signal doesn't
# get emitted when units exit the tree because of
# queue_free().
func _on_selected_unit_tree_exited(unit: Unit):
	var selected_unit_is_being_removed: bool = _selected_unit == unit
	if selected_unit_is_being_removed:
		set_selected_unit(null)


# NOTE: either peer_id or user_id has to be defined,
# depending on if connection is Nakama or Enet
static func make(player_id: int, peer_id: int, user_id: String) -> Player:
	var player: Player = Preloads.player_scene.instantiate()
	player._id = player_id
	player._peer_id = peer_id
	player._user_id = user_id

#	Add base class Builder as placeholder until the real
#	builder is assigned. This builder will have no effects.
	var placeholder_builder: Builder = Builder.new()
	player._builder = placeholder_builder
	player.add_child(placeholder_builder)

	return player
