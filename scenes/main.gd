extends Control


const SPRITES_PATH := "res://sprites/"
const OPTIONS := ["hair_back", "outfits", "ears", "chins", "blushes", "mouths", "noses", "eyes", "eyebrows", "hair_front"]
const COLOR_TYPES := ["skin", "sclera", "iris", "hair", "outfit", "blush", "teeth", "mouth"]
const DEFAULT_COLORS := [Color("fad6b8"), Color.white, Color("249fde"), Color("fa6a0a"), Color("c7b08b"), Color("f5a097"), Color.white, Color("bc4a9b")]
const COLOR_PICKER_BUTTON_SIZE := Vector2(32, 32)
const SAVES_PATH := "user://saves/"
const SAVE_ENDING := ".ini"
const IMAGE_SIZE := Vector2(64, 64)

export var items: PackedScene
export var item: PackedScene
export var save: PackedScene

var saves := []
var flips := []

onready var base := $VBox/Top/Portrait/ViewportContainer/Viewport/Base
onready var buttons := $VBox/Top/Buttons
onready var items_panel := $VBox/Top/Right/Items
onready var colors := $VBox/Top/Colors/VBox
onready var slots := $SaveLoad/VBox/Slots/VBox
onready var name_edit := $VBox/Bottom/Name
onready var save_load := $SaveLoad
onready var flip := $VBox/Top/Right/Bottom/Flip


func _ready() -> void:
	randomize()
	var dir := Directory.new()
	var bg := ButtonGroup.new()
	for option in OPTIONS:
		flips.append(false)
		var texture_rect := TextureRect.new()
		base.add_child(texture_rect)
		texture_rect.set_anchors_and_margins_preset(Control.PRESET_WIDE)
		texture_rect.expand = true
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.use_parent_material = true
		var button := Button.new()
		button.group = bg
		button.text = option.capitalize()
		button.toggle_mode = true
		buttons.add_child(button)
		button.connect("toggled", self, "on_button_toggled", [button.get_index()])
		var items_instance := items.instance()
		dir.open(SPRITES_PATH + option)
		dir.list_dir_begin(true, true)
		var file_name := dir.get_next()
		while file_name:
			if not dir.current_is_dir() and file_name.ends_with(".import"):
				var i := item.instance()
				i.set_data(SPRITES_PATH + option + "/" + file_name.replace(".import", ""))
				items_instance.get_node("Grid").add_child(i)
				i.connect("toggled", self, "on_item_toggled", [i])
			file_name = dir.get_next()
		dir.list_dir_end()
		items_panel.add_child(items_instance)
	buttons.get_child(0).pressed = true
	base.get_child(0).show_behind_parent = true
	show_option(0)
	for i in COLOR_TYPES.size():
		var type: String = COLOR_TYPES[i]
		var l := Label.new()
		l.align = Label.ALIGN_CENTER
		l.text = type.capitalize() + " Color"
		colors.add_child(l)
		var c := ColorPickerButton.new()
		c.flat = true
		c.color = DEFAULT_COLORS[i]
		c.rect_min_size = COLOR_PICKER_BUTTON_SIZE
		colors.add_child(c)
		c.connect("color_changed", self, "change_color", [type])
		change_color(DEFAULT_COLORS[i], type)
	if not dir.dir_exists(SAVES_PATH):
		dir.make_dir(SAVES_PATH)
		return
	dir.open(SAVES_PATH)
	dir.list_dir_begin(true, true)
	var file_name := dir.get_next()
	while file_name:
		if not dir.current_is_dir() and file_name.ends_with(SAVE_ENDING):
			var config := ConfigFile.new()
			if not config.load(SAVES_PATH + file_name) == OK:
				continue
			var n = config.get_value("metadata", "name", "")
			if not n is String:
				continue
			if not n:
				n = "<No name>"
			var date = config.get_value("metadata", "date", {})
			if not date is Dictionary or date.empty() or not date.has_all(["year", "month", "day", "hour", "minute", "second"]):
				continue
			var s := save.instance()
			s.text = "%s - %04d/%02d/%02d %02d:%02d:%02d" % [n, date.year, date.month, date.day, date.hour, date.minute, date.second]
			slots.add_child(s)
			s.connect("overwrite", self, "on_save_overwrite", [s])
			s.connect("load_requested", self, "on_save_load", [s])
			s.connect("delete", self, "on_save_delete", [s])
			saves.append(file_name)
		file_name = dir.get_next()
	if OS.get_name() == "HTML5" and OS.has_feature("JavaScript"):
		_define_js()

func _define_js() -> void:
	JavaScript.eval("""
	var _HTML5FileExchange = {};
	_HTML5FileExchange.upload = function(gd_callback) {
		canceled = true;
		var input = document.createElement('INPUT'); 
		input.setAttribute("type", "file");
		input.setAttribute("accept", "image/png, image/jpeg, image/webp");
		input.click();
		input.addEventListener('change', event => {
			if (event.target.files.length > 0){
				canceled = false;}
			var file = event.target.files[0];
			var reader = new FileReader();
			this.fileType = file.type;
			// var fileName = file.name;
			reader.readAsArrayBuffer(file);
			reader.onloadend = (evt) => { // Since here's it's arrow function, "this" still refers to _HTML5FileExchange
				if (evt.target.readyState == FileReader.DONE) {
					this.result = evt.target.result;
					gd_callback(); // It's hard to retrieve value from callback argument, so it's just for notification
				}
			}
		  });
	}
	""", true)

