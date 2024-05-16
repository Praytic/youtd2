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


# func get_ability_info_list() -> Array[AbilityInfo]:
# 	var list: Array[AbilityInfo] = []
	
# 	var ability: AbilityInfo = AbilityInfo.new()
# 	ability.name = "Ability Foo"
# 	ability.description_short = "FOOBAR\n"
# 	ability.description_full = "FOOBAR\n"
# 	list.append(ability)

# 	return list


# func load_triggers(triggers: BuffType):
# 	triggers.add_event_on_damage(on_damage)


# func load_specials(modifier: Modifier):
# 	modifier.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)


# func tower_init():
# 	example_bt = BuffType.new("example_bt", 5, 0, true, self)
# 	var example_bt_mod: Modifier = Modifier.new()
# 	example_bt_mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
# 	example_bt.set_buff_modifier(example_bt_mod)
# 	example_bt.set_buff_icon("res://resources/icons/GenericIcons/egg.tres")
# 	example_bt.set_buff_icon_color(Color.WHITE)
# 	example_bt.set_buff_tooltip("Title\nDescription.")

#	example_pt = ProjectileType.create("ProjectileModel.mdl", 0, 1000, self)
#	example_pt.enable_homing(example_pt_on_hit, 0)

#	multiboard = MultiboardValues.new(2)
#	multiboard.set_key(0, "Foo")
#	multiboard.set_key(1, "Bar")


# func create_autocasts() -> Array[Autocast]:
# 	var autocast: Autocast = Autocast.make()

# 	autocast.title = "Title"
# 	autocast.icon = "res://path/to/icon.png"
# 	autocast.description_short = ""
# 	autocast.description = ""
# 	autocast.caster_art = ""
# 	autocast.target_art = ""
# 	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
# 	autocast.num_buffs_before_idle = 0
# 	autocast.cast_range = 1200
# 	autocast.auto_range = 1200
# 	autocast.cooldown = 1
# 	autocast.mana_cost = 20
# 	autocast.target_self = false
# 	autocast.is_extended = false
# 	autocast.buff_type = null
# 	autocast.target_type = TargetType.new(TargetType.TOWERS)
# 	autocast.handler = on_autocast

#	return [autocast]


# func get_aura_types() -> Array[AuraType]:
# 	var aura: AuraType = AuraType.new()

# 	aura.name = ""
# 	aura.icon = ""
# 	aura.description_short = ""
# 	aura.description_full = ""

# 	aura.aura_range = 200
# 	aura.target_type = TargetType.new(TargetType.TOWERS)
# 	aura.target_self = true
# 	aura.level = 0
# 	aura.level_add = 1
# 	aura.power = 0
# 	aura.power_add = 1
# 	aura.aura_effect = aura_effect

# 	return [aura]


# func on_damage(event: Event):
#	pass


# func on_autocast(event: Event):
#	pass


# func on_tower_details() -> MultiboardValues:
# 	multiboard.set_value(0, "Foo value")
# 	multiboard.set_value(1, "Bar value")

# 	return multiboard


# func example_pt_on_hit(p: Projectile, target: Unit):
# 	if target == null:
# 		return

# 	tower.do_spell_damage(target, 123, tower.calc_spell_crit_no_bonus())
