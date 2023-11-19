class_name Tower
extends Building


signal items_changed()


# NOTE: order of CsvProperty enums must match the order of
# the columns in tower_properties.csv
enum CsvProperty {
	NAME,
	TIER,
	ID,
	FAMILY_ID,
	AUTHOR,
	RARITY,
	ELEMENT,
	ATTACK_TYPE,
	ATTACK_RANGE,
	ATTACK_CD,
	ATTACK_DAMAGE_MIN,
	ATTACK_DAMAGE_MAX,
	MANA,
	MANA_REGEN,
	COST,
	DESCRIPTION,
	REQUIRED_ELEMENT_LEVEL,
	REQUIRED_WAVE_LEVEL,
	ICON_ATLAS_NUM,
	RELEASE,
}

enum AttackStyle {
	NORMAL,
	SPLASH,
	BOUNCE,
}


const TOWER_SELECTION_VISUAL_SIZE: int = 128
const TARGET_TYPE_GROUND_ONLY: int = TargetType.CREEPS + TargetType.SIZE_MASS + TargetType.SIZE_NORMAL + TargetType.SIZE_CHAMPION + TargetType.SIZE_BOSS
const TARGET_TYPE_AIR_ONLY: int = TargetType.CREEPS + TargetType.SIZE_AIR

var _id: int = 0
var _stats: Dictionary
var _splash_map: Dictionary = {}
var _bounce_count_max: int = 0
var _bounce_damage_multiplier: float = 0.0
var _attack_style: AttackStyle = AttackStyle.NORMAL
# NOTE: _target_list must be an untyped Array because it may
# contain invalid instances.
var _target_list: Array = []
var _target_count_max: int = 1
var _default_projectile_type: ProjectileType
var _current_attack_cooldown: float = 0.0
var _was_ordered_to_stop_attack: bool = false
var _was_ordered_to_change_target: bool = false
var _new_target_from_order: Unit
var _item_container: TowerItemContainer
var _specials_modifier: Modifier = Modifier.new()
# NOTE: preceding tower reference is valid only during
# creation. It is also always null for first tier towers.
var _temp_preceding_tower: Tower = null
# This attack type determines which targets will be picked
# for attacking.
var _attack_target_type: TargetType = TargetType.new(TargetType.CREEPS)
var _placeholder_modulate: Color = Color.WHITE
var _aura_range_indicator_list: Array[RangeIndicator] = []


# NOTE: can't use @export because it breaks placeholder
# tower scenes.
@onready var _range_indicator: RangeIndicator = $RangeIndicator
@onready var _mana_bar: ProgressBar = $Visual/ManaBar
@onready var _tower_selection_area: Area2D = $Visual/TowerSelectionArea
# NOTE: $Model/Sprite2D node is added in Tower subclass scenes 
@onready var _model: Node2D = $Model
@onready var _sprite: Sprite2D = $Model/Sprite2D
@onready var _tower_actions: Control = $Visual/TowerActions
@onready var _visual: Node2D = $Visual

#########################
### Code starts here  ###
#########################

# NOTE: these f-ns needs to be called here and not in
# ready() so that we can form tooltip text for button
# tooltip.
# NOTE: this is also called separately when tower is used by
# TowerPreview.
func _internal_tower_init():
# 	Load stats for current tier. Stats are defined in
# 	subclass.
	var tier: int = get_tier()
	var tier_stats: Dictionary = get_tier_stats()
	_stats = tier_stats[tier]

	load_specials(_specials_modifier)


func _ready():
	super()

	_set_visual_node(_visual)

#	If this tower is used for towerpreview, then exit early
#	out of ready() so that no event handlers or auras are
#	created so that the tower instance is inactive. Also,
#	this early exit has to happen before adjusting positions
#	of visuals so that tower preview is correctly drawn
#	under mouse.
	if _visual_only:
		_mana_bar.hide()

		return

