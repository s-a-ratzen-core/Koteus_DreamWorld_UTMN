extends Node2D

enum State { WALKING, READING, ASLEEP, COMPOSING, TRANSITION, READY }
var current_state = State.WALKING

# Финальный список одиночных мыслей Котеуса
var dream_phrases: Array[String] = [
	"ДИПЛОМ", "ПОСПЕШИ", "ДЖЕМ", "ДЕДЛАЙН", "ГОРИТ", "ВЫПУСКНИК", "ВЫКЛЮЧИТЬ", "ПЛИТА"
]

var target_phrase: String = "ВОЙТИВСОН"
# Массив на 9 ячеек строго под каждую букву по порядку фразы
var sorted_letters: Array = [null, null, null, null, null, null, null, null, null]

var circle_points: Array[Vector2] = []
var total_rotation: float = 0.0
const REQUIRED_ROTATION = PI * 5.0 # 2.5 круга мыши для "варки"

var load_progress: float = 0.0

@onready var koteus = $Koteus 
@onready var chair = $Chair   
@onready var help_label = $HelpLabel
@onready var viewport_size = get_viewport_rect().size
@onready var center_point = viewport_size / 2.0

var custom_button: TextureButton

func _ready():
	help_label.visible = false
	koteus.position = Vector2(-100, chair.position.y)
	
	# Невидимая кликабельная зона ровно по центру экрана
	custom_button = TextureButton.new()
	custom_button.custom_minimum_size = Vector2(280, 60)
	custom_button.anchors_preset = Control.PRESET_CENTER
	custom_button.position = center_point - (Vector2(280, 60) / 2.0)
	custom_button.visible = false
	custom_button.disabled = true
	custom_button.pressed.connect(_on_dream_clicked)
	add_child(custom_button)

func _process(delta):
	match current_state:
		State.WALKING:
			koteus.position.x += delta * 150.0
			if koteus.position.x >= chair.position.x:
				koteus.position.x = chair.position.x
				current_state = State.READING
				
		State.READING:
			load_progress += delta * 60.0
			if load_progress >= 100.0:
				current_state = State.ASLEEP
				trigger_sleep()

# Слова собираются из отдельных букв, чтобы избежать прыжков
func trigger_sleep():
	help_label.text = "Мысли Котеуса путаются..."
	help_label.visible = true
	
	# Поочередно создаем слова
	for i in range(dream_phrases.size()):
		var text = dream_phrases[i]
		# Генерируем случайную базовую точку
		var word_base_pos = center_point + Vector2(randf_range(-250, 250), randf_range(-150, 150))
		
		# Одномоментно создаем и проявляем буквы этого слова на одной линии
		var word_tween = create_tween().set_parallel(true)
		
		for char_idx in range(text.length()):
			var ch = text[char_idx]
			var letter_label = Label.new()
			letter_label.text = ch
			# Фиксированный шаг букв (16 пикселей), чтобы текст был плотным и красивым
			letter_label.position = word_base_pos + Vector2(char_idx * 16, 0)
			letter_label.modulate.a = 0.0
			letter_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0)) # Строго белый
			# Даем буквам имя их слова, чтобы потом легко их найти
			letter_label.add_to_group("phrase_letters")
			add_child(letter_label)
			
			# Плавное проявление всей фразы целиком
			word_tween.tween_property(letter_label, "modulate:a", 0.8, 0.4)
			
		# Пауза перед появлением следующего слова
		await get_tree().create_timer(0.25).timeout
	
	await get_tree().create_timer(0.8).timeout
	melt_words_into_letters()

# Лишние буквы просто исчезают на месте, нужные — остаются
func melt_words_into_letters():
	help_label.text = "Разгоните тучи мыслей круговыми движениями мыши..."
	
	var all_letters = get_tree().get_nodes_in_group("phrase_letters")
	var melt_tween = create_tween().set_parallel(true)
	
	for letter_label in all_letters:
		var ch = letter_label.text
		var saved: bool = false
		
		# Ищем место для этой буквы в итоговой фразе "ВОЙТИ В СОН"
		for j in range(target_phrase.length()):
			if target_phrase[j] == ch and sorted_letters[j] == null:
				sorted_letters[j] = letter_label
				saved = true
				break
				
		# Если буква лишняя — она медленно тает прямо там, где стояла
		if not saved:
			melt_tween.tween_property(letter_label, "modulate:a", 0.0, 1.0)
			melt_tween.tween_callback(letter_label.queue_free).set_delay(1.0)
			
	current_state = State.COMPOSING

func get_letter_offset(index: int) -> float:
	var base_spacing = index * 22.0
	if index > 4: base_spacing += 20.0 # Пробел перед "В"
	if index > 5: base_spacing += 20.0 # Пробел перед "СОН"
	return base_spacing

func _input(event):
	if current_state != State.COMPOSING: return
	
	if event is InputEventMouseMotion:
		var current_vector = event.global_position - center_point
		
		if circle_points.size() > 0:
			var last_vector = circle_points[-1] - center_point
			total_rotation += abs(current_vector.angle_to(last_vector))
			
			var progress = clamp(total_rotation / REQUIRED_ROTATION, 0.0, 1.0)
			
			# Буквы плавно летят в центр, соблюдая пробелы и строгий белый цвет
			for i in range(sorted_letters.size()):
				if sorted_letters[i] != null and is_instance_valid(sorted_letters[i]):
					var letter = sorted_letters[i]
					var target_pos = center_point + Vector2(-110 + get_letter_offset(i), -10)
					
					letter.position = letter.position.lerp(target_pos, progress * 0.05)
					letter.position.y += sin(total_rotation + i) * 0.05
			
			if total_rotation >= REQUIRED_ROTATION:
				current_state = State.TRANSITION
				smooth_lock_and_transform()
				
		circle_points.append(event.global_position)
		if circle_points.size() > 10: circle_points.remove_at(0)

func smooth_lock_and_transform():
	help_label.text = "Мысли материализуются..."
	
	var align_tween = create_tween().set_parallel(true)
	
	for i in range(sorted_letters.size()):
		if sorted_letters[i] != null and is_instance_valid(sorted_letters[i]):
			var letter = sorted_letters[i]
			var final_pos = center_point + Vector2(-115 + get_letter_offset(i), -12)
			align_tween.tween_property(letter, "position", final_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			align_tween.tween_property(letter, "rotation", 0.0, 0.5)
	
	await align_tween.finished
	
	help_label.text = "Нажмите на фразу, чтобы войти в сон..."
	
	var transform_tween = create_tween().set_parallel(true)
	for letter in sorted_letters:
		if is_instance_valid(letter):
			transform_tween.tween_property(letter, "scale", Vector2(1.2, 1.2), 0.4)
	
	await transform_tween.finished
	
	custom_button.visible = true
	custom_button.disabled = false
	current_state = State.READY

func _on_dream_clicked():
	custom_button.disabled = true
	help_label.text = "Погружение..."
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	print("Переход на dream_world.tscn!")
	get_tree().change_scene_to_file("res://scenes/dream_world.tscn")
