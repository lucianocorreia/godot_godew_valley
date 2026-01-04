extends Button

const ICON_PATHS = {
	Enum.Item.WOOD: "res://graphics/icons/wood.png",
	Enum.Item.FISH: "res://graphics/icons/goldfish.png",
	Enum.Item.APPLE: "res://graphics/icons/apple.png",
	Enum.Item.CORN: "res://graphics/icons/corn.png",
	Enum.Item.WHEAT: "res://graphics/icons/wheat.png",
	Enum.Item.PUMPKIN: "res://graphics/icons/pumpkin.png",
	Enum.Item.TOMATO: "res://graphics/icons/tomato.png"
}

var item
var shop_type
var unlock: Array
var source

signal press(shop_type: Enum.Shop)


func setup(new_shop_type, item_enum: int, parent: Node) -> void:
	parent.add_child(self)
	item = item_enum
	shop_type = new_shop_type

	source = Data.STYLE_UPGRADES if shop_type == Enum.Shop.HAT else Data.MACHINE_UPGRADE_COST
	var data = source[item_enum]
	unlock = Data.unlocked_machines if shop_type == Enum.Shop.MAIN else Data.unlocked_styles

	$VBoxContainer/Control/Label.text = data["name"]
	# $VBoxContainer/ColorRect.color = data["color"]
	$VBoxContainer/ColorRect/TextureRect.texture = data["icon"]
	$VBoxContainer/Control/Control/HBoxContainer/HBoxContainer/Label.text = str(data["cost"].values()[0]) + " G"
	$VBoxContainer/Control/Control/HBoxContainer/HBoxContainer2/Label.text = str(data["cost"].values()[1]) + " G"
	var icon_1 = load(ICON_PATHS[data["cost"].keys()[0]])
	var icon_2 = load(ICON_PATHS[data["cost"].keys()[1]])
	$VBoxContainer/Control/Control/HBoxContainer/HBoxContainer/TextureRect.texture = icon_1
	$VBoxContainer/Control/Control/HBoxContainer/HBoxContainer2/TextureRect.texture = icon_2


func _on_focus_entered() -> void:
	$BG.theme_type_variation = "FocusPanel"


func _on_focus_exited() -> void:
	$BG.theme_type_variation = ""


func _on_pressed() -> void:
	var cost_enums = source[item]["cost"].keys()
	var cost_values = source[item]["cost"].values()

	if Data.items[cost_enums[0]] > cost_values[0] and Data.items[cost_enums[1]] > cost_values[1]:
		Data.change_item(cost_enums[0], -cost_values[0])
		Data.change_item(cost_enums[1], -cost_values[1])
		unlock.append(item)
		press.emit(shop_type)
