extends Control


onready var base_damage_label = get_node("%BaseDamage")
onready var base_cooldown_label = get_node("%BaseCooldown")
onready var base_damage_bonus_label = get_node("%BaseDamageBonus")
onready var base_damage_bonus_percent_label = get_node("%BaseDamageBonusPercent")
onready var damage_add_label = get_node("%DamageAdd")
onready var damage_add_percent_label = get_node("%DamageAddPercent")
onready var overall_damage_label = get_node("%OverallDamage")
onready var attackspeed_label = get_node("%Attackspeed")
onready var overall_cooldown_label = get_node("%OverallCooldown")


func _ready():
	pass # Replace with function body.


func set_tower_tooltip_text(tower_id: int):
	var tower = TowerManager.get_tower(tower_id)

	var base_damage = (tower.get_damage_min() + tower.get_damage_max()) / 2
	var base_damage_bonus = 0.0
	var base_damage_bonus_percent = 0.0
	var damage_add = 0.0
	var damage_add_percent = 0.0
	var base_cooldown = tower.get_base_cooldown()
	var attackspeed = tower.get_base_attack_speed()
	var overall_cooldown = tower.get_overall_cooldown()
	var overall_base_damage = (base_damage + base_damage_bonus) * (1 + base_damage_bonus_percent)
	var overall_damage = (overall_base_damage + damage_add) * (1 + damage_add_percent)

	base_damage_label.text = comma_sep(base_damage)
	base_damage_bonus_label.text = comma_sep(base_damage_bonus)
	base_damage_bonus_percent_label.text = percent(base_damage_bonus_percent)
	damage_add_label.text = comma_sep(damage_add)
	damage_add_percent_label.text = percent(damage_add_percent)
	overall_damage_label.text = comma_sep(overall_base_damage)
	
	base_cooldown_label.text = comma_sep(base_cooldown)
	attackspeed_label.text = percent(attackspeed, 1.0)
	overall_cooldown_label.text = comma_sep(overall_cooldown)


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

func percent(number, base = 0.0) -> String:
	var sign_str = ""
	match sign(number - base):
		-1.0: sign_str = "-"
		1.0: sign_str = "+"
	return "%s%.2f" % [sign_str, abs(number - base)]
