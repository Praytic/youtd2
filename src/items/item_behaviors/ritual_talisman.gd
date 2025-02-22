extends ItemBehavior


var ritual_bt: BuffType


func get_autocast_description() -> String:
	var text: String = ""

	text += "Performs a shamanistic ritual on a nearby tower, granting it 20% more experience gain and 10% more attack damage for 10 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.8% experience\n"
	text += "+0.2% damage\n"
	
	return text


func item_init():
	ritual_bt = BuffType.new("ritual_bt", 10, 0, true, self)
	ritual_bt.set_buff_icon("res://resources/icons/generic_icons/moebius_trefoil.tres")
	ritual_bt.set_buff_tooltip(tr("49QO"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.2, 0.008)
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.1, 0.002)
	ritual_bt.set_buff_modifier(mod)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Shamanistic Ritual"
	autocast.description = get_autocast_description()
	autocast.icon = "res://resources/icons/hud/gold.tres"
	autocast.caster_art = ""
	autocast.target_art = "res://src/effects/healing_wave_target.tscn"
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.target_self = true
	autocast.cooldown = 10
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = ritual_bt
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.cast_range = 450
	autocast.auto_range = 450
	autocast.handler = Callable()
	item.set_autocast(autocast)
