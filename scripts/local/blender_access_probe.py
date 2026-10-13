"""Non-destructive Blender CLI probe; writes only to a new output directory."""
import argparse
import json
import sys
from pathlib import Path
import bpy

parser = argparse.ArgumentParser()
parser.add_argument('--output', required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
output = Path(args.output).resolve()
output.mkdir(parents=True, exist_ok=False)
# This script is launched in its own --factory-startup --background process.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))
cube = bpy.context.object
cube.name = 'MiniKarts_Access_Probe'
material = bpy.data.materials.new('ProbeYellow')
material.diffuse_color = (1, 0.7, 0.05, 1)
cube.data.materials.append(material)
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'probe.blend'))
bpy.ops.export_scene.gltf(filepath=str(output / 'probe.glb'), export_format='GLB')
report = {'blender_version': bpy.app.version_string,
          'outputs': ['probe.blend', 'probe.glb'],
          'purpose': 'Access/export probe only; not a final game asset'}
(output / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report))