#	Apply offsets to account for tower being "on the second floor".
#	Visual nodes get moved up by one tile.
# 	Also move selection visual because it's placed at ground
# 	position in Unit.gd but needs to be at visual position
# 	for towers.
#	NOTE: important to use "-=" instead of "=" because these
#	nodes may have default values which we don't want to
#	override
	_visual.position.y -= Constants.TILE_HEIGHT
	_model.position.y -= Constants.TILE_HEIGHT
	_selection_visual.position.y -= Constants.TILE_HEIGHT

	var base_mana: float = get_csv_property(CsvProperty.MANA).to_float()
	set_base_mana(base_mana)
	set_mana(0)

	var base_mana_regen: float = get_csv_property(CsvProperty.MANA_REGEN).to_float()
	set_base_mana_regen(base_mana_regen)

	var inventory_capacity: int = get_inventory_capacity()
	_item_container = TowerItemContainer.new(inventory_capacity, self)
	add_child(_item_container)
	_item_container.items_changed.connect(_on_item_container_items_changed)

	add_to_group("towers")

	var attack_range: float = get_range()
	_range_indicator.set_radius(attack_range)

	mana_changed.connect(_on_mana_changed)
	_on_mana_changed()
	_mana_bar.visible = get_base_mana() > 0

	_default_projectile_type = ProjectileType.create("", 0.0, Constants.PROJECTILE_SPEED, self)
	_default_projectile_type.enable_homing(_on_projectile_target_hit, 0.0)

# 	Carry over some properties and all items from preceding
# 	tower
	if _temp_preceding_tower != null:
		var preceding_item_list: Array = _temp_preceding_tower.get_items()
		var preceding_oil_list: Array = _temp_preceding_tower.get_oils()

		for oil_item in preceding_oil_list:
			_temp_preceding_tower.get_item_container().remove_item(oil_item)
			_item_container.add_item(oil_item)

#		Remove items from preceding tower
		for item in preceding_item_list:
			_temp_preceding_tower.get_item_container().remove_item(item)

#		NOTE: must set level and experience after removing
#		items from preceding tower and before adding items
#		to new tower. This is to correctly handle items
#		which grant experience while carried.
		set_level(_temp_preceding_tower._level)
		_experience = _temp_preceding_tower._experience

#		Add items to new tower
#		NOTE: for upgrade case, inventory will always be
#		same size or bigger but for transform case inventory
#		may be smaller. Handle transform case by returning
#		any extra items to stash.
		for item in preceding_item_list:
			if have_item_space():
				_item_container.add_item(item)
			else:
				var tower_screen_pos: Vector2 = _visual.get_screen_transform().get_origin()
				item.fly_to_stash_from_pos(tower_screen_pos)

		_kill_count = _temp_preceding_tower._kill_count
		_best_hit = _temp_preceding_tower._best_hit
		_damage_dealt_total = _temp_preceding_tower._damage_dealt_total

#	NOTE: some stats have an innate level-based modifier
	var innate_modifier: Modifier = Modifier.new()
	innate_modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0, Constants.INNATE_MOD_ATK_CRIT_CHANCE_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0, Constants.INNATE_MOD_ATK_CRIT_DAMAGE_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0, Constants.INNATE_MOD_SPELL_CRIT_CHANCE_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0, Constants.INNATE_MOD_SPELL_CRIT_DAMAGE_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0, Constants.INNATE_MOD_DAMAGE_BASE_PERC_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0, Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD)
	add_modifier(innate_modifier)

	add_modifier(_specials_modifier)

	tower_init()

#	NOTE: must setup aura's after calling tower_init()
#	because auras use buff types which are initialized
#	inside tower_init().
	var aura_type_list: Array[AuraType] = get_aura_types()
	for aura_type in aura_type_list:
		add_aura(aura_type)

#	NOTE: add aura range indicators to "visual" for correct
#	positioning on y axis.
	_aura_range_indicator_list = Utils.add_range_indicators_for_auras(aura_type_list, _visual)

	on_create(_temp_preceding_tower)

	_on_modify_property()

	SelectUnit.connect_unit(self, _tower_selection_area)

	if _placeholder_modulate != Color.WHITE:
		_sprite.modulate = _placeholder_modulate
	
# 	NOTE: tower scenes have two sprites: "Base" and
# 	"Model/Sprite2D". We use "Model/Sprite2D" because that
# 	is the actual sprite. "Base" is a vestigial thing
# 	inherited from Building.tscn and is currently invisible
# 	and unused.
	var sprite: Sprite2D = $Model/Sprite2D
	var sprite_dimensions: Vector2 = Utils.get_sprite_dimensions(sprite)
	_set_unit_dimensions(sprite_dimensions)

#	NOTE: we want size of selection visual to be the same
#	for all towers. That's why we're not using sprite
#	dimensions here like for creeps.
	set_selection_size(TOWER_SELECTION_VISUAL_SIZE)

	selected.connect(on_selected)
	unselected.connect(on_unselected)
	tree_exited.connect(on_tree_exited)

#	Hide range indicators at creation
	on_unselected()

	_temp_preceding_tower = null
	
	# Need to create instance only if Tower has active specials
	_tower_actions.set_tower(self)


