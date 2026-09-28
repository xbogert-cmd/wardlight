shader_type spatial;
// Additive textured quad (ground runes, glows). Nearest filtering keeps pixels.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform sampler2D tex : filter_nearest, source_color;
uniform vec4 color : source_color = vec4(1.0);
uniform bool billboard = false;

void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	}
}

void fragment() {
	vec4 c = texture(tex, UV);
	ALBEDO = c.rgb * color.rgb;
	ALPHA = c.a * color.a;
}
