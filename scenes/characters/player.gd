extends CharacterBody2D

var direction: Vector2
var last_direction: Vector2
var speed := 50
var can_move: bool = true
var current_tool: Enum.Tool = Enum.Tool.SWORD
var current_seed: Enum.Seed
var current_state: Enum.State
var current_style: Enum.Style

@onready var move_state_machine = $Animation/AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var tool_state_machine = $Animation/AnimationTree.get("parameters/ToolStateMachine/playback")

signal tool_use(tool: Enum.Tool, pos: Vector2)
signal diagnose
signal day_change


func _physics_process(_delta: float) -> void:
	match current_state:
		Enum.State.DEFAULT:
			if can_move:
				get_basic_input()
				move()
				animate()

		Enum.State.FISHING:
			get_fishing_input()

	if direction:
		last_direction = direction

	var ray_y = int(last_direction.y if not last_direction.x else 0.0)

	$RayCast2D.target_position = Vector2(last_direction.x, ray_y).normalized() * 20  ## 20 = distance on raycast


func move():
	direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()


func animate():
	if direction:
		move_state_machine.travel("Walk")
		var direction_animation = Vector2(round(direction.x), round(direction.y))
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Walk/blend_position", direction_animation)
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Idle/blend_position", direction_animation)
		$Animation/AnimationTree.set("parameters/FishIdleBlendSpace2D/blend_position", direction_animation)

		for animation in Data.TOOL_STATE_ANIMATIONS.values():
			var animation_name = "parameters/ToolStateMachine/" + animation + "/blend_position"
			$Animation/AnimationTree.set(animation_name, direction_animation)

	else:
		move_state_machine.travel("Idle")


func get_basic_input():
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_forward", "tool_backward")
		current_tool = posmod(current_tool + int(dir), Enum.Tool.size()) as Enum.Tool
		$ToolUI.reveal(true)

	if Input.is_action_just_pressed("seed_forward"):
		current_seed = posmod(current_seed + 1, Enum.Seed.size()) as Enum.Seed
		$ToolUI.reveal(false)

	if Input.is_action_just_pressed("action"):
		$RayCast2D.force_raycast_update()
		if not $RayCast2D.get_collider():
			tool_state_machine.travel(Data.TOOL_STATE_ANIMATIONS[current_tool])
			$Animation/AnimationTree.set("parameters/ToolOneShow/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			$RayCast2D.get_collider().interact(self)

	if Input.is_action_just_pressed("diagnose"):
		diagnose.emit()

	if Input.is_action_just_pressed("style_toggle"):
		current_style = posmod(current_style + 1, Enum.Style.size()) as Enum.Style
		$Sprite2D.texture = Data.PLAYER_SKINS[current_style]


func get_fishing_input() -> void:
	if Input.is_action_just_pressed("action"):
		$FishingGame.action()


func start_fishing(_fish_pos: Vector2) -> void:
	$FishingGame.reveal()
	current_state = Enum.State.FISHING
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 1)


func stop_fishing() -> void:
	can_move = true
	current_state = Enum.State.DEFAULT
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 0)


# Emit tool use signal with current tool and position
func tool_use_emit():
	tool_use.emit(current_tool, position + last_direction * 16 + Vector2(0, 4))


func _on_animation_tree_animation_started(_anim_name: StringName) -> void:
	can_move = false


func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	can_move = true


func day_change_emit():
	day_change.emit()
