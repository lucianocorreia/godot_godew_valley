extends Node2D

var plant_scene = preload("uid://boqy2w11hcfuy")
var plant_info_scene = preload("uid://2df4pd5knx20")
var projectile_scene = preload("uid://gbpjkq6ikogm")
var blob_scene = preload("uid://c1ngrhhxby0j6")
var macchine_scenes = {
	Enum.Machine.SPRINKLER: preload("uid://jagwlsp7f7ck"),
	Enum.Machine.SCARECROW: preload("uid://duu6unox66m8d"),
	Enum.Machine.FISHER: preload("uid://drbptkvju1amb"),
}

const MACHINE_PREVIEW_TEXTURES = {
	Enum.Machine.SPRINKLER: {"texture": preload("res://graphics/icons/sprinkler.png"), "offset": Vector2i(0, 0)},
	Enum.Machine.FISHER: {"texture": preload("res://graphics/icons/fisher.png"), "offset": Vector2i(0, -4)},
	Enum.Machine.SCARECROW: {"texture": preload("res://graphics/icons/scarecrow.png"), "offset": Vector2i(0, -4)},
	Enum.Machine.DELETE: {"texture": preload("res://graphics/icons/delete.png"), "offset": Vector2i(0, 0)}
}

var used_cells: Array[Vector2i] = []
var raining: bool:
	set(value):
		raining = value
		$Overlay/RainDropsParticles.emitting = value
		$Layers/RainFloorParticles.emitting = value

@onready var player = $Objects/Player
@onready var day_transition_material = $Overlay/CanvasLayer/DayTransitionLayer.material
@onready var machine_preview = $Overlay/MachinePreviewSprite

@export var daytime_color: Gradient
@export var rain_color: Color


func _ready() -> void:
	Data.forecast_rain = [true, false].pick_random()
	for character in get_tree().get_nodes_in_group("Characters"):
		character.connect("open_shop", open_shop)


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
				$Objects/Player.start_fishing(pos)

		Enum.Tool.SEED:
			if has_soil and not grid_coord in used_cells:
				var selected_item = {
					Enum.Seed.TOMATO: Enum.Item.TOMATO,
					Enum.Seed.WHEAT: Enum.Item.WHEAT,
					Enum.Seed.CORN: Enum.Item.CORN,
					Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN,
				}[player.current_seed]

				if Data.items[selected_item] > 0:
					Data.change_item(selected_item, -1)
					var plant_res = PlantResource.new()
					plant_res.setup($Objects/Player.current_seed, selected_item)

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

	# machine preview
	machine_preview.visible = player.current_state == Enum.State.BUILDING
	machine_preview.position = player.get_machine_coord() + (MACHINE_PREVIEW_TEXTURES[player.current_machine]["offset"] as Vector2)


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


func create_projectile(start_pos: Vector2, direction: Vector2) -> void:
	var projectile = projectile_scene.instantiate()
	projectile.setup(start_pos, direction)
	$Objects.add_child(projectile)


func open_shop(shop_type: Enum.Shop) -> void:
	$Overlay/CanvasLayer/ShopUI.reveal(shop_type)
	player.current_state = Enum.State.SHOP


func _on_player_build(current_machine: int) -> void:
	if current_machine != Enum.Machine.DELETE:
		var machine = macchine_scenes[current_machine].instantiate()
		machine.setup(player.get_machine_coord(), self, $Objects)
	else:
		for machine in get_tree().get_nodes_in_group("Machines"):
			machine.delete(player.get_machine_coord() / 16)


func _on_player_machine_change(machine: int) -> void:
	$Overlay/MachinePreviewSprite.texture = MACHINE_PREVIEW_TEXTURES[machine]["texture"]


func water_planrs(coord: Vector2i) -> void:
	const SOIL_DIRECTIONS = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
	for dir in SOIL_DIRECTIONS:
		var cell = coord + dir
		if cell in $Layers/SoilLayer.get_used_cells():
			$Layers/SoilWaterLayer.set_cell(cell, 0, Vector2i(randi_range(0, 2), 0))


func _on_blob_timer_timeout() -> void:
	var plants = get_tree().get_nodes_in_group("Plants")
	if plants:
		var blob = blob_scene.instantiate()
		var pos = $BlobSpawnPositions.get_children().pick_random().position
		blob.setup(pos, plants.pick_random(), $Objects)


func _on_player_close_shop() -> void:
	$Overlay/CanvasLayer/ShopUI.hide()
	player.current_state = Enum.State.DEFAULT


func _on_shop_ui_close() -> void:
	_on_player_close_shop()
