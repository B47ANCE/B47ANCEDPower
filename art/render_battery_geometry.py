"""Preview original model geometry/materials; not a native-game screenshot."""
from pathlib import Path
import argparse
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
NAMES = ('BatteryAAA', 'BatteryAA', 'BatteryC', 'BatteryD', 'BatteryCoin', 'Battery9V', 'BatteryPackSmall', 'BatteryPackLarge', 'BatteryAAImprovised', 'BatteryLithiumPack')
parser = argparse.ArgumentParser()
parser.add_argument('--items', nargs='+', choices=NAMES, default=NAMES)
args = parser.parse_args()
for name in args.items:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(ROOT / 'models' / (name + '-v1.fbx')))
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 32
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.film_transparent = True
    model = next(o for o in scene.objects if o.type == 'MESH')
    center = sum((model.matrix_world @ Vector(c) for c in model.bound_box), Vector()) / 8
    size = max(model.dimensions)
    bpy.ops.object.camera_add(location=center + Vector((size*2, -size*3, size*2)))
    camera = bpy.context.object
    camera.rotation_euler = (center-camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = size * 1.4
    camera.data.clip_start = .0001
    scene.camera = camera
    for offset, energy in [((2,-3,4), .2), ((-2,1,2), .1)]:
        bpy.ops.object.light_add(type='AREA', location=center + Vector(offset)*size)
        light = bpy.context.object
        light.data.energy = energy
        light.data.shape = 'DISK'
        light.data.size = size * 3
        light.rotation_euler = (center-light.location).to_track_quat('-Z', 'Y').to_euler()
    if scene.world is None:
        scene.world = bpy.data.worlds.new('Preview world')
    scene.world.color = (.25, .25, .25)
    scene.render.filepath = str(ROOT / 'models' / (name + '-preview.png'))
    bpy.ops.render.render(write_still=True)
