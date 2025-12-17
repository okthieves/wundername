extends Button
class_name ItemGridCell

@onready var frame: TextureRect = $Frame
@onready var icon_texture: TextureRect = $Icon
@onready var amount_label: Label = $Amount
@onready var glow := $Glow

var item_data: Dictionary

func _ready():
	glow.visible = false

	mouse_entered.connect(func():
		glow.visible = true
	)

	mouse_exited.connect(func():
		glow.visible = false
	)

func setup(id: int, amount: int):
	item_data = ItemDB.ITEMS.get(id)
	if item_data == null:
		return

	amount_label.text = str(amount) if amount > 1 else ""
	icon_texture.texture = load(item_data.icon_path)
	glow.visible = false

	mouse_entered.connect(_on_hovered)
	mouse_exited.connect(_on_unhovered)
	mouse_entered.connect(func():
		print("HOVER WORKS")
	)
func _on_hovered():
	glow.visible = true
	GameManager.hud.show_tooltip(item_data, global_position)

func _on_unhovered():
	glow.visible = false
	GameManager.hud.hide_tooltip()
