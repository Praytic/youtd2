extends Tower


# NOTE: original script uses "acidbomb" cast for the acid
# skull ability. Implemented it using regular projectile
# instead.

# NOTE: also, original script applies armor debuffs before
# acid skull hits the targets. That is weird, changed it so
# that debuffs are applied after the projectile hits the
# target.


var sir_soul_vault_acid_skull_bt: BuffType
var sir_soul_vault_soulsteal_bt: BuffType
var sir_soul_vault_aura_bt: BuffType
var acid_skull_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Acid Skull[/color]\n"
	text += "This tower has a 25% chance to throw an Acid Skull onto the target, dealing 1800 damage to the main target and 1440 damage to targets in 225 range and reducing their armor by 5 over 4.5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+5% damage\n"
	text += "+0.4% chance\n"
	text += " \n"

	text += "[color=GOLD]Soulsteal[/color]\n"
	text += "This tower has a 12.5% chance to lock its target's soul. A unit without a soul will receive 50% more spell damage.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% chance\n"
	text += "+2% more spell damage taken\n"
	text += " \n"

	text += "[color=GOLD]Vault's Presence - Aura[/color]\n"
	text += "Units in 775 range have their armor reduced by 25%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% armor reduction\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""


	text += "[color=GOLD]Acid Skull[/color]\n"
	text += "Chance to throw an Acid Skull onto the target and nearby units.\n"
	text += " \n"

	text += "[color=GOLD]Soulsteal[/color]\n"
	text += "Chance to lock target's soul. A unit without a soul will receive more spell damage.\n"
	text += " \n"

	text += "[color=GOLD]Vault's Presence - Aura[/color]\n"
	text += "Units in range have their armor reduced.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	sir_soul_vault_aura_bt = BuffType.create_aura_effect_type("sir_soul_vault_aura_bt", false, self)
	var sir_soul_vault_aura_mod: Modifier = Modifier.new()
	sir_soul_vault_aura_mod.add_modification(Modification.Type.MOD_ARMOR_PERC, -0.25, -0.002)
	sir_soul_vault_aura_bt.set_buff_modifier(sir_soul_vault_aura_mod)
	sir_soul_vault_aura_bt.set_buff_icon("@@1@@")
	sir_soul_vault_aura_bt.set_buff_tooltip("Vault's Presence - Aura\nThis unit is under the effect of Vault's Presence Aura; it has reduced armor.")

	sir_soul_vault_acid_skull_bt = BuffType.new("sir_soul_vault_acid_skull_bt", 4.5, 0, false, self)
	var sir_soul_vault_acid_skull_mod: Modifier = Modifier.new()
	sir_soul_vault_acid_skull_mod.add_modification(Modification.Type.MOD_ARMOR, 0.50, 0.02)
	sir_soul_vault_acid_skull_bt.set_buff_modifier(sir_soul_vault_acid_skull_mod)
	sir_soul_vault_acid_skull_bt.set_buff_icon("@@0@@")
	sir_soul_vault_acid_skull_bt.set_buff_tooltip("Acid Skull\nThis unit was hit by an Acid Skull; it has reduced armor.")

	sir_soul_vault_soulsteal_bt = BuffType.new("sir_soul_vault_soulsteal_bt", 1000, 0, false, self)
	var sir_soul_vault_soulsteal_mod: Modifier = Modifier.new()
	sir_soul_vault_soulsteal_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.50, 0.02)
	sir_soul_vault_soulsteal_bt.set_buff_modifier(sir_soul_vault_soulsteal_mod)
	sir_soul_vault_soulsteal_bt.set_buff_icon("@@2@@")
	sir_soul_vault_soulsteal_bt.set_buff_tooltip("Soulsteal\nThis unit's soul was stolen; it will receive extra spell damage.")

	acid_skull_pt = ProjectileType.create("Hippogryph.mdl", 20, 700, self)
	acid_skull_pt.enable_homing(acid_skull_pt_on_hit, 0)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 775
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = sir_soul_vault_aura_bt

	return [aura]


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var acid_skull_chance: float = 0.25 + 0.004 * tower.get_level()

	if !tower.calc_chance(acid_skull_chance):
		return

	Projectile.create_from_unit_to_unit(acid_skull_pt, tower, 1.0, 1.0, tower, target, true, false, false)


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var soulsteal_chance: float = 0.125 + 0.001 * tower.get_level()

	if !tower.calc_chance(soulsteal_chance):
		return

	sir_soul_vault_soulsteal_bt.apply(tower, target, tower.get_level())


func acid_skull_pt_on_hit(_projectile: Projectile, target: Unit):
	var tower: Tower = self
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 225)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var is_main_target: bool = next == target

		var skull_damage: float
		if is_main_target:
			skull_damage = 1800 * (1.0 + 0.05 * tower.get_level())
		else:
			skull_damage = 1440 * (1.0 + 0.05 * tower.get_level())

		tower.do_spell_damage(next, skull_damage, tower.calc_spell_crit_no_bonus())
		sir_soul_vault_acid_skull_bt.apply(tower, next, tower.get_level())
