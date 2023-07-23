# Ball Lightning
extends Item


# NOTE: had to use instance_from_id() to convert user_int to
# item


var ball_lightning: ProjectileType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Ball Lightning[/color]\n"
	text += "Every 3 seconds this item jumps to another tower. If no other tower in  1500 range has an empty slot, this item will fly to stash."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 3.0)


func ball_lightning_jump(ball: Projectile):
	var tower: Tower = ball.get_caster()
	var towers_in_range: Iterate 
	var itm: Item = instance_from_id(ball.user_int) as Item
	var target_tower: Tower = instance_from_id(ball.user_int2) as Tower
	var tower_in_range: Tower

	if itm == null || target_tower == null:
		push_error("itm or target_tower is null: ", itm, target_tower)

		return

	if !itm.pickup(target_tower):
		towers_in_range = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.PLAYER_TOWERS), 1500.00)

		while true:
			tower_in_range = towers_in_range.next_random()

			if tower_in_range == null:
				break

			if tower_in_range != tower && tower_in_range != target_tower && tower_in_range.count_free_slots() > 0:
				break

		if tower_in_range != null:
			var ball_2 = Projectile.create_bezier_interpolation_from_unit_to_unit(ball_lightning, tower, 0, 0, target_tower, tower_in_range, 1.2, 0.0, 0.5, false)
			ball_2.user_int = itm.get_instance_id()
			ball_2.user_int2 = tower_in_range.get_instance_id()
		else:
			itm.set_visible(true)
			itm.fly_to_stash(0.0)


func item_init():
	ball_lightning = ProjectileType.create_interpolate("FarseerMissile.mdl", 300)
	ball_lightning.set_event_on_cleanup(ball_lightning_jump)


func periodic(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var ball: Projectile
	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.PLAYER_TOWERS), 1500.00)
	var tower_in_range: Tower

	itm.drop()

	while true:
		tower_in_range = towers_in_range.next_random()

		if tower_in_range == null:
			break

		if tower_in_range != tower && tower_in_range.count_free_slots() > 0:
			itm.set_visible(false)
			ball = Projectile.create_bezier_interpolation_from_unit_to_unit(ball_lightning, tower, 0, 0, tower, tower_in_range, 1.2, 0.0, 0.5, false)
			ball.user_int = itm.get_instance_id()
			ball.user_int2 = tower_in_range.get_instance_id()

			break

	if tower_in_range != null:
		towers_in_range.destroy()
	else:
		itm.fly_to_stash(0.0)
