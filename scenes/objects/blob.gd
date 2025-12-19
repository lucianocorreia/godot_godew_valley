extends CharacterBody2D

var direction: Vector2
var speed: float = 20
var push_distance: float = 130
var push_direction: Vector2
var health: int = 3:
	set(value):
		health = value
		if health <= 0:
			death()

@onready var plauer = get_tree().get_first_node_in_group("Player")


func _physics_process(_delta: float) -> void:
	direction = (plauer.position - position).normalized()
	velocity = direction * speed + push_direction
	move_and_slide()


func push(dir = Vector2.ZERO) -> void:
	var tween = get_tree().create_tween()
	var target_direction = dir if dir else (plauer.position - position).normalized()
	var target = target_direction * -1 * push_distance
	tween.tween_property(self, "push_direction", target, 0.1)
	tween.tween_property(self, "push_direction", Vector2.ZERO, 0.2)


func hit(tool: Enum.Tool, dir = Vector2.ZERO) -> void:
	if tool == Enum.Tool.SWORD:
		$FlashSprite2D.flash()
		push(dir)
		health -= 1


func death() -> void:
	speed = 0
	$AnimationPlayer.current_animation = "explode"
