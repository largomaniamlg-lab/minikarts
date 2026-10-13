shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform float thickness : hint_range(0.0, 0.12) = 0.05;
uniform vec4 outline_color : source_color = vec4(0.04, 0.055, 0.075, 1.0);
uniform bool smooth_shell = false;
uniform float far_distance = 60.0;
void vertex() {
 vec3 shell_normal = smooth_shell && length(VERTEX) > 0.001 ? normalize(VERTEX) : NORMAL;
 float range = distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, CAMERA_POSITION_WORLD);
 float fade = 1.0 - smoothstep(far_distance * 0.65, far_distance, range);
 VERTEX += shell_normal * thickness * fade;
}
void fragment() { ALBEDO = outline_color.rgb; }
