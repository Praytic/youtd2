# The Divine Wings of Tragedy
extends Item


var dmg_aura: BuffType


func get_ability_description() -> String:
    var text: String = ""

    text += "[color=GOLD]The Divine Wings of Tragedy - Aura[/color]\n"
    text += "Increases attack damage and attack speed of towers in 250 range by 15%.\n"

    return text


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.37, 0)


func item_init():
    var m: Modifier = Modifier.new()
    var damage_aura = BuffType.create_aura_effect_type("item230_damage_aura", true, self)
    m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.15, 0.0)
    m.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.15, 0.0)
    damage_aura.set_buff_modifier(m)
    damage_aura.set_buff_icon("@@0@@")
    damage_aura.set_stacking_group("dmgaura")
    damage_aura.set_buff_tooltip("The Divine Wings of Tragedy\nThis unit is under the effect of The Divine Wings of Tragedy Aura; it has increased attack damage and attack speed.")

    var aura: AuraType = AuraType.new()
    aura.aura_range = 250
    aura.target_type = TargetType.new(TargetType.TOWERS)
    aura.target_self = true
    aura.level = 0
    aura.level_add = 1
    aura.power = 0
    aura.power_add = 1
    aura.aura_effect = damage_aura
    add_aura(aura)
