shader_type spatial;
// Motorsport finish: continuous lighting with controlled glossy highlights.
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_albedo_texture = false;
uniform bool use_vertex_color = false;
uniform sampler2D ramp : filter_nearest, repeat_disable;
uniform vec4 shadow_tint : source_color = vec4(0.37, 0.29, 0.61, 1.0);
uniform float rim_strength : hint_range(0.0, 0.4) = 0.08;
uniform float finish_roughness = 0.65;
uniform float finish_metallic = 0.0;
uniform float surface_grain = 0.0;
uniform vec3 glow : source_color = vec3(0.0);
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 ALBEDO = use_vertex_color ? mix(COLOR.rgb, COLOR.rgb * albedo.rgb, COLOR.a) : albedo.rgb;
 if (use_albedo_texture) ALBEDO *= texture(albedo_texture, UV).rgb;
 float grain = fract(sin(dot(world_position.xz * 150.0, vec2(12.9898,78.233))) * 43758.5453);
 ALBEDO *= 1.0 - surface_grain * grain;
 ROUGHNESS = finish_roughness;
 METALLIC = finish_metallic;
 float edge = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
 EMISSION = ALBEDO * edge * rim_strength + glow;
}
void light() {
 // ATTENUATION includes the DirectionalLight shadow; quantize it with N.L.
 float light_level = clamp(max(dot(NORMAL, LIGHT), 0.0) * ATTENUATION, 0.0, 1.0);
 float band = smoothstep(0.0, 1.0, light_level);
 DIFFUSE_LIGHT += mix(vec3(0.10,0.13,0.19), vec3(1.0), band) * LIGHT_COLOR / PI;
 vec3 half_light = normalize(LIGHT + VIEW);
 float shine = pow(max(dot(NORMAL, half_light), 0.0), mix(90.0, 8.0, finish_roughness));
 SPECULAR_LIGHT += shine * ATTENUATION * LIGHT_COLOR * mix(vec3(0.12), ALBEDO, finish_metallic) * (1.0-finish_roughness);
}
