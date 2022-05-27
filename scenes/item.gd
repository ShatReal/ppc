extends VBoxContainer


signal toggled(on)

var selected := false


func _ready() -> void:
	$TextureButton/X.hide()
	

func set_data(image_path: String) -> void:
	$TextureButton.texture_normal = load(image_path)
	$Name.text = image_path.get_file().get_basename().capitalize().substr(2)


func _on_TextureButton_pressed() -> void:
	selected = not selected
	$TextureButton/X.visible = selected
	emit_signal("toggled", selected)


func select(enable: bool) -> void:
	selected = enable
	$TextureButton/X.visible = enable
