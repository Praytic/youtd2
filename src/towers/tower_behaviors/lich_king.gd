extends TowerBehavior


var curse_bt: BuffType
var aura_bt: BuffType
var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	curse_bt = BuffType.new("curse_bt", 5, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, 0.30, 0.008)
	curse_bt.set_buff_modifier(mod)
	curse_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	curse_bt.set_buff_tooltip(tr("AFMY"))

	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/omega.tres")
	aura_bt.add_event_on_create(aura_bt_on_create)
	aura_bt.add_event_on_refresh(aura_bt_on_refresh)
	aura_bt.add_event_on_cleanup(aura_bt_on_cleanup)
	aura_bt.set_buff_tooltip(tr("FOMA"))

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Stored Damage")


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	curse_bt.apply(tower, target, level)


func on_tower_details() -> MultiboardValues:
	var stored_damage_string: String = Utils.format_float(tower.user_real, 0)
	multiboard.set_value(0, stored_damage_string)

	return multiboard


func aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()

	var buff_apply_time: int = int(Utils.get_time())
	var max_dps: int = buff.get_level()
	var buff_stored_damage: float = 0.0
	var caster_id: int = caster.get_instance_id()

	buff.user_int = buff_apply_time
	buff.user_int2 = max_dps
	buff.user_int3 = caster_id
	buff.user_real = buff_stored_damage


func aura_bt_on_refresh(event: Event):
	var buff: Buff = event.get_buff()
	var new_dps: int = buff.get_level()
	var old_king_id: int = buff.user_int3
	var old_king: Unit = instance_from_id(old_king_id)
	var new_king: Unit = buff.get_caster()
	var new_king_id: int = new_king.get_instance_id()

	if old_king == null:
		return

	var old_wrath_damage: float = old_king.user_real * (0.5 + 0.04 * old_king.get_level())

	old_king.user_real = 0.0
	buff.user_int3 = new_king_id

	if new_dps > buff.user_int2:
		buff.user_int2 = new_dps

	if old_wrath_damage > 0.0:
		buff.user_real = buff.user_real + old_wrath_damage


func aura_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var caster: Unit = buff.get_caster()

	var apply_time: int = buff.user_int
	var max_dps: int = buff.user_int2
	var buff_stored_damage: float = buff.user_real

#	NOTE: original script multiplies time value by 0.04 here
#	because in youtd1 getGameTime() returns time multiplied
#	by 25. Not needed in youtd2, time is simply seconds.
	var damage: float = (Utils.get_time() - apply_time) * max_dps
	damage += buff_stored_damage

	if target.get_health() > 0:
		if caster.user_real > 0:
			caster.get_player().display_floating_text("Feel the Wrath!", caster, Color8(15, 15, 200))
			var stored_damage_ratio: float = 0.5 + 0.04 * caster.get_level()
			damage += caster.user_real * stored_damage_ratio
			caster.user_real = 0.0

		Effect.create_simple_at_unit("res://src/effects/frost_bolt_missile.tscn", target)
		caster.do_spell_damage(target, damage, caster.calc_spell_crit_no_bonus())
		caster.get_player().display_floating_text(Utils.format_float(damage, 0), caster, Color8(15, 15, 200))
	else:
		caster.user_real += damage
		caster.get_player().display_floating_text("+" + Utils.format_float(damage, 0), caster, Color8(15, 15, 200))
