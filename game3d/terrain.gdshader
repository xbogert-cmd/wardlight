shader_type spatial;
// Pixel-art terrain: textures are sampled on a world-space texel grid
// (24 px per metre), surfaces blend through a 4x4 ordered dither, steep
// faces become rock, and lighting is quantised into bands.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D grass_tex : filter_nearest, repeat_enable;
uniform sampler2D path_tex : filter_nearest, repeat_enable;
uniform sampler2D dirt_tex : filter_nearest, repeat_enable;
uniform sampler2D rock_tex : filter_nearest, repeat_enable;
uniform sampler2D splat : filter_linear, repeat_disable;
uniform vec2 map_origin = vec2(0.0);
uniform vec2 map_size = vec2(64.0);
uniform float density = 24.0;
uniform float tex_px = 32.0;
uniform float bands = 5.0;

varying vec3 wpos;
varying vec3 wnrm;

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float dither(vec2 tp) {
	ivec2 i = ivec2(mod(tp, 4.0));
	return (BAYER[i.y * 4 + i.x] + 0.5) / 16.0;
}

vec3 tex_at(sampler2D t, vec2 tp) {
	return texture(t, (tp + 0.5) / tex_px).rgb;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 tp = floor(wpos.xz * density);
	float d = dither(tp);
	vec4 sp = texture(splat, (wpos.xz - map_origin) / map_size);
	vec3 col = tex_at(grass_tex, tp);
	if (sp.g > d) col = tex_at(dirt_tex, tp);
	if (sp.r > d) col = tex_at(path_tex, tp);
	float steep = 1.0 - clamp(wnrm.y, 0.0, 1.0);
	if (steep > 0.42 + (d - 0.5) * 0.12) {
		vec2 side = abs(wnrm.x) > abs(wnrm.z) ? wpos.zy : wpos.xy;
		col = tex_at(rock_tex, floor(side * density));
		// grass lip along cliff tops
		if (steep < 0.5 && d < 0.4) col = tex_at(grass_tex, tp) * 1.1;
	}
	ALBEDO = col;
}

void light() {
	// dithered banding: light falls off in pixel-dithered steps
	ivec2 q = ivec2(mod(FRAGCOORD.xy, 4.0));
	float d = (BAYER[q.y * 4 + q.x] + 0.5) / 16.0 - 0.5;
	float i = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	i = clamp(floor(i * bands + 0.5 + d * 0.9) / bands, 0.0, 1.5);
	DIFFUSE_LIGHT += i * LIGHT_COLOR;
}
