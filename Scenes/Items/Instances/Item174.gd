# Essence of Rot
extends Item


var maj_rot_tower_buff: BuffType
var maj_rot_creep_buff: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Putrescent Presence - Aura[/color]\n"
	text += "Decreases the attack speed of towers in 350 range by 20% and increases the attack and spell damage taken by creeps in 800 range by 20%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% damage taken\n"
	text += "+0.2% attack speed\n"

	return text


func item_init():
	var m_tower: Modifier = Modifier.new()
	maj_rot_tower_buff = BuffType.create_aura_effect_type("maj_rot_tower_buff", false, self)
	maj_rot_creep_buff = BuffType.create_aura_effect_type("maj_rot_creep_buff", false, self)
	maj_rot_tower_buff.set_buff_icon("@@0@@")
	maj_rot_creep_buff.set_buff_icon("@@1@@")
	m_tower.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.2, 0.002)
	maj_rot_tower_buff.set_buff_modifier(m_tower)
	var m_creep: Modifier = Modifier.new()
	m_creep.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, 0.2, 0.004)
	m_creep.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.2, 0.004)
	maj_rot_creep_buff.set_buff_modifier(m_creep)

	maj_rot_tower_buff.set_buff_tooltip("Putrescent Presence\nThis unit is under the effect of Putrescent Presence Aura; it has reduced attack speed.")
	maj_rot_creep_buff.set_buff_tooltip("Putrescent Presence\nThis unit is under the effect of Putrescent Presence Aura; it will receive more damage from attacks and spells.")

	var aura_tower: AuraType = AuraType.new()
	aura_tower.aura_range = 350
	aura_tower.target_type = TargetType.new(TargetType.TOWERS)
	aura_tower.target_self = true
	aura_tower.level = 0
	aura_tower.level_add = 1
	aura_tower.power = 0
	aura_tower.power_add = 1
	aura_tower.aura_effect = maj_rot_tower_buff
	add_aura(aura_tower)

	var aura_creep: AuraType = AuraType.new()
	aura_creep.aura_range = 800
	aura_creep.target_type = TargetType.new(TargetType.CREEPS)
	aura_creep.target_self = true
	aura_creep.level = 0
	aura_creep.level_add = 1
	aura_creep.power = 0
	aura_creep.power_add = 1
	aura_creep.aura_effect = maj_rot_creep_buff
	add_aura(aura_creep)
