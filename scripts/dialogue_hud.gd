extends CanvasLayer

@onready var avatar = $Panel/Avatar
@onready var dialogue_text = $Panel/DialogueText
@onready var inventory_text = $Panel/InventoryText

var active_tween: Tween

func _ready():
	# Очистка строки при запуске
	dialogue_text.text = ""
	inventory_text.text = ""

# Функция печатной машинки
func show_message(full_text: String, speed_scale: float = 0.02):
	# Прерывание печатающейся фразы
	if active_tween and active_tween.is_running():
		active_tween.kill()
		
	dialogue_text.text = full_text
	dialogue_text.visible_characters = 0
	
	# Плавное раскрытие букв
	active_tween = create_tween()
	var duration = full_text.length() * speed_scale
	active_tween.tween_property(dialogue_text, "visible_characters", full_text.length(), duration)

# Обновление инвентаря и секундомера
func refresh_hud_display(minutes: int, seconds: int, pages: int, max_pages: int, inv: Dictionary):
	inventory_text.text = "⏱️ Варка: %02d:%02d\n📜 Листы: %d/%d\n🍓 Клубника: x%d\n🫐 Черника: x%d\n🍋 Лимон: x%d" % [
		minutes, seconds, pages, max_pages, inv["strawberry"], inv["blueberry"], inv["lemon"]
	]
