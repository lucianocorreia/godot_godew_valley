extends Control

@onready var label: Label = $PanelContainer/MarginContainer/Label

func set_text(text: String) -> void:
	label.text = text
