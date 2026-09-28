shader_type spatial;
// Pixel-textured 3D props (stone, wood): world-space triplanar on a texel
// grid, banded lighting to match the terrain.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D tex : filter_nearest, repeat_enable, source_color;
uniform vec4 tint : source_color = vec4(1.0);
uniform float density = 24.0;
uniform vec3 emission = vec3(0.0);
varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(wnrm);
	vec2 p;
	if (n.y > n.x && n.y > n.z) p = wpos.xz;
	else if (n.x > n.z) p = wpos.zy;
	else p = wpos.xy;
	vec2 tp = floor(p * density);
	ALBEDO = texture(tex, (tp + 0.5) / 32.0).rgb * tint.rgb;
	EMISSION = emission;
}

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
const float bands = 5.0;

void light() {
	// dithered banding: light falls off in pixel-dithered steps
	ivec2 q = ivec2(mod(FRAGCOORD.xy, 4.0));
	float d = (BAYER[q.y * 4 + q.x] + 0.5) / 16.0 - 0.5;
	float i = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	i = clamp(floor(i * bands + 0.5 + d * 0.9) / bands, 0.0, 1.5);
	DIFFUSE_LIGHT += i * LIGHT_COLOR;
}
