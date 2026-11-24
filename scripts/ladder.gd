extends Area2D

# На какую высоту ведёт эта лесенка (настраивается в Инспекторе справа)
@export var target_layer: int = 1

func _ready():
	# Подключаем сигналы: когда кот наступил на лесенку
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "KoteusPlayer":
		print("Котеус поднимается по лесенке на ярус: ", target_layer)
		# Поднимаем кота на нужный слой видимости, чтобы он отрисовался над скамьей
		body.z_index = target_layer
		body.get_node("Sprite").position.y = -5

func _on_body_exited(body):
	if body.name == "KoteusPlayer":
		# Проверка направления кота при сходе со скамейки:
		# Если он пошел выше — он остаётся на верхнем ярусе скамьи.
		# Если он развернулся и спустился назад — возвращаем его на землю (слой 1).
		if body.velocity.y > 0: # Движется вниз по экрану
			print("Котеус спустился на землю.")
			body.z_index = 1
			body.get_node("Sprite").position.y = 0
