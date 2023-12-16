extends Tower

# NOTE: not a real tower script, used as a template for
# tower scripts.

# var example_bt: BuffType
# var example_pt: ProjectileType
# var example_multiboard: MultiboardValues


# func get_tier_stats() -> Dictionary:
# 	return {
# 		1: {foo = 123},
# 		2: {foo = 123},
# 		3: {foo = 123},
# 	}


# func get_ability_description() -> String:
# 	var text: String = ""

# 	text += "[color=GOLD]Title[/color]\n"
# 	text += "Description\n"
# 	text += " \n"
# 	text += "[color=ORANGE]Level Bonus:[/color]\n"
# 	text += "foo\n"
# 	text += "bar\n"
# 	text += " \n"

# 	text += "[color=GOLD]Title[/color]\n"
# 	text += "Description\n"
# 	text += " \n"
# 	text += "[color=ORANGE]Level Bonus:[/color]\n"
# 	text += "foo\n"
# 	text += "bar\n"
# 	text += " \n"

# 	text += "[color=GOLD]Title[/color]\n"
# 	text += "Description\n"
# 	text += " \n"
# 	text += "[color=ORANGE]Level Bonus:[/color]\n"
# 	text += "foo\n"
# 	text += "bar\n"

# 	return text


# func get_ability_description_short() -> String:
# 	var text: String = ""

# 	text += "[color=GOLD]Title[/color]\n"
# 	text += "Description\n"
# 	text += " \n"

# 	text += "[color=GOLD]Title[/color]\n"
# 	text += "Description\n"
# 	text += " \n"

# 	text += "[color=GOLD]Title[/color]\n"
# 	text += "Description\n"


# 	return text


# func get_autocast_description() -> String:
# 	var text: String = ""

# 	text += "Description\n"
#	text += " \n"
# 	text += "[color=ORANGE]Level Bonus:[/color]\n"
# 	text += "foo\n"
# 	text += "bar\n"

# 	return text


# func get_autocast_description_short() -> String:
# 	var text: String = ""

# 	text += "Description\n"

# 	return text


# func load_triggers(triggers: BuffType):
# 	triggers.add_event_on_damage(on_damage)


# func load_specials(modifier: Modifier):
# 	modifier.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)


# func tower_init():
# 	example_bt = BuffType.new("example_bt", 5, 0, true, self)
# 	var example_bt_mod: Modifier = Modifier.new()
# 	example_bt_mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
# 	example_bt.set_buff_modifier(example_bt_mod)
# 	example_bt.set_buff_icon("@@0@@")
# 	example_bt.set_buff_tooltip("Title\nDescription.")

#	example_pt = ProjectileType.create("ProjectileModel.mdl", 0, 1000, self)
#	example_pt.enable_homing(example_pt_on_hit, 0)

#	example_multiboard = MultiboardValues.new(2)
#	example_multiboard.set_key(0, "Foo")
#	example_multiboard.set_key(1, "Bar")

# 	var autocast: Autocast = Autocast.make()
# 	autocast.title = "Title"
# 	autocast.description = get_autocast_description()
# 	autocast.description_short = get_autocast_description_short()
# 	autocast.icon = "res://path/to/icon.png"
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
# 	add_autocast(autocast)


# func get_aura_types() -> Array[AuraType]:
# 	var aura: AuraType = AuraType.new()
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
# 	var tower: Tower = self


# func on_autocast(event: Event):
# 	var tower: Tower = self


# func on_tower_details() -> MultiboardValues:
# 	example_multiboard.set_value(0, "Foo value")
# 	example_multiboard.set_value(1, "Bar value")

# 	return example_multiboard
