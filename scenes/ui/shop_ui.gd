extends Control

const shop_button_scene = preload("uid://cg28vjfqieo2u")

signal close

# func _ready() -> void:
# 	reveal(Enum.Shop.MAIN)


func reveal(shop_type: Enum.Shop = Enum.Shop.HAT):
	show()
	for child in $GridContainer.get_children():
		child.queue_free()

	var unlocked = Data.shop_connection[shop_type]["tracker"]
	var all = Data.shop_connection[shop_type]["all"]
	var available_items = (all + unlocked).filter(func(item): return not (item in all and item in unlocked))

	if available_items:
		for enum_item in available_items:
			var button_instance = shop_button_scene.instantiate()
			button_instance.setup(shop_type, enum_item, $GridContainer)
			button_instance.connect("press", reveal)
			await get_tree().process_frame
			$GridContainer.get_child(0).grab_focus()
	else:
		close.emit()
