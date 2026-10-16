"""Original battery geometry masters; run with the isolated Blender Python.

Physical dimensions are modeling references in metres, not gameplay balance.
Exports are source candidates pending texture and native scale validation.
"""
from pathlib import Path
import argparse
import math
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'models'
OUT.mkdir(exist_ok=True)

def cylinder(name, radius, depth, z):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=depth,
                                      location=(0, 0, z))
    obj = bpy.context.object
    obj.name = name
    material = bpy.data.materials.new(name + ' surface')
    material.use_nodes = True
    shader = material.node_tree.nodes.get('Principled BSDF')
    wrapper = name == 'Wrapper'
    shader.inputs['Base Color'].default_value = (.035, .04, .045, 1) if wrapper else (.55, .57, .60, 1)
    shader.inputs['Metallic'].default_value = .05 if wrapper else .8
    shader.inputs['Roughness'].default_value = .5 if wrapper else .32
    if wrapper:
        # Original procedural wrapper variation baked into the game atlas;
        # no runtime shader or third-party texture dependency.
        noise = material.node_tree.nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 38
        noise.inputs['Detail'].default_value = 2
        ramp = material.node_tree.nodes.new('ShaderNodeValToRGB')
        ramp.color_ramp.elements[0].position = .25
        ramp.color_ramp.elements[0].color = (.018,.022,.027,1)
        ramp.color_ramp.elements[1].position = .75
        ramp.color_ramp.elements[1].color = (.065,.07,.075,1)
        material.node_tree.links.new(noise.outputs['Fac'],ramp.inputs['Fac'])
        material.node_tree.links.new(ramp.outputs['Color'],shader.inputs['Base Color'])
    obj.data.materials.append(material)
    bevel = obj.modifiers.new('Manufactured edge', 'BEVEL')
    bevel.width = min(radius, depth) * 0.06
    bevel.segments = 2
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    for face in obj.data.polygons:
        face.use_smooth = abs(face.normal.z) < .99
    return obj

CYLINDERS = {'BatteryAAA': (.00525, .0445), 'BatteryAA': (.007, .0503),
             'BatteryC': (.0131, .050), 'BatteryD': (.0171, .0615)}

def cell_marking(text, radius, height):
    """Original curved size marking, independent of gameplay/localization UI."""
    bpy.ops.object.text_add()
    label = bpy.context.object
    label.data.body = text
    label.data.align_x = 'CENTER'
    label.data.align_y = 'CENTER'
    label.data.size = radius * .8
    label.data.resolution_u = 4
    bpy.ops.object.convert(target='MESH')
    label = bpy.context.object
    label.name = 'Cell size marking'
    subdiv = label.modifiers.new('Curved ink tessellation', 'SUBSURF')
    subdiv.subdivision_type = 'SIMPLE'
    subdiv.levels = 2
    bpy.ops.object.modifier_apply(modifier=subdiv.name)
    # Bend flat font geometry around the wrapper's front-facing surface.
    for vertex in label.data.vertices:
        x, y = vertex.co.x, vertex.co.y
        angle = x / radius
        vertex.co = ((radius+.00006)*math.sin(angle),
                     -(radius+.00006)*math.cos(angle),height*.48+y)
    material = bpy.data.materials.new('Size marking ink')
    material.use_nodes = True
    material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (.72,.72,.68,1)
    label.data.materials.append(material)
    return label