func get_log_name() -> String:
	return get_display_name()



# NOTE: need to do attack timing without Timer because Timer
# doesn't handle short durations well (<0.5s)
func _process(delta: float):
	if _visual_only:
		return

	if is_stunned():
		return

#	NOTE: reduce current tracked cooldown to overall
#	cooldown if overall cooldown is smaller. This handles
#	cases where tower's attackspeed was significantly
#	reduced and then returns to normal.
# 
#	For example, let's say tower's attackspeed gets reduced
#	by some debuff so much that the attack cooldown becomes
#	100 seconds. The debuff expires after 10 seconds and
#	tower would be doing nothing for 90 seconds. Instead of
#	that, we recalculate the cooldown so that tower can
#	start attacking normally again.
	var overall_cooldown: float = get_overall_cooldown()
	if _current_attack_cooldown > overall_cooldown:
		_current_attack_cooldown = overall_cooldown

	if _current_attack_cooldown > 0.0:
		_current_attack_cooldown -= delta

	if _current_attack_cooldown <= 0.0:
		var attack_success: bool = _try_to_attack()

# 		NOTE: important to add, not set! So that if game is
# 		lagging, all of the attacks fire instead of skipping.
		if attack_success:
			_current_attack_cooldown += get_overall_cooldown()


#########################
###       Public      ###
#########################


func force_attack_target(forced_target: Creep):
#	NOTE: if tower can attack 1 target, then we simply stop
#	attacking current target. If tower can attack multiple
#	targets, then we substitute one of the targets with the
#	forced target. Note that if the forced target is out of
#	range, we add it anyway and the tower will later
#	automatically remove out of range forced target find a
#	new valid target before next attack.
	if !_target_list.is_empty():
		_remove_target(_target_list[0])

	_add_target(forced_target)


func get_item_container() -> ItemContainer:
	return _item_container


# Tower is attacking while it has valid targets in range.
func is_attacking() -> bool:
	var attacking: bool = !_target_list.is_empty()

	return attacking


# Disables attacking or any other game interactions for the
# tower. Must be called before add_child().
func set_visual_only():
	_visual_only = true


# NOTE: tower.countFreeSlots() in JASS
func count_free_slots() -> int:
	var item_count: int = _item_container.get_item_count()
	var capacity: int = _item_container.get_capacity()
	var free_slots = capacity - item_count

	return free_slots


# NOTE: tower.haveItemSpace() in JASS
func have_item_space() -> bool:
	return _item_container.have_item_space()


func get_oils() -> Array[Item]:
	return _item_container.get_oil_list()


func get_items() -> Array[Item]:
	return _item_container.get_item_list()


func get_item_count() -> int:
	return _item_container.get_item_count()


# NOTE: slot_number starts at 1 instead of 0
# NOTE: tower.getHeldItem() in JASS
func get_held_item(slot_number: int) -> Item:
	var slot_index: int = slot_number - 1
	return _item_container.get_item_at_index(slot_index)


# Called by TowerInfo to get the part of the tooltip that
# is specific to the subclass
func on_tower_details() -> MultiboardValues:
	var empty_multiboard: MultiboardValues = MultiboardValues.new(0)

	return empty_multiboard


func get_item_tower_details() -> Array[MultiboardValues]:
	var out: Array[MultiboardValues] = []

	var item_list: Array[Item] = _item_container.get_item_list()
	
	for item in item_list:
		var board: MultiboardValues = item.on_tower_details()

		if board != null:
			out.append(board)

	return out


# NOTE: tower.orderStop() in JASS
func order_stop():
	_was_ordered_to_stop_attack = true


# NOTE: "attack" is the only order_type encountered in tower
# scripts so ignore that parameter
# 
# NOTE: tower.issueTargetOrder() in JASS
func issue_target_order(order_type: String, target: Unit):
	if order_type != "attack":
		print_debug("Unhandled order_type in issue_target_order()")

	_was_ordered_to_change_target = true
	_new_target_from_order = target


#########################
###      Private      ###
#########################


