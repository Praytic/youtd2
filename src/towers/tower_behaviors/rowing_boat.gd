extends TowerBehavior


var aura_bt: BuffType
var multiboard: MultiboardValues

const AURA_RANGE: int = 300


func get_tier_stats() -> Dictionary:
	return {
		1: {plunder_amount = 0.3, mod_bounty = 0.10, mod_bounty_add = 0.005},
		2: {plunder_amount = 1.3, mod_bounty = 0.10, mod_bounty_add = 0.010},
		3: {plunder_amount = 2.4, mod_bounty = 0.15, mod_bounty_add = 0.010},
		4: {plunder_amount = 4.0, mod_bounty = 0.20, mod_bounty_add = 0.010},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var plunder_amount: String = Utils.format_float(_stats.plunder_amount, 2)
	
	var list: Array[AbilityInfo] = []
	
	var pirates: AbilityInfo = AbilityInfo.new()
	pirates.name = "Pirates"
	pirates.icon = "res://resources/icons/tower_icons/dutchmans_grave.tres"
	pirates.description_short = "This tower plunders gold each attack.\n"
	pirates.description_full = "This tower plunders %s gold each attack.\n" % plunder_amount
	list.append(pirates)

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
	bounty_mod.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, _stats.mod_bounty, _stats.mod_bounty_add)
	aura_bt.set_buff_modifier(bounty_mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/gold_bar.tres")
	aura_bt.set_buff_tooltip("Treasure Seeker Aura\nIncreases bounty gained.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Gold Plundered")

	
func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var mod_bounty: String = Utils.format_percent(_stats.mod_bounty, 2)
	var mod_bounty_add: String = Utils.format_percent(_stats.mod_bounty_add, 2)

	aura.name = "Treasure Seeker"
	aura.icon = "res://resources/icons/trinkets/trinket_05.tres"
	aura.description_short = "Increases the bounty gain of nearby towers.\n"
	aura.description_full = "Increases the bounty gain of towers in %d range by %s.\n" % [AURA_RANGE, mod_bounty] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s bounty\n" % mod_bounty_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
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
