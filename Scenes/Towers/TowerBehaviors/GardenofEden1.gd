extends TowerBehavior


var multiboard: MultiboardValues
var current_spawn_level: int = 0
var lifeforce_stored: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Essence of the Mortals[/color]\n"
	text += "When the garden kills a nature, orc or human unit, its lifeforce is captured in the fountain. For each lifeforce stored in the fountain, the garden deals an additional [current spawn level x 2] spell damage on attack. Maximum of 5 stored lifeforce.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1 maximum lifeforce\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Essence of the Mortals[/color]\n"
	text += "When the garden kills a nature, orc or human unit, its lifeforce is captured in the fountain.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "The garden uses half of the stored lifeforce to create a huge explosion, dealing [current spawn level x 15] spell damage in 1600 AoE for each lifeforce stored.\n"

	return text


func get_autocast_description_short() -> String:
	return "Create a huge explosion.\n"


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

	var autocast: Autocast = Autocast.make()
	autocast.title = "Eden's Wrath"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
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
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	current_spawn_level = target.get_spawn_level()
	var damage: float = lifeforce_stored * 2 * current_spawn_level

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())


func on_kill(event: Event):
	var target: Creep = event.get_target()
	var category: CreepCategory.enm = target.get_category() as CreepCategory.enm
	var can_store_lifeforce: bool = lifeforce_stored < 5 + tower.get_level() && (category == CreepCategory.enm.NATURE || category == CreepCategory.enm.ORC || category == CreepCategory.enm.HUMANOID)

	if !can_store_lifeforce:
		return

	lifeforce_stored += 1
	SFX.sfx_at_unit("NEDeath.mdl", tower)


func on_autocast(_event: Event):
	var x: float = tower.get_x()
	var y: float = tower.get_y()

	if lifeforce_stored == 0:
		return

	var boom: int
	var effect_pos: Vector3 = Vector3(x, y, 0)
	boom = Effect.create_animated_scaled("WispExplode.mdl", effect_pos, 0, 8.0)
	Effect.set_animation_speed(boom, 0.6)
	Effect.set_lifetime(boom, 2.0)
	boom = Effect.create_animated_scaled("WispExplode.mdl", effect_pos, 0, 8.0)
	Effect.set_animation_speed(boom, 0.7)
	Effect.set_lifetime(boom, 2.0)
	boom = Effect.create_animated_scaled("WispExplode.mdl", effect_pos, 0, 8.0)
	Effect.set_animation_speed(boom, 0.8)
	Effect.set_lifetime(boom, 2.0)
	boom = Effect.create_animated_scaled("WispExplode.mdl", effect_pos, 0, 8.0)
	Effect.set_animation_speed(boom, 0.9)
	Effect.set_lifetime(boom, 2.0)

	await Utils.create_timer(0.5, self).timeout

	if Utils.unit_is_valid(tower):
		var aoe_damage: float = 15 * lifeforce_stored * current_spawn_level
		tower.do_spell_damage_pb_aoe(1600, aoe_damage, tower.calc_spell_crit_no_bonus(), 0.0)
		lifeforce_stored = 0


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(lifeforce_stored))

	return multiboard
