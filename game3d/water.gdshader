shader_type spatial;
// Flowing pixel water on a world-space texel grid.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D tex : filter_nearest, repeat_enable;
uniform vec2 flow = vec2(0.0, 0.6);
uniform float density = 24.0;
uniform vec3 tint = vec3(1.0);
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = floor((wpos.xz + flow * TIME) * density);
	if (abs(NORMAL.y) < 0.5) p = floor((vec2(wpos.x + wpos.z, wpos.y) + vec2(0.0, 2.2) * TIME) * density);
	vec3 c = texture(tex, (p + 0.5) / 32.0).rgb;
	c *= tint;
	ALBEDO = c;
	EMISSION = c * 0.25;
}

void light() {
	float i = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	DIFFUSE_LIGHT += floor(i * 4.0 + 0.35) / 4.0 * LIGHT_COLOR;
}
