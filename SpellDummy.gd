class_name SpellDummy extends DummyUnit


# TODO: implement "blizzard" spell

@onready var _debug_sprite: Sprite2D = $DebugSprite


func _ready():
	var visible_spell_dummys: bool = ProjectSettings.get_setting("application/config/visible_spell_dummys") as bool
	_debug_sprite.visible = visible_spell_dummys
