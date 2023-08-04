# Scroll of Speed
extends Item


var boekie_scroll_damage: BuffType


func get_autocast_description() -> String:
	var text: String = ""

	text += "Upon activation, towers in 350 range receive 10% bonus attackspeed for 4 seconds. Costs 1 charge.\n"
	text += " \n"
	text += "Regenerates 3 charges every 40 seconds up to a maximum of 10 charges.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 40)


func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Speed Boost"
	autocast.description = get_autocast_description()
	autocast.icon = "res://Resources/Textures/gold.tres"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.target_self = true
	autocast.cooldown = 4
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = null
	autocast.cast_range = 0
	autocast.auto_range = 1000
	autocast.handler = on_autocast
	set_autocast(autocast)


func on_autocast(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var lvl: int = tower.get_level()
	var it: Iterate
	var next: Unit

	if itm.user_int > 0:
		it = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 350)

		while true:
			next = it.next()

			if next == null:
				break

			boekie_scroll_damage.apply_custom_timed(tower, next, lvl * 2, 4.0)

		itm.user_int = itm.user_int - 1

	itm.set_charges(itm.user_int)
	await get_tree().create_timer(0.1).timeout
	itm.set_charges(itm.user_int)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.1, 0)
	boekie_scroll_damage = BuffType.new("boekie_scroll_damage", 0.0, 0.0, true, self)
	boekie_scroll_damage.set_buff_modifier(m)
	boekie_scroll_damage.set_buff_icon("@@0@@")
	boekie_scroll_damage.set_buff_tooltip("Speed Boost\nThis unit is affected by Scroll of Speed; it has increased attack speed.")


func on_create():
	var itm: Item = self
	itm.set_charges(10)
#	The item will use the userInt for charges, cause charges are bugged.
	itm.user_int = 10


func periodic(event: Event):
	var itm: Item = self
	itm.user_int = itm.user_int + 3

	if itm.user_int > 11:
		itm.user_int = 10

	itm.set_charges(itm.user_int)
	await get_tree().create_timer(0.1).timeout
	itm.set_charges(itm.user_int)
