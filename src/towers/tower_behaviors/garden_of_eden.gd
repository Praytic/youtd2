extends TowerBehavior


var multiboard: MultiboardValues
var current_spawn_level: int = 0
var lifeforce_stored: int = 0


func get_ability_info_list() -> Array[AbilityInfo]:
	var nature_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.NATURE)
	var orc_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.ORC)
	var human_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.HUMANOID)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Essence of the Mortals"
	ability.icon = "res://resources/icons/dioramas/mountain.tres"
	ability.description_short = "When the Garden kills a %s, %s and %s creep, its lifeforce is captured in the fountain. The lifeforce is used to deal extra spell damage.\n" % [nature_string, orc_string, human_string]
	ability.description_full = "When the Garden kills a %s, %s and %s creep, its lifeforce is captured in the fountain. Whenever the Garden attacks, it deals [color=GOLD][current spawn level x 2][/color] spell damage, for each lifeforce stored in the fountain, to the main target. Maximum of 5 stored lifeforce.\n" % [nature_string, orc_string, human_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1 maximum lifeforce\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.50, 0.0)


func tower_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Lifeforce Stored")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()
	
	autocast.title = "Eden's Wrath"
	autocast.icon = "res://resources/icons/trinkets/trinket_03.tres"
	autocast.description_short = "Create a huge explosion.\n"
	autocast.description = "The garden uses half of the stored lifeforce to create a huge explosion, dealing [color=gold][current wave level x 15][/color] spell damage in 1600 AoE for each lifeforce stored.\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 800
	autocast.auto_range = 800
	autocast.cooldown = 10
	autocast.mana_cost = 0
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.buff_target_type = null
	autocast.handler = on_autocast

	return [autocast]


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
	SFX.sfx_at_unit(SfxPaths.WARP, tower)


func on_autocast(_event: Event):
	var x: float = tower.get_x()
	var y: float = tower.get_y()
	var z: float = tower.get_z()

	if lifeforce_stored == 0:
		return

	var boom: int
	var effect_pos: Vector3 = Vector3(x, y, z + Constants.TILE_SIZE_WC3 / 2)
	var effect_color: Color = Color(Color.CYAN, 0.3)
	boom = Effect.create_animated_scaled("res://src/effects/bdragon_03_wisp_explode.tscn", effect_pos, 0, 5.0)
	Effect.set_animation_speed(boom, 0.6)
	Effect.set_lifetime(boom, 2.0)
	Effect.set_color(boom, effect_color)
	boom = Effect.create_animated_scaled("res://src/effects/bdragon_03_wisp_explode.tscn", effect_pos, 0, 5.0)
	Effect.set_animation_speed(boom, 0.7)
	Effect.set_lifetime(boom, 2.0)
	Effect.set_color(boom, effect_color)
	boom = Effect.create_animated_scaled("res://src/effects/bdragon_03_wisp_explode.tscn", effect_pos, 0, 5.0)
	Effect.set_animation_speed(boom, 0.8)
	Effect.set_lifetime(boom, 2.0)
	Effect.set_color(boom, effect_color)
	boom = Effect.create_animated_scaled("res://src/effects/bdragon_03_wisp_explode.tscn", effect_pos, 0, 5.0)
	Effect.set_animation_speed(boom, 0.9)
	Effect.set_lifetime(boom, 2.0)
	Effect.set_color(boom, effect_color)

	await Utils.create_timer(0.5, self).timeout

	if Utils.unit_is_valid(tower):
		var aoe_damage: float = 15 * lifeforce_stored * current_spawn_level
		tower.do_spell_damage_pb_aoe(1600, aoe_damage, tower.calc_spell_crit_no_bonus(), 0.0)
		lifeforce_stored = 0


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(lifeforce_stored))

	return multiboard
