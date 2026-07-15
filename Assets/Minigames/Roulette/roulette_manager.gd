extends Node3D
class_name SpinningWheel

@onready var texture_progress_price: TextureProgressBar = $SubViewport/Control/TextureProgressPrice
@onready var sprite_3d: Sprite3D = $Sprite3D

@export_range(0.0, 1) var option2_chance: float = 0.1
@export var spin_duration: float = 2.0
@export var full_loops: int = 5
@export var price: int = 10

var is_spinning: bool = false

func _ready() -> void:
	texture_progress_price.value = option2_chance * 100
	update_wheel_visuals()

func update_wheel_visuals() -> void:
	if texture_progress_price:
		texture_progress_price.value = option2_chance *100

func start_minigame() -> void:
	if is_spinning: return
	
	if GameManager.current_money <= price: 
		print("Not enough money.")
		return
		
	GameManager.current_money -= price
	
	update_wheel_visuals()
	spin_roulette()

func spin_roulette() -> void:
	is_spinning = true
	
	var player_wins: bool = randf() < option2_chance
	var landing_angle: float = 0.0
	
	var chunk_size: float = option2_chance * 360.0
	var margin: float = chunk_size * 0.05
	
	if player_wins:
		landing_angle = randf_range(margin, chunk_size - margin)
	else:
		var miss_margin: float = margin + 2.0
		landing_angle = randf_range(chunk_size + miss_margin, 360.0 - margin)
		
	var target_rot = sprite_3d.rotation_degrees
	var total_rotation: float = (full_loops * 360.0) + landing_angle
	target_rot.z += total_rotation
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(sprite_3d, "rotation_degrees", target_rot, spin_duration)
	
	tween.finished.connect(func(): _determine_winner(player_wins))

func _determine_winner(player_wins: bool) -> void:
	is_spinning = false
		
	if player_wins:
		print("Salvation!!!")
	else:
		print("No salvation :((")
