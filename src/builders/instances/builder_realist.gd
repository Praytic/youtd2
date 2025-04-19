extends Builder


func _get_tower_modifier() -> Modifier:
    var mod: Modifier = Modifier.new()
    mod.add_modification(ModificationType.enm.MOD_DAMAGE_BASE_PERC, 0.15, 0.015)
    mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, 0.15, 0.015)
    mod.add_modification(ModificationType.enm.MOD_MANA_REGEN_PERC, 1.50, 0.0)

    mod.add_modification(ModificationType.enm.MOD_TRIGGER_CHANCES, -0.50, 0.0)
    mod.add_modification(ModificationType.enm.MOD_ATK_CRIT_CHANCE, -0.20, 0.0)
    mod.add_modification(ModificationType.enm.MOD_SPELL_CRIT_CHANCE, -0.20, 0.0)

    return mod
