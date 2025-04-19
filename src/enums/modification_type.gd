class_name ModificationType extends Node


enum enm {
#	-----------------------
#	Tower modifications
#	-----------------------
#	Modifications below only make sense when applied to
#	towers

#	"Damage to X creep size" modifications
	MOD_DMG_TO_MASS,
	MOD_DMG_TO_NORMAL,
	MOD_DMG_TO_CHAMPION,
	MOD_DMG_TO_BOSS,
	MOD_DMG_TO_AIR,

#	"Damage to X creep race" modifications
	MOD_DMG_TO_UNDEAD,
	MOD_DMG_TO_MAGIC,
	MOD_DMG_TO_NATURE,
	MOD_DMG_TO_ORC,
	MOD_DMG_TO_HUMANOID,
	MOD_DMG_TO_CHALLENGE,

# 	Crit modifications

#	Modifies the chance that attacks of this unit will be
#	critical
#	+0.01 = +1% crit chance
# 	Note that initial value is equal to
# 	Constants.INNATE_MOD_ATK_CRIT_CHANCE
	MOD_ATK_CRIT_CHANCE,

#	Modifies the multiplier applied to critical attack
#	damage.
#	+0.01 = +1% crit damage
# 	Note that initial value is equal to
# 	Constants.INNATE_MOD_ATK_CRIT_DAMAGE
	MOD_ATK_CRIT_DAMAGE,

#	Modifies the multicrit value of this unit. Multicrit
#	determines the amount of types a single attack can crit.
#	Normally, attacks either don't crit or crit one time.
#	Some tower and item effects increase this value, making
#	it possible for an attack to crit 2 or more times. When
#	attack crits multiple times, the multiplier for crit
#	damage is added multiple times.
# 
#	2 crits with x1.25 crit damage multiplier =
# 	1.0 + 0.25 + 0.25 = x1.5 total multiplier
	MOD_MULTICRIT_COUNT,

#	Modifies the chance that spells of this unit will be
#	critical
#	+0.01 = +1% crit chance
# 	Note that initial value is equal to
# 	Constants.INNATE_MOD_SPELL_CRIT_CHANCE
	MOD_SPELL_CRIT_CHANCE,

#	Modifies the damage multiplier for critical spell
#	damage.
#	+0.01 = +1% crit damage
# 	Note that initial value is equal to
# 	Constants.INNATE_MOD_SPELL_CRIT_DAMAGE
	MOD_SPELL_CRIT_DAMAGE,

# 	Damage modifications

#	Modifies spell damage of this unit
#	+0.01 = +1% spell damage
	MOD_SPELL_DAMAGE_DEALT,

#	Modifies the attack speed of this unit. Note that this
#	value divides the attack speed, so higher = faster
#	1s base attack speed with 150% MOD_ATTACKSPEED would be
#	1s / 1.5 = 0.66s
#	+0.01 = +1% attack speed
	MOD_ATTACKSPEED,

#	Modifies the base damage of this unit. "White" numbers in WC3.
#	+1.0 = +1 to base damage
	MOD_DAMAGE_BASE,

#	Modifies the base damage of this unit. "White" numbers
#	in WC3. Applied on top of MOD_DAMAGE_BASE.
#	0.01 = 1% damage increase
	MOD_DAMAGE_BASE_PERC,

#	Modifies the add damage of this unit. "Green" numbers in WC3.
#	Applied on top of bonuses to base damage.
#	+1.0 = +1 to add damage
	MOD_DAMAGE_ADD,

#	Modifies the add damage of this unit. "Green" numbers in
#	WC3. Applied on top of MOD_DAMAGE_ADD and bonuses to
#	base damage.
#	+0.01 = +1% damage increase
	MOD_DAMAGE_ADD_PERC,

#	Modifies the DPS of this unit. Applied after base damage
#	bonuses and add damage bonuses.
#	+1.0 = +1 DPS
	MOD_DPS_ADD,

# 	Misc modifications

#	Modifies the chance of item drops when this tower kills
#	a creep.
#	+0.01 = +1% chance
	MOD_ITEM_CHANCE_ON_KILL,

#	Modifies the quality of item drops when this tower kills
#	a creep.
#	+0.01 = +1% quality
	MOD_ITEM_QUALITY_ON_KILL,

#	Modifies the amount of experience this tower receives
#	from kills.
#	+0.01 = +1% experience change
	MOD_EXP_RECEIVED,

#	Modifies the amount of bounty this tower receives
#	from kills.
#	+0.01 = +1% bounty change
	MOD_BOUNTY_RECEIVED,

#	-----------------------
#	Creep modifications
#	-----------------------
#	Modifications below only make sense when applied to
#	creeps

#	Modifies the amount of experience given by this creep
#	when killed.
#	+0.01 = +1% exp change
	MOD_EXP_GRANTED,

#	Modifies the amount of bounty given by this creep
#	when killed.
#	+0.01 = +1% bounty change
	MOD_BOUNTY_GRANTED,

#	Modifies the amount of attack damage taken by this creep.
#	+0.01 = +1% attack damage
	MOD_ATK_DAMAGE_RECEIVED,

#	Modifies the amount of spell damage taken by this creep.
#	+0.01 = +1% spell damage
	MOD_SPELL_DAMAGE_RECEIVED,

#	Modifies the chance of item drops when this creep is
#	killed.
#	+0.01 = +1% chance
	MOD_ITEM_CHANCE_ON_DEATH,

#	Modifies the quality of item drops when this creep is
#	killed.
#	+0.01 = +1% quality
	MOD_ITEM_QUALITY_ON_DEATH,

#	Modifies health of this creep
#	+1.0 = +1 health
	MOD_HP,

#	Modifies health of this creep. Applied on top of MOD_HP.
#	+0.01 = +1% health
	MOD_HP_PERC,

#	Modifies health regeneration of this creep.
#	+1.0 = +1 health / sec regeneration
	MOD_HP_REGEN,

#	Modifies health regeneration of this creep. Applied on
#	top of MOD_HP_REGEN.
#	+0.01 = +1% health regeneration
	MOD_HP_REGEN_PERC,

#	Modifies armor.
#	+1.0 = +1 armor
	MOD_ARMOR,

#	Modifies armor. Applied on top of MOD_ARMOR.
#	+0.01 = +1% armor
	MOD_ARMOR_PERC,

#	Changes movement speed of this creep.
#	+0.01 = +1% movement speed
	MOD_MOVESPEED,

#	Changes movement speed of this creep.
#	+1.0 = +1 movement speed (speed varies between 100 and 500)
	MOD_MOVESPEED_ABSOLUTE,

#	"Damage from X element" modifications. Modifies damage
#	by multiplying
	MOD_DMG_FROM_ASTRAL,
	MOD_DMG_FROM_DARKNESS,
	MOD_DMG_FROM_NATURE,
	MOD_DMG_FROM_FIRE,
	MOD_DMG_FROM_ICE,
	MOD_DMG_FROM_STORM,
	MOD_DMG_FROM_IRON,

#	-----------------------
#	General modifications
#	-----------------------
#	Modifications below can be applied to both towers and
#	creeps.

#	Modifies trigger chances of this unit, whenever
#	calc_chance() is called.
#	+0.01 = +1% trigger chances.
	MOD_TRIGGER_CHANCES,

#	Modifies the duration of buffs applied by this unit on
#	other units.
#	+0.01 = +1% buff duration
	MOD_BUFF_DURATION,

#	Modifies the duration of debuffs (negative buffs)
#	applied on this unit by other units. Common scenario is
#	where a creep stuns a tower for 3s. This modification
#	would reduce the stun duration.
#	+0.01 = +1% debuff duration
	MOD_DEBUFF_DURATION,
	
#	Modifies mana of this unit.
#	+1.0 = +1 mana
	MOD_MANA,

#	Modifies mana of this unit. Applied on top of MOD_MANA.
#	+0.01 = +1% mana
	MOD_MANA_PERC,

#	Modifies mana regen of this unit.
#	+1.0 = +1 mana regen / second
	MOD_MANA_REGEN,

#	Modifies mana of this unit. Applied on top of MOD_MANA_REGEN.
#	+0.01 = +1% mana regen
	MOD_MANA_REGEN_PERC,
}

