extends Builder


# NOTE: commented out sections relevant to invisibility
# because invisible waves are currently disabled.


func _init():
	_range_bonus = 75


# func _get_tower_buff() -> BuffType:
# 	var farseer_bt: BuffType = MagicalSightBuff.new("farseer_bt", 700, self)

# 	return farseer_bt


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.10, 0.0)

	return mod
