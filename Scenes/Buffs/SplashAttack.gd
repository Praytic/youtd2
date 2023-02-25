class_name SplashAttack
extends Buff

# SplashAttack buff implements damage spreading to mobs near
# the mob that was damaged by the tower with this buff.
# "splash_map" argument in the _init() function is a
# dictionary mapping distance->damage ratio to define how
# much splash damage the tower deals. For example, a splash
# value of {100: 0.5, 300: 0.2} will deal 50% splash damage
# to units within 100yd of target and 20% to units within
# 300yd of target.


var _splash_map: Dictionary = {}


func _init(splash_map: Dictionary).("", 0, 0, true):
	_splash_map = splash_map
	add_event_on_damage(self, "on_damage")


func on_damage(event: Event):
	if _splash_map.empty():
		return

	if !event.is_main_target():
		return

	var splash_target: Unit = event.get_target()
	var damage_base: float = event.damage
	var splash_pos: Vector2 = splash_target.position

#	Process splash ranges from closest to furthers,
#	so that strongest damage is applied
	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	var splash_range_max: float = splash_range_list.back()

	var mob_list: Array = Utils.get_mob_list_in_range(splash_pos, splash_range_max)

	for mob in mob_list:
		if mob == splash_target:
			continue
		
		var distance: float = splash_pos.distance_to(mob.position)

		for splash_range in splash_range_list:
			var mob_is_in_range: bool = distance < splash_range

			if mob_is_in_range:
				var splash_damage_ratio: float = _splash_map[splash_range]
				var splash_damage: float = damage_base * splash_damage_ratio
				_caster.do_spell_damage(mob, splash_damage, 0.0, false)

				break
