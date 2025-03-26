class_name Modification


enum Type {
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

const types_without_percent: Array = [
	Type.MOD_ARMOR,
	Type.MOD_MOVESPEED_ABSOLUTE,
	Type.MOD_DAMAGE_BASE,
	Type.MOD_DAMAGE_ADD,
	Type.MOD_DPS_ADD,
	Type.MOD_HP,
	Type.MOD_HP_REGEN,
	Type.MOD_MANA,
	Type.MOD_MANA_REGEN,
	Type.MOD_MULTICRIT_COUNT,
]


const _mod_to_string_map: Dictionary = {
	Type.MOD_DMG_TO_MASS: "MOD_DMG_TO_MASS",
	Type.MOD_DMG_TO_NORMAL: "MOD_DMG_TO_NORMAL",
	Type.MOD_DMG_TO_CHAMPION: "MOD_DMG_TO_CHAMPION",
	Type.MOD_DMG_TO_BOSS: "MOD_DMG_TO_BOSS",
	Type.MOD_DMG_TO_AIR: "MOD_DMG_TO_AIR",
	Type.MOD_DMG_TO_UNDEAD: "MOD_DMG_TO_UNDEAD",
	Type.MOD_DMG_TO_MAGIC: "MOD_DMG_TO_MAGIC",
	Type.MOD_DMG_TO_NATURE: "MOD_DMG_TO_NATURE",
	Type.MOD_DMG_TO_ORC: "MOD_DMG_TO_ORC",
	Type.MOD_DMG_TO_HUMANOID: "MOD_DMG_TO_HUMANOID",
	Type.MOD_DMG_TO_CHALLENGE: "MOD_DMG_TO_CHALLENGE",
	Type.MOD_ATK_CRIT_CHANCE: "MOD_ATK_CRIT_CHANCE",
	Type.MOD_ATK_CRIT_DAMAGE: "MOD_ATK_CRIT_DAMAGE",
	Type.MOD_MULTICRIT_COUNT: "MOD_MULTICRIT_COUNT",
	Type.MOD_SPELL_CRIT_CHANCE: "MOD_SPELL_CRIT_CHANCE",
	Type.MOD_SPELL_CRIT_DAMAGE: "MOD_SPELL_CRIT_DAMAGE",
	Type.MOD_SPELL_DAMAGE_DEALT: "MOD_SPELL_DAMAGE_DEALT",
	Type.MOD_ATTACKSPEED: "MOD_ATTACKSPEED",
	Type.MOD_DAMAGE_BASE: "MOD_DAMAGE_BASE",
	Type.MOD_DAMAGE_BASE_PERC: "MOD_DAMAGE_BASE_PERC",
	Type.MOD_DAMAGE_ADD: "MOD_DAMAGE_ADD",
	Type.MOD_DAMAGE_ADD_PERC: "MOD_DAMAGE_ADD_PERC",
	Type.MOD_DPS_ADD: "MOD_DPS_ADD",
	Type.MOD_ITEM_CHANCE_ON_KILL: "MOD_ITEM_CHANCE_ON_KILL",
	Type.MOD_ITEM_QUALITY_ON_KILL: "MOD_ITEM_QUALITY_ON_KILL",
	Type.MOD_EXP_RECEIVED: "MOD_EXP_RECEIVED",
	Type.MOD_BOUNTY_RECEIVED: "MOD_BOUNTY_RECEIVED",
	Type.MOD_EXP_GRANTED: "MOD_EXP_GRANTED",
	Type.MOD_BOUNTY_GRANTED: "MOD_BOUNTY_GRANTED",
	Type.MOD_ATK_DAMAGE_RECEIVED: "MOD_ATK_DAMAGE_RECEIVED",
	Type.MOD_SPELL_DAMAGE_RECEIVED: "MOD_SPELL_DAMAGE_RECEIVED",
	Type.MOD_ITEM_CHANCE_ON_DEATH: "MOD_ITEM_CHANCE_ON_DEATH",
	Type.MOD_ITEM_QUALITY_ON_DEATH: "MOD_ITEM_QUALITY_ON_DEATH",
	Type.MOD_HP: "MOD_HP",
	Type.MOD_HP_PERC: "MOD_HP_PERC",
	Type.MOD_HP_REGEN: "MOD_HP_REGEN",
	Type.MOD_HP_REGEN_PERC: "MOD_HP_REGEN_PERC",
	Type.MOD_ARMOR: "MOD_ARMOR",
	Type.MOD_ARMOR_PERC: "MOD_ARMOR_PERC",
	Type.MOD_MOVESPEED: "MOD_MOVESPEED",
	Type.MOD_MOVESPEED_ABSOLUTE: "MOD_MOVESPEED_ABSOLUTE",
	Type.MOD_DMG_FROM_ASTRAL: "MOD_DMG_FROM_ASTRAL",
	Type.MOD_DMG_FROM_DARKNESS: "MOD_DMG_FROM_DARKNESS",
	Type.MOD_DMG_FROM_NATURE: "MOD_DMG_FROM_NATURE",
	Type.MOD_DMG_FROM_FIRE: "MOD_DMG_FROM_FIRE",
	Type.MOD_DMG_FROM_ICE: "MOD_DMG_FROM_ICE",
	Type.MOD_DMG_FROM_STORM: "MOD_DMG_FROM_STORM",
	Type.MOD_DMG_FROM_IRON: "MOD_DMG_FROM_IRON",
	Type.MOD_TRIGGER_CHANCES: "MOD_TRIGGER_CHANCES",
	Type.MOD_BUFF_DURATION: "MOD_BUFF_DURATION",
	Type.MOD_DEBUFF_DURATION: "MOD_DEBUFF_DURATION",
	Type.MOD_MANA: "MOD_MANA",
	Type.MOD_MANA_PERC: "MOD_MANA_PERC",
	Type.MOD_MANA_REGEN: "MOD_MANA_REGEN",
	Type.MOD_MANA_REGEN_PERC: "MOD_MANA_REGEN_PERC",
}


const _string_to_mod_map: Dictionary = {
	"MOD_DMG_TO_MASS": Type.MOD_DMG_TO_MASS,
	"MOD_DMG_TO_NORMAL": Type.MOD_DMG_TO_NORMAL,
	"MOD_DMG_TO_CHAMPION": Type.MOD_DMG_TO_CHAMPION,
	"MOD_DMG_TO_BOSS": Type.MOD_DMG_TO_BOSS,
	"MOD_DMG_TO_AIR": Type.MOD_DMG_TO_AIR,
	"MOD_DMG_TO_UNDEAD": Type.MOD_DMG_TO_UNDEAD,
	"MOD_DMG_TO_MAGIC": Type.MOD_DMG_TO_MAGIC,
	"MOD_DMG_TO_NATURE": Type.MOD_DMG_TO_NATURE,
	"MOD_DMG_TO_ORC": Type.MOD_DMG_TO_ORC,
	"MOD_DMG_TO_HUMANOID": Type.MOD_DMG_TO_HUMANOID,
	"MOD_DMG_TO_CHALLENGE": Type.MOD_DMG_TO_CHALLENGE,
	"MOD_ATK_CRIT_CHANCE": Type.MOD_ATK_CRIT_CHANCE,
	"MOD_ATK_CRIT_DAMAGE": Type.MOD_ATK_CRIT_DAMAGE,
	"MOD_MULTICRIT_COUNT": Type.MOD_MULTICRIT_COUNT,
	"MOD_SPELL_CRIT_CHANCE": Type.MOD_SPELL_CRIT_CHANCE,
	"MOD_SPELL_CRIT_DAMAGE": Type.MOD_SPELL_CRIT_DAMAGE,
	"MOD_SPELL_DAMAGE_DEALT": Type.MOD_SPELL_DAMAGE_DEALT,
	"MOD_ATTACKSPEED": Type.MOD_ATTACKSPEED,
	"MOD_DAMAGE_BASE": Type.MOD_DAMAGE_BASE,
	"MOD_DAMAGE_BASE_PERC": Type.MOD_DAMAGE_BASE_PERC,
	"MOD_DAMAGE_ADD": Type.MOD_DAMAGE_ADD,
	"MOD_DAMAGE_ADD_PERC": Type.MOD_DAMAGE_ADD_PERC,
	"MOD_DPS_ADD": Type.MOD_DPS_ADD,
	"MOD_ITEM_CHANCE_ON_KILL": Type.MOD_ITEM_CHANCE_ON_KILL,
	"MOD_ITEM_QUALITY_ON_KILL": Type.MOD_ITEM_QUALITY_ON_KILL,
	"MOD_EXP_RECEIVED": Type.MOD_EXP_RECEIVED,
	"MOD_BOUNTY_RECEIVED": Type.MOD_BOUNTY_RECEIVED,
	"MOD_EXP_GRANTED": Type.MOD_EXP_GRANTED,
	"MOD_BOUNTY_GRANTED": Type.MOD_BOUNTY_GRANTED,
	"MOD_ATK_DAMAGE_RECEIVED": Type.MOD_ATK_DAMAGE_RECEIVED,
	"MOD_SPELL_DAMAGE_RECEIVED": Type.MOD_SPELL_DAMAGE_RECEIVED,
	"MOD_ITEM_CHANCE_ON_DEATH": Type.MOD_ITEM_CHANCE_ON_DEATH,
	"MOD_ITEM_QUALITY_ON_DEATH": Type.MOD_ITEM_QUALITY_ON_DEATH,
	"MOD_HP": Type.MOD_HP,
	"MOD_HP_PERC": Type.MOD_HP_PERC,
	"MOD_HP_REGEN": Type.MOD_HP_REGEN,
	"MOD_HP_REGEN_PERC": Type.MOD_HP_REGEN_PERC,
	"MOD_ARMOR": Type.MOD_ARMOR,
	"MOD_ARMOR_PERC": Type.MOD_ARMOR_PERC,
	"MOD_MOVESPEED": Type.MOD_MOVESPEED,
	"MOD_MOVESPEED_ABSOLUTE": Type.MOD_MOVESPEED_ABSOLUTE,
	"MOD_DMG_FROM_ASTRAL": Type.MOD_DMG_FROM_ASTRAL,
	"MOD_DMG_FROM_DARKNESS": Type.MOD_DMG_FROM_DARKNESS,
	"MOD_DMG_FROM_NATURE": Type.MOD_DMG_FROM_NATURE,
	"MOD_DMG_FROM_FIRE": Type.MOD_DMG_FROM_FIRE,
	"MOD_DMG_FROM_ICE": Type.MOD_DMG_FROM_ICE,
	"MOD_DMG_FROM_STORM": Type.MOD_DMG_FROM_STORM,
	"MOD_DMG_FROM_IRON": Type.MOD_DMG_FROM_IRON,
	"MOD_TRIGGER_CHANCES": Type.MOD_TRIGGER_CHANCES,
	"MOD_BUFF_DURATION": Type.MOD_BUFF_DURATION,
	"MOD_DEBUFF_DURATION": Type.MOD_DEBUFF_DURATION,
	"MOD_MANA": Type.MOD_MANA,
	"MOD_MANA_PERC": Type.MOD_MANA_PERC,
	"MOD_MANA_REGEN": Type.MOD_MANA_REGEN,
	"MOD_MANA_REGEN_PERC": Type.MOD_MANA_REGEN_PERC,
}

var type: Modification.Type
var value_base: float
var level_add: float


#########################
###     Built-in      ###
#########################

func _init(type_arg: Modification.Type, value_base_arg: float, level_add_arg: float):
	type = type_arg
	value_base = value_base_arg
	level_add = level_add_arg


#########################
###       Public      ###
#########################

func get_tooltip_text() -> String:
	var base_is_zero = abs(value_base) < 0.0001
	var add_is_zero = abs(level_add) < 0.0001

