extends Node

var minigames: Dictionary = {}

func register_minigame(game_name: String, node: Node) -> void:
	minigames[game_name] = node

func unregister_minigame(game_name: String) -> void:
	if minigames.has(game_name):
		minigames.erase(game_name)

func start_game_instance(game_node: Node) -> void:
	if is_instance_valid(game_node):
		if game_node.has_method("start_minigame"):
			game_node.start_minigame()
		else:
			push_error("The targeted minigame node does not have a start_minigame() method!")
	else:
		push_error("Requested minigame node instance is invalid or null!")