# NOTE: change color of projectile according to tower's
# element. Note that this overrides projectile's natural color so
# will need to rework this if we decide to make separate
# projectile sprites for each element.
func _make_projectile(from: Unit, target: Unit) -> Projectile:
	var projectile: Projectile = Projectile.create_from_unit_to_unit(_default_projectile_type, self, 0, 0, from, target, true, false, true)

	var element_color: Color
	var element: Element.enm = get_element()

	match element:
		Element.enm.ICE: element_color = Color.LIGHT_BLUE
		Element.enm.NATURE: element_color = Color.FOREST_GREEN
		Element.enm.FIRE: element_color = Color.TOMATO
		Element.enm.ASTRAL: element_color = Color.GOLD
		Element.enm.DARKNESS: element_color = Color.PURPLE
		Element.enm.IRON: element_color = Color.SLATE_GRAY
		Element.enm.STORM: element_color = Color.TEAL
		Element.enm.NONE: element_color = Color.PINK

	projectile.modulate = element_color

	return projectile


# This shouldn't be overriden in subclasses. This will
# automatically generate a string for specials that subclass
# defines in load_specials().
func get_specials_tooltip_text() -> String:
	var text: String = ""

	var attacks_ground_only: bool = _attack_target_type.to_int() == TARGET_TYPE_GROUND_ONLY
	var attacks_air_only: bool = _attack_target_type.to_int() == TARGET_TYPE_AIR_ONLY
	if attacks_ground_only:
		text += "[color=RED]Attacks GROUND only[/color]\n"
	elif attacks_air_only:
		text += "[color=RED]Attacks AIR only[/color]\n"

	match _attack_style:
		AttackStyle.SPLASH:
			text += _get_splash_attack_tooltip_text()
		AttackStyle.BOUNCE:
			text += _get_bounce_attack_tooltip_text()
		AttackStyle.NORMAL:
			text += ""

	var modifier_text: String = _specials_modifier.get_tooltip_text()
	text += modifier_text

	if _target_count_max > 1:
		if !text.is_empty():
			text += " \n"
		text += "[b][color=GOLD]Multishot:[/color][/b]\nAttacks up to %d targets at the same time.\n" % _target_count_max

	return text



# Override in subclass to define the description of tower
# abilities. String can contain rich text format(BBCode).
# NOTE: by default all numbers in this text will be colored
# but you can also define your own custom color tags.
func get_ability_description() -> String:
	return ""


# Same as get_ability_description() but shorter. Should not
# contain any numbers.
func get_ability_description_short() -> String:
	return ""


# Override in subclass to initialize subclass tower. This is
# the analog of "init" function from original API.
func tower_init():
	pass


# Override in subclass to define auras.
func get_aura_types() -> Array[AuraType]:
	var empty_list: Array[AuraType] = []

	return empty_list


# NOTE: override this in subclass to add tower specials.
# This includes adding modifiers and changing attack styles
# to splash or bounce.
func load_specials(_modifier: Modifier):
	pass


# Override this in tower subclass to implement the "On Tower
# Creation" trigger.
# NOTE: onCreate in JASS
func on_create(_preceding_tower: Tower):
	pass


# Override this in tower subclass to implement the "On Tower
# Destruction" trigger.
# NOTE: onDestruct in JASS
func on_destruct():
	pass


func _set_attack_ground_only():
	_attack_target_type = TargetType.new(TARGET_TYPE_GROUND_ONLY)


func _set_attack_air_only():
	_attack_target_type = TargetType.new(TARGET_TYPE_AIR_ONLY)


func _set_attack_style_splash(splash_map: Dictionary):
	_attack_style = AttackStyle.SPLASH
	_splash_map = splash_map


func _set_attack_style_bounce(bounce_count_max: int, bounce_damage_multiplier: float):
	_attack_style = AttackStyle.BOUNCE
	_bounce_count_max = bounce_count_max
	_bounce_damage_multiplier = bounce_damage_multiplier


# NOTE: if your tower needs to attack more than 1 target,
# call this f-n once in _ready() method of subclass
func _set_target_count(count: int):
	_target_count_max = count


# NOTE: tower.getTargetCount() in JASS
func get_target_count() -> int:
	return _target_count_max


func _try_to_attack() -> bool:
	_update_target_list()

# 	NOTE: have to do this weird stuff instead of just
# 	iterating over target list because attacks can modify
# 	the target list by killing creeps (and not just the
# 	current target)
	var attack_count: int = 0
	var already_attacked_list: Array = []

	while attack_count < _target_count_max:
		var target: Creep = null

		for the_target in _target_list:
#			NOTE: need to check for unit validy here because
#			targets during multishot attacks may become
#			invalid. For example, if a previously attacked
#			creep has a debuff which makes it explode and it
#			kills another target nearby.
			if !Utils.unit_is_valid(the_target):
				continue

			var already_attacked: bool = already_attacked_list.has(the_target)

			if !already_attacked:
				target = the_target

				break

		if target == null:
			break

		var target_is_first: bool = attack_count == 0
		_attack_target(target, target_is_first)
		already_attacked_list.append(target)

		attack_count += 1

