shader_type spatial;
// Billboard pixel sprite, lit with the same banded lighting as the terrain.
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D tex : filter_nearest, source_color;
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);  // uv rect of the frame
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform float bands = 4.0;
uniform float emit = 0.0;

void vertex() {
	// face the camera fully (keeps pixel-art proportions)
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
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
