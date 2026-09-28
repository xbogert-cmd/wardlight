shader_type spatial;
// Billboard pixel sprite, lit with the same banded lighting as the terrain.
render_mode diffuse_lambert, specular_disabled, cull_disabled, skip_vertex_transform;

uniform sampler2D tex : filter_nearest, source_color;
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);  // uv rect of the frame
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform float bands = 4.0;
uniform float emit = 0.0;
uniform float depth_bias = 0.15;  // metres toward the camera so near ground/props don't nick the feet

void vertex() {
	// Stand upright, turned only around Y, so props behind a character stay behind the whole
	// sprite (a fully camera-facing quad leans back into them). Stretch Y by 1/cos(pitch) so
	// the sprite still covers the same pixels as a camera-facing one.
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	float stretch = 1.0 / max(length(INV_VIEW_MATRIX[2].xz), 0.2);
	vec3 scl = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 world = MODEL_MATRIX[3].xyz + right * VERTEX.x * scl.x + vec3(0.0, VERTEX.y * scl.y * stretch, 0.0);
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
	VERTEX.z += depth_bias;
	NORMAL = vec3(0.0, 0.0, 1.0);
	UV = region.xy + UV * region.zw;
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) discard;
	ALBEDO = mix(c.rgb * tint.rgb, flash_color.rgb, flash);
	EMISSION = ALBEDO * emit;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void light() {
	float i = (0.6 + 0.4 * clamp(dot(NORMAL, LIGHT), 0.0, 1.0)) * ATTENUATION;
	i = floor(i * bands + 0.5) / bands;
	DIFFUSE_LIGHT += i * LIGHT_COLOR;
}
