class_name ActionSelectWisdomUpgrades



# NOTE: wisdom_upgrades must be a map of
# {upgrade_id => boolean}
# where boolean is TRUE if upgrade_id is enabled
static func make(wisdom_upgrades: Dictionary) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELECT_WISDOM_UPGRADES,
		Action.Field.WISDOM_UPGRADES: wisdom_upgrades,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var wisdom_upgrades: Dictionary = action[Action.Field.WISDOM_UPGRADES]

	var wisdom_modifier: Modifier = ActionSelectWisdomUpgrades.generate_wisdom_upgrades_modifier(wisdom_upgrades)
	player.set_wisdom_modifier(wisdom_modifier)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.ELEMENT_MASTERY]:
		player.add_tomes(40)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.MASTERY_OF_LOGISTICS]:
		player.modify_food_cap(16)


static func generate_wisdom_upgrades_modifier(wisdom_upgrades: Dictionary) -> Modifier:
	var modifier: Modifier = Modifier.new()

	var upgrade_to_mod_value_map: Dictionary = {
		WisdomUpgradeProperties.Id.ADVANCED_FORTUNE: {
			Modification.Type.MOD_TRIGGER_CHANCES: 0.10,
		},
		WisdomUpgradeProperties.Id.SWIFTNESS_MASTERY: {
			Modification.Type.MOD_ATTACKSPEED: 0.07,
		},
		WisdomUpgradeProperties.Id.COMBAT_MASTERY: {
			Modification.Type.MOD_DAMAGE_BASE_PERC: 0.08,
		},
		WisdomUpgradeProperties.Id.MASTERY_OF_PAIN: {
			Modification.Type.MOD_ATK_CRIT_CHANCE: 0.04,
			Modification.Type.MOD_SPELL_CRIT_CHANCE: 0.04,
		},
		WisdomUpgradeProperties.Id.ADVANCED_SORCERY: {
			Modification.Type.MOD_SPELL_DAMAGE_DEALT: 0.10,
		},
		WisdomUpgradeProperties.Id.MASTERY_OF_MAGIC: {
			Modification.Type.MOD_MANA_PERC: 0.20,
			Modification.Type.MOD_MANA_REGEN_PERC: 0.20,
		},
		WisdomUpgradeProperties.Id.LOOT_MASTERY: {
			Modification.Type.MOD_ITEM_CHANCE_ON_KILL: 0.12,
		},
		WisdomUpgradeProperties.Id.ADVANCED_WISDOM: {
			Modification.Type.MOD_EXP_RECEIVED: 0.20,
		},
	}
	
	for upgrade_id in wisdom_upgrades.keys():
		var upgrade_is_enabled: bool = wisdom_upgrades[upgrade_id] == true

		if !upgrade_is_enabled:
			continue

		var mod_values: Dictionary = upgrade_to_mod_value_map.get(upgrade_id, {})

		for mod_type in mod_values.keys():
			var mod_value: float = mod_values[mod_type]

			modifier.add_modification(mod_type, mod_value, 0)

	return modifier