func save_image(image:Image, fileName:String = "export.png")->void:
	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
		return
	
	image.clear_mipmaps()
	var buffer = image.save_png_to_buffer()
	JavaScript.download_buffer(buffer, fileName)


func on_button_toggled(button_pressed: bool, index: int) -> void:
	if button_pressed:
		show_option(index)


func show_option(index: int) -> void:
	for child in items_panel.get_children():
		child.hide()
	items_panel.get_child(index).show()
	flip.pressed = flips[index]


func on_item_toggled(on: bool, i: VBoxContainer) -> void:
	if on:
		for child in i.get_parent().get_children():
			if not child == i:
				child.select(false)
		base.get_child(i.get_parent().get_parent().get_index()).texture = i.get_node("TextureButton").texture_normal
	else:
		base.get_child(i.get_parent().get_parent().get_index()).texture = null


func change_color(color: Color, type: String) -> void:
	base.material.set_shader_param("replace_%s_color" % type, color)


func _on_SaveLoad_pressed() -> void:
	save_load.popup_centered()


func _on_NewSave_pressed() -> void:
	save_info()


func save_info() -> void:
	var config := ConfigFile.new()
	var date := OS.get_datetime()
	var unix := OS.get_unix_time()
	config.set_value("metadata", "date", date)
	config.set_value("metadata", "name", name_edit.text)
	for option in items_panel.get_children():
		var found_selected = false
		for i in option.get_node("Grid").get_children():
			if i.selected:
				config.set_value("items", OPTIONS[option.get_index()], i.get_index())
				found_selected = true
				break
		if not found_selected:
			config.set_value("items", OPTIONS[option.get_index()], -1)
	for child in colors.get_children():
		if child is ColorPickerButton:
			config.set_value("colors", COLOR_TYPES[child.get_index() / 2], child.color)
	config.set_value("data", "flips", flips)
	var dir := Directory.new()
	if dir.file_exists(SAVES_PATH + str(unix)):
		var counter := 0
		var name_to_check := str(unix) + str(counter)
		while dir.file_exists(SAVES_PATH + name_to_check):
			counter += 1
			name_to_check = str(unix) + str(counter)
		config.save(SAVES_PATH + name_to_check + SAVE_ENDING)
		saves.push_front(name_to_check + SAVE_ENDING)
	else:
		config.save(SAVES_PATH + str(unix) + SAVE_ENDING)
		saves.push_front(str(unix) + SAVE_ENDING)
	var s := save.instance()
	var name_to_use = name_edit.text if name_edit.text else "<No name>"
	s.text = "%s - %04d/%02d/%02d %02d:%02d:%02d" % [name_to_use, date.year, date.month, date.day, date.hour, date.minute, date.second]
	slots.add_child(s)
	slots.move_child(s, 0)


func on_save_overwrite(s: MenuButton) -> void:
	remove_save(s)
	save_info()
	

func on_save_load(s: MenuButton) -> void:
	var config := ConfigFile.new()
	if not config.load(SAVES_PATH + saves[s.get_index()]) == OK:
		return
	for i in OPTIONS.size():
		var index = config.get_value("items", OPTIONS[i], -1)
		if index == -1:
			continue
		for child in items_panel.get_child(i).get_node("Grid").get_children():
			child.select(false)
		items_panel.get_child(i).get_node("Grid").get_child(index).select(true)
		base.get_child(i).texture = items_panel.get_child(i).get_node("Grid").get_child(index).get_node("TextureButton").texture_normal
	for i in COLOR_TYPES.size():
		var color = config.get_value("colors", COLOR_TYPES[i], Color.white)
		colors.get_child(i * 2 + 1).color = color
		change_color(color, COLOR_TYPES[i])
	var f = config.get_value("data", "flips", [])
	if f is Array and f.size() == OPTIONS.size():
		flips = f
	for i in flips.size():
		base.get_child(i).flip_h = flips[i]
	flip.pressed = flips[buttons.get_child(0).group.get_pressed_button().get_index()]
	save_load.hide()
	
	
func on_save_delete(s: MenuButton) -> void:
	remove_save(s)


func remove_save(s: MenuButton) -> void:
	var dir := Directory.new()
	dir.remove(SAVES_PATH + saves[s.get_index()])
	saves.remove(s.get_index())
	s.queue_free()


func _on_DeleteAll_pressed() -> void:
	var dir := Directory.new()
	for s in saves:
		dir.remove(SAVES_PATH + s)
	saves = []
	for child in slots.get_children():
		child.queue_free()


func _on_Random_pressed() -> void:
	for i in OPTIONS.size():
		var count := items_panel.get_child(i).get_node("Grid").get_child_count()
		var index := randi() % count
		items_panel.get_child(i).get_node("Grid").get_child(index).select(true)
		base.get_child(i).texture = items_panel.get_child(i).get_node("Grid").get_child(index).get_node("TextureButton").texture_normal


func _on_Download_pressed() -> void:
	var img: Image = $VBox/Top/Portrait/ViewportContainer/Viewport.get_texture().get_data()
	img.flip_y()
	var download_name: String = name_edit.text if name_edit.text else "No name"
	save_image(img, download_name)


func _on_Flip_toggled(button_pressed: bool) -> void:
	var index: int = buttons.get_child(0).group.get_pressed_button().get_index()
	flips[index] = button_pressed
	base.get_child(index).flip_h = button_pressed
