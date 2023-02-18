class_name BounceAttack
extends Buff

# BounceAttack buff implements damage bouncing from main
# target in a chain to N other mobs.

# TODO: does bounce count include the main target? For
# example, if bounce count is 3, does that mean 3 mobs are
# damaged in total, or 4 mobs (main target + 3 more).

# TODO: what should be the bounce range? Seems to be the same for all towers.

const BOUNCE_RANGE: float = 200.0

var _bounce_count: int = 0
var _bounce_damage_decrease: float = 0.0


func _init(bounce_count: int, bounce_damage_multiplier: float).("bounce_attack"):
	_bounce_count = bounce_count
	_bounce_damage_decrease = bounce_damage_multiplier
	add_event_handler(Buff.EventType.DAMAGE, self, "on_damage")


func on_damage(event: Event):
	if !event.is_main_target():
		return

	var current_target: Unit = event.get_target()
	var current_damage: float = event.damage
	var visited_list: Array = [current_target]

	for _i in range(_bounce_count - 1):

		var mob_list: Array = Utils.get_mob_list_in_range(current_target.position, BOUNCE_RANGE)

#		NOTE: sort list to prioritize closest units
		Utils.sort_unit_list_by_distance(mob_list, current_target.position)

		for mob in mob_list:
			var already_visited: bool = visited_list.has(mob)
			
			if already_visited:
				continue

			var new_target: Unit = mob
			current_damage *= (1.0 - _bounce_damage_decrease)
		
			_caster.do_spell_damage(new_target, current_damage, 0.0, false)
			visited_list.append(new_target)

			current_target = new_target

			break
