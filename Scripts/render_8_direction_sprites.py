# MIT License

# Copyright (c) 2023 Dmitry Degtyarev
# Copyright (c) 2022 Joe

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Obtained this script here:
# https://github.com/FoozleCC/blender_scripts
# Added some modifications

import bpy
import os
import math
import mathutils


def render8directions_selected_objects(path):
    # path fixing
    path = os.path.abspath(path)

    # get list of selected objects
    selected_list = bpy.context.selected_objects

    # deselect all in scene
    bpy.ops.object.select_all(action='TOGGLE')

    s = bpy.context.scene

    s.render.resolution_x = 256
    s.render.resolution_y = 256
    
    scn = bpy.context.scene

    # Calculate the center of the bounding box of the selected objects
    bounding_box_center = mathutils.Vector((0, 0, 0))
    for o in selected_list:
        o_bbox_center = sum((mathutils.Vector(b) for b in o.bound_box), mathutils.Vector()) / 8
        bounding_box_center += o.matrix_world @ o_bbox_center
    bounding_box_center /= len(selected_list)
    
    # Add or use existing camera
    if "Camera" in bpy.data.objects:
        cam = bpy.data.objects["Camera"]
    else:
        cam_data = bpy.data.cameras.new('Camera')
        cam = bpy.data.objects.new('Camera', cam_data)
        bpy.context.collection.objects.link(cam)
    
    # Set camera distance from the center and its height
    cam_distance = 10
    cam_height = 5

    # loop all initial selected objects (which will likely just be one object.. I haven't tried setting up multiple yet)
    for o in selected_list:

        # select the object
        bpy.context.scene.objects[o.name].select_set(True)

        # loop through the actions
        for a in bpy.data.actions:
            # assign the action
            bpy.context.active_object.animation_data.action = bpy.data.actions.get(a.name)

            # dynamically set the last frame to render based on action
            scn.frame_end = int(bpy.context.active_object.animation_data.action.frame_range[1])

            # create folder for animation
            action_folder = os.path.join(path, a.name)
            if not os.path.exists(action_folder):
                os.makedirs(action_folder)

            # loop through all 8 directions
            for angle in range(0, 360, 90):
                if angle == 0:
                    cardinalDirection = "S"
                if angle == 90:
                    cardinalDirection = "E"
                if angle == 180:
                    cardinalDirection = "N"
                if angle == 270:
                    cardinalDirection = "W"
                
                # restore original rotation
                bpy.context.active_object.rotation_euler[2] = math.radians(0)
                
                # Set camera position in polar coordinates
                cam_x = bounding_box_center.x + cam_distance * math.cos(math.radians(angle))
                cam_y = bounding_box_center.y + cam_distance * math.sin(math.radians(angle))
                cam.location = mathutils.Vector((cam_x, cam_y, cam_height))

                # Set camera to point to the center of the bounding box
                direction = bounding_box_center - cam.location
                rot_quat = direction.to_track_quat('-Z', 'Y')
                cam.rotation_euler = rot_quat.to_euler()

                 # create folder for specific angle
                animation_folder = os.path.join(action_folder, cardinalDirection)
                if not os.path.exists(animation_folder):
                    os.makedirs(animation_folder)
            
                                # loop through and render frames.  Can set how "often" it renders.
                # Every frame is likely not needed.  Currently set to 2 (every other).
                for i in range(s.frame_start,s.frame_end,2):
                    s.frame_current = i

                    s.render.filepath = (
                                        animation_folder
                                        + "\\"
                                        + str(a.name)
                                        + "_"
                                        + str(cardinalDirection)
                                        + "_"
                                        + str(s.frame_current).zfill(3)
                                        )
                    bpy.ops.render.render( #{'dict': "override"},
                                          #'INVOKE_DEFAULT',  
                                          False,            # undo support
                                          animation=False, 
                                          write_still=True
                                         ) 



def get_export_path() -> str:
	script_path = os.path.realpath(__file__)
	blender_file_path = os.path.dirname(script_path)
	parent_folder_path = os.path.dirname(blender_file_path)
	export_path = os.path.join(parent_folder_path, "script-export")

	return export_path


export_path = get_export_path()
render8directions_selected_objects(export_path)
