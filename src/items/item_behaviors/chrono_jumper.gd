extends ItemBehavior


# NOTE: this item is complicated and has multiple edge
# cases. Some of the edge cases are handled by this item
# script. Others depend on specific call order in other
# source files. Very brittle setup!
# 
# Handled edge cases:
# - Jump to position, transform/upgrade tower while tower is
#   at jump position. New tower needs to correctly be built
#   at original position instead of jump position. This is
#   handled by transform/upgrade code. That code contains
#   specific call order where tower is first added to world
#   and then inherits position of prev tower. Adding to
#   world first ensures that items are transferred fist (in
#   Tower._ready) which means that CLEANUP callback is
#   called.
# - Buildable state at original position. When tower jumps,
#   previous position stays as "occupied" so it's not
#   possible to build a new tower on old position while
#   tower is jumping.
# - Buildable state at jump position. This is intentionally
#   not modified in any way. It is possible to build a tower
#   on top of jumping tower but that doesn't cause any
#   problems.
# - Transform tower while it's jumping into a tower with
#   less inventory slots. If Chrono Jumper is dropped from
#   tower instead of transferred to new tower because of not
#   enough inventory space, then new tower is still
#   correctly built at original position because CLEANUP
#   callback is still called.


const JUMP_DURATION: float = 10.0
const ATTACKSPEED_BONUS: float = 0.10
const COOLDOWN: float = 30.0

var jumper_bt: BuffType
var original_pos: Vector2 = Vector2.ZERO


func item_init():
	jumper_bt = BuffType.new("jumper_bt", JUMP_DURATION, 0, true, self)
	var jumper_bt_mod: Modifier = Modifier.new()
	jumper_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, ATTACKSPEED_BONUS, 0.0)
	jumper_bt.set_buff_modifier(jumper_bt_mod)
	jumper_bt.set_buff_icon("res://resources/icons/generic_icons/atomic_slashes.tres")
	jumper_bt.set_buff_tooltip("Chrono Jump\nThis tower has performed a Chrono Jump.")
	jumper_bt.add_event_on_cleanup(jumper_bt_on_cleanup)

	var jump_duration: String = Utils.format_float(JUMP_DURATION, 2)
	var attack_speed_bonus: String = Utils.format_percent(ATTACKSPEED_BONUS, 2)
	var cooldown: String = Utils.format_float(COOLDOWN, 2)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Chrono Jump"
	autocast.description = "[color=GOLD]Chrono Jump[/color]\n" \
	+ "Tower makes a leap through space to a target free location for %s seconds, then returns to its original position. Increases attack speed by %s for the duration.\n" % [jump_duration, attack_speed_bonus] \
	+ " \n" \
	+ "%ss cooldown\n" % cooldown\
	+ ""
	autocast.icon = "res://resources/icons/hud/gold.tres"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_NOAC_POINT
	autocast.target_self = false
	autocast.cooldown = COOLDOWN
	autocast.is_extended = true
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = null
	autocast.cast_range = 1500
	autocast.auto_range = 1500
	autocast.handler = on_autocast

	item.set_autocast(autocast)


# NOTE: there are convoluted conversions between wc3 and
# canvas positions because some API's accept only canvas
# positions. Be careful if you decide to fix this by adding
# API's for wc3 positions, it's easy to make a mistake.
func on_autocast(event: Event):
	var tower: Tower = item.get_carrier()
	var player: Player = tower.get_player()

	var tower_already_jumping: bool = tower.get_buff_of_type(jumper_bt) != null

	if tower_already_jumping:
		player.display_floating_text("Cannot jump right now.", tower, Color.PURPLE)

		return

	original_pos = tower.get_position_wc3_2d()
	var original_pos_3d: Vector3 = tower.get_position_wc3()
	var autocast: Autocast = event.get_autocast_type()
	var target_pos_wc3: Vector2 = autocast.get_target_pos()
	var target_pos_canvas: Vector2 = VectorUtils.wc3_2d_to_canvas(target_pos_wc3)
	var target_pos_canvas_snapped: Vector2 = VectorUtils.snap_canvas_pos_to_buildable_pos(target_pos_canvas)
	
	var game_scene: GameScene = get_tree().get_root().get_node("GameScene")
	var build_space: BuildSpace = game_scene.get_build_space()
	var can_build_at_pos: bool = build_space.can_build_at_pos(target_pos_canvas_snapped)

	var dest_pos_canvas: Vector2

	if can_build_at_pos:
		dest_pos_canvas = target_pos_canvas_snapped
	else:
		var nearby_buildable_pos: Vector2 = find_nearby_buildable_pos(target_pos_wc3)
		var found_buildable_pos: bool = nearby_buildable_pos != Vector2.INF

		if found_buildable_pos:
			dest_pos_canvas = nearby_buildable_pos
		else:
			player.display_floating_text_at_pos("Cannot jump to this position.", target_pos_wc3, Color.PURPLE)
			
			return

	dest_pos_canvas.y += Constants.TILE_SIZE.y
	var dest_pos_wc3: Vector2 = VectorUtils.canvas_to_wc3_2d(dest_pos_canvas)
	
	SFX.sfx_at_unit("MassTeleportCaster.mdl", tower)
	tower.set_position_wc3_2d(dest_pos_wc3)
	SFX.sfx_at_unit("MassTeleportTarget.mdl", tower)
	jumper_bt.apply(tower, tower, 0)

	var effect: int = Effect.create_animated("res://src/effects/generic_magic.tscn", original_pos_3d, 0)
	Effect.set_lifetime(effect, JUMP_DURATION)


# NOTE: chrono_jumper_onCleanup() in original script
func jumper_bt_on_cleanup(_event: Event):
	var tower: Tower = item.get_carrier()
	
	SFX.sfx_at_unit("MassTeleportCaster.mdl", tower)
	tower.set_position_wc3_2d(original_pos)
	SFX.sfx_at_unit("MassTeleportTarget.mdl", tower)


func find_nearby_buildable_pos(target_pos: Vector2):
	var game_scene: GameScene = get_tree().get_root().get_node("GameScene")
	var build_space: BuildSpace = game_scene.get_build_space()

	var neighbor_list: Array = []

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var offset: Vector2 = Vector2(dx, dy) * 0.5 * Constants.TILE_SIZE_WC3
			var neighbor: Vector2 = target_pos + offset

			if neighbor_list.has(neighbor):
				continue

			neighbor_list.append(neighbor)

	neighbor_list.sort_custom(
		func (a: Vector2, b: Vector2) -> bool:
			var dist_a: float = target_pos.distance_squared_to(a)
			var dist_b: float = target_pos.distance_squared_to(b)

			return dist_a < dist_b
			)

	for neighbor in neighbor_list:
		var neighbor_canvas: Vector2 = VectorUtils.wc3_2d_to_canvas(neighbor)
		var can_build_at_neighbor: bool = build_space.can_build_at_pos(neighbor_canvas)

		if can_build_at_neighbor:
			return neighbor_canvas

	var value_if_not_found: Vector2 = Vector2.INF

	return value_if_not_found