#		NOTE: handlers for attack event (inside
#		_attack_target) may order the tower to stop
#		attacking or switch to a different target. Process
#		the orders here. This part is to stop attacking if
#		tower has multishot.
		if _was_ordered_to_stop_attack:
			_was_ordered_to_stop_attack = false

			break

	var attack_success: bool = attack_count > 0

	return attack_success


func _attack_target(target: Unit, target_is_first: bool):
#	NOTE: need to generate crit number here early instead of
#	right before dealing damage, so that for attacks like
#	splash damage and bounce attacks all of the damage dealt
#	has the same crit values. Also so that attack and damage
#	event handlers have access to crit count.
	var crit_count: int = _generate_crit_count(0.0, 0.0)
	var crit_ratio: float = _calc_attack_multicrit_from_crit_count(crit_count, 0.0)

#	NOTE: emit attack event only for the "first" target so
#	that if the tower has multishot ability, the attack
#	event is emitted only once per series of attacks. This
#	is the way it works in original game.
	if target_is_first:
		var attack_event: Event = Event.new(target)
		attack_event._number_of_crits = crit_count
		attack.emit(attack_event)

#	NOTE: process crit bonuses after attack event so that if
#	any attack event handlers added crit bonuses, we apply
#	these bonuses to current attack.
	crit_count += _bonus_crit_count_for_next_attack
	_bonus_crit_count_for_next_attack = 0

	crit_ratio += _bonus_crit_ratio_for_next_attack
	_bonus_crit_ratio_for_next_attack = 0.0

#	NOTE: handlers for attack event may order the tower to
#	stop attacking or switch to a different target. Process
#	the orders here.
	if _was_ordered_to_stop_attack:
		return

	if _was_ordered_to_change_target:
		_was_ordered_to_change_target = false

		target = _new_target_from_order

	if target == null:
		return

	var attacked_event: Event = Event.new(target)
	attacked_event._number_of_crits = crit_count
	target.attacked.emit(attacked_event)

	var projectile: Projectile = _make_projectile(self, target)
	projectile.set_tower_crit_count(crit_count)
	projectile.set_tower_crit_ratio(crit_ratio)

	if _attack_style == AttackStyle.BOUNCE:
		var randomize_damage: bool = true
		var damage: float = get_current_attack_damage_with_bonus(randomize_damage)

		projectile.user_real = damage
		projectile.user_int = 0

	var sfx_path: String
	match get_element():
		Element.enm.NATURE: sfx_path = "res://Assets/SFX/swosh-08.mp3"
		Element.enm.STORM: sfx_path = "res://Assets/SFX/foom_02.mp3"
		Element.enm.FIRE: sfx_path = "res://Assets/SFX/fire_attack1.mp3"
		Element.enm.ICE: sfx_path = "res://Assets/SFX/iceball.mp3"
		Element.enm.ASTRAL: sfx_path = "res://Assets/SFX/attack_sound1.mp3"
		Element.enm.DARKNESS: sfx_path = "res://Assets/SFX/swosh-11.mp3"
		Element.enm.IRON: sfx_path = "res://Assets/SFX/iron_attack1.mp3"
		_: sfx_path = "res://Assets/SFX/swosh-08.mp3"

	SFX.sfx_at_unit(sfx_path, self, -20.0)


# Override this in subclass to define custom stats for each
# tower tier. Access as _stats.
func get_tier_stats() -> Dictionary:
	var tier: int = get_tier()
	var default_out: Dictionary = {}

	for i in range(1, tier + 1):
		default_out[i] = {}

	return default_out


func on_selected():
	for indicator in _aura_range_indicator_list:
		indicator.show()
	_range_indicator.show()
	_tower_actions.show()


func on_unselected():
	for indicator in _aura_range_indicator_list:
		indicator.hide()
	_range_indicator.hide()
	_tower_actions.hide()


func on_tree_exited():
	on_destruct()


func _get_base_properties() -> Dictionary:
	return {}


func _get_next_bounce_target(prev_target: Creep, visited_list: Array[Unit]) -> Creep:
	var creep_list: Array = Utils.get_units_in_range(_attack_target_type, prev_target.position, Constants.BOUNCE_ATTACK_RANGE)

	for visited_creep in visited_list:
		if !Utils.unit_is_valid(visited_creep):
			continue

		creep_list.erase(visited_creep)

	Utils.sort_unit_list_by_distance(creep_list, prev_target.position)

	if !creep_list.is_empty():
		var next_target = creep_list[0]

		return next_target
	else:
		return null


