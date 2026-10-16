"""Read-only local mesh-size evidence; never exports or copies vanilla assets."""
from pathlib import Path
import argparse
import json
import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument('--game-root', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parent


def inspect(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    if not points:
        raise ValueError(f'No mesh in {path}')
    low = [min(p[i] for p in points) for i in range(3)]
    high = [max(p[i] for p in points) for i in range(3)]
    return dict(file=path.name, mesh_count=len(meshes), minimum=low, maximum=high,
                dimensions=[b-a for a,b in zip(low,high)],
                object_transforms=[dict(location=list(o.location), scale=list(o.scale),
                                        rotation=list(o.rotation_euler)) for o in meshes])


native = inspect(args.game_root / 'media/models_X/WorldItems/Battery.fbx')
original = inspect(root / 'models/BatteryAA-v1.fbx')
print(json.dumps(dict(native=native, original=original,
                     warning='Blender-imported bounds only; PZ transform/placement unverified'), indent=2))
