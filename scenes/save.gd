extends MenuButton

signal overwrite
signal load_requested
signal delete


func _ready() -> void:
	get_popup().connect("id_pressed", self, "on_id_pressed")
	
	

func on_id_pressed(id: int) -> void:
	match id:
		0:
			emit_signal("overwrite")
		1:
			emit_signal("load_requested")
		2:
			emit_signal("delete")