func _update_target_list():
#	Remove targets that have become invalid. Targets can
#	become invalid by moving out of range, becoming
#	invisible
	var removed_target_list: Array = []

	for target in _target_list:
		var target_is_valid: bool = _target_is_valid(target)

		if !target_is_valid:
			removed_target_list.append(target)

	for target in removed_target_list:
		_remove_target(target)

# 	Remove targets if target list size is too large. For
# 	example, if a tower ability temporarily increased target
# 	count to 3 and then it went back down to 1.
	while _target_list.size() > _target_count_max:
		_target_list.pop_back()


# 	Add new targets that have entered into range
	var attack_range: float = get_range()
	var creeps_in_range: Array = Utils.get_units_in_range(_attack_target_type, position, attack_range)

	if Config.smart_targeting():
		Utils.sort_creep_list_for_targeting(creeps_in_range, position)
	else:
		Utils.sort_unit_list_by_distance(creeps_in_range, position)

	for target in _target_list:
		creeps_in_range.erase(target)

	while creeps_in_range.size() > 0 && _target_list.size() < _target_count_max:
		var new_target: Creep = creeps_in_range.pop_front()
		var target_is_valid: bool = _target_is_valid(new_target)

		if target_is_valid:
			_add_target(new_target)


func _add_target(target: Creep):
	_target_list.append(target)
	target.death.connect(_on_target_death.bind(target))


# NOTE: arg needs to be untyped because it may be an invalid
# instance.
func _remove_target(target):
	if is_instance_valid(target):
		target.death.disconnect(_on_target_death)

	_target_list.erase(target)


#########################
###     Callbacks     ###
#########################


func _on_mana_changed():
	var mana_ratio: float = get_mana_ratio()
	_mana_bar.ratio = mana_ratio


func _on_projectile_target_hit(projectile: Projectile, target: Unit):
	match _attack_style:
		AttackStyle.NORMAL:
			_on_projectile_target_hit_normal(projectile, target)
		AttackStyle.SPLASH:
			_on_projectile_target_hit_splash(projectile, target)
		AttackStyle.BOUNCE:
			_on_projectile_target_hit_bounce(projectile, target)


func _on_projectile_target_hit_normal(projectile: Projectile, target: Unit):
	var randomize_damage: bool = true
	var damage: float = get_current_attack_damage_with_bonus(randomize_damage)

	var crit_count: int = projectile.get_tower_crit_count()
	var crit_ratio: float = projectile.get_tower_crit_ratio()
	var is_main_target: bool = true

	do_attack_damage(target, damage, crit_ratio, crit_count, is_main_target)


func _on_projectile_target_hit_splash(projectile: Projectile, target: Unit):
	if _splash_map.is_empty():
		return

	var randomize_damage: bool = true
	var damage: float = get_current_attack_damage_with_bonus(randomize_damage)

	var crit_count: int = projectile.get_tower_crit_count()
	var crit_ratio: float = projectile.get_tower_crit_ratio()
	var is_main_target: bool = true

	do_attack_damage(target, damage, crit_ratio, crit_count, is_main_target)

	var splash_target: Unit = target
	var splash_pos: Vector2 = splash_target.position

#	Process splash ranges from closest to furthers,
#	so that strongest damage is applied
	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	var splash_range_max: float = splash_range_list.back()

	var creep_list: Array = Utils.get_units_in_range(_attack_target_type, splash_pos, splash_range_max)

	creep_list.erase(splash_target)

	for neighbor in creep_list:
#		NOTE: need to check validity because splash attack
#		may trigger an exploding creep ability which will
#		kill other splash attack targets before they are
#		processed.
		if !Utils.unit_is_valid(neighbor):
			continue

		var distance: float = Isometric.vector_distance_to(splash_pos, neighbor.position)

		for splash_range in splash_range_list:
			var creep_is_in_range: bool = distance < splash_range

			if creep_is_in_range:
				var splash_damage_ratio: float = _splash_map[splash_range]
				var splash_damage: float = damage * splash_damage_ratio
				var splash_is_main_target: bool = false
				do_attack_damage(neighbor, splash_damage, crit_ratio, crit_count, splash_is_main_target)

				break


