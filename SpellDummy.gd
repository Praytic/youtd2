class_name SpellDummy extends DummyUnit


# TODO: implement "blizzard" spell

@onready var _debug_sprite: Sprite2D = $DebugSprite


func _ready():
	_debug_sprite.visible = FF.visible_spell_dummys_enabled()