	var type_name: String = _get_type_name()

	var text: String
	
	if !base_is_zero && !add_is_zero:
		text = "%s %s (%s/lvl)\n" % [_format_percentage(value_base), type_name, _format_percentage(level_add)]
	elif !base_is_zero && add_is_zero:
		text = "%s %s\n" % [_format_percentage(value_base), type_name]
	elif base_is_zero && !add_is_zero:
		text = "%s %s/lvl\n" % [_format_percentage(level_add), type_name]
	else:
		text = ""

	return text


#########################
###      Private      ###
#########################

# Formats percentage values for use in tooltip text
# 0.1 = +10%
# -0.1 = -10%
# 0.001 = +0.1%
func _format_percentage(value: float) -> String:
	var sign_string: String
	if value > 0.0:
		sign_string = "+"
	else:
		sign_string = ""

	var value_is_percentage: bool = !types_without_percent.has(type)

	var value_string: String
	if value_is_percentage:
		value_string = String.num(value * 100, 2)
	else:
		value_string = String.num(value, 2)

	var percent_string: String
	if value_is_percentage:
		percent_string = "%"
	else:
		percent_string = ""

	var base_string: String = "%s%s%s" % [sign_string, value_string, percent_string]

	return base_string


func _get_type_name() -> String:
	match type:
		Type.MOD_ARMOR: return tr("MOD_ARMOR_TEXT")
		Type.MOD_ARMOR_PERC: return tr("MOD_ARMOR_PERC_TEXT")
		Type.MOD_EXP_GRANTED: return tr("MOD_EXP_GRANTED_TEXT")
		Type.MOD_EXP_RECEIVED: return tr("MOD_EXP_RECEIVED_TEXT")
		Type.MOD_SPELL_DAMAGE_RECEIVED: return tr("MOD_SPELL_DAMAGE_RECEIVED_TEXT")
		Type.MOD_SPELL_DAMAGE_DEALT: return tr("MOD_SPELL_DAMAGE_DEALT_TEXT")
		Type.MOD_SPELL_CRIT_DAMAGE: return tr("MOD_SPELL_CRIT_DAMAGE_TEXT")
		Type.MOD_SPELL_CRIT_CHANCE: return tr("MOD_SPELL_CRIT_CHANCE_TEXT")
		Type.MOD_BOUNTY_GRANTED: return tr("MOD_BOUNTY_GRANTED_TEXT")
		Type.MOD_BOUNTY_RECEIVED: return tr("MOD_BOUNTY_RECEIVED_TEXT")
		Type.MOD_ATK_CRIT_CHANCE: return tr("MOD_ATK_CRIT_CHANCE_TEXT")
		Type.MOD_ATK_CRIT_DAMAGE: return tr("MOD_ATK_CRIT_DAMAGE_TEXT")
		Type.MOD_ATK_DAMAGE_RECEIVED: return tr("MOD_ATK_DAMAGE_RECEIVED_TEXT")
		Type.MOD_ATTACKSPEED: return tr("MOD_ATTACKSPEED_TEXT")
		Type.MOD_MULTICRIT_COUNT: return tr("MOD_MULTICRIT_COUNT_TEXT")
		Type.MOD_ITEM_CHANCE_ON_KILL: return tr("MOD_ITEM_CHANCE_ON_KILL_TEXT")
		Type.MOD_ITEM_QUALITY_ON_KILL: return tr("MOD_ITEM_QUALITY_ON_KILL_TEXT")
		Type.MOD_ITEM_CHANCE_ON_DEATH: return tr("MOD_ITEM_CHANCE_ON_DEATH_TEXT")
		Type.MOD_ITEM_QUALITY_ON_DEATH: return tr("MOD_ITEM_QUALITY_ON_DEATH_TEXT")
		Type.MOD_BUFF_DURATION: return tr("MOD_BUFF_DURATION_TEXT")
		Type.MOD_DEBUFF_DURATION: return tr("MOD_DEBUFF_DURATION_TEXT")
		Type.MOD_TRIGGER_CHANCES: return tr("MOD_TRIGGER_CHANCES_TEXT")
		Type.MOD_MOVESPEED: return tr("MOD_MOVESPEED_TEXT")
		Type.MOD_MOVESPEED_ABSOLUTE: return tr("MOD_MOVESPEED_ABSOLUTE_TEXT")
		Type.MOD_DAMAGE_BASE: return tr("MOD_DAMAGE_BASE_TEXT")
		Type.MOD_DAMAGE_BASE_PERC: return tr("MOD_DAMAGE_BASE_PERC_TEXT")
		Type.MOD_DAMAGE_ADD: return tr("MOD_DAMAGE_ADD_TEXT")
		Type.MOD_DAMAGE_ADD_PERC: return tr("MOD_DAMAGE_ADD_PERC_TEXT")
		Type.MOD_DPS_ADD: return tr("MOD_DPS_ADD_TEXT")
		Type.MOD_HP: return tr("MOD_HP_TEXT")
		Type.MOD_HP_PERC: return tr("MOD_HP_PERC_TEXT")
		Type.MOD_HP_REGEN: return tr("MOD_HP_REGEN_TEXT")
		Type.MOD_HP_REGEN_PERC: return tr("MOD_HP_REGEN_PERC_TEXT")
		Type.MOD_MANA: return tr("MOD_MANA_TEXT")
		Type.MOD_MANA_PERC: return tr("MOD_MANA_PERC_TEXT")
		Type.MOD_MANA_REGEN: return tr("MOD_MANA_REGEN_TEXT")
		Type.MOD_MANA_REGEN_PERC: return tr("MOD_MANA_REGEN_PERC_TEXT")

