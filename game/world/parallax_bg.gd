class_name ParallaxBG
extends Node2D
## Region backdrop: fixed sky plus three layers that scroll sideways at
## different speeds and tile. Vertically the backdrop stays screen-fixed so
## tall levels never reveal an edge.

const LAYERS := [["sky", 0.0], ["far", 0.12], ["mid", 0.3], ["near", 0.55]]

var region := "woods"


func _ready() -> void:
	z_index = -100
	z_as_relative = false
	for l in LAYERS:
		var px := Parallax2D.new()
		px.scroll_scale = Vector2(l[1], 0.0)
		px.repeat_size = Vector2(640, 0)
		px.repeat_times = 3
		var spr := Sprite2D.new()
		spr.texture = load("res://assets/generated/bg_%s_%s.png" % [region, l[0]])
		spr.centered = false
		px.add_child(spr)
		add_child(px)
