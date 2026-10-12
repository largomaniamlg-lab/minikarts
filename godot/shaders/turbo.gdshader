shader_type spatial;
render_mode unshaded;
uniform vec4 color : source_color = vec4(0.32,0.89,1.0,1.0);
void fragment() {
 vec2 uv = UV;
 float chevron = step(0.58, fract(uv.y * 5.0 + abs(uv.x - 0.5) * 2.0 - TIME * 1.4));
 ALBEDO = mix(vec3(0.08,0.15,0.3), color.rgb, chevron);
 EMISSION = color.rgb * chevron * 0.25;
}
