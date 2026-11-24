extends Node2D

# Фазы работы сцены
enum Stage { INTRO_COMIC, GAMEPLAY, OUTRO_COMIC }
var current_stage = Stage.INTRO_COMIC

# Сценарий комикса-заставки перед входом в ТюмГУ. Не забыть сделать!
var dialogue_index: int = 0
var intro_scripts: Array[Dictionary] = [
	{
		"text": "Котеус: Так, папка на месте, зачетка здесь... Всё перепроверил.",
		"avatar_color": Color(0.4, 0.5, 0.9),
		"slide_color": Color(0.2, 0.2, 0.3)
	},
	{
		"text": "Котеус: Сейчас быстренько сдам работу, а потом вернусь домой и спокойно займусь дже...",
		"avatar_color": Color(0.4, 0.5, 0.9),
		"slide_color": Color(0.2, 0.2, 0.3)
	},
	{
		"text": "СТРАШНЫЙ СКВОЗНЯК! ХЛОП! Двери распахнулись! ВСЕ ЛИСТЫ ВЫЛЕТЕЛИ ИЗ ПАПКИ!",
		"avatar_color": Color(1.0, 0.3, 0.3),
		"slide_color": Color(0.5, 0.1, 0.1)
	},
	{
		"text": "Котеус: Что за чертовщина?! Куда полетели страницы?! И почему улица... парит?!",
		"avatar_color": Color(1.0, 0.3, 0.3),
		"slide_color": Color(0.1, 0.1, 0.2)
	},
	{
		"text": "Котеус: Погоди-ка... Этот запах... Черника? Но откуда он здесь? Ладно, иду по запаху наверх!",
		"avatar_color": Color(0.4, 0.9, 0.9),
		"slide_color": Color(0.1, 0.1, 0.2)
	}
]

# Система сбора страниц диплома
var pages_collected: int = 0
const MAX_PAGES: int = 14

# Секундомер варки джема
var time_elapsed: float = 0.0

# Система активного инвентаря джема
var inventory = {"strawberry": 0, "blueberry": 0, "lemon": 0}
var active_effect: String = "none"
var effect_timer: float = 0.0
const JAM_DURATION = 7.0 # Эффект суперсилы длится ровно 7 секунд

# Ссылки на узлы интерфейса и игрока
@onready var comic_slide = $DialogueHUD/ComicSlide
@onready var avatar = $DialogueHUD/Panel/Avatar
@onready var dialogue_text = $DialogueHUD/Panel/DialogueText
@onready var inventory_text = $DialogueHUD/Panel/InventoryText
@onready var player = $KoteusPlayer

# Настройки физики Котеуса
var run_speed = 320.0
var jump_force = -580.0
const BASE_SPEED = 320.0
const BASE_JUMP = -580.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var active_tween: Tween

func _ready():
	player.velocity = Vector2.ZERO
	player.position = Vector2(100, 450) # Приподнимаем на старте
	inventory_text.text = ""
	play_dialogue_step()

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if current_stage == Stage.INTRO_COMIC:
			if dialogue_text.visible_characters < dialogue_text.text.length():
				if active_tween and active_tween.is_running(): 
					active_tween.kill() 
				dialogue_text.visible_characters = dialogue_text.text.length() 
			else:
				dialogue_index += 1
				if dialogue_index < intro_scripts.size(): 
					play_dialogue_step()
				else: 
					start_gameplay()

func play_dialogue_step():
	var current_data = intro_scripts[dialogue_index]
	comic_slide.modulate = current_data["slide_color"]
	avatar.modulate = current_data["avatar_color"]
	dialogue_text.text = current_data["text"]
	dialogue_text.visible_characters = 0
	
	active_tween = create_tween()
	var duration = current_data["text"].length() * 0.03
	active_tween.tween_property(dialogue_text, "visible_characters", current_data["text"].length(), duration)

func start_gameplay():
	current_stage = Stage.GAMEPLAY
	var tween = create_tween()
	tween.tween_property(comic_slide, "modulate:a", 0.0, 0.5)
	update_hud_display()
	show_dialogue("Управление: A/D или Стрелочки — Бег, Пробел — Прыжок. Жмите кнопки 1, 2, 3 для активации джема!")

func show_dialogue(full_text: String):
	if active_tween and active_tween.is_running(): 
		active_tween.kill()
	dialogue_text.text = full_text
	dialogue_text.visible_characters = 0
	active_tween = create_tween()
	active_tween.tween_property(dialogue_text, "visible_characters", full_text.length(), full_text.length() * 0.02)

