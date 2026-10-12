shader_type spatial;
render_mode specular_disabled;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_albedo_texture = false;
uniform bool use_vertex_color = false;
uniform sampler2D ramp : filter_nearest, repeat_disable;
uniform vec4 shadow_tint : source_color = vec4(0.37, 0.29, 0.61, 1.0);
uniform float rim_strength : hint_range(0.0, 0.4) = 0.08;
uniform vec3 glow : source_color = vec3(0.0);
void fragment() {
 ALBEDO = use_vertex_color ? mix(COLOR.rgb, COLOR.rgb * albedo.rgb, COLOR.a) : albedo.rgb;
 if (use_albedo_texture) ALBEDO *= texture(albedo_texture, UV).rgb;
 ROUGHNESS = 1.0;
 float edge = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
 EMISSION = ALBEDO * edge * rim_strength + glow;
}
void light() {
 // ATTENUATION includes the DirectionalLight shadow; quantize it with N.L.
 float light_level = clamp(max(dot(NORMAL, LIGHT), 0.0) * ATTENUATION, 0.0, 1.0);
 float band = texture(ramp, vec2(light_level, 0.5)).r;
 DIFFUSE_LIGHT += mix(shadow_tint.rgb, vec3(1.0), band) * LIGHT_COLOR / PI;
}
