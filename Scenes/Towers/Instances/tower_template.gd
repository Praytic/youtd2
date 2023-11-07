extends Tower

# NOTE: not a real tower script, used as a template for
# tower scripts.


# func get_tier_stats() -> Dictionary:
# 	return {
# 		1: {foo = 123},
# 		2: {foo = 123},
# 		3: {foo = 123},
# 	}


# func get_ability_description() -> String:
# 	var foo: String = Utils.format_float(_stats.foo, 2)
# 	var bar: String = Utils.format_float(_stats.bar, 2)

# 	var text: String = ""

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

# 	return text


# func get_autocast_description() -> String:
# 	var foo: String = Utils.format_float(_stats.foo, 2)
# 	var bar: String = Utils.format_float(_stats.bar, 2)

# 	var text: String = ""

# 	text += "Description\n"
#	text += " \n"
# 	text += "[color=ORANGE]Level Bonus:[/color]\n"
# 	text += "foo\n"
# 	text += "bar\n"

# 	return text


# func get_autocast_description_short() -> String:
#	return "Description\n"


# func load_triggers(triggers: BuffType):
# 	triggers.add_event_on_damage(on_damage)


# func load_specials(modifier: Modifier):
# 	modifier.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)


# func tower_init():
# 	example_buff = BuffType.new("example_buff", 5, 0, true, self)
# 	var mod: Modifier = Modifier.new()
# 	mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
# 	example_buff.set_buff_modifier(mod)
# 	example_buff.set_buff_icon("@@0@@")
# 	example_buff.set_buff_tooltip("Title\nDescription.")

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