func add_jam_to_inventory(type: String):
	if inventory[type] < 3: 
		inventory[type] += 1
		update_hud_display()
		match type:
			"strawberry": show_dialogue("Котеус: Подобрал Клубничный джем! Положил в карман худи.")
			"blueberry": show_dialogue("Котеус: О, Черничный джем ТюмГУ! Пригодится для левитации.")
			"lemon": show_dialogue("Котеус: Лимонный джем. Кислый, но спасёт от иллюзий.")
	else:
		show_dialogue("Котеус: Карман забит, больше 3 банок этого джема унести не могу!")

func use_jam_effect(type: String):
	inventory[type] -= 1
	active_effect = type
	effect_timer = JAM_DURATION
	update_hud_display()
	
	match type:
		"strawberry":
			run_speed = BASE_SPEED * 1.5
			jump_force = BASE_JUMP * 1.3
			player.modulate = Color(2.0, 0.6, 0.6) 
			show_dialogue("Котеус: Вкусно! Скорость и прыгучесть выросли!")
		"blueberry":
			player.modulate = Color(0.6, 0.6, 2.0) 
			show_dialogue("Котеус: Ого, невесомость! Теперь я могу плавно летать в воздухе!")
		"lemon":
			player.modulate = Color(2.0, 2.0, 0.6) 
			get_tree().call_group("illusions", "reveal_truth", true)
			show_dialogue("Котеус: Кислота открыла мне глаза! Я вижу скрытые платформы!")

func reset_jam_effects():
	if active_effect == "lemon": get_tree().call_group("illusions", "reveal_truth", false)
	active_effect = "none"
	run_speed = BASE_SPEED
	jump_force = BASE_JUMP
	player.modulate = Color(1.0, 1.0, 1.0) 
	show_dialogue("Котеус: Действие джема закончилось. Физика пришла в норму.")

# Функция сбора листов
func collect_page(koteus_thought: String):
	pages_collected += 1
	update_hud_display()
	
	# Выводим мысль кота в текстовое поле нижней панели
	if is_instance_valid(dialogue_text):
		dialogue_text.text = koteus_thought
		dialogue_text.visible_characters = koteus_thought.length()
		
	# Если собрали все листы — улетаем в финальную зачетку
	if pages_collected >= MAX_PAGES: 
		trigger_final_wakeup()

func update_hud_display():
	var minutes = int(time_elapsed / 60.0)
	var seconds = int(time_elapsed) % 60
	inventory_text.text = "⏱️ Варка: %02d:%02d\n📜 Листы: %d/%d\n🍓 Клубника: x%d\n Blueberry: x%d\n🍋 Лимон: x%d" % [
		minutes, seconds, pages_collected, MAX_PAGES, inventory["strawberry"], inventory["blueberry"], inventory["lemon"]
	]

func trigger_final_wakeup():
	current_stage = Stage.OUTRO_COMIC
	player.velocity = Vector2.ZERO
	show_dialogue("Котеус: Есть! Почти все страницы у меня! Осталась последняя на самом верху...")
	
	# Переход через Autoload GlobalData
	GlobalData.final_time = time_elapsed
	
	await get_tree().create_timer(2.5).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")

func _physics_process(delta):
	if current_stage == Stage.INTRO_COMIC:
		player.velocity = Vector2.ZERO
		return
		
	if current_stage == Stage.GAMEPLAY:
		time_elapsed += delta

	# Кнопки активации джема (1, 2, 3)
	if active_effect == "none":
		if Input.is_key_pressed(KEY_1) and inventory["strawberry"] > 0: use_jam_effect("strawberry")
		if Input.is_key_pressed(KEY_2) and inventory["blueberry"] > 0: use_jam_effect("blueberry")
		if Input.is_key_pressed(KEY_3) and inventory["lemon"] > 0: use_jam_effect("lemon")

	if active_effect != "none" and effect_timer > 0:
		if active_effect == "blueberry":
			player.rotation_degrees = move_toward(player.rotation_degrees, 180.0, delta * 300.0)
		effect_timer -= delta
		if effect_timer <= 0: reset_jam_effects()

	# Режимы перемещения (Черничная левитация или стандартный бег)
	if active_effect == "blueberry":
		player.velocity.y = 0 
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): 
			player.velocity.y = -run_speed 
		elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): 
			player.velocity.y = run_speed
	else:
		player.rotation_degrees = move_toward(player.rotation_degrees, 0.0, delta * 500.0)
		if not player.is_on_floor():
			player.velocity.y += gravity * delta
		if (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) and player.is_on_floor():
			player.velocity.y = jump_force

	# Страховка от бездны
	if player.position.y > 750.0:
		player.position = Vector2(100, 450)
		player.velocity = Vector2.ZERO

	# Прямое считывание клавиш
	var direction: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0

	if direction != 0.0: 
		player.velocity.x = direction * run_speed
	else: 
		player.velocity.x = move_toward(player.velocity.x, 0.0, run_speed * 0.2) # Мягкое торможение

	player.move_and_slide()
