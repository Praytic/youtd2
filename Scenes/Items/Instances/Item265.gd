# Magic Link
extends Item


func get_autocast_description() -> String:
	var text: String = ""

	text += "Transfers a flat 30 experience from this tower to another one.\n"

	return text


func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Transfer Experience"
	autocast.description = get_autocast_description()
	autocast.icon = "res://Resources/Textures/UI/Icons/gold_icon.tres"
	autocast.caster_art = "DispelMagicTarget.mdl"
	autocast.target_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.target_self = false
	autocast.cooldown = 60
	autocast.is_extended = true
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.cast_range = 1200
	autocast.auto_range = 1200
	autocast.handler = on_autocast
	set_autocast(autocast)


func on_autocast(event: Event):
	var itm: Item = self

	event.get_target().add_exp_flat(itm.get_carrier().remove_exp_flat(30))
