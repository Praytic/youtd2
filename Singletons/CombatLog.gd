extends Node


# Global access to CombatLogStorage node. Game code uses
# log_x() to add a log entry and then CombatLogWindow
# displays log entries ingame.


#########################
###       Public      ###
#########################

func log_damage(caster: Unit, target: Unit, damage_source: Unit.DamageSource, damage: float, crit_count: int):
	var entry: CombatLogStorage.DamageEntry = CombatLogStorage.DamageEntry.new(caster, target, damage_source, damage, crit_count)
	_log_internal(entry)


func log_kill(caster: Unit, target: Unit):
	var entry: CombatLogStorage.KillEntry = CombatLogStorage.KillEntry.new(caster, target)
	_log_internal(entry)


func log_experience(unit: Unit, experience: float):
	var entry: CombatLogStorage.ExpEntry = CombatLogStorage.ExpEntry.new(unit, experience)
	_log_internal(entry)


func log_buff_apply(caster: Unit, target: Unit, buff: Buff):
	var entry: CombatLogStorage.BuffApplyEntry = CombatLogStorage.BuffApplyEntry.new(caster, target, buff)
	_log_internal(entry)


# NOTE: this is an optinal log f-n for logging custom tower abilities.
# For example, if you tower has a chance on attack to deal extra damage,
# you may use log_ability() to display this in combat log.
# NOTE: target arg may be null
func log_ability(caster: Unit, target: Unit, ability: String):
	var entry: CombatLogStorage.AbilityEntry = CombatLogStorage.AbilityEntry.new(caster, target, ability)
	_log_internal(entry)


# NOTE: target arg may be null
func log_item_ability(item: Item, target: Unit, ability: String):
	var entry: CombatLogStorage.ItemAbilityEntry = CombatLogStorage.ItemAbilityEntry.new(item, target, ability)
	_log_internal(entry)


# NOTE: target arg may be null
func log_autocast(caster: Unit, target: Unit, autocast: Autocast):
	var entry: CombatLogStorage.AutocastEntry = CombatLogStorage.AutocastEntry.new(caster, target, autocast)
	_log_internal(entry)


func log_item_charge(item: Item, old_charge: int, new_charge: int):
	var entry: CombatLogStorage.ItemChargeEntry = CombatLogStorage.ItemChargeEntry.new(item, old_charge, new_charge)
	_log_internal(entry)


#########################
###      Private      ###
#########################

func _log_internal(entry: CombatLogStorage.Entry):
	var combat_log_storage: Node = get_tree().get_root().get_node_or_null("GameScene/Gameplay/CombatLogStorage")

	if combat_log_storage == null:
		push_warning("CombatLogStorage is null. You can ignore this warning during game restart.")

		return

	combat_log_storage.add_entry(entry)
