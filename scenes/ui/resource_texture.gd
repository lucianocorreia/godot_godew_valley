extends TextureRect

var item_type: Enum.Item


func setup(item: Enum.Item, text: Texture2D) -> void:
	item_type = item
	texture = text


func update():
	$Label.text = str(Data.items[item_type])
