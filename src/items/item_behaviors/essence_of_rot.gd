extends ItemBehavior


var presence_tower_bt: BuffType
var presence_creep_bt: BuffType


func item_init():
	presence_tower_bt = BuffType.create_aura_effect_type("presence_tower_bt", false, self)
	presence_tower_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	presence_tower_bt.set_buff_tooltip(tr("7COB"))
	var presence_tower_bt_mod: Modifier = Modifier.new()
	presence_tower_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.2, 0.002)
	presence_tower_bt.set_buff_modifier(presence_tower_bt_mod)

	presence_creep_bt = BuffType.create_aura_effect_type("presence_creep_bt", false, self)
	presence_creep_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	presence_creep_bt.set_buff_tooltip(tr("H3NT"))
	var presence_creep_bt_mod: Modifier = Modifier.new()
	presence_creep_bt_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, 0.2, 0.004)
	presence_creep_bt_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.2, 0.004)
	presence_creep_bt.set_buff_modifier(presence_creep_bt_mod)