		Type.MOD_DMG_TO_MASS: return tr("MOD_DMG_TO_MASS_TEXT")
		Type.MOD_DMG_TO_NORMAL: return tr("MOD_DMG_TO_NORMAL_TEXT")
		Type.MOD_DMG_TO_CHAMPION: return tr("MOD_DMG_TO_CHAMPION_TEXT")
		Type.MOD_DMG_TO_BOSS: return tr("MOD_DMG_TO_BOSS_TEXT")
		Type.MOD_DMG_TO_AIR: return tr("MOD_DMG_TO_AIR_TEXT")

		Type.MOD_DMG_TO_UNDEAD: return tr("MOD_DMG_TO_UNDEAD_TEXT")
		Type.MOD_DMG_TO_MAGIC: return tr("MOD_DMG_TO_MAGIC_TEXT")
		Type.MOD_DMG_TO_NATURE: return tr("MOD_DMG_TO_NATURE_TEXT")
		Type.MOD_DMG_TO_ORC: return tr("MOD_DMG_TO_ORC_TEXT")
		Type.MOD_DMG_TO_HUMANOID: return tr("MOD_DMG_TO_HUMANOID_TEXT")
		Type.MOD_DMG_TO_CHALLENGE: return tr("MOD_DMG_TO_CHALLENGE_TEXT")

		Type.MOD_DMG_FROM_ASTRAL: return tr("MOD_DMG_FROM_ASTRAL_TEXT")
		Type.MOD_DMG_FROM_DARKNESS: return tr("MOD_DMG_FROM_DARKNESS_TEXT")
		Type.MOD_DMG_FROM_NATURE: return tr("MOD_DMG_FROM_NATURE_TEXT")
		Type.MOD_DMG_FROM_FIRE: return tr("MOD_DMG_FROM_FIRE_TEXT")
		Type.MOD_DMG_FROM_ICE: return tr("MOD_DMG_FROM_ICE_TEXT")
		Type.MOD_DMG_FROM_STORM: return tr("MOD_DMG_FROM_STORM_TEXT")
		Type.MOD_DMG_FROM_IRON: return tr("MOD_DMG_FROM_IRON_TEXT")

	push_error("Unhandled type: ", type)

	return ""


static func convert_mod_to_string(mod_id: Modification.Type) -> String:
	var string: String = _mod_to_string_map[mod_id]

	return string


static func convert_string_to_mod(string: String) -> Modification.Type:
	var mod_id: Modification.Type = _string_to_mod_map[string]

	return mod_id
