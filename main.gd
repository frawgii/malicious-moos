extends Node2D

@onready var cow = $Cow
@onready var timer = $Timer

var target_position = Vector2()
var is_walking = false
var speed = 150.0

func _ready():
	timer.wait_time = 3.0
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	target_position = cow.position
	
	# Start by playing the idle animation
	cow.play("idle") 
	
	# Ensure the invisible window covers the entire monitor
	var screen_size = DisplayServer.screen_get_size()
	get_window().size = screen_size
	get_window().position = Vector2i(0, 0)

func _process(delta):
	if is_walking:
		cow.position = cow.position.move_toward(target_position, speed * delta)
		
		if cow.position.distance_to(target_position) < 5.0:
			is_walking = false
			cow.play("idle") 
	
	var current_texture = cow.sprite_frames.get_frame_texture(cow.animation, cow.frame)
	var tex_size = current_texture.get_size()
	
	var canvas_transform = cow.get_global_transform_with_canvas()
	var screen_pos = canvas_transform.get_origin()
	var screen_scale = canvas_transform.get_scale()
	
	# NEW: Add a 15-pixel buffer around the cow to prevent black edge artifacts
	var padding = 15.0 
	
	var width = (tex_size.x * screen_scale.x) + padding
	var height = (tex_size.y * screen_scale.y) + padding
	
	# Draw the slightly larger box around the cow
	var polygon = PackedVector2Array([
		Vector2(screen_pos.x - width / 2, screen_pos.y - height / 2), 
		Vector2(screen_pos.x + width / 2, screen_pos.y - height / 2), 
		Vector2(screen_pos.x + width / 2, screen_pos.y + height / 2), 
		Vector2(screen_pos.x - width / 2, screen_pos.y + height / 2)  
	])
	
	DisplayServer.window_set_mouse_passthrough(polygon)

func _on_timer_timeout():
	if randi() % 2 == 0:
		is_walking = true
		
		# Start playing the walk animation when it begins to move
		cow.play("walk") 
		
		var screen_size = DisplayServer.screen_get_size()
		target_position = Vector2(
			randf_range(0, screen_size.x),
			randf_range(0, screen_size.y)
		)
		
		if target_position.x < cow.position.x:
			cow.flip_h = true 
		else:
			cow.flip_h = false
