extends Tower


# Changed original script by adding apply_soul_bonus() to
# get rid of the need to store the soul stats in
# user_real's. Instead, tower will apply changes appropriate
# for it's tier in apply_soul_bonus().


var natac_hall_of_souls_bt: BuffType
var accumulated_soul_damage: float = 0.0


func get_tier_stats() -> Dictionary:
	return {
		1: {soul_damage = 6, soul_damage_add = 0.3, soul_experience = 1},
		2: {soul_damage = 12, soul_damage_add = 0.6, soul_experience = 2},
		3: {soul_damage = 18, soul_damage_add = 0.9, soul_experience = 3},
	}

const AURA_RANGE: float = 1000


func get_extra_tooltip_text() -> String:
	var soul_damage: String = Utils.format_float(_stats.soul_damage, 2)
	var soul_damage_add: String = Utils.format_float(_stats.soul_damage_add, 2)
	var soul_experience: String = Utils.format_float(_stats.soul_experience, 2)
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)

	var text: String = ""

	text += "[color=GOLD]Revenge of Souls[/color]\n"
	text += "This tower gains %s permanent bonus damage and %s experience every time a creep in %s range dies.\n" % [soul_damage, soul_experience, aura_range]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage per kill\n" % soul_damage_add

	return text


func tower_init():
	natac_hall_of_souls_bt = BuffType.create_aura_effect_type("natac_hall_of_souls_bt", false, self)
	natac_hall_of_souls_bt.set_buff_icon("@@0@@")
	natac_hall_of_souls_bt.add_event_on_create(bt_on_create)
	natac_hall_of_souls_bt.add_event_on_death(bt_on_death)

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = natac_hall_of_souls_bt
	add_aura(aura)


# Carry over soul damage from previous tier
func on_create(preceding: Tower):
	var tower: Tower = self
	
	if preceding != null && preceding.get_family() == tower.get_family():
		var soul_bonus: float = preceding.accumulated_soul_damage
		tower.accumulated_soul_damage = soul_bonus
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD, soul_bonus)
	else:
		tower.accumulated_soul_damage = 0.0


func bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var family: int = caster.get_family()
	buff.user_int = family


# Iterate over all Hall of Souls towers in range of killed
# creep and apply bonuses from "Revenge of Souls" ability
func bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_caster(target, TargetType.new(TargetType.TOWERS), 1000)

	SFX.sfx_at_unit("AIsoTarget.mdl", target)

	while true:
		var tower: Unit = it.next()

		if tower == null:
			break

		if tower.get_family() == buff.user_int:
			tower.apply_soul_bonus()


func apply_soul_bonus():
	var tower: Tower = self

	var soul_damage: float = _stats.soul_damage + _stats.soul_damage_add * tower.get_level()
	var soul_experience: float = _stats.soul_experience

	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD, soul_damage)
	tower.add_exp(soul_experience)
	tower.accumulated_soul_damage += soul_damage
