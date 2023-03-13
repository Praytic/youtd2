extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {armor_ignored = 0.1, armor_ignored_add = 0.004},
		2: {armor_ignored = 0.2, armor_ignored_add = 0.008},
		3: {armor_ignored = 0.3, armor_ignored_add = 0.012},
		4: {armor_ignored = 0.4, armor_ignored_add = 0.016},
	}


func _tower_init():
	var triggers_buff: Buff = TriggersBuff.new()
	triggers_buff.add_event_on_damage(self, "on_damage", 1.0, 0.0)
	triggers_buff.apply_to_unit_permanent(self, self, 0)


func on_damage(event: Event):
	var tower: Tower = self

	var cur_ratio: float = _stats.armor_ignored + _stats.armor_ignored_add * tower.get_level()
	var s_dmg: float = event.damage
	var damage_base: float = event.damage
	var target: Mob = event.get_target() as Mob
	var temp: float = AttackType.get_damage_against(AttackType.enm.PHYSICAL, target.get_armor_type())

#	ignoring armor type "resistance" not weakness :P
	if temp > 0.0 && temp < 1.0:
		damage_base = damage_base / temp

	temp = (1 - target.get_current_armor_damage_reduction())
	if temp > 0.0:
		damage_base = damage_base / temp

	if s_dmg < damage_base:
		event.damage = damage_base * cur_ratio + s_dmg * (1.0 - cur_ratio)

	# The engine calculates critical strike extra damage ***AFTER*** the onDamage event, so there is no need to care about it in this trigger.