func _on_projectile_target_hit_bounce(projectile: Projectile, current_target: Unit):
	var current_damage: float = projectile.user_real
	var current_bounce_index: int = projectile.user_int
	var bounce_visited_list: Array[Unit] = projectile.get_tower_bounce_visited_list()
	bounce_visited_list.append(current_target)

	var crit_count: int = projectile.get_tower_crit_count()
	var crit_ratio: float = projectile.get_tower_crit_ratio()
	var is_first_bounce: bool = current_bounce_index == 0
	var is_main_target: bool = is_first_bounce

	do_attack_damage(current_target, current_damage, crit_ratio, crit_count, is_main_target)

# 	Launch projectile for next bounce, if bounce isn't over
	var bounce_end: bool = current_bounce_index == _bounce_count_max - 1

	if bounce_end:
		return

	var next_damage: float = current_damage * (1.0 - _bounce_damage_multiplier)

	var next_target: Creep = _get_next_bounce_target(current_target, bounce_visited_list)

	if next_target == null:
		return

	var next_projectile: Projectile = _make_projectile(current_target, next_target)
	next_projectile.user_real = next_damage
	next_projectile.user_int = current_bounce_index + 1
	next_projectile._tower_bounce_visited_list = bounce_visited_list
#	NOTE: save crit count in projectile so that it can be
#	used when projectile reaches the target to calculate
#	damage
	next_projectile.set_tower_crit_count(projectile.get_tower_crit_count())
	next_projectile.set_tower_crit_ratio(projectile.get_tower_crit_ratio())


func _on_target_death(_event: Event, target: Creep):
	_remove_target(target)


func _get_splash_attack_tooltip_text() -> String:
	var text: String = "[color=GREENYELLOW]Splash attack:[/color]\n"

	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	for splash_range in splash_range_list:
		var splash_ratio: float = _splash_map[splash_range]
		var splash_percentage: int = floor(splash_ratio * 100)
		text += "\t%d AoE: %d%% damage\n" % [splash_range, splash_percentage]

	return text


func _get_bounce_attack_tooltip_text() -> String:
	var text: String = "[color=GREENYELLOW]Bounce attack:[/color]\n\t%d targets\n\t-%d%% damage per bounce\n" % [_bounce_count_max, floor(_bounce_damage_multiplier * 100)]

	return text


#########################
### Setters / Getters ###
#########################


func get_current_target() -> Unit:
	if !_target_list.is_empty():
		return _target_list.front()
	else:
		return null


func get_item_name() -> String:
	return get_csv_property(CsvProperty.NAME)


# NOTE: this must be called once after the tower is created
# but before it's added to game scene
func set_id(id: int):
	_id = id


func get_id() -> int:
	return _id


func get_tier() -> int:
	return TowerProperties.get_tier(_id)

# NOTE: tower.getFamily() in JASS
func get_family() -> int:
	return TowerProperties.get_family(_id)

func get_icon_atlas_num() -> int:
	return TowerProperties.get_icon_atlas_num(_id)

func is_released() -> bool:
	return TowerProperties.is_released(_id)

# NOTE: tower.getElement() in JASS
func get_element() -> Element.enm:
	return TowerProperties.get_element(_id)

# NOTE: in tower scripts getCategory() is called to get
# tower's element instead of getElement(), for some reason,
# so make this wrapper over get_element()
# 
# NOTE: tower.getCategory() in JASS
func get_category() -> int:
	return get_element()

# How many the seconds the tower needs to reload without modifications.
func get_base_cooldown() -> float:
	return TowerProperties.get_base_cooldown(_id)

# The result of the calculation of the Base Cooldown and the Attack Speed. 
# This is the real rate with which the tower will attack. 
# Example: If the Base Cooldown is 2.0 seconds and the tower has 125% attackspeed, 
# then the real attack cooldown will be 2.0/1.25 == 1.6 seconds.
func get_overall_cooldown() -> float:
	var attack_cooldown: float = get_base_cooldown()
	var attack_speed_mod: float = get_base_attack_speed()
	var overall_cooldown: float = attack_cooldown / attack_speed_mod
	overall_cooldown = max(Constants.ATTACK_COOLDOWN_MIN, overall_cooldown)

	return overall_cooldown


# NOTE: this f-n returns overall cooldown even though that
# doesn't match the name. See "M.E.F.I.S. Rocket" tower
# script for proof.
# 
# NOTE: tower.getCurrentAttackSpeed() in JASS
func get_current_attack_speed() -> float:
	return get_overall_cooldown()

