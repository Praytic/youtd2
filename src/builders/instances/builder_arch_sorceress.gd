extends Builder


func _get_tower_modifier() -> Modifier:
    var mod: Modifier = Modifier.new()
    mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, 0.50, 0.0)
    mod.add_modification(ModificationType.enm.MOD_SPELL_CRIT_CHANCE, 0.20, 0.0)
    mod.add_modification(ModificationType.enm.MOD_SPELL_CRIT_DAMAGE, 0.50, 0.02)
    mod.add_modification(ModificationType.enm.MOD_DMG_TO_MAGIC, 0.0, 0.01)

    mod.add_modification(ModificationType.enm.MOD_DAMAGE_BASE_PERC, -0.10, -0.012)

    return mod
