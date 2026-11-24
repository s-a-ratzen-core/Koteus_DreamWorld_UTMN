extends Area2D

var start_y: float = 0.0
var time_passed: float = 0.0

@onready var body = $Body

var page_thoughts: Array[String] = [
	"Котеус: О, нашёл Титульный лист!",
	"Котеус: А вот и Введение.",
	"Котеус: Глава 1, черновик.",
	"Котеус: Список литературы!",
	"Котеус: Чертежи кампуса ТюмГУ!"
]

func _ready():
	start_y = position.y
	time_passed = randf_range(0.0, 3.0)
	body_entered.connect(_on_body_entered)

func _process(delta):
	time_passed += delta * 3.0
	position.y = start_y + sin(time_passed) * 10.0

func _on_body_entered(body_node):
	if body_node.name == "KoteusPlayer":
		var random_thought = page_thoughts[randi() % page_thoughts.size()]
		
		var main_level = get_tree().current_scene
		if main_level and main_level.has_method("collect_page"):
			main_level.collect_page(random_thought) # Вызываем функцию напрямую без call!
		else:
			print("Ошибка: Функция collect_page не найдена на сцене уровня!")
			
		queue_free()