const _types_without_percent: Array[ModificationType.enm] = [
	ModificationType.enm.MOD_ARMOR,
	ModificationType.enm.MOD_MOVESPEED_ABSOLUTE,
	ModificationType.enm.MOD_DAMAGE_BASE,
	ModificationType.enm.MOD_DAMAGE_ADD,
	ModificationType.enm.MOD_DPS_ADD,
	ModificationType.enm.MOD_HP,
	ModificationType.enm.MOD_HP_REGEN,
	ModificationType.enm.MOD_MANA,
	ModificationType.enm.MOD_MANA_REGEN,
	ModificationType.enm.MOD_MULTICRIT_COUNT,
]


const _mod_to_string_map: Dictionary = {
	ModificationType.enm.MOD_DMG_TO_MASS: "MOD_DMG_TO_MASS",
	ModificationType.enm.MOD_DMG_TO_NORMAL: "MOD_DMG_TO_NORMAL",
	ModificationType.enm.MOD_DMG_TO_CHAMPION: "MOD_DMG_TO_CHAMPION",
	ModificationType.enm.MOD_DMG_TO_BOSS: "MOD_DMG_TO_BOSS",
	ModificationType.enm.MOD_DMG_TO_AIR: "MOD_DMG_TO_AIR",
	ModificationType.enm.MOD_DMG_TO_UNDEAD: "MOD_DMG_TO_UNDEAD",
	ModificationType.enm.MOD_DMG_TO_MAGIC: "MOD_DMG_TO_MAGIC",
	ModificationType.enm.MOD_DMG_TO_NATURE: "MOD_DMG_TO_NATURE",
	ModificationType.enm.MOD_DMG_TO_ORC: "MOD_DMG_TO_ORC",
	ModificationType.enm.MOD_DMG_TO_HUMANOID: "MOD_DMG_TO_HUMANOID",
	ModificationType.enm.MOD_DMG_TO_CHALLENGE: "MOD_DMG_TO_CHALLENGE",
	ModificationType.enm.MOD_ATK_CRIT_CHANCE: "MOD_ATK_CRIT_CHANCE",
	ModificationType.enm.MOD_ATK_CRIT_DAMAGE: "MOD_ATK_CRIT_DAMAGE",
	ModificationType.enm.MOD_MULTICRIT_COUNT: "MOD_MULTICRIT_COUNT",
	ModificationType.enm.MOD_SPELL_CRIT_CHANCE: "MOD_SPELL_CRIT_CHANCE",
	ModificationType.enm.MOD_SPELL_CRIT_DAMAGE: "MOD_SPELL_CRIT_DAMAGE",
	ModificationType.enm.MOD_SPELL_DAMAGE_DEALT: "MOD_SPELL_DAMAGE_DEALT",
	ModificationType.enm.MOD_ATTACKSPEED: "MOD_ATTACKSPEED",
	ModificationType.enm.MOD_DAMAGE_BASE: "MOD_DAMAGE_BASE",
	ModificationType.enm.MOD_DAMAGE_BASE_PERC: "MOD_DAMAGE_BASE_PERC",
	ModificationType.enm.MOD_DAMAGE_ADD: "MOD_DAMAGE_ADD",
	ModificationType.enm.MOD_DAMAGE_ADD_PERC: "MOD_DAMAGE_ADD_PERC",
	ModificationType.enm.MOD_DPS_ADD: "MOD_DPS_ADD",
	ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL: "MOD_ITEM_CHANCE_ON_KILL",
	ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL: "MOD_ITEM_QUALITY_ON_KILL",
	ModificationType.enm.MOD_EXP_RECEIVED: "MOD_EXP_RECEIVED",
	ModificationType.enm.MOD_BOUNTY_RECEIVED: "MOD_BOUNTY_RECEIVED",
	ModificationType.enm.MOD_EXP_GRANTED: "MOD_EXP_GRANTED",
	ModificationType.enm.MOD_BOUNTY_GRANTED: "MOD_BOUNTY_GRANTED",
	ModificationType.enm.MOD_ATK_DAMAGE_RECEIVED: "MOD_ATK_DAMAGE_RECEIVED",
	ModificationType.enm.MOD_SPELL_DAMAGE_RECEIVED: "MOD_SPELL_DAMAGE_RECEIVED",
	ModificationType.enm.MOD_ITEM_CHANCE_ON_DEATH: "MOD_ITEM_CHANCE_ON_DEATH",
	ModificationType.enm.MOD_ITEM_QUALITY_ON_DEATH: "MOD_ITEM_QUALITY_ON_DEATH",
	ModificationType.enm.MOD_HP: "MOD_HP",
	ModificationType.enm.MOD_HP_PERC: "MOD_HP_PERC",
	ModificationType.enm.MOD_HP_REGEN: "MOD_HP_REGEN",
	ModificationType.enm.MOD_HP_REGEN_PERC: "MOD_HP_REGEN_PERC",
	ModificationType.enm.MOD_ARMOR: "MOD_ARMOR",
	ModificationType.enm.MOD_ARMOR_PERC: "MOD_ARMOR_PERC",
	ModificationType.enm.MOD_MOVESPEED: "MOD_MOVESPEED",
	ModificationType.enm.MOD_MOVESPEED_ABSOLUTE: "MOD_MOVESPEED_ABSOLUTE",
	ModificationType.enm.MOD_DMG_FROM_ASTRAL: "MOD_DMG_FROM_ASTRAL",
	ModificationType.enm.MOD_DMG_FROM_DARKNESS: "MOD_DMG_FROM_DARKNESS",
	ModificationType.enm.MOD_DMG_FROM_NATURE: "MOD_DMG_FROM_NATURE",
	ModificationType.enm.MOD_DMG_FROM_FIRE: "MOD_DMG_FROM_FIRE",
	ModificationType.enm.MOD_DMG_FROM_ICE: "MOD_DMG_FROM_ICE",
	ModificationType.enm.MOD_DMG_FROM_STORM: "MOD_DMG_FROM_STORM",
	ModificationType.enm.MOD_DMG_FROM_IRON: "MOD_DMG_FROM_IRON",
	ModificationType.enm.MOD_TRIGGER_CHANCES: "MOD_TRIGGER_CHANCES",
	ModificationType.enm.MOD_BUFF_DURATION: "MOD_BUFF_DURATION",
	ModificationType.enm.MOD_DEBUFF_DURATION: "MOD_DEBUFF_DURATION",
	ModificationType.enm.MOD_MANA: "MOD_MANA",
	ModificationType.enm.MOD_MANA_PERC: "MOD_MANA_PERC",
	ModificationType.enm.MOD_MANA_REGEN: "MOD_MANA_REGEN",
	ModificationType.enm.MOD_MANA_REGEN_PERC: "MOD_MANA_REGEN_PERC",
}


