extends Node


# Stores combat log entries. Game code uses log_x() to add a
# log entry and then CombatLogWindow displays log entries
# ingame.

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
	var _type: CombatLog.Type
	var _timestamp: float
	var _string: String

	func _init(type: CombatLog.Type):
		_type = type
		_timestamp = Utils.get_game_time()
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
	var _crit_ratio: float

	func _init(caster: Unit, target: Unit, damage_source: Unit.DamageSource, damage: float, crit_ratio: float):
		super(CombatLog.Type.DAMAGE)

		_caster_name = caster.get_log_name()
		_target_name = target.get_log_name()
		_damage_source = damage_source
		_damage = damage
		_crit_ratio = crit_ratio

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()
		var crit_string: String
		if _crit_ratio > 1.0:
			crit_string = " (Critical)"
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
		super(CombatLog.Type.KILL)

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
		super(CombatLog.Type.BUFF_APPLY)

		_caster_name = caster.get_log_name()
		_target_name = target.get_log_name()
		_buff_name = buff.get_type()

		var timestamp_string: String = get_timestamp_string()
		var type_string: String = get_type_string()

		_string = "%s: %s %s->%s buff=\"%s\"" % [timestamp_string, type_string, _caster_name, _target_name, _buff_name]


class ExpEntry extends Entry:
	var _unit_name: String
	var _experience: float

	func _init(unit: Unit, experience: float):
		super(CombatLog.Type.EXP)

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
		super(CombatLog.Type.ABILITY)

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


class AutocastEntry extends Entry:
	var _caster_name: String
	var _target_name: String
	var _autocast_name: String

	func _init(caster: Unit, target: Unit, autocast: Autocast):
		super(CombatLog.Type.AUTOCAST)

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
		super(CombatLog.Type.ITEM_CHARGE)

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

var _entry_list: Array[Entry] = []


func size() -> int:
	return _entry_list.size()


func get_entry_string(index: int) -> String:
	if index >= _entry_list.size():
		return "out of bounds"

	var entry: CombatLog.Entry = _entry_list[index]
	var entry_string: String = entry.get_string()

	return entry_string


func clear():
	_entry_list.resize(0)


func log_damage(caster: Unit, target: Unit, damage_source: Unit.DamageSource, damage: float, crit_ratio: float):
	var entry: DamageEntry = DamageEntry.new(caster, target, damage_source, damage, crit_ratio)
	_log_internal(entry)


func log_kill(caster: Unit, target: Unit):
	var entry: KillEntry = KillEntry.new(caster, target)
	_log_internal(entry)


func log_experience(unit: Unit, experience: float):
	var entry: ExpEntry = ExpEntry.new(unit, experience)
	_log_internal(entry)


func log_buff_apply(caster: Unit, target: Unit, buff: Buff):
	var entry: BuffApplyEntry = BuffApplyEntry.new(caster, target, buff)
	_log_internal(entry)


# NOTE: this is an optinal log f-n for logging custom tower abilities.
# For example, if you tower has a chance on attack to deal extra damage,
# you may use log_ability() to display this in combat log.
# NOTE: target arg may be null
func log_ability(caster: Unit, target: Unit, ability: String):
	var entry: AbilityEntry = AbilityEntry.new(caster, target, ability)
	_log_internal(entry)


# NOTE: target arg may be null
func log_autocast(caster: Unit, target: Unit, autocast: Autocast):
	var entry: AutocastEntry = AutocastEntry.new(caster, target, autocast)
	_log_internal(entry)


func log_item_charge(item: Item, old_charge: int, new_charge: int):
	var entry: ItemChargeEntry = ItemChargeEntry.new(item, old_charge, new_charge)
	_log_internal(entry)


func _log_internal(entry: Entry):
	_entry_list.insert(0, entry)

#	Delete old entries when list gets too big.
#	We need to limit log length to prevent CombatLog
#	using up too much memory.
	while _entry_list.size() > LOG_SIZE_MAX:
		_entry_list.pop_back()
