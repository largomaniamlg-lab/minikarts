import bpy,sys,os,json,hashlib
from mathutils import Vector
out=sys.argv[sys.argv.index('--')+1]
os.makedirs(out,exist_ok=True)
source=bpy.data.filepath
source_hash=hashlib.sha256(open(source,'rb').read()).hexdigest()
meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('V2_')]
report={'source':os.path.basename(source),'source_sha256':source_hash,'uniform_scale':0.5,'deformation':False,'objects':[]}
# Convert the procedural green/cream mask to actual glTF vertex colour.
head=bpy.data.objects.get('V2_head')
mat=bpy.data.materials.get('V2_head_teal_cream')
if head and mat:
 nt=mat.node_tree
 mix=next(n for n in nt.nodes if n.type=='MIX')
 colors=[tuple(s.default_value) for s in mix.inputs if s.type=='RGBA']
 attr=head.data.color_attributes.get('cream_mask')
 if attr and len(colors)>=2:
  lo,hi=colors[-2:]
  for item in attr.data:
   f=item.color[0];item.color=tuple(lo[i]*(1-f)+hi[i]*f for i in range(3))+(1,)
  head.data.color_attributes.active_color=attr
  bsdf=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
  vc=next(n for n in nt.nodes if n.type=='VERTEX_COLOR')
  nt.links.new(vc.outputs['Color'],bsdf.inputs['Base Color'])
# glTF exports the existing scales image directly, with ORM and normal retained.
scale_mat=bpy.data.materials.get('V2_teal_scales')
if scale_mat:
 nt=scale_mat.node_tree;bsdf=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
 image=next(n for n in nt.nodes if n.type=='TEX_IMAGE' and n.image and 'basecolor' in n.image.name.lower())
 nt.links.new(image.outputs['Color'],bsdf.inputs['Base Color'])
for o in meshes:
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 mw=o.matrix_world.copy();o.parent=None;o.matrix_world=mw
 for mod in list(o.modifiers):
  try:
   if mod.show_viewport:bpy.ops.object.modifier_apply(modifier=mod.name)
   else:o.modifiers.remove(mod)
  except RuntimeError:
   report.setdefault('disabled_modifiers',[]).append({'object':o.name,'modifier':mod.name})
   o.modifiers.remove(mod)
 before=sum(len(p.vertices)-2 for p in o.data.polygons)
 if before>180:
  mod=o.modifiers.new('MobileReduction','DECIMATE');mod.ratio=0.065 if o.name=='V2_head' else (0.18 if 'wheel' in o.name else 0.12)
  bpy.ops.object.modifier_apply(modifier=mod.name)
 for v in o.data.vertices:v.co*=0.5
 o.location*=0.5
 report['objects'].append({'name':o.name,'tri_before':before,'tri_after':sum(len(p.vertices)-2 for p in o.data.polygons)})
wheel_objects=[o for o in meshes if o.name.startswith('V2_wheel')]
body=[o for o in meshes if not o.name.startswith('V2_wheel')]
bpy.ops.object.select_all(action='DESELECT')
for o in body:o.select_set(True)
bpy.context.view_layer.objects.active=body[0];bpy.ops.object.join()
body[0].name='DragonBody'
final=[body[0]]+wheel_objects
bpy.ops.object.select_all(action='DESELECT')
for o in final:o.select_set(True)
bpy.context.view_layer.update()
points=[o.matrix_world@Vector(c) for o in final for c in o.bound_box]
lo=[min(p[i] for p in points) for i in range(3)];hi=[max(p[i] for p in points) for i in range(3)]
report.update({'bounds_blender':{'min':lo,'max':hi,'size':[hi[i]-lo[i] for i in range(3)]},'triangles':sum(r['tri_after'] for r in report['objects']),'wheels':{o.name:list(o.location) for o in final if 'wheel' in o.name},'mesh_objects':len(final)})
for image in bpy.data.images:
 if image.source=='FILE' and not image.packed_file:
  try:image.pack()
  except:pass
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'dragon_experimental_game.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(out,'dragon_experimental_v1.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_cameras=False,export_lights=False)
report['glb_sha256']=hashlib.sha256(open(os.path.join(out,'dragon_experimental_v1.glb'),'rb').read()).hexdigest()
json.dump(report,open(os.path.join(out,'manifest.json'),'w'),indent=2)
print('DRAGON_GAME_EXPORT',json.dumps({k:v for k,v in report.items() if k!='objects'}))
