extends TowerBehavior


var multiboard: MultiboardValues
var current_spawn_level: int = 0
var lifeforce_stored: int = 0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Lifeforce Stored")


func on_attack(event: Event):
	var target: Unit = event.get_target()
	current_spawn_level = target.get_spawn_level()
	var damage: float = lifeforce_stored * 2 * current_spawn_level

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())


func on_kill(event: Event):
	var target: Creep = event.get_target()
	var category: CreepCategory.enm = target.get_category()
	var category_match: bool = [CreepCategory.enm.NATURE, CreepCategory.enm.ORC, CreepCategory.enm.HUMANOID].has(category)
	var can_store_lifeforce: bool = lifeforce_stored < 5 + tower.get_level() && category_match

	if !can_store_lifeforce:
		return

	lifeforce_stored += 1
	Effect.create_simple_at_unit("res://src/effects/ne_death.tscn", tower)


func on_autocast(_event: Event):
	var x: float = tower.get_x()
	var y: float = tower.get_y()
	var z: float = tower.get_z()

	if lifeforce_stored == 0:
		return

	var boom: int
	var effect_pos: Vector3 = Vector3(x, y, z + Constants.TILE_SIZE_WC3 / 2)
	var effect_color: Color = Color(Color.CYAN, 0.3)
	boom = Effect.create_animated_scaled("res://src/effects/wisp_explode.tscn", effect_pos, 0, 2.0)
	Effect.set_animation_speed(boom, 0.6)
	Effect.set_lifetime(boom, 2.0)
	Effect.set_color(boom, effect_color)
	boom = Effect.create_animated_scaled("res://src/effects/wisp_explode.tscn", effect_pos, 0, 2.0)
	Effect.set_animation_speed(boom, 0.7)
	Effect.set_lifetime(boom, 2.0)
	Effect.set_color(boom, effect_color)
	boom = Effect.create_animated_scaled("res://src/effects/wisp_explode.tscn", effect_pos, 0, 2.0)
	Effect.set_animation_speed(boom, 0.8)
	Effect.set_lifetime(boom, 2.0)
	Effect.set_color(boom, effect_color)
	boom = Effect.create_animated_scaled("res://src/effects/wisp_explode.tscn", effect_pos, 0, 2.0)
	Effect.set_animation_speed(boom, 0.9)
	Effect.set_lifetime(boom, 2.0)
	Effect.set_color(boom, effect_color)

	await Utils.create_manual_timer(0.5, self).timeout

	if Utils.unit_is_valid(tower):
		var aoe_damage: float = 15 * lifeforce_stored * current_spawn_level
		tower.do_spell_damage_pb_aoe(1600, aoe_damage, tower.calc_spell_crit_no_bonus(), 0.0)
		lifeforce_stored = 0


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(lifeforce_stored))

	return multiboard
