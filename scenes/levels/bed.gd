extends StaticBody2D


func interact(player: CharacterBody2D) -> void:
	player.day_change_emit()
