extends Node2D

var plant_scene = preload("uid://boqy2w11hcfuy")
var used_cells: Array[Vector2i] = []

@onready var player = $Objects/Player
@onready var day_transition_material = $Overlay/CanvasLayer/DayTransitionLayer.material
@export var daytime_color: Gradient


func _on_player_tool_use(tool: Enum.Tool, pos: Vector2) -> void:
	var grid_coord: Vector2i = Vector2i(int(pos.x / Data.TILE_SIZE), int(pos.y / Data.TILE_SIZE))
	grid_coord.x += -1 if pos.x < 0 else 0
	grid_coord.y += -1 if pos.y < 0 else 0
	var has_soil = grid_coord in $Layers/SoilLayer.get_used_cells()
	match tool:
		Enum.Tool.HOE:
			var cell = $Layers/GrassLayer.get_cell_tile_data(grid_coord) as TileData
			if cell and cell.get_custom_data("farmable"):
				$Layers/SoilLayer.set_cells_terrain_connect([grid_coord], 0, 0)

		Enum.Tool.WATER:
			if has_soil:
				$Layers/SoilWaterLayer.set_cell(grid_coord, 0, Vector2i(randi_range(1, 2), 0))

		Enum.Tool.FISH:
			if not grid_coord in $Layers/GrassLayer.get_used_cells():
				print("fishing at ", grid_coord)

		Enum.Tool.SEED:
			if has_soil and not grid_coord in used_cells:
				var plant = plant_scene.instantiate()
				plant.setup(grid_coord, $Objects)
				used_cells.append(grid_coord)

		Enum.Tool.AXE, Enum.Tool.SWORD:
			for object in get_tree().get_nodes_in_group("Objects"):
				if object.position.distance_to(pos) < 20:
					object.hit(tool)


func _process(_delta: float) -> void:
	var daytime_point = 1 - ($Timers/DayTimer.time_left / $Timers/DayTimer.wait_time)
	var color = daytime_color.sample(daytime_point)
	$Overlay/CanvasModulate.color = color
	if Input.is_action_just_pressed("day_change"):
		day_restart()


func day_restart() -> void:
	var tween = create_tween()
	tween.tween_property(day_transition_material, "shader_parameter/progress", 1.0, 1.0)
	tween.tween_interval(0.5)
	tween.tween_callback(level_reset)
	tween.tween_property(day_transition_material, "shader_parameter/progress", 0.0, 1.0)


func level_reset() -> void:
	$Timers/DayTimer.start()
	for object in get_tree().get_nodes_in_group("Objects"):
		if "reset" in object:
			object.reset()
