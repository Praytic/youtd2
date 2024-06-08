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

	var type_string: String = _get_type_string()

	var text: String
	
	if !base_is_zero && !add_is_zero:
		text = "%s %s (%s/lvl)\n" % [_format_percentage(value_base), type_string, _format_percentage(level_add)]
	elif !base_is_zero && add_is_zero:
		text = "%s %s\n" % [_format_percentage(value_base), type_string]
	elif base_is_zero && !add_is_zero:
		text = "%s %s/lvl\n" % [_format_percentage(level_add), type_string]
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


func _get_type_string() -> String:
	match type:
		Type.MOD_ARMOR: return "armor"
		Type.MOD_ARMOR_PERC: return "armor"
		Type.MOD_EXP_GRANTED: return "experience granted"
		Type.MOD_EXP_RECEIVED: return "experience received"
		Type.MOD_SPELL_DAMAGE_RECEIVED: return "spell damage received"
		Type.MOD_SPELL_DAMAGE_DEALT: return "spell damage dealt"
		Type.MOD_SPELL_CRIT_DAMAGE: return "spell crit damage"
		Type.MOD_SPELL_CRIT_CHANCE: return "spell crit chance"
		Type.MOD_BOUNTY_GRANTED: return "bounty granted"
		Type.MOD_BOUNTY_RECEIVED: return "bounty received"
		Type.MOD_ATK_CRIT_CHANCE: return "crit chance"
		Type.MOD_ATK_CRIT_DAMAGE: return "crit damage"
		Type.MOD_ATK_DAMAGE_RECEIVED: return "attack damage received"
		Type.MOD_ATTACKSPEED: return "attack speed"
		Type.MOD_MULTICRIT_COUNT: return "multicrit"
		Type.MOD_ITEM_CHANCE_ON_KILL: return "item chance"
		Type.MOD_ITEM_QUALITY_ON_KILL: return "item quality"
		Type.MOD_ITEM_CHANCE_ON_DEATH: return "item chance"
		Type.MOD_ITEM_QUALITY_ON_DEATH: return "item quality"
		Type.MOD_BUFF_DURATION: return "buff duration"
		Type.MOD_DEBUFF_DURATION: return "debuff duration"
		Type.MOD_TRIGGER_CHANCES: return "trigger chances"
		Type.MOD_MOVESPEED: return "movement speed"
		Type.MOD_MOVESPEED_ABSOLUTE: return "movement speed"
		Type.MOD_DAMAGE_BASE: return "base damage"
		Type.MOD_DAMAGE_BASE_PERC: return "base damage"
		Type.MOD_DAMAGE_ADD: return "attack damage"
		Type.MOD_DAMAGE_ADD_PERC: return "attack damage"
		Type.MOD_DPS_ADD: return "DPS"
		Type.MOD_HP: return "health"
		Type.MOD_HP_PERC: return "health"
		Type.MOD_HP_REGEN: return "health regen"
		Type.MOD_HP_REGEN_PERC: return "health regen"
		Type.MOD_MANA: return "mana"
		Type.MOD_MANA_PERC: return "mana"
		Type.MOD_MANA_REGEN: return "mana regen"
		Type.MOD_MANA_REGEN_PERC: return "mana regen"

		Type.MOD_DMG_TO_MASS: return "damage to masses"
		Type.MOD_DMG_TO_NORMAL: return "damage to normals"
		Type.MOD_DMG_TO_CHAMPION: return "damage to champions"
		Type.MOD_DMG_TO_BOSS: return "damage to bosses"
		Type.MOD_DMG_TO_AIR: return "damage to air"

		Type.MOD_DMG_TO_UNDEAD: return "damage to undead"
		Type.MOD_DMG_TO_MAGIC: return "damage to magic"
		Type.MOD_DMG_TO_NATURE: return "damage to nature"
		Type.MOD_DMG_TO_ORC: return "damage to orcs"
		Type.MOD_DMG_TO_HUMANOID: return "damage to humanoids"
		Type.MOD_DMG_TO_CHALLENGE: return "damage to challenge"

		Type.MOD_DMG_FROM_ASTRAL: return "damage from astral"
		Type.MOD_DMG_FROM_DARKNESS: return "damage from darkness"
		Type.MOD_DMG_FROM_NATURE: return "damage from nature"
		Type.MOD_DMG_FROM_FIRE: return "damage from fire"
		Type.MOD_DMG_FROM_ICE: return "damage from ice"
		Type.MOD_DMG_FROM_STORM: return "damage from storm"
		Type.MOD_DMG_FROM_IRON: return "damage from iron"

	push_error("Unhandled type: ", type)

	return ""
