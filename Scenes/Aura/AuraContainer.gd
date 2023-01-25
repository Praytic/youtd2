extends Node


# AuraContainer stores aura instances. It is used by Mob and
# Tower. User of AuraContainer should call
# create_and_add_auras() to add auras and connect to
# applied() signal to apply effects of aura's. User of
# AuraContainer is responsible for the actual implementation
# of the effects, AuraContainer only passes the aura which
# contains basic information about it's effect. Note that
# for status auras(duration > 0, period == 0), applied()
# signal will be emitted when aura expires, so that you can
# reset status effects. For such cases check for
# "aura.is_expired" flag.

# Lifecycle of an aura:
# 
# 1. Aura info is passed to AuraContainer by parent.
# 2. AuraContainer creates the Aura based on aura info and stores it.
# 3. Aura enters the running state.
# 4. Aura may emit applied() signal during the running state.
# 5. AuraContainer may pass applied() signal to parent, but there is extra logic for different aura's.
# 6. Aura expires and is destroyed.
# 
# Different aura cases:
# 
# Instant aura's emit applied() and expire instantly when run for the first time.
# Periodic (poison) aura's emit applied multiple times during it's running time.
# Status aura's emit applied() instantly when run for the first time. When they expire, they emit applied() again to notify the user of the aura to reset aura effects.
#
# Poison aura's have special stacking behavior. If
# multiple poison auras of same type are added, then only
# the strongest aura will be running. Other aura's will be
# paused until the strongest aura expires. Note that if a
# stronger aura is added while another aura is running, the
# stronger one will take over. Note that auras are compared
# by DPS, not by value!
# 
# Status auras of the same type run and expire in parallel.
# Only the strongest aura of type has an effect. For
# example, if there are multiple slow aura's, then final
# slow effect will be equal to the strongest slow aura. If
# two slow aura's are running and one of them is stronger
# and shorter, then when the stronger one expires,
# AuraContainer will emit applied() signal with the weaker
# slow aura passed as a parameter. The end result is that
# the slow effect is reduced when stronger slow aura
# expires.

class_name AuraContainer


signal applied(aura)


func _ready():
	pass


# Call this function in object to add auras
func create_and_add_auras(aura_info_list: Array):
	for aura_info in aura_info_list:
		var aura = Aura.new(aura_info)
		aura.connect("applied", self, "on_aura_applied")
		aura.connect("expired", self, "on_aura_expired")
		add_child(aura)

		if aura.is_poison():
#			Poison auras start as paused if a stronger
#			poison of same type is running already
			process_poison_auras(aura.type)
		else:
			aura.run()


func process_poison_auras(type: int):
	var aura_list: Array = get_aura_list()

	var strongest_aura: Aura = null
	var running_aura: Aura = null
	
	for aura in aura_list:
		if aura.type != type:
			continue
		
		var this_dps: float = aura.get_dps()

		if strongest_aura != null:
			if this_dps > strongest_aura.get_dps():
				strongest_aura = aura
		else:
			strongest_aura = aura

		if aura.is_running:
			running_aura = aura

	if running_aura == null:
		if strongest_aura != null:
			strongest_aura.run()
	else:
		if running_aura != strongest_aura:
			running_aura.pause()
			strongest_aura.run()


func get_strongest_status_aura(type: int) -> Aura:
	var aura_list: Array = get_aura_list()

	var strongest_aura: Aura = null
	
	for aura in aura_list:
		if aura.type != type:
			continue
		
		var this_value: float = aura.get_value()

		if strongest_aura != null:
			if this_value > strongest_aura.get_value():
				strongest_aura = aura
		else:
			strongest_aura = aura
	
	return strongest_aura


func on_aura_applied(aura: Aura):
	if aura.is_status():
#		Only the strongest status aura is applied. If a
#		weaker status aura is added while a stronger one is
#		running, there are no changes.
		var strongest_status_aura: Aura = get_strongest_status_aura(aura.type)

		if aura == strongest_status_aura:
			emit_signal("applied", aura)
	else:
		emit_signal("applied", aura)


func on_aura_expired(aura: Aura):
	if aura.is_poison():
#		Start running the next strongest poison, when
#		current strongest poison expires, or do nothing if
#		no poisons remain.
		process_poison_auras(aura.type)
	elif aura.is_status():
#		If this expired aura is the last for it's type and
#		there are now no running status auras, return the
#		expired aura to indicate that expiry should be
#		handled and status effects should be reset.
#		Otherwise switch to the next strongest status aura.
		var strongest_status_aura: Aura = get_strongest_status_aura(aura.type)
		
		if strongest_status_aura != null:
			emit_signal("applied", strongest_status_aura)
		else:
			emit_signal("applied", aura)


# Get list of active aura's (including paused)
func get_aura_list() -> Array:
	var aura_list: Array = []

	for aura_node in get_children():
		if !(aura_node is Aura):
			continue
		
		var aura: Aura = aura_node as Aura
		
		if aura.is_expired:
			continue

		aura_list.append(aura)

	return aura_list
