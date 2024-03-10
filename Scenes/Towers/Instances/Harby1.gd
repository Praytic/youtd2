extends Tower


var glow_harby_aura_bt: BuffType
var glow_harby_awaken_bt: BuffType
var harby_pt: ProjectileType
var is_awake: bool = false


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Arcane Orb[/color]\n"
	text += "Infuses Harby's attacks with arcane energy at the cost of 100 mana per attack. Deals [color=GOLD][6 x Current Mana][/color] as bonus spelldamage. This ability also passively grants 1 bonus maximum mana for each creep Harby kills.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "[color=GOLD]+[0.1 x Current Mana][/color] as bonus spelldamage\n"
	text += " \n"

	text += "[color=GOLD]Grotesque Awakening[/color]\n"
	text += "Whenever hit by a spell, the statue comes to life for 5 seconds, enabling it to attack. This ability is affected by buff duration.\n"
	text += " \n"

	text += "[color=GOLD]Arcane Aura - Aura[/color]\n"
	text += "Towers in 350 range have a 10% chance to replenish 10% of their total manapool when casting an ability that costs mana. Cannot retrigger on the same tower within 5 seconds. This effect will also proc off Harby's Arcane Orb attacks, without the retrigger restriction.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+0.2% maximum mana replenished\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Arcane Orb[/color]\n"
	text += "Infuses Harby's attacks with arcane energy at the cost of mana.\n"
	text += " \n"

	text += "[color=GOLD]Grotesque Awakening[/color]\n"
	text += "Whenever hit by a spell, the statue comes to life.\n"
	text += " \n"

	text += "[color=GOLD]Arcane Aura - Aura[/color]\n"
	text += "Towers in range have a chance to replenish their mana.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)
	triggers.add_event_on_spell_targeted(on_spell_targeted)


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# spell crit damage = yes
# spell crit damage add = no
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.20, 0.05)
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.55, -0.01)
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 10)


func tower_init():
	glow_harby_aura_bt = BuffType.create_aura_effect_type("glow_harby_aura_bt", true, self)
	glow_harby_aura_bt.set_buff_tooltip("Arcane Aura\nChance to replenish mana when casting.")
	glow_harby_aura_bt.set_buff_icon("@@1@@")
	glow_harby_aura_bt.add_event_on_create(glow_harby_aura_bt_on_create)
	glow_harby_aura_bt.add_event_on_spell_casted(glow_harby_aura_bt_on_spell_casted)

	glow_harby_awaken_bt = BuffType.new("glow_harby_awaken_bt", 5, 0, true, self)
	glow_harby_awaken_bt.set_buff_icon("@@0@@")
	glow_harby_awaken_bt.set_buff_tooltip("Grotesque Awakening\nTemporarily awakened to attack.")
	glow_harby_awaken_bt.add_event_on_create(glow_harby_awaken_bt_on_create)
	glow_harby_awaken_bt.add_event_on_cleanup(glow_harby_awaken_bt_on_cleanup)

	harby_pt = ProjectileType.create("AvengerMissile.mdl", 10, 1500, self)
	harby_pt.enable_homing(harby_pt_on_hit, 0.0)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 350
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = glow_harby_aura_bt

	return [aura]


func on_attack(event: Event):
	var tower: Tower = self

	var damage: float = (6 + 0.1 * tower.get_level()) * tower.get_mana()
	var creep: Creep = event.get_target()

	if !is_awake:
		tower.order_stop()

		return

	var p: Projectile = Projectile.create_from_unit_to_unit(harby_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, creep, true, false, false)

	var arcane_aura_chance: float = 0.1 + 0.004 * tower.get_level()

	if tower.get_mana() >= 100:
		tower.subtract_mana(100, false)

		if tower.calc_chance(arcane_aura_chance):
			arcane_mana_replenish(tower)

		var floating_text: String = "+%s" % Utils.format_float(damage, 0)
		tower.get_player().display_floating_text_x(floating_text, tower, Color8(255, 0, 255, 255), 0.05, 2, 3)
		p.user_real = damage
		# p.set_model("IllidanMissile.mdl")
	else:
		p.user_real = 0


func on_kill(_event: Event):
	var tower: Tower = self
	tower.add_mana(1)


func on_spell_targeted(_event: Event):
	var tower: Tower = self
	glow_harby_awaken_bt.apply(tower, tower, 0)


func on_create(preceding_tower: Tower):
	if preceding_tower == null:
		return

	var tower: Tower = self
	var preceding_kills: int = preceding_tower.get_kills()
	# AddUnitAnimationProperties(tower.getUnit(), "stand alternate", false)
	tower.add_mana(preceding_kills)


func glow_harby_aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var last_proc_time: int = 0
	buff.user_int = last_proc_time


func glow_harby_aura_bt_on_spell_casted(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var last_proc_time: int = buff.user_int
	var autocast: Autocast = event.get_autocast_type()

#	NOTE: in original script it was 125 instead of 5 because
#	original API get_game_time() returns seconds multiplied
#	by 25. Youtd2 get_game_time() returns seconds.
	var can_proc: bool = last_proc_time + 5 < Utils.get_time() && autocast.get_manacost() > 0

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
	var effect: int = Effect.create_colored("ReplenishHealthCasterOverhead.mdl", target.get_visual_x(), target.get_visual_y(), 80, 0.0, 5, Color8(100, 100, 255, 255))
	Effect.destroy_effect_after_its_over(effect)
	var mana_gain: float = 0.1 + 0.002 * target.get_level()
	target.add_mana_perc(mana_gain)


func glow_harby_awaken_bt_on_create(_event: Event):
	var tower: Tower = self
	SFX.sfx_at_unit("PolyMorphDoneGround.mdl", tower)
	SFX.sfx_at_unit("ObsidianStatueCrumble2.mdl", tower)
	# AddUnitAnimationProperties(u, "stand alternate", true)
	# SetUnitFlyHeight(u, 100, 2000)

	CombatLog.log_ability(tower, null, "Grotesque Awakening")

	tower.is_awake = true


func glow_harby_awaken_bt_on_cleanup(_event: Event):
	var tower: Tower = self
	SFX.sfx_at_unit("PolyMorphDoneGround.mdl", tower)
	# AddUnitAnimationProperties(u, "stand alternate", false)
	# SetUnitFlyHeight(u, 40, 2000)

	CombatLog.log_ability(tower, null, "Grotesque Awakening End")

	tower.is_awake = false


func harby_pt_on_hit(p: Projectile, target: Unit):
	if target == null:
		return

	var damage: float = p.user_real
	p.do_spell_damage(target, damage)
