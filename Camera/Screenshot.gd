extends Node
class_name ViewportScreenshot


@export var screenshot_width: int = 320
@export var screenshot_height: int = 180


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if not event.echo:
				if event.keycode == KEY_F12:
					take_screenshot()


func take_screenshot() -> void:
	await RenderingServer.frame_post_draw

	var image: Image = get_viewport().get_texture().get_image()

	print(
		"SCREENSHOT ORIGINAL SIZE: ",
		image.get_width(),
		" x ",
		image.get_height()
	)

	if (
		image.get_width() != screenshot_width
		or image.get_height() != screenshot_height
	):
		image.resize(
			screenshot_width,
			screenshot_height,
			Image.INTERPOLATE_NEAREST
		)

	var folder_path: String = "user://Screenshots"

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(folder_path)
	)

	var timestamp: String = (
		Time.get_datetime_string_from_system()
		.replace(":", "-")
	)

	var file_path: String = (
		folder_path
		+ "/level_"
		+ timestamp
		+ ".png"
	)

	var error: Error = image.save_png(file_path)

	if error == OK:
		print(
			"SCREENSHOT SAVED: ",
			ProjectSettings.globalize_path(file_path)
		)
		print(
			"SCREENSHOT SIZE: ",
			image.get_width(),
			" x ",
			image.get_height()
		)
	else:
		print("SCREENSHOT FAILED: ", error)
