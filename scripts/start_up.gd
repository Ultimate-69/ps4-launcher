extends Control

@onready var bg_color: ColorRect = $Splash/BGColor
@onready var ps_icon: TextureRect = $Splash/PSIcon
@onready var menu: Control = $Menu
@onready var splash: Control = $Splash
@onready var game_container: HBoxContainer = $Menu/GameContainer
@onready var move_sound: AudioStreamPlayer = $Sounds/Move
@onready var game_items: Array[Node] = game_container.get_children()

const IMAGES_PATH = "user://game_images"
const DATA_PATH = "user://game_data"

enum States {
	Splash,
	Boot,
	Menu
}

var tween: Tween
var current_game_image_path: String
var current_game_exe_path: String

var is_quitting: bool = false
var state: States = States.Splash
var focus: Button

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(set_focus)
	$Splash.visible = true
	$Menu.visible = false
	$HomeScreen.visible = true
	$AddPopup.visible = false
	$RemovePopup.visible = false
	
	# splash screen
	
	ps_icon.modulate = Color(1, 1, 1, 0)
	await get_tree().create_timer(1.0).timeout
	tween = create_tween()
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
		
func render_games() -> void:
	for child_button: Button in $Menu/GameContainer.get_children():
		if child_button != $Menu/GameContainer/AddNew and child_button != $Menu/GameContainer/Quit \
		and child_button != $Menu/GameContainer/RemoveGame:
			child_button.queue_free()
			
	var data = DirAccess.open(DATA_PATH)
	if data:
		data.list_dir_begin()
		var game = data.get_next()
		while game != "":
			var game_data = FileAccess.get_file_as_string(DATA_PATH + "/" + game + "/data.json")
			game_data = JSON.parse_string(game_data)
			
			var game_name: String = game_data["name"]
			var game_path: String = game_data["path"]
		
			var game_image: Image
			
			var extensions = ["png", "jpg", "bmp"]
			for ext in extensions:
				var file_path = IMAGES_PATH + "/" + game + "/image." + ext
				if FileAccess.file_exists(file_path):
					game_image = Image.load_from_file(file_path)
					game_image.resize(128, 128)
					break
					
			var game_image_texture = ImageTexture.create_from_image(game_image)
			
			var game_button: Button = $Menu/GameContainer/AddNew.duplicate()
			game_button.pressed.disconnect(_on_add_new_pressed)
			var panel = game_button.get_children()[0]
			var label = panel.get_children()[0]
			label.text = game_name
			game_button.icon = game_image_texture
			
			game_button.pressed.connect(func ():
				AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
				OS.execute(game_path, [])
			)
			$Menu/GameContainer.add_child(game_button)
			
			game = data.get_next()
	
func _unhandled_key_input(event: InputEvent) -> void:
	if state == States.Boot:
		state = States.Menu
		render_games()
		$Sounds/Intro.play()
		if $Sounds/Boot.playing:
			$Splash.queue_free()
			$Sounds/Boot.volume_db = -80
			play_home_music_with_delay(0)
		
		tween = create_tween()
		tween.tween_property($HomeScreen, "modulate", Color(1, 1, 1, 0), 0.3)
		menu.visible = true
		menu.position = Vector2(192, 93)
		menu.scale = Vector2(0.5, 0.5)
		$Menu/GameContainer.position.x = 50
		await get_tree().create_timer(1).timeout
		$Menu/GameContainer/AddNew.grab_focus()
		move_container()
		tween = create_tween()
		tween.tween_property(menu, "scale", Vector2(0.7, 0.7), 0.4)
		tween = create_tween()
		tween.tween_property(menu, "position", Vector2(0, 0), 0.4)
	elif state == States.Menu and focus:
		if event.is_action("ui_right"):
			move_container()
		elif event.is_action("ui_left"):
			move_container()
			
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		var audio_server = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_mute(audio_server, false)

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
		move_sound.play()
	
func play_home_music_with_delay(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	$Sounds/HomeMusic.play()
	$Sounds/HomeMusic.volume_db = -80
	var audio: AudioStreamPlayer = $Sounds/HomeMusic
	var temp_tween = create_tween()
	temp_tween.tween_property(audio, "volume_db", 0.0, 3)
	
func set_focus(newFocus):
	if newFocus is Button:
		focus = newFocus

func _on_add_new_pressed() -> void:
	$AddPopup.visible = true
	$AddPopup/SubmitGame.grab_focus()

func _on_quit_pressed() -> void:
	if is_quitting: return
	is_quitting = true

	$Sounds/Confirm.play()
	await get_tree().create_timer(1.0).timeout
	var quit: Button = $Menu/GameContainer/Quit
	
	get_tree().quit()

func _on_change_image_pressed() -> void:
	$AddPopup/FileDialog.filters = ["*png", "*jpg", "*bmp"]
	$AddPopup/FileDialog.show()

func _on_choose_path_pressed() -> void:
	$AddPopup/FileDialog.filters = ["*exe"]
	$AddPopup/FileDialog.show()

func _on_file_dialog_file_selected(path: String) -> void:
	if path.ends_with(".png") or path.ends_with(".jpg"):
		var image: Image = Image.load_from_file(path)
		current_game_image_path = path
		var texture = ImageTexture.create_from_image(image)
		$AddPopup/TextureRect.texture = texture
	elif path.ends_with(".exe"):
		current_game_exe_path = path
	
func _on_submit_game_pressed() -> void:
	if $AddPopup/Name.text != "":
		# make new dir for image and copy old image into new dir
		# this helps if the old image gets deleted or something 
		# because now the game points to this image
		DirAccess.make_dir_recursive_absolute(IMAGES_PATH + "/" + $AddPopup/Name.text)
		DirAccess.copy_absolute(current_game_image_path, IMAGES_PATH + "/" +
		 $AddPopup/Name.text + "/" + "image." + current_game_image_path.get_extension())
		DirAccess.make_dir_recursive_absolute(DATA_PATH + "/" + $AddPopup/Name.text)
		
		var file: FileAccess = FileAccess.open(DATA_PATH + "/" + $AddPopup/Name.text + "/" + "data.json", FileAccess.WRITE)

		file.store_string(JSON.stringify({
			"name": $AddPopup/Name.text,
			"path": current_game_exe_path
		}))
		file.close()
		$AddPopup.visible = false
		$Menu/GameContainer/AddNew.grab_focus()
		render_games()


func _on_remove_game_pressed() -> void:
	$RemovePopup.visible = true
	
	for i in $RemovePopup/ScrollContainer/VBoxContainer.get_children():
		i.queue_free()
	
	var data = DirAccess.open(DATA_PATH)
	if data:
		data.list_dir_begin()
		var game = data.get_next()
		while game != "":
			var game_button: Button = Button.new()
			game_button.text = "Remove " + game
			game_button.pressed.connect(func ():
				OS.move_to_trash(ProjectSettings.globalize_path(DATA_PATH + "/" + game))
				OS.move_to_trash(ProjectSettings.globalize_path(IMAGES_PATH + "/" + game))
				render_games()
			)
			$RemovePopup/ScrollContainer/VBoxContainer.add_child(game_button)
			game = data.get_next()

func _on_close_remove_pressed() -> void:
	$RemovePopup.visible = false
	$Menu/GameContainer/AddNew.grab_focus()

func _on_cancel_pressed() -> void:
	$AddPopup.visible = false
	$Menu/GameContainer/AddNew.grab_focus()
