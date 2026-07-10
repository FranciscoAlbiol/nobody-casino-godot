extends Control
class_name Dialogue_Manager

@onready var dialogue_box: Panel = $DialogueBox
@onready var text_label: Label = $TextLabel
@onready var name_tag: Label = $NameTag
@onready var next_button: Button = $NextButton

	
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
	if (block.has("text")):
		text_label.text = block["text"]
		print(block["text"])
	
	if(block.has("name")):
		name_tag.text = block["name"]

func get_next_line():
	if(current_block.has("next")):
		current_block = current_dialogue[current_block["next"]]
		load_block(current_block)
	else:
		visible = false
		if GameManager.player_interaction:
			GameManager.player_interaction.end_interaction()
