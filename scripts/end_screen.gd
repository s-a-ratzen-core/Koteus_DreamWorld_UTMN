extends Node2D

@onready var camera = $Camera2D
@onready var table = get_node_or_null("Table")
@onready var zachetka_ui = get_node_or_null("Table/ZachetkaUI") if get_node_or_null("Table/ZachetkaUI") else get_node_or_null("ZachetkaUI")
@onready var results_label = get_node_or_null("Table/ZachetkaUI/ResultsLabel") if get_node_or_null("Table/ZachetkaUI/ResultsLabel") else get_node_or_null("ZachetkaUI/ResultsLabel")

# Переменные для кнопок
var restart_button: Button = null
var exit_button: Button = null

func _ready():
	# Фиксация размеров стола: 1280x720
	if is_instance_valid(table):
		table.size = Vector2(600, 450)
		table.position = Vector2(340, 135)
		table.color = Color(0.2, 0.15, 0.1) # Древесно-коричневый
		
	# Настраиваем разворот зачётки
	if is_instance_valid(zachetka_ui):
		zachetka_ui.modulate.a = 0.0
		zachetka_ui.size = Vector2(560, 410)
		zachetka_ui.position = Vector2(20, 20)
		
	# Фиксируем текст оценок и ачивок ТюмГУ
	if is_instance_valid(results_label):
		results_label.position = Vector2(25, 25)
		results_label.size = Vector2(510, 300)
		results_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	# Поиск кнопок
	restart_button = get_node_or_null("Table/ZachetkaUI/RestartButton")
	if not restart_button: restart_button = get_node_or_null("ZachetkaUI/RestartButton")
	if not restart_button: restart_button = get_node_or_null("Table/RestartButton")
		
	exit_button = get_node_or_null("Table/ZachetkaUI/ExitButton")
	if not exit_button: exit_button = get_node_or_null("ZachetkaUI/ExitButton")
	if not exit_button: exit_button = get_node_or_null("Table/ExitButton")

	# Если пути сбились — рекурсивно ищем кнопки по типу во всей сцене
	if not restart_button or not exit_button:
		for child in get_grandchildren(self):
			if child is Button:
				var btn_name = child.name.to_lower()
				if "restart" in btn_name or "again" in btn_name or "res" in btn_name:
					restart_button = child
				elif "exit" in btn_name or "menu" in btn_name or "out" in btn_name:
					exit_button = child

	# Подвязка кликов найденных кнопок
	if is_instance_valid(restart_button):
		restart_button.disabled = true
		restart_button.size = Vector2(180, 40)
		restart_button.position = Vector2(80, 340)
		if not restart_button.pressed.is_connected(_on_restart_pressed):
			restart_button.pressed.connect(_on_restart_pressed)
			
	if is_instance_valid(exit_button):
		exit_button.disabled = true
		exit_button.size = Vector2(180, 40)
		exit_button.position = Vector2(300, 340)
		if not exit_button.pressed.is_connected(_on_exit_pressed):
			exit_button.pressed.connect(_on_exit_pressed)
	
	if is_instance_valid(camera):
		camera.position = Vector2(640, 360)
		
	run_final_sequence()

# ESC
func _input(event):
	# Проверка, что игрок нажал именно физическую клавишу на клавиатуре
	if event is InputEventKey and event.pressed:
		# Проверка, что нажатая клавиша — это строго Escape
		if event.keycode == KEY_ESCAPE:
			print("Нажат Esc. Напрямую возвращаемся на стартовый экран...")
			_on_exit_pressed()

func run_final_sequence():
	await get_tree().create_timer(1.0).timeout
	
	var camera_tween = create_tween().set_parallel(true)
	if is_instance_valid(camera) and is_instance_valid(table):
		camera_tween.tween_property(camera, "zoom", Vector2(1.8, 1.8), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		camera_tween.tween_property(camera, "position", table.position + (table.size / 2.0), 2.0)
	if is_instance_valid(zachetka_ui):
		camera_tween.tween_property(zachetka_ui, "modulate:a", 1.0, 1.5)
	
	await camera_tween.finished
	display_achievements_and_grades()
	
	if is_instance_valid(restart_button): restart_button.disabled = false
	if is_instance_valid(exit_button): exit_button.disabled = false

func display_achievements_and_grades():
	var total_seconds = 0.0
	var score_node = get_tree().root.get_node_or_null("FinalScoreHolder")
	
	if score_node and score_node.has_meta("saved_time"):
		total_seconds = score_node.get_meta("saved_time")
		
	var mins = int(total_seconds / 60.0)
	var secs = int(total_seconds) % 60
	
	var grade = "ОТЛИЧНО"
	if mins >= 2: grade = "ХОРОШО (Джем слегка переварился)"
	if mins >= 5: grade = "УДОВЛЕТВОРИТЕЛЬНО (Кастрюля пригорела)"
	
	if is_instance_valid(results_label):
		results_label.text = "ЗАЧЕТНАЯ КНИЖКА СТУДЕНТА ТюмГУ\n"
		results_label.text += "Институт сновидений и джемоведения\n"
		results_label.text += "---------------------------------------\n"
		results_label.text += "• Статус сессии: ЗАЩИТА УСПЕШНА\n"
		results_label.text += "• Время в мире снов: %02d:%02d\n" % [mins, secs]
		results_label.text += "• Итоговая оценка: %s\n\n" % grade
		results_label.text += "ОСОБЫЕ ОТМЕТКИ ДЕКАНАТА:\n"
		
		if mins < 1:
			results_label.text += "🏅 [Тюменский спринтер] — диплом быстрее ветра!\n"
		elif mins >= 1 and mins < 3:
			results_label.text += "🏅 [Шеф-повар ТюмГУ] — идеальный тайм-менеджмент!\n"
		else:
			results_label.text += "🏅 [На грани пригорания] — фанат дедлайнов!\n"
	
	if score_node:
		score_node.queue_free()

func _on_restart_pressed():
	print("Перезапуск уровня...")
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.3)
	await fade.finished
	get_tree().change_scene_to_file("res://scenes/dream_world.tscn")

func _on_exit_pressed():
	print("Выход в меню...")
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.3)
	await fade.finished
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")

# Функция рекурсивного перебора дерева для поиска кнопок
func get_grandchildren(node: Node) -> Array:
	var results = []
	for child in node.get_children():
		results.append(child)
		results.append_array(get_grandchildren(child))
	return results
