extends Tower


# NOTE: original script multiplies game time delta by 0.04,
# not sure why. It has a comment saying:
# "multply by 0.04 to get seconds"
# but i thought that JASS getGameTime() returns seconds already?
# Whatever, removed the multiplication so that tower deals
# 500dmg per second spent in aura, same as in ability description.


var natac_lich_icy_curse_bt: BuffType
var natac_lich_aura_bt: BuffType
var multiboard: MultiboardValues

var stored_damage: float = 0.0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Icy Curse[/color]\n"
	text += "Curses creeps it damages for 5 seconds, increasing their debuff duration by 30%.\n"
	text += " \n"

	text += "[color=GOLD]King's Authority - Aura[/color]\n"
	text += "The Lich King rules over every creep in 900 range. Every creep leaving this range will be punished with 500 spelldamage for every second it was under this aura's effect.\n"
	text += "If a creep dies in this area of authority, the spelldamage that didn't get dealt is stored. The next creep to then leave the Lich King's area will be punished with [stored damage x 0.5] spelldamage.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+20 damage per second\n"
	text += "+[stored damage x 0.04] spelldamage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Icy Curse[/color]\n"
	text += "Curses creeps it damages, increasing their debuff duration.\n"
	text += " \n"

	text += "[color=GOLD]King's Authority - Aura[/color]\n"
	text += "The Lich King rules over every creep in range. Every creep leaving this range will be punished.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	natac_lich_icy_curse_bt = BuffType.new("natac_lich_icy_curse_bt", 5, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, 0.30, 0.008)
	natac_lich_icy_curse_bt.set_buff_modifier(mod)
	natac_lich_icy_curse_bt.set_buff_icon("@@0@@")
	natac_lich_icy_curse_bt.set_buff_tooltip("Icy Curse\nThis creep was cursed; it has increased debuff duration.")

	natac_lich_aura_bt = BuffType.create_aura_effect_type("natac_lich_aura_bt", false, self)
	natac_lich_aura_bt.set_buff_icon("@@1@@")
	natac_lich_aura_bt.add_event_on_create(natac_lich_aura_bt_on_create)
	natac_lich_aura_bt.add_event_on_refresh(natac_lich_aura_bt_on_refresh)
	natac_lich_aura_bt.add_event_on_cleanup(natac_lich_aura_bt_on_cleanup)
	natac_lich_aura_bt.set_buff_tooltip("King's Authority Aura\nThis creep is under the effect of the King's Authority Aura; it will take damage once it goes too far from the King.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Stored Damage")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 900
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 500
	aura.level_add = 20
	aura.power = 500
	aura.power_add = 20
	aura.aura_effect = natac_lich_aura_bt
	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	natac_lich_icy_curse_bt.apply(tower, target, level)


func on_tower_details() -> MultiboardValues:
	var stored_damage_string: String = Utils.format_float(stored_damage, 0)
	multiboard.set_value(0, stored_damage_string)

	return multiboard


func natac_lich_aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()

	var buff_apply_time: int = int(Utils.get_game_time())
	var max_dps: int = buff.get_level()
	var buff_stored_damage: float = 0.0
	var caster_id: int = caster.get_instance_id()

	buff.user_int = buff_apply_time
	buff.user_int2 = max_dps
	buff.user_int3 = caster_id
	buff.user_real = buff_stored_damage


func natac_lich_aura_bt_on_refresh(event: Event):
	var buff: Buff = event.get_buff()
	var new_dps: int = buff.get_level()
	var old_king_id: int = buff.user_int3
	var old_king: Unit = instance_from_id(old_king_id)
	var new_king: Unit = buff.get_caster()
	var new_king_id: int = new_king.get_instance_id()

	if old_king == null:
		return

	var old_wrath_damage: float = old_king.stored_damage * (0.5 + 0.04 * old_king.get_level())

	old_king.stored_damage = 0.0
	buff.user_int3 = new_king_id

	if new_dps > buff.user_int2:
		buff.user_int2 = new_dps

	if old_wrath_damage > 0.0:
		buff.user_real = buff.user_real + old_wrath_damage


func natac_lich_aura_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var caster: Unit = buff.get_caster()

	var apply_time: int = buff.user_int
	var max_dps: int = buff.user_int2
	var buff_stored_damage: float = buff.user_real

	var damage: float = (Utils.get_game_time() - apply_time) * max_dps
	damage += buff_stored_damage

	if !target.is_dead():
		if caster.stored_damage > 0:
			caster.get_player().display_floating_text("Feel the Wrath!", caster, 15, 15, 200)
			var stored_damage_ratio: float = 0.5 + 0.04 * caster.get_level()
			damage += caster.stored_damage * stored_damage_ratio
			caster.stored_damage = 0.0

		SFX.sfx_at_unit("FrostNovaTarget.mdl", target)
		caster.do_spell_damage(target, damage, caster.calc_spell_crit_no_bonus())
		caster.get_player().display_floating_text(Utils.format_float(damage, 0), caster, 15, 15, 200)
	else:
		caster.stored_damage += damage
		caster.get_player().display_floating_text("+" + Utils.format_float(damage, 0), caster, 15, 15, 200)
