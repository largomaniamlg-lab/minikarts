shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 flame_color : source_color = vec4(1.0,0.68,0.15,1.0);
void fragment() { ALBEDO=flame_color.rgb; ALPHA=0.55; }
