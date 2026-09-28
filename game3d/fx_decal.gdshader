shader_type spatial;
// Additive quad for spell effects. mode 0: texture (ground runes, glows).
// mode 1: pixel ring of radius `radius` (m) and `width` pixels, optionally only
// within `half_angle` of `arc_dir` (cone sweeps). mode 2: dashed line along
// the quad's length (telegraphs). Rings/lines are drawn on a 1/24 m pixel grid
// so they stay crisp at any size.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform sampler2D tex : filter_nearest, source_color;
uniform vec4 color : source_color = vec4(1.0);
uniform bool billboard = false;
uniform int mode = 0;
uniform vec2 size_m = vec2(1.0);     // quad size in metres (modes 1/2)
uniform float radius = 1.0;
uniform float width = 1.0;           // pixels
uniform float fill = 0.0;            // mode 1: alpha of the disc inside the ring
uniform vec2 arc_dir = vec2(1.0, 0.0);
uniform float half_angle = 3.2;
uniform float dash_phase = 0.0;
uniform bool solid_line = false;
uniform float depth_bias = 0.35;     // metres toward the camera: ground marks stay visible on slopes

const float PX = 1.0 / 24.0;

void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	}
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.z += depth_bias;
	POSITION = PROJECTION_MATRIX * view;
}

void fragment() {
	if (mode == 0) {
		vec4 c = texture(tex, UV);
		ALBEDO = c.rgb * color.rgb;
		ALPHA = c.a * color.a;
	} else if (mode == 1) {
		vec2 p = (floor((UV - 0.5) * size_m / PX) + 0.5) * PX;
		p.y = -p.y;
		float d = length(p);
		float a = 0.0;
		if (abs(d - radius) < width * PX * 0.5 + PX * 0.5) {
			a = 1.0;
		} else if (d < radius) {
			a = fill;
		}
		if (half_angle < 3.14) {
			float ang = acos(clamp(dot(normalize(p + vec2(1e-5)), normalize(arc_dir)), -1.0, 1.0));
			if (ang > half_angle) {
				a = 0.0;
			}
		}
		if (a <= 0.0) discard;
		ALBEDO = color.rgb;
		ALPHA = color.a * a;
	} else {
		// dashed line: UV.x runs along the line
		float along = floor(UV.x * size_m.x / PX);
		float across = abs((UV.y - 0.5) * size_m.y / PX);
		if (across > width * 0.5) discard;
		if (!solid_line && mod(along + dash_phase, 4.0) >= 2.0) discard;
		ALBEDO = color.rgb;
		ALPHA = color.a;
	}
}
