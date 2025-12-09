extends Control

var tool_enum: Enum.Tool


func setup(tool: Enum.Tool, texture: Texture2D) -> void:
	tool_enum = tool
	$TextureRect.texture = texture


func highlight(selected: bool) -> void:
	var tween = create_tween()
	var tarhet_size = Vector2(20, 20) if selected else Vector2(16, 16)
	tween.tween_property($TextureRect, "custom_minimum_size", tarhet_size, 0.1)
