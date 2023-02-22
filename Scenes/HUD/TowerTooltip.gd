extends Control


onready var base_damage_label = get_node("%BaseDamage")
onready var base_cooldown_label = get_node("%BaseCooldown")
onready var attackspeed_label = get_node("%Attackspeed")
onready var overall_cooldown_label = get_node("%OverallCooldown")


func _ready():
	pass # Replace with function body.


func set_tower_tooltip_text(tower_id: int):
	var tower = TowerManager.get_tower(tower_id)

	var base_damage = (tower.get_damage_min() + tower.get_damage_max()) / 2
	var base_cooldown = tower.get_base_cooldown()
	var attackspeed = 1.0
	var overall_cooldown = base_cooldown / attackspeed

	base_damage_label.text = comma_sep(base_damage)
	base_cooldown_label.text = "%6.2f" % base_cooldown
	attackspeed_label.text = "%6.2f" % attackspeed
	overall_cooldown_label.text = "%6.2f" % overall_cooldown


func set_tower_id(tower_id: int):
	set_tower_tooltip_text(tower_id)

func comma_sep(number) -> String:
	var string = str(number)
	var mod = string.length() % 3
	var res = ""

	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]

	return res
