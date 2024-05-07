extends ItemBehavior


var strength_bt: BuffType


func get_autocast_description() -> String:
	var text: String = ""

	text += "Upon activation, towers in 350 range receive 10% bonus base damage for 4 seconds. Costs 1 charge.\n"
	text += " \n"
	text += "Regenerates 3 charges every 40 seconds up to a maximum of 10 charges.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 40)


func item_init():
	strength_bt = BuffType.new("strength_bt", 0.0, 0.0, true, self)
	strength_bt.set_buff_icon("res://Resources/Icons/GenericIcons/biceps.tres")
	strength_bt.set_buff_tooltip("Strength Boost\nIncreases base attack damage.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.1, 0)
	strength_bt.set_buff_modifier(mod)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Strength Boost"
	autocast.description = get_autocast_description()
	autocast.icon = "res://Resources/Textures/UI/Icons/gold_icon.tres"
	autocast.caster_art = "DispelMagicTarget.mdl"
	autocast.target_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.target_self = true
	autocast.cooldown = 4
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = null
	autocast.cast_range = 0
	autocast.auto_range = 1000
	autocast.handler = on_autocast
	autocast.item_owner = item
	autocast.dont_cast_at_zero_charges = true
	item.set_autocast(autocast)


func on_autocast(_event: Event):
	var tower: Tower = item.get_carrier()
	var lvl: int = tower.get_level()
	var it: Iterate
	var next: Unit

	if item.user_int > 0:
		it = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 350)

		while true:
			next = it.next()

			if next == null:
				break

			strength_bt.apply_custom_timed(tower, next, lvl * 2, 4.0)

		item.user_int = item.user_int - 1

	item.set_charges(item.user_int)
	await Utils.create_timer(0.1, self).timeout
	item.set_charges(item.user_int)


func on_create():
	item.set_charges(10)
#	The item will use the userInt for charges, cause charges are bugged.
	item.user_int = 10


func periodic(_event: Event):
	item.user_int = item.user_int + 3

	if item.user_int >= 11:
		item.user_int = 10

	item.set_charges(item.user_int)
	await Utils.create_timer(0.1, self).timeout
	item.set_charges(item.user_int)
