# Mindleecher
extends Item


func get_autocast_description() -> String:
	var text: String = ""

	text += "Removes a flat 15 to 60 exp from a random tower in range and gives it to the caster.\n"

	return text


func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Siphon Knowledge"
	autocast.description = get_autocast_description()
	autocast.icon = "res://Resources/Textures/gold.tres"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE
	autocast.target_self = false
	autocast.cooldown = 30
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = null
	autocast.cast_range = 450
	autocast.auto_range = 0
	autocast.handler = on_autocast
	set_autocast(autocast)


func on_autocast(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 450)
	var next: Unit

	while true:
		next = it.next_random()

		if next == null:
			break

		if next != tower && next.get_exp() > 0:
			break

	if next != null:
		it.destroy()
		tower.add_exp_flat(next.remove_exp_flat(randi_range(15, 60)))
		SFX.sfx_on_unit("AnimateDeadTarget.mdl", next, "head")
		SFX.sfx_on_unit("DeathCoilSpecialArt.mdl", tower, "head")
