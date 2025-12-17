extends Control
class_name ItemGridCell

@onready var frame: TextureRect = $Frame
@onready var icon_texture: TextureRect = $Icon
@onready var amount_label: Label = $Amount
@onready var glow := $Glow

var item_data: Dictionary

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	# Glow setup
	glow.visible = true
	glow.self_modulate = Color(1, 1, 1, 0)

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

func setup(id: int, amount: int):
	item_data = ItemDB.ITEMS.get(id)
	if item_data == null:
		return

	amount_label.text = str(amount) if amount > 1 else ""
	icon_texture.texture = load(item_data.icon_path)
	glow.visible = false

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	mouse_entered.connect(func():
		print("HOVER WORKS")
	)
func _on_hover():
	glow.visible = true
	glow.self_modulate.a = 1
	GameManager.hud.show_tooltip(item_data, global_position)

func _on_unhover():
	glow.visible = false
	glow.self_modulate.a = 0
	GameManager.hud.hide_tooltip()
