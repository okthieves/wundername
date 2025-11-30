extends Resource
class_name ItemDB

static var ITEMS := {
	1: {
		"id": 1,
		"key": "home_ticket",
		"name": "Home Ticket",
		"type": "key",
		"value": 0,
		"description": "Lets you instantly travel back to station.",
	},

	2: {
		"id": 2,
		"key": "burger",
		"name": "Burger",
		"type": "consumable",
		"value": 15,
		"description": "Restores 15 HP.",
	},

	3: {
		"id": 3,
		"key": "gear_scrap",
		"name": "Salvaged Gear",
		"type": "material",
		"value": 5,
		"description": "Useful for crafting and repairs.",
	},
}

#============================#
#======HELPER FUNCTIONS======#
#============================#

static func get_by_id(id: int) -> Dictionary:
	return ITEMS.get(id, {})

static func get_by_key(key: String) -> Dictionary:
	for item in ITEMS.values():
		if item["key"] == key:
			return item
	return {}

static func get_item_from_id(id: int) -> Dictionary:
	return ITEMS[id]
