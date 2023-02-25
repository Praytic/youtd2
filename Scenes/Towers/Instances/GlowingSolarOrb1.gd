extends Tower

# TODO: implement visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {splash_125_damage = 0.45, splash_225_damage = 0.15, armor_decrease = 2},
		2: {splash_125_damage = 0.45, splash_225_damage = 0.20, armor_decrease = 3},
		3: {splash_125_damage = 0.50, splash_225_damage = 0.25, armor_decrease = 5},
		4: {splash_125_damage = 0.50, splash_225_damage = 0.30, armor_decrease = 7},
		5: {splash_125_damage = 0.55, splash_225_damage = 0.35, armor_decrease = 10},
	}


func _ready():
	var splash_map: Dictionary = {
		125: _stats.splash_125_damage,
		225: _stats.splash_225_damage,
	}
	_set_attack_style_splash(splash_map)

	var dmg_to_undead_modifier: Modifier = Modifier.new()
	dmg_to_undead_modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.15, 0.0)
	add_modifier(dmg_to_undead_modifier)

	var on_damage_buff: Buff = TriggersBuff.new()
	on_damage_buff.add_event_on_damage(self, "_on_damage", 1.0, 0.0)
	on_damage_buff.apply_to_unit_permanent(self, self, 0)


func _on_damage(event: Event):
	var tower = self

	var armor: Modifier = Modifier.new()
	armor.add_modification(Modification.Type.MOD_ARMOR, 0, -1)
	var cassim_armor: Buff = Buff.new("cassim_armor", 0, 0, false)
	cassim_armor.set_buff_icon("@@0@@")
	cassim_armor.set_buff_modifier(armor)
	cassim_armor.set_stacking_group("astral_armor")

	var lvl: int = tower.get_level()
	var creep: Unit = event.get_target()
	var size_factor: float = 1.0

	if creep.get_size() == Mob.Size.BOSS:
		size_factor = 2.0

	if tower.calc_chance((0.05 + lvl * 0.006) * size_factor):
		cassim_armor.apply_custom_timed(tower, creep, _stats.armor_decrease, 5 + lvl * 0.25)
