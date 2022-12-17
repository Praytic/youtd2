extends StaticBody2D


class_name Tower

enum AttackStyle {
	Shoot,
	Aoe,
	None,
}


var _internal_name: String = "" setget _private_set, _private_get


onready var _properties = Properties.towers[_internal_name] setget _private_set, _private_get
onready var attack_type: String = _properties["attack_type"]
onready var attack_range: float = _properties["attack_range"]
onready var attack_cd: float = _properties["attack_cd"]
onready var attack_style_string: String = _properties["attack_style"]
onready var id: int = _properties["id"]
onready var ingame_name: String = _properties["name"]
onready var family_id: int = _properties["family_id"]
onready var author: String = _properties["author"]
onready var rarity: String = _properties["rarity"]
onready var element: String = _properties["element"]
onready var damage_l: float = _properties["damage_l"]
onready var damage_r: float = _properties["damage_r"]
onready var cost: float = _properties["cost"]
onready var description: String = _properties["description"]
onready var texture_path: String = _properties["texture_path"]


export(int, 32, 64) var size = 32
var target_mob: Mob = null
var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var shoot_timer: Timer
var aoe_timer: Timer
var building_in_progress: bool = false
var aoe: AreaOfEffect
var attack_style = AttackStyle.None


# Must be called before add_child()
func init_internal_name(internal_name_arg: String):
	_internal_name = internal_name_arg


func _ready():
	aoe = AreaOfEffect.new(attack_range)
	aoe.position = Vector2(size, size) / 2
	add_child(aoe)
	aoe.hide()

	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	var _connect_error = shoot_timer.connect("timeout", self, "_on_shoot_timer_timeout")
	add_child(shoot_timer)

	aoe_timer = Timer.new()
	aoe_timer.one_shot = false
	var _connect_error2 = aoe_timer.connect("timeout", self, "_on_aoe_timer_timeout")
	add_child(aoe_timer)
	aoe_timer.start(attack_cd)
	
	var texture = load(texture_path)
	$Sprite.set_texture(texture)

	attack_style = attack_style_from_string(attack_style_string)


func attack_style_from_string(string: String):
	match attack_style_string:
		"shoot": return AttackStyle.Shoot
		"aoe": return AttackStyle.Aoe
		_: return AttackStyle.None


func build_init():
	aoe.show()
	building_in_progress = true


func have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return target_mob != null and is_instance_valid(target_mob)


func _on_shoot_timer_timeout():
	if !have_target():
		target_mob = find_new_target()
		
	try_to_shoot()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func find_new_target() -> Mob:
	var body_list: Array = $ShootingArea.get_overlapping_bodies()
	var closest_mob: Mob = null
	var distance_min: float = 1000000.0
	
	for body in body_list:
		var owner: Node = body.get_owner()
	
		if owner is Mob:
			var mob: Mob = owner
			var distance: float = (mob.position - position).length()
			
			if distance < distance_min:
				closest_mob = mob
				distance_min = distance
	
	return closest_mob


func try_to_shoot():
	if attack_style != AttackStyle.Shoot:
		return

	if !have_target():
		return

	if building_in_progress:
		return
	
	var shoot_on_cd = shoot_timer.time_left > 0
	
	if shoot_on_cd:
		return
	
	var projectile = projectile_scene.instance()
	projectile.target_mob = target_mob
	
#	var tower_center = position + $Base.texture.get_size() / 2
	projectile.position = position
	
#		TODO: move this to utils as get_game_scene()
	var game_scene = get_tree().get_root().get_node("GameScene")
	game_scene.call_deferred("add_child", projectile)
	
	shoot_timer.start(attack_cd)
	


func _on_ShootingArea_body_entered(body):
	if have_target():
		return
		
	var owner = body.get_owner()

	if owner is Mob:
#		New target acquired
		target_mob = owner
		try_to_shoot()


func _on_ShootingArea_body_exited(body):
	var owner = body.get_owner()

	if owner == target_mob:
#		Target has gone out of range
		target_mob = find_new_target()
		try_to_shoot()


func _on_aoe_timer_timeout():
	var body_list: Array = $ShootingArea.get_overlapping_bodies()
	
	for body in body_list:
		var owner: Node = body.get_owner()
	
		if owner is Mob:
			var mob: Mob = owner
			mob.apply_damage(4)
			print(mob)


func _private_set(_val = null):
   pass
   

func _private_get():
   pass
