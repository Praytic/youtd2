extends Builder


func _get_tower_modifier() -> Modifier:
    var mod: Modifier = Modifier.new()
    mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.0)
    mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.35, 0.0)
    mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, 0.004)
    mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.0, 0.02)
    mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 2.0, 0.0)

    mod.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, -3.0, 0.0)
    mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -1.0, 0.0)

    return mod
