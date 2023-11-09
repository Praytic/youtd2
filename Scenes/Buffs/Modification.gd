class_name Modification


enum Type {
	MOD_ARMOR,
	MOD_ARMOR_PERC,
	MOD_EXP_GRANTED,
	MOD_EXP_RECEIVED,
	MOD_SPELL_DAMAGE_RECEIVED,
	MOD_SPELL_DAMAGE_DEALT,
	MOD_SPELL_CRIT_DAMAGE,
	MOD_SPELL_CRIT_CHANCE,
	MOD_BOUNTY_GRANTED,
	MOD_BOUNTY_RECEIVED,
	MOD_ATK_CRIT_CHANCE,
	MOD_ATK_CRIT_DAMAGE,
	MOD_ATK_DAMAGE_RECEIVED,
	MOD_ATTACKSPEED,
	MOD_MULTICRIT_COUNT,
	MOD_ITEM_CHANCE_ON_KILL,
	MOD_ITEM_QUALITY_ON_KILL,
	MOD_ITEM_CHANCE_ON_DEATH,
	MOD_ITEM_QUALITY_ON_DEATH,
	MOD_BUFF_DURATION,
	MOD_DEBUFF_DURATION,
	MOD_TRIGGER_CHANCES,
	MOD_MOVESPEED,
	MOD_MOVESPEED_ABSOLUTE,
	MOD_DAMAGE_BASE,
	MOD_DAMAGE_BASE_PERC,
	MOD_DAMAGE_ADD,
	MOD_DAMAGE_ADD_PERC,
	MOD_DPS_ADD,
	MOD_HP,
	MOD_HP_PERC,
	MOD_HP_REGEN,
	MOD_HP_REGEN_PERC,
	MOD_MANA,
	MOD_MANA_PERC,
	MOD_MANA_REGEN,
	MOD_MANA_REGEN_PERC,

	MOD_DMG_TO_MASS,
	MOD_DMG_TO_NORMAL,
	MOD_DMG_TO_CHAMPION,
	MOD_DMG_TO_BOSS,
	MOD_DMG_TO_AIR,

	MOD_DMG_TO_UNDEAD,
	MOD_DMG_TO_MAGIC,
	MOD_DMG_TO_NATURE,
	MOD_DMG_TO_ORC,
	MOD_DMG_TO_HUMANOID,
	MOD_DMG_TO_CHALLENGE,

	MOD_DMG_FROM_ASTRAL,
	MOD_DMG_FROM_DARKNESS,
	MOD_DMG_FROM_NATURE,
	MOD_DMG_FROM_FIRE,
	MOD_DMG_FROM_ICE,
	MOD_DMG_FROM_STORM,
	MOD_DMG_FROM_IRON,
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


func _init(type_arg: Modification.Type, value_base_arg: float, level_add_arg: float):
	type = type_arg
	value_base = value_base_arg
	level_add = level_add_arg


func get_tooltip_text() -> String:
	var base_is_zero = abs(value_base) < 0.0001
	var add_is_zero = abs(level_add) < 0.0001

	var type_string: String = get_type_string()

	var text: String
	
	if !base_is_zero && !add_is_zero:
		text = "%s %s (%s/lvl)\n" % [format_percentage(value_base), type_string, format_percentage(level_add)]
	elif !base_is_zero && add_is_zero:
		text = "%s %s\n" % [format_percentage(value_base), type_string]
	elif base_is_zero && !add_is_zero:
		text = "%s %s/lvl\n" % [format_percentage(level_add), type_string]
	else:
		text = ""

	return text


# Formats percentage values for use in tooltip text
# 0.1 = +10%
# -0.1 = -10%
# 0.001 = +0.1%
func format_percentage(value: float) -> String:
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


func get_type_string() -> String:
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
		Type.MOD_ATK_DAMAGE_RECEIVED: return "damage received"
		Type.MOD_ATTACKSPEED: return "attack speed"
		Type.MOD_MULTICRIT_COUNT: return "multicrit"
		Type.MOD_ITEM_CHANCE_ON_KILL: return "item chance"
		Type.MOD_ITEM_QUALITY_ON_KILL: return "item quality"
		Type.MOD_ITEM_CHANCE_ON_DEATH: return "item chance"
		Type.MOD_ITEM_QUALITY_ON_DEATH: return "item quality"
		Type.MOD_BUFF_DURATION: return "buff duration"
		Type.MOD_DEBUFF_DURATION: return "debuff duration"
		Type.MOD_TRIGGER_CHANCES: return "trigger chances"
		Type.MOD_MOVESPEED: return "move speed"
		Type.MOD_MOVESPEED_ABSOLUTE: return "move speed"
		Type.MOD_DAMAGE_BASE: return "damage"
		Type.MOD_DAMAGE_BASE_PERC: return "damage"
		Type.MOD_DAMAGE_ADD: return "damage"
		Type.MOD_DAMAGE_ADD_PERC: return "damage"
		Type.MOD_DPS_ADD: return "dps"
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
