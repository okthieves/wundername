extends Button
class_name ItemGridCell

var item_id: int

@onready var icon_texture: TextureRect = $Icon
@onready var amount_label: Label = $Amount

func setup(id: int, amount: int):
	item_id = id

	# Amount
	amount_label.text = str(amount) if amount > 1 else ""

	# Metadata lookup
	var data = ItemDB.ITEMS.get(id)
	if data == null:
		push_warning("No ItemDB entry for item_id %s" % id)
		return

	icon_texture.texture = load(data.icon_path)
