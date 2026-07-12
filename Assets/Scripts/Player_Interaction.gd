extends Node3D
class_name Player_Interaction

@export var interact_range: float = 5.0
@export var player_camera: Camera3D
@export var interaction_raycast: RayCast3D
@export var transition_duration: float = 1.0
@export var movement_script: CharacterBody3D # Player movement

# UI
@export var fade_rect: ColorRect
@export var interact_notif: Control
@export var talk_notif: Control

var current_hovered: Interactable = null
var current_active: Interactable = null

var is_interacting: bool = false
var is_transitioning: bool = false
var input_cooldown: bool = false

func _ready() -> void:
	GameManager.player_interaction = self
	# Configure the raycast programmatically based on range
	if interaction_raycast:
		interaction_raycast.target_position = Vector3(0, 0, -interact_range)
		interaction_raycast.enabled = true

func _process(_delta: float) -> void:
	if is_transitioning: 
		return

	if input_cooldown:
		input_cooldown = false
		return

	if is_interacting:
		if Input.is_action_just_pressed("ui_cancel"): # ESC key
			if current_active and (current_active.trigger == null or current_active.trigger.has_seen_index()):
				end_dialogue()
		return

	var hovered: Interactable = null
	if interaction_raycast.is_colliding():
		var collider = interaction_raycast.get_collider()
		if collider:
			hovered = collider if collider is Interactable else collider.get_parent() as Interactable

	if hovered != current_hovered:
		if current_hovered:
			interact_notif.visible = false
			talk_notif.visible = false
			
		current_hovered = hovered
		
		if current_hovered:
			var is_game: bool = not current_hovered.minigame_to_start.is_empty()
			interact_notif.visible = is_game
			talk_notif.visible = not is_game
			print(is_game)

	if not interaction_raycast.is_colliding():
		interact_notif.visible = false
		talk_notif.visible = false

	if current_hovered:
		var is_game: bool = not current_hovered.minigame_to_start.is_empty()
		#var is_game = true; #this is just for debugging reaons
		
		# interact_game: E // interact_talk: Space
		var pressed: bool = Input.is_action_just_pressed("interact_game") if is_game else Input.is_action_just_pressed("interact_talk")

		if pressed:
			if not current_hovered.interactable_camera: 
				return
				
			current_active = current_hovered
			interact_notif.visible = false
			talk_notif.visible = false
			current_hovered = null

			transition_camera(player_camera, current_active.interactable_camera, true)

func end_interaction() -> void:
	if not current_active: 
		return
	is_interacting = false
	transition_camera(current_active.interactable_camera, player_camera, false)

func transition_camera(from_cam: Camera3D, to_cam: Camera3D, entering_interaction: bool) -> void:
	is_transitioning = true
	interact_notif.visible = false
	talk_notif.visible = false
	
	var half_duration: float = transition_duration / 2.0

	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, half_duration)
	await tween.finished

	from_cam.current = false
	to_cam.current = true

	if entering_interaction:
		is_interacting = true
		input_cooldown = true
		if movement_script.has_method("set_input_enabled"):
			movement_script.set_input_enabled(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		if current_active and current_active.dialogue_json:
			DialogueLayout.get_json(current_active.dialogue_json)
		elif current_active and not current_active.minigame_to_start.is_empty():
			start_minigame(current_active.minigame_to_start)
	else:
		is_interacting = false
		current_active = null
		if movement_script.has_method("set_input_enabled"):
			movement_script.set_input_enabled(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var tween_back = create_tween()
	tween_back.tween_property(fade_rect, "color:a", 0.0, half_duration)
	await tween_back.finished

	is_transitioning = false

#estas dos habrá que moverlas a un DialogueManager y GameManager respectivamente
func end_dialogue():
	transition_camera(current_active.interactable_camera, player_camera, false)

	
func start_minigame(minigame : String):
	pass
