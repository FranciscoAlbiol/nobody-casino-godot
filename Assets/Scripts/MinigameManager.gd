extends Node

var minigames: Dictionary = {}

func register_minigame(game_name: String, node: Node) -> void:
	minigames[game_name] = node

func unregister_minigame(game_name: String) -> void:
	if minigames.has(game_name):
		minigames.erase(game_name)

func start_game(game_name: String) -> void:
	if minigames.has(game_name):
		var game_node = minigames[game_name]
		if game_node.has_method("start_minigame"):
			game_node.start_minigame()
		else:
			push_error("Minigame " + game_name + " does not have a start_minigame() method!")
	else:
		push_error("Minigame " + game_name + " is not registered or loaded in the scene!")
