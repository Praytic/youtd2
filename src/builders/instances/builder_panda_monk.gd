extends Builder

# NOTE: this builder was named "Pandaren Monk" in original
# youtd

func _get_tower_modifier() -> Modifier:
    var mod: Modifier = Modifier.new()
    mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.25, 0.0)
    mod.add_modification(ModificationType.enm.MOD_DAMAGE_BASE_PERC, 0.15, 0.014)
    mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, 0.20, 0.012)
    mod.add_modification(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL, 0.0, 0.012)

    mod.add_modification(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL, -0.60, 0.0)
    mod.add_modification(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, -0.10, 0.0)

    return mod
