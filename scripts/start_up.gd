extends Control

@onready var bg_color: ColorRect = $Splash/BGColor
@onready var ps_icon: TextureRect = $Splash/PSIcon
@onready var menu: Control = $Menu
@onready var splash: Control = $Splash
@onready var game_container: HBoxContainer = $Menu/GameContainer
@onready var move_sound: AudioStreamPlayer = $Sounds/Move
@onready var game_items: Array[Node] = game_container.get_children()

enum States {
	Splash,
	Boot,
	Menu
}

var spacing := 25  # space between items
var tween: Tween

var state: States = States.Splash
var focus: Button

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(set_focus)
	$Splash.visible = true
	$Menu.visible = false
	$HomeScreen.visible = true
	
	# splash screen
	
	ps_icon.modulate = Color(1, 1, 1, 0)
	await get_tree().create_timer(1.0).timeout
	var tween = create_tween()
	tween.tween_property(ps_icon, "modulate", Color(1, 1, 1, 1), 0.3)
	await get_tree().create_timer(3.0).timeout
	tween = create_tween()
	tween.tween_property(ps_icon, "modulate", Color(1, 1, 1, 0), 0.3)
	await get_tree().create_timer(1.0).timeout
	tween = create_tween()
	tween.tween_property(bg_color, "modulate", Color(1, 1, 1, 0), 0.5)
	$Sounds/Boot.play()
	state = States.Boot
	await $Sounds/Boot.finished
	if splash:
		splash.queue_free()
		play_home_music_with_delay(2.0)
	
func _unhandled_key_input(event: InputEvent) -> void:
	if state == States.Boot:
		state = States.Menu
		$Sounds/Intro.play()
		if $Sounds/Boot.playing:
			$Splash.queue_free()
			$Sounds/Boot.volume_db = -80
			play_home_music_with_delay(0)
		
		var tween = create_tween()
		tween.tween_property($HomeScreen, "modulate", Color(1, 1, 1, 0), 0.3)
		menu.visible = true
		menu.position = Vector2(192, 93)
		menu.scale = Vector2(0.7, 0.7)
		$Menu/GameContainer.position.x = 50
		await get_tree().create_timer(1).timeout
		$Menu/GameContainer/AddNew.grab_focus()
		move_container()
		tween = create_tween()
		tween.tween_property(menu, "scale", Vector2(1.0, 1.0), 0.4)
		tween = create_tween()
		tween.tween_property(menu, "position", Vector2(0, 0), 0.4)
	elif state == States.Menu and focus:
		if event.is_action("ui_right"):
			move_container()
		elif event.is_action("ui_left"):
			move_container()

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_left") and focus or Input.is_action_pressed("ui_right") and focus:
		move_container()

func move_container() -> void:
	if tween and tween.is_running():
		tween.kill()

	var target_x: float = 50 - (1.7 * focus.position.x)

	tween = create_tween()
	tween.tween_property(game_container, "position:x", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not move_sound.playing:
		if focus != game_items[0] and focus != game_items[-1]:
			move_sound.play()
	
func play_home_music_with_delay(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	$Sounds/HomeMusic.play()
	$Sounds/HomeMusic.volume_db = -80
	var audio: AudioStreamPlayer = $Sounds/HomeMusic
	var tween = create_tween()
	tween.tween_property(audio, "volume_db", 0.0, 3)
	
func set_focus(newFocus):
	focus = newFocus
