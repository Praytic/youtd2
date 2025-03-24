extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] in original game there's a
# discrepancy between value in description vs script. In
# description, item chance level bonus = 0.14%. In script it
# is 0.16%.


const SECONDARY_EFFECT_CHANCE: float = 0.25
const AUTOCAST_RANGE: float = 500
const GIFT_DURATION: float = 5

const EXP_RECEIVED: float = 0.28
const EXP_RECEIVED_ADD: float = 0.008
const SPELL_DAMAGE_DEALT: float = 0.16
const SPELL_DAMAGE_DEALT_ADD: float = 0.004
const ATK_CRIT_CHANCE: float = 0.04
const ATK_CRIT_CHANCE_ADD: float = 0.001
const DAMAGE_ADD_PERC: float = 0.16
const DAMAGE_ADD_PERC_ADD: float = 0.004
const BUFF_DURATION: float = 0.2
const BUFF_DURATION_ADD: float = 0.006
const ATTACKSPEED: float = 0.08
const ATTACKSPEED_ADD: float = 0.002
const ITEM_CHANCE: float = 0.06
const ITEM_CHANCE_ADD: float = 0.0014


const ELEMENT_TO_MOD_MAP: Dictionary = {
	Element.enm.ASTRAL: Modification.Type.MOD_EXP_RECEIVED,
	Element.enm.DARKNESS: Modification.Type.MOD_SPELL_DAMAGE_DEALT,
	Element.enm.NATURE: Modification.Type.MOD_ATK_CRIT_CHANCE,
	Element.enm.FIRE: Modification.Type.MOD_DAMAGE_ADD_PERC,
	Element.enm.ICE: Modification.Type.MOD_BUFF_DURATION,
	Element.enm.STORM: Modification.Type.MOD_ATTACKSPEED,
	Element.enm.IRON: Modification.Type.MOD_ITEM_CHANCE_ON_KILL,
}


var gift_bt: BuffType
var sprite_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {buff_strength = 1.0, projectile_scale = 0.75},
		2: {buff_strength = 1.5, projectile_scale = 1.5},
		3: {buff_strength = 2.0, projectile_scale = 1.5},
	}


func gift_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target: Tower = buff.get_buffed_unit()
	var tower_element: Element.enm = target.get_element()

#	Ensure caster is still alive.
	if tower == null:
		return

	var main_mod_type: Modification.Type = ELEMENT_TO_MOD_MAP[tower_element]
	var main_mod_value: float = get_mod_value_for_stat(main_mod_type)

	target.modify_property(main_mod_type, main_mod_value)

#	Save values in buff, to be used later when undoing
	buff.user_int = main_mod_type
	buff.user_real = main_mod_value

	var secondary_effect_happened: bool = true

	if secondary_effect_happened:
#		NOTE: for secondary effect, do not include IRON in
#		the random list so that IRON effect can be used as a
#		fallback in case random element is same as tower
#		element.
		var element_list: Array[Element.enm] = Element.get_list()
		element_list.erase(Element.enm.IRON)

		var random_element: Element.enm = Utils.pick_random(Globals.synced_rng, element_list)
		if random_element == tower_element:
			random_element = Element.enm.IRON

		var secondary_mod_type: Modification.Type = ELEMENT_TO_MOD_MAP[random_element]
		var secondary_mod_value: float = get_mod_value_for_stat(secondary_mod_type)

		target.modify_property(secondary_mod_type, secondary_mod_value)

#		Save values in buff, to be used later when undoing
		buff.user_int2 = secondary_mod_type
		buff.user_real2 = secondary_mod_value
	else:
		buff.user_int2 = 0
		buff.user_real2 = 0

	var effect_id: int = Effect.create_simple_at_unit("res://src/effects/keeper_grove_missile.tscn", target, Unit.BodyPart.OVERHEAD)
	Effect.set_auto_destroy_enabled(effect_id, false)
	if secondary_effect_happened:
		Effect.set_color(effect_id, Color8(255, 180, 180))
		Effect.set_scale(effect_id, 1.5)
	buff.user_int3 = effect_id


func gift_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target: Tower = buff.get_buffed_unit()

	var main_mod_type: Modification.Type = buff.user_int as Modification.Type
	var main_mod_value: float = buff.user_real
	var secondary_mod_type: Modification.Type = buff.user_int2 as Modification.Type
	var secondary_mod_value: float = buff.user_real2

	target.modify_property(main_mod_type, -main_mod_value)

	if secondary_mod_type != 0:
		target.modify_property(secondary_mod_type, -secondary_mod_value)

	var effect_id: int = buff.user_int3
	if effect_id != 0:
		Effect.destroy_effect(effect_id)


func sprite_hit(_projectile: Projectile, target: Unit):
	if target == null:
		return

	gift_bt.apply(tower, target, tower.get_level())


func tower_init():
	gift_bt = BuffType.new("gift_bt", GIFT_DURATION, 0, true, self)
	gift_bt.set_buff_icon("res://resources/icons/generic_icons/holy_grail.tres")
	gift_bt.add_event_on_create(gift_bt_on_create)
	gift_bt.add_event_on_cleanup(gift_bt_on_cleanup)
	gift_bt.set_buff_tooltip(tr("I7WD"))

	sprite_pt = ProjectileType.create("res://src/effects/keeper_grove_missile.tscn", 4, 400, self)
	sprite_pt.enable_homing(sprite_hit, 0)


func on_autocast(event: Event):
	var p: Projectile = Projectile.create_from_unit_to_unit(sprite_pt, tower, 0, 0, tower, event.get_target(), true, false, false)
	p.set_projectile_scale(_stats.projectile_scale)
	p.set_color(Color8(50, 255, 50, 255))


func get_mod_value_for_stat(mod_type: Modification.Type) -> float:
	var value: float

	var level: int = tower.get_level()

	match mod_type:
		Modification.Type.MOD_EXP_RECEIVED: value = EXP_RECEIVED + level * EXP_RECEIVED_ADD
		Modification.Type.MOD_ITEM_CHANCE_ON_KILL: value = ITEM_CHANCE + level * ITEM_CHANCE_ADD
		Modification.Type.MOD_SPELL_DAMAGE_DEALT: value = SPELL_DAMAGE_DEALT + level * SPELL_DAMAGE_DEALT_ADD
		Modification.Type.MOD_ATK_CRIT_CHANCE: value = ATK_CRIT_CHANCE + level * ATK_CRIT_CHANCE_ADD
		Modification.Type.MOD_DAMAGE_ADD_PERC: value = DAMAGE_ADD_PERC + level * DAMAGE_ADD_PERC_ADD
		Modification.Type.MOD_BUFF_DURATION: value = BUFF_DURATION + level * BUFF_DURATION_ADD
		Modification.Type.MOD_ATTACKSPEED: value = ATTACKSPEED + level * ATTACKSPEED_ADD
		_:
			push_error("Unknown mod_type used in Nature's Sprite script")
			value = 0.0

	value *= _stats.buff_strength

	return value
