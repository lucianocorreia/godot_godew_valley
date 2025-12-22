extends Machine

@export var max_range: float = 150.0

signal shoot_projectile(start_pos: Vector2, new_direction: Vector2)


func get_nearest_blob(blobs: Array) -> CharacterBody2D:
	var nearest = blobs[0]
	for blob in blobs:
		if blob.position.distance_to(position) <= nearest.position.distance_to(position):
			nearest = blob

	return nearest


func _on_timer_timeout() -> void:
	var blobs := get_tree().get_nodes_in_group("Blobs")
	if blobs:
		var nearest_blob = get_nearest_blob(blobs)
		if nearest_blob.position.distance_to(position) <= max_range:
			shoot_projectile.emit(position, (nearest_blob.position - position).normalized())
