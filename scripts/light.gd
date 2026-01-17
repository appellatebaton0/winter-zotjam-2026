class_name Light extends Area2D

@onready var player:Player = get_tree().get_first_node_in_group("Player")

@onready var hit := $LightHit
@onready var light := $PointLight2D

@export var charge_amount := 2.0 # How long the light stays on for, at least.
var charge_time := 0.0

func change_light_state(to:bool) -> bool:
	if light.enabled == to: return false
	
	light.enabled = to
	return true

func _on_hit_area_entered(area: Area2D) -> void: if area is Bullet:
	
	charge_time = charge_amount * area.charge_amount
	
	change_light_state(true)

func _process(delta: float) -> void:
	if charge_time == 0:
		change_light_state(false)
		charge_time = -1
	elif charge_time > 0:
		charge_time = move_toward(charge_time, 0, delta)
	
	
	if get_overlapping_bodies().has(player) and light.enabled:
		player.light_amount += delta * 2
