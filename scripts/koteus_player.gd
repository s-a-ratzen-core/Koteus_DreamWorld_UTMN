extends CharacterBody2D

const BASE_SPEED: float = 320.0
const BASE_JUMP: float = -580.0

var run_speed: float = BASE_SPEED
var jump_force: float = BASE_JUMP
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var level_manager = get_parent()

func _physics_process(delta):
	# Если идет комикс-заставка — кот смирно стоит на месте
	if level_manager and level_manager.get("current_stage") != 1: # 1 — это Stage.GAMEPLAY
		velocity = Vector2.ZERO
		return

	# Режим Черничной левитации (Управление по вертикали на W/S или Стрелочки)
	if level_manager and level_manager.get("active_effect") == "blueberry":
		velocity.y = 0
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): 
			velocity.y = -run_speed 
		elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): 
			velocity.y = run_speed
	else:
		# Обычная гравитация платформера
		if not is_on_floor():
			velocity.y += gravity * delta
		# Прыжки (Пробел / W / Стрелочка вверх)
		if (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) and is_on_floor():
			velocity.y = jump_force

	# Страховка от падения в бездну под экран
	if position.y > 750.0:
		position = Vector2(100, 450)
		velocity = Vector2.ZERO

	# Бег влево/вправо (A/D или Стрелочки)
	var direction: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction += 1.0

	if direction != 0.0: 
		velocity.x = direction * run_speed
	else: 
		velocity.x = move_toward(velocity.x, 0.0, run_speed * 0.2)

	move_and_slide()

	# Автоматический разворот кота боком (flip_h)
	if is_instance_valid($Sprite):
		if direction < 0: $Sprite.flip_h = true  # Смотрит влево
		elif direction > 0: $Sprite.flip_h = false # Смотрит вправо
			
		var current_dir = "left" if $Sprite.flip_h else "right"
		if level_manager and level_manager.get("active_effect") == "blueberry":
			$Sprite.play("walk_" + current_dir)
		else:
			if is_on_floor():
				if abs(velocity.x) > 10.0: $Sprite.play("walk_" + current_dir)
				else: $Sprite.play("idle_" + current_dir) # Мягко дышит боком!
			else:
				$Sprite.play("walk_" + current_dir)
