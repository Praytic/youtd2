extends Tower


var sir_stormcoil_surge_bt: BuffType
var sir_stormcoil_slow_bt: BuffType
var sir_stormcoil_aura_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Overload[/color]\n"
	text += "On attack this tower deals [distance to the target x 12] energy damage, modified by its attack damage and slows the target for 1.5 seconds. The further away the target is, the more it will be slowed down. The maximum slow of 30% can only be reached, if the target has the maximum distance to the tower.\n"
	text += " \n"

	text += "[color=GOLD]Energetic Field - Aura[/color]\n"
	text += "Units in 1000 range around this tower are dealt up to 20% bonus damage by Storm towers. The further away creeps are from tower, the more damage is dealt.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% maximum damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Overload[/color]\n"
	text += "On attack this tower deals energy damage and slows. Effect is stronger for creeps far away\n"
	text += " \n"

	text += "[color=GOLD]Energetic Field - Aura[/color]\n"
	text += "Units in range receive extra damage from Storm towers. Effect is stronger for creeps far away.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "This tower creates a magnetic surge at its target's current location. The creep will suffer spell damage equal to 4 times the distance to the spot where the surge was created every 0.4 seconds. This effect lasts 4 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% spell damage\n"
	text += "+0.1 seconds duration\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "This tower creates a magnetic surge at its target's current location. Target will take periodic damage.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	sir_stormcoil_slow_bt = BuffType.new("sir_stormcoil_slow_bt", 0, 0, false, self)
	var sir_stormcoil_slow_bt_mod: Modifier = Modifier.new()
	sir_stormcoil_slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.0001)
	sir_stormcoil_slow_bt.set_buff_modifier(sir_stormcoil_slow_bt_mod)
	sir_stormcoil_slow_bt.set_buff_icon("@@1@@")
	sir_stormcoil_slow_bt.set_buff_tooltip("Overload\nThis unit has reduced movement speed.")

	sir_stormcoil_surge_bt = BuffType.new("sir_stormcoil_surge_bt", 5, 0, true, self)
	sir_stormcoil_surge_bt.set_buff_icon("@@0@@")
	sir_stormcoil_surge_bt.add_periodic_event(sir_stormcoil_surge_bt_periodic, 0.4)
	sir_stormcoil_surge_bt.set_buff_tooltip("Magnetic Surge\nThis unit is taking periodic damage.")

	sir_stormcoil_aura_bt = BuffType.create_aura_effect_type("sir_stormcoil_aura_bt", false, self)
	sir_stormcoil_aura_bt.set_buff_icon("@@2@@")
	sir_stormcoil_aura_bt.add_event_on_damaged(sir_stormcoil_aura_bt_on_damaged)
	sir_stormcoil_aura_bt.set_buff_tooltip("Energetic Field Aura\nThis unit receives extra damage from Storm towers.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Magnetic Surge"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 4
	autocast.mana_cost = 40
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 1000
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 0
	aura.power = 0
	aura.power_add = 0
	aura.aura_effect = sir_stormcoil_aura_bt

	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var distance_to_target: float = Isometric.vector_distance_to(tower.position, target.position)
	var damage: float = distance_to_target * 12.0 * tower.get_current_attack_damage_with_bonus() / tower.get_base_damage()

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())
	tower.get_player().display_floating_text_x(str(int(damage)), target, 255, 200, 0, 255, 0.05, 0.0, 2.0)

	var slow_power: int = int(distance_to_target * 3)
	sir_stormcoil_slow_bt.apply_advanced(tower, target, 0, slow_power, 1.5)


func on_autocast(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var duration: float = 4.0 + 0.1 * tower.get_level()

	var buff: Buff = sir_stormcoil_surge_bt.apply_advanced(tower, creep, 0, 0, duration)
	buff.user_real = creep.get_x()
	buff.user_real2 = creep.get_y()


func sir_stormcoil_surge_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var tower: Tower = buff.get_caster()
	var surge_pos: Vector2 = Vector2(buff.user_real, buff.user_real2)
	var distance_to_target: float = Isometric.vector_distance_to(surge_pos, target.position)
	var damage: float = 4 * distance_to_target * (1 + 0.02 * tower.get_level())

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	tower.get_player().display_floating_text_x(str(int(damage)), target, 150, 150, 255, 255, 0.05, 0.0, 2.0)
	SFX.sfx_at_unit("AIlbSpecialArt.mdl", target)


func sir_stormcoil_aura_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var distance_to_target: float = Isometric.vector_distance_to(tower.position, target.position)
	var damage_multiplier: float = 1.0 + distance_to_target * (0.00020 + 0.000006 * tower.get_level())
	var attacking_tower: Tower = event.get_target()
	var attacking_element: Element.enm = attacking_tower.get_element()

	if attacking_element == Element.enm.STORM:
		event.damage *= damage_multiplier
