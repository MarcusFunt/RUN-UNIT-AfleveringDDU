class_name RunUnitEnding
extends Control

@export_range(0.0, 3.0, 0.05) var status_delay: float = 0.8
@export_range(0.0, 4.0, 0.05) var thanks_delay: float = 1.8
@export_range(0.0, 5.0, 0.05) var buttons_delay: float = 3.0
@export_range(0.1, 3.0, 0.05) var fade_duration: float = 1.2
@export_range(1.0, 1.3, 0.005) var push_in_scale: float = 1.05
@export_range(5.0, 120.0, 1.0) var push_in_duration: float = 60.0
@export_range(0.5, 8.0, 0.1) var pulse_period: float = 2.6

@onready var vista: TextureRect = %Vista
@onready var beacon_halo: Polygon2D = %BeaconHalo
@onready var beacon_column: Polygon2D = %BeaconColumn
@onready var beacon_ring: Polygon2D = %BeaconRing
@onready var twinkles: Node2D = %Twinkles
@onready var unit_07: Node2D = %Unit07
@onready var status_label: Label = %StatusLabel
@onready var thanks_label: Label = %ThanksLabel
@onready var buttons: Control = %Buttons
@onready var sector_button: Button = %SectorButton
@onready var menu_button: Button = %MenuButton

var _reveal: Tween
var _push: Tween
var _loops: Array[Tween] = []

func _ready() -> void:
	sector_button.pressed.connect(_on_sector_pressed)
	menu_button.pressed.connect(_on_main_menu_pressed)
	status_label.modulate.a = 0.0
	thanks_label.modulate.a = 0.0
	buttons.modulate.a = 0.0
	RunUnitSession.clear_checkpoint()
	_start_push_in()
	_start_life()
	_start_reveal()

func _start_push_in() -> void:
	if _push != null and _push.is_valid():
		_push.kill()
	vista.scale = Vector2.ONE
	_push = create_tween()
	_push.tween_property(vista, "scale", Vector2.ONE * push_in_scale, push_in_duration)

func _start_life() -> void:
	for loop in _loops:
		if loop != null and loop.is_valid():
			loop.kill()
	_loops.clear()

	_pulse(beacon_column, 0.16, 0.34, pulse_period)
	_pulse(beacon_halo, 0.05, 0.13, pulse_period * 1.45)
	_pulse(beacon_ring, 0.18, 0.4, pulse_period * 0.8)
	var index := 0
	for child in twinkles.get_children():
		var light := child as CanvasItem
		if light == null:
			continue
		index += 1
		_pulse(light, 0.1, 0.95, 1.3 + 0.37 * index)

	var bob := create_tween().set_loops()
	var resting_y := unit_07.position.y
	bob.tween_property(unit_07, "position:y", resting_y - 2.0, 1.7).set_trans(Tween.TRANS_SINE)
	bob.tween_property(unit_07, "position:y", resting_y, 1.7).set_trans(Tween.TRANS_SINE)
	_loops.append(bob)

func _pulse(item: CanvasItem, low: float, high: float, period: float) -> void:
	var loop := create_tween().set_loops()
	loop.tween_property(item, "modulate:a", high, period * 0.5).set_trans(Tween.TRANS_SINE)
	loop.tween_property(item, "modulate:a", low, period * 0.5).set_trans(Tween.TRANS_SINE)
	_loops.append(loop)

func _start_reveal() -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()

	var thanks_y := thanks_label.position.y
	thanks_label.position.y = thanks_y + 16.0
	_reveal = create_tween()
	_reveal.tween_interval(status_delay)
	_reveal.tween_property(status_label, "modulate:a", 1.0, fade_duration)
	_reveal.tween_interval(maxf(thanks_delay - status_delay - fade_duration, 0.0))
	_reveal.tween_property(thanks_label, "modulate:a", 1.0, fade_duration)
	_reveal.parallel().tween_property(
		thanks_label,
		"position:y",
		thanks_y,
		fade_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_reveal.tween_interval(maxf(buttons_delay - thanks_delay - fade_duration, 0.0))
	_reveal.tween_property(buttons, "modulate:a", 1.0, fade_duration)
	_reveal.tween_callback(sector_button.grab_focus)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()
		get_viewport().set_input_as_handled()

func _on_sector_pressed() -> void:
	SceneLoader.load_scene("res://scenes/level_selector.tscn")

func _on_main_menu_pressed() -> void:
	SceneLoader.load_scene("res://scenes/main_menu.tscn")
