extends CharacterBody2D

var player: CharacterBody2D
var dialog_index: int

@export var dialog: Array[String] = []
@export var fin_dialog: String
@export var texture: Texture2D
@export var shop_tupe: Enum.Shop
@export var has_fin_animation: bool

signal open_shop(shop_type: Enum.Shop)


func _ready() -> void:
	$Sprite2D.texture = texture


func _process(_delta: float) -> void:
	if player:
		if player.position.distance_to(position) > 30:
			$Dialog.hide()


func interact(player_character: CharacterBody2D) -> void:
	player = player_character
	var raw_dir = (player.position - position).normalized()
	var dir = Vector2i(round(raw_dir.x), round(raw_dir.y))
	$Sprite2D.frame_coords.y = {
		Vector2i.DOWN: 0,
		Vector2i.LEFT: 1,
		Vector2i.RIGHT: 2,
		Vector2i.UP: 3,
	}[dir]

	$Dialog.show()
	if dialog_index < dialog.size():
		$Dialog.set_text(dialog[dialog_index])
		dialog_index += 1
	else:
		if Data.shop_connection[shop_tupe]["tracker"].size() == Data.shop_connection[shop_tupe]["all"].size():
			$Dialog.set_text(fin_dialog)
			if has_fin_animation:
				var tween = create_tween()
				tween.tween_property($Sprite2D, "frame", 23, 1.6).from(16)
				tween.tween_property($Sprite2D, "frame", 0, 0).from(16)
		else:
			$Dialog.hide()
			dialog_index = 0
			open_shop.emit(shop_tupe)
			get_tree().get_first_node_in_group("ResourceUI").reveal(false)
