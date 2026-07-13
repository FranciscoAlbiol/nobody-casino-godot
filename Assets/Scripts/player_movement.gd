extends CharacterBody3D
class_name PlayerMovement

@export var sensitivity: float = 0.002

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var camera_3d: Camera3D = %Camera3D

func _ready() -> void:
	GameManager.player = self
	camera_3d.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion and not GameManager.player_interaction.is_interacting:
		rotate_y(-event.relative.x * sensitivity)    
		camera_3d.rotate_x(-event.relative.y * sensitivity)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta: float) -> void:
	if not GameManager.player_interaction.is_interacting:
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		move_and_slide()
