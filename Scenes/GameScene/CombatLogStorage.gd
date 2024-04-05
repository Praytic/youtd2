class_name CombatLogStorage extends Node


# Stores combat log entries. Use CombatLog autoload to access this globally.

# NOTE: log entries cannot store references to game objects
# because log entries need to be usable after game objects
# are removed from the game. That's why log entries save
# string names.


enum Type {
	DAMAGE,
	BUFF_APPLY,
	KILL,
	EXP,
	ABILITY,
	AUTOCAST,
	ITEM_CHARGE,
}

class Entry:
	var _type: CombatLogStorage.Type
	var _timestamp: float
	var _string: String

	func _init(type: CombatLogStorage.Type):
		_type = type
		_timestamp = Utils.get_time()
		_string = "default log entry string"


	func get_string() -> String:
		return _string


	func get_timestamp_string() -> String:
		return "[color=GOLD]%s[/color]" % Utils.format_float(_timestamp, 2)


	func get_type_string() -> String:
		match _type:
			Type.DAMAGE: return "DAMAGE"
			Type.KILL: return "KILL"
			Type.BUFF_APPLY: return "BUFF_APPLY"
			Type.EXP: return "EXP"
			Type.ABILITY: return "ABILITY"
			Type.AUTOCAST: return "AUTOCAST"
			Type.ITEM_CHARGE: return "ITEM_CHARGE"

		return "unknown event type"



class DamageEntry extends Entry:
	var _caster_name: String
	var _target_name: String
	var _damage_source: Unit.DamageSource
	var _damage: float
	var _crit_count: int

	func _init(caster: Unit, target: Unit, damage_source: Unit.DamageSource, damage: float, crit_count: int):
		super(CombatLogStorage.Type.DAMAGE)

		_caster_name = caster.get_log_name()
		_target_name = target.get_log_name()
		_damage_source = damage_source
		_damage = damage
		_crit_count = crit_count

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()
		var crit_string: String = ""
		if crit_count > 0:
			for i in range(0, crit_count):
				crit_string += "!"
		else:
			crit_string = ""
		var damage_color: Color
		match damage_source:
			Unit.DamageSource.Attack: damage_color = Color.RED
			Unit.DamageSource.Spell: damage_color = Color.LIGHT_BLUE
		var damage_string: String = Utils.get_colored_string(Utils.format_float(_damage, 0), damage_color)

		_string = "%s: %s %s->%s [color=RED]%s %s[/color]" % [timestamp_string, type_string, _caster_name, _target_name, damage_string, crit_string]


class KillEntry extends Entry:
	var _caster_name: String
	var _target_name: String

	func _init(caster: Unit, target: Unit):
		super(CombatLogStorage.Type.KILL)

		_caster_name = caster.get_log_name()
		_target_name = target.get_log_name()

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()

		_string = "%s: %s %s->%s" % [timestamp_string, type_string, _caster_name, _target_name]


class BuffApplyEntry extends Entry:
	var _caster_name: String
	var _target_name: String
	var _buff_name: String

	func _init(caster: Unit, target: Unit, buff: Buff):
		super(CombatLogStorage.Type.BUFF_APPLY)

		_caster_name = caster.get_log_name()
		_target_name = target.get_log_name()
		_buff_name = buff.get_buff_type_name()

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()

		_string = "%s: %s %s->%s buff=\"%s\"" % [timestamp_string, type_string, _caster_name, _target_name, _buff_name]


class ExpEntry extends Entry:
	var _unit_name: String
	var _experience: float

	func _init(unit: Unit, experience: float):
		super(CombatLogStorage.Type.EXP)

		_unit_name = unit.get_log_name()
		_experience = experience

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()

		var exp_color: Color
		if experience >= 0.0:
			exp_color = Color.GREEN
		else:
			exp_color = Color.RED
		var exp_string: String = Utils.format_float(experience, 1)
		if experience >= 0.0:
			exp_string = "+" + exp_string
		exp_string = Utils.get_colored_string(exp_string, exp_color)

		_string = "%s: %s %s %s" % [timestamp_string, type_string, _unit_name, exp_string]


