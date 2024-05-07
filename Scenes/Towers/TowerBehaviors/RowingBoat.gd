extends TowerBehavior


var aura_bt: BuffType
var multiboard : MultiboardValues

func get_tier_stats() -> Dictionary:
	return {
		1: {plunder_amount = 0.3, aura_power_and_lvl = 5},
		2: {plunder_amount = 1.3, aura_power_and_lvl = 10},
		3: {plunder_amount = 2.4, aura_power_and_lvl = 10},
		4: {plunder_amount = 4.0, aura_power_and_lvl = 10},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var plunder_amount: String = Utils.format_float(_stats.plunder_amount, 2)
	var bounty_level_add: String = Utils.format_percent(_stats.aura_power_and_lvl * 0.001, 2)
	
	var list: Array[AbilityInfo] = []
	
	var pirates: AbilityInfo = AbilityInfo.new()
	pirates.name = "Pirates"
	pirates.icon = "res://Resources/Icons/TowerIcons/Dutchman'sGrave.tres"
	pirates.description_short = "Grants gold on attack.\n"
	pirates.description_full = "This tower plunders %s gold each attack.\n" % plunder_amount
	list.append(pirates)

	var treasure: AbilityInfo = AbilityInfo.new()
	treasure.name = "Treasure Seeker - Aura"
	treasure.icon = "res://Resources/Icons/ItemIcons/golden_decoration.tres"
	treasure.description_short = "Increases the bounty gain of nearby towers.\n"
	treasure.description_full = "Increases the bounty gain of towers in 300 range by 10%.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s bounty\n" % bounty_level_add
	list.append(treasure)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(_modifier: Modifier):
	tower.set_attack_ground_only()
	tower.set_attack_style_splash({
		25: 1.0,
		150: 0.4,
		250: 0.1,
		})


func tower_init():
	var bounty_mod: Modifier = Modifier.new()
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
#	Set by aura
	bounty_mod.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.0, 0.001)
	aura_bt.set_buff_modifier(bounty_mod)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/gold_bar.tres")
	aura_bt.set_buff_tooltip("Treasure Seeker Aura\nIncreases bounty gained.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Gold Plundered")

	
func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 300
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 100
	aura.level_add = _stats.aura_power_and_lvl
	aura.power = 100
	aura.power_add = _stats.aura_power_and_lvl
	aura.aura_effect = aura_bt
	return [aura]


func on_attack(_event: Event):
# 	The gold, that will be granted to the player on this attack 
	var gold_granted: float = _stats.plunder_amount
#	Set the statistics
	tower.user_real = tower.user_real + gold_granted
	tower.get_player().give_gold(gold_granted, tower, false, true)


func on_create(preceding_tower: Tower):
	var parent: Tower = preceding_tower

# 	Total gold, earned by this towers pirates ability 
	if parent != null && parent.get_family() == tower.get_family():
		tower.user_real = parent.user_real
	else:
		tower.user_real = 0


func on_tower_details() -> MultiboardValues:
	var gold_plundered_text: String = Utils.format_float(tower.user_real, 2)
	multiboard.set_value(0, gold_plundered_text)
	
	return multiboard
