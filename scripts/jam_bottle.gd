extends Area2D

# Настройка типа джема прямо в редакторе (strawberry, blueberry или lemon)
@export var jam_type: String = "strawberry"

func _ready():
	# Визуально красим баночку в зависимости от её типа, чтобы не рисовать разные спрайты
	match jam_type:
		"strawberry": modulate = Color(1.5, 0.5, 0.5) # Красная
		"blueberry": modulate = Color(0.5, 0.5, 1.5)  # Синяя
		"lemon": modulate = Color(1.5, 1.5, 0.5)      # Желтая
		
	# Подключаем столкновение с Котеусом
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Если котика коснулся игрок, вызов функцию добавления в инвентарь
	if body.has_method("collect_jam"):
		body.collect_jam(jam_type)
		queue_free() # Баночка исчезает с пола коридора