class AbilityEntry extends Entry:
	var _caster_name: String
	var _target_name: String
	var _ability: String

	func _init(caster: Unit, target: Unit, ability: String):
		super(CombatLogStorage.Type.ABILITY)

		_caster_name = caster.get_log_name()
		if target != null:
			_target_name = target.get_log_name()
		else:
			_target_name = ""
		_ability = ability

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()
		var ability_string: String = "[color=LIGHT_BLUE]\"%s\"[/color]" % ability

		if target != null:
			_string = "%s: %s %s->%s %s" % [timestamp_string, type_string, _caster_name, _target_name, ability_string]
		else:
			_string = "%s: %s %s %s" % [timestamp_string, type_string, _caster_name, ability_string]


class ItemAbilityEntry extends Entry:
	var _carrier_name: String
	var _item_name: String
	var _target_name: String
	var _ability: String

	func _init(item: Item, target: Unit, ability: String):
		super(CombatLogStorage.Type.ABILITY)

		var carrier: Unit = item.get_carrier()
		_carrier_name = carrier.get_log_name()
		_item_name = item.get_display_name()
		if target != null:
			_target_name = target.get_log_name()
		else:
			_target_name = ""
		_ability = ability

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()
		var carrier_string: String = "[color=GREEN]\"%s\"[/color]" % _carrier_name
		var item_string: String = "[color=ORANGE]\"%s\"[/color]" % _item_name
		var ability_string: String = "[color=LIGHT_BLUE]\"%s\"[/color]" % ability

		if target != null:
			_string = "%s: %s %s %s->%s %s" % [timestamp_string, type_string, carrier_string, item_string, _target_name, ability_string]
		else:
			_string = "%s: %s %s %s %s" % [timestamp_string, type_string, carrier_string, item_string, ability_string]


class AutocastEntry extends Entry:
	var _caster_name: String
	var _target_name: String
	var _autocast_name: String

	func _init(caster: Unit, target: Unit, autocast: Autocast):
		super(CombatLogStorage.Type.AUTOCAST)

		_caster_name = caster.get_log_name()
		if target != null:
			_target_name = target.get_log_name()
		else:
			_target_name = ""
		_autocast_name = autocast.title

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()
		var autocast_name_string: String = "[color=LIGHT_BLUE]\"%s\"[/color]" % _autocast_name

		if target != null:
			_string = "%s: %s %s->%s %s" % [timestamp_string, type_string, _caster_name, _target_name, autocast_name_string]
		else:
			_string = "%s: %s %s %s" % [timestamp_string, type_string, _caster_name, autocast_name_string]


class ItemChargeEntry extends Entry:
	var _carrier_name: String
	var _item_name: String
	var _old_charge: int
	var _new_charge: int

	func _init(item: Item, old_charge: int, new_charge: int):
		super(CombatLogStorage.Type.ITEM_CHARGE)

		var carrier: Unit = item.get_carrier()
		if carrier != null:
			_carrier_name = carrier.get_log_name()
		else:
			_carrier_name = "null"
		_item_name = ItemProperties.get_display_name(item.get_id())
		_item_name = Utils.get_colored_string(_item_name, Color.LIGHT_BLUE)
		_old_charge = old_charge
		_new_charge = new_charge

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()

		var change_color: Color
		if new_charge > old_charge:
			change_color = Color.GREEN
		else:
			change_color = Color.RED
		var change_string: String = "%d->%d" % [old_charge, new_charge]
		change_string = Utils.get_colored_string(change_string, change_color)

		_string = "%s: %s %s item=\"%s\" %s" % [timestamp_string, type_string, _carrier_name, _item_name, change_string]


const LOG_SIZE_MAX: int = 1000

var _entry_map: Dictionary = {}
var _min_index: int = 0
var _max_index: int = 0


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.player_requested_to_clear_combatlog.connect(_on_player_requested_to_clear_combatlog)

#########################
###       Public      ###
#########################

func add_entry(entry: Entry):
	var new_index: int = _max_index
	_max_index += 1

	_entry_map[new_index] = entry

#	Delete old entries when list gets too big.
#	We need to limit log length to prevent CombatLog
#	using up too much memory.
	if _max_index > LOG_SIZE_MAX:
		_entry_map.erase(_min_index)
		_min_index += 1


func get_min_index() -> int:
	return _min_index


func get_max_index() -> int:
	return _max_index


func get_entry_string(index: int) -> String:
	if _entry_map.is_empty() || _min_index > index || index >= _max_index:
		return ""

	var entry: CombatLogStorage.Entry = _entry_map[index]
	var entry_string: String = entry.get_string()

	return entry_string

#########################
###     Callbacks     ###
#########################

func _on_player_requested_to_clear_combatlog():
	_min_index = _max_index
	_entry_map.clear()
