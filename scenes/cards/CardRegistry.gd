## CardRegistry
## Central definition store for all card data.
## Cards are semantic objects and do not execute logic.
## Other systems interpret card meaning.
extends Node
class_name CardRegistry

const CARD_ELEMENTS := [
	"fire",
	"earth",
	"water",
	"blessed",
	"anomaly",
	"lifelight"
]

const CARD_TYPES := {
	"connection": {
		"uses_stats": true,
		"uses_tags": false
	},
	"item": {
		"uses_stats": false,
		"uses_tags": true
	},
	"memory": {
		"uses_stats": false,
		"uses_tags": true
	},
	"location": {
		"uses_stats": false,
		"uses_tags": true
	},
	"emotion": {
		"uses_stats": false,
		"uses_tags": true
	},
	"echo": {
		"uses_stats": false,
		"uses_tags": true
	},
	"maladaptive_trauma": {
		"uses_stats": false,
		"uses_tags": true
	},
	"supportive_trauma": {
		"uses_stats": false,
		"uses_tags": true
	},
	"action": {
		"uses_stats": false,
		"uses_tags": true
	}
}


const CARD_TAGS := {
	"memory": [
		"childhood",
		"loss",
		"joy",
		"fear",
		"family",
		"place",
		"time"
	],
	"emotion": [
		"anger",
		"grief",
		"hope",
		"love",
		"numb",
		"conflicted"
	],
	"item": [
		"tool",
		"key",
		"broken",
		"symbolic",
		"mundane"
	],
	"location": [
		"urban",
		"safe",
		"dangerous",
		"forgotten",
		"transit"
	],
	"echo": [
		"residual",
		"looping",
		"haunted",
		"unresolved"
	],
	"maladaptive_trauma": [
		"avoidance",
		"self_blame",
		"control",
		"shutdown"
	],
	"supportive_trauma": [
		"resilience",
		"bonding",
		"adaptation",
		"survival"
	],
	"action": [
		"move",
		"give",
		"take",
		"connect",
		"refuse"
	]
}

const CONNECTION_STATS := [
	"power",
	"stability",
	"clarity",
	"resonance"
]

const CARDS := {

	# ─────────────────────────────
	# CONNECTION
	# ─────────────────────────────
	"connection_fire_blood": {
		"id": "connection_fire_blood",
		"name": "Blood Runs Hot",
		"type": "connection",
		"element": "fire",
		"description": "Your pulse quickens under pressure.",

		"stats": {
			"hp": +5,
			"speed": +0.1,
			"luck": -1,
			"resilience": 0
		},

		"tags": [],
		"flags": { "persistent": true },
		"meta": { "rarity": "uncommon" }
	},

	# ─────────────────────────────
	# MEMORY
	# ─────────────────────────────
	"memory_river_childhood": {
		"id": "memory_river_childhood",
		"name": "The River, Once",
		"type": "memory",
		"element": "water",
		"description": "You remember the sound before the words.",

		"tags": ["childhood", "river"],
		"flags": { "hidden": false },
		"meta": { "rarity": "common" }
	},

	# ─────────────────────────────
	# ITEM
	# ─────────────────────────────
	"item_bent_key": {
		"id": "item_bent_key",
		"name": "Bent Key",
		"type": "item",
		"element": "earth",
		"description": "It opens something. Not cleanly.",

		"tags": ["keylike", "fragile"],
		"flags": { "consumable": true },
		"meta": { "rarity": "common" }
	},

	# ─────────────────────────────
	# LOCATION
	# ─────────────────────────────
	"location_abandoned_station": {
		"id": "location_abandoned_station",
		"name": "Abandoned Station",
		"type": "location",
		"element": "anomaly",
		"description": "Tracks end here. Time doesn’t.",

		"tags": ["industrial", "abandoned"],
		"flags": {},
		"meta": { "rarity": "rare" }
	}
}

static func has_card(card_id: String) -> bool:
	return CARDS.has(card_id)

static func get_card(card_id: String) -> Dictionary:
	if not CARDS.has(card_id):
		push_error("Unknown card_id: %s" % card_id)
		return {}
	return CARDS[card_id]

static func get_all_cards() -> Dictionary:
	return CARDS

func validate_card(card: Dictionary) -> bool:
	if not CARD_TYPES.has(card.type):
		push_error("Invalid card type: %s" % card.type)
		return false

	if not CARD_ELEMENTS.has(card.element):
		push_error("Invalid card element: %s" % card.element)
		return false

	var rules = CARD_TYPES[card.type]

	# Stats check
	if rules.uses_stats:
		if not card.has("stats"):
			push_error("Connection card missing stats")
			return false

		for stat in CONNECTION_STATS:
			if not card.stats.has(stat):
				push_error("Missing stat: %s" % stat)
				return false
	else:
		if card.has("stats"):
			push_warning("Non-connection card has stats")

	# Tag check
	if rules.uses_tags:
		for tag in card.get("tags", []):
			if not CARD_TAGS.get(card.type, []).has(tag):
				push_error("Invalid tag '%s' for type '%s'" % [tag, card.type])
				return false

	return true