NAMES = (*CYLINDERS, 'BatteryCoin', 'Battery9V', 'BatteryPackSmall', 'BatteryPackLarge', 'BatteryAAImprovised', 'BatteryLithiumPack')
parser = argparse.ArgumentParser()
parser.add_argument('--items', nargs='+', choices=NAMES, default=NAMES)
args = parser.parse_args()
for kind in args.items:
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    if kind == 'BatteryLithiumPack':
        # Unbranded sealed rechargeable pack: visual dimensions only. No
        # new voltage, connector compatibility, or capacity is introduced.
        for label, dimensions, location, color in (
            ('Sealed case', (.038,.019,.065), (0,0,.0325), (.035,.04,.045,1)),
            ('Top cap', (.0384,.0194,.006), (0,0,.065), (.10,.11,.12,1)),
            ('Bottom cap', (.0384,.0194,.005), (0,0,.0025), (.10,.11,.12,1)),
            ('Contact A', (.006,.0006,.008), (-.007,-.0098,.058), (.55,.57,.60,1)),
            ('Contact B', (.006,.0006,.008), (.007,-.0098,.058), (.55,.57,.60,1)),
        ):
            bpy.ops.mesh.primitive_cube_add(size=1, location=location)
            part = bpy.context.object
            part.name = label
            part.dimensions = dimensions
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            bevel = part.modifiers.new('Case edge', 'BEVEL')
            bevel.width = min(dimensions)*.12
            bevel.segments = 3
            bpy.ops.object.modifier_apply(modifier=bevel.name)
            material = bpy.data.materials.new(label+' surface')
            material.use_nodes = True
            material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = color
            part.data.materials.append(material)
    elif kind == 'BatteryAAImprovised':
        # Existing recipe: AAA cell plus paperclip. This depicts a folded
        # conductor spacer, not a new chemistry or gameplay capacity.
        radius, height = CYLINDERS['BatteryAAA']
        cylinder('Wrapper', radius, height-.0033, (height-.0033)/2)
        cylinder('Positive shoulder', radius, .0015, height-.00255)
        cylinder('Positive terminal', radius*.36, .0018, height-.0009)
        cylinder('Negative cap', radius*.985, .0008, .0004)
        curve = bpy.data.curves.new('Folded paperclip conductor', 'CURVE')
        curve.dimensions = '3D'
        curve.bevel_depth = .0004
        curve.bevel_resolution = 2
        spline = curve.splines.new('POLY')
        points = [(-.003,0,-.0004),(.003,0,-.0004),
                  (.003,0,-.0049),(-.003,0,-.0049),
                  (-.003,0,-.0013),(.002,0,-.0013),
                  (.002,0,-.004),(-.002,0,-.004)]
        spline.points.add(len(points)-1)
        for point, coordinate in zip(spline.points, points):
            point.co = (*coordinate, 1)
        wire = bpy.data.objects.new('Paperclip spacer', curve)
        bpy.context.collection.objects.link(wire)
        bpy.ops.object.select_all(action='DESELECT')
        wire.select_set(True)
        bpy.context.view_layer.objects.active = wire
        bpy.ops.object.convert(target='MESH')
        wire = bpy.context.object
        wire.data.materials.append(bpy.data.materials['Negative cap surface'])
        cell_marking('AAA', radius, height)
    elif kind in CYLINDERS:
        radius, height = CYLINDERS[kind]
        body = height - .0033
        cylinder('Wrapper', radius, body, body/2)
        cylinder('Positive shoulder', radius, .0015, body+.00075)
        cylinder('Positive terminal', radius*.36, .0018, body+.0024)
        cylinder('Negative cap', radius*.985, .0008, .0004)
        cell_marking(kind.removeprefix('Battery'), radius, height)
    elif kind in ('BatteryPackSmall', 'BatteryPackLarge'):
        radius, height = CYLINDERS['BatteryAA' if kind == 'BatteryPackSmall' else 'BatteryD']
        for x in (-radius, radius):
            for y in (-radius, radius):
                cell = cylinder('Wrapper', radius, height-.003, (height-.003)/2)
                cell.location.x, cell.location.y = x, y
                cap = cylinder('Cell cap', radius*.98, .0015, height-.0025)
                cap.location.x, cap.location.y = x, y
                terminal = cylinder('Cell terminal', radius*.36, .002, height-.001)
                terminal.location.x, terminal.location.y = x, y
                marking = cell_marking('AA' if kind == 'BatteryPackSmall' else 'D', radius, height)
                marking.location.x, marking.location.y = x, y
        # Four cells match the existing recipe; bands are the duct-tape input.
        for z in (height*.3, height*.7):
            # Rounded-square perimeter follows the convex hull of four cells.
            import math
            perimeter = []
            for cx, cy, start in ((radius,radius,0),(-radius,radius,90),
                                  (-radius,-radius,180),(radius,-radius,270)):
                for step in range(9):
                    angle = math.radians(start + step*90/8)
                    perimeter.append((cx+(radius+.0003)*math.cos(angle),
                                      cy+(radius+.0003)*math.sin(angle)))
            vertices = [(x,y,z+dz) for dz in (-height*.065,height*.065)
                        for x,y in perimeter]
            count = len(perimeter)
            faces = [(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
            mesh = bpy.data.meshes.new('Tape wrap surface')
            mesh.from_pydata(vertices, [], faces)
            mesh.update()
            band = bpy.data.objects.new('Duct tape band', mesh)
            bpy.context.collection.objects.link(band)
            bpy.context.view_layer.objects.active = band
            band.select_set(True)
            solid = band.modifiers.new('Tape thickness', 'SOLIDIFY')
            solid.thickness = .0002
            bpy.ops.object.modifier_apply(modifier=solid.name)
            material = bpy.data.materials.new('Duct tape grey')
            material.use_nodes = True
            material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (.20,.21,.22,1)
            band.data.materials.append(material)
    elif kind == 'Battery9V':
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, .023))
        body = bpy.context.object
        body.name = 'Rectangular wrapper'
        body.dimensions = (.0265, .0175, .046)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bevel = body.modifiers.new('Rounded case edges', 'BEVEL')
        bevel.width = .001
        bevel.segments = 3
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        material = bpy.data.materials.new('9V wrapper')
        material.use_nodes = True
        shader = material.node_tree.nodes.get('Principled BSDF')
        shader.inputs['Base Color'].default_value = (.035, .04, .045, 1)
        body.data.materials.append(material)
        positive = cylinder('Positive snap', .0026, .0025, .04725)
        positive.location.x = -.006
        negative = cylinder('Negative snap rim', .0037, .0025, .04725)
        negative.location.x = .006
        # Recessed center distinguishes the larger female snap at game scale.
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=.0024,
                                          depth=.003, location=(.006, 0, .0485))
        cutter = bpy.context.object
        bpy.context.view_layer.objects.active = negative
        cut = negative.modifiers.new('Snap recess', 'BOOLEAN')
        cut.operation = 'DIFFERENCE'
        cut.object = cutter
        bpy.ops.object.modifier_apply(modifier=cut.name)
        bpy.data.objects.remove(cutter, do_unlink=True)
        bpy.ops.object.text_add(location=(0,-.00881,.023))
        label=bpy.context.object
        label.name='9V size marking'
        label.data.body='9V'
        label.data.align_x='CENTER'
        label.data.align_y='CENTER'
        label.data.size=.008
        label.data.resolution_u=4
        label.rotation_euler.x=math.pi/2
        bpy.ops.object.convert(target='MESH')
        label=bpy.context.object
        ink=bpy.data.materials.new('9V marking ink')
        ink.use_nodes=True
        ink.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.72,.72,.68,1)
        label.data.materials.append(ink)
    else:
        cylinder('Cell body', .010, .0030, .0015)
        cylinder('Top face', .0098, .0002, .0031)
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    bpy.ops.object.join()
    model = bpy.context.object
    model.name = 'PW_' + kind
    # Consistent floor anchor, including the improvised cell's negative-end
    # spacer. Bake object translation rather than relying on importer behavior.
    bottom = min((model.matrix_world @ Vector(corner)).z for corner in model.bound_box)
    model.location.z -= bottom
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=.03)
    bpy.ops.object.mode_set(mode='OBJECT')
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 16
    atlas = bpy.data.images.new('PW_' + kind, width=256, height=256, alpha=True)
    for material in model.data.materials:
        # PZ consumes a color atlas, not Blender's metallic diffuse response.
        material.node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value = 0
        node = material.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = atlas
        material.node_tree.nodes.active = node
    scene.render.bake.use_pass_direct = False
    scene.render.bake.use_pass_indirect = False
    scene.render.bake.use_pass_color = True
    scene.render.bake.margin = 4
    bpy.ops.object.bake(type='DIFFUSE')
    atlas.filepath_raw = str(OUT / (kind + '-albedo.png'))
    atlas.file_format = 'PNG'
    atlas.save()
    # The exported game mesh uses a single atlas rather than Blender-only slots.
    game_material = bpy.data.materials.new('PW_' + kind + '_Atlas')
    game_material.use_nodes = True
    texture = game_material.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image = atlas
    game_shader = game_material.node_tree.nodes.get('Principled BSDF')
    game_material.node_tree.links.new(texture.outputs['Color'], game_shader.inputs['Base Color'])
    game_shader.inputs['Roughness'].default_value = .45
    model.data.materials.clear()
    model.data.materials.append(game_material)
    for face in model.data.polygons:
        face.material_index = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / (kind + '-v1.blend')))
    bpy.ops.export_scene.fbx(filepath=str(OUT / (kind + '-v1.fbx')),
                             use_selection=True, object_types={'MESH'},
                             bake_anim=False, add_leaf_bones=False)
    print(kind, 'vertices=', len(model.data.vertices),
          'polygons=', len(model.data.polygons), 'UV=', len(model.data.uv_layers))
