extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Original script did not
# allow placing Corruption Field before placing Recreation
# Field. Removed this restriction.


class Summoner:
	var size: float = 3.0
	var corruption_effect: int = 0
	var recreation_effect: int = 0
	var from_pos: Vector2 = Vector2.INF
	var dest_pos: Vector2 = Vector2.INF


# NOTE: SCALE_MIN should match the value in tower sprite
# scene
const SCALE_MIN: float = 0.7
const SCALE_MAX: float = 1.0
const TRANSPORT_CD: float = 1.0
const FIELD_RADIUS: float = 250
const FIELD_DAMAGE: float = 3000
const FIELD_DAMAGE_ADD: float = 100


var multiboard: MultiboardValues
var sum: Summoner = Summoner.new()
# NOTE: this map is never cleared which is a bit suspect but
# considering that the amount of creeps in game is capped at
# 1000's and this stores references - it's not a big deal.
var summoner_units: Dictionary = {}
var time_when_last_transported: float = 0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	multiboard = MultiboardValues.new(1)
	var spelldamage_bonus_label: String = tr("KERS")
	multiboard.set_key(0, spelldamage_bonus_label)


func on_destruct():
	var recreation_effect: int = sum.recreation_effect
	Effect.destroy_effect(recreation_effect)
	var corruption_effect: int = sum.corruption_effect
	Effect.destroy_effect(corruption_effect)


func on_attack(_event: Event):
	var both_fields_were_placed: bool = sum.dest_pos != Vector2.INF && sum.from_pos != Vector2.INF

	if !both_fields_were_placed:
		return

#	NOTE: original script implements transport cooldown by
#	TriggerSleepAction() which is brittle. Changed it to
#	this approach.
	var time_since_last_transport: float = Utils.get_time() - time_when_last_transported
	var transport_is_on_cooldown: bool = time_since_last_transport < TRANSPORT_CD

	if transport_is_on_cooldown:
		return

	time_when_last_transported = Utils.get_time()

	var aoe_dmg: float = FIELD_DAMAGE + FIELD_DAMAGE_ADD * tower.get_level()
	tower.do_spell_damage_aoe(sum.from_pos, FIELD_RADIUS, aoe_dmg, tower.calc_spell_crit_no_bonus(), 0.0)

	var effect_from: int = Effect.create_colored("res://src/effects/arcane_tower_attack_flat.tscn", Vector3(sum.from_pos.x, sum.from_pos.y, 100.0), 270.0, 2, Color8(0, 0, 0, 255))
	Effect.set_z_index(effect_from, Effect.Z_INDEX_BELOW_CREEPS)

	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), sum.from_pos, FIELD_RADIUS)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var creep: Creep = next as Creep

		if creep.get_size() >= CreepSize.enm.BOSS:
			continue

		var already_summoned: bool = summoner_units.has(creep)

		if already_summoned:
			continue

		summoner_units[creep] = true

		it_hunger_ability()

		var random_offset: Vector2 = Vector2(Globals.synced_rng.randf_range(-25, 25), Globals.synced_rng.randf_range(-25, 25))
		var dest_pos: Vector2 = sum.dest_pos + random_offset

		creep.move_to_point(dest_pos)

	tower.do_spell_damage_aoe(sum.dest_pos, FIELD_RADIUS, aoe_dmg, tower.calc_spell_crit_no_bonus(), 0.0)
	var effect_dest: int = Effect.create_colored("res://src/effects/arcane_tower_attack_flat.tscn", Vector3(sum.dest_pos.x, sum.dest_pos.y, 100.0), 270.0, 2, Color8(0, 0, 0, 255))
	Effect.set_z_index(effect_dest, Effect.Z_INDEX_BELOW_CREEPS)


func on_kill(_event: Event):
	it_hunger_ability()


# NOTE: need to check that position of Recreation Field is
# on creep path because creeps will get transported to that
# position.
func on_autocast_recreation(event: Event):
	var autocast: Autocast = event.get_autocast_type()
	var target_pos: Vector2 = autocast.get_target_pos()
	
	var target_pos_is_on_path: bool = Utils.is_point_on_creep_path(target_pos, tower.get_player())

	if !target_pos_is_on_path:
		var invalid_location_text: String = tr("FFW7")
		tower.get_player().display_small_floating_text(invalid_location_text, tower, Color8(255, 150, 0), 30)

		return

	sum.dest_pos = target_pos

	var recreation_field_exists: bool = sum.recreation_effect != 0

	if !recreation_field_exists:
		sum.recreation_effect = Effect.create_animated("res://src/effects/vampiric_aura.tscn", Vector3(target_pos.x, target_pos.y, 0), 270.0)
		Effect.set_z_index(sum.recreation_effect, Effect.Z_INDEX_BELOW_CREEPS)
		Effect.set_auto_destroy_enabled(sum.recreation_effect, false)
		Effect.set_color(sum.recreation_effect, Color8(255, 0, 0, 150))
	else:
		Effect.set_position(sum.recreation_effect, target_pos)


func on_autocast_corruption(event: Event):
	var autocast: Autocast = event.get_autocast_type()
	var target_pos: Vector2 = autocast.get_target_pos()

	sum.from_pos = target_pos

	var corruption_field_exists: bool = sum.corruption_effect != 0

	if !corruption_field_exists:
		sum.corruption_effect = Effect.create_animated("res://src/effects/vampiric_aura.tscn", Vector3(target_pos.x, target_pos.y, 0), 270.0)
		Effect.set_z_index(sum.corruption_effect, Effect.Z_INDEX_BELOW_CREEPS)
		Effect.set_auto_destroy_enabled(sum.corruption_effect, false)
		Effect.set_color(sum.corruption_effect, Color8(0, 0, 255, 150))
	else:
		Effect.set_position(sum.corruption_effect, target_pos)


func on_tower_details() -> MultiboardValues:
	var spelldmg_bonus: float = sum.size - 3.0
	var spelldmg_bonus_string: String = Utils.format_percent(spelldmg_bonus, 1)
	multiboard.set_value(0, spelldmg_bonus_string)

	return multiboard


# NOTE: "It_kill()" in original script
func it_hunger_ability():
	var mod: float = 0.001 + 0.0001 * tower.get_level()

	if sum.size < 10.0:
#		700% cap
		tower.modify_property(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, mod)
		sum.size += mod

	if sum.size < 3.7:
		var tower_scale: float = Utils.get_scale_from_grows(SCALE_MIN, SCALE_MAX, sum.size - 3.0, 0.7)
		tower.set_unit_scale(tower_scale)
