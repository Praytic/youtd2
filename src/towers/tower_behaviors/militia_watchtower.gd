extends TowerBehavior


var axe_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {miss_chance_add = 0.01, dmg_to_boss_add = 0.006, dmg_to_undead_add = 0.004, dmg_to_nature_add = 0.004},
		2: {miss_chance_add = 0.011, dmg_to_boss_add = 0.007, dmg_to_undead_add = 0.005, dmg_to_nature_add = 0.005},
		3: {miss_chance_add = 0.011, dmg_to_boss_add = 0.008, dmg_to_undead_add = 0.006, dmg_to_nature_add = 0.006},
		4: {miss_chance_add = 0.012, dmg_to_boss_add = 0.009, dmg_to_undead_add = 0.007, dmg_to_nature_add = 0.007},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var miss_chance_add: String = Utils.format_percent(_stats.miss_chance_add, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Hail of Axes"
	ability.icon = "res://resources/icons/hud/recipe_reassemble.tres"
	ability.description_short = "Militia guardians throw axes to up to 3 enemies at once, but each axe has a chance to miss.\n"
	ability.description_full = "Militia guardians throw axes to up to 3 enemies at once, but each axe has 33% chance to miss. If there are less creeps than axes, the remaining axes will hit the main target.\n" \
	+ " \n" \
	+ "[color=GOLD]Note:[/color] these extra axes will not trigger any \"on hit\" abilities.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "-%s chance to miss\n" % miss_chance_add \
	+ "+1 target at levels 15 and 25\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, -0.20, _stats.dmg_to_boss_add)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.20, _stats.dmg_to_undead_add)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.20, _stats.dmg_to_nature_add)


func axe_pt_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	if tower.calc_bad_chance(0.33 - _stats.miss_chance_add * tower.get_level()):
		tower.get_player().display_floating_text_x("Miss", tower, Color8(255, 0, 0, 255), 0.05, 0.0, 2.0)
	else:
		tower.do_attack_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit_no_bonus())


func tower_init():
	axe_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 800, self)
	axe_pt.set_event_on_interpolation_finished(axe_pt_hit)


func on_attack(event: Event):
	var attacks: int = 2
	var add: bool = false
	var maintarget: Unit = event.get_target()
	var target: Unit
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), maintarget, 450)
	var sidearc: float = 0.20
	var it_destroyed: bool = false

	if tower.get_level() >= 15:
		attacks = attacks + 1

	if tower.get_level() >= 25:
		attacks = attacks + 1

	while true:
#		Exit when all attacks are fired
		if attacks == 0:
			return

#		If the Iterate is not destroyed, get the next target
		if !it_destroyed:
			target = it.next()

#			If there are no more targets
			if target == null:
#				Iterate is destroyed (auto destroy)
				it_destroyed = true
#				target is the maintarget now
				target = maintarget

#		If there are no more units, shoot at the maintarget
#		(itDestroyed). If there are units then don't shoot
#		at the maintarget
		if it_destroyed || target != maintarget:
			Projectile.create_bezier_interpolation_from_unit_to_unit(axe_pt, tower, 0, 0, tower, target, 0, sidearc, 0, true).set_projectile_scale(0.40)
			attacks = attacks - 1
			sidearc = -sidearc

			if add:
				sidearc = sidearc + 0.020

			add = !add


func on_damage(event: Event):
	if tower.calc_bad_chance(0.33 - _stats.miss_chance_add * tower.get_level()):
		event.damage = 0
		tower.get_player().display_floating_text_x("Miss", tower, Color8(255, 0, 0, 255), 0.05, 0.0, 2.0)


func on_create(_preceding_tower: Tower):
# 	Save the family member (1 = first member)
	tower.user_int = tower.get_tier()
# 	Used to save the buff (double linked list)
	tower.user_int2 = 0
