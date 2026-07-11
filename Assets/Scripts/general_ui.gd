extends Control
@onready var money_text: Label = $MoneyText
@onready var pause_menu: TextureRect = $PauseMenu
@onready var back_button: TextureButton = $PauseMenu/BackButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back_button.pressed.connect(toggle_pause)


func _process(delta: float) -> void:
	#esto seguramente se pueda hacer con signals en lugar de hacerlo cada frame
	money_text.text = str(GameManager.current_money)
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if not pause_menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_menu.visible = true
		GameManager.player_interaction.is_interacting = true
	
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameManager.player_interaction.is_interacting = false
		pause_menu.visible = false
