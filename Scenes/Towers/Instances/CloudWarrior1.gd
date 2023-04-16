extends Tower


# NOTE: replaced (creep.getUID() == cid) with
# is_instance_valid(creep). Both serve the purpose of
# checking whether creep still exists.


func _get_tier_stats() -> Dictionary:
	return {
		1: {lightning_dmg = 100, lightning_dmg_add = 5},
		2: {lightning_dmg = 300, lightning_dmg_add = 15},
		3: {lightning_dmg = 750, lightning_dmg_add = 37.5},
		4: {lightning_dmg = 1875, lightning_dmg_add = 93.75},
		5: {lightning_dmg = 3750, lightning_dmg_add = 187.5},
	}


func get_extra_tooltip_text() -> String:
	var lightning_dmg: String = String.num(_stats.lightning_dmg, 2)
	var lightning_dmg_add: String = String.num(_stats.lightning_dmg_add * 100, 2)

	return "[color=gold]Lightning Strike[/color]\nWhenever this tower's attack does not bounce it shoots down a delayed lightning bolt onto the target. The lightning bolt deals %s Energy damage.\n[color=orange]Level Bonus:[/color]\n+%s damage" % [lightning_dmg, lightning_dmg_add]


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(self, "on_damage", 0.3, 0.0)


func load_specials(_modifier: Modifier):
	_set_attack_style_bounce(2, 0.0)


func on_create():
	user_int = 0
	

func on_damage(event: Event):
	var tower: Unit = self

	var creep: Unit = event.get_target()

	if event.is_main_target() == true:
		tower.user_int = 1
	else:
		tower.user_int = 0

	await get_tree().create_timer(0.4).timeout

	if tower.user_int == 1 && is_instance_valid(creep):
		Utils.sfx_at_unit("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", creep)
		tower.do_attack_damage(creep, _stats.lightning_dmg + (_stats.lightning_dmg_add * tower.get_level()), tower.calc_attack_multicrit(0.0, 0.0, 0.0))
