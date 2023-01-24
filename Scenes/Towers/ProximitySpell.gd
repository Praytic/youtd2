extends Node2D


var explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
onready var game_scene: Node = get_tree().get_root().get_node("GameScene")

var aura_list: Array
var target_type: int
var default_cast_cd: float
var cast_cd_mod: float = 0.0


func _ready():
	pass


func init(spell_info: Dictionary):
	default_cast_cd = spell_info[Properties.SpellParameter.CAST_CD]
	$CastTimer.wait_time = default_cast_cd

	var cast_range = spell_info[Properties.SpellParameter.CAST_RANGE]
	Utils.circle_shape_set_radius($CastArea/CollisionShape2D, cast_range)

	aura_list = spell_info[Properties.SpellParameter.AURA_LIST]
	target_type = spell_info[Properties.SpellParameter.TARGET_TYPE]


func _on_CastTimer_timeout():
	var body_list: Array = $CastArea.get_overlapping_bodies()

	for body in body_list:
		if target_type == Properties.SpellTargetType.MOBS && body is Mob:
			var mob: Mob = body as Mob
			mob.add_aura_list(aura_list)
			
			var explosion = explosion_scene.instance()
			explosion.position = mob.position
			game_scene.call_deferred("add_child", explosion)
		elif target_type == Properties.SpellTargetType.TOWERS && body.is_class("Tower"):
#			Can't use "is Tower" here because of circular
#			dependency
			body.add_aura_list(aura_list)


func apply_aura(aura: Aura):
	match aura.type:
		Properties.AuraType.DECREASE_CAST_CD:
			if aura.is_expired:
				cast_cd_mod = 0.0
			else:
				cast_cd_mod = aura.value

			$CastTimer.wait_time = default_cast_cd * (1.0 - cast_cd_mod)
		_: print_debug("unhandled aura.type in ProximitySpell.apply_aura():", aura.type)
