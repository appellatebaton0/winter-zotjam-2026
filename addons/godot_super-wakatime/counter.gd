@tool
class_name WakatimeCounter extends Panel

const CONFIG_FILE_PATH := "res://addons/godot_super-wakatime/counter.cfg"

var today_time:Dictionary
var overall_time:Dictionary

@onready var proj_name := $HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/ProjectName
@onready var today := $HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/Today
@onready var all_time := $HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/AllTime
@onready var daily_ratio := $HBoxContainer/MarginContainer/VBoxContainer/Control/DailyRatio
@onready var slack_id := $HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/ID

@onready var goal_format := $HBoxContainer/MarginContainer2/VBoxContainer2/VBoxContainer/HBoxContainer/VBoxContainer2/GoalFormat
@onready var total := $HBoxContainer/MarginContainer2/VBoxContainer2/VBoxContainer/HBoxContainer/VBoxContainer2/Total
@onready var end_date := $HBoxContainer/MarginContainer2/VBoxContainer2/VBoxContainer/HBoxContainer/VBoxContainer2/EndDate
@onready var right_progress := $HBoxContainer/MarginContainer2/VBoxContainer2/Control/RightProgress

@onready var under_colors:Array[ColorRect] = [$HBoxContainer/MarginContainer2/VBoxContainer2/Control/TextureRect/ColorRect, $HBoxContainer/MarginContainer/VBoxContainer/Control/TextureRect/ColorRect]
@onready var over_colors:Array[ColorRect]  = [$HBoxContainer/MarginContainer/VBoxContainer/Control/DailyRatio/ColorRect, $HBoxContainer/MarginContainer2/VBoxContainer2/Control/RightProgress/ColorRect]
@onready var under_color := $HBoxContainer/PanelContainer/MarginContainer3/HBoxContainer/UnderColor
@onready var over_color :=  $HBoxContainer/PanelContainer/MarginContainer3/HBoxContainer/OverColor

var api_key

func _ready() -> void:
	read_config()
	proj_name.text = "Project: " + ProjectSettings.get_setting("application/config/name")
	
	$HBoxContainer/PanelContainer/MarginContainer3/HBoxContainer/TextureRect.texture = get_theme_icon("ColorPick", "EditorIcons")
	
	# Make the Theme
	var background = get_theme_stylebox("Background", "EditorStyles")
	theme = Theme.new()
	theme.add_type("LineEdit")
	theme.set_stylebox("normal", "LineEdit", background)
	
	theme.add_type("OptionButton")
	theme.set_stylebox("normal", "OptionButton", background)
	
	theme.add_type("Button")
	theme.set_stylebox("normal", "Button", background)
	
	theme.add_type("PanelContainer")
	theme.set_stylebox("panel", "PanelContainer", background)
	
	_update()

func _update() -> void:
	_update_time()
	
	# Left side.
	
	today.text = "Today: " + today_time["text"]
	all_time.text = "All Time: " + overall_time["text"]
	
	daily_ratio.max_value = overall_time["total_seconds"]
	daily_ratio.value = today_time["total_seconds"]
	
	# Right side.
	
	match goal_format.selected:
		0: # Total
			var total_hours = int(total.text)
			var end_date_hours = Time.get_unix_time_from_datetime_string(end_date.text) / 3600
			var cur_date_hours = Time.get_unix_time_from_system() / 3600
			
			var days = ceil((end_date_hours - cur_date_hours) / 24) + 1
			
			right_progress.max_value = total_hours / days
			right_progress.value = today_time["total_seconds"] / 3600
			
			
			pass

func _update_time():
	
	# Get today's time
	
	var out = []
	OS.execute("curl", ["-H", "Authorization: Bearer " + api_key, "https://hackatime.hackclub.com/api/v1/users/my/stats?start_date="+Time.get_date_string_from_system()+"T06:00:00Z&features=projects&limit=100"], out)
	
	out = JSON.parse_string(out[0])
	
	today_time = find_project_time(out["data"]["projects"])
	
	# Get overall time.
	
	out = []
	OS.execute("curl", ["-H", "Authorization: Bearer " + api_key, "https://hackatime.hackclub.com/api/v1/users/"+slack_id.text+"/stats?features=projects"], out)
	
	out = JSON.parse_string(out[0])
	overall_time = find_project_time(out["data"]["projects"])
	
func find_project_time(from) -> Dictionary:
	# Find the time for the current project from a list of all projects.
	
	for project in from:
		if project["name"] == ProjectSettings.get_setting("application/config/name"):
			return project
	
	return {}

func read_config():
	
	var config = ConfigFile.new()
	
	var err := config.load(CONFIG_FILE_PATH)
	if err != OK: push_error("Failed to load config at path ", CONFIG_FILE_PATH)
	
	slack_id.text = config.get_value("config", "slack_id")
	
	under_color.color = config.get_value("config", "pie_under_color")
	over_color.color = config.get_value("config", "pie_over_color")
	
	goal_format.selected = config.get_value("config", "goal_format")
	total.text = config.get_value("config", "total")
	end_date.text = config.get_value("config", "end_date")
	
	if under_color.color: for rect in under_colors:
		rect.color = under_color.color
	if over_color.color: for rect in over_colors:
		rect.color = over_color.color

func write_config():
	var config = ConfigFile.new()
	
	var err := config.load(CONFIG_FILE_PATH)
	if err != OK: push_error("Failed to load config at path ", CONFIG_FILE_PATH)
	
	config.set_value("config", "slack_id", slack_id.text)
	
	config.set_value("config", "pie_under_color", under_color.color)
	config.set_value("config", "pie_over_color", over_color.color)
	
	config.set_value("config", "goal_format", goal_format.selected)
	config.set_value("config", "total", total.text)
	config.set_value("config", "end_date", end_date.text)
	
	config.save(CONFIG_FILE_PATH)

func _on_text_changed(new_text: String) -> void: write_config()
func _on_item_selected(index: int) -> void: write_config()
func _on_color_changed(color: Color) -> void: 
	write_config()
	
	if under_color: for rect in under_colors:
		rect.color = under_color.color
	if over_color: for rect in over_colors:
		rect.color = over_color.color
