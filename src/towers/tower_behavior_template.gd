extends TowerBehavior


# NOTE: this script can be used as a template for tower
# behavior scripts.


# var example_bt: BuffType
# var example_pt: ProjectileType
# var multiboard: MultiboardValues


# func get_tier_stats() -> Dictionary:
# 	return {
# 		1: {foo = 123},
# 		2: {foo = 123},
# 		3: {foo = 123},
# 	}


# func load_triggers(triggers: BuffType):
# 	triggers.add_event_on_damage(on_damage)


# func tower_init():
# 	example_bt = BuffType.new("example_bt", 5, 0, true, self)
# 	var example_bt_mod: Modifier = Modifier.new()
# 	example_bt_mod.add_modification(ModificationType.enm.MOD_ARMOR, 0.0, 0.0)
# 	example_bt.set_buff_modifier(example_bt_mod)
# 	example_bt.set_buff_icon("res://resources/icons/generic_icons/egg.tres")
# 	example_bt.set_buff_icon_color(Color.WHITE)
# 	example_bt.set_buff_tooltip(tr("TRANSLATION_ID_GOES_HERE"))

#	example_pt = ProjectileType.create("path_to_projectile_sprite", 0, 1000, self)
#	example_pt.enable_homing(example_pt_on_hit, 0)

#	multiboard = MultiboardValues.new(2)
#	var foo_label: String = tr("XYZW")
#	multiboard.set_key(0, foo_label)


# func on_damage(event: Event):
#	pass


# func on_autocast(event: Event):
#	pass


# func on_tower_details() -> MultiboardValues:
# 	multiboard.set_value(0, "Foo value")

# 	return multiboard


# func example_pt_on_hit(p: Projectile, target: Unit):
# 	if target == null:
# 		return

# 	tower.do_spell_damage(target, 123, tower.calc_spell_crit_no_bonus())