const _string_to_mod_map: Dictionary = {
	"MOD_DMG_TO_MASS": ModificationType.enm.MOD_DMG_TO_MASS,
	"MOD_DMG_TO_NORMAL": ModificationType.enm.MOD_DMG_TO_NORMAL,
	"MOD_DMG_TO_CHAMPION": ModificationType.enm.MOD_DMG_TO_CHAMPION,
	"MOD_DMG_TO_BOSS": ModificationType.enm.MOD_DMG_TO_BOSS,
	"MOD_DMG_TO_AIR": ModificationType.enm.MOD_DMG_TO_AIR,
	"MOD_DMG_TO_UNDEAD": ModificationType.enm.MOD_DMG_TO_UNDEAD,
	"MOD_DMG_TO_MAGIC": ModificationType.enm.MOD_DMG_TO_MAGIC,
	"MOD_DMG_TO_NATURE": ModificationType.enm.MOD_DMG_TO_NATURE,
	"MOD_DMG_TO_ORC": ModificationType.enm.MOD_DMG_TO_ORC,
	"MOD_DMG_TO_HUMANOID": ModificationType.enm.MOD_DMG_TO_HUMANOID,
	"MOD_DMG_TO_CHALLENGE": ModificationType.enm.MOD_DMG_TO_CHALLENGE,
	"MOD_ATK_CRIT_CHANCE": ModificationType.enm.MOD_ATK_CRIT_CHANCE,
	"MOD_ATK_CRIT_DAMAGE": ModificationType.enm.MOD_ATK_CRIT_DAMAGE,
	"MOD_MULTICRIT_COUNT": ModificationType.enm.MOD_MULTICRIT_COUNT,
	"MOD_SPELL_CRIT_CHANCE": ModificationType.enm.MOD_SPELL_CRIT_CHANCE,
	"MOD_SPELL_CRIT_DAMAGE": ModificationType.enm.MOD_SPELL_CRIT_DAMAGE,
	"MOD_SPELL_DAMAGE_DEALT": ModificationType.enm.MOD_SPELL_DAMAGE_DEALT,
	"MOD_ATTACKSPEED": ModificationType.enm.MOD_ATTACKSPEED,
	"MOD_DAMAGE_BASE": ModificationType.enm.MOD_DAMAGE_BASE,
	"MOD_DAMAGE_BASE_PERC": ModificationType.enm.MOD_DAMAGE_BASE_PERC,
	"MOD_DAMAGE_ADD": ModificationType.enm.MOD_DAMAGE_ADD,
	"MOD_DAMAGE_ADD_PERC": ModificationType.enm.MOD_DAMAGE_ADD_PERC,
	"MOD_DPS_ADD": ModificationType.enm.MOD_DPS_ADD,
	"MOD_ITEM_CHANCE_ON_KILL": ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL,
	"MOD_ITEM_QUALITY_ON_KILL": ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL,
	"MOD_EXP_RECEIVED": ModificationType.enm.MOD_EXP_RECEIVED,
	"MOD_BOUNTY_RECEIVED": ModificationType.enm.MOD_BOUNTY_RECEIVED,
	"MOD_EXP_GRANTED": ModificationType.enm.MOD_EXP_GRANTED,
	"MOD_BOUNTY_GRANTED": ModificationType.enm.MOD_BOUNTY_GRANTED,
	"MOD_ATK_DAMAGE_RECEIVED": ModificationType.enm.MOD_ATK_DAMAGE_RECEIVED,
	"MOD_SPELL_DAMAGE_RECEIVED": ModificationType.enm.MOD_SPELL_DAMAGE_RECEIVED,
	"MOD_ITEM_CHANCE_ON_DEATH": ModificationType.enm.MOD_ITEM_CHANCE_ON_DEATH,
	"MOD_ITEM_QUALITY_ON_DEATH": ModificationType.enm.MOD_ITEM_QUALITY_ON_DEATH,
	"MOD_HP": ModificationType.enm.MOD_HP,
	"MOD_HP_PERC": ModificationType.enm.MOD_HP_PERC,
	"MOD_HP_REGEN": ModificationType.enm.MOD_HP_REGEN,
	"MOD_HP_REGEN_PERC": ModificationType.enm.MOD_HP_REGEN_PERC,
	"MOD_ARMOR": ModificationType.enm.MOD_ARMOR,
	"MOD_ARMOR_PERC": ModificationType.enm.MOD_ARMOR_PERC,
	"MOD_MOVESPEED": ModificationType.enm.MOD_MOVESPEED,
	"MOD_MOVESPEED_ABSOLUTE": ModificationType.enm.MOD_MOVESPEED_ABSOLUTE,
	"MOD_DMG_FROM_ASTRAL": ModificationType.enm.MOD_DMG_FROM_ASTRAL,
	"MOD_DMG_FROM_DARKNESS": ModificationType.enm.MOD_DMG_FROM_DARKNESS,
	"MOD_DMG_FROM_NATURE": ModificationType.enm.MOD_DMG_FROM_NATURE,
	"MOD_DMG_FROM_FIRE": ModificationType.enm.MOD_DMG_FROM_FIRE,
	"MOD_DMG_FROM_ICE": ModificationType.enm.MOD_DMG_FROM_ICE,
	"MOD_DMG_FROM_STORM": ModificationType.enm.MOD_DMG_FROM_STORM,
	"MOD_DMG_FROM_IRON": ModificationType.enm.MOD_DMG_FROM_IRON,
	"MOD_TRIGGER_CHANCES": ModificationType.enm.MOD_TRIGGER_CHANCES,
	"MOD_BUFF_DURATION": ModificationType.enm.MOD_BUFF_DURATION,
	"MOD_DEBUFF_DURATION": ModificationType.enm.MOD_DEBUFF_DURATION,
	"MOD_MANA": ModificationType.enm.MOD_MANA,
	"MOD_MANA_PERC": ModificationType.enm.MOD_MANA_PERC,
	"MOD_MANA_REGEN": ModificationType.enm.MOD_MANA_REGEN,
	"MOD_MANA_REGEN_PERC": ModificationType.enm.MOD_MANA_REGEN_PERC,
}


