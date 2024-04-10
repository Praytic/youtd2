class_name ActionSelectWisdomUpgrades



static func make(wisdom_upgrades: Dictionary) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELECT_WISDOM_UPGRADES,
		Action.Field.WISDOM_UPGRADES: wisdom_upgrades,
		})

	return action


# TODO: validate upgrade config. For example, sum up how
# many orbs are used on upgrades and check that it's equal
# or less than player's orb count. Also check for negative
# values.
static func execute(action: Dictionary, player: Player):
	var wisdom_upgrades: Dictionary = action[Action.Field.WISDOM_UPGRADES]

	var wisdom_modifier: Modifier = ActionSelectWisdomUpgrades.generate_wisdom_upgrades_modifier(wisdom_upgrades)
	player.set_wisdom_modifier(wisdom_modifier)

	var bonus_tomes: int = 5 * wisdom_upgrades[WisdomUpgradeProperties.Id.ELEMENT_MASTERY]
	player.add_tomes(bonus_tomes)

	var bonus_food_cap: int = 2 * wisdom_upgrades[WisdomUpgradeProperties.Id.MASTERY_OF_LOGISTICS]
	player.modify_food_cap(bonus_food_cap)


static func generate_wisdom_upgrades_modifier(wisdom_upgrades: Dictionary) -> Modifier:
	var modifier: Modifier = Modifier.new()
	
	var trigger_chances: float = 0.013 * wisdom_upgrades[WisdomUpgradeProperties.Id.ADVANCED_FORTUNE]
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, trigger_chances, 0)

	var attackspeed: float = 0.0085 * wisdom_upgrades[WisdomUpgradeProperties.Id.SWIFTNESS_MASTERY]
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, attackspeed, 0)

	var mod_dmg_base: float = 0.01 * wisdom_upgrades[WisdomUpgradeProperties.Id.COMBAT_MASTERY]
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, mod_dmg_base, 0)

	var crit_chance: float = 0.005 * wisdom_upgrades[WisdomUpgradeProperties.Id.MASTERY_OF_PAIN]
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, crit_chance, 0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, crit_chance, 0)

	var mod_spell_dmg: float = 0.0125 * wisdom_upgrades[WisdomUpgradeProperties.Id.ADVANCED_SORCERY]
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, mod_spell_dmg, 0)

	var mod_mana_and_mana_regen: float = 0.025 * wisdom_upgrades[WisdomUpgradeProperties.Id.MASTERY_OF_MAGIC]
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, mod_mana_and_mana_regen, 0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, mod_mana_and_mana_regen, 0)

	var mod_item_chance: float = 0.015 * wisdom_upgrades[WisdomUpgradeProperties.Id.LOOT_MASTERY]
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, mod_item_chance, 0)

	var mod_exp_gain: float = 0.025 * wisdom_upgrades[WisdomUpgradeProperties.Id.ADVANCED_WISDOM]
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, mod_exp_gain, 0)

	return modifier
