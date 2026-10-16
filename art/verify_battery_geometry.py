"""Check original source masters against their FBX round trips."""
from pathlib import Path
import json
import math
import bpy
from mathutils import Vector
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_asset_coverage import battery_items, digest, ITEMS

ROOT = Path(__file__).resolve().parent

def measure(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return [max(p[i] for p in points) - min(p[i] for p in points)
            for i in range(3)]

results = []
for name in sorted(battery_items(ITEMS.read_text())):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'models' / (name + '-v1.blend')))
    source = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    assert len(source) == 1, (name, 'source object count')
    dimensions = sorted(measure(source[0]))
    vertices = len(source[0].data.vertices)
    polygons = len(source[0].data.polygons)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.fbx(filepath=str(ROOT / 'models' / (name + '-v1.fbx')))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    assert len(meshes) == 1, (name, 'FBX object count')
    mesh = meshes[0]
    actual = sorted(measure(mesh))
    assert all(abs(c) < 1e-6 for c in mesh.location), (name, 'nonzero exported origin')
    floor = min((mesh.matrix_world @ Vector(corner)).z for corner in mesh.bound_box)
    assert abs(floor) < 1e-6, (name, 'floor anchor offset', floor)
    assert all(abs(a-b) < 1e-6 for a,b in zip(actual, dimensions)), (name, actual, dimensions)
    assert len(mesh.data.vertices) == vertices, (name, 'vertex loss')
    assert len(mesh.data.polygons) == polygons, (name, 'face loss')
    assert len(mesh.data.uv_layers) == 1, (name, 'UV layer loss')
    assert all(math.isfinite(c) for v in mesh.data.vertices for c in v.co)
    assert all(math.isfinite(c) and -1e-6 <= c <= 1.000001
               for uv in mesh.data.uv_layers.active.data for c in uv.uv)
    assert not any(o.type == 'ARMATURE' for o in bpy.context.scene.objects)
    assert len(mesh.data.materials) == 1, (name, 'atlas material missing')
    material = mesh.data.materials[0]
    assert material.use_nodes, (name, 'material nodes missing')
    image_nodes = [n for n in material.node_tree.nodes
                   if n.type == 'TEX_IMAGE' and n.image]
    assert image_nodes, (name, 'exported texture reference missing')
    expected_texture = ROOT / 'models' / (name + '-albedo.png')
    assert expected_texture.is_file(), (name, 'texture file missing')
    referenced = [Path(bpy.path.abspath(n.image.filepath)).resolve() for n in image_nodes]
    assert expected_texture.resolve() in referenced, (name, 'wrong texture', referenced)
    atlas = next(n.image for n in image_nodes
                 if Path(bpy.path.abspath(n.image.filepath)).resolve() == expected_texture.resolve())
    assert tuple(atlas.size) == (256, 256), (name, 'atlas dimensions')
    shader = next(n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    assert shader.inputs['Base Color'].is_linked, (name, 'unconnected atlas')
    results.append(dict(model=name, vertices=vertices, polygons=polygons,
                        dimensions_metres_sorted=actual, status='PASS',
                        native_rendering='UNVERIFIED', textured=True,
                        texture=expected_texture.name,
                        sha256={name+suffix: digest(ROOT / 'models' / (name+suffix))
                                for suffix in ('-v1.blend', '-v1.fbx', '-albedo.png')}))
report = dict(blender=bpy.app.version_string, results=results)
(ROOT / 'geometry-validation.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report, indent=2))
