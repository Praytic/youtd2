extends Tower


var natac_treasureSeeker_Buff: BuffType
var natac_pirates_MultiboardValue : MultiboardValues

func get_tier_stats() -> Dictionary:
	return {
		1: {plunder_amount = 0.3, aura_power_and_lvl = 5},
		2: {plunder_amount = 1.3, aura_power_and_lvl = 10},
		3: {plunder_amount = 2.4, aura_power_and_lvl = 10},
		4: {plunder_amount = 4.0, aura_power_and_lvl = 10},
	}


func get_extra_tooltip_text() -> String:
	var plunder_amount: String = Utils.format_float(_stats.plunder_amount, 2)
	var bounty_level_add: String = Utils.format_percent(_stats.aura_power_and_lvl * 0.001, 2)

	var text: String = ""

	text += "[color=GOLD]Pirates[/color]\n"
	text += "This tower plunders %s gold each attack.\n" % plunder_amount
	text += " \n"
	text += "[color=GOLD]Treasure Seeker - Aura[/color]\n"
	text += "Increases the bounty gain of towers in 300 range by 10%%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s bounty\n" % bounty_level_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(_modifier: Modifier):
	_set_attack_ground_only()
	_set_attack_style_splash({
		25: 1.0,
		150: 0.4,
		250: 0.1,
		})


func tower_init():
	var bounty_mod: Modifier = Modifier.new()
	natac_treasureSeeker_Buff = BuffType.create_aura_effect_type("natac_treasureSeeker_Buff", true, self)
#	Set by aura
	bounty_mod.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.0, 0.001)
	natac_treasureSeeker_Buff.set_buff_modifier(bounty_mod)
	natac_treasureSeeker_Buff.set_buff_icon("@@0@@")
	natac_treasureSeeker_Buff.set_buff_tooltip("Treasure Seeker Aura\nThis unit is under the effect of Treasure Seeker Aura; it will receive extra bounty.")

	natac_pirates_MultiboardValue = MultiboardValues.new(1)
	natac_pirates_MultiboardValue.set_key(0, "Gold Plundered")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 300
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 100
	aura.level_add = _stats.aura_power_and_lvl
	aura.power = 100
	aura.power_add = _stats.aura_power_and_lvl
	aura.aura_effect = natac_treasureSeeker_Buff
	add_aura(aura)


func on_attack(_event: Event):
	var tower: Tower = self

# 	The gold, that will be granted to the player on this attack 
	var gold_granted: float = _stats.plunder_amount
#	Set the statistics
	tower.user_real = tower.user_real + gold_granted
	tower.getOwner().give_gold(gold_granted, tower, false, true)


func on_create(preceding_tower: Tower):
	var tower: Tower = self
	var parent: Tower = preceding_tower

# 	Total gold, earned by this towers pirates ability 
	if parent != null && parent.get_family() == tower.get_family():
		tower.user_real = parent.user_real
	else:
		tower.user_real = 0


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
#	Show total gold, stolen by this tower pirates ability
	natac_pirates_MultiboardValue.set_value(0, str(tower.user_real))
	return natac_pirates_MultiboardValue