func get_csv_property(csv_property: Tower.CsvProperty) -> String:
	return TowerProperties.get_csv_property(_id, csv_property)

func get_damage_min():
	return TowerProperties.get_damage_min(_id)

func get_damage_max():
	return TowerProperties.get_damage_max(_id)

func get_base_damage():
	return TowerProperties.get_base_damage(_id)

# NOTE: tower.getCurrentAttackDamageBase() in JASS
# NOTE: by default this value is based on the average of
# tower's min and max damage. When tower is calculating
# attack damage, the randomize_damage arg is set to true so
# that this f-n returns random value between min and max.
func get_current_attack_damage_base(randomize_damage: bool = false) -> float:
	var damage_min: float = get_damage_min()
	var damage_max: float = get_damage_max()

	var damage: float
	if randomize_damage:
		damage = randf_range(damage_min, damage_max)
	else:
		damage = floori((damage_min + damage_max) / 2)

	return damage

# NOTE: tower.getCurrentAttackDamageWithBonus() in JASS
func get_current_attack_damage_with_bonus(randomize_damage: bool = false) -> float:
	var base_damage: float = get_current_attack_damage_base(randomize_damage)
	var base_bonus: float = get_base_damage_bonus()
	var base_bonus_percent: float = get_base_damage_bonus_percent()
	var damage_add: float = get_damage_add()
	var damage_add_percent: float = get_damage_add_percent()
	var dps_bonus: float = get_dps_bonus()
	var cooldown: float = get_overall_cooldown()
	var dps_mod: float = dps_bonus * cooldown

	var overall_base_damage: float = (base_damage + base_bonus) * base_bonus_percent
	var overall_damage: float = (overall_base_damage + damage_add) * damage_add_percent + dps_mod

	overall_damage = max(0, overall_damage)

	return overall_damage


# NOTE: getter for TowerInfo
func get_overall_damage() -> float:
	return get_current_attack_damage_with_bonus()

# NOTE: getter for TowerInfo
# How much damage the tower deals with its attack per second on average (not counting in any crits). 
func get_overall_dps():
	return get_overall_damage() / get_overall_cooldown()

# How much damage the tower deals with its attack per second on average when 
# counting attack crits and multicrits.
func get_dps_with_crit():
	return get_overall_dps() * get_crit_multiplier()

# How much damage the tower dealt in total
func get_damage():
	return _damage_dealt_total

# How much kills the tower has in total
func get_kills():
	return _kill_count

# What was the max hit damage the tower dealt
func get_best_hit():
	return _best_hit

# NOTE: tower.getRange() in JASS
func get_range() -> float:
	return TowerProperties.get_range(_id)

# NOTE: tower.getRarity() in JASS
func get_rarity() -> Rarity.enm:
	return TowerProperties.get_rarity(_id)
	
func get_display_name() -> String:
	return TowerProperties.get_display_name(_id)

# NOTE: tower.getAttackType() in JASS
func get_attack_type() -> AttackType.enm:
	return TowerProperties.get_attack_type(_id)

# NOTE: tower.getGoldCost() in JASS
func get_gold_cost() -> int:
	return get_csv_property(CsvProperty.COST).to_int()

func get_inventory_capacity() -> int:
	var capacity: int = TowerProperties.get_inventory_capacity(_id)

	return capacity


func _on_item_container_items_changed():
	items_changed.emit()


# NOTE: this f-n does some unnecessary work in some cases
# but it's simpler this way. For example, it checks if
# target is invisible even though the get_units_in_range()
# f-n already filters out invisible creeps.
# NOTE: arg needs to be untyped because it may be an invalid
# instance.
func _target_is_valid(target) -> bool:
#	NOTE: return early here, so that if unit instance is
#	invalid, we don't call f-ns on it - that would cause
#	errors
	var unit_is_valid: bool = Utils.unit_is_valid(target)
	if !unit_is_valid:
		return false

	var distance_to_target: float = Isometric.vector_distance_to(position, target.position)
	var attack_range: float = get_range()
	var out_of_range: bool = distance_to_target > attack_range

	var target_is_invisible: bool = target.is_invisible()

	var target_is_immune: bool = target.is_immune()
	var tower_is_magic: bool = get_attack_type() == AttackType.enm.MAGIC
	var is_immune_valid: bool = !(target_is_immune && tower_is_magic)

	var target_is_valid: bool = !out_of_range && !target_is_invisible && is_immune_valid

	return target_is_valid


func _set_placeholder_modulate(color: Color):
	_placeholder_modulate = color
