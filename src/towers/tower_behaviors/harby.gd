extends TowerBehavior


var aura_bt: BuffType
var awaken_bt: BuffType
var missile_pt: ProjectileType
var is_awake: bool = false


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)
	triggers.add_event_on_spell_targeted(on_spell_targeted)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_tooltip(tr("WMXC"))
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")
	aura_bt.add_event_on_create(aura_bt_on_create)
	aura_bt.add_event_on_spell_casted(aura_bt_on_spell_casted)

	awaken_bt = BuffType.new("awaken_bt", 5, 0, true, self)
	awaken_bt.set_buff_icon("res://resources/icons/generic_icons/semi_closed_eye.tres")
	awaken_bt.set_buff_tooltip(tr("KY4C"))
	awaken_bt.add_event_on_create(awaken_bt_on_create)
	awaken_bt.add_event_on_cleanup(awaken_bt_on_cleanup)

	missile_pt = ProjectileType.create("path_to_projectile_sprite", 10, 1500, self)
	missile_pt.enable_homing(missile_pt_on_hit, 0.0)


func on_attack(event: Event):
	var damage: float = (6 + 0.1 * tower.get_level()) * tower.get_mana()
	var creep: Creep = event.get_target()

	if !is_awake:
		tower.order_stop()

		return

	var p: Projectile = Projectile.create_from_unit_to_unit(missile_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, creep, true, false, false)

	var arcane_aura_chance: float = 0.1 + 0.004 * tower.get_level()

	if tower.get_mana() >= 100:
		tower.subtract_mana(100, false)

		if tower.calc_chance(arcane_aura_chance):
			arcane_mana_replenish(tower)

		var floating_text: String = "+%s" % Utils.format_float(damage, 0)
		tower.get_player().display_floating_text_x(floating_text, tower, Color8(255, 0, 255, 255), 0.05, 2, 3)
		p.user_real = damage
	else:
		p.user_real = 0


func on_kill(_event: Event):
	tower.modify_property(ModificationType.enm.MOD_MANA, 1)


func on_spell_targeted(_event: Event):
	awaken_bt.apply(tower, tower, 0)


func on_create(preceding_tower: Tower):
	if preceding_tower == null:
		return

	var preceding_kills: int = preceding_tower.get_kills()
	tower.modify_property(ModificationType.enm.MOD_MANA, preceding_kills)


func aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var last_proc_time: int = 0
	buff.user_int = last_proc_time


func aura_bt_on_spell_casted(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var last_proc_time: int = buff.user_int
	var autocast: Autocast = event.get_autocast_type()

#	NOTE: in original script it was 125 instead of 5 because
#	original API get_game_time() returns seconds multiplied
#	by 25. Youtd2 get_game_time() returns seconds.
	var can_proc: bool = last_proc_time + 5 < Utils.get_time() && autocast.get_mana_cost() > 0

	if !can_proc:
		return

	var proc_chance: bool = 0.10 + 0.004 * buffed_tower.get_level()

	if !buffed_tower.calc_chance(proc_chance):
		return

	CombatLog.log_ability(buffed_tower, null, "Arcane Aura proc")

	arcane_mana_replenish(buffed_tower)

	last_proc_time = floori(Utils.get_time())
	buff.user_int = last_proc_time


func arcane_mana_replenish(target: Tower):
	Effect.create_colored("res://src/effects/replenish_mana.tscn", Vector3(target.get_x(), target.get_y(), 80), 0.0, 5, Color8(100, 100, 255, 255))
	var mana_gain: float = 0.1 + 0.002 * target.get_level()
	target.add_mana_perc(mana_gain)


func awaken_bt_on_create(_event: Event):
	# AddUnitAnimationProperties(u, "stand alternate", true)
	# SetUnitFlyHeight(u, 100, 2000)

	CombatLog.log_ability(tower, null, "Grotesque Awakening")

	is_awake = true


func awaken_bt_on_cleanup(_event: Event):
	# AddUnitAnimationProperties(u, "stand alternate", false)
	# SetUnitFlyHeight(u, 40, 2000)

	CombatLog.log_ability(tower, null, "Grotesque Awakening End")

	is_awake = false


func missile_pt_on_hit(p: Projectile, target: Unit):
	if target == null:
		return

	var damage: float = p.user_real
	p.do_spell_damage(target, damage)
