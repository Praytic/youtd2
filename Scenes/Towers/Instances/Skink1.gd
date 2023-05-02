extends Tower


var cedi_skinkA: BuffType
var cedi_skinkB: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {dmg = 3, dmg_add = 0.12},
		2: {dmg = 10, dmg_add = 0.4},
		3: {dmg = 30, dmg_add = 1.2},
		4: {dmg = 76.5, dmg_add = 3.06},
		5: {dmg = 127.5, dmg_add = 5.1},
	}


func get_extra_tooltip_text() -> String:
	var dmg: String = String.num(_stats.dmg, 2)
	var dmg_add: String = String.num(_stats.dmg_add, 2)

	var text: String = ""

	text += "[color=GOLD]Poisonous Skin - Aura[/color]\n"
	text += "This and any towers in 200 range gain a poisonous attack. The poison deals %s spell damage per second for 5 seconds. The effect stacks and is attack speed and range adjusted.\n" % dmg
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage per second" % dmg_add

	return text


func poisenskin(event: Event):
	var B: Buff = event.get_buff()

	var C: Tower = B.get_caster()
	var T: Tower = B.get_buffed_unit()
	var U: Unit = event.get_target()
	var P: Buff = U.get_buff_of_type(cedi_skinkB)
	var dmg: float = (C.user_real + C.user_real2 * C.get_level()) * T.get_current_attack_speed() / (T.get_range() / 800.0)

	if P != null:
		if P.get_caster().get_uid() == P.user_int:
			P.refresh_duration()
			P.user_real = P.user_real + dmg
		else:
			dmg = P.user_real + dmg
			P.remove_buff()
			P = cedi_skinkB.apply(C, U, C.get_level())
			P.user_int = C.get_uid()
			P.user_real = dmg
	else:
		P = cedi_skinkB.apply(C, U, C.get_level())
		P.user_int = C.get_uid()
		P.user_real = dmg


func dot(event: Event):
	var B: Buff = event.get_buff()

	var T: Tower = B.get_caster()
	T.do_spell_damage(B.get_buffed_unit(), B.user_real, T.calc_spell_crit_no_bonus())
	var effect: int = Effect.add_special_effect_target("Abilities\\Spells\\NightElf\\CorrosiveBreath\\ChimaeraAcidTargetArt.mdl", T, "head")
	Effect.destroy_effect(effect)


func tower_init():
	cedi_skinkA = BuffType.create_aura_effect_type("cedi_skinkA", true)
	cedi_skinkA.set_buff_icon("@@0@@")
	cedi_skinkA.add_event_on_attack(poisenskin, 1.0, 0.0)
	cedi_skinkA.set_buff_tooltip("Poisonous attack\nThis tower's attack has been enhanced with poison, it will deal extra damage over time.")

	cedi_skinkB = BuffType.new("cedi_skinkB", 5.00, 0.0, false)
	cedi_skinkB.set_buff_icon("@@1@@")
	cedi_skinkB.add_periodic_event(dot, 1.0)
	cedi_skinkB.set_buff_tooltip("Poison\nThis unit is poisoned and is suffering damage over time.")

	var aura: AuraType = AuraType.new()
	aura.power_add = 1
	aura.level_add = 1
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.level = 0
	aura.aura_effect = cedi_skinkA
	aura.power = 0
	aura.target_self = true
	aura.aura_range = 200

	add_aura(aura)


func on_create(_preceding_tower: Tower):
	var tower: Tower = self

	tower.user_real = _stats.dmg
	tower.user_real2 = _stats.dmg_add
