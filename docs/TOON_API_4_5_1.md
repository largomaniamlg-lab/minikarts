# APIs verificadas

Las propiedades se cotejaron con los XML de clases del tag **4.5.1-stable** del propio motor, no con documentación `latest`:
https://github.com/godotengine/godot/tree/4.5.1-stable/doc/classes

- Light3D: `shadow_enabled`, `light_energy`, `light_bake_mode`, `BAKE_DISABLED` (excluye sol del horneado).
- DirectionalLight3D: `directional_shadow_max_distance`.
- Environment: `FOG_MODE_DEPTH`, `fog_depth_begin/end`, `fog_light_color`, `ambient_light_energy/source`, `BG_SKY`.
- ProceduralSkyMaterial: `sky_top_color`, `sky_horizon_color`, `ground_horizon_color`, `sky_curve`.
- Material / ShaderMaterial: `next_pass`, `shader`, `set_shader_parameter()`.
- PrimitiveMesh: `add_uv2`; GeometryInstance3D: `GI_MODE_STATIC`, `SHADOW_CASTING_SETTING_OFF`.
- TorusMesh: `inner_radius`, `outer_radius`, `rings`, `ring_segments`.
- MultiMesh: `TRANSFORM_3D`, `mesh`, `instance_count`, `set_instance_transform()`.
- Viewport: `get_render_info(RenderInfoType, RenderInfo)`: **dos argumentos**, primero `RENDER_INFO_TYPE_VISIBLE`.
- RenderingServer: `get_current_rendering_method()`, `frame_post_draw`.
- DisplayServer: `get_display_safe_area()`: disponible en Android/iOS, devuelve rectángulo en píxeles del display.
- LightmapGI: `bounces`, `quality`, `directional`, `BAKE_QUALITY_LOW`. **No existe un método GDScript público `bake()`** en esta versión. El horneado se invoca desde el editor.

Shader spatial: [referencia oficial 4.5](https://github.com/godotengine/godot-docs/blob/4.5/tutorials/shaders/shader_reference/spatial_shader.rst) y [built-ins del motor exacto](https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/shader_types.cpp): `light()`, `ATTENUATION` (incluye sombra), `DIFFUSE_LIGHT`, `LIGHT_COLOR`, `PI`, `NORMAL`, `VIEW`, `COLOR`, `filter_nearest`, `cull_front`, `blend_add`, `depth_draw_never`, `shadows_disabled`. `force_vertex_shading=false` evita omitir `light()` en dispositivos móviles.

LightmapGI no hornea primitivas ni geometría generada en runtime. La demo convierte su geometría horneable a ArrayMesh persistente con UV2 e incluye el horneado real `toon_demo.lmbake` / `toon_demo.exr`, generado en el editor Mobile (18 s en el host). El sol tiene BAKE_DISABLED para no duplicar la luz directa. Árboles/arbustos MultiMesh reciben el sol en tiempo real. Los circuitos de producción siguen siendo procedurales: se usa sol + luz ambiental, sin fingir que hay lightmaps generados. SSAO, SSR, SDFGI, VoxelGI y niebla volumétrica no se activan.
