extends CharacterBody2D

var direction: Vector2
var speed := 50
var can_move: bool = true
var current_tool: Enum.Tool
var current_seed: Enum.Seed

@onready var move_state_machine = $Animation/AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var tool_state_machine = $Animation/AnimationTree.get("parameters/ToolStateMachine/playback")


func _physics_process(_delta: float) -> void:
	if can_move:
		get_basic_input()
		move()
		animate()


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

		for animation in Data.TOOL_STATE_ANIMATIONS.values():
			var animation_name = "parameters/ToolStateMachine/" + animation + "/blend_position"
			$Animation/AnimationTree.set(animation_name, direction_animation)

	else:
		move_state_machine.travel("Idle")


func get_basic_input():
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_forward", "tool_backward")
		current_tool = posmod(current_tool + int(dir), Enum.Tool.size()) as Enum.Tool

	if Input.is_action_just_pressed("seed_forward"):
		current_seed = posmod(current_seed + 1, Enum.Seed.size()) as Enum.Seed

	if Input.is_action_just_pressed("action"):
		tool_state_machine.travel(Data.TOOL_STATE_ANIMATIONS[current_tool])
		$Animation/AnimationTree.set("parameters/ToolOneShow/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func tool_use_emit():
	print("tool")


func _on_animation_tree_animation_started(_anim_name: StringName) -> void:
	can_move = false


func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	can_move = true
