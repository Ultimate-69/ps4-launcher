extends Button

var button: Button = self
var tween: Tween

func _ready() -> void:
	button.focus_entered.connect(expand)
	button.focus_exited.connect(shrink)
	
func expand() -> void:
	tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_SINE)
	
func shrink() -> void:
	tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE)
