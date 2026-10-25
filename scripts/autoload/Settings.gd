extends Node
## Player settings: volume (master / music / SFX), brightness, fullscreen.
## Changes apply live; save() writes them to disk, revert() drops unsaved changes.

const SAVE_PATH := "user://settings.cfg"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const MIN_BRIGHTNESS := 0.5
const MAX_BRIGHTNESS := 1.5

const BRIGHTNESS_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float brightness = 1.0;
void fragment() {
	vec4 c = texture(screen_tex, SCREEN_UV);
	COLOR = vec4(c.rgb * brightness, 1.0);
}
"""

signal changed

## Volumes are linear 0..1.
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var brightness: float = 1.0
var fullscreen: bool = false

var _brightness_layer: CanvasLayer
var _brightness_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_build_brightness_overlay()
	load_settings()


func _ensure_bus(bus_name: String) -> void:
	## Prefer buses from default_bus_layout.tres (required for reliable Godot 4.3 web audio).
	## Only add at runtime if the layout failed to load.
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _build_brightness_overlay() -> void:
	# Above every other layer so menus get the same brightness as the world.
	_brightness_layer = CanvasLayer.new()
	_brightness_layer.layer = 100
	add_child(_brightness_layer)
	_brightness_rect = ColorRect.new()
	_brightness_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_brightness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = BRIGHTNESS_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_brightness_rect.material = mat
	_brightness_layer.add_child(_brightness_rect)


func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_bus("Master", master_volume)


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_bus(MUSIC_BUS, music_volume)


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus(SFX_BUS, sfx_volume)


func set_brightness(v: float) -> void:
	brightness = clampf(v, MIN_BRIGHTNESS, MAX_BRIGHTNESS)
	(_brightness_rect.material as ShaderMaterial).set_shader_parameter("brightness", brightness)
	# Skip the full-screen pass entirely at normal brightness.
	_brightness_rect.visible = not is_equal_approx(brightness, 1.0)


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## True window state. In the browser, Esc can leave fullscreen behind the game's back.
func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _apply_bus(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.001)))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(SAVE_PATH)


func load_settings() -> void:
	_apply_saved(true)


## Drop unsaved changes and go back to what is on disk.
func revert() -> void:
	_apply_saved(false)


func _apply_saved(startup: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)  # Missing file → defaults below.
	set_master_volume(cfg.get_value("audio", "master", 1.0))
	set_music_volume(cfg.get_value("audio", "music", 1.0))
	set_sfx_volume(cfg.get_value("audio", "sfx", 1.0))
	set_brightness(cfg.get_value("video", "brightness", 1.0))
	var want_full: bool = cfg.get_value("video", "fullscreen", false)
	# Browsers only allow fullscreen from a click, so the web build starts windowed.
	if not (startup and OS.has_feature("web")) and want_full != is_fullscreen():
		set_fullscreen(want_full)
	fullscreen = want_full
	changed.emit()
