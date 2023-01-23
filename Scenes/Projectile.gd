extends KinematicBody2D


var target_mob: Mob = null
export var speed: int = 100
export var contact_distance: int = 30
var aura_list: Array = []
var projectile_range: float

onready var object_container = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("MobYSort")


# TODO: duplicated in GunT1.gd, move somewhere to share in both places
func have_target() -> bool:
	return target_mob != null and is_instance_valid(target_mob)

func _process(delta):
	if !have_target():
		queue_free()
		return
	
#	Move towards mob
	var target_pos = target_mob.position
	var pos_diff = target_pos - position
	
	var reached_mob = pos_diff.length() < contact_distance
	
	if reached_mob:
		var mob_list = get_affected_mob_list()

		for mob in mob_list:
			mob.add_aura_list(aura_list)

		queue_free()
		return
	
	var move_vector = speed * pos_diff.normalized() * delta
	
	position += move_vector
	

func get_affected_mob_list() -> Array:
	var apply_to_target_only = projectile_range == 0

	if apply_to_target_only:
		return [target_mob]
	else:
		var mob_list: Array = []

		for node in object_container.get_children():
			if node is Mob:
				var mob: Mob = node as Mob
				var distance: float = position.distance_to(mob.position)
				var mob_is_in_range = distance < projectile_range

				if mob_is_in_range:
					mob_list.append(mob)

		return mob_list


