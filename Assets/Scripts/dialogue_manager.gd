extends Control
class_name Dialogue_Manager

@onready var dialogue_box: Panel = $DialogueBox
@onready var text_label: Label = $TextLabel
@onready var name_tag: Label = $NameTag
@onready var next_button: Button = $NextButton

var typing_tween: Tween = null
@export var text_speed: float = 0.03

@export_file("*.json") var json_src
var current_dialogue : Dictionary
var current_block : Dictionary


func _ready() -> void:
	visible = false
	next_button.pressed.connect(get_next_line)


func start_dialogue():
	visible = true
	current_block = current_dialogue["start"];
	
	load_block(current_block)

func get_json(source: String):
	#get json file
	var json_text = FileAccess.get_file_as_string(source)
	current_dialogue = JSON.parse_string(json_text)
	start_dialogue()

func load_block(block : Dictionary):
	if(block.has("text_speed")):
		text_speed = block["text_speed"]
		
	if block.has("text"):
		if typing_tween and typing_tween.is_running():
			typing_tween.kill()
		
		text_label.text = block["text"]
		print(block["text"])
		
		text_label.visible_characters = 0
		
		var total_characters = block["text"].length()
		var duration = total_characters * text_speed
		
		typing_tween = create_tween()
		typing_tween.tween_property(
			text_label, 
			"visible_characters", 
			total_characters, 
			duration
		)
	
	if(block.has("name")):
		name_tag.text = block["name"]

func get_next_line():
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
		text_label.visible_characters = -1 # -1: show all characters
		return
		
	if(current_block.has("next")):
		current_block = current_dialogue[current_block["next"]]
		load_block(current_block)
	else:
		visible = false
		if GameManager.player_interaction:
			GameManager.player_interaction.end_interaction()
