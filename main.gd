extends Node2D

@export var meme_images: Array[Texture2D] 

@onready var cow = $Cow
@onready var timer = $Timer
@onready var meme_window = $MemeWindow
@onready var meme = $MemeWindow/Cow_Im_1
@onready var close_button = $MemeWindow/CloseButton # Grabs your new button!
@onready var moo_sound = $MooSound # Grabs your new speaker!
@export var footprint_texture: Texture2D # Holds your mud image
@export var footprint_scale: float = 0.3
var distance_walked = 0.0
var footprint_spacing = 40.0 # How many pixels the cow walks before leaving a print

var target_position = Vector2()
var is_walking = false
var is_dragging = false
var speed = 150.0
var last_polygon = PackedVector2Array() 

func _ready():
	timer.wait_time = 3.0
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	target_position = cow.position
	cow.play("idle")
	cow.z_index = 10
	
	close_button.pressed.connect(_on_close_button_pressed)
	
	# --- CONFIGURE THE SEPARATE MEME WINDOW ---
	meme_window.hide()
	meme_window.transient = false 
	meme_window.borderless = true
	meme_window.transparent = true
	meme_window.unresizable = true
	meme_window.always_on_top = true
	meme_window.transparent_bg = true 
	
	# --- CONFIGURE THE MAIN COW WINDOW ---
	var screen_size = DisplayServer.screen_get_size()
	get_window().size = screen_size
	get_window().position = Vector2i(0, 0)
	get_window().always_on_top = true
	get_window().unfocusable = true 
	get_window().borderless = true 
	get_window().transparent = true

func _process(delta):
	if is_walking or is_dragging:
		var old_pos = cow.position # Remember where the cow was a millisecond ago
		cow.position = cow.position.move_toward(target_position, speed * delta)
		
		# --- NEW: FOOTPRINT TRACKER ---
		distance_walked += old_pos.distance_to(cow.position)
		if distance_walked >= footprint_spacing:
			distance_walked = 0.0
			spawn_footprint()
		# ------------------------------
		if is_dragging:
			cow.flip_h = false 
			var canvas_transform = cow.get_global_transform_with_canvas()
			var screen_pos = canvas_transform.get_origin()
			
			var c_tex = cow.sprite_frames.get_frame_texture(cow.animation, cow.frame)
			var c_width = c_tex.get_size().x * cow.scale.x
			var m_height = meme_window.size.y
			
			var overlap = 40.0 
			var offset_x = (c_width / 2.0) + (meme_window.size.x / 2.0) - overlap
			
			meme_window.position = Vector2i(int(screen_pos.x + offset_x), int(screen_pos.y - m_height / 2.0))
		
		if cow.position.distance_to(target_position) < 5.0:
			is_walking = false
			if is_dragging:
				is_dragging = false 
			cow.play("idle") 

	# --- PURE COW PASSTHROUGH LOGIC (PIXEL PERFECT) ---
	var current_texture = cow.sprite_frames.get_frame_texture(cow.animation, cow.frame)
	var tex_size = current_texture.get_size()
	var canvas_transform = cow.get_global_transform_with_canvas()
	var screen_pos = canvas_transform.get_origin()
	var screen_scale = canvas_transform.get_scale()
	
	var padding = 20.0 
	var c_w = (tex_size.x * screen_scale.x) + padding
	var c_h = (tex_size.y * screen_scale.y) + padding
	
	var c_min_x = screen_pos.x - c_w / 2.0
	var c_max_x = screen_pos.x + c_w / 2.0
	var c_min_y = screen_pos.y - c_h / 2.0
	var c_max_y = screen_pos.y + c_h / 2.0
	
	var p1 = Vector2(round(c_min_x), round(c_min_y))
	var p2 = Vector2(round(c_max_x), round(c_min_y))
	var p3 = Vector2(round(c_max_x), round(c_max_y))
	var p4 = Vector2(round(c_min_x), round(c_max_y))
	
	var polygon = PackedVector2Array([p1, p2, p3, p4])
	
	if polygon != last_polygon:
		DisplayServer.window_set_mouse_passthrough(polygon)
		last_polygon = polygon

func _on_timer_timeout():
	if is_walking or is_dragging:
		return
		
	var screen_size = DisplayServer.screen_get_size()
	var action_roll = randi() % 10 
	
	if action_roll <= 2 and not meme_window.visible: 
		if meme_images.is_empty():
			return
			
		is_dragging = true
		meme.texture = meme_images.pick_random()
		
		var m_size = meme.texture.get_size() * meme.scale
		meme_window.size = Vector2i(int(m_size.x), int(m_size.y))
		meme.position = m_size / 2.0
		
		# Position the X button dynamically in the top-right corner of the new image!
		close_button.position = Vector2(0, 0)
		
		meme_window.show() 
		
		get_window().always_on_top = false
		get_window().always_on_top = true
		
		cow.play("walk")
		cow.position = Vector2(screen_size.x + 150, randf_range(200, screen_size.y - 200))
		target_position = Vector2(screen_size.x / 2.0, cow.position.y)
		cow.flip_h = false
		
	elif action_roll >= 3 and action_roll <= 6: 
		is_walking = true
		cow.play("walk")
		target_position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))
		
		if target_position.x < cow.position.x:
			cow.flip_h = true 
		else:
			cow.flip_h = false

# --- NEW: CLOSE BUTTON LOGIC ---
func _on_close_button_pressed():
	# Make the meme window vanish
	meme_window.hide()
	
	# If you click the X while the cow is actively dragging it, tell the cow to drop it!
	if is_dragging:
		is_dragging = false
		is_walking = true
		
		
# --- NEW: CLICK DETECTION LOGIC ---
# --- NEW: FOOLPROOF CLICK DETECTION ---
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# Get the exact mouse position in the 2D world
		var mouse_pos = get_global_mouse_position()
		
		# If the mouse click is within 60 pixels of the cow's center, MOO!
		if cow.position.distance_to(mouse_pos) < 60.0: 
			moo_sound.play()
			
# --- NEW: SCALED MICRO-WINDOW FOOTPRINTS ---
func spawn_footprint():
	if footprint_texture == null:
		return
		
	var print_win = Window.new()
	print_win.borderless = true
	print_win.transparent = true
	print_win.transparent_bg = true
	print_win.unfocusable = true
	print_win.always_on_top = true
	print_win.transient = false 
	print_win.mouse_passthrough = true 
	
	# 1. Calculate the new shrunken size
	var raw_size = footprint_texture.get_size()
	var f_size = raw_size * footprint_scale
	
	print_win.size = Vector2i(int(f_size.x), int(f_size.y))
	
	var canvas_transform = cow.get_global_transform_with_canvas()
	var spawn_pos = canvas_transform.get_origin()
	print_win.position = Vector2i(int(spawn_pos.x - f_size.x / 2.0), int(spawn_pos.y - f_size.y / 2.0 + 35))
	
	add_child(print_win)
	print_win.show()
	
	var print_sprite = Sprite2D.new()
	print_sprite.texture = footprint_texture
	
	# 2. Physically shrink the image to match the tiny window
	print_sprite.scale = Vector2(footprint_scale, footprint_scale) 
	
	print_sprite.position = f_size / 2.0
	print_sprite.rotation_degrees = randf_range(-30.0, 30.0)
	print_win.add_child(print_sprite)
	
	var tween = create_tween()
	tween.tween_property(print_sprite, "modulate:a", 0.0, 2.0)
	tween.tween_callback(print_win.queue_free)
