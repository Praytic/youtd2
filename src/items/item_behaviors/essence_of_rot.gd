extends ItemBehavior


var presence_tower_bt: BuffType
var presence_creep_bt: BuffType


func item_init():
	presence_tower_bt = BuffType.create_aura_effect_type("presence_tower_bt", false, self)
	presence_tower_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	presence_tower_bt.set_buff_tooltip("Putrescent Presence\nReduces attack speed.")
	var presence_tower_bt_mod: Modifier = Modifier.new()
	presence_tower_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.2, 0.002)
	presence_tower_bt.set_buff_modifier(presence_tower_bt_mod)

	presence_creep_bt = BuffType.create_aura_effect_type("presence_creep_bt", false, self)
	presence_creep_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	presence_creep_bt.set_buff_tooltip("Putrescent Presence\nIncreases attack and spell damage taken.")
	var presence_creep_bt_mod: Modifier = Modifier.new()
	presence_creep_bt_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, 0.2, 0.004)
	presence_creep_bt_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.2, 0.004)
	presence_creep_bt.set_buff_modifier(presence_creep_bt_mod)

	var aura_tower: AuraType = AuraType.new()
	aura_tower.aura_range = 350
	aura_tower.target_type = TargetType.new(TargetType.TOWERS)
	aura_tower.target_self = true
	aura_tower.level = 0
	aura_tower.level_add = 1
	aura_tower.aura_effect = presence_tower_bt
	item.add_aura(aura_tower)

	var aura_creep: AuraType = AuraType.new()
	aura_creep.aura_range = 800
	aura_creep.target_type = TargetType.new(TargetType.CREEPS)
	aura_creep.target_self = true
	aura_creep.level = 0
	aura_creep.level_add = 1
	aura_creep.aura_effect = presence_creep_bt
	item.add_aura(aura_creep)
