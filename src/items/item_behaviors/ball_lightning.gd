extends ItemBehavior


# NOTE: had to use instance_from_id() to convert user_int to
# item


var lightning_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ball Lightning[/color]\n"
	text += "Every 3 seconds this item jumps to another tower in 1500 range. If there's no tower with an empty slot, this item will fly to stash.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 3.0)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.5, 0.0)


# NOTE: BallLightningJump() in original script
func lightning_pt_on_cleanup(ball: Projectile):
	var tower: Tower = ball.get_caster()
	var towers_in_range: Iterate 
	var ball_item: Item = instance_from_id(ball.user_int) as Item
	var target_tower: Tower = instance_from_id(ball.user_int2) as Tower
	var tower_in_range: Tower

	if ball_item == null:
		push_error("ball_item is null: ", ball_item, target_tower)
	
		return
	
#	NOTE: target tower may become invalid if target tower is
#	sold or transformed while Ball Lightning is flying to
#	it.
	var target_tower_is_valid: bool = target_tower != null && Utils.unit_is_valid(target_tower)
	if !target_tower_is_valid:
		ball_item.set_visible(true)
		ball_item.fly_to_stash(0.0)

		return

	if !ball_item.pickup(target_tower):
		towers_in_range = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.PLAYER_TOWERS), 1500.00)

		while true:
			tower_in_range = towers_in_range.next_random()

			if tower_in_range == null:
				break

			if tower_in_range != tower && tower_in_range != target_tower && tower_in_range.count_free_slots() > 0:
				break

		if tower_in_range != null:
			var ball_2 = Projectile.create_bezier_interpolation_from_unit_to_unit(lightning_pt, tower, 0, 0, target_tower, tower_in_range, 1.2, 0.0, 0.5, false)
			ball_2.user_int = ball_item.get_instance_id()
			ball_2.user_int2 = tower_in_range.get_instance_id()
		else:
			ball_item.set_visible(true)
			ball_item.fly_to_stash(0.0)


func item_init():
	lightning_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 300, self)
	lightning_pt.set_event_on_cleanup(lightning_pt_on_cleanup)


func periodic(_event: Event):
	var tower: Tower = item.get_carrier()
	var ball: Projectile
	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.PLAYER_TOWERS), 1500.00)
	var tower_in_range: Tower

	item.drop()

	var found_tower: bool = false

	if towers_in_range.count() == 0:
		item.fly_to_stash(0.0)

		return

	while true:
		tower_in_range = towers_in_range.next_random()

		if tower_in_range == null:
			break

		if tower_in_range != tower && tower_in_range.count_free_slots() > 0:
			item.set_visible(false)
			ball = Projectile.create_bezier_interpolation_from_unit_to_unit(lightning_pt, tower, 0, 0, tower, tower_in_range, 1.2, 0.0, 0.5, false)
			ball.user_int = item.get_instance_id()
			ball.user_int2 = tower_in_range.get_instance_id()

			found_tower = true

			break

	if !found_tower:
		item.fly_to_stash(0.0)
