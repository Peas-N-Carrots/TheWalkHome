extends ColorRect

var capture_timer = 0.0
var capture_interval = 2.0

var afterimage: ImageTexture
var blend: float

func _ready() -> void:
	var blank = Image.create(
		get_viewport().size.x,
		get_viewport().size.y,
		false,
		Image.FORMAT_RGB8
	)
	blank.fill(Color.BLACK)
	afterimage = ImageTexture.create_from_image(blank)
	
	material.set_shader_parameter("AFTERIMAGE_TEXTURE", afterimage)
	material.set_shader_parameter("AFTERIMAGE_BLEND", blend)

func _process(delta: float) -> void:
	capture_timer -= delta
	
	if capture_timer <= 0.0:
		#visible = false
		#await RenderingServer.frame_post_draw
		
		afterimage.update(get_viewport().get_texture().get_image())
		
		#visible = true
		
		capture_timer = capture_interval
		blend = 0.0
		material.set_shader_parameter("AFTERIMAGE_BLEND", blend)
	
	else:
		blend = clamp(capture_timer/capture_interval, 0.0, 1.0)
		material.set_shader_parameter("AFTERIMAGE_BLEND", blend)
