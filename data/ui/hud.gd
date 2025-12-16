extends Control
class_name HUD

## General Variables ##
@onready var wunderpal = $Wunderpal
@onready var wunder_anim = $Wunderpal/AnimationPlayer
@onready var ss_container := $Wunderpal/Frame/ScreenArea/GameViewportContainer
@onready var ss_viewport := $Wunderpal/Frame/ScreenArea/GameViewportContainer/GameViewport

## Tab Variables ##
var current_tab : String = ""
@onready var inventory_list = $Wunderpal/Frame/ScreenArea/Inventory_List
@onready var inventory_detail = $Wunderpal/Frame/ScreenArea/Inventory_Detail

@onready var quest_list     = $Wunderpal/Frame/ScreenArea/Quest_List
@onready var quest_detail = $Wunderpal/Frame/ScreenArea/Quest_Detail

@onready var skill_list     = $Wunderpal/Frame/ScreenArea/Skill_List
@onready var skill_detail = $Wunderpal/Frame/ScreenArea/Skill_Detail

@onready var btn_inventory = $Wunderpal/Frame/ScreenArea/Tabs/Btn_Inventory
@onready var btn_quests = $Wunderpal/Frame/ScreenArea/Tabs/Btn_Quests
@onready var btn_skills = $Wunderpal/Frame/ScreenArea/Tabs/Btn_Skills
@onready var tab_buttons = {
	"inventory": $Wunderpal/Frame/ScreenArea/Tabs/Btn_Inventory,
	"quests": $Wunderpal/Frame/ScreenArea/Tabs/Btn_Quests,
	"skills": $Wunderpal/Frame/ScreenArea/Tabs/Btn_Skills
}

## Tooltip Variables ##
@onready var tooltip: Control = $Tooltip
@onready var tooltip_name: Label = $Tooltip/VBoxContainer/NameLabel
@onready var tooltip_desc: Label = $Tooltip/VBoxContainer/DescLabel

#region READY
func _ready():
	GameManager.toggle_wunderpal_requested.connect(_on_toggle_wunderpal)
	GameManager.hud = self
	tab_buttons["inventory"].pressed.connect(func():
		show_tab("inventory")
	)
	tab_buttons["quests"].pressed.connect(func():
		show_tab("quests")
	)
	tab_buttons["skills"].pressed.connect(func():
		show_tab("skills")
	)

	# Default tab
	show_tab("inventory")
	
	setup_wunderpal()
	
	tooltip.visible = false
#endregion

#region WUNDERPAL VARS
var is_wunderpal_open := false
var wunderpal_open_offset := 0
var wunderpal_closed_offset := 0
var slide_duration := 0.35
#endregion

#region WUNDERPAL READY
func setup_wunderpal():
	if wunderpal == null:
		push_warning("Wunderpal is NULL — did you forget to register nodes?")
		return

	# Open position = current offset
	wunderpal_open_offset = wunderpal.position.y

	# Closed position = offscreen bottom
	wunderpal_closed_offset = wunderpal_open_offset + wunderpal.size.y

	wunderpal.position.y = wunderpal_closed_offset
	wunderpal.visible = false

	print("[HUD] Wunderpal initialized",
		"open =", wunderpal_open_offset,
		"closed =", wunderpal_closed_offset)
#endregion

#region WUNDERPAL TOGGLE
func toggle_wunderpal():
	slide_wunderpal(!is_wunderpal_open)
#endregion

#region WUNDERPAL SLIDE (ANIMATION)
func slide_wunderpal(open: bool):
	is_wunderpal_open = open
	GameManager.state = GameManager.GameState.MENU_OPEN if open else GameManager.GameState.BOARD
	
	if open:
		wunderpal.visible = true
		show_tab("inventory") # ← important
		inventory_list.populate_inventory(GameManager.save_data["player"]["inventory"])
		wunder_anim.play("open_wunderpal")
	else:
		wunder_anim.play("close_wunderpal")
		await wunder_anim.animation_finished
		wunderpal.visible = false
#endregion

#region SIGNAL RECEIVER (ONTOGGLE WUNDERPAL)
func _on_toggle_wunderpal():
	toggle_wunderpal() # local HUD function
#endregion



## WUNDERPAL SCREENS AND HELPERS

func show_tab(tab_name: String):
	current_tab = tab_name

	_hide_all_screens()
	
	match tab_name:
		"inventory":
			inventory_list.visible = true
			inventory_list.populate_inventory(GameManager.save_data["player"]["inventory"])
		"quests":
			quest_list.visible = true
		"skills":
			skill_list.visible = true

func _hide_all_screens():
	ss_container.visible = false

	inventory_list.visible = false
	inventory_detail.visible = false
	quest_list.visible = false
	quest_detail.visible = false
	skill_list.visible = false
	skill_detail.visible = false

func show_tooltip(item_data: Dictionary, pos: Vector2):
	tooltip.visible = true
	tooltip.global_position = pos + Vector2(16, 16)
	tooltip_name.text = item_data.name
	tooltip_desc.text = item_data.description
	
func hide_tooltip():
	tooltip.visible = false
