class_name ActionSelectWisdomUpgrades



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
	
	if wisdom_upgrades[WisdomUpgradeProperties.Id.ADVANCED_FORTUNE]:
		modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.10, 0)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.SWIFTNESS_MASTERY]:
		modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.07, 0)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.COMBAT_MASTERY]:
		modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.08, 0)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.MASTERY_OF_PAIN]:
		modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.04, 0)
		modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.04, 0)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.ADVANCED_SORCERY]:
		modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.10, 0)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.MASTERY_OF_MAGIC]:
		modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.20, 0)
		modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.20, 0)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.LOOT_MASTERY]:
		modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.12, 0)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.ADVANCED_WISDOM]:
		modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.20, 0)

	return modifier
