extends Node2D

var plant_scene = preload("uid://boqy2w11hcfuy")
var plant_info_scene = preload("uid://2df4pd5knx20")
var used_cells: Array[Vector2i] = []
var raining: bool:
	set(value):
		raining = value
		$Overlay/RainDropsParticles.emitting = value
		$Layers/RainFloorParticles.emitting = value

@onready var player = $Objects/Player
@onready var day_transition_material = $Overlay/CanvasLayer/DayTransitionLayer.material

@export var daytime_color: Gradient
@export var rain_color: Color


func _ready() -> void:
	Data.forecast_rain = [true, false].pick_random()


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

			if raining:
				$Layers/SoilWaterLayer.set_cell(grid_coord, 0, Vector2i(randi_range(0, 2), 0))

		Enum.Tool.WATER:
			if has_soil:
				$Layers/SoilWaterLayer.set_cell(grid_coord, 0, Vector2i(randi_range(0, 2), 0))

		Enum.Tool.FISH:
			if not grid_coord in $Layers/GrassLayer.get_used_cells():
				print("fishing at ", grid_coord)

		Enum.Tool.SEED:
			if has_soil and not grid_coord in used_cells:
				var plant_res = PlantResource.new()
				plant_res.setup($Objects/Player.current_seed)

				var plant = plant_scene.instantiate()
				plant.setup(grid_coord, $Objects, plant_res, plant_death)
				used_cells.append(grid_coord)

				var plant_info = plant_info_scene.instantiate()
				plant_info.setup(plant_res)
				$Overlay/CanvasLayer/PlantInfoContainer.add(plant_info)

		Enum.Tool.AXE, Enum.Tool.SWORD:
			for object in get_tree().get_nodes_in_group("Objects"):
				if object.position.distance_to(pos) < 20:
					object.hit(tool)


func _on_player_diagnose() -> void:
	$Overlay/CanvasLayer/PlantInfoContainer.visible = not $Overlay/CanvasLayer/PlantInfoContainer.visible


func _on_player_day_change() -> void:
	day_restart()


func _process(_delta: float) -> void:
	var daytime_point = 1 - ($Timers/DayTimer.time_left / $Timers/DayTimer.wait_time)
	var color = daytime_color.sample(daytime_point).lerp(rain_color, 0.5 if raining else 0.0)
	$Overlay/CanvasModulate.color = color


func day_restart() -> void:
	var tween = create_tween()
	tween.tween_property(day_transition_material, "shader_parameter/progress", 1.0, 1.0)
	tween.tween_interval(0.5)
	tween.tween_callback(level_reset)
	tween.tween_property(day_transition_material, "shader_parameter/progress", 0.0, 1.0)


func level_reset() -> void:
	for plant in get_tree().get_nodes_in_group("Plants"):
		plant.grow(plant.coord in $Layers/SoilWaterLayer.get_used_cells())

	$Layers/SoilWaterLayer.clear()
	$Overlay/CanvasLayer/PlantInfoContainer.update_all()

	$Timers/DayTimer.start()
	for object in get_tree().get_nodes_in_group("Objects"):
		if "reset" in object:
			object.reset()

	raining = Data.forecast_rain
	Data.forecast_rain = [true, false].pick_random()

	if raining:
		for cell in $Layers/SoilLayer.get_used_cells():
			$Layers/SoilWaterLayer.set_cell(cell, 0, Vector2i(randi_range(0, 2), 0))


func plant_death(coord: Vector2i) -> void:
	used_cells.erase(coord)
