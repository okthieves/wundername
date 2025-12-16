extends Panel

@onready var name_label = $VBoxContainer/NameLabel
@onready var desc_label = $VBoxContainer/DescLabel

func set_item(data: Dictionary):
	name_label.text = data.name
	desc_label.text = data.description
