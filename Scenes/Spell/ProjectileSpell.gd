extends Node2D


# ProjectileSpell periodically fires projectiles on targets
# When a valid target enters tower's range, tower will stick
# to that same target until it goes out of range or dies.
# Whenever timer times out, ProximitySpell creates a
# projectile and passes aura info list to it. The projectile
# begins travelling to the tower's target. When the
# projectile reaches the target, aura info list is passed to
# the target.


onready var game_scene: Node = get_tree().get_root().get_node("GameScene")

var spell_scene: PackedScene = preload("res://Scenes/Spell/Spell.tscn")
var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var target_mob: Mob = null
var spell: Spell


func _ready():
	pass


func init(spell_info: Dictionary):
	spell = spell_scene.instance()
	add_child(spell)
	spell.init(spell_info)

	var cast_timer: Timer = spell.get_cast_timer()
	cast_timer.connect("timeout", self, "_on_CastTimer_timeout")
# 	NOTE: cast timer starts in expired state and is started
# 	after every cast
	cast_timer.one_shot = true
	cast_timer.start()

	var cast_area: Area2D = spell.get_cast_area()
	cast_area.connect("body_entered", self, "_on_CastArea_body_entered")
	cast_area.connect("body_exited", self, "_on_CastArea_body_exited")


func _on_CastTimer_timeout():
	if !have_target():
		target_mob = find_new_target()
		
	try_to_shoot()


func _on_CastArea_body_entered(body):
	if have_target():
		return
		
	if body is Mob:
#		New target acquired
		target_mob = body
		try_to_shoot()


func _on_CastArea_body_exited(body):
	if body == target_mob:
#		Target has gone out of range
		target_mob = find_new_target()
		try_to_shoot()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func find_new_target() -> Mob:
	var cast_area: Area2D = spell.get_cast_area()
	var body_list: Array = cast_area.get_overlapping_bodies()
	var closest_mob: Mob = null
	var distance_min: float = 1000000.0
	
	for body in body_list:
		if body is Mob:
			var mob: Mob = body
			var distance: float = (mob.position - self.position).length()
			
			if distance < distance_min:
				closest_mob = mob
				distance_min = distance
	
	return closest_mob


func try_to_shoot():
	if !have_target():
		return
	
	var cast_timer: Timer = spell.get_cast_timer()
	var shoot_on_cd = cast_timer.time_left > 0
	
	if shoot_on_cd:
		return
	
	var projectile = projectile_scene.instance()
	projectile.init(target_mob, global_position, spell.get_modded_aura_info())

	game_scene.call_deferred("add_child", projectile)
	
	cast_timer.start()


func have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return target_mob != null and is_instance_valid(target_mob)


func apply_aura(aura: Aura):
	spell.apply_aura(aura)
