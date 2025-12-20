## Heads-up display controller for the Wunderpal device.
## Manages UI visibility, tab switching, inventory display,
## tooltips, and integration with the GameManager.
extends Control
class_name HUD


## --------------------------
## GENERAL NODE REFERENCES
## --------------------------

## Root Control node for the Wunderpal UI.
@onready var wunderpal = $Wunderpal

## AnimationPlayer responsible for opening/closing the Wunderpal.
@onready var wunder_anim = $Wunderpal/AnimationPlayer

## Container holding the SubViewport used for side-scrolling scenes.
## Exists even when no scene is loaded.
@onready var ss_container := $Wunderpal/Frame/ScreenArea/GameViewportContainer

## SubViewport used to load and display side-scrolling gameplay scenes.
@onready var ss_viewport := $Wunderpal/Frame/ScreenArea/GameViewportContainer/GameViewport


## --------------------------
## TAB STATE AND REFERENCES
## --------------------------

## Name of the currently active Wunderpal tab.
var current_tab : String = ""

## Inventory list UI (grid of items).
@onready var inventory_list = $Wunderpal/Frame/ScreenArea/Inventory_List

## Inventory detail panel (selected item information).
@onready var inventory_detail = $Wunderpal/Frame/ScreenArea/Inventory_Detail

## Quest list UI.
@onready var quest_list     = $Wunderpal/Frame/ScreenArea/Quest_List

## Quest detail panel.
@onready var quest_detail = $Wunderpal/Frame/ScreenArea/Quest_Detail

## Skill list UI.
@onready var skill_list     = $Wunderpal/Frame/ScreenArea/Skill_List

## Skill detail panel.
@onready var skill_detail = $Wunderpal/Frame/ScreenArea/Skill_Detail


## --------------------------
## TAB BUTTON REFERENCES
## --------------------------

## Inventory tab button.
@onready var btn_inventory = $Wunderpal/Frame/ScreenArea/Tabs/Btn_Inventory

## Quests tab button.
@onready var btn_quests = $Wunderpal/Frame/ScreenArea/Tabs/Btn_Quests

## Skills tab button.
@onready var btn_skills = $Wunderpal/Frame/ScreenArea/Tabs/Btn_Skills

## Mapping of tab names to their corresponding buttons.
## Used for simplified tab switching logic.
@onready var tab_buttons = {
	"inventory": $Wunderpal/Frame/ScreenArea/Tabs/Btn_Inventory,
	"quests": $Wunderpal/Frame/ScreenArea/Tabs/Btn_Quests,
	"skills": $Wunderpal/Frame/ScreenArea/Tabs/Btn_Skills
}


## --------------------------
## TOOLTIP REFERENCES
## --------------------------

## Tooltip root control.
@onready var tooltip: Control = $Tooltip

## Label displaying the item name in the tooltip.
@onready var tooltip_name: Label = $Tooltip/VBoxContainer/NameLabel

## Label displaying the item description in the tooltip.
@onready var tooltip_desc: Label = $Tooltip/VBoxContainer/DescLabel


#region READY

## Initializes HUD connections, tab button callbacks,
## default state, and Wunderpal positioning.
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

	# Set default tab on startup
	show_tab("inventory")
	
	setup_wunderpal()
	
	tooltip.visible = false

#endregion


#region WUNDERPAL STATE VARIABLES

## Whether the Wunderpal is currently open.
var is_wunderpal_open := false

## Y-position of the Wunderpal when fully open.
var wunderpal_open_offset := 0

## Y-position of the Wunderpal when fully closed (off-screen).
var wunderpal_closed_offset := 0

## Duration (in seconds) of the open/close animation.
var slide_duration := 0.35

#endregion


#region WUNDERPAL INITIAL SETUP

## Calculates open and closed positions for the Wunderpal
## and initializes it in the closed state.
func setup_wunderpal():
	if wunderpal == null:
		push_warning("Wunderpal is NULL — did you forget to register nodes?")
		return

	# Open position = current Y offset
	wunderpal_open_offset = wunderpal.position.y

	# Closed position = pushed off-screen downward
	wunderpal_closed_offset = wunderpal_open_offset + wunderpal.size.y

	wunderpal.position.y = wunderpal_closed_offset
	wunderpal.visible = false

	print(
		"[HUD] Wunderpal initialized",
		"open =", wunderpal_open_offset,
		"closed =", wunderpal_closed_offset
	)

#endregion


#region WUNDERPAL TOGGLE

## Toggles the Wunderpal open or closed based on current state.
func toggle_wunderpal():
	slide_wunderpal(!is_wunderpal_open)

#endregion


#region WUNDERPAL SLIDE / ANIMATION

## Opens or closes the Wunderpal with animation.
## Updates game state and input routing accordingly.
## @param open Whether the Wunderpal should be opened.
func slide_wunderpal(open: bool):
	is_wunderpal_open = open
	GameManager.state = GameManager.GameState.MENU_OPEN if open else GameManager.GameState.BOARD
	
	# Disable SubViewport input while menu is open
	ss_viewport.gui_disable_input = open
	
	if open:
		wunderpal.visible = true
		show_tab("inventory") # Ensure a valid default screen
		inventory_list.populate_inventory(GameManager.save_data["player"]["inventory"])
		wunder_anim.play("open_wunderpal")
	else:
		wunder_anim.play("close_wunderpal")
		await wunder_anim.animation_finished
		wunderpal.visible = false

#endregion


#region SIGNAL RECEIVER

## Handles Wunderpal toggle requests from the GameManager.
func _on_toggle_wunderpal():
	toggle_wunderpal()

#endregion


## --------------------------
## WUNDERPAL SCREENS & HELPERS
## --------------------------

## Displays the requested tab and hides all others.
## @param tab_name Name of the tab to show.
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


## Hides all Wunderpal screens and disables mouse input
## for the SubViewport container.
func _hide_all_screens():
	ss_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	inventory_list.visible = false
	inventory_detail.visible = false
	quest_list.visible = false
	quest_detail.visible = false
	skill_list.visible = false
	skill_detail.visible = false


## Displays the tooltip for an inventory item.
## @param item_data Dictionary containing item name and description.
## @param pos Global mouse position for tooltip placement.
func show_tooltip(item_data: Dictionary, pos: Vector2):
	tooltip.visible = true
	tooltip.global_position = pos + Vector2(16, 16)
	tooltip_name.text = item_data.name
	tooltip_desc.text = item_data.description


## Hides the currently visible tooltip.
func hide_tooltip():
	tooltip.visible = false