static func from_string(string: String) -> ModificationType.enm:
	if _string_to_mod_map.has(string):
		return _string_to_mod_map[string]
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_to_mod_map.values()])

		return ModificationType.enm.MOD_ARMOR


static func convert_to_string(type: ModificationType.enm) -> String:
	return _mod_to_string_map[type]


static func get_display_string(type: ModificationType.enm) -> String:
	var string: String
	match type:
		ModificationType.enm.MOD_ARMOR: string = Utils.tr("MOD_ARMOR_TEXT")
		ModificationType.enm.MOD_ARMOR_PERC: string = Utils.tr("MOD_ARMOR_PERC_TEXT")
		ModificationType.enm.MOD_EXP_GRANTED: string = Utils.tr("MOD_EXP_GRANTED_TEXT")
		ModificationType.enm.MOD_EXP_RECEIVED: string = Utils.tr("MOD_EXP_RECEIVED_TEXT")
		ModificationType.enm.MOD_SPELL_DAMAGE_RECEIVED: string = Utils.tr("MOD_SPELL_DAMAGE_RECEIVED_TEXT")
		ModificationType.enm.MOD_SPELL_DAMAGE_DEALT: string = Utils.tr("MOD_SPELL_DAMAGE_DEALT_TEXT")
		ModificationType.enm.MOD_SPELL_CRIT_DAMAGE: string = Utils.tr("MOD_SPELL_CRIT_DAMAGE_TEXT")
		ModificationType.enm.MOD_SPELL_CRIT_CHANCE: string = Utils.tr("MOD_SPELL_CRIT_CHANCE_TEXT")
		ModificationType.enm.MOD_BOUNTY_GRANTED: string = Utils.tr("MOD_BOUNTY_GRANTED_TEXT")
		ModificationType.enm.MOD_BOUNTY_RECEIVED: string = Utils.tr("MOD_BOUNTY_RECEIVED_TEXT")
		ModificationType.enm.MOD_ATK_CRIT_CHANCE: string = Utils.tr("MOD_ATK_CRIT_CHANCE_TEXT")
		ModificationType.enm.MOD_ATK_CRIT_DAMAGE: string = Utils.tr("MOD_ATK_CRIT_DAMAGE_TEXT")
		ModificationType.enm.MOD_ATK_DAMAGE_RECEIVED: string = Utils.tr("MOD_ATK_DAMAGE_RECEIVED_TEXT")
		ModificationType.enm.MOD_ATTACKSPEED: string = Utils.tr("MOD_ATTACKSPEED_TEXT")
		ModificationType.enm.MOD_MULTICRIT_COUNT: string = Utils.tr("MOD_MULTICRIT_COUNT_TEXT")
		ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL: string = Utils.tr("MOD_ITEM_CHANCE_ON_KILL_TEXT")
		ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL: string = Utils.tr("MOD_ITEM_QUALITY_ON_KILL_TEXT")
		ModificationType.enm.MOD_ITEM_CHANCE_ON_DEATH: string = Utils.tr("MOD_ITEM_CHANCE_ON_DEATH_TEXT")
		ModificationType.enm.MOD_ITEM_QUALITY_ON_DEATH: string = Utils.tr("MOD_ITEM_QUALITY_ON_DEATH_TEXT")
		ModificationType.enm.MOD_BUFF_DURATION: string = Utils.tr("MOD_BUFF_DURATION_TEXT")
		ModificationType.enm.MOD_DEBUFF_DURATION: string = Utils.tr("MOD_DEBUFF_DURATION_TEXT")
		ModificationType.enm.MOD_TRIGGER_CHANCES: string = Utils.tr("MOD_TRIGGER_CHANCES_TEXT")
		ModificationType.enm.MOD_MOVESPEED: string = Utils.tr("MOD_MOVESPEED_TEXT")
		ModificationType.enm.MOD_MOVESPEED_ABSOLUTE: string = Utils.tr("MOD_MOVESPEED_ABSOLUTE_TEXT")
		ModificationType.enm.MOD_DAMAGE_BASE: string = Utils.tr("MOD_DAMAGE_BASE_TEXT")
		ModificationType.enm.MOD_DAMAGE_BASE_PERC: string = Utils.tr("MOD_DAMAGE_BASE_PERC_TEXT")
		ModificationType.enm.MOD_DAMAGE_ADD: string = Utils.tr("MOD_DAMAGE_ADD_TEXT")
		ModificationType.enm.MOD_DAMAGE_ADD_PERC: string = Utils.tr("MOD_DAMAGE_ADD_PERC_TEXT")
		ModificationType.enm.MOD_DPS_ADD: string = Utils.tr("MOD_DPS_ADD_TEXT")
		ModificationType.enm.MOD_HP: string = Utils.tr("MOD_HP_TEXT")
		ModificationType.enm.MOD_HP_PERC: string = Utils.tr("MOD_HP_PERC_TEXT")
		ModificationType.enm.MOD_HP_REGEN: string = Utils.tr("MOD_HP_REGEN_TEXT")
		ModificationType.enm.MOD_HP_REGEN_PERC: string = Utils.tr("MOD_HP_REGEN_PERC_TEXT")
		ModificationType.enm.MOD_MANA: string = Utils.tr("MOD_MANA_TEXT")
		ModificationType.enm.MOD_MANA_PERC: string = Utils.tr("MOD_MANA_PERC_TEXT")
		ModificationType.enm.MOD_MANA_REGEN: string = Utils.tr("MOD_MANA_REGEN_TEXT")
		ModificationType.enm.MOD_MANA_REGEN_PERC: string = Utils.tr("MOD_MANA_REGEN_PERC_TEXT")

		ModificationType.enm.MOD_DMG_TO_MASS: string = Utils.tr("MOD_DMG_TO_MASS_TEXT")
		ModificationType.enm.MOD_DMG_TO_NORMAL: string = Utils.tr("MOD_DMG_TO_NORMAL_TEXT")
		ModificationType.enm.MOD_DMG_TO_CHAMPION: string = Utils.tr("MOD_DMG_TO_CHAMPION_TEXT")
		ModificationType.enm.MOD_DMG_TO_BOSS: string = Utils.tr("MOD_DMG_TO_BOSS_TEXT")
		ModificationType.enm.MOD_DMG_TO_AIR: string = Utils.tr("MOD_DMG_TO_AIR_TEXT")

		ModificationType.enm.MOD_DMG_TO_UNDEAD: string = Utils.tr("MOD_DMG_TO_UNDEAD_TEXT")
		ModificationType.enm.MOD_DMG_TO_MAGIC: string = Utils.tr("MOD_DMG_TO_MAGIC_TEXT")
		ModificationType.enm.MOD_DMG_TO_NATURE: string = Utils.tr("MOD_DMG_TO_NATURE_TEXT")
		ModificationType.enm.MOD_DMG_TO_ORC: string = Utils.tr("MOD_DMG_TO_ORC_TEXT")
		ModificationType.enm.MOD_DMG_TO_HUMANOID: string = Utils.tr("MOD_DMG_TO_HUMANOID_TEXT")
		ModificationType.enm.MOD_DMG_TO_CHALLENGE: string = Utils.tr("MOD_DMG_TO_CHALLENGE_TEXT")

		ModificationType.enm.MOD_DMG_FROM_ASTRAL: string = Utils.tr("MOD_DMG_FROM_ASTRAL_TEXT")
		ModificationType.enm.MOD_DMG_FROM_DARKNESS: string = Utils.tr("MOD_DMG_FROM_DARKNESS_TEXT")
		ModificationType.enm.MOD_DMG_FROM_NATURE: string = Utils.tr("MOD_DMG_FROM_NATURE_TEXT")
		ModificationType.enm.MOD_DMG_FROM_FIRE: string = Utils.tr("MOD_DMG_FROM_FIRE_TEXT")
		ModificationType.enm.MOD_DMG_FROM_ICE: string = Utils.tr("MOD_DMG_FROM_ICE_TEXT")
		ModificationType.enm.MOD_DMG_FROM_STORM: string = Utils.tr("MOD_DMG_FROM_STORM_TEXT")
		ModificationType.enm.MOD_DMG_FROM_IRON: string = Utils.tr("MOD_DMG_FROM_IRON_TEXT")
		_: push_error("Unhandled type: ", type)
	
	return string


# Returns true for values like MOD_ARMOR_PERC "+10% armor"
# Returns false for values like MOD_ARMOR "+10 armor"
static func get_is_percentage(type: ModificationType.enm) -> bool:
	return !_types_without_percent.has(type)
